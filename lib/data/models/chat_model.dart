import 'inquiry_model.dart';

class ChatModel {
  final String id;
  final String customerName;
  final String customerPhone;
  final String channel;
  final String lastMessage;
  final String status;
  final String intent;
  final int unreadCount;
  final DateTime updatedAt;

  const ChatModel({
    required this.id,
    required this.customerName,
    required this.customerPhone,
    required this.channel,
    required this.lastMessage,
    required this.status,
    required this.intent,
    required this.unreadCount,
    required this.updatedAt,
  });

  factory ChatModel.fromInquiry(InquiryModel inquiry) {
    return ChatModel(
      id: inquiry.inquiryId,
      customerName: inquiry.customerName,
      customerPhone: inquiry.customerPhone,
      channel: inquiry.channel,
      lastMessage: inquiry.message,
      status: inquiry.status,
      intent: inquiry.intentType,
      unreadCount: inquiry.unreadCount,
      updatedAt: inquiry.updatedAt,
    );
  }
}
