import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_formatter.dart';
import '../../providers/announcement_provider.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/loading_widget.dart';

class AnnouncementDetailsScreen extends ConsumerWidget {
  final String announcementId;

  const AnnouncementDetailsScreen({super.key, required this.announcementId});

  Future<void> _call(BuildContext context, String phone) async {
    final uri = Uri(scheme: 'tel', path: PhoneFormatter.toDialFormat(phone));
    if (!await launchUrl(uri)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Не удалось совершить звонок'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    }
  }

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
                if (announcement.images.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    height: announcement.images.length == 1 ? 200 : 140,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: announcement.images.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) => ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: AspectRatio(
                          aspectRatio: announcement.images.length == 1 ? 16 / 10 : 4 / 3,
                          child: CachedNetworkImage(
                            imageUrl: announcement.images[index],
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(color: AppTheme.surfaceGrey),
                            errorWidget: (_, __, ___) => Container(color: AppTheme.surfaceGrey),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Text(announcement.description, style: Theme.of(context).textTheme.bodyLarge),
                if (announcement.contactPhone != null) ...[
                  const SizedBox(height: 24),
                  InkWell(
                    onTap: () => _call(context, announcement.contactPhone!),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlueLight,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
                              color: AppTheme.primaryBlue,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.call_rounded, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Контактный телефон',
                                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  PhoneFormatter.format(announcement.contactPhone!),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.primaryBlue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded, color: AppTheme.primaryBlue),
                        ],
                      ),
                    ),
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
