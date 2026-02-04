// Dart SDK
import 'dart:convert';

// Firebase
import 'package:cloud_firestore/cloud_firestore.dart';

// Paquetes externos
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Proyecto
import 'package:formulario_app/services/credentials_service.dart';
import 'package:formulario_app/utils/error_handler.dart';

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

      // Verificar credenciales de administrador usando servicio ofuscado
      final adminCreds = CredentialsService.getAdminCredentials();
      if (username.toLowerCase() == adminCreds['username']?.toLowerCase() &&
          password == adminCreds['password']) {
        final result = {
          'role': 'adminPastores',
          'userId': 'admin_cocep_unique_id',
          'userName': 'Administrador COCEP',
        };
        await _guardarSesion(result);
        return result;
      }

      // ✅ Verificar credenciales de Departamento de Discipulado
      final departamentoDoc = await FirebaseFirestore.instance
          .collection('departamentoDiscipulado')
          .doc('configuracion')
          .get();

      if (departamentoDoc.exists) {
        final depData = departamentoDoc.data()!;
        if (username.toLowerCase() == depData['usuario']?.toLowerCase() &&
            password == depData['contrasena']) {
          final result = {
            'role': 'departamentoDiscipulado',
            'userId': 'depto_discipulado_unique_id',
            'userName': 'Departamento de Discipulado',
            'puedeEditarCredenciales':
                depData['puedeEditarCredenciales'] ?? true,
          };
          await _guardarSesion(result);
          return result;
        }
      }

      // ✅ CORRECCIÓN: Verificar maestros de discipulado
      final maestroQuery = await FirebaseFirestore.instance
          .collection('maestrosDiscipulado')
          .where('usuario', isEqualTo: username)
          .where('contrasena', isEqualTo: password)
          .get();

      if (maestroQuery.docs.isNotEmpty) {
        final maestroData = maestroQuery.docs.first;
        final data = maestroData.data();

        print('✅ Maestro encontrado: ${data['nombre']} ${data['apellido']}');
        print('Clase asignada: ${data['claseAsignadaId']}');

        final result = {
          'role': 'maestroDiscipulado',
          'maestroId': maestroData.id,
          'maestroNombre': '${data['nombre']} ${data['apellido']}',
          'userId': maestroData.id,
          'userName': '${data['nombre']} ${data['apellido']}',
          'claseAsignadaId': data['claseAsignadaId'],
        };
        await _guardarSesion(result);
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

        if (userData['contrasena'] == password) {
          Map<String, dynamic>? result;

          switch (userData['rol']) {
            case 'tribu':
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
            await _guardarSesion(result);
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
        await _guardarSesion(result);
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
        await _guardarSesion(result);
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
        await _guardarSesion(result);
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
  // MÉTODOS PARA PERSISTENCIA DE SESIÓN
  // =============================================================================

  Future<void> _guardarSesion(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // ✅ NUEVO: Guardar timestamp de login
      await prefs.setInt(
          'loginTimestamp', DateTime.now().millisecondsSinceEpoch);

      await prefs.setString('userId', userData['userId']?.toString() ?? '');
      await prefs.setString('userRole', userData['role']?.toString() ?? '');
      await prefs.setString('userName', userData['userName']?.toString() ?? '');

      // ✅ Guardar datos específicos de maestro
      if (userData['maestroId'] != null) {
        await prefs.setString('maestroId', userData['maestroId'].toString());
        await prefs.setString(
            'maestroNombre', userData['maestroNombre']?.toString() ?? '');
        await prefs.setString(
            'claseAsignadaId', userData['claseAsignadaId']?.toString() ?? '');
      }

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

  Future<bool> isAuthenticated() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      final loginTimestamp = prefs.getInt('loginTimestamp');

      // ✅ NUEVO: Verificar que existe userId Y timestamp de login
      if (userId == null || userId.isEmpty || loginTimestamp == null) {
        print('❌ No hay sesión activa (userId o timestamp faltante)');
        return false;
      }

      // ✅ OPCIONAL: Verificar que la sesión no sea muy antigua (ej. 30 días)
      final loginDate = DateTime.fromMillisecondsSinceEpoch(loginTimestamp);
      final daysSinceLogin = DateTime.now().difference(loginDate).inDays;

      if (daysSinceLogin > 30) {
        print('❌ Sesión expirada (más de 30 días)');
        await logout(); // Limpiar sesión expirada
        return false;
      }

      print('✅ Sesión activa verificada');
      return true;
    } catch (e) {
      print('❌ Error al verificar autenticación: $e');
      return false;
    }
  }

  Future<String?> getCurrentUserRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('userRole');
    } catch (e) {
      print('❌ Error al obtener rol: $e');
      return null;
    }
  }

  Future<String> getUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('userId') ?? '';
    } catch (e) {
      return '';
    }
  }

  Future<String> getUserName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('userName') ?? '';
    } catch (e) {
      return '';
    }
  }

  // ✅ Métodos para maestros
  Future<String> getMaestroId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('maestroId') ?? '';
    } catch (e) {
      return '';
    }
  }

  Future<String> getMaestroNombre() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('maestroNombre') ?? '';
    } catch (e) {
      return '';
    }
  }

  Future<String> getClaseAsignadaId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('claseAsignadaId') ?? '';
    } catch (e) {
      return '';
    }
  }

  Future<String> getCoordinadorId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('coordinadorId') ?? '';
    } catch (e) {
      return '';
    }
  }

  Future<String> getCoordinadorNombre() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('coordinadorNombre') ?? '';
    } catch (e) {
      return '';
    }
  }

  Future<String> getTimoteoId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('timoteoId') ?? '';
    } catch (e) {
      return '';
    }
  }

  Future<String> getTimoteoNombre() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('timoteoNombre') ?? '';
    } catch (e) {
      return '';
    }
  }

  Future<String> getTribuId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('tribuId') ?? '';
    } catch (e) {
      return '';
    }
  }

  Future<String> getNombreTribu() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('nombreTribu') ?? '';
    } catch (e) {
      return '';
    }
  }

  Future<String> getMinisterio() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('ministerio') ?? '';
    } catch (e) {
      return '';
    }
  }

  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      print('🔄 Cerrando sesión...');
      print('📋 Datos antes de limpiar:');
      print('   - userId: ${prefs.getString('userId')}');
      print('   - userRole: ${prefs.getString('userRole')}');

      // ✅ CRÍTICO: Limpiar TODO el SharedPreferences
      final cleared = await prefs.clear();

      if (cleared) {
        print('✅ SharedPreferences limpiado exitosamente');

        // Verificar que realmente se limpió
        final userIdAfter = prefs.getString('userId');
        if (userIdAfter == null) {
          print('✅ Verificación: userId ya no existe');
        } else {
          print('⚠️ ADVERTENCIA: userId todavía existe después de clear()');
        }
      } else {
        print('❌ FALLO: clear() retornó false');
      }

      print('✅ Sesión cerrada completamente');
    } catch (e) {
      print('❌ Error al cerrar sesión: $e');
      ErrorHandler.logError(e, StackTrace.current);
    }
  }
}
