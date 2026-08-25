import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class SubscriptionService {
  // Укажи точную ссылку на эндпоинт Vercel
  static const String _vercelApiUrl = 'https://yookassaproj201514.vercel.app/api/create-payment';

  /// Безопасное создание платежа через сервер Vercel
  Future<String?> createOneTimePayment({
    required String userId,
    required String productId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_vercelApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'productId': productId,
          'isWeb': kIsWeb,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['confirmationUrl'] as String?;
      } else {
        debugPrint('Ошибка сервера Vercel: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Ошибка сети/запроса: $e');
      return null;
    }
  }

  /// Проверка активности Премиума по данным из Firestore
  static bool isDataPremiumActive(Map<String, dynamic>? data) {
    if (data == null) return false;
    final bool isPremium = data['isPremium'] ?? false;
    final bool isLifetime = data['isLifetime'] == true ||
        data['isLifetime'].toString().toLowerCase() == 'true' ||
        data['subscriptionPeriod'].toString().toLowerCase() == 'lifetime';

    if (isLifetime) return true;

    final DateTime? expiresAt = getExpirationDate(data);
    if (expiresAt != null) {
      return expiresAt.isAfter(DateTime.now());
    }

    return isPremium;
  }

  /// Получение даты окончания подписки
  static DateTime? getExpirationDate(Map<String, dynamic>? data) {
    if (data == null) return null;
    final dynamic expires = data['expiresAt'] ?? data['subscriptionExpiresAt'];
    if (expires is Timestamp) {
      return expires.toDate();
    } else if (expires is String) {
      return DateTime.tryParse(expires);
    }
    return null;
  }

  /// Ожидание активации доступа через Firestore Stream (Webhook от бэкенда) // CHANGED
  Future<bool> waitForLifetimeActivation(String userId) async { // CHANGED
    final docRef = FirebaseFirestore.instance.collection('users').doc(userId); // CHANGED

    try { // NEW
      // Безопасное ожидание события от сервера (через Webhook ЮKassa -> Vercel -> Firestore) // NEW
      final snapshot = await docRef.snapshots().firstWhere( // CHANGED
        (snap) { // NEW
          if (!snap.exists) return false; // NEW
          final data = snap.data(); // NEW
          return isDataPremiumActive(data); // NEW
        }, // NEW
      ).timeout(const Duration(seconds: 30)); // NEW

      return snapshot.exists && isDataPremiumActive(snapshot.data()); // CHANGED
    } catch (e) { // NEW
      // Таймаут ожидания Webhook или ошибка сети // NEW
      debugPrint('Таймаут или ошибка ожидания обновления премиума: $e'); // NEW
      return false; // CHANGED
    } // NEW
  }

  /// Проверка статуса на сервере
  Future<void> checkIsPremiumActive(String userId) async {
    // Вспомогательный метод
  }

  /// Отмена автопродления
  Future<bool> cancelSubscription(String userId) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'autoRenew': false,
      });
      return true;
    } catch (e) {
      return false;
    }
  }
}