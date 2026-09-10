import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/learner_profile.dart';

class LearnerProfileService {
  LearnerProfileService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<void> createProfile(LearnerProfile profile) async {
    await _firestore.collection('users').doc(profile.uid).set({
      ...profile.toFirestore(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
