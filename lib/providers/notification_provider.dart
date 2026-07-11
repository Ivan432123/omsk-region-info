import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_model.dart';
import '../repositories/notification_repository.dart';

final notificationRepositoryProvider = Provider((ref) => NotificationRepository());

/// Живой поток уведомлений района — обновляется автоматически при получении
/// нового push (документ создаётся в Firestore параллельно с отправкой FCM).
final notificationsStreamProvider =
    StreamProvider.family<List<NotificationModel>, String>((ref, districtId) {
  final repo = ref.watch(notificationRepositoryProvider);
  return repo.watchNotifications(districtId);
});

final unreadNotificationsCountProvider =
    Provider.family<int, String>((ref, districtId) {
  final notificationsAsync = ref.watch(notificationsStreamProvider(districtId));
  return notificationsAsync.maybeWhen(
    data: (list) => list.where((n) => !n.isRead).length,
    orElse: () => 0,
  );
});
