/**
 * Cloud Function: автоматическая рассылка push-уведомлений.
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
 * Установка:
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

  const shouldSendPush = PUSH_TRIGGERING_CATEGORIES.includes(category);

  // Фиксируем фактическое решение на самом документе — источник истины
  // сервер, а не то, что было (возможно, некорректно) прислано при создании.
  await snapshot.ref.update({ sendPush: shouldSendPush });

  if (!shouldSendPush || !districtId) {
    return;
  }

  const categoryLabel = CATEGORY_LABELS_RU[category] || 'Важно';
  const title = `${categoryLabel}: ${news.title}`;
  const body = news.description || '';
  const topic = `district_${districtId}`;

  // 1. Отправка push через FCM Topic конкретного района.
  await getMessaging().send({
    topic,
    notification: { title, body },
    data: {
      newsId,
      category,
      districtId,
    },
  });

  // 2. Параллельно создаём документ в notifications — это то, что клиент
  //    видит в истории уведомлений (экран "Уведомления"), даже если
  //    устройство было офлайн в момент отправки push.
  await getFirestore().collection('notifications').add({
    title,
    body,
    relatedNewsId: newsId,
    category,
    district: districtId,
    isRead: false,
    createdAt: FieldValue.serverTimestamp(),
  });
});
