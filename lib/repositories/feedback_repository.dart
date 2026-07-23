import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';
import '../models/feedback_model.dart';
import '../services/firestore_service.dart';

/// Репозиторий обращений в поддержку. Отправка (submitFeedback) доступна
/// БЕЗ входа в приложение — разрешено правилами Firestore (allow create с
/// валидацией полей), по аналогии с ad_requests/vacancy_requests. Читает
/// произвольное обращение по id кто угодно (allow get: if true — id это
/// непредсказуемый Firestore push-id, известный только автору обращения и
/// супер-админу), а вот allow list ограничен супер-админом — иначе можно
/// было бы перебором прочитать чужие обращения.
class FeedbackRepository {
  static const String _collection = AppConstants.collectionFeedback;

  final FirestoreService _firestoreService;

  FeedbackRepository({FirestoreService? firestoreService})
      : _firestoreService = firestoreService ?? FirestoreService();

  Future<String> submitFeedback({
    required String message,
    String? contact,
    required String districtId,
    required String districtName,
  }) async {
    final docRef = await _firestoreService.collection(_collection).add({
      'message': message,
      'contact': contact,
      'district': districtId,
      'districtName': districtName,
      'status': 'new',
      'createdAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  Future<FeedbackModel?> getFeedbackById(String id) async {
    final doc = await _firestoreService.collection(_collection).doc(id).get();
    if (!doc.exists) return null;
    return FeedbackModel.fromFirestore(doc);
  }
}
