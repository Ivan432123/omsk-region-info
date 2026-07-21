import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';

/// Цветной чип категории новости.
/// У каждой категории свой цвет — так новость легче узнать по цвету
/// с первого взгляда, не читая текст. Экстренные категории (вода, газ,
/// электричество, экстренное — см. AppConstants.isPushTriggeringCategory)
/// используют более "тревожные" цвета, а мероприятия/общее — нейтральные.
class CategoryChip extends StatelessWidget {
  final String category;

  const CategoryChip({super.key, required this.category});

  static const Map<String, Color> _backgroundColors = {
    'general': Color(0xFFEEEEEE),
    'water': Color(0xFFE3F2FD),
    'gas': Color(0xFFFFF3E0),
    'electricity': Color(0xFFFFFDE7),
    'road': Color(0xFFE8F5E9),
    'emergency': Color(0xFFFDEBEB),
    'events': Color(0xFFF3E5F5),
  };

  static const Map<String, Color> _textColors = {
    'general': Color(0xFF616161),
    'water': Color(0xFF1565C0),
    'gas': Color(0xFFEF6C00),
    'electricity': Color(0xFFF9A825),
    'road': AppTheme.success,
    'emergency': AppTheme.accentRed,
    'events': Color(0xFF7B1FA2),
  };

  @override
  Widget build(BuildContext context) {
    final label = AppConstants.categoryLabelsRu[category] ?? 'Общее';
    final backgroundColor =
        _backgroundColors[category] ?? AppTheme.primaryContainer(context);
    final textColor = _textColors[category] ?? AppTheme.primaryBlue;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}
