import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/district_provider.dart';
import '../../providers/news_provider.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/news/news_card.dart';

const Map<String?, String> _kCategoryLabels = {
  null: 'Все',
  'general': 'Общее',
  'water': 'Водоснабжение',
  'gas': 'Газоснабжение',
  'electricity': 'Электроснабжение',
  'road': 'Дороги',
  'emergency': 'Экстренное',
  'events': 'Мероприятия',
};

class NewsListScreen extends ConsumerStatefulWidget {
  const NewsListScreen({super.key});

  @override
  ConsumerState<NewsListScreen> createState() => _NewsListScreenState();
}

class _NewsListScreenState extends ConsumerState<NewsListScreen> {
  final ScrollController _scrollController = ScrollController();
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final districtId = ref.read(selectedDistrictProvider).id ?? '';
      ref
          .read(newsListByCategoryProvider(
            (districtId: districtId, category: _selectedCategory),
          ).notifier)
          .loadMore();
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
    final newsState = ref.watch(
      newsListByCategoryProvider(
          (districtId: districtId, category: _selectedCategory)),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Новости'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_rounded),
            tooltip: 'Мои закладки',
            onPressed: () => context.push('/bookmarks/news'),
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _kCategoryLabels.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final category = _kCategoryLabels.keys.elementAt(index);
                final label = _kCategoryLabels[category]!;
                final isSelected = _selectedCategory == category;
                return ChoiceChip(
                  label: Text(label),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() => _selectedCategory = category);
                  },
                  selectedColor: AppTheme.primaryBlue,
                  labelStyle: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : AppTheme.textPrimary(context),
                    fontWeight: FontWeight.w600,
                  ),
                  backgroundColor: AppTheme.surface(context),
                  side: BorderSide(
                    color: isSelected
                        ? AppTheme.primaryBlue
                        : AppTheme.divider(context),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Builder(
              builder: (context) {
                if (newsState.isLoading) return const LoadingListWidget();
                if (newsState.error != null) {
                  return EmptyStateWidget.error(
                    onRetry: () => ref
                        .read(newsListByCategoryProvider(
                          (districtId: districtId, category: _selectedCategory),
                        ).notifier)
                        .refresh(),
                  );
                }
                if (newsState.items.isEmpty) {
                  return const EmptyStateWidget.noNews();
                }

                return RefreshIndicator(
                  color: AppTheme.primaryBlueText(context),
                  onRefresh: () => ref
                      .read(newsListByCategoryProvider(
                        (districtId: districtId, category: _selectedCategory),
                      ).notifier)
                      .refresh(),
                  child: ListView.separated(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount:
                        newsState.items.length + (newsState.hasMore ? 1 : 0),
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      if (index >= newsState.items.length) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: AppTheme.primaryBlueText(context),
                              ),
                            ),
                          ),
                        );
                      }
                      final news = newsState.items[index];
                      return NewsCard(
                        key: ValueKey(news.id),
                        news: news,
                        heroTag: 'news_${news.id}',
                        onTap: () => context.push('/news/${news.id}'),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
