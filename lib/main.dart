import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'firebase_options.dart';
import 'providers/district_provider.dart';
import 'providers/news_provider.dart';
import 'providers/announcement_provider.dart';
import 'services/fcm_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Русская локализация форматов дат/времени (dd.MM.yyyy, 24ч).
  await initializeDateFormatting(AppConstants.locale, null);

  runApp(const ProviderScope(child: OmskRegionInfoApp()));
}

class OmskRegionInfoApp extends ConsumerStatefulWidget {
  const OmskRegionInfoApp({super.key});

  @override
  ConsumerState<OmskRegionInfoApp> createState() => _OmskRegionInfoAppState();
}

class _OmskRegionInfoAppState extends ConsumerState<OmskRegionInfoApp> {
  @override
  void initState() {
    super.initState();
    // Запрос разрешения на push (FcmService.initialize) больше НЕ вызывается
    // здесь безусловно при каждом старте — ОС показывает системный диалог
    // только один раз за установку, и раньше он "сгорал" сразу при первом
    // запуске, до того как житель успевал увидеть хоть что-то в приложении.
    // Теперь его запрашивает сам DistrictSelectionScreen после первого
    // выбора района, предварительно объяснив ценность в своём диалоге (см.
    // _showPushPermissionPrimer) — а для тех, кто там отказался,
    // NotificationPreferencesNotifier запрашивает разрешение повторно при
    // первом включении любой push-категории в Настройках. Слушатели входящих
    // push ниже по-прежнему настраиваются безусловно — без разрешения
    // сообщения просто не будут приходить, слушать их в этом случае
    // безвредно.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupPushHandling();
    });
  }

  /// Настраивает реакцию приложения на push-уведомления, когда оно уже
  /// запущено (тёплый старт):
  /// - тап по уведомлению (приложение было свёрнуто) -> переход к
  ///   новости или объявлению, в зависимости от типа (data.type);
  /// - уведомление пришло, пока приложение уже открыто (foreground) ->
  ///   не показываем системный баннер сами, но сразу обновляем все
  ///   связанные блоки текущего района, чтобы новая запись сразу была
  ///   видна (новости, важные объявления, продвигаемые объявления,
  ///   счётчик непрочитанных объявлений).
  ///
  /// Холодный запуск через тап по уведомлению (когда приложение было
  /// полностью закрыто) обрабатывается отдельно, внутри SplashScreen —
  /// если решать его здесь, получается гонка: пуш успевает открыть
  /// экран новости/объявления раньше, чем стартовый экран решит, куда
  /// вести пользователя (/home или /district-selection), и это решение
  /// через context.go() полностью стирает уже открытый пушем экран.
  void _setupPushHandling() {
    final fcmService = ref.read(fcmServiceProvider);

    // Приложение было в фоне, пользователь тапнул по уведомлению.
    fcmService.onMessageOpenedApp.listen(_handleNotificationTap);

    // Уведомление пришло, пока приложение уже открыто — обновляем всё,
    // что могло измениться, для текущего района.
    fcmService.onMessage.listen((_) => _refreshCurrentDistrictData());
  }

  void _handleNotificationTap(RemoteMessage message) {
    final path = notificationDeepLinkPath(message);
    if (path == null) return;
    if (!ref.read(fcmServiceProvider).consumeDeepLink(message)) return;
    AppRouter.router.push(path);
  }

  void _refreshCurrentDistrictData() {
    final districtId = ref.read(selectedDistrictProvider).id;
    if (districtId == null || districtId.isEmpty) return;
    ref.invalidate(importantAnnouncementsProvider(districtId));
    ref.invalidate(promotedAnnouncementsProvider(districtId));
    ref.invalidate(unreadAnnouncementsCountProvider(districtId));
    ref.read(newsListProvider(districtId).notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: AppRouter.router,
      locale: const Locale('ru', 'RU'),
      supportedLocales: const [Locale('ru', 'RU')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
