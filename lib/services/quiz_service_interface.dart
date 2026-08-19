import '../models/question.dart';

abstract class QuizServiceInterface {
  List<Question> getQuiz({required int domain, required int numberOfQuestions});

  List<Question> getQuizById(String quizId);

  List<Question> getShuffledQuestionsByCompetency(String competencyId);

  List<Question> getShuffledQuestionsBySubtopic(String subtopicId);

  List<Question> getShuffledQuestionsByTopic(String topicId);
}
