import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthService extends ChangeNotifier {
  static final AuthService instance = AuthService._init();
  AuthService._init();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  Future<String?> signInWithEmail(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      notifyListeners();
      return null; // Ошибок нет
    } on FirebaseAuthException catch (e) {
      // CHANGED: Перехватываем ошибку неверных данных и устаревшего токена
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
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      notifyListeners();
      return null; // Ошибок нет
    } on FirebaseAuthException catch (e) {
      // CHANGED: Добавлена обработка специфичных ошибок регистрации
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
    notifyListeners();
  }
}