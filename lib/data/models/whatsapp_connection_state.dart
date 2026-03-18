enum WhatsAppConnectionStatus {
  connected,
  syncing,
  disconnected,
  error,
}

class WhatsAppConnectionState {
  final WhatsAppConnectionStatus status;
  final DateTime? lastSyncedAt;
  final String? errorMessage;
  final String? connectedNumber;
  final bool isMock;

  const WhatsAppConnectionState({
    required this.status,
    this.lastSyncedAt,
    this.errorMessage,
    this.connectedNumber,
    this.isMock = false,
  });

  bool get isConnected => status == WhatsAppConnectionStatus.connected;

  String get label {
    switch (status) {
      case WhatsAppConnectionStatus.connected:
        return 'Connected';
      case WhatsAppConnectionStatus.syncing:
        return 'Syncing';
      case WhatsAppConnectionStatus.disconnected:
        return 'Not connected';
      case WhatsAppConnectionStatus.error:
        return 'Connection error';
    }
  }
}
