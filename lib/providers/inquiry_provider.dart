import 'dart:async';
import 'package:flutter/material.dart';
import '../data/models/inbox_message_model.dart';
import '../data/models/inquiry_model.dart';
import '../data/repositories/inbox_repository.dart';
import '../data/repositories/inquiry_repository.dart';

class InquiryProvider extends ChangeNotifier {
  final InquiryRepository _repo = InquiryRepository();
  final InboxRepository _inboxRepo = InboxRepository();
  List<InquiryModel> _inquiries = [];
  String? _filterStatus;
  String? _error;
  final bool _loading = false;
  StreamSubscription<List<InquiryModel>>? _inquiriesSub;

  List<InquiryModel> get inquiries => _filterStatus == null
      ? _inquiries
      : _inquiries.where((i) => i.status == _filterStatus).toList();
  bool get loading => _loading;
  String? get filterStatus => _filterStatus;
  String? get error => _error;

  Map<String, int> get statusCounts {
    final map = <String, int>{};
    for (final i in _inquiries) {
      map[i.status] = (map[i.status] ?? 0) + 1;
    }
    return map;
  }

  void listenInquiries({
    required String salonId,
    String? ownerUid,
  }) {
    _inquiriesSub?.cancel();
    _inquiriesSub = _repo
        .watchInquiries(salonId: salonId, ownerUid: ownerUid)
        .listen((list) {
      _error = null;
      _inquiries = list;
      notifyListeners();
    }, onError: (Object error) {
      _error = error.toString();
      notifyListeners();
    });
  }

  Stream<List<InboxMessageModel>> watchMessages(String conversationId) {
    return _inboxRepo.watchMessages(conversationId);
  }

  Future<void> addInquiry(InquiryModel inquiry) async {
    await _repo.createInquiry(inquiry);
  }

  Future<void> updateInquiry(InquiryModel inquiry) async {
    await _repo.updateInquiry(inquiry);
  }

  Future<void> updateStatus(String inquiryId, String status) async {
    await _repo.updateStatus(inquiryId, status);
  }

  Future<void> updateSuggestedReply(
      String inquiryId, String suggestedReply) async {
    await _repo.updateSuggestedReply(inquiryId, suggestedReply);
  }

  Future<void> deleteInquiry(String inquiryId) async {
    await _repo.deleteInquiry(inquiryId);
    _inquiries = _inquiries.where((i) => i.inquiryId != inquiryId).toList();
    notifyListeners();
  }

  void setFilter(String? status) {
    _filterStatus = status;
    notifyListeners();
  }

  void clear() {
    _inquiriesSub?.cancel();
    _inquiriesSub = null;
    _inquiries = [];
    _filterStatus = null;
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _inquiriesSub?.cancel();
    super.dispose();
  }
}
