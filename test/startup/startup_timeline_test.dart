import 'package:exam_platform/screens/startup/startup_timeline.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StartupTimeline', () {
    test('maps exact Lottie marker boundaries to matching beats', () {
      expect(StartupTimeline.beatForProgress(0), StartupBeat.ignite);
      expect(StartupTimeline.beatForProgress(18 / 144), StartupBeat.learn);
      expect(StartupTimeline.beatForProgress(44 / 144), StartupBeat.practice);
      expect(StartupTimeline.beatForProgress(70 / 144), StartupBeat.lab);
      expect(StartupTimeline.beatForProgress(96 / 144), StartupBeat.remember);
      expect(StartupTimeline.beatForProgress(132 / 144), StartupBeat.converge);
    });

    test('clamps progress outside the animation range', () {
      expect(StartupTimeline.beatForProgress(-1), StartupBeat.ignite);
      expect(StartupTimeline.beatForProgress(2), StartupBeat.converge);
    });

    test('returns normalized progress inside each beat', () {
      expect(StartupTimeline.beatProgress(0, StartupBeat.ignite), 0);
      expect(StartupTimeline.beatProgress(18 / 144, StartupBeat.ignite), 1);

      final midpoint = ((44 + 70) / 2) / 144;
      expect(
        StartupTimeline.beatProgress(midpoint, StartupBeat.practice),
        closeTo(0.5, 0.0001),
      );

      expect(StartupTimeline.beatProgress(1, StartupBeat.converge), 1);
    });
  });
}
