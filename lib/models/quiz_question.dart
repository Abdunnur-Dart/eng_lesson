import 'package:cloud_firestore/cloud_firestore.dart'; // NEW

class QuizQuestion {
  final String questionText;
  final List<String> options;
  final int correctOptionIndex;

  const QuizQuestion({
    required this.questionText,
    required this.options,
    required this.correctOptionIndex,
  });

  // NEW: Модель с безопасной типизацией для загрузки данных из Firestore
  factory QuizQuestion.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    
    final List<dynamic> rawOptions = data['options'] as List<dynamic>? ?? [];
    final List<String> parsedOptions = rawOptions.map((e) => e.toString()).toList();

    return QuizQuestion(
      questionText: data['questionText'] as String? ?? '',
      options: parsedOptions,
      correctOptionIndex: (data['correctOptionIndex'] as num?)?.toInt() ?? 0,
    );
  }

  // NEW: Метод конвертации для сохранения вопросов в Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'questionText': questionText,
      'options': options,
      'correctOptionIndex': correctOptionIndex,
    };
  }
}