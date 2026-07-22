import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';

/// Репозиторий заявок работодателей на публикацию вакансии. Отправка заявки
/// (submitRequest) доступна БЕЗ входа в приложение — разрешено правилами
/// Firestore (allow create: с валидацией полей), по аналогии с заявками на
/// баннер. Чтение и публикация заявки (создание документа в vacancies)
/// доступны только супер-админу через отдельную веб-панель.
class VacancyRequestRepository {
  static const String _collection = 'vacancy_requests';

  final FirestoreService _firestoreService;

  VacancyRequestRepository({FirestoreService? firestoreService})
      : _firestoreService = firestoreService ?? FirestoreService();

  /// Отправляет заявку на модерацию и возвращает её ID — он показывается
  /// работодателю как номер, который нужно указать в комментарии к переводу.
  Future<String> submitRequest({
    required String title,
    required String company,
    required String description,
    String? salary,
    required String phone,
    required int price,
    required String districtId,
  }) async {
    final docRef = await _firestoreService.collection(_collection).add({
      'title': title,
      'company': company,
      'description': description,
      'salary': salary,
      'phone': phone,
      'price': price,
      'status': 'pending',
      'district': districtId,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }
}
