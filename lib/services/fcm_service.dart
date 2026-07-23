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
  // Ответ супер-админа на обращение в поддержку — отдельная ветка: у него
  // нет news-документа, на который можно сослаться, ведёт всегда в один и
  // тот же список "Мои обращения", а не на конкретную запись.
  if (type == 'feedback_reply') return '/my-feedback';

  final itemId = message.data['newsId'];
  if (itemId == null || itemId.toString().isEmpty) return null;

  return type == 'announcement' ? '/announcements/$itemId' : '/news/$itemId';
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

  /// Подписывает устройство на push-ответ супер-админа по конкретному
  /// обращению в поддержку. В проекте нет адресной отправки по токену
  /// устройства — единственный реально работающий канал push (Cloudflare
  /// Worker, вызываемый из docs/index.html) умеет слать только в topic
  /// вида district_<id>. Поэтому вместо района сюда подставляется id
  /// самого обращения (topicForDistrict('feedback_$feedbackId') даёт
  /// district_feedback_<id>) — это не про район, а способ получить
  /// персональный topic на уже готовой инфраструктуре, не трогая Worker.
  Future<void> subscribeToFeedbackReply(String feedbackId) =>
      _messaging.subscribeToTopic(topicForDistrict('feedback_$feedbackId'));

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
