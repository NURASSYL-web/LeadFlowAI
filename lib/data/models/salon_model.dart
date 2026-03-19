import 'package:cloud_firestore/cloud_firestore.dart';

class SalonModel {
  final String salonId;
  final String ownerUid;
  final String businessName;
  final String businessType;
  final String? whatsappNumber;
  final String? phone;
  final String? address;
  final String? workingHours;
  final String? city;
  final DateTime createdAt;
  SalonModel(
      {required this.salonId,
      required this.ownerUid,
      required this.businessName,
      required this.businessType,
      this.whatsappNumber,
      this.phone,
      this.address,
      this.workingHours,
      this.city,
      required this.createdAt});
  factory SalonModel.fromMap(
    Map<String, dynamic> map, {
    String? documentId,
  }) =>
      SalonModel(
        salonId: (map['salonId'] ?? '').toString().trim().isNotEmpty
            ? (map['salonId'] ?? '').toString().trim()
            : (documentId ?? ''),
        ownerUid: map['ownerUid'] ?? '',
        businessName: map['businessName'] ?? '',
        businessType: map['businessType'] ?? '',
        whatsappNumber: map['whatsappNumber'],
        phone: map['phone'],
        address: map['address'],
        workingHours: map['workingHours'],
        city: map['city'],
        createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
  Map<String, dynamic> toMap() => {
        'salonId': salonId,
        'ownerUid': ownerUid,
        'businessName': businessName,
        'businessType': businessType,
        'whatsappNumber': whatsappNumber,
        'phone': phone,
        'address': address,
        'workingHours': workingHours,
        'city': city,
        'createdAt': Timestamp.fromDate(createdAt)
      };
  SalonModel copyWith(
          {String? businessName,
          String? businessType,
          String? whatsappNumber,
          String? phone,
          String? address,
          String? workingHours,
          String? city}) =>
      SalonModel(
          salonId: salonId,
          ownerUid: ownerUid,
          businessName: businessName ?? this.businessName,
          businessType: businessType ?? this.businessType,
          whatsappNumber: whatsappNumber ?? this.whatsappNumber,
          phone: phone ?? this.phone,
          address: address ?? this.address,
          workingHours: workingHours ?? this.workingHours,
          city: city ?? this.city,
          createdAt: createdAt);
}
