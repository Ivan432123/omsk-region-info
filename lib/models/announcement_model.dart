import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class AnnouncementModel extends Equatable {
  final String id;
  final String title;
  final String description;
  final String? contactPhone;
  final List<String> images;
  final DateTime? promotedUntil;
  final String districtId;
  final DateTime createdAt;

  const AnnouncementModel({
    required this.id,
    required this.title,
    required this.description,
    this.contactPhone,
    this.images = const [],
    this.promotedUntil,
    required this.districtId,
    required this.createdAt,
  });

  /// Объявление считается "продвигаемым" только пока не истёк срок,
  /// оплаченный жителем (см. approveAdRequest в админке — сейчас это
  /// 7 дней с момента публикации). После истечения срока объявление
  /// просто перестаёт попадать в витрину, оставаясь в общем списке на
  /// своём обычном месте по дате публикации.
  bool get isPromoted =>
      promotedUntil != null && promotedUntil!.isAfter(DateTime.now());

  factory AnnouncementModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return AnnouncementModel(
      id: doc.id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      contactPhone: data['contactPhone'] as String?,
      images: List<String>.from(data['images'] as List? ?? []),
      promotedUntil: (data['promotedUntil'] as Timestamp?)?.toDate(),
      districtId: data['district'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'contactPhone': contactPhone,
      'images': images,
      'promotedUntil': promotedUntil != null ? Timestamp.fromDate(promotedUntil!) : null,
      'district': districtId,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  @override
  List<Object?> get props =>
      [id, title, description, contactPhone, images, promotedUntil, districtId, createdAt];
}
