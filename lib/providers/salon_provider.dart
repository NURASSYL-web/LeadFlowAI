import 'package:flutter/material.dart';
import '../data/models/salon_model.dart';
import '../data/models/service_model.dart';
import '../data/models/faq_model.dart';
import '../data/repositories/salon_repository.dart';
import '../data/repositories/service_repository.dart';
import '../data/repositories/faq_repository.dart';

class SalonProvider extends ChangeNotifier {
  final SalonRepository _salonRepo = SalonRepository();
  final ServiceRepository _serviceRepo = ServiceRepository();
  final FaqRepository _faqRepo = FaqRepository();

  SalonModel? _salon;
  List<ServiceModel> _services = [];
  List<FaqModel> _faqs = [];
  bool _loading = false;
  String? _error;

  SalonModel? get salon => _salon;
  List<ServiceModel> get services => _services;
  List<FaqModel> get faqs => _faqs;
  bool get loading => _loading;
  String? get error => _error;
  bool get hasSalon => _salon != null;

  Future<void> loadSalon(String ownerUid) async {
    _loading = true;
    notifyListeners();
    try {
      _salon = await _salonRepo.getSalonByOwner(ownerUid);
      if (_salon != null) {
        _listenServices(_salon!.salonId);
        _listenFaqs(_salon!.salonId);
      }
    } catch (e) {
      _error = e.toString();
    }
    _loading = false;
    notifyListeners();
  }

  void _listenServices(String salonId) {
    _serviceRepo.watchServices(salonId).listen((list) {
      _services = list;
      notifyListeners();
    });
  }

  void _listenFaqs(String salonId) {
    _faqRepo.watchFaqs(salonId).listen((list) {
      _faqs = list;
      notifyListeners();
    });
  }

  Future<void> createOrUpdateSalon(SalonModel salon) async {
    _loading = true;
    notifyListeners();
    try {
      if (_salon == null) {
        _salon = await _salonRepo.createSalon(salon);
        _listenServices(_salon!.salonId);
        _listenFaqs(_salon!.salonId);
      } else {
        final updated = salon.copyWith(
          businessName: salon.businessName,
          businessType: salon.businessType,
          whatsappNumber: salon.whatsappNumber,
          phone: salon.phone,
          address: salon.address,
          workingHours: salon.workingHours,
          city: salon.city,
        );
        await _salonRepo.updateSalon(updated);
        _salon = updated;
      }
    } catch (e) {
      _error = e.toString();
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> addService(ServiceModel service) async {
    final newService = await _serviceRepo.createService(service);
    _services = [..._services, newService];
    notifyListeners();
  }

  Future<void> updateService(ServiceModel service) async {
    await _serviceRepo.updateService(service);
    _services = _services
        .map((s) => s.serviceId == service.serviceId ? service : s)
        .toList();
    notifyListeners();
  }

  Future<void> deleteService(String serviceId) async {
    await _serviceRepo.deleteService(serviceId);
    _services = _services.where((s) => s.serviceId != serviceId).toList();
    notifyListeners();
  }

  Future<void> addFaq(FaqModel faq) async {
    final newFaq = await _faqRepo.createFaq(faq);
    _faqs = [..._faqs, newFaq];
    notifyListeners();
  }

  Future<void> updateFaq(FaqModel faq) async {
    await _faqRepo.updateFaq(faq);
    _faqs = _faqs.map((f) => f.faqId == faq.faqId ? faq : f).toList();
    notifyListeners();
  }

  Future<void> deleteFaq(String faqId) async {
    await _faqRepo.deleteFaq(faqId);
    _faqs = _faqs.where((f) => f.faqId != faqId).toList();
    notifyListeners();
  }

  String generateSuggestedReply(String customerMessage, String intentType) {
    if (_salon == null) return '';
    final salonName = _salon!.businessName;
    final serviceList = _services
        .where((s) => s.isActive)
        .map((s) =>
            '${s.name} — \$${s.price.toStringAsFixed(0)} (${s.duration} min)')
        .join('\n');

    switch (intentType) {
      case 'Booking Request':
        return 'Hi! Thank you for your interest in $salonName 💜\nWe\'d love to book you in!\n\nOur working hours: ${_salon!.workingHours ?? 'Please contact us for availability'}.\n\nPlease let us know your preferred date and time, and we\'ll confirm right away. 😊';
      case 'Price Question':
        final prices = serviceList.isNotEmpty
            ? '\n\nOur current services & pricing:\n$serviceList'
            : '';
        return 'Hi! Thanks for reaching out to $salonName 💜$prices\n\nFeel free to ask about any specific service! 😊';
      case 'Complaint':
        return 'Hi, we\'re so sorry to hear about your experience at $salonName. Your satisfaction is our top priority. 🙏\n\nCould you share more details so we can make it right for you? We take all feedback seriously.';
      default:
        final faqAnswer = _faqs.firstWhere(
          (f) => customerMessage
              .toLowerCase()
              .contains(f.question.toLowerCase().split(' ').first),
          orElse: () => FaqModel(
              faqId: '',
              salonId: '',
              question: '',
              answer: '',
              createdAt: DateTime.now()),
        );
        if (faqAnswer.answer.isNotEmpty) return faqAnswer.answer;
        return 'Hi! Thanks for reaching out to $salonName 💜\n\nWe\'ll get back to you shortly. Is there anything specific you\'d like to know about our services?';
    }
  }

  void clear() {
    _salon = null;
    _services = [];
    _faqs = [];
    notifyListeners();
  }
}
