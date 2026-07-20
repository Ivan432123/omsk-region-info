import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/announcement_model.dart';
import '../services/firestore_service.dart';

/// Репозиторий объявлений. Фильтрация по district, как у новостей и
/// вакансий. Объявления автоматически скрываются из общего списка через
/// 14 дней после публикации (тот же приём, что уже применён к вакансиям)
/// — админка при этом видит все записи без ограничения по возрасту.
/// Композитные индексы (district ASC, createdAt DESC) и
/// (district ASC, promotedUntil DESC) должны быть созданы в Firestore
/// Console для коллекции announcements.
class AnnouncementRepository {
  static const String _collection = 'announcements';
  static const int _pageSize = 15;
  static const Duration _maxAge = Duration(days: 14);

  final FirestoreService _firestoreService;

  AnnouncementRepository({FirestoreService? firestoreService})
      : _firestoreService = firestoreService ?? FirestoreService();

  Query<Map<String, dynamic>> _baseQuery(String districtId) {
    final cutoff = Timestamp.fromDate(DateTime.now().subtract(_maxAge));
    return _firestoreService
        .collection(_collection)
        .where('district', isEqualTo: districtId)
        .where('createdAt', isGreaterThanOrEqualTo: cutoff)
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

  /// Продвигаемые (оплаченные, ещё не истёкшие) объявления района — для
  /// отдельного блока на главном экране и в верхней части списка.
  Future<List<AnnouncementModel>> getPromotedAnnouncements(
    String districtId, {
    int limit = 5,
  }) async {
    final snapshot = await _firestoreService
        .collection(_collection)
        .where('district', isEqualTo: districtId)
        .where('promotedUntil', isGreaterThan: Timestamp.now())
        .orderBy('promotedUntil', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.map(AnnouncementModel.fromFirestore).toList();
  }
}
