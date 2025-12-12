import 'package:expense_tracker/utils/api_client.dart';
import 'package:flutter/material.dart';

class AddExpenseScreen extends StatefulWidget {
  final String baseUrl;
  final int userId;
  final int? preSelectedGroupId;

  final bool isEditMode;
  final int? expenseIdToEdit;
  final bool isSettlement;
  final double? settlementAmount;
  final int? settlementReceiverId;
  final String? settlementReceiverName;

  const AddExpenseScreen({
    super.key,
    required this.baseUrl,
    required this.userId,
    this.preSelectedGroupId,
    this.isEditMode = false,
    this.expenseIdToEdit,
    this.isSettlement = false,
    this.settlementAmount,
    this.settlementReceiverId,
    this.settlementReceiverName,
  });

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _amountController = TextEditingController();
  final _descController = TextEditingController();

  // Data Stores
  List<dynamic> _myGroups = [];
  List<dynamic> _allFetchedUsers =
      []; // Cache of ALL users from Identity Service
  List<dynamic> _availableUsers = []; // The actual list shown in UI

  int? _selectedGroupId;
  final Map<int, bool> _selectedUserIds = {};
  final Map<int, TextEditingController> _unequalControllers = {};

  final List<String> _categories = [
    "Food",
    "Travel",
    "Shopping",
    "Rent",
    "Entertainment",
    "Health",
    "Other",
  ];
  String? _selectedCategory;

  bool _isLoading = false;
  bool _isEqualSplit = true;

  @override
  void initState() {
    super.initState();
    _selectedGroupId = widget.preSelectedGroupId;

    if (widget.isSettlement) {
      _amountController.text = widget.settlementAmount.toString();
      _descController.text = "Payment to ${widget.settlementReceiverName}";
      _selectedCategory = "Other";
      _isEqualSplit = false;
    }

    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      setState(() => _isLoading = true);

      // 1. Fetch All Users (Identity Service)
      final userResponse = await ApiClient.create(
        widget.baseUrl,
      ).get("${widget.baseUrl}/users");
      _allFetchedUsers = (userResponse.data as List).toList();

      // 2. Fetch My Groups (Expense Service)
      final groupResponse = await ApiClient.create(
        widget.baseUrl,
      ).get("${widget.baseUrl}/groups/user/${widget.userId}");
      _myGroups = groupResponse.data;

      // 3. Handle Edit Mode
      if (widget.isEditMode && widget.expenseIdToEdit != null) {
        await _loadExpenseDetails();
      }

      // 4. Handle Settlement
      if (widget.isSettlement && widget.settlementReceiverId != null) {
        _selectedUserIds[widget.settlementReceiverId!] = true;
        _getController(widget.settlementReceiverId!).text = widget
            .settlementAmount
            .toString();
      }

      if (mounted) {
        setState(() {
          // Initialize the list based on selection
          if (_selectedGroupId != null) {
            _filterUsersByGroup(_selectedGroupId);
          } else {
            // No group? Show everyone (or friends only in a real app)
            _availableUsers = List.from(_allFetchedUsers);
            _sortUsers();
          }
        });
      }
    } catch (e) {
      print("Error loading data: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- LOGIC: Filter Users based on Group Member IDs ---
  void _filterUsersByGroup(int? groupId) {
    if (groupId == null) {
      // Reset to show everyone if group is deselected
      setState(() {
        _availableUsers = List.from(_allFetchedUsers);
        _sortUsers();
        _selectedUserIds.clear(); // Clear selections when switching context
      });
      return;
    }

    final group = _myGroups.firstWhere(
      (g) => g['id'] == groupId,
      orElse: () => null,
    );
    if (group != null) {
      // BACKEND FIX: Expense Service returns 'memberIds' (List<Int>), NOT 'members' objects
      final List<dynamic> memberIds = group['memberIds'] ?? [];

      setState(() {
        // Filter the cached users to only those in this group
        _availableUsers = _allFetchedUsers
            .where((u) => memberIds.contains(u['id']))
            .toList();
        _sortUsers();

        if (!widget.isEditMode) {
          _selectedUserIds.clear();
          _unequalControllers.clear();
        }
      });
    }
  }

  void _sortUsers() {
    _availableUsers.sort((a, b) {
      if (a['id'] == widget.userId) return -1;
      if (b['id'] == widget.userId) return 1;
      return 0;
    });
  }

  Future<void> _loadExpenseDetails() async {
    final response = await ApiClient.create(
      widget.baseUrl,
    ).get("${widget.baseUrl}/expenses/${widget.expenseIdToEdit}");
    final data = response.data;

    setState(() {
      _amountController.text = data['amount'].toString();
      _descController.text = data['description'];
      _selectedCategory = data['category'];
      _selectedGroupId = data['groupId'];

      // Apply filter for the loaded group
      if (_selectedGroupId != null) _filterUsersByGroup(_selectedGroupId);

      final List<dynamic> splits = data['splits'];
      _isEqualSplit = false;

      for (var split in splits) {
        int uid = split['userId'];
        double amt = (split['amount'] as num).toDouble();
        _selectedUserIds[uid] = true;
        _getController(uid).text = amt.toString();
      }
    });
  }

  Future<void> _submitExpense() async {
    final double? totalAmount = double.tryParse(_amountController.text);
    if (totalAmount == null ||
        _descController.text.isEmpty ||
        _selectedCategory == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }

    List<Map<String, dynamic>> splitsToSend = [];
    List<int> participantIds = _selectedUserIds.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    if (participantIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select at least one person")),
      );
      return;
    }

    if (_isEqualSplit) {
      double share =
          (totalAmount / participantIds.length * 100).floorToDouble() / 100;
      for (int uid in participantIds) {
        splitsToSend.add({"userId": uid, "amount": share});
      }
      double calculatedTotal = share * participantIds.length;
      if (calculatedTotal < totalAmount) {
        splitsToSend[0]['amount'] =
            splitsToSend[0]['amount'] + (totalAmount - calculatedTotal);
      }
    } else {
      double sum = 0;
      for (int uid in participantIds) {
        double amount =
            double.tryParse(_unequalControllers[uid]?.text ?? "0") ?? 0;
        sum += amount;
        splitsToSend.add({"userId": uid, "amount": amount});
      }
      if ((sum - totalAmount).abs() > 0.1) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Splits sum ($sum) != Total ($totalAmount)")),
        );
        return;
      }
    }

    setState(() => _isLoading = true);
    try {
      String url = "${widget.baseUrl}/expenses";
      if (widget.isEditMode) url = "$url/${widget.expenseIdToEdit}";

      final payload = {
        "userId": widget.userId,
        "amount": totalAmount,
        "description": _descController.text,
        "category": _selectedCategory,
        "groupId": _selectedGroupId,
        "splits": splitsToSend,
      };

      if (widget.isEditMode) {
        await ApiClient.create(widget.baseUrl).put(url, data: payload);
      } else {
        await ApiClient.create(widget.baseUrl).post(url, data: payload);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Saved Successfully"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error saving: $e"),
            backgroundColor: Colors.red,
          ),
        );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  TextEditingController _getController(int uid) {
    _unequalControllers.putIfAbsent(uid, () => TextEditingController());
    return _unequalControllers[uid]!;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Find Group Name for display
    String? currentGroupName;
    if (_selectedGroupId != null && _myGroups.isNotEmpty) {
      final g = _myGroups.firstWhere(
        (g) => g['id'] == _selectedGroupId,
        orElse: () => null,
      );
      if (g != null) currentGroupName = g['name'];
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditMode ? "Edit Expense" : "Add Expense"),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Amount & Description
                  TextField(
                    controller: _amountController,
                    decoration: const InputDecoration(
                      labelText: "Amount",
                      prefixText: "₹ ",
                    ),
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _descController,
                    decoration: const InputDecoration(
                      labelText: "Description",
                      prefixIcon: Icon(Icons.description_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 2. Category
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: "Category",
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                    initialValue: _selectedCategory,
                    items: _categories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedCategory = v),
                  ),

                  const SizedBox(height: 24),

                  // 3. Split Type
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(
                          value: true,
                          label: Text("Equally"),
                          icon: Icon(Icons.pie_chart_outline),
                        ),
                        ButtonSegment(
                          value: false,
                          label: Text("Unequally"),
                          icon: Icon(Icons.edit_note),
                        ),
                      ],
                      selected: {_isEqualSplit},
                      onSelectionChanged: (Set<bool> newSelection) {
                        setState(() => _isEqualSplit = newSelection.first);
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 4. Group Selector Logic (Read-Only if preselected, Dropdown if not)
                  if (widget.preSelectedGroupId != null &&
                      currentGroupName != null) ...[
                    InputDecorator(
                      decoration: const InputDecoration(
                        labelText: "Group",
                        prefixIcon: Icon(Icons.group),
                        border: OutlineInputBorder(),
                        filled: true,
                      ),
                      child: Text(
                        currentGroupName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ] else ...[
                    DropdownButtonFormField<int>(
                      decoration: const InputDecoration(
                        labelText: "Group (Optional)",
                        prefixIcon: Icon(Icons.group_work_outlined),
                      ),
                      initialValue:
                          _selectedGroupId, // Use state variable directly
                      onChanged: (widget.isEditMode || widget.isSettlement)
                          ? null
                          : (val) {
                              setState(() => _selectedGroupId = val);
                              _filterUsersByGroup(val);
                            },
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text("No Group (Show All)"),
                        ),
                        ..._myGroups.map(
                          (group) => DropdownMenuItem<int>(
                            value: group['id'],
                            child: Text(group['name']),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 16),
                  Text(
                    "Select Participants",
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),

                  // 5. Friend List
                  Card(
                    child: _availableUsers.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text("No members found in this group."),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _availableUsers.length,
                            separatorBuilder: (c, i) => const Divider(
                              height: 1,
                              indent: 16,
                              endIndent: 16,
                            ),
                            itemBuilder: (context, index) {
                              final user = _availableUsers[index];
                              final int uid = user['id'];
                              final bool isMe = uid == widget.userId;
                              final bool isSelected =
                                  _selectedUserIds[uid] ?? false;

                              return CheckboxListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 4,
                                ),
                                title: Text(
                                  isMe ? "${user['name']} (You)" : user['name'],
                                  style: TextStyle(
                                    fontWeight: isMe
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                                value: isSelected,
                                onChanged: (val) => setState(
                                  () => _selectedUserIds[uid] = val!,
                                ),
                                secondary: CircleAvatar(
                                  backgroundColor:
                                      theme.colorScheme.surfaceContainerHighest,
                                  child: Text(user['name'][0].toUpperCase()),
                                ),
                                subtitle: (!_isEqualSplit && isSelected)
                                    ? Padding(
                                        padding: const EdgeInsets.only(
                                          top: 8.0,
                                        ),
                                        child: TextField(
                                          controller: _getController(uid),
                                          keyboardType: TextInputType.number,
                                          decoration: const InputDecoration(
                                            prefixText: "₹ ",
                                            isDense: true,
                                            filled: false,
                                            border: UnderlineInputBorder(),
                                          ),
                                        ),
                                      )
                                    : null,
                              );
                            },
                          ),
                  ),

                  const SizedBox(height: 24),

                  // 6. Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton.icon(
                      onPressed: _isLoading ? null : _submitExpense,
                      icon: const Icon(Icons.check),
                      label: const Text("Save Expense"),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }
}
