import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  static final AnalyticsService instance = AnalyticsService._init();
  AnalyticsService._init();

  factory AnalyticsService() => instance;

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  Future<void> setUserId(String? userId) async {
    await _analytics.setUserId(id: userId);
  }

  Future<void> setUserProperty({required String name, required String? value}) async {
    await _analytics.setUserProperty(name: name, value: value);
  }

  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    await _analytics.logEvent(name: name, parameters: parameters);
  }

  Future<void> logScreenView({required String screenName}) async {
    await _analytics.logScreenView(screenName: screenName);
  }

  Future<void> logLogin({String method = 'email'}) async {
    await _analytics.logLogin(loginMethod: method);
  }

  Future<void> logSignUp({String method = 'email'}) async {
    await _analytics.logSignUp(signUpMethod: method);
  }

  Future<void> logPurchase({
    required String productId,
    required double price,
    required String currency,
  }) async {
    await _analytics.logPurchase(
      currency: currency,
      value: price,
      items: [
        AnalyticsEventItem(
          itemId: productId,
          itemName: productId,
        ),
      ],
    );
  }

  Future<void> logLessonView({required int lessonId, required String title}) async {
    await _analytics.logEvent(
      name: 'view_lesson',
      parameters: {
        'lesson_id': lessonId,
        'lesson_title': title,
      },
    );
  }

  Future<void> logQuizCompleted({
    required int lessonId,
    required int score,
    required int total,
    required double percentage,
  }) async {
    await _analytics.logEvent(
      name: 'quiz_completed',
      parameters: {
        'lesson_id': lessonId,
        'score': score,
        'total_questions': total,
        'percentage': percentage,
      },
    );
  }

  Future<void> logPaywallViewed() async {
    await _analytics.logEvent(name: 'paywall_viewed');
  }
}