import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../services/settings_service.dart';
import '../services/subscription_service.dart';
import 'auth_screen.dart';

class AuthPaymentScreen extends StatefulWidget {
  final bool isLoginOnly;

  const AuthPaymentScreen({
    super.key,
    this.isLoginOnly = false,
  });

  @override
  State<AuthPaymentScreen> createState() => _AuthPaymentScreenState();
}

class _AuthPaymentScreenState extends State<AuthPaymentScreen> {
  static const String _supportEmail = 'anvistanb17@gmail.com';

  String? _loadingProductId;

  @override
  void initState() {
    super.initState();
    if (widget.isLoginOnly) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (FirebaseAuth.instance.currentUser == null && mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const AuthScreen()),
          );
        }
      });
    }
  }

  Future<void> _handlePayment(String productId) async {
    if (FirebaseAuth.instance.currentUser == null) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const AuthScreen()),
      );
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

  void _handleCancelSubscription({String? paymentId}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final displayPaymentId = (paymentId != null && paymentId.isNotEmpty)
        ? paymentId
        : 'Не найдено';

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: _buildLiquidGlassContainer(
          context: context,
          borderRadius: 24,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.warning_amber_rounded,
                        color: Colors.orange, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Возврат средств',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Вы действительно хотите отменить подписку и запросить возврат средств?\n\n'
                'Для оформления возврата потребуется обратиться в службу поддержки.',
                style: TextStyle(
                  height: 1.4,
                  color: textColor.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 16),
              _buildLiquidGlassContainer(
                context: context,
                borderRadius: 14,
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ID платежа (ЮKassa):',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: textColor.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: SelectableText(
                            displayPaymentId,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                              color: textColor,
                            ),
                          ),
                        ),
                        if (paymentId != null && paymentId.isNotEmpty)
                          IconButton(
                            icon: Icon(Icons.copy_rounded,
                                size: 18, color: textColor.withValues(alpha: 0.7)),
                            tooltip: 'Скопировать ID платежа',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              Clipboard.setData(
                                  ClipboardData(text: paymentId));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Payment ID скопирован')),
                              );
                            },
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Отмена',
                        style: TextStyle(color: textColor.withValues(alpha: 0.7))),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent.withValues(alpha: 0.8),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      _showSupportModal(paymentId: paymentId);
                    },
                    child: const Text('Продолжить'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showSupportModal({String? paymentId}) async {
    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid ?? 'Не авторизован';
    final userEmail = user?.email ?? 'Не указан';

    String finalPaymentId = paymentId ?? 'Не найден';
    if (paymentId == null && user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists) {
          final data = doc.data();
          finalPaymentId =
              data?['lastPaymentId'] ?? data?['paymentId'] ?? 'Не найден';
        }
      } catch (e) {
        debugPrint('Ошибка получения paymentId: $e');
      }
    }

    final settings = SettingsService.instance;
    final isPremium = settings.isPremium;
    final streak = settings.streakCount;
    final points = settings.totalPoints;

    final String systemInfo = '''
----------------------------------
Системная информация:
• User ID: $userId
• Email: $userEmail
• Payment ID: $finalPaymentId
• Premium: ${isPremium ? "Да" : "Нет"}
• Стрик: $streak дней
• Баллы: $points
----------------------------------''';

    if (!mounted) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final accentColor = isDark ? const Color(0xFF818CF8) : const Color(0xFF4F46E5);

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: _buildLiquidGlassContainer(
              context: context,
              borderRadius: 24,
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.mark_email_read_rounded,
                            color: accentColor, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Служба поддержки',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textColor),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close_rounded,
                            size: 20, color: textColor.withValues(alpha: 0.6)),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildLiquidGlassContainer(
                    context: context,
                    borderRadius: 12,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        Icon(Icons.email_outlined,
                            color: accentColor, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SelectableText(
                            _supportEmail,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                                color: textColor),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.copy_rounded,
                              size: 16, color: textColor.withValues(alpha: 0.6)),
                          tooltip: 'Скопировать E-mail',
                          onPressed: () {
                            Clipboard.setData(
                                const ClipboardData(text: _supportEmail));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('E-mail скопирован')),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildLiquidGlassContainer(
                    context: context,
                    borderRadius: 14,
                    padding: const EdgeInsets.all(12),
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
                                  color: accentColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            InkWell(
                              borderRadius: BorderRadius.circular(6),
                              onTap: () {
                                Clipboard.setData(ClipboardData(
                                  text:
                                      'Здравствуйте! Хочу отменить подписку и вернуть средства.\n\n$systemInfo',
                                ));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Шаблон обращения скопирован')),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                child: Row(
                                  children: [
                                    Icon(Icons.copy_rounded,
                                        size: 13, color: accentColor),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Скопировать',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: accentColor,
                                          fontWeight: FontWeight.bold),
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
                            color: textColor.withValues(alpha: 0.85),
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

  // Адаптивная обёртка Liquid Glass
  static Widget _buildLiquidGlassContainer({
    required BuildContext context,
    required Widget child,
    double borderRadius = 20,
    EdgeInsetsGeometry? padding,
    Color? borderColor,
    double blur = 16,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final defaultGradient = isDark
        ? [
            Colors.white.withValues(alpha: 0.12),
            Colors.white.withValues(alpha: 0.04),
          ]
        : [
            Colors.white.withValues(alpha: 0.65),
            Colors.white.withValues(alpha: 0.35),
          ];

    final defaultBorder = isDark
        ? Colors.white.withValues(alpha: 0.2)
        : Colors.white.withValues(alpha: 0.6);

    final defaultShadow = isDark
        ? Colors.black.withValues(alpha: 0.18)
        : Colors.blueGrey.withValues(alpha: 0.08);

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: defaultGradient,
            ),
            border: Border.all(
              color: borderColor ?? defaultBorder,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: defaultShadow,
                blurRadius: 16,
                spreadRadius: 2,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final primaryColor = isDark ? const Color(0xFF818CF8) : const Color(0xFF4F46E5);

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
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.3),
                ),
              ),
            ),
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('⭐', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Text(
                  'Премиум доступ 🏅',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(width: 8),
                const Text('⭐', style: TextStyle(fontSize: 16)),
              ],
            ),
            centerTitle: true,
            toolbarHeight: 46,
            iconTheme: IconThemeData(color: textColor),
          ),
          body: Stack(
            children: [
              // Liquid Background Effects (Deep Indigo / Cyber Palette)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? const [
                              Color(0xFF0F172A),
                              Color(0xFF1E1B4B),
                              Color(0xFF09090B),
                            ]
                          : const [
                              Color(0xFFF8FAFC),
                              Color(0xFFEEF2FF),
                              Color(0xFFE0E7FF),
                            ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 80,
                right: -60,
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: primaryColor.withValues(alpha: 0.2),
                  ),
                ),
              ),
              Positioned(
                bottom: 120,
                left: -80,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark
                        ? const Color(0xFF6366F1).withValues(alpha: 0.15)
                        : const Color(0xFF818CF8).withValues(alpha: 0.15),
                  ),
                ),
              ),
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                  child: const SizedBox.shrink(),
                ),
              ),
              // Main Content Body
              SafeArea(
                child: user == null
                    ? _buildPaywallView(user: user)
                    : StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(user.uid)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Center(
                                child: CircularProgressIndicator(
                                    color: textColor));
                          }

                          if (snapshot.hasError) {
                            return Center(
                                child: Text(
                                    'Ошибка загрузки: ${snapshot.error}',
                                    style: TextStyle(color: textColor)));
                          }

                          final userData =
                              (snapshot.hasData && snapshot.data!.exists)
                                  ? snapshot.data!.data()
                                      as Map<String, dynamic>?
                                  : null;

                          final bool isPremium =
                              userData?['isPremium'] ?? false;
                          final bool isLifetime =
                              userData?['isLifetime'] ?? false;
                          final Timestamp? expiresAtTimestamp =
                              userData?['expiresAt'] as Timestamp?;
                          final String? paymentId =
                              userData?['lastPaymentId'] ??
                                  userData?['paymentId'];

                          if (isPremium) {
                            return _buildActiveSubscriptionView(
                              isLifetime: isLifetime,
                              expiresAt: expiresAtTimestamp?.toDate(),
                              paymentId: paymentId,
                            );
                          } else {
                            return _buildPaywallView(user: user);
                          }
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActiveSubscriptionView({
    required bool isLifetime,
    DateTime? expiresAt,
    String? paymentId,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);

    String formattedDate = 'Неограниченно';
    if (!isLifetime && expiresAt != null) {
      formattedDate = '${expiresAt.day.toString().padLeft(2, '0')}.'
          '${expiresAt.month.toString().padLeft(2, '0')}.'
          '${expiresAt.year}';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: _buildLiquidGlassContainer(
          context: context,
          borderRadius: 24,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_circle_rounded,
                    color: isDark ? Colors.greenAccent : Colors.green.shade600, size: 56),
              ),
              const SizedBox(height: 16),
              Text('Подписка активна 🎉',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: textColor)),
              const SizedBox(height: 8),
              Text(
                isLifetime
                    ? 'Доступ Навсегда ✨'
                    : 'Срок действия до: $formattedDate',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: textColor.withValues(alpha: 0.7)),
              ),
              if (paymentId != null && paymentId.isNotEmpty) ...[
                const SizedBox(height: 8),
                SelectableText(
                  'ID платежа: $paymentId',
                  style: TextStyle(
                      fontSize: 12,
                      color: textColor.withValues(alpha: 0.5),
                      fontFamily: 'monospace'),
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark
                      ? Colors.white.withValues(alpha: 0.15)
                      : Colors.black.withValues(alpha: 0.08),
                  foregroundColor: textColor,
                  elevation: 0,
                  side: BorderSide(
                      color: textColor.withValues(alpha: 0.2)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Вернуться назад'),
              ),
              const SizedBox(height: 12),
              TextButton(
                style: TextButton.styleFrom(
                    foregroundColor: Colors.redAccent),
                onPressed: () =>
                    _handleCancelSubscription(paymentId: paymentId),
                child: const Text('Отменить подписку и вернуть средства'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaywallView({User? user}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final accentColor = isDark ? const Color(0xFF818CF8) : const Color(0xFF4F46E5);

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('config')
          .doc('tariffs')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
              child: CircularProgressIndicator(color: textColor));
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
        final lifetimeData =
            remoteData['lifetime_access'] as Map<String, dynamic>?;

        final globalTimer = remoteData['timer'] ?? remoteData['timer_end'];
        final monthTimer = monthData?['timer'] ?? monthData?['timer_end'];
        final yearTimer = yearData?['timer'] ?? yearData?['timer_end'];
        final lifetimeTimer =
            lifetimeData?['timer'] ?? lifetimeData?['timer_end'];

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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🚀', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Text(
                    'Выберите тариф',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textColor),
                  ),
                  const SizedBox(width: 8),
                  const Text('✨', style: TextStyle(fontSize: 20)),
                ],
              ),
              if (globalTimer != null) ...[
                const SizedBox(height: 10),
                Center(
                  child: CountdownTimerWidget(
                    timerValue: globalTimer,
                    prefix: '🔥 Скидки заканчиваются через: ',
                  ),
                ),
              ],
              const SizedBox(height: 16),
              _buildPricingCard(
                productId: 'sub_1_month',
                title: monthTitle,
                price: '$monthPrice ₽',
                oldPrice: monthOldPrice != null ? '$monthOldPrice ₽' : null,
                subtitle: monthSubtitle,
                icon: Icons.flash_on_rounded,
                primaryColor: accentColor,
                badge: monthBadge,
                timer: monthTimer,
              ),
              const SizedBox(height: 12),
              _buildPricingCard(
                productId: 'sub_1_year',
                title: yearTitle,
                price: '$yearPrice ₽',
                oldPrice: yearOldPrice != null ? '$yearOldPrice ₽' : null,
                subtitle: yearSubtitle,
                icon: Icons.star_rounded,
                primaryColor: accentColor,
                badge: yearBadge,
                timer: yearTimer,
              ),
              const SizedBox(height: 12),
              _buildPricingCard(
                productId: 'lifetime_access',
                title: lifetimeTitle,
                price: '$lifetimePrice ₽',
                oldPrice:
                    lifetimeOldPrice != null ? '$lifetimeOldPrice ₽' : null,
                subtitle: lifetimeSubtitle,
                icon: Icons.all_inclusive_rounded,
                primaryColor: accentColor,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);

    final bool isThisLoading = _loadingProductId == productId;
    final bool isAnyLoading = _loadingProductId != null;

    final hasBadge = badge != null && badge.isNotEmpty;

    return _buildLiquidGlassContainer(
      context: context,
      borderRadius: 16,
      borderColor: hasBadge
          ? primaryColor.withValues(alpha: isDark ? 0.6 : 0.4)
          : null,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isAnyLoading ? null : () => _handlePayment(productId),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: isDark ? 0.2 : 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: primaryColor.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Icon(icon, color: primaryColor, size: 22),
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
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: textColor),
                          ),
                          if (hasBadge) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.redAccent.shade400,
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.redAccent.withValues(alpha: 0.3),
                                    blurRadius: 6,
                                  ),
                                ],
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
                        style: TextStyle(
                          fontSize: 12,
                          color: textColor.withValues(alpha: 0.65),
                        ),
                      ),
                      if (timer != null) ...[
                        const SizedBox(height: 6),
                        CountdownTimerWidget(
                          timerValue: timer,
                          prefix: '⏳ ',
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
                          color: textColor.withValues(alpha: 0.4),
                          decoration: TextDecoration.lineThrough,
                          decorationColor: Colors.redAccent,
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
                        shadows: isDark
                            ? [
                                Shadow(
                                  color: primaryColor.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                ),
                              ]
                            : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    isThisLoading
                        ? SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: primaryColor,
                            ),
                          )
                        : Text(
                            'Выбрать →',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: textColor.withValues(alpha: 0.5),
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

  static Duration? _networkTimeOffset;
  static DateTime? _lastSyncTime;

  Timer? _timer;
  Duration _remainingDuration = Duration.zero;
  DateTime? _targetTime;
  bool _isSyncing = true;

  @override
  void initState() {
    super.initState();
    _initTimerWithNetworkSync();
  }

  @override
  void didUpdateWidget(covariant CountdownTimerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.timerValue != widget.timerValue) {
      _timer?.cancel();
      _initTimerWithNetworkSync();
    }
  }

  Future<void> _initTimerWithNetworkSync() async {
    _targetTime = _parseTimerValue(widget.timerValue);
    if (_targetTime == null) {
      if (mounted) setState(() => _isSyncing = false);
      return;
    }

    if (_networkTimeOffset == null ||
        _lastSyncTime == null ||
        DateTime.now().difference(_lastSyncTime!) > const Duration(minutes: 5)) {
      try {
        final response = await http
            .get(Uri.parse(
                'https://timeapi.io/api/v1/time/current/zone?timeZone=UTC'))
            .timeout(const Duration(seconds: 3));

        if (response.statusCode == 200) {
          final data = json.decode(response.body) as Map<String, dynamic>;
          final String? dateTimeStr = data['dateTime'];
          if (dateTimeStr != null) {
            final networkTime = DateTime.parse(dateTimeStr).toLocal();
            _networkTimeOffset = networkTime.difference(DateTime.now());
            _lastSyncTime = DateTime.now();
          }
        }
      } catch (_) {
        _networkTimeOffset ??= Duration.zero;
      }
    }

    if (!mounted) return;

    final correctedNow =
        DateTime.now().add(_networkTimeOffset ?? Duration.zero);
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
      _relativeTargetCache[cacheKey] =
          DateTime.now().add(Duration(seconds: n.toInt()));
    }
    return _relativeTargetCache[cacheKey]!;
  }

  void _calculateRemaining() {
    if (_targetTime == null) return;
    final correctedNow =
        DateTime.now().add(_networkTimeOffset ?? Duration.zero);
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

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final timerAccent = isDark ? const Color(0xFFFF5252) : const Color(0xFFE11D48);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [
                timerAccent.withValues(alpha: isDark ? 0.2 : 0.12),
                timerAccent.withValues(alpha: isDark ? 0.08 : 0.04),
              ],
            ),
            border: Border.all(
              color: timerAccent.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.local_fire_department_rounded,
                  size: 14, color: timerAccent),
              const SizedBox(width: 4),
              Flexible(
                child: _isSyncing
                    ? SizedBox(
                        width: 10,
                        height: 10,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: timerAccent,
                        ),
                      )
                    : Text(
                        '${widget.prefix}${_formatDuration(_remainingDuration)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: widget.style ??
                            TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: timerAccent,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}