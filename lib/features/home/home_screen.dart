import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../models/sponsored_content_model.dart';
import '../../providers/announcement_provider.dart';
import '../../providers/district_provider.dart';
import '../../providers/news_provider.dart';
import '../../providers/sponsored_content_provider.dart';
import '../../widgets/announcements/announcement_card.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/news/news_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final district = ref.watch(selectedDistrictProvider);
    final districtId = district.id ?? '';
    final newsState = ref.watch(newsListProvider(districtId));
    final announcementsAsync =
        ref.watch(importantAnnouncementsProvider(districtId));
    final promotedAdsAsync =
        ref.watch(promotedAnnouncementsProvider(districtId));
    final unreadAnnouncementsAsync =
        ref.watch(unreadAnnouncementsCountProvider(districtId));
    final sponsoredAsync = ref.watch(sponsoredContentProvider(districtId));

    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppTheme.primaryBlue,
          onRefresh: () async {
            ref.invalidate(importantAnnouncementsProvider(districtId));
            ref.invalidate(promotedAnnouncementsProvider(districtId));
            ref.invalidate(unreadAnnouncementsCountProvider(districtId));
            ref.invalidate(sponsoredContentProvider(districtId));
            await ref.read(newsListProvider(districtId).notifier).refresh();
          },
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _HeroHeader(
                  districtName: district.name ?? '',
                  onSearchTap: () => context.push('/search'),
                  onSettingsTap: () => context.push('/settings'),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: _QuickNavRow(
                    onVacancies: () => context.push('/vacancies'),
                    onAnnouncements: () => context.push('/announcements'),
                    onEvents: () => context.push('/events'),
                    onBusRoutes: () => context.push('/bus-routes'),
                    unreadAnnouncements: unreadAnnouncementsAsync.value ?? 0,
                  ),
                ),
              ),
              sponsoredAsync.when(
                loading: () =>
                    const SliverToBoxAdapter(child: SizedBox.shrink()),
                error: (_, __) =>
                    const SliverToBoxAdapter(child: SizedBox.shrink()),
                data: (sponsored) {
                  if (sponsored.isEmpty) {
                    return const SliverToBoxAdapter(child: SizedBox.shrink());
                  }
                  return SliverToBoxAdapter(
                    child: _SponsoredCarousel(items: sponsored, ref: ref),
                  );
                },
              ),
              promotedAdsAsync.when(
                loading: () =>
                    const SliverToBoxAdapter(child: SizedBox.shrink()),
                error: (_, __) =>
                    const SliverToBoxAdapter(child: SizedBox.shrink()),
                data: (promotedAds) {
                  if (promotedAds.isEmpty) {
                    return const SliverToBoxAdapter(child: SizedBox.shrink());
                  }
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.local_fire_department_rounded,
                                  color: Color(0xFFE67E22), size: 20),
                              SizedBox(width: 6),
                              Text('Объявления жителей',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 17)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...promotedAds.map(
                            (ad) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                      color: const Color(0xFFE67E22),
                                      width: 1.5),
                                ),
                                child: AnnouncementCard(
                                  announcement: ad,
                                  onTap: () =>
                                      context.push('/announcements/${ad.id}'),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              announcementsAsync.when(
                loading: () =>
                    const SliverToBoxAdapter(child: SizedBox.shrink()),
                error: (_, __) =>
                    const SliverToBoxAdapter(child: SizedBox.shrink()),
                data: (announcements) {
                  if (announcements.isEmpty) {
                    return const SliverToBoxAdapter(child: SizedBox.shrink());
                  }
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Важные объявления',
                              style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 12),
                          ...announcements.map(
                            (news) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: NewsCard(
                                news: news,
                                onTap: () => context.push('/news/${news.id}'),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Последние новости',
                          style: Theme.of(context).textTheme.titleLarge),
                      TextButton(
                        onPressed: () => context.go('/news'),
                        child: const Text('Все новости'),
                      ),
                    ],
                  ),
                ),
              ),
              if (newsState.isLoading)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Center(
                        child: CircularProgressIndicator(
                            color: AppTheme.primaryBlue)),
                  ),
                )
              else if (newsState.error != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: EmptyStateWidget.error(
                      onRetry: () => ref
                          .read(newsListProvider(districtId).notifier)
                          .refresh(),
                    ),
                  ),
                )
              else if (newsState.items.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(top: 20),
                    child: EmptyStateWidget.noNews(),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: NewsCard(
                          news: newsState.items[index],
                          onTap: () => context
                              .push('/news/${newsState.items[index].id}'),
                        ),
                      ),
                      childCount: newsState.items.length > 5
                          ? 5
                          : newsState.items.length,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Горизонтальная карусель партнёрских (спонсорских) баннеров —
/// "партнёрская лента" из TASKS.md, партия 3.4. Подпись "Реклама"
/// обязательна: карточки ведут по внешней ссылке партнёра, и это должно
/// быть явно отличимо от редакционного контента.
class _SponsoredCarousel extends StatelessWidget {
  final List<SponsoredContentModel> items;
  final WidgetRef ref;

  const _SponsoredCarousel({required this.items, required this.ref});

  Future<void> _open(String id, String url) async {
    unawaited(recordSponsoredClick(ref, id));
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Реклама',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary.withValues(alpha: 0.8),
                letterSpacing: 0.3,
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final item = items[index];
                return ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: () => _open(item.id, item.targetUrl),
                    child: SizedBox(
                      width: 260,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CachedNetworkImage(
                            imageUrl: item.imageUrl,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) =>
                                Container(color: AppTheme.surfaceGrey),
                          ),
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(10, 20, 10, 8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withValues(alpha: 0.65),
                                  ],
                                ),
                              ),
                              child: Text(
                                item.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  final String districtName;
  final VoidCallback onSearchTap;
  final VoidCallback onSettingsTap;

  const _HeroHeader({
    required this.districtName,
    required this.onSearchTap,
    required this.onSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primaryBlue, AppTheme.primaryBlueDark],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.location_on_rounded,
                          color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        districtName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: onSearchTap,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.search_rounded, color: Colors.white),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: onSettingsTap,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child:
                      const Icon(Icons.settings_outlined, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'ОМСКРЕГИОН ИНФО',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Всё самое важное о вашем районе — в одном месте',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85), fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _QuickNavRow extends StatelessWidget {
  final VoidCallback onVacancies;
  final VoidCallback onAnnouncements;
  final VoidCallback onEvents;
  final VoidCallback onBusRoutes;
  final int unreadAnnouncements;

  const _QuickNavRow({
    required this.onVacancies,
    required this.onAnnouncements,
    required this.onEvents,
    required this.onBusRoutes,
    required this.unreadAnnouncements,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickNavButton(
            icon: Icons.work_rounded,
            label: 'Вакансии',
            onTap: onVacancies,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickNavButton(
            icon: Icons.campaign_rounded,
            label: 'Объявления',
            onTap: onAnnouncements,
            badgeCount: unreadAnnouncements,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickNavButton(
            icon: Icons.event_rounded,
            label: 'Афиша',
            onTap: onEvents,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickNavButton(
            icon: Icons.directions_bus_rounded,
            label: 'Автобусы',
            onTap: onBusRoutes,
          ),
        ),
      ],
    );
  }
}

class _QuickNavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final int badgeCount;

  const _QuickNavButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.divider),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          children: [
            Badge(
              isLabelVisible: badgeCount > 0,
              label: Text('$badgeCount'),
              backgroundColor: AppTheme.accentRed,
              child: Icon(icon, color: AppTheme.primaryBlue, size: 24),
            ),
            const SizedBox(height: 6),
            // FittedBox + ширина на всю доступную область: у "Объявления" —
            // самая длинная подпись из четырёх кнопок ряда, без этого она
            // переносится на вторую строку и делает свою кнопку выше соседних
            // (Row выравнивает всех по центру относительно самой высокой),
            // из-за чего ряд выглядит "кривым". Однострочный текст,
            // уменьшающийся по ширине, держит все четыре кнопки одной высоты.
            SizedBox(
              width: double.infinity,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
