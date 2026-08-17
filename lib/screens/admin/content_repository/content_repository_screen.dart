import 'package:flutter/material.dart';

import '../../../data/csp11_blueprint.dart';
import '../../../models/content_repository.dart';
import '../../../services/study_content/content_repository_service.dart';
import '../../../theme/study/study_colors.dart';
import '../../../theme/study/study_radius.dart';
import '../../../theme/study/study_shadows.dart';
import '../../../theme/study/study_typography.dart';
import '../study_content/study_content_studio_screen.dart';
import 'repository_detail_screen.dart';
import 'repository_history_screen.dart';

class ContentRepositoryScreen extends StatefulWidget {
  const ContentRepositoryScreen({super.key});

  @override
  State<ContentRepositoryScreen> createState() =>
      _ContentRepositoryScreenState();
}

class _ContentRepositoryScreenState extends State<ContentRepositoryScreen> {
  final ContentRepositoryService _service = ContentRepositoryService();
  final TextEditingController _searchController = TextEditingController();

  List<ContentPackageSummary> _packages = <ContentPackageSummary>[];
  bool _loading = true;
  String _statusFilter = 'ALL';
  int? _domainFilter;
  String? _competencyFilter;
  bool _latestOnly = false;
  ContentPackageSummary? _selected;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_refreshView);
    _load();
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_refreshView)
      ..dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    try {
      final packages = await _service.loadPackages();

      if (!mounted) return;

      setState(() {
        _packages = packages;
        _loading = false;
        _selected = _selected == null
            ? null
            : _findById(_selected!.content.id, packages);
      });
    } catch (error) {
      if (!mounted) return;

      setState(() => _loading = false);
      _showMessage('Unable to load the Content Repository.\n$error');
    }
  }

  ContentPackageSummary? _findById(
    String id,
    List<ContentPackageSummary> packages,
  ) {
    for (final package in packages) {
      if (package.content.id == id) return package;
    }

    return null;
  }

  void _refreshView() {
    if (mounted) setState(() {});
  }

  List<ContentPackageSummary> get _filteredPackages {
    final query = _searchController.text.trim().toLowerCase();

    final filtered = _packages.where((package) {
      final content = package.content;
      final domain = domainForContentId(content.domainId);

      if (_domainFilter != null && domain?.number != _domainFilter) {
        return false;
      }

      if (_statusFilter != 'ALL' &&
          content.status.toUpperCase() != _statusFilter) {
        return false;
      }

      if (_competencyFilter != null &&
          content.competencyId != _competencyFilter) {
        return false;
      }

      if (query.isNotEmpty) {
        final haystack = [
          content.id,
          content.domainId,
          content.competencyId,
          content.competencyNumber.toString(),
          content.title,
          content.version.toString(),
          'v${content.version}',
        ].join(' ').toLowerCase();

        if (!haystack.contains(query)) return false;
      }

      return true;
    }).toList();

    if (!_latestOnly) return filtered;

    final latestByCompetency = <String, ContentPackageSummary>{};

    for (final package in filtered) {
      final key = package.content.competencyId;
      final current = latestByCompetency[key];

      if (current == null ||
          package.content.version > current.content.version) {
        latestByCompetency[key] = package;
      }
    }

    return latestByCompetency.values.toList()..sort(_comparePackages);
  }

  List<ContentPackageSummary> _packagesForDomain(int domainNumber) {
    return _packages
        .where(
          (package) =>
              domainForContentId(package.content.domainId)?.number ==
              domainNumber,
        )
        .toList();
  }

  List<String> get _competencyIds {
    final values = _packages
        .where((package) {
          if (_domainFilter == null) return true;

          return domainForContentId(package.content.domainId)?.number ==
              _domainFilter;
        })
        .map((package) => package.content.competencyId)
        .where((id) => id.trim().isNotEmpty)
        .toSet()
        .toList();

    values.sort();

    return values;
  }

  int _comparePackages(ContentPackageSummary a, ContentPackageSummary b) {
    final domainA = domainForContentId(a.content.domainId)?.number ?? 999;
    final domainB = domainForContentId(b.content.domainId)?.number ?? 999;

    final domainCompare = domainA.compareTo(domainB);

    if (domainCompare != 0) return domainCompare;

    final competencyCompare = a.content.competencyNumber.compareTo(
      b.content.competencyNumber,
    );

    if (competencyCompare != 0) return competencyCompare;

    return b.content.version.compareTo(a.content.version);
  }

  int get _domainCountWithContent {
    return csp11Domains
        .where((domain) => _packagesForDomain(domain.number).isNotEmpty)
        .length;
  }

  int get _publishedCount =>
      _packages.where((p) => p.status == 'published').length;

  int get _reviewCount => _packages.where((p) => p.status == 'review').length;

  int get _draftCount => _packages.where((p) => p.status == 'draft').length;

  int get _validatedCount =>
      _packages.where((p) => p.status == 'validated').length;

  void _selectDomain(int? number) {
    setState(() {
      _domainFilter = number;
      _competencyFilter = null;
    });
  }

  void _selectPackage(ContentPackageSummary package) {
    setState(() => _selected = package);
  }

  Future<void> _openStudio(ContentPackageSummary package) async {
    final status = package.status.toLowerCase();

    if (status == 'published' || status == 'archived') {
      _showMessage(
        'Published and archived versions are read-only. '
        'Create a new revision before editing.',
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            StudyContentStudioScreen(initialContent: package.content),
      ),
    );

    await _load();
  }

  Future<void> _createRevision(ContentPackageSummary package) async {
    try {
      final revision = await _service.createRevision(package.content);

      if (!mounted) return;

      _showMessage('Revision v${revision.version} created as DRAFT.');

      await _load();

      if (!mounted) return;

      final refreshed = _findById(revision.id, _packages);

      if (refreshed != null) {
        setState(() => _selected = refreshed);
        await _openStudio(refreshed);
      }
    } catch (error) {
      _showMessage('Unable to create revision.\n$error');
    }
  }

  Future<void> _sendToReview(ContentPackageSummary package) async {
    if (package.status != 'draft') return;

    try {
      await _service.submitForReview(package.content);

      _showMessage('Content submitted to REVIEW.');

      await _load();
    } catch (error) {
      _showMessage('Unable to submit for review.\n$error');
    }
  }

  Future<void> _validate(ContentPackageSummary package) async {
    if (package.status != 'review' && package.status != 'draft') {
      return;
    }

    try {
      await _service.validateAndMark(package.content);

      _showMessage('Validation passed. Package is now VALIDATED.');

      await _load();
    } catch (error) {
      _showMessage('$error');
    }
  }

  Future<void> _publish(ContentPackageSummary package) async {
    if (package.status != 'validated') return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Publish package?'),
        content: Text(
          'Publish ${package.content.title} v${package.content.version} '
          'to the student-facing repository?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.publish_rounded),
            label: const Text('Publish'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _service.publish(package.content);

      _showMessage('Version ${package.content.version} is now PUBLISHED.');

      await _load();
    } catch (error) {
      _showMessage('Unable to publish.\n$error');
    }
  }

  Future<void> _archive(ContentPackageSummary package) async {
    if (package.status != 'published') return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archive published version?'),
        content: Text(
          'Keep v${package.content.version} in history but remove it '
          'from the active student repository?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.archive_outlined),
            label: const Text('Archive'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _service.archive(package.content);

      _showMessage('Version ${package.content.version} archived.');

      await _load();
    } catch (error) {
      _showMessage('Unable to archive.\n$error');
    }
  }

  Future<void> _deletePublishedVersion(
    ContentPackageSummary package,
  ) async {
    final status = package.status;

    if (status != 'published' && status != 'archived') return;

    final isArchived = status == 'archived';
    final actionLabel = isArchived
        ? 'Delete Permanently'
        : 'Delete Published Content';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$actionLabel?'),
        content: Text(
          isArchived
              ? 'Permanently delete ${package.content.title} v${package.content.version}? This removes the archived version from the repository and cannot be undone.'
              : 'Delete ${package.content.title} v${package.content.version} from the published repository? Students will no longer be able to access this published version. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: Icon(
              isArchived
                  ? Icons.delete_forever_rounded
                  : Icons.delete_outline_rounded,
            ),
            label: Text(actionLabel),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _service.deletePublishedVersion(package.content);

      if (_selected?.content.id == package.content.id) {
        setState(() => _selected = null);
      }

      _showMessage(
        isArchived
            ? 'Archived version deleted permanently.'
            : 'Published version deleted. It is no longer student-live.',
      );

      await _load();
    } catch (error) {
      _showMessage('Unable to delete the version.\n$error');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: StudyRadius.medium),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 1000;

    return Scaffold(
      backgroundColor: StudyColors.background,
      appBar: _buildAppBar(),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
            ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 1,
      backgroundColor: StudyColors.surface,
      foregroundColor: StudyColors.textPrimary,
      surfaceTintColor: Colors.transparent,
      titleSpacing: 20,
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Content Repository',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 2),
          Text(
            'CSP11 competency-centred content command layer',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: StudyColors.textSecondary,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Refresh repository',
          onPressed: _load,
          icon: const Icon(Icons.refresh_rounded),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Padding(
      padding: const EdgeInsets.all(22),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 258, child: _buildDomainRail()),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              children: [
                _buildMetrics(),
                const SizedBox(height: 16),
                _buildFilters(),
                const SizedBox(height: 16),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildPackageList()),
                      const SizedBox(width: 16),
                      SizedBox(width: 360, child: _buildDetailsPanel()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return ListView(
      padding: const EdgeInsets.all(14),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        _buildMetrics(),
        const SizedBox(height: 14),
        _buildDomainRail(compact: true),
        const SizedBox(height: 14),
        _buildFilters(),
        const SizedBox(height: 14),
        _buildPackageList(),
        const SizedBox(height: 14),
        _buildDetailsPanel(),
      ],
    );
  }

  Widget _buildMetrics() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _metricCard(
          label: 'DOMAINS ACTIVE',
          value: '$_domainCountWithContent / 7',
          icon: Icons.account_tree_rounded,
          color: StudyColors.primary,
        ),
        _metricCard(
          label: 'PACKAGES',
          value: '${_packages.length}',
          icon: Icons.inventory_2_rounded,
          color: StudyColors.accent,
        ),
        _metricCard(
          label: 'PUBLISHED',
          value: '$_publishedCount',
          icon: Icons.publish_rounded,
          color: StudyColors.success,
        ),
        _metricCard(
          label: 'IN REVIEW',
          value: '$_reviewCount',
          icon: Icons.rate_review_rounded,
          color: StudyColors.warning,
        ),
        _metricCard(
          label: 'VALIDATED',
          value: '$_validatedCount',
          icon: Icons.verified_rounded,
          color: StudyColors.info,
        ),
        _metricCard(
          label: 'DRAFTS',
          value: '$_draftCount',
          icon: Icons.edit_note_rounded,
          color: StudyColors.examTip,
        ),
      ],
    );
  }

  Widget _metricCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: StudyColors.surface,
        borderRadius: StudyRadius.large,
        border: Border.all(color: StudyColors.border),
        boxShadow: StudyShadows.soft,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.09),
              borderRadius: StudyRadius.small,
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: StudyTypography.eyebrow.copyWith(fontSize: 8.5),
                ),
                const SizedBox(height: 3),
                Text(value, style: StudyTypography.cardTitle),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDomainRail({bool compact = false}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: StudyColors.surface,
        borderRadius: StudyRadius.large,
        border: Border.all(color: StudyColors.border),
        boxShadow: StudyShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 5, 8, 10),
            child: Row(
              children: [
                const Icon(
                  Icons.layers_rounded,
                  size: 17,
                  color: StudyColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'CSP11 DOMAINS',
                  style: StudyTypography.eyebrow.copyWith(
                    color: StudyColors.primary,
                  ),
                ),
              ],
            ),
          ),
          if (compact)
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                _domainChip(null, 'All'),
                ...csp11Domains.map(
                  (domain) => _domainChip(domain.number, 'D${domain.number}'),
                ),
              ],
            )
          else
            Column(
              children: [
                _domainTile(null, 'All Domains', '7-domain repository'),
                const SizedBox(height: 5),
                ...csp11Domains.map(
                  (domain) => Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: _domainTile(
                      domain.number,
                      'Domain ${domain.number}',
                      domain.title,
                      weight: '${domain.weightPercent}%',
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _domainChip(int? number, String label) {
    final selected = _domainFilter == number;

    return InkWell(
      onTap: () => _selectDomain(number),
      borderRadius: StudyRadius.pillRadius,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? StudyColors.primary : StudyColors.surfaceSoft,
          borderRadius: StudyRadius.pillRadius,
          border: Border.all(
            color: selected ? StudyColors.primary : StudyColors.border,
          ),
        ),
        child: Text(
          label,
          style: StudyTypography.label.copyWith(
            color: selected ? Colors.white : StudyColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _domainTile(
    int? number,
    String title,
    String subtitle, {
    String? weight,
  }) {
    final selected = _domainFilter == number;

    final count = number == null
        ? _packages.length
        : _packagesForDomain(number).length;

    return InkWell(
      onTap: () => _selectDomain(number),
      borderRadius: StudyRadius.medium,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: selected ? StudyColors.primaryLight : Colors.transparent,
          borderRadius: StudyRadius.medium,
          border: Border.all(
            color: selected
                ? StudyColors.primary.withValues(alpha: 0.15)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? StudyColors.primary : StudyColors.surfaceSoft,
                borderRadius: StudyRadius.small,
              ),
              child: Text(
                number == null ? 'ALL' : 'D$number',
                style: TextStyle(
                  fontSize: number == null ? 8 : 10,
                  fontWeight: FontWeight.w900,
                  color: selected ? Colors.white : StudyColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: StudyTypography.label.copyWith(
                      color: selected
                          ? StudyColors.primary
                          : StudyColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: StudyTypography.caption.copyWith(fontSize: 10),
                  ),
                ],
              ),
            ),
            if (weight != null)
              Text(
                weight,
                style: StudyTypography.caption.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            const SizedBox(width: 7),
            _countBadge(count),
          ],
        ),
      ),
    );
  }

  Widget _countBadge(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: StudyColors.surfaceSoft,
        borderRadius: StudyRadius.pillRadius,
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: StudyColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildFilters() {
    final competencies = _competencyIds;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: StudyColors.surface,
        borderRadius: StudyRadius.large,
        border: Border.all(color: StudyColors.border),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 260,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Search competency, package, version, ID...',
                prefixIcon: const Icon(Icons.search_rounded, size: 19),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: _searchController.clear,
                        icon: const Icon(Icons.close_rounded, size: 18),
                      ),
                border: OutlineInputBorder(
                  borderRadius: StudyRadius.medium,
                  borderSide: BorderSide(color: StudyColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: StudyRadius.medium,
                  borderSide: BorderSide(color: StudyColors.border),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
            ),
          ),
          _filterDropdown(
            label: 'Status',
            value: _statusFilter,
            items: const [
              'ALL',
              'DRAFT',
              'REVIEW',
              'VALIDATED',
              'PUBLISHED',
              'ARCHIVED',
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _statusFilter = value);
              }
            },
          ),
          SizedBox(
            width: 190,
            child: DropdownButtonFormField<String?>(
              initialValue: _competencyFilter,
              isDense: true,
              decoration: InputDecoration(
                labelText: 'Competency',
                border: OutlineInputBorder(borderRadius: StudyRadius.medium),
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('All competencies'),
                ),
                ...competencies.map(
                  (id) => DropdownMenuItem<String?>(
                    value: id,
                    child: Text(id, overflow: TextOverflow.ellipsis),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() => _competencyFilter = value);
              },
            ),
          ),
          FilterChip(
            selected: _latestOnly,
            label: const Text('Latest version only'),
            avatar: const Icon(Icons.auto_awesome_rounded, size: 16),
            onSelected: (selected) {
              setState(() => _latestOnly = selected);
            },
          ),
          Text(
            '${_filteredPackages.length} result'
            '${_filteredPackages.length == 1 ? '' : 's'}',
            style: StudyTypography.caption.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return SizedBox(
      width: 145,
      child: DropdownButtonFormField<String>(
        initialValue: value,
        isDense: true,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: StudyRadius.medium),
        ),
        items: items
            .map(
              (item) =>
                  DropdownMenuItem<String>(value: item, child: Text(item)),
            )
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildPackageList() {
    final packages = _filteredPackages..sort(_comparePackages);

    if (packages.isEmpty) {
      return _buildEmptyState();
    }

    return Container(
      decoration: BoxDecoration(
        color: StudyColors.surface,
        borderRadius: StudyRadius.large,
        border: Border.all(color: StudyColors.border),
        boxShadow: StudyShadows.soft,
      ),
      child: ListView.separated(
        padding: const EdgeInsets.all(10),
        shrinkWrap: true,
        physics: const ClampingScrollPhysics(),
        itemCount: packages.length,
        separatorBuilder: (_, _) => const SizedBox(height: 7),
        itemBuilder: (context, index) {
          return _buildPackageCard(packages[index]);
        },
      ),
    );
  }

  Widget _buildPackageCard(ContentPackageSummary package) {
    final selected = _selected?.content.id == package.content.id;
    final domain = domainForContentId(package.content.domainId);

    return InkWell(
      onTap: () => _selectPackage(package),
      borderRadius: StudyRadius.large,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? StudyColors.primaryLight : StudyColors.surface,
          borderRadius: StudyRadius.large,
          border: Border.all(
            color: selected
                ? StudyColors.primary.withValues(alpha: 0.22)
                : StudyColors.border,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _versionBadge(package.content.version),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        domain == null
                            ? package.content.domainId
                            : 'DOMAIN ${domain.number}',
                        style: StudyTypography.eyebrow.copyWith(
                          color: StudyColors.primary,
                          fontSize: 9,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'COMP '
                        '${package.content.competencyNumber}',
                        style: StudyTypography.eyebrow.copyWith(fontSize: 9),
                      ),
                      const Spacer(),
                      _statusBadge(package.status),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    package.content.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: StudyTypography.cardTitle,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    package.content.competencyId,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: StudyTypography.caption.copyWith(
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 11),
                  Row(
                    children: [
                      _miniStat(
                        Icons.account_tree_rounded,
                        '${package.subtopicCount}',
                      ),
                      _miniStat(
                        Icons.menu_book_rounded,
                        '${package.topicCount}',
                      ),
                      _miniStat(
                        Icons.view_agenda_rounded,
                        '${package.blockCount}',
                      ),
                      _miniStat(Icons.quiz_rounded, '${package.questionCount}'),
                      const Spacer(),
                      Text(
                        '${(package.completeness * 100).round()}%'
                        ' complete',
                        style: StudyTypography.caption.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _versionBadge(int version) {
    return Container(
      width: 50,
      height: 50,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: StudyColors.primary,
        borderRadius: StudyRadius.medium,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'VER',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 8,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          Text(
            '$version.0',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(IconData icon, String value) {
    return Padding(
      padding: const EdgeInsets.only(right: 11),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: StudyColors.textMuted),
          const SizedBox(width: 4),
          Text(
            value,
            style: StudyTypography.caption.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    final upper = status.toUpperCase();
    final color = _statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: StudyRadius.pillRadius,
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Text(
        upper,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.6,
          color: color,
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'published':
        return StudyColors.success;
      case 'validated':
        return StudyColors.info;
      case 'review':
        return StudyColors.warning;
      case 'archived':
        return StudyColors.textSecondary;
      default:
        return StudyColors.examTip;
    }
  }

  Widget _buildDetailsPanel() {
    final package = _selected;

    if (package == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: StudyColors.surface,
          borderRadius: StudyRadius.large,
          border: Border.all(color: StudyColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.touch_app_rounded,
              color: StudyColors.primary,
              size: 28,
            ),
            const SizedBox(height: 12),
            Text(
              'Select a content package',
              style: StudyTypography.subSectionTitle,
            ),
            const SizedBox(height: 7),
            Text(
              'Choose a competency version from the '
              'repository to inspect its lifecycle, '
              'completeness and available actions.',
              style: StudyTypography.bodySecondary,
            ),
          ],
        ),
      );
    }

    final content = package.content;
    final domain = domainForContentId(content.domainId);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: StudyColors.surface,
        borderRadius: StudyRadius.large,
        border: Border.all(color: StudyColors.border),
        boxShadow: StudyShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'PACKAGE DETAILS',
                  style: StudyTypography.eyebrow.copyWith(
                    color: StudyColors.primary,
                  ),
                ),
              ),
              _statusBadge(package.status),
            ],
          ),
          const SizedBox(height: 10),
          Text(content.title, style: StudyTypography.sectionTitle),
          const SizedBox(height: 7),
          Text(
            domain == null
                ? content.domainId
                : 'Domain ${domain.number} • '
                      '${domain.title}',
            style: StudyTypography.bodySecondary,
          ),
          const SizedBox(height: 15),
          _detailRow('Competency ID', content.competencyId),
          _detailRow('Competency number', '${content.competencyNumber}'),
          _detailRow('Version', '${content.version}.0'),
          _detailRow('Package ID', content.id),
          const SizedBox(height: 14),
          _buildCompleteness(package),
          const SizedBox(height: 14),
          _buildLifecycle(package),
          const SizedBox(height: 16),
          _buildActions(package),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(label, style: StudyTypography.caption),
          ),
          Expanded(
            child: Text(
              value,
              style: StudyTypography.caption.copyWith(
                color: StudyColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompleteness(ContentPackageSummary package) {
    final percent = package.completeness;

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: StudyColors.surfaceSoft,
        borderRadius: StudyRadius.medium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'CONTENT COMPLETENESS',
                  style: StudyTypography.eyebrow,
                ),
              ),
              Text(
                '${(percent * 100).round()}%',
                style: StudyTypography.label.copyWith(
                  color: StudyColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: StudyRadius.pillRadius,
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 7,
              backgroundColor: StudyColors.progressTrack,
              valueColor: const AlwaysStoppedAnimation<Color>(
                StudyColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _checkPill('Subtopics', package.subtopicCount > 0),
              _checkPill('Topics', package.topicCount > 0),
              _checkPill('Blocks', package.blockCount > 0),
              _checkPill('Questions', package.questionCount > 0),
            ],
          ),
        ],
      ),
    );
  }

  Widget _checkPill(String label, bool complete) {
    final color = complete ? StudyColors.success : StudyColors.warning;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: StudyRadius.pillRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            complete
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked,
            size: 13,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLifecycle(ContentPackageSummary package) {
    final current = package.status;

    const states = <String>[
      'draft',
      'review',
      'validated',
      'published',
      'archived',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('LIFECYCLE', style: StudyTypography.eyebrow),
        const SizedBox(height: 9),
        Row(
          children: states.asMap().entries.map((entry) {
            final index = entry.key;
            final state = entry.value;
            final active = state == current;
            final reached = states.indexOf(current) >= index;

            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: index == states.length - 1 ? 0 : 3,
                ),
                child: Column(
                  children: [
                    Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: reached
                            ? _statusColor(state)
                            : StudyColors.progressTrack,
                        borderRadius: StudyRadius.pillRadius,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      active ? state.toUpperCase() : '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 7.5,
                        fontWeight: FontWeight.w900,
                        color: _statusColor(state),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildActions(ContentPackageSummary package) {
    final status = package.status;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => RepositoryDetailScreen(
                  package: package,
                  allPackages: _packages,
                ),
              ),
            );
          },
          icon: const Icon(Icons.dashboard_customize_rounded),
          label: const Text('Open Repository Details'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => RepositoryHistoryScreen(
                  package: package,
                  allPackages: _packages,
                ),
              ),
            );
          },
          icon: const Icon(Icons.history_rounded),
          label: const Text('Version History'),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: () {
            if (package.status == 'published') {
              _createRevision(package);
              return;
            }

            if (package.status == 'archived') {
              _showMessage('Archived versions cannot be edited directly.');
              return;
            }

            _openStudio(package);
          },
          icon: Icon(
            package.status == 'published'
                ? Icons.fork_right_rounded
                : Icons.edit_note_rounded,
          ),
          label: Text(
            package.status == 'published'
                ? 'Create Revision & Edit'
                : package.status == 'archived'
                ? 'Archived Version'
                : 'Open in Content Studio',
          ),
        ),
        if (status == 'published') ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _archive(package),
            icon: const Icon(Icons.archive_outlined),
            label: const Text('Archive Version'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _deletePublishedVersion(package),
            icon: const Icon(Icons.delete_outline_rounded),
            label: const Text('Delete Published Content'),
          ),
        ],
        if (status == 'draft') ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _sendToReview(package),
            icon: const Icon(Icons.rate_review_rounded),
            label: const Text('Submit for Review'),
          ),
        ],
        if (status == 'review') ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _validate(package),
            icon: const Icon(Icons.verified_rounded),
            label: const Text('Validate Package'),
          ),
        ],
        if (status == 'validated') ...[
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: () => _publish(package),
            icon: const Icon(Icons.publish_rounded),
            label: const Text('Publish Version'),
          ),
        ],
        if (status == 'archived') ...[
          const SizedBox(height: 8),
          Text(
            'This version is retained for history and '
            'is not student-live.',
            style: StudyTypography.caption,
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _deletePublishedVersion(package),
            icon: const Icon(Icons.delete_forever_rounded),
            label: const Text('Delete Archived Content'),
          ),
        ],
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: StudyColors.surface,
        borderRadius: StudyRadius.large,
        border: Border.all(color: StudyColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.inventory_2_outlined,
            size: 34,
            color: StudyColors.textMuted,
          ),
          const SizedBox(height: 12),
          Text(
            'No content packages match the current '
            'filters.',
            style: StudyTypography.subSectionTitle,
          ),
          const SizedBox(height: 6),
          Text(
            'Import or create a competency package '
            'in Content Studio, then save it as a '
            'draft to make it appear here.',
            style: StudyTypography.bodySecondary,
          ),
        ],
      ),
    );
  }
}
