class ContentCloneRequest {
  final String sourceContentId;
  final String newContentId;
  final String newTitle;

  const ContentCloneRequest({
    required this.sourceContentId,
    required this.newContentId,
    required this.newTitle,
  });
}
