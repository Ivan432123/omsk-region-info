import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';
import '../models/organization_model.dart';
import '../services/firestore_service.dart';

class OrganizationRepository {
  final FirestoreService _firestoreService;

  OrganizationRepository({FirestoreService? firestoreService})
      : _firestoreService = firestoreService ?? FirestoreService();

  Future<({List<OrganizationModel> items, DocumentSnapshot<Map<String, dynamic>>? lastDoc})>
      getOrganizationsPage({
    required String districtId,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  }) async {
    final query = _firestoreService
        .collection(AppConstants.collectionOrganizations)
        .where('district', isEqualTo: districtId)
        .orderBy('name');

    final snapshot = await _firestoreService.fetchPage(
      query: query,
      startAfter: startAfter,
      limit: AppConstants.pageSize,
    );

    final items = snapshot.docs.map(OrganizationModel.fromFirestore).toList();
    final lastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;

    return (items: items, lastDoc: lastDoc);
  }

  Future<OrganizationModel?> getOrganizationById(String id) async {
    final doc = await _firestoreService
        .collection(AppConstants.collectionOrganizations)
        .doc(id)
        .get();

    if (!doc.exists) return null;
    return OrganizationModel.fromFirestore(
      doc as DocumentSnapshot<Map<String, dynamic>>,
    );
  }
}
