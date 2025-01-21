import 'package:js/js.dart';
import 'package:js_interop/js_interop.dart';

@JS()
@anonymous
class PromiseJsImpl<T> {
  external factory PromiseJsImpl();
}

@JS('firebase.messaging.MessagingJsImpl')
class MessagingJsImpl {
  external PromiseJsImpl<bool> deleteToken();
  external PromiseJsImpl<String> getToken(dynamic options);
  external PromiseJsImpl<bool> isSupported();
}
