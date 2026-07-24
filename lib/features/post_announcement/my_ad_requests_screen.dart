import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../../services/local_storage_service.dart';

class MyAdRequestsScreen extends StatefulWidget {
  const MyAdRequestsScreen({super.key});

  @override
  State<MyAdRequestsScreen> createState() => _MyAdRequestsScreenState();
}

class _MyAdRequestsScreenState extends State<MyAdRequestsScreen> {
  List<Map<String, dynamic>> _requests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final requests = await LocalStorageService().getMyAdRequests();
    if (!mounted) return;
    setState(() {
      _requests = requests;
      _isLoading = false;
    });
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Скопировано'), duration: Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Мои заявки')),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                  color: AppTheme.primaryBlueText(context)))
          : _requests.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Вы ещё не отправляли объявления с этого устройства',
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

  Widget _buildRequestCard(Map<String, dynamic> r) {
    final id = r['id'] as String? ?? '';
    final shortId = id.substring(0, id.length.clamp(0, 8));
    final wantsPush = r['wantsPush'] as bool? ?? false;
    final durationDays = r['durationDays'] as int? ?? 0;
    final banks = (r['banks'] as List?)?.join(', ') ?? '';

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
          Text(r['title'] as String? ?? '',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Row(
            children: [
              Text('Заявка №$shortId',
                  style: TextStyle(
                      color: AppTheme.textSecondary(context), fontSize: 13)),
              IconButton(
                icon: const Icon(Icons.copy_rounded, size: 16),
                onPressed: () => _copyToClipboard(shortId),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          if (wantsPush) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant(context),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Рассылка на $durationDays дней',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(
                      'Переведите ${r['amount']} ₽ по номеру ${r['paymentPhone']} (СБП)'),
                  const SizedBox(height: 4),
                  Text('Доступно через: $banks'),
                  const SizedBox(height: 4),
                  Text('В комментарии укажите: $shortId'),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
