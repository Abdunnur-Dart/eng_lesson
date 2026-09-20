import 'dart:ui';
import 'package:flutter/material.dart';

class LegalDocumentsScreen extends StatelessWidget {
  const LegalDocumentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        extendBodyBehindAppBar: true,
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
            child: Column(
              children: [
                // Glassmorphic Header + TabBar
                ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.white.withValues(alpha: 0.4),
                        border: Border(
                          bottom: BorderSide(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.12)
                                : Colors.white.withValues(alpha: 0.8),
                            width: 1.0,
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          AppBar(
                            title: const Text(
                              'Правовые документы',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            centerTitle: true,
                            backgroundColor: Colors.transparent,
                            elevation: 0,
                            scrolledUnderElevation: 0,
                          ),
                          TabBar(
                            isScrollable: true,
                            tabAlignment: TabAlignment.start,
                            indicatorSize: TabBarIndicatorSize.label,
                            indicator: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: isDark
                                  ? const Color(0xFF10B981).withValues(alpha: 0.3)
                                  : Colors.teal.shade700.withValues(alpha: 0.15),
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF34D399).withValues(alpha: 0.5)
                                    : Colors.teal.shade600.withValues(alpha: 0.5),
                                width: 1.2,
                              ),
                            ),
                            labelColor: isDark ? const Color(0xFF34D399) : Colors.teal.shade900,
                            unselectedLabelColor: isDark ? Colors.white60 : Colors.black54,
                            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                            padding: const EdgeInsets.only(bottom: 10, left: 12, right: 12),
                            indicatorPadding: const EdgeInsets.symmetric(horizontal: -10, vertical: 2),
                            tabs: const [
                              Tab(text: 'Конфиденциальность'),
                              Tab(text: 'Условия использования'),
                              Tab(text: 'Персональные данные'),
                              Tab(text: 'Возврат средств'),
                              Tab(text: 'Подписки'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Tab Content View
                const Expanded(
                  child: TabBarView(
                    children: [
                      _GlassDocumentContainer(child: PrivacyPolicyContent()),
                      _GlassDocumentContainer(child: TermsOfUseContent()),
                      _GlassDocumentContainer(child: PersonalDataConsentContent()),
                      _GlassDocumentContainer(child: RefundPolicyContent()),
                      _GlassDocumentContainer(child: SubscriptionTermsContent()),
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
}

// Обертка для контента в стиле Glassmorphism
class _GlassDocumentContainer extends StatelessWidget {
  final Widget child;

  const _GlassDocumentContainer({required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24.0),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.all(22.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24.0),
              gradient: LinearGradient(
                colors: isDark
                    ? [Colors.white.withValues(alpha: 0.12), Colors.white.withValues(alpha: 0.04)]
                    : [Colors.white.withValues(alpha: 0.75), Colors.white.withValues(alpha: 0.35)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.9),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.25)
                      : Colors.teal.shade900.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: child,
          ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF0F5132);
    final subtextColor = isDark ? Colors.white54 : Colors.teal.shade800.withValues(alpha: 0.7);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Политика конфиденциальности',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
        ),
        const SizedBox(height: 6),
        Text(
          'Дата вступления в силу: 25 августа 2026 г.',
          style: TextStyle(fontSize: 12, color: subtextColor, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 16),
        Text(
          '1. Сбор и использование информации\n'
          'Для обеспечения работы Приложения, синхронизации прогресса обучения и обработки платежей мы собираем следующие данные:\n'
          '• Учетные данные: адрес электронной почты (Email) при регистрации или входе через Firebase Authentication.\n'
          '• Данные об использовании и прогрессе: информация о прохождении уроков, результаты тестов, настройки приложения.\n'
          '• Аналитические данные: обезличенная статистика взаимодействия с интерфейсом через Firebase Analytics.\n'
          '• Платежные данные: при совершении покупок обработка платежа производится через платежный шлюз (ЮKassa). Мы не сохраняем данные банковских карт.',
          style: TextStyle(fontSize: 14, height: 1.5, color: textColor),
        ),
        const SizedBox(height: 16),
        Text(
          '2. Цели обработки данных\n'
          'Собранные данные используются исключительно для предоставления доступа к функционалу, синхронизации учебного прогресса, обработки платежей и улучшения работы приложения.',
          style: TextStyle(fontSize: 14, height: 1.5, color: textColor),
        ),
        const SizedBox(height: 16),
        Text(
          '3. Защита данных\n'
          'Мы принимаем необходимые технические и организационные меры для защиты вашей информации от несанкционированного доступа с использованием протоколов безопасности Google Firebase.',
          style: TextStyle(fontSize: 14, height: 1.5, color: textColor),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF0F5132);
    final subtextColor = isDark ? Colors.white54 : Colors.teal.shade800.withValues(alpha: 0.7);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Пользовательское соглашение',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
        ),
        const SizedBox(height: 6),
        Text(
          'Дата вступления в силу: 25 августа 2026 г.',
          style: TextStyle(fontSize: 12, color: subtextColor, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 16),
        Text(
          '1. Общие положения\n'
          '1.1. Приложение предназначено для образовательного изучения арабского алфавита и чтения Корана.\n'
          '1.2. Использование базового функционала является бесплатным. Часть материалов доступна в рамках приобретения «Премиум-доступа».',
          style: TextStyle(fontSize: 14, height: 1.5, color: textColor),
        ),
        const SizedBox(height: 16),
        Text(
          '2. Регистрация и аккаунт\n'
          '2.1. Для сохранения прогресса и синхронизации данных пользователь может создать учетную запись с использованием действующего Email.',
          style: TextStyle(fontSize: 14, height: 1.5, color: textColor),
        ),
        const SizedBox(height: 16),
        Text(
          '3. Оплата и Премиум-доступ\n'
          '3.1. Приобретение «Премиум-доступа навсегда» осуществляется на разовой основе через платежный шлюз.\n'
          '3.2. После подтверждения успешной оплаты статус премиум-аккаунта активируется автоматически.',
          style: TextStyle(fontSize: 14, height: 1.5, color: textColor),
        ),
        const SizedBox(height: 16),
        Text(
          '4. Ограничение ответственности\n'
          'Приложение предоставляется по принципу «как есть». Разработчик не несет ответственности за сбои в работе сторонних сервисов (Firebase, платежные шлюзы).',
          style: TextStyle(fontSize: 14, height: 1.5, color: textColor),
        ),
      ],
    );
  }
}

// 3. Согласие на обработку персональных данных (ФЗ-152)
class PersonalDataConsentContent extends StatelessWidget {
  const PersonalDataConsentContent({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF0F5132);
    final subtextColor = isDark ? Colors.white54 : Colors.teal.shade800.withValues(alpha: 0.7);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Согласие на обработку персональных данных',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
        ),
        const SizedBox(height: 6),
        Text(
          'Дата вступления в силу: 25 августа 2026 г.',
          style: TextStyle(fontSize: 12, color: subtextColor, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 16),
        Text(
          'Настоящим в соответствии с действующим законодательством я свободно, своей волей и в своем интересе выражаю безусловное согласие на обработку моих персональных данных (адрес электронной почты, технические идентификаторы устройств, данные об учебном прогрессе), предоставляемых при использовании мобильного приложения «Арабские буквы».\n\n'
          'Цели обработки персональных данных:\n'
          '• Регистрация и аутентификация в системе.\n'
          '• Синхронизация прогресса обучения между устройствами пользователя через облачное хранилище.\n\n'
          'Обработка данных может осуществляться с использованием средств автоматизации (включая инфраструктуру Google Firebase / Cloud Firestore). Настоящее согласие действует до момента удаления учетной записи пользователем через настройки или обращения в службу поддержки.',
          style: TextStyle(fontSize: 14, height: 1.5, color: textColor),
        ),
      ],
    );
  }
}

// 4. Политика возврата средств (Refund Policy)
class RefundPolicyContent extends StatelessWidget {
  const RefundPolicyContent({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF0F5132);
    final subtextColor = isDark ? Colors.white54 : Colors.teal.shade800.withValues(alpha: 0.7);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Политика возврата средств',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
        ),
        const SizedBox(height: 6),
        Text(
          'Дата вступления в силу: 25 августа 2026 г.',
          style: TextStyle(fontSize: 12, color: subtextColor, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 16),
        Text(
          '1. Общие положения\n'
          'Приобретение пожизненного Премиум-доступа в приложении носит характер цифровой покупки (цифрового контента).\n\n'
          '2. Условия возврата\n'
          '• Возврат средств возможен в случае, если оплата была списана ошибочно дважды за одну транзакцию по технической ошибке платежного шлюза.\n'
          '• В случае возникновения проблем с активацией премиум-доступа (если доступ не активировался автоматически в течение часа после успешной оплаты через вебхук), пользователь имеет право обратиться по email: anvistanb17@gmail.com .\n\n'
          '3. Порядок запроса возврата\n'
          'Для рассмотрения запроса на возврат или исправление статуса покупки напишите нам на электронную почту разработчика, указав ваш Email, привязанный к аккаунту, и детали платежа.',
          style: TextStyle(fontSize: 14, height: 1.5, color: textColor),
        ),
      ],
    );
  }
}

// 5. Условия подписок и автопродления
class SubscriptionTermsContent extends StatelessWidget {
  const SubscriptionTermsContent({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF0F5132);
    final subtextColor = isDark ? Colors.white54 : Colors.teal.shade800.withValues(alpha: 0.7);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Условия подписок и платежей',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
        ),
        const SizedBox(height: 6),
        Text(
          'Дата вступления в силу: 25 августа 2026 г.',
          style: TextStyle(fontSize: 12, color: subtextColor, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 16),
        Text(
          '1. Разовые покупки\n'
          'В приложении доступна покупка постоянного (бессрочного) доступа к полному функционалу курса («Премиум навсегда»).\n\n'
          '2. Безопасность платежей\n'
          'Все операции по банковским картам проводятся через защищенные протоколы платежных систем и партнеров (ЮKassa / Vercel эндпоинты). Реквизиты карт не хранятся на серверах приложения.',
          style: TextStyle(fontSize: 14, height: 1.5, color: textColor),
        ),
      ],
    );
  }
}