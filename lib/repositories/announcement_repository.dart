import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/announcement_model.dart';
import '../services/firestore_service.dart';

/// Репозиторий объявлений. Фильтрация по district, как у новостей и
/// вакансий. Композитный индекс (district ASC, createdAt DESC) должен
/// быть создан в Firestore Console для коллекции announcements.
/// Для продвигаемых объявлений (isPromoted) понадобится ещё один
/// композитный индекс (district ASC, isPromoted ASC, createdAt DESC) —
/// Firestore подскажет ссылку на его создание при первой ошибке запроса.
class AnnouncementRepository {
  static const String _collection = 'announcements';
  static const int _pageSize = 15;

  final FirestoreService _firestoreService;

  AnnouncementRepository({FirestoreService? firestoreService})
      : _firestoreService = firestoreService ?? FirestoreService();

  Query<Map<String, dynamic>> _baseQuery(String districtId) {
    return _firestoreService
        .collection(_collection)
        .where('district', isEqualTo: districtId)
        .orderBy('createdAt', descending: true);
  }

  Future<({List<AnnouncementModel> items, DocumentSnapshot<Map<String, dynamic>>? lastDoc})>
      getAnnouncementsPage({
    required String districtId,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  }) async {
    final query = _baseQuery(districtId);

    final snapshot = await _firestoreService.fetchPage(
      query: query,
      startAfter: startAfter,
      limit: _pageSize,
    );

    final items = snapshot.docs.map(AnnouncementModel.fromFirestore).toList();
    final lastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;

    return (items: items, lastDoc: lastDoc);
  }

  Future<AnnouncementModel?> getAnnouncementById(String id) async {
    final doc = await _firestoreService.collection(_collection).doc(id).get();
    if (!doc.exists) return null;
    return AnnouncementModel.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>);
  }

  /// Продвигаемые (оплаченные) объявления района — для отдельного блока
  /// на главном экране. Ограничено небольшим количеством, так как это
  /// витрина, а не полный список.
  Future<List<AnnouncementModel>> getPromotedAnnouncements(
    String districtId, {
    int limit = 5,
  }) async {
    final snapshot = await _firestoreService
        .collection(_collection)
        .where('district', isEqualTo: districtId)
        .where('isPromoted', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.map(AnnouncementModel.fromFirestore).toList();
  }
}
