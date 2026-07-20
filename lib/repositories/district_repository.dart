import '../core/constants/app_constants.dart';
import '../models/district_model.dart';
import '../services/firestore_service.dart';

/// Репозиторий районов. Возвращает только активные районы (isActive == true),
/// отсортированные по полю order — это позволяет админ-панели (future scope)
/// управлять порядком отображения и временно скрывать район без удаления.
class DistrictRepository {
  final FirestoreService _firestoreService;

  DistrictRepository({FirestoreService? firestoreService})
      : _firestoreService = firestoreService ?? FirestoreService();

  Future<List<DistrictModel>> getDistricts() async {
    final snapshot = await _firestoreService
        .collection(AppConstants.collectionDistricts)
        .where('isActive', isEqualTo: true)
        .orderBy('order')
        .get();

    return snapshot.docs.map(DistrictModel.fromFirestore).toList();
  }

  Future<DistrictModel?> getDistrictById(String id) async {
    final doc = await _firestoreService
        .collection(AppConstants.collectionDistricts)
        .doc(id)
        .get();

    if (!doc.exists) return null;
    return DistrictModel.fromFirestore(doc);
  }
}
