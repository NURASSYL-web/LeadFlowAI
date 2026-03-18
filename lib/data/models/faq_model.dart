import 'package:cloud_firestore/cloud_firestore.dart';

class FaqModel {
  final String faqId;
  final String salonId;
  final String question;
  final String answer;
  final DateTime createdAt;
  FaqModel(
      {required this.faqId,
      required this.salonId,
      required this.question,
      required this.answer,
      required this.createdAt});
  factory FaqModel.fromMap(Map<String, dynamic> map) => FaqModel(
        faqId: map['faqId'] ?? '',
        salonId: map['salonId'] ?? '',
        question: map['question'] ?? '',
        answer: map['answer'] ?? '',
        createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
  Map<String, dynamic> toMap() => {
        'faqId': faqId,
        'salonId': salonId,
        'question': question,
        'answer': answer,
        'createdAt': Timestamp.fromDate(createdAt)
      };
  FaqModel copyWith({String? question, String? answer}) => FaqModel(
      faqId: faqId,
      salonId: salonId,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      createdAt: createdAt);
}
