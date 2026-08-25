import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/auth_service.dart';
import '../services/subscription_service.dart';
import '../services/analytics_service.dart'; // NEW
import 'payment_webview_screen.dart';

class AuthPaymentScreen extends StatefulWidget {
  const AuthPaymentScreen({super.key});

  @override
  State<AuthPaymentScreen> createState() => _AuthPaymentScreenState();
}

class _AuthPaymentScreenState extends State<AuthPaymentScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final SubscriptionService _subscriptionService = SubscriptionService();
  bool _isLogin = true;
  bool _isLoading = false;
  bool _isPaymentLoading = false;

  Timer? _countdownTimer;
  Duration _remainingTime = Duration.zero;
  bool _isCancelling = false;

  @override // NEW
  void initState() { // NEW
    super.initState(); // NEW
    AnalyticsService.instance.logScreenView(screenName: 'AuthPaymentScreen'); // NEW
  } // NEW

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _startCountdown(DateTime expiresAt, String userId) {
    _countdownTimer?.cancel();

    void updateRemaining() {
      final now = DateTime.now();
      final difference = expiresAt.difference(now);

      if (difference.isNegative) {
        _countdownTimer?.cancel();
        if (mounted) {
          setState(() {
            _remainingTime = Duration.zero;
          });
          _subscriptionService.checkIsPremiumActive(userId);
        }
      } else {
        if (mounted) {
          setState(() {
            _remainingTime = difference;
          });
        }
      }
    }

    updateRemaining();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) => updateRemaining());
  }

  Future<void> _submitAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Заполните email и пароль')),
      );
      return;
    }

    setState(() => _isLoading = true);
    String? error;

    try { // NEW
      if (_isLogin) {
        error = await AuthService.instance.signInWithEmail(email, password);
      } else {
        error = await AuthService.instance.registerWithEmail(email, password);
      }
    } finally { // NEW
      _passwordController.clear(); // NEW - очищаем чувствительные данные из памяти контроллера сразу после запроса
    } // NEW

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    } else {
      _emailController.clear(); // NEW - очищаем email при успешной авторизации
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isLogin ? 'Успешный вход!' : 'Регистрация успешна!'),
        ),
      );
    }
  }

  /// Открытие оплаты разовой покупки
  Future<void> _openOneTimePaymentPage(User user) async {
    if (!mounted) return;
    setState(() => _isPaymentLoading = true);

    AnalyticsService.instance.logEvent( // NEW
      name: 'begin_checkout', // NEW
      parameters: {'product_id': 'lifetime_access', 'price': 499.0}, // NEW
    ); // NEW

    final confirmationUrl = await _subscriptionService.createOneTimePayment(
      userId: user.uid,
      productId: 'lifetime_access',
    );

    if (!mounted) return;
    setState(() => _isPaymentLoading = false);

    if (confirmationUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка формирования счета для оплаты')),
      );
      return;
    }

    if (kIsWeb) {
      final Uri url = Uri.parse(confirmationUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        
        if (!mounted) return;
        await _showActivationDialogAndWait(user.uid);
      }
      return;
    }

    final bool? result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentWebViewScreen(
          initialUrl: confirmationUrl,
          title: 'Разовая покупка',
        ),
      ),
    );

    if (!mounted) return;

    if (result == true) {
      await _showActivationDialogAndWait(user.uid);
    }
  }

  Future<void> _showActivationDialogAndWait(String userId) async {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Expanded(child: Text('Проверяем статус оплаты и активируем доступ...')),
          ],
        ),
      ),
    );

    final bool activated = await _subscriptionService.waitForLifetimeActivation(userId);

    if (!mounted) return;

    Navigator.of(context, rootNavigator: true).pop();

    if (activated) { // NEW
      AnalyticsService.instance.logPurchase( // NEW
        productId: 'lifetime_access', // NEW
        price: 499.00, // NEW
        currency: 'RUB', // NEW
      ); // NEW
    } // NEW

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          activated
              ? 'Оплата успешно подтверждена! Премиум активирован 🚀'
              : 'Платеж обрабатывается. Статус обновится автоматически через пару секунд.',
        ),
        backgroundColor: activated ? Colors.green.shade700 : Colors.orange.shade800,
      ),
    );
  }

  Future<void> _handleCancelSubscription(User user) async {
    if (!mounted) return;
    setState(() => _isCancelling = true);
    final success = await _subscriptionService.cancelSubscription(user.uid);
    if (!mounted) return;
    setState(() => _isCancelling = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Автопродление подписки отключено')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось отключить автопродление')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        final user = authSnapshot.data;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Доступ и Оплата', style: TextStyle(fontWeight: FontWeight.bold)),
            centerTitle: true,
            elevation: 0,
          ),
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: user == null
                  ? _buildAuthForm()
                  : _buildSubscriptionStatus(user),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAuthForm() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.lock_outline_rounded, size: 48, color: Colors.teal.shade700),
            const SizedBox(height: 16),
            Text(
              _isLogin ? 'Вход в аккаунт' : 'Создание аккаунта',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _isLogin 
                  ? 'Авторизуйтесь, чтобы синхронизировать ваш прогресс' 
                  : 'Зарегистрируйтесь для сохранения доступа',
              style: TextStyle(fontSize: 13, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Пароль',
                prefixIcon: const Icon(Icons.lock_outline),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _submitAuth,
                    child: Text(
                      _isLogin ? 'Войти' : 'Зарегистрироваться',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => setState(() => _isLogin = !_isLogin),
              child: Text(
                _isLogin
                    ? 'Нет аккаунта? Зарегистрироваться'
                    : 'Уже есть аккаунт? Войти',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionStatus(User user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        bool isPremium = false;
        bool autoRenew = false;
        bool isLifetime = false;
        DateTime? expiresAt;

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          isPremium = SubscriptionService.isDataPremiumActive(data);
          autoRenew = data?['autoRenew'] ?? false;
          
          final dynamic rawLifetime = data?['isLifetime'];
          final dynamic rawPeriod = data?['subscriptionPeriod'];
          isLifetime = rawLifetime == true || 
              rawLifetime.toString().toLowerCase() == 'true' || 
              rawPeriod.toString().toLowerCase() == 'lifetime';

          expiresAt = SubscriptionService.getExpirationDate(data);

          if (isPremium && expiresAt != null && !isLifetime) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _startCountdown(expiresAt!, user.uid);
            });
          }
        }

        final days = _remainingTime.inDays;
        final hours = _remainingTime.inHours.remainder(24);
        final minutes = _remainingTime.inMinutes.remainder(60);
        final seconds = _remainingTime.inSeconds.remainder(60);

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isPremium 
                      ? Colors.amber.shade600.withAlpha(100) 
                      : (isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade200),
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: isPremium
                      ? LinearGradient(
                          colors: [
                            Colors.amber.shade900.withAlpha(30),
                            Colors.amber.shade700.withAlpha(10),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                ),
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isPremium 
                            ? Colors.amber.shade500.withAlpha(30) 
                            : Colors.grey.shade500.withAlpha(20),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isPremium ? Icons.workspace_premium_rounded : Icons.lock_outline_rounded,
                        color: isPremium ? Colors.amber : Colors.grey,
                        size: 56,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Текущий аккаунт:',
                      style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                    ),
                    Text(
                      user.email ?? '',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Chip(
                      backgroundColor: isPremium ? Colors.green.shade900.withAlpha(50) : Colors.red.shade900.withAlpha(50),
                      side: BorderSide(color: isPremium ? Colors.green : Colors.red),
                      avatar: Icon(
                        isPremium ? Icons.check_circle_rounded : Icons.cancel_rounded,
                        color: isPremium ? Colors.greenAccent : Colors.redAccent,
                        size: 18,
                      ),
                      label: Text(
                        isPremium
                            ? (isLifetime ? 'Бессрочный Премиум 🚀' : 'Премиум Активен 🎉')
                            : 'Доступ ограничен',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isPremium ? Colors.greenAccent : Colors.redAccent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (isPremium && expiresAt != null && !isLifetime) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text(
                        'Осталось времени доступа:',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${days}д ${hours}ч ${minutes}м ${seconds}с',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal.shade400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            if (!isPremium) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Полный доступ',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade800,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'НАВСЕГДА',
                              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildFeatureRow('Все 28 уроков и интерактивные правила'),
                      const SizedBox(height: 20),
                      _isPaymentLoading
                          ? const Center(child: CircularProgressIndicator())
                          : SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange.shade800,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: () => _openOneTimePaymentPage(user),
                                child: const Text(
                                  'Купить навсегда за 499 ₽',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                    ],
                  ),
                ),
              ),
            ] else if (autoRenew && !isLifetime) ...[
              _isCancelling
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => _handleCancelSubscription(user),
                      child: const Text('Отменить автопродление'),
                    ),
            ],

            const SizedBox(height: 16),

            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.logout_rounded, size: 20),
              label: const Text('Выйти из аккаунта'),
              onPressed: () => AuthService.instance.signOut(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFeatureRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline_rounded, size: 18, color: Colors.teal.shade400),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}