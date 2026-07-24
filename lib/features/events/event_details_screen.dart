import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_formatter.dart';
import '../../providers/event_provider.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/fullscreen_gallery_viewer.dart';

class EventDetailsScreen extends ConsumerWidget {
  final String eventId;

  const EventDetailsScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventAsync = ref.watch(eventDetailsProvider(eventId));

    return Scaffold(
      appBar: AppBar(
        actions: [
          if (eventAsync.value != null)
            IconButton(
              icon: const Icon(Icons.share_outlined),
              onPressed: () {
                final e = eventAsync.value!;
                final when = DateFormatter.formatDateTime(e.eventDate);
                final where = e.location != null ? ' — ${e.location}' : '';
                Share.share('${e.title}\n$when$where\n\n${e.description}',
                    subject: e.title);
              },
            ),
        ],
      ),
      body: eventAsync.when(
        loading: () => const LoadingIndicatorWidget(),
        error: (_, __) => EmptyStateWidget.error(
          onRetry: () => ref.invalidate(eventDetailsProvider(eventId)),
        ),
        data: (event) {
          if (event == null) {
            return const EmptyStateWidget(
              icon: Icons.event_outlined,
              title: 'Событие не найдено',
              subtitle: 'Возможно, оно было удалено',
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.event_rounded,
                        size: 18, color: AppTheme.primaryBlueText(context)),
                    const SizedBox(width: 8),
                    Text(
                      DateFormatter.formatDateTime(event.eventDate),
                      style: TextStyle(
                        color: AppTheme.primaryBlueText(context),
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(event.title,
                    style: Theme.of(context).textTheme.headlineMedium),
                if (event.location != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    event.location!,
                    style: TextStyle(
                        color: AppTheme.textSecondary(context), fontSize: 15),
                  ),
                ],
                if (event.imageUrl != null) ...[
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () => FullscreenGalleryViewer.open(
                        context, [event.imageUrl!]),
                    child: Hero(
                      tag: FullscreenGalleryViewer.heroTag(event.imageUrl!, 0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: AspectRatio(
                          aspectRatio: 16 / 10,
                          child: CachedNetworkImage(
                            imageUrl: event.imageUrl!,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                                color: AppTheme.surfaceVariant(context)),
                            errorWidget: (_, __, ___) => Container(
                                color: AppTheme.surfaceVariant(context)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Text(event.description,
                    style: Theme.of(context).textTheme.bodyLarge),
              ],
            ),
          );
        },
      ),
    );
  }
}
