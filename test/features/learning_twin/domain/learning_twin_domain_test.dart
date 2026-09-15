import 'package:exam_platform/features/learning_twin/domain/learning_twin_domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = DeterministicLearningTwinDecisionService();

  LearningTwinContext context({
    LearningTwinTrigger trigger = LearningTwinTrigger.screenVisit,
    bool timedExam = false,
    bool learnerInitiated = false,
    String visitId = 'visit-1',
    String screenId = 'study-content',
    String? domainId = 'd01',
    String? competencyId = 'd01_c01',
    String? topicId = 'topic-1',
    String? subtopicId = 'subtopic-1',
  }) {
    return LearningTwinContext(
      screenId: screenId,
      visitId: visitId,
      trigger: trigger,
      isTimedExamActive: timedExam,
      learnerInitiated: learnerInitiated,
      domainId: domainId,
      competencyId: competencyId,
      topicId: topicId,
      subtopicId: subtopicId,
    );
  }

  LearningTwinMessage message({
    required String id,
    LearningTwinTrigger trigger = LearningTwinTrigger.screenVisit,
    int priority = 0,
    bool unsolicited = true,
    bool allowRepeat = false,
    String? screenId,
    String? domainId,
    String? competencyId,
    String? topicId,
    String? subtopicId,
  }) {
    return LearningTwinMessage(
      id: id,
      state: LearningTwinState.tip,
      trigger: trigger,
      body: 'Guidance for $id',
      priority: priority,
      unsolicited: unsolicited,
      allowRepeat: allowRepeat,
      screenId: screenId,
      domainId: domainId,
      competencyId: competencyId,
      topicId: topicId,
      subtopicId: subtopicId,
    );
  }

  test('message scope matching is deterministic', () {
    final scoped = message(
      id: 'scoped',
      screenId: 'study-content',
      domainId: 'd01',
      competencyId: 'd01_c01',
      topicId: 'topic-1',
      subtopicId: 'subtopic-1',
    );

    expect(scoped.matchesContext(context()), isTrue);
    expect(scoped.matchesContext(context(subtopicId: 'subtopic-2')), isFalse);
  });

  test('highest priority wins and equal priority uses stable message ID', () {
    final decision = service.decide(
      context: context(),
      candidates: <LearningTwinMessage>[
        message(id: 'z-message', priority: 50),
        message(id: 'b-message', priority: 80),
        message(id: 'a-message', priority: 80),
      ],
      sessionState: LearningTwinSessionState.empty(),
    );

    expect(decision.reason, LearningTwinDecisionReason.selected);
    expect(decision.message?.id, 'a-message');
  });

  test('active timed exam suppresses all guidance at decision layer', () {
    final decision = service.decide(
      context: context(
        trigger: LearningTwinTrigger.learnerRequestedHelp,
        timedExam: true,
        learnerInitiated: true,
      ),
      candidates: <LearningTwinMessage>[
        message(
          id: 'requested-help',
          trigger: LearningTwinTrigger.learnerRequestedHelp,
          unsolicited: false,
          priority: 100,
        ),
      ],
      sessionState: LearningTwinSessionState.empty(),
    );

    expect(decision.hasMessage, isFalse);
    expect(decision.reason, LearningTwinDecisionReason.timedExamActive);
  });

  test('dismissed messages remain suppressed', () {
    final state = LearningTwinSessionState.empty().dismiss('dismissed');

    final decision = service.decide(
      context: context(),
      candidates: <LearningTwinMessage>[message(id: 'dismissed')],
      sessionState: state,
    );

    expect(decision.hasMessage, isFalse);
  });

  test('shown message does not repeat unless repeat is explicitly allowed', () {
    final candidate = message(id: 'once');
    final shownState = LearningTwinSessionState.empty().markShown(
      message: candidate,
      context: context(),
    );

    final suppressed = service.decide(
      context: context(visitId: 'visit-2'),
      candidates: <LearningTwinMessage>[candidate],
      sessionState: shownState,
    );

    expect(suppressed.hasMessage, isFalse);

    final repeatable = message(id: 'repeatable', allowRepeat: true);
    final repeatState = LearningTwinSessionState.empty().markShown(
      message: repeatable,
      context: context(),
    );

    final allowed = service.decide(
      context: context(visitId: 'visit-2'),
      candidates: <LearningTwinMessage>[repeatable],
      sessionState: repeatState,
    );

    expect(allowed.message?.id, 'repeatable');
  });

  test('only one unsolicited intervention is allowed per screen visit', () {
    final first = message(id: 'first');
    final afterFirst = LearningTwinSessionState.empty().markShown(
      message: first,
      context: context(),
    );

    final decision = service.decide(
      context: context(),
      candidates: <LearningTwinMessage>[message(id: 'second')],
      sessionState: afterFirst,
    );

    expect(decision.hasMessage, isFalse);
  });

  test(
    'learner-requested guidance is not blocked by unsolicited visit quota',
    () {
      final first = message(id: 'first');
      final afterFirst = LearningTwinSessionState.empty().markShown(
        message: first,
        context: context(),
      );

      final requested = message(
        id: 'requested',
        trigger: LearningTwinTrigger.learnerRequestedHelp,
        unsolicited: false,
      );

      final decision = service.decide(
        context: context(
          trigger: LearningTwinTrigger.learnerRequestedHelp,
          learnerInitiated: true,
        ),
        candidates: <LearningTwinMessage>[requested],
        sessionState: afterFirst,
      );

      expect(decision.message?.id, 'requested');
    },
  );

  test('session state updates are immutable', () {
    final initial = LearningTwinSessionState.empty();
    final candidate = message(id: 'immutable');

    final shown = initial.markShown(message: candidate, context: context());
    final dismissed = shown.dismiss(candidate.id);

    expect(initial.shownMessageIds, isEmpty);
    expect(initial.dismissedMessageIds, isEmpty);
    expect(shown.shownMessageIds, contains('immutable'));
    expect(shown.dismissedMessageIds, isEmpty);
    expect(dismissed.dismissedMessageIds, contains('immutable'));
  });

  test('context mismatch produces no eligible message', () {
    final decision = service.decide(
      context: context(domainId: 'd02'),
      candidates: <LearningTwinMessage>[
        message(id: 'd01-only', domainId: 'd01'),
      ],
      sessionState: LearningTwinSessionState.empty(),
    );

    expect(decision.reason, LearningTwinDecisionReason.noEligibleMessage);
  });
}
