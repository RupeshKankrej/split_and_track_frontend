import 'package:flutter/material.dart';
import '../utils/api_client.dart';

class CreateGroupScreen extends StatefulWidget {
  final String baseUrl;
  final int userId;
  const CreateGroupScreen({
    super.key,
    required this.baseUrl,
    required this.userId,
  });

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _nameController = TextEditingController();

  // List of all available users (fetched + invited)
  List<dynamic> _allUsers = [];

  // IDs of selected users
  final List<int> _selectedMemberIds = [];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    try {
      // Calls Expense Service -> Gateway -> Identity Service (if routed correctly)
      // Or Expense Service's local cache if you strictly separated them.
      // Assuming Gateway routes /api/users to Identity Service:
      final response = await ApiClient.create(
        widget.baseUrl,
      ).get("${widget.baseUrl}/users");

      if (mounted) {
        setState(() {
          _allUsers = (response.data as List)
              .where((u) => u['id'] != widget.userId)
              .toList();
        });
      }
    } catch (e) {
      print("Error fetching users: $e");
    }
  }

  // --- NEW: INVITE LOGIC ---
  Future<void> _showInviteDialog() async {
    final emailCtrl = TextEditingController();
    final nameCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Invite Friend"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emailCtrl,
              decoration: const InputDecoration(
                labelText: "Email",
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: "Name (Optional)",
                prefixIcon: Icon(Icons.person),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          FilledButton(
            onPressed: () async {
              if (emailCtrl.text.isEmpty) return;
              Navigator.pop(ctx); // Close Dialog
              await _inviteUser(emailCtrl.text.trim(), nameCtrl.text.trim());
            },
            child: const Text("Invite"),
          ),
        ],
      ),
    );
  }

  Future<void> _inviteUser(String email, String name) async {
    setState(() => _isLoading = true);
    try {
      // 1. Call Identity Service via Gateway
      final response = await ApiClient.create(widget.baseUrl).post(
        "${widget.baseUrl}/users/invite",
        data: {"email": email, "name": name.isNotEmpty ? name : "Friend"},
      );

      final newUser =
          response.data; // Should return UserDTO {id, name, email...}

      // 2. Add to Local List & Auto-Select
      setState(() {
        // Avoid duplicates if user already exists in list
        final exists = _allUsers.any((u) => u['id'] == newUser['id']);
        if (!exists) {
          _allUsers.insert(0, newUser); // Add to top
        }

        // Auto-select the new/found user
        if (!_selectedMemberIds.contains(newUser['id'])) {
          _selectedMemberIds.add(newUser['id']);
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${newUser['name']} added to list!"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Invite failed: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
  // -------------------------

  Future<void> _createGroup() async {
    if (_nameController.text.isEmpty) return;
    setState(() => _isLoading = true);

    try {
      // Gateway routes /api/groups to Expense Service
      final url = "${widget.baseUrl}/groups/create";
      List<int> finalMembers = [widget.userId, ..._selectedMemberIds];

      await ApiClient.create(widget.baseUrl).post(
        url,
        data: {
          "name": _nameController.text,
          "userId": widget.userId,
          "memberIds": finalMembers,
        },
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Group Created!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to create group"),
            backgroundColor: Colors.red,
          ),
        );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Create New Group")),
      body: Column(
        children: [
          // Header Section
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: "Group Name",
                    hintText: "e.g. Goa Trip",
                    prefixIcon: Icon(Icons.group_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Members",
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    // INVITE BUTTON
                    TextButton.icon(
                      onPressed: _showInviteDialog,
                      icon: const Icon(Icons.person_add),
                      label: const Text("Invite by Email"),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // List Section
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _allUsers.length,
                    separatorBuilder: (c, i) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final user = _allUsers[index];
                      final isSelected = _selectedMemberIds.contains(
                        user['id'],
                      );

                      return CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          user['name'],
                          style: theme.textTheme.bodyLarge,
                        ),
                        subtitle: Text(
                          user['email'],
                          style: theme.textTheme.bodySmall,
                        ),
                        value: isSelected,
                        activeColor: theme.colorScheme.primary,
                        secondary: CircleAvatar(
                          backgroundColor: theme.colorScheme.primaryContainer,
                          child: Text(
                            user['name'][0].toUpperCase(),
                            style: TextStyle(
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                        onChanged: (val) {
                          setState(() {
                            if (val == true) {
                              _selectedMemberIds.add(user['id']);
                            } else {
                              _selectedMemberIds.remove(user['id']);
                            }
                          });
                        },
                      );
                    },
                  ),
          ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton.icon(
                onPressed: _isLoading ? null : _createGroup,
                icon: const Icon(Icons.check),
                label: const Text(
                  "Create Group",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
