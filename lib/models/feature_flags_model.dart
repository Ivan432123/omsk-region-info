/// Фиче-флаги, управляемые супер-админом через веб-панель без пересборки
/// приложения (документ settings/features). Отсутствие документа или полей
/// трактуется как выключено — обе опции по умолчанию недоступны жителям.
class FeatureFlagsModel {
  final bool paidPushEnabled;
  final bool bannerSubmissionEnabled;

  const FeatureFlagsModel({
    this.paidPushEnabled = false,
    this.bannerSubmissionEnabled = false,
  });

  factory FeatureFlagsModel.fromMap(Map<String, dynamic>? data) {
    if (data == null) return const FeatureFlagsModel();
    return FeatureFlagsModel(
      paidPushEnabled: data['paidPushEnabled'] == true,
      bannerSubmissionEnabled: data['bannerSubmissionEnabled'] == true,
    );
  }
}
