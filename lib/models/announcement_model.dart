import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class AnnouncementModel extends Equatable {
  final String id;
  final String title;
  final String description;
  final String? contactPhone;
  final String districtId;
  final DateTime createdAt;

  const AnnouncementModel({
    required this.id,
    required this.title,
    required this.description,
    this.contactPhone,
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
      districtId: data['district'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'contactPhone': contactPhone,
      'district': districtId,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  @override
  List<Object?> get props => [id, title, description, contactPhone, districtId, createdAt];
}
