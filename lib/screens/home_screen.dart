import 'dart:convert';
import 'dart:math' as math;
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

// ===========================================================================
// 🌿 МЯГКАЯ ПАСТЕЛЬНАЯ ПАЛИТРА (SOFT PASTEL PALETTE)
// ===========================================================================
abstract class PastelColors {
  // Светлая тема (Пастельный шалфей / Персиковая мята)
  static const Color lightBgStart = Color(0xFFF2F9F6);
  static const Color lightBgMid = Color(0xFFE6F4ED);
  static const Color lightBgEnd = Color(0xFFFDF8F5);

  static const Color lightPrimary = Color(0xFFA7F3D0);
  static const Color lightSecondary = Color(0xFF4ADE80);
  static const Color lightAccent = Color(0xFF2DD4BF);
  static const Color lightTextPrimary = Color(0xFF1F4E3D);

  // Фоновые дюны (Пастельная зелень и песок)
  static const Color duneBackLight = Color(0xFFD1FAE5);
  static const Color duneFrontLight = Color(0xFFA7F3D0);
  static const Color duneBackDark = Color(0xFF133E32);
  static const Color duneFrontDark = Color(0xFF0D2B23);

  // Тёмная тема (Глубокая ночная пастель)
  static const Color darkBgStart = Color(0xFF0F231C);
  static const Color darkBgMid = Color(0xFF143329);
  static const Color darkBgEnd = Color(0xFF1A3D31);
  static const Color darkPrimary = Color(0xFF6EE7B7);

  // Статусы прогресса (Нежные пастельные цвета)
  static const Color progressLow = Color(0xFFFECACA);
  static const Color progressMedium = Color(0xFFFDE68A);
  static const Color progressHigh = Color(0xFF86EFAC);
  static const Color progressEmpty = Color(0xFFE2E8F0);
}

// ===========================================================================
// 📖 ФАКТЫ О ПРОРОКЕ МУХАММАДЕ (мир ему и благословение Аллаха)
// ===========================================================================
const List<String> prophetFacts = [
  'Пророк Мухаммад ﷺ родился в Мекке в «Год Слона» (примерно 570 г. по милостивому летоисчислению).',
  'Имя «Мухаммад» означает «Восхваляемый». Оно встречается в Коране 4 раза.',
  'Пророк Мухаммад ﷺ до начала пророческой миссии был известен среди соплеменников как «Аль-Амин» (Достоверный, Достойный доверия).',
  'Первым откровением, ниспосланным Пророку ﷺ в пещере Хира через ангела Джибриля, были первые аяты суры «Аль-Аляк» («Читай!»).',
  'Пророк ﷺ проявлял величайшую доброту и милосердие к детям и животным, запрещая причинять им любой вред.',
  'Пророк Мухаммад ﷺ любил чистоту и перед каждым намазом рекомендовал использовать сивак для очищения зубов.',
  'Любимой едой Пророка ﷺ были мёд, финики, оливковое масло, тыква и молоко.',
  'Пророк ﷺ никогда не мстил за себя лично и прощал даже тех, кто причинял ему боль.',
  'Пророк Мухаммад ﷺ призывал к получению знаний, говоря, что стремление к знаниям — обязанность каждого мусульманина.',
];

// ===========================================================================
// ⚙ МОДЕЛИ ДЛЯ ОТОБРАЖЕНИЯ НА ДОРОЖКЕ
// ===========================================================================
abstract class PathItem {}

class LessonPathItem extends PathItem {
  final LetterModel letterData;
  final int lessonIndex;
  LessonPathItem(this.letterData, this.lessonIndex);
}

class ChestPathItem extends PathItem {
  final int chestIndex;
  final String fact;
  final int requiredLessonIndex; // Индекс последнего урока, необходимого для открытия
  ChestPathItem(this.chestIndex, this.fact, this.requiredLessonIndex);
}

class DesertItem {
  final int afterLessonIndex;
  final String emoji;
  final double offsetX;
  final double offsetY;

  const DesertItem({
    required this.afterLessonIndex,
    required this.emoji,
    this.offsetX = 110.0,
    this.offsetY = 55.0,
  });
}

abstract class WavePathConfig {
  static const double itemHeight = 110.0;
  static const double amplitudeFactor = 0.28;
  static const double maxAmplitude = 1500.0;

  static const double strokeWidth = 8.0;
  static const double glowWidth = 20.0;
  static const double glowOpacity = 0.35;
  static const double glowBlurSigma = 10.0;
  static const double topPadding = 32.0;
  static const double nodeCenterOffset = 41.0;

  static const double progressStrokeWidth = 6.0;

  static const List<DesertItem> desertDecorations = [
    DesertItem(afterLessonIndex: 0, emoji: '🌵', offsetX: 150.0, offsetY: 20.0),
    DesertItem(afterLessonIndex: 2, emoji: '⭐', offsetX: -230.0, offsetY: 25.0),
    DesertItem(afterLessonIndex: 4, emoji: '🌴', offsetX: 115.0, offsetY: 190.0),
    DesertItem(afterLessonIndex: 9, emoji: '🌵', offsetX: -170.0, offsetY: 170.0),
    DesertItem(afterLessonIndex: 12, emoji: '⛺', offsetX: 0.0, offsetY: 240.0),
    DesertItem(afterLessonIndex: 15, emoji: '⭐', offsetX: -20.0, offsetY: 400.0),
    DesertItem(afterLessonIndex: 18, emoji: '🏜️', offsetX: 30.0, offsetY: 450.0),
  ];
}

class WavePathMath {
  static double getDxForIndex(int index, double amplitude) {
    return math.sin(index * 0.75) * amplitude;
  }
}

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
  List<PathItem> _pathItems = [];
  Map<String, double> _lessonsProgress = {}; // Кеш прогресса по урокам
  bool _isLoading = true;
  bool _isError = false;

  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _loadJsonData();
    SettingsService.instance.updateStreak();
    AnalyticsService.instance.logScreenView(screenName: 'HomeScreen');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowAnnouncement();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _generatePathItems() {
    final List<PathItem> items = [];
    int chestCounter = 0;

    for (int i = 0; i < _lettersData.length; i++) {
      items.add(LessonPathItem(_lettersData[i], i));
      if ((i + 1) % 3 == 0) {
        final fact = prophetFacts[chestCounter % prophetFacts.length];
        // Сундучок привязывается к текущему (i-му) уроку
        items.add(ChestPathItem(chestCounter, fact, i));
        chestCounter++;
      }
    }

    _pathItems = items;
  }

  Future<void> _loadJsonData() async {
    setState(() {
      _isLoading = true;
      _isError = false;
    });

    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('app_data')
          .doc('lessons_doc')
          .get();

      if (!mounted) return;

      if (docSnapshot.exists && docSnapshot.data() != null) {
        final String rawJson = docSnapshot.get('json_data') ?? '[]';
        final List<dynamic> data = json.decode(rawJson);

        _lettersData = data
            .map((item) => LetterModel.fromJson(item))
            .take(27)
            .toList();

        _generatePathItems();
        await _loadAllLessonsProgress();

        if (mounted) {
          setState(() {
            _isLoading = false;
            _isError = false;
          });
        }
      } else {
        setState(() {
          _isLoading = false;
          _isError = true;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isError = true;
      });
    }
  }

  /// Загружает прогресс всех уроков единовременно для корректной проверки последовательности
  Future<void> _loadAllLessonsProgress() async {
    final Map<String, double> progressMap = {};
    
    for (var letter in _lettersData) {
      // 1. Для SettingsService передаём letter.id напрямую, так как он принимает int
      final progress = await SettingsService.instance.getLessonProgress(letter.id);
      
      // 2. Для ключа Map<String, double> преобразуем id в String
      progressMap[letter.id.toString()] = progress;
    }
    
    _lessonsProgress = progressMap;
  }

  /// Проверяет, доступен ли урок с индексом [index]
  bool _isLessonUnlocked(int index, bool isPremium, int maxFreeCount) {
    // Ограничение премиума
    if (!isPremium && index >= maxFreeCount) return false;

    // Первый урок всегда доступен
    if (index == 0) return true;

    // ОБНОВЛЕНО: Последующий урок доступен, если предыдущий начат (прогресс > 0)
    final prevLessonId = _lettersData[index - 1].id.toString();
    final prevProgress = _lessonsProgress[prevLessonId] ?? 0.0;
    return prevProgress > 0.0;
  }

  /// Проверяет, является ли урок ТЕКУЩИМ (первым не пройденным до конца среди доступных)
  bool _isCurrentLesson(int index, bool isUnlocked) {
    if (!isUnlocked) return false;
    final currentLessonId = _lettersData[index].id.toString();
    final currentProgress = _lessonsProgress[currentLessonId] ?? 0.0;
    return currentProgress < 1.0;
  }

  /// Проверяет, открыт ли сундучок (урок перед ним пройден хотя бы на 1%)
  bool _isChestUnlocked(int requiredLessonIndex) {
    if (requiredLessonIndex < 0 || requiredLessonIndex >= _lettersData.length) return false;
    final lessonId = _lettersData[requiredLessonIndex].id.toString();
    final progress = _lessonsProgress[lessonId] ?? 0.0;
    return progress > 0.0;
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
              ? PastelColors.darkBgStart.withOpacity(0.9)
              : Colors.white.withOpacity(0.95),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
            side: BorderSide(
              color: isDark ? Colors.white.withOpacity(0.2) : PastelColors.lightPrimary.withOpacity(0.4),
              width: 1.5,
            ),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: PastelColors.lightPrimary.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.campaign_rounded, color: PastelColors.lightTextPrimary, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: isDark ? Colors.white : PastelColors.lightTextPrimary,
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
                  backgroundColor: PastelColors.lightSecondary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
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

  void _showChestFactDialog(BuildContext context, String fact, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: AlertDialog(
          backgroundColor: isDark
              ? PastelColors.darkBgStart.withOpacity(0.92)
              : Colors.white.withOpacity(0.95),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
            side: BorderSide(
              color: isDark ? Colors.white.withOpacity(0.2) : PastelColors.lightPrimary.withOpacity(0.4),
              width: 1.5,
            ),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: PastelColors.progressMedium.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: const Text('🎁', style: TextStyle(fontSize: 26)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Факт о Пророке ﷺ',
                  style: TextStyle(
                    color: isDark ? Colors.white : PastelColors.lightTextPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            fact,
            style: TextStyle(
              fontSize: 16,
              height: 1.4,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: PastelColors.lightSecondary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('МашаАллах', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showChestLockedDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: AlertDialog(
          backgroundColor: isDark
              ? PastelColors.darkBgStart.withOpacity(0.92)
              : Colors.white.withOpacity(0.95),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
            side: BorderSide(
              color: isDark ? Colors.white.withOpacity(0.2) : PastelColors.lightPrimary.withOpacity(0.4),
              width: 1.5,
            ),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_rounded, color: Colors.amber, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Сундучок закрыт',
                  style: TextStyle(
                    color: isDark ? Colors.white : PastelColors.lightTextPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'Пройдите предыдущие уроки, чтобы открыть этот сундучок и узнать интересный факт!',
            style: TextStyle(
              fontSize: 15,
              height: 1.4,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: PastelColors.lightSecondary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                onPressed: () => Navigator.pop(ctx),
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
                color: isDark ? PastelColors.darkBgStart.withOpacity(0.92) : Colors.white.withOpacity(0.95),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(36.0)),
                border: Border(
                  top: BorderSide(
                    color: isDark ? Colors.white.withOpacity(0.2) : PastelColors.lightPrimary.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white38 : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: PastelColors.progressLow.withOpacity(0.4),
                    ),
                    child: const Icon(
                      Icons.local_fire_department_rounded,
                      color: Color(0xFFF87171),
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${settings.streakCount} ${_getStreakDaysText(settings.streakCount)} подряд!',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : PastelColors.lightTextPrimary,
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
                      color: isDark ? PastelColors.darkPrimary : PastelColors.lightTextPrimary,
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
                                  ? PastelColors.lightTextPrimary
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
                                  ? PastelColors.lightSecondary
                                  : (isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200),
                              border: isToday
                                  ? Border.all(color: PastelColors.lightTextPrimary, width: 2)
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
                                            ? PastelColors.lightTextPrimary
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
                        backgroundColor: PastelColors.lightSecondary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
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

  void _showPaywallDialog(BuildContext dialogContext, bool isDark) {
    AnalyticsService.instance.logPaywallViewed();
    showDialog(
      context: dialogContext,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: AlertDialog(
          backgroundColor: isDark
              ? PastelColors.darkBgStart.withOpacity(0.9)
              : Colors.white.withOpacity(0.95),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
            side: BorderSide(
              color: isDark ? Colors.white.withOpacity(0.2) : PastelColors.lightPrimary.withOpacity(0.4),
              width: 1.5,
            ),
          ),
          title: Row(
            children: [
              const Icon(Icons.workspace_premium_rounded, color: PastelColors.progressMedium, size: 28),
              const SizedBox(width: 12),
              Text(
                'Премиум доступ',
                style: TextStyle(
                  color: isDark ? Colors.white : PastelColors.lightTextPrimary,
                  fontWeight: FontWeight.bold,
                ),
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
                backgroundColor: PastelColors.progressMedium,
                foregroundColor: Colors.black87,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                if (!mounted) return;
                await Navigator.push(
                  dialogContext,
                  MaterialPageRoute(builder: (context) => const AuthPaymentScreen()),
                );
                if (!mounted) return;
                await _loadAllLessonsProgress();
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
              gradient: LinearGradient(
                colors: isDark
                    ? const [PastelColors.darkBgStart, PastelColors.darkBgMid, PastelColors.darkBgEnd]
                    : const [PastelColors.lightBgStart, PastelColors.lightBgMid, PastelColors.lightBgEnd],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
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
                                color: isDark ? PastelColors.darkPrimary : PastelColors.lightTextPrimary.withOpacity(0.7),
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Арабские буквы',
                              style: TextStyle(
                                color: isDark ? Colors.white : PastelColors.lightTextPrimary,
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
                                      color: isDark ? Colors.white.withOpacity(0.12) : Colors.white.withOpacity(0.85),
                                      borderRadius: BorderRadius.circular(22),
                                      border: Border.all(
                                        color: isDark ? Colors.white.withOpacity(0.2) : Colors.white,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.local_fire_department_rounded, color: Color(0xFFF87171), size: 18),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${settings.streakCount}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: isDark ? Colors.white : PastelColors.lightTextPrimary,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text('•', style: TextStyle(color: isDark ? Colors.white38 : Colors.grey)),
                                        const SizedBox(width: 8),
                                        const Icon(Icons.stars_rounded, color: PastelColors.progressMedium, size: 18),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${settings.totalPoints}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: isDark ? Colors.amber.shade200 : const Color(0xFFD97706),
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
                                await _loadAllLessonsProgress();
                                setState(() {});
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _isLoading
                        ? Center(
                            child: CircularProgressIndicator(
                              color: isDark ? PastelColors.darkPrimary : PastelColors.lightSecondary,
                            ),
                          )
                        : _isError
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.wifi_off_rounded,
                                        size: 64,
                                        color: isDark ? Colors.white70 : PastelColors.lightTextPrimary,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Нет подключения к интернету',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? Colors.white : PastelColors.lightTextPrimary,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Проверьте соединение и попробуйте снова',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: isDark ? Colors.white60 : Colors.black54,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 24),
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: PastelColors.lightSecondary,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          elevation: 0,
                                        ),
                                        onPressed: _loadJsonData,
                                        icon: const Icon(Icons.refresh_rounded, size: 20),
                                        label: const Text(
                                          'Повторить',
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : LayoutBuilder(
                                builder: (context, constraints) {
                                  final double amplitude = math.min(
                                    constraints.maxWidth * WavePathConfig.amplitudeFactor,
                                    WavePathConfig.maxAmplitude,
                                  );
                                  final double centerX = constraints.maxWidth / 2;

                                  return Stack(
                                    children: [
                                      Positioned.fill(
                                        child: CustomPaint(
                                          painter: DesertBackgroundPainter(isDark: isDark),
                                        ),
                                      ),
                                      Positioned.fill(
                                        child: AnimatedBuilder(
                                          animation: _scrollController,
                                          builder: (context, child) {
                                            final double scrollOffset = _scrollController.hasClients
                                                ? _scrollController.offset
                                                : 0.0;

                                            return CustomPaint(
                                              painter: _WavePathPainter(
                                                itemCount: _pathItems.length,
                                                itemHeight: WavePathConfig.itemHeight,
                                                amplitude: amplitude,
                                                scrollOffset: scrollOffset,
                                                isDark: isDark,
                                                strokeWidth: WavePathConfig.strokeWidth,
                                                glowWidth: WavePathConfig.glowWidth,
                                                glowOpacity: WavePathConfig.glowOpacity,
                                                glowBlurSigma: WavePathConfig.glowBlurSigma,
                                                topPadding: WavePathConfig.topPadding,
                                                nodeCenterOffset: WavePathConfig.nodeCenterOffset,
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      AnimatedBuilder(
                                        animation: _scrollController,
                                        builder: (context, child) {
                                          final double scrollOffset = _scrollController.hasClients
                                              ? _scrollController.offset
                                              : 0.0;

                                          return Stack(
                                            children: WavePathConfig.desertDecorations.map((item) {
                                              if (item.afterLessonIndex >= _pathItems.length) {
                                                return const SizedBox.shrink();
                                              }

                                              final double nodeX = centerX +
                                                  WavePathMath.getDxForIndex(
                                                      item.afterLessonIndex, amplitude);
                                              final double nodeY = WavePathConfig.topPadding +
                                                  (item.afterLessonIndex * WavePathConfig.itemHeight) +
                                                  WavePathConfig.nodeCenterOffset -
                                                  scrollOffset;

                                              final double posX = nodeX + item.offsetX - 22;
                                              final double posY = nodeY + item.offsetY - 22;

                                              return Positioned(
                                                left: posX,
                                                top: posY,
                                                child: DesertDecorationWidget(
                                                  emoji: item.emoji,
                                                  isDark: isDark,
                                                ),
                                              );
                                            }).toList(),
                                          );
                                        },
                                      ),
                                      ListView.builder(
                                        controller: _scrollController,
                                        padding: EdgeInsets.symmetric(vertical: WavePathConfig.topPadding),
                                        physics: const BouncingScrollPhysics(),
                                        itemCount: _pathItems.length,
                                        itemExtent: WavePathConfig.itemHeight,
                                        itemBuilder: (context, index) {
                                          final item = _pathItems[index];
                                          final double dx = WavePathMath.getDxForIndex(index, amplitude);

                                          if (item is ChestPathItem) {
                                            final bool isChestUnlocked = _isChestUnlocked(item.requiredLessonIndex);

                                            return Transform.translate(
                                              offset: Offset(dx, 0),
                                              child: Center(
                                                child: AnimatedChestWidget(
                                                  isDark: isDark,
                                                  isLocked: !isChestUnlocked,
                                                  onTap: () {
                                                    if (isChestUnlocked) {
                                                      _showChestFactDialog(context, item.fact, isDark);
                                                    } else {
                                                      _showChestLockedDialog(context, isDark);
                                                    }
                                                  },
                                                ),
                                              ),
                                            );
                                          }

                                          final lessonItem = item as LessonPathItem;
                                          final letterData = lessonItem.letterData;
                                          final int lessonIdx = lessonItem.lessonIndex;

                                          final bool isUnlocked = _isLessonUnlocked(lessonIdx, isPremium, unlockedCount);
                                          final bool isCurrent = _isCurrentLesson(lessonIdx, isUnlocked);
                                          final double lessonProgress = _lessonsProgress[letterData.id.toString()] ?? 0.0;

                                          return Transform.translate(
                                            offset: Offset(dx, 0),
                                            child: Center(
                                              child: ModernLessonCard(
                                                letterData: letterData,
                                                isLocked: !isUnlocked,
                                                isCurrent: isCurrent,
                                                isDark: isDark,
                                                progress: lessonProgress,
                                                onTap: () async {
                                                  // Премиум блокировка
                                                  if (!isPremium && lessonIdx >= unlockedCount) {
                                                    _showPaywallDialog(context, isDark);
                                                    return;
                                                  }

                                                  // Обычная последовательная блокировка
                                                  if (!isUnlocked) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      const SnackBar(
                                                        content: Text('Пройдите предыдущий урок хотя бы на 1%!'),
                                                        duration: Duration(seconds: 2),
                                                      ),
                                                    );
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
                                                  await _loadAllLessonsProgress();
                                                  setState(() {});
                                                },
                                              ),
                                            ),
                                          );
                                        },
                                      )
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
      },
    );
  }

  Widget _buildGlassIconButton({required IconData icon, required bool isDark, required VoidCallback onPressed}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.12) : Colors.white.withOpacity(0.85),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.2) : Colors.white,
              width: 1.5,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Icon(icon, color: isDark ? Colors.white : PastelColors.lightTextPrimary, size: 20),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// 🎁 АНИМИРОВАННЫЙ ВИДЖЕТ СУНДУЧКА
// ===========================================================================
class AnimatedChestWidget extends StatefulWidget {
  final bool isDark;
  final bool isLocked;
  final VoidCallback onTap;

  const AnimatedChestWidget({
    super.key,
    required this.isDark,
    required this.isLocked,
    required this.onTap,
  });

  @override
  State<AnimatedChestWidget> createState() => _AnimatedChestWidgetState();
}

class _AnimatedChestWidgetState extends State<AnimatedChestWidget>
    with TickerProviderStateMixin {
  late final AnimationController _idleController;
  late final AnimationController _openController;

  late final Animation<double> _chestScale;
  late final Animation<double> _lidAngle;
  late final Animation<double> _sparkleScale;
  late final Animation<double> _sparkleOpacity;

  bool _isOpened = false;

  @override
  void initState() {
    super.initState();

    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    if (!widget.isLocked) {
      _idleController.repeat(reverse: true);
    }

    _openController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    final Animation<double> curvedOpen = CurvedAnimation(
      parent: _openController,
      curve: Curves.easeInOut,
    );

    _chestScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.88), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 0.88, end: 1.12), weight: 45),
      TweenSequenceItem(tween: Tween(begin: 1.12, end: 1.0), weight: 30),
    ]).animate(curvedOpen);

    _lidAngle = Tween<double>(begin: 0.0, end: -0.65).animate(
      CurvedAnimation(
        parent: _openController,
        curve: const Interval(0.1, 0.85, curve: Curves.easeInOut),
      ),
    );

    _sparkleScale = Tween<double>(begin: 0.2, end: 1.4).animate(
      CurvedAnimation(
        parent: _openController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _sparkleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _openController,
        curve: const Interval(0.15, 0.5, curve: Curves.easeIn),
      ),
    );
  }

  @override
  void didUpdateWidget(covariant AnimatedChestWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isLocked != widget.isLocked) {
      if (widget.isLocked) {
        _idleController.stop();
        _idleController.value = 0.0;
      } else {
        _idleController.repeat(reverse: true);
      }
    }
  }

  @override
  void dispose() {
    _idleController.dispose();
    _openController.dispose();
    super.dispose();
  }

  void _handleTap() async {
    if (widget.isLocked) {
      widget.onTap();
      return;
    }

    if (_openController.isAnimating) return;

    HapticFeedback.mediumImpact();

    setState(() {
      _isOpened = true;
    });

    _openController.reset();
    await _openController.forward();
    widget.onTap();

    if (mounted) {
      await Future.delayed(const Duration(milliseconds: 300));
      await _openController.reverse();
      setState(() {
        _isOpened = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryGold = widget.isLocked
        ? Colors.grey
        : (widget.isDark ? const Color(0xFFF59E0B) : const Color(0xFFD97706));
    final accentGold = widget.isLocked
        ? Colors.grey.shade400
        : (widget.isDark ? const Color(0xFFFCD34D) : const Color(0xFFFBBF24));

    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([_idleController, _openController]),
        builder: (context, child) {
          final idleGlow = widget.isLocked ? 0.0 : math.sin(_idleController.value * math.pi) * 4.0;

          return ScaleTransition(
            scale: _chestScale,
            child: SizedBox(
              width: 86,
              height: 86,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  if (_openController.value > 0.05)
                    Opacity(
                      opacity: (1.0 - _openController.value).clamp(0.0, 1.0),
                      child: Transform.scale(
                        scale: _sparkleScale.value,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                accentGold.withOpacity(0.8),
                                primaryGold.withOpacity(0.0),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (_isOpened)
                    ...List.generate(5, (index) {
                      final angle = (index * 72.0) * math.pi / 180.0;
                      final distance = 38.0 * _openController.value;
                      final dx = math.cos(angle) * distance;
                      final dy = math.sin(angle) * distance - 10;

                      return Transform.translate(
                        offset: Offset(dx, dy),
                        child: Opacity(
                          opacity: (_sparkleOpacity.value * (1.0 - _openController.value)).clamp(0.0, 1.0),
                          child: Icon(
                            Icons.star_rounded,
                            size: 16,
                            color: accentGold,
                          ),
                        ),
                      );
                    }),
                  Positioned(
                    bottom: 4,
                    child: Container(
                      width: 60,
                      height: 14,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(100),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(widget.isDark ? 0.45 : 0.18),
                            blurRadius: 8 + idleGlow,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    child: Container(
                      width: 62,
                      height: 42,
                      decoration: BoxDecoration(
                        color: widget.isLocked
                            ? (widget.isDark ? const Color(0xFF1E293B) : const Color(0xFFCBD5E1))
                            : (widget.isDark ? const Color(0xFF332314) : const Color(0xFFB45309)),
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
                        border: Border.all(color: primaryGold, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: primaryGold.withOpacity(widget.isLocked ? 0.0 : 0.25 + (idleGlow / 30)),
                            blurRadius: 10 + idleGlow,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            left: 8,
                            top: 0,
                            bottom: 0,
                            child: Container(width: 5, color: primaryGold.withOpacity(0.8)),
                          ),
                          Positioned(
                            right: 8,
                            top: 0,
                            bottom: 0,
                            child: Container(width: 5, color: primaryGold.withOpacity(0.8)),
                          ),
                          Center(
                            child: Container(
                              width: 14,
                              height: 16,
                              decoration: BoxDecoration(
                                color: accentGold,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Center(
                                child: widget.isLocked
                                    ? const Icon(Icons.lock, size: 10, color: Colors.black87)
                                    : Container(
                                        width: 4,
                                        height: 6,
                                        decoration: const BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 48,
                    child: Transform(
                      alignment: Alignment.bottomCenter,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.002)
                        ..rotateX(_lidAngle.value),
                      child: Container(
                        width: 66,
                        height: 22,
                        decoration: BoxDecoration(
                          color: widget.isLocked
                              ? (widget.isDark ? const Color(0xFF334155) : const Color(0xFF94A3B8))
                              : (widget.isDark ? const Color(0xFF452B19) : const Color(0xFFD97706)),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                          border: Border.all(color: accentGold, width: 2.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Container(
                            width: 14,
                            height: 5,
                            decoration: BoxDecoration(
                              color: accentGold,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _WavePathPainter extends CustomPainter {
  final int itemCount;
  final double itemHeight;
  final double amplitude;
  final double scrollOffset;
  final bool isDark;

  final double strokeWidth;
  final double glowWidth;
  final double glowOpacity;
  final double glowBlurSigma;
  final double topPadding;
  final double nodeCenterOffset;

  _WavePathPainter({
    required this.itemCount,
    required this.itemHeight,
    required this.amplitude,
    required this.scrollOffset,
    required this.isDark,
    required this.strokeWidth,
    required this.glowWidth,
    required this.glowOpacity,
    required this.glowBlurSigma,
    required this.topPadding,
    required this.nodeCenterOffset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (itemCount <= 1) return;

    final double centerX = size.width / 2;

    final Paint mainLinePaint = Paint()
      ..color = isDark ? PastelColors.darkPrimary : PastelColors.lightSecondary
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final Paint glowPaint = Paint()
      ..color = (isDark ? PastelColors.darkPrimary : PastelColors.lightPrimary).withOpacity(glowOpacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = glowWidth
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, glowBlurSigma);

    final Path path = Path();

    for (int i = 0; i < itemCount; i++) {
      final double x = centerX + WavePathMath.getDxForIndex(i, amplitude);
      final double y = topPadding + (i * itemHeight) + nodeCenterOffset - scrollOffset;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        final double prevX = centerX + WavePathMath.getDxForIndex(i - 1, amplitude);
        final double prevY = topPadding + ((i - 1) * itemHeight) + nodeCenterOffset - scrollOffset;

        final double controlY1 = prevY + (itemHeight * 0.5);
        final double controlY2 = y - (itemHeight * 0.5);

        path.cubicTo(prevX, controlY1, x, controlY2, x, y);
      }
    }

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, mainLinePaint);
  }

  @override
  bool shouldRepaint(covariant _WavePathPainter oldDelegate) {
    return oldDelegate.itemCount != itemCount ||
        oldDelegate.itemHeight != itemHeight ||
        oldDelegate.amplitude != amplitude ||
        oldDelegate.scrollOffset != scrollOffset ||
        oldDelegate.isDark != isDark;
  }
}

class DesertBackgroundPainter extends CustomPainter {
  final bool isDark;

  DesertBackgroundPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint backDunePaint = Paint()
      ..color = isDark
          ? PastelColors.duneBackDark.withOpacity(0.4)
          : PastelColors.duneBackLight.withOpacity(0.45);

    final Paint frontDunePaint = Paint()
      ..color = isDark
          ? PastelColors.duneFrontDark.withOpacity(0.5)
          : PastelColors.duneFrontLight.withOpacity(0.35);

    final Path backDune = Path();
    backDune.moveTo(0, size.height * 0.28);
    backDune.quadraticBezierTo(
      size.width * 0.32,
      size.height * 0.18,
      size.width * 0.65,
      size.height * 0.32,
    );
    backDune.quadraticBezierTo(
      size.width * 0.85,
      size.height * 0.42,
      size.width,
      size.height * 0.35,
    );
    backDune.lineTo(size.width, size.height);
    backDune.lineTo(0, size.height);
    backDune.close();

    final Path frontDune = Path();
    frontDune.moveTo(0, size.height * 0.58);
    frontDune.quadraticBezierTo(
      size.width * 0.38,
      size.height * 0.72,
      size.width * 0.72,
      size.height * 0.55,
    );
    frontDune.quadraticBezierTo(
      size.width * 0.9,
      size.height * 0.45,
      size.width,
      size.height * 0.52,
    );
    frontDune.lineTo(size.width, size.height);
    frontDune.lineTo(0, size.height);
    frontDune.close();

    canvas.drawPath(backDune, backDunePaint);
    canvas.drawPath(frontDune, frontDunePaint);
  }

  @override
  bool shouldRepaint(covariant DesertBackgroundPainter oldDelegate) {
    return oldDelegate.isDark != isDark;
  }
}

class DesertDecorationWidget extends StatelessWidget {
  final String emoji;
  final bool isDark;

  const DesertDecorationWidget({
    super.key,
    required this.emoji,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      emoji,
      style: TextStyle(
        fontSize: 120,
        height: 1.0,
        shadows: [
          Shadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.12),
            offset: const Offset(0, 4),
            blurRadius: 8,
          ),
        ],
      ),
    );
  }
}

class ModernLessonCard extends StatefulWidget {
  final LetterModel letterData;
  final bool isLocked;
  final bool isCurrent;
  final bool isDark;
  final double progress;
  final VoidCallback onTap;

  const ModernLessonCard({
    super.key,
    required this.letterData,
    required this.isLocked,
    required this.isCurrent,
    required this.isDark,
    required this.progress,
    required this.onTap,
  });

  @override
  State<ModernLessonCard> createState() => _ModernLessonCardState();
}

class _ModernLessonCardState extends State<ModernLessonCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _scaleAnimation = Tween<double>(begin: 0.96, end: 1.08).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    _updateAnimationState();
  }

  @override
  void didUpdateWidget(covariant ModernLessonCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isCurrent != widget.isCurrent || oldWidget.isLocked != widget.isLocked) {
      _updateAnimationState();
    }
  }

  void _updateAnimationState() {
    // Карточка пульсирует (мигает), если урок доступен и является текущим для выполнения
    if (!widget.isLocked && widget.isCurrent) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    } else {
      if (_pulseController.isAnimating) {
        _pulseController.stop();
        _pulseController.value = 0.0;
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Color _getProgressColor(double progress) {
    if (progress <= 0.0) {
      return widget.isDark ? const Color(0xFF133E32) : PastelColors.progressEmpty;
    } else if (progress < 0.4) {
      return PastelColors.progressLow;
    } else if (progress < 0.8) {
      return PastelColors.progressMedium;
    } else {
      return PastelColors.progressHigh;
    }
  }

  @override
  Widget build(BuildContext context) {
    final double progress = widget.progress.clamp(0.0, 1.0);
    final bool isCompleted = progress >= 1.0;

    final Color primaryColor = widget.isLocked
        ? (widget.isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0))
        : (isCompleted ? PastelColors.progressHigh : PastelColors.lightSecondary);

    final Color bottomShadowColor = widget.isLocked
        ? (widget.isDark ? const Color(0xFF0F172A) : const Color(0xFFCBD5E1))
        : (isCompleted ? const Color(0xFF4ADE80) : const Color(0xFF2DD4BF));

    final String symbolText = widget.letterData.variations.isNotEmpty
        ? widget.letterData.variations.first.symbol
        : '${widget.letterData.id}';

    Widget progressIndicator = SizedBox(
      width: 82,
      height: 82,
      child: CircularProgressIndicator(
        value: progress == 0.0 ? 1.0 : progress,
        strokeWidth: WavePathConfig.progressStrokeWidth,
        color: _getProgressColor(progress),
        strokeCap: StrokeCap.round,
        backgroundColor: Colors.transparent,
      ),
    );

    return GestureDetector(
      onTap: widget.onTap,
      child: SizedBox(
        width: 84,
        height: 84,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (!widget.isLocked)
              _pulseController.isAnimating
                  ? ScaleTransition(scale: _scaleAnimation, child: progressIndicator)
                  : progressIndicator,
            Positioned(
              bottom: 4,
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: bottomShadowColor.withOpacity(0.6),
                ),
              ),
            ),
            Positioned(
              top: 2,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 70,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: widget.isLocked
                      ? Icon(
                          Icons.lock_rounded,
                          color: widget.isDark ? Colors.white54 : Colors.grey.shade500,
                          size: 28,
                        )
                      : Text(
                          symbolText,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: widget.isLocked
                                ? Colors.grey
                                : (isCompleted ? PastelColors.lightTextPrimary : Colors.white),
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}