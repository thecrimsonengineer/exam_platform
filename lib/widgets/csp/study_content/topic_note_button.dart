import 'package:flutter/material.dart';

import '../../../services/student_topic_note_service.dart';

class TopicNoteButton extends StatefulWidget {
  final String contentId;
  final String subtopicId;
  final String topicId;
  final String topicTitle;

  const TopicNoteButton({
    super.key,
    required this.contentId,
    required this.subtopicId,
    required this.topicId,
    required this.topicTitle,
  });

  @override
  State<TopicNoteButton> createState() => _TopicNoteButtonState();
}

class _TopicNoteButtonState extends State<TopicNoteButton> {
  final StudentTopicNoteService _service =
      const StudentTopicNoteService();

  bool _hasNote = false;

  Future<void> _openEditor() async {
    final existing = await _service.load(
      contentId: widget.contentId,
      subtopicId: widget.subtopicId,
      topicId: widget.topicId,
    );

    if (!mounted) {
      return;
    }

    final controller = TextEditingController(
      text: existing?.note ?? '',
    );

    final note = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MY NOTE',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const SizedBox(height: 8),
              Text(
                widget.topicTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                minLines: 4,
                maxLines: 8,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Write your note...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop(controller.text);
                  },
                  child: const Text('SAVE NOTE'),
                ),
              ),
            ],
          ),
        );
      },
    );

    controller.dispose();

    if (note == null) {
      return;
    }

    await _service.save(
      contentId: widget.contentId,
      subtopicId: widget.subtopicId,
      topicId: widget.topicId,
      topicTitle: widget.topicTitle,
      note: note,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _hasNote = note.trim().isNotEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'My note',
      onPressed: _openEditor,
      icon: Icon(
        _hasNote ? Icons.edit_note_rounded : Icons.note_add_outlined,
      ),
    );
  }
}
