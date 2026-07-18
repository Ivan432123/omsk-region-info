import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class OrganizationModel extends Equatable {
  final String id;
  final String name;
  final String category;
  final String? logoUrl;
  final List<String> gallery;
  final String description;
  final String phone;
  final String? website;
  final String address;
  final String workingHours;
  final double? latitude;
  final double? longitude;
  final double? rating;
  final int? reviewCount;
  final List<String> services;
  final String districtId;

  const OrganizationModel({
    required this.id,
    required this.name,
    required this.category,
    this.logoUrl,
    this.gallery = const [],
    required this.description,
    required this.phone,
    this.website,
    required this.address,
    required this.workingHours,
    this.latitude,
    this.longitude,
    this.rating,
    this.reviewCount,
    this.services = const [],
    required this.districtId,
  });

  factory OrganizationModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return OrganizationModel(
      id: doc.id,
      name: data['name'] as String? ?? '',
      category: data['category'] as String? ?? 'Организация',
      logoUrl: data['logoUrl'] as String?,
      gallery: List<String>.from(data['gallery'] as List? ?? []),
      description: data['description'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      website: data['website'] as String?,
      address: data['address'] as String? ?? '',
      workingHours: data['workingHours'] as String? ?? '',
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      rating: (data['rating'] as num?)?.toDouble(),
      reviewCount: (data['reviewCount'] as num?)?.toInt(),
      services: List<String>.from(data['services'] as List? ?? []),
      districtId: data['district'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'logoUrl': logoUrl,
      'gallery': gallery,
      'description': description,
      'phone': phone,
      'website': website,
      'address': address,
      'workingHours': workingHours,
      'latitude': latitude,
      'longitude': longitude,
      'rating': rating,
      'reviewCount': reviewCount,
      'services': services,
      'district': districtId,
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        category,
        logoUrl,
        gallery,
        description,
        phone,
        website,
        address,
        workingHours,
        latitude,
        longitude,
        rating,
        reviewCount,
        services,
        districtId,
      ];
}
