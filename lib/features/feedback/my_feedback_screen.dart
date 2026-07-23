import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/feedback_model.dart';
import '../../repositories/feedback_repository.dart';
import '../../services/local_storage_service.dart';

/// Список обращений, отправленных с этого устройства, вместе с ответом
/// супер-админа, если он уже есть. В отличие от "Мои заявки" (см.
/// MyAdRequestsScreen) данные не берутся из локального снимка — локально
/// хранятся только id (см. LocalStorageService.getMyFeedbackIds), а сам
/// статус/ответ каждый раз перезапрашивается из Firestore, потому что
/// ответ появляется уже после отправки и локально его взять неоткуда.
class MyFeedbackScreen extends StatefulWidget {
  const MyFeedbackScreen({super.key});

  @override
  State<MyFeedbackScreen> createState() => _MyFeedbackScreenState();
}

class _MyFeedbackScreenState extends State<MyFeedbackScreen> {
  List<FeedbackModel> _items = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final ids = await LocalStorageService().getMyFeedbackIds();
      final repository = FeedbackRepository();
      final items = await Future.wait(ids.map(repository.getFeedbackById));
      if (!mounted) return;
      setState(() {
        _items = items.whereType<FeedbackModel>().toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Мои обращения')),
      body: RefreshIndicator(
        color: AppTheme.primaryBlue,
        onRefresh: _load,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryBlue));
    }
    if (_hasError) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  'Не удалось загрузить обращения',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textSecondary(context)),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                    onPressed: _load, child: const Text('Повторить')),
              ],
            ),
          ),
        ],
      );
    }
    if (_items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Вы ещё не отправляли обращений с этого устройства',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary(context)),
            ),
          ),
        ],
      );
    }
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      itemCount: _items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _buildCard(_items[index]),
    );
  }

  Widget _buildCard(FeedbackModel item) {
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
          Row(
            children: [
              Expanded(
                child: Text(item.message,
                    style: Theme.of(context).textTheme.bodyLarge),
              ),
              const SizedBox(width: 8),
              _StatusChip(isAnswered: item.isAnswered),
            ],
          ),
          if (item.isAnswered) ...[
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
                  const Text('Ответ',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryBlue)),
                  const SizedBox(height: 4),
                  Text(item.reply!),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool isAnswered;

  const _StatusChip({required this.isAnswered});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isAnswered
            ? AppTheme.success.withValues(alpha: 0.15)
            : AppTheme.primaryBlue.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isAnswered ? 'Отвечено' : 'Ожидает ответа',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isAnswered ? AppTheme.success : AppTheme.primaryBlue,
        ),
      ),
    );
  }
}
