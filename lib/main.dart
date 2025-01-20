import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:formulario_app/screens/splash_screen.dart';
import 'package:provider/provider.dart';
import 'package:formulario_app/providers/app_provider.dart';
import 'package:formulario_app/utils/error_handler.dart';
import 'package:formulario_app/firebase_options.dart';
import 'package:formulario_app/services/sync_service.dart';
import 'package:formulario_app/services/database_service.dart';
import 'package:formulario_app/screens/admin_pastores.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:formulario_app/services/messaging_service.dart'; // Importar el servicio

void main() async {
  await runZonedGuarded(() async {
    final dbService = DatabaseService();
    WidgetsFlutterBinding.ensureInitialized();
    await initializeDateFormatting('es');
    ErrorHandler.initialize();

    try {
      // Inicializar Firebase
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Inicializar servicios
      final syncService = SyncService();
      await syncService.initialize();
      
      // Inicializar MessagingService solo si no estamos en web
      if (!kIsWeb) {
        final messagingService = MessagingService();
        await messagingService.initialize();
      }

      runApp(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(
              create: (_) => AppProvider(),
            ),
          ],
          child: const MyApp(),
        ),
      );
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace);
      rethrow;
    }
  }, (error, stack) {
    ErrorHandler.logError(error, stack);
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Formulario Dinámico',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: kIsWeb ? Colors.grey[50] : Colors.grey[100],
      ),
      home: kIsWeb 
          ? const WebWrapper(child: SplashScreen())
          : const SplashScreen(),
      debugShowCheckedModeBanner: false,
      navigatorObservers: [ErrorHandler.routeObserver],
      builder: (context, child) {
        return ErrorHandler.buildErrorScreen(
          context, 
          kIsWeb 
              ? WebWrapper(child: child ?? Container())
              : child ?? Container()
        );
      },
      routes: {
        '/splash': (context) => kIsWeb 
            ? const WebWrapper(child: SplashScreen())
            : const SplashScreen(),
        '/adminPastores': (context) => kIsWeb 
            ? const WebWrapper(child: AdminPastores())
            : const AdminPastores(),
      },
    );
  }
}

// Widget específico para la versión web
class WebWrapper extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final double minWidth;
  final EdgeInsets padding;

  const WebWrapper({
    super.key,
    required this.child,
    this.maxWidth = 1000, // Ancho estándar de tabla
    this.minWidth = 600,  // Ancho mínimo para mantener el diseño de tabla
    this.padding = const EdgeInsets.all(24),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // Fondo para toda la página web
      decoration: BoxDecoration(
        color: Colors.grey[50], // Fondo claro
        image: const DecorationImage(
          image: AssetImage('assets/images/background_pattern.png'), // Agrega tu imagen de fondo si lo deseas
          repeat: ImageRepeat.repeat,
          opacity: 0.1, // Ajusta la opacidad según necesites
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          double width = constraints.maxWidth;
          
          // Aplicar límites de ancho para mantener el estilo de tabla
          if (width > maxWidth) {
            width = maxWidth;
          } else if (width < minWidth) {
            width = minWidth;
          }

          return Center(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: width,
                minWidth: minWidth,
              ),
              padding: padding,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 5,
                    blurRadius: 15,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              margin: const EdgeInsets.symmetric(
                vertical: 32,
                horizontal: 16,
              ),
              child: child,
            ),
          );
        }
      ),
    );
  }
}

// Ejemplo de cómo usar estilos consistentes para las tablas en la versión web
class WebTableTheme {
  static const double defaultPadding = 16.0;
  
  static BoxDecoration get tableRowDecoration => BoxDecoration(
    border: Border(
      bottom: BorderSide(
        color: Colors.grey[200]!,
        width: 1,
      ),
    ),
  );
  
  static TextStyle get headerStyle => const TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 14,
    color: Colors.black87,
  );
  
  static TextStyle get cellStyle => const TextStyle(
    fontSize: 14,
    color: Colors.black54,
  );
}