import 'package:firebase_analytics/firebase_analytics.dart';

/// Тонкая обёртка над Firebase Analytics — именованные события вместо
/// разбросанных по экранам сырых вызовов logEvent с ключами-строками.
/// Автоматический screen_view при переходах между роутами настроен в
/// AppRouter (FirebaseAnalyticsObserver) — здесь только точечные бизнес-
/// события, которые не выводятся из одного факта смены маршрута. Данные
/// смотреть в Firebase Console (DebugView/Retention/Funnels) — в
/// собственную супер-админку (docs/index.html) Firebase Analytics не
/// проксируется (нет доступа к GA4 Data API без бэкенда), там отдельные
/// счётчики в Firestore (см. NotificationPreferencesNotifier._recordOptInChange,
/// SponsoredContentRepository.recordClick, UsefulOfferRepository.recordClick).
class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  /// "Submitted", а не "posted" — в момент этого события объявление ещё
  /// заявка (ad_requests), реальная публикация происходит позже, после
  /// модерации администратором района/супер-админом в веб-панели, которая
  /// Firebase Analytics не подключает вовсе (обычная веб-страница без SDK).
  Future<void> logAnnouncementSubmitted({required bool wantsPush}) => _log(
        'announcement_submitted',
        {'wants_push': wantsPush},
      );

  Future<void> logVacancyRequestSubmitted() =>
      _log('vacancy_request_submitted');

  Future<void> logBannerRequestSubmitted() =>
      _log('banner_request_submitted');

  Future<void> logUsefulOfferTapped(String offerId) =>
      _log('useful_offer_tapped', {'offer_id': offerId});

  Future<void> logSponsoredBannerTapped(String bannerId) =>
      _log('sponsored_banner_tapped', {'banner_id': bannerId});

  Future<void> logPushCategoryToggled(String category, bool enabled) => _log(
        'push_category_toggled',
        {'category': category, 'enabled': enabled},
      );

  /// Ошибки логирования не должны ронять или прерывать основную функцию
  /// экрана — тот же компромисс, что и у остальных "побочных" вызовов в
  /// проекте (recordSponsoredClick и т.п.).
  Future<void> _log(String name, [Map<String, Object>? parameters]) async {
    try {
      await _analytics.logEvent(name: name, parameters: parameters);
    } catch (_) {}
  }
}
