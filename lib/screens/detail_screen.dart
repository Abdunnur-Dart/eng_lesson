import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/letter_model.dart';
import 'quiz_screen.dart';

class DetailScreen extends StatefulWidget {
  final LetterModel letterData;

  const DetailScreen({
    super.key,
    required this.letterData,
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
          child: Column(
            children: [
              // Fully Seamless Liquid Glass Header
              ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                    decoration: BoxDecoration(
                      color: Colors.transparent, // Completely seamless with body
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
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final double titleFontSize =
                                  (MediaQuery.of(context).size.width * 0.022).clamp(15.0, 19.0);
                              return Text(
                                appBarTitle,
                                style: TextStyle(
                                  fontSize: titleFontSize,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.3,
                                  color: isDark ? Colors.white : const Color(0xFF0F5132),
                                ),
                              );
                            },
                          ),
                        ),
                        Builder(
                          builder: (context) {
                            final double btnFontSize =
                                (MediaQuery.of(context).size.width * 0.02).clamp(12.0, 15.0);
                            return InkWell(
                              onTap: () => _openQuiz(context, letter),
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: isDark
                                        ? [
                                            const Color(0xFF10B981).withValues(alpha: 0.25),
                                            const Color(0xFF059669).withValues(alpha: 0.1)
                                          ]
                                        : [
                                            Colors.white.withValues(alpha: 0.7),
                                            Colors.white.withValues(alpha: 0.3)
                                          ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isDark
                                        ? const Color(0xFF10B981).withValues(alpha: 0.5)
                                        : const Color(0xFF059669).withValues(alpha: 0.3),
                                    width: 1.2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.quiz_rounded,
                                      size: 16,
                                      color: isDark ? const Color(0xFF34D399) : const Color(0xFF059669),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'ТЕСТЫ',
                                      style: TextStyle(
                                        color: isDark ? const Color(0xFF34D399) : const Color(0xFF059669),
                                        fontWeight: FontWeight.w800,
                                        fontSize: btnFontSize,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 4),
                      ],
                    ),
                  ),
                ),
              ),

              // Layout Body
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final double screenWidth = constraints.maxWidth;
                    final double screenHeight = constraints.maxHeight;
                    final bool isWideScreen = screenWidth > screenHeight || screenWidth > 600;

                    return Column(
                      children: [
                        if (totalItems > 1)
                          _PageIndicator(
                            totalItems: totalItems,
                            currentIndex: _currentIndex,
                            screenWidth: screenWidth,
                          ),

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
                              final String symbol = variation?.symbol ?? letter.title;
                              final String transcription = variation?.transcription.toUpperCase() ?? '';
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
            ],
          ),
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

    final double activeWidth = (screenWidth * 0.06).clamp(22.0, 34.0);
    final double inactiveWidth = (screenWidth * 0.018).clamp(6.0, 10.0);
    final double height = (screenWidth * 0.015).clamp(6.0, 9.0);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: (screenWidth * 0.02).clamp(10.0, 18.0)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          totalItems,
          (index) => AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(horizontal: 4.0),
            height: height,
            width: currentIndex == index ? activeWidth : inactiveWidth,
            decoration: BoxDecoration(
              color: currentIndex == index
                  ? const Color(0xFF10B981)
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.15)
                      : Colors.teal.shade900.withValues(alpha: 0.15)),
              borderRadius: BorderRadius.circular(10.0),
              boxShadow: currentIndex == index
                  ? [
                      BoxShadow(
                        color: const Color(0xFF10B981).withValues(alpha: 0.45),
                        blurRadius: 10,
                        spreadRadius: 1,
                      )
                    ]
                  : null,
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
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32.0),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all((shortestSide * 0.04).clamp(16.0, 28.0)),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32.0),
                gradient: LinearGradient(
                  colors: isDark
                      ? [Colors.white.withValues(alpha: 0.18), Colors.white.withValues(alpha: 0.04)]
                      : [Colors.white.withValues(alpha: 0.75), Colors.white.withValues(alpha: 0.35)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.35)
                        : Colors.teal.shade900.withValues(alpha: 0.12),
                    blurRadius: 28,
                    spreadRadius: 1,
                    offset: const Offset(0, 12),
                  ),
                ],
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.3)
                      : Colors.white.withValues(alpha: 0.9),
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
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF064E3B),
                            shadows: [
                              Shadow(
                                color: isDark
                                    ? Colors.black.withValues(alpha: 0.3)
                                    : Colors.teal.shade900.withValues(alpha: 0.15),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
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
                        color: isDark
                            ? Colors.black.withValues(alpha: 0.3)
                            : Colors.white.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.2)
                              : Colors.white.withValues(alpha: 0.9),
                          width: 1.2,
                        ),
                      ),
                      child: Text(
                        transcription,
                        style: TextStyle(
                          fontSize: transcriptionFontSize,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                          color: isDark ? const Color(0xFF34D399) : const Color(0xFF047857),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
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
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24.0),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all((shortestSide * 0.04).clamp(14.0, 24.0)),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24.0),
                gradient: LinearGradient(
                  colors: isDark
                      ? [Colors.white.withValues(alpha: 0.14), Colors.white.withValues(alpha: 0.03)]
                      : [Colors.white.withValues(alpha: 0.65), Colors.white.withValues(alpha: 0.3)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.25)
                      : Colors.white.withValues(alpha: 0.8),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Описание',
                    style: TextStyle(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.bold,
                      color: isDark ? const Color(0xFF34D399) : const Color(0xFF065F46),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: textFontSize,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.85)
                          : Colors.black.withValues(alpha: 0.8),
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
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

    final bool canGoNext = currentIndex < totalItems - 1;
    final bool canGoPrev = currentIndex > 0;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: (screenWidth * 0.04).clamp(16.0, 32.0),
            vertical: (screenWidth * 0.02).clamp(10.0, 16.0),
          ),
          decoration: BoxDecoration(
            color: Colors.transparent, // Completely seamless base
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.teal.shade900.withValues(alpha: 0.08),
                width: 1.0,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Glass Back Button
                InkWell(
                  onTap: canGoPrev ? onPrevious : null,
                  borderRadius: BorderRadius.circular(18),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.symmetric(
                      horizontal: (shortestSide * 0.05).clamp(16.0, 26.0),
                      vertical: (shortestSide * 0.025).clamp(10.0, 16.0),
                    ),
                    decoration: BoxDecoration(
                      color: canGoPrev
                          ? (isDark
                              ? Colors.white.withValues(alpha: 0.12)
                              : Colors.white.withValues(alpha: 0.6))
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: canGoPrev
                            ? (isDark
                                ? Colors.white.withValues(alpha: 0.25)
                                : Colors.white.withValues(alpha: 0.9))
                            : Colors.transparent,
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: iconSize,
                          color: canGoPrev
                              ? (isDark ? Colors.white : const Color(0xFF0F5132))
                              : (isDark ? Colors.white24 : Colors.grey.shade400),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Назад',
                          style: TextStyle(
                            fontSize: buttonFontSize,
                            fontWeight: FontWeight.bold,
                            color: canGoPrev
                                ? (isDark ? Colors.white : const Color(0xFF0F5132))
                                : (isDark ? Colors.white24 : Colors.grey.shade400),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Liquid Emerald Action Next Button
                InkWell(
                  onTap: canGoNext ? onNext : null,
                  borderRadius: BorderRadius.circular(18),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.symmetric(
                      horizontal: (shortestSide * 0.06).clamp(20.0, 30.0),
                      vertical: (shortestSide * 0.025).clamp(10.0, 16.0),
                    ),
                    decoration: BoxDecoration(
                      gradient: canGoNext
                          ? const LinearGradient(
                              colors: [Color(0xFF10B981), Color(0xFF059669)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: canGoNext
                          ? null
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.black.withValues(alpha: 0.05)),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: canGoNext
                          ? [
                              BoxShadow(
                                color: const Color(0xFF10B981).withValues(alpha: 0.4),
                                blurRadius: 16,
                                spreadRadius: 1,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Далее',
                          style: TextStyle(
                            fontSize: buttonFontSize,
                            fontWeight: FontWeight.bold,
                            color: canGoNext
                                ? Colors.white
                                : (isDark ? Colors.white24 : Colors.grey.shade400),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: iconSize,
                          color: canGoNext
                              ? Colors.white
                              : (isDark ? Colors.white24 : Colors.grey.shade400),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}