import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/salon_model.dart';

class SalonRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  Future<SalonModel?> getSalonByOwner(String ownerUid) async {
    final snap = await _db
        .collection('salons')
        .where('ownerUid', isEqualTo: ownerUid)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return null;
    return SalonModel.fromMap(snap.docs.first.data());
  }

  Future<SalonModel> createSalon(SalonModel salon) async {
    final id = _uuid.v4();
    final created = SalonModel(
      salonId: id,
      ownerUid: salon.ownerUid,
      businessName: salon.businessName,
      businessType: salon.businessType,
      whatsappNumber: salon.whatsappNumber,
      phone: salon.phone,
      address: salon.address,
      workingHours: salon.workingHours,
      city: salon.city,
      createdAt: DateTime.now(),
    );
    await _db.collection('salons').doc(id).set(created.toMap());
    return created;
  }

  Future<void> updateSalon(SalonModel salon) async {
    await _db.collection('salons').doc(salon.salonId).update(salon.toMap());
  }

  Future<void> deleteSalon(String salonId) async {
    await _db.collection('salons').doc(salonId).delete();
  }
}
