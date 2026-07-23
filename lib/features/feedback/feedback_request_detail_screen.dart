import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/feedback_request_model.dart';
import '../../providers/feedback_request_provider.dart';
import '../../services/local_storage_service.dart';

/// Переписка по одному обращению — открывается и из "Мои обращения", и по
/// тапу на push-уведомление об ответе (см. notificationDeepLinkPath в
/// fcm_service.dart, type:'feedback'). При каждом открытии/после каждого
/// успешного показа сообщений отмечает тред прочитанным (см.
/// LocalStorageService.markFeedbackThreadSeen) — этим закрывается бейдж
/// непрочитанного в разделе "Мои обращения"/Настройках.
class FeedbackRequestDetailScreen extends ConsumerStatefulWidget {
  final String requestId;

  const FeedbackRequestDetailScreen({super.key, required this.requestId});

  @override
  ConsumerState<FeedbackRequestDetailScreen> createState() =>
      _FeedbackRequestDetailScreenState();
}

class _FeedbackRequestDetailScreenState
    extends ConsumerState<FeedbackRequestDetailScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  FeedbackRequestModel? _request;
  bool _isLoading = true;
  bool _isSending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final request = await ref
          .read(feedbackRequestRepositoryProvider)
          .getById(widget.requestId);
      if (!mounted) return;
      setState(() {
        _request = request;
        _isLoading = false;
      });
      if (request != null) {
        await LocalStorageService()
            .markFeedbackThreadSeen(widget.requestId, request.messages.length);
        ref.invalidate(unreadFeedbackRepliesCountProvider);
        _scrollToBottom();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Не удалось загрузить обращение';
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send() async {
    final text = _textController.text.trim();
    final request = _request;
    if (text.isEmpty || request == null || _isSending) return;

    setState(() => _isSending = true);
    try {
      await ref
          .read(feedbackRequestRepositoryProvider)
          .sendMessage(id: widget.requestId, text: text);

      final newMessage = FeedbackMessage(
        sender: 'resident',
        text: text,
        createdAt: DateTime.now(),
      );
      final updated = FeedbackRequestModel(
        id: request.id,
        phone: request.phone,
        districtId: request.districtId,
        deviceId: request.deviceId,
        status: 'pending',
        messages: [...request.messages, newMessage],
        createdAt: request.createdAt,
        updatedAt: DateTime.now(),
      );

      _textController.clear();
      if (!mounted) return;
      setState(() => _request = updated);
      await LocalStorageService()
          .markFeedbackThreadSeen(widget.requestId, updated.messages.length);
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Не удалось отправить сообщение, попробуйте ещё раз'),
          backgroundColor: AppTheme.accentRed,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Обращение')),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryBlue));
    }
    if (_error != null || _request == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _error ?? 'Обращение не найдено',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary(context)),
          ),
        ),
      );
    }

    final request = _request!;
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: request.messages.length,
            itemBuilder: (context, index) =>
                _buildBubble(request.messages[index]),
          ),
        ),
        _buildComposer(),
      ],
    );
  }

  Widget _buildBubble(FeedbackMessage message) {
    final isResident = message.sender == 'resident';
    return Align(
      alignment: isResident ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isResident
              ? AppTheme.primaryContainer(context)
              : AppTheme.surfaceVariant(context),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isResident ? 'Вы' : 'Администрация',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isResident
                    ? AppTheme.onPrimaryContainer(context)
                    : AppTheme.textSecondary(context),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message.text,
              style: TextStyle(
                color: isResident
                    ? AppTheme.onPrimaryContainer(context)
                    : AppTheme.textPrimary(context),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormatter.formatDateTime(message.createdAt),
              style: TextStyle(
                fontSize: 10,
                color: isResident
                    ? AppTheme.onPrimaryContainer(context).withValues(alpha: 0.7)
                    : AppTheme.textSecondary(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComposer() {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        border: Border(top: BorderSide(color: AppTheme.divider(context))),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                minLines: 1,
                maxLines: 4,
                maxLength: 2000,
                buildCounter: (context,
                        {required currentLength,
                        required isFocused,
                        maxLength}) =>
                    null,
                decoration: const InputDecoration(
                  hintText: 'Написать сообщение',
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              onPressed: _isSending ? null : _send,
              icon: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded, color: AppTheme.primaryBlue),
            ),
          ],
        ),
      ),
    );
  }
}
