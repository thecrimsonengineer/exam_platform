import 'package:flutter/material.dart';

import '../../services/haptics/csp11_haptic_event.dart';
import '../../services/haptics/csp11_haptic_service.dart';
import '../../services/settings/haptic_preference_service.dart';

/// Debug/admin-only surface for physical-device tactile verification.
///
/// This screen is intentionally not registered in learner navigation. It can be
/// pushed explicitly from a debug/admin entry point when physical validation is
/// required.
class HapticDiagnosticsScreen extends StatelessWidget {
  const HapticDiagnosticsScreen({super.key});

  static const routeName = '/admin/haptic-diagnostics';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Haptic diagnostics')),
      body: ValueListenableBuilder<bool>(
        valueListenable: HapticPreferenceService.enabled,
        builder: (context, enabled, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SwitchListTile.adaptive(
                key: const ValueKey('haptic-diagnostics-enabled'),
                title: const Text('Haptic feedback'),
                subtitle: const Text(
                  'Local device preference. No backend access is used.',
                ),
                value: enabled,
                onChanged: HapticPreferenceService.setEnabled,
              ),
              const SizedBox(height: 12),
              const Text(
                'Tap each event on a physical Android or iOS device and confirm '
                'that the tactile strength matches its semantic meaning.',
              ),
              const SizedBox(height: 16),
              for (final event in Csp11HapticEvent.values)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: FilledButton.tonal(
                    key: ValueKey('haptic-diagnostics-' + event.name),
                    onPressed: () => Csp11Haptics.trigger(event),
                    child: Text(_label(event)),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  String _label(Csp11HapticEvent event) {
    return switch (event) {
      Csp11HapticEvent.selection => 'Selection',
      Csp11HapticEvent.navigation => 'Navigation',
      Csp11HapticEvent.confirm => 'Confirm',
      Csp11HapticEvent.success => 'Success',
      Csp11HapticEvent.warning => 'Warning',
      Csp11HapticEvent.error => 'Error',
      Csp11HapticEvent.criticalDecision => 'Critical decision',
      Csp11HapticEvent.completion => 'Completion',
    };
  }
}
