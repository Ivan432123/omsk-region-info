import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../models/announcement_model.dart';
import '../../models/sponsored_content_model.dart';
import '../../core/utils/weather_code_info.dart';
import '../../providers/announcement_provider.dart';
import '../../providers/district_provider.dart';
import '../../providers/feature_flags_provider.dart';
import '../../providers/news_provider.dart';
import '../../providers/sponsored_content_provider.dart';
import '../../providers/weather_provider.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/news/news_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final district = ref.watch(selectedDistrictProvider);
    final districtId = district.id ?? '';
    final districtName = district.name ?? '';
    final weatherQuery = (districtId: districtId, districtName: districtName);
    final newsState = ref.watch(newsListProvider(districtId));
    final announcementsAsync =
        ref.watch(importantAnnouncementsProvider(districtId));
    final flags = ref.watch(featureFlagsProvider).valueOrNull;
    final announcementsEnabled = flags?.announcementsEnabled ?? false;
    final promotedAdsAsync = announcementsEnabled
        ? ref.watch(promotedAnnouncementsProvider(districtId))
        : const AsyncValue<List<AnnouncementModel>>.data([]);
    final bannerSubmissionEnabled = flags?.bannerSubmissionEnabled ?? false;
    final sponsoredAsync = bannerSubmissionEnabled
        ? ref.watch(sponsoredContentProvider(districtId))
        : const AsyncValue<List<SponsoredContentModel>>.data([]);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: AppTheme.primaryBlueText(context),
          onRefresh: () async {
            ref.invalidate(importantAnnouncementsProvider(districtId));
            ref.invalidate(promotedAnnouncementsProvider(districtId));
            ref.invalidate(unreadAnnouncementsCountProvider(districtId));
            ref.invalidate(sponsoredContentProvider(districtId));
            ref.invalidate(weatherProvider(weatherQuery));
            await ref.read(newsListProvider(districtId).notifier).refresh();
          },
          child: CustomScrollView(
            // AlwaysScrollableScrollPhysics: без него свайп для обновления
            // не срабатывает, если контента меньше, чем помещается на
            // экране, — стандартная особенность RefreshIndicator в Flutter.
            // Здесь секций обычно достаточно, чтобы экран заполнялся сам,
            // но на маленьком районе (мало новостей/объявлений) это не
            // гарантировано.
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              _HeroHeader(
                districtName: district.name ?? '',
                onSearchTap: () => context.push('/search'),
                onSettingsTap: () => context.push('/settings'),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: _QuickNavRow(
                    onVacancies: () => context.push('/vacancies'),
                    onEvents: () => context.push('/events'),
                    onBusRoutes: () => context.push('/bus-routes'),
                    onUsefulOffers: () => context.push('/useful-offers'),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: _WeatherCard(query: weatherQuery),
                ),
              ),
              promotedAdsAsync.when(
                loading: () =>
                    const SliverToBoxAdapter(child: _HorizontalStripSkeleton()),
                error: (_, __) =>
                    const SliverToBoxAdapter(child: SizedBox.shrink()),
                data: (promotedAds) {
                  if (promotedAds.isEmpty) {
                    return const SliverToBoxAdapter(child: SizedBox.shrink());
                  }
                  return SliverToBoxAdapter(
                    child: _PromotedAnnouncementsCarousel(items: promotedAds),
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
              // Весь блок "Реклама" (заголовок, ссылка "Разместить" и лента
              // баннеров под ней) целиком завязан на bannerSubmissionEnabled
              // — когда приём баннеров от жителей выключен супер-админом,
              // раздел не запрашивается и не показывается вовсе, даже если
              // в sponsored_content остались активные записи с прошлого
              // раза. Когда включён — заголовок и ссылка показываются
              // всегда (единственная точка входа для самостоятельной подачи
              // заявки рекламодателем), а сама лента карточек — только когда
              // есть что листать.
              if (bannerSubmissionEnabled)
                sponsoredAsync.when(
                  loading: () => const SliverToBoxAdapter(
                      child: _HorizontalStripSkeleton()),
                  error: (_, __) =>
                      const SliverToBoxAdapter(child: SizedBox.shrink()),
                  data: (sponsored) {
                    return SliverToBoxAdapter(
                      child: _SponsoredSection(items: sponsored, ref: ref),
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
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: Center(
                        child: CircularProgressIndicator(
                            color: AppTheme.primaryBlueText(context))),
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
                          heroTag: 'news_${newsState.items[index].id}',
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

/// Блок партнёрской (спонсорской) ленты на главном экране — заголовок
/// "Реклама" со ссылкой "Разместить" (единственная точка входа для
/// самостоятельной подачи заявки рекламодателем, см. PostBannerScreen) и,
/// если баннеры уже есть, горизонтальная карусель под ним. Весь виджет
/// строится только когда bannerSubmissionEnabled включён (см. home_screen
/// build) — заголовок и ссылка "Разместить" внутри него поэтому показаны
/// безусловно, даже когда лента пуста — иначе рекламодателю неоткуда узнать
/// о самостоятельном размещении.
class _SponsoredSection extends StatelessWidget {
  final List<SponsoredContentModel> items;
  final WidgetRef ref;

  const _SponsoredSection({
    required this.items,
    required this.ref,
  });

  Future<void> _open(String id, String url) async {
    unawaited(recordSponsoredClick(ref, id));
    unawaited(ref.read(analyticsServiceProvider).logSponsoredBannerTapped(id));
    // Та же нормализация схемы, что и в UsefulOffersListScreen._open — без
    // неё баннер, чья ссылка введена в админке без "http(s)://", молча не
    // открывается по тапу.
    final normalized = url.startsWith('http') ? url : 'https://$url';
    final uri = Uri.tryParse(normalized);
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Реклама',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color:
                        AppTheme.textSecondary(context).withValues(alpha: 0.8),
                    letterSpacing: 0.3,
                  ),
                ),
                InkWell(
                  onTap: () => context.push('/post-banner'),
                  child: Text(
                    'Разместить →',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryBlueText(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (items.isEmpty) const SizedBox(height: 4),
          if (items.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 76,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () => _open(item.id, item.targetUrl),
                      child: SizedBox(
                        width: 160,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CachedNetworkImage(
                              imageUrl: item.imageUrl,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => Container(
                                  color: AppTheme.surfaceVariant(context)),
                            ),
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.fromLTRB(8, 14, 8, 6),
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
                                    fontSize: 12,
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
        ],
      ),
    );
  }
}

/// Горизонтальная карусель платных объявлений жителей (промо-блок,
/// promotedUntil ещё не истёк) — листается влево/вправо так же, как лента
/// рекламных баннеров выше, вместо прежнего вертикального списка
/// полноразмерных карточек. Компактнее и явно перекликается визуально с
/// баннерами, только с оранжевым акцентом "🔥" вместо подписи "Реклама" —
/// это контент от жителей, а не от рекламодателей.
class _PromotedAnnouncementsCarousel extends StatelessWidget {
  final List<AnnouncementModel> items;

  const _PromotedAnnouncementsCarousel({required this.items});

  static const Color _accent = Color(0xFFE67E22);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(Icons.local_fire_department_rounded,
                    color: _accent, size: 16),
                SizedBox(width: 4),
                Text(
                  'Объявления жителей',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _accent,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 76,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final ad = items[index];
                return _PromotedAnnouncementCard(
                  announcement: ad,
                  onTap: () => context.push('/announcements/${ad.id}'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PromotedAnnouncementCard extends StatelessWidget {
  final AnnouncementModel announcement;
  final VoidCallback onTap;

  const _PromotedAnnouncementCard(
      {required this.announcement, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasImage = announcement.images.isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: 160,
          decoration: BoxDecoration(
            color: AppTheme.surface(context),
            border: Border.all(
                color: _PromotedAnnouncementsCarousel._accent, width: 1.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: hasImage
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: announcement.images.first,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) =>
                          Container(color: AppTheme.surfaceVariant(context)),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(8, 14, 8, 6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.7),
                            ],
                          ),
                        ),
                        child: Text(
                          announcement.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        announcement.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        announcement.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary(context),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

/// Заглушка на время загрузки горизонтальной ленты (баннеры или объявления
/// жителей) — той же формы и высоты, что и сама лента, чтобы контент не
/// "впрыгивал" рывком, сдвигая всё ниже, когда данные приходят.
class _HorizontalStripSkeleton extends StatelessWidget {
  const _HorizontalStripSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Shimmer.fromColors(
        baseColor: AppTheme.surfaceVariant(context),
        highlightColor: AppTheme.shimmerHighlight(context),
        child: SizedBox(
          height: 76,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 3,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) => Container(
              width: 160,
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant(context),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Шапка Главной — теперь SliverAppBar, а не статичный блок: при скролле
/// вниз крупный баннер (заголовок + подпись) сжимается в тонкую полосу,
/// освобождая экран под реальный контент для тех, кто уже знает, что это
/// за приложение и открывает его не первый раз. Район, поиск и настройки
/// вынесены в title/actions самого SliverAppBar — они часть неподвижного
/// тулбара и остаются на месте и в развёрнутом, и в свёрнутом виде
/// (в отличие от "ОМСКРЕГИОН ИНФО" и подписи, которые живут только в
/// flexibleSpace и исчезают при сворачивании).
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
    return SliverAppBar(
      pinned: true,
      expandedHeight: 186,
      backgroundColor: AppTheme.primaryBlueDark,
      elevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 12,
      title: Row(
        children: [
          const Icon(Icons.location_on_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 6),
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
      actions: [
        InkWell(
          onTap: onSearchTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            margin: const EdgeInsets.only(right: 4),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.search_rounded, color: Colors.white),
          ),
        ),
        InkWell(
          onTap: onSettingsTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.settings_outlined, color: Colors.white),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
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
          padding: const EdgeInsets.fromLTRB(20, kToolbarHeight + 16, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
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
        ),
      ),
    );
  }
}

/// Погода — "проверяю каждый день" триггер вернуться в приложение чаще, чем
/// только по мере локальных новостей. Компактная строка без заголовка и без
/// скелетона/спиннера на загрузке: это необязательный вспомогательный блок,
/// а не ключевой контент, поэтому при загрузке/ошибке/отсутствии координат
/// для района он просто не занимает места (SizedBox.shrink), а не показывает
/// пользователю пустую рамку или "не удалось загрузить".
class _WeatherCard extends ConsumerWidget {
  final WeatherQuery query;

  const _WeatherCard({required this.query});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weatherAsync = ref.watch(weatherProvider(query));

    return weatherAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (weather) {
        if (weather == null) return const SizedBox.shrink();
        final info = weatherCodeInfo(weather.weatherCode);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.surface(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.divider(context)),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Row(
            children: [
              Icon(info.icon, color: AppTheme.primaryBlueText(context), size: 26),
              const SizedBox(width: 12),
              Text(
                '${weather.temperature.round()}°',
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  info.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppTheme.textSecondary(context),
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _QuickNavRow extends StatelessWidget {
  final VoidCallback onVacancies;
  final VoidCallback onEvents;
  final VoidCallback onBusRoutes;
  final VoidCallback onUsefulOffers;

  const _QuickNavRow({
    required this.onVacancies,
    required this.onEvents,
    required this.onBusRoutes,
    required this.onUsefulOffers,
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
        const SizedBox(width: 12),
        Expanded(
          child: _QuickNavButton(
            icon: Icons.local_offer_rounded,
            label: 'Полезное',
            onTap: onUsefulOffers,
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

  const _QuickNavButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.surface(context),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.divider(context)),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.primaryBlueText(context), size: 24),
            const SizedBox(height: 6),
            // FittedBox + ширина на всю доступную область: без этого длинная
            // подпись переносится на вторую строку и делает свою кнопку выше
            // соседних (Row выравнивает всех по центру относительно самой
            // высокой), из-за чего ряд выглядит "кривым". Однострочный
            // текст, уменьшающийся по ширине, держит все кнопки одной высоты.
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
