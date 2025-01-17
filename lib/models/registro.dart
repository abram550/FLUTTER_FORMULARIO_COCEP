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
  });

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
    };
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      'nombre': nombre,
      'apellido': apellido,
      'telefono': telefono,
      'servicio': servicio,
      'tipo': tipo,
      'fecha': fecha,
      'motivo': motivo,
      'peticiones': peticiones,
      'consolidador': consolidador,
      'sexo': sexo,
      'edad': edad,
      'direccion': direccion,
      'barrio': barrio,
      'estadoCivil': estadoCivil,
      'nombrePareja': nombrePareja,
      'ocupaciones': ocupaciones,
      'descripcionOcupacion': descripcionOcupacion,
      'tieneHijos': tieneHijos,
      'referenciaInvitacion': referenciaInvitacion,
      'observaciones': observaciones,
    };
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
    );
  }
}