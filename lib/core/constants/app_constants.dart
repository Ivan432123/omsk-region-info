/// Централизованные константы приложения.
/// Любые "магические строки" (имена коллекций Firestore, ключи локального
/// хранилища, идентификаторы категорий) должны браться только отсюда —
/// это упрощает будущее расширение на весь Омский регион и всю Россию.
class AppConstants {
  AppConstants._();

  // Название приложения
  static const String appName = 'ОМСКРЕГИОН ИНФО';

  // ---------- Firestore коллекции ----------
  static const String collectionDistricts = 'districts';
  static const String collectionNews = 'news';
  static const String collectionOrganizations = 'organizations';
  static const String collectionNotifications = 'notifications';
  static const String collectionBusRoutes = 'bus_routes';
  static const String collectionSettings = 'settings';
  static const String settingsFeaturesDocId = 'features';

  // ---------- Ключи локального хранилища ----------
  static const String prefsSelectedDistrictId = 'selected_district_id';
  static const String prefsSelectedDistrictName = 'selected_district_name';
  static const String prefsFcmTopicSubscribed = 'fcm_topic_subscribed';

  // ---------- Категории новостей ----------
  // Категории, которые ОБЯЗАНЫ автоматически рассылать push-уведомления.
  // Общие новости (general, road, events) никогда не должны триггерить push.
  static const List<String> pushTriggeringCategories = [
    'water',
    'gas',
    'electricity',
    'emergency',
  ];

  static const Map<String, String> categoryLabelsRu = {
    'general': 'Общее',
    'water': 'Водоснабжение',
    'gas': 'Газоснабжение',
    'electricity': 'Электроснабжение',
    'road': 'Дороги',
    'emergency': 'Экстренное',
    'events': 'Мероприятия',
  };

  static bool isPushTriggeringCategory(String category) =>
      pushTriggeringCategories.contains(category);

  // ---------- Пагинация ----------
  static const int pageSize = 15;

  // ---------- Локаль и форматы ----------
  static const String locale = 'ru_RU';
  static const String dateFormatPattern = 'dd.MM.yyyy';
  static const String timeFormatPattern = 'HH:mm';
}
