String normalizePhoneNumber(String input) {
  return input.replaceAll(RegExp(r'[^0-9]'), '');
}

String buildWhatsAppUrl({
  required String phoneNumber,
  String? text,
}) {
  final normalizedPhone = normalizePhoneNumber(phoneNumber);
  final encodedText = Uri.encodeComponent(text ?? '');
  if (encodedText.isEmpty) {
    return 'https://wa.me/$normalizedPhone';
  }
  return 'https://wa.me/$normalizedPhone?text=$encodedText';
}
