import 'package:exam_platform/models/app_user.dart';
import 'package:exam_platform/services/auth/user_role_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('exact lowercase admin role is accepted', () async {
    final firestore = FakeFirebaseFirestore();
    await firestore.collection('users').doc('admin-001').set({
      'role': 'admin',
    });

    final service = UserRoleService(firestore: firestore);

    expect(await service.getRole('admin-001'), AppUserRole.admin);
  });

  test('case-variant admin role fails closed as student', () async {
    final firestore = FakeFirebaseFirestore();
    await firestore.collection('users').doc('admin-002').set({
      'role': 'Admin',
    });

    final service = UserRoleService(firestore: firestore);

    expect(await service.getRole('admin-002'), AppUserRole.student);
  });
}
