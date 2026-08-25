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

  bool get isDarkMode => _isDarkMode;
  bool get soundEnabled => _soundEnabled;
  double get fontSizeMultiplier => _fontSizeMultiplier;
  bool get isPremium => _isPremium;

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
          final progress = (doc.data()['progress'] as num?)?.toDouble() ?? 0.0;
          if (lessonId != null) {
            await prefs.setDouble('lesson_progress_$lessonId', progress);
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isPremium', false);
    
    final keys = prefs.getKeys();
    for (String key in keys) {
      if (key.startsWith('lesson_progress_')) {
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
    notifyListeners();
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