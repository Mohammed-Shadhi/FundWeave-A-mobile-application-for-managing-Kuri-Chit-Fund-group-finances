import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/user_model.dart';
import '../../widgets/shared_widgets.dart';
import '../../services/shop_service.dart';
import '../../providers/providers.dart';

import 'login_screen.dart';

// ── Country Code Data ──
class _Country {
  final String name;
  final String flag;
  final String dialCode;
  const _Country(this.name, this.flag, this.dialCode);
}

const List<_Country> _countries = [
  _Country('India',                '🇮🇳', '+91'),
  _Country('United States',        '🇺🇸', '+1'),
  _Country('United Kingdom',       '🇬🇧', '+44'),
  _Country('United Arab Emirates', '🇦🇪', '+971'),
  _Country('Saudi Arabia',         '🇸🇦', '+966'),
  _Country('Canada',               '🇨🇦', '+1'),
  _Country('Australia',            '🇦🇺', '+61'),
  _Country('Germany',              '🇩🇪', '+49'),
  _Country('France',               '🇫🇷', '+33'),
  _Country('Singapore',            '🇸🇬', '+65'),
  _Country('Malaysia',             '🇲🇾', '+60'),
  _Country('Bangladesh',           '🇧🇩', '+880'),
  _Country('Pakistan',             '🇵🇰', '+92'),
  _Country('Sri Lanka',            '🇱🇰', '+94'),
  _Country('Nepal',                '🇳🇵', '+977'),
  _Country('Qatar',                '🇶🇦', '+974'),
  _Country('Kuwait',               '🇰🇼', '+965'),
  _Country('Bahrain',              '🇧🇭', '+973'),
  _Country('Oman',                 '🇴🇲', '+968'),
  _Country('South Africa',         '🇿🇦', '+27'),
];

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  // ── Member (Basic) Text Controllers ──
  final usernameCtrl    = TextEditingController(); // replaces emailCtrl
  final passCtrl        = TextEditingController();
  final nameCtrl        = TextEditingController();
  final phoneCtrl       = TextEditingController();
  final addressCtrl     = TextEditingController();

  // ── Admin (Shop) Text Controllers ──
  final shopNameCtrl    = TextEditingController();
  final shopAddressCtrl = TextEditingController();
  final mobile1Ctrl     = TextEditingController();
  final mobile2Ctrl     = TextEditingController();

  // ── Admin (Payment) Text Controllers ──
  final upiIdCtrl         = TextEditingController();
  final accountNameCtrl   = TextEditingController();
  final accountNumberCtrl = TextEditingController();
  final ifscCtrl          = TextEditingController();
  final bankNameCtrl      = TextEditingController();

  // ── Country code selection (default: India) ──
  _Country _selectedCountry = _countries.first;

  bool   obscurePass   = true;
  bool   isLoading     = false;
  String error         = '';
  String _selectedRole = 'member';

  // ── OTP state ──
  String? _verificationId;

  // FundWeave Brand Colors
  static const Color _primaryBlue = Color(0xFF0F4CFF);
  static const Color _darkNavy    = Color(0xFF0A1F44);

  /// Converts the username to the hidden Firebase Auth email.
  /// e.g. "JohnDoe" → "johndoe@myagency.com"
  String get _dummyEmail =>
      '${usernameCtrl.text.trim().toLowerCase().replaceAll(' ', '')}@myagency.com';

  /// Full E.164 phone number used for Firebase, e.g. +919876543210
  String get _fullPhone =>
      '${_selectedCountry.dialCode}${phoneCtrl.text.trim()}';

  @override
  void dispose() {
    usernameCtrl.dispose();
    passCtrl.dispose();
    nameCtrl.dispose();
    phoneCtrl.dispose();
    addressCtrl.dispose();
    shopNameCtrl.dispose();
    shopAddressCtrl.dispose();
    mobile1Ctrl.dispose();
    mobile2Ctrl.dispose();
    upiIdCtrl.dispose();
    accountNameCtrl.dispose();
    accountNumberCtrl.dispose();
    ifscCtrl.dispose();
    bankNameCtrl.dispose();
    super.dispose();
  }

  // ── Country picker bottom sheet ──
  Future<void> _pickCountry() async {
    final TextEditingController filterCtrl = TextEditingController();
    List<_Country> filtered = List.from(_countries);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.65,
            maxChildSize: 0.9,
            builder: (_, scrollCtrl) => Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Select Country Code',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: _darkNavy)),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: filterCtrl,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Search country...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 0, horizontal: 16),
                    ),
                    onChanged: (val) {
                      setSheet(() {
                        filtered = _countries
                            .where((c) =>
                                c.name.toLowerCase().contains(val.toLowerCase()) ||
                                c.dialCode.contains(val))
                            .toList();
                      });
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    controller: scrollCtrl,
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final country = filtered[i];
                      final isSelected =
                          country.dialCode == _selectedCountry.dialCode &&
                          country.name == _selectedCountry.name;
                      return ListTile(
                        leading: Text(country.flag,
                            style: const TextStyle(fontSize: 24)),
                        title: Text(country.name,
                            style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal)),
                        trailing: Text(country.dialCode,
                            style: TextStyle(
                                color: isSelected
                                    ? _primaryBlue
                                    : Colors.grey.shade600,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal)),
                        selected: isSelected,
                        selectedTileColor: _primaryBlue.withOpacity(0.05),
                        onTap: () {
                          setState(() => _selectedCountry = country);
                          Navigator.pop(ctx);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── STEP 1 · Validate form then trigger phone verification ──
  Future<void> _startVerification() async {
    final username = usernameCtrl.text.trim();

    // Username validations: non-empty and no spaces
    if (username.isEmpty) {
      setState(() => error = 'Please enter a username.');
      return;
    }
    if (username.contains(' ')) {
      setState(() => error = 'Username must not contain spaces.');
      return;
    }

    if (nameCtrl.text.trim().isEmpty ||
        passCtrl.text.trim().length < 6 ||
        phoneCtrl.text.trim().isEmpty ||
        addressCtrl.text.trim().isEmpty) {
      setState(() =>
          error = 'Please fill out all basic personal details correctly.');
      return;
    }

    if (_selectedRole == 'admin') {
      if (shopNameCtrl.text.trim().isEmpty ||
          shopAddressCtrl.text.trim().isEmpty ||
          mobile1Ctrl.text.trim().isEmpty) {
        setState(() =>
            error = 'Please fill out all required Shop Details (*).');
        return;
      }
      if (upiIdCtrl.text.trim().isEmpty &&
          accountNumberCtrl.text.trim().isEmpty) {
        setState(() =>
            error =
                'Please add at least a UPI ID or Bank Account for your shop.');
        return;
      }
    }

    setState(() {
      isLoading = true;
      error = '';
    });

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: _fullPhone,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _finalizeRegistration(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        setState(() {
          error = e.message ?? 'Phone verification failed. Please try again.';
          isLoading = false;
        });
      },
      codeSent: (String verificationId, int? resendToken) {
        setState(() {
          _verificationId = verificationId;
          isLoading = false;
        });
        _showOtpDialog();
      },
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  // ── STEP 2 · OTP Dialog ──
  void _showOtpDialog() {
    final otpCtrl = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Verify Phone Number',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enter the 6-digit code sent to $_fullPhone',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: otpCtrl,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 22,
                  letterSpacing: 8,
                  fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                counterText: '',
                hintText: '------',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryBlue,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final credential = PhoneAuthProvider.credential(
                verificationId: _verificationId!,
                smsCode: otpCtrl.text.trim(),
              );
              await _finalizeRegistration(credential);
            },
            child: const Text('Verify & Register',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── STEP 3 · Create account after phone is verified ──
  Future<void> _finalizeRegistration(
      PhoneAuthCredential phoneCredential) async {
    setState(() {
      isLoading = true;
      error = '';
    });
    try {
      // Use the hidden dummy email derived from the username
      final userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _dummyEmail,
        password: passCtrl.text.trim(),
      );
      final uid = userCredential.user!.uid;
      String newShopId = '';

      final newUser = UserModel(
        uid:          uid,
        username:     usernameCtrl.text.trim().toLowerCase().replaceAll(' ', ''),
        fullName:     nameCtrl.text.trim(),
        phone:        _fullPhone,
        address:      addressCtrl.text.trim(),
        role:         _selectedRole,
        shopIds:      [],
        shopName:     null,
        memberNumber: null,
        displayId:    null,
        createdAt:    DateTime.now(),
      );
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set(newUser.toMap());

      if (_selectedRole == 'admin') {
        final shopService = ShopService();
        final result = await shopService.createShop(
          adminId: uid,
          adminEmail: _dummyEmail,   // internal only — not shown in UI
          shopName: shopNameCtrl.text.trim(),
          address: shopAddressCtrl.text.trim(),
          mobile1: mobile1Ctrl.text.trim(),
          mobile2: mobile2Ctrl.text.trim(),
          upiId: upiIdCtrl.text.trim(),
          accountName: accountNameCtrl.text.trim(),
          accountNumber: accountNumberCtrl.text.trim(),
          ifscCode: ifscCtrl.text.trim(),
          bankName: bankNameCtrl.text.trim(),
        );

        if (result['success'] != true) {
          setState(() {
            error = result['error'] ?? 'Error creating shop.';
            isLoading = false;
          });
          return;
        }

        newShopId = result['shopId'] as String;

        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .update({'shopIds': FieldValue.arrayUnion([newShopId])});

        final adminErr =
            await ref.read(authServiceProvider).activateAdmin(
          uid: uid,
          shopId: newShopId,
          shopName: shopNameCtrl.text.trim(),
        );

        if (adminErr != null) {
          setState(() {
            error = adminErr;
            isLoading = false;
          });
          return;
        }
      }

      if (!mounted) return;

      // ── FIXED: Don't manually navigate to dashboard ──
      // The StreamBuilder in main.dart watches authStateChanges and
      // userDocStreamProvider. Once the Firestore doc is written above,
      // main.dart automatically routes to the correct dashboard.
      // Manual pushAndRemoveUntil was causing the black screen by
      // fighting with the StreamBuilder simultaneously.
      Navigator.of(context).popUntil((route) => route.isFirst);

    } on FirebaseAuthException catch (e) {
      setState(
          () => error = e.message ?? 'An error occurred during registration.');
    } catch (e) {
      setState(() => error = 'An unexpected error occurred: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // ── Phone field with country code picker ──
  Widget _buildPhoneField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _pickCountry,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                border: Border(
                    right: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_selectedCountry.flag,
                      style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 6),
                  Text(_selectedCountry.dialCode,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: _darkNavy)),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_drop_down,
                      size: 18, color: Colors.grey.shade500),
                ],
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: 'Mobile number',
                hintStyle: TextStyle(
                    color: Colors.grey.shade400, fontSize: 14),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────────────── UI ──────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Custom Header ──
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios,
                        color: _darkNavy, size: 20),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    alignment: Alignment.centerLeft,
                  ),
                  const Spacer(),
                  Image.asset(
                    'assets/images/image_5dc8bd.png',
                    width: 40,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.savings, color: _primaryBlue),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              const Text(
                'Create Account',
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: _darkNavy,
                    letterSpacing: -0.5),
              ),
              const SizedBox(height: 8),
              const Text(
                'Join to securely manage or participate in financial pools.',
                style: TextStyle(
                    color: Colors.grey, fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 32),

              // ── Role Selector ──
              const Text('I want to...',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _darkNavy,
                      fontSize: 16)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _RoleCard(
                      title: 'Join a Pool',
                      icon: Icons.person_outline,
                      isSelected: _selectedRole == 'member',
                      onTap: () =>
                          setState(() => _selectedRole = 'member'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _RoleCard(
                      title: 'Manage a Pool',
                      icon: Icons.storefront_outlined,
                      isSelected: _selectedRole == 'admin',
                      onTap: () =>
                          setState(() => _selectedRole = 'admin'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Dynamic Form Container ──
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // ── Personal Details ──
                    const Text('Personal Details',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _primaryBlue,
                            fontSize: 14)),
                    const SizedBox(height: 16),

                    // ── Username field (replaces email) ──
                    AppTextField(
                        controller: usernameCtrl,
                        label: 'Username *',
                        icon: Icons.alternate_email,
                        keyboardType: TextInputType.text),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 10),
                      child: Text(
                        'No spaces allowed. Used to log in.',
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500),
                      ),
                    ),

                    AppTextField(
                        controller: nameCtrl,
                        label: 'Full Name *',
                        icon: Icons.person_outline),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: passCtrl,
                      label: 'Password *',
                      icon: Icons.lock_outline,
                      obscureText: obscurePass,
                      suffixIcon: IconButton(
                        icon: Icon(
                            obscurePass
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: Colors.grey.shade500),
                        onPressed: () =>
                            setState(() => obscurePass = !obscurePass),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Phone field with country code picker ──
                    const Text('Mobile Number * (OTP will be sent)',
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 6),
                    _buildPhoneField(),

                    const SizedBox(height: 16),
                    AppTextField(
                        controller: addressCtrl,
                        label: 'Complete Address *',
                        icon: Icons.location_on_outlined,
                        maxLines: 2),

                    // ── Admin Extra Details ──
                    if (_selectedRole == 'admin') ...[
                      const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Divider()),

                      const Text('Shop Details',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _primaryBlue,
                              fontSize: 14)),
                      const SizedBox(height: 16),
                      AppTextField(
                          controller: shopNameCtrl,
                          label: 'Shop Name *',
                          icon: Icons.storefront),
                      const SizedBox(height: 16),
                      AppTextField(
                          controller: shopAddressCtrl,
                          label: 'Shop Address *',
                          icon: Icons.location_on_outlined,
                          maxLines: 2),
                      const SizedBox(height: 16),
                      AppTextField(
                          controller: mobile1Ctrl,
                          label: 'Primary Shop Mobile *',
                          icon: Icons.phone,
                          keyboardType: TextInputType.phone),
                      const SizedBox(height: 16),
                      AppTextField(
                          controller: mobile2Ctrl,
                          label: 'Secondary Shop Mobile (Optional)',
                          icon: Icons.phone_android,
                          keyboardType: TextInputType.phone),

                      const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Divider()),

                      const Text('Payment Settings',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _primaryBlue,
                              fontSize: 14)),
                      const SizedBox(height: 8),
                      Text(
                          'Add at least one payment method for your members.',
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600)),
                      const SizedBox(height: 16),
                      AppTextField(
                          controller: upiIdCtrl,
                          label: 'UPI ID (Optional)',
                          icon: Icons.qr_code_2),
                      const SizedBox(height: 16),
                      AppTextField(
                          controller: accountNameCtrl,
                          label: 'Account Holder Name',
                          icon: Icons.person_outline),
                      const SizedBox(height: 16),
                      AppTextField(
                          controller: accountNumberCtrl,
                          label: 'Account Number',
                          icon: Icons.numbers,
                          keyboardType: TextInputType.number),
                      const SizedBox(height: 16),
                      AppTextField(
                          controller: ifscCtrl,
                          label: 'IFSC Code',
                          icon: Icons.code),
                      const SizedBox(height: 16),
                      AppTextField(
                          controller: bankNameCtrl,
                          label: 'Bank Name',
                          icon: Icons.account_balance_wallet_outlined),
                    ],

                    const SizedBox(height: 32),

                    LoadingButton(
                      isLoading: isLoading,
                      onPressed: _startVerification,
                      label: _selectedRole == 'admin'
                          ? 'Verify & Create Admin'
                          : 'Verify & Create Account',
                      icon: Icons.how_to_reg,
                      color: _primaryBlue,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              if (error.isNotEmpty)
                Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: ErrorMessage(message: error)),

              Center(
                child: TextButton(
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const LoginScreen()),
                  ),
                  child: Text.rich(TextSpan(
                    text: 'Already have an account? ',
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 14),
                    children: [
                      TextSpan(
                        text: 'Sign In',
                        style: const TextStyle(
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

// ── Helper Widget for the Role Buttons ──
class _RoleCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        isSelected ? const Color(0xFF0F4CFF) : Colors.grey.shade300;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
          border: Border.all(color: color, width: isSelected ? 2 : 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? color : Colors.grey, size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? color : Colors.grey.shade700,
                fontWeight:
                    isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}