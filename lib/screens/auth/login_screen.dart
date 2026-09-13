import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/providers.dart';
import '../../widgets/shared_widgets.dart';
import 'register_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final usernameCtrl = TextEditingController();
  final passCtrl     = TextEditingController();
  bool   obscurePass = true;
  bool   isLoading   = false;
  String error       = '';

  // Shows exactly what was sent to Firebase — tap the info icon to see
  String _debugEmail = '';

  static const Color _primaryBlue = Color(0xFF0F4CFF);
  static const Color _primaryTeal = Color(0xFF14D8C4);
  static const Color _darkNavy    = Color(0xFF0A1F44);

  String get _dummyEmail =>
      '${usernameCtrl.text.trim().toLowerCase().replaceAll(' ', '')}@myagency.com';

  @override
  void dispose() {
    usernameCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }

  Future<void> login() async {
    final username = usernameCtrl.text.trim();

    if (username.isEmpty || passCtrl.text.trim().isEmpty) {
      setState(() => error = 'Please fill all fields.');
      return;
    }
    if (username.contains(' ')) {
      setState(() => error = 'Username must not contain spaces.');
      return;
    }

    final emailToSend = _dummyEmail;
    setState(() {
      isLoading    = true;
      error        = '';
      _debugEmail  = emailToSend; // visible in debug banner
    });

    // ── Direct Firebase call so we can see the raw error code ──
    try {
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email:    emailToSend,
            password: passCtrl.text.trim(),
          )
          .timeout(const Duration(seconds: 15));

      if (!mounted) return;

      // Check for rejection via Firestore role
      final userDoc = await ref
          .read(authServiceProvider)
          .login(emailToSend, passCtrl.text.trim());

      // We already signed in above; userDoc is just for role check
      if (userDoc.containsKey('error') &&
          userDoc['error'] == 'rejected') {
        await FirebaseAuth.instance.signOut();
        setState(() {
          error     = '❌ Your shop registration was rejected.';
          isLoading = false;
        });
        return;
      }

      if (!mounted) return;
      setState(() => isLoading = false);

      // Pop back — main.dart StreamBuilder shows dashboard
      Navigator.of(context).popUntil((route) => route.isFirst);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        // Show full code + message so we can diagnose exactly
        error     = '${e.code}: ${e.message ?? 'Auth failed'}';
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error     = 'Error: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Branding ──
              Center(
                child: Column(
                  children: [
                    Image.asset(
                      'assets/images/logo_full.png',
                      width: 180,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _darkNavy,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.account_balance,
                            color: _primaryTeal, size: 50),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text('Welcome Back',
                        style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: _darkNavy,
                            letterSpacing: -0.5)),
                    const SizedBox(height: 8),
                    const Text('Secure access to your financial pools',
                        style: TextStyle(color: Colors.grey, fontSize: 14)),
                  ],
                ),
              ),

              const SizedBox(height: 48),

              // ── Debug banner — remove after fixing ──
              if (_debugEmail.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(children: [
                    const Icon(Icons.bug_report,
                        size: 14, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Attempting: $_debugEmail',
                        style: const TextStyle(
                            fontSize: 11, color: Colors.grey),
                      ),
                    ),
                  ]),
                ),

              // ── Form ──
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 20,
                        offset: const Offset(0, 10)),
                  ],
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: Column(
                  children: [
                    AppTextField(
                      controller: usernameCtrl,
                      label: 'Username',
                      icon: Icons.alternate_email,
                      keyboardType: TextInputType.text,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: passCtrl,
                      label: 'Password',
                      icon: Icons.lock_outline,
                      obscureText: obscurePass,
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscurePass
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: Colors.grey.shade500,
                        ),
                        onPressed: () =>
                            setState(() => obscurePass = !obscurePass),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {},
                        child: const Text('Forgot Password?',
                            style: TextStyle(
                                color: _primaryBlue,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    LoadingButton(
                      isLoading: isLoading,
                      onPressed: login,
                      label: 'Sign In',
                      icon: Icons.login,
                      color: _primaryBlue,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              if (error.isNotEmpty) ...[
                ErrorMessage(message: error),
                const SizedBox(height: 16),
              ],

              Center(
                child: TextButton(
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => const RegisterScreen())),
                  child: const Text.rich(TextSpan(
                    text: "Don't have an account? ",
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                    children: [
                      TextSpan(
                        text: 'Create Account',
                        style: TextStyle(
                            color: _primaryBlue,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  )),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}