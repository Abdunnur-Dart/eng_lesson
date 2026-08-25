import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  // Синглтон (единая точка доступа)
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  /// Получение Observer для автоматического отслеживания экранов в Navigator
  FirebaseAnalyticsObserver get analyticsObserver =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  /// Установка ID пользователя (например, UID из Firebase Auth)
  Future<void> setUserId(String? userId) async {
    await _analytics.setUserId(id: userId);
  }

  /// Установка пользовательских свойств (User Properties)
  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    await _analytics.setUserProperty(name: name, value: value);
  }

  /// Логирование входа пользователя
  Future<void> logLogin({String loginMethod = 'email'}) async {
    await _analytics.logLogin(loginMethod: loginMethod);
  }

  /// Логирование регистрации пользователя
  Future<void> logSignUp({String signUpMethod = 'email'}) async {
    await _analytics.logSignUp(signUpMethod: signUpMethod);
  }

  /// Логирование ручного просмотра экрана (если не используется NavigatorObserver)
  Future<void> logScreenView(String screenName) async {
    await _analytics.logScreenView(screenName: screenName);
  }

  /// Логирование прохождения урока/активности
  Future<void> logLessonCompleted({
    required String lessonId,
    required String lessonTitle,
    int? score,
  }) async {
    await _analytics.logEvent(
      name: 'lesson_completed',
      parameters: {
        'lesson_id': lessonId,
        'lesson_title': lessonTitle,
        if (score != null) 'score': score,
      },
    );
  }

  /// Логирование успешно совершенной покупки / подписки
  Future<void> logPurchase({
    required String productId,
    required double price,
    String currency = 'RUB',
  }) async {
    await _analytics.logEvent(
      name: 'successful_purchase',
      parameters: {
        'product_id': productId,
        'value': price,
        'currency': currency,
      },
    );
  }

  /// Универсальный метод для отправки любого кастомного события
  Future<void> logCustomEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    await _analytics.logEvent(
      name: name,
      parameters: parameters,
    );
  }
}