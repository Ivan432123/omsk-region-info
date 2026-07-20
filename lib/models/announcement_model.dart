import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class AnnouncementModel extends Equatable {
  final String id;
  final String title;
  final String description;
  final String? contactPhone;
  final List<String> images;
  final bool isPromoted;
  final String districtId;
  final DateTime createdAt;

  const AnnouncementModel({
    required this.id,
    required this.title,
    required this.description,
    this.contactPhone,
    this.images = const [],
    this.isPromoted = false,
    required this.districtId,
    required this.createdAt,
  });

  factory AnnouncementModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return AnnouncementModel(
      id: doc.id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      contactPhone: data['contactPhone'] as String?,
      images: List<String>.from(data['images'] as List? ?? []),
      isPromoted: data['isPromoted'] as bool? ?? false,
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
      'isPromoted': isPromoted,
      'district': districtId,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  @override
  List<Object?> get props =>
      [id, title, description, contactPhone, images, isPromoted, districtId, createdAt];
}
