import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/service_model.dart';

class ServiceRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  Stream<List<ServiceModel>> watchServices(String salonId) {
    return _db
        .collection('services')
        .where('salonId', isEqualTo: salonId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ServiceModel.fromMap(d.data(), documentId: d.id))
            .toList());
  }

  Future<List<ServiceModel>> getServices(String salonId) async {
    final snap = await _db
        .collection('services')
        .where('salonId', isEqualTo: salonId)
        .get();
    return snap.docs
        .map((d) => ServiceModel.fromMap(d.data(), documentId: d.id))
        .toList();
  }

  Future<ServiceModel> createService(ServiceModel service) async {
    final id = _uuid.v4();
    final newService = ServiceModel(
      serviceId: id,
      salonId: service.salonId,
      name: service.name,
      description: service.description,
      autoReplyTemplate: service.autoReplyTemplate,
      keywords: service.keywords,
      category: service.category,
      price: service.price,
      duration: service.duration,
      isActive: service.isActive,
      createdAt: DateTime.now(),
    );
    await _db.collection('services').doc(id).set(newService.toMap());
    return newService;
  }

  Future<void> updateService(ServiceModel service) async {
    await _db
        .collection('services')
        .doc(service.serviceId)
        .update(service.toMap());
  }

  Future<void> deleteService(String serviceId) async {
    await _db.collection('services').doc(serviceId).delete();
  }
}
