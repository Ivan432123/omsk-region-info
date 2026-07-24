import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/fcm_service.dart';
import '../services/local_storage_service.dart';
import 'district_provider.dart';

/// Опциональные push-категории — в отличие от district_<id> (срочные новости
/// вода/газ/электричество/авария и платные объявления, обязательные, без
/// переключателя), эти по умолчанию выключены: житель включает их сам в
/// "Настройках". events/vacancies/freeAnnouncements привязаны к району
/// (topicForDistrictCategory); usefulOffers — общеплатформенный раздел без
/// district, один topic на всё приложение.
enum PushCategory { events, vacancies, freeAnnouncements, usefulOffers }

extension PushCategoryTopic on PushCategory {
  String get storageKey => switch (this) {
        PushCategory.events => 'events',
        PushCategory.vacancies => 'vacancies',
        PushCategory.freeAnnouncements => 'free_announcements',
        PushCategory.usefulOffers => 'useful_offers',
      };

  bool get isDistrictScoped => this != PushCategory.usefulOffers;
}

class NotificationPreferencesState {
  final bool eventsEnabled;
  final bool vacanciesEnabled;
  final bool freeAnnouncementsEnabled;
  final bool usefulOffersEnabled;

  const NotificationPreferencesState({
    this.eventsEnabled = false,
    this.vacanciesEnabled = false,
    this.freeAnnouncementsEnabled = false,
    this.usefulOffersEnabled = false,
  });

  bool isEnabled(PushCategory category) => switch (category) {
        PushCategory.events => eventsEnabled,
        PushCategory.vacancies => vacanciesEnabled,
        PushCategory.freeAnnouncements => freeAnnouncementsEnabled,
        PushCategory.usefulOffers => usefulOffersEnabled,
      };

  NotificationPreferencesState _copyWith(PushCategory category, bool value) {
    return NotificationPreferencesState(
      eventsEnabled: category == PushCategory.events ? value : eventsEnabled,
      vacanciesEnabled:
          category == PushCategory.vacancies ? value : vacanciesEnabled,
      freeAnnouncementsEnabled: category == PushCategory.freeAnnouncements
          ? value
          : freeAnnouncementsEnabled,
      usefulOffersEnabled:
          category == PushCategory.usefulOffers ? value : usefulOffersEnabled,
    );
  }
}

class NotificationPreferencesNotifier
    extends StateNotifier<NotificationPreferencesState> {
  final LocalStorageService _storage;
  final FcmService _fcm;

  NotificationPreferencesNotifier(this._storage, this._fcm)
      : super(const NotificationPreferencesState()) {
    _load();
  }

  Future<void> _load() async {
    var next = const NotificationPreferencesState();
    for (final category in PushCategory.values) {
      final enabled = await _storage.isPushCategoryEnabled(category.storageKey);
      next = next._copyWith(category, enabled);
    }
    state = next;
  }

  /// [districtId] нужен для district-специфичных категорий — usefulOffers
  /// его игнорирует, раздел общеплатформенный. Подписка/отписка от FCM
  /// намеренно не блокирует сохранение состояния переключателя: без сети
  /// пользователь всё равно должен увидеть, что настройка сохранилась
  /// (тот же компромисс, что и у SelectedDistrictNotifier._subscribeSafely).
  Future<void> setEnabled(
      PushCategory category, bool value, String? districtId) async {
    await _storage.setPushCategoryEnabled(category.storageKey, value);
    state = state._copyWith(category, value);

    final topic = category.isDistrictScoped
        ? (districtId != null && districtId.isNotEmpty
            ? FcmService.topicForDistrictCategory(
                districtId, category.storageKey)
            : null)
        : FcmService.usefulOffersTopic;
    if (topic == null) return;

    try {
      if (value) {
        await _fcm.subscribeToTopic(topic);
      } else {
        await _fcm.unsubscribeFromTopic(topic);
      }
    } catch (_) {
      // Подписка повторится при следующем изменении настройки — не
      // критично для остального функционала приложения.
    }
  }

  /// Переносит уже включённые district-специфичные подписки со старого
  /// района на новый — вызывается из SelectedDistrictNotifier.changeDistrict.
  /// usefulOffers не участвует: он не привязан к району.
  Future<void> migrateDistrict(String oldDistrictId, String newDistrictId) async {
    for (final category
        in PushCategory.values.where((c) => c.isDistrictScoped)) {
      if (!state.isEnabled(category)) continue;
      try {
        await _fcm.unsubscribeFromTopic(
            FcmService.topicForDistrictCategory(
                oldDistrictId, category.storageKey));
        await _fcm.subscribeToTopic(
            FcmService.topicForDistrictCategory(
                newDistrictId, category.storageKey));
      } catch (_) {}
    }
  }
}

final notificationPreferencesProvider = StateNotifierProvider<
    NotificationPreferencesNotifier, NotificationPreferencesState>((ref) {
  return NotificationPreferencesNotifier(
    ref.watch(localStorageServiceProvider),
    ref.watch(fcmServiceProvider),
  );
});
