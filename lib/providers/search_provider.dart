import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/search_repository.dart';

final searchRepositoryProvider = Provider((ref) => SearchRepository());

/// Контент района для поиска — кэшируется по districtId, не по запросу:
/// набор из 5 полных .get() выполняется один раз за визит на экран поиска
/// (или при смене района), а не на каждый введённый символ. autoDispose:
/// экран поиска — push-маршрут, открывается заново при каждом заходе.
final _searchableDistrictContentProvider = FutureProvider.autoDispose
    .family<SearchableDistrictContent, String>((ref, districtId) async {
  final repo = ref.watch(searchRepositoryProvider);
  return repo.fetchDistrictContent(districtId);
});

/// autoDispose: экран поиска — push-маршрут, открывается заново при каждом
/// заходе; результаты не должны переживать закрытие экрана. Фильтрация по
/// запросу синхронна и не обращается к Firestore — см.
/// _searchableDistrictContentProvider выше.
final searchResultsProvider = FutureProvider.autoDispose
    .family<SearchResults, ({String districtId, String query})>(
        (ref, params) async {
  final repo = ref.watch(searchRepositoryProvider);
  final content = await ref
      .watch(_searchableDistrictContentProvider(params.districtId).future);
  return repo.filter(content, params.query);
});
