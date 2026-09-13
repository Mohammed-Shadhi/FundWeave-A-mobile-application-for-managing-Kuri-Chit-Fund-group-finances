import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/shop_model.dart';
import '../models/models.dart';
import '../utils/app_helpers.dart';

class ShopService {
  final _db = FirebaseFirestore.instance;

  // ── Create Shop ──
  Future<Map<String, dynamic>> createShop({
    required String adminId,
    required String adminEmail,
    required String shopName,
    required String address,
    required String mobile1,
    String mobile2 = '',
    String upiId = '',
    String accountName = '',
    String accountNumber = '',
    String ifscCode = '',
    String bankName = '',
  }) async {
    try {
      final existing = await _db
          .collection('shops')
          .where('name', isEqualTo: shopName)
          .limit(1)
          .get();
      if (existing.docs.isNotEmpty) {
        return {'success': false, 'error': 'A shop with this name already exists.'};
      }

      final shopRef = _db.collection('shops').doc();
      await shopRef.set({
        'name': shopName,
        'adminId': adminId,
        'adminEmail': adminEmail,
        'address': address,
        'mobile1': mobile1,
        'mobile2': mobile2,
        'status': 'approved',
        'receiptCounter': 0,
        'paymentDetails': {
          'upiId': upiId,
          'accountName': accountName,
          'accountNumber': accountNumber,
          'ifscCode': ifscCode,
          'bankName': bankName,
        },
        'createdAt': FieldValue.serverTimestamp(),
      });

      return {'success': true, 'shopId': shopRef.id};
    } catch (e) {
      return {'success': false, 'error': 'Error creating shop: $e'};
    }
  }

  // ── Update Payment Details ──
  Future<String?> updatePaymentDetails({
    required String shopId,
    required String upiId,
    required String accountName,
    required String accountNumber,
    required String ifscCode,
    required String bankName,
  }) async {
    try {
      await _db.collection('shops').doc(shopId).update({
        'paymentDetails': {
          'upiId': upiId,
          'accountName': accountName,
          'accountNumber': accountNumber,
          'ifscCode': ifscCode,
          'bankName': bankName,
        },
      });
      return null;
    } catch (e) {
      return 'Error updating payment details: $e';
    }
  }

  // ── Update Shop Info ──
  Future<String?> updateShopInfo({
    required String shopId,
    required String shopName,
    required String address,
    required String mobile1,
    String mobile2 = '',
  }) async {
    try {
      await _db.collection('shops').doc(shopId).update({
        'name': shopName,
        'address': address,
        'mobile1': mobile1,
        'mobile2': mobile2,
      });
      return null;
    } catch (e) {
      return 'Error updating shop: $e';
    }
  }

  // ── Link User to Shop by Phone ──
  Future<String?> linkUserToShopByPhone({
    required String phone,
    required String shopId,
  }) async {
    try {
      final userSnap = await _db
          .collection('users')
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get();

      if (userSnap.docs.isEmpty) {
        return 'No user registered with this phone number.';
      }

      final userDoc = userSnap.docs.first;
      final userId = userDoc.id;
      final shopIds =
          List<dynamic>.from(userDoc.data()['shopIds'] ?? []);

      if (shopIds.contains(shopId)) {
        return 'User is already a member of this shop.';
      }

      await _db.collection('users').doc(userId).update({
        'shopIds': FieldValue.arrayUnion([shopId]),
      });

      return null;
    } catch (e) {
      return 'Error linking user: $e';
    }
  }

  // ── Watch Shop Stream ──
  Stream<ShopModel?> watchShop(String shopId) {
    return _db.collection('shops').doc(shopId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return ShopModel.fromMap(doc.data()!, doc.id);
    });
  }

  // ── Get Shop Once ──
  Future<ShopModel?> getShop(String shopId) async {
    try {
      final doc = await _db.collection('shops').doc(shopId).get();
      if (!doc.exists) return null;
      return ShopModel.fromMap(doc.data()!, doc.id);
    } catch (_) {
      return null;
    }
  }

  // ── Watch All Shops (Platform Admin) ──
  Stream<QuerySnapshot> watchAllShops() {
    return _db
        .collection('shops')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // ── Approve Shop ──
  Future<void> approveShop(String shopId, String adminId) async {
    await _db.collection('shops').doc(shopId).update({'status': 'approved'});
    await _db
        .collection('users')
        .doc(adminId)
        .update({'role': 'admin'});
  }

  // ── Create Member record ──
  Future<Map<String, dynamic>> createMember({
    required String uid,
    required String shopId,
    required String shopName,
    required String fullName,
    required String email,
    required String phone,
    required String address,
  }) async {
    try {
      final snap = await _db
          .collection('members')
          .where('shopId', isEqualTo: shopId)
          .get();
      final count = snap.docs.length + 1;
      final memberNumber = AppHelpers.generateMemberNumber(count);
      final memberId = '${shopId}_$memberNumber';
      final displayId = '$shopId-$memberNumber';
      final keywords = AppHelpers.generateSearchKeywords(
          fullName, memberNumber, displayId);

      await _db.collection('members').doc(memberId).set({
        'uid': uid,
        'shopId': shopId,
        'shopName': shopName,
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'address': address,
        'memberNumber': memberNumber,
        'displayId': displayId,
        'searchKeywords': keywords,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _db.collection('users').doc(uid).update({
        'memberNumber': memberNumber,
        'displayId': displayId,
      });

      return {
        'success': true,
        'memberNumber': memberNumber,
        'displayId': displayId
      };
    } catch (e) {
      return {'success': false, 'error': 'Error creating member: $e'};
    }
  }

  // ── Watch Members ──
  Stream<QuerySnapshot<Map<String, dynamic>>> watchShopMembers(
      String shopId) {
    return _db
        .collection('members')
        .where('shopId', isEqualTo: shopId)
        .snapshots();
  }

  // ── Search Members ──
  Future<List<MemberModel>> searchMembers({
    required String shopId,
    required String query,
  }) async {
    if (query.trim().isEmpty) return [];
    try {
      final snap = await _db
          .collection('members')
          .where('shopId', isEqualTo: shopId)
          .where('searchKeywords',
              arrayContains: query.toLowerCase().trim())
          .limit(20)
          .get();
      return snap.docs
          .map((doc) => MemberModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ── Get Member by UID + Shop ──
  Future<MemberModel?> getMemberByUid(String uid, String shopId) async {
    try {
      final snap = await _db
          .collection('members')
          .where('uid', isEqualTo: uid)
          .where('shopId', isEqualTo: shopId)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return null;
      return MemberModel.fromMap(
          snap.docs.first.data(), snap.docs.first.id);
    } catch (_) {
      return null;
    }
  }

  // ── Next Receipt Number ──
  Future<int> getNextReceiptNumber(String shopId) async {
    int receiptNumber = 0;
    await _db.runTransaction((tx) async {
      final ref = _db.collection('shops').doc(shopId);
      final doc = await tx.get(ref);
      final current = (doc.data()?['receiptCounter'] ?? 0) as int;
      receiptNumber = current + 1;
      tx.update(ref, {'receiptCounter': receiptNumber});
    });
    return receiptNumber;
  }
}