import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Подбирает иконку и цвет для организации по тексту её категории.
/// Категория в организации — свободный текст, который вводит админ
/// (например "МФЦ", "Школа №1", "Дом культуры"), поэтому сопоставление
/// идёт по ключевым словам, а не по фиксированному списку значений —
/// так это работает с уже введёнными данными без необходимости их менять.
class OrganizationIconHelper {
  OrganizationIconHelper._();

  static IconData iconFor(String category) {
    final c = category.toLowerCase();
    if (c.contains('администра') ||
        c.contains('госучрежд') ||
        c.contains('мфц')) {
      return Icons.account_balance_rounded;
    }
    if (c.contains('больниц') ||
        c.contains('поликлин') ||
        c.contains('мед') ||
        c.contains('фап')) {
      return Icons.local_hospital_rounded;
    }
    if (c.contains('культур') ||
        c.contains('театр') ||
        c.contains('музей') ||
        c.contains('библиотек')) {
      return Icons.theater_comedy_rounded;
    }
    // Перед школой: "спортивная школа" должна получать иконку спорта, а не
    // школы — иначе она перехватывается более общей проверкой ниже.
    if (c.contains('спорт') || c.contains('стадион') || c.contains('бассейн')) {
      return Icons.sports_soccer_rounded;
    }
    if (c.contains('школ') ||
        c.contains('образован') ||
        c.contains('детский сад') ||
        c.contains('универ')) {
      return Icons.school_rounded;
    }
    if (c.contains('почт')) {
      return Icons.local_post_office_rounded;
    }
    if (c.contains('полиц') || c.contains('мчс') || c.contains('пожар')) {
      return Icons.local_police_rounded;
    }
    if (c.contains('такси')) {
      return Icons.local_taxi_rounded;
    }
    return Icons.apartment_rounded;
  }

  static Color colorFor(String category) {
    final c = category.toLowerCase();
    if (c.contains('администра') ||
        c.contains('госучрежд') ||
        c.contains('мфц')) {
      return AppTheme.primaryBlue;
    }
    if (c.contains('больниц') ||
        c.contains('поликлин') ||
        c.contains('мед') ||
        c.contains('фап')) {
      return AppTheme.success;
    }
    if (c.contains('культур') ||
        c.contains('театр') ||
        c.contains('музей') ||
        c.contains('библиотек')) {
      return const Color(0xFFD81B60);
    }
    if (c.contains('спорт') || c.contains('стадион') || c.contains('бассейн')) {
      return const Color(0xFF2E7D32);
    }
    if (c.contains('школ') ||
        c.contains('образован') ||
        c.contains('детский сад') ||
        c.contains('универ')) {
      return const Color(0xFF7B1FA2);
    }
    if (c.contains('почт')) {
      return const Color(0xFFEF6C00);
    }
    if (c.contains('полиц') || c.contains('мчс') || c.contains('пожар')) {
      return AppTheme.accentRed;
    }
    if (c.contains('такси')) {
      return const Color(0xFFFBC02D);
    }
    return AppTheme.primaryBlue;
  }

  static Color backgroundFor(String category) {
    return colorFor(category).withValues(alpha: 0.12);
  }
}
