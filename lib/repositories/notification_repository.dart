import '../core/constants/app_constants.dart';
import '../models/notification_model.dart';
import '../services/firestore_service.dart';

class NotificationRepository {
  final FirestoreService _firestoreService;

  NotificationRepository({FirestoreService? firestoreService})
      : _firestoreService = firestoreService ?? FirestoreService();

  Stream<List<NotificationModel>> watchNotifications(String districtId) {
    return _firestoreService
        .collection(AppConstants.collectionNotifications)
        .where('district', isEqualTo: districtId)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snap) => snap.docs.map(NotificationModel.fromFirestore).toList());
  }

  Future<void> markAsRead(String notificationId) async {
    await _firestoreService
        .collection(AppConstants.collectionNotifications)
        .doc(notificationId)
        .update({'isRead': true});
  }

  Future<int> getUnreadCount(String districtId) async {
    final snapshot = await _firestoreService
        .collection(AppConstants.collectionNotifications)
        .where('district', isEqualTo: districtId)
        .where('isRead', isEqualTo: false)
        .count()
        .get();
    return snapshot.count ?? 0;
  }
}
