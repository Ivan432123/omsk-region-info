import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Обращение жителя/районного админа к супер-администратору (вопросы по
/// сотрудничеству, работе приложения, пожелания). Отправляется без входа в
/// приложение, по аналогии с заявками на объявление/баннер/вакансию, но в
/// отличие от них требует обратного канала: супер-админ отвечает через
/// веб-панель, а автор должен увидеть ответ — deviceId в документе служит
/// и для показа "чьё это обращение" в веб-панели, и как адрес для
/// персонального push (тема feedback_<deviceId>, см. FcmService).
class FeedbackRequestModel extends Equatable {
  final String id;
  final String message;
  final String? phone;
  final String districtId;
  final String deviceId;
  final String status;
  final String? reply;
  final DateTime createdAt;
  final DateTime? repliedAt;

  const FeedbackRequestModel({
    required this.id,
    required this.message,
    this.phone,
    required this.districtId,
    required this.deviceId,
    this.status = 'pending',
    this.reply,
    required this.createdAt,
    this.repliedAt,
  });

  factory FeedbackRequestModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return FeedbackRequestModel(
      id: doc.id,
      message: data['message'] as String? ?? '',
      phone: data['phone'] as String?,
      districtId: data['district'] as String? ?? '',
      deviceId: data['deviceId'] as String? ?? '',
      status: data['status'] as String? ?? 'pending',
      reply: data['reply'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      repliedAt: (data['repliedAt'] as Timestamp?)?.toDate(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        message,
        phone,
        districtId,
        deviceId,
        status,
        reply,
        createdAt,
        repliedAt,
      ];
}
