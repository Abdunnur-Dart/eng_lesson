// lib/services/fcm_service.dart

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

// Обязательный топ-левел обработчик для фоновых сообщений
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    print("Фоновое сообщение получено: ${message.messageId}");
  }
}

class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  // Настройка канала для Android
  final AndroidNotificationChannel _channel = const AndroidNotificationChannel(
    'high_importance_channel', 
    'Важные уведомления', 
    description: 'Канал для отображения пуш-уведомлений в шторке',
    importance: Importance.max,
  );

  Future<void> init() async {
    // 1. Запрос разрешений у пользователя (для Android 13+)
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      if (kDebugMode) print('Разрешение на уведомления получено');
    } else {
      if (kDebugMode) print('Разрешение отклонено пользователем');
    }

    // 2. Инициализация локальных уведомлений
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (kDebugMode) {
          print('Пользователь нажал на уведомление, payload: ${response.payload}');
        }
      },
    );

    // 3. Создание канала уведомлений для Android 8.0+
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // 4. Регистрация фонового обработчика
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // 5. Обработка входящих сообщений, когда приложение открыто (Foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showNotification(message);
    });

    // 6. Обработка нажатия на уведомление, когда приложение было свернуто
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('Приложение открыто через клик по пушу: ${message.data}');
      }
    });

    // 7. Проверка: если приложение было полностью закрыто и запущено по клику на пуш
    RemoteMessage? initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      if (kDebugMode) {
        print('Приложение запущено из закрытого состояния через пуш: ${initialMessage.data}');
      }
    }
  }

  // Метод принудительного показа уведомления в системной шторке
  void _showNotification(RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    // Страховка: если сервер прислал данные в data-полях, а не в notification
    String title = notification?.title ?? message.data['title'] ?? 'Арабские буквы';
    String body = notification?.body ?? message.data['body'] ?? 'Уделите время изучению!';

    _localNotifications.show(
      DateTime.now().millisecond,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          icon: android?.smallIcon ?? '@mipmap/launcher_icon',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker',
        ),
      ),
      payload: message.data.toString(),
    );
  }
}