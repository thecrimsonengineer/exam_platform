import 'package:exam_platform/theme/study/study_spacing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('phone study layout uses compact horizontal spacing', () {
    expect(StudySpacing.pageHorizontalForWidth(390), StudySpacing.xs);
    expect(StudySpacing.heroHorizontalForWidth(390), StudySpacing.md);
  });

  test('tablet and desktop keep their wider reading margins', () {
    expect(StudySpacing.pageHorizontalForWidth(700), StudySpacing.pageHorizontal);
    expect(StudySpacing.heroHorizontalForWidth(700), StudySpacing.pageHorizontal);
    expect(
      StudySpacing.pageHorizontalForWidth(1200),
      StudySpacing.pageHorizontalDesktop,
    );
    expect(
      StudySpacing.heroHorizontalForWidth(1200),
      StudySpacing.pageHorizontalDesktop,
    );
  });
}
