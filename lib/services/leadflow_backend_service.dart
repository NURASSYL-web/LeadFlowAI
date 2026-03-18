import 'dart:convert';

import 'package:http/http.dart' as http;

import '../data/models/faq_model.dart';
import '../data/models/inbox_message_model.dart';
import '../data/models/service_model.dart';

class LeadflowBackendService {
  const LeadflowBackendService();

  static const String _baseUrl =
      'https://us-central1-leadflow-9d3b0.cloudfunctions.net';

  Future<String> generateAiReply({
    required String conversationId,
    required String customerName,
    required String customerMessage,
    required String businessName,
    required String? workingHours,
    required List<ServiceModel> services,
    required List<FaqModel> faqs,
    required List<InboxMessageModel> messages,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/generateAiReply'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'conversationId': conversationId,
        'customerName': customerName,
        'customerMessage': customerMessage,
        'businessName': businessName,
        'workingHours': workingHours,
        'services': services
            .where((service) => service.isActive)
            .map(
              (service) => {
                'name': service.name,
                'price': service.price,
                'duration': service.duration,
              },
            )
            .toList(),
        'faqs': faqs
            .map(
              (faq) => {
                'question': faq.question,
                'answer': faq.answer,
              },
            )
            .toList(),
        'messages': messages
            .map(
              (message) => {
                'direction': message.direction,
                'text': message.text,
              },
            )
            .toList(),
      }),
    );

    final data = _decode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        _humanizeBackendError(
          data['error']?.toString(),
          fallback: 'Failed to generate AI reply',
        ),
      );
    }

    final reply = (data['reply'] as String?)?.trim();
    if (reply == null || reply.isEmpty) {
      throw Exception('AI returned an empty reply');
    }
    return reply;
  }

  Future<void> sendTelegramReply({
    required String conversationId,
    required String text,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/sendTelegramReply'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'conversationId': conversationId,
        'text': text,
      }),
    );

    final data = _decode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        _humanizeBackendError(
          data['error']?.toString(),
          fallback: 'Failed to send Telegram reply',
        ),
      );
    }
  }

  Map<String, dynamic> _decode(String body) {
    if (body.trim().isEmpty) {
      return <String, dynamic>{};
    }
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    return <String, dynamic>{'value': decoded};
  }

  String _humanizeBackendError(String? error, {required String fallback}) {
    final text = error?.trim();
    if (text == null || text.isEmpty) {
      return fallback;
    }

    final normalized = text.toLowerCase();
    if (normalized.contains('insufficient_quota') ||
        normalized.contains('exceeded your current quota') ||
        normalized.contains('billing details') ||
        normalized.contains('run out of credits') ||
        normalized.contains('maximum monthly spend')) {
      return 'Лимит OpenAI API исчерпан. Пополни баланс или включи billing в OpenAI Platform, затем попробуй снова.';
    }

    if (normalized.contains('api key not valid') ||
        normalized.contains('invalid api key') ||
        normalized.contains('incorrect api key')) {
      return 'OpenAI API key недействителен. Проверь ключ и обнови секрет OPENAI_API_KEY.';
    }

    return text;
  }
}
