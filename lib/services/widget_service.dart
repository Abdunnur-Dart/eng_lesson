// NEW: Выделенный сервис продакшн-уровня для работы с Android-виджетами
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

class WidgetService {
  WidgetService._();
  static final WidgetService instance = WidgetService._();

  static const String _androidProviderName = 'AppWidgetProvider';

  static const String _keyLetterText = 'letter_text';
  static const String _keyLetterVariations = 'letter_variations'; // NEW
  static const String _keyLessonProgress = 'lesson_progress'; // NEW

  /// Обновляет отображаемую букву, формы её написания и прогресс урока в Android-виджете.
  Future<bool> updateWidgetData({
    required String letter,
    required String variations, // NEW
    required String progressPercent, // NEW
  }) async {
    try {
      // 1. Сохраняем значения для SharedPreferences виджета
      await HomeWidget.saveWidgetData<String>(_keyLetterText, letter);
      await HomeWidget.saveWidgetData<String>(_keyLetterVariations, variations); // NEW
      await HomeWidget.saveWidgetData<String>(_keyLessonProgress, progressPercent); // NEW

      // 2. Отправляем сигнал на обновление UI виджета
      final bool? updated = await HomeWidget.updateWidget(
        name: _androidProviderName,
        androidName: _androidProviderName,
      );

      if (kDebugMode) {
        print('WidgetService: Виджет обновлен. Буква: $letter, Формы: $variations, Прогресс: $progressPercent');
      }

      return updated ?? false;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('WidgetService Error: Ошибка при обновлении виджета: $e');
        print(stackTrace);
      }
      return false;
    }
  }

  // CHANGED: Метод для обратной совместимости
  Future<bool> updateWidgetLetter(String letter) async {
    return updateWidgetData(
      letter: letter,
      variations: '',
      progressPercent: '0%',
    );
  }

  @pragma('vm:entry-point')
  static Future<void> backgroundCallback(Uri? uri) async {
    if (uri != null && uri.host == 'update_letter') {
      // Логика фоновой обработки
    }
  }
}