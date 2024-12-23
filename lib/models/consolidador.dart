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