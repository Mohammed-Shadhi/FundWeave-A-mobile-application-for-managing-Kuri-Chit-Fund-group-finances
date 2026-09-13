import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';
import '../../widgets/shared_widgets.dart';
import '../../utils/app_helpers.dart';

class PaymentInfoScreen extends ConsumerWidget {
  final String shopId;
  final String kuriTitle;
  final double amount;
  final int month;

  const PaymentInfoScreen({
    super.key,
    required this.shopId,
    required this.kuriTitle,
    required this.amount,
    required this.month,
  });

  // FundWeave Brand Colors
  static const Color _primaryBlue = Color(0xFF0F4CFF);
  static const Color _primaryTeal = Color(0xFF14D8C4);
  static const Color _darkNavy = Color(0xFF0A1F44);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shopAsync = ref.watch(shopStreamProvider(shopId));

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text('Payment Details', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        backgroundColor: _darkNavy,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: shopAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: _primaryBlue)),
        error: (e, _) => Center(child: ErrorMessage(message: e.toString())),
        data: (shop) {
          if (shop == null) return const Center(child: Text('Shop not found.'));

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Payment Summary Card ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_primaryBlue, _primaryTeal],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: _primaryBlue.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Amount to Pay',
                          style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      Text(
                        AppHelpers.formatAmount(amount),
                        style: const TextStyle(
                            color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 24),
                      _summaryRow('Kuri', kuriTitle),
                      _summaryRow('Installment', 'Month $month'),
                      _summaryRow('Pay to', shop.name),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                if (!shop.hasAnyPaymentMethod)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: const Row(children: [
                      Icon(Icons.warning_amber, color: Colors.orange),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'No payment details configured yet. Please contact your admin.',
                          style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ]),
                  ),

                // ── UPI Section ──
                if (shop.hasUpi) ...[
                  _sectionHeader('Pay via UPI', Icons.qr_code_scanner, _primaryTeal),
                  const SizedBox(height: 16),
                  _paymentCard(
                    color: _primaryTeal,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('UPI ID', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Row(children: [
                          Expanded(
                            child: Text(shop.upiId,
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold, color: _darkNavy)),
                          ),
                          _copyButton(context, shop.upiId, 'UPI ID copied!'),
                        ]),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],

                // ── Bank Transfer Section ──
                if (shop.hasBankAccount) ...[
                  _sectionHeader('Pay via Bank Transfer', Icons.account_balance, _primaryBlue),
                  const SizedBox(height: 16),
                  _paymentCard(
                    color: _primaryBlue,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (shop.accountName.isNotEmpty)
                          _bankRow('Account Name', shop.accountName, context),
                        _bankRow('Account Number', shop.accountNumber, context),
                        if (shop.ifscCode.isNotEmpty)
                          _bankRow('IFSC Code', shop.ifscCode, context),
                        if (shop.bankName.isNotEmpty)
                          _bankRow('Bank Name', shop.bankName, context),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],

                // ── Contact Admin ──
                _sectionHeader('Need Help?', Icons.support_agent, Colors.orange.shade400),
                const SizedBox(height: 16),
                _paymentCard(
                  color: Colors.orange.shade400,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _bankRow('Mobile 1', shop.mobile1, context),
                      if (shop.mobile2.isNotEmpty)
                        _bankRow('Mobile 2', shop.mobile2, context),
                      const SizedBox(height: 8),
                      const Text(
                        'After payment, contact admin to confirm and collect your receipt.',
                        style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Text('$label: ', style: const TextStyle(color: Colors.white70, fontSize: 14)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  Widget _sectionHeader(String title, IconData icon, Color color) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      const SizedBox(width: 12),
      Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: _darkNavy)),
    ]);
  }

  Widget _paymentCard({required Color color, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _bankRow(String label, String value, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _darkNavy)),
          ]),
        ),
        _copyButton(context, value, '$label copied!'),
      ]),
    );
  }

  Widget _copyButton(BuildContext context, String text, String snackMsg) {
    return IconButton(
      onPressed: () {
        Clipboard.setData(ClipboardData(text: text));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(snackMsg, style: const TextStyle(fontWeight: FontWeight.bold)),
            duration: const Duration(seconds: 2),
            backgroundColor: _primaryBlue,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      icon: const Icon(Icons.copy_all, size: 20, color: _primaryBlue),
      tooltip: 'Copy',
    );
  }
}