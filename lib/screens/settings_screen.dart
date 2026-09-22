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

  // Базовый Liquid Glass Контейнер
  Widget _buildLiquidGlassContainer({
    required BuildContext context,
    required Widget child,
    double borderRadius = 24,
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
        ? Colors.black.withValues(alpha: 0.2)
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
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  // Виджет баннера уведомления из админ-панели
  Widget _buildAnnouncementBanner(SettingsService settings, BuildContext context) {
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
      child: _buildLiquidGlassContainer(
        context: context,
        borderRadius: 20,
        borderColor: borderColor,
        padding: const EdgeInsets.all(16.0),
        child: Container(
          color: backgroundColor,
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
    );
  }

  // Вспомогательный Liquid Glass Диалог Подтверждения
  Future<bool?> _showLiquidGlassDialog({
    required BuildContext context,
    required String title,
    required String content,
    required String confirmText,
    required VoidCallback onConfirm,
    bool isDestructive = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final primaryColor = isDark ? const Color(0xFF818CF8) : const Color(0xFF4F46E5);

    return showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: _buildLiquidGlassContainer(
          context: context,
          borderRadius: 28,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                content,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: textColor.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(
                      'Отмена',
                      style: TextStyle(
                        color: textColor.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDestructive
                          ? Colors.redAccent.withValues(alpha: 0.85)
                          : primaryColor,
                      foregroundColor: isDestructive
                          ? Colors.white
                          : Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                    ),
                    onPressed: onConfirm,
                    child: Text(
                      confirmText,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
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

    final String encodedSubject = Uri.encodeComponent(subject);
    final String encodedBody = Uri.encodeComponent(fullBody);

    final Uri mailtoUri = Uri.parse(
        'mailto:$_supportEmail?subject=$encodedSubject&body=$encodedBody');

    try {
      if (await canLaunchUrl(mailtoUri)) {
        launched = await launchUrl(mailtoUri,
            mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Mailto error: $e');
    }

    if (!launched) {
      final Uri webGmailUri = Uri.parse(
        'https://mail.google.com/mail/?view=cm&fs=1&to=$_supportEmail&su=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(fullBody)}',
      );

      try {
        if (await canLaunchUrl(webGmailUri)) {
          launched = await launchUrl(webGmailUri,
              mode: LaunchMode.externalApplication);
        }
      } catch (e) {
        debugPrint('Browser error: $e');
      }
    }

    if (!launched && context.mounted) {
      _showFallbackSupportModal(context, systemInfo);
    }
  }

  // Компактный стеклянный диалог поддержки
  void _showFallbackSupportModal(BuildContext context, String systemInfo) {
    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
        final primaryColor = isDark ? const Color(0xFF818CF8) : const Color(0xFF4F46E5);

        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: _buildLiquidGlassContainer(
              context: context,
              borderRadius: 24,
              padding: const EdgeInsets.all(20.0),
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
                          color: primaryColor.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.mark_email_read_rounded,
                            color: primaryColor, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Служба поддержки',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
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

                  // E-mail адрес
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.black.withValues(alpha: 0.2)
                          : primaryColor.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: primaryColor.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.email_outlined,
                            color: primaryColor, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SelectableText(
                            _supportEmail,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13.5,
                              color: textColor,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.copy_rounded,
                              size: 16, color: textColor.withValues(alpha: 0.7)),
                          tooltip: 'Скопировать E-mail',
                          onPressed: () {
                            Clipboard.setData(
                                const ClipboardData(text: _supportEmail));
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
                      color: isDark
                          ? Colors.black.withValues(alpha: 0.2)
                          : Colors.black.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: isDark ? Colors.white10 : Colors.black12),
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
                                  color: primaryColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            InkWell(
                              borderRadius: BorderRadius.circular(6),
                              onTap: () {
                                Clipboard.setData(ClipboardData(
                                  text:
                                      'Здравствуйте! Обращение по поводу приложения:\n\n$systemInfo',
                                ));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text('Шаблон обращения скопирован')),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                child: Row(
                                  children: [
                                    Icon(Icons.copy_rounded,
                                        size: 13, color: primaryColor),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Скопировать',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: primaryColor,
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
                            color: isDark
                                ? Colors.grey.shade300
                                : Colors.grey.shade800,
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

  // Метод изменения никнейма
  void _showEditDisplayNameDialog(BuildContext context, SettingsService settings) {
    final controller = TextEditingController(text: settings.displayName ?? '');
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final primaryColor = isDark ? const Color(0xFF818CF8) : const Color(0xFF4F46E5);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: _buildLiquidGlassContainer(
          context: context,
          borderRadius: 24,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Изменить имя профиля',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  hintText: 'Введите ваш никнейм',
                  hintStyle: TextStyle(color: textColor.withValues(alpha: 0.5)),
                  filled: true,
                  fillColor: isDark
                      ? Colors.black.withValues(alpha: 0.3)
                      : Colors.white.withValues(alpha: 0.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: textColor.withValues(alpha: 0.2)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: primaryColor, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text('Отмена', style: TextStyle(color: textColor.withValues(alpha: 0.7))),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      final name = controller.text.trim();
                      if (name.isNotEmpty) {
                        settings.setDisplayName(name);
                      }
                      Navigator.pop(ctx);
                    },
                    child: const Text('Сохранить'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Метод выхода из аккаунта
  Future<void> _signOut(BuildContext context) async {
    final confirm = await _showLiquidGlassDialog(
      context: context,
      title: 'Выход из аккаунта',
      content: 'Вы действительно хотите выйти из своего аккаунта?',
      confirmText: 'Выйти',
      isDestructive: true,
      onConfirm: () => Navigator.pop(context, true),
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

  // Метод удаления аккаунта
  Future<void> _deleteUserAccount(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Вы не авторизованы')),
      );
      return;
    }

    final confirm = await _showLiquidGlassDialog(
      context: context,
      title: 'Удаление аккаунта',
      content:
          'Вы уверены, что хотите удалить аккаунт? Весь ваш учебный прогресс и премиум-доступ будут удалены без возможности восстановления.',
      confirmText: 'Удалить',
      isDestructive: true,
      onConfirm: () => Navigator.pop(context, true),
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .delete();
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
              content: Text(
                  'Сессия устарела. Войдите заново для подтверждения удаления.'),
            ),
          );
          await FirebaseAuth.instance.signOut();

          if (context.mounted) {
            Navigator.of(context)
                .pushNamedAndRemoveUntil('/', (route) => false);
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
            final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
            final primaryColor =
                isDark ? const Color(0xFF818CF8) : const Color(0xFF4F46E5);

            return Scaffold(
              extendBodyBehindAppBar: true,
              appBar: PreferredSize(
                preferredSize: const Size.fromHeight(kToolbarHeight),
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: AppBar(
                      title: Text(
                        'Настройки',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      centerTitle: true,
                      backgroundColor: isDark
                          ? Colors.black.withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.3),
                      elevation: 0,
                      scrolledUnderElevation: 0,
                    ),
                  ),
                ),
              ),
              body: Stack(
                children: [
                  // Liquid Background Spheres
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
                  // Content ListView
                  SafeArea(
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 20.0),
                      children: [
                        // 1. БАННЕР ПРЕДУПРЕЖДЕНИЯ / ОШИБКИ
                        _buildAnnouncementBanner(settings, context),

                        // 2. КАРТОЧКА ПРОФИЛЬ И ПОДПИСКА
                        _buildSectionTitle('АККАУНТ И ПОДПИСКА', context),
                        const SizedBox(height: 8),
                        _GlassCard(
                          child: Column(
                            children: [
                              ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                leading: CircleAvatar(
                                  radius: 24,
                                  backgroundColor: primaryColor
                                      .withValues(alpha: isDark ? 0.25 : 0.15),
                                  child: Icon(
                                    user != null
                                        ? Icons.person
                                        : Icons.person_outline,
                                    color: primaryColor,
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        user != null
                                            ? (settings.displayName ?? user.email ?? 'Авторизован')
                                            : 'Гость',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: textColor,
                                        ),
                                      ),
                                    ),
                                    if (user != null)
                                      IconButton(
                                        icon: Icon(Icons.edit_outlined, size: 18, color: primaryColor),
                                        tooltip: 'Изменить имя',
                                        onPressed: () => _showEditDisplayNameDialog(context, settings),
                                      ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 2),
                                    Text(
                                      user != null
                                          ? 'Синхронизация данных включена'
                                          : 'Войдите для сохранения прогресса',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        color: textColor.withValues(alpha: 0.7),
                                      ),
                                    ),
                                    if (user != null) ...[
                                      const SizedBox(height: 4),
                                      InkWell(
                                        borderRadius: BorderRadius.circular(4),
                                        onTap: () {
                                          Clipboard.setData(
                                              ClipboardData(text: user.uid));
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                                content: Text(
                                                    'ID аккаунта скопирован')),
                                          );
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 2.0),
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
                                                    color: primaryColor,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Icon(
                                                Icons.copy_rounded,
                                                size: 13,
                                                color: primaryColor,
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
                                Divider(
                                    height: 1,
                                    indent: 16,
                                    endIndent: 16,
                                    color: textColor.withValues(alpha: 0.1)),
                                ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 4),
                                  title: Text('Войти в аккаунт',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: textColor)),
                                  subtitle: Text(
                                      'Авторизация и синхронизация прогресса',
                                      style: TextStyle(
                                          color:
                                              textColor.withValues(alpha: 0.6))),
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: primaryColor.withValues(alpha: 0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.login_rounded,
                                        color: primaryColor),
                                  ),
                                  trailing: Icon(Icons.chevron_right_rounded,
                                      size: 22,
                                      color: textColor.withValues(alpha: 0.5)),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const AuthScreen(),
                                      ),
                                    );
                                  },
                                ),
                              ],
                              Divider(
                                  height: 1,
                                  indent: 16,
                                  endIndent: 16,
                                  color: textColor.withValues(alpha: 0.1)),
                              ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 4),
                                title: Text('Управление подпиской',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: textColor)),
                                subtitle: Text(
                                    'Статус аккаунта и продление',
                                    style: TextStyle(
                                        color:
                                            textColor.withValues(alpha: 0.6))),
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade500
                                        .withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.star_rounded,
                                      color: Colors.amber),
                                ),
                                trailing: Icon(Icons.chevron_right_rounded,
                                    size: 22,
                                    color: textColor.withValues(alpha: 0.5)),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const AuthPaymentScreen(),
                                    ),
                                  );
                                },
                              ),
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
                                            ? Colors.purple.shade500
                                                .withValues(alpha: 0.25)
                                            : Colors.orange.shade500
                                                .withValues(alpha: 0.25),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        isDark
                                            ? Icons.dark_mode_rounded
                                            : Icons.light_mode_rounded,
                                        color: isDark
                                            ? Colors.purpleAccent
                                            : Colors.orange.shade800,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text('Тема оформления',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 15,
                                                  color: textColor)),
                                          Text(
                                            isDark
                                                ? 'Темная тема включена'
                                                : 'Светлая тема включена',
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: textColor
                                                    .withValues(alpha: 0.6)),
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
                                    onSelectionChanged:
                                        (Set<bool> newSelection) {
                                      settings.setDarkMode(newSelection.first);
                                    },
                                    style: ButtonStyle(
                                      visualDensity: VisualDensity.compact,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      foregroundColor:
                                          WidgetStateProperty.resolveWith(
                                              (states) {
                                        if (states
                                            .contains(WidgetState.selected)) {
                                          return isDark
                                              ? Colors.white
                                              : Colors.white;
                                        }
                                        return textColor;
                                      }),
                                      backgroundColor:
                                          WidgetStateProperty.resolveWith(
                                              (states) {
                                        if (states
                                            .contains(WidgetState.selected)) {
                                          return primaryColor;
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
                              ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                title: Text('Арабские буквы',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: textColor)),
                                subtitle: Text(
                                    'Версия 1.1.0\nПособие по обучению чтению арабского Корана',
                                    style: TextStyle(
                                        color:
                                            textColor.withValues(alpha: 0.6))),
                                leading: CircleAvatar(
                                  backgroundColor: Colors.transparent,
                                  child: Icon(Icons.info_outline_rounded,
                                      color: primaryColor),
                                ),
                              ),
                              Divider(
                                  height: 1,
                                  indent: 16,
                                  endIndent: 16,
                                  color: textColor.withValues(alpha: 0.1)),
                              ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 4),
                                title: Text('Правовые документы',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: textColor)),
                                subtitle: Text(
                                    'Политика конфиденциальности и условия',
                                    style: TextStyle(
                                        color:
                                            textColor.withValues(alpha: 0.6))),
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: primaryColor.withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.article_outlined,
                                      color: primaryColor),
                                ),
                                trailing: Icon(Icons.chevron_right_rounded,
                                    size: 22,
                                    color: textColor.withValues(alpha: 0.5)),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const LegalDocumentsScreen(),
                                    ),
                                  );
                                },
                              ),
                              Divider(
                                  height: 1,
                                  indent: 16,
                                  endIndent: 16,
                                  color: textColor.withValues(alpha: 0.1)),
                              ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 4),
                                title: Text('Служба поддержки',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: textColor)),
                                subtitle: Text('Написать разработчику',
                                    style: TextStyle(
                                        color:
                                            textColor.withValues(alpha: 0.6))),
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color:
                                        primaryColor.withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.support_agent_rounded,
                                      color: primaryColor),
                                ),
                                trailing: Icon(Icons.chevron_right_rounded,
                                    size: 22,
                                    color: textColor.withValues(alpha: 0.5)),
                                onTap: () => _handleSupportAction(context),
                              ),
                              if (user != null) ...[
                                Divider(
                                    height: 1,
                                    indent: 16,
                                    endIndent: 16,
                                    color: textColor.withValues(alpha: 0.1)),
                                ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 4),
                                  title: Text('Выйти из аккаунта',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: textColor)),
                                  subtitle: Text('Завершить текущую сессию',
                                      style: TextStyle(
                                          color:
                                              textColor.withValues(alpha: 0.6))),
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade500
                                          .withValues(alpha: 0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.logout_rounded,
                                        color: Colors.orange),
                                  ),
                                  trailing: Icon(Icons.chevron_right_rounded,
                                      size: 22,
                                      color: textColor.withValues(alpha: 0.5)),
                                  onTap: () => _signOut(context),
                                ),
                                Divider(
                                    height: 1,
                                    indent: 16,
                                    endIndent: 16,
                                    color: textColor.withValues(alpha: 0.1)),
                                ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 4),
                                  title: const Text('Удалить аккаунт',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.redAccent)),
                                  subtitle: Text(
                                      'Безвозвратное удаление профиля и данных',
                                      style: TextStyle(
                                          color:
                                              textColor.withValues(alpha: 0.6))),
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.redAccent
                                          .withValues(alpha: 0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                        Icons.delete_forever_rounded,
                                        color: Colors.redAccent),
                                  ),
                                  trailing: const Icon(
                                      Icons.chevron_right_rounded,
                                      size: 22,
                                      color: Colors.redAccent),
                                  onTap: () => _deleteUserAccount(context),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSectionTitle(String title, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? const Color(0xFF818CF8) : const Color(0xFF4F46E5);

    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: primaryColor,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

// Кастомная Glassmorphism Карточка
class _GlassCard extends StatelessWidget {
  final Widget child;

  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
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
      borderRadius: BorderRadius.circular(24.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24.0),
            gradient: LinearGradient(
              colors: defaultGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: defaultBorder,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: defaultShadow,
                blurRadius: 16,
                spreadRadius: 2,
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}