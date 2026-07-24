import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/useful_offer_provider.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/useful_offers/useful_offer_card.dart';

class UsefulOffersListScreen extends ConsumerWidget {
  const UsefulOffersListScreen({super.key});

  Future<void> _open(BuildContext context, String url) async {
    // Админка не заставляет вводить схему — если оффер добавлен без
    // "http(s)://" (например, просто "vk.com/..."), Uri.tryParse отдаёт
    // URI без scheme, и launchUrl молча не находит, чем его открыть (тап
    // выглядит так, будто ничего не произошло). Та же нормализация, что
    // уже используется для сайта организации в organization_details_screen.
    final normalized = url.startsWith('http') ? url : 'https://$url';
    final uri = Uri.tryParse(normalized);
    final opened = uri != null &&
        await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Не удалось открыть ссылку'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offersAsync = ref.watch(usefulOffersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Полезное')),
      body: offersAsync.when(
        loading: () => const LoadingListWidget(),
        error: (_, __) => EmptyStateWidget.error(
          onRetry: () => ref.invalidate(usefulOffersProvider),
        ),
        data: (offers) => offers.isEmpty
            ? const EmptyStateWidget(
                icon: Icons.local_offer_outlined,
                title: 'Пока пусто',
                subtitle: 'Полезные предложения от партнёров появятся здесь',
              )
            : RefreshIndicator(
                color: AppTheme.primaryBlue,
                onRefresh: () async => ref.invalidate(usefulOffersProvider),
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  itemCount: offers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final offer = offers[index];
                    return UsefulOfferCard(
                      key: ValueKey(offer.id),
                      offer: offer,
                      onTap: () => _open(context, offer.targetUrl),
                    );
                  },
                ),
              ),
      ),
    );
  }
}
