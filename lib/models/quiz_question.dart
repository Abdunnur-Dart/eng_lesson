class QuizQuestion {
  final String questionText;
  final List<String> options;
  final int correctOptionIndex;

  const QuizQuestion({
    required this.questionText,
    required this.options,
    required this.correctOptionIndex,
  });
}