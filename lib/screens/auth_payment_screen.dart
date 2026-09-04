import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import '../services/subscription_service.dart';
import '../services/settings_service.dart';
import 'dart:convert';

class AuthPaymentScreen extends StatefulWidget {
  const AuthPaymentScreen({Key? key}) : super(key: key);

  @override
  State<AuthPaymentScreen> createState() => _AuthPaymentScreenState();
}

class _AuthPaymentScreenState extends State<AuthPaymentScreen> {
  static const String _supportEmail = 'anvistanb17@gmail.com';
  String? _loadingProductId;

  Future<void> _handlePayment(String productId) async {
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

  // 1. Сначала показываем предупреждение о возврате
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
              Navigator.pop(context); // Закрываем предупреждение
              _showSupportModal();    // Открываем экран поддержки с данными
            },
            child: const Text('Продолжить'),
          ),
        ],
      ),
    );
  }

  // 2. Экран поддержки (модальное окно) с системной информацией
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
                  // Шапка
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

                  // E-mail адрес
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.withOpacity(0.2)),
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

                  // Карточка с информацией
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.withOpacity(0.2)),
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

  Future<Map<String, dynamic>> _fetchRemoteTariffs() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('config')
          .doc('tariffs')
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        final String jsonString = data['json_data'] ?? '{}';
        
        final decodedData = json.decode(jsonString);
        if (decodedData is Map<String, dynamic>) {
          return decodedData;
        }
      }
    } catch (e) {
      print('FIRESTORE FETCH ERROR: $e');
    }
    return {};
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Авторизация')),
        body: const Center(child: Text('Пожалуйста, войдите в аккаунт')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('⭐', style: TextStyle(fontSize: 16)),
            SizedBox(width: 8),
            Text('Премиум доступ 🏅', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(width: 8),
            Text('⭐', style: TextStyle(fontSize: 16)),
          ],
        ),
        centerTitle: true,
        elevation: 0,
        toolbarHeight: 46,
      ),
      body: StreamBuilder<DocumentSnapshot>(
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

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Данные пользователя не найдены.'));
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>?;
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
            
            // Кнопка отмены, которая теперь вызывает предварительное предупреждение
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
    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchRemoteTariffs(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final remoteData = snapshot.data ?? {};

        final monthData = remoteData['sub_1_month'] as Map<String, dynamic>?;
        final yearData = remoteData['sub_1_year'] as Map<String, dynamic>?;
        final lifetimeData = remoteData['lifetime_access'] as Map<String, dynamic>?;

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
                children: const [
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
  }) {
    final bool isThisLoading = _loadingProductId == productId;
    final bool isAnyLoading = _loadingProductId != null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: badge != null && badge.isNotEmpty 
              ? primaryColor.withOpacity(0.5) 
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
                    color: primaryColor.withOpacity(0.1),
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