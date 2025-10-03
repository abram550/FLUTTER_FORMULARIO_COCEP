import 'package:flutter/material.dart';
import 'package:formulario_app/screens/ministerio_lider_screen.dart';
import 'package:formulario_app/screens/splash_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:formulario_app/screens/login_screen.dart';
import 'package:formulario_app/screens/social_profile_screen.dart';
import 'package:formulario_app/screens/TimoteosScreen.dart';
import 'package:formulario_app/screens/form_screen.dart';
import 'package:formulario_app/screens/CoordinadorScreen.dart';
import 'package:formulario_app/screens/admin_pastores.dart';
import 'package:formulario_app/screens/admin_screen.dart';
import 'package:formulario_app/screens/TribusScreen.dart';

// Estado de autenticación global
final authState = ValueNotifier<bool>(false);

final GoRouter router = GoRouter(
  refreshListenable: authState,
  errorBuilder: (context, state) => const SplashScreen(),
  // ✅ SIN initialLocation - esto permite que los deep links funcionen
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
        final params = (state.extra ?? {}) as Map<String, dynamic>;
        return MinisterioLiderScreen(
          ministerio: params['ministerio'] ?? '',
        );
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
  redirect: (context, state) {
    final loggedIn = authState.value;
    final loggingIn = state.matchedLocation == '/login';

    // Si no está logueado y no está en login, redirigir guardando la URL
    if (!loggedIn && !loggingIn) {
      final from = Uri.encodeComponent(state.matchedLocation);
      return '/login?from=$from';
    }

    // Si ya está logueado y va al login, redirigir según URL de retorno
    if (loggedIn && loggingIn) {
      final from = state.uri.queryParameters['from'];
      if (from != null && from.isNotEmpty) {
        return Uri.decodeComponent(from);
      }
      return '/social_profile';
    }

    return null;
  },
);