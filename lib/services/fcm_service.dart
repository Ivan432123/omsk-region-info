import 'package:firebase_messaging/firebase_messaging.dart';
import 'local_storage_service.dart';

/// Сервис push-уведомлений.
///
/// Логика: пользователь подписывается на topic конкретного района
/// (например, "district_sherbakulsky"). Реальное решение "отправлять или
/// не отправлять push" принимается НЕ на клиенте, а на сервере —
/// Cloud Function, слушающая создание документа в коллекции news,
/// проверяет category и, только если она входит в
/// [water, gas, electricity, emergency], публикует сообщение в topic
/// соответствующего района. Общие новости никогда не порождают push.
/// Клиентский код ниже только управляет подпиской/отпиской на topic.
class FcmService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final LocalStorageService _storage = LocalStorageService();

  static String topicForDistrict(String districtId) => 'district_$districtId';

  Future<void> initialize() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  /// Подписывает устройство на push конкретного района.
  /// Идемпотентно — повторный вызов для того же района ничего не делает.
  Future<void> subscribeToDistrict(String districtId) async {
    final topic = topicForDistrict(districtId);
    final alreadySubscribed = await _storage.isFcmTopicSubscribed(topic);
    if (alreadySubscribed) return;

    await _messaging.subscribeToTopic(topic);
    await _storage.markFcmTopicSubscribed(topic);
  }

  /// При смене района (future scope: настройки) — отписка от старого.
  Future<void> unsubscribeFromDistrict(String districtId) async {
    await _messaging.unsubscribeFromTopic(topicForDistrict(districtId));
  }

  Future<String?> getToken() => _messaging.getToken();

  /// Поток входящих push-уведомлений, когда приложение открыто (foreground).
  Stream<RemoteMessage> get onMessage => FirebaseMessaging.onMessage;

  /// Событие открытия приложения через нажатие на push.
  Stream<RemoteMessage> get onMessageOpenedApp =>
      FirebaseMessaging.onMessageOpenedApp;
}
