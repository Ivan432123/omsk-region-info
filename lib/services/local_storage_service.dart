import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';

/// Сервис локального хранилища.
/// Отвечает за то, что выбор района сохраняется НАВСЕГДА и приложение
/// больше никогда не показывает экран выбора района, пока пользователь
/// сам не сбросит его в настройках (future scope).
class LocalStorageService {
  static const String _keyMyAdRequests = 'my_ad_requests';
  static const String _keyLastSeenAnnouncementsPrefix =
      'last_seen_announcements_';
  static const String _keyBookmarkedOrganizations = 'bookmarked_organizations';

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

  Future<void> clearSelectedDistrict() async {
    final prefs = await _prefs;
    await prefs.remove(AppConstants.prefsSelectedDistrictId);
    await prefs.remove(AppConstants.prefsSelectedDistrictName);
    await prefs.remove(AppConstants.prefsFcmTopicSubscribed);
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

  /// Организации, добавленные жителем в закладки (хранится локально на
  /// устройстве — входа в приложение нет, синхронизации между устройствами
  /// тоже намеренно нет).
  Future<bool> isOrganizationBookmarked(String organizationId) async {
    final prefs = await _prefs;
    final ids = prefs.getStringList(_keyBookmarkedOrganizations) ?? [];
    return ids.contains(organizationId);
  }

  Future<void> setOrganizationBookmarked(
    String organizationId,
    bool bookmarked,
  ) async {
    final prefs = await _prefs;
    final ids = prefs.getStringList(_keyBookmarkedOrganizations) ?? [];
    if (bookmarked) {
      if (!ids.contains(organizationId)) ids.add(organizationId);
    } else {
      ids.remove(organizationId);
    }
    await prefs.setStringList(_keyBookmarkedOrganizations, ids);
  }
}
