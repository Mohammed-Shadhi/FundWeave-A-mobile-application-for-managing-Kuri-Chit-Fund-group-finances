import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/shop_service.dart';
import '../services/kuri_payment_service.dart';
import '../services/connectivity_service.dart';
import '../models/shop_model.dart';
import '../models/models.dart';

// ── Auth ──
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

final currentUserDataProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((ref, uid) async {
  final doc = await FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .get();
  if (!doc.exists) return null;
  return doc.data();
});

final userDocStreamProvider =
    StreamProvider.family<Map<String, dynamic>?, String>((ref, uid) {
  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .snapshots()
      .map((doc) => doc.exists ? doc.data() : null);
});

// ── Shop ──
final shopServiceProvider = Provider<ShopService>((ref) => ShopService());

final shopStreamProvider =
    StreamProvider.family<ShopModel?, String>((ref, shopId) {
  return ref.watch(shopServiceProvider).watchShop(shopId);
});

final shopMembersProvider =
    StreamProvider.family<List<MemberModel>, String>((ref, shopId) {
  return ref
      .watch(shopServiceProvider)
      .watchShopMembers(shopId)
      .map((snap) => snap.docs
          .map((doc) => MemberModel.fromMap(
              doc.data(), doc.id))
          .toList());
});

// ── Kuri ──
final kuriServiceProvider = Provider<KuriService>((ref) => KuriService());

final shopKurisProvider =
    StreamProvider.family<List<KuriModel>, String>((ref, shopId) {
  return ref
      .watch(kuriServiceProvider)
      .watchShopKuris(shopId)
      .map((snap) => snap.docs
          .map((doc) => KuriModel.fromMap(
              doc.data(), doc.id))
          .toList());
});

final memberKurisProvider =
    StreamProvider.family<List<KuriModel>, String>((ref, shopId) {
  return ref
      .watch(kuriServiceProvider)
      .watchMemberKuris(shopId)
      .map((snap) => snap.docs
          .map((doc) => KuriModel.fromMap(
              doc.data(), doc.id))
          .toList());
});

// ── Draw: Eligible Members ──
// Fetched on-demand when the admin opens the Conduct Draw dialog.
// The family arg is a record so we can pass both kuriId and currentMonth
// and the provider automatically re-fetches if either changes.
final eligibleMembersProvider = FutureProvider.family<
    ({List<Map<String, dynamic>> eligible, String? error}),
    ({String kuriId, int currentMonth})>((ref, args) async {
  return ref.read(kuriServiceProvider).getEligibleMembers(
        kuriId:       args.kuriId,
        currentMonth: args.currentMonth,
      );
});

// ── Payment ──
final paymentServiceProvider =
    Provider<PaymentService>((ref) => PaymentService());

// Admin-facing: fetches ALL payments for a kuri.
final kuriPaymentsProvider =
    StreamProvider.family<List<PaymentModel>, String>((ref, kuriId) {
  return ref
      .watch(paymentServiceProvider)
      .watchKuriPayments(kuriId)
      .map((snap) => snap.docs
          .map((doc) => PaymentModel.fromMap(
              doc.data(), doc.id))
          .toList());
});

// Member-facing: fetches ONLY the current user's payments for a given kuri.
final myKuriPaymentsProvider =
    StreamProvider.family<List<PaymentModel>, String>((ref, kuriId) {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  return FirebaseFirestore.instance
      .collection('payments')
      .where('kuriId', isEqualTo: kuriId)
      .where('uid', isEqualTo: uid)
      .snapshots()
      .map((snap) => snap.docs
          .map((doc) => PaymentModel.fromMap(
              doc.data(), doc.id))
          .toList());
});

final memberPaymentsProvider = StreamProvider.family<List<PaymentModel>,
    ({String uid, String shopId})>((ref, args) {
  return ref
      .watch(paymentServiceProvider)
      .watchMemberPayments(args.uid, args.shopId)
      .map((snap) => snap.docs
          .map((doc) => PaymentModel.fromMap(
              doc.data(), doc.id))
          .toList());
});

final memberReceiptsProvider =
    StreamProvider.family<List<ReceiptModel>, String>((ref, uid) {
  return ref
      .watch(paymentServiceProvider)
      .watchMemberReceipts(uid)
      .map((snap) => snap.docs
          .map((doc) => ReceiptModel.fromMap(
              doc.data(), doc.id))
          .toList());
});

final shopReceiptsProvider =
    StreamProvider.family<List<ReceiptModel>, String>((ref, shopId) {
  return ref
      .watch(paymentServiceProvider)
      .watchShopReceipts(shopId)
      .map((snap) => snap.docs
          .map((doc) => ReceiptModel.fromMap(
              doc.data(), doc.id))
          .toList());
});

// ── Connectivity ──
final connectivityProvider =
    ChangeNotifierProvider<ConnectivityService>((ref) => ConnectivityService());

// ── Search ──
final memberSearchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = FutureProvider.family<List<MemberModel>,
    ({String shopId, String query})>((ref, args) async {
  if (args.query.trim().isEmpty) return [];
  return ref.read(shopServiceProvider).searchMembers(
        shopId: args.shopId,
        query:  args.query,
      );
});