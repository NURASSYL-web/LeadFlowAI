import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceModel {
  final String serviceId;
  final String salonId;
  final String name;
  final String description;
  final String autoReplyTemplate;
  final List<String> keywords;
  final String category;
  final double price;
  final int duration;
  final bool isActive;
  final DateTime createdAt;
  ServiceModel(
      {required this.serviceId,
      required this.salonId,
      required this.name,
      required this.description,
      this.autoReplyTemplate = '',
      this.keywords = const [],
      required this.category,
      required this.price,
      required this.duration,
      this.isActive = true,
      required this.createdAt});

  static String _stringValue(dynamic value) {
    if (value == null) {
      return '';
    }
    if (value is String) {
      return value;
    }
    return value.toString();
  }

  static double _doubleValue(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }

  static int _intValue(dynamic value, {int fallback = 60}) {
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static bool _boolValue(dynamic value, {bool fallback = true}) {
    if (value is bool) {
      return value;
    }
    if (value is String) {
      final normalized = value.toLowerCase().trim();
      if (normalized == 'true') {
        return true;
      }
      if (normalized == 'false') {
        return false;
      }
    }
    return fallback;
  }

  static List<String> _stringListValue(dynamic value) {
    if (value == null) {
      return const <String>[];
    }

    if (value is List) {
      return value
          .map((item) => _stringValue(item).trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }

    final text = _stringValue(value);
    if (text.trim().isEmpty) {
      return const <String>[];
    }

    return text
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  factory ServiceModel.fromMap(
    Map<String, dynamic> map, {
    String? documentId,
  }) =>
      ServiceModel(
        serviceId: _stringValue(map['serviceId']).trim().isNotEmpty
            ? _stringValue(map['serviceId']).trim()
            : (documentId ?? ''),
        salonId: _stringValue(map['salonId']),
        name: _stringValue(map['name']).trim().isEmpty
            ? 'Без названия'
            : _stringValue(map['name']).trim(),
        description: _stringValue(map['description']),
        autoReplyTemplate: _stringValue(map['autoReplyTemplate']),
        keywords: _stringListValue(map['keywords']),
        category: _stringValue(map['category']).trim().isEmpty
            ? 'Other'
            : _stringValue(map['category']).trim(),
        price: _doubleValue(map['price']),
        duration: _intValue(map['duration']),
        isActive: _boolValue(map['isActive']),
        createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
  Map<String, dynamic> toMap() => {
        'serviceId': serviceId,
        'salonId': salonId,
        'name': name,
        'description': description,
        'autoReplyTemplate': autoReplyTemplate,
        'keywords': keywords,
        'category': category,
        'price': price,
        'duration': duration,
        'isActive': isActive,
        'createdAt': Timestamp.fromDate(createdAt)
      };
  ServiceModel copyWith(
          {String? name,
          String? description,
          String? autoReplyTemplate,
          List<String>? keywords,
          String? category,
          double? price,
          int? duration,
          bool? isActive}) =>
      ServiceModel(
          serviceId: serviceId,
          salonId: salonId,
          name: name ?? this.name,
          description: description ?? this.description,
          autoReplyTemplate: autoReplyTemplate ?? this.autoReplyTemplate,
          keywords: keywords ?? this.keywords,
          category: category ?? this.category,
          price: price ?? this.price,
          duration: duration ?? this.duration,
          isActive: isActive ?? this.isActive,
          createdAt: createdAt);
}
