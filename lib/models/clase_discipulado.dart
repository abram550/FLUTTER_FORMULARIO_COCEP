// ========================================
// UBICACIÓN: formulario_app/lib/models/clase_discipulado.dart
// CREAR ESTE NUEVO ARCHIVO
// ========================================

import 'package:cloud_firestore/cloud_firestore.dart';

class ClaseDiscipulado {
  String? id;
  String tipo; // 'Discipulado 1', 'Discipulado 2', 'Discipulado 3', 'Consolidación'
  int totalModulos;
  DateTime fechaInicio;
  String? maestroId;
  String? maestroNombre;
  List<Map<String, dynamic>> discipulosInscritos;
  String estado; // 'activa', 'finalizada'
  DateTime? fechaFinalizacion;

  ClaseDiscipulado({
    this.id,
    required this.tipo,
    required this.totalModulos,
    required this.fechaInicio,
    this.maestroId,
    this.maestroNombre,
    required this.discipulosInscritos,
    this.estado = 'activa',
    this.fechaFinalizacion,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'tipo': tipo,
      'totalModulos': totalModulos,
      'fechaInicio': Timestamp.fromDate(fechaInicio),
      'maestroId': maestroId,
      'maestroNombre': maestroNombre,
      'discipulosInscritos': discipulosInscritos,
      'estado': estado,
      'fechaFinalizacion': fechaFinalizacion != null 
          ? Timestamp.fromDate(fechaFinalizacion!) 
          : null,
    };
  }

  factory ClaseDiscipulado.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return ClaseDiscipulado(
      id: doc.id,
      tipo: data['tipo'] ?? '',
      totalModulos: data['totalModulos'] ?? 0,
      fechaInicio: (data['fechaInicio'] as Timestamp).toDate(),
      maestroId: data['maestroId'],
      maestroNombre: data['maestroNombre'],
      discipulosInscritos: List<Map<String, dynamic>>.from(
        data['discipulosInscritos'] ?? []
      ),
      estado: data['estado'] ?? 'activa',
      fechaFinalizacion: data['fechaFinalizacion'] != null 
          ? (data['fechaFinalizacion'] as Timestamp).toDate() 
          : null,
    );
  }
}

class MaestroDiscipulado {
  String? id;
  String nombre;
  String apellido;
  String usuario;
  String contrasena;
  String? claseAsignadaId;
  DateTime fechaCreacion;

  MaestroDiscipulado({
    this.id,
    required this.nombre,
    required this.apellido,
    required this.usuario,
    required this.contrasena,
    this.claseAsignadaId,
    required this.fechaCreacion,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'nombre': nombre,
      'apellido': apellido,
      'usuario': usuario,
      'contrasena': contrasena,
      'claseAsignadaId': claseAsignadaId,
      'fechaCreacion': Timestamp.fromDate(fechaCreacion),
      'rol': 'maestroDiscipulado',
    };
  }

  factory MaestroDiscipulado.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return MaestroDiscipulado(
      id: doc.id,
      nombre: data['nombre'] ?? '',
      apellido: data['apellido'] ?? '',
      usuario: data['usuario'] ?? '',
      contrasena: data['contrasena'] ?? '',
      claseAsignadaId: data['claseAsignadaId'],
      fechaCreacion: (data['fechaCreacion'] as Timestamp).toDate(),
    );
  }
}

class AsistenciaDiscipulado {
  String claseId;
  String discipuloId;
  String discipuloNombre;
  int numeroModulo;
  bool asistio;
  DateTime fecha;

  AsistenciaDiscipulado({
    required this.claseId,
    required this.discipuloId,
    required this.discipuloNombre,
    required this.numeroModulo,
    required this.asistio,
    required this.fecha,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'claseId': claseId,
      'discipuloId': discipuloId,
      'discipuloNombre': discipuloNombre,
      'numeroModulo': numeroModulo,
      'asistio': asistio,
      'fecha': Timestamp.fromDate(fecha),
    };
  }

  factory AsistenciaDiscipulado.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return AsistenciaDiscipulado(
      claseId: data['claseId'] ?? '',
      discipuloId: data['discipuloId'] ?? '',
      discipuloNombre: data['discipuloNombre'] ?? '',
      numeroModulo: data['numeroModulo'] ?? 0,
      asistio: data['asistio'] ?? false,
      fecha: (data['fecha'] as Timestamp).toDate(),
    );
  }
}