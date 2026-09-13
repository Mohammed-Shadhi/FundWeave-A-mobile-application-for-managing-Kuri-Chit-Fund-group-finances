import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String username;   // replaces email — login handle, no spaces
  final String fullName;
  final String phone;
  final String address;
  final String role;
  
  // 🟢 UPGRADE: Changed from a single String to a List of Strings
  final List<String> shopIds; 
  
  final String? shopName;
  final String? memberNumber;
  final String? displayId;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.username,
    required this.fullName,
    required this.phone,
    required this.address,
    required this.role,
    required this.shopIds, // 🟢 Now requires the list
    this.shopName,
    this.memberNumber,
    this.displayId,
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    // 🟢 BACKWARD COMPATIBILITY MAGIC
    // Handles both new array data and old single-string data
    List<String> parsedShopIds = [];
    if (map['shopIds'] != null) {
      parsedShopIds = List<String>.from(map['shopIds']);
    } else if (map['shopId'] != null && map['shopId'].toString().isNotEmpty) {
      parsedShopIds = [map['shopId'].toString()];
    }

    return UserModel(
      uid:          id,
      username:     map['username'] ?? '',
      fullName:     map['fullName'] ?? '',
      phone:        map['phone']    ?? '',
      address:      map['address']  ?? '',
      role:         map['role']     ?? 'user',
      shopIds:      parsedShopIds,  // 🟢 Updated mapping
      shopName:     map['shopName'],
      memberNumber: map['memberNumber'],
      displayId:    map['displayId'],
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as dynamic).toDate()
          : DateTime.now(),
    );
  }

  // 🟢 MISSING METHOD ADDED: Required for RegisterScreen to save data
  Map<String, dynamic> toMap() {
    return {
      'uid':          uid,
      'username':     username,
      'fullName':     fullName,
      'phone':        phone,
      'address':      address,
      'role':         role,
      'shopIds':      shopIds,
      'shopName':     shopName,
      'memberNumber': memberNumber,
      'displayId':    displayId,
      'createdAt':    Timestamp.fromDate(createdAt),
    };
  }
}