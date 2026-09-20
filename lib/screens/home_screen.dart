import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/letter_model.dart';
import '../services/settings_service.dart';
import '../services/analytics_service.dart';
import 'detail_screen.dart';
import 'settings_screen.dart';
import 'auth_payment_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _HomeContentScreen();
  }
}

class _HomeContentScreen extends StatefulWidget {
  const _HomeContentScreen();

  @override
  State<_HomeContentScreen> createState() => _HomeContentScreenState();
}

class _HomeContentScreenState extends State<_HomeContentScreen> {
  List<LetterModel> _lettersData = [];
  bool _isLoading = true;
  late PageController _pageController;
  int _currentIndex = 0;
  double _currentViewportFraction = 0.78;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: _currentViewportFraction);
    _loadJsonData();
    SettingsService.instance.updateStreak();
    AnalyticsService.instance.logScreenView(screenName: 'HomeScreen');
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowAnnouncement();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _checkAndShowAnnouncement() async {
    final announcement = SettingsService.instance.announcementData;
    if (announcement == null) return;

    final bool isActive = announcement['isActive'] ?? false;
    if (!isActive) return;

    final String announcementId = announcement['id']?.toString() ??
        announcement['updatedAt']?.toString() ??
        'default_announcement';
    
    final prefs = await SharedPreferences.getInstance();
    final lastSeenId = prefs.getString('last_seen_announcement_id');

    if (lastSeenId == announcementId) return;
    if (!mounted) return;

    final isDark = SettingsService.instance.isDarkMode;
    final String title = announcement['title'] ?? 'Важное уведомление';
    final String htmlContent = announcement['htmlContent'] ?? announcement['content'] ?? '';
    final String plainText = htmlContent.replaceAll(RegExp(r'<[^>]*>'), '');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => BackdropFilter( // NEW Liquid Glass Backdrop
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12), // NEW
        child: AlertDialog(
          backgroundColor: isDark // CHANGED
              ? const Color(0xFF0F172A).withValues(alpha: 0.6) // CHANGED Liquid Glass
              : Colors.white.withValues(alpha: 0.75), // CHANGED Liquid Glass
          shape: RoundedRectangleBorder( // CHANGED
            borderRadius: BorderRadius.circular(28), // CHANGED
            side: BorderSide( // NEW Liquid Glass Border
              color: isDark ? Colors.white.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.8), // NEW
              width: 1.5, // NEW
            ), // NEW
          ),
          title: Row(
            children: [
              const Icon(Icons.campaign_rounded, color: Colors.teal, size: 28),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 18),
                ),
              ),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 350, maxWidth: 400),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    plainText,
                    style: TextStyle(fontSize: 15, color: isDark ? Colors.white70 : Colors.black87),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                await prefs.setString('last_seen_announcement_id', announcementId);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Понятно', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ), // NEW
    );
  }

  void _showStreakScheduleModal(BuildContext context, SettingsService settings, bool isDark) {
    HapticFeedback.mediumImpact();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final currentWeekday = now.weekday;
    final monday = today.subtract(Duration(days: currentWeekday - 1));

    int activeDaysCount = settings.streakCount;
    DateTime? lastActiveDay;

    if (settings.lastLoginDate != null || settings.streakCount > 0) {
      lastActiveDay = today;
    }

    List<bool> activeDaysMask = List.filled(7, false);

    if (activeDaysCount > 0 && lastActiveDay != null) {
      for (int i = 0; i < activeDaysCount; i++) {
        final activeDate = lastActiveDay.subtract(Duration(days: i));
        final diffInDays = activeDate.difference(monday).inDays;
        if (diffInDays >= 0 && diffInDays < 7) {
          activeDaysMask[diffInDays] = true;
        }
      }
    }

    final daysOfWeek = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return ClipRRect( // NEW Liquid Glass Wrapper
          borderRadius: const BorderRadius.vertical(top: Radius.circular(36.0)), // CHANGED
          child: BackdropFilter( // NEW Liquid Glass Blur
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20), // NEW
            child: Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.65) : Colors.white.withValues(alpha: 0.8), // CHANGED
                borderRadius: const BorderRadius.vertical(top: Radius.circular(36.0)), // CHANGED
                border: Border( // NEW Glass top border
                  top: BorderSide( // NEW
                    color: isDark ? Colors.white.withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.9), // NEW
                    width: 1.5, // NEW
                  ), // NEW
                ), // NEW
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3), // CHANGED
                    blurRadius: 30, // CHANGED
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white30 : Colors.grey.shade400, // CHANGED
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFFF3B30).withValues(alpha: 0.15), // CHANGED
                      border: Border.all(
                        color: const Color(0xFFFF3B30).withValues(alpha: 0.3), // NEW
                        width: 1.5, // NEW
                      ),
                    ),
                    child: const Icon(
                      Icons.local_fire_department_rounded,
                      color: Color(0xFFFF3B30),
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${settings.streakCount} ${_getStreakDaysText(settings.streakCount)} подряд!',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Занимайтесь каждый день, чтобы развивать привычку!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'РАСПИСАНИЕ ТЕКУЩЕЙ НЕДЕЛИ',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: isDark ? Colors.tealAccent : Colors.teal.shade800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(7, (index) {
                      final dayDate = monday.add(Duration(days: index)); // CHANGED
                      final isToday = index == (currentWeekday - 1);
                      final isActive = activeDaysMask[index];

                      return Column(
                        children: [
                          Text(
                            daysOfWeek[index],
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                              color: isToday
                                  ? const Color(0xFF10B981)
                                  : (isDark ? Colors.white54 : Colors.black45),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isActive
                                  ? const Color(0xFF10B981)
                                  : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200),
                              border: isToday
                                  ? Border.all(color: const Color(0xFF10B981), width: 2)
                                  : null,
                            ),
                            child: Center(
                              child: isActive
                                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                                  : Text( // CHANGED
                                      '${dayDate.day}', // CHANGED
                                      style: TextStyle( // CHANGED
                                        fontSize: 13, // CHANGED
                                        fontWeight: isToday ? FontWeight.bold : FontWeight.w500, // CHANGED
                                        color: isToday // CHANGED
                                            ? const Color(0xFF10B981) // CHANGED
                                            : (isDark ? Colors.white70 : Colors.black54), // CHANGED
                                      ), // CHANGED
                                    ), // CHANGED
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Отлично', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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

  double _calculateViewportFraction(double screenWidth) {
    return (350.0 / screenWidth).clamp(0.35, 0.82);
  }

  void _updatePageControllerIfNeeded(double screenWidth) {
    final double targetFraction = _calculateViewportFraction(screenWidth);
    if ((targetFraction - _currentViewportFraction).abs() > 0.01) {
      _currentViewportFraction = targetFraction;
      final int previousIndex = _currentIndex;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _pageController.dispose();
        setState(() {
          _pageController = PageController(
            initialPage: previousIndex,
            viewportFraction: _currentViewportFraction,
          );
        });
      });
    }
  }

  String _getStreakDaysText(int count) {
    int num = count % 100;
    if (num >= 11 && num <= 19) {
      return 'дней';
    }
    int lastDigit = count % 10;
    if (lastDigit == 1) {
      return 'день';
    }
    if (lastDigit >= 2 && lastDigit <= 4) {
      return 'дня';
    }
    return 'дней';
  }

  Future<void> _loadJsonData() async {
    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('app_data')
          .doc('lessons_doc')
          .get();

      if (!mounted) return;

      if (docSnapshot.exists && docSnapshot.data() != null) {
        final String rawJson = docSnapshot.get('json_data') ?? '[]';
        final List<dynamic> data = json.decode(rawJson);
        
        setState(() {
          _lettersData = data
              .map((item) => LetterModel.fromJson(item))
              .take(27)
              .toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
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
      builder: (ctx) => BackdropFilter( // NEW Liquid Glass Backdrop
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12), // NEW
        child: AlertDialog(
          backgroundColor: isDark // CHANGED
              ? const Color(0xFF0F172A).withValues(alpha: 0.6) // CHANGED Liquid Glass
              : Colors.white.withValues(alpha: 0.75), // CHANGED Liquid Glass
          shape: RoundedRectangleBorder( // CHANGED
            borderRadius: BorderRadius.circular(28), // CHANGED
            side: BorderSide( // NEW Liquid Glass Border
              color: isDark ? Colors.white.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.8), // NEW
              width: 1.5, // NEW
            ), // NEW
          ),
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
                if (!mounted) return;
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
      ), // NEW
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
          body: LayoutBuilder(
            builder: (context, constraints) {
              final double screenWidth = constraints.maxWidth;
              _updatePageControllerIfNeeded(screenWidth);

              final double titleFontSize = (screenWidth * 0.032).clamp(20.0, 28.0);
              final double streakFontSize = (screenWidth * 0.022).clamp(14.0, 18.0);
              final double streakIconSize = (screenWidth * 0.035).clamp(22.0, 30.0);
              final double arrowSize = (screenWidth * 0.03).clamp(20.0, 28.0);
              final double badgeSize = (screenWidth * 0.18).clamp(64.0, 84.0);

              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? const [Color(0xFF0B132B), Color(0xFF1C2541), Color(0xFF3A506B)] // CHANGED Enhanced gradient for glass contrast
                        : const [Color(0xFFD8F3DC), Color(0xFFB7E4C7), Color(0xFFE9ECEF)], // CHANGED
                    begin: Alignment.topLeft, // CHANGED
                    end: Alignment.bottomRight, // CHANGED
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: (screenWidth * 0.04).clamp(16.0, 36.0),
                          vertical: (screenWidth * 0.015).clamp(8.0, 16.0),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Арабские буквы',
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.teal.shade900,
                                fontSize: titleFontSize,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            IconButton(
                              iconSize: streakIconSize,
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
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onLongPress: () => _showStreakScheduleModal(context, settings, isDark),
                              child: ClipOval( // NEW Liquid Glass Clip
                                child: BackdropFilter( // NEW Liquid Glass Blur
                                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16), // CHANGED
                                  child: Container(
                                    width: badgeSize,
                                    height: badgeSize,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient( // NEW Glass Highlight Gradient
                                        colors: isDark // NEW
                                            ? [Colors.white.withValues(alpha: 0.15), Colors.white.withValues(alpha: 0.03)] // NEW
                                            : [Colors.white.withValues(alpha: 0.65), Colors.white.withValues(alpha: 0.25)], // NEW
                                        begin: Alignment.topLeft, // NEW
                                        end: Alignment.bottomRight, // NEW
                                      ), // NEW
                                      border: Border.all(
                                        color: isDark ? const Color(0xFF10B981).withValues(alpha: 0.8) : const Color(0xFF10B981), // CHANGED
                                        width: 2.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF10B981).withValues(alpha: 0.35),
                                          blurRadius: 18, // CHANGED
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.local_fire_department_rounded,
                                          color: const Color(0xFFFF3B30),
                                          size: badgeSize * 0.44,
                                        ),
                                        Text(
                                          '${settings.streakCount}',
                                          style: TextStyle(
                                            color: isDark ? Colors.white : const Color(0xFF1F2937),
                                            fontSize: badgeSize * 0.3,
                                            fontWeight: FontWeight.w900,
                                            height: 0.95,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ), // NEW
                              ), // NEW
                            ),
                            const SizedBox(height: 8),
                            ClipRRect( // NEW Liquid Glass Clip
                              borderRadius: BorderRadius.circular(24.0), // NEW
                              child: BackdropFilter( // NEW Liquid Glass Blur
                                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16), // CHANGED
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: (screenWidth * 0.03).clamp(12.0, 18.0),
                                    vertical: (screenWidth * 0.01).clamp(6.0, 10.0),
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient( // NEW
                                      colors: isDark // NEW
                                          ? [Colors.amber.shade900.withValues(alpha: 0.35), Colors.amber.shade900.withValues(alpha: 0.1)] // NEW
                                          : [Colors.white.withValues(alpha: 0.7), Colors.white.withValues(alpha: 0.3)], // NEW
                                      begin: Alignment.topLeft, // NEW
                                      end: Alignment.bottomRight, // NEW
                                    ), // NEW
                                    borderRadius: BorderRadius.circular(24.0),
                                    border: Border.all(
                                      color: isDark
                                          ? Colors.amber.shade600.withValues(alpha: 0.5) // CHANGED
                                          : Colors.white.withValues(alpha: 0.9), // CHANGED
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: isDark
                                            ? Colors.amber.shade900.withValues(alpha: 0.25) // CHANGED
                                            : Colors.amber.shade200.withValues(alpha: 0.5), // CHANGED
                                        blurRadius: 12, // CHANGED
                                        offset: const Offset(0, 3), // CHANGED
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.stars_rounded,
                                        color: const Color(0xFFF59E0B),
                                        size: streakIconSize,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${settings.totalPoints}',
                                        style: TextStyle(
                                          fontSize: streakFontSize,
                                          fontWeight: FontWeight.w800,
                                          color: isDark ? Colors.amber.shade200 : const Color(0xFFB45309),
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ), // NEW
                            ), // NEW
                          ],
                        ),
                      ),
                      Expanded(
                        child: _isLoading
                            ? Center(
                                child: CircularProgressIndicator(
                                  color: isDark ? const Color.fromARGB(255, 255, 153, 0) : Colors.teal.shade700,
                                ),
                              )
                            : Stack(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 16.0),
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
                                              scale = (1 - (pageOffset * 0.15)).clamp(0.85, 1.0);
                                              opacity = (1 - (pageOffset * 0.4)).clamp(0.6, 1.0);
                                            } else {
                                              scale = index == 0 ? 1.0 : 0.85;
                                              opacity = index == 0 ? 1.0 : 0.6;
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
                                            screenWidth: screenWidth,
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
                                  if (_currentIndex > 0)
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Padding(
                                        padding: EdgeInsets.only(
                                          left: (screenWidth * 0.02).clamp(8.0, 20.0),
                                        ),
                                        child: _CarouselArrowButton(
                                          icon: Icons.arrow_back_ios_new_rounded,
                                          isDark: isDark,
                                          size: arrowSize,
                                          onPressed: () => _animateToPage(_currentIndex - 1),
                                        ),
                                      ),
                                    ),
                                  if (_currentIndex < _lettersData.length - 1)
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: Padding(
                                        padding: EdgeInsets.only(
                                          right: (screenWidth * 0.02).clamp(8.0, 20.0),
                                        ),
                                        child: _CarouselArrowButton(
                                          icon: Icons.arrow_forward_ios_rounded,
                                          isDark: isDark,
                                          size: arrowSize,
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
              );
            },
          ),
        );
      },
    );
  }
}

class _CarouselArrowButton extends StatelessWidget {
  final IconData icon;
  final bool isDark;
  final double size;
  final VoidCallback onPressed;

  const _CarouselArrowButton({
    required this.icon,
    required this.isDark,
    required this.size,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.12) : Colors.teal.shade800.withValues(alpha: 0.85),
        shape: BoxShape.circle,
        border: Border.all( // NEW Glass Border for Arrows
          color: isDark ? Colors.white.withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.6), // NEW
          width: 1.2, // NEW
        ), // NEW
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2), // CHANGED
            blurRadius: 12, // CHANGED
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12), // CHANGED
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              child: Padding(
                padding: EdgeInsets.all(size * 0.6),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: size,
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
  final double screenWidth;
  final VoidCallback onTap;

  const LessonCardButton({
    super.key,
    required this.letterData,
    this.isLocked = false,
    required this.isDark,
    required this.screenWidth,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final double shortestSide = mediaQuery.size.shortestSide;
    
    final double maxCardWidth = (shortestSide * 0.85).clamp(260.0, 440.0);
    final double titleFontSize = (shortestSide * 0.04).clamp(14.0, 18.0);
    final double transcriptionFontSize = (shortestSide * 0.035).clamp(12.0, 16.0);

    return FutureBuilder<double>(
      future: SettingsService.instance.getLessonProgress(letterData.id),
      builder: (context, snapshot) {
        final double progress = snapshot.data ?? 0.0;

        final List<Color> cardGradient = isLocked // CHANGED Premium Liquid Glass Gradient with reflex
            ? (isDark
                ? [Colors.white.withValues(alpha: 0.12), Colors.white.withValues(alpha: 0.02)] // CHANGED
                : [Colors.white.withValues(alpha: 0.55), Colors.white.withValues(alpha: 0.20)]) // CHANGED
            : (isDark
                ? [Colors.white.withValues(alpha: 0.22), Colors.white.withValues(alpha: 0.06)] // CHANGED
                : [Colors.white.withValues(alpha: 0.75), Colors.white.withValues(alpha: 0.35)]); // CHANGED

        final Color borderColor = isLocked // CHANGED Liquid Glass Border Highlight
            ? (isDark ? Colors.white.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.6)) // CHANGED
            : (isDark ? Colors.white.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.9)); // CHANGED

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxCardWidth),
            child: GestureDetector(
              onTap: onTap,
              child: ClipRRect( // NEW Liquid Glass Wrapper
                borderRadius: BorderRadius.circular(32.0), // NEW
                child: BackdropFilter( // NEW Liquid Glass Blur
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20), // CHANGED Production Level Blur
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(32.0),
                      gradient: LinearGradient(
                        colors: cardGradient,
                        begin: Alignment.topLeft, // CHANGED Reflection angle
                        end: Alignment.bottomRight, // CHANGED
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? (isLocked ? Colors.black.withValues(alpha: 0.3) : const Color(0xFF10B981).withValues(alpha: 0.2)) // CHANGED
                              : (isLocked 
                                  ? Colors.black.withValues(alpha: 0.08) 
                                  : const Color(0xFF059669).withValues(alpha: 0.18)), // CHANGED
                          blurRadius: isDark ? 28 : 32, // CHANGED
                          spreadRadius: isDark ? 1 : 2,
                          offset: const Offset(0, 12), // CHANGED
                        ),
                      ],
                      border: Border.all(
                        color: borderColor, 
                        width: isDark ? 1.5 : 2.0, // CHANGED
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all((shortestSide * 0.04).clamp(14.0, 24.0)),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? (isLocked ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.3)) // CHANGED
                                      : (isLocked ? Colors.black.withValues(alpha: 0.08) : const Color(0xFF10B981).withValues(alpha: 0.85)), // CHANGED
                                  borderRadius: BorderRadius.circular(14), // CHANGED
                                  border: Border.all( // NEW Sub-glass Border
                                    color: isDark ? Colors.white.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.5), // NEW
                                    width: 1.0, // NEW
                                  ), // NEW
                                ),
                                child: Text(
                                  'УРОК № ${letterData.id}',
                                  style: TextStyle(
                                    fontSize: (shortestSide * 0.03).clamp(11.0, 13.0),
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.8,
                                    color: isDark
                                        ? (isLocked ? Colors.white60 : const Color(0xFFE0F2F1))
                                        : (isLocked ? const Color(0xFF334155) : Colors.white),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: isLocked
                                    ? Icon(
                                        Icons.lock_rounded, 
                                        color: isDark ? Colors.amber : const Color(0xFFD97706), 
                                        size: 20,
                                      )
                                    : CircularProgressIndicator(
                                        value: progress,
                                        strokeWidth: 3.0,
                                        backgroundColor: isDark ? Colors.white.withValues(alpha: 0.2) : const Color(0xFFA7F3D0),
                                        color: isDark ? Colors.white : const Color(0xFF059669),
                                      ),
                              ),
                            ],
                          ),
                          Expanded(
                            child: isLocked
                                ? Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(18),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isDark 
                                              ? Colors.amber.withValues(alpha: 0.15) 
                                              : const Color(0xFFFEF3C7).withValues(alpha: 0.6), // CHANGED
                                          border: Border.all(
                                            color: isDark 
                                                ? Colors.amber.withValues(alpha: 0.4) 
                                                : const Color(0xFFF59E0B),
                                            width: 2,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.lock_rounded,
                                          size: (shortestSide * 0.1).clamp(36.0, 56.0),
                                          color: isDark ? const Color(0xFFFFD700) : const Color(0xFFD97706),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isDark 
                                              ? Colors.amber.withValues(alpha: 0.2) 
                                              : const Color(0xFFFDE68A).withValues(alpha: 0.8), // CHANGED
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all( // NEW
                                            color: isDark ? Colors.amber.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.6), // NEW
                                            width: 1.0, // NEW
                                          ),
                                        ),
                                        child: Text(
                                          'PREMIUM',
                                          style: TextStyle(
                                            fontSize: (shortestSide * 0.028).clamp(10.0, 13.0),
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
                                      const SizedBox(height: 6),
                                      Expanded(
                                        child: Center(
                                          child: FittedBox(
                                            fit: BoxFit.contain,
                                            child: Text(
                                              letterData.variations.isNotEmpty
                                                  ? letterData.variations.first.symbol
                                                  : '${letterData.id}',
                                              style: TextStyle(
                                                fontSize: 160,
                                                fontWeight: FontWeight.bold,
                                                color: isDark ? Colors.white : const Color(0xFF064E3B),
                                                shadows: [ // NEW Glass Depth Drop Shadow for Symbol
                                                  Shadow( // NEW
                                                    color: isDark ? Colors.black.withValues(alpha: 0.3) : Colors.teal.shade900.withValues(alpha: 0.15), // NEW
                                                    blurRadius: 10, // NEW
                                                    offset: const Offset(0, 4), // NEW
                                                  ), // NEW
                                                ], // NEW
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      if (letterData.variations.isNotEmpty &&
                                          letterData.variations.first.transcription.isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: isDark 
                                                ? Colors.black.withValues(alpha: 0.25) // CHANGED
                                                : Colors.white.withValues(alpha: 0.6), // CHANGED
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: isDark 
                                                  ? Colors.white.withValues(alpha: 0.2) 
                                                  : Colors.white.withValues(alpha: 0.9), // CHANGED
                                              width: 1.2,
                                            ),
                                          ),
                                          child: Text(
                                            letterData.variations.first.transcription.toUpperCase(),
                                            style: TextStyle(
                                              fontSize: transcriptionFontSize,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 1.2,
                                              color: isDark ? Colors.white : const Color(0xFF047857),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            isLocked ? 'Доступно в Premium' : letterData.title,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: titleFontSize,
                              fontWeight: FontWeight.w800,
                              color: isLocked
                                  ? (isDark ? Colors.white38 : const Color(0xFF64748B))
                                  : (isDark ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF064E3B)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ), // NEW
              ), // NEW
            ),
          ),
        );
      },
    );
  }
}