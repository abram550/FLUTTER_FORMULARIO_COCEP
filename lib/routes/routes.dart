import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Screens
import 'package:formulario_app/screens/login_screen.dart';
import 'package:formulario_app/screens/social_profile_screen.dart';
import 'package:formulario_app/screens/peticiones_form_screen.dart';
import 'package:formulario_app/screens/TimoteosScreen.dart';
import 'package:formulario_app/screens/form_screen.dart';
import 'package:formulario_app/screens/CoordinadorScreen.dart';
import 'package:formulario_app/screens/admin_pastores.dart';
import 'package:formulario_app/screens/admin_screen.dart';
import 'package:formulario_app/screens/TribusScreen.dart';
import 'package:formulario_app/screens/ministerio_lider_screen.dart';
import 'package:formulario_app/screens/departamento_discipulado_screen.dart';
import 'package:formulario_app/screens/maestro_discipulado_screen.dart';

// Middleware
import 'package:formulario_app/middleware/auth_guard.dart';

final AuthGuard _authGuard = AuthGuard();

final GoRouter router = GoRouter(
  initialLocation: '/login',
  redirect: (BuildContext context, GoRouterState state) async {
    final path = state.matchedLocation;

    // ✅ CORREGIDO: Rutas públicas que NO requieren autenticación
    const publicRoutes = ['/login', '/form', '/social_profile'];

    // ✅ NUEVO: Verificar si es una ruta de peticiones (dinámica)
    if (publicRoutes.contains(path) || path.startsWith('/peticiones/')) {
      return null; // Permitir acceso sin autenticación
    }

    // Todas las demás rutas requieren autenticación
    final isAuth = await _authGuard.isAuthenticated();
    if (!isAuth) {
      return '/login';
    }

    return null; // Usuario autenticado, permitir navegación
  },
  routes: [
    // ============================================================
    // RUTA PÚBLICA - LOGIN
    // ============================================================
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),

    GoRoute(
      path: '/form',
      builder: (context, state) => const FormularioPage(),
    ),

    GoRoute(
      path: '/social_profile',
      builder: (context, state) => const SocialProfileScreen(),
    ),

    // RUTA PÚBLICA - FORMULARIO DE PETICIONES
    GoRoute(
      path: '/peticiones/:tribuId',
      builder: (context, state) {
        final tribuId = state.pathParameters['tribuId']!;
        return PeticionesFormScreen(tribuId: tribuId);
      },
    ),

    // ============================================================
    // RUTAS PROTEGIDAS - Requieren autenticación
    // ============================================================

    GoRoute(
      path: '/admin_pastores',
      redirect: (context, state) =>
          _authGuard.redirect(context, state, ['adminPastores']),
      builder: (context, state) => const AdminPastores(),
    ),

    GoRoute(
      path: '/admin',
      redirect: (context, state) =>
          _authGuard.redirect(context, state, ['liderConsolidacion']),
      builder: (context, state) => const AdminPanel(),
    ),

    GoRoute(
      path: '/timoteos/:timoteoId/:timoteoNombre',
      redirect: (context, state) =>
          _authGuard.redirect(context, state, ['timoteo', 'coordinador']),
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
      path: '/coordinador/:coordinadorId/:coordinadorNombre',
      redirect: (context, state) =>
          _authGuard.redirect(context, state, ['coordinador']),
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
      path: '/tribus/:tribuId/:tribuNombre',
      redirect: (context, state) => _authGuard.redirect(
        context,
        state,
        ['tribu', 'timoteo', 'coordinador'],
      ),
      builder: (context, state) {
        final tribuId = state.pathParameters['tribuId']!;
        final tribuNombre = state.pathParameters['tribuNombre']!;
        return TribusScreen(
          tribuId: tribuId,
          tribuNombre: tribuNombre,
        );
      },
    ),

    GoRoute(
      path: '/ministerio_lider',
      redirect: (context, state) =>
          _authGuard.redirect(context, state, ['liderMinisterio']),
      builder: (context, state) {
        final params = state.extra as Map<String, dynamic>;
        return MinisterioLiderScreen(ministerio: params['ministerio']);
      },
    ),

    // ============================================================
    // DEPARTAMENTO DE DISCIPULADO
    // ============================================================

    GoRoute(
      path: '/departamento_discipulado',
      redirect: (context, state) =>
          _authGuard.redirect(context, state, ['departamentoDiscipulado']),
      builder: (context, state) => const DepartamentoDiscipuladoScreen(),
    ),

    GoRoute(
      path: '/maestro_discipulado/:maestroId/:maestroNombre',
      redirect: (context, state) =>
          _authGuard.redirect(context, state, ['maestroDiscipulado']),
      builder: (context, state) {
        final maestroId = state.pathParameters['maestroId']!;
        final maestroNombre = state.pathParameters['maestroNombre']!;
        final claseAsignadaId = state.uri.queryParameters['claseAsignadaId'];
        return MaestroDiscipuladoScreen(
          maestroId: maestroId,
          maestroNombre: maestroNombre,
          claseAsignadaId: claseAsignadaId,
        );
      },
    ),
  ],
);
