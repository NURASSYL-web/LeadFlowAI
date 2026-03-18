import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/inbox_message_model.dart';

class InboxRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<InboxMessageModel>> watchMessages(String conversationId) {
    return _db
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt')
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => InboxMessageModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }
}
