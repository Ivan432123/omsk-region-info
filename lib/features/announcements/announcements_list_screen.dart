import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/announcement_provider.dart';
import '../../providers/district_provider.dart';
import '../../widgets/announcements/announcement_card.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/loading_widget.dart';

class AnnouncementsListScreen extends ConsumerStatefulWidget {
  const AnnouncementsListScreen({super.key});

  @override
  ConsumerState<AnnouncementsListScreen> createState() => _AnnouncementsListScreenState();
}

class _AnnouncementsListScreenState extends ConsumerState<AnnouncementsListScreen> {
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
      ref.read(announcementListProvider(districtId).notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final district = ref.watch(selectedDistrictProvider);
    final districtId = district.id ?? '';
    final state = ref.watch(announcementListProvider(districtId));

    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(title: const Text('Объявления')),
      body: state.isLoading
          ? const LoadingListWidget()
          : state.error != null
              ? EmptyStateWidget.error(
                  onRetry: () =>
                      ref.read(announcementListProvider(districtId).notifier).refresh(),
                )
              : state.items.isEmpty
                  ? const EmptyStateWidget(
                      icon: Icons.campaign_outlined,
                      title: 'Пока нет объявлений',
                      subtitle: 'Загляните позже',
                    )
                  : RefreshIndicator(
                      color: AppTheme.primaryBlue,
                      onRefresh: () =>
                          ref.read(announcementListProvider(districtId).notifier).refresh(),
                      child: ListView.separated(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(20),
                        itemCount: state.items.length + (state.hasMore ? 1 : 0),
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          if (index >= state.items.length) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: CircularProgressIndicator(color: AppTheme.primaryBlue),
                              ),
                            );
                          }
                          final announcement = state.items[index];
                          return AnnouncementCard(
                            announcement: announcement,
                            onTap: () => context.push('/announcements/${announcement.id}'),
                          );
                        },
                      ),
                    ),
    );
  }
}
