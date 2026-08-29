import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/letter_model.dart';
import '../services/settings_service.dart';
import '../services/analytics_service.dart';
import 'detail_screen.dart';
import 'settings_screen.dart';
import 'auth_payment_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<LetterModel> _lettersData = [];
  bool _isLoading = true;
  late final PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.78);
    _loadJsonData();
    AnalyticsService.instance.logScreenView(screenName: 'HomeScreen');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadJsonData() async {
    try {
      final String response = await rootBundle.loadString('assets/letters_data.json');
      final List<dynamic> data = json.decode(response);
      if (!mounted) return;
      setState(() {
        _lettersData = data
            .map((item) => LetterModel.fromJson(item))
            .take(27)
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showPaywallDialog(BuildContext dialogContext, bool isDark) {
    AnalyticsService.instance.logPaywallViewed();
    showDialog(
      context: dialogContext,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.workspace_premium_rounded, color: Color(0xFFFFD700), size: 28),
            const SizedBox(width: 8),
            Text(
              'Премиум доступ',
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
            ),
          ],
        ),
        content: Text(
          'Вторая половина уроков доступна только в Премиум-версии. Разблокируйте все уроки и занимайтесь без ограничений!',
          style: TextStyle(fontSize: 15, color: isDark ? Colors.white70 : Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFB703),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await Navigator.push(
                dialogContext,
                MaterialPageRoute(
                  builder: (context) => const AuthPaymentScreen(),
                ),
              );
              if (!mounted) return;
              setState(() {});
            },
            child: const Text('Купить Premium', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _animateToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SettingsService.instance,
      builder: (context, child) {
        final settings = SettingsService.instance;
        final isDark = settings.isDarkMode;
        final isPremium = settings.isPremium;
        final unlockedCount = (_lettersData.length / 2).ceil();

        return Scaffold(
          body: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? const [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)] // Тёмный градиент
                    : const [Color(0xFFE8F5E9), Color(0xFFE0F2F1), Color(0xFFF4F7F6)], // Светлый мягкий градиент
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Шапка приложения
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox(width: 48),
                        Text(
                          'Арабские буквы',
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.teal.shade900,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.settings_outlined,
                            color: isDark ? Colors.white : Colors.teal.shade900,
                          ),
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SettingsScreen(),
                              ),
                            );
                            if (!mounted) return;
                            setState(() {});
                          },
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: _isLoading
                        ? Center(
                            child: CircularProgressIndicator(
                              color: isDark ? const Color(0xFF00E676) : Colors.teal.shade700,
                            ),
                          )
                        : Stack(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 20.0),
                                child: PageView.builder(
                                  controller: _pageController,
                                  physics: const BouncingScrollPhysics(),
                                  itemCount: _lettersData.length,
                                  onPageChanged: (index) {
                                    setState(() {
                                      _currentIndex = index;
                                    });
                                  },
                                  itemBuilder: (context, index) {
                                    final letterData = _lettersData[index];
                                    final bool isLocked = !isPremium && index >= unlockedCount;

                                    return AnimatedBuilder(
                                      animation: _pageController,
                                      builder: (context, child) {
                                        double scale = 1.0;
                                        double opacity = 1.0;

                                        if (_pageController.position.haveDimensions) {
                                          double pageOffset = (_pageController.page! - index).abs();
                                          scale = (1 - (pageOffset * 0.18)).clamp(0.82, 1.0);
                                          opacity = (1 - (pageOffset * 0.45)).clamp(0.55, 1.0);
                                        } else {
                                          scale = index == 0 ? 1.0 : 0.82;
                                          opacity = index == 0 ? 1.0 : 0.55;
                                        }

                                        return Transform.scale(
                                          scale: scale,
                                          child: Opacity(
                                            opacity: opacity,
                                            child: child,
                                          ),
                                        );
                                      },
                                      child: LessonCardButton(
                                        letterData: letterData,
                                        isLocked: isLocked,
                                        isDark: isDark,
                                        onTap: () async {
                                          if (isLocked) {
                                            _showPaywallDialog(context, isDark);
                                            return;
                                          }

                                          AnalyticsService.instance.logLessonView(
                                            lessonId: letterData.id,
                                            title: letterData.title,
                                          );

                                          await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => DetailScreen(
                                                letterData: letterData,
                                                allLetters: _lettersData,
                                                currentIndex: index,
                                              ),
                                            ),
                                          );
                                          if (!mounted) return;
                                          setState(() {});
                                        },
                                      ),
                                    );
                                  },
                                ),
                              ),

                              // Кнопки-стрелки
                              if (_currentIndex > 0)
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 6.0),
                                    child: _CarouselArrowButton(
                                      icon: Icons.arrow_back_ios_new_rounded,
                                      isDark: isDark,
                                      onPressed: () => _animateToPage(_currentIndex - 1),
                                    ),
                                  ),
                                ),

                              if (_currentIndex < _lettersData.length - 1)
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 6.0),
                                    child: _CarouselArrowButton(
                                      icon: Icons.arrow_forward_ios_rounded,
                                      isDark: isDark,
                                      onPressed: () => _animateToPage(_currentIndex + 1),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CarouselArrowButton extends StatelessWidget {
  final IconData icon;
  final bool isDark;
  final VoidCallback onPressed;

  const _CarouselArrowButton({
    required this.icon,
    required this.isDark,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.12) : Colors.teal.shade800.withOpacity(0.85),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class LessonCardButton extends StatelessWidget {
  final LetterModel letterData;
  final bool isLocked;
  final bool isDark;
  final VoidCallback onTap;

  const LessonCardButton({
    super.key,
    required this.letterData,
    this.isLocked = false,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<double>(
      future: SettingsService.instance.getLessonProgress(letterData.id),
      builder: (context, snapshot) {
        double progress = snapshot.data ?? 0.0;

        // --- Настройки Палитры ---
        // Для светлой темы делаем сочную чистую карточку с изумрудным градиентом-акцентом
        final List<Color> cardGradient = isLocked
            ? (isDark
                ? [Colors.white.withOpacity(0.08), Colors.white.withOpacity(0.03)]
                : [const Color(0xFFE2E8F0), const Color(0xFFCBD5E1)])
            : (isDark
                ? const [Color(0xFF1F4037), Color(0xFF99F2C8)]
                : const [Color(0xFFFFFFFF), Color(0xFFF0FDF4)]); // Сочный свежий чистый белый -> мятный

        final Color borderColor = isLocked
            ? (isDark ? Colors.white.withOpacity(0.12) : const Color(0xFF94A3B8))
            : (isDark ? const Color(0xFF99F2C8).withOpacity(0.6) : const Color(0xFF10B981)); // Сочная изумрудная рамка

        return GestureDetector(
          onTap: onTap,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 10.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32.0),
              gradient: LinearGradient(
                colors: cardGradient,
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              boxShadow: [
                BoxShadow(
                  // В светлой теме делаем глубокую цветную тень, чтобы карточка "парила"
                  color: isDark
                      ? (isLocked ? Colors.black.withOpacity(0.2) : const Color(0xFF99F2C8).withOpacity(0.2))
                      : (isLocked 
                          ? Colors.black.withOpacity(0.06) 
                          : const Color(0xFF059669).withOpacity(0.22)), // Цветная изумрудная тень!
                  blurRadius: isDark ? 20 : 24,
                  spreadRadius: isDark ? 1 : 2,
                  offset: const Offset(0, 10),
                ),
              ],
              border: Border.all(
                color: borderColor, 
                width: isDark ? 1.5 : 2.5, // На светлой теме делаем контур более четким
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  // Шапка карточки
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark
                              ? (isLocked ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.25))
                              : (isLocked ? const Color(0xFFCBD5E1) : const Color(0xFF10B981)), // Яркая плашка
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          'УРОК № ${letterData.id}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                            color: isDark
                                ? (isLocked ? Colors.white60 : const Color(0xFFE0F2F1))
                                : (isLocked ? const Color(0xFF334155) : Colors.white), // Белый четкий текст
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 26,
                        height: 26,
                        child: isLocked
                            ? Icon(
                                Icons.lock_rounded, 
                                color: isDark ? Colors.amber : const Color(0xFFD97706), 
                                size: 22,
                              )
                            : CircularProgressIndicator(
                                value: progress,
                                strokeWidth: 3.5,
                                backgroundColor: isDark ? Colors.white.withOpacity(0.2) : const Color(0xFFA7F3D0),
                                color: isDark ? Colors.white : const Color(0xFF059669),
                              ),
                      ),
                    ],
                  ),

                  // Контент карточки
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: isLocked
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(22),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isDark 
                                          ? Colors.amber.withOpacity(0.15) 
                                          : const Color(0xFFFEF3C7),
                                      border: Border.all(
                                        color: isDark 
                                            ? Colors.amber.withOpacity(0.4) 
                                            : const Color(0xFFF59E0B),
                                        width: 2,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.lock_rounded,
                                      size: 52,
                                      color: isDark ? const Color(0xFFFFD700) : const Color(0xFFD97706),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: isDark 
                                          ? Colors.amber.withOpacity(0.2) 
                                          : const Color(0xFFFDE68A),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Text(
                                      'PREMIUM',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.5,
                                        color: isDark ? const Color(0xFFFFD700) : const Color(0xFFB45309),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(height: 8),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      letterData.variations.isNotEmpty
                                          ? letterData.variations.first.symbol
                                          : '${letterData.id}',
                                      style: TextStyle(
                                        fontSize: 98,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white : const Color(0xFF064E3B), // Глубокий сочный темный изумруд
                                      ),
                                    ),
                                  ),
                                  if (letterData.variations.isNotEmpty &&
                                      letterData.variations.first.transcription.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: isDark 
                                            ? Colors.black.withOpacity(0.2) 
                                            : const Color(0xFFD1FAE5),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: isDark 
                                              ? Colors.white.withOpacity(0.2) 
                                              : const Color(0xFF6EE7B7),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Text(
                                        letterData.variations.first.transcription.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 1.5,
                                          color: isDark ? Colors.white : const Color(0xFF047857),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Название урока
                  Text(
                    isLocked ? 'Доступно в Premium' : letterData.title,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: isLocked
                          ? (isDark ? Colors.white38 : const Color(0xFF64748B))
                          : (isDark ? Colors.white.withOpacity(0.9) : const Color(0xFF064E3B)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}