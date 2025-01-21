// En lib/src/interop/messaging.dart

import 'dart:async';
import 'package:js/js_util.dart' as js_util;
import './messaging_interop.dart';

class MessagePayload {
  final dynamic jsObject;

  MessagePayload(this.jsObject);

  Map<String, dynamic>? get data => 
    jsObject.data != null ? dartify(jsObject.data) : null;

  static dynamic dartify(dynamic jsObject) {
    if (jsObject == null) return null;
    
    // Convertir objeto JS a Dart usando js_util
    return js_util.dartify(jsObject);
  }
}

class Messaging {
  final MessagingJsImpl jsObject;

  Messaging(this.jsObject);

  Future<T> handleThenable<T>(PromiseJsImpl<T> promise) {
    return js_util.promiseToFuture(promise);
  }

  Future<bool> isSupported() {
    return handleThenable(jsObject.isSupported());
  }

  Future<bool> deleteToken() {
    return handleThenable(jsObject.deleteToken());
  }

  Future<String> getToken([dynamic options]) {
    return handleThenable(jsObject.getToken(options));
  }
}