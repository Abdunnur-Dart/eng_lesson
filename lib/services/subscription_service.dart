import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // NEW
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class SubscriptionService {
  // Укажи точную ссылку на эндпоинт Vercel
  static const String _vercelApiUrl = 'https://yookassaproj201514.vercel.app/api/create-payment.js';

  /// Безопасное создание платежа через сервер Vercel
  Future<String?> createOneTimePayment({
    required String userId,
    required String productId,
  }) async {
    try {
      final User? currentUser = FirebaseAuth.instance.currentUser; // NEW
      final String? idToken = await currentUser?.getIdToken(); // NEW

      final response = await http.post(
        Uri.parse(_vercelApiUrl),
        headers: {
          'Content-Type': 'application/json',
          if (idToken != null) 'Authorization': 'Bearer $idToken', // NEW - Защита токеном
        },
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

  /// Ожидание активации доступа через Firestore Stream (Webhook от бэкенда)
  Future<bool> waitForLifetimeActivation(String userId) async {
    final docRef = FirebaseFirestore.instance.collection('users').doc(userId);

    try {
      // Безопасное ожидание события от сервера (через Webhook ЮKassa -> Vercel -> Firestore)
      final snapshot = await docRef.snapshots().firstWhere(
        (snap) {
          if (!snap.exists) return false;
          final data = snap.data();
          return isDataPremiumActive(data);
        },
      ).timeout(const Duration(seconds: 30));

      return snapshot.exists && isDataPremiumActive(snapshot.data());
    } catch (e) {
      // Таймаут ожидания Webhook или ошибка сети
      debugPrint('Таймаут или ошибка ожидания обновления премиума: $e');
      return false;
    }
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