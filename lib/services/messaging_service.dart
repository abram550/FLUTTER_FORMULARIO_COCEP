/*import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'web_messaging_service.dart';

class MessagingService {
  static final MessagingService _instance = MessagingService._internal();
  factory MessagingService() => _instance;
  MessagingService._internal();

  late final WebMessagingService _webMessaging;
  late final FirebaseMessaging _messaging;

  Future<void> initialize() async {
    if (kIsWeb) {
      _webMessaging = WebMessagingService();
      await _webMessaging.requestPermission();
    } else {
      _messaging = FirebaseMessaging.instance;
      await _setupNotifications();
    }
  }

  Future<void> _setupNotifications() async {
    if (!kIsWeb) {
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      
      print('User granted permission: ${settings.authorizationStatus}');
      
      // Get FCM token
      String? token = await _messaging.getToken();
      print('FCM Token: $token');
    }
  }

  Future<String?> getToken() async {
    try {
      if (kIsWeb) {
        return await _webMessaging.getToken();
      } else {
        return await _messaging.getToken();
      }
    } catch (e) {
      print('Error getting token: $e');
      return null;
    }
  }
}*/