import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/feedback_request_model.dart';
import '../services/firestore_service.dart';

/// Репозиторий обращений к супер-администратору. Отправка (submitRequest)
/// доступна без входа в приложение — разрешено правилами Firestore, по
/// аналогии с заявками на баннер/вакансию. В отличие от них также разрешён
/// точечный обратный readback (getById): автор обращения не аутентифицирован,
/// поэтому единственный способ показать ему ответ супер-админа — прочитать
/// документ по ID, который был сохранён на устройстве в момент отправки (см.
/// LocalStorageService.saveMyFeedbackRequest). Правила Firestore разрешают
/// `get` по известному ID всем, но `list` — только супер-админу.
class FeedbackRequestRepository {
  static const String _collection = 'feedback_requests';

  final FirestoreService _firestoreService;

  FeedbackRequestRepository({FirestoreService? firestoreService})
      : _firestoreService = firestoreService ?? FirestoreService();

  Future<String> submitRequest({
    required String message,
    String? phone,
    required String districtId,
    required String deviceId,
  }) async {
    final docRef = await _firestoreService.collection(_collection).add({
      'message': message,
      'phone': phone,
      'district': districtId,
      'deviceId': deviceId,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  Future<FeedbackRequestModel?> getById(String id) async {
    final doc = await _firestoreService.collection(_collection).doc(id).get();
    if (!doc.exists) return null;
    return FeedbackRequestModel.fromFirestore(doc);
  }
}
