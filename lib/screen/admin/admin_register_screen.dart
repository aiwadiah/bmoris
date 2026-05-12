import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../widgets/admin_ui.dart';
import '../../widgets/bmoris_back_button.dart';

class AdminRegisterScreen extends StatefulWidget {
  const AdminRegisterScreen({super.key});

  @override
  State<AdminRegisterScreen> createState() => _AdminRegisterScreenState();
}

class _AdminRegisterScreenState extends State<AdminRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _adminCodeController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  static const String _adminSecretCode = 'BMORIS_ADMIN_2024';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _adminCodeController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_adminCodeController.text.trim() != _adminSecretCode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid admin code'), backgroundColor: Colors.red),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.signUpAsAdmin(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      name: _nameController.text.trim(),
    );
    if (success && mounted) {
      Navigator.pushReplacementNamed(context, '/admin');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      backgroundColor: Colors.white,
      child: AdminShell(
        title: 'Admin Register',
        subtitle: 'Create a controlled admin account for BMoris operations.',
        leading: const BMorisBackButton(),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              AdminCard(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('New admin account', style: AdminUi.title()),
                              const SizedBox(height: 6),
                              Text(
                                'Use the secure admin code to unlock registration.',
                                style: AdminUi.body(AdminUi.muted),
                              ),
                            ],
                          ),
                        ),
                        Image.asset(
                          'assets/bmorisbird3.png',
                          width: 62,
                          height: 62,
                          fit: BoxFit.contain,
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Consumer<AuthProvider>(
                      builder: (context, auth, _) {
                        if (auth.error == null) return const SizedBox.shrink();
                        return Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF1F1),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFF0CACA)),
                          ),
                          child: Text(auth.error!, style: AdminUi.body(AdminUi.danger)),
                        );
                      },
                    ),
                    TextFormField(
                      controller: _nameController,
                      decoration: adminInputDecoration(
                        label: 'Full name',
                        prefixIcon: const Icon(Icons.person_outline_rounded),
                      ),
                      validator: (value) => value == null || value.isEmpty ? 'Please enter your name' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: adminInputDecoration(
                        label: 'Email',
                        prefixIcon: const Icon(Icons.mail_outline_rounded),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Please enter email';
                        if (!value.contains('@')) return 'Please enter a valid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: adminInputDecoration(
                        label: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                      ).copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Please enter password';
                        if (value.length < 6) return 'Password must be at least 6 characters';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      decoration: adminInputDecoration(
                        label: 'Confirm password',
                        prefixIcon: const Icon(Icons.verified_user_outlined),
                      ).copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(_obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                          onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Please confirm password';
                        if (value != _passwordController.text) return 'Passwords do not match';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _adminCodeController,
                      decoration: adminInputDecoration(
                        label: 'Admin secret code',
                        prefixIcon: const Icon(Icons.key_rounded),
                      ),
                      validator: (value) => value == null || value.isEmpty ? 'Please enter admin code' : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Consumer<AuthProvider>(
                builder: (context, auth, _) {
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: auth.isLoading ? null : _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AdminUi.teal,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child:
                          auth.isLoading
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                              : Text('Register Admin', style: AdminUi.body(Colors.white)),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                child: Text('Back to Login', style: AdminUi.body(AdminUi.teal)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
