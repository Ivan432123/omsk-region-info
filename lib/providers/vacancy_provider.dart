import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_constants.dart';
import '../models/vacancy_model.dart';
import '../repositories/vacancy_repository.dart';

final vacancyRepositoryProvider = Provider((ref) => VacancyRepository());

class VacancyListState {
  final List<VacancyModel> items;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;
  final DocumentSnapshot<Map<String, dynamic>>? lastDoc;

  const VacancyListState({
    this.items = const [],
    this.isLoading = true,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
    this.lastDoc,
  });

  VacancyListState copyWith({
    List<VacancyModel>? items,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
    DocumentSnapshot<Map<String, dynamic>>? lastDoc,
    bool clearError = false,
  }) {
    return VacancyListState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: clearError ? null : (error ?? this.error),
      lastDoc: lastDoc ?? this.lastDoc,
    );
  }
}

class VacancyListNotifier extends StateNotifier<VacancyListState> {
  final VacancyRepository _repository;
  final String districtId;

  VacancyListNotifier(this._repository, this.districtId)
      : super(const VacancyListState()) {
    loadFirstPage();
  }

  Future<void> loadFirstPage() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _repository.getVacanciesPage(districtId: districtId);
      state = state.copyWith(
        items: result.items,
        isLoading: false,
        hasMore: result.items.length == AppConstants.pageSize,
        lastDoc: result.lastDoc,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error:
            'Не удалось загрузить вакансии. Проверьте подключение к интернету.',
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.lastDoc == null) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final result = await _repository.getVacanciesPage(
        districtId: districtId,
        startAfter: state.lastDoc,
      );
      state = state.copyWith(
        items: [
          ...state.items,
          ...result.items.where(
              (v) => state.items.every((existing) => existing.id != v.id)),
        ],
        isLoadingMore: false,
        hasMore: result.items.length == AppConstants.pageSize,
        lastDoc: result.lastDoc ?? state.lastDoc,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  Future<void> refresh() => loadFirstPage();
}

/// autoDispose: экран вакансий — отдельный push-маршрут (не вкладка нижней
/// навигации), поэтому при каждом заходе в раздел справедливо ожидать
/// свежий список — без этого опубликованная вакансия не появлялась бы,
/// пока приложение не перезапустят (провайдер живёт в контейнере вечно и
/// просто отдаёт однажды загруженные данные снова).
final vacancyListProvider = StateNotifierProvider.autoDispose
    .family<VacancyListNotifier, VacancyListState, String>((ref, districtId) {
  return VacancyListNotifier(ref.watch(vacancyRepositoryProvider), districtId);
});

/// autoDispose: см. комментарий у newsDetailsProvider — та же причина.
final vacancyDetailsProvider = FutureProvider.autoDispose
    .family<VacancyModel?, String>((ref, vacancyId) async {
  final repo = ref.watch(vacancyRepositoryProvider);
  return repo.getVacancyById(vacancyId);
});
