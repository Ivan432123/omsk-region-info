import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/news_model.dart';
import '../repositories/news_repository.dart';

final newsRepositoryProvider = Provider((ref) => NewsRepository());

class NewsListState {
  final List<NewsModel> items;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;
  final DocumentSnapshot<Map<String, dynamic>>? lastDoc;

  const NewsListState({
    this.items = const [],
    this.isLoading = true,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
    this.lastDoc,
  });

  NewsListState copyWith({
    List<NewsModel>? items,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
    DocumentSnapshot<Map<String, dynamic>>? lastDoc,
    bool clearError = false,
  }) {
    return NewsListState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: clearError ? null : (error ?? this.error),
      lastDoc: lastDoc ?? this.lastDoc,
    );
  }
}

/// Управляет пагинацией новостей для конкретного района.
/// Используется family, чтобы у каждого района был независимый экземпляр
/// состояния — важно для будущего мульти-районного сравнения (admin).
class NewsListNotifier extends StateNotifier<NewsListState> {
  final NewsRepository _repository;
  final String districtId;

  NewsListNotifier(this._repository, this.districtId) : super(const NewsListState()) {
    loadFirstPage();
  }

  Future<void> loadFirstPage() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _repository.getNewsPage(districtId: districtId);
      state = state.copyWith(
        items: result.items,
        isLoading: false,
        hasMore: result.items.length == 15,
        lastDoc: result.lastDoc,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Не удалось загрузить новости. Проверьте подключение к интернету.',
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.lastDoc == null) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final result = await _repository.getNewsPage(
        districtId: districtId,
        startAfter: state.lastDoc,
      );
      state = state.copyWith(
        items: [...state.items, ...result.items],
        isLoadingMore: false,
        hasMore: result.items.length == 15,
        lastDoc: result.lastDoc ?? state.lastDoc,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  Future<void> refresh() => loadFirstPage();
}

final newsListProvider =
    StateNotifierProvider.family<NewsListNotifier, NewsListState, String>((ref, districtId) {
  return NewsListNotifier(ref.watch(newsRepositoryProvider), districtId);
});

/// Важные объявления для главной (только push-триггерящие категории).
final importantAnnouncementsProvider =
    FutureProvider.family<List<NewsModel>, String>((ref, districtId) async {
  final repo = ref.watch(newsRepositoryProvider);
  return repo.getImportantAnnouncements(districtId);
});

final newsDetailsProvider =
    FutureProvider.family<NewsModel?, String>((ref, newsId) async {
  final repo = ref.watch(newsRepositoryProvider);
  return repo.getNewsById(newsId);
});
