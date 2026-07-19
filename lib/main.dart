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
    // Инициализация push-уведомлений (запрос разрешений) сразу при старте.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(fcmServiceProvider).initialize();
      _setupPushHandling();
    });
  }

  /// Настраивает реакцию приложения на push-уведомления:
  /// - тап по уведомлению (приложение было свёрнуто) -> переход к новости;
  /// - холодный запуск приложения именно через тап по уведомлению ->
  ///   тот же переход, как только приложение полностью откроется;
  /// - уведомление пришло, пока приложение уже открыто (foreground) ->
  ///   не показываем системный баннер сами, но сразу обновляем список
  ///   новостей текущего района, чтобы не пришлось тянуть вручную.
  void _setupPushHandling() {
    final fcmService = ref.read(fcmServiceProvider);

    // Приложение было в фоне, пользователь тапнул по уведомлению.
    fcmService.onMessageOpenedApp.listen(_handleNotificationTap);

    // Приложение было полностью закрыто и открылось именно через тап
    // по уведомлению — проверяем это один раз при старте.
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) _handleNotificationTap(message);
    });

    // Уведомление пришло, пока приложение уже открыто — обновляем список
    // новостей текущего района, чтобы новая запись сразу была видна.
    fcmService.onMessage.listen((_) => _refreshCurrentDistrictNews());
  }

  void _handleNotificationTap(RemoteMessage message) {
    final newsId = message.data['newsId'];
    if (newsId != null && newsId.toString().isNotEmpty) {
      AppRouter.router.push('/news/$newsId');
    }
  }

  void _refreshCurrentDistrictNews() {
    final districtId = ref.read(selectedDistrictProvider).id;
    if (districtId == null || districtId.isEmpty) return;
    ref.invalidate(importantAnnouncementsProvider(districtId));
    ref.read(newsListProvider(districtId).notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
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
