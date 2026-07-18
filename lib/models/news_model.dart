import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import '../core/constants/app_constants.dart';

class NewsModel extends Equatable {
  final String id;
  final String title;
  final String description;
  final String content;
  final String? imageUrl;
  final String districtId;
  final String? villageId; // задел под фильтрацию по сёлам
  final String category;
  final bool sendPush;
  final int viewCount;
  final DateTime createdAt;

  const NewsModel({
    required this.id,
    required this.title,
    required this.description,
    required this.content,
    this.imageUrl,
    required this.districtId,
    this.villageId,
    required this.category,
    required this.sendPush,
    this.viewCount = 0,
    required this.createdAt,
  });

  String get categoryLabel =>
      AppConstants.categoryLabelsRu[category] ?? 'Общее';

  bool get isPushTriggering => AppConstants.isPushTriggeringCategory(category);

  factory NewsModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return NewsModel(
      id: doc.id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      content: data['content'] as String? ?? '',
      imageUrl: data['image'] as String?,
      districtId: data['district'] as String? ?? '',
      villageId: data['village'] as String?,
      category: data['category'] as String? ?? 'general',
      sendPush: data['sendPush'] as bool? ?? false,
      viewCount: (data['viewCount'] as num?)?.toInt() ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'content': content,
      'image': imageUrl,
      'district': districtId,
      'village': villageId,
      'category': category,
      // sendPush фактически проставляется сервером (Cloud Function) на
      // основании категории — см. README, раздел "Логика push-уведомлений".
      'sendPush': sendPush,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        content,
        imageUrl,
        districtId,
        villageId,
        category,
        sendPush,
        viewCount,
        createdAt,
      ];
}
