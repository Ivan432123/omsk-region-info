import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Заявка работодателя на публикацию вакансии — подаётся прямо из
/// приложения без входа/регистрации, по аналогии с заявками на баннер (см.
/// BannerRequestModel). Оплата — вручную через СБП (см. PaymentInfo),
/// администратор сверяет поступление и публикует вакансию в vacancies через
/// веб-панель. В отличие от баннеров/объявлений — фиксированная цена без
/// выбора срока (durationDays): опубликованная вакансия живёт стандартные
/// 30 дней, как и любая другая (см. VacancyRepository._maxAge), платного
/// продвижения поверх этого срока пока нет.
class VacancyRequestModel extends Equatable {
  final String id;
  final String title;
  final String company;
  final String description;
  final String? salary;
  final String phone;
  final int price;
  final String status;
  final String districtId;
  final DateTime createdAt;

  const VacancyRequestModel({
    required this.id,
    required this.title,
    required this.company,
    required this.description,
    this.salary,
    required this.phone,
    required this.price,
    this.status = 'pending',
    required this.districtId,
    required this.createdAt,
  });

  factory VacancyRequestModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return VacancyRequestModel(
      id: doc.id,
      title: data['title'] as String? ?? '',
      company: data['company'] as String? ?? '',
      description: data['description'] as String? ?? '',
      salary: data['salary'] as String?,
      phone: data['phone'] as String? ?? '',
      price: (data['price'] as num?)?.toInt() ?? 0,
      status: data['status'] as String? ?? 'pending',
      districtId: data['district'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        company,
        description,
        salary,
        phone,
        price,
        status,
        districtId,
        createdAt,
      ];
}
