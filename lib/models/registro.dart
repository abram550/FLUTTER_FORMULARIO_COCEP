// ========================================
// UBICACIÓN: formulario_app/lib/models/registro.dart
// REEMPLAZA TODO EL CONTENIDO del archivo por este código
// ========================================

import 'package:cloud_firestore/cloud_firestore.dart';

class Registro {
  String? id;
  String nombre;
  String apellido;
  String telefono;
  String servicio;
  String? tipo;
  DateTime fecha;
  String? motivo;
  String? peticiones;
  String? consolidador;

  // Campos personales
  String sexo;
  int edad;
  String direccion;
  String barrio;
  String estadoCivil;
  String? nombrePareja;
  List<String> ocupaciones;
  String descripcionOcupacion;
  bool tieneHijos;
  String referenciaInvitacion;
  String? observaciones;

  // Campos de asignación
  String? tribuAsignada;
  String? ministerioAsignado;
  String? nombreTribu;
  Timestamp? fechaAsignacion;
  Timestamp? fechaAsignacionTribu;
  String? coordinadorAsignado;
  String? timoteoAsignado;
  String? nombreTimoteo;
  Timestamp? fechaAsignacionCoordinador;

  // Campos de seguimiento
  String? estadoFonovisita;
  String? observaciones2;
  String? estadoProceso;
  DateTime? fechaNacimiento;
  bool activo;
  int faltasConsecutivas;

  // Campos para perfil social
  bool? origenPerfilSocial;
  String? perfilSocialId;

  Registro({
    this.id,
    required this.nombre,
    required this.apellido,
    required this.telefono,
    required this.servicio,
    this.tipo,
    required this.fecha,
    this.motivo,
    this.peticiones,
    this.consolidador,
    required this.sexo,
    required this.edad,
    required this.direccion,
    required this.barrio,
    required this.estadoCivil,
    this.nombrePareja,
    required this.ocupaciones,
    required this.descripcionOcupacion,
    required this.tieneHijos,
    required this.referenciaInvitacion,
    this.observaciones,
    this.tribuAsignada,
    this.ministerioAsignado,
    this.nombreTribu,
    this.fechaAsignacion,
    this.fechaAsignacionTribu,
    this.estadoFonovisita,
    this.observaciones2,
    this.estadoProceso,
    this.fechaNacimiento,
    this.coordinadorAsignado,
    this.timoteoAsignado,
    this.nombreTimoteo,
    this.fechaAsignacionCoordinador,
    this.activo = true,
    this.faltasConsecutivas = 0,
    this.origenPerfilSocial,
    this.perfilSocialId,
  });

  // ========================================
  // Método toLocalMap (para SQLite local)
  // ========================================
  Map<String, dynamic> toLocalMap() {
    return {
      'id': id,
      'nombre': nombre,
      'apellido': apellido,
      'telefono': telefono,
      'servicio': servicio,
      'tipo': tipo,
      'fecha': fecha.toIso8601String(),
      'motivo': motivo,
      'peticiones': peticiones,
      'consolidador': consolidador,
      'sexo': sexo,
      'edad': edad,
      'direccion': direccion,
      'barrio': barrio,
      'estadoCivil': estadoCivil,
      'nombrePareja': nombrePareja,
      'ocupaciones': ocupaciones.join(','),
      'descripcionOcupacion': descripcionOcupacion,
      'tieneHijos': tieneHijos ? 1 : 0,
      'referenciaInvitacion': referenciaInvitacion,
      'observaciones': observaciones,
      'tribuAsignada': tribuAsignada,
      'ministerioAsignado': ministerioAsignado,
      'nombreTribu': nombreTribu,
      'estadoFonovisita': estadoFonovisita,
      'observaciones2': observaciones2,
      'estadoProceso': estadoProceso,
      'fechaNacimiento': fechaNacimiento?.toIso8601String(),
      'coordinadorAsignado': coordinadorAsignado,
      'timoteoAsignado': timoteoAsignado,
      'nombreTimoteo': nombreTimoteo,
      'activo': activo ? 1 : 0,
      'faltasConsecutivas': faltasConsecutivas,
      'origenPerfilSocial': origenPerfilSocial == true ? 1 : 0,
      'perfilSocialId': perfilSocialId,
    };
  }

  // ========================================
  // Método toFirestoreMap (para guardar en Firestore)
  // ========================================
  Map<String, dynamic> toFirestoreMap() {
    final Map<String, dynamic> data = {
      'nombre': nombre,
      'apellido': apellido,
      'telefono': telefono,
      'servicio': servicio,
      'fecha': fecha,
      'activo': activo,
      'faltasConsecutivas': faltasConsecutivas,
    };

    // Tipo de registro
    if (tipo != null && tipo!.isNotEmpty) {
      data['tipo'] = tipo;
    }

    // Campos específicos para VISITA
    if (tipo?.toLowerCase() == 'visita') {
      if (motivo != null && motivo!.isNotEmpty) {
        data['motivo'] = motivo;
      }
      if (peticiones != null && peticiones!.isNotEmpty) {
        data['peticiones'] = peticiones;
      }
      if (consolidador != null && consolidador!.isNotEmpty) {
        data['consolidador'] = consolidador;
      }
    }

    // Campos específicos para NUEVO
    if (tipo?.toLowerCase() == 'nuevo') {
      if (sexo.isNotEmpty) data['sexo'] = sexo;
      if (edad > 0) data['edad'] = edad;
      if (direccion.isNotEmpty) data['direccion'] = direccion;
      if (barrio.isNotEmpty) data['barrio'] = barrio;
      if (estadoCivil.isNotEmpty) data['estadoCivil'] = estadoCivil;
      if (ocupaciones.isNotEmpty) data['ocupaciones'] = ocupaciones;
      if (descripcionOcupacion.isNotEmpty) {
        data['descripcionOcupacion'] = descripcionOcupacion;
      }
      data['tieneHijos'] = tieneHijos;
      if (referenciaInvitacion.isNotEmpty) {
        data['referenciaInvitacion'] = referenciaInvitacion;
      }

      if (nombrePareja != null && nombrePareja!.isNotEmpty) {
        data['nombrePareja'] = nombrePareja;
      }
      if (observaciones != null && observaciones!.isNotEmpty) {
        data['observaciones'] = observaciones;
      }
      if (peticiones != null && peticiones!.isNotEmpty) {
        data['peticiones'] = peticiones;
      }
      if (consolidador != null && consolidador!.isNotEmpty) {
        data['consolidador'] = consolidador;
      }
    }

    // Campos de asignación
    if (ministerioAsignado != null && ministerioAsignado!.isNotEmpty) {
      data['ministerioAsignado'] = ministerioAsignado;
    }
    if (tribuAsignada != null && tribuAsignada!.isNotEmpty) {
      data['tribuAsignada'] = tribuAsignada;
    }
    if (nombreTribu != null && nombreTribu!.isNotEmpty) {
      data['nombreTribu'] = nombreTribu;
    }
    if (fechaAsignacion != null) {
      data['fechaAsignacion'] = fechaAsignacion;
    }
    if (fechaAsignacionTribu != null) {
      data['fechaAsignacionTribu'] = fechaAsignacionTribu;
    }
    if (coordinadorAsignado != null && coordinadorAsignado!.isNotEmpty) {
      data['coordinadorAsignado'] = coordinadorAsignado;
    }
    if (timoteoAsignado != null && timoteoAsignado!.isNotEmpty) {
      data['timoteoAsignado'] = timoteoAsignado;
    }
    if (nombreTimoteo != null && nombreTimoteo!.isNotEmpty) {
      data['nombreTimoteo'] = nombreTimoteo;
    }
    if (fechaAsignacionCoordinador != null) {
      data['fechaAsignacionCoordinador'] = fechaAsignacionCoordinador;
    }

    // Campos de seguimiento
    if (estadoFonovisita != null && estadoFonovisita!.isNotEmpty) {
      data['estadoFonovisita'] = estadoFonovisita;
    }
    if (observaciones2 != null && observaciones2!.isNotEmpty) {
      data['observaciones2'] = observaciones2;
    }
    if (estadoProceso != null && estadoProceso!.isNotEmpty) {
      data['estadoProceso'] = estadoProceso;
    }
    if (fechaNacimiento != null) {
      data['fechaNacimiento'] = fechaNacimiento;
    }

    // Campos de perfil social
    if (origenPerfilSocial == true) {
      data['origenPerfilSocial'] = true;
    }
    if (perfilSocialId != null && perfilSocialId!.isNotEmpty) {
      data['perfilSocialId'] = perfilSocialId;
    }

    return data;
  }

  // ========================================
  // Factory fromLocalMap (desde SQLite)
  // ========================================
  factory Registro.fromLocalMap(Map<String, dynamic> map) {
    return Registro(
      id: map['id']?.toString(),
      nombre: map['nombre'] ?? '',
      apellido: map['apellido'] ?? '',
      telefono: map['telefono'] ?? '',
      servicio: map['servicio'] ?? '',
      tipo: map['tipo'],
      fecha: DateTime.parse(map['fecha'] as String),
      motivo: map['motivo'],
      peticiones: map['peticiones'],
      consolidador: map['consolidador'],
      sexo: map['sexo'] ?? '',
      edad: map['edad'] ?? 0,
      direccion: map['direccion'] ?? '',
      barrio: map['barrio'] ?? '',
      estadoCivil: map['estadoCivil'] ?? '',
      nombrePareja: map['nombrePareja'],
      ocupaciones:
          (map['ocupaciones'] as String?)?.split(',') ?? ['No especificado'],
      descripcionOcupacion: map['descripcionOcupacion'] ?? '',
      tieneHijos: map['tieneHijos'] == 1,
      referenciaInvitacion: map['referenciaInvitacion'] ?? '',
      observaciones: map['observaciones'],
      tribuAsignada: map['tribuAsignada'],
      ministerioAsignado: map['ministerioAsignado'],
      nombreTribu: map['nombreTribu'],
      estadoFonovisita: map['estadoFonovisita'],
      observaciones2: map['observaciones2'],
      estadoProceso: map['estadoProceso'],
      fechaNacimiento: map['fechaNacimiento'] != null
          ? DateTime.parse(map['fechaNacimiento'])
          : null,
      coordinadorAsignado: map['coordinadorAsignado'],
      timoteoAsignado: map['timoteoAsignado'],
      nombreTimoteo: map['nombreTimoteo'],
      activo: map['activo'] == 1,
      faltasConsecutivas: map['faltasConsecutivas'] ?? 0,
      origenPerfilSocial: map['origenPerfilSocial'] == 1,
      perfilSocialId: map['perfilSocialId'],
    );
  }

  // ========================================
  // Factory fromFirestore (desde Firestore) - ✅ MÉTODO CORREGIDO
  // ========================================
  factory Registro.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Registro(
      id: doc.id,
      nombre: data['nombre']?.toString() ?? '',
      apellido: data['apellido']?.toString() ?? '',
      telefono: data['telefono']?.toString() ?? '',
      servicio: data['servicio']?.toString() ?? '',
      tipo: data['tipo']?.toString(),
      fecha: _parseFecha(data['fecha'] ?? data['fechaRegistro']),
      motivo: data['motivo']?.toString(),
      peticiones: data['peticiones']?.toString(),
      consolidador: data['consolidador']?.toString(),
      sexo: data['sexo']?.toString() ?? 'No especificado',
      edad: _parseToInt(data['edad']),
      direccion: data['direccion']?.toString() ?? '',
      barrio: data['barrio']?.toString() ?? '',
      estadoCivil: data['estadoCivil']?.toString() ?? 'No especificado',
      nombrePareja: data['nombrePareja']?.toString(),
      ocupaciones: _parseOcupaciones(data['ocupaciones']),
      descripcionOcupacion: data['descripcionOcupacion']?.toString() ??
          data['descripcionOcupaciones']?.toString() ??
          '',
      tieneHijos: data['tieneHijos'] == true,
      referenciaInvitacion: data['referenciaInvitacion']?.toString() ?? '',
      observaciones: data['observaciones']?.toString(),
      tribuAsignada: data['tribuAsignada']?.toString(),
      ministerioAsignado: data['ministerioAsignado']?.toString(),
      nombreTribu: data['nombreTribu']?.toString(),
      fechaAsignacion: data['fechaAsignacion'] as Timestamp?,
      fechaAsignacionTribu: data['fechaAsignacionTribu'] as Timestamp?,
      estadoFonovisita: data['estadoFonovisita']?.toString(),
      observaciones2: data['observaciones2']?.toString(),
      estadoProceso: data['estadoProceso']?.toString() ?? 'En Proceso',
      fechaNacimiento: _parseFechaNacimiento(data['fechaNacimiento']),
      coordinadorAsignado: data['coordinadorAsignado']?.toString(),
      timoteoAsignado: data['timoteoAsignado']?.toString(),
      nombreTimoteo: data['nombreTimoteo']?.toString(),
      fechaAsignacionCoordinador:
          data['fechaAsignacionCoordinador'] as Timestamp?,
      activo: data['activo'] == true,
      faltasConsecutivas: _parseToInt(data['faltasConsecutivas']),
      origenPerfilSocial: data['origenPerfilSocial'] as bool?,
      perfilSocialId: data['perfilSocialId']?.toString(),
    );
  }

  // ========================================
  // Métodos auxiliares para parseo seguro
  // ========================================

  static int _parseToInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is double) return value.toInt();
    return 0;
  }

  static List<String> _parseOcupaciones(dynamic value) {
    if (value == null) return ['No especificado'];
    if (value is List) {
      final list = value
          .map((e) => e?.toString() ?? '')
          .where((e) => e.isNotEmpty)
          .toList();
      return list.isEmpty ? ['No especificado'] : list;
    }
    if (value is String && value.isNotEmpty) {
      return [value];
    }
    return ['No especificado'];
  }

  static DateTime _parseFecha(dynamic value) {
    if (value == null) return DateTime.now();

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is String) {
      final parsed = DateTime.tryParse(value);
      return parsed ?? DateTime.now();
    }

    if (value is DateTime) {
      return value;
    }

    return DateTime.now();
  }

  static DateTime? _parseFechaNacimiento(dynamic value) {
    if (value == null) return null;

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is String) {
      return DateTime.tryParse(value);
    }

    if (value is DateTime) {
      return value;
    }

    return null;
  }
}
