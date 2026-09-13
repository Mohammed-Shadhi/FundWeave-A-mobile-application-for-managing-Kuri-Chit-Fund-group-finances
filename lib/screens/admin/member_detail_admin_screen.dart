import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../../widgets/shared_widgets.dart';
import '../../utils/app_helpers.dart';

class MemberDetailAdminScreen extends ConsumerWidget {
  final MemberModel member;
  final String shopId;
  final String shopName;

  const MemberDetailAdminScreen({
    super.key,
    required this.member,
    required this.shopId,
    required this.shopName,
  });

  // FundWeave Brand Colors
  static const Color _primaryBlue = Color(0xFF0F4CFF);
  static const Color _primaryTeal = Color(0xFF14D8C4);
  static const Color _darkNavy = Color(0xFF0A1F44);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kurisAsync = ref.watch(shopKurisProvider(shopId));
    final connectivity = ref.watch(connectivityProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9), // Clean light background
      appBar: AppBar(
        title: const Text('Member Profile', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        backgroundColor: _darkNavy,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(children: [
          
          // ── Premium Profile Header ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 20, bottom: 40, left: 24, right: 24),
            decoration: const BoxDecoration(
              color: _darkNavy,
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
                  border: Border.all(color: _primaryTeal, width: 2),
                ),
                child: CircleAvatar(
                  radius: 45,
                  backgroundColor: _primaryBlue.withOpacity(0.2),
                  child: Text(
                    member.fullName[0].toUpperCase(),
                    style: const TextStyle(
                        fontSize: 36, color: _primaryTeal, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(member.fullName,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: _primaryTeal.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _primaryTeal.withOpacity(0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.badge, color: _primaryTeal, size: 14),
                    const SizedBox(width: 6),
                    Text(member.displayId,
                        style: const TextStyle(
                            color: _primaryTeal,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                            fontSize: 13)),
                  ],
                ),
              ),
            ]),
          ),

          // ── Contact Info ──
          Transform.translate(
            offset: const Offset(0, -20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Contact Details',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _darkNavy)),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  _infoRow(Icons.email_outlined, 'Email', member.email),
                  _infoRow(Icons.phone_outlined, 'Phone', member.phone),
                  _infoRow(Icons.location_on_outlined, 'Address', member.address),
                ]),
              ),
            ),
          ),

          // ── Kuri Payments ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Kuri Subscriptions',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: _darkNavy)),
              const SizedBox(height: 16),
              
              if (!connectivity.isOnline)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: const Row(children: [
                    Icon(Icons.wifi_off, color: Colors.red, size: 16),
                    SizedBox(width: 8),
                    Text('Go online to mark new payments.',
                        style: TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w500)),
                  ]),
                ),

              kurisAsync.when(
                data: (kuris) {
                  final activeKuris =
                      kuris.where((k) => k.status == 'active').toList();
                  if (activeKuris.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: const Text('No active kuri groups found for this member.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
                    );
                  }
                  return Column(
                    children: activeKuris
                        .map((kuri) => _kuriPaymentSection(
                            context, ref, kuri, connectivity.isOnline))
                        .toList(),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator(color: _primaryBlue)),
                error: (e, _) => ErrorMessage(message: e.toString()),
              ),
            ]),
          ),
          const SizedBox(height: 40),
        ]),
      ),
    );
  }

  Widget _kuriPaymentSection(
    BuildContext context,
    WidgetRef ref,
    KuriModel kuri,
    bool isOnline,
  ) {
    final paymentsAsync = ref.watch(kuriPaymentsProvider(kuri.kuriId));

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ]
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8)
              ),
              child: const Icon(Icons.savings, color: _primaryBlue, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(kuri.title,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _darkNavy)),
                  const SizedBox(height: 2),
                  Text('${AppHelpers.formatAmount(kuri.monthlyAmount)} / month',
                      style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _primaryTeal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _primaryTeal.withOpacity(0.5))
              ),
              child: Text('Month ${kuri.currentMonth}/${kuri.totalMonths}',
                  style: const TextStyle(color: _primaryTeal, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ]),
          
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),

          paymentsAsync.when(
            data: (payments) {
              final memberPayments =
                  payments.where((p) => p.uid == member.uid).toList();
              final paidMonths = memberPayments.map((p) => p.month).toSet();

              return Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Monthly Tracker:',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _darkNavy)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: List.generate(kuri.totalMonths, (i) {
                    final month = i + 1;
                    final isPaid = paidMonths.contains(month);
                    final isFuture = month > kuri.currentMonth;

                    Color boxColor = isPaid ? _primaryTeal : isFuture ? const Color(0xFFF1F5F9) : const Color(0xFFFFF7ED);
                    Color borderColor = isPaid ? _primaryTeal : isFuture ? Colors.grey.shade300 : Colors.orange.shade300;
                    Color textColor = isPaid ? Colors.white : isFuture ? Colors.grey.shade500 : Colors.orange.shade800;

                    return GestureDetector(
                      onTap: (!isPaid && !isFuture && isOnline)
                          ? () => _showMarkPaidDialog(context, ref, kuri, month)
                          : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: boxColor,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: borderColor),
                        ),
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isPaid ? Icons.check_circle : isFuture ? Icons.lock : Icons.add_circle,
                                size: 16,
                                color: textColor,
                              ),
                              const SizedBox(height: 2),
                              Text('M$month',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  )),
                            ]),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 16),
                Wrap(spacing: 16, children: [
                  _legend(_primaryTeal, 'Paid'),
                  _legend(Colors.orange.shade400, 'Due (Tap)'),
                  _legend(Colors.grey.shade300, 'Future'),
                ]),
              ]);
            },
            loading: () => const Center(child: CircularProgressIndicator(color: _primaryBlue)),
            error: (e, _) => ErrorMessage(message: e.toString()),
          ),
        ]),
      ),
    );
  }

  void _showMarkPaidDialog(
    BuildContext context,
    WidgetRef ref,
    KuriModel kuri,
    int month,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: _primaryTeal.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.payment, color: _primaryTeal, size: 20)
          ),
          const SizedBox(width: 12),
          const Text('Mark as Paid', style: TextStyle(fontWeight: FontWeight.bold)),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                _dialogRow('Member', member.fullName),
                _dialogRow('Member ID', member.displayId),
                const Divider(height: 16),
                _dialogRow('Kuri Pool', kuri.title),
                _dialogRow('Installment', 'Month $month'),
                _dialogRow('Amount', AppHelpers.formatAmount(kuri.monthlyAmount), isBold: true),
              ],
            ),
          )
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), 
              child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              final err = await ref.read(paymentServiceProvider).markAsPaid(
                kuriId: kuri.kuriId,
                shopId: shopId,
                shopName: shopName,
                uid: member.uid,
                memberName: member.fullName,
                memberId: member.displayId,
                month: month,
                amount: kuri.monthlyAmount,
                kuriName: kuri.title,
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(err ?? '✅ Payment recorded for Month $month', style: const TextStyle(fontWeight: FontWeight.bold)),
                  backgroundColor: err != null ? Colors.red : _primaryTeal,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ));
              }
            },
            icon: const Icon(Icons.check),
            label: const Text('Confirm Payment', style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
                backgroundColor: _primaryBlue, 
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: _primaryBlue, size: 20),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: _darkNavy)),
        ]),
      ]),
    );
  }

  Widget _legend(Color color, String label) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(3))),
      const SizedBox(width: 6),
      Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
    ]);
  }

  Widget _dialogRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        SizedBox(
            width: 80,
            child: Text(label,
                style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500))),
        const Text(': ', style: TextStyle(color: Colors.grey)),
        Expanded(
            child: Text(value,
                style: TextStyle(
                    fontWeight: isBold ? FontWeight.bold : FontWeight.w600, 
                    fontSize: isBold ? 15 : 13,
                    color: isBold ? _primaryTeal : _darkNavy))),
      ]),
    );
  }
}