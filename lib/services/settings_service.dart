import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService extends ChangeNotifier {
  static final SettingsService instance = SettingsService._init();

  SettingsService._init() {
    _loadSettings();
  }

  bool _isDarkMode = false;
  bool _soundEnabled = true;
  double _fontSizeMultiplier = 1.0;

  bool get isDarkMode => _isDarkMode;
  bool get soundEnabled => _soundEnabled;
  double get fontSizeMultiplier => _fontSizeMultiplier;

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    _soundEnabled = prefs.getBool('soundEnabled') ?? true;
    _fontSizeMultiplier = prefs.getDouble('fontSizeMultiplier') ?? 1.0;
    notifyListeners();
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
  }

  Future<void> resetProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _loadSettings();
  }
}