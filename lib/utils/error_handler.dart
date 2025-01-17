import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'package:formulario_app/screens/form_screen.dart';

class ErrorHandler {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

  static void initialize() {
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      logError(details.exception, details.stack);
    };
  }

  /// Registra errores y sus stack traces.
  /// [error] es el error ocurrido, [stackTrace] es la traza del error.
  static void logError(Object error, StackTrace? stackTrace) {
    // Implementar logging real aquí (e.g., Crashlytics, Sentry)
    debugPrint('Error: $error');
    if (stackTrace != null) {
      debugPrint('StackTrace: $stackTrace');
    }
  }

  /// Construye una pantalla de error personalizada.
  /// [context] es el contexto actual, [child] es el widget principal de la app.
  static Widget buildErrorScreen(BuildContext context, Widget? child) {
    return MaterialApp(
      builder: (BuildContext context, Widget? widget) {
        ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 60,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Ocurrió un error',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    kDebugMode
                        ? errorDetails.toString()
                        : 'Por favor, intenta nuevamente',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => const FormularioPage(),
                        ),
                      );
                    },
                    child: const Text('Reiniciar aplicación'),
                  ),
                ],
              ),
            ),
          );
        };
        return widget ?? Container();
      },
      home: child,
    );
  }
}
