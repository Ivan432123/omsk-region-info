import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_formatter.dart';
import '../../providers/organization_provider.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/loading_widget.dart';

class OrganizationDetailsScreen extends ConsumerWidget {
  final String organizationId;

  const OrganizationDetailsScreen({super.key, required this.organizationId});

  Future<void> _call(BuildContext context, String phone) async {
    final uri = Uri(scheme: 'tel', path: PhoneFormatter.toDialFormat(phone));
    if (!await launchUrl(uri)) {
      if (context.mounted) _showError(context, 'Не удалось совершить звонок');
    }
  }

  Future<void> _openMap(BuildContext context, double lat, double lng) async {
    final uri = Uri.parse('https://yandex.ru/maps/?pt=$lng,$lat&z=16&l=map');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) _showError(context, 'Не удалось открыть карту');
    }
  }

  Future<void> _openWebsite(BuildContext context, String url) async {
    final uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) _showError(context, 'Не удалось открыть сайт');
    }
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.accentRed),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orgAsync = ref.watch(organizationDetailsProvider(organizationId));

    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(title: const Text('Организация')),
      body: orgAsync.when(
        loading: () => const LoadingIndicatorWidget(),
        error: (_, __) => EmptyStateWidget.error(
          onRetry: () => ref.invalidate(organizationDetailsProvider(organizationId)),
        ),
        data: (org) {
          if (org == null) {
            return const EmptyStateWidget(
              icon: Icons.apartment_outlined,
              title: 'Организация не найдена',
              subtitle: 'Возможно, она была удалена',
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: SizedBox(
                        width: 72,
                        height: 72,
                        child: org.logoUrl != null
                            ? CachedNetworkImage(imageUrl: org.logoUrl!, fit: BoxFit.cover)
                            : Container(
                                color: AppTheme.primaryBlueLight,
                                child: const Icon(Icons.apartment_rounded,
                                    color: AppTheme.primaryBlue, size: 32),
                              ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(org.name, style: Theme.of(context).textTheme.headlineMedium),
                          const SizedBox(height: 4),
                          Text(
                            org.category,
                            style: const TextStyle(
                              color: AppTheme.primaryBlue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (org.gallery.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 100,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: org.gallery.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) => ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: CachedNetworkImage(
                          imageUrl: org.gallery[index],
                          width: 140,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                if (org.description.isNotEmpty) ...[
                  Text('Описание', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text(org.description, style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: 20),
                ],
                _InfoRow(
                  icon: Icons.call_outlined,
                  label: 'Телефон',
                  value: PhoneFormatter.format(org.phone),
                ),
                _InfoRow(
                  icon: Icons.location_on_outlined,
                  label: 'Адрес',
                  value: org.address,
                ),
                _InfoRow(
                  icon: Icons.access_time_outlined,
                  label: 'Часы работы',
                  value: org.workingHours,
                ),
                if (org.website != null)
                  _InfoRow(
                    icon: Icons.language_outlined,
                    label: 'Сайт',
                    value: org.website!,
                  ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _call(context, org.phone),
                        icon: const Icon(Icons.call_rounded, size: 18),
                        label: const Text('Позвонить'),
                      ),
                    ),
                    if (org.latitude != null && org.longitude != null) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _openMap(context, org.latitude!, org.longitude!),
                          icon: const Icon(Icons.map_outlined, size: 18),
                          label: const Text('На карте'),
                        ),
                      ),
                    ],
                  ],
                ),
                if (org.website != null) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _openWebsite(context, org.website!),
                      icon: const Icon(Icons.open_in_new_rounded, size: 18),
                      label: const Text('Перейти на сайт'),
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

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppTheme.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                const SizedBox(height: 2),
                Text(value, style: Theme.of(context).textTheme.bodyLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
