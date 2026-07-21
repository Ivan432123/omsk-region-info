import 'package:flutter/material.dart';

/// Единая тема приложения — светлая и тёмная (следует системной настройке
/// устройства, см. ThemeMode.system в main.dart).
/// Стиль: премиальный государственный сервис — синий основной цвет,
/// красный акцентный для ключевых действий, скруглённые карточки, мягкие
/// тени, Material 3.
///
/// Фон/поверхности/текст — не const-цвета, а методы AppTheme.xxx(context),
/// читающие их из активной темы, поэтому один и тот же код экрана
/// корректно выглядит в обеих темах. Брендовые (primaryBlue, accentRed,
/// success, warning) — одинаковы в обеих темах и остаются const.
class AppTheme {
  AppTheme._();

  // ---------- Брендовые цвета (не меняются между темами) ----------
  static const Color primaryBlue = Color(0xFF1B4F9C);
  static const Color primaryBlueDark = Color(0xFF123A73);
  static const Color accentRed = Color(0xFFD32F2F);
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFF9A825);

  // ---------- Светлая палитра ----------
  static const Color _lightBackground = Color(0xFFFFFFFF);
  static const Color _lightSurfaceVariant = Color(0xFFF6F7F9);
  static const Color _lightTextPrimary = Color(0xFF1A1D1F);
  static const Color _lightTextSecondary = Color(0xFF6B7280);
  static const Color _lightDivider = Color(0xFFE5E7EB);
  static const Color _lightPrimaryContainer = Color(0xFFE8F0FB);

  // ---------- Тёмная палитра ----------
  // Не чистый чёрный — мягкий тёмно-синевато-серый читается спокойнее на
  // OLED и меньше "звенит" рядом с ярко-синим акцентом.
  static const Color _darkBackground = Color(0xFF13161B);
  static const Color _darkSurface = Color(0xFF1C2028);
  static const Color _darkSurfaceVariant = Color(0xFF262B34);
  static const Color _darkTextPrimary = Color(0xFFEDEFF2);
  static const Color _darkTextSecondary = Color(0xFF9AA3B3);
  static const Color _darkDivider = Color(0xFF2D323C);
  static const Color _darkPrimaryContainer = Color(0xFF213456);

  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 16,
      offset: Offset(0, 6),
    ),
  ];

  // ---------- Семантические цвета, зависящие от активной темы ----------
  static Color surface(BuildContext context) =>
      Theme.of(context).colorScheme.surface;

  static Color scaffoldBackground(BuildContext context) =>
      Theme.of(context).scaffoldBackgroundColor;

  static Color textPrimary(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface;

  static Color textSecondary(BuildContext context) =>
      Theme.of(context).colorScheme.onSurfaceVariant;

  static Color divider(BuildContext context) => Theme.of(context).dividerColor;

  /// Нейтральный слегка выделяющийся фон (плейсхолдеры картинок, подложки
  /// info-блоков) — в старой светлой-only теме назывался surfaceGrey.
  static Color surfaceVariant(BuildContext context) =>
      Theme.of(context).colorScheme.surfaceContainerHighest;

  /// Приглушённый тон бренд-синего для подложек чипов/бейджей/иконок —
  /// в светлой теме бледно-голубой, в тёмной — приглушённый тёмно-синий
  /// (алгоритм Material 3 сам подбирает контрастный вариант под тему).
  static Color primaryContainer(BuildContext context) =>
      Theme.of(context).colorScheme.primaryContainer;

  /// Текст/иконка поверх primaryContainer(context) — гарантированно
  /// контрастны в обеих темах. Использовать вместо фиксированного цвета
  /// вроде primaryBlueDark: тот в тёмной теме оказывается тёмным текстом
  /// на тёмном фоне (primaryContainer в тёмной теме сам становится тёмным).
  static Color onPrimaryContainer(BuildContext context) =>
      Theme.of(context).colorScheme.onPrimaryContainer;

  /// "Блик" shimmer-скелетона — заметно светлее фона в светлой теме, но
  /// должен оставаться тёмным (лишь немного светлее базового) в тёмной,
  /// иначе яркая полоса на почти чёрном фоне выглядит как всполох, а не
  /// спокойная анимация.
  static const Color _darkShimmerHighlight = Color(0xFF333A46);

  static Color shimmerHighlight(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? _darkShimmerHighlight
          : const Color(0xFFEDEFF2);

  static ThemeData get lightTheme => _buildTheme(
        brightness: Brightness.light,
        background: _lightBackground,
        surface: _lightBackground,
        surfaceVariant: _lightSurfaceVariant,
        textPrimaryColor: _lightTextPrimary,
        textSecondaryColor: _lightTextSecondary,
        dividerColor: _lightDivider,
        primaryContainer: _lightPrimaryContainer,
      );

  static ThemeData get darkTheme => _buildTheme(
        brightness: Brightness.dark,
        background: _darkBackground,
        surface: _darkSurface,
        surfaceVariant: _darkSurfaceVariant,
        textPrimaryColor: _darkTextPrimary,
        textSecondaryColor: _darkTextSecondary,
        dividerColor: _darkDivider,
        primaryContainer: _darkPrimaryContainer,
      );

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color surfaceVariant,
    required Color textPrimaryColor,
    required Color textSecondaryColor,
    required Color dividerColor,
    required Color primaryContainer,
  }) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: 'Roboto',
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        brightness: brightness,
        primary: primaryBlue,
        secondary: accentRed,
        surface: surface,
        onSurface: textPrimaryColor,
        onSurfaceVariant: textSecondaryColor,
        surfaceContainerHighest: surfaceVariant,
        primaryContainer: primaryContainer,
      ),
      scaffoldBackgroundColor: background,
      dividerColor: dividerColor,
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: textPrimaryColor,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: textPrimaryColor,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      textTheme: base.textTheme.copyWith(
        headlineLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: textPrimaryColor,
          height: 1.2,
        ),
        headlineMedium: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: textPrimaryColor,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: textPrimaryColor,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textPrimaryColor,
        ),
        bodyLarge:
            TextStyle(fontSize: 16, color: textPrimaryColor, height: 1.4),
        bodyMedium:
            TextStyle(fontSize: 14, color: textSecondaryColor, height: 1.4),
        labelLarge: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: dividerColor, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentRed,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(56),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryBlue,
          side: const BorderSide(color: primaryBlue, width: 1.4),
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceVariant,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primaryBlue, width: 1.6),
        ),
        hintStyle: TextStyle(color: textSecondaryColor),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: background,
        indicatorColor: primaryContainer,
        // Иконка/подпись выбранной вкладки лежат поверх заливки индикатора
        // (primaryContainer), а не поверх фона панели — им нужен цвет,
        // контрастный ИМЕННО с primaryContainer (onPrimaryContainer), а не
        // фиксированный primaryBlue: в тёмной теме primaryContainer сам
        // становится тёмно-синим, и primaryBlue на нём почти не виден —
        // ровно то же самое, что было с primaryBlueDark на чекбоксе
        // объявления.
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected
                ? base.colorScheme.onPrimaryContainer
                : textSecondaryColor,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
              color: selected
                  ? base.colorScheme.onPrimaryContainer
                  : textSecondaryColor);
        }),
      ),
      dividerTheme: DividerThemeData(color: dividerColor, thickness: 1),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: primaryContainer,
        labelStyle: const TextStyle(
            color: primaryBlue, fontWeight: FontWeight.w600, fontSize: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: BorderSide.none,
      ),
    );
  }
}
