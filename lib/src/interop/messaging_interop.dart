import 'dart:js_interop';

@JS('firebase.messaging.MessagingJsImpl')
extension type MessagingJsImpl._(JSObject _) implements JSObject {
  external JSPromise<JSBoolean> deleteToken();
  external JSPromise<JSString> getToken([JSAny? options]);
  external JSPromise<JSBoolean> isSupported();
}