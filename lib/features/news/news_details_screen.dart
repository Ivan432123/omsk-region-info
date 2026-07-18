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
      backgroundColor: AppTheme.backgroundWhite,
      body: newsAsync.when(
        loading: () => const LoadingIndicatorWidget(),
        error: (_, __) => Scaffold(
          appBar: AppBar(),
          body: EmptyStateWidget.error(
            onRetry: () => ref.invalidate(newsDetailsProvider(newsId)),
          ),
        ),
        data: (news) {
          if (news == null) {
            return Scaffold(
              appBar: AppBar(),
              body: const EmptyStateWidget(
                icon: Icons.article_outlined,
                title: 'Новость не найдена',
                subtitle: 'Возможно, она была удалена',
              ),
            );
          }

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: news.imageUrl != null ? 260 : 0,
                backgroundColor: AppTheme.backgroundWhite,
                foregroundColor: AppTheme.textPrimary,
                surfaceTintColor: Colors.transparent,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.share_outlined),
                    onPressed: () => Share.share(
                      '${news.title}\n\n${news.description}',
                      subject: news.title,
                    ),
                  ),
                ],
                flexibleSpace: news.imageUrl != null
                    ? FlexibleSpaceBar(
                        background: GestureDetector(
                          onTap: () =>
                              _openFullScreenImage(context, news.imageUrl!),
                          child: Container(
                            color: AppTheme.surfaceGrey,
                            child: Hero(
                              tag: news.imageUrl!,
                              child: CachedNetworkImage(
                                imageUrl: news.imageUrl!,
                                fit: BoxFit.cover,
                                alignment: Alignment.topCenter,
                                placeholder: (_, __) =>
                                    Container(color: AppTheme.surfaceGrey),
                                errorWidget: (_, __, ___) =>
                                    Container(color: AppTheme.surfaceGrey),
                              ),
                            ),
                          ),
                        ),
                      )
                    : null,
              ),
              SliverToBoxAdapter(
                child: Padding(
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
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 14,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            DateFormatter.formatDateTime(news.createdAt),
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Icon(
                            Icons.visibility_outlined,
                            size: 14,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${_formatViewCount(news.viewCount)} просмотров',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        news.content.isNotEmpty
                            ? news.content
                            : news.description,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _openFullScreenImage(BuildContext context, String imageUrl) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (_, __, ___) =>
            _FullScreenImageViewer(imageUrl: imageUrl),
      ),
    );
  }
}

class _FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;

  const _FullScreenImageViewer({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: Hero(
              tag: imageUrl,
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 4,
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
