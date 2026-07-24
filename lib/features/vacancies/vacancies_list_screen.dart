import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/district_provider.dart';
import '../../providers/feature_flags_provider.dart';
import '../../providers/vacancy_provider.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/vacancies/vacancy_card.dart';

class VacanciesListScreen extends ConsumerStatefulWidget {
  const VacanciesListScreen({super.key});

  @override
  ConsumerState<VacanciesListScreen> createState() =>
      _VacanciesListScreenState();
}

class _VacanciesListScreenState extends ConsumerState<VacanciesListScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final districtId = ref.read(selectedDistrictProvider).id ?? '';
      ref.read(vacancyListProvider(districtId).notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final district = ref.watch(selectedDistrictProvider);
    final districtId = district.id ?? '';
    final state = ref.watch(vacancyListProvider(districtId));
    final vacancySubmissionEnabled =
        ref.watch(featureFlagsProvider).valueOrNull?.vacancySubmissionEnabled ??
            false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Вакансии'),
        actions: [
          if (vacancySubmissionEnabled)
            TextButton(
              onPressed: () => context.push('/post-vacancy'),
              child: const Text('Разместить →'),
            ),
        ],
      ),
      body: state.isLoading
          ? const LoadingListWidget()
          : state.error != null
              ? EmptyStateWidget.error(
                  onRetry: () => ref
                      .read(vacancyListProvider(districtId).notifier)
                      .refresh(),
                )
              : state.items.isEmpty
                  ? const EmptyStateWidget(
                      icon: Icons.work_outline_rounded,
                      title: 'Пока нет вакансий',
                      subtitle: 'Загляните позже',
                    )
                  : RefreshIndicator(
                      color: AppTheme.primaryBlueText(context),
                      onRefresh: () => ref
                          .read(vacancyListProvider(districtId).notifier)
                          .refresh(),
                      child: ListView.separated(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(20),
                        itemCount: state.items.length + (state.hasMore ? 1 : 0),
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          if (index >= state.items.length) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: CircularProgressIndicator(
                                    color: AppTheme.primaryBlueText(context)),
                              ),
                            );
                          }
                          final vacancy = state.items[index];
                          return VacancyCard(
                            key: ValueKey(vacancy.id),
                            vacancy: vacancy,
                            onTap: () =>
                                context.push('/vacancies/${vacancy.id}'),
                          );
                        },
                      ),
                    ),
    );
  }
}
