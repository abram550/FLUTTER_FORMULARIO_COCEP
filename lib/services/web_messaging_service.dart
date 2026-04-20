import 'dart:js_interop';
import 'package:web/web.dart' as web;

@JS('firebase.messaging')
external JSObject get messaging;

extension MessagingExtension on JSObject {
  external JSPromise getToken();
  external JSPromise requestPermission();
}

class WebMessagingService {
  static final WebMessagingService _instance = WebMessagingService._internal();
  factory WebMessagingService() => _instance;
  WebMessagingService._internal();

  Future<String?> getToken() async {
    try {
      final messagingInstance = messaging;
      final token = await messagingInstance.getToken().toDart;
      return token.dartify() as String?;
    } catch (e) {
      print('Error getting token: $e');
      return null;
    }
  }

  Future<void> requestPermission() async {
    try {
      final messagingInstance = messaging;
      await messagingInstance.requestPermission().toDart;
    } catch (e) {
      print('Error requesting permission: $e');
    }
  }
}