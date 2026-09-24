import 'package:exam_platform/features/learning_twin/ui/learning_twin_asset.dart';
import 'package:exam_platform/features/learning_twin/ui/learning_twin_avatar.dart';
import 'package:exam_platform/features/learning_twin/ui/learning_twin_motion_renderer.dart';
import 'package:exam_platform/features/learning_twin/ui/learning_twin_motion_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';

void main() {
  Future<void> pumpAvatar(WidgetTester tester, Widget avatar) async {
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: Center(child: avatar))),
    );
    await tester.pump();
  }

  testWidgets('legacy neutral call remains static and compatible', (
    tester,
  ) async {
    await pumpAvatar(tester, const LearningTwinAvatar());

    expect(find.byType(SvgPicture), findsOneWidget);
    expect(find.byType(LearningTwinMotionRenderer), findsNothing);
  });

  testWidgets('legacy explain success and hero calls remain static', (
    tester,
  ) async {
    await pumpAvatar(
      tester,
      const Column(
        children: [
          LearningTwinAvatar(asset: LearningTwinAsset.explain),
          LearningTwinAvatar(asset: LearningTwinAsset.success),
          LearningTwinAvatar(
            asset: LearningTwinAsset.hero,
            compactCrop: false,
          ),
        ],
      ),
    );

    expect(find.byType(SvgPicture), findsNWidgets(3));
    expect(find.byType(LearningTwinMotionRenderer), findsNothing);
  });

  testWidgets('motion remains explicit opt-in through the avatar facade', (
    tester,
  ) async {
    await pumpAvatar(
      tester,
      const LearningTwinAvatar(
        motionState: LearningTwinMotionState.explain,
        animationEnabled: false,
      ),
    );

    expect(find.byType(LearningTwinMotionRenderer), findsOneWidget);
    expect(find.byType(SvgPicture), findsOneWidget);
  });
}
