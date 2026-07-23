import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../models/feedback_request_model.dart';
import '../../providers/feedback_request_provider.dart';
import '../../services/local_storage_service.dart';

/// История обращений жителя к супер-администратору, по образцу
/// MyVacancyRequestsScreen — но, в отличие от заявок на объявление/баннер/
/// вакансию, здесь нужно показать не только то, что было отправлено, а и
/// ответ супер-админа. Локальный снимок (id, message, createdAt) хранится
/// на устройстве с момента отправки (см. LocalStorageService.
/// saveMyFeedbackRequest); при открытии экрана каждый ID перечитывается из
/// Firestore (FeedbackRequestRepository.getById), чтобы подтянуть
/// актуальные status/reply.
class MyFeedbackRequestsScreen extends ConsumerStatefulWidget {
  const MyFeedbackRequestsScreen({super.key});

  @override
  ConsumerState<MyFeedbackRequestsScreen> createState() =>
      _MyFeedbackRequestsScreenState();
}

class _MyFeedbackRequestsScreenState
    extends ConsumerState<MyFeedbackRequestsScreen> {
  List<FeedbackRequestModel> _requests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final saved = await LocalStorageService().getMyFeedbackRequests();
    final repository = ref.read(feedbackRequestRepositoryProvider);

    final requests = <FeedbackRequestModel>[];
    for (final entry in saved) {
      final id = entry['id'] as String? ?? '';
      if (id.isEmpty) continue;
      final fresh = await repository.getById(id);
      if (fresh != null) {
        requests.add(fresh);
      } else {
        // Документ ещё не подтянулся (например, офлайн) — показываем то,
        // что сохранили локально при отправке, вместо пустого списка.
        requests.add(FeedbackRequestModel(
          id: id,
          message: entry['message'] as String? ?? '',
          districtId: '',
          deviceId: '',
          createdAt: DateTime.tryParse(entry['createdAt'] as String? ?? '') ??
              DateTime.now(),
        ));
      }
    }

    if (!mounted) return;
    setState(() {
      _requests = requests;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Мои обращения')),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryBlue))
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
    final isAnswered = r.status == 'answered' && r.reply != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(r.message, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                    ? AppTheme.success
                    : AppTheme.textSecondary(context),
              ),
            ),
          ),
          if (isAnswered) ...[
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
                  const Text('Ответ администрации',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(r.reply!),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
