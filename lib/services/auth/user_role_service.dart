import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/app_user.dart';

class UserRoleService {
  UserRoleService({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<AppUserRole> getRole(String uid) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(uid)
        .get();

    if (!snapshot.exists) {
      return AppUserRole.student;
    }

    final data = snapshot.data();

    final role = data?['role'];

    if (role == 'admin') {
      return AppUserRole.admin;
    }

    return AppUserRole.student;
  }

  Future<void> setRole({
    required String uid,
    required AppUserRole role,
  }) async {
    await _firestore.collection('users').doc(uid).set(
      {
        'role': role.name,
      },
      SetOptions(merge: true),
    );
  }
}