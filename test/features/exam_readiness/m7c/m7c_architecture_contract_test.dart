import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('M7C architecture and anti-backdoor contract', () {
    late String service;
    late String model;
    late String screen;
    late String planScreen;

    setUpAll(() {
      service = File(
        'lib/features/exam_readiness/services/readiness_profile_service.dart',
      ).readAsStringSync();
      model = File(
        'lib/features/exam_readiness/models/competency_readiness_profile.dart',
      ).readAsStringSync();
      screen = File(
        'lib/features/exam_readiness/screens/readiness_profile_screen.dart',
      ).readAsStringSync();
      planScreen = File(
        'lib/features/exam_readiness/screens/exam_readiness_plan_screen.dart',
      ).readAsStringSync();
    });

    test('M7C service contains no DailyStudyPlan implementation', () {
      expect(service, isNot(contains('DailyStudyPlan')));
    });

    test('M7C service contains no LearningPriorityEngine implementation', () {
      expect(service, isNot(contains('LearningPriorityEngine')));
    });

    test('M7C service contains no pass probability language', () {
      expect(service.toLowerCase(), isNot(contains('pass probability')));
    });

    test('M7C model exposes no numeric overall readiness field', () {
      expect(model, isNot(contains('overallReadiness')));
      expect(model, isNot(contains('readinessIndex')));
    });

    test('dashboard contract explicitly disables composite index', () {
      expect(model, contains('hasCompositeReadinessIndex => false'));
    });

    test('M7C screen explicitly explains no single readiness percentage', () {
      expect(screen, contains('single exam-readiness percentage'));
    });

    test('M7C screen does not claim exam pass prediction', () {
      expect(screen, contains('predict whether you will pass the exam'));
    });

    test('knowledge dimension remains nullable', () {
      expect(model, contains('final double? value'));
    });

    test('retention remains a separate readiness dimension', () {
      expect(model, contains('final ReadinessDimension retention'));
    });

    test('application remains a separate readiness dimension', () {
      expect(model, contains('final ReadinessDimension applicationAbility'));
    });

    test('Ultra Hard remains separate inside difficulty profile', () {
      expect(model, contains('final double? ultraHardAccuracy'));
    });

    test('readiness gaps use structured reason codes', () {
      expect(model, contains('final String reasonCode'));
      expect(service, contains('APPLICATION_EVIDENCE_MISSING'));
      expect(service, contains('RETENTION_EVIDENCE_MISSING'));
    });

    test('readiness state includes insufficient evidence separately', () {
      expect(model, contains('insufficientEvidence'));
    });

    test('readiness state includes at risk separately', () {
      expect(model, contains('atRisk'));
    });

    test('readiness state includes stale separately', () {
      expect(model, contains('stale'));
    });

    test('exam plan links to readiness profile screen', () {
      expect(planScreen, contains('ReadinessProfileScreen'));
      expect(planScreen, contains('m7c-open-readiness-profile'));
    });

    test('M7C screen exposes competency matrix', () {
      expect(screen, contains('m7c-competency-matrix'));
    });

    test('M7C screen exposes limitations card', () {
      expect(screen, contains('m7c-limitations-card'));
    });
  });
}
