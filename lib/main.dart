import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'firebase_options.dart';
import 'providers/district_provider.dart';

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
                                          });
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
