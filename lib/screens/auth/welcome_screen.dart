import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  // FundWeave Brand Colors
  final Color _primaryBlue = const Color(0xFF0F4CFF);
  final Color _primaryTeal = const Color(0xFF14D8C4);
  final Color _darkNavy = const Color(0xFF0A1F44);
  final Color _darkerNavy = const Color(0xFF051126);

  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _checkIfAlreadySeen();
  }

  Future<void> _checkIfAlreadySeen() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeen = prefs.getBool('has_seen_welcome') ?? false;

    if (hasSeen && mounted) {
      // Already seen before — skip welcome, go straight to login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } else {
      // First time — show the welcome screen
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _onGetStarted() async {
    // Mark welcome as seen so it never shows again
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_welcome', true);

    if (!mounted) return;

    // pushReplacement so back button cannot return to welcome
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show a blank dark screen while checking SharedPreferences
    // This avoids a white flash before redirecting
    if (_checking) {
      return const Scaffold(
        backgroundColor: Color(0xFF051126),
        body: SizedBox.shrink(),
      );
    }

    return Scaffold(
      body: Container(
        width: double.infinity,
        // Premium Radial Gradient Background
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [_darkNavy, _darkerNavy],
            center: Alignment.center,
            radius: 1.2,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Column(
              children: [
                const Spacer(),

                // ── Animated Logo & Slogan ──
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 1200),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(0, 30 * (1 - value)),
                      child: Opacity(
                        opacity: value,
                        child: Column(
                          children: [
                            // Your app logo
                            Image.asset(
                              'assets/images/logo_full.png',
                              width: 250,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(height: 24),
                            Text(
                              "Save together, grow together.",
                              style: TextStyle(
                                color: _primaryTeal,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const Spacer(),

                // ── Animated Get Started Button ──
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: Opacity(
                        opacity: value,
                        child: child,
                      ),
                    );
                  },
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 8,
                        shadowColor: _primaryBlue.withValues(alpha: 0.5),
                      ),
                      onPressed: _onGetStarted,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Get Started',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_rounded, size: 20),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}