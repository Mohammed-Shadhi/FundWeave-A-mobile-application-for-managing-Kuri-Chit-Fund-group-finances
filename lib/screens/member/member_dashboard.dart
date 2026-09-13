import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../../widgets/shared_widgets.dart';
import '../../utils/app_helpers.dart';

import '../shared/receipt_list_screen.dart';
import 'member_kuri_detail_screen.dart';
import 'invitation_screen.dart';

class MemberDashboard extends ConsumerWidget {
  final String shopId;
  final String shopName;
  final String uid;

  const MemberDashboard({
    super.key,
    required this.shopId,
    required this.shopName,
    required this.uid,
  });

  // FundWeave Brand Colors
  static const Color _primaryBlue = Color(0xFF0F4CFF);
  static const Color _primaryTeal = Color(0xFF14D8C4);
  static const Color _darkNavy = Color(0xFF0A1F44);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivity = ref.watch(connectivityProvider);
    final userDocAsync = ref.watch(userDocStreamProvider(uid));
    final kurisAsync = ref.watch(memberKurisProvider(shopId));
    final shopAsync = ref.watch(shopStreamProvider(shopId));

    final phone =
        FirebaseAuth.instance.currentUser?.phoneNumber ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: Text(shopName.isNotEmpty ? shopName : 'My Dashboard',
            style: const TextStyle(
                fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        backgroundColor: _darkNavy,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long),
            tooltip: 'My Receipts',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ReceiptListScreen(
                  shopId: shopId,
                  isAdmin: false,
                  uid: uid,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            tooltip: 'Logout',
            onPressed: () async =>
                ref.read(authServiceProvider).signOut(),
          ),
        ],
      ),
      body: Column(
        children: [
          if (!connectivity.isOnline) const OfflineBanner(),
          const PaymentPendingBanner(),

          // ── Invitation Button ──
          if (phone.isNotEmpty)
            _InviteButton(uid: uid, phone: phone),

          Expanded(
            child: userDocAsync.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(color: _primaryBlue)),
              error: (e, _) =>
                  Center(child: ErrorMessage(message: e.toString())),
              data: (userData) {
                if (userData == null) {
                  return const Center(
                      child: Text('User data not found.',
                          style: TextStyle(color: Colors.grey)));
                }
                final fullName =
                    userData['fullName'] as String? ?? '';
                final phone =
                    userData['phone'] as String? ?? '';
                final address =
                    userData['address'] as String? ?? '';
                final displayId =
                    userData['displayId'] as String? ?? '';
                final initial = fullName.isNotEmpty
                    ? fullName[0].toUpperCase()
                    : 'M';

                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Premium Profile Header ──
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 32),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [_primaryBlue, _primaryTeal],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(30),
                            bottomRight: Radius.circular(30),
                          ),
                        ),
                        child: Column(children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.5),
                                  width: 2),
                            ),
                            child: CircleAvatar(
                              radius: 40,
                              backgroundColor: Colors.white,
                              child: Text(
                                initial,
                                style: const TextStyle(
                                  fontSize: 32,
                                  color: _primaryBlue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            fullName,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (displayId.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 6),
                              decoration: BoxDecoration(
                                color: _darkNavy.withOpacity(0.3),
                                borderRadius:
                                    BorderRadius.circular(20),
                                border: Border.all(
                                    color:
                                        Colors.white.withOpacity(0.2)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.badge,
                                      color: Colors.white, size: 14),
                                  const SizedBox(width: 6),
                                  Text(
                                    displayId,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ]),
                      ),

                      // ── My Details Card ──
                      Transform.translate(
                        offset: const Offset(0, -20),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius:
                                  BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      Colors.black.withOpacity(0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                              border: Border.all(
                                  color: Colors.grey.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text('Personal Details',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: _darkNavy,
                                        fontSize: 16)),
                                const SizedBox(height: 12),
                                const Divider(height: 1),
                                const SizedBox(height: 12),
                                _infoRow(
                                    Icons.phone_outlined,
                                    'Phone',
                                    phone.isNotEmpty
                                        ? phone
                                        : 'N/A'),
                                _infoRow(
                                    Icons.location_on_outlined,
                                    'Address',
                                    address.isNotEmpty
                                        ? address
                                        : 'N/A'),
                                _infoRow(
                                    Icons.storefront_outlined,
                                    'Shop Network',
                                    shopName),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // ── Shop Details ──
                      shopAsync.when(
                        data: (shop) {
                          if (shop == null)
                            return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(
                                20, 0, 20, 16),
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius:
                                    BorderRadius.circular(16),
                                border: Border.all(
                                    color: Colors.grey.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text('Network Shop Info',
                                      style: TextStyle(
                                          fontWeight:
                                              FontWeight.bold,
                                          color: _darkNavy,
                                          fontSize: 16)),
                                  const SizedBox(height: 12),
                                  const Divider(height: 1),
                                  const SizedBox(height: 12),
                                  _infoRow(Icons.store, 'Name',
                                      shop.name),
                                  _infoRow(Icons.location_on,
                                      'Address', shop.address),
                                  _infoRow(Icons.phone, 'Mobile',
                                      shop.mobile1),
                                  if (shop.mobile2.isNotEmpty)
                                    _infoRow(
                                        Icons.phone_android,
                                        'Secondary Mobile',
                                        shop.mobile2),
                                  const SizedBox(height: 16),
                                  if (shop.hasUpi ||
                                      shop.hasBankAccount)
                                    Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          if (shop.hasUpi)
                                            _badge('UPI Available',
                                                _primaryTeal),
                                          if (shop.hasBankAccount)
                                            _badge('Bank Transfer',
                                                _primaryBlue),
                                        ]),
                                ],
                              ),
                            ),
                          );
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),

                      // ── My Kuri Groups ──
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                            24, 8, 24, 16),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text('My Kuri Subscriptions',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _darkNavy,
                                    fontSize: 18)),
                            kurisAsync.when(
                              data: (k) => Container(
                                padding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4),
                                decoration: BoxDecoration(
                                  color: _primaryBlue
                                      .withOpacity(0.1),
                                  borderRadius:
                                      BorderRadius.circular(12),
                                ),
                                child: Text('${k.length} active',
                                    style: const TextStyle(
                                        color: _primaryBlue,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12)),
                              ),
                              loading: () =>
                                  const SizedBox.shrink(),
                              error: (_, __) =>
                                  const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      ),

                      kurisAsync.when(
                        data: (kuris) {
                          if (kuris.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.all(30),
                              child: Center(
                                child: Column(children: [
                                  Icon(Icons.savings_outlined,
                                      size: 70,
                                      color: Colors.grey.shade400),
                                  const SizedBox(height: 16),
                                  const Text(
                                      'No active kuri groups.',
                                      style: TextStyle(
                                          color: Colors.grey,
                                          fontWeight:
                                              FontWeight.w500,
                                          fontSize: 16)),
                                ]),
                              ),
                            );
                          }
                          return ListView.builder(
                            shrinkWrap: true,
                            physics:
                                const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20),
                            itemCount: kuris.length,
                            itemBuilder: (context, i) =>
                                _kuriCard(
                                    context, ref, kuris[i]),
                          );
                        },
                        loading: () => const Center(
                            child: CircularProgressIndicator(
                                color: _primaryBlue)),
                        error: (e, _) => Center(
                            child: ErrorMessage(
                                message: e.toString())),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _kuriCard(
      BuildContext context, WidgetRef ref, KuriModel kuri) {
    final paymentsAsync =
        ref.watch(myKuriPaymentsProvider(kuri.kuriId));
    final hasWon =
        kuri.winnersHistory.any((w) => w['uid'] == uid);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade200)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MemberKuriDetailScreen(
              kuriId: kuri.kuriId,
              shopId: shopId,
              shopName: shopName,
              uid: uid,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.savings,
                        color: _primaryBlue, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(kuri.title,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: _darkNavy)),
                          const SizedBox(height: 2),
                          Text(
                              'Month ${kuri.currentMonth} of ${kuri.totalMonths}',
                              style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500)),
                        ]),
                  ),
                  const Icon(Icons.chevron_right,
                      color: Colors.grey),
                ]),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  _chip(
                      '${AppHelpers.formatAmount(kuri.monthlyAmount)}/mo',
                      _primaryBlue),
                  _chip(
                      'Pool: ${AppHelpers.formatAmount(kuri.totalPool)}',
                      _primaryTeal),
                  _chip(
                      '${kuri.totalMembers} members', _darkNavy),
                ]),
                const SizedBox(height: 16),
                paymentsAsync.when(
                  data: (payments) {
                    final myPaid = payments.any((p) =>
                        p.uid == uid &&
                        p.month == kuri.currentMonth);
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: myPaid
                            ? Colors.green.shade50
                            : Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: myPaid
                                ? Colors.green.shade200
                                : Colors.orange.shade200),
                      ),
                      child: Row(children: [
                        Icon(
                          myPaid
                              ? Icons.check_circle
                              : Icons.warning_amber,
                          color: myPaid
                              ? Colors.green.shade700
                              : Colors.orange.shade700,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            myPaid
                                ? 'Installment for Month ${kuri.currentMonth} is Paid ✓'
                                : 'Month ${kuri.currentMonth} pending — Tap to pay',
                            style: TextStyle(
                              color: myPaid
                                  ? Colors.green.shade700
                                  : Colors.orange.shade800,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ]),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                if (hasWon) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: const Color(0xFFFFD54F)),
                    ),
                    child: const Row(children: [
                      Icon(Icons.military_tech,
                          color: Color(0xFFF57F17), size: 20),
                      SizedBox(width: 8),
                      Text(
                          'Winner Status: You have won this pool!',
                          style: TextStyle(
                              color: Color(0xFFF57F17),
                              fontSize: 13,
                              fontWeight: FontWeight.bold)),
                    ]),
                  ),
                ],
              ]),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child:
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: _primaryBlue, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(value,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: _darkNavy)),
              ]),
        ),
      ]),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.2))),
      child: Text(label,
          style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold)),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.check_circle, color: color, size: 14),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold)),
      ]),
    );
  }
}


// ─────────────────────────────────────────────────────────────
// _InviteButton — shows a badge button when a pending invite
// exists, tapping navigates to InvitationScreen.
// ─────────────────────────────────────────────────────────────
class _InviteButton extends StatelessWidget {
  final String uid;
  final String phone;

  const _InviteButton({required this.uid, required this.phone});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('invitations')
          .doc(phone)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const SizedBox.shrink();
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final shopName = data['shopName'] as String? ?? 'a shop';

        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => InvitationScreen(uid: uid, phone: phone),
            ),
          ),
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFFD54F)),
            ),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF57F17).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.mark_email_unread,
                    color: Color(0xFFF57F17), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pending Invitation',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Color(0xFF5D3A00),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'You are invited to join $shopName',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right,
                  color: Color(0xFFF57F17), size: 20),
            ]),
          ),
        );
      },
    );
  }
}