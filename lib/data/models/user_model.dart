import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String? phone;
  final String? avatarUrl;
  final DateTime createdAt;
  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.phone,
    this.avatarUrl,
    required this.createdAt,
  });
  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
        uid: map['uid'] ?? '',
        name: map['name'] ?? '',
        email: map['email'] ?? '',
        phone: map['phone'],
        avatarUrl: map['avatarUrl'],
        createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
  Map<String, dynamic> toMap() => {
        'uid': uid,
        'name': name,
        'email': email,
        'phone': phone,
        'avatarUrl': avatarUrl,
        'createdAt': Timestamp.fromDate(createdAt),
      };
  UserModel copyWith({String? name, String? phone, String? avatarUrl}) =>
      UserModel(
        uid: uid,
        name: name ?? this.name,
        email: email,
        phone: phone ?? this.phone,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        createdAt: createdAt,
      );
}
