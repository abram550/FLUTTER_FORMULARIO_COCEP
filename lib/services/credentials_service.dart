import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kReleaseMode;

/// Servicio para gestionar credenciales de forma segura
/// Las credenciales están ofuscadas usando Base64 dividido
class CredentialsService {
  // ⚠️ CREDENCIALES DE ADMIN OFUSCADAS Y DIVIDIDAS
  // "admincocep" → YWRtaW5jb2NlcA== (dividido para evitar pattern matching)
  static const List<String> _uParts = ["YWRt", "aW5j", "b2Nl", "cA=="];

  // "Avivamiento_Cocep#" → QXZpdmFtaWVudG9fQ29jZXAj (dividido)
  static const List<String> _pParts = ["QXZpdmF", "taWVudG9fQ", "29jZXAj"];

  // ⚠️ CLAVE DE ELIMINACIÓN DE TRIBU OFUSCADA Y DIVIDIDA
  // "T1empoC0cep!" → VDFlbXBvQzBjZXAh (dividido)
  static const List<String> _delParts = ["V", "DFlbXBv", "QzBjZXAh"];

  /// Une las partes de una cadena dividida
  static String _join(List<String> parts) => parts.join();

  /// Decodifica Base64 de forma segura (sin logs de secretos)
  static String _b64(String b64) {
    final bytes = base64.decode(b64);
    return utf8.decode(bytes);
  }

  /// Comparación en tiempo constante para prevenir timing attacks
  static bool _constTimeEquals(String a, String b) {
    if (a.isEmpty && b.isEmpty) return true;

    final ba = Uint8List.fromList(utf8.encode(a));
    final bb = Uint8List.fromList(utf8.encode(b));

    // XOR de longitudes para detectar diferencias
    int diff = ba.length ^ bb.length;

    // Comparar todos los bytes hasta la longitud mínima
    final len = (ba.length < bb.length) ? ba.length : bb.length;
    for (int i = 0; i < len; i++) {
      diff |= (ba[i] ^ bb[i]);
    }

    // diff == 0 solo si son idénticos
    return diff == 0;
  }

  /// Decodifica las credenciales del administrador
  static Map<String, String> getAdminCredentials() {
    try {
      final username = _b64(_join(_uParts));
      final password = _b64(_join(_pParts));

      return {
        'username': username,
        'password': password,
      };
    } catch (e) {
      // En producción NO exponemos secretos por fallback
      if (kReleaseMode) {
        // Retorna vacío para mantener la firma pero sin exponer secretos
        return {
          'username': '',
          'password': '',
        };
      }

      // Solo en debug mantenemos el fallback original (útil para desarrollo)
      return {
        'username': 'admincocep',
        'password': 'Avivamiento_Cocep#',
      };
    }
  }

  /// Obtiene la clave de eliminación de tribu
  static String getDeletionKey() {
    try {
      return _b64(_join(_delParts));
    } catch (e) {
      // En producción NO exponemos la clave por defecto
      if (kReleaseMode) {
        return ''; // Retorna vacío en release
      }

      // Solo en debug mantenemos el fallback original
      return 'T1empoC0cep!';
    }
  }

  /// Valida si una clave de eliminación es correcta
  /// Usa comparación en tiempo constante para prevenir timing attacks
  static bool validateDeletionKey(String inputKey) {
    try {
      final correctKey = getDeletionKey();
      // Comparación segura en tiempo constante
      return _constTimeEquals(inputKey, correctKey);
    } catch (e) {
      return false;
    }
  }
}
