import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';

/// Репозиторий заявок рекламодателей на размещение баннера в партнёрской
/// ленте. Отправка заявки (submitRequest) доступна БЕЗ входа в приложение —
/// разрешено правилами Firestore (allow create: с валидацией полей), по
/// аналогии с заявками жителей на объявления. Чтение и публикация заявки
/// (создание документа в sponsored_content) доступны только супер-админу
/// через отдельную веб-панель.
class BannerRequestRepository {
  static const String _collection = 'banner_requests';

  final FirestoreService _firestoreService;

  BannerRequestRepository({FirestoreService? firestoreService})
      : _firestoreService = firestoreService ?? FirestoreService();

  /// Отправляет заявку на модерацию и возвращает её ID — он показывается
  /// рекламодателю как номер, который нужно указать в комментарии к переводу.
  Future<String> submitRequest({
    required String title,
    required String imageUrl,
    required String targetUrl,
    required String phone,
    required int durationDays,
    required int price,
    required String districtId,
  }) async {
    final docRef = await _firestoreService.collection(_collection).add({
      'title': title,
      'imageUrl': imageUrl,
      'targetUrl': targetUrl,
      'phone': phone,
      'durationDays': durationDays,
      'price': price,
      'status': 'pending',
      'district': districtId,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }
}
