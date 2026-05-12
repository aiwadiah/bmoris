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
        title: Text('Edit Profile', style: AdminUi.title()),
        content: TextField(
          controller: nameController,
          decoration: adminInputDecoration(label: 'Name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, nameController.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: AdminUi.teal),
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
    final currentUser = context.watch<AuthProvider>().user;
    return AdminPage(
      child:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : AdminShell(
                title: 'Admin Profile',
                subtitle: 'Manage your admin account and team access.',
                leading: const BMorisBackButton(),
                child: Column(
                  children: [
                    if (currentUser != null)
                      AdminCard(
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 34,
                              backgroundColor: AdminUi.teal,
                              child: Text(
                                currentUser.name.isEmpty ? 'A' : currentUser.name[0].toUpperCase(),
                                style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(currentUser.name, style: AdminUi.title()),
                            const SizedBox(height: 4),
                            Text(currentUser.email, style: AdminUi.caption()),
                            const SizedBox(height: 10),
                            const AdminPill(label: 'Super Admin', selected: true),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () => _editProfile(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AdminUi.teal,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size.fromHeight(46),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                                child: Text('Edit Profile', style: AdminUi.body(Colors.white)),
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _signOut,
                                icon: const Icon(Icons.logout_rounded, size: 18),
                                label: Text('Log Out', style: AdminUi.body(AdminUi.danger)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AdminUi.danger,
                                  side: const BorderSide(color: AdminUi.danger),
                                  minimumSize: const Size.fromHeight(46),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 18),
                    AdminCard(
                      child: Column(
                        children: [
                          AdminSectionTitle('Admin Team', trailing: Text('${_allAdmins.length} admins', style: AdminUi.caption())),
                          const SizedBox(height: 12),
                          if (_allAdmins.isEmpty)
                            Text('No admin accounts found.', style: AdminUi.body(AdminUi.muted))
                          else
                            ..._allAdmins.map((admin) {
                              final isCurrentUser = admin.uid == currentUser?.uid;
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
                  ],
                ),
              ),
    );
  }
}
