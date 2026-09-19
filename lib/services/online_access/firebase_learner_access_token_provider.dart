import 'package:firebase_auth/firebase_auth.dart';

import 'learner_online_access_gate.dart';

class FirebaseLearnerAccessTokenProvider implements LearnerAccessTokenProvider {
  FirebaseLearnerAccessTokenProvider({FirebaseAuth? firebaseAuth})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseAuth _firebaseAuth;

  @override
  Future<String?> currentToken({bool forceRefresh = false}) {
    return _firebaseAuth.currentUser?.getIdToken(forceRefresh) ??
        Future<String?>.value();
  }
}
