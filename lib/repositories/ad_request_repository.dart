import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';

/// Репозиторий заявок на объявления от жителей.
/// Отправка заявки (submitRequest) доступна БЕЗ входа в приложение —
/// это специально разрешено правилами Firestore (allow create: if true),
/// чтобы любой житель мог подать объявление без регистрации. Чтение и
/// изменение статуса заявок доступно только администратору через
/// отдельную веб-панель (там уже есть вход через Firebase Auth).
class AdRequestRepository {
  static const String _collection = 'ad_requests';

  final FirestoreService _firestoreService;

  AdRequestRepository({FirestoreService? firestoreService})
      : _firestoreService = firestoreService ?? FirestoreService();

  /// Отправляет заявку на модерацию и возвращает её ID — он показывается
  /// жителю как номер, который нужно указать в комментарии к переводу.
  Future<String> submitRequest({
    required String title,
    required String description,
    required String phone,
    required bool wantsPush,
    required String districtId,
    List<String> images = const [],
  }) async {
    final docRef = await _firestoreService.collection(_collection).add({
      'title': title,
      'description': description,
      'phone': phone,
      'wantsPush': wantsPush,
      'status': 'pending',
      'district': districtId,
      'images': images,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }
}
