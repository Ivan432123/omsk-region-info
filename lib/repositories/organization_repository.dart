import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';
import '../models/organization_model.dart';
import '../services/firestore_service.dart';

class OrganizationRepository {
  final FirestoreService _firestoreService;

  OrganizationRepository({FirestoreService? firestoreService})
      : _firestoreService = firestoreService ?? FirestoreService();

  Future<
      ({
        List<OrganizationModel> items,
        DocumentSnapshot<Map<String, dynamic>>? lastDoc
      })> getOrganizationsPage({
    required String districtId,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  }) async {
    final query = _firestoreService
        .collection(AppConstants.collectionOrganizations)
        .where('district', isEqualTo: districtId)
        .orderBy('name');

    final snapshot = await _firestoreService.fetchPage(
      query: query,
      startAfter: startAfter,
      limit: AppConstants.pageSize,
    );

    final items = snapshot.docs.map(OrganizationModel.fromFirestore).toList();
    final lastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;

    return (items: items, lastDoc: lastDoc);
  }

  Future<OrganizationModel?> getOrganizationById(String id) async {
    final doc = await _firestoreService
        .collection(AppConstants.collectionOrganizations)
        .doc(id)
        .get();

    if (!doc.exists) return null;
    return OrganizationModel.fromFirestore(doc);
  }

  /// Голос (звёзды 1-5) устройства [deviceId] за организацию [orgId], если
  /// уже голосовало. Использует подколлекцию organizations/{orgId}/ratings/
  /// {deviceId} — id документа = deviceId, поэтому у устройства может быть
  /// не больше одного голоса за организацию.
  Future<int?> getMyRating(String orgId, String deviceId) async {
    final doc = await _firestoreService
        .collection(AppConstants.collectionOrganizations)
        .doc(orgId)
        .collection('ratings')
        .doc(deviceId)
        .get();
    if (!doc.exists) return null;
    return (doc.data()?['stars'] as num?)?.toInt();
  }

  /// Отправляет/меняет голос устройства [deviceId] за организацию [orgId] и
  /// пересчитывает агрегат (ratingSum/ratingCount) на самой организации —
  /// транзакцией, без Cloud Functions (их в проекте нет, тариф Blaze
  /// недоступен). Повторное голосование тем же устройством перезаписывает
  /// его же документ в подколлекции, а не создаёт новый.
  Future<void> submitRating(String orgId, String deviceId, int stars) async {
    final orgRef = _firestoreService
        .collection(AppConstants.collectionOrganizations)
        .doc(orgId);
    final ratingRef = orgRef.collection('ratings').doc(deviceId);

    await _firestoreService.instance.runTransaction((tx) async {
      final orgSnapshot = await tx.get(orgRef);
      final ratingSnapshot = await tx.get(ratingRef);

      final currentSum = (orgSnapshot.data()?['ratingSum'] as num?) ?? 0;
      final currentCount = (orgSnapshot.data()?['ratingCount'] as num?) ?? 0;
      final oldStars = ratingSnapshot.exists
          ? (ratingSnapshot.data()?['stars'] as num?)?.toInt()
          : null;

      final deltaSum = oldStars == null ? stars : stars - oldStars;
      final deltaCount = oldStars == null ? 1 : 0;

      tx.set(ratingRef, {
        'stars': stars,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      tx.update(orgRef, {
        'ratingSum': currentSum.toInt() + deltaSum,
        'ratingCount': currentCount.toInt() + deltaCount,
      });
    });
  }
}
