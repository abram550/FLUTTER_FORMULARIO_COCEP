class Registro {
  int? id;
  String nombre;
  String apellido;
  String telefono;
  String servicio;
  String? tipo;
  DateTime fecha;
  String? motivo;
  String? peticiones;
  String? consolidador;

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
  });

  Map<String, dynamic> toMap() {
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
    };
  }

  factory Registro.fromMap(Map<String, dynamic> map) {
    return Registro(
      id: map['id'],
      nombre: map['nombre'],
      apellido: map['apellido'],
      telefono: map['telefono'],
      servicio: map['servicio'],
      tipo: map['tipo'],
      fecha: DateTime.parse(map['fecha']),
      motivo: map['motivo'],
      peticiones: map['peticiones'],
      consolidador: map['consolidador'],
    );
  }
}

class Consolidador {
  int? id;
  String nombre;

  Consolidador({this.id, required this.nombre});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
    };
  }

  factory Consolidador.fromMap(Map<String, dynamic> map) {
    return Consolidador(
      id: map['id'],
      nombre: map['nombre'],
    );
  }
}