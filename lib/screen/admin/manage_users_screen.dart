import 'package:flutter/material.dart';

import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/admin_ui.dart';
import '../../widgets/bmoris_back_button.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  List<UserModel> _users = [];
  bool _isLoading = true;
  String _filterRole = 'all';

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final snapshot = await _firestoreService.firestore.collection('users').orderBy('createdAt', descending: true).get();
      _users = snapshot.docs.map((doc) => UserModel.fromMap(doc.data(), doc.id)).toList();
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  List<UserModel> get _filteredUsers {
    final query = _searchController.text.trim().toLowerCase();
    return _users.where((user) {
      if (_filterRole != 'all' && user.role != _filterRole) return false;
      if (query.isEmpty) return true;
      return user.name.toLowerCase().contains(query) || user.email.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> _deleteUser(UserModel user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete User', style: AdminUi.title()),
        content: Text('Are you sure you want to delete "${user.name}"?', style: AdminUi.body()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
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
        await _firestoreService.firestore.collection('users').doc(user.uid).delete();
        await _loadUsers();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting user: $e')));
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
        await _firestoreService.syncWeeklyXpFromAdminDelta(user: user, updates: result);
        await _loadUsers();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  Future<void> _toggleAdminRole(UserModel user) async {
    final newRole = user.role == 'admin' ? 'user' : 'admin';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(newRole == 'admin' ? 'Make Admin' : 'Remove Admin', style: AdminUi.title()),
        content: Text(
          newRole == 'admin'
              ? 'Grant admin privileges to "${user.name}"?'
              : 'Remove admin privileges from "${user.name}"?',
          style: AdminUi.body(),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirm')),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await _firestoreService.firestore.collection('users').doc(user.uid).update({'role': newRole});
        await _loadUsers();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredUsers = _filteredUsers;
    return AdminPage(
      child:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : AdminShell(
                title: 'Manage Users',
                subtitle: '${_users.length} total accounts in BMoris.',
                leading: const BMorisBackButton(),
                child: Column(
                  children: [
                    AdminSearchField(controller: _searchController, hintText: 'Search by name or email'),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        AdminPill(label: 'All', selected: _filterRole == 'all', onTap: () => setState(() => _filterRole = 'all')),
                        AdminPill(label: 'Learner', selected: _filterRole == 'user', onTap: () => setState(() => _filterRole = 'user')),
                        AdminPill(label: 'Admin', selected: _filterRole == 'admin', onTap: () => setState(() => _filterRole = 'admin')),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (filteredUsers.isEmpty)
                      const AdminEmptyState(
                        icon: Icons.people_outline_rounded,
                        title: 'No users found',
                        subtitle: 'Try another search or switch the active role filter.',
                      )
                    else
                      ...filteredUsers.map((user) => AdminCard(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ExpansionTile(
                          tilePadding: EdgeInsets.zero,
                          childrenPadding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AdminUi.radius)),
                          leading: CircleAvatar(
                            backgroundColor: user.isAdmin ? const Color(0xFFEAD8A7) : AdminUi.teal,
                            child: Icon(
                              user.isAdmin ? Icons.shield_rounded : Icons.person_rounded,
                              color: user.isAdmin ? AdminUi.text : Colors.white,
                            ),
                          ),
                          title: Text(user.name, style: AdminUi.body()),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user.email, style: AdminUi.caption()),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  AdminPill(label: user.isAdmin ? 'Admin' : 'Learner', selected: user.isAdmin),
                                  const SizedBox(width: 8),
                                  Text('Level ${user.currentLevel}', style: AdminUi.caption()),
                                  const SizedBox(width: 8),
                                  Text('${user.xp} XP', style: AdminUi.caption(const Color(0xFFE59B2F))),
                                ],
                              ),
                            ],
                          ),
                          children: [
                            const Divider(height: 24, color: AdminUi.border),
                            _detailRow('Phone', user.phoneNumber ?? 'Not set'),
                            _detailRow('Streak', '${user.streak} days'),
                            _detailRow('Badges', '${user.badges.length}'),
                            _detailRow('Joined', '${user.createdAt.day}/${user.createdAt.month}/${user.createdAt.year}'),
                            const SizedBox(height: 14),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                AdminActionButton.primary(label: 'Edit', icon: Icons.edit_outlined, onPressed: () => _editUser(user)),
                                AdminActionButton.outlined(
                                  label: user.isAdmin ? 'Remove Admin' : 'Make Admin',
                                  icon: user.isAdmin ? Icons.person_outline_rounded : Icons.shield_outlined,
                                  onPressed: () => _toggleAdminRole(user),
                                ),
                                AdminActionButton.danger(label: 'Delete', icon: Icons.delete_outline_rounded, onPressed: () => _deleteUser(user)),
                              ],
                            ),
                          ],
                        ),
                      )),
                  ],
                ),
              ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(width: 84, child: Text(label, style: AdminUi.caption())),
          Expanded(child: Text(value, style: AdminUi.body())),
        ],
      ),
    );
  }
}

class _UserFormDialog extends StatefulWidget {
  const _UserFormDialog({required this.user});

  final UserModel user;

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
      title: Text('Edit User', style: AdminUi.title()),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: adminInputDecoration(label: 'Name'),
                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: adminInputDecoration(label: 'Email'),
                enabled: false,
              ),
              const SizedBox(height: 12),
              TextFormField(controller: _phoneController, decoration: adminInputDecoration(label: 'Phone Number')),
              const SizedBox(height: 12),
              TextFormField(
                controller: _xpController,
                keyboardType: TextInputType.number,
                decoration: adminInputDecoration(label: 'XP'),
                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _streakController,
                keyboardType: TextInputType.number,
                decoration: adminInputDecoration(label: 'Streak'),
                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: _level,
                decoration: adminInputDecoration(label: 'Level'),
                items: List.generate(50, (i) => i + 1).map((level) {
                  return DropdownMenuItem(value: level, child: Text('Level $level'));
                }).toList(),
                onChanged: (value) => setState(() => _level = value!),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, {
                'name': _nameController.text.trim(),
                'phoneNumber': _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
                'xp': int.parse(_xpController.text.trim()),
                'streak': int.parse(_streakController.text.trim()),
                'currentLevel': _level,
              });
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: AdminUi.teal),
          child: const Text('Save', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
