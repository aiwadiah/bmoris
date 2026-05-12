import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../widgets/admin_ui.dart';
import '../../widgets/bmoris_back_button.dart';

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  List<UserModel> _allAdmins = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAdmins();
  }

  Future<void> _loadAdmins() async {
    setState(() => _isLoading = true);
    try {
      final allUsers = await _firestoreService.getAllUsers();
      _allAdmins = allUsers.where((user) => user.isAdmin).toList();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading admins: $e')));
      }
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _editProfile(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    if (user == null) return;
    final nameController = TextEditingController(text: user.name);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Edit Profile', style: AdminUi.title()),
        content: Container(
          width: 400, // Fixed width to make it bigger
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: TextField(
            controller: nameController,
            decoration: adminInputDecoration(label: 'Name'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: AdminUi.muted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, nameController.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminUi.teal,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      await authProvider.updateProfile(name: result);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully')));
      }
    }
  }

  Future<void> _deleteAdmin(UserModel admin) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (admin.uid == authProvider.user?.uid) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You cannot delete your own account')));
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove Admin', style: AdminUi.title()),
        content: Text('Remove ${admin.name} from the admin role?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await _firestoreService.firestore.collection('users').doc(admin.uid).update({'role': 'user'});
        await _loadAdmins();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Admin removed successfully')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error removing admin: $e')));
        }
      }
    }
  }

  Future<void> _signOut() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      await authProvider.signOut();
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/login');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error signing out: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final currentUser = authProvider.user;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('User not found')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Green Header (from User Profile)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 60),
              decoration: const BoxDecoration(color: AdminUi.teal),
              child: Column(
                children: [
                  Row(
                    children: [
                      const BMorisBackButton.plain(color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        'Admin Profile',
                        style: AdminUi.headline(Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  CircleAvatar(
                    radius: 55,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white,
                      backgroundImage: currentUser.photoUrl != null &&
                              currentUser.photoUrl!.isNotEmpty
                          ? NetworkImage(currentUser.photoUrl!)
                          : null,
                      child: currentUser.photoUrl == null ||
                              currentUser.photoUrl!.isEmpty
                          ? const Icon(
                              Icons.person,
                              size: 50,
                              color: AdminUi.teal,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    currentUser.name,
                    style: AdminUi.title(Colors.white).copyWith(fontSize: 22),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Super Admin',
                      style: AdminUi.body(Colors.white).copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),

            // Content Area with Overlap
            Transform.translate(
              offset: const Offset(0, -30),
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 30, 24, 0),
                  child: Column(
                    children: [
                      // Admin Team Card (Keep this admin-specific feature)
                      AdminCard(
                        child: Column(
                          children: [
                            AdminSectionTitle(
                              'Admin Team',
                              trailing: Text('${_allAdmins.length} admins', style: AdminUi.caption()),
                            ),
                            const SizedBox(height: 12),
                            if (_allAdmins.isEmpty)
                              Text('No admin accounts found.', style: AdminUi.body(AdminUi.muted))
                            else
                              ..._allAdmins.map((admin) {
                                final isCurrentUser = admin.uid == currentUser.uid;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundColor: isCurrentUser ? const Color(0xFFEAD8A7) : AdminUi.mint,
                                        child: Text(
                                          admin.name.isEmpty ? '?' : admin.name[0].toUpperCase(),
                                          style: const TextStyle(fontWeight: FontWeight.w700, color: AdminUi.text),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    admin.name,
                                                    style: AdminUi.body(),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                if (isCurrentUser) ...[
                                                  const SizedBox(width: 8),
                                                  const AdminPill(label: 'You', selected: true),
                                                ],
                                              ],
                                            ),
                                            Text(admin.email, style: AdminUi.caption()),
                                          ],
                                        ),
                                      ),
                                      if (!isCurrentUser)
                                        IconButton(
                                          onPressed: () => _deleteAdmin(admin),
                                          icon: const Icon(Icons.delete_outline_rounded, color: AdminUi.danger),
                                        ),
                                    ],
                                  ),
                                );
                              }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Unified Menu Card (from User Profile)
                      Card(
                        color: Colors.white,
                        elevation: 4,
                        shadowColor: Colors.black.withValues(alpha: 0.05),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            _buildMenuItem(
                              'Edit Profile',
                              Icons.edit_outlined,
                              () => _editProfile(context),
                            ),
                            Divider(
                              height: 1,
                              thickness: 0.5,
                              color: Colors.grey.withValues(alpha: 0.2),
                              indent: 20,
                              endIndent: 20,
                            ),
                            _buildMenuItem(
                              'Logout',
                              Icons.logout_rounded,
                              _signOut,
                              color: AdminUi.danger,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    String title,
    IconData icon,
    VoidCallback onTap, {
    Color? color,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Icon(icon, color: color ?? AdminUi.teal, size: 26),
      title: Text(
        title,
        style: AdminUi.body().copyWith(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, size: 22, color: AdminUi.muted),
      onTap: onTap,
    );
  }
}
