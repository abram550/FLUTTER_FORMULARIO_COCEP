import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:formulario_app/screens/ministerio_lider_screen.dart';
import 'package:formulario_app/screens/splash_screen.dart';
import 'package:provider/provider.dart';
import 'package:formulario_app/providers/app_provider.dart';
import 'package:formulario_app/utils/error_handler.dart';
import 'package:formulario_app/firebase_options.dart';
import 'package:formulario_app/services/sync_service.dart';
import 'package:formulario_app/services/database_service.dart';
import 'package:formulario_app/services/auth_service.dart'; // 🆕 AGREGAR ESTA LÍNEA
import 'package:formulario_app/screens/admin_pastores.dart';
import 'package:formulario_app/screens/login_screen.dart';
import 'package:formulario_app/screens/social_profile_screen.dart';
import 'package:formulario_app/screens/TimoteosScreen.dart';
import 'package:formulario_app/screens/form_screen.dart';
import 'package:formulario_app/screens/CoordinadorScreen.dart';
import 'package:formulario_app/screens/admin_screen.dart';
import 'package:formulario_app/screens/TribusScreen.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// =============================================================================
// 🆕 NUEVA CLASE: Servicio de Limpieza Automática de Eventos
// Colócala DESPUÉS de los imports y ANTES de la clase AppColors
// =============================================================================

/// Servicio para gestionar la eliminación automática de eventos vencidos
class ServicioLimpiezaEventos {
  static Timer? _timer;

  /// Inicializa la limpieza automática de eventos
  /// Se ejecuta cada 24 horas y una vez al iniciar la aplicación
  static void iniciarLimpiezaAutomatica() {
    try {
      print('🚀 Iniciando servicio de limpieza automática de eventos...');

      // Ejecutar limpieza inmediatamente al iniciar
      _ejecutarLimpieza();

      // Programar limpieza cada 24 horas
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

  /// Detiene el servicio de limpieza automática
  static void detenerLimpiezaAutomatica() {
    _timer?.cancel();
    _timer = null;
    print('🛑 Servicio de limpieza automática detenido');
  }

  /// Ejecuta la limpieza de eventos vencidos
  static Future<void> _ejecutarLimpieza() async {
    try {
      await eliminarEventosVencidos();
    } catch (e) {
      print('❌ Error en limpieza automática: $e');
      ErrorHandler.logError(e, StackTrace.current);
    }
  }

  /// Elimina todos los eventos que ya cumplieron su fecha de eliminación automática
  /// Esta función busca eventos con 'fechaEliminacionAutomatica' vencida
  static Future<void> eliminarEventosVencidos() async {
    try {
      final ahora = DateTime.now();

      print('🧹 Iniciando limpieza de eventos vencidos...');
      print('📅 Fecha actual: ${ahora.toString()}');

      // Buscar eventos cuya fecha de eliminación automática ya pasó
      final querySnapshot = await FirebaseFirestore.instance
          .collection('eventos')
          .where('fechaEliminacionAutomatica',
              isLessThan: Timestamp.fromDate(ahora))
          .get();

      print(
          '📋 Encontrados ${querySnapshot.docs.length} eventos para eliminar');

      // Si no hay eventos para eliminar, terminar
      if (querySnapshot.docs.isEmpty) {
        print('✅ No hay eventos vencidos para eliminar');
        return;
      }

      // Preparar eliminación en lotes para mejor rendimiento
      WriteBatch batch = FirebaseFirestore.instance.batch();
      int contador = 0;
      List<String> nombresEliminados = [];

      // Procesar cada evento a eliminar
      for (var doc in querySnapshot.docs) {
        // Agregar operación de eliminación al batch
        batch.delete(doc.reference);
        contador++;

        // Guardar nombre del evento para el log
        final data = doc.data() as Map<String, dynamic>;
        final nombreEvento = data['nombre'] ?? 'Sin nombre';
        final fechaEliminacion =
            data['fechaEliminacionAutomatica'] as Timestamp?;

        nombresEliminados.add(nombreEvento);
        print(
            '🗑️ Programado para eliminar: $nombreEvento (vencido: ${fechaEliminacion?.toDate()})');

        // Firebase permite máximo 500 operaciones por batch
        if (contador >= 500) {
          await batch.commit();
          batch = FirebaseFirestore.instance.batch();
          contador = 0;
          print('📦 Ejecutado lote de 500 eliminaciones');
        }
      }

      // Ejecutar el último batch si tiene operaciones pendientes
      if (contador > 0) {
        await batch.commit();
        print('📦 Ejecutado lote final de $contador eliminaciones');
      }

      // Mostrar resumen de eliminaciones
      print(
          '✅ LIMPIEZA COMPLETADA - Eliminados ${querySnapshot.docs.length} eventos vencidos:');
      for (int i = 0; i < nombresEliminados.length; i++) {
        print('   ${i + 1}. ${nombresEliminados[i]}');
      }
    } catch (e) {
      print('❌ Error al eliminar eventos vencidos: $e');
      ErrorHandler.logError(e, StackTrace.current);
      rethrow; // Re-lanzar para que el error se maneje en el nivel superior
    }
  }

  /// Función auxiliar para verificar si un evento específico debe eliminarse
  /// Útil para mostrar información en la UI
  static bool debeEliminarseEvento(DateTime fechaFinEvento) {
    final ahora = DateTime.now();
    final fechaLimite = DateTime(ahora.year - 1, ahora.month, ahora.day);
    return fechaFinEvento.isBefore(fechaLimite);
  }

  /// Calcula los días restantes antes de que un evento sea eliminado
  /// Retorna 0 si ya debe eliminarse
  static int diasRestantesParaEliminacion(DateTime fechaFinEvento) {
    final ahora = DateTime.now();
    final fechaEliminacion = DateTime(
        fechaFinEvento.year + 1, fechaFinEvento.month, fechaFinEvento.day);

    if (fechaEliminacion.isBefore(ahora)) return 0;
    return fechaEliminacion.difference(ahora).inDays;
  }
}

// Tu clase AppColors existente (sin cambios)
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
// 🔄 CONFIGURACIÓN DE RUTAS CON AUTENTICACIÓN PERSISTENTE
// =============================================================================

final GoRouter router = GoRouter(
  initialLocation: '/login', // 🎯 Ruta principal: siempre inicia en login
  errorBuilder: (context, state) => const SplashScreen(),

  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/social_profile',
      builder: (context, state) => const SocialProfileScreen(),
    ),
    GoRoute(
      path: '/timoteos/:timoteoId/:timoteoNombre',
      builder: (context, state) {
        final timoteoId = state.pathParameters['timoteoId']!;
        final timoteoNombre = state.pathParameters['timoteoNombre']!;
        return TimoteoScreen(
          timoteoId: timoteoId,
          timoteoNombre: timoteoNombre,
        );
      },
    ),
    GoRoute(
      path: '/form',
      builder: (context, state) => const FormularioPage(),
    ),
    GoRoute(
      path: '/coordinador/:coordinadorId/:coordinadorNombre',
      builder: (context, state) {
        final coordinadorId = state.pathParameters['coordinadorId']!;
        final coordinadorNombre = state.pathParameters['coordinadorNombre']!;
        return CoordinadorScreen(
          coordinadorId: coordinadorId,
          coordinadorNombre: coordinadorNombre,
        );
      },
    ),
    GoRoute(
      path: '/admin_pastores',
      builder: (context, state) => const AdminPastores(),
    ),
    GoRoute(
      path: '/admin',
      builder: (context, state) => const AdminPanel(),
    ),
    GoRoute(
      path: '/ministerio_lider',
      builder: (context, state) {
        final params = state.extra as Map<String, dynamic>;
        return MinisterioLiderScreen(ministerio: params['ministerio']);
      },
    ),
    GoRoute(
      path: '/tribus/:tribuId/:tribuNombre',
      builder: (context, state) {
        final tribuId = state.pathParameters['tribuId']!;
        final tribuNombre = state.pathParameters['tribuNombre']!;
        return TribusScreen(
          tribuId: tribuId,
          tribuNombre: tribuNombre,
        );
      },
    ),
  ],
);

// =============================================================================
// 🚫 FUNCIÓN SIN PERMISOS DE NOTIFICACIÓN - COMPLETAMENTE DESACTIVADA
// =============================================================================

Future<void> initializeFirebaseMessaging() async {
  try {
    print('ℹ️ Firebase Messaging: Notificaciones desactivadas');
    // ✅ No hacer nada - función vacía
    // Las notificaciones están completamente desactivadas
  } catch (e) {
    print('❌ Error: $e');
    ErrorHandler.logError(e, StackTrace.current);
  }
}

// =============================================================================
// 🔄 FUNCIÓN MAIN MODIFICADA - Aquí se activa la limpieza automática
// =============================================================================
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

      // ✅ CAMBIO: Inicializar messaging SIN pedir permisos
      //if (!kIsWeb) {
       // await initializeFirebaseMessaging();
       
       // print('📱 Firebase Messaging configurado (sin solicitar permisos aún)');
     // }

      final syncService = SyncService();
      await syncService.initialize();

      // 🆕 Iniciar servicio de limpieza automática de eventos
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

// Tus clases existentes (sin cambios)
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: router,
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
