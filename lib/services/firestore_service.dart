import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/registro.dart';
import 'dart:async';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream para escuchar cambios en tiempo real de los registros
  Stream<List<Registro>> streamRegistros() {
    return _firestore
        .collection('registros')
        .orderBy('fecha', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) {
              try {
                return Registro.fromFirestore(doc);
              } catch (e) {
                print('Error al convertir documento: $e');
                return null;
              }
            })
            .whereType<Registro>()
            .toList());
  }

  // Stream para escuchar cambios en tiempo real de los consolidadores
  Stream<List<Map<String, String>>> streamConsolidadores() {
    return _firestore
        .collection('consolidadores')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              return {
                'id': doc.id, // El ID siempre es String
                'nombre': doc['nombre']?.toString() ?? '',
              };
            }).toList());
  }

// Obtener todos los registros sin stream, para consultas puntuales
  Future<List<Registro>> obtenerTodosLosRegistros() async {
    try {
      final snapshot = await _firestore.collection('registros').get();
      return snapshot.docs.map((doc) {
        return Registro.fromFirestore(doc); // Usamos tu método ya existente
      }).toList();
    } catch (e) {
      print('Error al obtener todos los registros: $e');
      return [];
    }
  }

  // Verificar credenciales de usuario
  Future<bool> verificarCredenciales(String usuario, String contrasena) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('usuarios')
          .where('usuario', isEqualTo: usuario)
          .where('contrasena', isEqualTo: contrasena)
          .get();
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error de autenticación: $e');
      return false;
    }
  }

  // CRUD Operaciones para Registros
  Future<String> insertRegistro(Registro registro) async {
    try {
      print('Intentando insertar registro en Firestore: ${registro.nombre}');
      final data = registro.toFirestoreMap(); // Usar el método correcto

      DocumentReference docRef =
          await _firestore.collection('registros').add(data);
      print(
          'Registro insertado exitosamente en Firestore con ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('Error al insertar registro en Firestore: $e');
      rethrow;
    }
  }

  Future<void> actualizarRegistro(String docId, Registro registro) async {
    try {
      final data = registro.toFirestoreMap(); // Usar el método correcto
      await _firestore.collection('registros').doc(docId).update(data);
    } catch (e) {
      print('Error al actualizar registro: $e');
      rethrow;
    }
  }

  Future<void> eliminarRegistro(String docId) async {
    try {
      await _firestore.collection('registros').doc(docId).delete();
    } catch (e) {
      print('Error al eliminar registro: $e');
      rethrow;
    }
  }

  // CRUD Operaciones para Consolidadores
  Future<void> agregarConsolidador(String nombreConsolidador) async {
    try {
      await _firestore.collection('consolidadores').add({
        'nombre': nombreConsolidador,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error al agregar consolidador: $e');
      rethrow;
    }
  }

  Future<void> actualizarConsolidador(String docId, String nuevoNombre) async {
    try {
      await _firestore.collection('consolidadores').doc(docId).update({
        'nombre': nuevoNombre,
        'ultimaActualizacion': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error al actualizar consolidador: $e');
      rethrow;
    }
  }

  Future<void> eliminarConsolidador(String docId) async {
    try {
      await _firestore.collection('consolidadores').doc(docId).delete();
    } catch (e) {
      print('Error al eliminar consolidador: $e');
      rethrow;
    }
  }

  // Sincronización batch para registros locales
  Future<void> sincronizarRegistrosLocales(
      List<Registro> registrosLocales) async {
    try {
      for (var registro in registrosLocales) {
        final data = registro.toFirestoreMap(); // Usar el método correcto
        // Subir cada registro como un documento en Firestore
        await _firestore.collection('registros').add(data);
      }
      print('Registros sincronizados con Firebase.');
    } catch (e) {
      print('Error al sincronizar registros con Firebase: $e');
      rethrow;
    }
  }
}
