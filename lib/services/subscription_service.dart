import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../screens/payment_webview_screen.dart';

class SubscriptionService {
  // Проверка статуса подписки по готовым данным из Map
  static bool checkPremiumFromData(Map<String, dynamic>? data) {
    if (data == null) return false;

    final bool isPremium = data['isPremium'] ?? false;
    final bool isLifetime = data['isLifetime'] ?? false;
    final Timestamp? expiresAt = data['expiresAt'] as Timestamp?;

    if (isLifetime) return true;

    if (isPremium && expiresAt != null) {
      return expiresAt.toDate().isAfter(DateTime.now());
    }

    return isPremium;
  }

  // Приватный метод проверки статуса подписки через запрос к Firestore
  Future<bool> _checkPremiumStatus() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!doc.exists) return false;

      return checkPremiumFromData(doc.data());
    } catch (e) {
      debugPrint('Ошибка проверки подписки: $e');
      return false;
    }
  }

  // Для вызова через экземпляр: SubscriptionService().isDataPremiumActive()
  Future<bool> isDataPremiumActive() => _checkPremiumStatus();

  // Для статического вызова: SubscriptionService.isDataPremiumActiveStatic()
  static Future<bool> isDataPremiumActiveStatic() => SubscriptionService()._checkPremiumStatus();

  // Создание платежа
  static Future<void> createPayment(String productId, BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Пользователь не авторизован');
    }

    final idToken = await user.getIdToken();

    final response = await http.post(
      Uri.parse('https://yookassaproj201514.vercel.app/api/create-payment.js'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode({
        'productId': productId,
        'isWeb': kIsWeb,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Сервер вернул ошибку (${response.statusCode}): ${response.reasonPhrase}');
    }

    Map<String, dynamic> data;
    try {
      data = jsonDecode(response.body);
    } catch (e) {
      throw Exception('Некорректный формат ответа от сервера');
    }

    if (data['confirmationUrl'] != null) {
      final String confirmationUrl = data['confirmationUrl'];

      if (kIsWeb) {
        final url = Uri.parse(confirmationUrl);
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        } else {
          throw Exception('Не удалось открыть страницу оплаты');
        }
      } else {
        if (!context.mounted) return;
        final bool? paymentSuccess = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (context) => PaymentWebViewScreen(
              initialUrl: confirmationUrl,
              title: 'Оплата подписки',
            ),
          ),
        );

        if (paymentSuccess == true && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Платеж выполнен успешно! Обновляем статус...'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } else {
      throw Exception(data['error'] ?? 'Ошибка при создании платежа');
    }
  }

  // Отмена подписки с оформлением возврата средств
  static Future<void> cancelSubscription() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Пользователь не авторизован');
    }

    final idToken = await user.getIdToken();

    final response = await http.post(
      Uri.parse('https://yookassaproj201514.vercel.app/api/cancel-subscription.js'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
    );

    Map<String, dynamic> data;
    try {
      data = jsonDecode(response.body);
    } catch (e) {
      throw Exception('Сервер вернул ошибку (${response.statusCode}). Проверьте логи Vercel.');
    }

    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['error'] ?? 'Ошибка при отмене подписки');
    }
  }
}