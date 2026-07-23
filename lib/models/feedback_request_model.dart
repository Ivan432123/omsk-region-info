import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Одно сообщение в переписке по обращению — либо от жителя, либо от
/// супер-администратора. createdAt проставляет клиент (Firestore не умеет
/// serverTimestamp() внутри элементов массива — он резолвится в null), но
/// это не критично: единственное следствие — порядок/время сообщений
/// доверяет часам отправителя, а не серверу. Для сортировки/бейджей самих
/// обращений в списках (админка, "непрочитано") используется поле верхнего
/// уровня FeedbackRequestModel.updatedAt — оно обычный serverTimestamp().
class FeedbackMessage extends Equatable {
  final String sender; // 'resident' | 'admin'
  final String text;
  final DateTime createdAt;

  const FeedbackMessage({
    required this.sender,
    required this.text,
    required this.createdAt,
  });

  bool get isFromAdmin => sender == 'admin';

  factory FeedbackMessage.fromMap(Map<String, dynamic> map) {
    final rawCreatedAt = map['createdAt'];
    return FeedbackMessage(
      sender: map['sender'] as String? ?? 'resident',
      text: map['text'] as String? ?? '',
      createdAt: rawCreatedAt is Timestamp
          ? rawCreatedAt.toDate()
          : (rawCreatedAt is DateTime ? rawCreatedAt : DateTime.now()),
    );
  }

  Map<String, dynamic> toMap() => {
        'sender': sender,
        'text': text,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  @override
  List<Object?> get props => [sender, text, createdAt];
}

/// Обращение жителя/районного админа к супер-администратору (вопросы по
/// сотрудничеству, работе приложения, пожелания). Отправляется без входа в
/// приложение, по аналогии с заявками на объявление/баннер/вакансию, но в
/// отличие от них — это чат: после ответа супер-админа житель может писать
/// дальше по тому же обращению, а не только один раз получить ответ.
/// deviceId в документе служит и для показа "чьё это обращение" в веб-
/// панели, и как адрес для персонального push (тема feedback_<deviceId>,
/// см. FcmService).
class FeedbackRequestModel extends Equatable {
  final String id;
  final String? phone;
  final String districtId;
  final String deviceId;
  final String status;
  final List<FeedbackMessage> messages;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const FeedbackRequestModel({
    required this.id,
    this.phone,
    required this.districtId,
    required this.deviceId,
    this.status = 'pending',
    this.messages = const [],
    required this.createdAt,
    this.updatedAt,
  });

  /// Первое сообщение треда — то, с которым житель обратился изначально.
  /// Используется там, где раньше читалось плоское поле message (превью в
  /// списках, офлайн-фолбэк).
  String get firstMessage => messages.isEmpty ? '' : messages.first.text;

  bool get isAnswered =>
      status == 'answered' && messages.any((m) => m.isFromAdmin);

  factory FeedbackRequestModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return FeedbackRequestModel.fromMap(doc.id, data);
  }

  factory FeedbackRequestModel.fromMap(String id, Map<String, dynamic> data) {
    final rawMessages = data['messages'];
    List<FeedbackMessage> messages;
    if (rawMessages is List) {
      messages = rawMessages
          .whereType<Map>()
          .map((m) => FeedbackMessage.fromMap(Map<String, dynamic>.from(m)))
          .toList();
    } else {
      // Документ старого формата (до введения чата) — синтезируем
      // messages из плоских полей message/reply, чтобы не понадобилась
      // миграция данных в Firestore.
      final createdAt =
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
      messages = [
        FeedbackMessage(
          sender: 'resident',
          text: data['message'] as String? ?? '',
          createdAt: createdAt,
        ),
        if (data['reply'] != null)
          FeedbackMessage(
            sender: 'admin',
            text: data['reply'] as String,
            createdAt:
                (data['repliedAt'] as Timestamp?)?.toDate() ?? createdAt,
          ),
      ];
    }

    return FeedbackRequestModel(
      id: id,
      phone: data['phone'] as String?,
      districtId: data['district'] as String? ?? '',
      deviceId: data['deviceId'] as String? ?? '',
      status: data['status'] as String? ?? 'pending',
      messages: messages,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        phone,
        districtId,
        deviceId,
        status,
        messages,
        createdAt,
        updatedAt,
      ];
}
