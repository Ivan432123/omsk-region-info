import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_constants.dart';
import '../models/organization_model.dart';
import '../repositories/organization_repository.dart';

final organizationRepositoryProvider =
    Provider((ref) => OrganizationRepository());

class OrganizationListState {
  final List<OrganizationModel> items;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;
  final DocumentSnapshot<Map<String, dynamic>>? lastDoc;

  const OrganizationListState({
    this.items = const [],
    this.isLoading = true,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
    this.lastDoc,
  });

  OrganizationListState copyWith({
    List<OrganizationModel>? items,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
    DocumentSnapshot<Map<String, dynamic>>? lastDoc,
    bool clearError = false,
  }) {
    return OrganizationListState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: clearError ? null : (error ?? this.error),
      lastDoc: lastDoc ?? this.lastDoc,
    );
  }
}

class OrganizationListNotifier extends StateNotifier<OrganizationListState> {
  final OrganizationRepository _repository;
  final String districtId;

  OrganizationListNotifier(this._repository, this.districtId)
      : super(const OrganizationListState()) {
    loadFirstPage();
  }

  Future<void> loadFirstPage() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result =
          await _repository.getOrganizationsPage(districtId: districtId);
      state = state.copyWith(
        items: result.items,
        isLoading: false,
        hasMore: result.items.length == AppConstants.pageSize,
        lastDoc: result.lastDoc,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Не удалось загрузить организации. Попробуйте позже.',
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.lastDoc == null) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final result = await _repository.getOrganizationsPage(
        districtId: districtId,
        startAfter: state.lastDoc,
      );
      state = state.copyWith(
        items: [...state.items, ...result.items],
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

final organizationListProvider = StateNotifierProvider.family<
    OrganizationListNotifier, OrganizationListState, String>((ref, districtId) {
  return OrganizationListNotifier(
      ref.watch(organizationRepositoryProvider), districtId);
});

final organizationDetailsProvider =
    FutureProvider.family<OrganizationModel?, String>((ref, id) async {
  final repo = ref.watch(organizationRepositoryProvider);
  return repo.getOrganizationById(id);
});
