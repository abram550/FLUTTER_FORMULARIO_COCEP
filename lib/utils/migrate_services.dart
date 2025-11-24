import 'package:cloud_firestore/cloud_firestore.dart';

/// Script para migrar asistencias con nombres antiguos
Future<void> migrarNombresServicios() async {
  print('🔄 Iniciando migración de nombres de servicios...');
  
  try {
    // Buscar asistencias con "Dominical"
    final queryDominical = await FirebaseFirestore.instance
        .collection('asistencias')
        .where('nombreServicio', whereIn: ['Servicio Dominical', 'servicio dominical'])
        .get();

    print('📋 Encontradas ${queryDominical.docs.length} asistencias con "Dominical"');

    WriteBatch batch = FirebaseFirestore.instance.batch();
    int contador = 0;

    for (var doc in queryDominical.docs) {
      batch.update(doc.reference, {
        'nombreServicio': 'Servicio Familiar',
      });
      contador++;

      if (contador >= 500) {
        await batch.commit();
        batch = FirebaseFirestore.instance.batch();
        contador = 0;
        print('✅ Procesados 500 documentos...');
      }
    }

    if (contador > 0) {
      await batch.commit();
    }

    // Buscar asistencias con "Reunión General"
    final queryReunion = await FirebaseFirestore.instance
        .collection('asistencias')
        .where('nombreServicio', whereIn: ['Reunión General', 'reunion general'])
        .get();

    print('📋 Encontradas ${queryReunion.docs.length} asistencias con "Reunión General"');

    batch = FirebaseFirestore.instance.batch();
    contador = 0;

    for (var doc in queryReunion.docs) {
      batch.update(doc.reference, {
        'nombreServicio': 'Servicio Especial',
      });
      contador++;

      if (contador >= 500) {
        await batch.commit();
        batch = FirebaseFirestore.instance.batch();
        contador = 0;
      }
    }

    if (contador > 0) {
      await batch.commit();
    }

    print('✅ Migración completada exitosamente');
  } catch (e) {
    print('❌ Error en migración: $e');
  }
}