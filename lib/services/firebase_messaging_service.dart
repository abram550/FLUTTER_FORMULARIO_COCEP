import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class FirebaseMessagingService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  // ✅ NUEVO: Inicialización SIN solicitar permisos automáticamente
  Future<void> initialize() async {
    if (kIsWeb) {
      return; // No inicializar en web
    }

    // ❌ REMOVIDO: requestPermission() de aquí
    // Ya NO pedimos permisos automáticamente

    // ✅ Solo configuramos los listeners
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Received foreground message: ${message.notification?.title}');
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Message clicked: ${message.notification?.title}');
    });

    // ✅ Intentar obtener token SIN mostrar diálogo
    try {
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        print('FCM Token obtenido sin solicitar permisos: $token');
      }
    } catch (e) {
      print('No se pudo obtener token (permisos no concedidos): $e');
    }
  }

  // ✅ NUEVO: Método separado para solicitar permisos MANUALMENTE
  Future<bool> requestPermissions() async {
    if (kIsWeb) {
      return false;
    }

    try {
      NotificationSettings settings =
          await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false, // No usar provisional para evitar problemas
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        String? token = await _firebaseMessaging.getToken();
        print('FCM Token después de permisos: $token');
        return true;
      }

      return false;
    } catch (e) {
      print('Error al solicitar permisos: $e');
      return false;
    }
  }

  // ✅ Obtener token de forma segura
  Future<String?> getToken() async {
    if (kIsWeb) {
      return null;
    }

    try {
      return await _firebaseMessaging.getToken();
    } catch (e) {
      print('Error obteniendo token: $e');
      return null;
    }
  }

  // ✅ Verificar si ya tiene permisos sin mostrar diálogo
  Future<bool> hasPermissions() async {
    if (kIsWeb) {
      return false;
    }

    try {
      NotificationSettings settings =
          await _firebaseMessaging.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (e) {
      print('Error verificando permisos: $e');
      return false;
    }
  }

  Future<void> subscribeToTopic(String topic) async {
    if (!kIsWeb) {
      await _firebaseMessaging.subscribeToTopic(topic);
    }
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    if (!kIsWeb) {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
    }
  }
}
