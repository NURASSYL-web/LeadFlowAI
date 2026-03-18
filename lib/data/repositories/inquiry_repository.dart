import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/inquiry_model.dart';

class InquiryRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  Stream<List<InquiryModel>> watchInquiries({
    required String salonId,
    String? ownerUid,
  }) {
    return _db
        .collection('conversations')
        .where('channel', isEqualTo: 'telegram')
        .snapshots()
        .map((snap) {
      final inquiries = snap.docs
          .map(
            (doc) => InquiryModel.fromConversationMap(doc.data(), doc.id),
          )
          .toList();

      inquiries.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return inquiries;
    });
  }

  Future<void> migrateLegacyInquiries(String salonId) async {
    final legacyDocs = await _db
        .collection('inquiries')
        .where('salonId', isEqualTo: salonId)
        .get();

    for (final doc in legacyDocs.docs) {
      final inquiry = InquiryModel.fromMap(doc.data());
      final conversationRef =
          _db.collection('conversations').doc(inquiry.inquiryId);
      final conversationSnapshot = await conversationRef.get();

      if (conversationSnapshot.exists) {
        continue;
      }

      final batch = _db.batch();
      batch.set(conversationRef, _conversationDataFromInquiry(inquiry));
      batch.set(
        conversationRef
            .collection('messages')
            .doc('${inquiry.inquiryId}-initial'),
        _messageDataFromInquiry(
          inquiry: inquiry,
          messageId: '${inquiry.inquiryId}-initial',
        ),
      );
      await batch.commit();
    }
  }

  Future<InquiryModel> createInquiry(InquiryModel inquiry) async {
    final id = _uuid.v4();
    final messageId = _uuid.v4();
    final now = DateTime.now();
    final newInquiry = InquiryModel(
      inquiryId: id,
      salonId: inquiry.salonId,
      customerName: inquiry.customerName,
      customerPhone: inquiry.customerPhone,
      channel: inquiry.channel,
      message: inquiry.message,
      intentType: inquiry.intentType,
      status: inquiry.status,
      suggestedReply: inquiry.suggestedReply,
      unreadCount: inquiry.unreadCount,
      createdAt: now,
      updatedAt: now,
    );
    final batch = _db.batch();
    batch.set(_db.collection('inquiries').doc(id), newInquiry.toMap());
    final conversationRef = _db.collection('conversations').doc(id);
    batch.set(conversationRef, _conversationDataFromInquiry(newInquiry));
    batch.set(
      conversationRef.collection('messages').doc(messageId),
      _messageDataFromInquiry(inquiry: newInquiry, messageId: messageId),
    );
    await batch.commit();
    return newInquiry;
  }

  Future<void> updateInquiry(InquiryModel inquiry) async {
    final updated = inquiry.copyWith();
    final batch = _db.batch();
    batch.set(
      _db.collection('inquiries').doc(inquiry.inquiryId),
      updated.toMap(),
      SetOptions(merge: true),
    );
    batch.set(
      _db.collection('conversations').doc(inquiry.inquiryId),
      _conversationDataFromInquiry(updated),
      SetOptions(merge: true),
    );
    await batch.commit();
  }

  Future<void> updateStatus(String inquiryId, String status) async {
    final now = Timestamp.fromDate(DateTime.now());
    final batch = _db.batch();
    batch.set(
      _db.collection('inquiries').doc(inquiryId),
      {'status': status, 'updatedAt': now},
      SetOptions(merge: true),
    );
    batch.set(
      _db.collection('conversations').doc(inquiryId),
      {'status': status, 'updatedAt': now},
      SetOptions(merge: true),
    );
    await batch.commit();
  }

  Future<void> updateSuggestedReply(
      String inquiryId, String suggestedReply) async {
    final now = Timestamp.fromDate(DateTime.now());
    await _db.collection('conversations').doc(inquiryId).set({
      'suggestedReply': suggestedReply,
      'updatedAt': now,
    }, SetOptions(merge: true));
  }

  Future<void> deleteInquiry(String inquiryId) async {
    final messages = await _db
        .collection('conversations')
        .doc(inquiryId)
        .collection('messages')
        .get();
    final batch = _db.batch();
    for (final doc in messages.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_db.collection('conversations').doc(inquiryId));
    batch.delete(_db.collection('inquiries').doc(inquiryId));
    await batch.commit();
  }

  Map<String, dynamic> _conversationDataFromInquiry(InquiryModel inquiry) {
    return {
      'conversationId': inquiry.inquiryId,
      'salonId': inquiry.salonId,
      'customerName': inquiry.customerName,
      'customerPhone': inquiry.customerPhone,
      'channel': 'manual',
      'lastMessage': inquiry.message,
      'lastMessageAt': Timestamp.fromDate(inquiry.updatedAt),
      'intentType': inquiry.intentType,
      'status': inquiry.status,
      'suggestedReply': inquiry.suggestedReply,
      'unreadCount': inquiry.unreadCount,
      'updatedAt': Timestamp.fromDate(inquiry.updatedAt),
      'createdAt': Timestamp.fromDate(inquiry.createdAt),
    };
  }

  Map<String, dynamic> _messageDataFromInquiry({
    required InquiryModel inquiry,
    required String messageId,
  }) {
    return {
      'messageId': messageId,
      'conversationId': inquiry.inquiryId,
      'from': inquiry.customerPhone,
      'direction': 'inbound',
      'type': 'text',
      'text': inquiry.message,
      'createdAt': Timestamp.fromDate(inquiry.createdAt),
      'updatedAt': Timestamp.fromDate(inquiry.updatedAt),
    };
  }
}
