import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../../widgets/shared_widgets.dart';
import '../../utils/app_helpers.dart';

class KuriDetailScreen extends ConsumerWidget {
  final String kuriId;
  final String shopId;
  final String shopName;
  final bool isAdmin;

  const KuriDetailScreen({
    super.key,
    required this.kuriId,
    required this.shopId,
    required this.shopName,
    required this.isAdmin,
  });

  static const Color _primaryBlue = Color(0xFF0F4CFF);
  static const Color _primaryTeal = Color(0xFF14D8C4);
  static const Color _darkNavy    = Color(0xFF0A1F44);
  static const Color _goldAccent  = Color(0xFFFFB800);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivity = ref.watch(connectivityProvider);

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('kuris')
          .doc(kuriId)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              backgroundColor: Color(0xFFF4F6F9),
              body: Center(
                  child: CircularProgressIndicator(color: _primaryBlue)));
        }
        if (!snap.hasData || !snap.data!.exists) {
          return const Scaffold(
              backgroundColor: Color(0xFFF4F6F9),
              body: Center(
                  child: Text('Pool not found.',
                      style: TextStyle(color: Colors.grey))));
        }

        final kuri = KuriModel.fromMap(
            snap.data!.data() as Map<String, dynamic>, kuriId);
        final paymentsAsync = ref.watch(kuriPaymentsProvider(kuriId));

        return Scaffold(
          backgroundColor: const Color(0xFFF4F6F9),
          appBar: AppBar(
            title: Text(kuri.title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, letterSpacing: 0.5)),
            backgroundColor: _darkNavy,
            foregroundColor: Colors.white,
            elevation: 0,
            actions: [
              if (isAdmin && kuri.status == 'active')
                PopupMenuButton<String>(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  onSelected: (val) async {
                    if (val == 'complete') {
                      final confirm = await _confirmDialog(
                          context, 'Mark as Completed?',
                          'This will end the pool group.');
                      if (confirm) {
                        await ref
                            .read(kuriServiceProvider)
                            .updateStatus(kuriId, 'completed');
                        if (context.mounted) Navigator.pop(context);
                      }
                    } else if (val == 'delete') {
                      final confirm = await _confirmDialog(
                          context, 'Delete Pool?',
                          'This cannot be undone.',
                          isDanger: true);
                      if (confirm) {
                        await ref
                            .read(kuriServiceProvider)
                            .deleteKuri(kuriId);
                        if (context.mounted) Navigator.pop(context);
                      }
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                        value: 'complete',
                        child: Row(children: [
                          Icon(Icons.done_all,
                              color: _primaryTeal, size: 20),
                          SizedBox(width: 10),
                          Text('Mark Complete',
                              style: TextStyle(fontWeight: FontWeight.w500))
                        ])),
                    const PopupMenuItem(
                        value: 'delete',
                        child: Row(children: [
                          Icon(Icons.delete_outline,
                              color: Colors.redAccent, size: 20),
                          SizedBox(width: 10),
                          Text('Delete',
                              style: TextStyle(
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.w500))
                        ])),
                  ],
                ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!connectivity.isOnline) const OfflineBanner(),

                  // ── Premium Summary Card ──
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
                          Row(
                            children: [
                              Expanded(
                                child: Text(kuri.title,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold)),
                              ),
                              if (kuri.status == 'completed')
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                        color:
                                            Colors.white.withOpacity(0.4)),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.verified,
                                          color: Colors.white, size: 14),
                                      SizedBox(width: 4),
                                      Text('Completed',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight:
                                                  FontWeight.bold)),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(shopName,
                              style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500)),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 16, horizontal: 12),
                            decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color:
                                        Colors.white.withOpacity(0.2))),
                            child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  _summaryItem('Monthly',
                                      AppHelpers.formatAmount(
                                          kuri.monthlyAmount)),
                                  Container(
                                      width: 1,
                                      height: 30,
                                      color:
                                          Colors.white.withOpacity(0.3)),
                                  _summaryItem(
                                      'Pool',
                                      AppHelpers.formatAmount(
                                          kuri.totalPool)),
                                  Container(
                                      width: 1,
                                      height: 30,
                                      color:
                                          Colors.white.withOpacity(0.3)),
                                  _summaryItem(
                                      'Month',
                                      '${kuri.currentMonth > kuri.totalMonths ? kuri.totalMonths : kuri.currentMonth}/${kuri.totalMonths}'),
                                ]),
                          ),
                        ]),
                  ),
                  const SizedBox(height: 24),

                  // ── Conduct Draw Button ──
                  if (isAdmin && kuri.status == 'active')
                    connectivity.isOnline
                        ? Padding(
                            padding: const EdgeInsets.only(bottom: 24),
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => _showConductDrawDialog(
                                    context, ref, kuri),
                                icon: const Icon(Icons.emoji_events,
                                    size: 22),
                                label: Text(
                                    'Conduct Draw — Month ${kuri.currentMonth}',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _darkNavy,
                                  foregroundColor: _goldAccent,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 16),
                                  elevation: 4,
                                  shadowColor:
                                      _darkNavy.withOpacity(0.4),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(14)),
                                ),
                              ),
                            ),
                          )
                        : Container(
                            margin: const EdgeInsets.only(bottom: 24),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border:
                                  Border.all(color: Colors.red.shade200),
                            ),
                            child: const Row(children: [
                              Icon(Icons.wifi_off,
                                  color: Colors.red, size: 20),
                              SizedBox(width: 12),
                              Text('Go online to conduct the draw.',
                                  style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500)),
                            ]),
                          ),

                  // ── Completed notice ──
                  if (kuri.status == 'completed')
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 24),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _primaryTeal.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: _primaryTeal.withOpacity(0.3)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.verified,
                            color: _primaryTeal, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'All ${kuri.totalMonths} draws have been completed. '
                            'This pool is now closed.',
                            style: TextStyle(
                                color: _darkNavy.withOpacity(0.8),
                                fontSize: 14,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                      ]),
                    ),

                  // ── Pending Approvals ──
                  if (isAdmin)
                    paymentsAsync.when(
                      data: (payments) {
                        final pending = payments
                            .where((p) => p.isPendingApproval)
                            .toList();
                        if (pending.isEmpty)
                          return const SizedBox.shrink();
                        return _buildPendingApprovals(
                            context, ref, pending, kuri);
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),

                  // ── Payment Summary ──
                  if (isAdmin)
                    paymentsAsync.when(
                      data: (payments) =>
                          _buildPaymentSummary(payments, kuri),
                      loading: () => const Center(
                          child: CircularProgressIndicator(
                              color: _primaryBlue)),
                      error: (e, _) =>
                          ErrorMessage(message: e.toString()),
                    ),

                  const SizedBox(height: 12),

                  // ── Winners History ──
                  Text('Winners History',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: _darkNavy)),
                  const SizedBox(height: 16),

                  if (kuri.winnersHistory.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.military_tech_outlined,
                              size: 40, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          const Text('No draws conducted yet.',
                              style: TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500),
                              textAlign: TextAlign.center),
                        ],
                      ),
                    )
                  else
                    ...kuri.winnersHistory.map((w) => Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            border: Border.all(
                                color: _goldAccent.withOpacity(0.3)),
                          ),
                          child: Row(children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: _goldAccent.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.emoji_events,
                                  color: _goldAccent, size: 22),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(w['name'] ?? '',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: _darkNavy)),
                                    const SizedBox(height: 2),
                                    Text('Won Month ${w['month']}',
                                        style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 13,
                                            fontWeight:
                                                FontWeight.w500)),
                                  ]),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: _goldAccent.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text('Month ${w['month']}',
                                  style: TextStyle(
                                      color: _goldAccent.withOpacity(0.8),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ]),
                        )),

                  const SizedBox(height: 40),
                ]),
          ),
        );
      },
    );
  }

  // ══════════════════════════════════════════
  // CONDUCT DRAW DIALOG
  // ══════════════════════════════════════════
  Future<void> _showConductDrawDialog(
      BuildContext context, WidgetRef ref, KuriModel kuri) async {
    final result = await ref.read(
      eligibleMembersProvider((
        kuriId:       kuriId,
        currentMonth: kuri.currentMonth,
      )).future,
    );

    if (!context.mounted) return;

    if (result.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: ${result.error}',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
      ));
      return;
    }

    final isLastMonth = kuri.currentMonth >= kuri.totalMonths;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _ConductDrawDialog(
        kuri:        kuri,
        eligible:    result.eligible,
        isLastMonth: isLastMonth,
        onConfirm:   (winnerUid, winnerName) async {
          Navigator.pop(ctx);
          await _executeDraw(
            context:     context,
            ref:         ref,
            kuri:        kuri,
            winnerUid:   winnerUid,
            winnerName:  winnerName,
            isLastMonth: isLastMonth,
          );
        },
      ),
    );
  }

  Future<void> _executeDraw({
    required BuildContext context,
    required WidgetRef ref,
    required KuriModel kuri,
    required String winnerUid,
    required String winnerName,
    required bool isLastMonth,
  }) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        content: Row(children: [
          const CircularProgressIndicator(color: _primaryBlue),
          const SizedBox(width: 20),
          Expanded(
            child: Text(
              isLastMonth
                  ? 'Completing final draw...'
                  : 'Recording draw result...',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ]),
      ),
    );

    final err = await ref.read(kuriServiceProvider).conductDraw(
          kuriId:       kuriId,
          winnerUid:    winnerUid,
          winnerName:   winnerName,
          currentMonth: kuri.currentMonth,
        );

    if (!context.mounted) return;
    Navigator.pop(context); // close loading

    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $err',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
      ));
      return;
    }

    final message = isLastMonth
        ? '🏆 Final draw complete! $winnerName wins Month ${kuri.currentMonth}. '
            'This pool is now closed.'
        : '🏆 $winnerName wins Month ${kuri.currentMonth}! '
            'Month ${kuri.currentMonth + 1} is now active.';

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message,
          style: const TextStyle(fontWeight: FontWeight.bold)),
      backgroundColor: _primaryTeal,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 5),
    ));

    if (isLastMonth && context.mounted) {
      Navigator.pop(context);
    }
  }

  // ══════════════════════════════════════════
  // PENDING APPROVALS
  // ══════════════════════════════════════════
  Widget _buildPendingApprovals(
    BuildContext context,
    WidgetRef ref,
    List<PaymentModel> pending,
    KuriModel kuri,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text('Pending Approvals',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: _darkNavy)),
          const SizedBox(width: 10),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('${pending.length}',
                style: TextStyle(
                    color: Colors.orange.shade800,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
          ),
        ]),
        const SizedBox(height: 12),
        ...pending.map((p) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.amber.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.access_time_rounded,
                            color: Colors.amber.shade700, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.memberName,
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: _darkNavy)),
                            Text(
                                'Month ${p.month}  •  ${AppHelpers.formatAmount(p.amount)}',
                                style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 13)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.amber.shade300),
                        ),
                        child: Text('Pending',
                            style: TextStyle(
                                color: Colors.amber.shade800,
                                fontWeight: FontWeight.bold,
                                fontSize: 12)),
                      ),
                    ]),
                    if (p.transactionId.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(10),
                          border:
                              Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(children: [
                          Icon(Icons.tag,
                              size: 16, color: Colors.grey.shade500),
                          const SizedBox(width: 8),
                          Text('TXN ID: ',
                              style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 13)),
                          Expanded(
                            child: SelectableText(
                              p.transactionId,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: _darkNavy,
                                  letterSpacing: 0.5),
                            ),
                          ),
                        ]),
                      ),
                    ],
                    if (p.note.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.notes,
                                size: 15,
                                color: Colors.blue.shade400),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(p.note,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue.shade700,
                                      height: 1.4)),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (p.submittedAt != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Submitted: ${AppHelpers.formatDate(p.submittedAt!)}',
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500),
                      ),
                    ],
                    const SizedBox(height: 14),
                    const Divider(height: 1),
                    const SizedBox(height: 14),
                    Row(children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              _rejectPayment(context, ref, p),
                          icon: const Icon(Icons.close,
                              size: 18, color: Colors.redAccent),
                          label: const Text('Reject',
                              style: TextStyle(
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                                color: Colors.red.shade200),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(
                                vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              _approvePayment(context, ref, p, kuri),
                          icon: const Icon(Icons.check, size: 18),
                          label: const Text('Approve',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryTeal,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(
                                vertical: 12),
                          ),
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
            )),
        const SizedBox(height: 8),
      ],
    );
  }

  Future<void> _approvePayment(BuildContext context, WidgetRef ref,
      PaymentModel p, KuriModel kuri) async {
    final confirm = await _confirmDialog(
      context,
      'Approve Payment?',
      'Confirm that ${p.memberName} paid ${AppHelpers.formatAmount(p.amount)} '
          'for Month ${p.month}. A receipt will be generated automatically.',
    );
    if (!confirm || !context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        content: const Row(children: [
          CircularProgressIndicator(color: _primaryBlue),
          SizedBox(width: 20),
          Text('Approving payment...',
              style: TextStyle(fontWeight: FontWeight.w500)),
        ]),
      ),
    );

    final err = await ref.read(paymentServiceProvider).approvePayment(
          paymentId:     p.paymentId,
          shopId:        shopId,
          shopName:      shopName,
          uid:           p.uid,
          memberName:    p.memberName,
          memberId:      p.memberId,
          kuriId:        kuriId,
          kuriName:      kuri.title,
          month:         p.month,
          amount:        p.amount,
          transactionId: p.transactionId,
        );

    if (context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            err != null
                ? 'Error: $err'
                : '✓ Payment approved & receipt generated',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: err != null ? Colors.redAccent : _primaryTeal,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  Future<void> _rejectPayment(
      BuildContext context, WidgetRef ref, PaymentModel p) async {
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.close,
                color: Colors.redAccent, size: 22),
          ),
          const SizedBox(width: 12),
          const Text('Reject Payment',
              style: TextStyle(fontWeight: FontWeight.bold)),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Reject ${p.memberName}\'s payment of '
                '${AppHelpers.formatAmount(p.amount)} for Month ${p.month}?',
                style: TextStyle(fontSize: 14, color: _darkNavy)),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Reason (optional)',
                hintStyle: TextStyle(
                    color: Colors.grey.shade400, fontSize: 13),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel',
                  style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Reject',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final err = await ref.read(paymentServiceProvider).rejectPayment(
          paymentId:     p.paymentId,
          rejectionNote: reasonController.text.trim(),
        );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            err != null ? 'Error: $err' : 'Payment rejected.',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor:
            err != null ? Colors.redAccent : Colors.grey.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  Widget _buildPaymentSummary(
      List<PaymentModel> payments, KuriModel kuri) {
    final approved = payments
        .where((p) => p.isApproved && p.month == kuri.currentMonth)
        .toList();
    final collected = approved.fold(0.0, (sum, p) => sum + p.amount);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Month ${kuri.currentMonth} Payments',
          style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: _darkNavy)),
      const SizedBox(height: 16),
      Row(children: [
        Expanded(
            child: StatCard(
          title: 'Paid',
          value: '${approved.length}/${kuri.totalMembers}',
          icon: Icons.how_to_reg,
          color: _primaryTeal,
        )),
        const SizedBox(width: 12),
        Expanded(
            child: StatCard(
          title: 'Collected',
          value: AppHelpers.formatAmount(collected),
          icon: Icons.account_balance_wallet,
          color: _primaryBlue,
        )),
      ]),
      const SizedBox(height: 20),
      if (approved.isNotEmpty) ...[
        Text('Approved Payments (${approved.length})',
            style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: _darkNavy)),
        const SizedBox(height: 12),
        ...approved.map((p) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 4),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _primaryTeal.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check,
                      color: _primaryTeal, size: 18),
                ),
                title: Text(p.memberName,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _darkNavy)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.memberId,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.grey)),
                    if (p.transactionId.isNotEmpty)
                      Text('TXN: ${p.transactionId}',
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500)),
                  ],
                ),
                isThreeLine: p.transactionId.isNotEmpty,
                trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(AppHelpers.formatAmount(p.amount),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: _primaryTeal)),
                      const SizedBox(height: 4),
                      Text(
                          AppHelpers.formatDate(
                              p.paymentDate ?? p.submittedAt),
                          style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500)),
                    ]),
              ),
            )),
      ],
      const SizedBox(height: 16),
    ]);
  }

  Future<bool> _confirmDialog(
      BuildContext context, String title, String content,
      {bool isDanger = false}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(content, style: const TextStyle(fontSize: 15)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel',
                  style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isDanger ? Colors.redAccent : _primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Confirm',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Widget _summaryItem(String label, String value) => Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(label,
              style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
        ],
      );
}

// ══════════════════════════════════════════
// CONDUCT DRAW DIALOG
// ══════════════════════════════════════════
class _ConductDrawDialog extends StatefulWidget {
  final KuriModel kuri;
  final List<Map<String, dynamic>> eligible;
  final bool isLastMonth;
  final Future<void> Function(String winnerUid, String winnerName) onConfirm;

  const _ConductDrawDialog({
    required this.kuri,
    required this.eligible,
    required this.isLastMonth,
    required this.onConfirm,
  });

  @override
  State<_ConductDrawDialog> createState() => _ConductDrawDialogState();
}

class _ConductDrawDialogState extends State<_ConductDrawDialog> {
  static const Color _darkNavy   = Color(0xFF0A1F44);
  static const Color _goldAccent = Color(0xFFFFB800);

  String? _selectedUid;
  String? _selectedName;
  bool    _confirming = false;

  @override
  Widget build(BuildContext context) {
    final hasEligible = widget.eligible.isNotEmpty;

    return AlertDialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      title: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _goldAccent.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.emoji_events,
              color: _goldAccent, size: 26),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Conduct Draw',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18)),
              Text('Month ${widget.kuri.currentMonth}',
                  style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 13,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ]),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Final month banner
            if (widget.isLastMonth)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _goldAccent.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border:
                      Border.all(color: _goldAccent.withOpacity(0.4)),
                ),
                child: Row(children: [
                  const Icon(Icons.stars, color: _goldAccent, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This is the final draw. The pool will be marked '
                      'as completed after confirming.',
                      style: TextStyle(
                          color: Colors.orange.shade800,
                          fontSize: 12,
                          height: 1.4),
                    ),
                  ),
                ]),
              ),

            // No eligible members
            if (!hasEligible)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(children: [
                  const Icon(Icons.person_off,
                      color: Colors.redAccent, size: 32),
                  const SizedBox(height: 8),
                  const Text('No eligible members',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.redAccent)),
                  const SizedBox(height: 4),
                  Text(
                    'All members must have approved payments for every '
                    'month up to Month ${widget.kuri.currentMonth}, '
                    'and must not have won previously.',
                    style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 12,
                        height: 1.4),
                    textAlign: TextAlign.center,
                  ),
                ]),
              )
            else ...[
              Text(
                'Select the winner for Month ${widget.kuri.currentMonth}:',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: _darkNavy),
              ),
              const SizedBox(height: 4),
              Text(
                '${widget.eligible.length} eligible '
                'member${widget.eligible.length == 1 ? '' : 's'}',
                style:
                    TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
              const SizedBox(height: 12),

              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 280),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: widget.eligible.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final member     = widget.eligible[i];
                    final uid        = member['uid'] as String;
                    final name       = member['name'] as String;
                    final isSelected = _selectedUid == uid;

                    return GestureDetector(
                      onTap: () => setState(() {
                        _selectedUid  = uid;
                        _selectedName = name;
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? _goldAccent.withOpacity(0.08)
                              : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? _goldAccent
                                : Colors.grey.shade200,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? _goldAccent.withOpacity(0.2)
                                  : Colors.grey.shade200,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                name.isNotEmpty
                                    ? name[0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: isSelected
                                        ? _goldAccent
                                        : Colors.grey.shade600),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(name,
                                style: TextStyle(
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    fontSize: 14,
                                    color: isSelected
                                        ? _darkNavy
                                        : Colors.grey.shade800)),
                          ),
                          if (isSelected)
                            const Icon(Icons.check_circle,
                                color: _goldAccent, size: 22),
                        ]),
                      ),
                    );
                  },
                ),
              ),
            ],

            if (hasEligible) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade100),
                ),
                child: const Row(children: [
                  Icon(Icons.warning_amber, color: Colors.red, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This action is permanent and cannot be undone.',
                      style: TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ]),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _confirming ? null : () => Navigator.pop(context),
          child: const Text('Cancel',
              style: TextStyle(color: Colors.grey)),
        ),
        if (hasEligible)
          ElevatedButton.icon(
            onPressed: (_selectedUid == null || _confirming)
                ? null
                : () async {
                    setState(() => _confirming = true);
                    await widget.onConfirm(
                        _selectedUid!, _selectedName!);
                  },
            icon: _confirming
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.emoji_events, size: 18),
            label: Text(
              _confirming
                  ? 'Confirming...'
                  : _selectedUid == null
                      ? 'Select a Member'
                      : 'Confirm Winner',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  _selectedUid != null && !_confirming
                      ? _darkNavy
                      : Colors.grey.shade400,
              foregroundColor:
                  _selectedUid != null && !_confirming
                      ? _goldAccent
                      : Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
            ),
          ),
      ],
    );
  }
}