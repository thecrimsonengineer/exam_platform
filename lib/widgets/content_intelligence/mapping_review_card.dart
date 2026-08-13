import 'package:flutter/material.dart';

import '../../models/mapping_review_item.dart';

class MappingReviewCard extends StatelessWidget {
  final MappingReviewItem item;
  final VoidCallback onAccept;
  final VoidCallback onEdit;
  final VoidCallback onReject;

  const MappingReviewCard({
    super.key,
    required this.item,
    required this.onAccept,
    required this.onEdit,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final percent = (item.confidence * 100).round();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'MAPPING REVIEW',
              style: Theme.of(context).textTheme.labelSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Confidence $percent%',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 10),
            _row('Domain', item.domainId ?? 'Not mapped'),
            _row('Competency', item.competencyId ?? 'Not mapped'),
            _row('Subtopic', item.subtopicTitle ?? 'Not proposed'),
            _row('Topic', item.topicTitle ?? 'Not proposed'),
            const SizedBox(height: 10),
            Text(item.rationale),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton(
                  onPressed: onAccept,
                  child: const Text('ACCEPT'),
                ),
                OutlinedButton(
                  onPressed: onEdit,
                  child: const Text('EDIT'),
                ),
                TextButton(
                  onPressed: onReject,
                  child: const Text('REJECT'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Text('$label: $value'),
    );
  }
}
