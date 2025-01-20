import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../models/registro.dart';
import 'dart:io';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() => _instance;

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    await _initDatabase();
    return _database!;
  }

  Future<void> _initDatabase() async {
    try {
      final dbFolder = await getApplicationDocumentsDirectory();
      final dbPath = path.join(dbFolder.path, 'registros.db');

      await Directory(path.dirname(dbPath)).create(recursive: true);

      _database = await openDatabase(
        dbPath,
        version: 2, // Incrementamos la versión para forzar la actualización
        onCreate: (Database db, int version) async {
          await db.execute('''
            CREATE TABLE registros_pendientes (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              nombre TEXT NOT NULL,
              apellido TEXT NOT NULL,
              telefono TEXT NOT NULL,
              servicio TEXT NOT NULL,
              tipo TEXT,
              fecha TEXT NOT NULL,
              motivo TEXT,
              peticiones TEXT,
              consolidador TEXT,
              sexo TEXT NOT NULL,
              edad INTEGER NOT NULL,
              direccion TEXT NOT NULL,
              barrio TEXT NOT NULL,
              estadoCivil TEXT NOT NULL,
              nombrePareja TEXT,
              ocupaciones TEXT NOT NULL,
              descripcionOcupacion TEXT NOT NULL,
              tieneHijos INTEGER NOT NULL,
              referenciaInvitacion TEXT NOT NULL,
              observaciones TEXT,
              sincronizado INTEGER DEFAULT 0
            )
          ''');
        },
        onUpgrade: (Database db, int oldVersion, int newVersion) async {
          if (oldVersion < 2) {
            // Si existe la tabla anterior, la eliminamos
            await db.execute('DROP TABLE IF EXISTS registros_pendientes');

            // Creamos la nueva tabla con todas las columnas
            await db.execute('''
              CREATE TABLE registros_pendientes (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                nombre TEXT NOT NULL,
                apellido TEXT NOT NULL,
                telefono TEXT NOT NULL,
                servicio TEXT NOT NULL,
                tipo TEXT,
                fecha TEXT NOT NULL,
                motivo TEXT,
                peticiones TEXT,
                consolidador TEXT,
                sexo TEXT NOT NULL,
                edad INTEGER NOT NULL,
                direccion TEXT NOT NULL,
                barrio TEXT NOT NULL,
                estadoCivil TEXT NOT NULL,
                nombrePareja TEXT,
                ocupaciones TEXT NOT NULL,
                descripcionOcupacion TEXT NOT NULL,
                tieneHijos INTEGER NOT NULL,
                referenciaInvitacion TEXT NOT NULL,
                observaciones TEXT,
                sincronizado INTEGER DEFAULT 0
              )
            ''');
          }
        },
      );
    } catch (e) {
      print('Error al inicializar base de datos: $e');
      rethrow;
    }
  }

  Future<int> insertRegistroPendiente(Registro registro) async {
    try {
      final db = await database;
      final data = registro.toLocalMap(); // Usar el nuevo método
      data['sincronizado'] = 0;

      return await db.insert(
        'registros_pendientes',
        data,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      print('Error en insertRegistroPendiente: $e');
      rethrow;
    }
  }

  Future<List<Registro>> obtenerRegistrosPendientes() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'registros_pendientes',
        where: 'sincronizado = ?',
        whereArgs: [0],
      );

      print('Registros encontrados en BD local: ${maps.length}');

      return maps
          .map((map) {
            try {
              // Asegurarnos de que el map sea mutable
              final mutableMap = Map<String, dynamic>.from(map);
              final registro = Registro.fromLocalMap(mutableMap);
              print('Registro parseado correctamente: ${registro.nombre}');
              return registro;
            } catch (e) {
              print('Error al parsear registro individual: $e');
              return null;
            }
          })
          .whereType<Registro>()
          .toList();
    } catch (e) {
      print('Error en obtenerRegistrosPendientes: $e');
      return [];
    }
  }

  Future<void> marcarRegistroComoSincronizado(int id) async {
    try {
      final db = await database;
      await db.update(
        'registros_pendientes',
        {'sincronizado': 1},
        where: 'id = ?',
        whereArgs: [id],
      );
      // Eliminar inmediatamente después de marcar como sincronizado
      await eliminarRegistrosSincronizados();
    } catch (e) {
      print('Error en marcarRegistroComoSincronizado: $e');
    }
  }

  Future<void> eliminarRegistrosSincronizados() async {
    try {
      final db = await database;
      await db.delete(
        'registros_pendientes',
        where: 'sincronizado = ?',
        whereArgs: [1],
      );
    } catch (e) {
      print('Error al eliminar registros sincronizados: $e');
    }
  }

  Future<void> cerrarBaseDeDatos() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
