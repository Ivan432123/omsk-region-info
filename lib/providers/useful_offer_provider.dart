import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/useful_offer_model.dart';
import '../repositories/useful_offer_repository.dart';

final usefulOfferRepositoryProvider =
    Provider((ref) => UsefulOfferRepository());

/// autoDispose: экран "Полезное" — push-маршрут, открывается заново при
/// каждом заходе (см. TASKS.md, партия 3.14, тот же приём, что у вакансий/
/// афиши/автобусов) — свежие данные должны подгружаться каждый раз.
final usefulOffersProvider =
    FutureProvider.autoDispose<List<UsefulOfferModel>>((ref) async {
  final repo = ref.watch(usefulOfferRepositoryProvider);
  return repo.getOffers();
});

/// Фиксирует переход по офферу. Ошибки намеренно проглатываются — не
/// должны мешать пользователю открыть партнёрскую ссылку (тот же приём,
/// что и у recordSponsoredClick в sponsored_content_provider.dart).
Future<void> recordUsefulOfferClick(WidgetRef ref, String id) async {
  try {
    await ref.read(usefulOfferRepositoryProvider).recordClick(id);
  } catch (_) {}
}
