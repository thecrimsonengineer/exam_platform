import 'package:flutter/material.dart';

import '../../../models/content_mapping_candidate.dart';
import '../../../models/source_extraction_result.dart';
import '../../../models/source_structure_node.dart';
import '../../../services/source_upload_service.dart';
import '../../../services/study_content/intelligent_content_pipeline_service.dart';

class IntelligentSourceImportScreen extends StatefulWidget {
  const IntelligentSourceImportScreen({super.key});

  @override
  State<IntelligentSourceImportScreen> createState() =>
      _IntelligentSourceImportScreenState();
}

class _IntelligentSourceImportScreenState
    extends State<IntelligentSourceImportScreen> {
  final SourceUploadService _uploadService = const SourceUploadService();

  final IntelligentContentPipelineService _pipeline =
      IntelligentContentPipelineService();

  SourceExtractionResult? _extraction;
  IntelligentContentPipelineResult? _analysis;

  ContentMappingCandidate? _selectedCandidate;
  SourceStructureNode? _selectedNode;

  bool _isUploading = false;
  bool _isAnalyzing = false;
  bool _isCreatingDraft = false;

  String? _errorMessage;

  Future<void> _selectSource() async {
    setState(() {
      _isUploading = true;
      _errorMessage = null;
      _analysis = null;
      _selectedCandidate = null;
      _selectedNode = null;
    });

    try {
      final result = await _uploadService.selectAndExtract();

      if (!mounted) return;

      if (result == null) {
        setState(() {
          _isUploading = false;
        });
        return;
      }

      if (!result.successful) {
        setState(() {
          _isUploading = false;
          _extraction = result;
          _errorMessage = result.errorMessage ?? 'Source extraction failed.';
        });
        return;
      }

      setState(() {
        _extraction = result;
        _isUploading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isUploading = false;
        _errorMessage = error.toString();
      });
    }
  }

  void _analyzeSource() {
    final extraction = _extraction;

    if (extraction == null || !extraction.successful) {
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _errorMessage = null;
      _analysis = null;
      _selectedCandidate = null;
      _selectedNode = null;
    });

    try {
      final result = _pipeline.analyzeSource(extraction: extraction);

      if (!mounted) return;

      setState(() {
        _analysis = result;
        _isAnalyzing = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isAnalyzing = false;
        _errorMessage = error.toString();
      });
    }
  }

  Future<void> _createDraft() async {
    final candidate = _selectedCandidate;
    final node = _selectedNode;

    if (candidate == null || node == null) {
      return;
    }

    setState(() {
      _isCreatingDraft = true;
      _errorMessage = null;
    });

    try {
      final draft = await _pipeline.createDraftFromCandidate(
        candidate: candidate,
        sourceNode: node,
      );

      if (!mounted) return;

      setState(() {
        _isCreatingDraft = false;
      });

      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Draft Created'),
            content: Text(
              'The intelligent source has been converted into '
              'a CSP11 draft.\n\n'
              'Status: ${draft.status.toUpperCase()}\n'
              'Version: ${draft.version}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          );
        },
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isCreatingDraft = false;
        _errorMessage = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final extraction = _extraction;
    final analysis = _analysis;

    return Scaffold(
      appBar: AppBar(title: const Text('Intelligent Source Import')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildSourceCard(extraction),
                if (extraction != null && extraction.successful) ...[
                  const SizedBox(height: 20),
                  _buildAnalyzeCard(),
                ],
                if (analysis != null) ...[
                  const SizedBox(height: 20),
                  _buildAnalysisCard(analysis),
                ],
                if (_errorMessage != null) ...[
                  const SizedBox(height: 20),
                  _buildErrorCard(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Intelligent Source',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          'Convert reference material into a CSP11 study-content draft.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }

  Widget _buildSourceCard(SourceExtractionResult? extraction) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '1. Select Reference Source',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Select a supported reference document for analysis.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            if (extraction == null)
              const Text('No source selected.')
            else
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.description_outlined),
                title: Text(
                  extraction.fileName.isEmpty
                      ? 'Reference source'
                      : extraction.fileName,
                ),
                subtitle: Text(
                  '${extraction.pageCount} page(s) • '
                  '${extraction.byteLength} bytes',
                ),
              ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _isUploading ? null : _selectSource,
              icon: _isUploading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.upload_file),
              label: Text(_isUploading ? 'Selecting...' : 'Select Source'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyzeCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '2. Analyze Source',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Identify structure and generate CSP11 mapping candidates.',
                  ),
                ],
              ),
            ),
            FilledButton.icon(
              onPressed: _isAnalyzing ? null : _analyzeSource,
              icon: _isAnalyzing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(_isAnalyzing ? 'Analyzing...' : 'Analyze Source'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisCard(IntelligentContentPipelineResult analysis) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '3. Review CSP11 Mapping',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              '${analysis.nodes.length} structural nodes • '
              '${analysis.candidates.length} mapping candidates',
            ),
            const SizedBox(height: 20),
            if (analysis.candidates.isEmpty)
              const Text('No CSP11 mapping candidates were generated.')
            else
              ...analysis.candidates.asMap().entries.map((entry) {
                final index = entry.key;
                final candidate = entry.value;

                final selected = identical(_selectedCandidate, candidate);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildCandidateCard(index + 1, candidate, selected),
                );
              }),
            if (_selectedCandidate != null) ...[
              const SizedBox(height: 20),
              _buildSelectedNodeSection(analysis),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isCreatingDraft ? null : _createDraft,
                  icon: _isCreatingDraft
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.note_add_outlined),
                  label: Text(
                    _isCreatingDraft
                        ? 'Creating Draft...'
                        : 'Create CSP11 Draft',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCandidateCard(
    int number,
    ContentMappingCandidate candidate,
    bool selected,
  ) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        final analysis = _analysis;
        if (analysis == null) return;

        final matchingNode = analysis.nodes.firstWhere(
          (node) => node.id == candidate.sourceNodeId,
          orElse: () => analysis.nodes.first,
        );

        setState(() {
          _selectedCandidate = candidate;
          _selectedNode = matchingNode;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).dividerColor,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(radius: 18, child: Text('$number')),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    candidate.domainId,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(candidate.competencyId ?? 'No competency selected'),
                  const SizedBox(height: 8),
                  Text('${(candidate.confidence * 100).round()}% confidence'),
                  if (candidate.evidenceTerms.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: candidate.evidenceTerms.map((term) {
                        return Chip(label: Text(term));
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    candidate.rationale,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (selected) const Icon(Icons.check_circle),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedNodeSection(IntelligentContentPipelineResult analysis) {
    final node = _selectedNode;

    if (node == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selected Source Content',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          if (node.title.isNotEmpty)
            Text(
              node.title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          if (node.text.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(node.text, maxLines: 8, overflow: TextOverflow.ellipsis),
          ],
          const SizedBox(height: 8),
          Text(
            'Source node: ${node.id}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _errorMessage!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
