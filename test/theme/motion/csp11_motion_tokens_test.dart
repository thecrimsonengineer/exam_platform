import 'package:exam_platform/theme/motion/csp11_motion.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('MOT Run 1 duration tokens stay frozen', () {
    expect(Csp11MotionDuration.instant, const Duration(milliseconds: 80));
    expect(Csp11MotionDuration.quick, const Duration(milliseconds: 140));
    expect(Csp11MotionDuration.standard, const Duration(milliseconds: 220));
    expect(Csp11MotionDuration.emphasized, const Duration(milliseconds: 320));
    expect(Csp11MotionDuration.celebration, const Duration(milliseconds: 520));
  });

  test('MOT semantic intent vocabulary stays frozen', () {
    expect(Csp11MotionIntent.values, <Csp11MotionIntent>[
      Csp11MotionIntent.navigate,
      Csp11MotionIntent.reveal,
      Csp11MotionIntent.select,
      Csp11MotionIntent.confirm,
      Csp11MotionIntent.consequence,
      Csp11MotionIntent.celebrate,
    ]);
  });
}
