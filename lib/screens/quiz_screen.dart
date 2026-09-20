import 'dart:math' as math;
import 'dart:ui';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/quiz_question.dart';
import '../services/settings_service.dart';
import '../services/quiz_service.dart';
import '../services/analytics_service.dart';

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
  final AudioPlayer _audioPlayer = AudioPlayer();
  int _currentIndex = 0;
  int _score = 0;
  int? _selectedAnswerIndex;
  bool _isAnswered = false;
  bool _isFinished = false;

  // Баллы за текущий проход и всего
  int _earnedPoints = 0;
  int _totalPoints = 0;

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logScreenView(screenName: 'QuizScreen_${widget.lessonId}');
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _playSound(bool isCorrect) async {
    try {
      await _audioPlayer.stop();
      final String soundPath = isCorrect ? 'sounds/right.mp3' : 'sounds/error.mp3';
      await _audioPlayer.play(AssetSource(soundPath));
    } catch (e) {
      if (kDebugMode) {
        print("Ошибка при воспроизведении звука: $e");
      }
    }
  }

  void _resetQuiz() {
    setState(() {
      _currentIndex = 0;
      _score = 0;
      _selectedAnswerIndex = null;
      _isAnswered = false;
      _isFinished = false;
      _earnedPoints = 0;
    });
  }

  void _checkAndShowReviewDialog(double percentage) {
    if (percentage >= 85.0) {
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                'Отличный результат!',
                textAlign: TextAlign.center,
              ),
              content: const Text(
                'Вам нравится наше приложение? Пожалуйста, оставьте отзыв в RuStore — это очень поможет нам развиваться!',
                textAlign: TextAlign.center,
              ),
              actionsAlignment: MainAxisAlignment.spaceEvenly,
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Позже'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.of(dialogContext).pop();
                    final Uri appUri = Uri.parse(
                      'https://www.rustore.ru/catalog/app/com.abdteam.muali',
                    );
                    try {
                      await launchUrl(
                        appUri,
                        mode: LaunchMode.externalApplication,
                      );
                    } catch (e) {
                      if (kDebugMode) {
                        print("Ошибка при открытии ссылки RuStore: $e");
                      }
                    }
                  },
                  child: const Text('Оставить отзыв'),
                ),
              ],
            );
          },
        );
      });
    }
  }

  void _answerQuestion(int index, List<QuizQuestion> activeQuestions) {
    if (_isAnswered || _isFinished) return;

    final bool isCorrect = index == activeQuestions[_currentIndex].correctOptionIndex;
    _playSound(isCorrect);

    setState(() {
      _selectedAnswerIndex = index;
      _isAnswered = true;
      if (isCorrect) {
        _score++;
      }
    });

    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      if (_currentIndex < activeQuestions.length - 1) {
        setState(() {
          _selectedAnswerIndex = null;
          _isAnswered = false;
          _currentIndex++;
        });
      } else {
        final int previousBest = SettingsService.instance.getLessonBestScore(widget.lessonId);
        int pointsToAdd = 0;

        if (_score > previousBest) {
          pointsToAdd = _score - previousBest;
          SettingsService.instance.setLessonBestScore(widget.lessonId, _score);
          SettingsService.instance.addPoints(pointsToAdd);
        }

        final double progressValue = _score / activeQuestions.length;
        final double percentage = progressValue * 100;
        SettingsService.instance.setLessonProgress(widget.lessonId, progressValue);

        setState(() {
          _earnedPoints = pointsToAdd;
          _totalPoints = SettingsService.instance.getTotalPoints();
          _isFinished = true;
        });

        AnalyticsService.instance.logQuizCompleted(
          lessonId: widget.lessonId,
          score: _score,
          total: activeQuestions.length,
          percentage: percentage,
        );

        _checkAndShowReviewDialog(percentage);
      }
    });
  }

  Widget _buildOptionButton({
    required int index,
    required String optionText,
    required QuizQuestion question,
    required List<QuizQuestion> activeQuestions,
    required bool isDark,
    required double shortestSide,
  }) {
    Color cardGradientStart = isDark ? Colors.white.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.65);
    Color cardGradientEnd = isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white.withValues(alpha: 0.3);
    Color textColor = isDark ? Colors.white : const Color(0xFF0F5132);
    Color borderColor = isDark ? Colors.white.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.8);
    List<BoxShadow>? shadows = [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.06),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ];

    if (_isAnswered) {
      if (index == question.correctOptionIndex) {
        cardGradientStart = const Color(0xFF10B981).withValues(alpha: 0.85);
        cardGradientEnd = const Color(0xFF059669).withValues(alpha: 0.75);
        textColor = Colors.white;
        borderColor = const Color(0xFF34D399);
        shadows = [
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: 0.4),
            blurRadius: 14,
            spreadRadius: 1,
          )
        ];
      } else if (index == _selectedAnswerIndex) {
        cardGradientStart = const Color(0xFFEF4444).withValues(alpha: 0.85);
        cardGradientEnd = const Color(0xFFDC2626).withValues(alpha: 0.75);
        textColor = Colors.white;
        borderColor = const Color(0xFFFCA5A5);
        shadows = [
          BoxShadow(
            color: const Color(0xFFEF4444).withValues(alpha: 0.4),
            blurRadius: 14,
            spreadRadius: 1,
          )
        ];
      }
    }

    final bool isShortText = optionText.trim().length <= 3;
    final double fontSize = isShortText
        ? (shortestSide * 0.075).clamp(28.0, 48.0)
        : (shortestSide * 0.034).clamp(14.0, 18.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              colors: [cardGradientStart, cardGradientEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: borderColor,
              width: 1.2,
            ),
            boxShadow: shadows,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => _answerQuestion(index, activeQuestions),
              child: Padding(
                padding: EdgeInsets.all((shortestSide * 0.015).clamp(8.0, 14.0)),
                child: Center(
                  child: isShortText
                      ? FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            optionText,
                            style: TextStyle(
                              fontSize: fontSize,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        )
                      : Text(
                          optionText,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: fontSize,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                            height: 1.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionCard({
    required String questionText,
    required bool isDark,
    required double shortestSide,
  }) {
    final bool isQuestionShort = questionText.trim().length <= 3;

    return ClipRRect(
      borderRadius: BorderRadius.circular(28.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          padding: EdgeInsets.all((shortestSide * 0.045).clamp(16.0, 28.0)),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28.0),
            gradient: LinearGradient(
              colors: isDark
                  ? [Colors.white.withValues(alpha: 0.16), Colors.white.withValues(alpha: 0.04)]
                  : [Colors.white.withValues(alpha: 0.75), Colors.white.withValues(alpha: 0.35)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.9),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black.withValues(alpha: 0.3) : Colors.teal.shade900.withValues(alpha: 0.1),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Center(
            child: isQuestionShort
                ? FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      questionText,
                      style: TextStyle(
                        fontSize: (shortestSide * 0.12).clamp(48.0, 84.0),
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF064E3B),
                        shadows: [
                          Shadow(
                            color: isDark ? Colors.black.withValues(alpha: 0.3) : Colors.teal.shade900.withValues(alpha: 0.15),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                : SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Text(
                      questionText,
                      style: TextStyle(
                        fontSize: (shortestSide * 0.042).clamp(16.0, 24.0),
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF064E3B),
                        height: 1.35,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mediaQuery = MediaQuery.of(context);
    final double shortestSide = mediaQuery.size.shortestSide;
    final double screenWidth = mediaQuery.size.width;
    final double screenHeight = mediaQuery.size.height;
    final bool isLandscape = screenWidth > screenHeight;
    final bool isTablet = shortestSide >= 600;

    return StreamBuilder<List<QuizQuestion>>(
      stream: _quizService.streamQuestionsForLesson(widget.lessonId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return Scaffold(
            extendBodyBehindAppBar: true,
            body: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? const [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF0F2942)]
                      : const [Color(0xFFE2F1E7), Color(0xFFC8E6C9), Color(0xFFE8F5E9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: CircularProgressIndicator(color: isDark ? const Color(0xFF34D399) : Colors.teal.shade800),
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Scaffold(
            extendBodyBehindAppBar: true,
            body: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? const [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF0F2942)]
                      : const [Color(0xFFE2F1E7), Color(0xFFC8E6C9), Color(0xFFE8F5E9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: Padding(
                      padding: EdgeInsets.all((shortestSide * 0.05).clamp(20.0, 32.0)),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: isDark ? Colors.white.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.quiz_outlined,
                                  size: (shortestSide * 0.15).clamp(56.0, 80.0),
                                  color: isDark ? Colors.white70 : Colors.teal.shade700,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Вопросы для этого урока пока не добавлены. Скоро появятся!',
                                  style: TextStyle(
                                    fontSize: (shortestSide * 0.038).clamp(15.0, 18.0),
                                    color: isDark ? Colors.white : Colors.teal.shade900,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isDark ? const Color(0xFF10B981) : Colors.teal.shade800,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  ),
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Вернуться к урокам', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        final activeQuestions = snapshot.data!;
        if (_currentIndex >= activeQuestions.length) {
          _currentIndex = activeQuestions.length - 1;
        }

        final question = activeQuestions[_currentIndex];

        double percentage = 0;
        if (_isFinished) {
          percentage = (_score / activeQuestions.length) * 100;
        }

        final bool showTwoColumnGrid = isLandscape || isTablet;

        return Scaffold(
          extendBodyBehindAppBar: true,
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? const [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF0F2942)]
                    : const [Color(0xFFE2F1E7), Color(0xFFC8E6C9), Color(0xFFE8F5E9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                SafeArea(
                  child: Column(
                    children: [
                      // Seamless Glass Header
                      ClipRect(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              border: Border(
                                bottom: BorderSide(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.08)
                                      : Colors.teal.shade900.withValues(alpha: 0.08),
                                  width: 1.0,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                                  color: isDark ? Colors.white : const Color(0xFF0F5132),
                                  onPressed: () => Navigator.pop(context),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    _isFinished ? 'Результат теста' : 'Тест: ${widget.lessonTitle}',
                                    style: TextStyle(
                                      fontSize: (screenWidth * 0.022).clamp(15.0, 19.0),
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : const Color(0xFF0F5132),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Main Content Area
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: isTablet ? 32.0 : 16.0,
                            vertical: isTablet ? 20.0 : 12.0,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Glass Progress Bar
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  height: isTablet ? 10.0 : 7.0,
                                  color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.teal.shade900.withValues(alpha: 0.1),
                                  child: FractionallySizedBox(
                                    alignment: Alignment.centerLeft,
                                    widthFactor: (_currentIndex + 1) / activeQuestions.length,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF10B981),
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF10B981).withValues(alpha: 0.5),
                                            blurRadius: 8,
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Вопрос ${_currentIndex + 1} из ${activeQuestions.length}',
                                style: TextStyle(
                                  color: isDark ? const Color(0xFF34D399) : const Color(0xFF047857),
                                  fontSize: isTablet ? 15.0 : 13.0,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Expanded(
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  transitionBuilder: (Widget child, Animation<double> animation) {
                                    return FadeTransition(
                                      opacity: animation,
                                      child: ScaleTransition(
                                        scale: Tween<double>(begin: 0.96, end: 1.0).animate(animation),
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: Container(
                                    key: ValueKey<int>(_currentIndex),
                                    child: showTwoColumnGrid
                                        ? Row(
                                            crossAxisAlignment: CrossAxisAlignment.stretch,
                                            children: [
                                              Expanded(
                                                flex: 5,
                                                child: _buildQuestionCard(
                                                  questionText: question.questionText,
                                                  isDark: isDark,
                                                  shortestSide: shortestSide,
                                                ),
                                              ),
                                              const SizedBox(width: 18),
                                              Expanded(
                                                flex: 6,
                                                child: GridView.builder(
                                                  physics: const NeverScrollableScrollPhysics(),
                                                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                                    crossAxisCount: 2,
                                                    mainAxisSpacing: isTablet ? 16 : 12,
                                                    crossAxisSpacing: isTablet ? 16 : 12,
                                                    childAspectRatio: isTablet ? 2.2 : 1.8,
                                                  ),
                                                  itemCount: question.options.length,
                                                  itemBuilder: (context, index) {
                                                    return _buildOptionButton(
                                                      index: index,
                                                      optionText: question.options[index],
                                                      question: question,
                                                      activeQuestions: activeQuestions,
                                                      isDark: isDark,
                                                      shortestSide: shortestSide,
                                                    );
                                                  },
                                                ),
                                              ),
                                            ],
                                          )
                                        : Column(
                                            crossAxisAlignment: CrossAxisAlignment.stretch,
                                            children: [
                                              SizedBox(
                                                height: (screenHeight * 0.28).clamp(140.0, 260.0),
                                                child: _buildQuestionCard(
                                                  questionText: question.questionText,
                                                  isDark: isDark,
                                                  shortestSide: shortestSide,
                                                ),
                                              ),
                                              const SizedBox(height: 16),
                                              Expanded(
                                                child: ListView.builder(
                                                  physics: const NeverScrollableScrollPhysics(),
                                                  itemCount: question.options.length,
                                                  itemBuilder: (context, index) {
                                                    return Padding(
                                                      padding: const EdgeInsets.only(bottom: 12.0),
                                                      child: SizedBox(
                                                        height: (screenHeight * 0.088).clamp(52.0, 72.0),
                                                        child: _buildOptionButton(
                                                          index: index,
                                                          optionText: question.options[index],
                                                          question: question,
                                                          activeQuestions: activeQuestions,
                                                          isDark: isDark,
                                                          shortestSide: shortestSide,
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                if (_isFinished) ...[
                  Positioned.fill(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.45),
                      ),
                    ),
                  ),
                  if (percentage >= 70) const Positioned.fill(child: _ConfettiWidget()),
                  QuizResultModal(
                    score: _score,
                    totalQuestions: activeQuestions.length,
                    earnedPoints: _earnedPoints,
                    totalPoints: _totalPoints,
                    onReset: _resetQuiz,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class QuizResultModal extends StatelessWidget {
  final int score;
  final int totalQuestions;
  final int earnedPoints;
  final int totalPoints;
  final VoidCallback onReset;

  const QuizResultModal({
    super.key,
    required this.score,
    required this.totalQuestions,
    required this.earnedPoints,
    required this.totalPoints,
    required this.onReset,
  });

  Color _getResultColor(double percentage) {
    if (percentage < 35) {
      return const Color(0xFFEF4444);
    } else if (percentage < 70) {
      return const Color(0xFFF59E0B);
    } else {
      return const Color(0xFF10B981);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mediaQuery = MediaQuery.of(context);
    final double shortestSide = mediaQuery.size.shortestSide;
    final double screenWidth = mediaQuery.size.width;
    final double screenHeight = mediaQuery.size.height;
    final bool isLandscape = screenWidth > screenHeight;
    final bool isTablet = shortestSide >= 600;

    final double percentage = (score / totalQuestions) * 100;
    final Color resultColor = _getResultColor(percentage);

    final String titleText = percentage >= 85
        ? 'Отличный результат! 🎉'
        : (percentage >= 70
            ? 'Хорошая работа! 👍'
            : (percentage >= 35 ? 'Нормально! 💡' : 'Попробуй еще раз! 🔄'));

    final IconData iconData = percentage >= 70
        ? Icons.emoji_events_rounded
        : (percentage >= 35 ? Icons.thumb_up_alt_rounded : Icons.replay_rounded);

    final Widget progressWidget = Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: isTablet ? 120 : (isLandscape ? 80 : 100),
          height: isTablet ? 120 : (isLandscape ? 80 : 100),
          child: CircularProgressIndicator(
            value: score / totalQuestions,
            strokeWidth: isTablet ? 10 : 8,
            backgroundColor: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.teal.shade900.withValues(alpha: 0.1),
            color: resultColor,
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${percentage.toInt()}%',
              style: TextStyle(
                fontSize: isTablet ? 28 : (isLandscape ? 18 : 22),
                fontWeight: FontWeight.bold,
                color: resultColor,
              ),
            ),
            Text(
              '$score из $totalQuestions',
              style: TextStyle(
                fontSize: isTablet ? 13 : 11,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.teal.shade900,
              ),
            ),
          ],
        ),
      ],
    );

    final Widget pointsBadge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.black.withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.amber.shade600.withValues(alpha: 0.5),
          width: 1.2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.stars_rounded, color: Colors.amber.shade500, size: isTablet ? 24 : 20),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  earnedPoints > 0 ? '+$earnedPoints баллов!' : 'Рекорд не побит (+0)',
                  style: TextStyle(
                    fontSize: isTablet ? 13 : 12,
                    fontWeight: FontWeight.bold,
                    color: earnedPoints > 0
                        ? (isDark ? const Color(0xFF34D399) : const Color(0xFF047857))
                        : (isDark ? Colors.white70 : Colors.black54),
                  ),
                ),
                Text(
                  'Всего заработано: $totalPoints',
                  style: TextStyle(
                    fontSize: isTablet ? 11 : 10,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white60 : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    final Widget actionButtons = Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: onReset,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.white.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.refresh_rounded, size: isTablet ? 18 : 16, color: isDark ? Colors.white : Colors.black87),
                  const SizedBox(width: 6),
                  Text(
                    'Повторить',
                    style: TextStyle(
                      fontSize: isTablet ? 13 : 12,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [resultColor, resultColor.withValues(alpha: 0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: resultColor.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline_rounded, size: isTablet ? 18 : 16, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    'Завершить',
                    style: TextStyle(
                      fontSize: isTablet ? 13 : 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );

    final bool useHorizontalLayout = isTablet || isLandscape;

    return Center(
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              constraints: BoxConstraints(
                maxWidth: isTablet ? 600 : 420,
                maxHeight: screenHeight * 0.85,
              ),
              padding: EdgeInsets.all(isTablet ? 28 : 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: LinearGradient(
                  colors: isDark
                      ? [Colors.white.withValues(alpha: 0.18), Colors.white.withValues(alpha: 0.05)]
                      : [Colors.white.withValues(alpha: 0.85), Colors.white.withValues(alpha: 0.5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: isDark ? Colors.white.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.9),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 30,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: useHorizontalLayout
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: resultColor.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(iconData, size: isTablet ? 42 : 32, color: resultColor),
                              ),
                              const SizedBox(height: 12),
                              progressWidget,
                            ],
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  titleText,
                                  style: TextStyle(
                                    fontSize: isTablet ? 22 : 17,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : const Color(0xFF0F5132),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Вы правильно ответили на $score из $totalQuestions вопросов.',
                                  style: TextStyle(
                                    fontSize: isTablet ? 13 : 11,
                                    color: isDark ? Colors.white70 : Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                pointsBadge,
                                const SizedBox(height: 16),
                                actionButtons,
                              ],
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: resultColor.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(iconData, size: 36, color: resultColor),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            titleText,
                            style: TextStyle(
                              fontSize: (shortestSide * 0.05).clamp(18.0, 22.0),
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF0F5132),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          progressWidget,
                          const SizedBox(height: 12),
                          pointsBadge,
                          const SizedBox(height: 16),
                          actionButtons,
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ConfettiWidget extends StatefulWidget {
  const _ConfettiWidget();

  @override
  State<_ConfettiWidget> createState() => _ConfettiWidgetState();
}

class _ConfettiWidgetState extends State<_ConfettiWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final List<_Particle> _particles = List.generate(160, (index) => _Particle());

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _ConfettiPainter(_particles, _controller.value),
        );
      },
    );
  }
}

class _Particle {
  late double startX;
  late double startY;
  late double vx;
  late double vy;
  late double size;
  late Color color;
  late double rotation;
  late double rotationSpeed;
  late bool isCircle;

  _Particle() {
    final random = math.Random();
    startX = 0.1 + random.nextDouble() * 0.8;
    startY = -0.1 - random.nextDouble() * 0.4;
    vx = (random.nextDouble() - 0.5) * 0.8;
    vy = 0.5 + random.nextDouble() * 0.9;
    size = 6.0 + random.nextDouble() * 10.0;
    rotation = random.nextDouble() * math.pi * 2;
    rotationSpeed = (random.nextDouble() - 0.5) * 8.0;
    isCircle = random.nextBool();

    const palette = [
      Color(0xFFFFD700),
      Color(0xFFFF4081),
      Color(0xFF00E676),
      Color(0xFF00E5FF),
      Color(0xFFFF9100),
      Color(0xFFE040FB),
      Color(0xFFFF5252),
    ];
    color = palette[random.nextInt(palette.length)];
  }
}

class _ConfettiPainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  _ConfettiPainter(this.particles, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    for (var particle in particles) {
      final double currentX = (particle.startX + particle.vx * progress) * size.width;
      final double currentY = (particle.startY + particle.vy * progress) * size.height;
      final double opacity = (1.0 - (progress * 0.85)).clamp(0.0, 1.0);

      paint.color = particle.color.withValues(alpha: opacity);

      canvas.save();
      canvas.translate(currentX, currentY);
      canvas.rotate(particle.rotation + particle.rotationSpeed * progress);

      if (particle.isCircle) {
        canvas.drawCircle(Offset.zero, particle.size / 2, paint);
      } else {
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: particle.size,
            height: particle.size * 0.6,
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => true;
}