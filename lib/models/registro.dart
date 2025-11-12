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
  // Nuevos campos
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
  String? tribuAsignada;
  // Campos nuevos a agregar
  String? estadoFonovisita;
  String? observaciones2;
  // NUEVO CAMPO: Fecha de nacimiento
  DateTime? fechaNacimiento;

  String? coordinadorAsignado;
  bool activo;

  Registro(
      {this.id,
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
      this.estadoFonovisita,
      this.observaciones2,
      // NUEVO CAMPO EN CONSTRUCTOR
      this.fechaNacimiento,
      this.coordinadorAsignado,
      this.activo = true});

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
      'estadoFonovisita': estadoFonovisita,
      'observaciones2': observaciones2,
      // NUEVO CAMPO EN toLocalMap
      'fechaNacimiento': fechaNacimiento?.toIso8601String(),
    };
  }

  Map<String, dynamic> toFirestoreMap() {
    // 🔥 MAPA BASE CON CAMPOS SIEMPRE REQUERIDOS
    final Map<String, dynamic> data = {
      'nombre': nombre,
      'apellido': apellido,
      'telefono': telefono,
      'servicio': servicio,
      'fecha': fecha,
      'activo': activo,
    };

    // ✅ AGREGAR CAMPOS SOLO SI TIENEN VALOR

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
      // Campos obligatorios para nuevos
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

      // Campos opcionales para nuevos
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

    // Campos administrativos (solo si existen)
    if (tribuAsignada != null && tribuAsignada!.isNotEmpty) {
      data['tribuAsignada'] = tribuAsignada;
    }
    if (estadoFonovisita != null && estadoFonovisita!.isNotEmpty) {
      data['estadoFonovisita'] = estadoFonovisita;
    }
    if (observaciones2 != null && observaciones2!.isNotEmpty) {
      data['observaciones2'] = observaciones2;
    }
    if (fechaNacimiento != null) {
      data['fechaNacimiento'] = fechaNacimiento;
    }
    if (coordinadorAsignado != null && coordinadorAsignado!.isNotEmpty) {
      data['coordinadorAsignado'] = coordinadorAsignado;
    }

    return data;
  }

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
      ocupaciones: (map['ocupaciones'] as String).split(','),
      descripcionOcupacion: map['descripcionOcupacion'] ?? '',
      tieneHijos: map['tieneHijos'] == 1,
      referenciaInvitacion: map['referenciaInvitacion'] ?? '',
      observaciones: map['observaciones'],
      tribuAsignada: map['tribuAsignada'],
      estadoFonovisita: map['estadoFonovisita'],
      observaciones2: map['observaciones2'],
      // NUEVO CAMPO EN fromLocalMap
      fechaNacimiento: map['fechaNacimiento'] != null
          ? DateTime.parse(map['fechaNacimiento'])
          : null,
    );
  }

  factory Registro.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Registro(
      id: doc.id,
      nombre: data['nombre'] ?? '',
      apellido: data['apellido'] ?? '',
      telefono: data['telefono'] ?? '',
      servicio: data['servicio'] ?? '',
      tipo: data['tipo'],
      fecha: (data['fecha'] as Timestamp).toDate(),
      motivo: data['motivo'],
      peticiones: data['peticiones'],
      consolidador: data['consolidador'],
      sexo: data['sexo'] ?? '',
      edad: data['edad'] ?? 0,
      direccion: data['direccion'] ?? '',
      barrio: data['barrio'] ?? '',
      estadoCivil: data['estadoCivil'] ?? '',
      nombrePareja: data['nombrePareja'],
      ocupaciones: List<String>.from(data['ocupaciones'] ?? []),
      descripcionOcupacion: data['descripcionOcupacion'] ?? '',
      tieneHijos: data['tieneHijos'] ?? false,
      referenciaInvitacion: data['referenciaInvitacion'] ?? '',
      observaciones: data['observaciones'],
      tribuAsignada: data['tribuAsignada'],
      estadoFonovisita: data['estadoFonovisita'],
      observaciones2: data['observaciones2'],
      // NUEVO CAMPO EN fromFirestore
      fechaNacimiento: data['fechaNacimiento'] != null
          ? (data['fechaNacimiento'] as Timestamp).toDate()
          : null,
      coordinadorAsignado: data['coordinadorAsignado'],
      activo: data['activo'] ?? true,
    );
  }
}
