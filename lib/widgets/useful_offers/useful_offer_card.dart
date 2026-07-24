import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/useful_offer_model.dart';

class UsefulOfferCard extends StatelessWidget {
  final UsefulOfferModel offer;
  final VoidCallback onTap;

  const UsefulOfferCard({super.key, required this.offer, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surface(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.divider(context)),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: 56,
                height: 56,
                child: offer.imageUrl != null && offer.imageUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: offer.imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                            color: AppTheme.surfaceVariant(context)),
                        errorWidget: (_, __, ___) => const _FallbackIcon(),
                      )
                    : const _FallbackIcon(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    offer.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    offer.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.open_in_new_rounded,
                size: 18, color: AppTheme.textSecondary(context)),
          ],
        ),
      ),
    );
  }
}

class _FallbackIcon extends StatelessWidget {
  const _FallbackIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.primaryContainer(context),
      child: Icon(Icons.local_offer_rounded,
          color: AppTheme.onPrimaryContainer(context)),
    );
  }
}
