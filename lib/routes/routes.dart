// ========================================
// UBICACIÓN: formulario_app/lib/router.dart
// REEMPLAZA TODO EL CONTENIDO del archivo por este código
// ========================================

import 'package:flutter/material.dart';
import 'package:formulario_app/screens/ministerio_lider_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:formulario_app/screens/login_screen.dart';
import 'package:formulario_app/screens/social_profile_screen.dart';
import 'package:formulario_app/screens/TimoteosScreen.dart';
import 'package:formulario_app/screens/form_screen.dart';
import 'package:formulario_app/screens/CoordinadorScreen.dart';
import 'package:formulario_app/screens/admin_pastores.dart';
import 'package:formulario_app/screens/admin_screen.dart';
import 'package:formulario_app/screens/TribusScreen.dart';
import 'package:formulario_app/screens/departamento_discipulado_screen.dart';
import 'package:formulario_app/screens/maestro_discipulado_screen.dart';

final GoRouter router = GoRouter(
  initialLocation: '/login',
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
            timoteoId: timoteoId, timoteoNombre: timoteoNombre);
      },
    ),
    GoRoute(
      path: '/ministerio_lider',
      builder: (context, state) {
        final params = state.extra as Map<String, dynamic>;
        return MinisterioLiderScreen(ministerio: params['ministerio']);
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
            coordinadorId: coordinadorId, coordinadorNombre: coordinadorNombre);
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
      path: '/tribus/:tribuId/:tribuNombre',
      builder: (context, state) {
        final tribuId = state.pathParameters['tribuId']!;
        final tribuNombre = state.pathParameters['tribuNombre']!;
        return TribusScreen(tribuId: tribuId, tribuNombre: tribuNombre);
      },
    ),
    // ✅ NUEVAS RUTAS - Departamento de Discipulado
    // Departamento de Discipulado
    GoRoute(
      path: '/departamento_discipulado',
      builder: (context, state) => const DepartamentoDiscipuladoScreen(),
    ),

// Maestro de Discipulado
    GoRoute(
      path: '/maestro_discipulado/:maestroId/:maestroNombre',
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
