import 'package:flutter/material.dart';
import '../models/quiz_question.dart';
import '../services/settings_service.dart';
import '../services/quiz_service.dart';

class QuizScreen extends StatefulWidget {
  final int lessonId;
  final String lessonTitle;
  final List<QuizQuestion> questions;

  const QuizScreen({
    super.key,
    required this.lessonId,
    required this.lessonTitle,
    required this.questions,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final QuizService _quizService = QuizService();
  int _currentIndex = 0;
  int _score = 0;
  int? _selectedAnswerIndex;
  bool _isAnswered = false;
  bool _isFinished = false;

  void _answerQuestion(int index, List<QuizQuestion> activeQuestions) {
    if (_isAnswered) return;

    setState(() {
      _selectedAnswerIndex = index;
      _isAnswered = true;
      if (index == activeQuestions[_currentIndex].correctOptionIndex) {
        _score++;
      }
    });

    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() {
        _selectedAnswerIndex = null;
        _isAnswered = false;
        if (_currentIndex < activeQuestions.length - 1) {
          _currentIndex++;
        } else {
          _isFinished = true;
          double progressValue = _score / activeQuestions.length;
          SettingsService.instance.setLessonProgress(widget.lessonId, progressValue);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<QuizQuestion>>(
      stream: _quizService.streamQuestionsForLesson(widget.lessonId),
      builder: (context, snapshot) {
        // NEW: Состояние загрузки данных из Firestore
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(
              title: Text('Тест: ${widget.lessonTitle}'),
              backgroundColor: Colors.teal.shade800,
              foregroundColor: Colors.white,
            ),
            body: const Center(
              child: CircularProgressIndicator(color: Colors.teal),
            ),
          );
        }

        // NEW: Проверка на отсутствие вопросов в базе для данного урока
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Scaffold(
            appBar: AppBar(
              title: Text('Тест: ${widget.lessonTitle}'),
              backgroundColor: Colors.teal.shade800,
              foregroundColor: Colors.white,
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.quiz_outlined, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text(
                      'Вопросы для этого урока пока не добавлены.',
                      style: TextStyle(fontSize: 16, color: Colors.grey.shade700, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal.shade700,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Вернуться к урокам'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final activeQuestions = snapshot.data!;

        if (_isFinished) {
          int total = activeQuestions.length;
          double percentage = (_score / total) * 100;

          return Scaffold(
            appBar: AppBar(
              title: Text('Итог теста: ${widget.lessonTitle}'),
              backgroundColor: Colors.teal.shade800,
              foregroundColor: Colors.white,
              centerTitle: true,
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Тест успешно пройден! 🎉',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 160,
                          height: 160,
                          child: CircularProgressIndicator(
                            value: _score / total,
                            strokeWidth: 14,
                            backgroundColor: Colors.teal.shade100,
                            color: Colors.teal.shade600,
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${percentage.toInt()}%',
                              style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.teal.shade900),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$_score из $total верных',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Завершить урок', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (_currentIndex >= activeQuestions.length) {
          _currentIndex = 0;
        }

        final question = activeQuestions[_currentIndex];

        return Scaffold(
          appBar: AppBar(
            title: Text('Тест: ${widget.lessonTitle}'),
            backgroundColor: Colors.teal.shade800,
            foregroundColor: Colors.white,
          ),
          body: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LinearProgressIndicator(
                  value: (_currentIndex + 1) / activeQuestions.length,
                  backgroundColor: Colors.teal.shade100,
                  color: Colors.teal.shade700,
                  minHeight: 10,
                ),
                const SizedBox(height: 20),
                Text(
                  'Вопрос ${_currentIndex + 1} из ${activeQuestions.length}',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  question.questionText,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 25),
                ...List.generate(question.options.length, (index) {
                  Color buttonColor = Colors.teal.shade50;
                  Color textColor = Colors.teal.shade900;
                  BorderSide borderSide = BorderSide(color: Colors.teal.shade400, width: 1.5);

                  if (_isAnswered) {
                    if (index == question.correctOptionIndex) {
                      buttonColor = Colors.green.shade400;
                      textColor = Colors.white;
                      borderSide = const BorderSide(color: Colors.green, width: 2);
                    } else if (index == _selectedAnswerIndex) {
                      buttonColor = Colors.red.shade400;
                      textColor = Colors.white;
                      borderSide = const BorderSide(color: Colors.red, width: 2);
                    }
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: buttonColor,
                        side: borderSide,
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => _answerQuestion(index, activeQuestions),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          question.options[index],
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}