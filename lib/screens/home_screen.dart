import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/api_client.dart'; // Ensure you use ApiClient for auth
import 'login_screen.dart';
import 'create_group_screen.dart';
import 'group_detail_screen.dart';
import 'analysis_screen.dart';

class HomeScreen extends StatefulWidget {
  final String baseUrl;
  final int userId;
  final String userName;

  const HomeScreen({
    super.key,
    required this.baseUrl,
    required this.userId,
    required this.userName,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> _myGroups = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchGroups();
  }

  Future<void> _fetchGroups() async {
    try {
      final groupUrl = "${widget.baseUrl}/groups";

      // Use ApiClient to ensure Token is attached
      final response = await ApiClient.create(
        widget.baseUrl,
      ).get('$groupUrl/user/${widget.userId}');

      if (mounted) {
        setState(() {
          _myGroups = response.data;
          _isLoading = false;
        });
      }
    } catch (e) {
      print(e);
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => LoginScreen(baseUrl: widget.baseUrl),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text("My Groups")),

      // --- MODERN DRAWER ---
      drawer: Drawer(
        backgroundColor: theme.colorScheme.surface,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(color: theme.colorScheme.primary),
              accountName: Text(
                widget.userName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onPrimary,
                ),
              ),
              accountEmail: Text(
                "Logged In",
                style: TextStyle(
                  color: theme.colorScheme.onPrimary.withOpacity(0.8),
                ),
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: theme.colorScheme.onPrimary,
                child: Text(
                  widget.userName.isNotEmpty
                      ? widget.userName[0].toUpperCase()
                      : "U",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ),

            ListTile(
              leading: Icon(
                Icons.pie_chart_outline,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              title: const Text("Spend Analysis"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AnalysisScreen(
                      baseUrl: widget.baseUrl,
                      userId: widget.userId,
                    ),
                  ),
                );
              },
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Divider(color: theme.colorScheme.outlineVariant),
            ),

            ListTile(
              leading: Icon(
                Icons.group_add_outlined,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              title: const Text("Create New Group"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreateGroupScreen(
                      baseUrl: widget.baseUrl,
                      userId: widget.userId,
                    ),
                  ),
                ).then((_) => _fetchGroups());
              },
            ),
            ListTile(
              leading: Icon(Icons.logout, color: theme.colorScheme.error),
              title: Text(
                "Logout",
                style: TextStyle(color: theme.colorScheme.error),
              ),
              onTap: _logout,
            ),
          ],
        ),
      ),

      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _myGroups.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.groups_3_outlined,
                    size: 64,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text("No groups yet", style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CreateGroupScreen(
                            baseUrl: widget.baseUrl,
                            userId: widget.userId,
                          ),
                        ),
                      );
                      _fetchGroups();
                    },
                    icon: const Icon(Icons.add),
                    label: const Text("Create One"),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _myGroups.length,
              itemBuilder: (context, index) {
                final group = _myGroups[index];

                // Modern Card Design
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 0, // Material 3 uses color for elevation mostly
                  color:
                      theme.colorScheme.surfaceContainer, // Subtle background
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GroupDetailScreen(
                            baseUrl: widget.baseUrl,
                            userId: widget.userId,
                            groupId: group['id'],
                            groupName: group['name'],
                          ),
                        ),
                      ).then((_) => _fetchGroups());
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          // Group Icon Container
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.group_outlined,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(width: 16),

                          // Text Content
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  group['name'],
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Tap to view expenses",
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Icon(
                            Icons.chevron_right,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateGroupScreen(
                baseUrl: widget.baseUrl,
                userId: widget.userId,
              ),
            ),
          );
          _fetchGroups();
        },
        label: const Text("New Group"),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
