enum TwinIdentityCandidateSource { curatedReference, avatarMaker }

class TwinIdentityCandidate {
  const TwinIdentityCandidate({
    required this.id,
    required this.label,
    required this.intent,
    required this.source,
    this.assetPath,
    this.svg,
    this.json,
    this.rasterBackedSvg = false,
  }) : assert(assetPath != null || svg != null);

  final String id;
  final String label;
  final String intent;
  final TwinIdentityCandidateSource source;
  final String? assetPath;
  final String? svg;
  final String? json;
  final bool rasterBackedSvg;

  bool get isCuratedReference =>
      source == TwinIdentityCandidateSource.curatedReference;

  const TwinIdentityCandidate.curated({
    required this.id,
    required this.label,
    required this.intent,
    required String assetPath,
  }) : source = TwinIdentityCandidateSource.curatedReference,
       assetPath = assetPath,
       svg = null,
       json = null,
       rasterBackedSvg = true;

  TwinIdentityCandidate.avatarMaker({
    required this.id,
    required this.label,
    required String svg,
    required String json,
  }) : intent = 'authoring candidate',
       source = TwinIdentityCandidateSource.avatarMaker,
       assetPath = null,
       svg = svg,
       json = json,
       rasterBackedSvg = false;
}
