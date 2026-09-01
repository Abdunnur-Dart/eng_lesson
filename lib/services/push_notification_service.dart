// lib/services/push_notification_service.dart

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

// Обязательный топ-левел обработчик для фоновых и закрытых состояний
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  if (kDebugMode) {
    print("Фоновое сообщение получено: ${message.messageId}");
  }
}

class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

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
    // 1. Запрос разрешений у пользователя
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
        // Здесь можно добавить навигацию на нужный экран
      },
    );

    // 3. Создание канала уведомлений для Android 8.0+
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // 4. Получение токена устройства
    String? token = await _fcm.getToken();
    if (kDebugMode) {
      print("FCM Token: $token");
    }

    // 5. Регистрация фонового обработчика
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // 6. Обработка входящих сообщений, когда приложение открыто (Foreground)
    // Принудительно показываем через локальные уведомления, чтобы гарантированно падало в шторку
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              _channel.id,
              _channel.name,
              channelDescription: _channel.description,
              icon: android.smallIcon ?? '@mipmap/launcher_icon',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
          payload: message.data.toString(),
        );
      }
    });

    // 7. Обработка нажатия на уведомление, когда приложение было свернуто
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('Приложение открыто через клик по пушу: ${message.data}');
      }
    });
  }
}