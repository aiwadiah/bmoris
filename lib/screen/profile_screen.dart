import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../widgets/bmoris_back_button.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isEditing = false;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    if (user != null) {
      _nameController.text = user.name;
      _phoneController.text = user.phoneNumber ?? '';
      _emailController.text = user.email;
    }
    // Check and award any eligible badges
    WidgetsBinding.instance.addPostFrameCallback((_) {
      authProvider.checkAndAwardAllEligibleBadges();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user!;

    // Update name and phone
    await authProvider.updateProfile(
      name: _nameController.text.trim(),
      phoneNumber:
          _phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim(),
    );

    // Update email if changed
    if (_emailController.text.trim() != user.email) {
      final success = await authProvider.updateEmail(
        _emailController.text.trim(),
      );
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Email update failed. You may need to re-login and try again.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification email sent! Please check your inbox.'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    }

    setState(() {
      _isEditing = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    }
  }

  Future<void> _uploadProfilePicture() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    if (user == null) return;

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );

      if (image == null) return;

      setState(() {
        _isUploadingImage = true;
      });

      // Upload to Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_pictures')
          .child('${user.uid}.jpg');

      await storageRef.putFile(File(image.path));
      final photoUrl = await storageRef.getDownloadURL();

      // Update user profile
      await authProvider.updateProfile(photoUrl: photoUrl);

      setState(() {
        _isUploadingImage = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture updated successfully')),
        );
      }
    } catch (e) {
      setState(() {
        _isUploadingImage = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _resetPassword() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    if (user == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Reset Password'),
            content: Text('Send password reset email to ${user.email}?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Send'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      final success = await authProvider.sendPasswordResetEmail(user.email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Password reset email sent! Check your inbox.'
                  : 'Failed to send reset email. Try again.',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(

        leadingWidth: BMorisBackButton.plainLeadingWidth,
        leading: const BMorisBackButton.plain(color: Colors.white),
        title: const Text('Profile'),
        backgroundColor: const Color(0xFF00796B),
        foregroundColor: Colors.white,
      ),
      body: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          final user = auth.user;
          if (user == null) {
            return const Center(child: Text('User not found'));
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                // Green Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 60),
                  decoration: const BoxDecoration(color: Color(0xFF00796B)),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 55,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.2,
                            ),
                            child: CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.white,
                              backgroundImage:
                                  user.photoUrl != null &&
                                          user.photoUrl!.isNotEmpty
                                      ? NetworkImage(user.photoUrl!)
                                      : null,
                              child:
                                  user.photoUrl == null ||
                                          user.photoUrl!.isEmpty
                                      ? const Icon(
                                        Icons.person,
                                        size: 50,
                                        color: Color(0xFF00796B),
                                      )
                                      : null,
                            ),
                          ),
                          if (_isUploadingImage)
                            Positioned.fill(
                              child: CircleAvatar(
                                radius: 55,
                                backgroundColor: Colors.black54,
                                child: const CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap:
                                  _isUploadingImage
                                      ? null
                                      : _uploadProfilePicture,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.1,
                                      ),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Color(0xFF00796B),
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        user.name,
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Level ${user.currentLevel}',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
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
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(30),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 30, 24, 0),
                      child: Column(
                        children: [
                          // Stats Card
                          Card(
                            color: Colors.white,
                            elevation: 4,
                            shadowColor: Colors.black.withValues(alpha: 0.05),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                children: [
                                  Text(
                                    'Your Stats',
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: [
                                      _buildStatItem(
                                        'Level',
                                        '${user.currentLevel}',
                                        Icons.trending_up,
                                        const Color(0xFF00796B),
                                      ),
                                      _buildStatItem(
                                        'XP',
                                        '${user.xp}',
                                        Icons.star,
                                        Colors.orange,
                                      ),
                                      _buildStatItem(
                                        'Streak',
                                        '${user.streak}',
                                        Icons.local_fire_department,
                                        Colors.red,
                                      ),
                                      _buildStatItem(
                                        'Badges',
                                        '${user.badges.length}',
                                        Icons.military_tech,
                                        Colors.amber,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Badges Section
                          if (user.badges.isNotEmpty) ...[
                            Text(
                              'Achieved Badges',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 110,
                              child: Center(
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  physics: const BouncingScrollPhysics(),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children:
                                        user.badges.map((badge) {
                                          return Container(
                                            width: 110,
                                            margin: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                            ),
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              border: Border.all(
                                                color: Colors.amber.shade100,
                                                width: 1.5,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.amber
                                                      .withValues(alpha: 0.1),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ],
                                            ),
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                const Icon(
                                                  Icons.military_tech,
                                                  color: Colors.amber,
                                                  size: 36,
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  badge,
                                                  textAlign: TextAlign.center,
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                          ],

                          // Unified Menu Card
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
                                  () => Navigator.pushNamed(
                                    context,
                                    '/edit-profile',
                                  ),
                                ),
                                Divider(
                                  height: 1,
                                  thickness: 0.5,
                                  color: Colors.grey.withValues(alpha: 0.2),
                                  indent: 20,
                                  endIndent: 20,
                                ),
                                _buildMenuItem(
                                  'Reset Password',
                                  Icons.lock_reset,
                                  _resetPassword,
                                ),
                                Divider(
                                  height: 1,
                                  thickness: 0.5,
                                  color: Colors.grey.withValues(alpha: 0.2),
                                  indent: 20,
                                  endIndent: 20,
                                ),
                                _buildMenuItem(
                                  'Pronunciation History',
                                  Icons.history,
                                  () => Navigator.pushNamed(
                                    context,
                                    '/pronunciation-history',
                                  ),
                                ),
                                Divider(
                                  height: 1,
                                  thickness: 0.5,
                                  color: Colors.grey.withValues(alpha: 0.2),
                                  indent: 20,
                                  endIndent: 20,
                                ),
                                _buildMenuItem(
                                  'Quiz History',
                                  Icons.quiz,
                                  () => Navigator.pushNamed(
                                    context,
                                    '/quiz-history',
                                  ),
                                ),
                                Divider(
                                  height: 1,
                                  thickness: 0.5,
                                  color: Colors.grey.withValues(alpha: 0.2),
                                  indent: 20,
                                  endIndent: 20,
                                ),
                                _buildMenuItem(
                                  'Notifications',
                                  Icons.notifications,
                                  () => Navigator.pushNamed(
                                    context,
                                    '/notifications',
                                  ),
                                ),
                                Divider(
                                  height: 1,
                                  thickness: 0.5,
                                  color: Colors.grey.withValues(alpha: 0.2),
                                  indent: 20,
                                  endIndent: 20,
                                ),
                                _buildMenuItem(
                                  'Offline Lessons',
                                  Icons.download_done,
                                  () => Navigator.pushNamed(
                                    context,
                                    '/offline-lessons',
                                  ),
                                ),
                                Divider(
                                  height: 1,
                                  thickness: 0.5,
                                  color: Colors.grey.withValues(alpha: 0.2),
                                  indent: 20,
                                  endIndent: 20,
                                ),
                                _buildMenuItem(
                                  'Send Feedback',
                                  Icons.feedback,
                                  () =>
                                      Navigator.pushNamed(context, '/feedback'),
                                ),
                                Divider(
                                  height: 1,
                                  thickness: 0.5,
                                  color: Colors.grey.withValues(alpha: 0.2),
                                  indent: 20,
                                  endIndent: 20,
                                ),
                                _buildMenuItem('Logout', Icons.logout, () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder:
                                        (context) => AlertDialog(
                                          title: const Text('Logout'),
                                          content: const Text(
                                            'Are you sure you want to logout?',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed:
                                                  () => Navigator.pop(
                                                    context,
                                                    false,
                                                  ),
                                              child: const Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed:
                                                  () => Navigator.pop(
                                                    context,
                                                    true,
                                                  ),
                                              style: TextButton.styleFrom(
                                                foregroundColor: Colors.red,
                                              ),
                                              child: const Text('Logout'),
                                            ),
                                          ],
                                        ),
                                  );

                                  if (confirm == true && mounted) {
                                    await auth.signOut();
                                    if (mounted) {
                                      Navigator.pushReplacementNamed(
                                        context,
                                        '/login',
                                      );
                                    }
                                  }
                                }, color: Colors.redAccent),
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
          );
        },
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
        ),
      ],
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
      leading: Icon(icon, color: color ?? const Color(0xFF00796B), size: 26),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          color: color,
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, size: 22, color: Colors.grey),
      onTap: onTap,
    );
  }
}
