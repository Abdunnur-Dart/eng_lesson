import 'package:flutter/material.dart';
import '../models/letter_model.dart';
import 'quiz_screen.dart';

class DetailScreen extends StatefulWidget {
  final LetterModel letterData;
  final List<LetterModel>? allLetters;
  final int? currentIndex;

  const DetailScreen({
    super.key,
    required this.letterData,
    this.allLetters,
    this.currentIndex,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late final PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _openQuiz(BuildContext context, LetterModel letter) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuizScreen(
          lessonId: letter.id,
          lessonTitle: letter.title,
          questions: const [],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final letter = widget.letterData;
    final variations = letter.variations;
    final totalItems = variations.isNotEmpty ? variations.length : 1;
    final appBarTitle = 'Урок № ${letter.id}: ${letter.title}';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Theme.of(context).scaffoldBackgroundColor : Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.teal.shade800,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: LayoutBuilder(
          builder: (context, constraints) {
            final double titleFontSize = (MediaQuery.of(context).size.width * 0.022).clamp(15.0, 19.0);
            return Text(
              appBarTitle,
              style: TextStyle(fontSize: titleFontSize, fontWeight: FontWeight.w600),
            );
          },
        ),
        actions: [
          Builder(
            builder: (context) {
              final double btnFontSize = (MediaQuery.of(context).size.width * 0.02).clamp(13.0, 16.0);
              return TextButton(
                onPressed: () => _openQuiz(context, letter),
                child: Text(
                  'ТЕСТЫ',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: btnFontSize,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double screenWidth = constraints.maxWidth;
            final double screenHeight = constraints.maxHeight;
            final bool isWideScreen = screenWidth > screenHeight || screenWidth > 600;

            return Column(
              children: [
                // Индикатор страниц сверху
                if (totalItems > 1)
                  _PageIndicator(
                    totalItems: totalItems,
                    currentIndex: _currentIndex,
                    screenWidth: screenWidth,
                  ),

                // Основная карусель
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: totalItems,
                    onPageChanged: (index) {
                      setState(() {
                        _currentIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      final variation = variations.isNotEmpty ? variations[index] : null;
                      String symbol = variation?.symbol ?? letter.title;
                      String transcription = variation?.transcription.toUpperCase() ?? '';

                      final bool hasDescription = index == 0 && letter.description.isNotEmpty;

                      return SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Padding(
                          padding: EdgeInsets.all((screenWidth * 0.035).clamp(16.0, 28.0)),
                          child: isWideScreen && hasDescription
                              ? Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      flex: 5,
                                      child: _SymbolCard(
                                        symbol: symbol,
                                        transcription: transcription,
                                        screenWidth: screenWidth,
                                      ),
                                    ),
                                    SizedBox(width: (screenWidth * 0.02).clamp(12.0, 24.0)),
                                    Expanded(
                                      flex: 6,
                                      child: _DescriptionSection(
                                        description: letter.description,
                                        screenWidth: screenWidth,
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  children: [
                                    SizedBox(height: (screenWidth * 0.015).clamp(8.0, 16.0)),
                                    _SymbolCard(
                                      symbol: symbol,
                                      transcription: transcription,
                                      screenWidth: screenWidth,
                                    ),
                                    if (hasDescription) ...[
                                      SizedBox(height: (screenWidth * 0.03).clamp(16.0, 28.0)),
                                      _DescriptionSection(
                                        description: letter.description,
                                        screenWidth: screenWidth,
                                      ),
                                    ],
                                    SizedBox(height: (screenWidth * 0.03).clamp(16.0, 28.0)),
                                  ],
                                ),
                        ),
                      );
                    },
                  ),
                ),

                // Нижняя панель навигации
                _BottomNavBar(
                  totalItems: totalItems,
                  currentIndex: _currentIndex,
                  screenWidth: screenWidth,
                  onPrevious: () => _goToPage(_currentIndex - 1),
                  onNext: () => _goToPage(_currentIndex + 1),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PageIndicator extends StatelessWidget {
  final int totalItems;
  final int currentIndex;
  final double screenWidth;

  const _PageIndicator({
    required this.totalItems,
    required this.currentIndex,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final double activeWidth = (screenWidth * 0.05).clamp(20.0, 32.0);
    final double inactiveWidth = (screenWidth * 0.018).clamp(6.0, 10.0);
    final double height = (screenWidth * 0.015).clamp(6.0, 9.0);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: (screenWidth * 0.02).clamp(10.0, 18.0)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          totalItems,
          (index) => AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 4.0),
            height: height,
            width: currentIndex == index ? activeWidth : inactiveWidth,
            decoration: BoxDecoration(
              color: currentIndex == index
                  ? (isDark ? Colors.tealAccent.shade700 : Colors.teal.shade800)
                  : (isDark ? Colors.grey.shade800 : Colors.teal.shade200),
              borderRadius: BorderRadius.circular(4.0),
            ),
          ),
        ),
      ),
    );
  }
}

class _SymbolCard extends StatelessWidget {
  final String symbol;
  final String transcription;
  final double screenWidth;

  const _SymbolCard({
    required this.symbol,
    required this.transcription,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mediaQuery = MediaQuery.of(context);
    final double shortestSide = mediaQuery.size.shortestSide;
    final double screenHeight = mediaQuery.size.height;

    final double maxCardWidth = (shortestSide * 0.85).clamp(280.0, 480.0);
    final double cardHeight = (screenHeight * 0.42).clamp(180.0, 340.0);
    final double transcriptionFontSize = (shortestSide * 0.038).clamp(14.0, 18.0);

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxCardWidth,
          maxHeight: cardHeight,
        ),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all((shortestSide * 0.04).clamp(16.0, 28.0)),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(28.0),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black.withOpacity(0.3) : Colors.teal.shade900.withOpacity(0.08),
                blurRadius: 20,
                spreadRadius: 2,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: isDark ? const Color(0xFF2C2C2C) : Colors.teal.shade100,
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: Text(
                      symbol,
                      style: TextStyle(
                        fontSize: 200,
                        fontWeight: FontWeight.w400,
                        color: isDark ? Colors.tealAccent.shade200 : Colors.teal.shade900,
                      ),
                    ),
                  ),
                ),
              ),
              if (transcription.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: (shortestSide * 0.035).clamp(12.0, 20.0),
                    vertical: (shortestSide * 0.015).clamp(5.0, 8.0),
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2A2A2A) : Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    transcription,
                    style: TextStyle(
                      fontSize: transcriptionFontSize,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: isDark ? Colors.tealAccent.shade400 : Colors.teal.shade800,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DescriptionSection extends StatelessWidget {
  final String description;
  final double screenWidth;

  const _DescriptionSection({
    required this.description,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final double shortestSide = MediaQuery.of(context).size.shortestSide;

    final double maxCardWidth = (shortestSide * 0.85).clamp(280.0, 520.0);
    final double titleFontSize = (shortestSide * 0.038).clamp(15.0, 19.0);
    final double textFontSize = (shortestSide * 0.032).clamp(13.0, 17.0);

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxCardWidth),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all((shortestSide * 0.04).clamp(14.0, 24.0)),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDark ? const Color(0xFF2C2C2C) : Colors.teal.shade100),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Описание',
                style: TextStyle(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.tealAccent.shade200 : Colors.teal.shade900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(
                  fontSize: textFontSize,
                  color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  final int totalItems;
  final int currentIndex;
  final double screenWidth;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const _BottomNavBar({
    required this.totalItems,
    required this.currentIndex,
    required this.screenWidth,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final double shortestSide = MediaQuery.of(context).size.shortestSide;

    final double buttonFontSize = (shortestSide * 0.032).clamp(13.0, 16.0);
    final double iconSize = (shortestSide * 0.032).clamp(14.0, 18.0);
    final EdgeInsets buttonPadding = EdgeInsets.symmetric(
      horizontal: (shortestSide * 0.04).clamp(14.0, 24.0),
      vertical: (shortestSide * 0.02).clamp(10.0, 16.0),
    );

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: (screenWidth * 0.04).clamp(16.0, 32.0),
        vertical: (screenWidth * 0.02).clamp(10.0, 16.0),
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.4) : Colors.teal.shade900.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ElevatedButton(
              onPressed: currentIndex > 0 ? onPrevious : null,
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: isDark ? const Color(0xFF2A2A2A) : Colors.teal.shade50,
                foregroundColor: isDark ? Colors.tealAccent.shade400 : Colors.teal.shade800,
                disabledBackgroundColor: isDark ? const Color(0xFF181818) : Colors.grey.shade100,
                disabledForegroundColor: isDark ? Colors.grey.shade700 : Colors.grey.shade400,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: buttonPadding,
              ),
              child: Row(
                children: [
                  Icon(Icons.arrow_back_ios, size: iconSize),
                  const SizedBox(width: 4),
                  Text(
                    'Назад',
                    style: TextStyle(fontSize: buttonFontSize, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: currentIndex < totalItems - 1 ? onNext : null,
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: isDark ? Colors.tealAccent.shade700 : Colors.teal.shade800,
                foregroundColor: isDark ? Colors.black : Colors.white,
                disabledBackgroundColor: isDark ? const Color(0xFF181818) : Colors.grey.shade100,
                disabledForegroundColor: isDark ? Colors.grey.shade700 : Colors.grey.shade400,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: buttonPadding,
              ),
              child: Row(
                children: [
                  Text(
                    'Далее',
                    style: TextStyle(fontSize: buttonFontSize, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward_ios, size: iconSize),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}