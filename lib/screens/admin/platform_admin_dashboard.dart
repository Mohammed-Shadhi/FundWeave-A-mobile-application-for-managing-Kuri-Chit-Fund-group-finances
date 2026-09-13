import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/providers.dart';
import '../../models/shop_model.dart';
import '../../widgets/shared_widgets.dart';
import '../../utils/app_helpers.dart';

class PlatformAdminDashboard extends ConsumerStatefulWidget {
  final String uid;
  const PlatformAdminDashboard({super.key, required this.uid});

  @override
  ConsumerState<PlatformAdminDashboard> createState() =>
      _PlatformAdminDashboardState();
}

class _PlatformAdminDashboardState
    extends ConsumerState<PlatformAdminDashboard> {
  int _tab = 0;

  // FundWeave Brand Colors
  static const Color _primaryBlue = Color(0xFF0F4CFF);
  static const Color _primaryTeal = Color(0xFF14D8C4);
  static const Color _darkNavy = Color(0xFF0A1F44);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9), // Clean light background
      appBar: AppBar(
        title: const Text('Super Admin', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        backgroundColor: _darkNavy,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            tooltip: 'Logout',
            onPressed: () async {
              await ref.read(authServiceProvider).signOut();
            },
          ),
        ],
      ),
      body: Column(children: [
        // Custom Tab bar
        Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ]
          ),
          child: Row(children: [
            _tabBtn(0, 'Registered Shops', Icons.storefront),
            _tabBtn(1, 'Platform Stats', Icons.bar_chart),
          ]),
        ),
        
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: ref.read(shopServiceProvider).watchAllShops(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: _primaryBlue));
              }
              if (snap.hasError) {
                return Center(child: ErrorMessage(message: snap.error.toString()));
              }
              final allShops = snap.data?.docs
                      .map((doc) => ShopModel.fromMap(
                          doc.data() as Map<String, dynamic>, doc.id))
                      .toList() ??
                  [];

              if (_tab == 0) return _buildShopsTab(allShops);
              return _buildStatsTab(allShops);
            },
          ),
        ),
      ]),
    );
  }

  Widget _buildShopsTab(List<ShopModel> shops) {
    if (shops.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.domain_disabled, size: 70, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text('No shops registered yet.',
                style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.w500)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
      itemCount: shops.length,
      itemBuilder: (context, i) => _shopCard(shops[i]),
    );
  }

  Widget _buildStatsTab(List<ShopModel> all) {
    final approved = all.where((s) => s.status == 'approved').length;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Network Overview',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _darkNavy)),
        const SizedBox(height: 16),
        StatCard(title: 'Total Shops', value: '${all.length}',
            icon: Icons.store, color: _darkNavy),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: StatCard(title: 'Active Shops', value: '$approved',
                  icon: Icons.check_circle, color: _primaryTeal),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(title: 'Pending', value: '${all.length - approved}',
                  icon: Icons.pending_actions, color: Colors.orange.shade400),
            ),
          ],
        ),
        const SizedBox(height: 12),
        StatCard(title: 'Total Receipts Issued',
            value: '${all.fold(0, (s, shop) => s + shop.receiptCounter)}',
            icon: Icons.receipt_long, color: _primaryBlue),
      ]),
    );
  }

  Widget _shopCard(ShopModel shop) {
    final isApproved = shop.status.toLowerCase() == 'approved';
    final statusColor = isApproved ? _primaryTeal : Colors.orange;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200)
      ),
      color: Colors.white,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _primaryBlue.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.storefront, color: _primaryBlue, size: 24),
        ),
        title: Text(shop.name,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _darkNavy)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(shop.adminEmail,
                style: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            Text(shop.mobile1,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 4),
            Text('Registered: ${AppHelpers.formatDate(shop.createdAt)}',
                style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ]),
        ),
        isThreeLine: true,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: statusColor.withOpacity(0.5)),
              ),
              child: Text(shop.status.toUpperCase(),
                  style: TextStyle(
                      color: statusColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
            ),
          ],
        ),
        onTap: () => _showShopDetail(shop),
      ),
    );
  }

  void _showShopDetail(ShopModel shop) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(shop.name,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _darkNavy)),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          
          _detail(Icons.badge_outlined, 'Shop ID: ${shop.shopId}'),
          _detail(Icons.email_outlined, shop.adminEmail),
          _detail(Icons.phone_outlined, shop.mobile1),
          if (shop.mobile2.isNotEmpty) _detail(Icons.phone_android, shop.mobile2),
          _detail(Icons.location_on_outlined, shop.address),
          _detail(Icons.receipt_long, 'Total Receipts Issued: ${shop.receiptCounter}'),
          
          const SizedBox(height: 16),
          if (shop.hasUpi || shop.hasBankAccount) ...[
            Text('Payment Settings Configured:', 
                style: TextStyle(fontWeight: FontWeight.bold, color: _darkNavy, fontSize: 14)),
            const SizedBox(height: 8),
            if (shop.hasUpi) _detail(Icons.qr_code, 'UPI ID: ${shop.upiId}'),
            if (shop.hasBankAccount)
              _detail(Icons.account_balance, 'Bank: ${shop.accountNumber} (${shop.bankName})'),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200)
              ),
              child: const Row(children: [
                Icon(Icons.warning_amber, color: Colors.orange, size: 18),
                SizedBox(width: 8),
                Expanded(child: Text('No payment details configured by this shop yet.', style: TextStyle(color: Colors.orange, fontSize: 13))),
              ]),
            ),
          ],
          const SizedBox(height: 24),
        ]),
      ),
    );
  }

  Widget _detail(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 18, color: _primaryBlue),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: TextStyle(fontSize: 14, color: Colors.grey.shade800, fontWeight: FontWeight.w500))),
      ]),
    );
  }

  Widget _tabBtn(int index, String label, IconData icon) {
    final selected = _tab == index;
    return Expanded(child: GestureDetector(
      onTap: () => setState(() => _tab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? _darkNavy : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(children: [
          Icon(icon, color: selected ? Colors.white : Colors.grey.shade400, size: 22),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(
            color: selected ? Colors.white : Colors.grey.shade500,
            fontSize: 12,
            fontWeight: selected ? FontWeight.bold : FontWeight.w500,
          )),
        ]),
      ),
    ));
  }
}