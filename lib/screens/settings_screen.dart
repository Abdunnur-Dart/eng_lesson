import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/settings_service.dart';
import 'auth_payment_screen.dart';
import 'auth_screen.dart';
import 'legal_documents_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const String _supportEmail = 'anvistanb17@gmail.com';

  // Виджет баннера уведомления / ошибки из админ-панели (в стеклянном стиле)
  Widget _buildAnnouncementBanner(SettingsService settings) {
    final data = settings.announcementData;

    if (data == null || data['isActive'] != true) {
      return const SizedBox.shrink();
    }

    final String title = data['title'] ?? '';
    final String content = data['htmlContent'] ?? data['content'] ?? '';
    final String badgeColor = data['badgeColor'] ?? 'yellow';

    final isRed = badgeColor == 'red';

    final Color backgroundColor = isRed
        ? Colors.red.shade900.withValues(alpha: 0.25)
        : Colors.amber.shade900.withValues(alpha: 0.25);

    final Color borderColor = isRed
        ? Colors.red.shade400.withValues(alpha: 0.5)
        : Colors.amber.shade400.withValues(alpha: 0.5);

    final Color iconAndTitleColor = isRed
        ? Colors.red.shade300
        : Colors.amber.shade300;

    final IconData icon = isRed
        ? Icons.error_outline_rounded
        : Icons.warning_amber_rounded;

    return Container(
      margin: const EdgeInsets.only(bottom: 20.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor, width: 1.2),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  icon,
                  color: iconAndTitleColor,
                  size: 26,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (title.isNotEmpty) ...[
                        Text(
                          title,
                          style: TextStyle(
                            color: iconAndTitleColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                      if (content.isNotEmpty)
                        Text(
                          content,
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.35,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 3-этапная логика открытия поддержки
  Future<void> _handleSupportAction(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid ?? 'Не авторизован';
    final userEmail = user?.email ?? 'Не указан';

    final settings = SettingsService.instance;
    final isPremium = settings.isPremium;
    final streak = settings.streakCount;
    final points = settings.totalPoints;

    final String subject = 'Поддержка: Пользователь $userId';
    final String systemInfo = '''
----------------------------------
Системная информация:
• User ID: $userId
• Email: $userEmail
• Premium: ${isPremium ? "Да" : "Нет"}
• Стрик: $streak дней
• Баллы: $points
----------------------------------''';

    final String fullBody = '''
Здравствуйте! Напишите ваше обращение ниже:



$systemInfo''';

    bool launched = false;

    // 1. Попытка открыть системный почтовый клиент
    final String encodedSubject = Uri.encodeComponent(subject);
    final String encodedBody = Uri.encodeComponent(fullBody);

    final Uri mailtoUri = Uri.parse(
      'mailto:$_supportEmail?subject=$encodedSubject&body=$encodedBody'
    );

    try { 
      if (await canLaunchUrl(mailtoUri)) {
        launched = await launchUrl(mailtoUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Mailto error: $e');
    }

    // 2. Попытка открыть веб-версию почты в браузере
    if (!launched) {
      final Uri webGmailUri = Uri.parse(
        'https://mail.google.com/mail/?view=cm&fs=1&to=$_supportEmail&su=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(fullBody)}',
      );

      try {
        if (await canLaunchUrl(webGmailUri)) {
          launched = await launchUrl(webGmailUri, mode: LaunchMode.externalApplication);
        }
      } catch (e) {
        debugPrint('Browser error: $e');
      }
    }

    // 3. Резервный вариант: Компактный диалог с данными
    if (!launched && context.mounted) {
      _showFallbackSupportModal(context, systemInfo);
    }
  }

  // Компактный стеклянный диалог
  void _showFallbackSupportModal(BuildContext context, String systemInfo) {
    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.white.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isDark ? Colors.white.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.9),
                      width: 1.2,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Шапка
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.teal.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.mark_email_read_rounded, color: Colors.teal, size: 22),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Служба поддержки',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                      const SizedBox(height: 14),

                      // E-mail адрес
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.teal.shade50.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.teal.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.email_outlined, color: Colors.teal, size: 18),
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
                      const SizedBox(height: 12),

                      // Карточка с информацией
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    'Данные аккаунта для решения проблемы:',
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
                                      text: 'Здравствуйте! Обращение по поводу приложения:\n\n$systemInfo',
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
            ),
          ),
        );
      },
    );
  }

  // Метод выхода из аккаунта
  Future<void> _signOut(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выход из аккаунта'),
        content: const Text('Вы действительно хотите выйти из своего аккаунта?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Выйти', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await FirebaseAuth.instance.signOut();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Вы успешно вышли из аккаунта')),
        );
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка выхода: $e')),
        );
      }
    }
  }

  Future<void> _deleteUserAccount(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Вы не авторизованы')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удаление аккаунта'),
        content: const Text(
          'Вы уверены, что хотите удалить аккаунт? Весь ваш учебный прогресс и премиум-доступ будут удалены без возможности восстановления.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();
      await user.delete();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Аккаунт успешно удален')),
        );
        
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/',
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Сессия устарела. Войдите заново для подтверждения удаления.'),
            ),
          );
          await FirebaseAuth.instance.signOut();
          
          if (context.mounted) {
            Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
          }
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка удаления: ${e.message}')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Произошла ошибка: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        final user = authSnapshot.data;

        return AnimatedBuilder(
          animation: SettingsService.instance,
          builder: (context, child) {
            final settings = SettingsService.instance;
            final isDark = settings.isDarkMode;

            return Scaffold(
              extendBodyBehindAppBar: true,
              appBar: PreferredSize(
                preferredSize: const Size.fromHeight(kToolbarHeight),
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: AppBar(
                      title: const Text('Настройки', style: TextStyle(fontWeight: FontWeight.bold)),
                      centerTitle: true,
                      backgroundColor: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.white.withValues(alpha: 0.4),
                      elevation: 0,
                      scrolledUnderElevation: 0,
                    ),
                  ),
                ),
              ),
              body: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? const [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF0F2942)]
                        : const [Color(0xFFE2F1E7), Color(0xFFC8E6C9), Color(0xFFE8F5E9)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                    children: [
                      // 1. БАННЕР ПРЕДУПРЕЖДЕНИЯ / ОШИБКИ ИЗ АДМИНКИ
                      _buildAnnouncementBanner(settings),

                      // 2. КАРТОЧКА ПРОФИЛЬ И ПОДПИСКА
                      _buildSectionTitle('АККАУНТ И ПОДПИСКА', context),
                      const SizedBox(height: 8),
                      _GlassCard(
                        child: Column(
                          children: [
                            ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: CircleAvatar(
                                radius: 24,
                                backgroundColor: isDark ? Colors.teal.shade900.withValues(alpha: 0.4) : Colors.teal.shade100,
                                child: Icon(
                                  user != null ? Icons.person : Icons.person_outline,
                                  color: isDark ? Colors.tealAccent : Colors.teal.shade800,
                                ),
                              ),
                              title: Text(
                                user != null ? (user.email ?? 'Авторизован') : 'Гость',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 2),
                                  Text(
                                    user != null ? 'Синхронизация данных включена' : 'Войдите для сохранения прогресса',
                                    style: TextStyle(fontSize: 12.5, color: isDark ? Colors.grey.shade300 : Colors.grey.shade700),
                                  ),
                                  if (user != null) ...[
                                    const SizedBox(height: 4),
                                    InkWell(
                                      borderRadius: BorderRadius.circular(4),
                                      onTap: () {
                                        Clipboard.setData(ClipboardData(text: user.uid));
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('ID аккаунта скопирован')),
                                        );
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Flexible(
                                              child: Text(
                                                'ID: ${user.uid}',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontFamily: 'monospace',
                                                  fontWeight: FontWeight.w500,
                                                  color: isDark ? Colors.tealAccent : Colors.teal.shade800,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Icon(
                                              Icons.copy_rounded,
                                              size: 13,
                                              color: isDark ? Colors.tealAccent : Colors.teal.shade800,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (user == null) ...[
                              Divider(height: 1, indent: 16, endIndent: 16, color: isDark ? Colors.white12 : Colors.black12),
                              ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                title: const Text('Войти в аккаунт', style: TextStyle(fontWeight: FontWeight.w600)),
                                subtitle: const Text('Авторизация и синхронизация прогресса'),
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.teal.shade500.withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.login_rounded, color: Colors.teal),
                                ),
                                trailing: const Icon(Icons.chevron_right_rounded, size: 22),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const AuthScreen(),
                                    ),
                                  );
                                },
                              ),
                              Divider(height: 1, indent: 16, endIndent: 16, color: isDark ? Colors.white12 : Colors.black12),
                              ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                title: const Text('Управление подпиской', style: TextStyle(fontWeight: FontWeight.w600)),
                                subtitle: const Text('Статус аккаунта и продление'),
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade500.withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.star_rounded, color: Colors.amber),
                                ),
                                trailing: const Icon(Icons.chevron_right_rounded, size: 22),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const AuthPaymentScreen(),
                                    ),
                                  );
                                },
                              ),
                            ],
                            if (user != null) ...[
                              Divider(height: 1, indent: 16, endIndent: 16, color: isDark ? Colors.white12 : Colors.black12),
                              ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                title: const Text('Управление подпиской', style: TextStyle(fontWeight: FontWeight.w600)),
                                subtitle: const Text('Статус аккаунта и продление'),
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade500.withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.star_rounded, color: Colors.amber),
                                ),
                                trailing: const Icon(Icons.chevron_right_rounded, size: 22),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const AuthPaymentScreen(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // 3. СЕКЦИЯ ВНЕШНЕГО ВИДА
                      _buildSectionTitle('ВНЕШНИЙ ВИД', context),
                      const SizedBox(height: 8),
                      _GlassCard(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isDark 
                                          ? Colors.purple.shade500.withValues(alpha: 0.25) 
                                          : Colors.orange.shade500.withValues(alpha: 0.25),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                                      color: isDark ? Colors.purpleAccent : Colors.orange.shade800,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Тема оформления', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                        Text(
                                          isDark ? 'Темная тема включена' : 'Светлая тема включена',
                                          style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: SegmentedButton<bool>(
                                  segments: const [
                                    ButtonSegment(
                                      value: false, 
                                      label: Text('Светлая'),
                                      icon: Icon(Icons.light_mode, size: 18),
                                    ),
                                    ButtonSegment(
                                      value: true, 
                                      label: Text('Темная'),
                                      icon: Icon(Icons.dark_mode, size: 18),
                                    ),
                                  ],
                                  selected: {settings.isDarkMode},
                                  onSelectionChanged: (Set<bool> newSelection) {
                                    settings.setDarkMode(newSelection.first);
                                  },
                                  style: ButtonStyle( 
                                    visualDensity: VisualDensity.compact,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    backgroundColor: WidgetStateProperty.resolveWith((states) {
                                      if (states.contains(WidgetState.selected)) {
                                        return isDark 
                                            ? Colors.teal.shade700.withValues(alpha: 0.6) 
                                            : Colors.teal.shade400.withValues(alpha: 0.5);
                                      }
                                      return Colors.transparent;
                                    }),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // 4. СЕКЦИЯ "О ПРИЛОЖЕНИИ"
                      _buildSectionTitle('О ПРИЛОЖЕНИИ', context),
                      const SizedBox(height: 8),
                      _GlassCard(
                        child: Column(
                          children: [
                            const ListTile(
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              title: Text('Арабские буквы', style: TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('Версия 1.1.0\nПособие по обучению чтению арабского Корана'),
                              leading: CircleAvatar(
                                backgroundColor: Colors.transparent,
                                child: Icon(Icons.info_outline_rounded, color: Colors.teal),
                              ),
                            ),
                            Divider(height: 1, indent: 16, endIndent: 16, color: isDark ? Colors.white12 : Colors.black12),
                            ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              title: const Text('Правовые документы', style: TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: const Text('Политика конфиденциальности и условия'),
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.teal.shade500.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.article_outlined, color: Colors.teal),
                              ),
                              trailing: const Icon(Icons.chevron_right_rounded, size: 22),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const LegalDocumentsScreen(),
                                  ),
                                );
                              },
                            ),
                            Divider(height: 1, indent: 16, endIndent: 16, color: isDark ? Colors.white12 : Colors.black12),
                            ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              title: const Text('Служба поддержки', style: TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: const Text('Написать разработчику'),
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade500.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.support_agent_rounded, color: Colors.blue),
                              ),
                              trailing: const Icon(Icons.chevron_right_rounded, size: 22),
                              onTap: () => _handleSupportAction(context),
                            ),
                            if (user != null) ...[
                              Divider(height: 1, indent: 16, endIndent: 16, color: isDark ? Colors.white12 : Colors.black12),
                              ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                title: const Text('Выйти из аккаунта', style: TextStyle(fontWeight: FontWeight.w600)),
                                subtitle: const Text('Завершить текущую сессию'),
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade500.withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.logout_rounded, color: Colors.orange),
                                ),
                                trailing: const Icon(Icons.chevron_right_rounded, size: 22),
                                onTap: () => _signOut(context),
                              ),
                              Divider(height: 1, indent: 16, endIndent: 16, color: isDark ? Colors.white12 : Colors.black12),
                              ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                title: const Text('Удалить аккаунт', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.red)),
                                subtitle: const Text('Безвозвратное удаление профиля и данных'),
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade500.withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.delete_forever_rounded, color: Colors.red),
                                ),
                                trailing: const Icon(Icons.chevron_right_rounded, size: 22, color: Colors.red),
                                onTap: () => _deleteUserAccount(context),
                              ),
                            ],
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
      },
    );
  }

  Widget _buildSectionTitle(String title, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.tealAccent : Colors.teal.shade900,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

// Кастомный Glassmorphism контейнер
class _GlassCard extends StatelessWidget {
  final Widget child;

  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.0),
            gradient: LinearGradient(
              colors: isDark
                  ? [Colors.white.withValues(alpha: 0.1), Colors.white.withValues(alpha: 0.03)]
                  : [Colors.white.withValues(alpha: 0.75), Colors.white.withValues(alpha: 0.35)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.8),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.25)
                    : Colors.teal.shade900.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}