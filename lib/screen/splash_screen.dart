import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  bool _isReady = false;
  late AnimationController _controller;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _progressAnimation = Tween<double>(begin: 0, end: 1).animate(_controller)
      ..addListener(() {
        setState(() {});
      });
    _controller.forward().then((_) {
      setState(() {
        _isReady = true;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _navigateToNext() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isAuthenticated) {
      if (authProvider.isAdmin) {
        Navigator.pushReplacementNamed(context, '/admin');
      } else {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background Gradient Glow
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.2),
                  radius: 0.8,
                  colors: [
                    const Color(0xFF00897B).withValues(alpha: 0.25),
                    Colors.white.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          
          // Subtle background icons (Simulated)
          Positioned(
            top: 50,
            left: 30,
            child: Icon(Icons.chat_bubble_outline, size: 40, color: Colors.black.withValues(alpha: 0.03)),
          ),
          Positioned(
            top: 80,
            right: 40,
            child: Icon(Icons.menu_book_outlined, size: 40, color: Colors.black.withValues(alpha: 0.03)),
          ),
          Positioned(
            top: 200,
            left: 50,
            child: Icon(Icons.menu_book_outlined, size: 30, color: Colors.black.withValues(alpha: 0.02)),
          ),
          Positioned(
            top: 250,
            right: 60,
            child: Icon(Icons.chat_bubble_outline, size: 24, color: Colors.black.withValues(alpha: 0.02)),
          ),
          Positioned(
            bottom: 100,
            left: 40,
            child: Icon(Icons.star_border, size: 40, color: Colors.black.withValues(alpha: 0.03)),
          ),
          Positioned(
            bottom: 150,
            right: 30,
            child: Icon(Icons.translate, size: 40, color: Colors.black.withValues(alpha: 0.03)),
          ),
          Positioned(
            bottom: 250,
            left: 80,
            child: Icon(Icons.chat_bubble_outline, size: 32, color: Colors.black.withValues(alpha: 0.02)),
          ),
          Positioned(
            bottom: 200,
            right: 100,
            child: Icon(Icons.menu_book_outlined, size: 36, color: Colors.black.withValues(alpha: 0.02)),
          ),
          
          Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 50),
                  // Bird Image
                  Image.asset(
                    'assets/bmorisbird.png',
                    height: 250,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.error_outline, size: 100, color: Colors.red);
                    },
                  ),
                  const SizedBox(height: 30),
                  // Title
                  Text(
                    'BMoris',
                    style: GoogleFonts.poppins(
                      fontSize: 56,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF00897B),
                      letterSpacing: -1,
                    ),
                  ),
                  // Subtitle
                  Text(
                    'Learn BM with confidence.',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 60),
                  
                  if (!_isReady) ...[
                    // Custom Progress Bar
                    Container(
                      width: 200,
                      height: 12,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2F1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Stack(
                        children: [
                          Container(
                            width: 200 * _progressAnimation.value,
                            height: 12,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFD54F),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Bottom Text
                    Text(
                      'Preparing your lessons...',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ] else
                    // Get Started Button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: ElevatedButton(
                        onPressed: _navigateToNext,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00897B),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 40),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                'Get Started!',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward_rounded, weight: 700),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
