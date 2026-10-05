import 'dart:async';
import 'package:arabic/services/subscription_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class SettingsService extends ChangeNotifier {
  static final SettingsService instance = SettingsService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  StreamSubscription<DocumentSnapshot>? _userDocSubscription;
  StreamSubscription<DocumentSnapshot>? _announcementSubscription;
  StreamSubscription<String>? _fcmTokenSubscription;

  SettingsService._internal() {
    _init();
  }

  bool _isDarkMode = false;
  bool _soundEnabled = true;
  double _fontSizeMultiplier = 1.0;
  bool _isPremium = false;
  int _streakCount = 0;
  String? _lastActivityDate;
  String? _lastLoginDate;
  String? _fcmToken;

  int _totalPoints = 0;
  int _weeklyPoints = 0;
  int _lastWeekNumber = 0;
  String? _displayName;
  bool _hasRequestedReview = false; // NEW: Поле для отслеживания запроса отзыва

  final Map<int, int> _lessonBestScores = {};
  Map<String, dynamic>? _announcementData;

  bool get isDarkMode => _isDarkMode;
  bool get soundEnabled => _soundEnabled;
  double get fontSizeMultiplier => _fontSizeMultiplier;
  bool get isPremium => _isPremium;
  int get streakCount => _streakCount;
  int get totalPoints => _totalPoints;
  int get weeklyPoints => _weeklyPoints;
  String? get displayName => _displayName;
  String? get lastLoginDate => _lastLoginDate;
  String? get fcmToken => _fcmToken;
  Map<String, dynamic>? get announcementData => _announcementData;
  bool get hasRequestedReview => _hasRequestedReview; // NEW: Геттер для проверки

  void _init() {
    _loadSettings();
    _listenAuthChanges();
    _listenGlobalAnnouncement();
  }

  void _listenAuthChanges() {
    _auth.authStateChanges().listen((User? user) {
      _userDocSubscription?.cancel();

      if (user != null) {
        _listenFirestoreUserData(user.uid);
        updateLastLogin();
        updateFcmToken();
      } else {
        clearUserDataOnSignOut();
      }
    });
  }

  void _listenGlobalAnnouncement() {
    _announcementSubscription = _firestore
        .collection('config')
        .doc('announcement')
        .snapshots()
        .listen((DocumentSnapshot snapshot) {
      if (snapshot.exists) {
        _announcementData = snapshot.data() as Map<String, dynamic>?;
        notifyListeners();
      } else {
        _announcementData = null;
        notifyListeners();
      }
    });
  }

  void _listenFirestoreUserData(String uid) {
    _userDocSubscription = _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen((DocumentSnapshot snapshot) async {
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>?;
        final bool activePremium = SubscriptionService.checkPremiumFromData(data);
        
        if (_isPremium != activePremium) {
          _isPremium = activePremium;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isPremium', _isPremium);
          notifyListeners();
        }

        if (data != null && data.containsKey('streakCount')) {
          final firestoreStreak = (data['streakCount'] as num?)?.toInt() ?? 0;
          final firestoreLastDate = data['lastActivityDate'] as String?;
          if (firestoreStreak != _streakCount || firestoreLastDate != _lastActivityDate) {
            _streakCount = firestoreStreak;
            _lastActivityDate = firestoreLastDate;
            final prefs = await SharedPreferences.getInstance();
            await prefs.setInt('streakCount', _streakCount);
            if (_lastActivityDate != null) {
              await prefs.setString('lastActivityDate', _lastActivityDate!);
            }
            _checkStreakExpiration();
            notifyListeners();
          }
        }

        if (data != null && data.containsKey('totalPoints')) {
          final firestorePoints = (data['totalPoints'] as num?)?.toInt() ?? 0;
          if (firestorePoints > _totalPoints) {
            _totalPoints = firestorePoints;
            final prefs = await SharedPreferences.getInstance();
            await prefs.setInt('total_user_points', _totalPoints);
            notifyListeners();
          }
        }

        if (data != null && data.containsKey('displayName')) {
          _displayName = data['displayName'] as String?;
          notifyListeners();
        }

        if (data != null && data.containsKey('weeklyPoints')) {
          _weeklyPoints = (data['weeklyPoints'] as num?)?.toInt() ?? 0;
        }
      }
    });

    _syncProgressWithFirestore(uid);
  }

  Future<void> setDisplayName(String name) async {
    _displayName = name;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_display_name', name);
    notifyListeners();

    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      try {
        await _firestore.collection('users').doc(currentUser.uid).set({
          'displayName': name,
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Ошибка сохранения имени в Firestore: $e');
      }
    }
  }

  // NEW: Метод сохранения статуса запроса отзыва
  Future<void> setHasRequestedReview(bool value) async {
    _hasRequestedReview = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_requested_review', value);
    notifyListeners();
  }

  Future<void> _syncProgressWithFirestore(String uid) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('progress')
          .get();

      if (snapshot.docs.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        for (var doc in snapshot.docs) {
          final lessonId = int.tryParse(doc.id);
          if (lessonId != null) {
            final data = doc.data();
            final progress = (data['progress'] as num?)?.toDouble() ?? 0.0;
            final bestScore = (data['bestScore'] as num?)?.toInt() ?? 0;

            await prefs.setDouble('lesson_progress_$lessonId', progress);

            if (bestScore > (_lessonBestScores[lessonId] ?? 0)) {
              _lessonBestScores[lessonId] = bestScore;
              await prefs.setInt('lesson_best_$lessonId', bestScore);
            }
          }
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Ошибка синхронизации с Firestore: $e');
    }
  }

  Future<void> updateFcmToken() async {
    try {
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        
        final token = await _messaging.getToken();
        if (token != null) {
          _fcmToken = token;
          await _saveFcmTokenToFirestore(token);
        }

        _fcmTokenSubscription?.cancel();
        _fcmTokenSubscription = _messaging.onTokenRefresh.listen((newToken) async {
          _fcmToken = newToken;
          await _saveFcmTokenToFirestore(newToken);
        });
      }
    } catch (e) {
      debugPrint('Ошибка при получении FCM токена: $e');
    }
  }

  Future<void> _saveFcmTokenToFirestore(String token) async {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      try {
        await _firestore.collection('users').doc(currentUser.uid).set({
          'fcmToken': token,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Ошибка сохранения FCM токена в Firestore: $e');
      }
    }
  }

  Future<void> updateLastLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final nowIso = DateTime.now().toIso8601String();
    
    _lastLoginDate = nowIso;
    await prefs.setString('lastLoginDate', nowIso);

    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      try {
        await _firestore.collection('users').doc(currentUser.uid).set({
          'lastLoginAt': FieldValue.serverTimestamp(),
          'lastLoginDate': nowIso,
          'email': currentUser.email ?? '',
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Ошибка сохранения даты входа в Firestore: $e');
      }
    }
  }

  Future<void> clearUserDataOnSignOut() async {
    _fcmTokenSubscription?.cancel();
    _isPremium = false;
    _streakCount = 0;
    _lastActivityDate = null;
    _lastLoginDate = null;
    _fcmToken = null;
    _totalPoints = 0;
    _weeklyPoints = 0;
    _displayName = null;
    _hasRequestedReview = false; // Очищаем локально тоже при выходе (опционально)
    _lessonBestScores.clear();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isPremium', false);
    await prefs.remove('streakCount');
    await prefs.remove('lastActivityDate');
    await prefs.remove('lastLoginDate');
    await prefs.remove('total_user_points');
    await prefs.remove('weekly_user_points');
    await prefs.remove('user_display_name');
    
    final keys = prefs.getKeys();
    for (String key in keys) {
      if (key.startsWith('lesson_progress_') || key.startsWith('lesson_best_')) {
        await prefs.remove(key);
      }
    }
    notifyListeners();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    _soundEnabled = prefs.getBool('soundEnabled') ?? true;
    _fontSizeMultiplier = prefs.getDouble('fontSizeMultiplier') ?? 1.0;
    _isPremium = prefs.getBool('isPremium') ?? false;
    _streakCount = prefs.getInt('streakCount') ?? 0;
    _lastActivityDate = prefs.getString('lastActivityDate');
    _lastLoginDate = prefs.getString('lastLoginDate');
    _totalPoints = prefs.getInt('total_user_points') ?? 0;
    _weeklyPoints = prefs.getInt('weekly_user_points') ?? 0;
    _lastWeekNumber = prefs.getInt('last_week_number') ?? 0;
    _displayName = prefs.getString('user_display_name');
    _hasRequestedReview = prefs.getBool('has_requested_review') ?? false; // NEW: Загружаем статус отзыва

    _checkWeeklyReset();
    _checkStreakExpiration();
    notifyListeners();
  }

  void _checkWeeklyReset() {
    final now = DateTime.now();
    final currentWeekNumber = _getWeekOfYear(now);
    if (_lastWeekNumber != currentWeekNumber) {
      _weeklyPoints = 0;
      _lastWeekNumber = currentWeekNumber;
      SharedPreferences.getInstance().then((prefs) {
        prefs.setInt('weekly_user_points', 0);
        prefs.setInt('last_week_number', currentWeekNumber);
      });
    }
  }

  int _getWeekOfYear(DateTime date) {
    final dayOfYear = int.parse("${date.year}${date.difference(DateTime(date.year, 1, 1)).inDays}");
    return (dayOfYear / 7).ceil();
  }

  void _checkStreakExpiration() {
    if (_lastActivityDate != null && _streakCount > 0) {
      try {
        final now = DateTime.now();
        final todayDate = DateTime(now.year, now.month, now.day);
        
        final parts = _lastActivityDate!.split('-');
        DateTime lastDate;
        if (parts.length >= 3) {
          final year = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          final day = int.parse(parts[2].substring(0, 2));
          lastDate = DateTime(year, month, day);
        } else {
          final lastDateParsed = DateTime.parse(_lastActivityDate!);
          lastDate = DateTime(lastDateParsed.year, lastDateParsed.month, lastDateParsed.day);
        }

        final difference = todayDate.difference(lastDate).inDays;
        if (difference > 1) {
          _streakCount = 0;
          _saveStreakToStorageAndFirestore();
        }
      } catch (e) {
        debugPrint('Ошибка проверки стрика: $e');
      }
    }
  }

  Future<void> _saveStreakToStorageAndFirestore() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('streakCount', _streakCount);
    if (_lastActivityDate != null) {
      await prefs.setString('lastActivityDate', _lastActivityDate!);
    }
    notifyListeners();

    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      try {
        await _firestore.collection('users').doc(currentUser.uid).set({
          'streakCount': _streakCount,
          'lastActivityDate': _lastActivityDate,
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Ошибка сохранения сброса стрика в Firestore: $e');
      }
    }
  }

  Future<void> updateStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    
    if (_lastActivityDate == todayStr && _streakCount > 0) {
      return;
    }

    if (_lastActivityDate != null && _streakCount > 0) {
      try {
        final parts = _lastActivityDate!.split('-');
        DateTime lastDate;
        if (parts.length >= 3) {
          final year = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          final day = int.parse(parts[2].substring(0, 2));
          lastDate = DateTime(year, month, day);
        } else {
          final lastDateParsed = DateTime.parse(_lastActivityDate!);
          lastDate = DateTime(lastDateParsed.year, lastDateParsed.month, lastDateParsed.day);
        }
        
        final todayDate = DateTime(now.year, now.month, now.day);
        final difference = todayDate.difference(lastDate).inDays;

        if (difference == 1) {
          _streakCount += 1;
        } else if (difference > 1) {
          _streakCount = 1;
        }
      } catch (e) {
        _streakCount = 1;
      }
    } else {
      _streakCount = 1;
    }

    _lastActivityDate = todayStr;
    await prefs.setInt('streakCount', _streakCount);
    await prefs.setString('lastActivityDate', todayStr);
    notifyListeners();

    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      try {
        await _firestore.collection('users').doc(currentUser.uid).set({
          'streakCount': _streakCount,
          'lastActivityDate': todayStr,
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Ошибка обновления стрика в Firestore: $e');
      }
    }
  }

  int getLessonBestScore(int lessonId) {
    return _lessonBestScores[lessonId] ?? 0;
  }

  Future<void> setLessonBestScore(int lessonId, int score) async {
    _lessonBestScores[lessonId] = score;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('lesson_best_$lessonId', score);
    notifyListeners();

    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      try {
        await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .collection('progress')
            .doc(lessonId.toString())
            .set({
          'bestScore': score,
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Ошибка сохранения рекорда в Firestore: $e');
      }
    }
  }

  int getTotalPoints() {
    return _totalPoints;
  }

  Future<void> addPoints(int points) async {
    _checkWeeklyReset();
    _totalPoints += points;
    _weeklyPoints += points;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('total_user_points', _totalPoints);
    await prefs.setInt('weekly_user_points', _weeklyPoints);
    notifyListeners();

    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      try {
        await _firestore.collection('users').doc(currentUser.uid).set({
          'totalPoints': _totalPoints,
          'weeklyPoints': _weeklyPoints,
          'email': currentUser.email ?? '',
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Ошибка сохранения баллов в Firestore: $e');
      }
    }
  }

  Future<void> setPremium(bool value) async {
    _isPremium = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isPremium', value);

    notifyListeners();

    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      try {
        await _firestore.collection('users').doc(currentUser.uid).set({
          'isPremium': value,
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Ошибка обновления Premium в Firestore: $e');
      }
    }
  }

  Future<void> setDarkMode(bool value) async {
    _isDarkMode = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', value);
  }

  Future<void> setSoundEnabled(bool value) async {
    _soundEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('soundEnabled', value);
  }

  Future<void> setFontSizeMultiplier(double value) async {
    _fontSizeMultiplier = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('fontSizeMultiplier', value);
  }

  Future<double> getLessonProgress(int lessonId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble('lesson_progress_$lessonId') ?? 0.0;
  }

  Future<void> setLessonProgress(int lessonId, double progress) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('lesson_progress_$lessonId', progress);
    await updateStreak();
    notifyListeners();

    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      try {
        await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .collection('progress')
            .doc(lessonId.toString())
            .set({
          'progress': progress,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Ошибка сохранения урока в Firestore: $e');
      }
    }
  }

  Future<void> resetProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _loadSettings();
  }

  @override
  void dispose() {
    _userDocSubscription?.cancel();
    _announcementSubscription?.cancel();
    _fcmTokenSubscription?.cancel();
    super.dispose();
  }
}