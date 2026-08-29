// CHANGED
import 'package:flutter/material.dart';

class LegalDocumentsScreen extends StatelessWidget {
  const LegalDocumentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: 5, // CHANGED: Увеличили количество вкладок до 5
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Правовые документы', style: TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: true,
          bottom: TabBar(
            isScrollable: true, // CHANGED: Разрешаем скролл вкладок, так как их стало больше
            indicatorColor: Colors.teal.shade400,
            labelColor: isDark ? Colors.tealAccent : Colors.teal.shade800,
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(text: 'Конфиденциальность'),
              Tab(text: 'Условия использования'),
              Tab(text: 'Персональные данные'), // NEW
              Tab(text: 'Возврат средств'),      // NEW
              Tab(text: 'Подписки'),            // NEW
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            SingleChildScrollView(padding: EdgeInsets.all(20.0), child: PrivacyPolicyContent()),
            SingleChildScrollView(padding: EdgeInsets.all(20.0), child: TermsOfUseContent()),
            SingleChildScrollView(padding: EdgeInsets.all(20.0), child: PersonalDataConsentContent()), // NEW
            SingleChildScrollView(padding: EdgeInsets.all(20.0), child: RefundPolicyContent()),          // NEW
            SingleChildScrollView(padding: EdgeInsets.all(20.0), child: SubscriptionTermsContent()),       // NEW
          ],
        ),
      ),
    );
  }
}

// 1. Политика конфиденциальности
class PrivacyPolicyContent extends StatelessWidget {
  const PrivacyPolicyContent({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Политика конфиденциальности', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        Text('Дата вступления в силу: 25 августа 2026 г.', style: TextStyle(fontSize: 12, color: Colors.grey)),
        SizedBox(height: 16),
        Text(
          '1. Сбор и использование информации\n'
          'Для обеспечения работы Приложения, синхронизации прогресса обучения и обработки платежей мы собираем следующие данные:\n'
          '• Учетные данные: адрес электронной почты (Email) при регистрации или входе через Firebase Authentication.\n'
          '• Данные об использовании и прогрессе: информация о прохождении уроков, результаты тестов, настройки приложения.\n'
          '• Аналитические данные: обезличенная статистика взаимодействия с интерфейсом через Firebase Analytics.\n'
          '• Платежные данные: при совершении покупок обработка платежа производится через платежный шлюз (ЮKassa). Мы не сохраняем данные банковских карт.',
          style: TextStyle(fontSize: 14, height: 1.5),
        ),
        SizedBox(height: 16),
        Text(
          '2. Цели обработки данных\n'
          'Собранные данные используются исключительно для предоставления доступа к функционалу, синхронизации учебного прогресса, обработки платежей и улучшения работы приложения.',
          style: TextStyle(fontSize: 14, height: 1.5),
        ),
        SizedBox(height: 16),
        Text(
          '3. Защита данных\n'
          'Мы принимаем необходимые технические и организационные меры для защиты вашей информации от несанкционированного доступа с использованием протоколов безопасности Google Firebase.',
          style: TextStyle(fontSize: 14, height: 1.5),
        ),
      ],
    );
  }
}

// 2. Пользовательское соглашение
class TermsOfUseContent extends StatelessWidget {
  const TermsOfUseContent({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Пользовательское соглашение', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        Text('Дата вступления в силу: 25 августа 2026 г.', style: TextStyle(fontSize: 12, color: Colors.grey)),
        SizedBox(height: 16),
        Text(
          '1. Общие положения\n'
          '1.1. Приложение предназначено для образовательного изучения арабского алфавита и чтения Корана.\n'
          '1.2. Использование базового функционала является бесплатным. Часть материалов доступна в рамках приобретения «Премиум-доступа».',
          style: TextStyle(fontSize: 14, height: 1.5),
        ),
        SizedBox(height: 16),
        Text(
          '2. Регистрация и аккаунт\n'
          '2.1. Для сохранения прогресса и синхронизации данных пользователь может создать учетную запись с использованием действующего Email.\n',
          style: TextStyle(fontSize: 14, height: 1.5),
        ),
        SizedBox(height: 16),
        Text(
          '3. Оплата и Премиум-доступ\n'
          '3.1. Приобретение «Премиум-доступа навсегда» осуществляется на разовой основе через платежный шлюз.\n'
          '3.2. После подтверждения успешной оплаты статус премиум-аккаунта активируется автоматически.',
          style: TextStyle(fontSize: 14, height: 1.5),
        ),
        SizedBox(height: 16),
        Text(
          '4. Ограничение ответственности\n'
          'Приложение предоставляется по принципу «как есть». Разработчик не несет ответственности за сбои в работе сторонних сервисов (Firebase, платежные шлюзы).',
          style: TextStyle(fontSize: 14, height: 1.5),
        ),
      ],
    );
  }
}

// NEW: 3. Согласие на обработку персональных данных (ФЗ-152)
class PersonalDataConsentContent extends StatelessWidget {
  const PersonalDataConsentContent({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Согласие на обработку персональных данных', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        Text('Дата вступления в силу: 25 августа 2026 г.', style: TextStyle(fontSize: 12, color: Colors.grey)),
        SizedBox(height: 16),
        Text(
          'Настоящим в соответствии с действующим законодательством я свободно, своей волей и в своем интересе выражаю безусловное согласие на обработку моих персональных данных (адрес электронной почты, технические идентификаторы устройств, данные об учебном прогрессе), предоставляемых при использовании мобильного приложения «Арабские буквы».\n\n'
          'Цели обработки персональных данных:\n'
          '• Регистрация и аутентификация в системе.\n'
          '• Синхронизация прогресса обучения между устройствами пользователя через облачное хранилище.\n'
          'Обработка данных может осуществляться с использованием средств автоматизации (включая инфраструктуру Google Firebase / Cloud Firestore). Настоящее согласие действует до момента удаления учетной записи пользователем через настройки или обращения в службу поддержки.',
          style: TextStyle(fontSize: 14, height: 1.5),
        ),
      ],
    );
  }
}

// NEW: 4. Политика возврата средств (Refund Policy)
class RefundPolicyContent extends StatelessWidget {
  const RefundPolicyContent({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Политика возврата средств', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        Text('Дата вступления в силу: 25 августа 2026 г.', style: TextStyle(fontSize: 12, color: Colors.grey)),
        SizedBox(height: 16),
        Text(
          '1. Общие положения\n'
          'Приобретение пожизненного Премиум-доступа в приложении носит характер цифровой покупки (цифрового контента).\n\n'
          '2. Условия возврата\n'
          '• Возврат средств возможен в случае, если оплата была списана ошибочно дважды за одну транзакцию по технической ошибке платежного шлюза.\n'
          '• В случае возникновения проблем с активацией премиум-доступа (если доступ не активировался автоматически в течение часа после успешной оплаты через вебхук), пользователь имеет право обратиться по email: anvistanb17@gmail.com .\n\n'
          '3. Порядок запроса возврата\n'
          'Для рассмотрения запроса на возврат или исправление статуса покупки напишите нам на электронную почту разработчика, указав ваш Email, привязанный к аккаунту, и детали платежа.',
          style: TextStyle(fontSize: 14, height: 1.5),
        ),
      ],
    );
  }
}

// NEW: 5. Условия подписок и автопродления
class SubscriptionTermsContent extends StatelessWidget {
  const SubscriptionTermsContent({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Условия подписок и платежей', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        Text('Дата вступления в силу: 25 августа 2026 г.', style: TextStyle(fontSize: 16, color: Colors.grey)),
        SizedBox(height: 16),
        Text(
          '1. Разовые покупки\n'
          'В приложении доступна покупка постоянного (бессрочного) доступа к полному функционалу курса («Премиум навсегда»).\n\n'
          '3. Безопасность платежей\n'
          'Все операции по банковским картам проводятся через защищенные протоколы платежных систем и партнеров (ЮKassa / Vercel эндпоинты). Реквизиты карт не хранятся на серверах приложения.',
          style: TextStyle(fontSize: 14, height: 1.5),
        ),
      ],
    );
  }
}