import '../models/bus_route_model.dart';
import '../services/firestore_service.dart';

/// Репозиторий маршрутов автобусов. Как и у партнёрской ленты, данных на
/// район немного и без срока действия — постраничная загрузка не нужна,
/// весь список запрашивается одним запросом и сортируется по [order].
/// Композитный индекс (district ASC, order ASC) должен быть создан в
/// Firestore Console (см. firestore.indexes.json).
class BusRouteRepository {
  static const String _collection = 'bus_routes';

  final FirestoreService _firestoreService;

  BusRouteRepository({FirestoreService? firestoreService})
      : _firestoreService = firestoreService ?? FirestoreService();

  Future<List<BusRouteModel>> getRoutes(String districtId) async {
    final snapshot = await _firestoreService
        .collection(_collection)
        .where('district', isEqualTo: districtId)
        .orderBy('order')
        .get();

    return snapshot.docs.map(BusRouteModel.fromFirestore).toList();
  }

  Future<BusRouteModel?> getRouteById(String id) async {
    final doc = await _firestoreService.collection(_collection).doc(id).get();
    if (!doc.exists) return null;
    return BusRouteModel.fromFirestore(doc);
  }
}
