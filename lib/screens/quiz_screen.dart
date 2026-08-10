import 'dart:math';
import 'package:flutter/material.dart';
import '../models/quiz_question.dart';
import '../services/settings_service.dart';

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
  late List<QuizQuestion> _generatedQuestions;
  int _currentIndex = 0;
  int _score = 0;
  int? _selectedAnswerIndex;
  bool _isAnswered = false;
  bool _isFinished = false;

  @override
  void initState() {
    super.initState();
    _generatedQuestions = _buildExtendedQuestions(widget.lessonTitle);
  }

  List<QuizQuestion> _buildExtendedQuestions(String currentLetter) {
    final random = Random();
    final dummyLetters = ['Әлиф', 'Ба', 'Тә', 'Сә', 'Жим', 'Хә', 'Ха', 'Дәл', 'Ра', 'Син', 'Фәйн', 'Мим', 'Нун'];

    List<QuizQuestion> list = [];

    list.add(QuizQuestion(
      questionText: 'Как называется эта буква?  اَ',
      options: _getRandomOptions(currentLetter, dummyLetters, 4),
      correctOptionIndex: 0,
    ));

    list.add(const QuizQuestion(
      questionText: 'Сколько основных позиций написания имеет арабская буква в слове?',
      options: ['Только 1', '2 позиции', 'До 4 позиций (начальная, срединная, конечная, обособленная)', 'Больше 5'],
      correctOptionIndex: 2,
    ));

    list.add(const QuizQuestion(
      questionText: 'Для чего служат примеры слов в карточках?',
      options: ['Для красоты', 'Для проверки чтения и произношения', 'Для перевода текста', 'Не имеют значения'],
      correctOptionIndex: 1,
    ));

    list.add(QuizQuestion(
      questionText: 'Какая из характеристик свойственна букве "$currentLetter"?',
      options: [
        'Имеет уникальное звуковое и графическое исполнение',
        'Это цифра',
        'Это знак препинания',
        'Не читается никогда'
      ],
      correctOptionIndex: 0,
    ));

    list.add(const QuizQuestion(
      questionText: 'С какой стороны начинается написание и чтение арабских букв?',
      options: ['Слева направо', 'Справа налево', 'Сверху вниз', 'Из центра'],
      correctOptionIndex: 1,
    ));

    list.add(const QuizQuestion(
      questionText: 'Может ли эта буква соединяться со следующей за ней буквой слева?',
      options: ['Зависит от свойств самой буквы', 'Всегда соединяется', 'Никогда не соединяется', 'Только в начале строки'],
      correctOptionIndex: 0,
    ));

    list.add(const QuizQuestion(
      questionText: 'Что помогает правильно поставить произношение?',
      options: ['Прослушивание и повторение за диктором', 'Только чтение про себя', 'Письмо от руки', 'Заучивание наизусть'],
      correctOptionIndex: 0,
    ));

    list.add(const QuizQuestion(
      questionText: 'Что изучается в данном уроке пособия «Муаллим Сани»?',
      options: ['Алфавит и правила чтения', 'Арифметика', 'Грамматика', 'История'],
      correctOptionIndex: 0,
    ));

    list.add(QuizQuestion(
      questionText: 'Встречается ли буква "$currentLetter" в священном Коране?',
      options: ['Да, как и все буквы арабского алфавита', 'Нет', 'Только в переводах', 'Редко'],
      correctOptionIndex: 0,
    ));

    list.add(const QuizQuestion(
      questionText: 'Готовы ли вы перейти к следующему уроку после усвоения материала?',
      options: ['Да, материал усвоен', 'Нужно повторить еще раз', 'Слишком сложно', 'Отказываюсь отвечать'],
      correctOptionIndex: 0,
    ));

    for (var q in list) {
      if (q.questionText.contains('Как называется')) {
        List<String> shuffledOpts = [currentLetter];
        while (shuffledOpts.length < 4) {
          String randomDummy = dummyLetters[random.nextInt(dummyLetters.length)];
          if (!shuffledOpts.contains(randomDummy)) shuffledOpts.add(randomDummy);
        }
        shuffledOpts.shuffle();
        int newCorrectIdx = shuffledOpts.indexOf(currentLetter);
        int index = list.indexOf(q);
        list[index] = QuizQuestion(
          questionText: q.questionText,
          options: shuffledOpts,
          correctOptionIndex: newCorrectIdx,
        );
      }
    }

    return list;
  }

  List<String> _getRandomOptions(String correct, List<String> pool, int count) {
    List<String> opts = [correct];
    while (opts.length < count) {
      String item = pool[Random().nextInt(pool.length)];
      if (!opts.contains(item)) opts.add(item);
    }
    opts.shuffle();
    return opts;
  }

  void _answerQuestion(int index) {
    if (_isAnswered) return;

    setState(() {
      _selectedAnswerIndex = index;
      _isAnswered = true;
      if (index == _generatedQuestions[_currentIndex].correctOptionIndex) {
        _score++;
      }
    });

    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() {
        _selectedAnswerIndex = null;
        _isAnswered = false;
        if (_currentIndex < _generatedQuestions.length - 1) {
          _currentIndex++;
        } else {
          _isFinished = true;
          double progressValue = _score / _generatedQuestions.length;
          SettingsService.instance.setLessonProgress(widget.lessonId, progressValue);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isFinished) {
      int total = _generatedQuestions.length;
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

    final question = _generatedQuestions[_currentIndex];

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
              value: (_currentIndex + 1) / _generatedQuestions.length,
              backgroundColor: Colors.teal.shade100,
              color: Colors.teal.shade700,
              minHeight: 10,
            ),
            const SizedBox(height: 20),
            Text(
              'Вопрос ${_currentIndex + 1} из ${_generatedQuestions.length}',
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
                  onPressed: () => _answerQuestion(index),
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
  }
}