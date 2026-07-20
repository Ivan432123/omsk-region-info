import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';
import '../models/news_model.dart';
import '../services/firestore_service.dart';

class NewsRepository {
  final FirestoreService _firestoreService;

  NewsRepository({FirestoreService? firestoreService})
      : _firestoreService = firestoreService ?? FirestoreService();

  Query<Map<String, dynamic>> _baseQuery(String districtId) {
    return _firestoreService
        .collection(AppConstants.collectionNews)
        .where('district', isEqualTo: districtId)
        .orderBy('createdAt', descending: true);
  }

  Future<
      ({
        List<NewsModel> items,
        DocumentSnapshot<Map<String, dynamic>>? lastDoc
      })> getNewsPage({
    required String districtId,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
    String? categoryFilter,
  }) async {
    var query = _baseQuery(districtId);
    if (categoryFilter != null) {
      query = query.where('category', isEqualTo: categoryFilter);
    }

    final snapshot = await _firestoreService.fetchPage(
      query: query,
      startAfter: startAfter,
      limit: AppConstants.pageSize,
    );

    final items = snapshot.docs.map(NewsModel.fromFirestore).toList();
    final lastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;

    return (items: items, lastDoc: lastDoc);
  }

  Future<List<NewsModel>> getImportantAnnouncements(String districtId) async {
    final snapshot = await _firestoreService
        .collection(AppConstants.collectionNews)
        .where('district', isEqualTo: districtId)
        .where('category', whereIn: AppConstants.pushTriggeringCategories)
        .orderBy('createdAt', descending: true)
        .limit(5)
        .get();

    return snapshot.docs.map(NewsModel.fromFirestore).toList();
  }

  Future<NewsModel?> getNewsById(String id) async {
    final docRef =
        _firestoreService.collection(AppConstants.collectionNews).doc(id);

    // Увеличиваем счётчик просмотров при каждом открытии новости.
    // Делаем это "не дожидаясь" (fire-and-forget) и гасим возможную ошибку,
    // чтобы сбой инкремента просмотров никогда не мешал показу самой новости.
    docRef.update({'viewCount': FieldValue.increment(1)}).catchError((_) {});

    final doc = await docRef.get();

    if (!doc.exists) return null;
    return NewsModel.fromFirestore(doc);
  }
}
