import 'package:cloud_firestore/cloud_firestore.dart';


class AsistenciaSemanal {
  final String id;
  final String tribuId;
  final DateTime fecha;
  final List<String> asistentesViernes;
  final List<String> asistentesSabado;
  final List<String> asistentesDomingo;
  final int totalAsistentes;
  final int semana;
  final int mes;
  final int ano;

  AsistenciaSemanal({
    required this.id,
    required this.tribuId,
    required this.fecha,
    required this.asistentesViernes,
    required this.asistentesSabado,
    required this.asistentesDomingo,
    required this.totalAsistentes,
    required this.semana,
    required this.mes,
    required this.ano,
  });

  Map<String, dynamic> toMap() {
    return {
      'tribuId': tribuId,
      'fecha': fecha,
      'asistentesViernes': asistentesViernes,
      'asistentesSabado': asistentesSabado,
      'asistentesDomingo': asistentesDomingo,
      'totalAsistentes': totalAsistentes,
      'semana': semana,
      'mes': mes,
      'año': ano,
    };
  }
}