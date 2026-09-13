import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';
import '../../widgets/shared_widgets.dart';

class ReceiptListScreen extends ConsumerWidget {
  final String shopId;
  final bool isAdmin;
  final String? uid;

  const ReceiptListScreen({
    super.key,
    required this.shopId,
    required this.isAdmin,
    this.uid,
  });

  // FundWeave Brand Colors
  static const Color _primaryBlue = Color(0xFF0F4CFF);
  static const Color _darkNavy = Color(0xFF0A1F44);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receiptsAsync = isAdmin
        ? ref.watch(shopReceiptsProvider(shopId))
        : ref.watch(memberReceiptsProvider(uid ?? ''));

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9), // Light premium background
      appBar: AppBar(
        title: Text(isAdmin ? 'All Receipts' : 'My Receipts', 
            style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        backgroundColor: _darkNavy,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: receiptsAsync.when(
        data: (receipts) {
          if (receipts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_outlined,
                      size: 80, color: _primaryBlue.withOpacity(0.3)),
                  const SizedBox(height: 16),
                  Text(
                    'No receipts found.',
                    style: TextStyle(color: _darkNavy.withOpacity(0.6), fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Receipts are generated automatically\nwhen payments are confirmed.',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }
          final sorted = [...receipts]
            ..sort((a, b) => b.receiptNumber.compareTo(a.receiptNumber));
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sorted.length,
            itemBuilder: (context, i) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ReceiptCard(receipt: sorted[i]),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: _primaryBlue)),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ErrorMessage(message: e.toString()),
          ),
        ),
      ),
    );
  }
}