import 'package:firebase_auth/firebase_auth.dart'; 
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/settings_service.dart';
import 'auth_payment_screen.dart';
import 'support_chat_screen.dart'; // Укажите правильный путь, если файл лежит в другой папке
import 'legal_documents_screen.dart';
// Импортируйте ваш главный экран (замените путь/имя файла на ваш, например, main_screen.dart или home_screen.dart)
// import 'main_screen.dart'; 

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  // Автоматическое открытие почты со сбором системных данных[cite: 2]

  // Безопасное удаление аккаунта и корректный выход[cite: 2]
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
      // 1. Удаляем документы пользователя из Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();

      // 2. Удаляем пользователя из Firebase Authentication
      await user.delete();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Аккаунт успешно удален')),
        );
        
        // ИСПРАВЛЕНИЕ: Вместо того чтобы кидать на строгий экран авторизации, 
        // сбрасываем на главный экран приложения (или корневой экран навигации),
        // чтобы пользователь не оказался "заперт" без стрелки назад.
        // Замените MainScreen() на ваш главный виджет приложения.
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/', // Или ваш главный роут / главный экран, например: MaterialPageRoute(builder: (_) => const MainScreen())
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
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
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
              appBar: AppBar(
                title: const Text('Настройки', style: TextStyle(fontWeight: FontWeight.bold)),
                centerTitle: true,
              ),
              body: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                children: [
                  // Секция аккаунта
                  _buildSectionTitle('АККАУНТ И ПОДПИСКА', context),
                  const SizedBox(height: 8),
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            radius: 24,
                            backgroundColor: isDark ? Colors.teal.shade900.withAlpha(100) : Colors.teal.shade50,
                            child: Icon(
                              user != null ? Icons.person : Icons.person_outline,
                              color: isDark ? Colors.tealAccent : Colors.teal.shade700,
                            ),
                          ),
                          title: Text(
                            user != null ? (user.email ?? 'Авторизован') : 'Гость',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          subtitle: Text(
                            user != null ? 'Синхронизация данных включена' : 'Войдите для сохранения прогресса',
                            style: TextStyle(fontSize: 13, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                          ),
                        ),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          title: const Text('Управление подпиской', style: TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: const Text('Статус аккаунта и продление'),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade500.withAlpha(30),
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
                    ),
                  ),

                  const SizedBox(height: 24),

// Переключатель темной темы
_buildSectionTitle('ВНЕШНИЙ ВИД', context),
const SizedBox(height: 8),
Card(
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
                    ? Colors.purple.shade500.withAlpha(30) 
                    : Colors.orange.shade500.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                color: isDark ? Colors.purpleAccent : Colors.orange,
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
            style: const ButtonStyle( 
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ),
      ],
    ),
  ),
),

                  const SizedBox(height: 24),

                  // Секция "О программе"
                  _buildSectionTitle('О ПРИЛОЖЕНИИ', context),
                  const SizedBox(height: 8),
                  Card(
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
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          title: const Text('Правовые документы', style: TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: const Text('Политика конфиденциальности и условия'),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.teal.shade500.withAlpha(30),
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
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        // Кнопка Службы поддержки с автозаполнением[cite: 2]
                        // Кнопка Службы поддержки (теперь открывает чат внутри приложения)
ListTile(
  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
  title: const Text('Служба поддержки', style: TextStyle(fontWeight: FontWeight.w600)),
  subtitle: const Text('Чат с поддержкой'),
  leading: Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: Colors.blue.shade500.withAlpha(30),
      shape: BoxShape.circle,
    ),
    child: const Icon(Icons.support_agent_rounded, color: Colors.blue),
  ),
  trailing: const Icon(Icons.chevron_right_rounded, size: 22),
  // ИСПРАВЛЕНИЕ: Вместо _openSupportEmail(context) открываем SupportChatScreen
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SupportChatScreen(),
      ),
    );
  },
),
                        if (user != null) ...[
                          const Divider(height: 1, indent: 16, endIndent: 16),
                          // Кнопка удаления аккаунта[cite: 2]
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            title: const Text('Удалить аккаунт', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.red)),
                            subtitle: const Text('Безвозвратное удаление профиля и данных'),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.red.shade500.withAlpha(30),
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
          color: isDark ? Colors.tealAccent : Colors.teal.shade800,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}