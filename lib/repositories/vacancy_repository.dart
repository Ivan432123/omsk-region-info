import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/vacancy_model.dart';
import '../services/firestore_service.dart';

/// Репозиторий вакансий.
/// Все запросы обязательно фильтруются по district — по аналогии с
/// новостями. Вакансии старше 30 дней с момента публикации автоматически
/// скрываются из выдачи приложения (админка видит все вакансии без
/// ограничения по возрасту — фильтр применяется только здесь).
/// Композитный индекс (district ASC, createdAt DESC) должен быть создан
/// в Firestore Console для коллекции vacancies.
class VacancyRepository {
  static const String _collection = 'vacancies';
  static const int _pageSize = 15;
  static const Duration _maxAge = Duration(days: 30);

  final FirestoreService _firestoreService;

  VacancyRepository({FirestoreService? firestoreService})
      : _firestoreService = firestoreService ?? FirestoreService();

  Query<Map<String, dynamic>> _baseQuery(String districtId) {
    final cutoff = Timestamp.fromDate(DateTime.now().subtract(_maxAge));
    return _firestoreService
        .collection(_collection)
        .where('district', isEqualTo: districtId)
        .where('createdAt', isGreaterThanOrEqualTo: cutoff)
        .orderBy('createdAt', descending: true);
  }

  Future<({List<VacancyModel> items, DocumentSnapshot<Map<String, dynamic>>? lastDoc})>
      getVacanciesPage({
    required String districtId,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  }) async {
    final query = _baseQuery(districtId);

    final snapshot = await _firestoreService.fetchPage(
      query: query,
      startAfter: startAfter,
      limit: _pageSize,
    );

    final items = snapshot.docs.map(VacancyModel.fromFirestore).toList();
    final lastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;

    return (items: items, lastDoc: lastDoc);
  }

  Future<VacancyModel?> getVacancyById(String id) async {
    final doc = await _firestoreService.collection(_collection).doc(id).get();
    if (!doc.exists) return null;
    return VacancyModel.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>);
  }
}
