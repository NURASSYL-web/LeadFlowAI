import 'inbox_message_model.dart';

class MessageModel {
  final String id;
  final String chatId;
  final String sender;
  final String text;
  final String direction;
  final String type;
  final DateTime createdAt;

  const MessageModel({
    required this.id,
    required this.chatId,
    required this.sender,
    required this.text,
    required this.direction,
    required this.type,
    required this.createdAt,
  });

  factory MessageModel.fromInboxMessage(InboxMessageModel message) {
    return MessageModel(
      id: message.messageId,
      chatId: message.conversationId,
      sender: message.from,
      text: message.text,
      direction: message.direction,
      type: message.type,
      createdAt: message.createdAt,
    );
  }
}
