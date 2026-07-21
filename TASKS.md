# Текущие задачи

## Партия 3.4 — Партнёрская (спонсорская) лента
- [x] Новая коллекция sponsored_content: district, title, imageUrl, targetUrl, organizationId?, activeUntil, order (модель + composite index district+activeUntil)
- [x] Простая repository/provider-пара (district + activeUntil > now, сортировка по order на клиенте — Firestore требует, чтобы первый orderBy совпадал с полем неравенства)
- [x] home_screen.dart: горизонтальная карусель, подпись "Реклама" (featured-организаций на главном пока нет, карусель размещена под блоком объявлений жителей)
- [x] firestore.rules: read: true, write: admin auth only — внесено (см. партия 3.6)

## Партия 3.5 — Каркас раздела "Автобусы"
- [x] Модель BusRouteModel (routeNumber, routeName, stops, departureTimes, notes, district, order)
- [x] repository/provider (простой fetch по district, сортировка по order на сервере — без пагинации, как sponsored_content)
- [x] Список маршрутов + экран деталей маршрута (остановки + расписание), роуты /bus-routes, /bus-routes/:id
- [x] Кнопка "Автобусы" в _QuickNavRow на главном экране
- [x] firestore.rules: read: true, write: admin auth only; composite-индекс (district+order) в firestore.indexes.json
- [ ] Реальные маршруты и время отправления — коллекция bus_routes пока пустая, наполняется вручную (см. "Ручные шаги")

## Партия 3.6 — Учёт кликов по рекламным баннерам + недостающие правила
- [x] firestore.rules для sponsored_content наконец внесены (были пропущены с партии 3.4 — карусель на проде не грузилась бы вообще, коллекция без правила = запрет по умолчанию)
- [x] SponsoredContentModel.clickCount + SponsoredContentRepository.recordClick — при тапе по баннеру инкремент clickCount/lastClickedAt, разрешено анонимно только по этим двум полям (по аналогии с news.viewCount и notifications.isRead)
- [x] Цель: у партнёра/рекламодателя должна быть хоть какая-то цифра кликов, а не просто "мы разместили баннер"

## Партия 3.7 — Аудит по итогам task.md (баги + качество кода)
- [x] Админка (docs/index.html): добавлены разделы "Рекламный баннер" и "Автобусный маршрут" — sponsored_content и bus_routes были доступны только через Firebase Console, теперь полноценные формы add/edit/delete, как у остальных разделов
- [x] Админка: все load*()-функции (news/organizations/vacancies/announcements/events/ad_requests/districts) обёрнуты в try/catch — раньше при любой ошибке Firestore (запрет правил, отсутствующий индекс, обрыв сети) список молча зависал на "Загрузка..." навсегда; теперь показывается причина и кнопка "Повторить"
- [x] Утечка Firestore-подписки: notificationsStreamProvider/unreadNotificationsCountProvider — единственный live .snapshots()-listener в приложении — не были autoDispose; при смене района в "Настройках" подписка на уведомления старого района жила до конца сессии. Добавлен autoDispose к обоим
- [x] importantAnnouncementsProvider — добавлена защита `if (districtId.isEmpty) return []`, как у остальных family-провайдеров главного экрана (не проявлялось на практике, т.к. сплэш всегда дожидается района, но было единственным исключением из паттерна)
- [x] Закладки организаций были write-only: кнопка сохраняла ID локально, но нигде не было экрана посмотреть список. Добавлены LocalStorageService.getBookmarkedOrganizationIds, bookmarkedOrganizationsProvider (autoDispose), экран "Мои закладки" (/bookmarks), иконка-вход в AppBar раздела "Организации"
- [x] analysis_options.yaml — flutter_lints был в зависимостях, но не подключён (`flutter analyze` реально проверял только голые ошибки компиляции). Подключён рекомендованный набор, поправлены все 7 всплывших info-level замечаний (4× prefer_const_constructors, 3× curly_braces_in_flow_control_structures)
- [ ] Не сделано намеренно: карусель организаций на главном (в task.md упомянута как существующая фича, в кодовой базе её нет и никогда не было — нужно отдельное уточнение, что именно имелось в виду, прежде чем изобретать дизайн)

## Известные баги
- [x] firestore.rules — задвоенные закрывающие скобки в конце файла (см. коммит f1a588b)
- [x] race condition в push-уведомлениях (getInitialMessage и onMessageOpenedApp разведены между SplashScreen и main.dart, см. комментарии в обоих файлах)
- [x] незащищённые вызовы FCM (district_provider.dart: _subscribeSafely/_unsubscribeSafely)
- [x] фейковая кнопка "закладка" (теперь персистится через LocalStorageService)
- [x] отсутствовали composite-индексы для announcements(district+promotedUntil) и events(district+eventDate) — промо-объявления и афиша могли не грузиться в проде; добавлены в firestore.indexes.json, требуют `firebase deploy --only firestore:indexes`
- [x] падение приложения при открытии галереи (объявления/организации): Hero-теги строились из URL картинки; если в галерее случайно встречались два одинаковых URL (ручной ввод в админке), Flutter падал с "multiple heroes that share the same tag". Теги теперь строятся из URL+индекс через FullscreenGalleryViewer.heroTag — исправлено во всех 4 экранах деталей (announcement/organization/event/news) и самом просмотрщике

## Проверка после каждой партии
1. dart format lib
2. flutter analyze — 0 замечаний
3. Ручной обзор diff'а Firestore-правил на скобки
4. Проверка firestore.indexes.json на composite-запросы

## Ручные шаги в конце
- Внесение координат районов
- Реальные маршруты и расписание автобусов — теперь можно вносить прямо из админки (раздел "Добавить автобусный маршрут"), Firebase Console больше не обязателен
- Реальный контент в sponsored_content — аналогично, теперь через админку (раздел "Добавить рекламный баннер")
- Деплой Cloud Functions и Firestore Rules/Indexes через firebase deploy (включая правила sponsored_content и bus_routes, партии 3.5–3.6)

## Осознанно не сделано в этой сессии (см. рекомендации по монетизации)
- Платёжный SDK (ЮKassa/СБП-эквайринг) — по решению пользователя оплата продолжает идти вручную через СБП, админ сверяет и публикует, как и раньше
- Ролевая модель Firestore-правил для нескольких районных модераторов — сейчас write у organizations/vacancies/announcements/events разрешён любому аутентифицированному пользователю; терпимо, пока модератор один, но нужно продумать до найма второго
- Платное продвижение вакансий (по аналогии с promotedUntil у объявлений) — у vacancies сейчас вообще нет пользовательского flow подачи (только админ), заводить платный буст поверх несуществующего flow — отдельная большая задача, не мелкое улучшение
