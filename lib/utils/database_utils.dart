// En un archivo separado como database_utils.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseUtils {
  static Future<void> verificarYMigrarDocumento(String registroId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('registros')
          .doc(registroId)
          .get();

      if (!doc.exists) return;
      
      final data = doc.data();
      if (data == null) return;

      Map<String, dynamic> camposAActualizar = {};
      
      // Verifica y establece campos con valores por defecto si no existen
      if (!data.containsKey('faltasConsecutivas')) {
        camposAActualizar['faltasConsecutivas'] = 0;
      }
      
      if (!data.containsKey('estadoProceso')) {
        camposAActualizar['estadoProceso'] = 'Sin iniciar';
      }
      
      if (!data.containsKey('asistencias')) {
        camposAActualizar['asistencias'] = [];
      }

      if (!data.containsKey('fechaActualizacionEstado')) {
        camposAActualizar['fechaActualizacionEstado'] = FieldValue.serverTimestamp();
      }

      if (camposAActualizar.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('registros')
            .doc(registroId)
            .update(camposAActualizar);
      }
    } catch (e) {
      print('Error en verificarYMigrarDocumento: $e');
    }
  }
}