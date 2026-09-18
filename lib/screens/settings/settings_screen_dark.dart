import 'package:flutter/material.dart';

import 'package:exam_platform/theme/glass/student_glass.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/app_colors.dart';
import '../../services/auth/auth_state_service.dart';
import '../../services/student_learning_position_service.dart';
import '../../services/student_learning_progress_service.dart';
import '../../services/student_question_progress_service.dart';
import '../../services/settings/settings_external_links.dart';
import '../../services/settings/theme_mode_service.dart';
import 'legal_document_screen.dart';
import 'legal_document_screen_dark.dart';

typedef DarkSettingsUriLauncher = Future<bool> Function(Uri uri);

class DarkSettingsScreen extends StatelessWidget {
  final DarkSettingsUriLauncher? externalLauncher;
  final Future<void> Function()? signOutAction;
  final Future<void> Function()? resetLearningDataAction;

  const DarkSettingsScreen({
    super.key,
    this.externalLauncher,
    this.signOutAction,
    this.resetLearningDataAction,
  });

  static const _background = Color(0xFF0A111D);
  static const _surface = Color(0xFF111B2C);
  static const _navy = Color(0xFF5F93D8);
  static const _blue = Color(0xFF6EA8FF);
  static const _violet = Color(0xFF9A7CF4);
  static const _textPrimary = Color(0xFFF4F7FB);
  static const _textMuted = Color(0xFFA5B1C4);
  static const _border = Color(0xFF25344A);
  static const _green = Color(0xFF1F8A4C);
  static const _amber = Color(0xFFE59A24);

  Future<bool> _launch(Uri uri) {
    final launcher = externalLauncher;

    if (launcher != null) {
      return launcher(uri);
    }

    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _openExternal(
    BuildContext context,
    Uri uri,
    String label,
  ) async {
    try {
      final opened = await _launch(uri);

      if (!opened && context.mounted) {
        _showMessage(context, 'Could not open $label.');
      }
    } catch (_) {
      if (context.mounted) {
        _showMessage(context, 'Could not open $label.');
      }
    }
  }

  Future<void> _signOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          'Your UID-scoped local progress will remain on this device and will be available again when you sign back into the same account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('SIGN OUT'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    final action = signOutAction;

    if (action != null) {
      await action();
    } else {
      await AuthStateService().signOut();
    }
  }

  Future<void> _resetLearningData(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear local learning data?'),
        content: const Text(
          'This clears this account’s Subtopic progress, Continue Learning position, and completed-question history from this device. It cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('KEEP MY DATA'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('CLEAR DATA'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    try {
      final action = resetLearningDataAction;

      if (action != null) {
        await action();
      } else {
        await const StudentLearningProgressService().clearAllProgress();
        await const StudentLearningPositionService().clearPosition();
        await const StudentQuestionProgressService().clearAllProgress();
      }

      if (context.mounted) {
        _showMessage(context, 'Local learning data cleared for this account.');
      }
    } catch (_) {
      if (context.mounted) {
        _showMessage(context, 'Learning data could not be cleared.');
      }
    }
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _openLegal(BuildContext context, LegalDocument document) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DarkLegalDocumentScreen(document: document),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StudentGlassScaffold(
      backgroundColor: _background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A111D), Color(0xFF0D1624), Color(0xFF111827)],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            key: const PageStorageKey<String>('csp11-settings-scroll'),
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildAppBar(),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  _pageHorizontal(context),
                  12,
                  _pageHorizontal(context),
                  48,
                ),
                sliver: SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1100),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHero(context),
                          const SizedBox(height: 28),
                          _buildSectionHeading(
                            eyebrow: 'GET IN TOUCH',
                            title: 'Learn with the developer',
                            subtitle:
                                'For CSP tuition, focused study sessions, classes, or app support.',
                          ),
                          const SizedBox(height: 14),
                          _buildContactGrid(context),
                          const SizedBox(height: 30),
                          _buildSectionHeading(
                            eyebrow: 'APP & ACCOUNT',
                            title: 'Your CSP11 workspace',
                            subtitle:
                                'Manage your current account, local learning data, and app access.',
                          ),
                          const SizedBox(height: 14),
                          _settingsGroup(
                            children: [
                              _SettingsTile(
                                key: const ValueKey('settings-dark-mode'),
                                icon: Icons.dark_mode_rounded,
                                iconColor: _violet,
                                iconBackground: const Color(0xFF1D1934),
                                title: 'Dark mode',
                                subtitle:
                                    'Use the dark CSP11 design across Home, Study, Domain, Topics, Subtopics, Notes, Practice, Quiz, Results, Legal, Flashcards, Progress, and Settings.',
                                trailing: ValueListenableBuilder<bool>(
                                  valueListenable: ThemeModeService.isDarkMode,
                                  builder: (context, enabled, _) => Switch(
                                    value: enabled,
                                    onChanged: ThemeModeService.setDarkMode,
                                  ),
                                ),
                                onTap: () {
                                  ThemeModeService.toggle();
                                },
                              ),
                              _SettingsTile(
                                key: const ValueKey('settings-rate-app'),
                                icon: Icons.star_rounded,
                                iconColor: _amber,
                                iconBackground: const Color(0xFF2A2113),
                                title: 'Rate CSP11',
                                subtitle:
                                    'Play Store rating link will activate after release.',
                                trailing: const _ComingSoonPill(),
                                onTap: () => _showMessage(
                                  context,
                                  'Play Store rating will be linked after release.',
                                ),
                              ),
                              _SettingsTile(
                                icon: Icons.storage_rounded,
                                iconColor: _blue,
                                iconBackground: const Color(0xFF14243B),
                                title: 'Learning data on this device',
                                subtitle:
                                    'Progress is separated by your Firebase account UID and stored locally on this device.',
                                onTap: () => _showDataInfo(context),
                              ),
                              _SettingsTile(
                                key: const ValueKey(
                                  'settings-clear-learning-data',
                                ),
                                icon: Icons.delete_outline_rounded,
                                iconColor: Colors.red.shade700,
                                iconBackground: const Color(0xFF2B171C),
                                title: 'Clear my local learning data',
                                subtitle:
                                    'Reset this account’s local progress, Continue Learning position, and question history.',
                                onTap: () => _resetLearningData(context),
                              ),
                              _SettingsTile(
                                key: const ValueKey('settings-sign-out'),
                                icon: Icons.logout_rounded,
                                iconColor: _textPrimary,
                                iconBackground: const Color(0xFF162238),
                                title: 'Sign out',
                                subtitle:
                                    'Your local progress remains available for this account on this device.',
                                onTap: () => _signOut(context),
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),
                          _buildSectionHeading(
                            eyebrow: 'LEGAL',
                            title: 'Policies & important information',
                            subtitle:
                                'Read how the app handles data and the limits of educational use.',
                          ),
                          const SizedBox(height: 14),
                          _settingsGroup(
                            children: [
                              _SettingsTile(
                                key: const ValueKey('settings-privacy-policy'),
                                icon: Icons.privacy_tip_outlined,
                                iconColor: _green,
                                iconBackground: const Color(0xFF13271D),
                                title: 'Privacy Policy',
                                subtitle:
                                    'Account, local progress, external links, and data choices.',
                                onTap: () => _openLegal(
                                  context,
                                  Csp11LegalDocuments.privacyPolicy,
                                ),
                              ),
                              _SettingsTile(
                                key: const ValueKey(
                                  'settings-terms-of-service',
                                ),
                                icon: Icons.description_outlined,
                                iconColor: _blue,
                                iconBackground: const Color(0xFF14243B),
                                title: 'Terms of Service',
                                subtitle:
                                    'Conditions for using the CSP11 learning platform.',
                                onTap: () => _openLegal(
                                  context,
                                  Csp11LegalDocuments.termsOfService,
                                ),
                              ),
                              _SettingsTile(
                                key: const ValueKey(
                                  'settings-legal-disclaimer',
                                ),
                                icon: Icons.gavel_rounded,
                                iconColor: _violet,
                                iconBackground: const Color(0xFF1D1934),
                                title: 'Legal Disclaimer',
                                subtitle:
                                    'Educational-use limits, exam outcomes, and professional reliance.',
                                onTap: () => _openLegal(
                                  context,
                                  Csp11LegalDocuments.legalDisclaimer,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),
                          _buildAboutCard(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _pageHorizontal(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1200) return 28;
    if (width >= 700) return 22;
    return 16;
  }

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      automaticallyImplyLeading: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: _background.withValues(alpha: 0.96),
      surfaceTintColor: Colors.transparent,
      titleSpacing: 18,
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.10),
              ),
            ),
            child: const Icon(
              Icons.tune_rounded,
              color: AppColors.primary,
              size: 17,
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'CSP11',
            style: TextStyle(
              color: _textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.25,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.45),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Settings',
            style: TextStyle(
              color: _textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 650;

    return Container(
      key: const ValueKey('settings-hero'),
      width: double.infinity,
      constraints: BoxConstraints(minHeight: compact ? 320 : 290),
      padding: EdgeInsets.all(compact ? 22 : 28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF102A56), Color(0xFF1E4C91), Color(0xFF5B36A8)],
          stops: [0.0, 0.58, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.20),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -72,
            right: -42,
            child: IgnorePointer(
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.065),
                    width: 24,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: compact ? 6 : 30,
            bottom: compact ? -12 : 22,
            child: IgnorePointer(
              child: Icon(
                Icons.settings_suggest_rounded,
                size: compact ? 120 : 158,
                color: Colors.white.withValues(alpha: 0.045),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _heroPill(
                icon: Icons.settings_rounded,
                text: 'CSP11 CONTROL CENTER',
              ),
              const SizedBox(height: 26),
              const Text(
                'Settings that stay\nout of your way.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  height: 1.06,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.9,
                ),
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 650),
                child: Text(
                  'Contact the developer, manage your account and local learner data, and keep important legal information close at hand.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.80),
                    fontSize: 14,
                    height: 1.55,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 9,
                runSpacing: 9,
                children: [
                  _heroMiniPill(Icons.shield_outlined, 'UID-SEPARATED DATA'),
                  _heroMiniPill(Icons.support_agent_rounded, 'DIRECT SUPPORT'),
                  _heroMiniPill(Icons.gavel_rounded, 'LEGAL CENTER'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroPill({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white.withValues(alpha: 0.94), size: 14),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.94),
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.9,
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroMiniPill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.075),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white.withValues(alpha: 0.76)),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              fontSize: 8,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.55,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeading({
    required String eyebrow,
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.15,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          title,
          style: const TextStyle(
            color: _textPrimary,
            fontSize: 22,
            height: 1.12,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.45,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          style: const TextStyle(
            color: _textMuted,
            fontSize: 11.5,
            height: 1.45,
          ),
        ),
      ],
    );
  }

  Widget _buildContactGrid(BuildContext context) {
    final items = [
      _ContactData(
        keyName: 'settings-whatsapp',
        icon: Icons.chat_rounded,
        eyebrow: 'WHATSAPP',
        title: 'Message Naveed',
        subtitle: '+91 81296 59572',
        gradient: const [Color(0xFF116A57), Color(0xFF1E9A78)],
        onTap: () =>
            _openExternal(context, SettingsExternalLinks.whatsApp, 'WhatsApp'),
      ),
      _ContactData(
        keyName: 'settings-email',
        icon: Icons.mail_rounded,
        eyebrow: 'EMAIL',
        title: 'Email the developer',
        subtitle: 'csp11app@gmail.com',
        gradient: const [_navy, _blue],
        onTap: () =>
            _openExternal(context, SettingsExternalLinks.email, 'email'),
      ),
      _ContactData(
        keyName: 'settings-linkedin',
        icon: Icons.work_outline_rounded,
        eyebrow: 'LINKEDIN',
        title: 'Connect on LinkedIn',
        subtitle: 'naveedcsp',
        gradient: const [_violet, Color(0xFF7654C6)],
        onTap: () =>
            _openExternal(context, SettingsExternalLinks.linkedIn, 'LinkedIn'),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900
            ? 3
            : constraints.maxWidth >= 580
            ? 2
            : 1;

        const gap = 13.0;
        final width = columns == 1
            ? constraints.maxWidth
            : (constraints.maxWidth - gap * (columns - 1)) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: items
              .map(
                (item) => SizedBox(
                  width: width,
                  height: 156,
                  child: _contactCard(item),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _contactCard(_ContactData item) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey(item.keyName),
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: item.gradient,
            ),
            boxShadow: [
              BoxShadow(
                color: item.gradient.first.withValues(alpha: 0.15),
                blurRadius: 17,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -8,
                bottom: -12,
                child: Icon(
                  item.icon,
                  size: 72,
                  color: Colors.white.withValues(alpha: 0.055),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(item.icon, color: Colors.white, size: 20),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.arrow_outward_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    item.eyebrow,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.62),
                      fontSize: 8.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.74),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _settingsGroup({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: _navy.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1)
              const Divider(height: 1, indent: 72, color: _border),
          ],
        ],
      ),
    );
  }

  void _showDataInfo(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Learning data on this device',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              const Text(
                'Your Subtopic completion, Continue Learning position, and submitted-question history are stored locally under the currently signed-in Firebase UID. Another account on the same device uses a different local namespace.',
                style: TextStyle(fontSize: 12, height: 1.5),
              ),
              const SizedBox(height: 12),
              const Text(
                'This local data does not currently synchronize automatically to another device.',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAboutCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF101A2A),
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: _border),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_rounded, color: AppColors.primary, size: 26),
          SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CSP11 Learning Platform',
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Study, practise, review, and track your progress through the CSP11 learning architecture. Built around focused learning rather than invented readiness scores.',
                  style: TextStyle(
                    color: _textMuted,
                    fontSize: 10.5,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  const _SettingsTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: DarkSettingsScreen._textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: DarkSettingsScreen._textMuted,
                        fontSize: 9.5,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              trailing ??
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: DarkSettingsScreen._textMuted,
                    size: 20,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ComingSoonPill extends StatelessWidget {
  const _ComingSoonPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2113),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        'LATER',
        style: TextStyle(
          color: DarkSettingsScreen._amber,
          fontSize: 7.5,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _ContactData {
  final String keyName;
  final IconData icon;
  final String eyebrow;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _ContactData({
    required this.keyName,
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });
}
