import 'dart:convert';
import 'dart:developer';

import 'package:flutter/services.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

class FCMService {
  FCMService._internal();

  static final FCMService _instance = FCMService._internal();

  factory FCMService() => _instance;

  static const String _projectId = 'pawner-mga';

  Future<String?> _getAuthToken() async {
    try {
      final String response = await rootBundle.loadString(
        'assets/firebase_credentials.json',
      );

      final credentials = ServiceAccountCredentials.fromJson(response);

      const scopes = ['https://www.googleapis.com/auth/firebase.messaging'];

      final client = await clientViaServiceAccount(credentials, scopes);

      final accessToken = client.credentials.accessToken.data;

      client.close();

      return accessToken;
    } catch (e) {
      log('Error obteniendo token OAuth2: $e');
      return null;
    }
  }

  Future<bool> enviarNotificacionFamiliar({
    required String topic,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    final accessToken = await _getAuthToken();

    if (accessToken == null) {
      log('No se pudo enviar la notificación');
      return false;
    }

    final url = Uri.parse(
      'https://fcm.googleapis.com/v1/projects/$_projectId/messages:send',
    );

    final payload = {
      "message": {
        "topic": topic,
        "notification": {"title": title, "body": body},
        "android": {
          "priority": "HIGH",
          "notification": {"channel_id": "canal_super_importante"},
        },
      },
    };

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        log('Notificación enviada');
        return true;
      }

      log('Error FCM: ${response.body}');
      return false;
    } catch (e) {
      log('Excepción FCM: $e');
      return false;
    }
  }
}
