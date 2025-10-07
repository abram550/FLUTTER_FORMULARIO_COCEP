import 'dart:math';
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:formulario_app/models/registro.dart';
import 'package:formulario_app/models/social_profile.dart';
import 'package:formulario_app/services/firestore_service.dart';
import 'package:formulario_app/services/excel_service.dart';
import 'package:intl/intl.dart';
import 'TribusScreen.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/gestures.dart';
// NUEVOS IMPORTS PARA DESCARGAR GRÁFICAS
import 'package:screenshot/screenshot.dart';
import 'package:universal_html/html.dart' as html;
import 'dart:ui' as ui;
import 'dart:typed_data';

class AdminPanel extends StatefulWidget {
  const AdminPanel({super.key});

  @override
  _AdminPanelState createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _nuevoConsolidadorController =
      TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  final ExcelService _excelService = ExcelService();
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Colores personalizados basados en el logo
  final Color primaryTeal = const Color(0xFF1C8C8C);
  final Color secondaryOrange = const Color(0xFFFF6B35);

// Variables de estado para el filtro
  late int _anioSeleccionado;
  late String _mesSeleccionado;
  bool _isSearching = false;
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  List<int> _aniosDisponibles = [];

  bool _cargando = false;
  Map<String, List<ChartData>> _datosFiltrados = {
    "consolidacion": [],
    "redes": [],
  };

  final Map<DateTime, List<Registro>> _registrosPorFecha = {};
  Map<int, Map<int, Map<DateTime, List<Registro>>>> _registrosPorAnioMesDia =
      {};

  Map<int, Map<int, Map<DateTime, List<Registro>>>> _registrosFiltrados = {};
  bool _mostrarFiltrados = false;

// Variables para las gráficas
  String _filtroSeleccionado = "mensual";
  String _tipoGrafica = "consolidacion";
  String _tipoVisualizacion =
      "barras"; // Para seleccionar entre barras, lineal o circular

  List<Map<String, String>> _consolidadores = [];

// Variables para el manejo de sesión - AGREGAR ESTAS LÍNEAS
  Timer? _inactivityTimer;
  static const Duration _inactivityDuration = Duration(minutes: 15);

  @override
  void initState() {
    super.initState();
    _loadData();
    _setupAnimations();
    final now = DateTime.now();
    _anioSeleccionado = now.year;
    _mesSeleccionado = _getMesNombre(now.month);
    _cargando = true;

    // AGREGAR ESTAS LÍNEAS PARA EL MANEJO DE SESIÓN
    _resetInactivityTimer();

    // Detectar interacciones del usuario
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        GestureBinding.instance.pointerRouter.addGlobalRoute((event) {
          if (mounted) {
            _resetInactivityTimer();
          }
        });
      }
    });
  }

  String _getMesNombre(int mesNumero) {
    const meses = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre'
    ];
    return meses[
        mesNumero - 1]; // Se resta 1 porque los meses en DateTime van de 1-12
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
    _animationController.forward();
  }

  @override
  void dispose() {
    _nuevoConsolidadorController.dispose();
    _searchController.dispose();
    _animationController.dispose();
    _inactivityTimer?.cancel();
    super.dispose();
  }

// Métodos para manejo de sesión - AGREGAR TODO ESTE BLOQUE
  void _resetInactivityTimer() {
    if (!mounted) return;

    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(_inactivityDuration, () {
      if (mounted) {
        _cerrarSesionPorInactividad();
      }
    });
  }

  Future<void> _cerrarSesionPorInactividad() async {
    if (!mounted) return;

    _inactivityTimer?.cancel();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(Icons.error_outline, color: Colors.white, size: 20),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Sesión expirada por inactividad',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(16),
        duration: Duration(seconds: 3),
      ),
    );

    await Future.delayed(Duration(milliseconds: 500));

    if (mounted) {
      context.go('/login');
    }
  }

  Future<void> _confirmarCerrarSesion() async {
    _resetInactivityTimer();

    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: secondaryOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.logout_rounded,
                color: secondaryOrange,
                size: 24,
              ),
            ),
            SizedBox(width: 12),
            Text(
              'Cerrar Sesión',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        content: Text(
          '¿Estás seguro que deseas cerrar sesión?',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              'Cancelar',
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 2,
            ),
            child: Text(
              'Cerrar Sesión',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _inactivityTimer?.cancel();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Container(
                padding: EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check, color: Colors.white, size: 20),
              ),
              SizedBox(width: 12),
              Text(
                'Cerrando sesión...',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          backgroundColor: primaryTeal,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: EdgeInsets.all(16),
        ),
      );

      await Future.delayed(Duration(milliseconds: 300));
      if (mounted) {
        context.go('/login');
      }
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Obtener los años desde los registros
      final registros = await _firestoreService.obtenerTodosLosRegistros();

      // ✅ Filtrar solo registros con fecha válida
      Set<int> aniosDisponibles = registros
          .where((r) => r.fecha != null)
          .map((r) => r.fecha.year)
          .toSet();

      if (aniosDisponibles.isNotEmpty) {
        setState(() {
          _aniosDisponibles = aniosDisponibles.toList()..sort();
          _anioSeleccionado = _aniosDisponibles.isNotEmpty
              ? _aniosDisponibles.last // Seleccionar el año más reciente
              : DateTime.now().year;
        });
      } else {
        print('⚠️ No se encontraron registros con fecha válida');
        setState(() {
          _aniosDisponibles = [DateTime.now().year];
          _anioSeleccionado = DateTime.now().year;
        });
      }

      _inicializarStreams();
    } catch (e) {
      _mostrarError('Error cargando datos: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _inicializarStreams() {
    _firestoreService.streamRegistros().listen(
      (registros) {
        if (mounted) {
          setState(() {
            _registrosPorAnioMesDia = _agruparRegistrosPorFecha(registros);
          });
        }
      },
      onError: (error) => _mostrarError('Error cargando registros: $error'),
    );

    _firestoreService.streamConsolidadores().listen(
      (consolidadores) {
        if (mounted) {
          setState(() {
            _consolidadores = consolidadores;
          });
        }
      },
      onError: (error) =>
          _mostrarError('Error cargando consolidadores: $error'),
    );
  }

  void _mostrarError(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Map<int, Map<int, Map<DateTime, List<Registro>>>> _agruparRegistrosPorFecha(
      List<Registro> registros) {
    Map<int, Map<int, Map<DateTime, List<Registro>>>> agrupados = {};

    for (var registro in registros) {
      // ✅ Validar que el registro tenga una fecha válida
      if (registro.fecha == null) {
        print(
            '⚠️ Registro sin fecha válida (ID: ${registro.id}) - ignorado en agrupación');
        continue;
      }

      final anio = registro.fecha.year;
      final mes = registro.fecha.month;
      final fechaSinHora = DateTime(anio, mes, registro.fecha.day);

      agrupados[anio] ??= {};
      agrupados[anio]![mes] ??= {};
      agrupados[anio]![mes]![fechaSinHora] ??= [];
      agrupados[anio]![mes]![fechaSinHora]!.add(registro);
    }

    return agrupados;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length:
          3, // Importante: asegurar que hay 3 tabs para mantener la lógica original
      child: Scaffold(
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _mostrarGrafica(context),
          backgroundColor: secondaryOrange,
          label:
              const Text('Estadísticas', style: TextStyle(color: Colors.white)),
          icon: const Icon(Icons.analytics, color: Colors.white),
          elevation: 4,
        ),
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          elevation: 0,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [primaryTeal, primaryTeal.withOpacity(0.8)],
              ),
            ),
          ),
          title: _isSearching
              ? TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: "Buscar por nombre o apellido...",
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: Colors.white70),
                  ),
                  style: const TextStyle(color: Colors.white),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                )
              : const Text(
                  'Panel de Administración',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 20,
                  ),
                ),
          actions: [
            IconButton(
              icon: Icon(_isSearching ? Icons.close : Icons.search,
                  color: Colors.white),
              onPressed: () {
                _resetInactivityTimer();
                setState(() {
                  if (_isSearching) {
                    _isSearching = false;
                    _searchController.clear();
                    _searchQuery = '';
                  } else {
                    _isSearching = true;
                  }
                });
              },
            ),
            // Botón de cerrar sesión mejorado
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: _confirmarCerrarSesion,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.logout_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Salir',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
          bottom: TabBar(
            indicatorColor: secondaryOrange,
            indicatorWeight: 4,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            tabs: [
              Tab(
                icon: Icon(Icons.assignment, color: secondaryOrange),
                text: 'Registros',
              ),
              Tab(
                icon: Icon(Icons.people, color: secondaryOrange),
                text: 'Consolidadores',
              ),
              Tab(
                icon: Icon(Icons.people_alt, color: secondaryOrange),
                text: 'Perfiles Sociales',
              ),
            ],
          ),
        ),
        body: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    primaryTeal.withOpacity(0.1),
                    Colors.white,
                  ],
                ),
              ),
              child: TabBarView(
                children: [
                  _buildRegistrosTab(),
                  _buildConsolidadoresTab(),
                  _buildPerfilesSocialesTab(),
                ],
              ),
            ),
            if (_isLoading)
              Container(
                color: Colors.black54,
                child: Center(
                  child: CircularProgressIndicator(
                    color: secondaryOrange,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _mostrarGrafica(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Obtener el tamaño de la pantalla
            final size = MediaQuery.of(context).size;
            final isSmallScreen = size.width < 600;
            final isMediumScreen = size.width >= 600 && size.width < 900;
            final isLargeScreen = size.width >= 900;

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                width: isSmallScreen
                    ? size.width * 0.95
                    : isMediumScreen
                        ? size.width * 0.85
                        : size.width * 0.75,
                constraints: BoxConstraints(
                  maxHeight: size.height * 0.92,
                  maxWidth: isLargeScreen ? 1200 : double.infinity,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Cabecera fija con botón de descarga - RESPONSIVA
                    Padding(
                      padding: EdgeInsets.all(isSmallScreen ? 12 : 20),
                      child: isSmallScreen
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.bar_chart,
                                        color: primaryTeal,
                                        size: isSmallScreen ? 24 : 28),
                                    SizedBox(width: isSmallScreen ? 8 : 10),
                                    Expanded(
                                      child: Text(
                                        "Estadísticas",
                                        style: TextStyle(
                                          fontSize: isSmallScreen ? 18 : 24,
                                          fontWeight: FontWeight.bold,
                                          color: primaryTeal,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon:
                                          Icon(Icons.close, color: primaryTeal),
                                      onPressed: () => Navigator.pop(context),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12),
                                // Botón de descarga en pantallas pequeñas
                                Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        secondaryOrange,
                                        secondaryOrange.withOpacity(0.8)
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: secondaryOrange.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(12),
                                      onTap: () => _descargarGrafica(setState),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 10),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.download_rounded,
                                                color: Colors.white, size: 20),
                                            const SizedBox(width: 6),
                                            Text(
                                              'Descargar',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Icon(Icons.bar_chart,
                                          color: primaryTeal, size: 28),
                                      const SizedBox(width: 10),
                                      Text(
                                        "Estadísticas",
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: primaryTeal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Botón de descarga en pantallas medianas/grandes
                                Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        secondaryOrange,
                                        secondaryOrange.withOpacity(0.8)
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: secondaryOrange.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(12),
                                      onTap: () => _descargarGrafica(setState),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 10),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.download_rounded,
                                                color: Colors.white, size: 20),
                                            const SizedBox(width: 6),
                                            Text(
                                              'Descargar',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.close, color: primaryTeal),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ],
                            ),
                    ),
                    const Divider(thickness: 1),

                    // Contenido con scroll - RESPONSIVO
                    Flexible(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 12 : 20,
                          vertical: isSmallScreen ? 8 : 0,
                        ),
                        child: Padding(
                          padding:
                              EdgeInsets.only(bottom: isSmallScreen ? 12 : 20),
                          child: Column(
                            children: [
                              SizedBox(height: isSmallScreen ? 10 : 15),

                              // Selección de tipo de datos - RESPONSIVA
                              Card(
                                elevation: 3,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Padding(
                                  padding:
                                      EdgeInsets.all(isSmallScreen ? 8 : 12),
                                  child: isSmallScreen
                                      ? Column(
                                          children: [
                                            _buildTipoGraficaButton(
                                              "Consolidación",
                                              "consolidacion",
                                              Icons.people_outline,
                                              setState,
                                            ),
                                            const SizedBox(height: 8),
                                            _buildTipoGraficaButton(
                                              "Redes Sociales",
                                              "redes",
                                              Icons.public,
                                              setState,
                                            ),
                                          ],
                                        )
                                      : Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          children: [
                                            Expanded(
                                              child: _buildTipoGraficaButton(
                                                "Consolidación",
                                                "consolidacion",
                                                Icons.people_outline,
                                                setState,
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: _buildTipoGraficaButton(
                                                "Redes Sociales",
                                                "redes",
                                                Icons.public,
                                                setState,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),

                              SizedBox(height: isSmallScreen ? 12 : 15),

                              // Selección de período - RESPONSIVA
                              Card(
                                elevation: 3,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Padding(
                                  padding:
                                      EdgeInsets.all(isSmallScreen ? 8 : 12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: EdgeInsets.only(
                                          left: 8.0,
                                          bottom: isSmallScreen ? 8 : 12,
                                        ),
                                        child: Text(
                                          "Período",
                                          style: TextStyle(
                                            fontSize: isSmallScreen ? 14 : 16,
                                            fontWeight: FontWeight.bold,
                                            color: primaryTeal,
                                          ),
                                        ),
                                      ),
                                      isSmallScreen
                                          ? Column(
                                              children: [
                                                _buildFiltroButton("Semanal",
                                                    "semanal", setState),
                                                const SizedBox(height: 8),
                                                _buildFiltroButton("Mensual",
                                                    "mensual", setState),
                                                const SizedBox(height: 8),
                                                _buildFiltroButton(
                                                    "Anual", "anual", setState),
                                              ],
                                            )
                                          : Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceEvenly,
                                              children: [
                                                _buildFiltroButton("Semanal",
                                                    "semanal", setState),
                                                _buildFiltroButton("Mensual",
                                                    "mensual", setState),
                                                _buildFiltroButton(
                                                    "Anual", "anual", setState),
                                              ],
                                            ),
                                    ],
                                  ),
                                ),
                              ),

                              SizedBox(height: isSmallScreen ? 12 : 15),

                              // Filtro por fecha
                              Card(
                                elevation: 3,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Padding(
                                  padding:
                                      EdgeInsets.all(isSmallScreen ? 10 : 12),
                                  child: _buildFiltroPorFecha(setState),
                                ),
                              ),

                              SizedBox(height: isSmallScreen ? 12 : 15),

                              // Selección de tipo de visualización - RESPONSIVA
                              Card(
                                elevation: 3,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Padding(
                                  padding:
                                      EdgeInsets.all(isSmallScreen ? 8 : 12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: EdgeInsets.only(
                                          left: 8.0,
                                          bottom: isSmallScreen ? 8 : 12,
                                        ),
                                        child: Text(
                                          "Tipo de gráfica",
                                          style: TextStyle(
                                            fontSize: isSmallScreen ? 14 : 16,
                                            fontWeight: FontWeight.bold,
                                            color: primaryTeal,
                                          ),
                                        ),
                                      ),
                                      isSmallScreen
                                          ? Column(
                                              children: [
                                                _buildVisualizacionButton(
                                                    "Barras",
                                                    "barras",
                                                    Icons.bar_chart,
                                                    setState),
                                                const SizedBox(height: 8),
                                                _buildVisualizacionButton(
                                                    "Línea",
                                                    "lineal",
                                                    Icons.show_chart,
                                                    setState),
                                                const SizedBox(height: 8),
                                                _buildVisualizacionButton(
                                                    "Circular",
                                                    "circular",
                                                    Icons.pie_chart,
                                                    setState),
                                              ],
                                            )
                                          : Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceEvenly,
                                              children: [
                                                _buildVisualizacionButton(
                                                    "Barras",
                                                    "barras",
                                                    Icons.bar_chart,
                                                    setState),
                                                _buildVisualizacionButton(
                                                    "Línea",
                                                    "lineal",
                                                    Icons.show_chart,
                                                    setState),
                                                _buildVisualizacionButton(
                                                    "Circular",
                                                    "circular",
                                                    Icons.pie_chart,
                                                    setState),
                                              ],
                                            ),
                                    ],
                                  ),
                                ),
                              ),

                              SizedBox(height: isSmallScreen ? 15 : 20),

                              // Gráfica con altura responsiva
                              SizedBox(
                                height: isSmallScreen
                                    ? 280
                                    : isMediumScreen
                                        ? 350
                                        : 400,
                                child: Card(
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: Padding(
                                    padding:
                                        EdgeInsets.all(isSmallScreen ? 10 : 15),
                                    child: _buildGrafica(setState),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFiltroButton(
      String titulo, String filtro, StateSetter setState) {
    bool isSelected = _filtroSeleccionado == filtro;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: ElevatedButton(
          onPressed: () {
            setState(() {
              _filtroSeleccionado = filtro;
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: isSelected ? secondaryOrange : Colors.grey[200],
            foregroundColor: isSelected ? Colors.white : Colors.black87,
            elevation: isSelected ? 4 : 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              titulo,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTipoGraficaButton(
      String titulo, String tipo, IconData icono, StateSetter setState) {
    bool isSelected = _tipoGrafica == tipo;

    return ElevatedButton.icon(
      onPressed: () {
        setState(() {
          _tipoGrafica = tipo;
        });
      },
      icon: Icon(
        icono,
        color: isSelected ? Colors.white : primaryTeal,
        size: 20,
      ),
      label: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          titulo,
          style: TextStyle(
            color: isSelected ? Colors.white : primaryTeal,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? primaryTeal : Colors.white,
        elevation: isSelected ? 4 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: primaryTeal,
            width: 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      ),
    );
  }

  Widget _buildVisualizacionButton(
      String titulo, String tipo, IconData icono, StateSetter setState) {
    bool isSelected = _tipoVisualizacion == tipo;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: ElevatedButton.icon(
          onPressed: () {
            setState(() {
              _tipoVisualizacion = tipo;
            });
          },
          icon: Icon(
            icono,
            color: isSelected ? Colors.white : Colors.black87,
            size: 18,
          ),
          label: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              titulo,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: isSelected ? secondaryOrange : Colors.grey[200],
            elevation: isSelected ? 4 : 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          ),
        ),
      ),
    );
  }

  Widget _buildGrafica(StateSetter setDialogState) {
    return FutureBuilder<Map<String, List<ChartData>>>(
      future: _obtenerDatosParaGrafica(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: secondaryOrange),
                const SizedBox(height: 8),
                Text(
                  "Cargando datos...",
                  style: TextStyle(
                    color: primaryTeal,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 32),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    "Error al cargar datos: ${snapshot.error}",
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                  ),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info_outline, color: primaryTeal, size: 32),
                const SizedBox(height: 6),
                Text(
                  "No hay datos disponibles",
                  style: TextStyle(
                    color: primaryTeal,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          );
        }

        final datos = snapshot.data!;
        final tipoActual = datos[_tipoGrafica] ?? [];

        return Screenshot(
          controller: _screenshotController,
          child: RepaintBoundary(
            key: _chartKey,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Título de la gráfica
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        "${_tipoGrafica == 'consolidacion' ? 'Consolidación' : 'Redes Sociales'} - ${_filtroSeleccionado.substring(0, 1).toUpperCase() + _filtroSeleccionado.substring(1)}",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: primaryTeal,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const Divider(thickness: 1),
                  const SizedBox(height: 5),

                  // Selector de tipo de visualización
                  if (!_isCapturing)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildVisualizationToggle('barras', Icons.bar_chart),
                          _buildVisualizationToggle('lineal', Icons.show_chart),
                          _buildVisualizationToggle(
                              'circular', Icons.pie_chart),
                        ],
                      ),
                    ),
                  if (!_isCapturing) const SizedBox(height: 5),

                  // Gráfica principal
                  Expanded(
                    child: _renderizarGrafica(tipoActual),
                  ),

                  // Leyenda
                  _buildLeyendaCompacta(tipoActual),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// ========== MÉTODO MEJORADO PARA DESCARGAR GRÁFICA EN ALTA RESOLUCIÓN ==========
  /// Este método crea una copia invisible de la gráfica en tamaño fijo (1600x900px)
  /// y la captura, asegurando que siempre se vea bien sin importar el tamaño de pantalla

  Future<void> _descargarGrafica(StateSetter setDialogState) async {
    OverlayEntry? overlayEntry;

    try {
      // Mostrar indicador de carga
      setDialogState(() {
        _isCapturing = true;
      });

      // Mostrar mensaje de progreso
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              const Text('Generando gráfica en alta resolución...'),
            ],
          ),
          backgroundColor: primaryTeal,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );

      // ✅ CAMBIO CRÍTICO: Usar los MISMOS datos que ya están filtrados y mostrados en pantalla
      // en lugar de volver a obtenerlos
      print('\n🔍 === DEBUG EXPORTACIÓN ===');
      print('📊 Obteniendo datos actuales de la gráfica visible...');

      // Obtener exactamente los mismos datos que se están mostrando en la gráfica actual
      final datosGrafica = await _obtenerDatosParaGrafica();
      final tipoActual = datosGrafica[_tipoGrafica] ?? [];

      print('📈 Total datos para exportar: ${tipoActual.length}');
      for (var data in tipoActual) {
        print('   - ${data.label}: ${data.value} registros');
      }
      print('=========================\n');

      if (tipoActual.isEmpty) {
        throw Exception('No hay datos para exportar');
      }

      // Crear un controlador de screenshot específico para la captura
      final screenshotController = ScreenshotController();
      final GlobalKey repaintKey = GlobalKey();

      // Crear una copia invisible de la gráfica en tamaño fijo
      overlayEntry = OverlayEntry(
        builder: (context) => Positioned(
          // Posicionar fuera de la vista pero renderizable
          left: -10000,
          top: -10000,
          child: Opacity(
            opacity: 0.01,
            child: IgnorePointer(
              child: MediaQuery(
                data: MediaQueryData(
                  size: Size(1600, 900),
                  devicePixelRatio: 1.0,
                  textScaleFactor: 1.0,
                ),
                child: Directionality(
                  textDirection: ui.TextDirection.ltr,
                  child: Material(
                    color: Colors.transparent,
                    child: Screenshot(
                      controller: screenshotController,
                      child: RepaintBoundary(
                        key: repaintKey,
                        child: Container(
                          width: 1600,
                          height: 900,
                          color: Colors.white,
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Encabezado de la gráfica
                              _buildExportHeader(tipoActual),

                              const SizedBox(height: 20),

                              // Contenedor de la gráfica con tamaño fijo
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: primaryTeal.withOpacity(0.2),
                                      width: 2,
                                    ),
                                  ),
                                  child: _buildExportChart(tipoActual),
                                ),
                              ),

                              const SizedBox(height: 20),

                              // Leyenda con mejor formato para exportación
                              _buildExportLegend(tipoActual),

                              const SizedBox(height: 16),

                              // Pie de página con información
                              _buildExportFooter(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      // Insertar el overlay en la pantalla
      Overlay.of(context).insert(overlayEntry);

      // Esperar a que se renderice completamente (2 frames)
      await Future.delayed(const Duration(milliseconds: 100));
      await WidgetsBinding.instance.endOfFrame;
      await Future.delayed(const Duration(milliseconds: 100));
      await WidgetsBinding.instance.endOfFrame;

      // Capturar la imagen en alta calidad
      final Uint8List? imageBytes = await screenshotController.capture(
        pixelRatio: 2.0,
      );

      // Remover el overlay
      overlayEntry.remove();
      overlayEntry = null;

      if (imageBytes == null) {
        throw Exception('No se pudo capturar la imagen');
      }

      // Generar nombre descriptivo del archivo
      final String tipoGraficaTexto =
          _tipoGrafica == 'consolidacion' ? 'Consolidacion' : 'Redes_Sociales';
      final String periodoTexto =
          _filtroSeleccionado.substring(0, 1).toUpperCase() +
              _filtroSeleccionado.substring(1);
      final String visualizacionTexto =
          _tipoVisualizacion.substring(0, 1).toUpperCase() +
              _tipoVisualizacion.substring(1);
      final String anio =
          _anioSeleccionado != -1 ? _anioSeleccionado.toString() : 'Todos';
      final String mes = _mesSeleccionado != "Todos los meses"
          ? _mesSeleccionado.substring(0, 3)
          : 'Todos';
      final String fecha =
          DateFormat('dd-MM-yyyy_HH-mm').format(DateTime.now());

      final String nombreArchivo =
          'Grafica_${tipoGraficaTexto}_${periodoTexto}_${visualizacionTexto}_${anio}_${mes}_$fecha.png';

      // Crear blob y descargar (solo para web)
      final blob = html.Blob([imageBytes], 'image/png');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', nombreArchivo)
        ..click();

      // Limpiar URL
      html.Url.revokeObjectUrl(url);

      // Ocultar indicador de carga
      setDialogState(() {
        _isCapturing = false;
      });

      // Mostrar mensaje de éxito
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child:
                      Icon(Icons.check_circle, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '✓ Gráfica descargada exitosamente',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        nombreArchivo,
                        style: TextStyle(fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green[600],
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e, stackTrace) {
      // Limpiar overlay si existe
      overlayEntry?.remove();

      // Ocultar indicador de carga
      setDialogState(() {
        _isCapturing = false;
      });

      // Log del error para debugging
      print('❌ Error al descargar gráfica: $e');
      print('Stack trace: $stackTrace');

      // Mostrar error al usuario
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Error al descargar gráfica',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'Por favor, intenta nuevamente',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red[600],
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Reintentar',
              textColor: Colors.white,
              onPressed: () => _descargarGrafica(setDialogState),
            ),
          ),
        );
      }
    }
  }

  /// ========== MÉTODOS AUXILIARES PARA CONSTRUIR LA GRÁFICA DE EXPORTACIÓN ==========

  /// Construye el encabezado para la gráfica exportada
  Widget _buildExportHeader(List<ChartData> datos) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryTeal, primaryTeal.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: primaryTeal.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _tipoVisualizacion == 'barras'
                  ? Icons.bar_chart
                  : _tipoVisualizacion == 'lineal'
                      ? Icons.show_chart
                      : Icons.pie_chart,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _tipoGrafica == 'consolidacion'
                      ? 'Estadísticas de Consolidación'
                      : 'Estadísticas de Redes Sociales',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Período: ${_filtroSeleccionado.substring(0, 1).toUpperCase() + _filtroSeleccionado.substring(1)} | '
                  'Año: ${_anioSeleccionado != -1 ? _anioSeleccionado : "Todos"} | '
                  'Mes: $_mesSeleccionado',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: secondaryOrange,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ),
    );
  }

  /// Construye la gráfica optimizada para exportación
  Widget _buildExportChart(List<ChartData> datos) {
    if (datos.isEmpty) {
      return Center(
        child: Text(
          'No hay datos disponibles',
          style: TextStyle(
            fontSize: 24,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    // Renderizar según el tipo de visualización seleccionado
    switch (_tipoVisualizacion) {
      case 'barras':
        return _buildExportBarChart(datos);
      case 'lineal':
        return _buildExportLineChart(datos);
      case 'circular':
        return _buildExportPieChart(datos);
      default:
        return _buildExportBarChart(datos);
    }
  }

  /// Gráfica de barras optimizada para exportación
  Widget _buildExportBarChart(List<ChartData> datos) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: _calcularMaxY(datos) * 1.2,
        barGroups: datos.asMap().entries.map((entry) {
          int x = entry.key;
          ChartData data = entry.value;
          return BarChartGroupData(
            x: x,
            barRods: [
              BarChartRodData(
                toY: data.value.toDouble(),
                color: data.color,
                width: 28, // Barras más anchas para exportación
                borderRadius: BorderRadius.circular(8),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: _calcularMaxY(datos) * 1.1,
                  color: Colors.grey.withOpacity(0.1),
                ),
              ),
            ],
            showingTooltipIndicators: [0],
          );
        }).toList(),
        titlesData: FlTitlesData(
          show: true,
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 60,
              interval: _calcularIntervaloY(datos),
              getTitlesWidget: (value, meta) => Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Text(
                  value.toInt().toString(),
                  style: const TextStyle(
                    fontSize: 16, // Texto más grande
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 80,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < datos.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: Transform.rotate(
                      angle: -pi / 4,
                      child: Text(
                        datos[value.toInt()].label,
                        style: const TextStyle(
                          fontSize: 14, // Texto más grande
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: _calcularIntervaloY(datos),
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.withOpacity(0.3),
              strokeWidth: 1,
              dashArray: [8, 4],
            );
          },
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(
            bottom: BorderSide(color: Colors.grey.withOpacity(0.5), width: 2),
            left: BorderSide(color: Colors.grey.withOpacity(0.5), width: 2),
          ),
        ),
        barTouchData: BarTouchData(enabled: false),
      ),
    );
  }

  /// Gráfica lineal optimizada para exportación
  Widget _buildExportLineChart(List<ChartData> datos) {
    return LineChart(
      LineChartData(
        lineTouchData: LineTouchData(enabled: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: _calcularIntervaloY(datos),
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.withOpacity(0.3),
              strokeWidth: 1,
              dashArray: [8, 4],
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              interval: 1,
              getTitlesWidget: (value, meta) {
                if (value < 0 || value >= datos.length) return const Text('');
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  space: 8,
                  child: Text(
                    datos[value.toInt()].label,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 60,
              interval: _calcularIntervaloY(datos),
              getTitlesWidget: (value, meta) {
                if (value % 1 == 0) {
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    space: 8,
                    child: Text(
                      value.toInt().toString(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(
            bottom: BorderSide(color: Colors.grey.withOpacity(0.5), width: 2),
            left: BorderSide(color: Colors.grey.withOpacity(0.5), width: 2),
          ),
        ),
        minX: 0,
        maxX: datos.length - 1.0,
        minY: 0,
        maxY: _calcularMaxY(datos) * 1.2,
        lineBarsData: [
          LineChartBarData(
            spots: datos.asMap().entries.map((entry) {
              return FlSpot(entry.key.toDouble(), entry.value.value.toDouble());
            }).toList(),
            isCurved: true,
            color: primaryTeal,
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 6,
                  color: secondaryOrange,
                  strokeWidth: 3.0,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  primaryTeal.withOpacity(0.4),
                  primaryTeal.withOpacity(0.1),
                  primaryTeal.withOpacity(0.0),
                ],
                stops: [0, 0.7, 1.0],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Gráfica circular optimizada para exportación
  Widget _buildExportPieChart(List<ChartData> datos) {
    final total = _calcularTotal(datos);

    return PieChart(
      PieChartData(
        pieTouchData: PieTouchData(enabled: false),
        sections: datos.asMap().entries.map((entry) {
          final index = entry.key;
          final data = entry.value;
          final porcentaje = (data.value / total) * 100;

          return PieChartSectionData(
            color: data.color,
            value: data.value.toDouble(),
            title: '${porcentaje.toStringAsFixed(1)}%',
            radius: 180, // Radio más grande para exportación
            titleStyle: TextStyle(
              fontSize: 18, // Texto más grande
              fontWeight: FontWeight.bold,
              color: _esColorOscuro(data.color) ? Colors.white : Colors.black87,
              shadows: [
                Shadow(
                  color: Colors.black26,
                  offset: const Offset(0, 2),
                  blurRadius: 3,
                ),
              ],
            ),
            badgeWidget: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    data.label,
                    style: TextStyle(
                      color: data.color,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    data.value.toString(),
                    style: TextStyle(
                      color: Colors.grey.shade800,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            badgePositionPercentageOffset: 1.3,
          );
        }).toList(),
        sectionsSpace: 2,
        centerSpaceRadius: 60,
        centerSpaceColor: Colors.white,
      ),
    );
  }

  /// Construye la leyenda optimizada para exportación
  Widget _buildExportLegend(List<ChartData> datos) {
    if (datos.isEmpty) return const SizedBox();

    final total =
        _tipoVisualizacion == "circular" ? _calcularTotal(datos) : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.legend_toggle, color: primaryTeal, size: 24),
              const SizedBox(width: 8),
              Text(
                'Leyenda',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: primaryTeal,
                ),
              ),
              if (_tipoVisualizacion == "circular") ...[
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: secondaryOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: secondaryOrange),
                  ),
                  child: Text(
                    "Total: ${total.toInt()} registros",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: secondaryOrange,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 20,
            runSpacing: 12,
            children: datos.map((data) {
              final porcentaje = _tipoVisualizacion == "circular"
                  ? ((data.value / total) * 100).toStringAsFixed(1)
                  : null;

              return Container(
                constraints: const BoxConstraints(minWidth: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: data.color.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: data.color,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: data.color.withOpacity(0.4),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        data.label,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: data.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        porcentaje != null
                            ? '${data.value} ($porcentaje%)'
                            : data.value.toString(),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: data.color,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// Construye el pie de página con información adicional
  Widget _buildExportFooter() {
    final now = DateTime.now();
    final fechaFormateada = DateFormat('dd/MM/yyyy HH:mm').format(now);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_today, color: Colors.grey[600], size: 18),
              const SizedBox(width: 8),
              Text(
                'Generado: $fechaFormateada',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Icon(Icons.church, color: primaryTeal, size: 20),
              const SizedBox(width: 8),
              Text(
                'Panel de Administración',
                style: TextStyle(
                  fontSize: 14,
                  color: primaryTeal,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

// Widget para cambiar tipo de visualización de forma interactiva
  Widget _buildVisualizationToggle(String tipo, IconData icono) {
    bool isSelected = _tipoVisualizacion == tipo;
    return GestureDetector(
      onTap: () {
        setState(() {
          _tipoVisualizacion = tipo;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? primaryTeal : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryTeal.withOpacity(0.4),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icono,
              size: 16,
              color: isSelected ? Colors.white : Colors.grey.shade700,
            ),
            if (isSelected) const SizedBox(width: 4),
            if (isSelected)
              Text(
                tipo[0].toUpperCase() + tipo.substring(1),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _renderizarGrafica(List<ChartData> datos) {
    if (datos.isEmpty) {
      return Center(
          child: Text("No hay datos disponibles",
              style: TextStyle(color: primaryTeal, fontSize: 13)));
    }

    // Obtener el tamaño de la pantalla para ajustar la gráfica
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;

    // Contenedor con dimensiones apropiadas y padding reducido
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 4 : 8),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: animation,
              child: child,
            ),
          );
        },
        child: _getChartByType(datos),
      ),
    );
  }

  Widget _getChartByType(List<ChartData> datos) {
    switch (_tipoVisualizacion) {
      case "barras":
        return _buildBarChart(datos);
      case "lineal":
        return _buildLineChart(datos);
      case "circular":
        return _buildPieChart(datos);
      default:
        return _buildBarChart(datos);
    }
  }

// Funciones auxiliares para cálculos - mantenidas del primer código
  double _calcularMaxY(List<ChartData> data) {
    double maxY = 0;
    for (var item in data) {
      if (item.value > maxY) maxY = item.value.toDouble();
    }
    return maxY == 0 ? 10 : maxY * 1.1; // Añadir 10% de espacio extra
  }

  double _calcularIntervaloY(List<ChartData> data) {
    double maxY = _calcularMaxY(data);

    // Calcular un intervalo apropiado basado en el valor máximo
    if (maxY <= 10) return 1;
    if (maxY <= 50) return 5;
    if (maxY <= 100) return 10;
    if (maxY <= 500) return 50;
    if (maxY <= 1000) return 100;
    if (maxY <= 5000) return 500;
    if (maxY <= 10000) return 1000;

    // Para valores muy grandes
    return maxY / 10;
  }

  double _calcularTotal(List<ChartData> data) {
    double total = 0;
    for (var item in data) {
      total += item.value;
    }
    return total;
  }

// Variable para seguimiento de sección seleccionada en gráfica circular
  int _pieChartIndex = -1;
  // Variables para guardar el estado de interactividad
  int _barTouchedIndex = -1;
  int _lineSpotTouched = -1;

// ============ NUEVAS VARIABLES PARA CAPTURA DE GRÁFICAS ============
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isCapturing = false;
  GlobalKey _chartKey = GlobalKey();
// ===================================================================

// Función auxiliar para acortar etiquetas largas
  String _acortarEtiqueta(String etiqueta, int maxLength) {
    if (etiqueta.length <= maxLength) return etiqueta;

    if (_filtroSeleccionado == "semanal") {
      return "Sem. ${etiqueta.substring(7, 8)}";
    } else if (_filtroSeleccionado == "mensual") {
      final partes = etiqueta.split(' ');
      if (partes.isNotEmpty) {
        return "${partes[0].substring(0, min(3, partes[0].length))}.";
      }
    }

    return "${etiqueta.substring(0, maxLength)}...";
  }

// Función para determinar si un color es oscuro (para contrastes de texto)
  bool _esColorOscuro(Color color) {
    // Fórmula YIQ para determinar luminosidad
    return ((color.red * 299) + (color.green * 587) + (color.blue * 114)) /
            1000 <
        128;
  }
// Variable para seguimiento de sección seleccionada en gráfica circular

  Widget _buildBarChart(List<ChartData> datos) {
    return Container(
      padding: const EdgeInsets.all(8),
      height: 350,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: _calcularMaxY(datos) * 1.2,
          barGroups: datos.asMap().entries.map((entry) {
            int x = entry.key;
            ChartData data = entry.value;
            return BarChartGroupData(
              x: x,
              barRods: [
                BarChartRodData(
                  toY: data.value.toDouble(),
                  color: data.color,
                  width: 18,
                  borderRadius: BorderRadius.circular(8),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: _calcularMaxY(datos) * 1.1,
                    color: Colors.grey.withOpacity(0.1),
                  ),
                ),
              ],
            );
          }).toList(),
          titlesData: FlTitlesData(
            show: true,
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: _calcularIntervaloY(datos),
                getTitlesWidget: (value, meta) => Padding(
                  padding: const EdgeInsets.only(right: 6.0),
                  child: Text(
                    value.toInt().toString(),
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 50,
                getTitlesWidget: (value, meta) => Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Transform.rotate(
                    angle: -pi / 4,
                    child: Text(
                      _acortarEtiqueta(datos[value.toInt()].label, 12),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: _calcularIntervaloY(datos),
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey.withOpacity(0.2),
                strokeWidth: 0.8,
                dashArray: [4, 4],
              );
            },
          ),
          borderData: FlBorderData(
            show: true,
            border: Border(
              bottom:
                  BorderSide(color: Colors.grey.withOpacity(0.5), width: 0.8),
              left: BorderSide(color: Colors.grey.withOpacity(0.5), width: 0.8),
            ),
          ),
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              tooltipBgColor: Colors.blueGrey.shade800,
              tooltipPadding: const EdgeInsets.all(8),
              tooltipMargin: 6,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${datos[group.x].label}\n',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  children: [
                    TextSpan(
                      text: '${rod.toY.toInt()} valores',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                );
              },
            ),
            // Efecto al tocar una barra con animación
            touchCallback: (FlTouchEvent event, barTouchResponse) {
              if (event is FlTapUpEvent &&
                  barTouchResponse != null &&
                  barTouchResponse.spot != null) {
                final touchedIndex =
                    barTouchResponse.spot!.touchedBarGroupIndex;

                // Animación al tocar
                setState(() {
                  // Activar efecto visual o mostrar información detallada
                  _barTouchedIndex = touchedIndex;
                });

                // Después de 1 segundo, resetear
                Future.delayed(const Duration(seconds: 1), () {
                  setState(() {
                    _barTouchedIndex = -1;
                  });
                });
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLineChart(List<ChartData> datos) {
    return Container(
      padding: const EdgeInsets.all(8),
      height: 350,
      child: LineChart(
        LineChartData(
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              tooltipBgColor: Colors.blueGrey.shade800,
              tooltipPadding: const EdgeInsets.all(8),
              tooltipMargin: 6,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((touchedSpot) {
                  final spotIndex = touchedSpot.spotIndex;
                  return LineTooltipItem(
                    '${datos[spotIndex].label}\n',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    children: [
                      TextSpan(
                        text: '${touchedSpot.y.toInt()} valores',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  );
                }).toList();
              },
            ),
            // Añadir animación al tocar puntos
            touchCallback: (FlTouchEvent event, lineTouch) {
              if (event is FlTapUpEvent &&
                  lineTouch != null &&
                  lineTouch.lineBarSpots != null &&
                  lineTouch.lineBarSpots!.isNotEmpty) {
                setState(() {
                  _lineSpotTouched = lineTouch.lineBarSpots![0].spotIndex;
                });

                // Después de 1 segundo, resetear
                Future.delayed(const Duration(seconds: 1), () {
                  setState(() {
                    _lineSpotTouched = -1;
                  });
                });
              }
            },
            handleBuiltInTouches: true,
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: _calcularIntervaloY(datos),
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey.withOpacity(0.2),
                strokeWidth: 0.8,
                dashArray: [4, 4],
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 25,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  if (value < 0 || value >= datos.length) return const Text('');
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    space: 6,
                    child: Text(
                      _acortarEtiqueta(datos[value.toInt()].label, 8),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 9,
                        color: Colors.black87,
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: _calcularIntervaloY(datos),
                getTitlesWidget: (value, meta) {
                  if (value % 1 == 0) {
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      space: 6,
                      child: Text(
                        value.toInt().toString(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border(
              bottom:
                  BorderSide(color: Colors.grey.withOpacity(0.5), width: 0.8),
              left: BorderSide(color: Colors.grey.withOpacity(0.5), width: 0.8),
            ),
          ),
          minX: 0,
          maxX: datos.length - 1.0,
          minY: 0,
          maxY: _calcularMaxY(datos) * 1.2,
          lineBarsData: [
            LineChartBarData(
              spots: datos.asMap().entries.map((entry) {
                return FlSpot(
                    entry.key.toDouble(), entry.value.value.toDouble());
              }).toList(),
              isCurved: true,
              color: primaryTeal,
              barWidth: 3.5,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  // Puntos destacados cuando son tocados
                  final bool isSelected = index == _lineSpotTouched;
                  return FlDotCirclePainter(
                    radius: isSelected ? 8 : 5,
                    color: isSelected
                        ? secondaryOrange.withOpacity(0.8)
                        : secondaryOrange,
                    strokeWidth: isSelected ? 3.0 : 2.0,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    primaryTeal.withOpacity(0.3),
                    primaryTeal.withOpacity(0.1),
                    primaryTeal.withOpacity(0.0),
                  ],
                  stops: [0, 0.7, 1.0],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart(List<ChartData> datos) {
    // Calcular el total para obtener porcentajes
    final total = _calcularTotal(datos);

    return Container(
      padding: const EdgeInsets.all(4),
      height: 300,
      child: PieChart(
        PieChartData(
          pieTouchData: PieTouchData(
            touchCallback: (FlTouchEvent event, pieTouchResponse) {
              if (event is FlTapUpEvent &&
                  pieTouchResponse != null &&
                  pieTouchResponse.touchedSection != null) {
                final index =
                    pieTouchResponse.touchedSection!.touchedSectionIndex;

                // Actualizar el estado para mostrar la sección seleccionada con animación
                setState(() {
                  if (_pieChartIndex == index) {
                    _pieChartIndex = -1; // Desactivar si ya estaba seleccionado
                  } else {
                    _pieChartIndex = index; // Activar
                  }
                });
              }
            },
          ),
          sections: datos.asMap().entries.map((entry) {
            final index = entry.key;
            final data = entry.value;
            final porcentaje = (data.value / total) * 100;
            final bool isSelected = index == _pieChartIndex;

            return PieChartSectionData(
              color: data.color,
              value: data.value.toDouble(),
              title: '${porcentaje.toStringAsFixed(1)}%',
              radius: isSelected ? 130 : 110,
              titleStyle: TextStyle(
                fontSize: isSelected ? 16 : 12,
                fontWeight: FontWeight.bold,
                color:
                    _esColorOscuro(data.color) ? Colors.white : Colors.black87,
                shadows: [
                  Shadow(
                    color: Colors.black26,
                    offset: const Offset(0, 1),
                    blurRadius: 2,
                  ),
                ],
              ),
              badgeWidget: isSelected ? _buildBadge(data) : null,
              badgePositionPercentageOffset: 1.05,
            );
          }).toList(),
          sectionsSpace: 1.5,
          centerSpaceRadius: 30,
          centerSpaceColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildBadge(ChartData data) {
    return Container(
      padding: const EdgeInsets.all(6), // Reducido de 8 a 6
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 0.5, // Reducido
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            data.label,
            style: TextStyle(
              color: data.color,
              fontWeight: FontWeight.bold,
              fontSize: 12, // Reducido de 14 a 12
            ),
          ),
          Text(
            data.value.toString(),
            style: TextStyle(
              color: Colors.grey.shade800,
              fontSize: 11, // Tamaño pequeño
            ),
          ),
        ],
      ),
    );
  }

// Versión más compacta de la leyenda
  Widget _buildLeyendaCompacta(List<ChartData> datos) {
    if (datos.isEmpty) return const SizedBox();

    // Para gráficas circulares, mostrar el total
    double total = 0;
    if (_tipoVisualizacion == "circular") {
      total = _calcularTotal(datos);
    }

    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // Reducido
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // Ajustar al contenido
        children: [
          if (_tipoVisualizacion == "circular")
            Padding(
              padding: const EdgeInsets.only(bottom: 4.0), // Reducido de 8 a 4
              child: Text(
                "Total: ${total.toInt()} valores",
                style: TextStyle(
                  fontSize: 14, // Reducido de 16 a 14
                  fontWeight: FontWeight.bold,
                  color: primaryTeal,
                ),
              ),
            ),
          // Leyenda en forma de Wrap más compacta
          Wrap(
            spacing: 8, // Reducido de 12 a 8
            runSpacing: 4, // Reducido de 8 a 4
            children: datos.map((data) {
              return Container(
                margin: const EdgeInsets.only(right: 4, bottom: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10, // Reducido de 14 a 10
                      height: 10, // Reducido de 14 a 10
                      decoration: BoxDecoration(
                        color: data.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4), // Reducido de 6 a 4
                    Text(
                      data.label,
                      style: const TextStyle(
                        fontSize: 10, // Reducido de 12 a 10
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

// Variables para guardar el estado de interactividad

  Widget _buildLeyenda(List<ChartData> datos) {
    if (datos.isEmpty) return const SizedBox();

    // Para gráficas circulares, mostrar el total
    double total = 0;
    if (_tipoVisualizacion == "circular") {
      total = _calcularTotal(datos);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_tipoVisualizacion == "circular")
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                "Total: ${total.toInt()} valores",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: primaryTeal,
                ),
              ),
            ),
          // Título de la leyenda
          Text(
            "Leyenda:",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 4),
          // Leyenda en forma de Wrap para adaptarse a diferentes anchos
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: datos.map((data) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: data.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    data.label,
                    style: const TextStyle(
                      fontSize: 12,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

// Función para crear un widget principal de gráfica
  Widget _buildChartWidget(String titulo, Widget chart, List<ChartData> datos) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: Text(
                titulo,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[800],
                ),
              ),
            ),
            const Divider(),
            const SizedBox(height: 8),
            chart,
            const SizedBox(height: 8),
            _buildLeyenda(datos),
          ],
        ),
      ),
    );
  }

  Future<Map<String, List<ChartData>>> _obtenerDatosParaGrafica() async {
    Map<String, List<ChartData>> resultados = {};

    try {
      // Colores a utilizar para las gráficas
      List<Color> consolidacionColors = [
        primaryTeal,
        secondaryOrange,
        Colors.purple,
        Colors.green,
        Colors.amber,
        Colors.red,
        Colors.blue,
        Colors.indigo,
        Colors.deepOrange,
        Colors.teal,
        Colors.pink,
        Colors.cyan,
      ];

      List<Color> redesColors =
          consolidacionColors.map((c) => c.withOpacity(0.7)).toList();

      print('\n🔍 === INICIO DEBUG OBTENER DATOS PARA GRÁFICA ===');
      print('📅 Filtro seleccionado: $_filtroSeleccionado');
      print('📆 Año: $_anioSeleccionado');
      print('📆 Mes: $_mesSeleccionado');

      // Obtener datos de consolidación
      print('\n📊 Obteniendo documentos de CONSOLIDACIÓN (registros)...');
      List<QueryDocumentSnapshot> consolidacionDocs =
          await _obtenerDocumentosFiltrados(
              "registros", _anioSeleccionado, _mesSeleccionado);

      print(
          '✅ Total docs consolidación obtenidos: ${consolidacionDocs.length}');

      // DEBUG: Mostrar cada documento de consolidación
      for (var doc in consolidacionDocs) {
        final data = doc.data() as Map<String, dynamic>?;
        final nombre = data?['nombre'] ?? 'Sin nombre';
        final apellido = data?['apellido'] ?? '';

        // Mostrar TODOS los campos de fecha que tiene el documento
        print('\n  📄 Documento ID: ${doc.id}');
        print('     Nombre: $nombre $apellido');
        print('     Campos de fecha disponibles:');

        if (data?.containsKey('fecha') == true) {
          final fecha = data!['fecha'];
          if (fecha is Timestamp) {
            print(
                '       ✓ fecha: ${DateFormat('dd/MM/yyyy HH:mm:ss').format(fecha.toDate())}');
          } else {
            print('       ✓ fecha: $fecha (tipo: ${fecha.runtimeType})');
          }
        } else {
          print('       ✗ fecha: NO EXISTE');
        }

        if (data?.containsKey('fechaRegistro') == true) {
          final fechaReg = data!['fechaRegistro'];
          if (fechaReg is Timestamp) {
            print(
                '       ✓ fechaRegistro: ${DateFormat('dd/MM/yyyy HH:mm:ss').format(fechaReg.toDate())}');
          } else {
            print(
                '       ✓ fechaRegistro: $fechaReg (tipo: ${fechaReg.runtimeType})');
          }
        } else {
          print('       ✗ fechaRegistro: NO EXISTE');
        }

        if (data?.containsKey('createdAt') == true) {
          final created = data!['createdAt'];
          if (created is Timestamp) {
            print(
                '       ✓ createdAt: ${DateFormat('dd/MM/yyyy HH:mm:ss').format(created.toDate())}');
          } else {
            print(
                '       ✓ createdAt: $created (tipo: ${created.runtimeType})');
          }
        } else {
          print('       ✗ createdAt: NO EXISTE');
        }

        if (data?.containsKey('fechaAsignacion') == true) {
          final fechaAsig = data!['fechaAsignacion'];
          if (fechaAsig is Timestamp) {
            print(
                '       ⚠ fechaAsignacion: ${DateFormat('dd/MM/yyyy HH:mm:ss').format(fechaAsig.toDate())}');
          }
        }

        if (data?.containsKey('fechaAsignacionTribu') == true) {
          final fechaAsigTribu = data!['fechaAsignacionTribu'];
          if (fechaAsigTribu is Timestamp) {
            print(
                '       ⚠ fechaAsignacionTribu: ${DateFormat('dd/MM/yyyy HH:mm:ss').format(fechaAsigTribu.toDate())}');
          }
        }

        if (data?.containsKey('ultimaAsistencia') == true) {
          final ultAsist = data!['ultimaAsistencia'];
          if (ultAsist is Timestamp) {
            print(
                '       ⚠ ultimaAsistencia: ${DateFormat('dd/MM/yyyy HH:mm:ss').format(ultAsist.toDate())}');
          }
        }

        // Mostrar qué fecha se está usando finalmente
        final fechaUsada = _convertirFecha(data);
        if (fechaUsada != null) {
          print(
              '       ➡️ FECHA USADA PARA GRÁFICA: ${DateFormat('dd/MM/yyyy').format(fechaUsada)}');
        } else {
          print('       ❌ SIN FECHA VÁLIDA - REGISTRO SERÁ IGNORADO');
        }
      }

      // Obtener datos de redes sociales
      print(
          '\n📊 Obteniendo documentos de REDES SOCIALES (social_profiles)...');
      List<QueryDocumentSnapshot> redesDocs = await _obtenerDocumentosFiltrados(
          "social_profiles", _anioSeleccionado, _mesSeleccionado);

      print('✅ Total docs redes sociales obtenidos: ${redesDocs.length}');

      // Procesar los datos según el filtro seleccionado
      print('\n🔄 Procesando datos por período...');
      List<ChartData> consolidacion =
          _procesarDatosPorPeriodo(consolidacionDocs, consolidacionColors);

      print(
          '📈 Datos de consolidación procesados: ${consolidacion.length} puntos');
      for (var data in consolidacion) {
        print('   - ${data.label}: ${data.value} registros');
      }

      List<ChartData> redes = _procesarDatosPorPeriodo(redesDocs, redesColors);

      print('📈 Datos de redes procesados: ${redes.length} puntos');
      print('\n🏁 === FIN DEBUG OBTENER DATOS PARA GRÁFICA ===\n');

      return {
        "consolidacion": consolidacion,
        "redes": redes,
      };
    } catch (e) {
      print("❌ Error al obtener datos para gráfica: $e");
      return {
        "consolidacion": [],
        "redes": [],
      };
    }
  }

  Future<List<QueryDocumentSnapshot>> _obtenerDocumentosFiltrados(
      String coleccion, int anioFiltro, String mesFiltro) async {
    try {
      final snapshot = await _firestore.collection(coleccion).get();
      final int mesIndex = _getMonthIndex(mesFiltro);

      // DEBUG: Imprimir total de documentos obtenidos
      print('📊 Total documentos en "$coleccion": ${snapshot.docs.length}');

      List<QueryDocumentSnapshot> resultados = snapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>?;

        // Usar el método _convertirFecha que ahora puede retornar null
        final fecha = _convertirFecha(data);

        // ✅ IGNORAR registros sin campo 'fecha'
        if (fecha == null) {
          print('  ❌ Doc ID: ${doc.id} - Sin campo "fecha" válido, ignorado');
          return false;
        }

        // DEBUG: Imprimir cada documento procesado
        print('  - Doc ID: ${doc.id}');
        print('    Fecha procesada: ${DateFormat('dd/MM/yyyy').format(fecha)}');
        print('    Año: ${fecha.year}, Mes: ${fecha.month}');

        if (_filtroSeleccionado == "anual") {
          if (anioFiltro == -1) {
            print('    ✅ Incluido (Todos los años)');
            return true;
          } else {
            bool incluir = fecha.year == anioFiltro;
            print(
                '    ${incluir ? "✅" : "❌"} ${incluir ? "Incluido" : "Excluido"} (año: $anioFiltro)');
            return incluir;
          }
        } else if (mesFiltro == "Todos los meses") {
          bool incluir = fecha.year == anioFiltro;
          print(
              '    ${incluir ? "✅" : "❌"} ${incluir ? "Incluido" : "Excluido"} (año: $anioFiltro, todos los meses)');
          return incluir;
        } else {
          bool incluir = fecha.year == anioFiltro && fecha.month == mesIndex;
          print(
              '    ${incluir ? "✅" : "❌"} ${incluir ? "Incluido" : "Excluido"} (año: $anioFiltro, mes: $mesFiltro)');
          return incluir;
        }
      }).toList();

      // DEBUG: Total de documentos filtrados
      print('🎯 Total documentos filtrados: ${resultados.length}\n');

      return resultados;
    } catch (e) {
      print("❌ Error al obtener documentos filtrados: $e");
      return [];
    }
  }

// Función auxiliar para convertir el nombre del mes a su índice (1-12)
  int _getMonthIndex(String mes) {
    const meses = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre'
    ];
    return meses.indexOf(mes) + 1; // enero = 1
  }

// Método para actualizar la gráfica cuando cambian los selectores
  void _actualizarGrafica() {
    setState(() {
      // Actualiza el estado para forzar la reconstrucción de la gráfica
      _cargando = true;
    });

    _obtenerDatosParaGrafica().then((datos) {
      setState(() {
        _datosFiltrados = datos;
        _cargando = false;
      });
    });
  }

  List<ChartData> _procesarDatosPorPeriodo(
      List<QueryDocumentSnapshot> docs, List<Color> colors) {
    if (docs.isEmpty) return [];

    final DateFormat dateFormat = DateFormat('dd/MM/yyyy', 'es_ES');
    final Map<String, int> resultados = {};
    final List<String> ordenMeses = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre'
    ];

    List<ChartData> chartData = [];
    int colorIndex = 0;

    switch (_filtroSeleccionado) {
      case "semanal":
        // Pre-inicializar SOLO las 4 semanas
        for (int i = 0; i < 4; i++) {
          final fechaReferencia =
              DateTime(_anioSeleccionado, _getMonthIndex(_mesSeleccionado), 1);
          final mesNombre = DateFormat('MMMM', 'es_ES').format(fechaReferencia);
          resultados["Semana ${i + 1} de $mesNombre - $_anioSeleccionado"] = 0;
        }

        // Contar registros reales
        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>?;
          final fecha = _convertirFecha(data);

          // ✅ IGNORAR registros sin fecha válida
          if (fecha == null) continue;

          if (fecha.year == _anioSeleccionado &&
              fecha.month == _getMonthIndex(_mesSeleccionado)) {
            int weekOfMonth = ((fecha.day - 1) ~/ 7) + 1;
            if (weekOfMonth > 4) weekOfMonth = 4;

            final mesNombre = DateFormat('MMMM', 'es_ES').format(fecha);
            final key = "Semana $weekOfMonth de $mesNombre - ${fecha.year}";
            resultados[key] = (resultados[key] ?? 0) + 1;
          }
        }
        break;

      case "mensual":
        if (_mesSeleccionado == "Todos los meses") {
          // Pre-inicializar todos los meses del año
          for (var mes in ordenMeses) {
            resultados["$mes - $_anioSeleccionado"] = 0;
          }

          // Contar registros reales
          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>?;
            final fecha = _convertirFecha(data);

            // ✅ IGNORAR registros sin fecha válida
            if (fecha == null) continue;

            if (fecha.year == _anioSeleccionado) {
              final mesNombre = ordenMeses[fecha.month - 1];
              resultados["$mesNombre - ${fecha.year}"] =
                  (resultados["$mesNombre - ${fecha.year}"] ?? 0) + 1;
            }
          }
        } else {
          // Pre-inicializar los 12 meses
          for (int i = 1; i <= 12; i++) {
            final monthStr = DateFormat('MMMM', 'es_ES')
                .format(DateTime(_anioSeleccionado, i));
            resultados["$monthStr - $_anioSeleccionado"] = 0;
          }

          // Contar registros reales
          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>?;
            final fecha = _convertirFecha(data);

            // ✅ IGNORAR registros sin fecha válida
            if (fecha == null) continue;

            if (fecha.year == _anioSeleccionado) {
              final monthStr = DateFormat('MMMM', 'es_ES').format(fecha);
              resultados["$monthStr - ${fecha.year}"] =
                  (resultados["$monthStr - ${fecha.year}"] ?? 0) + 1;
            }
          }
        }
        break;

      case "anual":
        // NO pre-inicializar aquí, solo obtener años de los docs
        Set<int> anios = {};

        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>?;
          final fecha = _convertirFecha(data);

          // ✅ IGNORAR registros sin fecha válida
          if (fecha == null) continue;

          anios.add(fecha.year);
        }

        if (anios.isEmpty) break;

        List<int> aniosOrdenados = anios.toList()..sort();

        // Inicializar SOLO los años que tienen datos
        for (int anio in aniosOrdenados) {
          resultados["$anio"] = 0;
        }

        // Contar registros reales
        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>?;
          final fecha = _convertirFecha(data);

          // ✅ IGNORAR registros sin fecha válida
          if (fecha == null) continue;

          resultados["${fecha.year}"] = (resultados["${fecha.year}"] ?? 0) + 1;
        }

        // Crear chartData directamente aquí
        aniosOrdenados.forEach((anio) {
          chartData.add(ChartData(
            anio.toString(),
            resultados["$anio"]!,
            color: colors[colorIndex % colors.length],
          ));
          colorIndex++;
        });
        return chartData;
    }

    // Generar chartData para casos semanal y mensual
    if (_filtroSeleccionado == "mensual" &&
        _mesSeleccionado == "Todos los meses") {
      // Mantener el orden de los meses
      for (var mes in ordenMeses) {
        final key = "$mes - $_anioSeleccionado";
        if (resultados.containsKey(key)) {
          chartData.add(ChartData(
            key,
            resultados[key]!,
            color: colors[colorIndex % colors.length],
          ));
          colorIndex++;
        }
      }
    } else {
      // Para semanal y mensual individual
      resultados.forEach((key, value) {
        chartData.add(ChartData(
          key,
          value,
          color: colors[colorIndex % colors.length],
        ));
        colorIndex++;
      });
    }

    return chartData;
  }

  DateTime? _convertirFecha(dynamic fecha) {
    // Si es un documento completo (Map), extraer el campo 'fecha'
    if (fecha is Map<String, dynamic>) {
      // SOLO usar el campo 'fecha'
      if (fecha.containsKey('fecha') && fecha['fecha'] != null) {
        final fechaCampo = fecha['fecha'];
        if (fechaCampo is Timestamp) {
          return fechaCampo.toDate();
        } else if (fechaCampo is String) {
          try {
            return DateTime.parse(fechaCampo);
          } catch (e) {
            print('Error al parsear fecha: $fechaCampo');
            return null;
          }
        }
      }

      // Si no existe el campo 'fecha', retornar null para ignorar este registro
      print('⚠️ Registro sin campo "fecha" - será ignorado en las gráficas');
      return null;
    }

    // Si es directamente un Timestamp
    if (fecha is Timestamp) {
      return fecha.toDate();
    }

    // Si es directamente un String
    if (fecha is String) {
      try {
        return DateTime.parse(fecha);
      } catch (e) {
        print('Error al parsear fecha string: $fecha');
        return null;
      }
    }

    // Si no se pudo obtener fecha, retornar null
    print('⚠️ No se pudo convertir la fecha - registro será ignorado');
    return null;
  }

  Widget _buildFiltroPorFecha(StateSetter setState) {
    final List<String> meses = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre'
    ];

    // Filtrar años desde los registros almacenados
    final List<int> anios = _aniosDisponibles.isNotEmpty
        ? _aniosDisponibles
        : [DateTime.now().year];

    // Lógica de selección de meses según el filtro
    bool mostrarMeses =
        _filtroSeleccionado == "mensual" || _filtroSeleccionado == "semanal";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.calendar_today, color: primaryTeal, size: 18),
            const SizedBox(width: 8),
            Text(
              "Seleccionar Año y Mes",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: primaryTeal,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Selector de Año
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<dynamic>(
              value: _anioSeleccionado == -1
                  ? "Todos los años"
                  : _anioSeleccionado,
              isExpanded: true,
              icon: Icon(Icons.arrow_drop_down, color: primaryTeal),
              items: [
                if (_filtroSeleccionado == "anual") // Solo para Anual
                  DropdownMenuItem<dynamic>(
                    value: "Todos los años",
                    child: Text(
                      "Todos los años",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ...anios.map((year) => DropdownMenuItem<dynamic>(
                      value: year,
                      child: Text(
                        year.toString(),
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.black87,
                        ),
                      ),
                    )),
              ],
              onChanged: (value) {
                setState(() {
                  _anioSeleccionado = (value == "Todos los años") ? -1 : value;
                  _actualizarGrafica();
                });
              },
            ),
          ),
        ),

        const SizedBox(height: 10),

        // Selector de Mes (solo si es Semanal o Mensual)
        if (mostrarMeses)
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _mesSeleccionado,
                isExpanded: true,
                icon: Icon(Icons.arrow_drop_down, color: primaryTeal),
                items: [
                  DropdownMenuItem<String>(
                    value: "Todos los meses",
                    child: Text("Todos los meses",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        )),
                  ),
                  ...meses.map((mes) => DropdownMenuItem<String>(
                        value: mes,
                        child: Text(mes,
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.black87,
                            )),
                      )),
                ],
                onChanged: (value) {
                  setState(() {
                    _mesSeleccionado = value!;
                    _actualizarGrafica();
                  });
                },
              ),
            ),
          ),

        const SizedBox(height: 5),
        Text(
          "Los datos se filtrarán según el año y mes seleccionados",
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryTeal,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: primaryTeal,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  Future<void> _selectDateRangeWithMonth(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryTeal,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: primaryTeal,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  Future<void> _exportarRegistros({bool todos = false}) async {
    setState(() => _isLoading = true);
    try {
      List<Registro> registrosParaExportar = [];
      List<SocialProfile> perfilesParaExportar = [];
      String prefix;

      if (todos) {
        // Obtener todos los registros
        registrosParaExportar = _registrosPorAnioMesDia.values
            .expand((meses) => meses.values)
            .expand((dias) => dias.values)
            .expand((registros) => registros)
            .toList();

        // Obtener todos los perfiles sociales SIN filtrar por fecha
        final perfilesSnapshot = await FirebaseFirestore.instance
            .collection('social_profiles')
            .get();
        perfilesParaExportar = perfilesSnapshot.docs
            .map((doc) => SocialProfile.fromMap(
                doc.data() as Map<String, dynamic>, doc.id))
            .toList();

        prefix = 'todos_los_registros';
      } else if (_startDate != null && _endDate != null) {
        // Definir las variables para el rango de fechas
        final fechaInicio =
            DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
        final fechaFin = DateTime(
            _endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59);

        // Filtrar registros por fecha
        registrosParaExportar = _registrosPorAnioMesDia.values
            .expand((meses) => meses.values)
            .expand((dias) => dias.values)
            .expand((registros) => registros)
            .where((registro) {
          final fechaRegistro = registro.fecha;
          return fechaRegistro
                  .isAfter(fechaInicio.subtract(const Duration(seconds: 1))) &&
              fechaRegistro.isBefore(fechaFin.add(const Duration(seconds: 1)));
        }).toList();

        // Filtrar perfiles sociales por fecha
        final perfilesSnapshot = await FirebaseFirestore.instance
            .collection('social_profiles')
            .get(); // Primero obtenemos todos

        // Luego filtramos manualmente por fecha
        perfilesParaExportar = perfilesSnapshot.docs
            .map((doc) => SocialProfile.fromMap(
                doc.data() as Map<String, dynamic>, doc.id))
            .where((perfil) {
          final createdAt = perfil.createdAt;
          return createdAt
                  .isAfter(fechaInicio.subtract(const Duration(seconds: 1))) &&
              createdAt.isBefore(fechaFin.add(const Duration(seconds: 1)));
        }).toList();

        prefix =
            'registros_${DateFormat('dd_MM_yyyy').format(_startDate!)}_a_${DateFormat('dd_MM_yyyy').format(_endDate!)}';
      } else {
        throw Exception('Selecciona un rango de fechas');
      }

      if (registrosParaExportar.isEmpty && perfilesParaExportar.isEmpty) {
        throw Exception('No hay datos para el rango de fechas seleccionado');
      }

      final filePath = await _excelService.exportarRegistros(
        registrosParaExportar,
        perfilesParaExportar, // Ahora siempre enviamos perfiles (si existen)
        prefix: prefix,
      );

      if (!mounted) return;
      _mostrarExito('Archivo exportado: $filePath');
    } catch (e) {
      _mostrarError('Error al exportar: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> asignarRegistroAMinisterio(
      String registroId, String ministerio) async {
    try {
      await FirebaseFirestore.instance
          .collection('registros')
          .doc(registroId)
          .update({
        'ministerioAsignado': ministerio,
        'tribuAsignada':
            null, // Asegurar que no tenga tribu al asignarlo al ministerio
        'fechaAsignacion': FieldValue.serverTimestamp(),
      });
      print('Registro asignado correctamente al ministerio: $ministerio');
    } catch (e) {
      print('Error al asignar el registro: $e');
    }
  }

  Future<void> _assignRegistroToTribu(String registroId) async {
    // Verificar si el registro existe
    final registroDoc = await FirebaseFirestore.instance
        .collection('registros')
        .doc(registroId)
        .get();

    if (!registroDoc.exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('El registro no existe o ha sido eliminado.')),
      );
      return;
    }

    // Inicializar opciones
    final List<DropdownMenuItem<String>> opciones = [];
    String? opcionSeleccionada;

    try {
      // Agregar opciones directas para ministerios primero
      opciones.add(const DropdownMenuItem(
        value: 'Ministerio de Damas',
        child: Text('Ministerio de Damas'),
      ));
      opciones.add(const DropdownMenuItem(
        value: 'Ministerio de Caballeros',
        child: Text('Ministerio de Caballeros'),
      ));

      // Agregar un separador visual
      opciones.add(DropdownMenuItem(
        value: 'separator',
        enabled: false,
        child: Divider(thickness: 2, color: Colors.grey),
      ));

      // Agregar título para tribus juveniles
      opciones.add(DropdownMenuItem(
        value: 'juveniles_title',
        enabled: false,
        child: Text('Tribus Juveniles',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
      ));

      // Cargar las tribus juveniles - SOLUCIÓN MODIFICADA: Eliminamos el orderBy
      final tribusSnapshot = await FirebaseFirestore.instance
          .collection('tribus')
          .where('categoria', isEqualTo: 'Ministerio Juvenil')
          .get();

      // Ordenar las tribus por nombre en memoria para evitar necesitar índices compuestos
      final sortedDocs = tribusSnapshot.docs
        ..sort((a, b) => (a.data()['nombre'] as String? ?? '')
            .compareTo(b.data()['nombre'] as String? ?? ''));

      // Agregar tribus juveniles al dropdown
      for (var doc in sortedDocs) {
        final nombre = doc['nombre'] ?? 'Sin nombre';

        opciones.add(DropdownMenuItem(
          value: doc.id,
          child: Text(nombre),
        ));
      }

      if (opciones.length <= 4) {
        // Si solo tenemos los ministerios y separadores
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('No hay tribus juveniles disponibles para asignar.')),
        );
        // Continuamos de todos modos porque podemos asignar a los ministerios principales
      }

      // Mostrar diálogo para seleccionar
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: const Text('Asignar a Ministerio o Tribu'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: opcionSeleccionada,
                      items: opciones,
                      onChanged: (value) {
                        // Ignorar selecciones de separadores y títulos
                        if (value != 'separator' &&
                            value != 'juveniles_title') {
                          setState(() {
                            opcionSeleccionada = value;
                          });
                        }
                      },
                      decoration: const InputDecoration(
                        labelText: 'Seleccione una opción',
                        border: OutlineInputBorder(),
                      ),
                      isExpanded: true,
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  ElevatedButton(
                    onPressed: opcionSeleccionada == null
                        ? null
                        : () async {
                            if (opcionSeleccionada == 'Ministerio de Damas' ||
                                opcionSeleccionada ==
                                    'Ministerio de Caballeros') {
                              // 🔹 Aquí se llama la función para asignar al ministerio correctamente
                              await asignarRegistroAMinisterio(
                                  registroId, opcionSeleccionada!);
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Registro asignado a "$opcionSeleccionada" correctamente',
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } else {
                              try {
                                // Obtener información de la tribu seleccionada
                                final docTribu = await FirebaseFirestore
                                    .instance
                                    .collection('tribus')
                                    .doc(opcionSeleccionada)
                                    .get();

                                if (!docTribu.exists) {
                                  throw Exception(
                                      'La tribu seleccionada ya no existe');
                                }

                                final dataTribu =
                                    docTribu.data() as Map<String, dynamic>;
                                final ministerioAsignado =
                                    dataTribu['categoria'] ?? '';
                                final nombreTribu = dataTribu['nombre'] ?? '';

                                // Actualizar registro con tribu y ministerio
                                await FirebaseFirestore.instance
                                    .collection('registros')
                                    .doc(registroId)
                                    .update({
                                  'tribuAsignada': opcionSeleccionada,
                                  'nombreTribu': nombreTribu,
                                  'ministerioAsignado': ministerioAsignado,
                                  'fechaAsignacionTribu':
                                      FieldValue.serverTimestamp(),
                                });

                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Registro asignado a "$nombreTribu" correctamente',
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              } catch (e) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'Error al asignar: ${e.toString()}'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                    child: const Text('Asignar'),
                  ),
                ],
              );
            },
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar las opciones: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _mostrarExito(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(mensaje)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildRegistrosTab() {
    return SingleChildScrollView(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            _buildExportCard(),
            _searchQuery.isNotEmpty
                ? _buildRegistrosSearchList()
                : _buildRegistrosList(),
          ],
        ),
      ),
    );
  }

  Widget _buildRegistrosSearchList() {
    List<Registro> registrosFiltrados = _filtrarPorTexto();

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, primaryTeal.withOpacity(0.05)],
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(Icons.search, color: secondaryOrange, size: 24),
                  const SizedBox(width: 10),
                  Text(
                    'Resultados para: "${_searchQuery}"',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: primaryTeal,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey),
                    onPressed: () {
                      setState(() {
                        _isSearching = false;
                        _searchController.clear();
                        _searchQuery = '';
                      });
                    },
                    tooltip: 'Limpiar búsqueda',
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            registrosFiltrados.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(30),
                    child: Column(
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 50,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 15),
                        Text(
                          "No se encontraron registros",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: registrosFiltrados.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      return _buildRegistroTile(registrosFiltrados[index]);
                    },
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, primaryTeal.withOpacity(0.1)],
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.file_download, size: 28, color: secondaryOrange),
                const SizedBox(width: 12),
                Text(
                  'Exportar Registros',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: primaryTeal,
                  ),
                ),
              ],
            ),
            const Divider(height: 30),
            _buildDateRangeSelector(),
            const SizedBox(height: 20),
            _buildExportButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRangeSelector() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: primaryTeal.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _startDate != null && _endDate != null
                  ? 'Del ${DateFormat('dd/MM/yyyy').format(_startDate!)} al ${DateFormat('dd/MM/yyyy').format(_endDate!)}'
                  : 'Selecciona un rango de fechas',
              style: TextStyle(
                color: Colors.grey[800],
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () => _selectDateRange(context),
            icon: const Icon(Icons.date_range),
            label: const Text('Seleccionar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryTeal,
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: (_startDate != null && _endDate != null)
                ? () => _exportarRegistros()
                : null,
            icon: const Icon(Icons.date_range),
            label: const Text('Por Fechas'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryTeal,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _exportarRegistros(todos: true),
            icon: const Icon(Icons.cloud_download),
            label: const Text('Todo'),
            style: ElevatedButton.styleFrom(
              backgroundColor: secondaryOrange,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRegistrosList() {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, primaryTeal.withOpacity(0.05)],
          ),
        ),
        child: Column(
          children: [
            _buildBuscadorFechas(),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('registros')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                      child: Text('No hay registros disponibles.'));
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(8),
                  itemCount: (_mostrarFiltrados
                          ? _registrosFiltrados
                          : _registrosPorAnioMesDia)
                      .length,
                  itemBuilder: (context, indexAnio) {
                    final datos = _mostrarFiltrados
                        ? _registrosFiltrados
                        : _registrosPorAnioMesDia;
                    final anio = datos.keys.toList()[indexAnio];
                    return _buildAnioGroup(anio, datos[anio]!);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBuscadorFechas() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.search),
              label: Text(_startDate != null && _endDate != null
                  ? '${DateFormat('dd/MM/yyyy').format(_startDate!)} - ${DateFormat('dd/MM/yyyy').format(_endDate!)}'
                  : 'Buscar por fechas'),
              onPressed: () => _selectDateRange(context).then((value) {
                if (_startDate != null && _endDate != null) {
                  _filtrarRegistros();
                }
              }),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryTeal,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          if (_mostrarFiltrados)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: _limpiarFiltro,
              color: secondaryOrange,
            ),
        ],
      ),
    );
  }

  void _filtrarRegistros() {
    if (_startDate == null || _endDate == null) return;

    final registrosFiltrados =
        Map<int, Map<int, Map<DateTime, List<Registro>>>>.from({});

    _registrosPorAnioMesDia.forEach((anio, meses) {
      meses.forEach((mes, dias) {
        dias.forEach((dia, registros) {
          if (dia.isAfter(_startDate!.subtract(const Duration(days: 1))) &&
              dia.isBefore(_endDate!.add(const Duration(days: 1)))) {
            registrosFiltrados[anio] ??= {};
            registrosFiltrados[anio]![mes] ??= {};
            registrosFiltrados[anio]![mes]![dia] = registros;
          }
        });
      });
    });

    setState(() {
      _registrosFiltrados = registrosFiltrados;
      _mostrarFiltrados = true;
    });
  }

// Agregar esta nueva función separada para la búsqueda por texto
  List<Registro> _filtrarPorTexto() {
    if (_searchQuery.isEmpty) {
      return [];
    }
    // Obtiene todos los registros sin agrupación
    List<Registro> todosLosRegistros = [];

    _registrosPorAnioMesDia.forEach((anio, meses) {
      meses.forEach((mes, dias) {
        dias.forEach((dia, registros) {
          todosLosRegistros.addAll(registros);
        });
      });
    });

    // Filtra por nombre o apellido
    return todosLosRegistros.where((registro) {
      String nombreCompleto =
          '${registro.nombre} ${registro.apellido}'.toLowerCase();
      return nombreCompleto.contains(_searchQuery);
    }).toList();
  }

  void _limpiarFiltro() {
    setState(() {
      _mostrarFiltrados = false;
      _startDate = null;
      _endDate = null;
    });
  }

  Widget _buildAnioGroup(
      int anio, Map<int, Map<DateTime, List<Registro>>> registrosPorMes) {
    return ExpansionTile(
      leading: CircleAvatar(
        backgroundColor: primaryTeal,
        child: Text(
          anio.toString(),
          style: const TextStyle(color: Colors.white),
        ),
      ),
      title: Text(
        'Año $anio',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      children: registrosPorMes.entries
          .map((mes) => _buildMesGroup(mes.key, mes.value))
          .toList(),
    );
  }

  Widget _buildMesGroup(
      int mes, Map<DateTime, List<Registro>> registrosPorDia) {
    final nombreMes = _getNombreMes(mes);
    int totalRegistros =
        registrosPorDia.values.expand((registros) => registros).length;

    return ExpansionTile(
      leading: CircleAvatar(
        backgroundColor: secondaryOrange,
        child: Text(
          mes.toString(),
          style: const TextStyle(color: Colors.white),
        ),
      ),
      title: Text(
        nombreMes,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      subtitle: Text(
        '$totalRegistros registros',
        style: TextStyle(
          color: secondaryOrange,
          fontWeight: FontWeight.w500,
        ),
      ),
      children: registrosPorDia.entries
          .map((entrada) => _buildFechaGroup(entrada.key, entrada.value))
          .toList(),
    );
  }

  String _getNombreMes(int mes) {
    const meses = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre'
    ];
    return meses[mes - 1];
  }

  Widget _buildFechaGroup(DateTime fecha, List<Registro> registros) {
    // Variables locales para los filtros
    String? filtroSexoLocal;
    int? filtroEdadLocal;

    // Lista filtrable
    List<Registro> registrosFiltrados = List.from(registros);

    // Función para aplicar filtros
    void aplicarFiltros() {
      registrosFiltrados = registros.where((registro) {
        final coincideSexo =
            filtroSexoLocal == null || registro.sexo == filtroSexoLocal;
        final coincideEdad =
            filtroEdadLocal == null || registro.edad >= filtroEdadLocal!;
        return coincideSexo && coincideEdad;
      }).toList();
    }

    // Aplicar filtros iniciales
    aplicarFiltros();

    return StatefulBuilder(
      builder: (context, setState) {
        return Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: ExpansionTile(
              leading: CircleAvatar(
                backgroundColor: primaryTeal,
                child: const Icon(Icons.calendar_today, color: Colors.white),
              ),
              title: Text(
                DateFormat('dd/MM/yyyy').format(fecha),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.people_outline,
                          size: 16, color: secondaryOrange),
                      const SizedBox(width: 4),
                      Text(
                        '${registrosFiltrados.length} registros',
                        style: TextStyle(
                          color: secondaryOrange,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: filtroSexoLocal,
                                hint: const Text("Filtrar por Sexo"),
                                isExpanded: true,
                                icon: const Icon(Icons.person_outline),
                                items: ['Hombre', 'Mujer'].map((sexo) {
                                  return DropdownMenuItem(
                                    value: sexo,
                                    child: Text(sexo),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    filtroSexoLocal = value;
                                    aplicarFiltros();
                                  });
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: TextField(
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                hintText: "Filtrar por Edad",
                                border: InputBorder.none,
                                prefixIcon: Icon(Icons.cake_outlined),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  filtroEdadLocal = int.tryParse(value);
                                  aplicarFiltros();
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              children: [
                ...registrosFiltrados
                    .map((registro) => _buildRegistroTile(registro)),
                if (registrosFiltrados.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'No se encontraron registros con los filtros seleccionados',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRegistroTile(Registro registro) {
    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setInnerState) {
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, primaryTeal.withOpacity(0.05)],
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: secondaryOrange.withOpacity(0.2),
                      child: Text(
                        registro.nombre[0].toUpperCase(),
                        style: TextStyle(
                          color: secondaryOrange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${registro.nombre} ${registro.apellido}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: primaryTeal,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            registro.servicio,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Botones de acción
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _editarRegistro(context, registro),
                        ),
                        // Verificar si el registro ya tiene una tribu o ministerio asignado
                        StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('registros')
                              .doc(registro.id)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) return SizedBox();

                            final registroData =
                                snapshot.data!.data() as Map<String, dynamic>?;
                            final tribuAsignada =
                                registroData?['tribuAsignada'];
                            final ministerioAsignado =
                                registroData?['ministerioAsignado'];

                            // Si no tiene asignación, mostrar botón "Asignar"
                            if (tribuAsignada == null &&
                                ministerioAsignado == null) {
                              return IconButton(
                                icon: const Icon(Icons.group_add,
                                    color: Colors.blue),
                                tooltip: 'Asignar a tribu o ministerio',
                                onPressed: () => _asignarAtribu(registro),
                              );
                            } else {
                              // Si ya tiene asignación, mostrar "Cambiar Asignación"
                              return IconButton(
                                icon: const Icon(Icons.swap_horiz,
                                    color: Colors.orange),
                                tooltip: 'Cambiar asignación',
                                onPressed: () => _mostrarConfirmacionCambio(
                                    context, registro),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  children: [
                    Icon(Icons.phone, size: 20, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      registro.telefono,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _mostrarConfirmacionCambio(BuildContext context, Registro registro) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Confirmar Cambio',
              style:
                  TextStyle(color: primaryTeal, fontWeight: FontWeight.bold)),
          content: Text(
              '¿Está seguro de cambiar la asignación de este registro? La asignación actual será eliminada.',
              style: TextStyle(fontSize: 15)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('Cancelar', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _cambiarAsignacionRegistro(registro);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: secondaryOrange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _cambiarAsignacionRegistro(Registro registro) async {
    try {
      // Eliminar la asignación previa
      await FirebaseFirestore.instance
          .collection('registros')
          .doc(registro.id)
          .update({
        'nombreTribu': null,
        'tribuAsignada': null,
        'ministerioAsignado': null,
        'coordinadorAsignado': null,
        'timoteoAsignado': null,
        'nombreTimoteo': null,
      });

      // Llamar a la función sin await, porque es void
      _asignarAtribu(registro);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Asignación cambiada correctamente'),
            backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error al cambiar asignación: $e'),
            backgroundColor: Colors.red),
      );
    }
  }

  Widget _buildPerfilesSocialesTab() {
    const Color primaryTeal = Color(0xFF038C7F);

    return SingleChildScrollView(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            Card(
              margin: const EdgeInsets.all(16),
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.white, primaryTeal.withOpacity(0.1)],
                  ),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.date_range,
                            size: 28, color: secondaryOrange),
                        const SizedBox(width: 12),
                        Text(
                          'Filtrar por Fecha',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: primaryTeal,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildDateRangeSelector(),
                  ],
                ),
              ),
            ),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('social_profiles')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(primaryTeal),
                    ),
                  );
                }

                List<SocialProfile> allPerfiles =
                    snapshot.data!.docs.map((doc) {
                  return SocialProfile.fromMap(
                      doc.data() as Map<String, dynamic>, doc.id);
                }).toList();

                // Filter perfiles based on date range if selected
                List<SocialProfile> filteredPerfiles = allPerfiles;
                if (_startDate != null && _endDate != null) {
                  filteredPerfiles = allPerfiles.where((perfil) {
                    DateTime createdAt = perfil.createdAt;
                    return createdAt.isAfter(
                            _startDate!.subtract(const Duration(seconds: 1))) &&
                        createdAt.isBefore(
                            _endDate!.add(const Duration(seconds: 1)));
                  }).toList();
                }

                if (filteredPerfiles.isEmpty) {
                  return Card(
                    margin: const EdgeInsets.all(16),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 48,
                            color: secondaryOrange.withOpacity(0.7),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _startDate != null && _endDate != null
                                ? 'No hay perfiles sociales para el rango de fechas seleccionado'
                                : 'No hay perfiles sociales disponibles',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Agrupar perfiles por año, mes, semana y día
                Map<int, Map<int, Map<int, Map<String, List<SocialProfile>>>>>
                    groupedPerfiles = {};

                // Obtener los años únicos para inicializar
                Set<int> years = {};

                for (var perfil in filteredPerfiles) {
                  final DateTime date = perfil.createdAt;
                  final int year = date.year;
                  final int month = date.month;
                  final int weekNumber = _getWeekNumber(date);
                  final String weekday = _getWeekdayName(date.weekday);

                  years.add(year);

                  // Inicializar estructuras anidadas si no existen
                  groupedPerfiles[year] ??= {};
                  groupedPerfiles[year]![month] ??= {};
                  groupedPerfiles[year]![month]![weekNumber] ??= {};
                  groupedPerfiles[year]![month]![weekNumber]![weekday] ??= [];

                  // Agregar perfil al grupo correspondiente
                  groupedPerfiles[year]![month]![weekNumber]![weekday]!
                      .add(perfil);
                }

                // Convertir a lista ordenada por año
                List<int> orderedYears = years.toList()
                  ..sort((a, b) => b.compareTo(a)); // Orden descendente

                return _buildGroupedPerfilesView(
                  context,
                  groupedPerfiles,
                  orderedYears,
                  primaryTeal,
                  secondaryOrange,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupedPerfilesView(
    BuildContext context,
    Map<int, Map<int, Map<int, Map<String, List<SocialProfile>>>>>
        groupedPerfiles,
    List<int> years,
    Color primaryTeal,
    Color secondaryOrange,
  ) {
    return Column(
      children: years.map((year) {
        return _buildYearGroup(context, year, groupedPerfiles[year]!,
            primaryTeal, secondaryOrange);
      }).toList(),
    );
  }

  Widget _buildYearGroup(
    BuildContext context,
    int year,
    Map<int, Map<int, Map<String, List<SocialProfile>>>> yearData,
    Color primaryTeal,
    Color secondaryOrange,
  ) {
    // Calcular el total de perfiles en este año
    int totalProfilesInYear = 0;
    yearData.forEach((month, monthData) {
      monthData.forEach((week, weekData) {
        weekData.forEach((day, profiles) {
          totalProfilesInYear += profiles.length;
        });
      });
    });

    // Obtener los meses en orden cronológico
    List<int> months = yearData.keys.toList()..sort();

    return ExpansionCard(
      title: 'Año $year',
      subtitle: '$totalProfilesInYear perfiles',
      icon: Icons.calendar_today_rounded,
      iconColor: secondaryOrange,
      textColor: primaryTeal,
      expandedColor: primaryTeal.withOpacity(0.1),
      children: months.map((month) {
        return _buildMonthGroup(
          context,
          month,
          year,
          yearData[month]!,
          primaryTeal,
          secondaryOrange,
        );
      }).toList(),
    );
  }

  Widget _buildMonthGroup(
    BuildContext context,
    int month,
    int year,
    Map<int, Map<String, List<SocialProfile>>> monthData,
    Color primaryTeal,
    Color secondaryOrange,
  ) {
    // Calcular el total de perfiles en este mes
    int totalProfilesInMonth = 0;
    monthData.forEach((week, weekData) {
      weekData.forEach((day, profiles) {
        totalProfilesInMonth += profiles.length;
      });
    });

    // Obtener las semanas en orden cronológico
    List<int> weeks = monthData.keys.toList()..sort();

    return Padding(
      padding: const EdgeInsets.only(left: 16.0),
      child: ExpansionCard(
        title: _getMonthName(month),
        subtitle: '$totalProfilesInMonth perfiles',
        icon: Icons.event,
        iconColor: secondaryOrange,
        textColor: primaryTeal,
        expandedColor: primaryTeal.withOpacity(0.05),
        children: weeks.map((week) {
          return _buildWeekGroup(
            context,
            week,
            month,
            year,
            monthData[week]!,
            primaryTeal,
            secondaryOrange,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildWeekGroup(
    BuildContext context,
    int week,
    int month,
    int year,
    Map<String, List<SocialProfile>> weekData,
    Color primaryTeal,
    Color secondaryOrange,
  ) {
    // Calcular el total de perfiles en esta semana
    int totalProfilesInWeek = 0;
    weekData.forEach((day, profiles) {
      totalProfilesInWeek += profiles.length;
    });

    // Ordenar los días según el orden de la semana (lunes a domingo)
    List<String> weekdayOrder = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo'
    ];
    List<String> days = weekData.keys.toList()
      ..sort(
          (a, b) => weekdayOrder.indexOf(a).compareTo(weekdayOrder.indexOf(b)));

    DateTime startDate = _getFirstDayOfWeek(year, month, week);
    DateTime endDate = startDate.add(const Duration(days: 6));

    return Padding(
      padding: const EdgeInsets.only(left: 16.0),
      child: ExpansionCard(
        title: 'Semana $week',
        subtitle:
            '$totalProfilesInWeek perfiles · ${DateFormat('dd/MM').format(startDate)} - ${DateFormat('dd/MM').format(endDate)}',
        icon: Icons.view_week_rounded,
        iconColor: secondaryOrange,
        textColor: primaryTeal,
        expandedColor: primaryTeal.withOpacity(0.02),
        children: days.map((day) {
          return _buildDayGroup(
            context,
            day,
            weekData[day]!,
            primaryTeal,
            secondaryOrange,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDayGroup(
    BuildContext context,
    String day,
    List<SocialProfile> profiles,
    Color primaryTeal,
    Color secondaryOrange,
  ) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0),
      child: ExpansionCard(
        title: day,
        subtitle: '${profiles.length} perfiles',
        icon: _getDayIcon(day),
        iconColor: secondaryOrange,
        textColor: primaryTeal,
        expandedColor: Colors.transparent,
        children: [
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            itemCount: profiles.length,
            itemBuilder: (context, index) {
              final perfil = profiles[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    radius: 22,
                    backgroundColor: secondaryOrange.withOpacity(0.2),
                    child: Text(
                      perfil.name[0].toUpperCase(),
                      style: TextStyle(
                        fontSize: 18,
                        color: secondaryOrange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    '${perfil.name} ${perfil.lastName}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: primaryTeal,
                    ),
                  ),
                  subtitle: Row(
                    children: [
                      Icon(_getSocialNetworkIcon(perfil.socialNetwork),
                          size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(perfil.socialNetwork,
                          style: TextStyle(fontSize: 13)),
                      const SizedBox(width: 8),
                      Icon(Icons.schedule, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(DateFormat('HH:mm').format(perfil.createdAt),
                          style: TextStyle(fontSize: 13)),
                    ],
                  ),
                  trailing: IconButton(
                    icon: Icon(
                      Icons.visibility,
                      color: primaryTeal,
                      size: 20,
                    ),
                    tooltip: 'Ver detalles',
                    onPressed: () => _mostrarDetallesPerfil(context, perfil),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

// Funciones auxiliares para manejar fechas y nombres
  String _getMonthName(int month) {
    switch (month) {
      case 1:
        return 'Enero';
      case 2:
        return 'Febrero';
      case 3:
        return 'Marzo';
      case 4:
        return 'Abril';
      case 5:
        return 'Mayo';
      case 6:
        return 'Junio';
      case 7:
        return 'Julio';
      case 8:
        return 'Agosto';
      case 9:
        return 'Septiembre';
      case 10:
        return 'Octubre';
      case 11:
        return 'Noviembre';
      case 12:
        return 'Diciembre';
      default:
        return 'Mes $month';
    }
  }

  String _getWeekdayName(int weekday) {
    switch (weekday) {
      case 1: // DateTime.monday
        return 'Lunes';
      case 2:
        return 'Martes';
      case 3:
        return 'Miércoles';
      case 4:
        return 'Jueves';
      case 5:
        return 'Viernes';
      case 6:
        return 'Sábado';
      case 7: // DateTime.sunday
        return 'Domingo';
      default:
        return 'Desconocido';
    }
  }

  IconData _getDayIcon(String day) {
    switch (day) {
      case 'Lunes':
        return Icons.start;
      case 'Martes':
        return Icons.looks_two;
      case 'Miércoles':
        return Icons.looks_3;
      case 'Jueves':
        return Icons.looks_4;
      case 'Viernes':
        return Icons.weekend;
      case 'Sábado':
        return Icons.sports_bar;
      case 'Domingo':
        return Icons.brightness_5;
      default:
        return Icons.calendar_today;
    }
  }

// Obtener el número de semana (asumiendo que la semana comienza el lunes)
  int _getWeekNumber(DateTime date) {
    // Encontrar el primer día del mes
    final DateTime firstDayOfMonth = DateTime(date.year, date.month, 1);

    // Calcular días hasta el primer lunes
    int daysUntilFirstMonday = (8 - firstDayOfMonth.weekday) % 7;

    // Primer lunes del mes
    final DateTime firstMonday =
        firstDayOfMonth.add(Duration(days: daysUntilFirstMonday));

    // Si la fecha es anterior al primer lunes, está en la semana 0
    if (date.isBefore(firstMonday)) {
      return 0;
    }

    // Calcular la diferencia en días entre la fecha y el primer lunes
    final int dayDifference = date.difference(firstMonday).inDays;

    // Calcular el número de semana (empezando por 1 para la primera semana completa)
    return (dayDifference / 7).floor() + 1;
  }

// Obtener el primer día de una semana específica en un mes y año
  DateTime _getFirstDayOfWeek(int year, int month, int weekNumber) {
    // Primer día del mes
    final DateTime firstDayOfMonth = DateTime(year, month, 1);

    // Calcular días hasta el primer lunes
    int daysUntilFirstMonday = (8 - firstDayOfMonth.weekday) % 7;

    // Primer lunes del mes
    final DateTime firstMonday =
        firstDayOfMonth.add(Duration(days: daysUntilFirstMonday));

    // Si es la semana 0 (parcial, antes del primer lunes)
    if (weekNumber == 0) {
      return firstDayOfMonth;
    }

    // Calcular el primer día de la semana solicitada
    return firstMonday.add(Duration(days: (weekNumber - 1) * 7));
  }

  void _mostrarDetallesPerfil(BuildContext context, SocialProfile perfil) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 10,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.white, primaryTeal.withOpacity(0.05)],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [primaryTeal, primaryTeal.withOpacity(0.8)],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        spreadRadius: 1,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.white,
                            child: Text(
                              perfil.name[0].toUpperCase(),
                              style: TextStyle(
                                fontSize: 26,
                                color: primaryTeal,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: secondaryOrange,
                            child: Icon(
                              _getSocialNetworkIcon(perfil.socialNetwork),
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${perfil.name} ${perfil.lastName}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                perfil.socialNetwork,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Contenido principal
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      children: [
                        // Sección de Información Personal
                        _buildDetailSection(
                          'Información Personal',
                          [
                            _buildDetailItem(
                                Icons.cake, 'Edad', '${perfil.age} años'),
                            _buildDetailItem(_getGenderIcon(perfil.gender),
                                'Género', _formatGender(perfil.gender)),
                            _buildDetailItem(Icons.phone, 'Teléfono',
                                _formatPhone(perfil.phone)),
                          ],
                        ),

                        const SizedBox(height: 4),
                        const Divider(indent: 20, endIndent: 20),
                        const SizedBox(height: 4),

                        // Sección de Ubicación
                        _buildDetailSection(
                          'Ubicación',
                          [
                            _buildDetailItem(
                                Icons.home, 'Dirección', perfil.address),
                            _buildDetailItem(
                                Icons.location_city, 'Ciudad', perfil.city),
                          ],
                        ),

                        const SizedBox(height: 4),
                        const Divider(indent: 20, endIndent: 20),
                        const SizedBox(height: 4),

                        // Sección de Información Adicional
                        _buildDetailSection(
                          'Información Adicional',
                          [
                            _buildDetailItem(
                                Icons.favorite,
                                'Petición de Oración',
                                perfil.prayerRequest ?? 'No especificada'),
                            _buildDetailItem(
                                Icons.calendar_today,
                                'Fecha de Registro',
                                DateFormat('dd/MM/yyyy')
                                    .format(perfil.createdAt)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Botones de acción
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        label: const Text('Cerrar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryTeal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

// Funciones auxiliares para el diálogo de detalles
  Widget _buildDetailSection(String title, List<Widget> items) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(
                  color: secondaryOrange,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: primaryTeal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...items,
        ],
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: secondaryOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: secondaryOrange,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

// Funciones de formateado para mejorar la visualización
  String _formatPhone(String phone) {
    if (phone.length == 10) {
      return '${phone.substring(0, 3)} ${phone.substring(3, 6)} ${phone.substring(6)}';
    } else if (phone.length > 10) {
      return '${phone.substring(0, 3)} ${phone.substring(3, 6)} ${phone.substring(6, 10)}';
    }
    return phone;
  }

  String _formatGender(String gender) {
    String normalizedGender = gender.toLowerCase();
    if (normalizedGender == 'masculino' || normalizedGender == 'hombre') {
      return 'Hombre';
    } else if (normalizedGender == 'femenino' || normalizedGender == 'mujer') {
      return 'Mujer';
    }
    return gender;
  }

  IconData _getGenderIcon(String gender) {
    String normalizedGender = gender.toLowerCase();
    if (normalizedGender == 'masculino' || normalizedGender == 'hombre') {
      return Icons.male;
    } else if (normalizedGender == 'femenino' || normalizedGender == 'mujer') {
      return Icons.female;
    }
    return Icons.person;
  }

  IconData _getSocialNetworkIcon(String network) {
    String normalizedNetwork = network.toLowerCase();
    if (normalizedNetwork.contains('facebook')) {
      return Icons.facebook;
    } else if (normalizedNetwork.contains('youtube')) {
      return Icons.play_circle_filled;
    }
    return Icons.public; // Ícono predeterminado si no es Facebook ni YouTube
  }

  Widget _buildConsolidadoresTab() {
    return SingleChildScrollView(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            _buildAgregarConsolidadorCard(),
            _buildConsolidadoresList(),
          ],
        ),
      ),
    );
  }

  Widget _buildAgregarConsolidadorCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, primaryTeal.withOpacity(0.1)],
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person_add, size: 28, color: secondaryOrange),
                const SizedBox(width: 12),
                Text(
                  'Agregar Consolidador',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: primaryTeal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nuevoConsolidadorController,
                    decoration: InputDecoration(
                      labelText: 'Nombre del Consolidador',
                      labelStyle: TextStyle(color: primaryTeal),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: primaryTeal, width: 2),
                      ),
                      prefixIcon: Icon(Icons.person, color: primaryTeal),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () async {
                    if (_nuevoConsolidadorController.text.isNotEmpty) {
                      await _firestoreService.agregarConsolidador(
                        _nuevoConsolidadorController.text,
                      );
                      _nuevoConsolidadorController.clear();
                      _mostrarExito('Consolidador agregado exitosamente');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: secondaryOrange,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Agregar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConsolidadoresList() {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, primaryTeal.withOpacity(0.05)],
          ),
        ),
        child: ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemCount: _consolidadores.length,
          itemBuilder: (context, index) {
            return _buildConsolidadorTile(_consolidadores[index]);
          },
        ),
      ),
    );
  }

  Widget _buildConsolidadorTile(Map<String, String> consolidador) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: secondaryOrange.withOpacity(0.2),
          child: Text(
            (consolidador['nombre'] ?? '')[0].toUpperCase(),
            style: TextStyle(
              color: secondaryOrange,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          consolidador['nombre'] ?? 'Sin nombre',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: primaryTeal,
            fontSize: 16,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit, color: primaryTeal),
              onPressed: () => _editarConsolidador(context, consolidador),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _confirmarEliminarConsolidador(consolidador),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmarEliminarConsolidador(
      Map<String, String> consolidador) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(Icons.warning, color: secondaryOrange),
            const SizedBox(width: 5),
            const Text('Confirmar Eliminación'),
          ],
        ),
        content: Container(
          constraints:
              BoxConstraints(maxWidth: 300), // Ajusta el ancho del contenido
          child: Text('¿Estás seguro de eliminar a ${consolidador['nombre']}?'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancelar',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _firestoreService
                    .eliminarConsolidador(consolidador['id']!);
                _mostrarExito('Consolidador eliminado exitosamente');
              } catch (e) {
                _mostrarError('Error al eliminar: $e');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _asignarAtribu(Registro registro) async {
    setState(() => _isLoading = true);

    try {
      // Obtener solo las tribus del Ministerio Juvenil
      final tribusSnapshot = await FirebaseFirestore.instance
          .collection('tribus')
          .where('categoria', isEqualTo: 'Ministerio Juvenil')
          .get();

      final ministerios = ['Ministerio de Damas', 'Ministerio de Caballeros'];

      if (tribusSnapshot.docs.isEmpty && ministerios.isEmpty) {
        _mostrarError('No hay tribus o ministerios disponibles para asignar.');
        setState(() => _isLoading = false);
        return;
      }

      List<DropdownMenuItem<String>> opciones = [];

      // Agregar las opciones de ministerios
      for (var min in ministerios) {
        opciones.add(DropdownMenuItem(
            value: min,
            child: Row(
              children: [
                Icon(min.contains('Damas') ? Icons.female : Icons.male,
                    color: primaryTeal, size: 18),
                SizedBox(width: 8),
                Text(min),
              ],
            )));
      }

      // Agregar un separador visual
      opciones.add(DropdownMenuItem(
        value: 'separator',
        enabled: false,
        child: Divider(thickness: 2, color: Colors.grey),
      ));

      // Agregar título para Ministerio Juvenil
      opciones.add(DropdownMenuItem(
        value: 'title_juvenil',
        enabled: false,
        child: Row(
          children: [
            Icon(Icons.people_alt, color: primaryTeal, size: 18),
            SizedBox(width: 8),
            Text('Ministerio Juvenil',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: primaryTeal,
                )),
          ],
        ),
      ));

      // Agregar las opciones de tribus del Ministerio Juvenil
      for (var doc in tribusSnapshot.docs) {
        opciones.add(DropdownMenuItem(
            value: doc.id,
            child: Row(
              children: [
                Icon(Icons.groups, color: secondaryOrange, size: 18),
                SizedBox(width: 8),
                Text(doc['nombre'] ?? 'Tribu sin nombre'),
              ],
            )));
      }

      String? seleccion;

      setState(() => _isLoading = false);

      // Mostrar diálogo para seleccionar tribu o ministerio
      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Asignar a Tribu o Ministerio',
                style:
                    TextStyle(color: primaryTeal, fontWeight: FontWeight.bold)),
            content: Container(
              width: double.maxFinite,
              child: DropdownButtonFormField<String>(
                value: seleccion,
                items: opciones,
                onChanged: (value) {
                  if (value != 'separator' && value != 'title_juvenil') {
                    seleccion = value;
                  }
                },
                decoration: InputDecoration(
                  labelText: 'Seleccione una opción',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: primaryTeal, width: 2),
                  ),
                ),
              ),
            ),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancelar', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (seleccion != null) {
                    setState(() => _isLoading = true);
                    Navigator.pop(context);

                    // ✅ CORRECCIÓN PRINCIPAL: Determinar el ministerio correcto
                    String? ministerioAsignado;
                    String? tribuAsignada;
                    String? nombreTribu;

                    if (seleccion!.contains('Ministerio')) {
                      // Es un ministerio directo (Damas o Caballeros)
                      ministerioAsignado = seleccion;
                      tribuAsignada = null;
                      nombreTribu = null;
                    } else {
                      // Es una tribu del Ministerio Juvenil
                      tribuAsignada = seleccion;
                      ministerioAsignado =
                          'Ministerio Juvenil'; // ✅ SIEMPRE asignar Ministerio Juvenil

                      // Obtener el nombre de la tribu
                      final tribuDoc = tribusSnapshot.docs.firstWhere(
                        (doc) => doc.id == seleccion,
                        orElse: () => throw Exception('Tribu no encontrada'),
                      );
                      nombreTribu = tribuDoc['nombre'] ?? 'Tribu sin nombre';
                    }

                    print('=== DEBUG ASIGNACIÓN ===');
                    print('Selección: $seleccion');
                    print('Ministerio asignado: $ministerioAsignado');
                    print('Tribu asignada: $tribuAsignada');
                    print('Nombre tribu: $nombreTribu');
                    print('=======================');

                    // ✅ ACTUALIZAR CON LOS DATOS CORRECTOS
                    Map<String, dynamic> updateData = {
                      'ministerioAsignado': ministerioAsignado,
                      'tribuAsignada': tribuAsignada,
                      'fechaAsignacion': FieldValue.serverTimestamp(),
                    };

                    // Solo agregar nombreTribu si existe
                    if (nombreTribu != null) {
                      updateData['nombreTribu'] = nombreTribu;
                    }

                    // Limpiar campos relacionados si es necesario
                    if (tribuAsignada == null) {
                      updateData['nombreTribu'] = null;
                    }

                    await FirebaseFirestore.instance
                        .collection('registros')
                        .doc(registro.id)
                        .update(updateData);

                    // ✅ VERIFICACIÓN POST-ASIGNACIÓN
                    await Future.delayed(Duration(milliseconds: 500));
                    final docVerificacion = await FirebaseFirestore.instance
                        .collection('registros')
                        .doc(registro.id)
                        .get();

                    if (docVerificacion.exists) {
                      final data =
                          docVerificacion.data() as Map<String, dynamic>;
                      print('=== VERIFICACIÓN POST-ASIGNACIÓN ===');
                      print(
                          'ministerioAsignado guardado: ${data['ministerioAsignado']}');
                      print('tribuAsignada guardada: ${data['tribuAsignada']}');
                      print('nombreTribu guardado: ${data['nombreTribu']}');
                      print('==================================');
                    }

                    setState(() => _isLoading = false);

                    // Mensaje de éxito más específico
                    String mensajeExito;
                    if (ministerioAsignado != null && tribuAsignada != null) {
                      mensajeExito =
                          'Asignado a tribu "$nombreTribu" del $ministerioAsignado';
                    } else if (ministerioAsignado != null) {
                      mensajeExito = 'Asignado al $ministerioAsignado';
                    } else {
                      mensajeExito = 'Registro asignado exitosamente';
                    }

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(mensajeExito),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                        duration: Duration(seconds: 3),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: secondaryOrange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: Text('Asignar'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      _mostrarError('Error al asignar tribu o ministerio: $e');
      setState(() => _isLoading = false);
    }
  }

  void _editarRegistro(BuildContext context, Registro registro) {
    // Controllers from first code
    final nombreController = TextEditingController(text: registro.nombre);
    final apellidoController = TextEditingController(text: registro.apellido);
    final telefonoController = TextEditingController(text: registro.telefono);
    final direccionController = TextEditingController(text: registro.direccion);
    final barrioController = TextEditingController(text: registro.barrio);
    final estadoCivilController =
        TextEditingController(text: registro.estadoCivil);
    final nombreParejaController =
        TextEditingController(text: registro.nombrePareja);
    final ocupacionesController =
        TextEditingController(text: registro.ocupaciones.join(', '));
    final descripcionOcupacionController =
        TextEditingController(text: registro.descripcionOcupacion);
    final referenciaInvitacionController =
        TextEditingController(text: registro.referenciaInvitacion);
    final observacionesController =
        TextEditingController(text: registro.observaciones);
    final estadoFonovisitaController =
        TextEditingController(text: registro.estadoFonovisita);
    final observaciones2Controller =
        TextEditingController(text: registro.observaciones2);

    // Additional controllers from second code
    final edadController =
        TextEditingController(text: registro.edad?.toString() ?? '0');
    final peticionesController =
        TextEditingController(text: registro.peticiones ?? '');
    final sexoController = TextEditingController(text: registro.sexo ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.edit, color: Colors.teal),
              const SizedBox(width: 8),
              const Text(
                'Editar Registro',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSectionTitle('Información Personal'),
                _buildEditTextField(
                  controller: nombreController,
                  label: 'Nombre',
                  icon: Icons.person,
                ),
                const SizedBox(height: 16),
                _buildEditTextField(
                  controller: apellidoController,
                  label: 'Apellido',
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildEditTextField(
                        controller: edadController,
                        label: 'Edad',
                        icon: Icons.cake,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildEditTextField(
                        controller: sexoController,
                        label: 'Sexo',
                        icon: Icons.wc,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildEditTextField(
                  controller: telefonoController,
                  label: 'Teléfono',
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                _buildEditTextField(
                  controller: direccionController,
                  label: 'Dirección',
                  icon: Icons.home,
                ),
                const SizedBox(height: 16),
                _buildEditTextField(
                  controller: barrioController,
                  label: 'Barrio',
                  icon: Icons.location_city,
                ),
                const SizedBox(height: 16),
                _buildEditTextField(
                  controller: estadoCivilController,
                  label: 'Estado Civil',
                  icon: Icons.favorite,
                ),
                const SizedBox(height: 16),
                _buildEditTextField(
                  controller: nombreParejaController,
                  label: 'Nombre de Pareja',
                  icon: Icons.people,
                ),
                const SizedBox(height: 16),
                _buildEditTextField(
                  controller: ocupacionesController,
                  label: 'Ocupaciones (separadas por coma)',
                  icon: Icons.work,
                ),
                const SizedBox(height: 16),
                _buildEditTextField(
                  controller: descripcionOcupacionController,
                  label: 'Descripción Ocupación',
                  icon: Icons.description,
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                _buildEditTextField(
                  controller: peticionesController,
                  label: 'Peticiones',
                  icon: Icons.favorite_border,
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                _buildEditTextField(
                  controller: referenciaInvitacionController,
                  label: 'Referencia Invitación',
                  icon: Icons.link,
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.grey[50],
                    border: Border.all(color: Colors.grey.shade400),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: DropdownButtonFormField<String>(
                    value: registro.estadoFonovisita,
                    decoration: const InputDecoration(
                      labelText: 'Estado de Fonovisita',
                      labelStyle: TextStyle(color: Colors.teal),
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.call, color: Colors.teal),
                    ),
                    items: [
                      'Contactada',
                      'No Contactada',
                      '# Errado',
                      'Apagado',
                      'Buzón',
                      'Número No Activado',
                      '# Equivocado',
                      'Difícil contacto'
                    ]
                        .map((estado) => DropdownMenuItem(
                              value: estado,
                              child: Text(estado),
                            ))
                        .toList(),
                    onChanged: (valor) {
                      estadoFonovisitaController.text = valor ?? '';
                    },
                  ),
                ),
                const SizedBox(height: 16),
                _buildEditTextField(
                  controller: observacionesController,
                  label: 'Observaciones',
                  icon: Icons.note,
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                _buildEditTextField(
                  controller: observaciones2Controller,
                  label: 'Observaciones-2',
                  icon: Icons.note_alt,
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancelar',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                _guardarEdicionRegistro(
                  context,
                  registro,
                  nombreController,
                  apellidoController,
                  telefonoController,
                  direccionController,
                  barrioController,
                  estadoCivilController,
                  nombreParejaController,
                  ocupacionesController,
                  descripcionOcupacionController,
                  referenciaInvitacionController,
                  observacionesController,
                  estadoFonovisitaController,
                  observaciones2Controller,
                  edadController,
                  sexoController,
                  peticionesController,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.teal,
        ),
      ),
    );
  }

  Widget _buildEditTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.teal),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.teal, width: 2),
        ),
        prefixIcon: Icon(icon, color: Colors.teal),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }

  Future<void> _guardarEdicionRegistro(
    BuildContext context,
    Registro registro,
    TextEditingController nombreController,
    TextEditingController apellidoController,
    TextEditingController telefonoController,
    TextEditingController direccionController,
    TextEditingController barrioController,
    TextEditingController estadoCivilController,
    TextEditingController nombreParejaController,
    TextEditingController ocupacionesController,
    TextEditingController descripcionOcupacionController,
    TextEditingController referenciaInvitacionController,
    TextEditingController observacionesController,
    TextEditingController estadoFonovisitaController,
    TextEditingController observaciones2Controller,
    TextEditingController edadController,
    TextEditingController sexoController,
    TextEditingController peticionesController,
  ) async {
    try {
      registro.nombre = nombreController.text;
      registro.apellido = apellidoController.text;
      registro.telefono = telefonoController.text;
      registro.direccion = direccionController.text;
      registro.barrio = barrioController.text;
      registro.estadoCivil = estadoCivilController.text;
      registro.nombrePareja = nombreParejaController.text;
      registro.ocupaciones =
          ocupacionesController.text.split(',').map((e) => e.trim()).toList();
      registro.descripcionOcupacion = descripcionOcupacionController.text;
      registro.referenciaInvitacion = referenciaInvitacionController.text;
      registro.observaciones = observacionesController.text;
      registro.estadoFonovisita = estadoFonovisitaController.text;
      registro.observaciones2 = observaciones2Controller.text;
      registro.edad = int.tryParse(edadController.text) ?? 0;
      registro.sexo = sexoController.text;
      registro.peticiones = peticionesController.text;

      await _firestoreService.actualizarRegistro(registro.id!, registro);
      Navigator.pop(context);
      _mostrarExito('Registro actualizado exitosamente');
    } catch (e) {
      _mostrarError('Error al actualizar: $e');
    }
  }

  void _editarConsolidador(
      BuildContext context, Map<String, String> consolidador) {
    final controlador = TextEditingController(text: consolidador['nombre']);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.edit, color: primaryTeal),
              const SizedBox(width: 8),
              const Text(
                'Editar Consolidador',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: TextField(
            controller: controlador,
            decoration: InputDecoration(
              labelText: 'Nombre del Consolidador',
              labelStyle: TextStyle(color: primaryTeal),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: primaryTeal, width: 2),
              ),
              prefixIcon: Icon(Icons.person, color: primaryTeal),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancelar',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _firestoreService.actualizarConsolidador(
                    consolidador['id']!,
                    controlador.text,
                  );
                  Navigator.pop(context);
                  _mostrarExito('Consolidador actualizado exitosamente');
                } catch (e) {
                  _mostrarError('Error al actualizar: $e');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryTeal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 3,
              ),
              child: const Text(
                'Guardar',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Método auxiliar para mostrar el mensaje de éxito con animación
  void _mostrarExitoAnimado(String mensaje) {
    showGeneralDialog(
      context: context,
      pageBuilder: (context, animation1, animation2) => Container(),
      transitionBuilder: (context, animation1, animation2, child) {
        return ScaleTransition(
          scale: Tween<double>(begin: 0.5, end: 1.0).animate(animation1),
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: Colors.green.shade50,
            title: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 30),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    mensaje,
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            content: const SizedBox(height: 20),
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black54,
    );

    Future.delayed(const Duration(seconds: 1), () {
      Navigator.of(context).pop();
    });
  }

  // Método auxiliar para efectos de hover en botones
  Widget _buildAnimatedButton({
    required VoidCallback onPressed,
    required Widget child,
    required Color baseColor,
  }) {
    return StatefulBuilder(
      builder: (context, setState) {
        bool isHovered = false;

        return MouseRegion(
          onEnter: (_) => setState(() => isHovered = true),
          onExit: (_) => setState(() => isHovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            transform: isHovered
                ? (Matrix4.identity()..scale(1.05))
                : Matrix4.identity(),
            child: ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isHovered ? baseColor.withOpacity(0.9) : baseColor,
                elevation: isHovered ? 8 : 4,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: child,
            ),
          ),
        );
      },
    );
  }

  // Widget para tarjetas con efecto de elevación al hover
  Widget _buildHoverCard({
    required Widget child,
    double initialElevation = 4,
    double hoverElevation = 8,
  }) {
    return StatefulBuilder(
      builder: (context, setState) {
        bool isHovered = false;

        return MouseRegion(
          onEnter: (_) => setState(() => isHovered = true),
          onExit: (_) => setState(() => isHovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: isHovered ? hoverElevation : initialElevation,
                  spreadRadius: isHovered ? 2 : 1,
                ),
              ],
            ),
            child: child,
          ),
        );
      },
    );
  }
}

class ChartData {
  final String label;
  final int value;
  final Color color;

  ChartData(this.label, this.value, {this.color = Colors.blue});
}

// Componente de tarjeta expansible personalizada
class ExpansionCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color textColor;
  final Color expandedColor;
  final List<Widget> children;

  const ExpansionCard({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.textColor,
    required this.expandedColor,
    required this.children,
  }) : super(key: key);

  @override
  _ExpansionCardState createState() => _ExpansionCardState();
}

class _ExpansionCardState extends State<ExpansionCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: widget.iconColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      widget.icon,
                      color: widget.iconColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: widget.textColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.subtitle,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: widget.textColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox(height: 0),
          secondChild: Container(
            decoration: BoxDecoration(
              color: widget.expandedColor,
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.only(top: 2, bottom: 8, left: 4, right: 4),
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: widget.children,
            ),
          ),
          crossFadeState: _isExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 300),
        ),
      ],
    );
  }
}
