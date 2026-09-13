import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../../widgets/shared_widgets.dart';
import '../../utils/app_helpers.dart';
import '../shared/receipt_list_screen.dart';
import 'payment_info_screen.dart';

class MemberKuriDetailScreen extends ConsumerWidget {
  final String kuriId;
  final String shopId;
  final String shopName;
  final String uid;

  const MemberKuriDetailScreen({
    super.key,
    required this.kuriId,
    required this.shopId,
    required this.shopName,
    required this.uid,
  });

  // FundWeave Brand Colors
  static const Color _primaryBlue = Color(0xFF0F4CFF);
  static const Color _primaryTeal = Color(0xFF14D8C4);
  static const Color _darkNavy    = Color(0xFF0A1F44);
  static const Color _goldAccent  = Color(0xFFFFB800);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(myKuriPaymentsProvider(kuriId));

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('kuris')
          .doc(kuriId)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(
            backgroundColor: Color(0xFFF4F6F9),
            body: Center(
                child: CircularProgressIndicator(color: _primaryBlue)));
        }
        if (!snap.data!.exists) {
          return const Scaffold(
            backgroundColor: Color(0xFFF4F6F9),
            body: Center(
                child: Text('Pool not found',
                    style: TextStyle(color: Colors.grey))));
        }

        final kuri = KuriModel.fromMap(
            snap.data!.data() as Map<String, dynamic>, kuriId);
        final hasWon =
            kuri.winnersHistory.any((w) => w['uid'] == uid);
        final myWinList =
            kuri.winnersHistory.where((w) => w['uid'] == uid).toList();
        final myWin = myWinList.isNotEmpty ? myWinList.first : null;

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
              IconButton(
                icon: const Icon(Icons.receipt_long),
                tooltip: 'My Receipts',
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => ReceiptListScreen(
                            shopId: shopId,
                            isAdmin: false,
                            uid: uid))),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                      Text(kuri.title,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold)),
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
                              color: Colors.white.withOpacity(0.2)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _summaryItem('Monthly',
                                AppHelpers.formatAmount(kuri.monthlyAmount)),
                            Container(
                                width: 1,
                                height: 30,
                                color: Colors.white.withOpacity(0.3)),
                            _summaryItem('Total Pool',
                                AppHelpers.formatAmount(kuri.totalPool)),
                            Container(
                                width: 1,
                                height: 30,
                                color: Colors.white.withOpacity(0.3)),
                            _summaryItem('Progress',
                                '${kuri.currentMonth}/${kuri.totalMonths}'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Won Banner ──
                if (hasWon)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: _goldAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border:
                          Border.all(color: _goldAccent.withOpacity(0.5)),
                    ),
                    child: Row(children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _goldAccent.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.emoji_events,
                            color: _goldAccent, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                                'Congratulations! You won this pool.',
                                style: TextStyle(
                                    color: Color(0xFFB78500),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15)),
                            if (myWin != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                    'Won in Month ${myWin['month']}',
                                    style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500)),
                              ),
                          ],
                        ),
                      ),
                    ]),
                  ),

                // ── My Payment Status ──
                Text('My Monthly Payments',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: _darkNavy)),
                const SizedBox(height: 16),

                paymentsAsync.when(
                  data: (myPayments) {
                    final paidMonths = myPayments
                        .where((p) => p.isApproved)
                        .map((p) => p.month)
                        .toSet();
                    final pendingMonths = myPayments
                        .where((p) => p.isPendingApproval)
                        .map((p) => p.month)
                        .toSet();

                    final paidCount = paidMonths.length;
                    final dueCount =
                        ((kuri.currentMonth - 1) - paidCount)
                            .clamp(0, 999);
                    final totalOwed = dueCount * kuri.monthlyAmount;

                    final currentMonthPaid =
                        paidMonths.contains(kuri.currentMonth);
                    final currentMonthPending =
                        pendingMonths.contains(kuri.currentMonth);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Stats row
                        Row(children: [
                          Expanded(
                              child: _paymentStat(
                                  'Paid', '$paidCount months', _primaryTeal)),
                          const SizedBox(width: 12),
                          Expanded(
                              child: _paymentStat(
                                  'Due',
                                  dueCount > 0
                                      ? '$dueCount months'
                                      : 'None',
                                  dueCount > 0
                                      ? Colors.orange.shade600
                                      : _primaryTeal)),
                          const SizedBox(width: 12),
                          Expanded(
                              child: _paymentStat(
                                  'Remaining',
                                  '${(kuri.totalMonths - kuri.currentMonth + 1).clamp(0, 999)}',
                                  _primaryBlue)),
                        ]),
                        const SizedBox(height: 24),

                        // Due amount warning
                        if (dueCount > 0)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border:
                                  Border.all(color: Colors.red.shade200),
                            ),
                            child: Row(children: [
                              const Icon(Icons.warning_amber,
                                  color: Colors.redAccent, size: 22),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  '$dueCount unpaid month${dueCount > 1 ? 's' : ''}. '
                                  'Total due: ${AppHelpers.formatAmount(totalOwed)}',
                                  style: const TextStyle(
                                      color: Colors.redAccent,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ]),
                          ),

                        // ── PAY NOW button ──
                        if (kuri.status == 'active' &&
                            !currentMonthPaid &&
                            !currentMonthPending)
                          Container(
                            margin: const EdgeInsets.only(bottom: 24),
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PaymentInfoScreen(
                                    shopId:    shopId,
                                    kuriTitle: kuri.title,
                                    amount:    kuri.monthlyAmount,
                                    month:     kuri.currentMonth,
                                  ),
                                ),
                              ),
                              icon: const Icon(Icons.payment, size: 22),
                              label: Text(
                                  'Pay Month ${kuri.currentMonth} — ${AppHelpers.formatAmount(kuri.monthlyAmount)}',
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _primaryBlue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 16),
                                elevation: 4,
                                shadowColor:
                                    _primaryBlue.withOpacity(0.4),
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(14)),
                              ),
                            ),
                          ),

                        // ── Pending approval banner ──
                        if (currentMonthPending && !currentMonthPaid)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            margin: const EdgeInsets.only(bottom: 24),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: Colors.amber.shade300),
                            ),
                            child: Row(children: [
                              Icon(Icons.access_time_rounded,
                                  color: Colors.amber.shade700, size: 22),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Month ${kuri.currentMonth} — Pending Approval',
                                      style: TextStyle(
                                          color: Colors.amber.shade800,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Your payment is being reviewed by the admin.',
                                      style: TextStyle(
                                          color: Colors.amber.shade700,
                                          fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ]),
                          ),

                        // ── Paid banner ──
                        if (kuri.status == 'active' && currentMonthPaid)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            margin: const EdgeInsets.only(bottom: 24),
                            decoration: BoxDecoration(
                              color: _primaryTeal.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: _primaryTeal.withOpacity(0.3)),
                            ),
                            child: Row(children: [
                              const Icon(Icons.check_circle,
                                  color: _primaryTeal, size: 22),
                              const SizedBox(width: 12),
                              Text(
                                  'Current month installment is paid ✓',
                                  style: TextStyle(
                                      color: _darkNavy.withOpacity(0.8),
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold)),
                            ]),
                          ),

                        // ── Month grid ──
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border:
                                Border.all(color: Colors.grey.shade200),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Installment Tracker',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15)),
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: List.generate(
                                  kuri.totalMonths,
                                  (i) {
                                    final month     = i + 1;
                                    final isPaid    = paidMonths.contains(month);
                                    final isPending = pendingMonths.contains(month);
                                    final isFuture  = month > kuri.currentMonth;

                                    Color boxColor, borderColor, textColor;
                                    IconData iconData;

                                    if (isPaid) {
                                      boxColor    = _primaryTeal;
                                      borderColor = _primaryTeal;
                                      textColor   = Colors.white;
                                      iconData    = Icons.check_circle;
                                    } else if (isPending) {
                                      boxColor    = Colors.amber.shade50;
                                      borderColor = Colors.amber.shade400;
                                      textColor   = Colors.amber.shade800;
                                      iconData    = Icons.access_time_rounded;
                                    } else if (isFuture) {
                                      boxColor    = const Color(0xFFF1F5F9);
                                      borderColor = Colors.grey.shade300;
                                      textColor   = Colors.grey.shade500;
                                      iconData    = Icons.lock;
                                    } else {
                                      boxColor    = const Color(0xFFFFF7ED);
                                      borderColor = Colors.orange.shade300;
                                      textColor   = Colors.orange.shade800;
                                      iconData    = Icons.payment;
                                    }

                                    return GestureDetector(
                                      onTap: (!isPaid &&
                                              !isPending &&
                                              !isFuture)
                                          ? () => Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      PaymentInfoScreen(
                                                    shopId:    shopId,
                                                    kuriTitle: kuri.title,
                                                    amount:    kuri.monthlyAmount,
                                                    month:     month,
                                                  ),
                                                ),
                                              )
                                          : null,
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                            milliseconds: 200),
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          color: boxColor,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: Border.all(
                                              color: borderColor),
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(iconData,
                                                size: 16,
                                                color: textColor),
                                            const SizedBox(height: 2),
                                            Text('M$month',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight:
                                                      FontWeight.bold,
                                                  color: textColor,
                                                )),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 16),
                              Wrap(spacing: 12, runSpacing: 6, children: [
                                _legendItem(_primaryTeal, 'Paid'),
                                _legendItem(
                                    Colors.amber.shade400, 'Pending'),
                                _legendItem(
                                    Colors.orange.shade400, 'Due (Tap)'),
                                _legendItem(
                                    Colors.grey.shade300, 'Future'),
                              ]),
                            ],
                          ),
                        ),

                        // ── Payment history ──
                        if (myPayments.isNotEmpty) ...[
                          const SizedBox(height: 32),
                          Text('Payment History',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: _darkNavy)),
                          const SizedBox(height: 16),
                          ...myPayments.map((p) {
                            final statusColor = p.isApproved
                                ? _primaryTeal
                                : p.isPendingApproval
                                    ? Colors.amber.shade700
                                    : Colors.redAccent;
                            final statusIcon = p.isApproved
                                ? Icons.check
                                : p.isPendingApproval
                                    ? Icons.access_time_rounded
                                    : Icons.close;
                            final statusLabel = p.isApproved
                                ? 'Approved'
                                : p.isPendingApproval
                                    ? 'Pending Approval'
                                    : 'Rejected';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: Colors.grey.shade200),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        Colors.black.withOpacity(0.02),
                                    blurRadius: 5,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ListTile(
                                contentPadding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color:
                                        statusColor.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(statusIcon,
                                      color: statusColor, size: 20),
                                ),
                                title: Text(
                                  'Month ${p.month} — ${AppHelpers.monthLabel(kuri.startDate, p.month)}',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: _darkNavy),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    if (p.paymentDate != null)
                                      Text(
                                        AppHelpers.formatDate(
                                            p.paymentDate!),
                                        style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12,
                                            fontWeight:
                                                FontWeight.w500),
                                      ),
                                    if (p.transactionId.isNotEmpty)
                                      Text(
                                        'TXN: ${p.transactionId}',
                                        style: TextStyle(
                                            color:
                                                Colors.grey.shade500,
                                            fontSize: 11),
                                      ),
                                    Container(
                                      margin:
                                          const EdgeInsets.only(top: 4),
                                      padding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 3),
                                      decoration: BoxDecoration(
                                        color: statusColor
                                            .withOpacity(0.1),
                                        borderRadius:
                                            BorderRadius.circular(20),
                                      ),
                                      child: Text(statusLabel,
                                          style: TextStyle(
                                              color: statusColor,
                                              fontSize: 11,
                                              fontWeight:
                                                  FontWeight.bold)),
                                    ),
                                  ],
                                ),
                                isThreeLine: true,
                                trailing: Text(
                                  AppHelpers.formatAmount(p.amount),
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: statusColor,
                                      fontSize: 15),
                                ),
                              ),
                            );
                          }),
                        ],
                      ],
                    );
                  },
                  loading: () => const Center(
                      child:
                          CircularProgressIndicator(color: _primaryBlue)),
                  error: (e, _) => ErrorMessage(message: e.toString()),
                ),

                const SizedBox(height: 32),

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
                        const Text('No winners selected yet.',
                            style: TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.w500),
                            textAlign: TextAlign.center),
                      ],
                    ),
                  )
                else
                  ...kuri.winnersHistory.map((w) {
                    final isMe = w['uid'] == uid;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isMe
                            ? _goldAccent.withOpacity(0.05)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          if (!isMe)
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                        ],
                        border: Border.all(
                            color: isMe
                                ? _goldAccent.withOpacity(0.5)
                                : Colors.grey.shade200),
                      ),
                      child: Row(children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isMe
                                ? _goldAccent.withOpacity(0.1)
                                : Colors.grey.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.emoji_events,
                              color: isMe
                                  ? _goldAccent
                                  : Colors.grey.shade400,
                              size: 22),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(w['name'] ?? '',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: isMe
                                          ? const Color(0xFFB78500)
                                          : _darkNavy)),
                              const SizedBox(height: 2),
                              Text('Won Month ${w['month']}',
                                  style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                        if (isMe)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                                color: _goldAccent,
                                borderRadius:
                                    BorderRadius.circular(20)),
                            child: const Text('You 🏆',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold)),
                          ),
                      ]),
                    );
                  }),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
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

  Widget _paymentStat(String label, String value, Color color) =>
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(children: [
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 15)),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                  fontWeight: FontWeight.w500)),
        ]),
      );

  Widget _legendItem(Color color, String label) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.w500)),
      ]);
}