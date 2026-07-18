import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/event_model.dart';
import '../repositories/event_repository.dart';

final eventRepositoryProvider = Provider((ref) => EventRepository());

class EventListState {
  final List<EventModel> items;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;
  final DocumentSnapshot<Map<String, dynamic>>? lastDoc;

  const EventListState({
    this.items = const [],
    this.isLoading = true,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
    this.lastDoc,
  });

  EventListState copyWith({
    List<EventModel>? items,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
    DocumentSnapshot<Map<String, dynamic>>? lastDoc,
    bool clearError = false,
  }) {
    return EventListState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: clearError ? null : (error ?? this.error),
      lastDoc: lastDoc ?? this.lastDoc,
    );
  }
}

class EventListNotifier extends StateNotifier<EventListState> {
  final EventRepository _repository;
  final String districtId;

  EventListNotifier(this._repository, this.districtId) : super(const EventListState()) {
    loadFirstPage();
  }

  Future<void> loadFirstPage() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _repository.getEventsPage(districtId: districtId);
      state = state.copyWith(
        items: result.items,
        isLoading: false,
        hasMore: result.items.length == 15,
        lastDoc: result.lastDoc,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Не удалось загрузить афишу. Проверьте подключение к интернету.',
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.lastDoc == null) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final result = await _repository.getEventsPage(
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

final eventListProvider =
    StateNotifierProvider.family<EventListNotifier, EventListState, String>((ref, districtId) {
  return EventListNotifier(ref.watch(eventRepositoryProvider), districtId);
});

final eventDetailsProvider =
    FutureProvider.family<EventModel?, String>((ref, eventId) async {
  final repo = ref.watch(eventRepositoryProvider);
  return repo.getEventById(eventId);
});
