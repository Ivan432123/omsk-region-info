/**
 * Скрипт наполнения Firestore демонстрационными данными.
 *
 * Использование:
 *   1. Скачайте сервисный ключ (Project Settings → Service Accounts →
 *      Generate new private key) и сохраните как serviceAccountKey.json
 *      рядом с этим файлом (НЕ коммитьте его в git).
 *   2. node seed/seed.js
 */

const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const serviceAccount = require('./serviceAccountKey.json');

initializeApp({ credential: cert(serviceAccount) });
const db = getFirestore();

const districts = [
  { id: 'sherbakulsky', name: 'Шербакульский район', order: 1 },
  { id: 'azovsky', name: 'Азовский район', order: 2 },
  { id: 'odessky', name: 'Одесский район', order: 3 },
  { id: 'moskalensky', name: 'Москаленский район', order: 4 },
  { id: 'isilkulsky', name: 'Исилькульский район', order: 5 },
  { id: 'tavrichesky', name: 'Таврический район', order: 6 },
];

const news = [
  {
    district: 'sherbakulsky',
    category: 'water',
    title: 'Плановое отключение воды',
    description: 'С 10:00 до 16:00 будет приостановлена подача воды по ул. Ленина',
    content:
      'В связи с плановыми ремонтными работами на водопроводной сети 15 июля с 10:00 ' +
      'до 16:00 будет приостановлена подача холодной воды по улицам Ленина, Советская ' +
      'и Мира. Просим жителей заранее запастись водой. Приносим извинения за неудобства.',
    image: 'https://images.unsplash.com/photo-1504328345606-18bbc8c9d7d1?w=800&q=80',
  },
  {
    district: 'sherbakulsky',
    category: 'electricity',
    title: 'Отключение электроэнергии',
    description: 'Аварийные работы на подстанции затронут центральную часть района',
    content:
      'Из-за аварийных работ на подстанции 16 июля с 09:00 до 13:00 возможны перебои ' +
      'электроснабжения в центральной части района. Энергетики уже приступили к устранению неисправности.',
    image: 'https://images.unsplash.com/photo-1621905251189-08b45d6a269e?w=800&q=80',
  },
  {
    district: 'sherbakulsky',
    category: 'events',
    title: 'День района',
    description: 'Праздничные мероприятия пройдут на центральной площади 20 июля',
    content:
      '20 июля центральная площадь района станет площадкой для празднования Дня района. ' +
      'В программе: концерт местных коллективов, ярмарка мастеров, конкурсы для детей и вечерний салют.',
    image: 'https://images.unsplash.com/photo-1533174072545-7a4b6ad7a6c3?w=800&q=80',
  },
  {
    district: 'sherbakulsky',
    category: 'general',
    title: 'Открытие новой спортивной площадки',
    description: 'Современная площадка с уличными тренажёрами открылась в микрорайоне',
    content:
      'В микрорайоне открылась новая спортивная площадка с уличными тренажёрами и зоной для ' +
      'воркаута. Площадка доступна для жителей всех возрастов ежедневно с 07:00 до 22:00.',
    image: 'https://images.unsplash.com/photo-1517649763962-0c623066013b?w=800&q=80',
  },
  {
    district: 'azovsky',
    category: 'gas',
    title: 'Технические работы на газопроводе',
    description: 'Кратковременная приостановка подачи газа в частном секторе',
    content:
      'В связи с плановым техническим обслуживанием газопровода 17 июля возможна ' +
      'кратковременная приостановка подачи газа в частном секторе села. Работы завершатся до вечера.',
    image: 'https://images.unsplash.com/photo-1518709268805-4e9042af2176?w=800&q=80',
  },
  {
    district: 'azovsky',
    category: 'emergency',
    title: 'Экстренное предупреждение о непогоде',
    description: 'МЧС предупреждает о сильном ветре и грозе в ближайшие сутки',
    content:
      'Главное управление МЧС предупреждает жителей района о сильном ветре до 20 м/с и грозе ' +
      'в ближайшие сутки. Просим воздержаться от поездок без необходимости и убрать лёгкие предметы с балконов.',
    image: 'https://images.unsplash.com/photo-1500674425229-f692875b0ab7?w=800&q=80',
  },
];

const organizations = [
  {
    district: 'sherbakulsky',
    name: 'Администрация Шербакульского района',
    category: 'Администрация района',
    phone: '+73816521000',
    address: 'р.п. Шербакуль, ул. Ленина, 1',
    workingHours: 'Пн–Пт: 08:00–17:00, обед 12:00–13:00',
    description: 'Орган местного самоуправления Шербакульского района.',
  },
  {
    district: 'sherbakulsky',
    name: 'МФЦ Шербакульского района',
    category: 'МФЦ',
    phone: '+73816521235',
    address: 'р.п. Шербакуль, ул. Советская, 5',
    workingHours: 'Пн–Сб: 08:00–20:00',
    description: 'Многофункциональный центр предоставления государственных услуг.',
  },
  {
    district: 'sherbakulsky',
    name: 'Центральная районная больница',
    category: 'Больница',
    phone: '+73816521236',
    address: 'р.п. Шербакуль, ул. Больничная, 2',
    workingHours: 'Круглосуточно',
    description: 'Стационарная и амбулаторная медицинская помощь населению района.',
  },
  {
    district: 'sherbakulsky',
    name: 'Поликлиника №1',
    category: 'Поликлиника',
    phone: '+73816521237',
    address: 'р.п. Шербакуль, ул. Мира, 10',
    workingHours: 'Пн–Пт: 08:00–19:00, Сб: 08:00–14:00',
    description: 'Приём терапевта, узких специалистов, лабораторная диагностика.',
  },
  {
    district: 'sherbakulsky',
    name: 'Средняя школа №1',
    category: 'Школа',
    phone: '+73816521238',
    address: 'р.п. Шербакуль, ул. Школьная, 3',
    workingHours: 'Пн–Пт: 08:00–15:00',
    description: 'Общеобразовательная школа полного цикла.',
  },
  {
    district: 'sherbakulsky',
    name: 'Детский сад «Солнышко»',
    category: 'Детский сад',
    phone: '+73816521239',
    address: 'р.п. Шербакуль, ул. Молодёжная, 7',
    workingHours: 'Пн–Пт: 07:00–19:00',
    description: 'Дошкольное образовательное учреждение.',
  },
  {
    district: 'sherbakulsky',
    name: 'Районный дом культуры',
    category: 'Дом культуры',
    phone: '+73816521240',
    address: 'р.п. Шербакуль, ул. Ленина, 15',
    workingHours: 'Вт–Вс: 10:00–21:00',
    description: 'Концертные и творческие мероприятия, кружки для детей и взрослых.',
  },
];

async function seed() {
  const batch = db.batch();

  districts.forEach((d) => {
    const ref = db.collection('districts').doc(d.id);
    batch.set(ref, {
      name: d.name,
      regionId: 'omsk',
      villages: [],
      isActive: true,
      order: d.order,
    });
  });

  news.forEach((n) => {
    const ref = db.collection('news').doc();
    batch.set(ref, {
      ...n,
      sendPush: ['water', 'gas', 'electricity', 'emergency'].includes(n.category),
      createdAt: FieldValue.serverTimestamp(),
    });
  });

  organizations.forEach((o) => {
    const ref = db.collection('organizations').doc();
    batch.set(ref, { ...o, logoUrl: null, gallery: [], website: null });
  });

  await batch.commit();
  console.log('Демонстрационные данные успешно загружены.');
}

seed().catch((err) => {
  console.error('Ошибка загрузки демо-данных:', err);
  process.exit(1);
});
