import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/search_repository.dart';

final searchRepositoryProvider = Provider((ref) => SearchRepository());

final searchResultsProvider =
    FutureProvider.family<SearchResults, ({String districtId, String query})>(
        (ref, params) async {
  final repo = ref.watch(searchRepositoryProvider);
  return repo.search(params.districtId, params.query);
});
