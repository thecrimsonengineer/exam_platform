import 'package:flutter/material.dart';

import '../../../services/student_topic_bookmark_service.dart';

class TopicBookmarkButton extends StatefulWidget {
  final String contentId;
  final String subtopicId;
  final String topicId;
  final String topicTitle;

  const TopicBookmarkButton({
    super.key,
    required this.contentId,
    required this.subtopicId,
    required this.topicId,
    required this.topicTitle,
  });

  @override
  State<TopicBookmarkButton> createState() =>
      _TopicBookmarkButtonState();
}

class _TopicBookmarkButtonState extends State<TopicBookmarkButton> {
  final StudentTopicBookmarkService _service =
      const StudentTopicBookmarkService();

  bool _loading = true;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final saved = await _service.isBookmarked(
      contentId: widget.contentId,
      subtopicId: widget.subtopicId,
      topicId: widget.topicId,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _saved = saved;
      _loading = false;
    });
  }

  Future<void> _toggle() async {
    if (_loading) {
      return;
    }

    if (_saved) {
      await _service.remove(
        contentId: widget.contentId,
        subtopicId: widget.subtopicId,
        topicId: widget.topicId,
      );
    } else {
      await _service.save(
        contentId: widget.contentId,
        subtopicId: widget.subtopicId,
        topicId: widget.topicId,
        topicTitle: widget.topicTitle,
      );
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _saved = !_saved;
    });
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: _saved ? 'Remove bookmark' : 'Bookmark topic',
      onPressed: _loading ? null : _toggle,
      icon: Icon(
        _saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
      ),
    );
  }
}
