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

// Configuración del Router
final GoRouter router = GoRouter(
  initialLocation: '/login',
  errorBuilder: (context, state) =>
      const SplashScreen(), // Página por defecto en caso de error
  routes: [
    /*GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),*/
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
Future<void> initializeFirebaseMessaging() async {
  try {
    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      final token = await messaging.getToken();
      // Store or use token as needed
      print('Firebase Messaging Token: $token');
    }
  } catch (e) {
    print('Error initializing Firebase messaging: $e');
    ErrorHandler.logError(e, StackTrace.current);
  }
}

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
      if (!kIsWeb) {
        // Only initialize messaging for mobile platforms
        await initializeFirebaseMessaging();
      }

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
