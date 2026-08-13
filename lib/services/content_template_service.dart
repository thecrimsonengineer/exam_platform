import '../models/content_authoring_template.dart';

class ContentTemplateService {
  const ContentTemplateService();

  List<ContentAuthoringTemplate> templates() {
    return const [
      ContentAuthoringTemplate(
        type: ContentAuthoringTemplateType.studyTopic,
        name: 'Study Topic',
        fields: [
          'DOMAIN',
          'COMPETENCY',
          'SUBTOPIC',
          'TOPIC',
          'CONTENT',
          'KEY POINTS',
          'EXAMPLE',
          'EXAM TIP',
          'REFERENCE',
        ],
      ),
      ContentAuthoringTemplate(
        type: ContentAuthoringTemplateType.fiveQuestionQuiz,
        name: 'Five Question Quiz',
        fields: [
          'QUESTION',
          'A',
          'B',
          'C',
          'D',
          'BEST ANSWER',
          'EXPLANATION',
          'REFERENCE',
          'TAGS',
          'DIFFICULTY',
          'COGNITIVE LEVEL',
        ],
      ),
      ContentAuthoringTemplate(
        type: ContentAuthoringTemplateType.referenceEntry,
        name: 'Reference',
        fields: [
          'TITLE',
          'AUTHOR',
          'ORGANIZATION',
          'EDITION',
          'YEAR',
          'URL',
        ],
      ),
    ];
  }
}
