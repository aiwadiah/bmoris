import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/bmoris_back_button.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  List<UserModel> _users = [];
  bool _isLoading = true;
  String _filterRole = 'all';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final snapshot =
          await _firestoreService.firestore
              .collection('users')
              .orderBy('createdAt', descending: true)
              .get();
      _users =
          snapshot.docs
              .map((doc) => UserModel.fromMap(doc.data(), doc.id))
              .toList();
    } catch (e) {
      // Handle error
    }
    setState(() => _isLoading = false);
  }

  List<UserModel> get _filteredUsers {
    if (_filterRole == 'all') {
      return _users;
    }
    return _users.where((user) => user.role == _filterRole).toList();
  }

  Future<void> _deleteUser(UserModel user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete User'),
            content: Text('Are you sure you want to delete "${user.name}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      try {
        await _firestoreService.firestore
            .collection('users')
            .doc(user.uid)
            .delete();
        _loadUsers();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting user: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _editUser(UserModel user) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _UserFormDialog(user: user),
    );

    if (result != null) {
      try {
        await _firestoreService.syncWeeklyXpFromAdminDelta(
          user: user,
          updates: result,
        );
        _loadUsers();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _toggleAdminRole(UserModel user) async {
    final newRole = user.role == 'admin' ? 'user' : 'admin';
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(newRole == 'admin' ? 'Make Admin' : 'Remove Admin'),
            content: Text(
              newRole == 'admin'
                  ? 'Grant admin privileges to "${user.name}"?'
                  : 'Remove admin privileges from "${user.name}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Confirm'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      try {
        await _firestoreService.firestore
            .collection('users')
            .doc(user.uid)
            .update({'role': newRole});
        _loadUsers();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                newRole == 'admin'
                    ? 'Admin privileges granted'
                    : 'Admin privileges removed',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredUsers = _filteredUsers;

    return Scaffold(
      appBar: AppBar(
        leading: const BMorisBackButton(),
        title: const Text('Manage Users'),
        backgroundColor: const Color(0xFF00796B),
        foregroundColor: Colors.white,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  // Filter Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.grey.shade100,
                    child: Row(
                      children: [
                        const Text(
                          'Filter by Role:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SegmentedButton<String>(
                            segments: const [
                              ButtonSegment(value: 'all', label: Text('All')),
                              ButtonSegment(
                                value: 'user',
                                label: Text('Users'),
                              ),
                              ButtonSegment(
                                value: 'admin',
                                label: Text('Admins'),
                              ),
                            ],
                            selected: {_filterRole},
                            onSelectionChanged: (Set<String> newSelection) {
                              setState(() {
                                _filterRole = newSelection.first;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Users List
                  Expanded(
                    child:
                        filteredUsers.isEmpty
                            ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.people_outline,
                                    size: 80,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'No users found',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            )
                            : RefreshIndicator(
                              onRefresh: _loadUsers,
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: filteredUsers.length,
                                itemBuilder: (context, index) {
                                  final user = filteredUsers[index];
                                  return _buildUserCard(user);
                                },
                              ),
                            ),
                  ),
                ],
              ),
    );
  }

  Widget _buildUserCard(UserModel user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor:
              user.isAdmin ? Colors.orange : const Color(0xFF00796B),
          child: Icon(
            user.isAdmin ? Icons.admin_panel_settings : Icons.person,
            color: Colors.white,
          ),
        ),
        title: Text(user.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email),
            const SizedBox(height: 4),
            Row(
              children: [
                Chip(
                  label: Text(user.role.toUpperCase()),
                  backgroundColor:
                      user.isAdmin
                          ? Colors.orange.shade50
                          : Colors.blue.shade50,
                  labelStyle: const TextStyle(fontSize: 10),
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(width: 8),
                Text(
                  'Level ${user.currentLevel}',
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(width: 8),
                Text(
                  '${user.xp} XP',
                  style: const TextStyle(fontSize: 12, color: Colors.amber),
                ),
              ],
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Phone', user.phoneNumber ?? 'Not set'),
                _buildInfoRow('Streak', '${user.streak} days'),
                _buildInfoRow('Badges', '${user.badges.length}'),
                _buildInfoRow(
                  'Joined',
                  '${user.createdAt.day}/${user.createdAt.month}/${user.createdAt.year}',
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _editUser(user),
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Edit', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _toggleAdminRole(user),
                      icon: Icon(
                        user.isAdmin
                            ? Icons.person
                            : Icons.admin_panel_settings,
                        size: 16,
                      ),
                      label: Text(
                        user.isAdmin ? 'Remove Admin' : 'Make Admin',
                        style: const TextStyle(fontSize: 12),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _deleteUser(user),
                      icon: const Icon(Icons.delete, size: 16),
                      label: const Text(
                        'Delete',
                        style: TextStyle(fontSize: 12),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _UserFormDialog extends StatefulWidget {
  final UserModel user;

  const _UserFormDialog({required this.user});

  @override
  State<_UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<_UserFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _xpController = TextEditingController();
  final _streakController = TextEditingController();
  int _level = 1;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.user.name;
    _emailController.text = widget.user.email;
    _phoneController.text = widget.user.phoneNumber ?? '';
    _xpController.text = widget.user.xp.toString();
    _streakController.text = widget.user.streak.toString();
    _level = widget.user.currentLevel;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _xpController.dispose();
    _streakController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit User'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                enabled: false,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number (Optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _xpController,
                decoration: const InputDecoration(
                  labelText: 'XP',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _streakController,
                decoration: const InputDecoration(
                  labelText: 'Streak',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: _level,
                decoration: const InputDecoration(
                  labelText: 'Level',
                  border: OutlineInputBorder(),
                ),
                items:
                    List.generate(50, (i) => i + 1)
                        .map(
                          (level) => DropdownMenuItem(
                            value: level,
                            child: Text('Level $level'),
                          ),
                        )
                        .toList(),
                onChanged: (value) {
                  setState(() {
                    _level = value!;
                  });
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, {
                'name': _nameController.text.trim(),
                'phoneNumber':
                    _phoneController.text.trim().isEmpty
                        ? null
                        : _phoneController.text.trim(),
                'xp': int.parse(_xpController.text.trim()),
                'streak': int.parse(_streakController.text.trim()),
                'currentLevel': _level,
              });
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00796B),
            foregroundColor: Colors.white,
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
