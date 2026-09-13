import 'package:cloud_firestore/cloud_firestore.dart';
import 'shop_service.dart';

// ══════════════════════════════════════════
// KURI SERVICE
// ══════════════════════════════════════════
class KuriService {
  final _db = FirebaseFirestore.instance;

  Future<String?> createKuri({
    required String shopId,
    required String title,
    required double monthlyAmount,
    required int totalMembers,
    required int totalMonths,
    required DateTime startDate,
  }) async {
    try {
      await _db.collection('kuris').add({
        'shopId':         shopId,
        'title':          title,
        'monthlyAmount':  monthlyAmount,
        'totalMembers':   totalMembers,
        'totalMonths':    totalMonths,
        'currentMonth':   1,
        'status':         'active',
        'startDate':      Timestamp.fromDate(startDate),
        'winnersHistory': [],
        'lastWinner':     '',
        'lastWinnerUid':  '',
        'createdAt':      FieldValue.serverTimestamp(),
      });
      return null;
    } catch (e) {
      return 'Error creating pool: $e';
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchShopKuris(String shopId) {
    return _db
        .collection('kuris')
        .where('shopId', isEqualTo: shopId)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchMemberKuris(String shopId) {
    return _db
        .collection('kuris')
        .where('shopId', isEqualTo: shopId)
        .where('status', isEqualTo: 'active')
        .snapshots();
  }

  // ── Get Eligible Members for the Draw ──
  // Returns a list of maps: [{'uid': ..., 'name': ...}, ...]
  // Eligibility rules:
  //   1. Must have an approved/paid payment for every month up to currentMonth
  //   2. Must not have won previously in this pool
  Future<({List<Map<String, dynamic>> eligible, String? error})>
      getEligibleMembers({
    required String kuriId,
    required int currentMonth,
  }) async {
    try {
      final kuriDoc = await _db.collection('kuris').doc(kuriId).get();
      if (!kuriDoc.exists) return (eligible: <Map<String, dynamic>>[], error: 'Pool not found.');

      final kuriData = kuriDoc.data() as Map<String, dynamic>;
      final winnersHistory = List<Map<String, dynamic>>.from(
          kuriData['winnersHistory'] ?? []);
      final alreadyWonUids =
          winnersHistory.map((w) => w['uid'] as String).toSet();

      final allPaymentsSnap = await _db
          .collection('payments')
          .where('kuriId', isEqualTo: kuriId)
          .get();

      // Build a map of uid → set of approved months for fast lookup
      final Map<String, Set<int>> approvedMonthsByUid = {};
      for (final doc in allPaymentsSnap.docs) {
        final data = doc.data();
        final uid = data['uid'] as String? ?? '';
        final month = data['month'] as int? ?? 0;
        final approved =
            data['paid'] == true || data['status'] == 'approved';
        if (uid.isNotEmpty && month > 0 && approved) {
          approvedMonthsByUid.putIfAbsent(uid, () => {}).add(month);
        }
      }

      // Check eligibility for each unique uid
      final List<Map<String, dynamic>> eligible = [];
      for (final entry in approvedMonthsByUid.entries) {
        final uid = entry.key;
        if (alreadyWonUids.contains(uid)) continue;

        // Must have approved payment for every month 1..currentMonth
        bool hasAll = true;
        for (int m = 1; m <= currentMonth; m++) {
          if (!entry.value.contains(m)) {
            hasAll = false;
            break;
          }
        }
        if (!hasAll) continue;

        final userDoc = await _db.collection('users').doc(uid).get();
        final name =
            (userDoc.data()?['fullName'] ?? 'Unknown') as String;
        eligible.add({'uid': uid, 'name': name});
      }

      eligible.sort((a, b) =>
          (a['name'] as String).compareTo(b['name'] as String));

      return (eligible: eligible, error: null);
    } catch (e) {
      return (eligible: <Map<String, dynamic>>[], error: 'Error loading members: $e');
    }
  }

  // ── Conduct Draw ──
  // The admin explicitly selects the winner (winnerUid + winnerName).
  // Uses a Firestore transaction to prevent race conditions.
  //
  // After recording the winner:
  //   • If currentMonth < totalMonths  → increment currentMonth, keep 'active'
  //   • If currentMonth == totalMonths → set status 'completed' (final draw)
  //
  // Payment reset: any 'pendingApproval' payments for the NEW month that were
  // pre-submitted are left intact. There is nothing to reset — payment docs
  // are keyed as `{kuriId}_{uid}_month{N}` so month N+1 docs don't exist yet.
  // This method explicitly verifies the winner is still eligible inside the
  // transaction to guard against double-submission.
  Future<String?> conductDraw({
    required String kuriId,
    required String winnerUid,
    required String winnerName,
    required int currentMonth,
  }) async {
    try {
      final kuriRef = _db.collection('kuris').doc(kuriId);

      final String? txError =
          await _db.runTransaction<String?>((transaction) async {
        final kuriSnap = await transaction.get(kuriRef);
        if (!kuriSnap.exists) return 'Pool not found.';

        final data = kuriSnap.data() as Map<String, dynamic>;

        // Guard: ensure the month hasn't already been drawn
        final liveCurrentMonth = data['currentMonth'] as int? ?? 1;
        if (liveCurrentMonth != currentMonth) {
          return 'This month\'s draw has already been conducted. '
              'Please refresh and try again.';
        }

        // Guard: ensure winner hasn't already won
        final history = List<Map<String, dynamic>>.from(
            data['winnersHistory'] ?? []);
        final alreadyWon =
            history.any((w) => w['uid'] == winnerUid);
        if (alreadyWon) {
          return '$winnerName has already won a previous month '
              'and is no longer eligible.';
        }

        final totalMonths = data['totalMonths'] as int? ?? 0;
        final isLastMonth  = currentMonth >= totalMonths;

        history.add({
          'uid':   winnerUid,
          'name':  winnerName,
          'month': currentMonth,
          'date':  DateTime.now().toIso8601String(),
        });

        transaction.update(kuriRef, {
          'winnersHistory': history,
          'lastWinner':     winnerName,
          'lastWinnerUid':  winnerUid,
          // Advance to next month, or keep at totalMonths+1 as a sentinel
          'currentMonth':   currentMonth + 1,
          // Auto-complete on the final draw
          'status':         isLastMonth ? 'completed' : 'active',
        });

        return null; // success
      });

      return txError;
    } catch (e) {
      return 'Error conducting draw: $e';
    }
  }

  // ── Legacy pickWinner kept for backwards compatibility ──
  // New code should use conductDraw + getEligibleMembers instead.
  @Deprecated('Use conductDraw instead')
  Future<String?> pickWinner({
    required String kuriId,
    required String shopId,
    required int currentMonth,
  }) async {
    final result = await getEligibleMembers(
        kuriId: kuriId, currentMonth: currentMonth);
    if (result.error != null) return result.error;
    if (result.eligible.isEmpty) {
      return 'No eligible members found. All members must have approved '
          'payments for every month up to Month $currentMonth '
          'and must not have won before.';
    }
    final winner = result.eligible.first; // deterministic for compat
    return conductDraw(
      kuriId:       kuriId,
      winnerUid:    winner['uid'] as String,
      winnerName:   winner['name'] as String,
      currentMonth: currentMonth,
    );
  }

  Future<void> updateStatus(String kuriId, String status) async {
    await _db.collection('kuris').doc(kuriId).update({'status': status});
  }

  Future<void> deleteKuri(String kuriId) async {
    await _db.collection('kuris').doc(kuriId).delete();
  }
}

// ══════════════════════════════════════════
// PAYMENT SERVICE
// ══════════════════════════════════════════
class PaymentService {
  final _db          = FirebaseFirestore.instance;
  final _shopService = ShopService();

  // ── Submit Payment (Member) ──
  Future<String?> submitPayment({
    required String kuriId,
    required String shopId,
    required String uid,
    required String memberName,
    required String memberId,
    required int    month,
    required double amount,
    required String transactionId,
    String note = '',
  }) async {
    try {
      final paymentDocId = '${kuriId}_${uid}_month$month';

      final existing =
          await _db.collection('payments').doc(paymentDocId).get();

      if (existing.exists) {
        final data   = existing.data()!;
        final status = data['status'] ?? '';
        final paid   = data['paid']   ?? false;

        if (paid == true || status == 'approved') {
          return 'Payment for Month $month is already approved.';
        }
        if (status == 'pendingApproval') {
          return 'Payment for Month $month is already submitted '
              'and awaiting approval.';
        }
        // 'rejected' — allow resubmission by falling through
      }

      await _db.collection('payments').doc(paymentDocId).set({
        'uid':           uid,
        'kuriId':        kuriId,
        'shopId':        shopId,
        'memberName':    memberName,
        'memberId':      memberId,
        'month':         month,
        'amount':        amount,
        'paid':          false,
        'status':        'pendingApproval',
        'transactionId': transactionId,
        'note':          note,
        'submittedAt':   FieldValue.serverTimestamp(),
        'paymentDate':   null,
      });

      return null;
    } catch (e) {
      return 'Error submitting payment: $e';
    }
  }

  // ── Approve Payment (Admin) ──
  Future<String?> approvePayment({
    required String paymentId,
    required String shopId,
    required String shopName,
    required String uid,
    required String memberName,
    required String memberId,
    required String kuriId,
    required String kuriName,
    required int    month,
    required double amount,
    required String transactionId,
  }) async {
    try {
      final now           = DateTime.now();
      final receiptNumber = await _shopService.getNextReceiptNumber(shopId);
      final receiptId     = '${shopId}_receipt_$receiptNumber';

      final batch = _db.batch();

      batch.update(_db.collection('payments').doc(paymentId), {
        'status':      'approved',
        'paid':        true,
        'paymentDate': Timestamp.fromDate(now),
      });

      batch.set(_db.collection('receipts').doc(receiptId), {
        'shopId':        shopId,
        'shopName':      shopName,
        'receiptNumber': receiptNumber,
        'uid':           uid,
        'memberName':    memberName,
        'memberId':      memberId,
        'kuriId':        kuriId,
        'kuriName':      kuriName,
        'month':         month,
        'amount':        amount,
        'transactionId': transactionId,
        'paymentDate':   Timestamp.fromDate(now),
      });

      await batch.commit();
      return null;
    } catch (e) {
      return 'Error approving payment: $e';
    }
  }

  // ── Reject Payment (Admin) ──
  Future<String?> rejectPayment({
    required String paymentId,
    String rejectionNote = '',
  }) async {
    try {
      await _db.collection('payments').doc(paymentId).update({
        'status': 'rejected',
        'paid':   false,
        'note':   rejectionNote,
      });
      return null;
    } catch (e) {
      return 'Error rejecting payment: $e';
    }
  }

  // ── Legacy: Mark As Paid (Admin direct) ──
  Future<String?> markAsPaid({
    required String kuriId,
    required String shopId,
    required String shopName,
    required String uid,
    required String memberName,
    required String memberId,
    required int    month,
    required double amount,
    required String kuriName,
  }) async {
    try {
      final paymentDocId = '${kuriId}_${uid}_month$month';

      final existing =
          await _db.collection('payments').doc(paymentDocId).get();
      if (existing.exists && (existing.data()?['paid'] == true)) {
        return 'Payment already recorded for Month $month.';
      }

      final now           = DateTime.now();
      final receiptNumber = await _shopService.getNextReceiptNumber(shopId);
      final receiptId     = '${shopId}_$receiptNumber';

      await _db.collection('payments').doc(paymentDocId).set({
        'uid':         uid,
        'kuriId':      kuriId,
        'shopId':      shopId,
        'memberName':  memberName,
        'memberId':    memberId,
        'month':       month,
        'amount':      amount,
        'paid':        true,
        'status':      'approved',
        'paymentDate': Timestamp.fromDate(now),
      });

      await _db.collection('receipts').doc(receiptId).set({
        'shopId':        shopId,
        'shopName':      shopName,
        'receiptNumber': receiptNumber,
        'uid':           uid,
        'memberName':    memberName,
        'memberId':      memberId,
        'kuriId':        kuriId,
        'kuriName':      kuriName,
        'month':         month,
        'amount':        amount,
        'paymentDate':   Timestamp.fromDate(now),
      });

      return null;
    } catch (e) {
      return 'Error recording payment: $e';
    }
  }

  // ── Streams ──

  Stream<QuerySnapshot<Map<String, dynamic>>> watchKuriPayments(
      String kuriId) {
    return _db
        .collection('payments')
        .where('kuriId', isEqualTo: kuriId)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchMemberPayments(
      String uid, String shopId) {
    return _db
        .collection('payments')
        .where('uid', isEqualTo: uid)
        .where('shopId', isEqualTo: shopId)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchShopReceipts(
      String shopId) {
    return _db
        .collection('receipts')
        .where('shopId', isEqualTo: shopId)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchMemberReceipts(
      String uid) {
    return _db
        .collection('receipts')
        .where('uid', isEqualTo: uid)
        .snapshots();
  }
}