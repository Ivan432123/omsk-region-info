import '../core/constants/app_constants.dart';
import '../models/feature_flags_model.dart';
import '../services/firestore_service.dart';

/// Читает фиче-флаги в реальном времени, чтобы включение/выключение опции
/// супер-админом в веб-панели отражалось у уже открытого приложения без
/// перезапуска.
class FeatureFlagsRepository {
  final FirestoreService _firestoreService;

  FeatureFlagsRepository({FirestoreService? firestoreService})
      : _firestoreService = firestoreService ?? FirestoreService();

  Stream<FeatureFlagsModel> watchFeatureFlags() {
    return _firestoreService
        .collection(AppConstants.collectionSettings)
        .doc(AppConstants.settingsFeaturesDocId)
        .snapshots()
        .map((doc) => FeatureFlagsModel.fromMap(doc.data()));
  }
}
