import '../data/models/faq_model.dart';
import '../data/models/service_model.dart';

class LocalReplyService {
  const LocalReplyService();

  static const Set<String> _stopWords = {
    'сколько',
    'стоит',
    'цена',
    'прайс',
    'можно',
    'ли',
    'у',
    'вас',
    'есть',
    'на',
    'по',
    'и',
    'в',
    'как',
    'when',
    'what',
    'how',
    'much',
    'cost',
    'price',
    'the',
    'a',
    'an',
    'is',
  };

  String buildReply({
    required String latestMessage,
    required String businessName,
    required List<ServiceModel> services,
    required List<FaqModel> faqs,
  }) {
    final normalizedMessage = _normalize(latestMessage);
    final matchedService = _findBestService(normalizedMessage, services);
    if (matchedService != null) {
      return _buildServiceReply(matchedService, businessName);
    }

    final matchedFaq = _findBestFaq(normalizedMessage, faqs);
    if (matchedFaq != null) {
      return matchedFaq.answer.trim();
    }

    final activeServices = services.where((service) => service.isActive).toList();
    if (activeServices.isNotEmpty) {
      final names = activeServices.take(3).map((service) => service.name).join(', ');
      return 'Здравствуйте! Спасибо за сообщение в $businessName. '
          'Уточните, пожалуйста, какая именно услуга вас интересует. '
          'Сейчас у нас доступны: $names.';
    }

    return 'Здравствуйте! Спасибо за сообщение в $businessName. '
        'Напишите, пожалуйста, какая услуга вас интересует, и мы подготовим ответ.';
  }

  ServiceModel? _findBestService(
    String normalizedMessage,
    List<ServiceModel> services,
  ) {
    ServiceModel? bestMatch;
    var bestScore = 0;

    for (final service in services.where((item) => item.isActive)) {
      final score = _scoreService(normalizedMessage, service);
      if (score > bestScore) {
        bestScore = score;
        bestMatch = service;
      }
    }

    return bestScore > 0 ? bestMatch : null;
  }

  FaqModel? _findBestFaq(String normalizedMessage, List<FaqModel> faqs) {
    FaqModel? bestMatch;
    var bestScore = 0;

    for (final faq in faqs) {
      final score = _tokenScore(normalizedMessage, faq.question);
      if (score > bestScore) {
        bestScore = score;
        bestMatch = faq;
      }
    }

    return bestScore >= 2 ? bestMatch : null;
  }

  int _scoreService(String normalizedMessage, ServiceModel service) {
    final normalizedName = _normalize(service.name);
    final normalizedCategory = _normalize(service.category);
    final normalizedKeywords =
        service.keywords.map(_normalize).where((item) => item.isNotEmpty).toList();
    var score = 0;

    if (normalizedName.isNotEmpty && normalizedMessage.contains(normalizedName)) {
      score += 10;
    }
    if (normalizedCategory.isNotEmpty &&
        normalizedMessage.contains(normalizedCategory)) {
      score += 4;
    }
    for (final keyword in normalizedKeywords) {
      if (normalizedMessage.contains(keyword)) {
        score += 20;
      }
    }

    score += _tokenScore(normalizedMessage, service.name) * 3;
    score += _tokenScore(normalizedMessage, service.keywords.join(' ')) * 4;
    score += _tokenScore(normalizedMessage, service.category) * 2;
    score += _tokenScore(normalizedMessage, service.description);

    return score;
  }

  int _tokenScore(String normalizedMessage, String source) {
    final tokens = _tokens(source);
    var score = 0;
    for (final token in tokens) {
      if (normalizedMessage.contains(token)) {
        score += 1;
      }
    }
    return score;
  }

  Set<String> _tokens(String input) {
    return _normalize(input)
        .split(' ')
        .map((token) => token.trim())
        .where((token) => token.length >= 3 && !_stopWords.contains(token))
        .toSet();
  }

  String _buildServiceReply(ServiceModel service, String businessName) {
    final template = service.autoReplyTemplate.trim();
    if (template.isNotEmpty) {
      return template
          .replaceAll('{service}', service.name)
          .replaceAll('{price}', service.price.toStringAsFixed(0))
          .replaceAll('{duration}', service.duration.toString())
          .replaceAll('{businessName}', businessName)
          .replaceAll('{description}', service.description.trim());
    }

    final description = service.description.trim();
    final descriptionLine =
        description.isEmpty ? '' : ' $description';

    return 'Здравствуйте! $businessName предлагает услугу "${service.name}" '
        'за ${service.price.toStringAsFixed(0)} KZT, длительность ${service.duration} мин.'
        '$descriptionLine';
  }

  String _normalize(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-zA-Zа-яА-Я0-9]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
