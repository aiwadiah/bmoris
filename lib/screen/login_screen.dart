import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (success && mounted) {
      if (authProvider.isAdmin) {
        Navigator.pushReplacementNamed(context, '/admin');
      } else {
        Navigator.pushReplacementNamed(context, '/home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Header Background Gradient
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 300,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFFE0F2F1).withValues(alpha: 0.5),
                    Colors.white,
                  ],
                ),
              ),
            ),
          ),
          
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  // Header Content (Text Only)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back!',
                          style: GoogleFonts.poppins(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF00695C),
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Continue your pronunciation practice and build speaking confidence.',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 100),

                  // Bird and Card Stack
                  Stack(
                    alignment: Alignment.topCenter,
                    clipBehavior: Clip.none,
                    children: [
                      // Larger Bird mascot (Positioned to overlap)
                      Positioned(
                        top: -110, // Moved down from -150 to avoid text overlap
                        right: 15,
                        child: Image.asset(
                          'assets/bmorisbird2.png',
                          height: 220,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.face_retouching_natural, size: 100, color: Color(0xFF00695C));
                          },
                        ),
                      ),
                      
                      // Form Card
                      Container(
                        margin: const EdgeInsets.fromLTRB(24, 60, 24, 0),
                        padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Email',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: GoogleFonts.poppins(),
                            decoration: InputDecoration(
                              hintText: 'Email',
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade200),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Please enter your email';
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          
                          Text(
                            'Password',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: GoogleFonts.poppins(),
                            decoration: InputDecoration(
                              hintText: 'Password',
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade200),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                  color: Colors.grey,
                                  size: 20,
                                ),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Please enter your password';
                              return null;
                            },
                          ),
                          
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                // Forgot password logic
                              },
                              child: Text(
                                'Forgot password?',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: const Color(0xFF00897B),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          Consumer<AuthProvider>(
                            builder: (context, auth, _) {
                              return SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: auth.isLoading ? null : _login,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF00897B),
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size.fromHeight(50), // Matches textfield height
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: auth.isLoading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        )
                                      : Text(
                                          'Login',
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                              );
                            },
                          ),
                          
                        ],
                      ),
                    ),
                  ),
                ],
              ),
                  
                  const SizedBox(height: 32),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Provider.of<AuthProvider>(context, listen: false).clearError();
                        Navigator.pushNamed(context, '/register');
                      },
                      child: Text(
                        'Register a new account',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF00897B),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
