import '../../../models/micro_learning/micro_fact.dart';
import '../ui/learning_twin_asset.dart';

class MicroLearningTwinPresentation {
  const MicroLearningTwinPresentation({
    required this.asset,
    required this.eventKey,
    required this.semanticLabel,
  });

  final LearningTwinAsset asset;
  final String eventKey;
  final String semanticLabel;
}

class MicroLearningTwinPresentationBridge {
  const MicroLearningTwinPresentationBridge();

  MicroLearningTwinPresentation forFact(MicroFact fact) {
    return MicroLearningTwinPresentation(
      asset: LearningTwinAsset.explain,
      eventKey: 'microfact:${fact.microFactId}:v${fact.contentVersion}',
      semanticLabel: 'Naveed Learning Guide sharing a CSP insight',
    );
  }
}
