/// Реквизиты для ручной оплаты через СБП — общие для платного продвижения
/// объявлений жителей (push всем подписчикам района) и для размещения
/// баннеров рекламодателей. Оплата обрабатывается вручную: житель/
/// рекламодатель переводит деньги и указывает номер заявки в комментарии,
/// администратор сверяет поступление в личном кабинете банка и публикует
/// объявление/баннер через веб-панель. Платёжный SDK сознательно не
/// подключён — см. TASKS.md.
class PaymentInfo {
  PaymentInfo._();

  static const String phoneNumber = '+79236885501';
  static const List<String> banks = ['Т-Банк', 'Озон Банк', 'Сбербанк'];
}

/// Тарифы на размещение баннера в партнёрской ленте — цена зависит от
/// срока размещения. Ключ — число дней, значение — цена в рублях.
/// Используются и в форме заявки (что видит рекламодатель), и в админке
/// (что сверяет администратор при публикации), поэтому вынесены в одно
/// место, а не продублированы.
class BannerPricing {
  BannerPricing._();

  static const Map<int, int> priceByDurationDays = {
    7: 500,
    14: 900,
    30: 1600,
  };

  static int priceFor(int durationDays) {
    final price = priceByDurationDays[durationDays];
    if (price == null) {
      throw ArgumentError.value(
          durationDays, 'durationDays', 'Нет тарифа для этого срока');
    }
    return price;
  }
}

/// Тарифы на платное продвижение объявления жителя (push всем подписчикам
/// района) — та же схема "срок → цена", что и у баннеров.
class AnnouncementPromotionPricing {
  AnnouncementPromotionPricing._();

  static const Map<int, int> priceByDurationDays = {
    7: 350,
    14: 600,
    30: 1200,
  };

  static int priceFor(int durationDays) {
    final price = priceByDurationDays[durationDays];
    if (price == null) {
      throw ArgumentError.value(
          durationDays, 'durationDays', 'Нет тарифа для этого срока');
    }
    return price;
  }
}

/// Цена публикации вакансии работодателем — в отличие от баннеров и
/// объявлений, фиксированная и без выбора срока: платного продвижения
/// поверх стандартных 30 дней (см. VacancyRepository._maxAge) пока нет.
class VacancyRequestPricing {
  VacancyRequestPricing._();

  static const int price = 600;
}
