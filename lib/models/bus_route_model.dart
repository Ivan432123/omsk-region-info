import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Маршрут автобуса с расписанием. Справочные данные, как districts/
/// organizations — публикуются администратором вручную через веб-панель
/// или Firebase Console, в приложении только читаются.
class BusRouteModel extends Equatable {
  final String id;
  final String routeNumber;
  final String routeName;
  final List<String> stops;
  final List<String> departureTimes;
  final String? notes;
  final String districtId;
  final int order;

  const BusRouteModel({
    required this.id,
    required this.routeNumber,
    required this.routeName,
    this.stops = const [],
    this.departureTimes = const [],
    this.notes,
    required this.districtId,
    this.order = 0,
  });

  factory BusRouteModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return BusRouteModel(
      id: doc.id,
      routeNumber: data['routeNumber'] as String? ?? '',
      routeName: data['routeName'] as String? ?? '',
      stops: List<String>.from(data['stops'] as List? ?? []),
      departureTimes: List<String>.from(data['departureTimes'] as List? ?? []),
      notes: data['notes'] as String?,
      districtId: data['district'] as String? ?? '',
      order: (data['order'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'routeNumber': routeNumber,
      'routeName': routeName,
      'stops': stops,
      'departureTimes': departureTimes,
      'notes': notes,
      'district': districtId,
      'order': order,
    };
  }

  @override
  List<Object?> get props => [
        id,
        routeNumber,
        routeName,
        stops,
        departureTimes,
        notes,
        districtId,
        order,
      ];
}
