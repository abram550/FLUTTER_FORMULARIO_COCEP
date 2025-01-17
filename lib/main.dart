import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:formulario_app/screens/splash_screen.dart';
import 'package:provider/provider.dart';
import 'package:formulario_app/providers/app_provider.dart';
import 'package:formulario_app/utils/error_handler.dart';
import 'package:formulario_app/firebase_options.dart';
import 'package:formulario_app/services/sync_service.dart'; // Importa tu SyncService
import 'package:formulario_app/services/database_service.dart'; // Importa DatabaseService
import 'package:formulario_app/screens/admin_pastores.dart';



//await Firebase.initializeApp(
   // options: DefaultFirebaseOptions.currentPlatform,
void main() async {
  await runZonedGuarded(() async {
    final dbService = DatabaseService();
    WidgetsFlutterBinding.ensureInitialized();

    // Configurar error handling global
    ErrorHandler.initialize();

    try {
      // Inicializa Firebase
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Resetear la base de datos (solo en desarrollo)
      final dbService = DatabaseService();

      // Inicializa el SyncService
      final syncService = SyncService();
      await syncService.initialize();

      // Ejecuta la app
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
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      home: const SplashScreen(), // Pantalla de inicio
      debugShowCheckedModeBanner: false,
      navigatorObservers: [ErrorHandler.routeObserver],
      builder: (context, child) {
        return ErrorHandler.buildErrorScreen(context, child);
      },
      routes: {
        '/adminPastores': (context) => const AdminPastores(),
        // Aquí puedes agregar más rutas según sea necesario.
        '/splash': (context) => const SplashScreen(),
        // Agrega otras rutas a tus pantallas, si es necesario.
      },
    );
  }
}
