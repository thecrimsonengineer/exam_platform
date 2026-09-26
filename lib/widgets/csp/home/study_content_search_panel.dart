import 'dart:async';

import 'package:flutter/material.dart';

import 'package:exam_platform/theme/glass/student_glass.dart';

import '../../../services/study_content_remote_search_service.dart';
import '../../../services/study_content_search_service.dart';

class StudyContentSearchPanel extends StatefulWidget {
  final bool isDarkMode;
  final Future<void> Function(StudyContentSearchResult result) onSelected;
  final StudyContentSearchService? searchService;

  const StudyContentSearchPanel({
    super.key,
    required this.isDarkMode,
    required this.onSelected,
    this.searchService,
  });

  @override
  State<StudyContentSearchPanel> createState() =>
      _StudyContentSearchPanelState();
}

class _StudyContentSearchPanelState extends State<StudyContentSearchPanel> {
  late final StudyContentSearchService _searchService;
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  Timer? _debounce;
  List<StudyContentSearchResult> _results = const [];
  String _query = '';
  String? _error;
  bool _loading = false;
  int _requestSerial = 0;

  Color get _surface =>
      widget.isDarkMode ? const Color(0xFF111B2C) : Colors.white;
  Color get _surfaceAlt =>
      widget.isDarkMode ? const Color(0xFF162238) : const Color(0xFFF7F9FC);
  Color get _textPrimary =>
      widget.isDarkMode ? const Color(0xFFF4F7FB) : const Color(0xFF18243A);
  Color get _textMuted =>
      widget.isDarkMode ? const Color(0xFFA5B1C4) : const Color(0xFF718096);
  Color get _border =>
      widget.isDarkMode ? const Color(0xFF25344A) : const Color(0xFFE1E7F0);
  Color get _primary =>
      widget.isDarkMode ? const Color(0xFF9A7CF4) : const Color(0xFF5B36A8);
  Color get _primarySoft =>
      widget.isDarkMode ? const Color(0xFF251E45) : const Color(0xFFF0EBFA);

  @override
  void initState() {
    super.initState();
    _searchService = widget.searchService ?? RemoteStudyContentSearchService();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _focusNode
      ..removeListener(_handleFocusChange)
      ..dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (mounted) {
      setState(() {});
    }
  }

  void _onChanged(String value) {
    _debounce?.cancel();

    final query = value.trim();
    final request = ++_requestSerial;

    setState(() {
      _query = query;
      _error = null;
      _results = const [];
      _loading = query.length >= 2;
    });

    if (query.length < 2) {
      return;
    }

    _debounce = Timer(
      const Duration(milliseconds: 240),
      () => _runSearch(query, request: request),
    );
  }

  void _submit(String value) {
    _debounce?.cancel();

    final query = value.trim();

    if (query.length < 2) {
      return;
    }

    final request = ++_requestSerial;

    setState(() {
      _query = query;
      _results = const [];
      _loading = true;
      _error = null;
    });

    _runSearch(query, request: request);
  }

  Future<void> _runSearch(String query, {required int request}) async {
    try {
      final results = await _searchService.search(query, limit: 8);

      if (!mounted || request != _requestSerial || query != _query) {
        return;
      }

      setState(() {
        _results = results;
        _loading = false;
      });
    } catch (_) {
      if (!mounted || request != _requestSerial || query != _query) {
        return;
      }

      setState(() {
        _results = const [];
        _loading = false;
        _error =
            'Search content is unavailable. Check your connection and try again.';
      });
    }
  }

  Future<void> _selectResult(StudyContentSearchResult result) async {
    _focusNode.unfocus();
    await widget.onSelected(result);
  }

  void _clear() {
    _debounce?.cancel();
    _requestSerial++;
    _controller.clear();

    setState(() {
      _query = '';
      _results = const [];
      _loading = false;
      _error = null;
    });

    _focusNode.requestFocus();
  }

  void _retry() {
    _submit(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final showDropdown = _focusNode.hasFocus && _query.length >= 2;

    return StudentGlassSurface(
      key: const ValueKey('home-study-content-search'),
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      borderRadius: BorderRadius.circular(20),
      tint: _surface.withValues(alpha: widget.isDarkMode ? 0.58 : 0.50),
      borderColor: _border.withValues(alpha: 0.74),
      shadowColor: Colors.black.withValues(
        alpha: widget.isDarkMode ? 0.20 : 0.08,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _primarySoft,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  Icons.manage_search_rounded,
                  color: _primary,
                  size: 23,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SEARCH CSP11 CONTENT',
                      style: TextStyle(
                        color: _primary,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.9,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Find a concept and jump to its subtopic',
                      style: TextStyle(
                        color: _textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          TextField(
            key: const ValueKey('home-study-search-field'),
            controller: _controller,
            focusNode: _focusNode,
            textInputAction: TextInputAction.search,
            onChanged: _onChanged,
            onSubmitted: _submit,
            style: TextStyle(
              color: _textPrimary,
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: 'Search hazard, formula, process, control, topic…',
              hintStyle: TextStyle(
                color: _textMuted,
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
              ),
              prefixIcon: Icon(Icons.search_rounded, color: _primary),
              suffixIcon: _loading || _query.isNotEmpty
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_loading)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: SizedBox(
                              width: 17,
                              height: 17,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: _primary,
                              ),
                            ),
                          ),
                        if (_query.isNotEmpty)
                          IconButton(
                            key: const ValueKey('home-study-search-clear'),
                            tooltip: 'Clear search',
                            onPressed: _clear,
                            icon: Icon(Icons.close_rounded, color: _textMuted),
                          ),
                      ],
                    )
                  : null,
              suffixIconConstraints: const BoxConstraints(minHeight: 48),
              filled: true,
              fillColor: _surfaceAlt,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 15,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: _border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: _border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: _primary, width: 1.5),
              ),
            ),
          ),
          if (_query.isNotEmpty && _query.length < 2) ...[
            const SizedBox(height: 8),
            Text(
              'Type at least 2 characters to search.',
              style: TextStyle(
                color: _textMuted,
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          if (showDropdown) ...[const SizedBox(height: 10), _buildDropdown()],
        ],
      ),
    );
  }

  Widget _buildDropdown() {
    if (_loading && _results.isEmpty) {
      return _messageRow(
        icon: Icons.travel_explore_rounded,
        text: 'Searching published study content…',
      );
    }

    if (_error != null) {
      return _messageRow(
        icon: Icons.cloud_off_rounded,
        text: _error!,
        actionLabel: 'Retry',
        onAction: _retry,
      );
    }

    if (_results.isEmpty) {
      return _messageRow(
        icon: Icons.search_off_rounded,
        text: 'No matching subtopics found.',
      );
    }

    return Container(
      key: const ValueKey('home-study-search-dropdown'),
      constraints: const BoxConstraints(maxHeight: 430),
      decoration: BoxDecoration(
        color: _surfaceAlt,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _border),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 6),
        shrinkWrap: true,
        itemCount: _results.length,
        separatorBuilder: (_, _) =>
            Divider(height: 1, indent: 16, endIndent: 16, color: _border),
        itemBuilder: (context, index) {
          final result = _results[index];

          return Material(
            color: Colors.transparent,
            child: InkWell(
              key: ValueKey('home-study-search-result-${result.subtopicId}'),
              onTap: () => _selectResult(result),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _primarySoft,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(
                        Icons.menu_book_rounded,
                        color: _primary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            result.subtopicTitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: _textPrimary,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            result.breadcrumb,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: _primary,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '${result.matchSection}: ${result.snippet}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: _textMuted,
                              fontSize: 11.5,
                              height: 1.35,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(top: 7),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        color: _primary,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _messageRow({
    required IconData icon,
    required String text,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: _surfaceAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: _textMuted),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: _textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(width: 8),
            TextButton(
              key: const ValueKey('home-study-search-retry'),
              onPressed: onAction,
              child: Text(actionLabel),
            ),
          ],
        ],
      ),
    );
  }
}
