// Dart SDK
import 'dart:async';

// Flutter
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// Firebase
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:formulario_app/routes/routes.dart';

// Paquetes externos
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

// Proyecto – configuración y utils
import 'package:formulario_app/firebase_options.dart';
import 'package:formulario_app/providers/app_provider.dart';
import 'package:formulario_app/utils/error_handler.dart';
import 'package:formulario_app/utils/migrate_services.dart';

// Proyecto – servicios
import 'package:formulario_app/services/auth_service.dart';
import 'package:formulario_app/services/database_service.dart';
import 'package:formulario_app/services/sync_service.dart';



// Proyecto – screens
import 'package:formulario_app/screens/splash_screen.dart';

// =============================================================================
// SERVICIO DE LIMPIEZA AUTOMÁTICA DE EVENTOS
// =============================================================================

class ServicioLimpiezaEventos {
  static Timer? _timer;

  static void iniciarLimpiezaAutomatica() {
    try {
      print('🚀 Iniciando servicio de limpieza automática de eventos...');
      _ejecutarLimpieza();
      _timer = Timer.periodic(Duration(hours: 24), (timer) {
        print('⏰ Ejecutando limpieza programada cada 24 horas...');
        _ejecutarLimpieza();
      });
      print('✅ Servicio de limpieza automática configurado correctamente');
    } catch (e) {
      print('❌ Error al iniciar servicio de limpieza: $e');
      ErrorHandler.logError(e, StackTrace.current);
    }
  }

  static void detenerLimpiezaAutomatica() {
    _timer?.cancel();
    _timer = null;
    print('🛑 Servicio de limpieza automática detenido');
  }

  static Future<void> _ejecutarLimpieza() async {
    try {
      await eliminarEventosVencidos();
    } catch (e) {
      print('❌ Error en limpieza automática: $e');
      ErrorHandler.logError(e, StackTrace.current);
    }
  }

  static Future<void> eliminarEventosVencidos() async {
    try {
      final ahora = DateTime.now();
      print('🧹 Iniciando limpieza de eventos vencidos...');
      print('📅 Fecha actual: ${ahora.toString()}');

      final querySnapshot = await FirebaseFirestore.instance
          .collection('eventos')
          .where('fechaEliminacionAutomatica',
              isLessThan: Timestamp.fromDate(ahora))
          .get();

      print(
          '📋 Encontrados ${querySnapshot.docs.length} eventos para eliminar');

      if (querySnapshot.docs.isEmpty) {
        print('✅ No hay eventos vencidos para eliminar');
        return;
      }

      WriteBatch batch = FirebaseFirestore.instance.batch();
      int contador = 0;
      List<String> nombresEliminados = [];

      for (var doc in querySnapshot.docs) {
        batch.delete(doc.reference);
        contador++;

        final data = doc.data() as Map<String, dynamic>;
        final nombreEvento = data['nombre'] ?? 'Sin nombre';
        final fechaEliminacion =
            data['fechaEliminacionAutomatica'] as Timestamp?;

        nombresEliminados.add(nombreEvento);
        print(
            '🗑️ Programado para eliminar: $nombreEvento (vencido: ${fechaEliminacion?.toDate()})');

        if (contador >= 500) {
          await batch.commit();
          batch = FirebaseFirestore.instance.batch();
          contador = 0;
          print('📦 Ejecutado lote de 500 eliminaciones');
        }
      }

      if (contador > 0) {
        await batch.commit();
        print('📦 Ejecutado lote final de $contador eliminaciones');
      }

      print(
          '✅ LIMPIEZA COMPLETADA - Eliminados ${querySnapshot.docs.length} eventos vencidos:');
      for (int i = 0; i < nombresEliminados.length; i++) {
        print('   ${i + 1}. ${nombresEliminados[i]}');
      }
    } catch (e) {
      print('❌ Error al eliminar eventos vencidos: $e');
      ErrorHandler.logError(e, StackTrace.current);
      rethrow;
    }
  }

  static bool debeEliminarseEvento(DateTime fechaFinEvento) {
    final ahora = DateTime.now();
    final fechaLimite = DateTime(ahora.year - 1, ahora.month, ahora.day);
    return fechaFinEvento.isBefore(fechaLimite);
  }

  static int diasRestantesParaEliminacion(DateTime fechaFinEvento) {
    final ahora = DateTime.now();
    final fechaEliminacion = DateTime(
        fechaFinEvento.year + 1, fechaFinEvento.month, fechaFinEvento.day);

    if (fechaEliminacion.isBefore(ahora)) return 0;
    return fechaEliminacion.difference(ahora).inDays;
  }
}

class AppColors {
  static const Color primary = Color(0xFF1A7A8B);
  static const Color secondary = Color(0xFFFF6B35);
  static const Color background = Color(0xFFF8FDFF);
  static const Color cardBackground = Colors.white;
  static const Color textPrimary = Color(0xFF2D3B45);
  static const Color textSecondary = Color(0xFF6B7C85);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1A7A8B),
      Color(0xFF2591A5),
    ],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFF6B35),
      Color(0xFFFF8659),
    ],
  );
}

// =============================================================================
// FUNCIÓN SIN PERMISOS DE NOTIFICACIÓN
// =============================================================================

Future<void> initializeFirebaseMessaging() async {
  // Notificaciones desactivadas
}

// =============================================================================
// FUNCIÓN MAIN
// =============================================================================
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

      ServicioLimpiezaEventos.iniciarLimpiezaAutomatica();

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
    return MaterialApp.router(
      routerConfig: router, // ✅ Usando el router protegido
      title: 'Formulario Dinámico',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: AppColors.textPrimary),
          bodyMedium: TextStyle(color: AppColors.textSecondary),
        ),
        useMaterial3: true,
      ),
      builder: (context, child) {
        Widget processedChild = child ?? Container();
        if (kIsWeb) {
          processedChild = ResponsiveWrapper(child: processedChild);
        }
        return ErrorHandler.buildErrorScreen(context, processedChild);
      },
    );
  }
}

class ResponsiveWrapper extends StatelessWidget {
  final Widget child;
  final double maxMobileWidth = 600;
  final double maxWebWidth = 900;

  const ResponsiveWrapper({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < maxMobileWidth) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.primary.withOpacity(0.05),
                  AppColors.background,
                ],
              ),
            ),
            child: child,
          );
        } else {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withOpacity(0.1),
                  AppColors.background,
                  AppColors.secondary.withOpacity(0.05),
                ],
              ),
            ),
            child: Center(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: maxWebWidth,
                ),
                margin: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 16.0,
                ),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.1),
                      offset: const Offset(0, 8),
                      blurRadius: 24,
                    ),
                    BoxShadow(
                      color: AppColors.secondary.withOpacity(0.08),
                      offset: const Offset(0, -2),
                      blurRadius: 12,
                    ),
                  ],
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    children: [
                      Positioned(
                        top: -50,
                        right: -50,
                        child: Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppColors.primaryGradient,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.2),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -30,
                        left: -30,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppColors.accentGradient,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.secondary.withOpacity(0.2),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                      child,
                    ],
                  ),
                ),
              ),
            ),
          );
        }
      },
    );
  }
}

class ResponsiveHelper {
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 600;
  }

  static double getContentWidth(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 600) {
      return screenWidth;
    } else {
      return 900;
    }
  }

  static EdgeInsets getScreenPadding(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.all(16.0);
    } else {
      return const EdgeInsets.symmetric(
        horizontal: 40.0,
        vertical: 32.0,
      );
    }
  }
}