import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/district_provider.dart';
import '../../providers/news_provider.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/news/news_card.dart';

class NewsListScreen extends ConsumerStatefulWidget {
  const NewsListScreen({super.key});

  @override
  ConsumerState<NewsListScreen> createState() => _NewsListScreenState();
}

class _NewsListScreenState extends ConsumerState<NewsListScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final districtId = ref.read(selectedDistrictProvider).id ?? '';
      ref.read(newsListProvider(districtId).notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final districtId = ref.watch(selectedDistrictProvider).id ?? '';
    final newsState = ref.watch(newsListProvider(districtId));

    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(title: const Text('Новости')),
      body: Builder(
        builder: (context) {
          if (newsState.isLoading) return const LoadingListWidget();
          if (newsState.error != null) {
            return EmptyStateWidget.error(
              onRetry: () => ref.read(newsListProvider(districtId).notifier).refresh(),
            );
          }
          if (newsState.items.isEmpty) return const EmptyStateWidget.noNews();

          return RefreshIndicator(
            color: AppTheme.primaryBlue,
            onRefresh: () => ref.read(newsListProvider(districtId).notifier).refresh(),
            child: ListView.separated(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: newsState.items.length + (newsState.hasMore ? 1 : 0),
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index >= newsState.items.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                    ),
                  );
                }
                final news = newsState.items[index];
                return NewsCard(
                  news: news,
                  onTap: () => context.push('/news/${news.id}'),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
