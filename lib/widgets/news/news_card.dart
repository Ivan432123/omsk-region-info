import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/news_model.dart';
import '../common/category_chip.dart';

String _formatViewCount(int count) {
  if (count >= 1000) {
    final thousands = count / 1000;
    return '${thousands.toStringAsFixed(thousands >= 10 ? 0 : 1)}K';
  }
  return '$count';
}

class NewsCard extends StatelessWidget {
  final NewsModel news;
  final VoidCallback onTap;

  /// Тег для Hero-перелёта картинки в детали новости. Опциональный и по
  /// умолчанию выключен (null = обычный Container без Hero): NewsCard
  /// переиспользуется в нескольких блоках одного экрана одновременно
  /// (например, на главном одна и та же новость может попасть и в "Важные
  /// объявления", и в "Последние новости") — если бы каждая карточка сама
  /// строила тег из news.id, при таком совпадении на экране оказались бы
  /// два Hero с одинаковым тегом и приложение упало бы ровно так же, как
  /// уже однажды случилось с галереей (см. TASKS.md, "Известные баги").
  /// Поэтому решение "включать ли Hero" остаётся за вызывающим экраном,
  /// который точно знает, что дублей на этом экране быть не может.
  final String? heroTag;

  const NewsCard({
    super.key,
    required this.news,
    required this.onTap,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    final image = news.imageUrl == null
        ? null
        : SizedBox(
            width: 96,
            height: 108,
            child: CachedNetworkImage(
              imageUrl: news.imageUrl!,
              fit: BoxFit.cover,
              placeholder: (_, __) =>
                  Container(color: AppTheme.surfaceVariant(context)),
              errorWidget: (_, __, ___) => Container(
                color: AppTheme.surfaceVariant(context),
                child: Icon(Icons.image_not_supported_outlined,
                    color: AppTheme.textSecondary(context)),
              ),
            ),
          );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.divider(context)),
          boxShadow: AppTheme.cardShadow,
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (image != null)
              heroTag != null ? Hero(tag: heroTag!, child: image) : image,
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CategoryChip(category: news.category),
                    const SizedBox(height: 6),
                    Text(
                      news.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      news.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          DateFormatter.formatDate(news.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary(context),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Icon(Icons.visibility_outlined,
                            size: 13, color: AppTheme.textSecondary(context)),
                        const SizedBox(width: 3),
                        Text(
                          _formatViewCount(news.viewCount),
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary(context),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
