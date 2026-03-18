import 'package:cloud_firestore/cloud_firestore.dart';

import '../data/models/salon_model.dart';
import '../data/models/whatsapp_connection_state.dart';

class WhatsAppBusinessService {
  const WhatsAppBusinessService();

  Future<WhatsAppConnectionState> resolveConnection(SalonModel? salon) async {
    final botHandle = salon?.whatsappNumber?.trim();
    if (salon == null) {
      return const WhatsAppConnectionState(
        status: WhatsAppConnectionStatus.disconnected,
      );
    }

    final snapshot = await _findLinkedConversation(
      salonId: salon.salonId,
      ownerUid: salon.ownerUid,
    );

    if (snapshot.docs.isEmpty) {
      return WhatsAppConnectionState(
        status: WhatsAppConnectionStatus.syncing,
        connectedNumber: botHandle,
        errorMessage:
            'Telegram webhook готов. Ждём первое входящее сообщение боту.',
      );
    }

    final data = snapshot.docs.first.data();
    final lastSyncedAt = (data['updatedAt'] as Timestamp?)?.toDate() ??
        (data['lastMessageAt'] as Timestamp?)?.toDate();

    return WhatsAppConnectionState(
      status: WhatsAppConnectionStatus.connected,
      connectedNumber: (data['telegramBotUsername'] as String?) ?? botHandle,
      lastSyncedAt: lastSyncedAt,
    );
  }

  Future<QuerySnapshot<Map<String, dynamic>>> _findLinkedConversation({
    required String? salonId,
    required String? ownerUid,
  }) async {
    final conversations = FirebaseFirestore.instance.collection('conversations');

    if ((salonId ?? '').trim().isNotEmpty) {
      final bySalon = await conversations
          .where('salonId', isEqualTo: salonId)
          .where('channel', isEqualTo: 'telegram')
          .limit(1)
          .get();
      if (bySalon.docs.isNotEmpty) {
        return bySalon;
      }
    }

    if ((ownerUid ?? '').trim().isNotEmpty) {
      final byOwner = await conversations
          .where('ownerUid', isEqualTo: ownerUid)
          .where('channel', isEqualTo: 'telegram')
          .limit(1)
          .get();
      if (byOwner.docs.isNotEmpty) {
        return byOwner;
      }
    }

    return conversations.where('channel', isEqualTo: 'telegram').limit(1).get();
  }
}
