import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Партнёрский оффер в разделе "Полезное" (карты, страховки, займы и
/// т.п.) — публикуется супер-админом через веб-панель. В отличие от
/// новостей/объявлений/вакансий раздел общеплатформенный: без district,
/// виден всем жителям независимо от выбранного района.
class UsefulOfferModel extends Equatable {
  final String id;
  final String title;
  final String description;
  final String? imageUrl;
  final String targetUrl;
  final int order;
  final DateTime createdAt;

  const UsefulOfferModel({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    required this.targetUrl,
    this.order = 0,
    required this.createdAt,
  });

  factory UsefulOfferModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return UsefulOfferModel(
      id: doc.id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      imageUrl: data['imageUrl'] as String?,
      targetUrl: data['targetUrl'] as String? ?? '',
      order: (data['order'] as num?)?.toInt() ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  @override
  List<Object?> get props =>
      [id, title, description, imageUrl, targetUrl, order, createdAt];
}
