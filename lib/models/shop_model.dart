class ShopModel {
  final String shopId;
  final String name;
  final String adminId;
  final String adminEmail;
  final String address;
  final String mobile1;
  final String mobile2;
  final String status;
  final int receiptCounter;
  final Map<String, dynamic> paymentDetails;
  final DateTime createdAt;

  ShopModel({
    required this.shopId,
    required this.name,
    required this.adminId,
    required this.adminEmail,
    required this.address,
    required this.mobile1,
    this.mobile2 = '',
    required this.status,
    this.receiptCounter = 0,
    this.paymentDetails = const {},
    required this.createdAt,
  });

  // ── Payment detail getters ──
  String get upiId => (paymentDetails['upiId'] ?? '') as String;
  String get accountName => (paymentDetails['accountName'] ?? '') as String;
  String get accountNumber => (paymentDetails['accountNumber'] ?? '') as String;
  String get ifscCode => (paymentDetails['ifscCode'] ?? '') as String;
  String get bankName => (paymentDetails['bankName'] ?? '') as String;

  bool get hasUpi => upiId.isNotEmpty;
  bool get hasBankAccount => accountNumber.isNotEmpty;
  bool get hasAnyPaymentMethod => hasUpi || hasBankAccount;

  factory ShopModel.fromMap(Map<String, dynamic> map, String id) {
    return ShopModel(
      shopId: id,
      name: map['name'] ?? '',
      adminId: map['adminId'] ?? '',
      adminEmail: map['adminEmail'] ?? '',
      address: map['address'] ?? '',
      mobile1: map['mobile1'] ?? '',
      mobile2: map['mobile2'] ?? '',
      status: map['status'] ?? 'approved',
      receiptCounter: map['receiptCounter'] ?? 0,
      paymentDetails: Map<String, dynamic>.from(map['paymentDetails'] ?? {}),
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as dynamic).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'adminId': adminId,
        'adminEmail': adminEmail,
        'address': address,
        'mobile1': mobile1,
        'mobile2': mobile2,
        'status': status,
        'receiptCounter': receiptCounter,
        'paymentDetails': paymentDetails,
        'createdAt': createdAt,
      };
}
