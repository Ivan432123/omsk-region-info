/**
 * НЕ ЗАДЕПЛОЕНО И НЕ ИСПОЛЬЗУЕТСЯ.
 *
 * Firebase-проект на бесплатном тарифе Spark (карта для перехода на Blaze
 * не проходит), а Cloud Functions v2 требует Blaze — деплой невозможен.
 * Реальная отправка push и запись истории в notifications для новостей
 * сделаны напрямую в docs/index.html (функция addNews -> sendPushNotification
 * через Cloudflare Worker) — см. PUSH_WORKER_URL там же. Это единственный
 * работающий канал, а не дублирующий.
 *
 * Файл оставлен в репозитории как справочная реализация той же логики на
 * случай, если тариф всё же сменится на Blaze в будущем — но пока это
 * мёртвый код: правки здесь ни на что не влияют, пока кто-то намеренно не
 * выполнит `firebase deploy --only functions`.
 *
 * Cloud Function: автоматическая рассылка push-уведомлений (справочно).
 *
 * КРИТИЧЕСКИ ВАЖНАЯ ЛОГИКА (требование продукта):
 * Только категории water, gas, electricity, emergency должны автоматически
 * рассылать push. Категория general (и любая другая, не входящая в список)
 * НИКОГДА не должна порождать push-уведомление.
 *
 * Это решение сознательно вынесено на сервер (а не оставлено на клиенте),
 * потому что поле sendPush в документе новости нельзя доверять клиенту —
 * его должен проставлять и проверять только backend.
 *
 * Установка (если появится Blaze):
 *   cd functions && npm install
 *   firebase deploy --only functions
 */

const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { initializeApp } = require('firebase-admin/app');
const { getMessaging } = require('firebase-admin/messaging');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');

initializeApp();

const PUSH_TRIGGERING_CATEGORIES = ['water', 'gas', 'electricity', 'emergency'];

const CATEGORY_LABELS_RU = {
  general: 'Общее',
  water: 'Водоснабжение',
  gas: 'Газоснабжение',
  electricity: 'Электроснабжение',
  road: 'Дороги',
  emergency: 'Экстренное',
  events: 'Мероприятия',
};

exports.onNewsCreated = onDocumentCreated('news/{newsId}', async (event) => {
  const snapshot = event.data;
  if (!snapshot) return;

  const news = snapshot.data();
  const newsId = event.params.newsId;
  const category = news.category || 'general';
  const districtId = news.district;
  const newsTitle = news.title;

  const shouldSendPush = PUSH_TRIGGERING_CATEGORIES.includes(category);

  // Фиксируем фактическое решение на самом документе — источник истины
  // сервер, а не то, что было (возможно, некорректно) прислано при создании.
  // В try/catch: сбой здесь не должен блокировать остальную обработку.
  try {
    await snapshot.ref.update({ sendPush: shouldSendPush });
  } catch (err) {
    console.error(`onNewsCreated(${newsId}): не удалось записать sendPush`, err);
  }

  if (!shouldSendPush) {
    return;
  }

  // Документ мог быть создан не через админ-панель (например, вручную в
  // консоли Firestore) и не пройти её валидацию — не отправляем push с
  // мусорным текстом и не роняем функцию без try/catch ниже.
  if (typeof districtId !== 'string' || districtId.length === 0) {
    console.error(`onNewsCreated(${newsId}): отсутствует/некорректен district, push не отправлен`);
    return;
  }
  if (typeof newsTitle !== 'string' || newsTitle.length === 0) {
    console.error(`onNewsCreated(${newsId}): отсутствует/некорректен title, push не отправлен`);
    return;
  }

  const firestore = getFirestore();

  // Идемпотентность: onDocumentCreated гарантирует "at-least-once" —
  // Cloud Functions может повторно вызвать обработчик для того же
  // документа при инфраструктурном retry. Без этой проверки повторный
  // вызов отправил бы push и создал дубликат записи в notifications ещё раз.
  const alreadyProcessed = await firestore
      .collection('notifications')
      .where('relatedNewsId', '==', newsId)
      .limit(1)
      .get();
  if (!alreadyProcessed.empty) {
    console.log(`onNewsCreated(${newsId}): уже обработано, пропускаем`);
    return;
  }

  const categoryLabel = CATEGORY_LABELS_RU[category] || 'Важно';
  const title = `${categoryLabel}: ${newsTitle}`;
  const body = news.description || '';
  const topic = `district_${districtId}`;

  // 1. Отправка push через FCM Topic конкретного района.
  try {
    await getMessaging().send({
      topic,
      notification: { title, body },
      data: {
        newsId,
        category,
        districtId,
      },
    });
  } catch (err) {
    console.error(`onNewsCreated(${newsId}): отправка push через FCM не удалась`, err);
    return;
  }

  // 2. Создаём документ в notifications — это то, что клиент видит в
  //    истории уведомлений (экран "Уведомления"), даже если устройство
  //    было офлайн в момент отправки push.
  try {
    await firestore.collection('notifications').add({
      title,
      body,
      relatedNewsId: newsId,
      category,
      district: districtId,
      createdAt: FieldValue.serverTimestamp(),
    });
  } catch (err) {
    console.error(`onNewsCreated(${newsId}): push отправлен, но запись в notifications не создана`, err);
  }
});
