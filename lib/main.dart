import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'screens/auth_payment_screen.dart';
import 'screens/home_screen.dart';
import 'services/analytics_service.dart';
import 'services/fcm_service.dart';
import 'services/settings_service.dart';

// Глобальный ключ для управления навигацией вне контекста виджетов
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Инициализация Firebase
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  // 2. Инициализация Firebase App Check
  await FirebaseAppCheck.instance.activate(
    androidProvider: kDebugMode
        ? AndroidProvider.debug
        : AndroidProvider.playIntegrity,
    appleProvider: kDebugMode
        ? AppleProvider.debug
        : AppleProvider.deviceCheck,
  );

  // 3. Инициализация сервиса уведомлений (FCM + локальная шторка)
  await FcmService().init();

  // 4. Вывод FCM токена в консоль для тестирования
  await _printFcmToken();

  // 5. Настройка устойчивости Firestore (оффлайн + SSL)
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    sslEnabled: true,
  );

  runApp(const MyApp());
}

// Функция для получения и вывода FCM токена
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
      print("Ошибка при получении токена FCM: $e");
    }
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();

  }

  // Показ диалога с перенаправлением в отдельное приложение RuStore // CHANGED
  // Показ диалога с перенаправлением в отдельное приложение RuStore // CHANGED
 

  void _initDeepLinks() {
    _appLinks = AppLinks();

    // 1. Обработка ссылки при холодном запуске (приложение закрыто)
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) _handleUri(uri);
    });

    // 2. Обработка ссылки при горячем запуске (приложение свернуто)
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleUri(uri);
    });
  }

  void _handleUri(Uri uri) {
    if (kDebugMode) {
      print("--------------------------------------------------");
      print("DEEP LINK RECEIVED: $uri");
      print("Scheme: ${uri.scheme}, Host: ${uri.host}, Path: ${uri.path}");
      print("--------------------------------------------------");
    }

    if ((uri.scheme == 'arabicletters' || uri.scheme == 'muallimsani') &&
        (uri.host == 'paywall' || uri.path.contains('paywall'))) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (navigatorKey.currentState != null) {
          navigatorKey.currentState!.push(
            MaterialPageRoute(builder: (_) => const AuthPaymentScreen()),
          );
        } else {
          if (kDebugMode) print("Ошибка: navigatorKey.currentState равен null");
        }
      });
    }
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: SettingsService.instance,
      builder: (context, child) {
        final isDark = SettingsService.instance.isDarkMode;

        return MaterialApp(
          navigatorKey: navigatorKey,
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