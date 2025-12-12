import 'package:flutter/material.dart';
import '../utils/api_client.dart';
import 'add_expense_screen.dart';

class GroupDetailScreen extends StatefulWidget {
  final String baseUrl;
  final int userId;
  final int groupId;
  final String groupName;

  const GroupDetailScreen({
    super.key,
    required this.baseUrl,
    required this.userId,
    required this.groupId,
    required this.groupName,
  });

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  List<dynamic> _expenses = [];
  List<dynamic> _balances = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final expRes = await ApiClient.create(widget.baseUrl).get(
        "${widget.baseUrl}/expenses/group/${widget.groupId}/${widget.userId}",
      );
      final balRes = await ApiClient.create(widget.baseUrl).get(
        "${widget.baseUrl}/groups/${widget.groupId}/balances/${widget.userId}",
      );

      if (mounted) {
        setState(() {
          _expenses = expRes.data;
          _balances = balRes.data;
          _isLoading = false;
        });
      }
    } catch (e) {
      print(e);
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<bool> _confirmDelete(int expenseId) async {
    return await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Delete Expense?"),
            content: const Text("This action cannot be undone."),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text("Cancel"),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                child: const Text("Delete"),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _deleteExpense(int expenseId) async {
    try {
      await ApiClient.create(
        widget.baseUrl,
      ).delete("${widget.baseUrl}/expenses/$expenseId");
      setState(() {
        _expenses.removeWhere((e) => e['expenseId'] == expenseId);
      });
      _fetchData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Delete failed")));
      }
    }
  }

  void _editExpense(int expenseId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddExpenseScreen(
          baseUrl: widget.baseUrl,
          userId: widget.userId,
          preSelectedGroupId: widget.groupId,
          isEditMode: true,
          expenseIdToEdit: expenseId,
        ),
      ),
    ).then((_) => _fetchData());
  }

  void _onSettleUp(int friendId, String friendName, double amount) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddExpenseScreen(
          baseUrl: widget.baseUrl,
          userId: widget.userId,
          preSelectedGroupId: widget.groupId,
          isSettlement: true,
          settlementAmount: amount.abs(),
          settlementReceiverId: friendId,
          settlementReceiverName: friendName,
        ),
      ),
    ).then((_) => _fetchData());
  }

  void _showExpenseDetails(dynamic item, bool isInvolved) async {
    // 1. Show Loading Indicator immediately
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allow full height
      builder: (ctx) => const Padding(
        padding: EdgeInsets.all(40.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text("Loading details..."),
          ],
        ),
      ),
    );

    try {
      // 2. Fetch Full Details (Splits breakdown) from Backend
      final response = await ApiClient.create(
        widget.baseUrl,
      ).get("${widget.baseUrl}/expenses/${item['expenseId']}");

      // Close Loading Sheet
      if (mounted) Navigator.pop(context);

      if (!mounted) return;

      final fullData = response.data;
      final List<dynamic> splits = fullData['splits'];
      final theme = Theme.of(context);

      // 3. Show Data Sheet
      showModalBottomSheet(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (context) {
          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.6, // Start at 60% height
            maxChildSize: 0.9,
            builder: (_, controller) => Container(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: ListView(
                controller: controller,
                children: [
                  // HEADER
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          fullData['description'],
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        "₹${fullData['amount']}",
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Paid by ${item['paidByName']}",
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Divider(height: 32),

                  // SPLIT BREAKDOWN LIST
                  Text(
                    "Split Details",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  ...splits.map((split) {
                    final bool isMe = split['userId'] == widget.userId;
                    // Note: You might need to fetch User Names map to show names here
                    // if 'splits' only has UserIDs.
                    // Ideally, Update ExpenseDetailResponseDTO in backend to include userName in SplitDefinition!
                    // For now, we show "User ID: X" or "You"
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                        child: Icon(
                          Icons.person,
                          size: 16,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      title: Text(
                        isMe
                            ? "You"
                            : "User ${split['userId']}", // UPDATE BACKEND TO SEND NAMES
                        style: TextStyle(
                          fontWeight: isMe
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      trailing: Text(
                        "₹${split['amount']}",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    );
                  }),

                  const SizedBox(height: 24),

                  // ACTIONS
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _deleteExpense(item['expenseId']);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: theme.colorScheme.error,
                          ),
                          icon: const Icon(Icons.delete),
                          label: const Text("Delete"),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _editExpense(item['expenseId']);
                          },
                          icon: const Icon(Icons.edit),
                          label: const Text("Edit"),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Failed to load details")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final greenColor = isDark ? Colors.greenAccent[400] : Colors.green[700];
    final redColor = isDark ? const Color(0xFFFF8A80) : Colors.red[700];

    return Scaffold(
      appBar: AppBar(title: Text(widget.groupName)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                if (_balances.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant.withOpacity(
                            0.5,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Balances",
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ..._balances.map((bal) {
                            final double amount = (bal['amount'] as num)
                                .toDouble();
                            final bool iOwe = amount < 0;
                            String safeName = bal['userName'] ?? "?";
                            String firstChar = safeName.isNotEmpty
                                ? safeName[0].toUpperCase()
                                : "?";

                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8.0,
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor:
                                        theme.colorScheme.secondaryContainer,
                                    child: Text(
                                      firstChar,
                                      style: TextStyle(
                                        color: theme
                                            .colorScheme
                                            .onSecondaryContainer,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      iOwe
                                          ? "You owe $safeName"
                                          : "$safeName owes you",
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                  ),
                                  Text(
                                    "₹${amount.abs()}",
                                    style: TextStyle(
                                      color: iOwe ? redColor : greenColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  if (iOwe) ...[
                                    const SizedBox(width: 12),
                                    FilledButton.tonal(
                                      onPressed: () => _onSettleUp(
                                        bal['userId'],
                                        safeName,
                                        amount,
                                      ),
                                      style: FilledButton.styleFrom(
                                        visualDensity: VisualDensity.compact,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                        ),
                                      ),
                                      child: const Text("Settle"),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),

                SliverPadding(
                  padding: const EdgeInsets.only(bottom: 80),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildModernTile(
                        _expenses[index],
                        theme,
                        greenColor!,
                        redColor!,
                      ),
                      childCount: _expenses.length,
                    ),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddExpenseScreen(
                baseUrl: widget.baseUrl,
                userId: widget.userId,
                preSelectedGroupId: widget.groupId,
              ),
            ),
          );
          _fetchData();
        },
        label: const Text("Add Expense"),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildModernTile(
    dynamic item,
    ThemeData theme,
    Color green,
    Color red,
  ) {
    final int paidByUserId = item['paidByUserId'];
    final bool iPaid = paidByUserId == widget.userId;

    final double totalAmount = (item['totalAmount'] as num).toDouble();
    final double myShare = (item['myShare'] as num).toDouble();

    // --- LOGIC FIX START ---
    // Override backend flag if we know we are involved based on amounts
    bool isInvolved = (item['involved'] ?? false) || iPaid || (myShare > 0.01);
    // --- LOGIC FIX END ---

    Color amountColor;
    String statusText;

    if (!isInvolved) {
      amountColor = theme.colorScheme.onSurface.withOpacity(0.4);
      statusText = "not involved";
    } else if (iPaid) {
      amountColor = green;
      statusText = "you lent";
    } else {
      amountColor = red;
      statusText = "you borrowed";
    }

    double displayAmount = isInvolved
        ? (iPaid ? totalAmount - myShare : myShare)
        : totalAmount;

    final double opacity = isInvolved ? 1.0 : 0.6;

    return Dismissible(
      key: Key(item['expenseId'].toString()),
      direction: DismissDirection.startToEnd,
      confirmDismiss: (direction) => _confirmDelete(item['expenseId']),
      background: Container(
        color: theme.colorScheme.error,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Icon(Icons.delete, color: Colors.white, size: 32),
      ),
      child: Opacity(
        opacity: opacity,
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          elevation: 0,
          color: theme.colorScheme.surfaceContainerLow,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _showExpenseDetails(item, isInvolved),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.receipt_long,
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                  const SizedBox(width: 16),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['description'],
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          iPaid
                              ? "You paid ₹$totalAmount"
                              : "${item['paidByName']} paid ₹$totalAmount",
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        statusText,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: amountColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "₹${displayAmount.toStringAsFixed(2)}",
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: amountColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
