import 'package:hive_flutter/hive_flutter.dart';

class CacheService {
  static const String _kuriBox = 'kuris_cache';
  static const String _memberBox = 'members_cache';
  static const String _paymentBox = 'payments_cache';
  static const String _receiptBox = 'receipts_cache';
  static const String _shopBox = 'shop_cache';

  // ── Init ──
  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_kuriBox);
    await Hive.openBox(_memberBox);
    await Hive.openBox(_paymentBox);
    await Hive.openBox(_receiptBox);
    await Hive.openBox(_shopBox);
  }

  // ── Shop ──
  Future<void> cacheShop(String shopId, Map<String, dynamic> data) async {
    final box = Hive.box(_shopBox);
    await box.put(shopId, data);
  }

  Map<String, dynamic>? getCachedShop(String shopId) {
    final box = Hive.box(_shopBox);
    final val = box.get(shopId);
    if (val == null) return null;
    return Map<String, dynamic>.from(val as Map);
  }

  // ── Kuris ──
  Future<void> cacheKuris(String shopId, List<Map<String, dynamic>> kuris) async {
    final box = Hive.box(_kuriBox);
    await box.put(shopId, kuris);
  }

  List<Map<String, dynamic>> getCachedKuris(String shopId) {
    final box = Hive.box(_kuriBox);
    final val = box.get(shopId);
    if (val == null) return [];
    return (val as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  // ── Members ──
  Future<void> cacheMembers(String shopId, List<Map<String, dynamic>> members) async {
    final box = Hive.box(_memberBox);
    await box.put(shopId, members);
  }

  List<Map<String, dynamic>> getCachedMembers(String shopId) {
    final box = Hive.box(_memberBox);
    final val = box.get(shopId);
    if (val == null) return [];
    return (val as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  // ── Payments ──
  Future<void> cachePayments(String kuriId, List<Map<String, dynamic>> payments) async {
    final box = Hive.box(_paymentBox);
    await box.put(kuriId, payments);
  }

  List<Map<String, dynamic>> getCachedPayments(String kuriId) {
    final box = Hive.box(_paymentBox);
    final val = box.get(kuriId);
    if (val == null) return [];
    return (val as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  // ── Receipts ──
  Future<void> cacheReceipts(String key, List<Map<String, dynamic>> receipts) async {
    final box = Hive.box(_receiptBox);
    await box.put(key, receipts);
  }

  List<Map<String, dynamic>> getCachedReceipts(String key) {
    final box = Hive.box(_receiptBox);
    final val = box.get(key);
    if (val == null) return [];
    return (val as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  // ── Clear all cache ──
  Future<void> clearAll() async {
    await Hive.box(_kuriBox).clear();
    await Hive.box(_memberBox).clear();
    await Hive.box(_paymentBox).clear();
    await Hive.box(_receiptBox).clear();
    await Hive.box(_shopBox).clear();
  }
}
