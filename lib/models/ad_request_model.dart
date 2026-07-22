import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Заявка жителя на размещение объявления — подаётся прямо из приложения
/// без входа/регистрации. Попадает на модерацию администратору района,
/// который вручную сверяет оплату (если выбрано платное продвижение push)
/// и публикует объявление через веб-панель.
class AdRequestModel extends Equatable {
  final String id;
  final String title;
  final String description;
  final String phone;
  final bool wantsPush;
  final String status;
  final String districtId;
  final DateTime createdAt;
  final List<String> images;

  const AdRequestModel({
    required this.id,
    required this.title,
    required this.description,
    required this.phone,
    this.wantsPush = false,
    this.status = 'pending',
    required this.districtId,
    required this.createdAt,
    this.images = const [],
  });

  factory AdRequestModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return AdRequestModel(
      id: doc.id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      wantsPush: data['wantsPush'] as bool? ?? false,
      status: data['status'] as String? ?? 'pending',
      districtId: data['district'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      images: (data['images'] as List?)?.whereType<String>().toList() ?? const [],
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        phone,
        wantsPush,
        status,
        districtId,
        createdAt,
        images
      ];
}
