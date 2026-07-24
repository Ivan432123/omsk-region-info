import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/news_provider.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/news/news_card.dart';

class BookmarkedNewsScreen extends ConsumerWidget {
  const BookmarkedNewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarksAsync = ref.watch(bookmarkedNewsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Мои закладки')),
      body: bookmarksAsync.when(
        loading: () => const LoadingListWidget(),
        error: (_, __) => EmptyStateWidget.error(
          onRetry: () => ref.invalidate(bookmarkedNewsProvider),
        ),
        data: (news) => news.isEmpty
            ? const EmptyStateWidget(
                icon: Icons.bookmark_border_rounded,
                title: 'Пока нет закладок',
                subtitle:
                    'Нажмите на значок закладки на странице новости, чтобы быстро находить её здесь',
              )
            : RefreshIndicator(
                color: AppTheme.primaryBlueText(context),
                onRefresh: () async => ref.invalidate(bookmarkedNewsProvider),
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: news.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = news[index];
                    return NewsCard(
                      key: ValueKey(item.id),
                      news: item,
                      heroTag: 'news_${item.id}',
                      onTap: () => context.push('/news/${item.id}'),
                    );
                  },
                ),
              ),
      ),
    );
  }
}
