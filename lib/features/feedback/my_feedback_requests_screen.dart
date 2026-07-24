import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/feedback_request_model.dart';
import '../../providers/feedback_request_provider.dart';
import '../../services/local_storage_service.dart';

/// История обращений жителя к супер-администратору, по образцу
/// MyVacancyRequestsScreen — но, в отличие от заявок на объявление/баннер/
/// вакансию, это список ТРЕДОВ переписки, а не одноразовых заявок: каждая
/// карточка показывает последнее сообщение и статус, тап открывает полный
/// чат (FeedbackRequestDetailScreen). Локальный снимок (id, message,
/// createdAt) хранится на устройстве с момента отправки (см.
/// LocalStorageService.saveMyFeedbackRequest); при открытии экрана каждый ID
/// перечитывается из Firestore (FeedbackRequestRepository.getById), чтобы
/// подтянуть актуальную переписку.
class MyFeedbackRequestsScreen extends ConsumerStatefulWidget {
  const MyFeedbackRequestsScreen({super.key});

  @override
  ConsumerState<MyFeedbackRequestsScreen> createState() =>
      _MyFeedbackRequestsScreenState();
}

class _MyFeedbackRequestsScreenState
    extends ConsumerState<MyFeedbackRequestsScreen> {
  List<FeedbackRequestModel> _requests = [];
  Map<String, bool> _unread = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final storage = LocalStorageService();
    final saved = await storage.getMyFeedbackRequests();
    final repository = ref.read(feedbackRequestRepositoryProvider);

    final requests = <FeedbackRequestModel>[];
    final unread = <String, bool>{};
    for (final entry in saved) {
      final id = entry['id'] as String? ?? '';
      if (id.isEmpty) continue;
      final fresh = await repository.getById(id);
      if (fresh != null) {
        requests.add(fresh);
        final lastSeen = await storage.getFeedbackLastSeenCount(id);
        unread[id] = fresh.messages.length > lastSeen;
      } else {
        // Документ ещё не подтянулся (например, офлайн) — показываем то,
        // что сохранили локально при отправке, вместо пустого списка.
        requests.add(FeedbackRequestModel(
          id: id,
          districtId: '',
          deviceId: '',
          messages: [
            FeedbackMessage(
              sender: 'resident',
              text: entry['message'] as String? ?? '',
              createdAt:
                  DateTime.tryParse(entry['createdAt'] as String? ?? '') ??
                      DateTime.now(),
            ),
          ],
          createdAt: DateTime.tryParse(entry['createdAt'] as String? ?? '') ??
              DateTime.now(),
        ));
      }
    }

    if (!mounted) return;
    setState(() {
      _requests = requests;
      _unread = unread;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Мои обращения')),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                  color: AppTheme.primaryBlueText(context)))
          : _requests.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Вы ещё не отправляли обращений с этого устройства',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.textSecondary(context)),
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: _requests.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) =>
                      _buildRequestCard(_requests[index]),
                ),
    );
  }

  Widget _buildRequestCard(FeedbackRequestModel r) {
    final isAnswered = r.isAnswered;
    final isUnread = _unread[r.id] ?? false;
    final lastMessage = r.messages.isEmpty ? null : r.messages.last;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () async {
        await context.push('/feedback-requests/${r.id}');
        if (mounted) _load();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUnread ? AppTheme.primaryBlue : AppTheme.divider(context),
            width: isUnread ? 1.4 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(r.firstMessage, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isAnswered
                        ? AppTheme.success.withValues(alpha: 0.15)
                        : AppTheme.surfaceVariant(context),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isAnswered ? 'Отвечено' : 'Ожидает ответа',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isAnswered
                          ? AppTheme.successText(context)
                          : AppTheme.textSecondary(context),
                    ),
                  ),
                ),
                if (isUnread) ...[
                  const SizedBox(width: 8),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppTheme.accentRed,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text('Новое',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.errorText(context))),
                ],
              ],
            ),
            if (lastMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceVariant(context),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lastMessage.sender == 'admin'
                          ? 'Ответ администрации'
                          : 'Ваше сообщение',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lastMessage.text,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormatter.formatDateTime(lastMessage.createdAt),
                      style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary(context)),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
