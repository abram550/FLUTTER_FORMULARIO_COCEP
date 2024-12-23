import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import 'database_service.dart';
import 'firestore_service.dart';

class SyncService {
  final DatabaseService _databaseService = DatabaseService();
  final FirestoreService _firestoreService = FirestoreService();
  Timer? _syncTimer;
  StreamSubscription? _connectivitySubscription;
  bool _isInitialized = false;
  bool _isSyncing = false;

  // Método de inicialización
  Future<void> initialize() async {
    if (_isInitialized) return;
    print('Inicializando SyncService...');

    try {
      // Verificar conectividad al iniciar
      var connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult != ConnectivityResult.none) {
        await sincronizarDatos(); // Sincronización inicial si hay conexión
      }

      // Escuchar cambios en la conectividad para sincronizar automáticamente
      _connectivitySubscription = Connectivity().onConnectivityChanged.listen((result) async {
        if (result != ConnectivityResult.none) {
          await sincronizarDatos(); // Sincronizar cuando la conectividad vuelva
        }
      });

      // Sincronización periódica cada 15 minutos
      _syncTimer = Timer.periodic(const Duration(minutes: 15), (_) async {
        var connectivityResult = await Connectivity().checkConnectivity();
        if (connectivityResult != ConnectivityResult.none) {
          await sincronizarDatos(); // Sincronizar periódicamente si hay conexión
        }
      });

      _isInitialized = true;
    } catch (e) {
      print('Error en initialize de SyncService: $e');
      _isInitialized = false;
    }
  }

  // Método para sincronizar los registros con Firestore
  Future<void> sincronizarDatos() async {
    if (_isSyncing) return; // Si ya hay una sincronización en curso, evitarla.

    _isSyncing = true;
    print('Iniciando sincronización...');

    try {
      // Verificar conectividad antes de intentar sincronizar
      var connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        print('Sin conexión a Internet, sincronización cancelada');
        return; // Si no hay conexión, cancelar la sincronización
      }

      // Obtener los registros pendientes de la base de datos local
      final registrosPendientes = await _databaseService.obtenerRegistrosPendientes();
      print('Registros pendientes encontrados: ${registrosPendientes.length}');

      // Iterar sobre los registros pendientes y sincronizarlos con Firestore
      for (var registro in registrosPendientes) {
        try {
          print('Intentando sincronizar registro: ${registro.nombre}');
          final firestoreId = await _firestoreService.insertRegistro(registro);
          print('Registro sincronizado con Firestore ID: $firestoreId');

          // Marcar el registro como sincronizado en la base de datos local
          if (registro.id != null) {
            await _databaseService.marcarRegistroComoSincronizado(
              int.parse(registro.id!));
            print('Registro marcado como sincronizado en BD local');
          }
        } catch (e) {
          print('Error al sincronizar registro individual: $e');
          // Continuar con el siguiente registro en caso de error
          continue;
        }
      }
    } catch (e) {
      print('Error durante la sincronización: $e');
    } finally {
      _isSyncing = false; // Restablecer el estado de sincronización
    }
  }

  // Método para liberar recursos cuando se termine
  void dispose() {
    _syncTimer?.cancel();
    _connectivitySubscription?.cancel();
    _databaseService.cerrarBaseDeDatos();
  }
}
