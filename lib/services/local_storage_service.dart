import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';

/// Сервис локального хранилища.
/// Отвечает за то, что выбор района сохраняется НАВСЕГДА и приложение
/// больше никогда не показывает экран выбора района, пока пользователь
/// сам не сбросит его в настройках (future scope).
class LocalStorageService {
  static const String _keyMyAdRequests = 'my_ad_requests';
  static const String _keyMyBannerRequests = 'my_banner_requests';
  static const String _keyLastSeenAnnouncementsPrefix =
      'last_seen_announcements_';
  static const String _keyLastSeenNotificationsPrefix =
      'last_seen_notifications_';
  static const String _keyBookmarkedOrganizations = 'bookmarked_organizations';
  static const String _keyBookmarkedNews = 'bookmarked_news';
  static const String _keyBookmarkedAnnouncements = 'bookmarked_announcements';
  static const String _keyDeviceId = 'device_id';
  static const String _keyDistrictCoordsPrefix = 'district_coords_';

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  Future<bool> hasSelectedDistrict() async {
    final prefs = await _prefs;
    return prefs.containsKey(AppConstants.prefsSelectedDistrictId);
  }

  Future<String?> getSelectedDistrictId() async {
    final prefs = await _prefs;
    return prefs.getString(AppConstants.prefsSelectedDistrictId);
  }

  Future<String?> getSelectedDistrictName() async {
    final prefs = await _prefs;
    return prefs.getString(AppConstants.prefsSelectedDistrictName);
  }

  Future<void> saveSelectedDistrict({
    required String districtId,
    required String districtName,
  }) async {
    final prefs = await _prefs;
    await prefs.setString(AppConstants.prefsSelectedDistrictId, districtId);
    await prefs.setString(AppConstants.prefsSelectedDistrictName, districtName);
  }

  Future<bool> isFcmTopicSubscribed(String topic) async {
    final prefs = await _prefs;
    return prefs.getString(AppConstants.prefsFcmTopicSubscribed) == topic;
  }

  Future<void> markFcmTopicSubscribed(String topic) async {
    final prefs = await _prefs;
    await prefs.setString(AppConstants.prefsFcmTopicSubscribed, topic);
  }

  /// Сохраняет отправленную жителем заявку на объявление локально на
  /// устройстве — чтобы реквизиты оплаты можно было посмотреть повторно
  /// даже после закрытия приложения (в аккаунте это не хранится, входа
  /// в приложение нет вообще).
  Future<void> saveMyAdRequest(Map<String, dynamic> request) async {
    final prefs = await _prefs;
    final existing = await getMyAdRequests();
    existing.insert(0, request);
    // Храним не больше 10 последних заявок, чтобы список не рос бесконечно.
    final trimmed = existing.take(10).toList();
    await prefs.setString(_keyMyAdRequests, jsonEncode(trimmed));
  }

  Future<List<Map<String, dynamic>>> getMyAdRequests() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_keyMyAdRequests);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List;
      return decoded.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  /// Сохраняет отправленную рекламодателем заявку на баннер локально на
  /// устройстве — по тому же принципу, что и заявки на объявления (см.
  /// saveMyAdRequest), чтобы реквизиты оплаты можно было посмотреть снова.
  Future<void> saveMyBannerRequest(Map<String, dynamic> request) async {
    final prefs = await _prefs;
    final existing = await getMyBannerRequests();
    existing.insert(0, request);
    final trimmed = existing.take(10).toList();
    await prefs.setString(_keyMyBannerRequests, jsonEncode(trimmed));
  }

  Future<List<Map<String, dynamic>>> getMyBannerRequests() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_keyMyBannerRequests);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List;
      return decoded.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  /// Отметка "когда житель последний раз заходил в раздел Объявления
  /// этого района" — используется для счётчика новых объявлений.
  Future<DateTime?> getLastSeenAnnouncementsTime(String districtId) async {
    final prefs = await _prefs;
    final raw = prefs.getString('$_keyLastSeenAnnouncementsPrefix$districtId');
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  Future<void> markAnnouncementsSeen(String districtId) async {
    final prefs = await _prefs;
    await prefs.setString(
      '$_keyLastSeenAnnouncementsPrefix$districtId',
      DateTime.now().toIso8601String(),
    );
  }

  /// Отметка "когда житель последний раз заходил в раздел Уведомления этого
  /// района" — по тому же принципу, что и объявления (см.
  /// markAnnouncementsSeen). "Прочитано" для уведомлений намеренно хранится
  /// только локально: раньше это был общий флаг isRead на документе
  /// notifications, который читают все жители района одновременно —
  /// открытие уведомления одним человеком помечало его прочитанным у всех
  /// остальных.
  Future<DateTime?> getLastSeenNotificationsTime(String districtId) async {
    final prefs = await _prefs;
    final raw = prefs.getString('$_keyLastSeenNotificationsPrefix$districtId');
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  Future<void> markNotificationsSeen(String districtId) async {
    final prefs = await _prefs;
    await prefs.setString(
      '$_keyLastSeenNotificationsPrefix$districtId',
      DateTime.now().toIso8601String(),
    );
  }

  /// Закладки (организации/новости/объявления) хранятся локально на
  /// устройстве по одному и тому же принципу — входа в приложение нет,
  /// синхронизации между устройствами тоже намеренно нет. Приватный
  /// generic-хелпер ниже параметризован ключом SharedPreferences, чтобы не
  /// плодить три копии одной и той же логики; публичный API остаётся
  /// явным — отдельные именованные методы под каждый тип контента.
  Future<bool> _isBookmarked(String prefsKey, String id) async {
    final prefs = await _prefs;
    return (prefs.getStringList(prefsKey) ?? []).contains(id);
  }

  Future<List<String>> _getBookmarkedIds(String prefsKey) async {
    final prefs = await _prefs;
    return prefs.getStringList(prefsKey) ?? [];
  }

  Future<void> _setBookmarked(String prefsKey, String id, bool value) async {
    final prefs = await _prefs;
    final ids = prefs.getStringList(prefsKey) ?? [];
    if (value) {
      if (!ids.contains(id)) ids.add(id);
    } else {
      ids.remove(id);
    }
    await prefs.setStringList(prefsKey, ids);
  }

  Future<bool> isOrganizationBookmarked(String organizationId) =>
      _isBookmarked(_keyBookmarkedOrganizations, organizationId);

  Future<List<String>> getBookmarkedOrganizationIds() =>
      _getBookmarkedIds(_keyBookmarkedOrganizations);

  Future<void> setOrganizationBookmarked(
          String organizationId, bool bookmarked) =>
      _setBookmarked(_keyBookmarkedOrganizations, organizationId, bookmarked);

  Future<bool> isNewsBookmarked(String newsId) =>
      _isBookmarked(_keyBookmarkedNews, newsId);

  Future<List<String>> getBookmarkedNewsIds() =>
      _getBookmarkedIds(_keyBookmarkedNews);

  Future<void> setNewsBookmarked(String newsId, bool bookmarked) =>
      _setBookmarked(_keyBookmarkedNews, newsId, bookmarked);

  Future<bool> isAnnouncementBookmarked(String announcementId) =>
      _isBookmarked(_keyBookmarkedAnnouncements, announcementId);

  Future<List<String>> getBookmarkedAnnouncementIds() =>
      _getBookmarkedIds(_keyBookmarkedAnnouncements);

  Future<void> setAnnouncementBookmarked(
          String announcementId, bool bookmarked) =>
      _setBookmarked(_keyBookmarkedAnnouncements, announcementId, bookmarked);

  /// Локальный ID устройства — единственный способ ограничить "один голос
  /// за организацию" в приложении без входа (см. rules organizations/
  /// {orgId}/ratings/{deviceId}). Генерируется один раз через
  /// Random.secure() (16 случайных байт → hex-строка, без новых
  /// зависимостей) и сохраняется навсегда; сброс данных приложения или
  /// переустановка даёт новое устройство — это мягкое, осознанно принятое
  /// ограничение, не криптографическая идентификация.
  Future<String> getOrCreateDeviceId() async {
    final prefs = await _prefs;
    final existing = prefs.getString(_keyDeviceId);
    if (existing != null && existing.isNotEmpty) return existing;

    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    final id = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    await prefs.setString(_keyDeviceId, id);
    return id;
  }

  /// Координаты района для виджета погоды на Главной — определяются
  /// геокодированием названия района (см. GeocodingRepository) при первом
  /// обращении и кэшируются здесь навсегда: у района не бывает переезда,
  /// а без кэша каждое обновление Главной заново дёргало бы geocoding API.
  Future<(double, double)?> getCachedDistrictCoordinates(
      String districtId) async {
    final prefs = await _prefs;
    final raw = prefs.getString('$_keyDistrictCoordsPrefix$districtId');
    if (raw == null) return null;
    final parts = raw.split(',');
    if (parts.length != 2) return null;
    final lat = double.tryParse(parts[0]);
    final lon = double.tryParse(parts[1]);
    if (lat == null || lon == null) return null;
    return (lat, lon);
  }

  Future<void> cacheDistrictCoordinates(
      String districtId, double lat, double lon) async {
    final prefs = await _prefs;
    await prefs.setString('$_keyDistrictCoordsPrefix$districtId', '$lat,$lon');
  }
}
