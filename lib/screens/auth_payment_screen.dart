import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class AuthPaymentScreen extends StatefulWidget {
  const AuthPaymentScreen({super.key});

  @override
  State<AuthPaymentScreen> createState() => _AuthPaymentScreenState();
}

class _AuthPaymentScreenState extends State<AuthPaymentScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;

  Future<void> _submitAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Заполните email и пароль')),
      );
      return;
    }

    setState(() => _isLoading = true);
    String? error;

    if (_isLogin) {
      error = await AuthService.instance.signInWithEmail(email, password);
    } else {
      error = await AuthService.instance.registerWithEmail(email, password);
    }

    setState(() => _isLoading = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isLogin ? 'Успешный вход!' : 'Регистрация успешна!')),
      );
    }
  }

  Future<void> _openPaymentPage(User user) async {
    final String appReturn = kIsWeb 
        ? 'https://yookassaproj201514.vercel.app/' 
        : 'muallimsani://success';

    final String urlString = 'https://yookassaproj201514.vercel.app/?user_id=${user.uid}&app_return=${Uri.encodeComponent(appReturn)}';
    final Uri url = Uri.parse(urlString);

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        throw 'Не удалось открыть ссылку';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка открытия оплаты: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Слушаем изменения авторизации Firebase
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        final user = authSnapshot.data;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Аккаунт и подписка'),
            backgroundColor: Colors.teal.shade800,
            foregroundColor: Colors.white,
            centerTitle: true,
          ),
          body: Padding(
            padding: const EdgeInsets.all(20.0),
            child: user == null
                ? _buildAuthForm()
                : _buildSubscriptionStatus(user),
          ),
        );
      },
    );
  }

  // Форма входа и регистрации
  Widget _buildAuthForm() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _isLogin ? 'Вход в аккаунт' : 'Регистрация',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: 'Email', 
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _passwordController,
          decoration: const InputDecoration(
            labelText: 'Пароль', 
            border: OutlineInputBorder(),
          ),
          obscureText: true,
        ),
        const SizedBox(height: 20),
        _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _submitAuth,
                child: Text(
                  _isLogin ? 'Войти' : 'Зарегистрироваться', 
                  style: const TextStyle(fontSize: 16),
                ),
              ),
        TextButton(
          onPressed: () => setState(() => _isLogin = !_isLogin),
          child: Text(_isLogin ? 'Нет аккаунта? Зарегистрироваться' : 'Уже есть аккаунт? Войти'),
        ),
      ],
    );
  }

  // Экран статуса подписки с получением данных в реальном времени
  Widget _buildSubscriptionStatus(User user) {
    return StreamBuilder<DocumentSnapshot>(
      // Слушаем изменения документа пользователя в реальном времени
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        bool isPremium = false;
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          isPremium = data?['isPremium'] ?? false;
        }

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              isPremium ? Icons.verified : Icons.stars,
              color: isPremium ? Colors.amber.shade700 : Colors.teal.shade400,
              size: 80,
            ),
            const SizedBox(height: 20),
            Text(
              'Вы авторизованы как:\n${user.email}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              isPremium ? 'Подписка активна 🎉' : 'Подписка не оформлена',
              style: TextStyle(
                fontSize: 16, 
                fontWeight: FontWeight.w600,
                color: isPremium ? Colors.green.shade700 : Colors.red.shade700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            if (!isPremium)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade800,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () => _openPaymentPage(user),
                child: const Text(
                  'Оформить подписку', 
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: () => AuthService.instance.signOut(),
              child: const Text('Выйти из аккаунта'),
            ),
          ],
        );
      },
    );
  }
}