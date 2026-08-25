import 'package:firebase_auth/firebase_auth.dart'; // NEW
import 'package:flutter/material.dart';
import '../services/settings_service.dart';
import 'auth_payment_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>( // NEW: Слушаем изменения статуса авторизации в реальном времени
      stream: FirebaseAuth.instance.authStateChanges(), // NEW
      builder: (context, authSnapshot) { // NEW
        final user = authSnapshot.data; // CHANGED: Берём актуального пользователя напрямую из Stream

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
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Тема оформления', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                  Text(
                                    isDark ? 'Темная тема включена' : 'Светлая тема включена',
                                    style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          SegmentedButton<bool>(
                            segments: const [
                              ButtonSegment(value: false, icon: Icon(Icons.light_mode, size: 18)),
                              ButtonSegment(value: true, icon: Icon(Icons.dark_mode, size: 18)),
                            ],
                            selected: {settings.isDarkMode},
                            onSelectionChanged: (Set<bool> newSelection) {
                              settings.setDarkMode(newSelection.first);
                            },
                            style: const ButtonStyle( // CHANGED
                              visualDensity: VisualDensity.compact,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      title: const Text('арабские буквы', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text('Версия 1.1.0\nПособие по обучению чтению арабского Корана'),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.teal.shade500.withAlpha(30),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.info_outline_rounded, color: Colors.teal),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      }, // NEW
    ); // NEW
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