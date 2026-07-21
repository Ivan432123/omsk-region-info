import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_formatter.dart';
import '../../providers/news_provider.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/category_chip.dart';
import '../../widgets/common/fullscreen_gallery_viewer.dart';

String _formatViewCount(int count) {
  if (count >= 1000) {
    final thousands = count / 1000;
    return '${thousands.toStringAsFixed(thousands >= 10 ? 0 : 1)}K';
  }
  return '$count';
}

class NewsDetailsScreen extends ConsumerWidget {
  final String newsId;

  const NewsDetailsScreen({super.key, required this.newsId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newsAsync = ref.watch(newsDetailsProvider(newsId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Новость'),
        actions: [
          if (newsAsync.value != null)
            IconButton(
              icon: const Icon(Icons.share_outlined),
              onPressed: () {
                final news = newsAsync.value!;
                Share.share(
                  '${news.title}\n\n${news.description}',
                  subject: news.title,
                );
              },
            ),
        ],
      ),
      body: newsAsync.when(
        loading: () => const LoadingIndicatorWidget(),
        error: (_, __) => EmptyStateWidget.error(
          onRetry: () => ref.invalidate(newsDetailsProvider(newsId)),
        ),
        data: (news) {
          if (news == null) {
            return const EmptyStateWidget(
              icon: Icons.article_outlined,
              title: 'Новость не найдена',
              subtitle: 'Возможно, она была удалена',
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CategoryChip(category: news.category),
                const SizedBox(height: 12),
                Text(
                  news.title,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 14,
                      color: AppTheme.textSecondary(context),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      DateFormatter.formatDateTime(news.createdAt),
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary(context),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Icon(
                      Icons.visibility_outlined,
                      size: 14,
                      color: AppTheme.textSecondary(context),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${_formatViewCount(news.viewCount)} просмотров',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary(context),
                      ),
                    ),
                  ],
                ),
                if (news.imageUrl != null) ...[
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () =>
                        FullscreenGalleryViewer.open(context, [news.imageUrl!]),
                    child: Hero(
                      // news_${id}, а не FullscreenGalleryViewer.heroTag —
                      // этот Hero сначала обслуживает перелёт картинки из
                      // карточки списка (см. NewsCard.heroTag), у новости
                      // всегда ровно одно фото, поэтому отдельная анимация
                      // "вырастания" при открытии полноэкранной галереи
                      // здесь не так важна, как анимация список → детали.
                      tag: 'news_${news.id}',
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: AspectRatio(
                          aspectRatio: 16 / 10,
                          child: CachedNetworkImage(
                            imageUrl: news.imageUrl!,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                                color: AppTheme.surfaceVariant(context)),
                            errorWidget: (_, __, ___) => Container(
                                color: AppTheme.surfaceVariant(context)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Text(
                  news.content.isNotEmpty ? news.content : news.description,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
