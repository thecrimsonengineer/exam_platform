import 'package:flutter/material.dart';

import '../domain/learning_twin_state.dart';
import 'learning_twin_asset.dart';
import 'learning_twin_avatar.dart';
import 'learning_twin_motion_mapper.dart';
import 'learning_twin_motion_state.dart';

class LearningTwinMotionPreview extends StatefulWidget {
  const LearningTwinMotionPreview({super.key});

  @override
  State<LearningTwinMotionPreview> createState() =>
      _LearningTwinMotionPreviewState();
}

class _LearningTwinMotionPreviewState extends State<LearningTwinMotionPreview> {
  LearningTwinState _state = LearningTwinState.idle;
  bool _animationEnabled = true;
  bool _reducedMotion = false;
  double _size = 180;
  int _eventSequence = 0;

  @override
  Widget build(BuildContext context) {
    final motionState = LearningTwinMotionMapper.map(_state);

    return Scaffold(
      appBar: AppBar(title: const Text('Learning Twin Motion Preview')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(disableAnimations: _reducedMotion),
              child: LearningTwinAvatar(
                asset: LearningTwinAsset.hero,
                size: _size,
                compactCrop: false,
                motionState: motionState,
                animationEnabled: _animationEnabled,
                motionEventKey:
                    'ltam4-preview:${motionState.manifestKey}:$_eventSequence',
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Mapped motion: ${motionState.manifestKey}',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<LearningTwinState>(
            initialValue: _state,
            decoration: const InputDecoration(labelText: 'LearningTwinState'),
            items: [
              for (final state in LearningTwinState.values)
                DropdownMenuItem(value: state, child: Text(state.name)),
            ],
            onChanged: (value) {
              if (value == null) {
                return;
              }
              setState(() {
                _state = value;
                _eventSequence++;
              });
            },
          ),
          SwitchListTile(
            title: const Text('Animation enabled'),
            value: _animationEnabled,
            onChanged: (value) => setState(() => _animationEnabled = value),
          ),
          SwitchListTile(
            title: const Text('Simulate reduced motion'),
            value: _reducedMotion,
            onChanged: (value) => setState(() => _reducedMotion = value),
          ),
          Slider(
            min: 48,
            max: 260,
            value: _size,
            label: _size.round().toString(),
            onChanged: (value) => setState(() => _size = value),
          ),
          FilledButton(
            onPressed: () => setState(() => _eventSequence++),
            child: const Text('Replay with new event key'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _state = LearningTwinState.idle;
                _eventSequence++;
              });
            },
            child: const Text('Return to idle'),
          ),
        ],
      ),
    );
  }
}
