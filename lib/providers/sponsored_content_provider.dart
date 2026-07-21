import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/sponsored_content_model.dart';
import '../repositories/sponsored_content_repository.dart';

final sponsoredContentRepositoryProvider =
    Provider((ref) => SponsoredContentRepository());

/// Активные партнёрские баннеры района — для карусели на главном экране.
final sponsoredContentProvider =
    FutureProvider.family<List<SponsoredContentModel>, String>(
        (ref, districtId) async {
  if (districtId.isEmpty) return [];
  final repo = ref.watch(sponsoredContentRepositoryProvider);
  return repo.getActiveSponsoredContent(districtId);
});

/// Фиксирует переход по рекламному баннеру. Ошибки намеренно проглатываются
/// — не должны мешать пользователю открыть ссылку партнёра.
Future<void> recordSponsoredClick(WidgetRef ref, String id) async {
  try {
    await ref.read(sponsoredContentRepositoryProvider).recordClick(id);
  } catch (_) {}
}
