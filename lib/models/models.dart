// ── Member Model ──
class MemberModel {
  final String memberId;
  final String uid;
  final String shopId;
  final String fullName;
  final String email;
  final String phone;
  final String address;
  final String memberNumber;
  final String displayId;
  final List<String> searchKeywords;
  final DateTime createdAt;

  MemberModel({
    required this.memberId,
    required this.uid,
    required this.shopId,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.address,
    required this.memberNumber,
    required this.displayId,
    required this.searchKeywords,
    required this.createdAt,
  });

  factory MemberModel.fromMap(Map<String, dynamic> map, String id) {
    return MemberModel(
      memberId: id,
      uid: map['uid'] ?? '',
      shopId: map['shopId'] ?? '',
      fullName: map['fullName'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      address: map['address'] ?? '',
      memberNumber: map['memberNumber'] ?? '',
      displayId: map['displayId'] ?? '',
      searchKeywords: List<String>.from(map['searchKeywords'] ?? []),
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as dynamic).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'shopId': shopId,
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'address': address,
        'memberNumber': memberNumber,
        'displayId': displayId,
        'searchKeywords': searchKeywords,
        'createdAt': createdAt,
      };
}

// ── Kuri Model ──
class KuriModel {
  final String kuriId;
  final String shopId;
  final String title;
  final double monthlyAmount;
  final int totalMembers;
  final int totalMonths;
  final int currentMonth;
  final String status;
  final DateTime startDate;
  final List<Map<String, dynamic>> winnersHistory;
  final String lastWinner;
  final DateTime createdAt;

  KuriModel({
    required this.kuriId,
    required this.shopId,
    required this.title,
    required this.monthlyAmount,
    required this.totalMembers,
    required this.totalMonths,
    required this.currentMonth,
    required this.status,
    required this.startDate,
    required this.winnersHistory,
    required this.lastWinner,
    required this.createdAt,
  });

  double get totalPool => monthlyAmount * totalMembers;

  factory KuriModel.fromMap(Map<String, dynamic> map, String id) {
    return KuriModel(
      kuriId: id,
      shopId: map['shopId'] ?? '',
      title: map['title'] ?? '',
      monthlyAmount: (map['monthlyAmount'] ?? 0).toDouble(),
      totalMembers: map['totalMembers'] ?? 0,
      totalMonths: map['totalMonths'] ?? 0,
      currentMonth: map['currentMonth'] ?? 1,
      status: map['status'] ?? 'active',
      startDate: map['startDate'] != null
          ? (map['startDate'] as dynamic).toDate()
          : DateTime.now(),
      winnersHistory:
          List<Map<String, dynamic>>.from(map['winnersHistory'] ?? []),
      lastWinner: map['lastWinner'] ?? '',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as dynamic).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'shopId': shopId,
        'title': title,
        'monthlyAmount': monthlyAmount,
        'totalMembers': totalMembers,
        'totalMonths': totalMonths,
        'currentMonth': currentMonth,
        'status': status,
        'startDate': startDate,
        'winnersHistory': winnersHistory,
        'lastWinner': lastWinner,
        'createdAt': createdAt,
      };
}

// ── Payment Model ──
// Status values:
//   'pendingApproval' → member submitted TXN ID, awaiting admin review
//   'approved'        → admin confirmed, paid = true
//   'rejected'        → admin rejected the submission
class PaymentModel {
  final String paymentId;
  final String uid;
  final String kuriId;
  final String shopId;
  final String memberName;
  final String memberId;
  final int month;
  final double amount;
  final bool paid;
  final String status;          // 'pendingApproval' | 'approved' | 'rejected'
  final String transactionId;   // UTR / TXN ID entered by member
  final String note;            // optional note from member
  final DateTime? paymentDate;
  final DateTime? submittedAt;  // when member submitted

  PaymentModel({
    required this.paymentId,
    required this.uid,
    required this.kuriId,
    required this.shopId,
    required this.memberName,
    required this.memberId,
    required this.month,
    required this.amount,
    required this.paid,
    this.status        = '',
    this.transactionId = '',
    this.note          = '',
    this.paymentDate,
    this.submittedAt,
  });

  /// Convenience getters
  bool get isPendingApproval => status == 'pendingApproval';
  bool get isApproved        => status == 'approved' || paid;
  bool get isRejected        => status == 'rejected';

  factory PaymentModel.fromMap(Map<String, dynamic> map, String id) {
    return PaymentModel(
      paymentId:     id,
      uid:           map['uid']           ?? '',
      kuriId:        map['kuriId']        ?? '',
      shopId:        map['shopId']        ?? '',
      memberName:    map['memberName']    ?? '',
      memberId:      map['memberId']      ?? '',
      month:         map['month']         ?? 0,
      amount:        (map['amount']       ?? 0).toDouble(),
      paid:          map['paid']          ?? false,
      status:        map['status']        ?? '',
      transactionId: map['transactionId'] ?? '',
      note:          map['note']          ?? '',
      paymentDate: map['paymentDate'] != null
          ? (map['paymentDate'] as dynamic).toDate()
          : null,
      submittedAt: map['submittedAt'] != null
          ? (map['submittedAt'] as dynamic).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'uid':           uid,
        'kuriId':        kuriId,
        'shopId':        shopId,
        'memberName':    memberName,
        'memberId':      memberId,
        'month':         month,
        'amount':        amount,
        'paid':          paid,
        'status':        status,
        'transactionId': transactionId,
        'note':          note,
        'paymentDate':   paymentDate,
        'submittedAt':   submittedAt,
      };
}

// ── Receipt Model ──
class ReceiptModel {
  final String receiptId;
  final String shopId;
  final String shopName;
  final int receiptNumber;
  final String uid;
  final String memberName;
  final String memberId;
  final String kuriId;
  final String kuriName;
  final int month;
  final double amount;
  final DateTime paymentDate;

  ReceiptModel({
    required this.receiptId,
    required this.shopId,
    required this.shopName,
    required this.receiptNumber,
    required this.uid,
    required this.memberName,
    required this.memberId,
    required this.kuriId,
    required this.kuriName,
    required this.month,
    required this.amount,
    required this.paymentDate,
  });

  factory ReceiptModel.fromMap(Map<String, dynamic> map, String id) {
    return ReceiptModel(
      receiptId: id,
      shopId: map['shopId'] ?? '',
      shopName: map['shopName'] ?? '',
      receiptNumber: map['receiptNumber'] ?? 0,
      uid: map['uid'] ?? '',
      memberName: map['memberName'] ?? '',
      memberId: map['memberId'] ?? '',
      kuriId: map['kuriId'] ?? '',
      kuriName: map['kuriName'] ?? '',
      month: map['month'] ?? 0,
      amount: (map['amount'] ?? 0).toDouble(),
      paymentDate: map['paymentDate'] != null
          ? (map['paymentDate'] as dynamic).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'shopId': shopId,
        'shopName': shopName,
        'receiptNumber': receiptNumber,
        'uid': uid,
        'memberName': memberName,
        'memberId': memberId,
        'kuriId': kuriId,
        'kuriName': kuriName,
        'month': month,
        'amount': amount,
        'paymentDate': paymentDate,
      };
}

// ── User Model ──
// NOTE: Email field removed. Authentication uses a hidden dummy email
// constructed as: "${username.toLowerCase()}@myagency.com"
// Only the username is stored in Firestore and shown in the UI.
class UserModel {
  final String uid;
  final String username;   // replaces email — the user-facing login handle
  final String fullName;
  final String phone;
  final String address;
  final String role;
  final List<String> shopIds;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.username,
    required this.fullName,
    required this.phone,
    required this.address,
    required this.role,
    required this.shopIds,
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid:       map['uid']      ?? '',
      username:  map['username'] ?? '',
      fullName:  map['fullName'] ?? '',
      phone:     map['phone']    ?? '',
      address:   map['address']  ?? '',
      role:      map['role']     ?? 'member',
      shopIds:   List<String>.from(map['shopIds'] ?? []),
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as dynamic).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'uid':       uid,
        'username':  username,
        'fullName':  fullName,
        'phone':     phone,
        'address':   address,
        'role':      role,
        'shopIds':   shopIds,
        'createdAt': createdAt,
      };
}