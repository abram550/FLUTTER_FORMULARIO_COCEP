import 'dart:js' as js;

Future<void> abrirUrl(String url) async {
  js.context.callMethod('open', [url]); // Abre el enlace en una nueva pestaña
}
