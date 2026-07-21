import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/sponsored_content_model.dart';
import '../services/firestore_service.dart';

/// Репозиторий партнёрской (спонсорской) ленты — см. TASKS.md, партия 3.4.
/// Firestore требует, чтобы первый orderBy совпадал с полем, по которому
/// стоит неравенство (activeUntil), поэтому сортировка по [order]
/// (позиция карточки в ленте) выполняется уже на клиенте, после фильтрации
/// по сроку действия. Композитный индекс (district ASC, activeUntil ASC)
/// должен быть создан в Firestore Console.
class SponsoredContentRepository {
  static const String _collection = 'sponsored_content';

  final FirestoreService _firestoreService;

  SponsoredContentRepository({FirestoreService? firestoreService})
      : _firestoreService = firestoreService ?? FirestoreService();

  Future<List<SponsoredContentModel>> getActiveSponsoredContent(
    String districtId, {
    int limit = 10,
  }) async {
    final snapshot = await _firestoreService
        .collection(_collection)
        .where('district', isEqualTo: districtId)
        .where('activeUntil', isGreaterThan: Timestamp.now())
        .orderBy('activeUntil')
        .limit(limit)
        .get();

    final items =
        snapshot.docs.map(SponsoredContentModel.fromFirestore).toList();
    items.sort((a, b) => a.order.compareTo(b.order));
    return items;
  }

  /// Инкремент кликов по баннеру — единственная метрика, которую можно
  /// показать рекламодателю без полноценной аналитики. Правило Firestore
  /// разрешает это обновление анонимно, но только по полям clickCount и
  /// lastClickedAt (см. firestore.rules).
  Future<void> recordClick(String id) {
    return _firestoreService.collection(_collection).doc(id).update({
      'clickCount': FieldValue.increment(1),
      'lastClickedAt': FieldValue.serverTimestamp(),
    });
  }
}
