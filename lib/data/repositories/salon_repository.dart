import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/salon_model.dart';

class SalonRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<SalonModel?> getSalonByOwner(String ownerUid) async {
    final canonicalRef = _db.collection('salons').doc(ownerUid);
    final canonicalSnap = await canonicalRef.get();
    if (canonicalSnap.exists) {
      return SalonModel.fromMap(canonicalSnap.data()!, documentId: canonicalSnap.id);
    }

    final snap = await _db
        .collection('salons')
        .where('ownerUid', isEqualTo: ownerUid)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return null;
    final legacy = SalonModel.fromMap(
      snap.docs.first.data(),
      documentId: snap.docs.first.id,
    );
    final normalized = SalonModel(
      salonId: ownerUid,
      ownerUid: ownerUid,
      businessName: legacy.businessName,
      businessType: legacy.businessType,
      whatsappNumber: legacy.whatsappNumber,
      phone: legacy.phone,
      address: legacy.address,
      workingHours: legacy.workingHours,
      city: legacy.city,
      createdAt: legacy.createdAt,
    );
    await canonicalRef.set(
      normalized.toMap(),
      SetOptions(merge: true),
    );
    return normalized;
  }

  Future<SalonModel> createSalon(SalonModel salon) async {
    final created = SalonModel(
      salonId: salon.ownerUid,
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
    await _db.collection('salons').doc(created.ownerUid).set(created.toMap());
    return created;
  }

  Future<void> updateSalon(SalonModel salon) async {
    final canonicalId =
        salon.ownerUid.trim().isNotEmpty ? salon.ownerUid : salon.salonId;
    final normalized = SalonModel(
      salonId: canonicalId,
      ownerUid: salon.ownerUid,
      businessName: salon.businessName,
      businessType: salon.businessType,
      whatsappNumber: salon.whatsappNumber,
      phone: salon.phone,
      address: salon.address,
      workingHours: salon.workingHours,
      city: salon.city,
      createdAt: salon.createdAt,
    );
    await _db.collection('salons').doc(canonicalId).set(
          normalized.toMap(),
          SetOptions(merge: true),
        );
  }

  Future<void> deleteSalon(String salonId) async {
    await _db.collection('salons').doc(salonId).delete();
  }
}
