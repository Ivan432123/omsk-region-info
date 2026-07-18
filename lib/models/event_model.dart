import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class EventModel extends Equatable {
  final String id;
  final String title;
  final String description;
  final String? location;
  final String? imageUrl;
  final DateTime eventDate;
  final String districtId;
  final DateTime createdAt;

  const EventModel({
    required this.id,
    required this.title,
    required this.description,
    this.location,
    this.imageUrl,
    required this.eventDate,
    required this.districtId,
    required this.createdAt,
  });

  factory EventModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return EventModel(
      id: doc.id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      location: data['location'] as String?,
      imageUrl: data['image'] as String?,
      eventDate: (data['eventDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      districtId: data['district'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'location': location,
      'image': imageUrl,
      'eventDate': Timestamp.fromDate(eventDate),
      'district': districtId,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        location,
        imageUrl,
        eventDate,
        districtId,
        createdAt,
      ];
}
