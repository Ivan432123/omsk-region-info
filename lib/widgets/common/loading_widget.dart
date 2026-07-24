import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/app_theme.dart';

/// Скелетон-заглушка на время загрузки списков (новости/организации).
class LoadingListWidget extends StatelessWidget {
  final int itemCount;

  const LoadingListWidget({super.key, this.itemCount = 4});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: AppTheme.surfaceVariant(context),
        highlightColor: AppTheme.shimmerHighlight(context),
        child: Container(
          height: 108,
          decoration: BoxDecoration(
            color: AppTheme.surfaceVariant(context),
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }
}

/// Простой центрированный индикатор — для первого запуска, деталей и т.п.
class LoadingIndicatorWidget extends StatelessWidget {
  final String label;

  const LoadingIndicatorWidget({super.key, this.label = 'Загрузка...'});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: AppTheme.primaryBlueText(context)),
          const SizedBox(height: 16),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
