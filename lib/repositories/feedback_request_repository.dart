import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/feedback_request_model.dart';
import '../services/firestore_service.dart';

/// Репозиторий обращений к супер-администратору. Отправка (submitRequest)
/// доступна без входа в приложение — разрешено правилами Firestore, по
/// аналогии с заявками на баннер/вакансию. В отличие от них также разрешён
/// точечный обратный readback (getById) и продолжение переписки
/// (sendMessage): автор обращения не аутентифицирован, поэтому единственный
/// способ показать ему ответ супер-админа и дать написать дальше — работать
/// по ID, который был сохранён на устройстве в момент отправки (см.
/// LocalStorageService.saveMyFeedbackRequest). Правила Firestore разрешают
/// `get` по известному ID всем, но `list` — только супер-админу; дописывать
/// сообщение в конец переписки (arrayUnion) может и не-админ, лишь бы это
/// было ровно одно новое сообщение от 'resident' (см. firestore.rules).
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
      'phone': phone,
      'district': districtId,
      'deviceId': deviceId,
      'status': 'pending',
      'messages': [
        FeedbackMessage(
          sender: 'resident',
          text: message,
          createdAt: DateTime.now(),
        ).toMap(),
      ],
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  Future<FeedbackRequestModel?> getById(String id) async {
    final doc = await _firestoreService.collection(_collection).doc(id).get();
    if (!doc.exists) return null;
    return FeedbackRequestModel.fromFirestore(doc);
  }

  /// Дописывает сообщение жителя в конец переписки. arrayUnion (а не
  /// перезапись всего массива) гарантирует на уровне самого Firestore, что
  /// прошлые сообщения — включая ответы админа — не могут быть подменены
  /// этим вызовом (см. правила update для feedback_requests): арифметика
  /// arrayUnion может только добавить новый элемент, не тронув старые.
  /// Статус возвращается в 'pending' — админ должен увидеть, что ветка снова
  /// ждёт ответа.
  Future<void> sendMessage({required String id, required String text}) async {
    await _firestoreService.collection(_collection).doc(id).update({
      'messages': FieldValue.arrayUnion([
        FeedbackMessage(
          sender: 'resident',
          text: text,
          createdAt: DateTime.now(),
        ).toMap(),
      ]),
      'status': 'pending',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
