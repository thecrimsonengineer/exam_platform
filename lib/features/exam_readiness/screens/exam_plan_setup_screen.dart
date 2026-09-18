import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../services/auth/learner_local_identity.dart';
import '../models/exam_study_plan.dart';
import '../models/study_capacity_snapshot.dart';
import '../repositories/exam_study_plan_repository.dart';
import '../services/exam_study_capacity_service.dart';

class ExamPlanSetupScreen extends StatefulWidget {
  const ExamPlanSetupScreen({
    super.key,
    this.repository,
    this.initialPlan,
    this.now,
  });

  final ExamStudyPlanRepository? repository;
  final ExamStudyPlan? initialPlan;
  final DateTime Function()? now;

  @override
  State<ExamPlanSetupScreen> createState() => _ExamPlanSetupScreenState();
}

class _ExamPlanSetupScreenState extends State<ExamPlanSetupScreen> {
  static const _capacityService = ExamStudyCapacityService();

  late DateTime _examDate;
  late Set<int> _studyDays;
  late int _minutesPerDay;
  late TextEditingController _customMinutesController;
  bool _saving = false;
  String? _error;

  ExamStudyPlanRepository get _repository =>
      widget.repository ?? ExamStudyPlanRepository();

  DateTime get _now => widget.now?.call() ?? DateTime.now();

  @override
  void initState() {
    super.initState();
    final existing = widget.initialPlan;
    final today = ExamStudyPlan.dateOnly(_now);
    _examDate = existing?.examDate ?? today.add(const Duration(days: 90));
    _studyDays = Set<int>.from(
      existing?.studyDaysOfWeek ??
          const {
            DateTime.monday,
            DateTime.tuesday,
            DateTime.wednesday,
            DateTime.friday,
            DateTime.saturday,
          },
    );
    _minutesPerDay = existing?.defaultMinutesPerStudyDay ?? 60;
    _customMinutesController = TextEditingController(
      text: _minutesPerDay.toString(),
    );
  }

  @override
  void dispose() {
    _customMinutesController.dispose();
    super.dispose();
  }

  Future<void> _pickExamDate() async {
    final today = ExamStudyPlan.dateOnly(_now);
    final selected = await showDatePicker(
      context: context,
      initialDate: _examDate.isBefore(today) ? today : _examDate,
      firstDate: today,
      lastDate: today.add(const Duration(days: 730)),
      helpText: 'Select CSP exam date',
    );

    if (selected != null && mounted) {
      setState(() => _examDate = selected);
    }
  }

  ExamStudyPlan _draftPlan() {
    final existing = widget.initialPlan;
    final now = _now;
    final userId =
        existing?.userId ?? LearnerLocalIdentity.requireCurrentUserId();

    if (existing != null) {
      return existing.nextVersion(
        updatedAt: now,
        examDate: _examDate,
        studyDaysOfWeek: _studyDays,
        defaultMinutesPerStudyDay: _minutesPerDay,
        maxDailyMinutes: math.max(existing.maxDailyMinutes, _minutesPerDay),
      );
    }

    return ExamStudyPlan.create(
      id: 'exam-plan-${now.microsecondsSinceEpoch}',
      userId: userId,
      examDate: _examDate,
      studyDaysOfWeek: _studyDays,
      defaultMinutesPerStudyDay: _minutesPerDay,
      maxDailyMinutes: math.max(240, _minutesPerDay),
      now: now,
    );
  }

  Future<void> _save() async {
    if (_studyDays.isEmpty) {
      setState(() => _error = 'Select at least one study day.');
      return;
    }

    final declaredMinutes = int.tryParse(_customMinutesController.text.trim());
    if (declaredMinutes == null ||
        declaredMinutes <= 0 ||
        declaredMinutes > 1440) {
      setState(
        () => _error = 'Daily study time must be between 1 and 1440 minutes.',
      );
      return;
    }
    _minutesPerDay = declaredMinutes;

    final plan = _draftPlan();
    final today = ExamStudyPlan.dateOnly(_now);
    if (!plan.examDate.isAfter(today)) {
      setState(() => _error = 'Choose an exam date after today.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await _repository.savePlan(plan, syncRemote: false);
      if (!mounted) return;
      Navigator.of(context).pop(plan);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = error.toString().replaceFirst('Bad state: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final plan = _draftPlan();
    final snapshot = _capacityService.calculate(plan: plan, now: _now);

    return Scaffold(
      appBar: AppBar(title: const Text('Exam Readiness Plan')),
      body: SafeArea(
        child: ListView(
          key: const ValueKey('m7a-setup-list'),
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
          children: [
            Text(
              'Build a realistic study-capacity plan',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'CSP11 will use your actual exam date, selected study days and '
              'available minutes. Readiness scoring is deliberately not part '
              'of M7A.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 24),
            _PlanCard(
              key: const ValueKey('m7a-exam-date-card'),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event_rounded),
                title: const Text('CSP exam date'),
                subtitle: Text(_formatDate(_examDate)),
                trailing: FilledButton.tonal(
                  key: const ValueKey('m7a-change-exam-date'),
                  onPressed: _saving ? null : _pickExamDate,
                  child: const Text('Change'),
                ),
              ),
            ),
            const SizedBox(height: 14),
            _PlanCard(
              key: const ValueKey('m7a-study-days-card'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Study days',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (var weekday = 1; weekday <= 7; weekday++)
                        FilterChip(
                          key: ValueKey('m7a-weekday-$weekday'),
                          label: Text(_weekdayLabel(weekday)),
                          selected: _studyDays.contains(weekday),
                          onSelected: _saving
                              ? null
                              : (selected) {
                                  setState(() {
                                    if (selected) {
                                      _studyDays.add(weekday);
                                    } else {
                                      _studyDays.remove(weekday);
                                    }
                                  });
                                },
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _PlanCard(
              key: const ValueKey('m7a-minutes-card'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Available time per study day',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [30, 45, 60, 90, 120, 180, 240]
                        .map(
                          (minutes) => ChoiceChip(
                            key: ValueKey('m7a-minutes-$minutes'),
                            label: Text('$minutes min'),
                            selected: _minutesPerDay == minutes,
                            onSelected: _saving
                                ? null
                                : (_) {
                                    setState(() {
                                      _minutesPerDay = minutes;
                                      _customMinutesController.text = minutes
                                          .toString();
                                    });
                                  },
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    key: const ValueKey('m7a-custom-minutes'),
                    controller: _customMinutesController,
                    enabled: !_saving,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Custom daily capacity',
                      hintText: 'Enter minutes',
                      suffixText: 'min',
                      helperText:
                          '120 minutes is a common choice, not a limit. '
                          'You can declare more time if you genuinely have it.',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      final minutes = int.tryParse(value);
                      if (minutes == null || minutes <= 0 || minutes > 1440) {
                        return;
                      }
                      setState(() => _minutesPerDay = minutes);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _CapacityPreview(snapshot: snapshot),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                key: const ValueKey('m7a-plan-error'),
                style: TextStyle(
                  color: scheme.error,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton.icon(
              key: const ValueKey('m7a-save-plan'),
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_circle_rounded),
              label: Text(_saving ? 'Saving...' : 'Create study plan'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _weekdayLabel(int weekday) {
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return labels[weekday - 1];
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: child,
    );
  }
}

class _CapacityPreview extends StatelessWidget {
  const _CapacityPreview({required this.snapshot});

  final StudyCapacitySnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      key: const ValueKey('m7a-capacity-preview'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scheme.primaryContainer, scheme.secondaryContainer],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'YOUR STUDY CAPACITY',
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 24,
            runSpacing: 16,
            children: [
              _Metric(
                value: '${snapshot.calendarDaysRemaining}',
                label: 'days remaining',
              ),
              _Metric(
                value: '${snapshot.plannedStudyDaysRemaining}',
                label: 'study days',
              ),
              _Metric(
                value: snapshot.plannedHoursRemaining.toStringAsFixed(1),
                label: 'study hours',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${snapshot.studyDaysThisWeek} study days and '
            '${snapshot.minutesThisWeek} minutes are planned for the current week.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 92,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(label, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
