import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/announcement_provider.dart';
import '../../widgets/announcements/announcement_card.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/loading_widget.dart';

class BookmarkedAnnouncementsScreen extends ConsumerWidget {
  const BookmarkedAnnouncementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarksAsync = ref.watch(bookmarkedAnnouncementsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Мои закладки')),
      body: bookmarksAsync.when(
        loading: () => const LoadingListWidget(),
        error: (_, __) => EmptyStateWidget.error(
          onRetry: () => ref.invalidate(bookmarkedAnnouncementsProvider),
        ),
        data: (announcements) => announcements.isEmpty
            ? const EmptyStateWidget(
                icon: Icons.bookmark_border_rounded,
                title: 'Пока нет закладок',
                subtitle:
                    'Нажмите на значок закладки на странице объявления, чтобы быстро находить его здесь',
              )
            : RefreshIndicator(
                color: AppTheme.primaryBlue,
                onRefresh: () async =>
                    ref.invalidate(bookmarkedAnnouncementsProvider),
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: announcements.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = announcements[index];
                    return AnnouncementCard(
                      key: ValueKey(item.id),
                      announcement: item,
                      onTap: () => context.push('/announcements/${item.id}'),
                    );
                  },
                ),
              ),
      ),
    );
  }
}
