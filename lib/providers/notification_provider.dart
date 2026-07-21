import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_model.dart';
import '../repositories/notification_repository.dart';

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

final unreadNotificationsCountProvider =
    Provider.autoDispose.family<int, String>((ref, districtId) {
  final notificationsAsync = ref.watch(notificationsStreamProvider(districtId));
  return notificationsAsync.maybeWhen(
    data: (list) => list.where((n) => !n.isRead).length,
    orElse: () => 0,
  );
});
