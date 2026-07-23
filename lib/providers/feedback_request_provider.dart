import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/feedback_request_repository.dart';
import '../services/local_storage_service.dart';

final feedbackRequestRepositoryProvider =
    Provider((ref) => FeedbackRequestRepository());

/// Количество тредов обращений жителя, в которых есть ответ администрации,
/// ещё не открытый на этом устройстве — по аналогии с
/// unreadAnnouncementsCountProvider, но на основе счётчика сообщений (см.
/// LocalStorageService.getFeedbackLastSeenCount), а не времени: время
/// сообщений в чате проставляет клиент (см. FeedbackMessage) и ему нельзя
/// доверять для логики непрочитанного, а вот выросшая длина списка сообщений
/// — надёжный и простой признак.
final unreadFeedbackRepliesCountProvider = FutureProvider<int>((ref) async {
  final storage = LocalStorageService();
  final saved = await storage.getMyFeedbackRequests();
  if (saved.isEmpty) return 0;

  final repository = ref.watch(feedbackRequestRepositoryProvider);
  var unreadCount = 0;
  for (final entry in saved) {
    final id = entry['id'] as String? ?? '';
    if (id.isEmpty) continue;
    final request = await repository.getById(id);
    if (request == null) continue;
    final lastSeen = await storage.getFeedbackLastSeenCount(id);
    if (request.messages.length > lastSeen) unreadCount++;
  }
  return unreadCount;
});
