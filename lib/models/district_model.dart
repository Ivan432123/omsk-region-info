import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Модель района.
/// Архитектура сразу учитывает будущее расширение:
/// - regionId позволяет в будущем масштабироваться на всю Россию
///   (сейчас единственное значение — "omsk"), без переписывания моделей.
/// - villages — задел под фильтрацию по сёлам внутри района.
class DistrictModel extends Equatable {
  final String id;
  final String name;
  final String regionId;
  final String? imageUrl;
  final List<String> villages;
  final bool isActive;
  final int order;

  const DistrictModel({
    required this.id,
    required this.name,
    this.regionId = 'omsk',
    this.imageUrl,
    this.villages = const [],
    this.isActive = true,
    this.order = 0,
  });

  factory DistrictModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return DistrictModel(
      id: doc.id,
      name: data['name'] as String? ?? '',
      regionId: data['regionId'] as String? ?? 'omsk',
      imageUrl: data['imageUrl'] as String?,
      villages: List<String>.from(data['villages'] as List? ?? []),
      isActive: data['isActive'] as bool? ?? true,
      order: data['order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'regionId': regionId,
      'imageUrl': imageUrl,
      'villages': villages,
      'isActive': isActive,
      'order': order,
    };
  }

  @override
  List<Object?> get props => [id, name, regionId, imageUrl, villages, isActive, order];
}
