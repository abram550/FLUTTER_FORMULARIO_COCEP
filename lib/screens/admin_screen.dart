import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:formulario_app/models/registro.dart';
import 'package:formulario_app/models/social_profile.dart';
import 'package:formulario_app/services/firestore_service.dart';
import 'package:formulario_app/services/excel_service.dart';
import 'package:intl/intl.dart';
import 'TribusScreen.dart';
import 'package:fl_chart/fl_chart.dart';

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

  @override
  void initState() {
    super.initState();
    _loadData();
    _setupAnimations();
    final now = DateTime.now();
    _anioSeleccionado = now.year;
    _mesSeleccionado = _getMesNombre(now.month);
    _cargando = true;
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
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Obtener los años desde los registros
      final registros = await _firestoreService.obtenerTodosLosRegistros();
      Set<int> aniosDisponibles = registros.map((r) => r.fecha.year).toSet();

      if (aniosDisponibles.isNotEmpty) {
        setState(() {
          _aniosDisponibles = aniosDisponibles.toList()..sort();
          _anioSeleccionado = _aniosDisponibles.isNotEmpty
              ? _aniosDisponibles.last // Seleccionar el año más reciente
              : DateTime.now().year;
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
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.9,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Cabecera fija
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
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
                          IconButton(
                            icon: Icon(Icons.close, color: primaryTeal),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                    const Divider(thickness: 1),

                    // Contenido con scroll
                    Flexible(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          child: Column(
                            children: [
                              const SizedBox(height: 15),

                              // Selección de tipo de datos
                              Card(
                                elevation: 3,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: Row(
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

                              const SizedBox(height: 15),

                              // Selección de período
                              Card(
                                elevation: 3,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(2.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            left: 8.0, bottom: 5),
                                        child: Text(
                                          "Período",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: primaryTeal,
                                          ),
                                        ),
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          _buildFiltroButton(
                                              "Semanal", "semanal", setState),
                                          _buildFiltroButton(
                                              "Mensual", "mensual", setState),
                                          _buildFiltroButton(
                                              "Anual", "anual", setState),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 15),

                              // Filtro por fecha
                              Card(
                                elevation: 3,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: _buildFiltroPorFecha(setState),
                                ),
                              ),

                              const SizedBox(height: 15),

                              // Selección de tipo de visualización
                              Card(
                                elevation: 3,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            left: 8.0, bottom: 5),
                                        child: Text(
                                          "Tipo de gráfica",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: primaryTeal,
                                          ),
                                        ),
                                      ),
                                      Row(
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

                              const SizedBox(height: 20),

                              // Gráfica con LayoutBuilder para ser responsiva
                              LayoutBuilder(builder: (context, constraints) {
                                return SizedBox(
                                  height: constraints.maxWidth > 600
                                      ? 400 // Altura para pantallas grandes
                                      : 300, // Altura para pantallas pequeñas
                                  child: Card(
                                    elevation: 4,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(15),
                                      child: _buildGrafica(setState),
                                    ),
                                  ),
                                );
                              }),
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
          child: Text(
            titulo,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
      ),
      label: Text(
        titulo,
        style: TextStyle(
          color: isSelected ? Colors.white : primaryTeal,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
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
          label: Text(
            titulo,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
              mainAxisSize: MainAxisSize.min, // Reducir tamaño vertical
              children: [
                CircularProgressIndicator(color: secondaryOrange),
                const SizedBox(height: 8), // Reducido de 15 a 8
                Text(
                  "Cargando datos...",
                  style: TextStyle(
                    color: primaryTeal,
                    fontWeight: FontWeight.bold,
                    fontSize: 14, // Tamaño de fuente reducido
                  ),
                ),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min, // Reducir tamaño vertical
              children: [
                Icon(Icons.error_outline,
                    color: Colors.red, size: 32), // Reducido de 40 a 32
                const SizedBox(height: 6), // Reducido de 10 a 6
                Text(
                  "Error al cargar datos: ${snapshot.error}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 13, // Tamaño de fuente reducido
                  ),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min, // Reducir tamaño vertical
              children: [
                Icon(Icons.info_outline,
                    color: primaryTeal, size: 32), // Reducido de 40 a 32
                const SizedBox(height: 6), // Reducido de 10 a 6
                Text(
                  "No hay datos disponibles",
                  style: TextStyle(
                    color: primaryTeal,
                    fontWeight: FontWeight.bold,
                    fontSize: 13, // Tamaño de fuente reducido
                  ),
                ),
              ],
            ),
          );
        }

        final datos = snapshot.data!;
        final tipoActual = datos[_tipoGrafica] ?? [];

        return Column(
          children: [
            // Título más compacto
            Padding(
              padding: const EdgeInsets.symmetric(
                  vertical: 6.0), // Reducido de 10 a 6
              child: Text(
                "${_tipoGrafica == 'consolidacion' ? 'Consolidación' : 'Redes Sociales'} - ${_filtroSeleccionado.substring(0, 1).toUpperCase() + _filtroSeleccionado.substring(1)}",
                style: TextStyle(
                  fontSize: 16, // Reducido de 20 a 16
                  fontWeight: FontWeight.bold,
                  color: primaryTeal,
                  shadows: [
                    Shadow(
                      offset: const Offset(0, 1),
                      blurRadius: 2,
                      color: Colors.black
                          .withOpacity(0.15), // Ligeramente más sutil
                    ),
                  ],
                ),
              ),
            ),
            const Divider(thickness: 1), // Reducido de 1.5 a 1
            const SizedBox(height: 5), // Reducido de 10 a 5

            // Añadir selector de tipo de visualización más compacto
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildVisualizationToggle('barras', Icons.bar_chart),
                  _buildVisualizationToggle('lineal', Icons.show_chart),
                  _buildVisualizationToggle('circular', Icons.pie_chart),
                ],
              ),
            ),
            const SizedBox(height: 5),

            // Contenido de la gráfica con mayor espacio
            Expanded(
              child: _renderizarGrafica(tipoActual),
            ),

            // Leyenda más compacta
            _buildLeyendaCompacta(tipoActual),
          ],
        );
      },
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

    // Contenedor con dimensiones apropiadas y padding reducido
    return Container(
      padding: const EdgeInsets.all(8), // Reducido de 12 a 8
      height: MediaQuery.of(context).size.height *
          0.45, // Aumentado ligeramente para dar más espacio a la gráfica
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
  int _barTouchedIndex = -1;
  int _lineSpotTouched = -1;
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

      // Obtener datos de consolidación (ajustado para filtrar por año y mes)
      List<QueryDocumentSnapshot> consolidacionDocs =
          await _obtenerDocumentosFiltrados(
              "registros", _anioSeleccionado, _mesSeleccionado);

      // Obtener datos de redes sociales (ajustado para filtrar por año y mes)
      List<QueryDocumentSnapshot> redesDocs = await _obtenerDocumentosFiltrados(
          "social_profiles", _anioSeleccionado, _mesSeleccionado);

      // Procesar los datos según el filtro seleccionado
      List<ChartData> consolidacion =
          _procesarDatosPorPeriodo(consolidacionDocs, consolidacionColors);

      List<ChartData> redes = _procesarDatosPorPeriodo(redesDocs, redesColors);

      return {
        "consolidacion": consolidacion,
        "redes": redes,
      };
    } catch (e) {
      print("Error al obtener datos para gráfica: $e");
      return {
        "consolidacion": [],
        "redes": [],
      };
    }
  }

// Método actualizado para obtener documentos filtrados por año y mes
  Future<List<QueryDocumentSnapshot>> _obtenerDocumentosFiltrados(
      String coleccion, int anioFiltro, String mesFiltro) async {
    try {
      final snapshot = await _firestore.collection(coleccion).get();
      final int mesIndex = _getMonthIndex(mesFiltro);

      return snapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>?;
        final fecha = _convertirFecha(data?['fecha'] ?? data?['createdAt']);

        if (_filtroSeleccionado == "anual") {
          if (anioFiltro == -1) {
            // "Todos los años"
            return true; // No filtrar por año, mostrar todo
          } else {
            return fecha.year == anioFiltro;
          }
        } else if (mesFiltro == "Todos los meses") {
          return fecha.year == anioFiltro;
        } else {
          return fecha.year == anioFiltro && fecha.month == mesIndex;
        }
      }).toList();
    } catch (e) {
      print("Error al obtener documentos filtrados: $e");
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

    final now = DateTime.now();
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
        for (int i = 0; i < 4; i++) {
          final fechaReferencia =
              DateTime(_anioSeleccionado, _getMonthIndex(_mesSeleccionado), 1);
          resultados[
              "Semana ${i + 1} de ${DateFormat('MMMM', 'es_ES').format(fechaReferencia)} - $_anioSeleccionado"] = 0;
        }

        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>?;
          final fecha = _convertirFecha(data?['fecha'] ?? data?['createdAt']);

          if (fecha.year == _anioSeleccionado &&
              fecha.month == _getMonthIndex(_mesSeleccionado)) {
            int weekOfMonth = ((fecha.day - 1) ~/ 7) + 1;
            if (weekOfMonth > 4) weekOfMonth = 4;
            resultados[
                    "Semana $weekOfMonth de ${DateFormat('MMMM', 'es_ES').format(fecha)} - ${fecha.year}"] =
                (resultados["Semana $weekOfMonth de ${DateFormat('MMMM', 'es_ES').format(fecha)} - ${fecha.year}"] ??
                        0) +
                    1;
          }
        }
        break;

      case "mensual":
        if (_mesSeleccionado == "Todos los meses") {
          for (var mes in ordenMeses) {
            resultados["$mes - $_anioSeleccionado"] = 0;
          }

          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>?;
            final fecha = _convertirFecha(data?['fecha'] ?? data?['createdAt']);

            if (fecha.year == _anioSeleccionado) {
              final mesNombre = ordenMeses[fecha.month - 1];
              resultados["$mesNombre - ${fecha.year}"] =
                  (resultados["$mesNombre - ${fecha.year}"] ?? 0) + 1;
            }
          }
        } else {
          for (int i = 1; i <= 12; i++) {
            final monthStr = DateFormat('MMMM', 'es_ES')
                .format(DateTime(_anioSeleccionado, i));
            resultados["$monthStr - $_anioSeleccionado"] = 0;
          }

          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>?;
            final fecha = _convertirFecha(data?['fecha'] ?? data?['createdAt']);

            if (fecha.year == _anioSeleccionado) {
              final monthStr = DateFormat('MMMM', 'es_ES').format(fecha);
              resultados["$monthStr - ${fecha.year}"] =
                  (resultados["$monthStr - ${fecha.year}"] ?? 0) + 1;
            }
          }
        }
        break;

      case "anual":
        Set<int> anios = docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>?;
          final fecha = _convertirFecha(data?['fecha'] ?? data?['createdAt']);
          return fecha.year;
        }).toSet();

        if (anios.isEmpty) break;

        List<int> aniosOrdenados = anios.toList()..sort();
        for (int anio in aniosOrdenados) {
          resultados["$anio"] = 0;
        }

        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>?;
          final fecha = _convertirFecha(data?['fecha'] ?? data?['createdAt']);
          resultados["${fecha.year}"] = (resultados["${fecha.year}"] ?? 0) + 1;
        }

        aniosOrdenados.forEach((anio) {
          chartData.add(ChartData(
            anio.toString(),
            resultados["$anio"]!,
            color: colors[colorIndex % colors.length],
          ));
          colorIndex++;
        });
        return chartData; // ← IMPORTANTE: Rompe el flujo aquí para evitar duplicados
    }

    if (_filtroSeleccionado == "mensual" &&
        _mesSeleccionado == "Todos los meses") {
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
    } else if (_filtroSeleccionado != "anual") {
      // Evita agregar duplicados después del case "anual"
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

  DateTime _convertirFecha(dynamic fecha) {
    if (fecha is Timestamp) {
      return fecha.toDate();
    } else if (fecha is String) {
      try {
        return DateTime.parse(fecha);
      } catch (e) {
        print('Error al parsear fecha: \$fecha');
        return DateTime.now();
      }
    } else {
      return DateTime.now();
    }
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                          child: Row(
                            children: [
                              Icon(
                                Icons.people_alt_rounded,
                                size: 26,
                                color: secondaryOrange,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Perfiles de Redes Sociales',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: primaryTeal,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: primaryTeal,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${filteredPerfiles.length} registros',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 24),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredPerfiles.length,
                          itemBuilder: (context, index) {
                            final perfil = filteredPerfiles[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                leading: CircleAvatar(
                                  radius: 24,
                                  backgroundColor:
                                      secondaryOrange.withOpacity(0.2),
                                  child: Text(
                                    perfil.name[0].toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 20,
                                      color: secondaryOrange,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  '${perfil.name} ${perfil.lastName}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: primaryTeal,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.cake,
                                            size: 16, color: Colors.grey[600]),
                                        const SizedBox(width: 4),
                                        Text('${perfil.age} años'),
                                        const SizedBox(width: 12),
                                        Icon(
                                            perfil.gender.toLowerCase() ==
                                                    'masculino'
                                                ? Icons.male
                                                : Icons.female,
                                            size: 16,
                                            color: Colors.grey[600]),
                                        const SizedBox(width: 4),
                                        Text(perfil.gender),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.public,
                                            size: 16, color: Colors.grey[600]),
                                        const SizedBox(width: 4),
                                        Text(perfil.socialNetwork),
                                        const SizedBox(width: 12),
                                        Icon(Icons.calendar_today,
                                            size: 16, color: Colors.grey[600]),
                                        const SizedBox(width: 4),
                                        Text(DateFormat('dd/MM/yyyy')
                                            .format(perfil.createdAt)),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: Icon(
                                    Icons.visibility,
                                    color: primaryTeal,
                                  ),
                                  tooltip: 'Ver detalles',
                                  onPressed: () =>
                                      _mostrarDetallesPerfil(context, perfil),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
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

                    await FirebaseFirestore.instance
                        .collection('registros')
                        .doc(registro.id)
                        .update({
                      'tribuAsignada':
                          seleccion!.contains('Ministerio') ? null : seleccion,
                      'ministerioAsignado':
                          seleccion!.contains('Ministerio') ? seleccion : null,
                      'fechaAsignacion': FieldValue.serverTimestamp(),
                    });

                    setState(() => _isLoading = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Registro asignado exitosamente'),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
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
