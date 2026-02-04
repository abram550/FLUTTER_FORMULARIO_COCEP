import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:formulario_app/services/auth_service.dart';

/// Guard de autenticación para proteger rutas
/// Verifica que el usuario tenga sesión activa y el rol correcto
class AuthGuard {
  final AuthService _authService = AuthService();

  /// Verifica si el usuario está autenticado
  Future<bool> isAuthenticated() async {
    return await _authService.isAuthenticated();
  }

  /// Verifica si el usuario tiene el rol correcto para la ruta
  Future<bool> hasRequiredRole(List<String> allowedRoles) async {
    final currentRole = await _authService.getCurrentUserRole();
    if (currentRole == null) return false;
    return allowedRoles.contains(currentRole);
  }

  /// Redirige al usuario según su estado de autenticación y rol
  Future<String?> redirect(
    BuildContext context,
    GoRouterState state,
    List<String> allowedRoles,
  ) async {
    final isAuth = await isAuthenticated();

    // Si no está autenticado, redirigir al login
    if (!isAuth) {
      return '/login';
    }

    // Si está autenticado, verificar el rol
    final hasRole = await hasRequiredRole(allowedRoles);
    if (!hasRole) {
      // Redirigir a la pantalla correcta según su rol actual
      final currentRole = await _authService.getCurrentUserRole();
      return _getCorrectRouteForRole(currentRole);
    }

    // Todo correcto, permitir acceso
    return null;
  }

  /// Obtiene la ruta correcta según el rol del usuario
  String _getCorrectRouteForRole(String? role) {
    if (role == null) return '/login';

    switch (role) {
      case 'adminPastores':
        return '/admin_pastores';
      case 'liderConsolidacion':
        return '/admin';
      case 'departamentoDiscipulado':
        return '/departamento_discipulado';
      case 'maestroDiscipulado':
        // Para maestro necesitamos obtener sus datos
        return '/login'; // Volverá a autenticarse y se redirigirá correctamente
      case 'coordinador':
        return '/login';
      case 'tribu':
        return '/login';
      case 'timoteo':
        return '/login';
      case 'liderMinisterio':
        return '/login';
      default:
        return '/login';
    }
  }
}