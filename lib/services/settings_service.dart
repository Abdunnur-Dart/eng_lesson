import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'subscription_service.dart';

class SettingsService extends ChangeNotifier {
  static final SettingsService instance = SettingsService._init();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<DocumentSnapshot>? _userDocSubscription;

  SettingsService._init() {
    _loadSettings();
    _listenAuthChanges();
  }

  bool _isDarkMode = false;
  bool _soundEnabled = true;
  double _fontSizeMultiplier = 1.0;
  bool _isPremium = false;
  int _streakCount = 0;
  String? _lastActivityDate;

  // Баллы и рекорды уроков
  int _totalPoints = 0;
  final Map<int, int> _lessonBestScores = {};

  bool get isDarkMode => _isDarkMode;
  bool get soundEnabled => _soundEnabled;
  double get fontSizeMultiplier => _fontSizeMultiplier;
  bool get isPremium => _isPremium;
  int get streakCount => _streakCount;
  int get totalPoints => _totalPoints;

  void _listenAuthChanges() {
    _auth.authStateChanges().listen((User? user) {
      _userDocSubscription?.cancel();

      if (user != null) {
        _listenFirestoreUserData(user.uid);
      } else {
        clearUserDataOnSignOut();
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
        final bool activePremium = SubscriptionService.isDataPremiumActive(data);
        
        if (_isPremium != activePremium) {
          _isPremium = activePremium;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isPremium', _isPremium);
          notifyListeners();
        }

        // Синхронизация стрика из Firestore
        if (data != null && data.containsKey('streakCount')) {
          final firestoreStreak = (data['streakCount'] as num?)?.toInt() ?? 0;
          final firestoreLastDate = data['lastActivityDate'] as String?;
          if (firestoreStreak > _streakCount) {
            _streakCount = firestoreStreak;
            _lastActivityDate = firestoreLastDate;
            final prefs = await SharedPreferences.getInstance();
            await prefs.setInt('streakCount', _streakCount);
            if (_lastActivityDate != null) {
              await prefs.setString('lastActivityDate', _lastActivityDate!);
            }
            notifyListeners();
          }
        }

        // Синхронизация общих баллов из Firestore
        if (data != null && data.containsKey('totalPoints')) {
          final firestorePoints = (data['totalPoints'] as num?)?.toInt() ?? 0;
          if (firestorePoints > _totalPoints) {
            _totalPoints = firestorePoints;
            final prefs = await SharedPreferences.getInstance();
            await prefs.setInt('total_user_points', _totalPoints);
            notifyListeners();
          }
        }
      }
    });

    _syncProgressWithFirestore(uid);
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

  Future<void> clearUserDataOnSignOut() async {
    _isPremium = false;
    _streakCount = 0;
    _lastActivityDate = null;
    _totalPoints = 0;
    _lessonBestScores.clear();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isPremium', false);
    await prefs.remove('streakCount');
    await prefs.remove('lastActivityDate');
    await prefs.remove('total_user_points');
    
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
    _totalPoints = prefs.getInt('total_user_points') ?? 0;

    // Загрузка сохраненных рекордов уроков в память
    final keys = prefs.getKeys();
    for (String key in keys) {
      if (key.startsWith('lesson_best_')) {
        final lessonId = int.tryParse(key.replaceFirst('lesson_best_', ''));
        if (lessonId != null) {
          _lessonBestScores[lessonId] = prefs.getInt(key) ?? 0;
        }
      }
    }

    _checkStreakExpiration();
    notifyListeners();
  }

  void _checkStreakExpiration() {
    if (_lastActivityDate != null) {
      try {
        final now = DateTime.now();
        final todayDate = DateTime(now.year, now.month, now.day);
        final lastDateParsed = DateTime.parse(_lastActivityDate!);
        final lastDate = DateTime(lastDateParsed.year, lastDateParsed.month, lastDateParsed.day);
        final difference = todayDate.difference(lastDate).inDays;
        if (difference > 1) {
          _streakCount = 0;
        }
      } catch (e) {
        debugPrint('Ошибка проверки стрика: $e');
      }
    }
  }

  Future<void> updateStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    
    if (_lastActivityDate == todayStr) {
      return;
    }

    if (_lastActivityDate != null) {
      try {
        final lastDateParsed = DateTime.parse(_lastActivityDate!);
        final lastDate = DateTime(lastDateParsed.year, lastDateParsed.month, lastDateParsed.day);
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

  // Методы работы с балльной системой и рекордами
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
    _totalPoints += points;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('total_user_points', _totalPoints);
    notifyListeners();

    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      try {
        await _firestore.collection('users').doc(currentUser.uid).set({
          'totalPoints': _totalPoints,
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
    super.dispose();
  }
}