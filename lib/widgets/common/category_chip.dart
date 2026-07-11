import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';

/// Цветной чип категории новости.
/// Категории, автоматически рассылающие push (вода/газ/свет/экстренное),
/// визуально выделяются красным — это важная информация для жителя,
/// а не просто декоративная деталь.
class CategoryChip extends StatelessWidget {
  final String category;

  const CategoryChip({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final isUrgent = AppConstants.isPushTriggeringCategory(category);
    final label = AppConstants.categoryLabelsRu[category] ?? 'Общее';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isUrgent ? const Color(0xFFFDEBEB) : AppTheme.primaryBlueLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isUrgent ? AppTheme.accentRed : AppTheme.primaryBlue,
        ),
      ),
    );
  }
}
