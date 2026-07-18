import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_model.dart';
import '../services/firestore_service.dart';

/// Репозиторий афиши (событий района).
/// Сортировка по дате проведения (eventDate) по возрастанию — ближайшие
/// события показываются первыми. Композитный индекс
/// (district ASC, eventDate ASC) должен быть создан в Firestore Console.
class EventRepository {
  static const String _collection = 'events';
  static const int _pageSize = 15;

  final FirestoreService _firestoreService;

  EventRepository({FirestoreService? firestoreService})
      : _firestoreService = firestoreService ?? FirestoreService();

  Query<Map<String, dynamic>> _baseQuery(String districtId) {
    return _firestoreService
        .collection(_collection)
        .where('district', isEqualTo: districtId)
        .orderBy('eventDate', descending: false);
  }

  Future<({List<EventModel> items, DocumentSnapshot<Map<String, dynamic>>? lastDoc})>
      getEventsPage({
    required String districtId,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  }) async {
    final query = _baseQuery(districtId);

    final snapshot = await _firestoreService.fetchPage(
      query: query,
      startAfter: startAfter,
      limit: _pageSize,
    );

    final items = snapshot.docs.map(EventModel.fromFirestore).toList();
    final lastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;

    return (items: items, lastDoc: lastDoc);
  }

  Future<EventModel?> getEventById(String id) async {
    final doc = await _firestoreService.collection(_collection).doc(id).get();
    if (!doc.exists) return null;
    return EventModel.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>);
  }
}
