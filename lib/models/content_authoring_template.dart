enum ContentAuthoringTemplateType {
  studyTopic,
  fiveQuestionQuiz,
  referenceEntry,
}

class ContentAuthoringTemplate {
  final ContentAuthoringTemplateType type;
  final String name;
  final List<String> fields;

  const ContentAuthoringTemplate({
    required this.type,
    required this.name,
    required this.fields,
  });
}
