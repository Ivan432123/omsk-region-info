import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class NotificationModel extends Equatable {
  final String id;
    final String title;
      final String body;
        final String? relatedNewsId;
          final String category;
            final String districtId;
              final DateTime createdAt;
                final bool isRead;

                  const NotificationModel({
                      required this.id,
                          required this.title,
                              required this.body,
                                  this.relatedNewsId,
                                      required this.category,
                                          required this.districtId,
                                              required this.createdAt,
                                                  this.isRead = false,
                                                    });

                                                      factory NotificationModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
                                                          final data = doc.data() ?? {};
                                                              return NotificationModel(
                                                                    id: doc.id,
                                                                          title: data['title'] as String? ?? '',
                                                                                body: data['body'] as String? ?? '',
                                                                                      relatedNewsId: data['relatedNewsId'] as String?,
                                                                                            category: data['category'] as String? ?? 'general',
                                                                                                  districtId: data['district'] as String? ?? '',
                                                                                                        createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
                                                                                                              isRead: data['isRead'] as bool? ?? false,
                                                                                                                  );
                                                                                                                    }

                                                                                                                      NotificationModel copyWith({bool? isRead}) {
                                                                                                                          return NotificationModel(
                                                                                                                                id: id,
                                                                                                                                      title: title,
                                                                                                                                            body: body,
                                                                                                                                                  relatedNewsId: relatedNewsId,
                                                                                                                                                        category: category,
                                                                                                                                                              districtId: districtId,
                                                                                                                                                                    createdAt: createdAt,
                                                                                                                                                                          isRead: isRead ?? this.isRead,
                                                                                                                                                                              );
                                                                                                                                                                                }

                                                                                                                                                                                  @override
                                                                                                                                                                                    List<Object?> get props =>
                                                                                                                                                                                          [id, title, body, relatedNewsId, category, districtId, createdAt, isRead];
                                                                                                                                                                                          }
