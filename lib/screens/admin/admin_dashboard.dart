import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';
import '../../widgets/shared_widgets.dart';
import '../../utils/app_helpers.dart';
// REMOVED: import '../auth/login_screen.dart'; // Cleared the unused import warning
import '../shared/receipt_list_screen.dart';
import 'create_kuri_screen.dart';
import 'member_list_screen.dart';
import 'kuri_detail_screen.dart';
import 'shop_payment_settings_screen.dart';

class AdminDashboard extends ConsumerStatefulWidget {
  final String shopId;
  final String shopName;
  final String uid;
  
  const AdminDashboard({
    super.key,
    required this.shopId,
    required this.shopName,
    required this.uid,
  });

  @override
  ConsumerState<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends ConsumerState<AdminDashboard> {
  int _tab = 0;

  // FundWeave Premium Brand Colors
  final Color _primaryBlue = const Color(0xFF0F4CFF);
  final Color _primaryTeal = const Color(0xFF14D8C4);
  final Color _darkNavy = const Color(0xFF0A1F44);

  @override
  Widget build(BuildContext context) {
    final connectivity = ref.watch(connectivityProvider);
    final kurisAsync = ref.watch(shopKurisProvider(widget.shopId));
    final membersAsync = ref.watch(shopMembersProvider(widget.shopId));
    final shopAsync = ref.watch(shopStreamProvider(widget.shopId));

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9), // Light clean background
      appBar: AppBar(
        title: Text(widget.shopName, style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1)),
        backgroundColor: _darkNavy, // FundWeave Navy Header
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long),
            tooltip: 'Receipts',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) =>
                    ReceiptListScreen(shopId: widget.shopId, isAdmin: true))),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (val) async {
              if (val == 'payment_settings') {
                Navigator.push(context, MaterialPageRoute(
                    builder: (_) => ShopPaymentSettingsScreen(shopId: widget.shopId)));
              } else if (val == 'logout') {
                await ref.read(authServiceProvider).signOut();
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'payment_settings',
                child: Row(children: [
                  Icon(Icons.account_balance, color: _primaryBlue, size: 20),
                  const SizedBox(width: 10),
                  const Text('Payment Settings'),
                ]),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(children: [
                  Icon(Icons.logout, color: Colors.redAccent, size: 20),
                  const SizedBox(width: 10),
                  Text('Logout', style: TextStyle(color: Colors.redAccent)),
                ]),
              ),
            ],
          ),
        ],
      ),
      body: Column(children: [
        if (!connectivity.isOnline) const OfflineBanner(),

        // Payment Settings Warning if not set
        shopAsync.when(
          data: (shop) {
            if (shop == null) return const SizedBox.shrink();
            if (!shop.hasAnyPaymentMethod) {
              return GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => ShopPaymentSettingsScreen(shopId: widget.shopId))),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  color: const Color(0xFFE63946), // A sharp, modern red for alerts
                  child: const Row(children: [
                    Icon(Icons.warning_amber, color: Colors.white, size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'No payment details set. Tap to add UPI/Bank details for members.',
                        style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, color: Colors.white, size: 14),
                  ]),
                ),
              );
            }
            return const SizedBox.shrink();
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),

        // Custom Tab bar
        Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ]
          ),
          child: Row(children: [
            _tabBtn(0, 'Dashboard', Icons.dashboard),
            _tabBtn(1, 'Kuris', Icons.savings),
            _tabBtn(2, 'Members', Icons.people),
          ]),
        ),

        Expanded(child: _tab == 0
            ? _buildDashboard(kurisAsync, membersAsync)
            : _tab == 1
                ? _buildKuriTab(kurisAsync)
                : _buildMembersTab()),
      ]),

      floatingActionButton: _tab == 1
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) =>
                      CreateKuriScreen(shopId: widget.shopId))),
              icon: const Icon(Icons.add),
              label: const Text('New Kuri', style: TextStyle(fontWeight: FontWeight.bold)),
              backgroundColor: _primaryBlue,
              foregroundColor: Colors.white,
              elevation: 4,
            )
          : _tab == 2
              ? FloatingActionButton.extended(
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => MemberListScreen(
                        shopId: widget.shopId,
                        shopName: widget.shopName,
                        uid: widget.uid,
                      ))),
                  icon: const Icon(Icons.person_add),
                  label: const Text('Add Member', style: TextStyle(fontWeight: FontWeight.bold)),
                  backgroundColor: _primaryTeal,
                  foregroundColor: Colors.white,
                  elevation: 4,
                )
              : null,
    );
  }

  Widget _buildDashboard(AsyncValue kurisAsync, AsyncValue membersAsync) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const PaymentPendingBanner(),
        const SizedBox(height: 12),
        Text('Overview',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _darkNavy)),
        const SizedBox(height: 16),
        kurisAsync.when(
          data: (kuris) {
            final active = kuris.where((k) => k.status == 'active').length;
            final pool = kuris
                .where((k) => k.status == 'active')
                .fold(0.0, (sum, k) => sum + k.totalPool);
            return Column(children: [
              Row(children: [
                Expanded(child: StatCard(
                  title: 'Total Kuris',
                  value: '${kuris.length}',
                  icon: Icons.savings,
                  color: _primaryBlue,
                  onTap: () => setState(() => _tab = 1),
                )),
                const SizedBox(width: 12),
                Expanded(child: StatCard(
                  title: 'Active',
                  value: '$active',
                  icon: Icons.check_circle,
                  color: _primaryTeal,
                )),
              ]),
              const SizedBox(height: 12),
              membersAsync.when(
                data: (members) => StatCard(
                  title: 'Total Members',
                  value: '${members.length}',
                  icon: Icons.people,
                  color: _darkNavy,
                  onTap: () => setState(() => _tab = 2),
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 12),
              StatCard(
                title: 'Active Pool Value',
                value: AppHelpers.formatAmount(pool),
                icon: Icons.currency_rupee,
                color: _primaryBlue,
              ),
            ]);
          },
          loading: () => Center(child: CircularProgressIndicator(color: _primaryBlue)),
          error: (e, _) => ErrorMessage(message: e.toString()),
        ),
        const SizedBox(height: 28),
        Text('Quick Actions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _darkNavy)),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: _quickAction(
            'New Kuri', Icons.add_circle, _primaryBlue,
            () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => CreateKuriScreen(shopId: widget.shopId))),
          )),
          const SizedBox(width: 12),
          Expanded(child: _quickAction(
            'Members', Icons.person_add, _primaryTeal,
            () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => MemberListScreen(
                  shopId: widget.shopId,
                  shopName: widget.shopName,
                  uid: widget.uid,
                ))),
          )),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _quickAction(
            'Settings', Icons.account_balance, _darkNavy,
            () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => ShopPaymentSettingsScreen(shopId: widget.shopId))),
          )),
          const SizedBox(width: 12),
          Expanded(child: _quickAction(
            'Receipts', Icons.receipt_long, _primaryBlue,
            () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => ReceiptListScreen(shopId: widget.shopId, isAdmin: true))),
          )),
        ]),
      ]),
    );
  }

  Widget _buildKuriTab(AsyncValue kurisAsync) {
    return kurisAsync.when(
      data: (kuris) {
        if (kuris.isEmpty) {
          return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.savings_outlined, size: 70, color: _primaryBlue.withOpacity(0.5)),
            const SizedBox(height: 16),
            const Text('No kuri groups yet.',
                style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => CreateKuriScreen(shopId: widget.shopId))),
              icon: const Icon(Icons.add),
              label: const Text('Create Kuri', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryBlue, 
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ]));
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          itemCount: kuris.length,
          itemBuilder: (context, i) => _kuriCard(kuris[i]),
        );
      },
      loading: () => Center(child: CircularProgressIndicator(color: _primaryBlue)),
      error: (e, _) => Center(child: ErrorMessage(message: e.toString())),
    );
  }

  Widget _buildMembersTab() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.people_outline, size: 70, color: _primaryTeal.withOpacity(0.5)),
      const SizedBox(height: 16),
      const Text('View and manage members',
          style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.w500)),
      const SizedBox(height: 20),
      ElevatedButton.icon(
        onPressed: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => MemberListScreen(
              shopId: widget.shopId,
              shopName: widget.shopName,
              uid: widget.uid,
            ))),
        icon: const Icon(Icons.people),
        label: const Text('Open Member List', style: TextStyle(fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
            backgroundColor: _primaryTeal, 
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    ]));
  }

  Widget _kuriCard(kuri) {
    final isActive = kuri.status == 'active';
    final statusColor = isActive ? _primaryTeal : Colors.grey;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => KuriDetailScreen(
              kuriId: kuri.kuriId,
              shopId: widget.shopId,
              shopName: widget.shopName,
              isAdmin: true,
            ))),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: _primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.savings, color: _primaryBlue, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(kuri.title,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _darkNavy)),
                const SizedBox(height: 2),
                Text('Month ${kuri.currentMonth} of ${kuri.totalMonths}',
                    style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                ),
                child: Text(kuri.status.toUpperCase(),
                    style: TextStyle(
                        color: statusColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              ),
            ]),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: [
              _chip('${AppHelpers.formatAmount(kuri.monthlyAmount)}/mo', _primaryBlue),
              _chip('${kuri.totalMembers} members', _darkNavy),
              _chip('Pool: ${AppHelpers.formatAmount(kuri.totalPool)}', _primaryTeal),
            ]),
            if (kuri.lastWinner.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(children: [
                const Icon(Icons.emoji_events, color: Colors.amber, size: 16),
                const SizedBox(width: 6),
                Text('Last winner: ${kuri.lastWinner}',
                    style: const TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.w500)),
              ]),
            ],
          ]),
        ),
      ),
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
          color: selected ? _primaryBlue : Colors.transparent,
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

  Widget _quickAction(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.15), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ]
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: TextStyle(
              color: _darkNavy, 
              fontWeight: FontWeight.w700,
              fontSize: 13,
            )),
          ),
        ]),
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08), 
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.2))
      ),
      child: Text(label,
          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}