import '../core/constants/app_constants.dart';
import '../data/models/chat_model.dart';
import '../data/models/message_model.dart';

class ChatAutomationResult {
  final String status;
  final String priority;
  final String intent;
  final String suggestedReply;
  final bool handledByAi;

  const ChatAutomationResult({
    required this.status,
    required this.priority,
    required this.intent,
    required this.suggestedReply,
    this.handledByAi = true,
  });
}

class ChatAutomationService {
  const ChatAutomationService();

  ChatAutomationResult analyzeChat({
    required ChatModel chat,
    required List<MessageModel> messages,
    required String businessName,
  }) {
    final latestText = messages.isNotEmpty
        ? messages.last.text.toLowerCase()
        : chat.lastMessage.toLowerCase();

    final inferredIntent = _detectIntent(latestText, fallback: chat.intent);
    final inferredStatus = _detectStatus(latestText, fallback: chat.status);
    final priority = _detectPriority(latestText, inferredStatus);

    return ChatAutomationResult(
      status: inferredStatus,
      priority: priority,
      intent: inferredIntent,
      suggestedReply: _buildReply(
        text: latestText,
        businessName: businessName,
        intent: inferredIntent,
      ),
    );
  }

  String _detectIntent(String text, {required String fallback}) {
    if (text.contains('book') ||
        text.contains('запис') ||
        text.contains('appointment')) {
      return 'Booking Request';
    }
    if (text.contains('price') ||
        text.contains('cost') ||
        text.contains('сколько') ||
        text.contains('цена')) {
      return 'Price Question';
    }
    if (text.contains('bad') ||
        text.contains('complaint') ||
        text.contains('ужас') ||
        text.contains('жалоб')) {
      return 'Complaint';
    }
    return AppConstants.intentTypes.contains(fallback)
        ? fallback
        : 'General Question';
  }

  String _detectStatus(String text, {required String fallback}) {
    if (text.contains('urgent') || text.contains('срочно')) {
      return 'Urgent';
    }
    if (text.contains('ok') ||
        text.contains('confirmed') ||
        text.contains('подтвержда')) {
      return 'Completed';
    }
    if (text.contains('wait') ||
        text.contains('later') ||
        text.contains('подума')) {
      return 'Awaiting Client';
    }
    if (text.trim().isNotEmpty) {
      return 'In Progress';
    }
    return fallback;
  }

  String _detectPriority(String text, String status) {
    if (status == 'Urgent' ||
        text.contains('today') ||
        text.contains('tomorrow') ||
        text.contains('сегодня') ||
        text.contains('завтра')) {
      return 'High';
    }
    if (status == 'Awaiting Client') {
      return 'Medium';
    }
    return 'Normal';
  }

  String _buildReply({
    required String text,
    required String businessName,
    required String intent,
  }) {
    if (intent == 'Booking Request') {
      return 'Здравствуйте! Спасибо за обращение в $businessName. Мы можем помочь с записью. Напишите удобную дату и время, а мы быстро подтвердим ближайшие слоты.';
    }
    if (intent == 'Price Question') {
      return 'Здравствуйте! Спасибо за интерес к $businessName. Мы подготовили для клиента ответ с ценой и ближайшими доступными слотами. При необходимости можно отправить уточняющее сообщение.';
    }
    if (intent == 'Complaint') {
      return 'Здравствуйте! Нам очень жаль, что у клиента возникла проблема. ИИ подготовил вежливый ответ с извинением и просьбой уточнить детали для быстрого решения.';
    }
    return 'Здравствуйте! Спасибо за сообщение в $businessName. ИИ подготовил нейтральный ответ и предложил продолжить диалог с уточнением деталей запроса.';
  }
}
