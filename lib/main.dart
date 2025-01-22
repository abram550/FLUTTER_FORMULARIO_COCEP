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

void main() async {
  await runZonedGuarded(() async {
    final dbService = DatabaseService();
    WidgetsFlutterBinding.ensureInitialized();
    await initializeDateFormatting('es');
    ErrorHandler.initialize();

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      final syncService = SyncService();
      await syncService.initialize();

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

  const WebWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // Fondo para toda la página web
      decoration: BoxDecoration(
        color: Colors.grey[50],
        image: const DecorationImage(
          image: AssetImage('assets/images/background_pattern.png'),
          repeat: ImageRepeat.repeat,
          opacity: 0.1,
        ),
      ),
      child: child, // Renderiza el contenido sin márgenes ni restricciones
    );
  }
}