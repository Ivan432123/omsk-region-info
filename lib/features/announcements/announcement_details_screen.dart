import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/announcement_provider.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/loading_widget.dart';

class AnnouncementDetailsScreen extends ConsumerWidget {
  final String announcementId;

  const AnnouncementDetailsScreen({super.key, required this.announcementId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final announcementAsync = ref.watch(announcementDetailsProvider(announcementId));

    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(),
      body: announcementAsync.when(
        loading: () => const LoadingIndicatorWidget(),
        error: (_, __) => EmptyStateWidget.error(
          onRetry: () => ref.invalidate(announcementDetailsProvider(announcementId)),
        ),
        data: (announcement) {
          if (announcement == null) {
            return const EmptyStateWidget(
              icon: Icons.campaign_outlined,
              title: 'Объявление не найдено',
              subtitle: 'Возможно, оно было удалено',
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(announcement.title, style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 20),
                Text(announcement.description, style: Theme.of(context).textTheme.bodyLarge),
                if (announcement.contactPhone != null) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Контакт: ${announcement.contactPhone}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
