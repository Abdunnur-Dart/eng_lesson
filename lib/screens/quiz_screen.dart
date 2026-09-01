import 'dart:math' as math;
import 'package:flutter/material.dart';
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

  void _answerQuestion(int index, List<QuizQuestion> activeQuestions) {
    if (_isAnswered || _isFinished) return;

    setState(() {
      _selectedAnswerIndex = index;
      _isAnswered = true;
      if (index == activeQuestions[_currentIndex].correctOptionIndex) {
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
        // Расчет и добавление баллов при увеличении рекорда
        final int previousBest = SettingsService.instance.getLessonBestScore(widget.lessonId);
        int pointsToAdd = 0;

        if (_score > previousBest) {
          pointsToAdd = _score - previousBest;
          SettingsService.instance.setLessonBestScore(widget.lessonId, _score);
          SettingsService.instance.addPoints(pointsToAdd);
        }

        final double progressValue = _score / activeQuestions.length;
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
          percentage: progressValue * 100,
        );
      }
    });
  }

  Color _getResultColor(double percentage) {
    if (percentage < 35) {
      return Colors.red.shade700;
    } else if (percentage < 70) {
      return Colors.orange.shade800;
    } else {
      return Colors.green.shade700;
    }
  }

  Widget _buildOptionButton({
    required int index,
    required String optionText,
    required QuizQuestion question,
    required List<QuizQuestion> activeQuestions,
    required bool isDark,
    required double shortestSide,
  }) {
    Color buttonColor = isDark ? const Color(0xFF1E1E1E) : Colors.teal.shade50;
    Color textColor = isDark ? Colors.tealAccent.shade100 : Colors.teal.shade900;
    BorderSide borderSide = BorderSide(
      color: isDark ? const Color(0xFF2C2C2C) : Colors.teal.shade400,
      width: 1.5,
    );

    if (_isAnswered) {
      if (index == question.correctOptionIndex) {
        buttonColor = isDark ? Colors.green.shade800 : Colors.green.shade400;
        textColor = Colors.white;
        borderSide = const BorderSide(color: Colors.green, width: 2);
      } else if (index == _selectedAnswerIndex) {
        buttonColor = isDark ? Colors.red.shade800 : Colors.red.shade400;
        textColor = Colors.white;
        borderSide = const BorderSide(color: Colors.red, width: 2);
      }
    }

    final bool isShortText = optionText.trim().length <= 3;
    final double fontSize = isShortText
        ? (shortestSide * 0.08).clamp(32.0, 56.0)
        : (shortestSide * 0.035).clamp(16.0, 24.0);

    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        backgroundColor: buttonColor,
        side: borderSide,
        padding: EdgeInsets.all((shortestSide * 0.015).clamp(8.0, 16.0)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      onPressed: () => _answerQuestion(index, activeQuestions),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            optionText,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isShortText ? FontWeight.w500 : FontWeight.w600,
              color: textColor,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildPointsBadge({
    required int earnedPoints,
    required int totalPoints,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2621) : Colors.amber.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.amber.shade600.withOpacity(0.5),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.stars_rounded, color: Colors.amber.shade600, size: 26),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                earnedPoints > 0 ? '+$earnedPoints баллов!' : 'Рекорд не побит (+0)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: earnedPoints > 0
                      ? (isDark ? Colors.greenAccent : Colors.green.shade800)
                      : (isDark ? Colors.grey.shade400 : Colors.grey.shade700),
                ),
              ),
              Text(
                'Всего заработано: $totalPoints',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultModal({
    required BuildContext context,
    required double percentage,
    required int totalQuestions,
    required bool isDark,
    required bool isTablet,
    required bool isLandscape,
    required VoidCallback onReset,
  }) {
    final Color resultColor = _getResultColor(percentage);

    final Widget progressWidget = Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: isTablet ? 140 : 115,
          height: isTablet ? 140 : 115,
          child: CircularProgressIndicator(
            value: _score / totalQuestions,
            strokeWidth: isTablet ? 12 : 10,
            backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
            color: resultColor,
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${percentage.toInt()}%',
              style: TextStyle(
                fontSize: isTablet ? 36 : 28,
                fontWeight: FontWeight.bold,
                color: resultColor,
              ),
            ),
            Text(
              '$_score из $totalQuestions',
              style: TextStyle(
                fontSize: isTablet ? 15 : 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ],
    );

    final String titleText = percentage >= 85
        ? 'Отличный результат! 🎉'
        : (percentage >= 70
            ? 'Хорошая работа! 👍'
            : (percentage >= 35 ? 'Нормально! 💡' : 'Попробуй еще раз! 🔄'));

    final IconData iconData = percentage >= 70
        ? Icons.emoji_events_rounded
        : (percentage >= 35 ? Icons.thumb_up_alt_rounded : Icons.replay_rounded);

    final Widget actionButtons = Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: Size(0, isTablet ? 50 : 44),
              side: BorderSide(color: resultColor, width: 1.8),
              foregroundColor: resultColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: onReset,
            icon: Icon(Icons.refresh_rounded, size: isTablet ? 18 : 15),
            label: Text(
              'Повторить',
              style: TextStyle(fontSize: isTablet ? 13 : 11, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              minimumSize: Size(0, isTablet ? 50 : 44),
              backgroundColor: resultColor,
              foregroundColor: Colors.white,
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.check_circle_outline_rounded, size: isTablet ? 18 : 15),
            label: Text(
              'Завершить',
              style: TextStyle(fontSize: isTablet ? 13 : 11, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );

    final bool useHorizontalLayout = isTablet || isLandscape;

    return Center(
      child: Container(
        width: isTablet ? 640 : (MediaQuery.of(context).size.width * 0.9).clamp(280.0, 440.0),
        margin: const EdgeInsets.all(20),
        padding: EdgeInsets.all(isTablet ? 32 : 24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF242424) : Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 30,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: useHorizontalLayout
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: resultColor.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(iconData, size: isTablet ? 52 : 40, color: resultColor),
                      ),
                      const SizedBox(height: 16),
                      progressWidget,
                    ],
                  ),
                  const SizedBox(width: 32),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          titleText,
                          style: TextStyle(
                            fontSize: isTablet ? 26 : 20,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Вы правильно ответили на $_score из $totalQuestions вопросов.',
                          style: TextStyle(
                            fontSize: isTablet ? 15 : 13,
                            color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildPointsBadge(
                          earnedPoints: _earnedPoints,
                          totalPoints: _totalPoints,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 24),
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
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: resultColor.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(iconData, size: 48, color: resultColor),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    titleText,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  progressWidget,
                  const SizedBox(height: 16),
                  _buildPointsBadge(
                    earnedPoints: _earnedPoints,
                    totalPoints: _totalPoints,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 20),
                  actionButtons,
                ],
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
        final Color scaffoldBg = isDark ? Theme.of(context).scaffoldBackgroundColor : Colors.grey.shade50;
        Color appBarBg = isDark ? const Color(0xFF1E1E1E) : Colors.teal.shade800;

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: scaffoldBg,
            appBar: AppBar(
              title: Text('Тест: ${widget.lessonTitle}'),
              backgroundColor: appBarBg,
              foregroundColor: Colors.white,
            ),
            body: Center(
              child: CircularProgressIndicator(color: isDark ? Colors.tealAccent : Colors.teal),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Scaffold(
            backgroundColor: scaffoldBg,
            appBar: AppBar(
              title: Text('Тест: ${widget.lessonTitle}'),
              backgroundColor: appBarBg,
              foregroundColor: Colors.white,
            ),
            body: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Padding(
                  padding: EdgeInsets.all((shortestSide * 0.05).clamp(20.0, 32.0)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.quiz_outlined,
                        size: (shortestSide * 0.15).clamp(56.0, 80.0),
                        color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Вопросы для этого урока пока не добавлены. Скоро появятся!',
                        style: TextStyle(
                          fontSize: (shortestSide * 0.038).clamp(15.0, 18.0),
                          color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? Colors.tealAccent.shade700 : Colors.teal.shade700,
                          foregroundColor: isDark ? Colors.black : Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Вернуться к урокам', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
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
        final bool isQuestionShort = question.questionText.trim().length <= 3;
        final double questionFontSize = isQuestionShort
            ? (shortestSide * 0.1).clamp(44.0, 80.0)
            : (shortestSide * 0.04).clamp(18.0, 28.0);

        double percentage = 0;
        if (_isFinished) {
          percentage = (_score / activeQuestions.length) * 100;
          appBarBg = _getResultColor(percentage);
        }

        final bool showTwoColumnGrid = isLandscape || isTablet;

        return Scaffold(
          backgroundColor: scaffoldBg,
          appBar: AppBar(
            title: Text(_isFinished ? 'Результат теста' : 'Тест: ${widget.lessonTitle}'),
            backgroundColor: appBarBg,
            foregroundColor: Colors.white,
            elevation: _isFinished ? 4 : 0,
          ),
          body: Stack(
            children: [
              SafeArea(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 32.0 : 16.0,
                    vertical: isTablet ? 20.0 : 12.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: (_currentIndex + 1) / activeQuestions.length,
                          backgroundColor: isDark ? Colors.grey.shade800 : Colors.teal.shade100,
                          color: isDark ? Colors.tealAccent.shade400 : Colors.teal.shade700,
                          minHeight: isTablet ? 12.0 : 8.0,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Вопрос ${_currentIndex + 1} из ${activeQuestions.length}',
                        style: TextStyle(
                          color: isDark ? Colors.tealAccent.shade100 : Colors.grey.shade700,
                          fontSize: isTablet ? 16.0 : 13.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Expanded(
                        child: showTwoColumnGrid
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    flex: 5,
                                    child: Container(
                                      padding: EdgeInsets.all(isTablet ? 28.0 : 16.0),
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                                        borderRadius: BorderRadius.circular(24),
                                        border: Border.all(
                                          color: isDark ? const Color(0xFF2C2C2C) : Colors.teal.shade100,
                                        ),
                                      ),
                                      child: Center(
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            question.questionText,
                                            style: TextStyle(
                                              fontSize: questionFontSize,
                                              fontWeight: isQuestionShort ? FontWeight.w500 : FontWeight.bold,
                                              color: isDark ? Colors.white : Colors.teal.shade900,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
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
                                  Container(
                                    height: (screenHeight * 0.28).clamp(140.0, 260.0),
                                    padding: const EdgeInsets.all(18),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(
                                        color: isDark ? const Color(0xFF2C2C2C) : Colors.teal.shade100,
                                      ),
                                    ),
                                    child: Center(
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          question.questionText,
                                          style: TextStyle(
                                            fontSize: questionFontSize,
                                            fontWeight: isQuestionShort ? FontWeight.w500 : FontWeight.bold,
                                            color: isDark ? Colors.white : Colors.teal.shade900,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
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
                                            height: (screenHeight * 0.09).clamp(52.0, 72.0),
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
                    ],
                  ),
                ),
              ),

              if (_isFinished) ...[
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withOpacity(0.65),
                  ),
                ),
                if (percentage >= 70) const Positioned.fill(child: _ConfettiWidget()),
                _buildResultModal(
                  context: context,
                  percentage: percentage,
                  totalQuestions: activeQuestions.length,
                  isDark: isDark,
                  isTablet: isTablet,
                  isLandscape: isLandscape,
                  onReset: _resetQuiz,
                ),
              ],
            ],
          ),
        );
      },
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

      paint.color = particle.color.withOpacity(opacity);

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