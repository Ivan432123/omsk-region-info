# ОМСКРЕГИОН ИНФО

Информационный сервис для жителей районов Омской области. Вышло далеко за
рамки исходного MVP: помимо новостей и организаций — вакансии, объявления
жителей, афиша, автобусные маршруты, партнёрская реклама с самостоятельной
подачей и платным продвижением, ролевая веб-админка (супер-админ + районные
админы).

## Содержание

1. Технологический стек
2. Архитектура
3. Структура проекта
4. Роли и модерация контента
5. Монетизация
6. Логика push-уведомлений (важно)
7. Настройка Firebase
8. Настройка проекта и запуск
9. Тесты
10. Наполнение демо-данными
11. Веб-админка
12. Сборка Android (Codemagic)
13. Дальнейшее расширение
14. Безопасность
15. Статус проекта

---

## 1. Технологический стек

- **Flutter 3.x**, null safety, Material 3, тёмная тема (`ThemeMode.system`)
- **Riverpod** — управление состоянием (StateNotifier + FutureProvider,
  большинство `autoDispose` — экраны должны сами обновляться после действий
  админа, а не только при перезапуске приложения)
- **GoRouter** — навигация, включая `StatefulShellBranch` для нижней панели
- **Firebase**: Firestore, Cloud Storage, Cloud Messaging (только подписка
  на topics — сама отправка push НЕ через Firebase, см. раздел 6)
- **Cloudinary** — загрузка фото (объявления, баннеры, галереи организаций)
  из приложения и из админки, общий пресет
- **Open-Meteo** (без ключа) — погода и геокодирование координат района
  (`WeatherRepository`, `GeocodingRepository`)
- **Веб-админка** (`docs/index.html`) — не Flutter, обычный HTML/JS,
  Firebase JS SDK (compat), захостена на GitHub Pages
- **MVVM + Repository Pattern**: экраны → провайдеры (ViewModel) →
  репозитории → Firestore/HTTP

## 2. Архитектура

```
UI (features/*)
   ↓ читает/вызывает
Providers (providers/*)      ← Riverpod StateNotifier / FutureProvider
   ↓ вызывает
Repositories (repositories/*) ← Repository Pattern, единственная точка доступа к данным
   ↓ использует
Services (services/*)         ← FirestoreService, FcmService, LocalStorageService, ImageUploadService
   ↓
Firebase (Firestore / Storage / FCM) + Cloudinary + Open-Meteo
```

Модели (`models/*`) — простые неизменяемые классы с `fromFirestore`/`toMap`;
почти без бизнес-логики, кроме единичных вычисляемых геттеров вроде
`AnnouncementModel.isPromoted` (есть ли активное платное продвижение).

## 3. Структура проекта

```
lib/
  core/
    theme/app_theme.dart          — тема (светлая/тёмная, Material 3)
    constants/                    — коллекции, категории, тарифы рекламы, геокодинг районов
    router/                       — GoRouter + нижняя навигация (собственная, не NavigationBar)
    utils/                        — форматы даты/телефона, InputSanitizer, коды погоды
  models/                         — District, News, Organization, Vacancy, Announcement,
                                     AdRequest, BannerRequest, SponsoredContent, BusRoute,
                                     Event, Notification, Weather
  repositories/                   — по одному на модель + WeatherRepository/GeocodingRepository
  services/                       — FirestoreService, FcmService, LocalStorageService, ImageUploadService
  providers/                      — Riverpod-провайдеры (состояние экранов)
  features/
    splash/, district_selection/, home/, news/, organizations/,
    vacancies/, announcements/, post_announcement/, events/, bus_routes/,
    post_banner/, search/, settings/, notifications/
  widgets/                        — карточки и общие виджеты по фичам
  main.dart
  firebase_options.dart           — ШАБЛОН, см. раздел 7

test/
  models/                         — unit-тесты на бизнес-логику моделей (пока минимально)

docs/
  index.html                      — веб-админка (GitHub Pages), см. раздел 11

functions/
  index.js                        — Cloud Function НЕ ЗАДЕПЛОЕНА (Blaze недоступен на
                                     текущем тарифе), оставлена как справочная реализация
                                     той же логики фильтрации push. Реальный push идёт
                                     через Cloudflare Worker из docs/index.html, см. раздел 6

seed/
  seed.js                         — наполнение Firestore демо-данными

codemagic.yaml                    — CI-сборка Android APK (запускается вручную)
firestore.rules                   — правила безопасности (роли, см. раздел 4)
firestore.indexes.json            — composite-индексы
firebase.json                     — конфигурация Firebase CLI (hosting/firestore/functions)
```

Папки `android/`, `ios/` в репозитории нет — их создаёт `flutter create` на
каждой сборке Codemagic (см. раздел 12); правки манифеста живут в
`codemagic.yaml`, а не в закоммиченных platform-файлах.

## 4. Роли и модерация контента

Два уровня доступа к веб-админке, оба через Firebase Auth (email/пароль):

- **Супер-админ** — единственный email, захардкоженный в `isAdmin()`
  (`firestore.rules`). Видит и пишет всё, включая разделы, недоступные
  районным админам: управление районами, назначение районных админов,
  рекламные баннеры, платные заявки на объявления (со всех районов сразу).
- **Районный админ** — документ в `district_admins/{uid}` (создаёт только
  супер-админ), привязан к одному району. Видит и редактирует контент
  только своего района (сверено и на клиенте через `currentDistrictId`, и на
  сервере через `isDistrictAdminFor()` в правилах). Модерирует **только
  бесплатные** заявки на объявления своего района.

Заявки жителей на объявления (`ad_requests`) с выбранным платным
продвижением (🔥, push всем в районе) видит и публикует **только
супер-админ** — районный админ не может задним числом включить платное
продвижение или разослать push сам.

## 5. Монетизация

- **Объявления жителей**: подача без регистрации (`post_announcement`) →
  заявка в `ad_requests` → модерация (см. раздел 4) → публикация в
  `announcements`. При платном продвижении проставляется `promotedUntil`
  (используется `AnnouncementModel.isPromoted` в приложении и админке).
  Бесплатные объявления автоматически перестают показываться в ленте через
  14 дней после публикации, но остаются в списке админки без ограничения.
- **Рекламные баннеры**: самостоятельная подача рекламодателем
  (`post_banner`, без регистрации) → заявка в `banner_requests` с тарифом
  (7/14/30 дней, см. `BannerPricing` в `app_constants`/`payment_info`) →
  модерация и публикация только супер-админом в `sponsored_content`.
  Баннер может быть привязан к одному району или ко всем (`district: 'all'`).
- **Оплата — вручную**: реквизиты для перевода (СБП) показываются жителю
  после подачи заявки, администратор сверяет поступление перед публикацией.
  Платёжный SDK (ЮKassa и т.п.) сознательно не подключался.

## 6. Логика push-уведомлений (важно)

**Продуктовое требование не изменилось:** только категории новостей `water`,
`gas`, `electricity`, `emergency` рассылают push автоматически; `general` и
любые другие — никогда. Платное продвижение объявления тоже рассылает push
всем подписчикам района.

**Как это реализовано сейчас (отличается от исходного плана в
`functions/index.js`):** Firebase-проект на бесплатном тарифе Spark, Cloud
Functions v2 требует Blaze — задеплоить нельзя. Поэтому:

1. Приложение только подписывается на FCM topic `district_<districtId>`
   (`FcmService.subscribeToDistrict`) и слушает коллекцию `notifications`
   для истории — как и раньше.
2. Реальную отправку делает веб-админка (`docs/index.html`): при публикации
   новости push-категории или платного объявления она вызывает
   `sendPushNotification()`, которая шлёт POST (с Firebase ID-токеном
   администратора) на Cloudflare Worker (`PUSH_WORKER_URL` в
   `docs/index.html`).
3. Сам Worker **не хранится в этом репозитории** — управляется отдельно
   (Cloudflare dashboard/wrangler). При изменении логики рассылки его нужно
   редактировать там, правки в `docs/index.html` или `functions/index.js`
   на него не влияют.
4. `functions/index.js` оставлен только как справочная реализация той же
   бизнес-логики на случай перехода на Blaze в будущем — это мёртвый код,
   `firebase deploy --only functions` его не запускает автоматически ни при
   каких обстоятельствах в текущем pipeline.

## 7. Настройка Firebase

1. Создайте проект в [Firebase Console](https://console.firebase.google.com).
2. Включите Firestore, Storage, Cloud Messaging.
3. Установите FlutterFire CLI и сгенерируйте `firebase_options.dart`:
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure --project=<ваш-project-id>
   ```
4. Разверните правила безопасности и индексы:
   ```bash
   firebase deploy --only firestore:rules,firestore:indexes
   ```
5. Cloud Functions разворачивать не нужно (см. раздел 6) — только если
   тариф проекта сменится на Blaze и вы осознанно решите перейти на них.

## 8. Настройка проекта и запуск

```bash
flutter pub get
flutter run
```

Регенерация моделей (если добавите `freezed`/`json_serializable` поля):
```bash
dart run build_runner build --delete-conflicting-outputs
```

## 9. Тесты

```bash
flutter test
```

Покрытие пока минимальное (`test/models/`) — юнит-тесты только на чистую
бизнес-логику моделей (например, `AnnouncementModel.isPromoted`). Модерация
и права доступа проверяются `firestore.rules` и логикой `docs/index.html`,
их тестирование потребовало бы Firebase emulator + `@firebase/rules-unit-testing`
(в проекте пока не подключено).

## 10. Наполнение демо-данными

1. Firebase Console → Project Settings → Service Accounts →
   Generate new private key → сохраните как `seed/serviceAccountKey.json`
   (файл уже в `.gitignore`, не коммитьте его).
2. Запустите:
   ```bash
   cd seed
   npm install firebase-admin
   node seed.js
   ```

## 11. Веб-админка

`docs/index.html` — единственная точка администрирования всего контента
(новости, организации, вакансии, объявления, события, баннеры, автобусные
маршруты), захостена на GitHub Pages (папка `docs/` в главной ветке).
Обновляется обычным `git push` в `main` — отдельного деплоя не требует
(в отличие от `firestore.rules`, который нужно деплоить через Firebase CLI
отдельно).

Ролевой доступ — см. раздел 4. У супер-админа дополнительно есть простая
статистика по объявлениям (всего/платных/бесплатных, за всё время и за
7 дней, по всем районам сразу) со сбросом счётчика.

## 12. Сборка Android (Codemagic)

Автотриггера на push в репозиторий нет — сборка запускается вручную
кнопкой "Start new build" в Codemagic. Текущий workflow (`codemagic.yaml`)
собирает **debug APK**: генерирует `android/` через `flutter create`,
добавляет разрешение `POST_NOTIFICATIONS` в манифест и собирает
`flutter build apk --debug`.

Для релизной сборки (RuStore) потребуется отдельный release-workflow с
подписью (`flutter build appbundle --release`), это ещё не настроено.

## 13. Дальнейшее расширение

- **Фильтрация по сёлам внутри района** — поле `villages` уже есть в
  `DistrictModel`, поле `village` — в `NewsModel`. Остаётся добавить
  экран выбора села и фильтр в `NewsRepository`.
- **Весь Омский регион / вся Россия** — поле `regionId` в `DistrictModel`
  уже заложено (сейчас всегда `"omsk"`).
- **Автоматизация оплаты** (ЮKassa/СБП-эквайринг) — сейчас админ сверяет
  переводы вручную; интеграция потребует бэкенда, а Cloud Functions
  недоступны (см. раздел 6) — вероятно, тоже через Cloudflare Worker.
- **Платное продвижение вакансий** (по аналогии с `promotedUntil` у
  объявлений) — у вакансий пока вообще нет пользовательского flow подачи
  (только админ добавляет напрямую).
- **Реальные данные автобусных маршрутов** — коллекция `bus_routes` в
  проде пока пустая, форма добавления в админке уже готова.

## 14. Безопасность

- Приложение работает без регистрации — клиент не пишет напрямую в
  `districts`/`news`/`organizations`; создание `ad_requests`/`banner_requests`
  разрешено анонимно, но с валидацией полей на уровне правил.
- Запись в контентные коллекции требует либо `isAdmin()` (супер-админ),
  либо `isDistrictAdminFor(district)` (районный админ, только свой район) —
  см. `firestore.rules`.
- Поисковый ввод и поля форм проходят через `InputSanitizer`.
- API-ключи Firebase, сгенерированные `flutterfire configure`, должны быть
  ограничены в Google Cloud Console (API restrictions) до релиза.
- Сервисный ключ для `seed.js` не коммитится (`.gitignore`).

---

## 15. Статус проекта

Далеко за пределами исходного MVP. Реализовано: District Selection → Home
(погода, реклама, быстрые переходы) → News → Organizations (рейтинги,
закладки) → Vacancies → Announcements (подача жителями, платное
продвижение) → Events → Bus Routes → Notifications → Обратная связь с
супер-админом (Settings → "Обратная связь", ответ приходит push'ем); ролевая
веб-админка с модерацией и статистикой; самостоятельная подача рекламных
баннеров; push-уведомления через Cloudflare Worker (не Cloud Functions);
базовые unit-тесты.

Сознательно не сделано: платёжный SDK (оплата вручную), платное
продвижение вакансий, релизный (не debug) Android-workflow, тестирование
firestore.rules через emulator. Подробная история изменений по партиям —
в `TASKS.md`.
