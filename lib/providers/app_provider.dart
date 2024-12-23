import 'package:flutter/material.dart';
import 'package:formulario_app/models/registro.dart';
import 'package:formulario_app/services/database_service.dart';
import 'package:formulario_app/services/firestore_service.dart';
import 'package:formulario_app/services/sync_service.dart';
import 'dart:async';

class AppProvider extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  final FirestoreService _firestoreService = FirestoreService();
  final SyncService _syncService = SyncService();

  bool _isInitialized = false;
  final bool _isLoading = false;

  Map<DateTime, List<Registro>> _registrosPorFecha = {};
  List<Map<String, String>> _consolidadores = [];

  bool get isLoading => _isLoading;
  Map<DateTime, List<Registro>> get registrosPorFecha => _registrosPorFecha;
  List<Map<String, String>> get consolidadores => _consolidadores;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Inicializa solo lo esencial para el arranque rápido
      await _syncService.initialize(); // Inicializa la sincronización básica.
      
      // Posterior a la carga inicial, configurar streams sin bloquear el arranque
      Future.microtask(() => _inicializarStreams());

      _isInitialized = true;
    } catch (e) {
      print('Error initializing AppProvider: $e');
    }
  }

  void _inicializarStreams() {
    _firestoreService.streamRegistros().listen((registros) {
      _registrosPorFecha = _agruparRegistrosPorFecha(registros);
      notifyListeners();
    });

    _firestoreService.streamConsolidadores().listen((consolidadores) {
      _consolidadores = consolidadores;
      notifyListeners();
    });
  }

  Map<DateTime, List<Registro>> _agruparRegistrosPorFecha(List<Registro> registros) {
    Map<DateTime, List<Registro>> agrupados = {};
    for (var registro in registros) {
      DateTime fechaSinHora = DateTime(registro.fecha.year, registro.fecha.month, registro.fecha.day);
      agrupados.putIfAbsent(fechaSinHora, () => []).add(registro);
    }
    return Map.fromEntries(
      agrupados.entries.toList()..sort((a, b) => b.key.compareTo(a.key)),
    );
  }

  @override
  void dispose() {
    _syncService.dispose();
    super.dispose();
  }
}
