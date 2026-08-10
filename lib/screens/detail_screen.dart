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

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.teal.shade800,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          appBarTitle,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        actions: [
          TextButton(
            onPressed: () => _openQuiz(context, letter),
            child: const Text(
              'ТЕСТЫ',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Индикатор страниц сверху
            if (totalItems > 1)
              _PageIndicator(
                totalItems: totalItems,
                currentIndex: _currentIndex,
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

                  // Единый стабильный скролл для всех страниц без резких переключений физики
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          const SizedBox(height: 12),
                          _SymbolCard(
                            symbol: symbol,
                            transcription: transcription,
                          ),
                          if (hasDescription) ...[
                            const SizedBox(height: 24),
                            _DescriptionSection(description: letter.description),
                          ],
                          const SizedBox(height: 24),
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
              onPrevious: () => _goToPage(_currentIndex - 1),
              onNext: () => _goToPage(_currentIndex + 1),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Выделенные изолированные виджеты ---

class _PageIndicator extends StatelessWidget {
  final int totalItems;
  final int currentIndex;

  const _PageIndicator({
    required this.totalItems,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          totalItems,
          (index) => AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 4.0),
            height: 8.0,
            width: currentIndex == index ? 24.0 : 8.0,
            decoration: BoxDecoration(
              color: currentIndex == index
                  ? Colors.teal.shade800
                  : Colors.teal.shade200,
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

  const _SymbolCard({
    required this.symbol,
    required this.transcription,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 24.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24.0),
          boxShadow: [
            BoxShadow(
              color: Colors.teal.shade900.withOpacity(0.08),
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(
            color: Colors.teal.shade100,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                symbol,
                style: TextStyle(
                  fontSize: 120,
                  fontWeight: FontWeight.w400,
                  color: Colors.teal.shade900,
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (transcription.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  transcription,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: Colors.teal.shade800,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DescriptionSection extends StatelessWidget {
  final String description;

  const _DescriptionSection({required this.description});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.teal.shade100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Описание',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.teal.shade900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  final int totalItems;
  final int currentIndex;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const _BottomNavBar({
    required this.totalItems,
    required this.currentIndex,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.teal.shade900.withOpacity(0.06),
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
                backgroundColor: Colors.teal.shade50,
                foregroundColor: Colors.teal.shade800,
                disabledBackgroundColor: Colors.grey.shade100,
                disabledForegroundColor: Colors.grey.shade400,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.arrow_back_ios, size: 16),
                  SizedBox(width: 4),
                  Text('Назад', style: TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: currentIndex < totalItems - 1 ? onNext : null,
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: Colors.teal.shade800,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade100,
                disabledForegroundColor: Colors.grey.shade400,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Row(
                children: [
                  Text('Далее', style: TextStyle(fontWeight: FontWeight.w600)),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_ios, size: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}