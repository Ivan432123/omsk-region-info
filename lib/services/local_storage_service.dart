import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';

/// Сервис локального хранилища.
/// Отвечает за то, что выбор района сохраняется НАВСЕГДА и приложение
/// больше никогда не показывает экран выбора района, пока пользователь
/// сам не сбросит его в настройках (future scope).
class LocalStorageService {
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
}
