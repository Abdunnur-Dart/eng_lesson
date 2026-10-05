import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'settings_service.dart';
import 'analytics_service.dart';

class AuthService extends ChangeNotifier {
  static final AuthService instance = AuthService._init();
  
  AuthService._init() {
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        AnalyticsService.instance.setUserId(user.uid);
      } else {
        AnalyticsService.instance.setUserId(null);
      }
      notifyListeners();
    });
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  /// Вход по Email и Паролю
  Future<String?> signInWithEmail(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Ошибка авторизации.';
    } catch (e) {
      return 'Не удалось войти. Проверьте введенные данные.';
    }
  }

  /// Регистрация по Email и Паролю
  Future<String?> registerWithEmail(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
          'isPremium': false,
        }, SetOptions(merge: true));
      }

      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Ошибка регистрации.';
    } catch (e) {
      return 'Не удалось зарегистрировать пользователя.';
    }
  }

  /// Авторизация через Google
  Future<String?> signInWithGoogle() async {
    try {
      GoogleAuthProvider googleProvider = GoogleAuthProvider();
      UserCredential userCredential = await _auth.signInWithProvider(googleProvider);

      if (userCredential.user != null) {
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'email': userCredential.user!.email,
          'createdAt': FieldValue.serverTimestamp(),
          'isPremium': false,
        }, SetOptions(merge: true));

        await AnalyticsService.instance.setUserId(userCredential.user!.uid);
        await AnalyticsService.instance.logLogin(method: 'google');
      }

      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Ошибка авторизации Firebase.';
    } catch (e) {
      return 'Неудачная попытка входа через Google.';
    }
  }

  /// Авторизация через GitHub
  Future<String?> signInWithGithub() async {
    try {
      GithubAuthProvider githubProvider = GithubAuthProvider();
      UserCredential userCredential = await _auth.signInWithProvider(githubProvider);

      if (userCredential.user != null) {
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'email': userCredential.user!.email,
          'createdAt': FieldValue.serverTimestamp(),
          'isPremium': false,
        }, SetOptions(merge: true));

        await AnalyticsService.instance.setUserId(userCredential.user!.uid);
        await AnalyticsService.instance.logLogin(method: 'github');
      }

      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Ошибка авторизации через GitHub.';
    } catch (e) {
      return 'Неудачная попытка входа через GitHub.';
    }
  }

  /// Выход из системы
  Future<void> signOut() async {
    await _auth.signOut();
    await SettingsService.instance.clearUserDataOnSignOut();
    await AnalyticsService.instance.setUserId(null);
    notifyListeners();
  }
}