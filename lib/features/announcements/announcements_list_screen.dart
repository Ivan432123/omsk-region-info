import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/announcement_provider.dart';
import '../../providers/district_provider.dart';
import '../../services/local_storage_service.dart';
import '../../widgets/announcements/announcement_card.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/loading_widget.dart';

class AnnouncementsListScreen extends ConsumerStatefulWidget {
  const AnnouncementsListScreen({super.key});

  @override
  ConsumerState<AnnouncementsListScreen> createState() =>
      _AnnouncementsListScreenState();
}

class _AnnouncementsListScreenState
    extends ConsumerState<AnnouncementsListScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _markAsSeen());
  }

  Future<void> _markAsSeen() async {
    final districtId = ref.read(selectedDistrictProvider).id ?? '';
    if (districtId.isEmpty) return;
    await LocalStorageService().markAnnouncementsSeen(districtId);
    ref.invalidate(unreadAnnouncementsCountProvider(districtId));
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
      appBar: AppBar(
        title: const Text('Объявления'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_rounded),
            tooltip: 'Мои закладки',
            onPressed: () => context.push('/bookmarks/announcements'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/post-announcement'),
        backgroundColor: AppTheme.primaryBlue,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: state.isLoading
          ? const LoadingListWidget()
          : state.error != null
              ? EmptyStateWidget.error(
                  onRetry: () => ref
                      .read(announcementListProvider(districtId).notifier)
                      .refresh(),
                )
              : state.items.isEmpty
                  ? const EmptyStateWidget(
                      icon: Icons.campaign_outlined,
                      title: 'Пока нет объявлений',
                      subtitle: 'Загляните позже',
                    )
                  : RefreshIndicator(
                      color: AppTheme.primaryBlue,
                      onRefresh: () => ref
                          .read(announcementListProvider(districtId).notifier)
                          .refresh(),
                      child: _buildList(context, state),
                    ),
    );
  }

  Widget _buildList(BuildContext context, AnnouncementListState state) {
    final promoted = state.items.where((a) => a.isPromoted).toList();
    final regular = state.items.where((a) => !a.isPromoted).toList();

    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 90),
      children: [
        if (promoted.isNotEmpty) ...[
          const Row(
            children: [
              Icon(Icons.local_fire_department_rounded,
                  color: Color(0xFFE67E22), size: 20),
              SizedBox(width: 6),
              Text(
                'Продвигаемые объявления',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...promoted.map(
            (announcement) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border:
                      Border.all(color: const Color(0xFFE67E22), width: 1.5),
                ),
                child: AnnouncementCard(
                  announcement: announcement,
                  onTap: () =>
                      context.push('/announcements/${announcement.id}'),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Все объявления',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          const SizedBox(height: 12),
        ],
        ...regular.map(
          (announcement) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AnnouncementCard(
              announcement: announcement,
              onTap: () => context.push('/announcements/${announcement.id}'),
            ),
          ),
        ),
        if (state.hasMore)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: CircularProgressIndicator(color: AppTheme.primaryBlue),
            ),
          ),
      ],
    );
  }
}
