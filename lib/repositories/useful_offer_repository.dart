import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/useful_offer_model.dart';
import '../services/firestore_service.dart';

/// Раздел "Полезное" общеплатформенный (без district) — один запрос без
/// фильтрации по региону, в отличие от большинства других репозиториев в
/// проекте.
class UsefulOfferRepository {
  static const String _collection = 'useful_offers';

  final FirestoreService _firestoreService;

  UsefulOfferRepository({FirestoreService? firestoreService})
      : _firestoreService = firestoreService ?? FirestoreService();

  Future<List<UsefulOfferModel>> getOffers() async {
    final snapshot = await _firestoreService
        .collection(_collection)
        .orderBy('order')
        .get();
    return snapshot.docs.map(UsefulOfferModel.fromFirestore).toList();
  }

  /// Инкремент кликов по офферу — та же схема, что и у
  /// SponsoredContentRepository.recordClick: показывается в супер-админке
  /// рядом с самим оффером, единственная метрика популярности без
  /// полноценной аналитики.
  Future<void> recordClick(String id) {
    return _firestoreService.collection(_collection).doc(id).update({
      'clickCount': FieldValue.increment(1),
    });
  }
}
