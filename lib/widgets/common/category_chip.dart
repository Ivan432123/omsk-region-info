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

  // Пастельные фоны, рассчитанные на светлый фон карточки — на тёмном фоне
  // светились бы яркими белёсыми пятнами, поэтому только для светлой темы.
  static const Map<String, Color> _lightBackgroundColors = {
    'general': Color(0xFFEEEEEE),
    'water': Color(0xFFE3F2FD),
    'gas': Color(0xFFFFF3E0),
    'electricity': Color(0xFFFFFDE7),
    'road': Color(0xFFE8F5E9),
    'emergency': Color(0xFFFDEBEB),
    'events': Color(0xFFF3E5F5),
  };

  static const Map<String, Color> _lightTextColors = {
    'general': Color(0xFF616161),
    'water': Color(0xFF1565C0),
    'gas': Color(0xFFEF6C00),
    'electricity': Color(0xFFF9A825),
    'road': AppTheme.success,
    'emergency': AppTheme.accentRed,
    'events': Color(0xFF7B1FA2),
  };

  // Тёмные приглушённые фоны и посветлевший текст того же оттенка — тот же
  // приём, что использует Material 3 для container-цветов.
  static const Map<String, Color> _darkBackgroundColors = {
    'general': Color(0xFF3A3A3A),
    'water': Color(0xFF163654),
    'gas': Color(0xFF4A2E10),
    'electricity': Color(0xFF4A4310),
    'road': Color(0xFF1B3A20),
    'emergency': Color(0xFF4A1F1B),
    'events': Color(0xFF3A1F42),
  };

  static const Map<String, Color> _darkTextColors = {
    'general': Color(0xFFC7C7C7),
    'water': Color(0xFF7EB6F5),
    'gas': Color(0xFFFFB74D),
    'electricity': Color(0xFFFFE082),
    'road': Color(0xFF81C784),
    'emergency': Color(0xFFEF9A9A),
    'events': Color(0xFFCE93D8),
  };

  @override
  Widget build(BuildContext context) {
    final label = AppConstants.categoryLabelsRu[category] ?? 'Общее';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        (isDark ? _darkBackgroundColors : _lightBackgroundColors)[category] ??
            AppTheme.primaryContainer(context);
    final textColor = (isDark ? _darkTextColors : _lightTextColors)[category] ??
        AppTheme.onPrimaryContainer(context);

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
