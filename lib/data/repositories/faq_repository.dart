import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/faq_model.dart';

class FaqRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  Stream<List<FaqModel>> watchFaqs(String salonId) {
    return _db
        .collection('faqItems')
        .where('salonId', isEqualTo: salonId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => FaqModel.fromMap(d.data())).toList());
  }

  Future<FaqModel> createFaq(FaqModel faq) async {
    final id = _uuid.v4();
    final newFaq = FaqModel(
        faqId: id,
        salonId: faq.salonId,
        question: faq.question,
        answer: faq.answer,
        createdAt: DateTime.now());
    await _db.collection('faqItems').doc(id).set(newFaq.toMap());
    return newFaq;
  }

  Future<void> updateFaq(FaqModel faq) async {
    await _db.collection('faqItems').doc(faq.faqId).update(faq.toMap());
  }

  Future<void> deleteFaq(String faqId) async {
    await _db.collection('faqItems').doc(faqId).delete();
  }
}
