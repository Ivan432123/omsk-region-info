# ОМСКРЕГИОН ИНФО

Информационный сервис для жителей районов Омской области. MVP-версия,
готовая к коммерческому запуску в RuStore с последующим расширением
на все районы Омской области и все регионы России.

## Содержание

1. Технологический стек
2. Архитектура
3. Структура проекта
4. Логика push-уведомлений (важно)
5. Настройка Firebase
6. Настройка проекта и запуск
7. Наполнение демо-данными
8. Деплой в RuStore
9. Дальнейшее расширение
10. Безопасность

---

## 1. Технологический стек

- **Flutter 3.x**, null safety, Material 3
- **Riverpod** — управление состоянием (StateNotifier + FutureProvider/StreamProvider)
- **GoRouter** — навигация
- **Firebase**: Firestore, Cloud Storage, Cloud Messaging, Cloud Functions
- **MVVM + Repository Pattern**: экраны → провайдеры (ViewModel) → репозитории → Firestore

## 2. Архитектура

```
UI (features/*)
   ↓ читает/вызывает
Providers (providers/*)      ← Riverpod StateNotifier / FutureProvider / StreamProvider
   ↓ вызывает
Repositories (repositories/*) ← Repository Pattern, единственная точка доступа к данным
   ↓ использует
Services (services/*)         ← FirestoreService, FcmService, LocalStorageService
   ↓
Firebase (Firestore / Storage / FCM)
```

Модели (`models/*`) — простые неизменяемые классы с `fromFirestore`/`toMap`,
не содержат бизнес-логики.

Каждый слой заменяем независимо от других (SOLID, Dependency Inversion) —
например, `FirestoreService` можно подменить в тестах mock-реализацией без
изменения репозиториев или UI.

## 3. Структура проекта

```
lib/
  core/
    theme/app_theme.dart          — единая тема (Material 3, синий/белый/красный)
    constants/app_constants.dart  — коллекции, ключи хранилища, категории
    router/app_router.dart        — GoRouter конфигурация
    utils/date_formatter.dart     — форматы даты/времени/телефона (ru_RU)
    utils/input_sanitizer.dart    — валидация и очистка ввода
  models/                         — District, News, Organization, Notification
  repositories/                   — District/News/Organization/NotificationRepository
  services/                       — FirestoreService, FcmService, LocalStorageService
  providers/                      — Riverpod-провайдеры (состояние экранов)
  features/
    splash/                       — Splash Screen
    district_selection/           — Выбор района (поиск + список + сохранение навсегда)
    home/                         — Главный экран
    news/                         — Список новостей + детали новости
    organizations/                — Список организаций + детали организации
    notifications/                — История уведомлений
  widgets/
    common/                       — EmptyState, Loading, CategoryChip
    news/news_card.dart
    organizations/organization_card.dart
  main.dart
  firebase_options.dart           — ШАБЛОН, см. раздел 5

functions/
  index.js                        — Cloud Function: серверная логика push-уведомлений
  package.json

seed/
  seed.js                         — Наполнение Firestore демо-данными

firestore.rules                  — правила безопасности
firestore.indexes.json           — необходимые составные индексы
firebase.json                    — конфигурация Firebase CLI
```

## 4. Логика push-уведомлений (важно)

**Требование продукта:** только категории `water`, `gas`, `electricity`,
`emergency` должны автоматически рассылать push-уведомления. Категория
`general` (и любые другие категории) — никогда.

**Это решение реализовано на сервере, а не на клиенте.** Клиентское
приложение никогда не решает, отправлять push или нет — оно только:

1. Подписывается на Firestore Cloud Messaging topic вида
   `district_<districtId>` при выборе района (`FcmService.subscribeToDistrict`).
2. Слушает коллекцию `notifications`, отфильтрованную по своему району,
   для отображения истории (экран "Уведомления").

Фактическая отправка push происходит в `functions/index.js`
(`onNewsCreated`): при создании документа в коллекции `news` Cloud Function
проверяет поле `category`. Если категория входит в список
push-триггерящих — функция:
- отправляет push в topic `district_<districtId>`;
- создаёт документ в `notifications` (чтобы история была видна даже тем,
  кто был офлайн в момент отправки);
- принудительно проставляет корректное значение `sendPush` в документе
  новости (не доверяя значению, которое могло прийти от клиента/админки).

Это гарантирует, что даже если админ-панель (future scope) отправит
некорректное значение `sendPush`, финальное решение всё равно проверяется
на сервере.

## 5. Настройка Firebase

1. Создайте проект в [Firebase Console](https://console.firebase.google.com).
2. Включите Firestore, Storage, Cloud Messaging.
3. Установите FlutterFire CLI и сгенерируйте `firebase_options.dart`:
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure --project=<ваш-project-id>
   ```
   Это заменит шаблонный файл `lib/firebase_options.dart` реальными ключами.
4. Разверните правила безопасности и индексы:
   ```bash
   firebase deploy --only firestore:rules,firestore:indexes
   ```
5. Разверните Cloud Function:
   ```bash
   cd functions
   npm install
   cd ..
   firebase deploy --only functions
   ```

## 6. Настройка проекта и запуск

```bash
flutter pub get
flutter run
```

Для регенерации моделей (если добавите `freezed`/`json_serializable` поля):
```bash
dart run build_runner build --delete-conflicting-outputs
```

## 7. Наполнение демо-данными

1. Firebase Console → Project Settings → Service Accounts →
   Generate new private key → сохраните как `seed/serviceAccountKey.json`
   (файл уже добавлен в `.gitignore`, не коммитьте его).
2. Запустите:
   ```bash
   cd seed
   npm install firebase-admin
   node seed.js
   ```
Скрипт создаст 6 демо-районов Омской области, набор новостей по всем
категориям и организации (администрация, МФЦ, больница, поликлиника,
школа, детский сад, дом культуры).

## 8. Деплой в RuStore

1. Соберите релизный APK/AAB:
   ```bash
   flutter build appbundle --release
   ```
2. Зарегистрируйтесь как разработчик в [RuStore Console](https://console.rustore.ru).
3. Загрузите `.aab`, заполните карточку приложения на русском языке
   (название "ОМСКРЕГИОН ИНФО", описание, скриншоты, политика конфиденциальности).
4. Укажите разрешение на push-уведомления и обоснование геолокации не
   требуется (MVP не запрашивает геолокацию устройства — район выбирается
   вручную).
5. Пройдите модерацию RuStore (обычно 1–3 рабочих дня).

## 9. Дальнейшее расширение (архитектура уже это учитывает)

- **Фильтрация по сёлам внутри района** — поле `villages` уже есть в
  `DistrictModel`, поле `village` — в `NewsModel`. Остаётся добавить
  экран выбора села и фильтр в `NewsRepository`.
- **Весь Омский регион / вся Россия** — поле `regionId` в `DistrictModel`
  уже заложено (сейчас всегда `"omsk"`). Экран выбора района достаточно
  расширить на выбор региона → района, репозитории не меняются.
- **Админ-панель** — отдельное Flutter Web или React-приложение,
  использующее Admin SDK для записи в те же коллекции; мобильное
  приложение продолжит работать без изменений, так как вся запись и так
  происходит только через сервер (см. `firestore.rules`).
- **Бизнес-кабинет / реклама / платные push** — новые коллекции
  (`businesses`, `ads`, `promoted_notifications`) добавляются без
  изменения структуры `districts`/`news`/`organizations`.
- **Погода, события** — новые фичи по аналогии с `features/news`, тот же
  паттерн Repository → Provider → UI.

## 10. Безопасность

- Приложение работает без регистрации — клиент никогда не пишет в
  `districts`, `news`, `organizations` (см. `firestore.rules`).
- Единственная разрешённая клиенту операция записи — пометка одного
  уведомления как прочитанного, ограниченная на уровне правил только
  полем `isRead`.
- Поисковый ввод и любые будущие поля форм проходят через
  `InputSanitizer` (очистка управляющих символов, ограничение длины).
- API-ключи Firebase, сгенерированные `flutterfire configure`, должны
  быть ограничены в Google Cloud Console (API restrictions) до релиза.
- Сервисный ключ для `seed.js` не должен попадать в систему контроля
  версий — добавьте `seed/serviceAccountKey.json` в `.gitignore` (уже
  сделано в шаблоне ниже).

---

## Статус MVP

Реализовано: Splash → District Selection → Home → News (список/детали) →
Organizations (список/детали) → Notifications, пагинация, пустые
состояния, кэширование изображений, серверная логика push-уведомлений,
правила безопасности Firestore, скрипт демо-данных.

Не входит в MVP (сознательно, чтобы не размывать первый релиз):
регистрация/личный кабинет, геолокация, оффлайн-режим, админ-панель,
монетизация. Архитектура рассчитана на добавление всего перечисленного
без переписывания существующего кода.
# проверка push из Cloud Shell
