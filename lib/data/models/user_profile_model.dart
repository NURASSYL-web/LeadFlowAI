import 'user_model.dart';

class UserProfileModel {
  final String uid;
  final String fullName;
  final String email;
  final String? avatarUrl;
  final String? businessName;
  final String? phone;

  const UserProfileModel({
    required this.uid,
    required this.fullName,
    required this.email,
    this.avatarUrl,
    this.businessName,
    this.phone,
  });

  factory UserProfileModel.fromUser(
    UserModel user, {
    String? businessName,
    String? phone,
  }) {
    return UserProfileModel(
      uid: user.uid,
      fullName: user.name,
      email: user.email,
      avatarUrl: user.avatarUrl,
      businessName: businessName,
      phone: phone ?? user.phone,
    );
  }
}
