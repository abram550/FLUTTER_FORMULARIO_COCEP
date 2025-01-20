// Archivo: lib/services/messaging_service.dart

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:firebase_core/firebase_core.dart';
export 'package:firebase_core/firebase_core.dart';

class MessagingService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  // Singleton pattern
  static final MessagingService _instance = MessagingService._internal();
  
  factory MessagingService() {
    return _instance;
  }
  
  MessagingService._internal();

  Future<void> initialize() async {
    if (!kIsWeb) {
      // Configurar notificaciones locales
      await _initializeLocalNotifications();
      
      // Solicitar permisos
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      
      print('User granted permission: ${settings.authorizationStatus}');
      
      // Obtener token FCM
      String? token = await _firebaseMessaging.getToken();
      print('FCM Token: $token');
      
      // Configurar handlers de mensajes
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      
      // Verificar si la app fue abierta desde una notificación
      RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        _handleInitialMessage(initialMessage);
      }
    }
  }
  
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
        
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        // Manejar la interacción con la notificación
        print('Notification clicked: ${details.payload}');
      },
    );
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('Got a message whilst in the foreground!');
    print('Message data: ${message.data}');

    if (message.notification != null) {
      await _showLocalNotification(message);
    }
  }

  void _handleBackgroundMessage(RemoteMessage message) {
    print('Handling a background message: ${message.messageId}');
    // Navegar a una pantalla específica o realizar alguna acción
  }

  void _handleInitialMessage(RemoteMessage message) {
    // Manejar la notificación que abrió la app
    print('App opened from terminated state via notification');
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'This channel is used for important notifications.',
      importance: Importance.max,
      priority: Priority.high,
    );

    final NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      platformChannelSpecifics,
      payload: message.data.toString(),
    );
  }
  
  // Método para suscribirse a tópicos
  Future<void> subscribeToTopic(String topic) async {
    if (!kIsWeb) {
      await _firebaseMessaging.subscribeToTopic(topic);
    }
  }
  
  // Método para desuscribirse de tópicos
  Future<void> unsubscribeFromTopic(String topic) async {
    if (!kIsWeb) {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
    }
  }
}

// Este handler debe estar fuera de la clase y a nivel global
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling a background message: ${message.messageId}');
}