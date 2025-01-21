import 'package:js/js.dart';
import 'package:js/js_util.dart';

@JS('firebase.messaging')
external dynamic get messaging;

class WebMessagingService {
  static final WebMessagingService _instance = WebMessagingService._internal();
  factory WebMessagingService() => _instance;
  WebMessagingService._internal();

  Future<String?> getToken() async {
    try {
      final messagingInstance = messaging;
      final token = await promiseToFuture(callMethod(messagingInstance, 'getToken', []));
      return token as String?;
    } catch (e) {
      print('Error getting token: $e');
      return null;
    }
  }

  Future<void> requestPermission() async {
    try {
      final messagingInstance = messaging;
      await promiseToFuture(
        callMethod(messagingInstance, 'requestPermission', [])
      );
    } catch (e) {
      print('Error requesting permission: $e');
    }
  }
}
