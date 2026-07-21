import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Заявка рекламодателя на размещение баннера в партнёрской ленте —
/// подаётся прямо из приложения без входа/регистрации, по аналогии с
/// заявками жителей на объявления (см. AdRequestModel). Оплата — вручную
/// через СБП (см. PaymentInfo), администратор сверяет поступление и
/// публикует баннер в sponsored_content через веб-панель.
class BannerRequestModel extends Equatable {
  final String id;
  final String title;
  final String imageUrl;
  final String targetUrl;
  final String phone;
  final int durationDays;
  final int price;
  final String status;
  final String districtId;
  final DateTime createdAt;

  const BannerRequestModel({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.targetUrl,
    required this.phone,
    required this.durationDays,
    required this.price,
    this.status = 'pending',
    required this.districtId,
    required this.createdAt,
  });

  factory BannerRequestModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return BannerRequestModel(
      id: doc.id,
      title: data['title'] as String? ?? '',
      imageUrl: data['imageUrl'] as String? ?? '',
      targetUrl: data['targetUrl'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      durationDays: (data['durationDays'] as num?)?.toInt() ?? 0,
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
        imageUrl,
        targetUrl,
        phone,
        durationDays,
        price,
        status,
        districtId,
        createdAt,
      ];
}
