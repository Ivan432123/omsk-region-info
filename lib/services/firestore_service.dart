import 'package:cloud_firestore/cloud_firestore.dart';

/// Тонкая обёртка над Firestore, инкапсулирующая построение пагинированных
/// запросов. Репозитории используют её вместо прямого обращения к
/// FirebaseFirestore.instance — это соответствует Repository Pattern и
/// упрощает подмену источника данных в тестах.
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  FirebaseFirestore get instance => _db;

  CollectionReference<Map<String, dynamic>> collection(String path) =>
      _db.collection(path);

  /// Возвращает страницу документов, отсортированных по [orderByField]
  /// (по убыванию), с опциональным курсором [startAfter] для пагинации.
  Future<QuerySnapshot<Map<String, dynamic>>> fetchPage({
    required Query<Map<String, dynamic>> query,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
    int limit = 15,
  }) async {
    var q = query.limit(limit);
    if (startAfter != null) {
      q = q.startAfterDocument(startAfter);
    }
    return q.get();
  }
}
