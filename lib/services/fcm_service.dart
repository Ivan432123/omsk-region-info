import 'package:firebase_messaging/firebase_messaging.dart';
import 'local_storage_service.dart';

/// Определяет, на какой экран должен вести пуш-уведомление, по его data-
/// payload'у ({newsId, type}). Общая логика для тёплого старта (тап по
/// уведомлению, когда приложение уже открыто/свёрнуто — см. main.dart) и
/// холодного старта (приложение было полностью закрыто — см. SplashScreen),
/// чтобы решение "куда вести" принималось в обоих случаях одинаково.
/// Возвращает null, если уведомление не ссылается на конкретную запись
/// (например, обычный информационный пуш без data.newsId).
String? notificationDeepLinkPath(RemoteMessage message) {
  final type = message.data['type'];
  // "Полезное" — общеплатформенный раздел без отдельного экрана по id
  // (см. UsefulOffersListScreen), поэтому пуш всегда ведёт на сам список,
  // itemId ему не нужен.
  if (type == 'useful_offer') return '/useful-offers';

  final itemId = message.data['newsId'];
  if (itemId == null || itemId.toString().isEmpty) return null;

  switch (type) {
    case 'announcement':
      return '/announcements/$itemId';
    case 'event':
      return '/events/$itemId';
    case 'vacancy':
      return '/vacancies/$itemId';
    case 'feedback':
      return '/feedback-requests/$itemId';
    default:
      return '/news/$itemId';
  }
}

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

  static String topicForDevice(String deviceId) => 'feedback_$deviceId';

  /// Topic опциональных push-категорий (события/вакансии/бесплатные
  /// объявления — см. NotificationPreferences) — отдельный от
  /// topicForDistrict(), чтобы житель мог включать/выключать их по
  /// отдельности, не трогая обязательный topic (срочные новости и платные
  /// объявления продолжают идти в topicForDistrict()).
  static String topicForDistrictCategory(String districtId, String category) =>
      'district_${districtId}_$category';

  /// "Полезное" — общеплатформенный раздел без district (см.
  /// UsefulOfferModel), поэтому topic один на всё приложение, а не на район.
  static const String usefulOffersTopic = 'useful_offers';

  /// Generic подписка/отписка — используется NotificationPreferences для
  /// опциональных категорий (topicForDistrictCategory/usefulOffersTopic),
  /// в отличие от subscribeToDistrict/subscribeToFeedbackTopic ниже, которые
  /// инкапсулируют ещё и свою специфичную логику идемпотентности.
  Future<void> subscribeToTopic(String topic) =>
      _messaging.subscribeToTopic(topic);

  Future<void> unsubscribeFromTopic(String topic) =>
      _messaging.unsubscribeFromTopic(topic);

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

  /// Подписывает устройство на его персональную тему обратной связи —
  /// ответ супер-администратора на обращение приходит именно в неё, а не в
  /// district_<id> (это разослало бы личный ответ всему району). Одна и та
  /// же тема обслуживает ВСЕ обращения, отправленные с этого устройства, —
  /// подписка постоянна и оформляется один раз, отписки не предусмотрено.
  Future<void> subscribeToFeedbackTopic(String deviceId) async {
    if (await _storage.isFeedbackTopicSubscribed()) return;

    await _messaging.subscribeToTopic(topicForDevice(deviceId));
    await _storage.markFeedbackTopicSubscribed();
  }

  Future<String?> getToken() => _messaging.getToken();

  String? _consumedDeepLinkMessageId;

  /// Дедупликация одного и того же push между двумя независимыми путями
  /// обработки (см. main.dart и SplashScreen): на части версий/сборок
  /// firebase_messaging уведомление, открывшее приложение "с нуля",
  /// доставляется и через getInitialMessage() (холодный старт), и следом
  /// через onMessageOpenedApp (тёплый старт) — оба пути тогда попытались бы
  /// сделать push() на один и тот же экран, а GoRouter падает с ассерцией
  /// дублирующегося ключа страницы. Возвращает true (и "занимает" сообщение)
  /// только для первого вызова с данным messageId; повторный вызов с тем же
  /// id возвращает false. Сообщения без messageId не дедуплицируются —
  /// дедуплицировать их надёжно нечем.
  bool consumeDeepLink(RemoteMessage message) {
    final id = message.messageId;
    if (id != null && id == _consumedDeepLinkMessageId) return false;
    _consumedDeepLinkMessageId = id;
    return true;
  }

  /// Уведомление, тапом по которому приложение было запущено "с нуля"
  /// (было полностью закрыто). Возвращает null при обычном запуске.
  Future<RemoteMessage?> getInitialMessage() => _messaging.getInitialMessage();

  /// Поток входящих push-уведомлений, когда приложение открыто (foreground).
  Stream<RemoteMessage> get onMessage => FirebaseMessaging.onMessage;

  /// Событие открытия приложения через нажатие на push.
  Stream<RemoteMessage> get onMessageOpenedApp =>
      FirebaseMessaging.onMessageOpenedApp;
}
