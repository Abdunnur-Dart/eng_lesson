import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/settings_service.dart';

class SupportChatScreen extends StatefulWidget {
  const SupportChatScreen({super.key});

  @override
  State<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends State<SupportChatScreen> {
  static const String _supportEmail = 'anvistanb17@gmail.com';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sendEmail(context);
    });
  }

  Future<void> _sendEmail(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid ?? 'Не авторизован';
    final userEmail = user?.email ?? 'Не указан';

    final settings = SettingsService.instance;
    final isPremium = settings.isPremium;
    final streak = settings.streakCount;
    final points = settings.totalPoints;

    final String subject = 'Поддержка: Пользователь $userId';
    final String body = '''
Здравствуйте! Напишите ваше обращение ниже:



----------------------------------
Системная информация:
• User ID: $userId
• Email: $userEmail
• Premium: ${isPremium ? "Да" : "Нет"}
• Стрик: $streak дней
• Баллы: $points
----------------------------------
''';

    bool launched = false;

    // 1. Попытка открыть почтовое приложение
    final Uri mailtoUri = Uri(
      scheme: 'mailto',
      path: _supportEmail,
      queryParameters: {
        'subject': subject,
        'body': body,
      },
    );

    try {
      if (await canLaunchUrl(mailtoUri)) {
        launched = await launchUrl(mailtoUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Ошибка запуска mailto: $e');
    }

    // 2. Попытка открыть веб-версию Gmail в браузере
    if (!launched) {
      final Uri webGmailUri = Uri.parse(
        'https://mail.google.com/mail/?view=cm&fs=1&to=$_supportEmail&su=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}',
      );

      try {
        if (await canLaunchUrl(webGmailUri)) {
          launched = await launchUrl(webGmailUri, mode: LaunchMode.externalApplication);
        }
      } catch (e) {
        debugPrint('Ошибка запуска браузера: $e');
      }
    }

    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Не удалось открыть почту или браузер. Данные скопированы.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label скопирован в буфер обмена'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid ?? 'Не авторизован';
    final userEmail = user?.email ?? 'Не указан';
    final settings = SettingsService.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Служба поддержки', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              // Ограничение максимальной ширины контента для планшетов (до 560px)
              constraints: const BoxConstraints(maxWidth: 560.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.mark_email_read_rounded,
                    size: 80,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Связь с разработчиком',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Нажмите кнопку ниже, чтобы отправить письмо в службу поддержки с готовыми данными аккаунта.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
                  ),
                  const SizedBox(height: 28),

                  // Кнопка переоткрытия почты
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () => _sendEmail(context),
                    icon: const Icon(Icons.mail_outline_rounded),
                    label: const Text(
                      'Открыть почту / браузер',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Карточка информации
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.withOpacity(0.2)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text('E-mail поддержки:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                  SizedBox(height: 2),
                                  SelectableText(
                                    _supportEmail,
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy_rounded, size: 20),
                              tooltip: 'Скопировать E-mail',
                              onPressed: () => _copyToClipboard(context, _supportEmail, 'E-mail'),
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Ваш ID: $userId\nEmail: $userEmail\nPremium: ${settings.isPremium ? "Да" : "Нет"} | Баллы: ${settings.totalPoints}',
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.4),
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
  }
}