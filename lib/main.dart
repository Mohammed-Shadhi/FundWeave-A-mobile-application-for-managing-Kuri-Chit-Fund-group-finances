import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';

import 'screens/auth/welcome_screen.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/admin/platform_admin_dashboard.dart';
import 'screens/member/member_dashboard.dart';
import 'services/shop_service.dart';
import 'providers/providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: KuriApp()));
}

class KuriApp extends StatelessWidget {
  const KuriApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FundWeave',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(elevation: 0),
        cardTheme: const CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 14),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(
                vertical: 14, horizontal: 20),
          ),
        ),
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _SplashScreen();
          }
          if (snapshot.hasData) {
            return _RoleRouter(uid: snapshot.data!.uid);
          }
          return const WelcomeScreen();
        },
      ),
    );
  }
}

// ── Splash shown while Firebase Auth initializes ──
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0A1F44),
      body: Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );
  }
}

// ── Routes to correct dashboard based on Firestore role ──
class _RoleRouter extends ConsumerWidget {
  final String uid;
  const _RoleRouter({required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userDocAsync = ref.watch(userDocStreamProvider(uid));

    return userDocAsync.when(
      loading: () => const _SplashScreen(),
      error: (e, _) => Scaffold(
        backgroundColor: const Color(0xFF0A1F44),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text('Error: $e',
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
      data: (userData) {
        if (userData == null) return const _SplashScreen();

        final role = userData['role'] as String? ?? 'member';
        final shopIdsList =
            userData['shopIds'] as List<dynamic>? ?? [];
        final shopId = shopIdsList.isNotEmpty
            ? shopIdsList.first.toString()
            : '';
        final shopName =
            userData['shopName'] as String? ?? 'My Pool';

        switch (role) {
          case 'platform_admin':
            return PlatformAdminDashboard(uid: uid);

          case 'admin':
            return AdminDashboard(
                uid: uid, shopId: shopId, shopName: shopName);

          case 'member':
            // ── FIX: member with no shopId yet ──
            // This happens when a user registers but hasn't accepted
            // an invitation yet. Show a waiting screen instead of
            // passing an empty shopId to MemberDashboard which would
            // cause all providers to fail silently.
            if (shopId.isEmpty) {
              return _WaitingForInviteScreen(uid: uid);
            }
            return MemberDashboard(
                uid: uid, shopId: shopId, shopName: shopName);

          case 'rejected':
            return _RejectedScreen(uid: uid);

          default:
            return const WelcomeScreen();
        }
      },
    );
  }
}

// ── Shown to a registered member who hasn't accepted an invite yet ──
class _WaitingForInviteScreen extends ConsumerWidget {
  final String uid;
  const _WaitingForInviteScreen({required this.uid});

  static const Color _primaryBlue = Color(0xFF0F4CFF);
  static const Color _darkNavy    = Color(0xFF0A1F44);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the user doc so the screen auto-advances the moment
    // an admin accepts the invitation and shopIds is updated.
    final userDocAsync = ref.watch(userDocStreamProvider(uid));

    // Read phone for the invitation stream
    final phone = FirebaseAuth.instance.currentUser?.phoneNumber ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text('FundWeave',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: _darkNavy,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            tooltip: 'Logout',
            onPressed: () =>
                ref.read(authServiceProvider).signOut(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 40),

            // Illustration
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: _primaryBlue.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.mark_email_unread_outlined,
                  size: 72, color: _primaryBlue.withOpacity(0.7)),
            ),
            const SizedBox(height: 32),

            const Text(
              'Waiting for Invitation',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _darkNavy,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Your account is ready. Ask your pool admin to '
              'search for you by name or phone number and send '
              'you an invitation.',
              style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Show pending invitation banner if one exists
            userDocAsync.whenData((userData) {
              final userPhone =
                  userData?['phone'] as String? ?? phone;
              if (userPhone.isEmpty) return null;

              return StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection('invitations')
                    .doc(userPhone)
                    .snapshots(),
                builder: (context, snap) {
                  if (!snap.hasData || !snap.data!.exists) {
                    return const SizedBox.shrink();
                  }
                  final data = snap.data!.data()
                      as Map<String, dynamic>;
                  final shopName =
                      data['shopName'] as String? ?? 'a shop';

                  return _PendingInviteBanner(
                    shopName: shopName,
                    uid:      uid,
                    phone:    userPhone,
                  );
                },
              );
            }).value ?? const SizedBox.shrink(),

            const SizedBox(height: 32),

            // What to do next card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('What happens next?',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _darkNavy,
                          fontSize: 15)),
                  const SizedBox(height: 16),
                  _step('1', 'Share your registered name or phone '
                      'number with your pool admin.'),
                  const SizedBox(height: 12),
                  _step('2', 'The admin searches for you in the '
                      'Directory and taps Invite.'),
                  const SizedBox(height: 12),
                  _step('3', 'You\'ll see an invitation banner '
                      'here. Tap it to accept and join the pool.'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _step(String number, String text) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: _primaryBlue,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(number,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(text,
              style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                  height: 1.4)),
        ),
      ),
    ]);
  }
}

// ── Pending invite banner shown inside _WaitingForInviteScreen ──
class _PendingInviteBanner extends StatefulWidget {
  final String shopName;
  final String uid;
  final String phone;
  const _PendingInviteBanner({
    required this.shopName,
    required this.uid,
    required this.phone,
  });

  @override
  State<_PendingInviteBanner> createState() =>
      _PendingInviteBannerState();
}

class _PendingInviteBannerState extends State<_PendingInviteBanner> {
  bool _accepting = false;
  String? _error;

  Future<void> _accept() async {
    setState(() { _accepting = true; _error = null; });

    try {
      // Read invitation data
      final inviteDoc = await FirebaseFirestore.instance
          .collection('invitations')
          .doc(widget.phone)
          .get();

      if (!inviteDoc.exists) {
        setState(() {
          _error    = 'Invitation no longer exists.';
          _accepting = false;
        });
        return;
      }

      final data   = inviteDoc.data()!;
      final shopId = data['shopId'] as String;
      final fullName =
          data['fullName'] as String? ?? '';
      final address = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .get()
          .then((d) => d.data()?['address'] as String? ?? '');
      final phone = data['phone'] as String? ?? '';

      // Create member record
      final shopService = ShopService();
      final result = await shopService.createMember(
        uid:      widget.uid,
        shopId:   shopId,
        shopName: widget.shopName,
        fullName: fullName,
        email:    '',
        phone:    phone,
        address:  address,
      );

      if (result['success'] != true) {
        setState(() {
          _error    = result['error'] as String? ?? 'Failed to join.';
          _accepting = false;
        });
        return;
      }

      // Link shopId to user and delete invitation atomically
      final batch = FirebaseFirestore.instance.batch();
      batch.update(
        FirebaseFirestore.instance.collection('users').doc(widget.uid),
        {'shopIds': FieldValue.arrayUnion([shopId])},
      );
      batch.delete(
        FirebaseFirestore.instance
            .collection('invitations')
            .doc(widget.phone),
      );
      await batch.commit();

      // _RoleRouter's stream will detect shopIds update and
      // automatically navigate to MemberDashboard — no push needed.
    } catch (e) {
      setState(() {
        _error    = 'Error: $e';
        _accepting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFD54F)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF57F17).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.mark_email_unread,
                  color: Color(0xFFF57F17), size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('You have a pending invitation!',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Color(0xFF5D3A00))),
                  Text(
                    'Join ${widget.shopName}',
                    style: TextStyle(
                        fontSize: 13,
                        color: Colors.orange.shade700),
                  ),
                ],
              ),
            ),
          ]),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!,
                style: const TextStyle(
                    color: Colors.redAccent, fontSize: 12)),
          ],
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _accepting ? null : () async {
                  // Decline — just delete the invitation
                  await FirebaseFirestore.instance
                      .collection('invitations')
                      .doc(widget.phone)
                      .delete();
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.orange.shade300),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Decline',
                    style: TextStyle(color: Colors.orange)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _accepting ? null : _accept,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF57F17),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: _accepting
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white))
                    : const Text('Accept',
                        style: TextStyle(
                            fontWeight: FontWeight.bold)),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

class _RejectedScreen extends ConsumerWidget {
  final String uid;
  const _RejectedScreen({required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cancel, color: Colors.red, size: 70),
              const SizedBox(height: 16),
              const Text('Registration Rejected',
                  style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text(
                  'Your shop registration was rejected. '
                  'Please contact support.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () async =>
                    ref.read(authServiceProvider).signOut(),
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}