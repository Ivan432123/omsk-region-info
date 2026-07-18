import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class VacancyModel extends Equatable {
  final String id;
  final String title;
  final String company;
  final String description;
  final String? salary;
  final String? contactPhone;
  final String districtId;
  final DateTime createdAt;

  const VacancyModel({
    required this.id,
    required this.title,
    required this.company,
    required this.description,
    this.salary,
    this.contactPhone,
    required this.districtId,
    required this.createdAt,
  });

  factory VacancyModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return VacancyModel(
      id: doc.id,
      title: data['title'] as String? ?? '',
      company: data['company'] as String? ?? '',
      description: data['description'] as String? ?? '',
      salary: data['salary'] as String?,
      contactPhone: data['contactPhone'] as String?,
      districtId: data['district'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'company': company,
      'description': description,
      'salary': salary,
      'contactPhone': contactPhone,
      'district': districtId,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        title,
        company,
        description,
        salary,
        contactPhone,
        districtId,
        createdAt,
      ];
}
