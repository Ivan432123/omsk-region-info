import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/district_provider.dart';
import '../../services/fcm_service.dart';

/// Экран загрузки.
/// Показывает логотип и анимацию, параллельно проверяя, выбран ли уже
/// район ранее (сохранён локально навсегда). В зависимости от результата
/// перенаправляет либо на главный экран, либо на выбор района.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _decideNextRoute();
  }

  Future<void> _decideNextRoute() async {
    // Минимальная задержка ради ощущения премиального, не мигающего запуска,
    // плюс достаточно времени, чтобы провайдер успел прочитать локальное
    // хранилище. Параллельно проверяем, не был ли этот холодный запуск
    // вызван тапом по push-уведомлению — вместе, а не по отдельности,
    // чтобы между решением "куда вести" (/home или /district-selection)
    // и открытием конкретной новости/объявления не было гонки: если бы
    // пуш обрабатывался отдельно (например, в main.dart сразу при
    // старте), он почти всегда успевал бы открыть нужный экран раньше,
    // чем сработает этот таймер, а последующий context.go() отсюда
    // полностью стирал бы уже открытый пушем экран.
    final results = await Future.wait([
      Future.delayed(const Duration(milliseconds: 1200)),
      ref.read(fcmServiceProvider).getInitialMessage(),
    ]);
    if (!mounted) return;
    final initialMessage = results[1] as RemoteMessage?;

    final selected = ref.read(selectedDistrictProvider);

    // Если провайдер ещё не успел прочитать SharedPreferences — ждём его.
    if (selected.isLoading) {
      await Future.doWhile(() async {
        await Future.delayed(const Duration(milliseconds: 100));
        return ref.read(selectedDistrictProvider).isLoading && mounted;
      });
    }

    if (!mounted) return;
    final finalState = ref.read(selectedDistrictProvider);
    if (!finalState.hasSelection) {
      // Район ещё не выбран — деть-линк из пуша некуда вести (в реальности
      // до выбора района подписки на push и не бывает), просто идём на
      // выбор района как обычно.
      context.go('/district-selection');
      return;
    }

    context.go('/home');
    final deepLinkPath = initialMessage != null
        ? notificationDeepLinkPath(initialMessage)
        : null;
    if (deepLinkPath != null &&
        mounted &&
        ref.read(fcmServiceProvider).consumeDeepLink(initialMessage!)) {
      context.push(deepLinkPath);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBlue,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: Tween(begin: 0.94, end: 1.0).animate(
                CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
              ),
              child: Container(
                width: 104,
                height: 104,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.location_city_rounded,
                  size: 56,
                  color: AppTheme.primaryBlue,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'ОМСКРЕГИОН ИНФО',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Информационный сервис вашего района',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.6,
                valueColor:
                    AlwaysStoppedAnimation(Colors.white.withValues(alpha: 0.9)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
