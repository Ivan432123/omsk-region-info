import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Обращение жителя в поддержку — вопросы по сотрудничеству и работе
/// приложения, пожелания. Отдельная сущность от ad_requests/vacancy_requests:
/// читает и отвечает только супер-админ (см. firestore.rules), район
/// прикладывается только для сортировки в панели, а не для модерации
/// районным админом. Ответ супер-админа доставляется push'ем на topic
/// district_feedback_{id} (см. FcmService.subscribeToFeedbackReply) — это
/// подмена districtId в уже работающем механизме sendPushNotification
/// (docs/index.html), а не адресная отправка по токену устройства.
class FeedbackModel extends Equatable {
  final String id;
  final String message;
  final String? contact;
  final String districtId;
  final String districtName;
  final String status;
  final String? reply;
  final DateTime createdAt;
  final DateTime? repliedAt;

  const FeedbackModel({
    required this.id,
    required this.message,
    this.contact,
    required this.districtId,
    required this.districtName,
    this.status = 'new',
    this.reply,
    required this.createdAt,
    this.repliedAt,
  });

  bool get isAnswered => status == 'answered' && reply != null;

  factory FeedbackModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return FeedbackModel(
      id: doc.id,
      message: data['message'] as String? ?? '',
      contact: data['contact'] as String?,
      districtId: data['district'] as String? ?? '',
      districtName: data['districtName'] as String? ?? '',
      status: data['status'] as String? ?? 'new',
      reply: data['reply'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      repliedAt: (data['repliedAt'] as Timestamp?)?.toDate(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        message,
        contact,
        districtId,
        districtName,
        status,
        reply,
        createdAt,
        repliedAt,
      ];
}
