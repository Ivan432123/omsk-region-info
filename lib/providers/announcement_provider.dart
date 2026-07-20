import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/announcement_model.dart';
import '../repositories/announcement_repository.dart';

final announcementRepositoryProvider = Provider((ref) => AnnouncementRepository());

class AnnouncementListState {
  final List<AnnouncementModel> items;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;
  final DocumentSnapshot<Map<String, dynamic>>? lastDoc;

  const AnnouncementListState({
    this.items = const [],
    this.isLoading = true,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
    this.lastDoc,
  });

  AnnouncementListState copyWith({
    List<AnnouncementModel>? items,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
    DocumentSnapshot<Map<String, dynamic>>? lastDoc,
    bool clearError = false,
  }) {
    return AnnouncementListState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: clearError ? null : (error ?? this.error),
      lastDoc: lastDoc ?? this.lastDoc,
    );
  }
}

class AnnouncementListNotifier extends StateNotifier<AnnouncementListState> {
  final AnnouncementRepository _repository;
  final String districtId;

  AnnouncementListNotifier(this._repository, this.districtId)
      : super(const AnnouncementListState()) {
    loadFirstPage();
  }

  Future<void> loadFirstPage() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _repository.getAnnouncementsPage(districtId: districtId);
      state = state.copyWith(
        items: result.items,
        isLoading: false,
        hasMore: result.items.length == 15,
        lastDoc: result.lastDoc,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Не удалось загрузить объявления. Проверьте подключение к интернету.',
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.lastDoc == null) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final result = await _repository.getAnnouncementsPage(
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

final announcementListProvider = StateNotifierProvider.family<AnnouncementListNotifier,
    AnnouncementListState, String>((ref, districtId) {
  return AnnouncementListNotifier(ref.watch(announcementRepositoryProvider), districtId);
});

final announcementDetailsProvider =
    FutureProvider.family<AnnouncementModel?, String>((ref, announcementId) async {
  final repo = ref.watch(announcementRepositoryProvider);
  return repo.getAnnouncementById(announcementId);
});

/// Продвигаемые (оплаченные) объявления района — для блока на главном
/// экране.
final promotedAnnouncementsProvider =
    FutureProvider.family<List<AnnouncementModel>, String>((ref, districtId) async {
  if (districtId.isEmpty) return [];
  final repo = ref.watch(announcementRepositoryProvider);
  return repo.getPromotedAnnouncements(districtId);
});
