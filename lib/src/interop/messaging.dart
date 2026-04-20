import 'dart:async';
import 'dart:js_interop';
import './messaging_interop.dart';

class MessagePayload {
  final JSObject jsObject;

  MessagePayload(this.jsObject);

  Map<String, dynamic>? get data {
    final raw = jsObject.dartify();
    if (raw == null) return null;
    return Map<String, dynamic>.from(raw as Map);
  }
}

class Messaging {
  final MessagingJsImpl jsObject;

  Messaging(this.jsObject);

  Future<bool> isSupported() async {
    final result = await jsObject.isSupported().toDart;
    return result.toDart;
  }

  Future<bool> deleteToken() async {
    final result = await jsObject.deleteToken().toDart;
    return result.toDart;
  }

  Future<String> getToken([dynamic options]) async {
    final result = await jsObject.getToken(options as JSAny?).toDart;
    return result.toDart;
  }
}