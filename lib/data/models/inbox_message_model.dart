import 'package:cloud_firestore/cloud_firestore.dart';

class InboxMessageModel {
  final String messageId;
  final String conversationId;
  final String from;
  final String text;
  final String direction;
  final String type;
  final DateTime createdAt;

  InboxMessageModel({
    required this.messageId,
    required this.conversationId,
    required this.from,
    required this.text,
    required this.direction,
    required this.type,
    required this.createdAt,
  });

  factory InboxMessageModel.fromMap(Map<String, dynamic> map, String id) {
    return InboxMessageModel(
      messageId: map['messageId'] ?? id,
      conversationId: map['conversationId'] ?? '',
      from: map['from'] ?? '',
      text: map['text'] ?? '',
      direction: map['direction'] ?? 'inbound',
      type: map['type'] ?? 'text',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
