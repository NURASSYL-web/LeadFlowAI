import 'package:flutter/material.dart';

import '../data/models/whatsapp_connection_state.dart';
import '../data/models/salon_model.dart';
import '../services/whatsapp_business_service.dart';

class WhatsAppConnectionProvider extends ChangeNotifier {
  final WhatsAppBusinessService _service = const WhatsAppBusinessService();
  WhatsAppConnectionState _state = const WhatsAppConnectionState(
    status: WhatsAppConnectionStatus.disconnected,
  );

  WhatsAppConnectionState get state => _state;

  Future<void> syncFromSalon(SalonModel? salon) async {
    _state = await _service.resolveConnection(salon);
    notifyListeners();
  }

  Future<void> reconnect(SalonModel? salon) async {
    _state = WhatsAppConnectionState(
      status: WhatsAppConnectionStatus.syncing,
      connectedNumber: salon?.whatsappNumber,
    );
    notifyListeners();
    _state = await _service.resolveConnection(salon);
    notifyListeners();
  }
}
