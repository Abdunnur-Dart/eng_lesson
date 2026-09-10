import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import '../services/subscription_service.dart';
import '../services/settings_service.dart';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http; // // NEW: Импортируем пакет для сетевых запросов к World Time API

class AuthPaymentScreen extends StatefulWidget {
  final bool isLoginOnly; // NEW: Флаг принудительного открытия входа

  const AuthPaymentScreen({
    super.key,
    this.isLoginOnly = false, // По умолчанию false (обычное поведение)
  });

  @override
  State<AuthPaymentScreen> createState() => _AuthPaymentScreenState();
}

class _AuthPaymentScreenState extends State<AuthPaymentScreen> {
  static const String _supportEmail = 'anvistanb17@gmail.com';
  String? _loadingProductId;

  // Контроллеры и состояния авторизации
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoginMode = true;
  bool _isAuthLoading = false;
  String? _authError;
  bool _dialogShown = false; // Флаг, чтобы модалка открывалась 1 раз при `isLoginOnly`

  @override
  void initState() {
    super.initState();
    // NEW: Если экран вызван именно для входа и пользователь еще не авторизован — сразу показываем диалог авторизации
    if (widget.isLoginOnly) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (FirebaseAuth.instance.currentUser == null && !_dialogShown) {
          _dialogShown = true;
          _showAuthDialog(onDismiss: () {
            // Если пользователь закрыл диалог входа и не авторизовался, можно вернуть его назад
            if (FirebaseAuth.instance.currentUser == null && mounted) {
              Navigator.of(context).pop();
            }
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Авторизация / Регистрация с записью полного шаблона в Firestore
  Future<void> _submitAuth({String? pendingProductId, BuildContext? dialogContext, VoidCallback? onStateChanged}) async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _authError = 'Пожалуйста, заполните все поля');
      if (onStateChanged != null) onStateChanged();
      return;
    }

    setState(() {
      _isAuthLoading = true;
      _authError = null;
    });
    if (onStateChanged != null) onStateChanged();

    try {
      if (_isLoginMode) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } else {
        final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        final user = userCredential.user;
        if (user != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
            'autoRenew': false,
            'createdAt': FieldValue.serverTimestamp(),
            'email': email,
            'expiresAt': null,
            'isLifetime': false,
            'isPremium': false,
            'paymentId': null,
            'paymentMethodId': null,
            'premiumPurchasedAt': null,
            'subscriptionPeriod': null,
          }, SetOptions(merge: true));
        }
      }

      if (dialogContext != null && dialogContext.mounted) {
        Navigator.of(dialogContext).pop();
      }

      // Если это был режим `isLoginOnly`, то после успешного входа закрываем сам экран планов/входа и возвращаем на главный/настройки
      if (widget.isLoginOnly && mounted) {
        Navigator.of(context).pop();
        return;
      }

      if (pendingProductId != null && mounted) {
        _handlePayment(pendingProductId);
      }

    } on FirebaseAuthException catch (e) {
      setState(() {
        switch (e.code) {
          case 'user-not-found':
            _authError = 'Пользователь с таким email не найден';
            break;
          case 'wrong-password':
            _authError = 'Неверный пароль';
            break;
          case 'email-already-in-use':
            _authError = 'Этот email уже используется';
            break;
          case 'invalid-email':
            _authError = 'Некорректный формат email';
            break;
          case 'weak-password':
            _authError = 'Пароль слишком простой (минимум 6 символов)';
            break;
          default:
            _authError = e.message ?? 'Ошибка авторизации';
        }
      });
    } catch (e) {
      setState(() {
        _authError = 'Произошла непредвиденная ошибка: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _isAuthLoading = false);
        if (onStateChanged != null) onStateChanged();
      }
    }
  }

  // Модальное окно авторизации/регистрации
  void _showAuthDialog({String? pendingProductId, VoidCallback? onDismiss}) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _isLoginMode ? 'Войти в аккаунт' : 'Создать аккаунт',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, size: 20),
                              onPressed: () => Navigator.of(dialogContext).pop(),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isLoginMode
                              ? 'Введите учетные данные для авторизации'
                              : 'Зарегистрируйтесь для синхронизации аккаунта',
                          style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 20),

                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            prefixIcon: const Icon(Icons.email_outlined),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: isDark ? Colors.grey.shade900 : Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),

                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'Пароль',
                            prefixIcon: const Icon(Icons.lock_outline),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: isDark ? Colors.grey.shade900 : Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),

                        if (_authError != null) ...[
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline, color: Colors.red, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _authError!,
                                    style: const TextStyle(color: Colors.red, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],

                        ElevatedButton(
                          onPressed: _isAuthLoading
                              ? null
                              : () => _submitAuth(
                                    pendingProductId: pendingProductId,
                                    dialogContext: dialogContext,
                                    onStateChanged: () => setDialogState(() {}),
                                  ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isAuthLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : Text(
                                  _isLoginMode ? 'Войти' : 'Зарегистрироваться',
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                ),
                        ),
                        const SizedBox(height: 12),

                        TextButton(
                          onPressed: _isAuthLoading
                              ? null
                              : () {
                                  setState(() {
                                    _isLoginMode = !_isLoginMode;
                                    _authError = null;
                                  });
                                  setDialogState(() {});
                                },
                          child: Text(
                            _isLoginMode
                                ? 'Нет аккаунта? Зарегистрироваться'
                                : 'Уже есть аккаунт? Войти',
                            style: const TextStyle(color: Colors.teal, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    ).then((_) {
      if (onDismiss != null) onDismiss();
    });
  }

  Future<void> _handlePayment(String productId) async {
    if (FirebaseAuth.instance.currentUser == null) {
      _showAuthDialog(pendingProductId: productId);
      return;
    }

    setState(() => _loadingProductId = productId);

    try {
      await SubscriptionService.createPayment(productId, context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка оплаты: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _loadingProductId = null);
      }
    }
  }

  void _handleCancelSubscription() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24),
            SizedBox(width: 8),
            Text('Возврат средств'),
          ],
        ),
        content: const Text(
          'Вы действительно хотите отменить подписку и запросить возврат средств?\n\n'
          'Для оформления возврата потребуется обратиться в службу поддержки.',
          style: TextStyle(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              _showSupportModal();
            },
            child: const Text('Продолжить'),
          ),
        ],
      ),
    );
  }

  void _showSupportModal() {
    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid ?? 'Не авторизован';
    final userEmail = user?.email ?? 'Не указан';

    final settings = SettingsService.instance;
    final isPremium = settings.isPremium;
    final streak = settings.streakCount;
    final points = settings.totalPoints;

    final String systemInfo = '''
----------------------------------
Системная информация:
• User ID: $userId
• Email: $userEmail
• Premium: ${isPremium ? "Да" : "Нет"}
• Стрик: $streak дней
• Баллы: $points
----------------------------------''';

    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.teal.withAlpha(30),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.mark_email_read_rounded, color: Colors.teal, size: 22),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Служба поддержки',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.email_outlined, color: Colors.teal, size: 16),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: SelectableText(
                            _supportEmail,
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy_rounded, size: 16),
                          tooltip: 'Скопировать E-mail',
                          onPressed: () {
                            Clipboard.setData(const ClipboardData(text: _supportEmail));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('E-mail скопирован')),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                'Данные аккаунта для быстрого решения проблемы:',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.tealAccent : Colors.teal.shade800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            InkWell(
                              borderRadius: BorderRadius.circular(6),
                              onTap: () {
                                Clipboard.setData(ClipboardData(
                                  text: 'Здравствуйте! Хочу отменить подписку и вернуть средства.\n\n$systemInfo',
                                ));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Шаблон обращения скопирован')),
                                );
                              },
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                child: Row(
                                  children: [
                                    Icon(Icons.copy_rounded, size: 13, color: Colors.teal),
                                    SizedBox(width: 4),
                                    Text(
                                      'Скопировать',
                                      style: TextStyle(fontSize: 11, color: Colors.teal, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        SelectableText(
                          systemInfo,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontFamily: 'monospace',
                            color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = authSnapshot.data;

        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          appBar: AppBar(
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('⭐', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Text(
                  user == null ? 'Авторизация 🔐' : 'Премиум доступ 🏅',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                const Text('⭐', style: TextStyle(fontSize: 16)),
              ],
            ),
            centerTitle: true,
            elevation: 0,
            toolbarHeight: 46,
            actions: [
              // Кнопка для ручного вызова входа из шапки, если пользователь гость
              if (user == null)
                IconButton(
                  icon: const Icon(Icons.login_rounded),
                  tooltip: 'Войти',
                  onPressed: () => _showAuthDialog(),
                ),
            ],
          ),
          body: user == null
              ? _buildPaywallView()
              : StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(child: Text('Ошибка загрузки: ${snapshot.error}'));
                    }

                    final userData = (snapshot.hasData && snapshot.data!.exists)
                        ? snapshot.data!.data() as Map<String, dynamic>?
                        : null;

                    final bool isPremium = userData?['isPremium'] ?? false;
                    final bool isLifetime = userData?['isLifetime'] ?? false;
                    final Timestamp? expiresAtTimestamp = userData?['expiresAt'] as Timestamp?;

                    if (isPremium) {
                      return _buildActiveSubscriptionView(
                        isLifetime: isLifetime,
                        expiresAt: expiresAtTimestamp?.toDate(),
                      );
                    } else {
                      return _buildPaywallView();
                    }
                  },
                ),
        );
      },
    );
  }

  Widget _buildActiveSubscriptionView({
    required bool isLifetime,
    DateTime? expiresAt,
  }) {
    String formattedDate = 'Неограниченно';
    if (!isLifetime && expiresAt != null) {
      formattedDate = '${expiresAt.day.toString().padLeft(2, '0')}.'
          '${expiresAt.month.toString().padLeft(2, '0')}.'
          '${expiresAt.year}';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.green, size: 56),
            const SizedBox(height: 12),
            const Text('Подписка активна 🎉', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(
              isLifetime ? 'Доступ Навсегда ✨' : 'Срок действия до: $formattedDate',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Вернуться назад'),
            ),
            const SizedBox(height: 8),
            
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: _handleCancelSubscription,
              child: const Text('Отменить подписку и вернуть средства'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaywallView() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('config')
          .doc('tariffs')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        Map<String, dynamic> remoteData = {};

        if (snapshot.hasData && snapshot.data!.exists) {
          final rawData = snapshot.data!.data() as Map<String, dynamic>?;
          final String jsonString = rawData?['json_data'] ?? '{}';
          try {
            final decoded = json.decode(jsonString);
            if (decoded is Map<String, dynamic>) {
              remoteData = decoded;
            }
          } catch (e) {
            debugPrint('Ошибка парсинга JSON тарифов: $e');
          }
        }

        final monthData = remoteData['sub_1_month'] as Map<String, dynamic>?;
        final yearData = remoteData['sub_1_year'] as Map<String, dynamic>?;
        final lifetimeData = remoteData['lifetime_access'] as Map<String, dynamic>?;

        final globalTimer = remoteData['timer'] ?? remoteData['timer_end'];
        final monthTimer = monthData?['timer'] ?? monthData?['timer_end'];
        final yearTimer = yearData?['timer'] ?? yearData?['timer_end'];
        final lifetimeTimer = lifetimeData?['timer'] ?? lifetimeData?['timer_end'];

        final monthPrice = monthData?['price'] ?? 189;
        final monthOldPrice = monthData?['old_price'];
        final monthTitle = monthData?['title'] ?? '1 месяц';
        final monthSubtitle = monthData?['subtitle'] ?? 'Гибкий старт';
        final monthBadge = monthData?['badge'] as String?;

        final yearPrice = yearData?['price'] ?? 1990;
        final yearOldPrice = yearData?['old_price'];
        final yearTitle = yearData?['title'] ?? '1 год';
        final yearSubtitle = yearData?['subtitle'] ?? 'Выбор большинства';
        final yearBadge = yearData?['badge'] as String?;

        final lifetimePrice = lifetimeData?['price'] ?? 2990;
        final lifetimeOldPrice = lifetimeData?['old_price'];
        final lifetimeTitle = lifetimeData?['title'] ?? 'Навсегда';
        final lifetimeSubtitle = lifetimeData?['subtitle'] ?? 'Разовый платеж';
        final lifetimeBadge = lifetimeData?['badge'] as String?;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Кнопка быстрого вызова входа прямо с экрана тарифов для гостей
              OutlinedButton.icon(
                onPressed: () => _showAuthDialog(),
                icon: const Icon(Icons.login_rounded, size: 16, color: Colors.teal),
                label: const Text('Уже есть аккаунт? Войти', style: TextStyle(color: Colors.teal)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.teal),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 16),

              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('🚀', style: TextStyle(fontSize: 20)),
                  SizedBox(width: 8),
                  Text(
                    'Выберите тариф',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 8),
                  Text('✨', style: TextStyle(fontSize: 20)),
                ],
              ),

              if (globalTimer != null) ...[
                const SizedBox(height: 8),
                Center(
                  child: CountdownTimerWidget(
                    timerValue: globalTimer,
                    prefix: '🔥 Скидки заканчиваются через: ',
                    style: TextStyle(
                      color: Colors.red.shade900,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
              
              const SizedBox(height: 12),
              
              _buildPricingCard(
                productId: 'sub_1_month',
                title: monthTitle,
                price: '$monthPrice ₽',
                oldPrice: monthOldPrice != null ? '$monthOldPrice ₽' : null,
                subtitle: monthSubtitle,
                icon: Icons.flash_on_rounded,
                primaryColor: Colors.blue,
                badge: monthBadge,
                timer: monthTimer,
              ),
              const SizedBox(height: 8),

              _buildPricingCard(
                productId: 'sub_1_year',
                title: yearTitle,
                price: '$yearPrice ₽',
                oldPrice: yearOldPrice != null ? '$yearOldPrice ₽' : null,
                subtitle: yearSubtitle,
                icon: Icons.star_rounded,
                primaryColor: Colors.amber.shade800,
                badge: yearBadge,
                timer: yearTimer,
              ),
              const SizedBox(height: 8),

              _buildPricingCard(
                productId: 'lifetime_access',
                title: lifetimeTitle,
                price: '$lifetimePrice ₽',
                oldPrice: lifetimeOldPrice != null ? '$lifetimeOldPrice ₽' : null,
                subtitle: lifetimeSubtitle,
                icon: Icons.all_inclusive_rounded,
                primaryColor: Colors.teal.shade700,
                badge: lifetimeBadge,
                timer: lifetimeTimer,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPricingCard({
    required String productId,
    required String title,
    required String price,
    String? oldPrice,
    required String subtitle,
    required IconData icon,
    required Color primaryColor,
    String? badge,
    dynamic timer,
  }) {
    final bool isThisLoading = _loadingProductId == productId;
    final bool isAnyLoading = _loadingProductId != null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: badge != null && badge.isNotEmpty 
              ? primaryColor.withValues(alpha: 0.5) 
              : Colors.grey.shade200,
          width: badge != null && badge.isNotEmpty ? 1.5 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: isAnyLoading ? null : () => _handlePayment(productId),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: primaryColor, size: 20),
                ),
                const SizedBox(width: 12),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          if (badge != null && badge.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.red.shade600,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                badge,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                      
                      if (timer != null) ...[
                        const SizedBox(height: 6),
                        CountdownTimerWidget(
                          timerValue: timer,
                          prefix: '⏳ ',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade800,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (oldPrice != null) ...[
                      Text(
                        oldPrice,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red.shade500,
                          decoration: TextDecoration.lineThrough,
                          decorationColor: Colors.red.shade500,
                          decorationThickness: 2,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 1),
                    ],
                    Text(
                      price,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: primaryColor,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    isThisLoading
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            'Выбрать →',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade500,
                            ),
                          ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CountdownTimerWidget extends StatefulWidget {
  final dynamic timerValue;
  final TextStyle? style;
  final String prefix;

  const CountdownTimerWidget({
    super.key,
    required this.timerValue,
    this.style,
    this.prefix = '⏳ До конца: ',
  });

  @override
  State<CountdownTimerWidget> createState() => _CountdownTimerWidgetState();
}

class _CountdownTimerWidgetState extends State<CountdownTimerWidget> {
  static final Map<String, DateTime> _relativeTargetCache = {};
  
  // // NEW: Кэш смещения сетевого времени относительно локального устройства для предотвращения частых запросов
  static Duration? _networkTimeOffset;
  static DateTime? _lastSyncTime;

  Timer? _timer;
  Duration _remainingDuration = Duration.zero;
  DateTime? _targetTime;
  bool _isSyncing = true; // // NEW: Флаг загрузки сетевого времени

  @override
  void initState() {
    super.initState();
    _initTimerWithNetworkSync(); // // CHANGED: Инициализация с запросом к World Time API
  }

  @override
  void didUpdateWidget(covariant CountdownTimerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.timerValue != widget.timerValue) {
      _timer?.cancel();
      _initTimerWithNetworkSync(); // // CHANGED: Переинициализация при обновлении данных тарифа
    }
  }

  // // NEW: Метод получения точного сетевого времени через World Time API с защитой от лимитов (rate limit)
  Future<void> _initTimerWithNetworkSync() async {
    _targetTime = _parseTimerValue(widget.timerValue);
    if (_targetTime == null) {
      if (mounted) setState(() => _isSyncing = false);
      return;
    }

    // Если мы уже синхронизировали время менее чем 5 минут назад, используем готовое смещение для экономии лимита API
    if (_networkTimeOffset == null || _lastSyncTime == null || DateTime.now().difference(_lastSyncTime!) > const Duration(minutes: 5)) {
      try {
        final response = await http
            .get(Uri.parse('http://worldtimeapi.org/api/ip'))
            .timeout(const Duration(seconds: 4));

        if (response.statusCode == 200) {
          final data = json.decode(response.body) as Map<String, dynamic>;
          // Поле unixtime содержит количество секунд с эпохи Unix в UTC
          final int unixtime = data['unixtime'] ?? 0;
          if (unixtime > 0) {
            final networkTime = DateTime.fromMillisecondsSinceEpoch(unixtime * 1000, isUtc: true).toLocal();
            _networkTimeOffset = networkTime.difference(DateTime.now());
            _lastSyncTime = DateTime.now();
          }
        }
      } catch (e) {
        // Если сеть недоступна или сработал Rate Limit (429), безопасно падаем на локальные часы устройства
        debugPrint('World Time API sync failed, falling back to local time: $e');
        _networkTimeOffset ??= Duration.zero;
      }
    }

    if (!mounted) return;

    // Вычисляем текущее точное время с учетом сетевого смещения
    final correctedNow = DateTime.now().add(_networkTimeOffset ?? Duration.zero);
    final diff = _targetTime!.difference(correctedNow);

    setState(() {
      _remainingDuration = diff.isNegative ? Duration.zero : diff;
      _isSyncing = false;
    });

    if (_remainingDuration > Duration.zero) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        _calculateRemaining();
      });
    }
  }

  DateTime? _parseTimerValue(dynamic val) {
    if (val == null) return null;

    if (val is String) {
      final parsedDate = DateTime.tryParse(val);
      if (parsedDate != null) return parsedDate.toLocal();
      final parsedInt = int.tryParse(val);
      if (parsedInt != null) return _parseFromNum(parsedInt);
    } else if (val is num) {
      return _parseFromNum(val);
    }
    return null;
  }

  DateTime _parseFromNum(num n) {
    if (n > 1000000000000) {
      return DateTime.fromMillisecondsSinceEpoch(n.toInt()).toLocal();
    }
    if (n > 1000000000) {
      return DateTime.fromMillisecondsSinceEpoch((n * 1000).toInt()).toLocal();
    }
    
    final cacheKey = 'rel_sec_${n.toInt()}';
    if (!_relativeTargetCache.containsKey(cacheKey) ||
        _relativeTargetCache[cacheKey]!.isBefore(DateTime.now())) {
      _relativeTargetCache[cacheKey] = DateTime.now().add(Duration(seconds: n.toInt()));
    }
    return _relativeTargetCache[cacheKey]!;
  }

  void _calculateRemaining() {
    if (_targetTime == null) return;
    // Используем скорректированное сетевое время каждую секунду тика таймера
    final correctedNow = DateTime.now().add(_networkTimeOffset ?? Duration.zero);
    final diff = _targetTime!.difference(correctedNow);
    if (!mounted) return;
    setState(() {
      if (diff.isNegative) {
        _remainingDuration = Duration.zero;
        _timer?.cancel();
      } else {
        _remainingDuration = diff;
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    if (duration.isNegative || duration.inSeconds <= 0) {
      return '00:00:00';
    }
    final days = duration.inDays;
    final hours = (duration.inHours % 24).toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');

    if (days > 0) {
      return '$daysд $hours:$minutes:$seconds';
    }
    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    if (_targetTime == null || _remainingDuration <= Duration.zero) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.red.shade200, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer_outlined, size: 12, color: Colors.red),
          const SizedBox(width: 4),
          Flexible(
            child: _isSyncing
                ? const SizedBox(
                    width: 10,
                    height: 10,
                    child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.red),
                  )
                : Text(
                    '${widget.prefix}${_formatDuration(_remainingDuration)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: widget.style ??
                        TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade800,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                  ),
          ),
        ],
      ),
    );
  }
}