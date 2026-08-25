import 'package:firebase_auth/firebase_auth.dart'; // NEW
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'settings_service.dart';
import 'analytics_service.dart'; // NEW

class AuthService extends ChangeNotifier {
  static final AuthService instance = AuthService._init();
  
  AuthService._init() { // CHANGED
    _auth.authStateChanges().listen((user) { // CHANGED
      if (user != null) { // NEW
        AnalyticsService.instance.setUserId(user.uid); // NEW
      } else { // NEW
        AnalyticsService.instance.setUserId(null); // NEW
      } // NEW
      notifyListeners(); // NEW
    }); // NEW
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Future<String?> signInWithEmail(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await AnalyticsService.instance.logLogin(method: 'email'); // NEW
      notifyListeners();
      return null; // Ошибок нет
    } on FirebaseAuthException catch (e) {
      if (e.code == 'invalid-credential' || e.code == 'wrong-password' || e.code == 'user-not-found') {
        return 'Неверный email или пароль.';
      } else if (e.code == 'user-disabled') {
        return 'Учетная запись заблокирована.';
      } else if (e.code == 'invalid-email') {
        return 'Некорректный формат email.';
      }
      return e.message ?? 'Ошибка авторизации.';
    } catch (e) {
      return 'Произошла непредвиденная ошибка.';
    }
  }

  Future<String?> registerWithEmail(String email, String password) async {
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        await _firestore.collection('users').doc(credential.user!.uid).set({
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
          'isPremium': false,
        }, SetOptions(merge: true));
        await AnalyticsService.instance.setUserId(credential.user!.uid); // NEW
        await AnalyticsService.instance.logSignUp(method: 'email'); // NEW
      }

      notifyListeners();
      return null; // Ошибок нет
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        return 'Пользователь с таким email уже существует.';
      } else if (e.code == 'weak-password') {
        return 'Пароль слишком простой (минимум 6 символов).';
      }
      return e.message ?? 'Ошибка регистрации.';
    } catch (e) {
      return 'Произошла непредвиденная ошибка.';
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await SettingsService.instance.clearUserDataOnSignOut();
    await AnalyticsService.instance.setUserId(null); // NEW
    notifyListeners();
  }
}