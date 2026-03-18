import 'package:cloud_firestore/cloud_firestore.dart';

class InquiryModel {
  final String inquiryId;
  final String salonId;
  final String customerName;
  final String customerPhone;
  final String channel;
  final String message;
  final String intentType;
  final String status;
  final String? suggestedReply;
  final int unreadCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  InquiryModel(
      {required this.inquiryId,
      required this.salonId,
      required this.customerName,
      required this.customerPhone,
      required this.channel,
      required this.message,
      required this.intentType,
      required this.status,
      this.suggestedReply,
      required this.unreadCount,
      required this.createdAt,
      required this.updatedAt});
  factory InquiryModel.fromMap(Map<String, dynamic> map) => InquiryModel(
        inquiryId: map['inquiryId'] ?? '',
        salonId: map['salonId'] ?? '',
        customerName: map['customerName'] ?? '',
        customerPhone: map['customerPhone'] ?? '',
        channel: map['channel'] ?? 'manual',
        message: map['message'] ?? '',
        intentType: map['intentType'] ?? 'General Question',
        status: map['status'] ?? 'New',
        suggestedReply: map['suggestedReply'],
        unreadCount: map['unreadCount'] ?? 0,
        createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
  factory InquiryModel.fromConversationMap(
    Map<String, dynamic> map,
    String conversationId,
  ) =>
      InquiryModel(
        inquiryId: conversationId,
        salonId: map['salonId'] ?? '',
        customerName: map['customerName'] ?? 'Telegram user',
        customerPhone: map['customerPhone'] ??
            map['customerPhoneNumber'] ??
            map['customerPhoneRaw'] ??
            map['customerPhoneE164'] ??
            map['customerPhoneLocal'] ??
            map['customerPhoneNational'] ??
            map['customerPhoneIntl'] ??
            map['customerPhoneInternational'] ??
            map['customerPhoneFormatted'] ??
            map['customerPhoneDigits'] ??
            map['customerPhoneDisplay'] ??
            map['customerPhoneVisible'] ??
            map['phone'] ??
            map['customer_number'] ??
            map['customerNumber'] ??
            '',
        channel: map['channel'] ?? 'telegram',
        message: map['lastMessage'] ?? '',
        intentType: map['intentType'] ?? 'General Question',
        status: map['status'] ?? 'New',
        suggestedReply: map['suggestedReply'],
        unreadCount: map['unreadCount'] ?? 0,
        createdAt: (map['lastMessageAt'] as Timestamp?)?.toDate() ??
            (map['createdAt'] as Timestamp?)?.toDate() ??
            DateTime.now(),
        updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ??
            (map['lastMessageAt'] as Timestamp?)?.toDate() ??
            DateTime.now(),
      );
  Map<String, dynamic> toMap() => {
        'inquiryId': inquiryId,
        'salonId': salonId,
        'customerName': customerName,
        'customerPhone': customerPhone,
        'channel': channel,
        'message': message,
        'intentType': intentType,
        'status': status,
        'suggestedReply': suggestedReply,
        'unreadCount': unreadCount,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt)
      };
  InquiryModel copyWith(
          {String? customerName,
          String? customerPhone,
          String? channel,
          String? message,
          String? intentType,
          String? status,
          String? suggestedReply,
          int? unreadCount}) =>
      InquiryModel(
          inquiryId: inquiryId,
          salonId: salonId,
          customerName: customerName ?? this.customerName,
          customerPhone: customerPhone ?? this.customerPhone,
          channel: channel ?? this.channel,
          message: message ?? this.message,
          intentType: intentType ?? this.intentType,
          status: status ?? this.status,
          suggestedReply: suggestedReply ?? this.suggestedReply,
          unreadCount: unreadCount ?? this.unreadCount,
          createdAt: createdAt,
          updatedAt: DateTime.now());
}
