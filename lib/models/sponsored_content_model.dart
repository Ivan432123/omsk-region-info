import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Партнёрский (спонсорский) баннер — карточка в рекламной ленте на
/// главном экране. Публикуется администратором вручную (см. TASKS.md,
/// партия 3.4) через веб-панель или Firebase Console; в приложении только
/// читается.
class SponsoredContentModel extends Equatable {
  final String id;
  final String title;
  final String imageUrl;
  final String targetUrl;
  final String? organizationId;
  final DateTime activeUntil;
  final int order;
  final String districtId;
  final int clickCount;

  const SponsoredContentModel({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.targetUrl,
    this.organizationId,
    required this.activeUntil,
    this.order = 0,
    required this.districtId,
    this.clickCount = 0,
  });

  factory SponsoredContentModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return SponsoredContentModel(
      id: doc.id,
      title: data['title'] as String? ?? '',
      imageUrl: data['imageUrl'] as String? ?? '',
      targetUrl: data['targetUrl'] as String? ?? '',
      organizationId: data['organizationId'] as String?,
      activeUntil:
          (data['activeUntil'] as Timestamp?)?.toDate() ?? DateTime.now(),
      order: (data['order'] as num?)?.toInt() ?? 0,
      districtId: data['district'] as String? ?? '',
      clickCount: (data['clickCount'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        imageUrl,
        targetUrl,
        organizationId,
        activeUntil,
        order,
        districtId,
        clickCount,
      ];
}
