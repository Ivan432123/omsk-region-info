import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_model.dart';
import '../repositories/notification_repository.dart';
import '../services/local_storage_service.dart';

final notificationRepositoryProvider =
    Provider((ref) => NotificationRepository());

/// Живой поток уведомлений района — обновляется автоматически при получении
/// нового push (документ создаётся в Firestore параллельно с отправкой FCM).
/// autoDispose обязателен: это единственная постоянная Firestore-подписка
/// (.snapshots()) в приложении, и без него при смене района в "Настройках"
/// подписка на уведомления старого района продолжала бы жить до конца
/// сессии — никто её больше не watch'ит, но StreamProvider без autoDispose
/// не закрывает listener сам.
final notificationsStreamProvider = StreamProvider.autoDispose
    .family<List<NotificationModel>, String>((ref, districtId) {
  final repo = ref.watch(notificationRepositoryProvider);
  return repo.watchNotifications(districtId);
});

/// Момент, когда житель последний раз открывал раздел "Уведомления" этого
/// района — источник истины для "прочитано", хранится только локально на
/// устройстве (см. LocalStorageService.markNotificationsSeen). Инвалидируется
/// из NotificationsScreen после того, как экран отмечает уведомления
/// просмотренными.
final lastSeenNotificationsProvider =
    FutureProvider.autoDispose.family<DateTime?, String>((ref, districtId) {
  return LocalStorageService().getLastSeenNotificationsTime(districtId);
});

final unreadNotificationsCountProvider =
    Provider.autoDispose.family<int, String>((ref, districtId) {
  final notificationsAsync = ref.watch(notificationsStreamProvider(districtId));
  final lastSeen =
      ref.watch(lastSeenNotificationsProvider(districtId)).valueOrNull;
  return notificationsAsync.maybeWhen(
    data: (list) => lastSeen == null
        ? list.length
        : list.where((n) => n.createdAt.isAfter(lastSeen)).length,
    orElse: () => 0,
  );
});
