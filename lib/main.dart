import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'services/settings_service.dart';
import 'services/analytics_service.dart';
import 'services/fcm_service.dart'; // Убедись, что путь к твоему сервису верный

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Инициализация Firebase (с защитой, если вдруг уже инициализирован)
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  // 2. Инициализация сервиса уведомлений (FCM + локальная шторка)
  await FcmService().init();

  // 3. Вывод FCM-токена в консоль для тестов
  await _printFcmToken();

  // 4. Настройка устойчивости Firestore (актуально для оффлайна / WayDroid)
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  runApp(const MyApp());
}

// Отдельная функция для получения и вывода токена
Future<void> _printFcmToken() async {
  try {
    String? token = await FirebaseMessaging.instance.getToken();
    if (kDebugMode) {
      print("--------------------------------------------------");
      print("FCM TOKEN: $token");
      print("--------------------------------------------------");
    }
  } catch (e) {
    if (kDebugMode) {
      print("Ошибка при получении токена: $e");
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: SettingsService.instance,
      builder: (context, child) {
        final isDark = SettingsService.instance.isDarkMode;

        return MaterialApp(
          title: 'Арабские буквы',
          navigatorObservers: [
            AnalyticsService.instance.observer,
          ],
          debugShowCheckedModeBanner: false,
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.teal,
              primary: Colors.teal.shade700,
              brightness: Brightness.light,
            ),
            scaffoldBackgroundColor: const Color(0xFFF8FAF9),
            cardTheme: CardThemeData(
              color: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200),
              ),
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF121212),
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.teal,
              primary: Colors.tealAccent.shade700,
              brightness: Brightness.dark,
              surface: const Color(0xFF1E1E1E),
            ),
            cardTheme: CardThemeData(
              color: const Color(0xFF1E1E1E),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFF2C2C2C)),
              ),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1E1E1E),
              elevation: 0,
            ),
          ),
          home: const HomeScreen(),
        );
      },
    );
  }
}