import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../../../models/study_content.dart';
import '../../../services/studio/studio_ultra_hard_question_publish_service.dart';
import '../../../services/ultra_hard_question_contract.dart';

class StudioUltraHardQuestionJsonDialog extends StatefulWidget {
  const StudioUltraHardQuestionJsonDialog({
    super.key,
    required this.content,
    required this.bulkService,
  });

  final StudyContent content;
  final StudioUltraHardQuestionPublishService bulkService;

  @override
  State<StudioUltraHardQuestionJsonDialog> createState() =>
      _StudioUltraHardQuestionJsonDialogState();
}

class _StudioUltraHardQuestionJsonDialogState
    extends State<StudioUltraHardQuestionJsonDialog> {
  StudioUltraHardQuestionPlan? _plan;
  String? _fileName;
  String? _error;
  bool _busy = false;

  Future<void> _selectFile() async {
    setState(() {
      _busy = true;
      _error = null;
      _plan = null;
    });

    try {
      const group = XTypeGroup(
        label: 'CSP11 Ultra Hard DQG300 JSON',
        extensions: ['json'],
      );

      final file = await openFile(acceptedTypeGroups: [group]);

      if (file == null) {
        if (mounted) {
          setState(() => _busy = false);
        }
        return;
      }

      final text = await file.readAsString();
      final plan = widget.bulkService.prepareFromJsonText(
        input: text,
        content: widget.content,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _fileName = file.name;
        _plan = plan;
        _busy = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _busy = false;
        _error = error
            .toString()
            .replaceFirst('FormatException: ', '')
            .replaceFirst('Bad state: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final plan = _plan;
    final coverage = plan?.questionCountBySubtopic.entries.toList()
      ?..sort((a, b) => a.key.compareTo(b.key));

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.workspace_premium_rounded),
          SizedBox(width: 10),
          Expanded(child: Text('Ultra Hard • DQG300 Bulk Import')),
        ],
      ),
      content: SizedBox(
        width: 920,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This is the separate Ultra Hard importer. It does not use the '
                'legacy H0.3 bulk gate. Every question must include complete '
                'dqg300Evidence and must pass exactly 300/300 with DQS 100 '
                'before publication is enabled.',
              ),
              const SizedBox(height: 14),
              Container(
                key: const ValueKey('ultra-hard-validator-banner'),
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF24124D),
                      Color(0xFF49206E),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Color(0xFFB99CFF),
                    width: 0.8,
                  ),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      UltraHardQuestionContract.validatorLabel,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'No override, warning allowance, score rounding, or '
                      'reduced-quality publication path is accepted.',
                      style: TextStyle(color: Color(0xFFD9CCFF)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Competency: ${widget.content.competencyId} • '
                '${widget.content.title}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  FilledButton.icon(
                    key: const ValueKey('ultra-hard-choose-json'),
                    onPressed: _busy ? null : _selectFile,
                    icon: const Icon(Icons.upload_file_rounded),
                    label: Text(_busy ? 'Validating...' : 'Choose Ultra Hard JSON'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _fileName ?? 'No file selected',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _error!,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
              if (plan != null) ...[
                const SizedBox(height: 18),
                Container(
                  key: const ValueKey('ultra-hard-pass-summary'),
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.green.withValues(alpha: 0.28),
                    ),
                  ),
                  child: Text(
                    '${plan.questionCount} Ultra Hard questions passed '
                    '300/300 with DQS 100. '
                    '${plan.subtopicCount} Subtopics meet the 5-question '
                    'coverage gate.',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Validated coverage',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 260,
                  child: ListView.separated(
                    itemCount: coverage?.length ?? 0,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final entry = coverage![index];
                      return ListTile(
                        dense: true,
                        leading: const Icon(
                          Icons.verified_rounded,
                          color: Colors.green,
                          size: 18,
                        ),
                        title: Text(entry.key),
                        trailing: Text(
                          '${entry.value} validated',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          key: const ValueKey('ultra-hard-continue'),
          onPressed: plan == null || _busy
              ? null
              : () => Navigator.of(context).pop(plan),
          icon: const Icon(Icons.verified_user_rounded),
          label: const Text('Continue with 300/300 Set'),
        ),
      ],
    );
  }
}
