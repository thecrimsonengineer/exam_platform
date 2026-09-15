enum LearningTwinAsset { neutral, explain, success, hero }

extension LearningTwinAssetX on LearningTwinAsset {
  String get assetPath => switch (this) {
    LearningTwinAsset.neutral => 'assets/learning_twin/naveed_twin.svg',
    LearningTwinAsset.explain => 'assets/learning_twin/naveed_twin_explain.svg',
    LearningTwinAsset.success => 'assets/learning_twin/naveed_twin_success.svg',
    LearningTwinAsset.hero => 'assets/learning_twin/naveed_twin_fullbody.svg',
  };

  String get semanticLabel => switch (this) {
    LearningTwinAsset.neutral => 'Naveed Learning Guide',
    LearningTwinAsset.explain => 'Naveed Learning Guide explaining',
    LearningTwinAsset.success => 'Naveed Learning Guide celebrating',
    LearningTwinAsset.hero => 'Naveed Learning Guide',
  };
}
