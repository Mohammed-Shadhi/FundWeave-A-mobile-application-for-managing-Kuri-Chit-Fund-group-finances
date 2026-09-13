import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';
import '../../models/shop_model.dart';
import '../../widgets/shared_widgets.dart';

class ShopPaymentSettingsScreen extends ConsumerStatefulWidget {
  final String shopId;
  const ShopPaymentSettingsScreen({super.key, required this.shopId});

  @override
  ConsumerState<ShopPaymentSettingsScreen> createState() =>
      _ShopPaymentSettingsScreenState();
}

class _ShopPaymentSettingsScreenState
    extends ConsumerState<ShopPaymentSettingsScreen> {
  final upiIdCtrl = TextEditingController();
  final accountNameCtrl = TextEditingController();
  final accountNumberCtrl = TextEditingController();
  final ifscCtrl = TextEditingController();
  final bankNameCtrl = TextEditingController();

  bool isLoading = false;
  bool isSaving = false;
  String error = '';
  String success = '';
  bool _loaded = false;

  // FundWeave Brand Colors
  static const Color _primaryBlue = Color(0xFF0F4CFF);
  static const Color _primaryTeal = Color(0xFF14D8C4);
  static const Color _darkNavy = Color(0xFF0A1F44);

  @override
  void dispose() {
    upiIdCtrl.dispose();
    accountNameCtrl.dispose();
    accountNumberCtrl.dispose();
    ifscCtrl.dispose();
    bankNameCtrl.dispose();
    super.dispose();
  }

  void _loadData(ShopModel shop) {
    if (_loaded) return;
    _loaded = true;
    upiIdCtrl.text = shop.upiId;
    accountNameCtrl.text = shop.accountName;
    accountNumberCtrl.text = shop.accountNumber;
    ifscCtrl.text = shop.ifscCode;
    bankNameCtrl.text = shop.bankName;
  }

  Future<void> _save() async {
    if (upiIdCtrl.text.trim().isEmpty && accountNumberCtrl.text.trim().isEmpty) {
      setState(() => error = 'Please add at least a UPI ID or Bank Account Number.');
      return;
    }

    setState(() { isSaving = true; error = ''; success = ''; });

    final err = await ref.read(shopServiceProvider).updatePaymentDetails(
      shopId: widget.shopId,
      upiId: upiIdCtrl.text.trim(),
      accountName: accountNameCtrl.text.trim(),
      accountNumber: accountNumberCtrl.text.trim(),
      ifscCode: ifscCtrl.text.trim(),
      bankName: bankNameCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() {
      isSaving = false;
      if (err != null) {
        error = err;
      } else {
        success = '✅ Payment details updated successfully!';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final shopAsync = ref.watch(shopStreamProvider(widget.shopId));

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9), // Clean light background
      appBar: AppBar(
        title: const Text('Payment Settings', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        backgroundColor: _darkNavy,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: shopAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: _primaryBlue)),
        error: (e, _) => Center(child: ErrorMessage(message: e.toString())),
        data: (shop) {
          if (shop == null) return const Center(child: Text('Shop not found.', style: TextStyle(color: Colors.grey)));
          _loadData(shop);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── Info Banner ──
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _primaryBlue.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _primaryBlue.withOpacity(0.2)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.info_outline, color: _primaryBlue, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Members will see these details when making their monthly pool payments. Please ensure they are accurate.',
                        style: TextStyle(fontSize: 13, color: _darkNavy.withOpacity(0.8), height: 1.4),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 32),

                // ── UPI Section ──
                _sectionHeader('UPI Payment', Icons.qr_code_scanner, _primaryTeal),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      )
                    ]
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppTextField(
                        controller: upiIdCtrl,
                        label: 'UPI ID (e.g. yourshop@ybl)',
                        icon: Icons.qr_code_2,
                      ),
                      if (upiIdCtrl.text.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _previewChip('Active UPI: ${upiIdCtrl.text}', _primaryTeal),
                      ]
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // ── Bank Section ──
                _sectionHeader('Bank Account', Icons.account_balance, _primaryBlue),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      )
                    ]
                  ),
                  child: Column(
                    children: [
                      AppTextField(
                        controller: accountNameCtrl,
                        label: 'Account Holder Name',
                        icon: Icons.person_outline,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: accountNumberCtrl,
                        label: 'Account Number',
                        icon: Icons.numbers,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: AppTextField(
                              controller: ifscCtrl,
                              label: 'IFSC Code',
                              icon: Icons.code,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: AppTextField(
                              controller: bankNameCtrl,
                              label: 'Bank Name',
                              icon: Icons.account_balance_wallet_outlined,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                LoadingButton(
                  isLoading: isSaving,
                  onPressed: _save,
                  label: 'Save Payment Details',
                  icon: Icons.verified_user_outlined,
                  color: _darkNavy,
                ),

                if (error.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  ErrorMessage(message: error),
                ],
                if (success.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9), // Light green
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFA5D6A7)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 20),
                      const SizedBox(width: 12),
                      Text(success, style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold)),
                    ]),
                  ),
                ],
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
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

  Widget _previewChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.check_circle, color: color, size: 16),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
      ]),
    );
  }
}