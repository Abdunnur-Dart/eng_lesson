import 'package:flutter/material.dart';
import '../services/settings_service.dart';
import 'auth_payment_screen.dart'; // CHANGED

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: SettingsService.instance,
      builder: (context, child) {
        final settings = SettingsService.instance;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Настройки'),
            centerTitle: true,
          ),
          body: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // CHANGED
              const Text(
                'Аккаунт и доступ',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.teal),
              ),
              const SizedBox(height: 8),
              // CHANGED
              ListTile(
                title: const Text('Управление подпиской'),
                subtitle: const Text('Статус аккаунта и продление'),
                leading: const Icon(Icons.star, color: Colors.amber),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      // CHANGED
                      builder: (context) => const AuthPaymentScreen(),
                    ),
                  );
                },
              ),
              const Divider(),
              const Text(
                'Внешний вид',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.teal),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('Темная тема'),
                subtitle: const Text('Включить темный режим интерфейса'),
                secondary: const Icon(Icons.dark_mode_outlined),
                value: settings.isDarkMode,
                onChanged: (bool value) {
                  settings.setDarkMode(value);
                },
              ),
              const Divider(),
              const Text(
                'О программе',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.teal),
              ),
              const SizedBox(height: 8),
              const ListTile(
                title: Text('Муаллим Сани'),
                subtitle: Text('Версия 1.1.0\nПособие по обучению чтению арабского Корана'),
                leading: Icon(Icons.info_outline),
              ),
            ],
          ),
        );
      },
    );
  }
}