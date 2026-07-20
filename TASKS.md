# Текущие задачи

## Партия 3.4 — Партнёрская (спонсорская) лента
- [ ] Новая коллекция sponsored_content: district, title, imageUrl, targetUrl, organizationId?, activeUntil, order
- [ ] Простая repository/provider-пара (district + activeUntil > now, orderBy order)
- [ ] home_screen.dart: горизонтальная карусель под featured-организациями, подпись "Реклама"
- [ ] firestore.rules: read: true, write: admin auth only

## Известные баги
- [ ] firestore.rules — задвоенные закрывающие скобки в конце файла
- [ ] race condition в push-уведомлениях
- [ ] незащищённые вызовы FCM
- [ ] фейковая кнопка "закладка"

## Проверка после каждой партии
1. dart format lib
2. flutter analyze — 0 замечаний
3. Ручной обзор diff'а Firestore-правил на скобки
4. Проверка firestore.indexes.json на composite-запросы

## Ручные шаги в конце
- Внесение координат районов
- Данные по автобусам
- Реальный контент в sponsored_content
- Деплой Cloud Functions и Firestore Rules/Indexes через firebase deploy
