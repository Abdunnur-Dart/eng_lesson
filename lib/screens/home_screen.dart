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
import 'leaderboard_screen.dart';
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

  @override
  void initState() {
    super.initState();
    _loadJsonData();
    SettingsService.instance.updateStreak();
    AnalyticsService.instance.logScreenView(screenName: 'HomeScreen');
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowAnnouncement();
    });
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
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: AlertDialog(
          backgroundColor: isDark
              ? const Color(0xFF0F172A).withOpacity(0.85)
              : Colors.white.withOpacity(0.9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
            side: BorderSide(
              color: isDark ? Colors.white.withOpacity(0.2) : Colors.white.withOpacity(0.8),
              width: 1.5,
            ),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.campaign_rounded, color: Color(0xFF818CF8), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 350, maxWidth: 400),
            child: SingleChildScrollView(
              child: Text(
                plainText,
                style: TextStyle(fontSize: 15, color: isDark ? Colors.white70 : Colors.black87, height: 1.4),
              ),
            ),
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                  shadowColor: const Color(0xFF6366F1).withOpacity(0.4),
                ),
                onPressed: () async {
                  await prefs.setString('last_seen_announcement_id', announcementId);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('Понятно', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
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
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(36.0)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
            child: Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A).withOpacity(0.88) : Colors.white.withOpacity(0.9),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(36.0)),
                border: Border(
                  top: BorderSide(
                    color: isDark ? Colors.white.withOpacity(0.25) : Colors.white,
                    width: 1.5,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 35,
                    offset: const Offset(0, -10),
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
                      color: isDark ? Colors.white38 : Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFFF3B30).withOpacity(0.15),
                      border: Border.all(
                        color: const Color(0xFFFF3B30).withOpacity(0.4),
                        width: 1.5,
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
                      color: isDark ? const Color(0xFF818CF8) : const Color(0xFF4338CA),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(7, (index) {
                      final dayDate = monday.add(Duration(days: index));
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
                                  ? const Color(0xFF6366F1)
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
                                  ? const Color(0xFF6366F1)
                                  : (isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200),
                              border: isToday
                                  ? Border.all(color: const Color(0xFF6366F1), width: 2)
                                  : null,
                            ),
                            child: Center(
                              child: isActive
                                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                                  : Text(
                                      '${dayDate.day}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                                        color: isToday
                                            ? const Color(0xFF6366F1)
                                            : (isDark ? Colors.white70 : Colors.black54),
                                      ),
                                    ),
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
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                        shadowColor: const Color(0xFF6366F1).withOpacity(0.4),
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

  String _getStreakDaysText(int count) {
    int num = count % 100;
    if (num >= 11 && num <= 19) return 'дней';
    int lastDigit = count % 10;
    if (lastDigit == 1) return 'день';
    if (lastDigit >= 2 && lastDigit <= 4) return 'дня';
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
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _showPaywallDialog(BuildContext dialogContext, bool isDark) {
    AnalyticsService.instance.logPaywallViewed();
    showDialog(
      context: dialogContext,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: AlertDialog(
          backgroundColor: isDark
              ? const Color(0xFF0F172A).withOpacity(0.85)
              : Colors.white.withOpacity(0.9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
            side: BorderSide(
              color: isDark ? Colors.white.withOpacity(0.2) : Colors.white.withOpacity(0.8),
              width: 1.5,
            ),
          ),
          title: Row(
            children: [
              const Icon(Icons.workspace_premium_rounded, color: Color(0xFFFFD700), size: 28),
              const SizedBox(width: 12),
              Text(
                'Премиум доступ',
                style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Text(
            'Вторая половина уроков доступна только в Премиум-версии. Разблокируйте все уроки и занимайтесь без ограничений!',
            style: TextStyle(fontSize: 15, color: isDark ? Colors.white70 : Colors.black87, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Отмена', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFB703),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 4,
                shadowColor: const Color(0xFFFFB703).withOpacity(0.4),
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                if (!mounted) return;
                await Navigator.push(
                  dialogContext,
                  MaterialPageRoute(builder: (context) => const AuthPaymentScreen()),
                );
                if (!mounted) return;
                setState(() {});
              },
              child: const Text('Купить Premium', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
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
            duration: const Duration(milliseconds: 400),
            decoration: BoxDecoration(
              // Ультрасовременный сине-фиолетовый космический градиент (без зеленого)
              gradient: LinearGradient(
                colors: isDark
                    ? const [Color(0xFF0F172A), Color(0xFF1E1B4B), Color(0xFF09090B)]
                    : const [Color(0xFFF8FAFC), Color(0xFFEEF2FF), Color(0xFFE0E7FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Top Header with Ultra-Glass Buttons & Stats
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ИЗУЧЕНИЕ',
                              style: TextStyle(
                                color: isDark ? const Color(0xFF818CF8) : const Color(0xFF4338CA),
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Арабские буквы',
                              style: TextStyle(
                                color: isDark ? Colors.white : const Color(0xFF312E81),
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            GestureDetector(
                              onLongPress: () => _showStreakScheduleModal(context, settings, isDark),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(22),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                    decoration: BoxDecoration(
                                      color: isDark ? Colors.white.withOpacity(0.12) : Colors.white.withOpacity(0.8),
                                      borderRadius: BorderRadius.circular(22),
                                      border: Border.all(
                                        color: isDark ? Colors.white.withOpacity(0.25) : Colors.white,
                                        width: 1.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.local_fire_department_rounded, color: Color(0xFFFF3B30), size: 18),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${settings.streakCount}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: isDark ? Colors.white : Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text('•', style: TextStyle(color: isDark ? Colors.white38 : Colors.grey)),
                                        const SizedBox(width: 8),
                                        const Icon(Icons.stars_rounded, color: Color(0xFFF59E0B), size: 18),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${settings.totalPoints}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: isDark ? Colors.amber.shade200 : const Color(0xFFB45309),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildGlassIconButton(
                              icon: Icons.leaderboard_rounded,
                              isDark: isDark,
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const LeaderboardScreen()),
                              ),
                            ),
                            const SizedBox(width: 6),
                            _buildGlassIconButton(
                              icon: Icons.settings_outlined,
                              isDark: isDark,
                              onPressed: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
                                );
                                if (!mounted) return;
                                setState(() {});
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Main Lessons Bento Grid View
                  Expanded(
                    child: _isLoading
                        ? Center(
                            child: CircularProgressIndicator(
                              color: isDark ? const Color(0xFF818CF8) : const Color(0xFF4F46E5),
                            ),
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                            physics: const BouncingScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 0.85,
                            ),
                            itemCount: _lettersData.length,
                            itemBuilder: (context, index) {
                              final letterData = _lettersData[index];
                              final bool isLocked = !isPremium && index >= unlockedCount;

                              return ModernLessonCard(
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
                                      builder: (context) => DetailScreen(letterData: letterData),
                                    ),
                                  );
                                  if (!mounted) return;
                                  setState(() {});
                                },
                              );
                            },
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

  // Helper for ultra-glass icon buttons in the header
  Widget _buildGlassIconButton({required IconData icon, required bool isDark, required VoidCallback onPressed}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.25) : Colors.white,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Icon(icon, color: isDark ? Colors.white : const Color(0xFF312E81), size: 20),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ModernLessonCard extends StatelessWidget {
  final LetterModel letterData;
  final bool isLocked;
  final bool isDark;
  final VoidCallback onTap;

  const ModernLessonCard({
    super.key,
    required this.letterData,
    required this.isLocked,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<double>(
      future: SettingsService.instance.getLessonProgress(letterData.id),
      builder: (context, snapshot) {
        final double progress = snapshot.data ?? 0.0;

        final cardGradient = isLocked
            ? (isDark
                ? [Colors.white.withOpacity(0.08), Colors.white.withOpacity(0.02)]
                : [Colors.white.withOpacity(0.75), Colors.white.withOpacity(0.35)])
            : (isDark
                ? [Colors.white.withOpacity(0.15), Colors.white.withOpacity(0.03)]
                : [Colors.white.withOpacity(0.85), Colors.white.withOpacity(0.45)]);

        return ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: LinearGradient(
                  colors: cardGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: isLocked
                      ? (isDark ? Colors.white.withOpacity(0.12) : Colors.white.withOpacity(0.6))
                      : (isDark ? Colors.white.withOpacity(0.25) : Colors.white.withOpacity(0.9)),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.black.withOpacity(0.4) : Colors.indigo.shade900.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(28),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.black.withOpacity(0.3) : Colors.white.withOpacity(0.75),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isDark ? Colors.white.withOpacity(0.15) : Colors.white,
                                ),
                              ),
                              child: Text(
                                'УРОК ${letterData.id}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                  color: isDark ? Colors.white70 : const Color(0xFF4338CA),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 22,
                              height: 22,
                              child: isLocked
                                  ? const Icon(Icons.lock_rounded, color: Color(0xFFD97706), size: 16)
                                  : CircularProgressIndicator(
                                      value: progress,
                                      strokeWidth: 2.5,
                                      backgroundColor: isDark ? Colors.white24 : Colors.indigo.shade100,
                                      color: isDark ? const Color(0xFF818CF8) : const Color(0xFF4F46E5),
                                    ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Center(
                          child: isLocked
                              ? Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: const Color(0xFFFFB703).withOpacity(0.15),
                                        border: Border.all(color: const Color(0xFFFFB703).withOpacity(0.3)),
                                      ),
                                      child: const Icon(Icons.lock_rounded, color: Color(0xFFF59E0B), size: 28),
                                    ),
                                    const SizedBox(height: 6),
                                    const Text(
                                      'PREMIUM',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFFD97706),
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        letterData.variations.isNotEmpty
                                            ? letterData.variations.first.symbol
                                            : '${letterData.id}',
                                        style: TextStyle(
                                          fontSize: 56,
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? Colors.white : const Color(0xFF312E81),
                                          shadows: [
                                            Shadow(
                                              color: isDark ? Colors.black.withOpacity(0.5) : Colors.indigo.shade900.withOpacity(0.15),
                                              blurRadius: 10,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    if (letterData.variations.isNotEmpty &&
                                        letterData.variations.first.transcription.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          letterData.variations.first.transcription.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 1.0,
                                            color: isDark ? const Color(0xFF818CF8) : const Color(0xFF4338CA),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                        ),
                        const Spacer(),
                        Text(
                          isLocked ? 'Заблокировано' : letterData.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isLocked
                                ? (isDark ? Colors.white30 : Colors.grey.shade500)
                                : (isDark ? Colors.white.withOpacity(0.9) : const Color(0xFF312E81)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}