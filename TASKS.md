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

## Известные баги
- [x] firestore.rules — задвоенные закрывающие скобки в конце файла (см. коммит f1a588b)
- [x] race condition в push-уведомлениях (getInitialMessage и onMessageOpenedApp разведены между SplashScreen и main.dart, см. комментарии в обоих файлах)
- [x] незащищённые вызовы FCM (district_provider.dart: _subscribeSafely/_unsubscribeSafely)
- [x] фейковая кнопка "закладка" (теперь персистится через LocalStorageService)
- [x] отсутствовали composite-индексы для announcements(district+promotedUntil) и events(district+eventDate) — промо-объявления и афиша могли не грузиться в проде; добавлены в firestore.indexes.json, требуют `firebase deploy --only firestore:indexes`

## Проверка после каждой партии
1. dart format lib
2. flutter analyze — 0 замечаний
3. Ручной обзор diff'а Firestore-правил на скобки
4. Проверка firestore.indexes.json на composite-запросы

## Ручные шаги в конце
- Внесение координат районов
- Реальные маршруты и расписание автобусов (коллекция bus_routes — модель и экраны готовы, см. партия 3.5)
- Реальный контент в sponsored_content
- Деплой Cloud Functions и Firestore Rules/Indexes через firebase deploy (включая новые правила sponsored_content и bus_routes, партии 3.5–3.6)

## Осознанно не сделано в этой сессии (см. рекомендации по монетизации)
- Платёжный SDK (ЮKassa/СБП-эквайринг) — по решению пользователя оплата продолжает идти вручную через СБП, админ сверяет и публикует, как и раньше
- Ролевая модель Firestore-правил для нескольких районных модераторов — сейчас write у organizations/vacancies/announcements/events разрешён любому аутентифицированному пользователю; терпимо, пока модератор один, но нужно продумать до найма второго
- Платное продвижение вакансий (по аналогии с promotedUntil у объявлений) — у vacancies сейчас вообще нет пользовательского flow подачи (только админ), заводить платный буст поверх несуществующего flow — отдельная большая задача, не мелкое улучшение
