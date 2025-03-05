import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
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

      // Verificar si las credenciales son las del usuario por defecto
      if (username.toLowerCase() == 'admin' && password == '123') {
        return {'role': 'adminPastores'};
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
          switch (userData['rol']) {
            case 'tribu':
              // Asegurarse de que todos los campos necesarios existan
              if (userData['tribuId'] != null && userData['nombre'] != null) {
                return {
                  'role': 'tribu',
                  'tribuId': userData['tribuId'],
                  'nombreTribu': userData['nombre'],
                };
              }
              print('Faltan datos requeridos para la tribu');
              return null;
            case 'liderConsolidacion':
              return {'role': 'liderConsolidacion'};
            case 'coordinador':
              if (userData['coordinadorId'] != null) {
                return {
                  'role': 'coordinador',
                  'coordinadorId': userData['coordinadorId'],
                  'coordinadorNombre': userData['nombre'] ?? '',
                };
              }
              return null;
            case 'liderMinisterio':
              return {
                'role': 'liderMinisterio',
                'ministerio': userData['ministerio'] ?? '',
              };
            default:
              print('Rol no reconocido: ${userData['rol']}');
              return null;
          }
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
        return {
          'role': 'coordinador',
          'coordinadorId': coordinadorData.id,
          'coordinadorNombre':
              '${coordinadorData['nombre']} ${coordinadorData['apellido']}',
        };
      }

      // Verificar timoteos
      final timoteoQuery = await FirebaseFirestore.instance
          .collection('timoteos')
          .where('usuario', isEqualTo: username)
          .where('contrasena', isEqualTo: password)
          .get();

      if (timoteoQuery.docs.isNotEmpty) {
        final timoteoData = timoteoQuery.docs.first;
        return {
          'role': 'timoteo',
          'timoteoId': timoteoData.id,
          'timoteoNombre': '${timoteoData['nombre']} ${timoteoData['apellido']}'
        };
      }

      // Verificar líderes de ministerio en su colección específica
      final liderMinisterioQuery = await FirebaseFirestore.instance
          .collection('lideresMinisterio')
          .where('usuario', isEqualTo: username)
          .where('contrasena', isEqualTo: password)
          .get();

      if (liderMinisterioQuery.docs.isNotEmpty) {
        final liderData = liderMinisterioQuery.docs.first;
        return {
          'role': 'liderMinisterio',
          'ministerio': liderData['ministerio'],
        };
      }

      print('No se encontró coincidencia de credenciales');
      return null;
    } catch (e, stack) {
      print('Error en login: $e');
      ErrorHandler.logError(e, stack);
      return null;
    }
  }
}
