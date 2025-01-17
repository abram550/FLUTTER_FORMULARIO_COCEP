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
      // Verificar si las credenciales son las del usuario por defecto
      if (username.toLowerCase() == 'admin' && password == '123') {
        return {'role': 'adminPastores'};
      }

      // Primero intentar autenticar en la colección de usuarios
      final userQuery = await FirebaseFirestore.instance
          .collection('usuarios')
          .where('usuario', isEqualTo: username)
          .where('contrasena', isEqualTo: _hashPassword(password))
          .get();

      if (userQuery.docs.isNotEmpty) {
        final userData = userQuery.docs.first.data();
        return {
          'role': userData['rol'],
          'tribuId': userData['tribuId'] ?? '',
        };
      }

      // Si no se encuentra en usuarios, buscar en timoteos
      final timoteoQuery = await FirebaseFirestore.instance
          .collection('timoteos')
          .where('usuario', isEqualTo: username)
          .where('contrasena', isEqualTo: password) // No hasheamos la contraseña para timoteos
          .get();

      if (timoteoQuery.docs.isNotEmpty) {
        final timoteoData = timoteoQuery.docs.first;
        return {
          'role': 'timoteo',
          'timoteoId': timoteoData.id,
          'timoteoNombre': '${timoteoData['nombre']} ${timoteoData['apellido']}'
        };
      }

      return null;
    } catch (e, stack) {
      ErrorHandler.logError(e, stack);
      return null;
    }
  }
}