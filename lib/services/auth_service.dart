import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:formulario_app/utils/error_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();

  factory AuthService() => _instance;

  AuthService._internal();

  String _hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  Future<Map<String, dynamic>?> login(String username, String password) async {
    try {
      print('Intentando login con usuario: $username');

      // Verificar si las credenciales son las del usuario por defecto
      if (username.toLowerCase() == 'admincocep' && password == 'Avivamiento_Cocep#') {
        final result = {'role': 'adminPastores'};
        await _guardarSesion(result); // 🆕 Guardar sesión
        return result;
      }

      // Buscar en la colección de usuarios
      final userQuery = await FirebaseFirestore.instance
          .collection('usuarios')
          .where('usuario', isEqualTo: username)
          .get();

      print('Encontrados ${userQuery.docs.length} documentos');

      if (userQuery.docs.isNotEmpty) {
        final userData = userQuery.docs.first.data();
        print('Datos encontrados: $userData');

        // Verificar la contraseña sin hash para todos los usuarios
        if (userData['contrasena'] == password) {
          Map<String, dynamic>? result;

          switch (userData['rol']) {
            case 'tribu':
              // Asegurarse de que todos los campos necesarios existan
              if (userData['tribuId'] != null && userData['nombre'] != null) {
                result = {
                  'role': 'tribu',
                  'tribuId': userData['tribuId'],
                  'nombreTribu': userData['nombre'],
                  'userId': userQuery.docs.first.id,
                  'userName': userData['nombre'],
                };
              } else {
                print('Faltan datos requeridos para la tribu');
                return null;
              }
              break;

            case 'liderConsolidacion':
              result = {
                'role': 'liderConsolidacion',
                'userId': userQuery.docs.first.id,
                'userName': userData['nombre'] ?? username,
              };
              break;

            case 'coordinador':
              if (userData['coordinadorId'] != null) {
                result = {
                  'role': 'coordinador',
                  'coordinadorId': userData['coordinadorId'],
                  'coordinadorNombre': userData['nombre'] ?? '',
                  'userId': userData['coordinadorId'],
                  'userName': userData['nombre'] ?? '',
                };
              } else {
                return null;
              }
              break;

            case 'liderMinisterio':
              result = {
                'role': 'liderMinisterio',
                'ministerio': userData['ministerio'] ?? '',
                'userId': userQuery.docs.first.id,
                'userName': userData['nombre'] ?? username,
              };
              break;

            default:
              print('Rol no reconocido: ${userData['rol']}');
              return null;
          }

          if (result != null) {
            await _guardarSesion(result); // 🆕 Guardar sesión
          }
          return result;
        } else {
          print('Contraseña incorrecta');
          return null;
        }
      }

      // Verificar coordinadores en su colección específica
      final coordinadorQuery = await FirebaseFirestore.instance
          .collection('coordinadores')
          .where('usuario', isEqualTo: username)
          .where('contrasena', isEqualTo: password)
          .get();

      if (coordinadorQuery.docs.isNotEmpty) {
        final coordinadorData = coordinadorQuery.docs.first;
        final result = {
          'role': 'coordinador',
          'coordinadorId': coordinadorData.id,
          'coordinadorNombre':
              '${coordinadorData['nombre']} ${coordinadorData['apellido']}',
          'userId': coordinadorData.id,
          'userName':
              '${coordinadorData['nombre']} ${coordinadorData['apellido']}',
        };
        await _guardarSesion(result); // 🆕 Guardar sesión
        return result;
      }

      // Verificar timoteos
      final timoteoQuery = await FirebaseFirestore.instance
          .collection('timoteos')
          .where('usuario', isEqualTo: username)
          .where('contrasena', isEqualTo: password)
          .get();

      if (timoteoQuery.docs.isNotEmpty) {
        final timoteoData = timoteoQuery.docs.first;
        final result = {
          'role': 'timoteo',
          'timoteoId': timoteoData.id,
          'timoteoNombre':
              '${timoteoData['nombre']} ${timoteoData['apellido']}',
          'userId': timoteoData.id,
          'userName': '${timoteoData['nombre']} ${timoteoData['apellido']}',
        };
        await _guardarSesion(result); // 🆕 Guardar sesión
        return result;
      }

      // Verificar líderes de ministerio en su colección específica
      final liderMinisterioQuery = await FirebaseFirestore.instance
          .collection('lideresMinisterio')
          .where('usuario', isEqualTo: username)
          .where('contrasena', isEqualTo: password)
          .get();

      if (liderMinisterioQuery.docs.isNotEmpty) {
        final liderData = liderMinisterioQuery.docs.first;
        final result = {
          'role': 'liderMinisterio',
          'ministerio': liderData['ministerio'],
          'userId': liderData.id,
          'userName': liderData['nombre'] ?? username,
        };
        await _guardarSesion(result); // 🆕 Guardar sesión
        return result;
      }

      print('No se encontró coincidencia de credenciales');
      return null;
    } catch (e, stack) {
      print('Error en login: $e');
      ErrorHandler.logError(e, stack);
      return null;
    }
  }

  // =============================================================================
  // 🆕 MÉTODOS NUEVOS PARA PERSISTENCIA DE SESIÓN
  // =============================================================================

  /// Guarda la sesión del usuario en SharedPreferences
  Future<void> _guardarSesion(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userId', userData['userId']?.toString() ?? '');
      await prefs.setString('userRole', userData['role']?.toString() ?? '');
      await prefs.setString('userName', userData['userName']?.toString() ?? '');

      // Guardar datos específicos según el rol
      if (userData['coordinadorId'] != null) {
        await prefs.setString(
            'coordinadorId', userData['coordinadorId'].toString());
        await prefs.setString('coordinadorNombre',
            userData['coordinadorNombre']?.toString() ?? '');
      }
      if (userData['timoteoId'] != null) {
        await prefs.setString('timoteoId', userData['timoteoId'].toString());
        await prefs.setString(
            'timoteoNombre', userData['timoteoNombre']?.toString() ?? '');
      }
      if (userData['tribuId'] != null) {
        await prefs.setString('tribuId', userData['tribuId'].toString());
        await prefs.setString(
            'nombreTribu', userData['nombreTribu']?.toString() ?? '');
      }
      if (userData['ministerio'] != null) {
        await prefs.setString('ministerio', userData['ministerio'].toString());
      }

      print('✅ Sesión guardada correctamente: ${userData['role']}');
    } catch (e) {
      print('❌ Error al guardar sesión: $e');
      ErrorHandler.logError(e, StackTrace.current);
    }
  }

  /// Verifica si el usuario está autenticado
  Future<bool> isAuthenticated() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      return userId != null && userId.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Obtiene el rol del usuario actual desde SharedPreferences
  Future<String?> getCurrentUserRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('userRole');
    } catch (e) {
      print('❌ Error al obtener rol: $e');
      return null;
    }
  }

  /// Obtiene el ID del usuario actual
  Future<String> getUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('userId') ?? '';
    } catch (e) {
      return '';
    }
  }

  /// Obtiene el nombre del usuario actual
  Future<String> getUserName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('userName') ?? '';
    } catch (e) {
      return '';
    }
  }

  /// Obtiene el ID del coordinador (si aplica)
  Future<String> getCoordinadorId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('coordinadorId') ?? '';
    } catch (e) {
      return '';
    }
  }

  /// Obtiene el nombre del coordinador (si aplica)
  Future<String> getCoordinadorNombre() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('coordinadorNombre') ?? '';
    } catch (e) {
      return '';
    }
  }

  /// Obtiene el ID del timoteo (si aplica)
  Future<String> getTimoteoId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('timoteoId') ?? '';
    } catch (e) {
      return '';
    }
  }

  /// Obtiene el nombre del timoteo (si aplica)
  Future<String> getTimoteoNombre() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('timoteoNombre') ?? '';
    } catch (e) {
      return '';
    }
  }

  /// Obtiene el ID de la tribu (si aplica)
  Future<String> getTribuId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('tribuId') ?? '';
    } catch (e) {
      return '';
    }
  }

  /// Obtiene el nombre de la tribu (si aplica)
  Future<String> getNombreTribu() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('nombreTribu') ?? '';
    } catch (e) {
      return '';
    }
  }

  /// Obtiene el ministerio del líder (si aplica)
  Future<String> getMinisterio() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('ministerio') ?? '';
    } catch (e) {
      return '';
    }
  }

  /// Cierra la sesión del usuario
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      print('✅ Sesión cerrada correctamente');
    } catch (e) {
      print('❌ Error al cerrar sesión: $e');
      ErrorHandler.logError(e, StackTrace.current);
    }
  }
}
