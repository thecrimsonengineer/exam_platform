import 'package:flutter/material.dart';

import '../../../../../../controllers/quiz_controller.dart';
import '../../../../../../models/question.dart';
import 'answer_option_card.dart';

class AnswerList extends StatelessWidget {
  final Question question;
  final QuizController controller;
  final ValueChanged<int> onSelect;

  const AnswerList({
    super.key,
    required this.question,
    required this.controller,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final options = controller.currentOptions;
    final correctIndex = controller.currentCorrectDisplayIndex;

    return Column(
      children: List.generate(options.length, (index) {
        final bool isSelected = controller.selectedAnswer == index;

        final bool isCorrect = controller.submitted && correctIndex == index;

        final bool isIncorrect =
            controller.submitted && isSelected && correctIndex != index;

        return Padding(
          padding: EdgeInsets.only(
            bottom: index == options.length - 1 ? 0 : 14,
          ),
          child: AnswerOptionCard(
            label: String.fromCharCode(65 + index),
            text: options[index],
            isSelected: isSelected,
            isCorrect: isCorrect,
            isIncorrect: isIncorrect,
            submitted: controller.submitted,
            onTap: () => onSelect(index),
          ),
        );
      }),
    );
  }
}
