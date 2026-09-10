import 'package:flutter_test/flutter_test.dart';
import 'package:exam_platform/models/learner_profile.dart';

void main() {
  group('LearnerProfile', () {
    test('stores only learner profile fields and hard-codes student role', () {
      const profile = LearnerProfile(
        uid: 'uid-1',
        fullName: '  Learner One ',
        email: ' LEARNER@EXAMPLE.COM ',
        country: ' India ',
        phone: '',
        organization: 'Example Co',
        jobTitle: 'Safety Professional',
        yearsExperience: 6,
      );

      final data = profile.toFirestore();

      expect(data['uid'], 'uid-1');
      expect(data['fullName'], 'Learner One');
      expect(data['email'], 'learner@example.com');
      expect(data['country'], 'India');
      expect(data['role'], 'student');
      expect(data['phone'], isNull);
      expect(data['organization'], 'Example Co');
      expect(data['yearsExperience'], 6);
      expect(data.containsKey('password'), isFalse);
      expect(data.containsKey('otp'), isFalse);
      expect(data.containsKey('verificationToken'), isFalse);
    });
  });
}
