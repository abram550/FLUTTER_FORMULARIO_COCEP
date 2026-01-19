// Dart SDK
import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

// Flutter
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

// Firebase
import 'package:cloud_firestore/cloud_firestore.dart';

// Paquetes externos
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:screenshot/screenshot.dart';
import 'package:universal_html/html.dart' as html;

// Proyecto
import 'package:formulario_app/models/registro.dart';
import 'package:formulario_app/models/social_profile.dart';
import 'package:formulario_app/services/firestore_service.dart';
import 'package:formulario_app/services/excel_service.dart';

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
  int _anioSeleccionado = -1; // ✅ Inicializar directamente en -1
  late String _mesSeleccionado;
  bool _isSearching = false;
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  List<int> _aniosDisponibles = [];

  bool _cargando = false;

// Variables para controlar la visibilidad de los filtros desplegables
  bool _mostrarFiltroExportacion = false;
  bool _mostrarFiltroTipo = false;
  bool _detailsTableExpanded =
      false; // Controla si la tabla de detalles está desplegada

  String _tipoAgrupacionMensual = "dias";

// Variables para filtros por semana con controladores
  Map<String, String?> _filtrosSexoPorSemana = {};
  Map<String, int?> _filtrosEdadPorSemana = {};
  Map<String, TextEditingController> _controladoresEdadPorSemana = {};

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

// Variables para filtro por tipo de registro
  String?
      _filtroTipoRegistro; // null = todos, "nuevo" = nuevos, "visita" = visitas

  List<Map<String, String>> _consolidadores = [];

// Variables para el manejo de sesión - AGREGAR ESTAS LÍNEAS
  Timer? _inactivityTimer;
  static const Duration _inactivityDuration = Duration(minutes: 15);

  // Variables para mantener el estado de expansión de las agrupaciones
Map<int, bool> _aniosExpandidos = {};
Map<String, bool> _mesesExpandidos = {}; // key: "año-mes"
Map<String, bool> _semanasExpandidas = {}; // key: "año-mes-semana"
Map<String, bool> _diasExpandidos = {}; // key: "año-mes-día"

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _cargando = true;
    // ✅ Mantener _anioSeleccionado en -1 hasta que se carguen los datos
    final now = DateTime.now();
    _mesSeleccionado = _getMesNombre(now.month);
    _loadData(); // ✅ Llamar al final
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

    // Limpiar controladores de edad
    _controladoresEdadPorSemana.forEach((key, controller) {
      controller.dispose();
    });
    _controladoresEdadPorSemana.clear();

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
    print('🚀 === INICIANDO _loadData ===');
    setState(() => _isLoading = true);

    try {
      final snapshot = await _firestore.collection('registros').get();
      print('📊 Total documentos en "registros": ${snapshot.docs.length}');

      final Set<int> anios = {};

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>?;

        // ✅ MANEJO SEGURO: Verificar que exista el campo 'fecha' y sea un Timestamp
        if (data == null ||
            !data.containsKey('fecha') ||
            data['fecha'] == null) {
          print('  ⚠️ Doc ${doc.id}: Sin campo "fecha" válido - ignorado');
          continue;
        }

        try {
          // ✅ CONVERSIÓN SEGURA: Intentar convertir a DateTime
          final fechaField = data['fecha'];
          DateTime? fecha;

          if (fechaField is Timestamp) {
            fecha = fechaField.toDate();
          } else if (fechaField is String) {
            fecha = DateTime.tryParse(fechaField);
          }

          // ✅ Si se obtuvo una fecha válida, agregar el año
          if (fecha != null) {
            anios.add(fecha.year);
            print('  ✅ Doc ${doc.id}: Año ${fecha.year} agregado');
          } else {
            print(
                '  ⚠️ Doc ${doc.id}: Campo "fecha" no es Timestamp ni String válido');
          }
        } catch (e) {
          print('  ❌ Doc ${doc.id}: Error al procesar fecha: $e');
        }
      }

      if (anios.isNotEmpty) {
        final lista = anios.toList()..sort();

        setState(() {
          _aniosDisponibles = lista;

          // ✅ CORRECCIÓN PRINCIPAL: Seleccionar el año MÁS RECIENTE con datos
          _anioSeleccionado = _aniosDisponibles.last;

          // ✅ Para vista mensual/semanal inicial, mostrar "Todos los meses"
          if (_filtroSeleccionado == "mensual" ||
              _filtroSeleccionado == "semanal") {
            _mesSeleccionado = "Todos los meses";
          }
        });

        print('📅 Años disponibles (con datos): $_aniosDisponibles');
        print('🎯 Año seleccionado automáticamente: $_anioSeleccionado');
      } else {
        print('⚠️ No se encontraron documentos con fecha válida');

        // ✅ FALLBACK: Si no hay datos, usar año actual
        final currentYear = DateTime.now().year;
        setState(() {
          _aniosDisponibles = [currentYear];
          _anioSeleccionado = currentYear;
        });
        print('ℹ️ Usando año actual como fallback: $currentYear');
      }

      _inicializarStreams();
    } catch (e, stackTrace) {
      print('❌ ERROR CRÍTICO en _loadData: $e');
      print('Stack trace: $stackTrace');
      _mostrarError('Error cargando datos: $e');
    } finally {
      setState(() => _isLoading = false);
      print('🏁 === FIN _loadData ===\n');
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
      // ✅ FILTRO CRÍTICO: Ignorar registros de perfiles sociales
      // Verificar si el registro proviene de un perfil social
      final origenPerfilSocial = registro.origenPerfilSocial ?? false;
      final perfilSocialId = registro.perfilSocialId;

      // Si tiene alguno de estos campos, NO incluirlo en la agrupación
      if (origenPerfilSocial == true ||
          (perfilSocialId != null &&
              perfilSocialId.toString().trim().isNotEmpty)) {
        print(
            '⚠️ Registro ignorado en agrupación (origen perfil social): ${registro.id}');
        continue; // Saltar este registro
      }

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
          toolbarHeight: null, // Permite altura automática
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [primaryTeal, primaryTeal.withOpacity(0.8)],
              ),
            ),
          ),

          // ✅ TÍTULO CON LOGO Y DISEÑO PROFESIONAL
          title: _isSearching
              ? TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: "Buscar por nombre o apellido...",
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: Colors.white70),
                    isCollapsed: true,
                  ),
                  style: const TextStyle(color: Colors.white),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final double availableWidth = constraints.maxWidth;

                    // Detectar tamaño de pantalla
                    final bool isVerySmallScreen = availableWidth < 280;
                    final bool isSmallScreen = availableWidth < 420;
                    final bool isMediumScreen =
                        availableWidth >= 420 && availableWidth < 600;

                    return Row(
                      children: [
                        // ✅ LOGO CON ANIMACIÓN HERO
                        Hero(
                          tag: 'logo_cocep_admin',
                          child: Container(
                            padding: EdgeInsets.all(isVerySmallScreen ? 2 : 3),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Container(
                              height: isVerySmallScreen
                                  ? 32
                                  : (isSmallScreen ? 36 : 40),
                              width: isVerySmallScreen
                                  ? 32
                                  : (isSmallScreen ? 36 : 40),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  'assets/Cocep_.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                            width: isVerySmallScreen
                                ? 8
                                : (isSmallScreen ? 10 : 12)),

                        // ✅ TÍTULO RESPONSIVO CON MÚLTIPLES LÍNEAS
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Primera línea: "Panel de Control"
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Panel de Control',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.95),
                                    fontWeight: FontWeight.w600,
                                    fontSize: isVerySmallScreen
                                        ? 15
                                        : (isSmallScreen
                                            ? 17
                                            : (isMediumScreen ? 19 : 21)),
                                    height: 1.1,
                                    letterSpacing: 0.3,
                                    shadows: [
                                      Shadow(
                                        offset: const Offset(0, 1),
                                        blurRadius: 2,
                                        color: Colors.black.withOpacity(0.2),
                                      ),
                                    ],
                                  ),
                                  maxLines: 1,
                                ),
                              ),
                              const SizedBox(height: 2),

                              // Segunda línea: "de Consolidación"
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'de Consolidación',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: isVerySmallScreen
                                        ? 17
                                        : (isSmallScreen
                                            ? 19
                                            : (isMediumScreen ? 21 : 24)),
                                    height: 1.1,
                                    letterSpacing: 0.5,
                                    shadows: [
                                      Shadow(
                                        offset: const Offset(0, 2),
                                        blurRadius: 4,
                                        color: Colors.black.withOpacity(0.3),
                                      ),
                                    ],
                                  ),
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),

          actions: [
            // Botón de búsqueda
            IconButton(
              icon: Icon(
                _isSearching ? Icons.close : Icons.search,
                color: Colors.white,
                size: 22,
              ),
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
              tooltip: _isSearching ? 'Cerrar búsqueda' : 'Buscar',
            ),

            // ✅ BOTÓN DE CERRAR SESIÓN - ADAPTATIVO (solo ícono en pantallas pequeñas)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Detectar si la pantalla es pequeña basándose en el ancho del MediaQuery
                  final screenWidth = MediaQuery.of(context).size.width;
                  final isSmallScreen = screenWidth < 500;

                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _confirmarCerrarSesion,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        constraints: BoxConstraints(
                          minWidth: isSmallScreen ? 44 : 70,
                          maxWidth: isSmallScreen ? 44 : 100,
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 10 : 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withOpacity(0.25),
                              Colors.white.withOpacity(0.15),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.6),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: isSmallScreen
                            ? const Icon(
                                Icons.logout_rounded,
                                color: Colors.white,
                                size: 20,
                              )
                            : FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.center,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(
                                      Icons.logout_rounded,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    SizedBox(width: 5),
                                    Text(
                                      'Cerrar\nsesión',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.3,
                                        height: 1.1,
                                        shadows: [
                                          Shadow(
                                            offset: Offset(0, 1),
                                            blurRadius: 2,
                                            color: Colors.black26,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],

          // Tabs responsivos
          bottom: TabBar(
            indicatorColor: secondaryOrange,
            indicatorWeight: 4,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              letterSpacing: 0.3,
            ),
            tabs: [
              Tab(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 90) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.assignment,
                              color: secondaryOrange, size: 18),
                          const SizedBox(height: 2),
                          const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text('Registros'),
                          ),
                        ],
                      );
                    }
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.assignment,
                            color: secondaryOrange, size: 20),
                        const SizedBox(width: 6),
                        const Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text('Registros'),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              Tab(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 110) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people, color: secondaryOrange, size: 18),
                          const SizedBox(height: 2),
                          const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text('Consolidadores'),
                          ),
                        ],
                      );
                    }
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people, color: secondaryOrange, size: 20),
                        const SizedBox(width: 6),
                        const Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text('Consolidadores'),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              Tab(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 110) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_alt,
                              color: secondaryOrange, size: 18),
                          const SizedBox(height: 2),
                          const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text('Perfiles Sociales'),
                          ),
                        ],
                      );
                    }
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_alt,
                            color: secondaryOrange, size: 20),
                        const SizedBox(width: 6),
                        const Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text('Perfiles Sociales'),
                          ),
                        ),
                      ],
                    );
                  },
                ),
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
            final size = MediaQuery.of(context).size;
            final isSmallScreen = size.width < 600;
            final isMediumScreen = size.width >= 600 && size.width < 900;
            final isLargeScreen = size.width >= 900;
            final isVerySmallScreen = size.width < 400;

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
                  maxHeight: size.height * 0.90,
                  maxWidth: isLargeScreen ? 1200 : double.infinity,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header fijo
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

                    // Contenido con scroll
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

                              // Selección de tipo de datos
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

                              // Selección de período
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

                              // Selección de tipo de visualización
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

                              // Gráfica con tabla desplegable - AJUSTADA
                              _buildGraficaConTabla(
                                  setState, isSmallScreen, isVerySmallScreen),
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

  /// ✅ NUEVO MÉTODO: Gráfica con tabla desplegable integrada

  Widget _buildGraficaConTabla(
      StateSetter setDialogState, bool isSmallScreen, bool isVerySmallScreen) {
    return FutureBuilder<Map<String, List<ChartData>>>(
      future: _obtenerDatosParaGrafica(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: 300,
            child: Center(
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
            ),
          );
        }

        if (snapshot.hasError) {
          return SizedBox(
            height: 300,
            child: Center(
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
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return SizedBox(
            height: 300,
            child: Center(
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
            ),
          );
        }

        final datos = snapshot.data!;
        final tipoActual = datos[_tipoGrafica] ?? [];

        if (tipoActual.isEmpty) {
          return SizedBox(
            height: 300,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.info_outline, color: primaryTeal, size: 32),
                  const SizedBox(height: 6),
                  Text(
                    "No hay datos para mostrar",
                    style: TextStyle(
                      color: primaryTeal,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // ✅ ALTURA DINÁMICA MEJORADA - MÁS ESPACIO PARA LA GRÁFICA
        double chartHeight;
        if (_tipoVisualizacion == "circular") {
          chartHeight = isVerySmallScreen
              ? 350 // Aumentado de 250 a 350
              : isSmallScreen
                  ? 400 // Aumentado de 280 a 400
                  : 450; // Aumentado de 320 a 450
        } else {
          chartHeight = isVerySmallScreen
              ? 380 // Aumentado de 280 a 380
              : isSmallScreen
                  ? 420 // Aumentado de 320 a 420
                  : 480; // Aumentado de 360 a 480
        }

        return Column(
          children: [
            // ✅ Gráfica con altura mejorada
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Container(
                height: chartHeight,
                width: double.infinity,
                padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                child: Screenshot(
                  controller: _screenshotController,
                  child: RepaintBoundary(
                    key: _chartKey,
                    child: Container(
                      color: Colors.white,
                      padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
                      child: Column(
                        children: [
                          // Título de la gráfica - MÁS COMPACTO
                          Padding(
                            padding: EdgeInsets.symmetric(
                                vertical: isSmallScreen ? 2 : 4),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                "${_tipoGrafica == 'consolidacion' ? 'Consolidación' : 'Redes Sociales'} - ${_filtroSeleccionado.substring(0, 1).toUpperCase() + _filtroSeleccionado.substring(1)}",
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 13 : 15,
                                  fontWeight: FontWeight.bold,
                                  color: primaryTeal,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          Divider(thickness: 1, height: isSmallScreen ? 6 : 8),
                          SizedBox(height: isSmallScreen ? 2 : 4),

                          // ✅ GRÁFICA PRINCIPAL - ESPACIO MÁXIMO
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                double availableHeight = constraints.maxHeight;
                                double availableWidth = constraints.maxWidth;

                                // ✅ AJUSTE PARA GRÁFICA CIRCULAR - MEJOR PROPORCIÓN
                                if (_tipoVisualizacion == 'circular') {
                                  double maxDimension = min(
                                      availableHeight * 0.75,
                                      availableWidth * 0.75);

                                  return Center(
                                    child: SizedBox(
                                      height: maxDimension,
                                      width: maxDimension,
                                      child: _renderizarGrafica(tipoActual),
                                    ),
                                  );
                                }

                                // Para barras y líneas - USAR TODO EL ESPACIO
                                return Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isSmallScreen ? 2 : 4,
                                    vertical: isSmallScreen ? 2 : 4,
                                  ),
                                  child: _renderizarGrafica(tipoActual),
                                );
                              },
                            ),
                          ),

                          // Leyenda compacta - MÁS PEQUEÑA
                          _buildLeyendaUltraCompacta(tipoActual, isSmallScreen),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 15),

            // ✅ Tabla desplegable de detalles
            _buildExpandableDetailsTable(
                tipoActual, isVerySmallScreen, setDialogState),
          ],
        );
      },
    );
  }

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
                          height: 1200, // ✅ Aumentado para incluir tabla
                          color: Colors.white,
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Encabezado
                              _buildExportHeader(tipoActual),
                              const SizedBox(height: 20),

                              // Contenedor de la gráfica
                              Expanded(
                                flex: 3,
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

                              // ✅ NUEVA TABLA PARA EXPORTACIÓN
                              Expanded(
                                flex: 2,
                                child: _buildExportTable(tipoActual),
                              ),

                              const SizedBox(height: 16),

                              // Pie de página
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
              reservedSize: 60,
              interval: 1,
              getTitlesWidget: (value, meta) {
                if (value < 0 || value >= datos.length) return const Text('');
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  space: 8,
                  child: Transform.rotate(
                    angle: -pi / 4,
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
            // ✅ AGREGAR ETIQUETAS EN CADA PUNTO
            showingIndicators: List.generate(datos.length, (index) => index),
          ),
        ],
        showingTooltipIndicators: datos.asMap().entries.map((entry) {
          return ShowingTooltipIndicators([
            LineBarSpot(
              LineChartBarData(
                spots: datos.asMap().entries.map((e) {
                  return FlSpot(e.key.toDouble(), e.value.value.toDouble());
                }).toList(),
              ),
              entry.key,
              FlSpot(entry.key.toDouble(), entry.value.value.toDouble()),
            ),
          ]);
        }).toList(),
        lineTouchData: LineTouchData(
          enabled: false, // ✅ No interacción necesaria en el PNG
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: Colors.transparent, // ✅ Sin “caja”
            tooltipPadding: EdgeInsets.zero, // ✅ Sin padding
            tooltipMargin: 10, // ✅ Queda encima del punto
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                return LineTooltipItem(
                  '${spot.y.toInt()}',
                  const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

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
            radius: 120, // ✅ Radio reducido para exportación
            titleStyle: TextStyle(
              fontSize: 16,
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
              padding: const EdgeInsets.all(8),
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
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    data.value.toString(),
                    style: TextStyle(
                      color: Colors.grey.shade800,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            badgePositionPercentageOffset: 1.25,
          );
        }).toList(),
        sectionsSpace: 2,
        centerSpaceRadius: 40, // ✅ Radio central reducido
        centerSpaceColor: Colors.white,
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
                'Panel de Control de Consolidación',
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

  /// Construye la tabla de datos para exportación
  Widget _buildExportTable(List<ChartData> datos) {
    if (datos.isEmpty) return const SizedBox();

    final total = datos.fold(0, (sum, item) => sum + item.value);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título
          Row(
            children: [
              Icon(Icons.table_chart, color: primaryTeal, size: 24),
              const SizedBox(width: 8),
              Text(
                'Detalle de Datos',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: primaryTeal,
                ),
              ),
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
                  "Total: $total registros",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: secondaryOrange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Tabla
          Expanded(
            child: SingleChildScrollView(
              child: Table(
                border: TableBorder.all(
                  color: primaryTeal.withOpacity(0.3),
                  width: 1.5,
                  borderRadius: BorderRadius.circular(8),
                ),
                columnWidths: const {
                  0: FlexColumnWidth(3),
                  1: FlexColumnWidth(2),
                  2: FlexColumnWidth(2),
                },
                children: [
                  // Encabezado
                  TableRow(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primaryTeal, primaryTeal.withOpacity(0.8)],
                      ),
                    ),
                    children: [
                      _buildExportTableCell("Período", isHeader: true),
                      _buildExportTableCell("Cantidad", isHeader: true),
                      _buildExportTableCell("Porcentaje", isHeader: true),
                    ],
                  ),
                  // Datos
                  ...datos.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    final percentage =
                        ((item.value / total) * 100).toStringAsFixed(1);
                    final isEven = index % 2 == 0;

                    return TableRow(
                      decoration: BoxDecoration(
                        color: isEven
                            ? Colors.white
                            : primaryTeal.withOpacity(0.05),
                      ),
                      children: [
                        _buildExportTableCell(item.label),
                        _buildExportTableCell(item.value.toString()),
                        _buildExportTableCell("$percentage%"),
                      ],
                    );
                  }).toList(),
                  // Total
                  TableRow(
                    decoration: BoxDecoration(
                      color: secondaryOrange.withOpacity(0.15),
                    ),
                    children: [
                      _buildExportTableCell("TOTAL",
                          isHeader: true, color: secondaryOrange),
                      _buildExportTableCell(total.toString(),
                          isHeader: true, color: secondaryOrange),
                      _buildExportTableCell("100.0%",
                          isHeader: true, color: secondaryOrange),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Construye una celda para la tabla de exportación
  Widget _buildExportTableCell(String text,
      {bool isHeader = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        text,
        textAlign: isHeader ? TextAlign.center : TextAlign.left,
        style: TextStyle(
          fontSize: isHeader ? 16 : 15,
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
          color: color ?? (isHeader ? Colors.white : Colors.black87),
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
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;
    final isMediumScreen = size.width >= 600 && size.width < 900;

    // ✅ ALTURA RESPONSIVA MEJORADA
    double chartHeight;
    if (isSmallScreen) {
      chartHeight = 320; // Aumentado de 280
    } else if (isMediumScreen) {
      chartHeight = 360; // Aumentado de 320
    } else {
      chartHeight = 400; // Aumentado de 350
    }

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 4 : 8),
      height: chartHeight,
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
                  width: isSmallScreen ? 16 : 20, // Barras más anchas
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
                reservedSize: isSmallScreen ? 38 : 45,
                interval: _calcularIntervaloY(datos),
                getTitlesWidget: (value, meta) => Padding(
                  padding: EdgeInsets.only(right: isSmallScreen ? 4.0 : 6.0),
                  child: Text(
                    value.toInt().toString(),
                    style: TextStyle(
                      fontSize: isSmallScreen ? 9 : 10,
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
                reservedSize: isSmallScreen ? 45 : 55,
                getTitlesWidget: (value, meta) => Padding(
                  padding: EdgeInsets.only(top: isSmallScreen ? 6.0 : 8.0),
                  child: Transform.rotate(
                    angle: -pi / 4,
                    child: Text(
                      _acortarEtiqueta(
                          datos[value.toInt()].label, isSmallScreen ? 7 : 10),
                      style: TextStyle(
                        fontSize: isSmallScreen ? 8 : 9,
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
              tooltipPadding: EdgeInsets.all(isSmallScreen ? 6 : 8),
              tooltipMargin: 6,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${datos[group.x].label}\n',
                  TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: isSmallScreen ? 11 : 13,
                  ),
                  children: [
                    TextSpan(
                      text: '${rod.toY.toInt()} valores',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isSmallScreen ? 12 : 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                );
              },
            ),
            touchCallback: (FlTouchEvent event, barTouchResponse) {
              if (event is FlTapUpEvent &&
                  barTouchResponse != null &&
                  barTouchResponse.spot != null) {
                final touchedIndex =
                    barTouchResponse.spot!.touchedBarGroupIndex;
                setState(() {
                  _barTouchedIndex = touchedIndex;
                });
                Future.delayed(const Duration(seconds: 1), () {
                  if (mounted) {
                    setState(() {
                      _barTouchedIndex = -1;
                    });
                  }
                });
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLineChart(List<ChartData> datos) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;
    final isMediumScreen = size.width >= 600 && size.width < 900;

    // ✅ ALTURA RESPONSIVA MEJORADA
    double chartHeight;
    if (isSmallScreen) {
      chartHeight = 320; // Aumentado de 280
    } else if (isMediumScreen) {
      chartHeight = 360; // Aumentado de 320
    } else {
      chartHeight = 400; // Aumentado de 350
    }

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 4 : 8),
      height: chartHeight,
      child: LineChart(
        LineChartData(
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              tooltipBgColor: Colors.blueGrey.shade800,
              tooltipPadding: EdgeInsets.all(isSmallScreen ? 6 : 8),
              tooltipMargin: 6,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((touchedSpot) {
                  final spotIndex = touchedSpot.spotIndex;
                  return LineTooltipItem(
                    '${datos[spotIndex].label}\n',
                    TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: isSmallScreen ? 10 : 12,
                    ),
                    children: [
                      TextSpan(
                        text: '${touchedSpot.y.toInt()} valores',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isSmallScreen ? 12 : 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  );
                }).toList();
              },
            ),
            touchCallback: (FlTouchEvent event, lineTouch) {
              if (event is FlTapUpEvent &&
                  lineTouch != null &&
                  lineTouch.lineBarSpots != null &&
                  lineTouch.lineBarSpots!.isNotEmpty) {
                setState(() {
                  _lineSpotTouched = lineTouch.lineBarSpots![0].spotIndex;
                });
                Future.delayed(const Duration(seconds: 1), () {
                  if (mounted) {
                    setState(() {
                      _lineSpotTouched = -1;
                    });
                  }
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
                reservedSize: isSmallScreen ? 24 : 30,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  if (value < 0 || value >= datos.length) return const Text('');
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    space: isSmallScreen ? 4 : 6,
                    child: Transform.rotate(
                      angle: -pi / 4,
                      child: Text(
                        _acortarEtiqueta(
                            datos[value.toInt()].label, isSmallScreen ? 5 : 7),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isSmallScreen ? 7 : 8,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: isSmallScreen ? 32 : 38,
                interval: _calcularIntervaloY(datos),
                getTitlesWidget: (value, meta) {
                  if (value % 1 == 0) {
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      space: isSmallScreen ? 4 : 6,
                      child: Text(
                        value.toInt().toString(),
                        style: TextStyle(
                          fontSize: isSmallScreen ? 8 : 9,
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
              barWidth: isSmallScreen ? 2.5 : 3.5,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  final bool isSelected = index == _lineSpotTouched;
                  return FlDotCirclePainter(
                    radius: isSelected
                        ? (isSmallScreen ? 6 : 8)
                        : (isSmallScreen ? 4 : 5),
                    color: isSelected
                        ? secondaryOrange.withOpacity(0.8)
                        : secondaryOrange,
                    strokeWidth: isSelected ? (isSmallScreen ? 2.5 : 3.0) : 2.0,
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
    final total = _calcularTotal(datos);

    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;
    final isMediumScreen = size.width >= 600 && size.width < 900;

    // ✅ RADIOS MÁS APROPIADOS PARA MEJOR LEGIBILIDAD
    double centerSpaceRadius;
    double baseRadius;
    double selectedRadius;

    if (isSmallScreen) {
      centerSpaceRadius = 20;
      baseRadius = 65;
      selectedRadius = 75;
    } else if (isMediumScreen) {
      centerSpaceRadius = 25;
      baseRadius = 80;
      selectedRadius = 95;
    } else {
      centerSpaceRadius = 30;
      baseRadius = 95;
      selectedRadius = 115;
    }

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 4 : 8),
      child: PieChart(
        PieChartData(
          pieTouchData: PieTouchData(
            touchCallback: (FlTouchEvent event, pieTouchResponse) {
              if (event is FlTapUpEvent &&
                  pieTouchResponse != null &&
                  pieTouchResponse.touchedSection != null) {
                final index =
                    pieTouchResponse.touchedSection!.touchedSectionIndex;
                setState(() {
                  if (_pieChartIndex == index) {
                    _pieChartIndex = -1;
                  } else {
                    _pieChartIndex = index;
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
              radius: isSelected ? selectedRadius : baseRadius,
              titleStyle: TextStyle(
                fontSize: isSelected
                    ? (isSmallScreen ? 10 : 12)
                    : (isSmallScreen ? 9 : 10),
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
              badgeWidget: isSelected ? _buildBadge(data, isSmallScreen) : null,
              badgePositionPercentageOffset: isSmallScreen ? 1.2 : 1.15,
            );
          }).toList(),
          sectionsSpace: 1,
          centerSpaceRadius: centerSpaceRadius,
          centerSpaceColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildBadge(ChartData data, [bool isSmall = false]) {
    return Container(
      padding: EdgeInsets.all(isSmall ? 4 : 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 0.5,
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
              fontSize: isSmall ? 9 : 12,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            data.value.toString(),
            style: TextStyle(
              color: Colors.grey.shade800,
              fontSize: isSmall ? 8 : 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeyendaUltraCompacta(List<ChartData> datos, bool isSmall) {
    if (datos.isEmpty) return const SizedBox();

    double total = 0;
    if (_tipoVisualizacion == "circular") {
      total = _calcularTotal(datos);
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 4 : 6,
        vertical: isSmall ? 2 : 3,
      ),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_tipoVisualizacion == "circular")
            Padding(
              padding: EdgeInsets.only(bottom: isSmall ? 2 : 3),
              child: Text(
                "Total: ${total.toInt()}",
                style: TextStyle(
                  fontSize: isSmall ? 10 : 11,
                  fontWeight: FontWeight.bold,
                  color: primaryTeal,
                ),
              ),
            ),

          // ✅ Mismo tamaño (ultra compacto), pero ahora se puede ver TODO con scroll interno
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: isSmall ? 36 : 44),
            child: Scrollbar(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Wrap(
                  spacing: isSmall ? 4 : 6,
                  runSpacing: isSmall ? 2 : 3,
                  children: datos.map((data) {
                    return Container(
                      margin: EdgeInsets.only(right: isSmall ? 2 : 3),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: isSmall ? 6 : 8,
                            height: isSmall ? 6 : 8,
                            decoration: BoxDecoration(
                              color: data.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: isSmall ? 2 : 3),
                          Text(
                            data.label.length > (isSmall ? 8 : 12)
                                ? '${data.label.substring(0, isSmall ? 8 : 12)}...'
                                : data.label,
                            style: TextStyle(
                              fontSize: isSmall ? 8 : 9,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

// Variables para guardar el estado de interactividad

  Future<Map<String, List<ChartData>>> _obtenerDatosParaGrafica() async {
    // ✅ AGREGAR ESTOS PRINTS AL INICIO
    print('\n🔍 === DEBUG _obtenerDatosParaGrafica ===');
    print('📅 _anioSeleccionado: $_anioSeleccionado');
    print('📅 _aniosDisponibles: $_aniosDisponibles');
    print('📅 _mesSeleccionado: $_mesSeleccionado');
    print('📊 _filtroSeleccionado: $_filtroSeleccionado');
    print('=====================================\n');

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

      print('📊 Total documentos en "$coleccion": ${snapshot.docs.length}');

      List<QueryDocumentSnapshot> resultados = snapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>?;
        final fecha = _convertirFecha(data);

        if (fecha == null) {
          print('  ❌ Doc ID: ${doc.id} - Sin campo "fecha" válido, ignorado');
          return false;
        }

        print('  - Doc ID: ${doc.id}');
        print('    Fecha procesada: ${DateFormat('dd/MM/yyyy').format(fecha)}');
        print('    Año: ${fecha.year}, Mes: ${fecha.month}');

        // ✅ CORRECCIÓN PRINCIPAL: Lógica de filtrado por año
        if (_filtroSeleccionado == "anual") {
          // Para vista anual: si es -1, incluir TODOS los años
          if (anioFiltro == -1) {
            print('    ✅ Incluido (Todos los años - Vista anual)');
            return true;
          } else {
            bool incluir = fecha.year == anioFiltro;
            print(
                '    ${incluir ? "✅" : "❌"} ${incluir ? "Incluido" : "Excluido"} (año específico: $anioFiltro)');
            return incluir;
          }
        } else if (mesFiltro == "Todos los meses") {
          // Para "Todos los meses": si anioFiltro es -1, incluir todos
          if (anioFiltro == -1) {
            print('    ✅ Incluido (Todos los años - Todos los meses)');
            return true;
          } else {
            bool incluir = fecha.year == anioFiltro;
            print(
                '    ${incluir ? "✅" : "❌"} ${incluir ? "Incluido" : "Excluido"} (año: $anioFiltro, todos los meses)');
            return incluir;
          }
        } else {
          // Para mes específico: si anioFiltro es -1, incluir todos los años con ese mes
          if (anioFiltro == -1) {
            bool incluir = fecha.month == mesIndex;
            print(
                '    ${incluir ? "✅" : "❌"} ${incluir ? "Incluido" : "Excluido"} (Todos los años, mes: $mesFiltro)');
            return incluir;
          } else {
            bool incluir = fecha.year == anioFiltro && fecha.month == mesIndex;
            print(
                '    ${incluir ? "✅" : "❌"} ${incluir ? "Incluido" : "Excluido"} (año: $anioFiltro, mes: $mesFiltro)');
            return incluir;
          }
        }
      }).toList();

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
    try {
      // Si es un documento completo (Map), extraer el campo de fecha apropiado
      if (fecha is Map<String, dynamic>) {
        // ✅ PRIORIDAD 1: Intentar con 'createdAt' (para social_profiles)
        if (fecha.containsKey('createdAt') && fecha['createdAt'] != null) {
          final createdAtCampo = fecha['createdAt'];

          // Si es String ISO8601 (formato de social_profiles)
          if (createdAtCampo is String) {
            try {
              return DateTime.parse(createdAtCampo);
            } catch (e) {
              print('⚠️ Error parseando createdAt String: $e');
            }
          }

          // Si es Timestamp
          if (createdAtCampo is Timestamp) {
            return createdAtCampo.toDate();
          }
        }

        // ✅ PRIORIDAD 2: Intentar con 'fecha' (para registros)
        if (fecha.containsKey('fecha') && fecha['fecha'] != null) {
          final fechaCampo = fecha['fecha'];

          // Si es Timestamp
          if (fechaCampo is Timestamp) {
            return fechaCampo.toDate();
          }

          // Si es String
          if (fechaCampo is String) {
            return DateTime.tryParse(fechaCampo);
          }
        }

        print('⚠️ Documento sin campo "fecha" o "createdAt" válido');
        return null;
      }

      // Si es directamente un Timestamp
      if (fecha is Timestamp) {
        return fecha.toDate();
      }

      // Si es directamente un String
      if (fecha is String) {
        return DateTime.tryParse(fecha);
      }

      // Si no se pudo obtener fecha, retornar null
      print('⚠️ Tipo de fecha no reconocido: ${fecha.runtimeType}');
      return null;
    } catch (e) {
      print('❌ Error en _convertirFecha: $e');
      return null;
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
            child: DropdownButton<int>(
              // ✅ VALIDACIÓN MEJORADA: Asegurar que el valor sea válido
              value: _aniosDisponibles.contains(_anioSeleccionado)
                  ? _anioSeleccionado
                  : (_aniosDisponibles.isNotEmpty
                      ? _aniosDisponibles.last
                      : DateTime.now().year),
              isExpanded: true,
              icon: Icon(Icons.arrow_drop_down, color: primaryTeal),
              items: [
                // ✅ Opción "Todos los años" solo si hay más de un año
                if (_aniosDisponibles.length > 1)
                  DropdownMenuItem<int>(
                    value: -1,
                    child: Text(
                      "Todos los años disponibles",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                // ✅ Lista de años disponibles en orden descendente
                ...(_aniosDisponibles.toList()..sort((a, b) => b.compareTo(a)))
                    .map((year) => DropdownMenuItem<int>(
                          value: year,
                          child: Text(
                            year.toString(),
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.black87,
                              fontWeight: _anioSeleccionado == year
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        )),
              ],
              onChanged: (value) {
                setState(() {
                  _anioSeleccionado = value!;
                  print('🔄 Año seleccionado cambiado a: $_anioSeleccionado');
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
                    child: Text(
                      "Todos los meses",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  ...meses.map((mes) => DropdownMenuItem<String>(
                        value: mes,
                        child: Text(
                          mes,
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.black87,
                          ),
                        ),
                      )),
                ],
                onChanged: (value) {
                  setState(() {
                    _mesSeleccionado = value!;
                    print('🔄 Mes seleccionado cambiado a: $_mesSeleccionado');
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
            dialogBackgroundColor: Colors.white,
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: primaryTeal,
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            dividerColor: primaryTeal.withOpacity(0.2),
          ),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        primaryTeal.withOpacity(0.05),
                        Colors.white,
                      ],
                    ),
                  ),
                  child: child,
                ),
              ),
            ],
          ),
        );
      },
      helpText: 'SELECCIONAR RANGO DE FECHAS',
      cancelText: 'Cancelar',
      confirmText: 'Aplicar',
      saveText: 'Guardar',
      errorFormatText: 'Formato inválido',
      errorInvalidText: 'Fecha fuera de rango',
      errorInvalidRangeText: 'Rango inválido',
      fieldStartHintText: 'Fecha inicio',
      fieldEndHintText: 'Fecha fin',
      fieldStartLabelText: 'Desde',
      fieldEndLabelText: 'Hasta',
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });

      // Aplicar filtros automáticamente
      _filtrarRegistros();

      // Mostrar confirmación visual
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
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Filtro aplicado: ${DateFormat('dd/MM/yyyy').format(picked.start)} - ${DateFormat('dd/MM/yyyy').format(picked.end)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: primaryTeal,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        ),
      );
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

        // ✅ APLICAR FILTRO POR TIPO SI ESTÁ ACTIVO
        if (_filtroTipoRegistro != null) {
          registrosParaExportar = registrosParaExportar.where((registro) {
            final tipoRegistro = registro.tipo?.toLowerCase();
            return tipoRegistro == _filtroTipoRegistro;
          }).toList();

          prefix = _filtroTipoRegistro == 'nuevo'
              ? 'registros_nuevos'
              : 'registros_visitas';
        } else {
          prefix = 'todos_los_registros';
        }

        // Obtener todos los perfiles sociales SIN filtrar por fecha
        final perfilesSnapshot = await FirebaseFirestore.instance
            .collection('social_profiles')
            .get();
        perfilesParaExportar = perfilesSnapshot.docs
            .map((doc) => SocialProfile.fromMap(
                doc.data() as Map<String, dynamic>, doc.id))
            .toList();
      } else if (_startDate != null && _endDate != null) {
        // Validación de seguridad adicional
        if (_startDate == null || _endDate == null) {
          throw Exception('Error interno: Fechas nulas inesperadas');
        }

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

        // ✅ APLICAR FILTRO POR TIPO SI ESTÁ ACTIVO
        if (_filtroTipoRegistro != null) {
          registrosParaExportar = registrosParaExportar.where((registro) {
            final tipoRegistro = registro.tipo?.toLowerCase() ?? '';
            return tipoRegistro == _filtroTipoRegistro;
          }).toList();
        }

        // Filtrar perfiles sociales por fecha
        final perfilesSnapshot = await FirebaseFirestore.instance
            .collection('social_profiles')
            .get();

        perfilesParaExportar = perfilesSnapshot.docs
            .map((doc) => SocialProfile.fromMap(
                doc.data() as Map<String, dynamic>, doc.id))
            .where((perfil) {
          final createdAt = perfil.createdAt;
          return createdAt
                  .isAfter(fechaInicio.subtract(const Duration(seconds: 1))) &&
              createdAt.isBefore(fechaFin.add(const Duration(seconds: 1)));
        }).toList();

        // ✅ MEJORAR EL NOMBRE DEL ARCHIVO
        String tipoTexto = _filtroTipoRegistro == null
            ? 'todos'
            : (_filtroTipoRegistro == 'nuevo' ? 'nuevos' : 'visitas');

        prefix =
            'registros_${tipoTexto}_${DateFormat('dd_MM_yyyy').format(_startDate!)}_a_${DateFormat('dd_MM_yyyy').format(_endDate!)}';
      } else {
        throw Exception('Selecciona un rango de fechas');
      }

      if (registrosParaExportar.isEmpty && perfilesParaExportar.isEmpty) {
        throw Exception('No hay datos para el rango de fechas seleccionado');
      }

      final filePath = await _excelService.exportarRegistros(
        registrosParaExportar,
        perfilesParaExportar,
        prefix: prefix,
      );

      if (!mounted) return;

      // ✅ MENSAJE MEJORADO CON INFO DEL FILTRO
      String mensaje = 'Archivo exportado: $filePath';
      if (_filtroTipoRegistro != null) {
        String tipoExportado =
            _filtroTipoRegistro == 'nuevo' ? 'Nuevos' : 'Visitas';
        mensaje += '\n(Solo registros tipo: $tipoExportado)';
      }

      _mostrarExito(mensaje);
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
        child: Column(
          children: [
            // Header siempre visible
            InkWell(
              onTap: () {
                setState(() {
                  _mostrarFiltroExportacion = !_mostrarFiltroExportacion;
                });
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: secondaryOrange.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.file_download,
                          size: 28, color: secondaryOrange),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Exportar Registros',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: primaryTeal,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _startDate != null && _endDate != null
                                ? 'Rango: ${DateFormat('dd/MM/yyyy').format(_startDate!)} - ${DateFormat('dd/MM/yyyy').format(_endDate!)}'
                                : 'Toca para configurar exportación',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: _mostrarFiltroExportacion ? 0.5 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: primaryTeal.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.keyboard_arrow_down,
                          color: primaryTeal,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Contenido desplegable
            AnimatedCrossFade(
              firstChild: const SizedBox(width: double.infinity),
              secondChild: Container(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  children: [
                    const Divider(height: 1),
                    const SizedBox(height: 20),
                    _buildDateRangeSelector(),
                    const SizedBox(height: 20),
                    _buildExportButtons(),
                  ],
                ),
              ),
              crossFadeState: _mostrarFiltroExportacion
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 300),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRangeSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryTeal.withOpacity(0.05),
            secondaryOrange.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: _startDate != null && _endDate != null
              ? primaryTeal
              : primaryTeal.withOpacity(0.3),
          width: _startDate != null && _endDate != null ? 2 : 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryTeal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.date_range,
                  color: primaryTeal,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rango de Fechas',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: primaryTeal,
                      ),
                    ),
                    if (_startDate != null && _endDate != null)
                      Text(
                        'Del ${DateFormat('dd/MM/yyyy').format(_startDate!)} al ${DateFormat('dd/MM/yyyy').format(_endDate!)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
              if (_startDate != null && _endDate != null)
                Container(
                  decoration: BoxDecoration(
                    color: secondaryOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.clear,
                      color: secondaryOrange,
                      size: 20,
                    ),
                    onPressed: _limpiarFiltro,
                    tooltip: 'Limpiar filtro de fecha',
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _selectDateRange(context),
                  icon: Icon(
                    _startDate != null && _endDate != null
                        ? Icons.edit_calendar
                        : Icons.calendar_today,
                    size: 20,
                  ),
                  label: Text(
                    _startDate != null && _endDate != null
                        ? 'Cambiar Fechas'
                        : 'Seleccionar Fechas',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryTeal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
            ],
          ),
          if (_startDate != null && _endDate != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.green.shade200,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green.shade700,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Filtro aplicado: Mostrando registros del rango seleccionado',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green.shade900,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
            _buildFiltroTipoRegistro(),
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

                // ✅ FILTRO CRÍTICO: Excluir registros provenientes de perfiles sociales
                final registrosFiltrados = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>?;

                  // ✅ CRITERIO 1: Excluir si tiene origenPerfilSocial = true
                  final origenPerfilSocial =
                      data?['origenPerfilSocial'] ?? false;
                  if (origenPerfilSocial == true) {
                    return false; // NO mostrar en pestaña Registros
                  }

                  // ✅ CRITERIO 2: Excluir si tiene perfilSocialId (vinculado a perfil social)
                  final perfilSocialId = data?['perfilSocialId'];
                  if (perfilSocialId != null &&
                      perfilSocialId.toString().trim().isNotEmpty) {
                    return false; // NO mostrar en pestaña Registros
                  }

                  // ✅ Si no cumple ninguno de los criterios anteriores, SÍ mostrarlo
                  return true; // Mostrar solo registros directos
                }).toList();

                if (registrosFiltrados.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        'No hay registros directos disponibles.\nLos registros de perfiles sociales se muestran en su pestaña.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ),
                  );
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

  Widget _buildFiltroTipoRegistro() {
    // Calcular registros según estado actual
    int totalRegistros = _contarRegistrosFiltrados();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryTeal.withOpacity(0.08),
            secondaryOrange.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: primaryTeal.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header siempre visible
          InkWell(
            onTap: () {
              setState(() {
                _mostrarFiltroTipo = !_mostrarFiltroTipo;
              });
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: primaryTeal.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.filter_list_rounded,
                      color: primaryTeal,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Filtrar por Tipo',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: primaryTeal,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _filtroTipoRegistro == null
                              ? 'Todos los registros ($totalRegistros)'
                              : _filtroTipoRegistro == 'nuevo'
                                  ? 'Solo Nuevos ($totalRegistros)'
                                  : 'Solo Visitas ($totalRegistros)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_filtroTipoRegistro != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: secondaryOrange.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: secondaryOrange.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: secondaryOrange,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$totalRegistros',
                            style: TextStyle(
                              color: secondaryOrange,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: _mostrarFiltroTipo ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryTeal.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        color: primaryTeal,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Contenido desplegable con los botones de filtro
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isSmallScreen = constraints.maxWidth < 600;

                      if (isSmallScreen) {
                        return Column(
                          children: [
                            _buildBotonFiltroTipo(
                              label: 'Todos',
                              icon: Icons.all_inclusive,
                              isSelected: _filtroTipoRegistro == null,
                              onTap: () {
                                setState(() {
                                  _filtroTipoRegistro = null;
                                  _aplicarFiltroTipo();
                                });
                              },
                              color: Colors.blueGrey,
                              width: double.infinity,
                            ),
                            const SizedBox(height: 8),
                            _buildBotonFiltroTipo(
                              label: 'Nuevos',
                              icon: Icons.fiber_new_rounded,
                              isSelected: _filtroTipoRegistro == 'nuevo',
                              onTap: () {
                                setState(() {
                                  _filtroTipoRegistro = 'nuevo';
                                  _aplicarFiltroTipo();
                                });
                              },
                              color: primaryTeal,
                              width: double.infinity,
                            ),
                            const SizedBox(height: 8),
                            _buildBotonFiltroTipo(
                              label: 'Visitas',
                              icon: Icons.visibility_rounded,
                              isSelected: _filtroTipoRegistro == 'visita',
                              onTap: () {
                                setState(() {
                                  _filtroTipoRegistro = 'visita';
                                  _aplicarFiltroTipo();
                                });
                              },
                              color: secondaryOrange,
                              width: double.infinity,
                            ),
                          ],
                        );
                      } else {
                        return Row(
                          children: [
                            Expanded(
                              child: _buildBotonFiltroTipo(
                                label: 'Todos',
                                icon: Icons.all_inclusive,
                                isSelected: _filtroTipoRegistro == null,
                                onTap: () {
                                  setState(() {
                                    _filtroTipoRegistro = null;
                                    _aplicarFiltroTipo();
                                  });
                                },
                                color: Colors.blueGrey,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildBotonFiltroTipo(
                                label: 'Nuevos',
                                icon: Icons.fiber_new_rounded,
                                isSelected: _filtroTipoRegistro == 'nuevo',
                                onTap: () {
                                  setState(() {
                                    _filtroTipoRegistro = 'nuevo';
                                    _aplicarFiltroTipo();
                                  });
                                },
                                color: primaryTeal,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildBotonFiltroTipo(
                                label: 'Visitas',
                                icon: Icons.visibility_rounded,
                                isSelected: _filtroTipoRegistro == 'visita',
                                onTap: () {
                                  setState(() {
                                    _filtroTipoRegistro = 'visita';
                                    _aplicarFiltroTipo();
                                  });
                                },
                                color: secondaryOrange,
                              ),
                            ),
                          ],
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
            crossFadeState: _mostrarFiltroTipo
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }

  Widget _buildBotonFiltroTipo({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required Color color,
    double? width,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [color, color.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey[600],
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  int _contarRegistrosFiltrados() {
    int count = 0;
    final datos =
        _mostrarFiltrados ? _registrosFiltrados : _registrosPorAnioMesDia;

    datos.forEach((anio, meses) {
      meses.forEach((mes, dias) {
        dias.forEach((dia, registros) {
          count += registros.length;
        });
      });
    });

    return count;
  }

  void _aplicarFiltroTipo() {
    // Si no hay filtro de tipo, verificar si hay filtro de fecha
    if (_filtroTipoRegistro == null) {
      if (_startDate != null && _endDate != null) {
        // Mantener solo el filtro de fecha
        _filtrarRegistros();
      } else {
        // No hay filtros activos, mostrar todos
        setState(() {
          _mostrarFiltrados = false;
        });
      }
      return;
    }

    // Determinar qué registros usar como base
    Map<int, Map<int, Map<DateTime, List<Registro>>>> registrosBase;

    if (_startDate != null && _endDate != null) {
      // Si hay filtro de fecha, partir de registros filtrados por fecha
      registrosBase = {};
      _registrosPorAnioMesDia.forEach((anio, meses) {
        meses.forEach((mes, dias) {
          dias.forEach((dia, registros) {
            if (dia.isAfter(_startDate!.subtract(const Duration(days: 1))) &&
                dia.isBefore(_endDate!.add(const Duration(days: 1)))) {
              registrosBase[anio] ??= {};
              registrosBase[anio]![mes] ??= {};
              registrosBase[anio]![mes]![dia] = registros;
            }
          });
        });
      });
    } else {
      // Si no hay filtro de fecha, usar todos los registros
      registrosBase = _registrosPorAnioMesDia;
    }

    // Aplicar filtro por tipo sobre la base
    final registrosFiltrados =
        Map<int, Map<int, Map<DateTime, List<Registro>>>>.from({});

    registrosBase.forEach((anio, meses) {
      meses.forEach((mes, dias) {
        dias.forEach((dia, registros) {
          final registrosFiltradosDia = registros.where((registro) {
            final tipoRegistro = registro.tipo?.toLowerCase();
            return tipoRegistro == _filtroTipoRegistro;
          }).toList();

          if (registrosFiltradosDia.isNotEmpty) {
            registrosFiltrados[anio] ??= {};
            registrosFiltrados[anio]![mes] ??= {};
            registrosFiltrados[anio]![mes]![dia] = registrosFiltradosDia;
          }
        });
      });
    });

    setState(() {
      _registrosFiltrados = registrosFiltrados;
      _mostrarFiltrados = true;
    });
  }

  void _filtrarRegistros() {
    // Validación de seguridad
    if (_startDate == null || _endDate == null) {
      print('⚠️ No se puede filtrar: fechas nulas');
      return;
    }

    print('\n🔍 === INICIANDO FILTRADO DE REGISTROS ===');
    print('📅 Fecha inicio: ${DateFormat('dd/MM/yyyy').format(_startDate!)}');
    print('📅 Fecha fin: ${DateFormat('dd/MM/yyyy').format(_endDate!)}');
    print('🏷️ Filtro tipo: ${_filtroTipoRegistro ?? "ninguno"}');

    final registrosFiltrados =
        Map<int, Map<int, Map<DateTime, List<Registro>>>>.from({});

    _registrosPorAnioMesDia.forEach((anio, meses) {
      meses.forEach((mes, dias) {
        dias.forEach((dia, registros) {
          // Filtrar por rango de fechas
          if (dia.isAfter(_startDate!.subtract(const Duration(days: 1))) &&
              dia.isBefore(_endDate!.add(const Duration(days: 1)))) {
            // Aplicar filtro por tipo si está activo
            List<Registro> registrosFiltradosPorTipo = registros;
            if (_filtroTipoRegistro != null) {
              registrosFiltradosPorTipo = registros.where((registro) {
                // Manejo seguro del tipo
                final tipoRegistro = registro.tipo?.toLowerCase() ?? '';
                return tipoRegistro == _filtroTipoRegistro;
              }).toList();
            }

            // Solo agregar si hay registros después de aplicar filtros
            if (registrosFiltradosPorTipo.isNotEmpty) {
              registrosFiltrados[anio] ??= {};
              registrosFiltrados[anio]![mes] ??= {};
              registrosFiltrados[anio]![mes]![dia] = registrosFiltradosPorTipo;
            }
          }
        });
      });
    });

    print('✅ Registros filtrados: ${registrosFiltrados.length} años');
    print('🏁 === FIN FILTRADO ===\n');

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
      _filtroTipoRegistro = null;
      _mostrarFiltroExportacion = true;
      _mostrarFiltroTipo = true;
    });

    // Confirmación visual
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
              child: const Icon(
                Icons.refresh,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Filtros eliminados - Mostrando todos los registros',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: secondaryOrange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }


Widget _buildAnioGroup(
    int anio, Map<int, Map<DateTime, List<Registro>>> registrosPorMes) {
  // Inicializar estado de expansión si no existe
  _aniosExpandidos[anio] ??= false;

  return ExpansionTile(
    // ✅ CRÍTICO: Controlar expansión manualmente
    initiallyExpanded: _aniosExpandidos[anio]!,
    onExpansionChanged: (expanded) {
      setState(() {
        _aniosExpandidos[anio] = expanded;
      });
    },
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
        .map((mes) => _buildMesGroup(mes.key, mes.value, anio))
        .toList(),
  );
}


Widget _buildMesGroup(
    int mes, Map<DateTime, List<Registro>> registrosPorDia, int anio) {
  final nombreMes = _getNombreMes(mes);
  int totalRegistros =
      registrosPorDia.values.expand((registros) => registros).length;

  // Clave única para este mes
  final mesKey = "$anio-$mes";
  _mesesExpandidos[mesKey] ??= false;

  return ExpansionTile(
    // ✅ CRÍTICO: Controlar expansión manualmente
    initiallyExpanded: _mesesExpandidos[mesKey]!,
    onExpansionChanged: (expanded) {
      setState(() {
        _mesesExpandidos[mesKey] = expanded;
      });
    },
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
    children: [
      // ✅ BOTONES DE AGRUPACIÓN RESPONSIVOS
      StatefulBuilder(
        builder: (BuildContext context, StateSetter setLocalState) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final isSmallScreen = constraints.maxWidth < 600;

              return Column(
                children: [
                  Container(
                    margin: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 8 : 12,
                      vertical: isSmallScreen ? 6 : 8,
                    ),
                    padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          primaryTeal.withOpacity(0.05),
                          secondaryOrange.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: primaryTeal.withOpacity(0.2),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.view_module,
                              color: primaryTeal,
                              size: isSmallScreen ? 18 : 20,
                            ),
                            SizedBox(width: isSmallScreen ? 6 : 8),
                            Text(
                              'Agrupar por:',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 12 : 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: isSmallScreen ? 10 : 12),
                        isSmallScreen
                            ? Column(
                                children: [
                                  _buildAgrupacionButton(
                                    'Días',
                                    Icons.calendar_view_day,
                                    _tipoAgrupacionMensual == "dias",
                                    () {
                                      setLocalState(() {
                                        _tipoAgrupacionMensual = "dias";
                                      });
                                    },
                                    isSmall: true,
                                  ),
                                  const SizedBox(height: 8),
                                  _buildAgrupacionButton(
                                    'Semanas',
                                    Icons.view_week,
                                    _tipoAgrupacionMensual == "semanas",
                                    () {
                                      setLocalState(() {
                                        _tipoAgrupacionMensual = "semanas";
                                      });
                                    },
                                    isSmall: true,
                                  ),
                                ],
                              )
                            : Row(
                                children: [
                                  Expanded(
                                    child: _buildAgrupacionButton(
                                      'Días',
                                      Icons.calendar_view_day,
                                      _tipoAgrupacionMensual == "dias",
                                      () {
                                        setLocalState(() {
                                          _tipoAgrupacionMensual = "dias";
                                        });
                                      },
                                      isSmall: false,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _buildAgrupacionButton(
                                      'Semanas',
                                      Icons.view_week,
                                      _tipoAgrupacionMensual == "semanas",
                                      () {
                                        setLocalState(() {
                                          _tipoAgrupacionMensual = "semanas";
                                        });
                                      },
                                      isSmall: false,
                                    ),
                                  ),
                                ],
                              ),
                      ],
                    ),
                  ),
                  ..._tipoAgrupacionMensual == "dias"
                      ? registrosPorDia.entries
                          .map((entrada) =>
                              _buildFechaGroup(entrada.key, entrada.value, anio, mes))
                          .toList()
                      : _buildSemanaGroups(registrosPorDia, anio, mes),
                ],
              );
            },
          );
        },
      ),
    ],
  );
}



  // ✅ MÉTODO AUXILIAR PARA BOTÓN DE AGRUPACIÓN
  Widget _buildAgrupacionButton(
      String label, IconData icon, bool isSelected, VoidCallback onTap,
      {required bool isSmall}) {
    final color = label == 'Días' ? primaryTeal : secondaryOrange;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: isSmall ? 10 : 12,
          vertical: isSmall ? 10 : 12,
        ),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [color, color.withOpacity(0.8)],
                )
              : null,
          color: isSelected ? null : Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey[600],
              size: isSmall ? 18 : 20,
            ),
            SizedBox(width: isSmall ? 6 : 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontSize: isSmall ? 13 : 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

// Agrupa registros por semanas (Lunes a Domingo)




List<Widget> _buildSemanaGroups(
    Map<DateTime, List<Registro>> registrosPorDia, int anio, int mes) {
  Map<int, Map<DateTime, List<Registro>>> registrosPorSemana = {};

  registrosPorDia.forEach((fecha, registros) {
    int numeroSemana = _getNumeroSemanaDelMes(fecha);
    registrosPorSemana[numeroSemana] ??= {};
    registrosPorSemana[numeroSemana]![fecha] = registros;
  });

  List<int> semanasOrdenadas = registrosPorSemana.keys.toList()..sort();

  return semanasOrdenadas
      .map((semana) => _buildSemanaGroup(semana, registrosPorSemana[semana]!, anio, mes))
      .toList();
}



// Calcular número de semana dentro del mes (1-5)
  int _getNumeroSemanaDelMes(DateTime fecha) {
    // Encontrar el primer lunes del mes
    DateTime primerDiaDelMes = DateTime(fecha.year, fecha.month, 1);

    // Calcular cuántos días faltan para el primer lunes
    int diasHastaLunes = (DateTime.monday - primerDiaDelMes.weekday + 7) % 7;
    DateTime primerLunes = primerDiaDelMes.add(Duration(days: diasHastaLunes));

    // Si la fecha es antes del primer lunes, está en la "semana 0"
    if (fecha.isBefore(primerLunes)) {
      return 0;
    }

    // Calcular la diferencia en días desde el primer lunes
    int diasDesdePrimerLunes = fecha.difference(primerLunes).inDays;

    // Calcular número de semana (1-indexed)
    return (diasDesdePrimerLunes ~/ 7) + 1;
  }

// Obtener el rango de fechas de una semana
  String _getRangoSemana(Map<DateTime, List<Registro>> registrosSemana) {
    if (registrosSemana.isEmpty) return '';

    List<DateTime> fechas = registrosSemana.keys.toList()..sort();
    DateTime inicio = fechas.first;
    DateTime fin = fechas.last;

    return '${DateFormat('dd/MM').format(inicio)} - ${DateFormat('dd/MM').format(fin)}';
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

  String _getNombreDiaSemana(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Lunes';
      case DateTime.tuesday:
        return 'Martes';
      case DateTime.wednesday:
        return 'Miércoles';
      case DateTime.thursday:
        return 'Jueves';
      case DateTime.friday:
        return 'Viernes';
      case DateTime.saturday:
        return 'Sábado';
      case DateTime.sunday:
        return 'Domingo';
      default:
        return '';
    }
  }


Widget _buildFechaGroup(DateTime fecha, List<Registro> registros, int anio, int mes) {
  // Clave única para este día
  final diaKey = "$anio-$mes-${fecha.day}";
  _diasExpandidos[diaKey] ??= false;

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

  aplicarFiltros();

  return StatefulBuilder(
    builder: (context, setState) {
      return Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ExpansionTile(
            // ✅ CRÍTICO: Controlar expansión manualmente
            initiallyExpanded: _diasExpandidos[diaKey]!,
            onExpansionChanged: (expanded) {
              // ✅ Actualizar AMBOS estados
              this.setState(() {
                _diasExpandidos[diaKey] = expanded;
              });
            },
            leading: CircleAvatar(
              backgroundColor: primaryTeal,
              child: const Icon(Icons.calendar_today, color: Colors.white),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: primaryTeal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: primaryTeal.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _getNombreDiaSemana(fecha.weekday),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: primaryTeal,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    DateFormat('dd/MM/yyyy').format(fecha),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.people_outline, size: 16, color: secondaryOrange),
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
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isSmallScreen = constraints.maxWidth < 600;

                    return Container(
                      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            primaryTeal.withOpacity(0.05),
                            secondaryOrange.withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: primaryTeal.withOpacity(0.2),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: primaryTeal.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.filter_alt,
                                  color: primaryTeal,
                                  size: isSmallScreen ? 16 : 18,
                                ),
                              ),
                              SizedBox(width: isSmallScreen ? 6 : 8),
                              Text(
                                'Filtros',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 12 : 14,
                                  fontWeight: FontWeight.bold,
                                  color: primaryTeal,
                                ),
                              ),
                              const Spacer(),
                              if (filtroSexoLocal != null || filtroEdadLocal != null)
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      filtroSexoLocal = null;
                                      filtroEdadLocal = null;
                                      aplicarFiltros();
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: isSmallScreen ? 8 : 10,
                                        vertical: isSmallScreen ? 4 : 6),
                                    decoration: BoxDecoration(
                                      color: secondaryOrange.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: secondaryOrange.withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.clear_all,
                                          color: secondaryOrange,
                                          size: isSmallScreen ? 14 : 16,
                                        ),
                                        SizedBox(width: isSmallScreen ? 2 : 4),
                                        Text(
                                          'Limpiar',
                                          style: TextStyle(
                                            color: secondaryOrange,
                                            fontSize: isSmallScreen ? 10 : 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: isSmallScreen ? 12 : 16),

                          isSmallScreen
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.wc, color: Colors.grey[600], size: 18),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Sexo:',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildChipSexo(
                                            'Hombre',
                                            Icons.male,
                                            filtroSexoLocal == 'Hombre',
                                            () {
                                              setState(() {
                                                filtroSexoLocal =
                                                    filtroSexoLocal == 'Hombre'
                                                        ? null
                                                        : 'Hombre';
                                                aplicarFiltros();
                                              });
                                            },
                                            isSmall: true,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: _buildChipSexo(
                                            'Mujer',
                                            Icons.female,
                                            filtroSexoLocal == 'Mujer',
                                            () {
                                              setState(() {
                                                filtroSexoLocal =
                                                    filtroSexoLocal == 'Mujer'
                                                        ? null
                                                        : 'Mujer';
                                                aplicarFiltros();
                                              });
                                            },
                                            isSmall: true,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                )
                              : Row(
                                  children: [
                                    Icon(Icons.wc, color: Colors.grey[600], size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Sexo:',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: _buildChipSexo(
                                              'Hombre',
                                              Icons.male,
                                              filtroSexoLocal == 'Hombre',
                                              () {
                                                setState(() {
                                                  filtroSexoLocal =
                                                      filtroSexoLocal == 'Hombre'
                                                          ? null
                                                          : 'Hombre';
                                                  aplicarFiltros();
                                                });
                                              },
                                              isSmall: false,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: _buildChipSexo(
                                              'Mujer',
                                              Icons.female,
                                              filtroSexoLocal == 'Mujer',
                                              () {
                                                setState(() {
                                                  filtroSexoLocal =
                                                      filtroSexoLocal == 'Mujer'
                                                          ? null
                                                          : 'Mujer';
                                                  aplicarFiltros();
                                                });
                                              },
                                              isSmall: false,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                          SizedBox(height: isSmallScreen ? 10 : 12),

                          isSmallScreen
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.cake, color: Colors.grey[600], size: 18),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Edad mínima:',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    _buildEdadTextField(
                                      filtroEdadLocal,
                                      (value) {
                                        setState(() {
                                          filtroEdadLocal = int.tryParse(value);
                                          aplicarFiltros();
                                        });
                                      },
                                      () {
                                        setState(() {
                                          filtroEdadLocal = null;
                                          aplicarFiltros();
                                        });
                                      },
                                      isSmall: true,
                                    ),
                                  ],
                                )
                              : Row(
                                  children: [
                                    Icon(Icons.cake, color: Colors.grey[600], size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Edad mínima:',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildEdadTextField(
                                        filtroEdadLocal,
                                        (value) {
                                          setState(() {
                                            filtroEdadLocal = int.tryParse(value);
                                            aplicarFiltros();
                                          });
                                        },
                                        () {
                                          setState(() {
                                            filtroEdadLocal = null;
                                            aplicarFiltros();
                                          });
                                        },
                                        isSmall: false,
                                      ),
                                    ),
                                    if (filtroEdadLocal != null)
                                      Padding(
                                        padding: const EdgeInsets.only(left: 8),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: primaryTeal.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: primaryTeal.withOpacity(0.3),
                                              width: 1,
                                            ),
                                          ),
                                          child: Text(
                                            '≥ $filtroEdadLocal',
                                            style: TextStyle(
                                              color: primaryTeal,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
            children: [
              ...registrosFiltrados.map((registro) => _buildRegistroTile(registro)),
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

  // ✅ MÉTODO AUXILIAR PARA CHIP DE SEXO
  Widget _buildChipSexo(
      String label, IconData icon, bool isSelected, VoidCallback onTap,
      {required bool isSmall}) {
    final color = label == 'Hombre' ? primaryTeal : secondaryOrange;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isSmall ? 8 : 12,
          vertical: isSmall ? 6 : 8,
        ),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [color, color.withOpacity(0.8)],
                )
              : null,
          color: isSelected ? null : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey[600],
              size: isSmall ? 16 : 18,
            ),
            SizedBox(width: isSmall ? 3 : 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontSize: isSmall ? 11 : 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ MÉTODO AUXILIAR PARA CAMPO DE EDAD
  Widget _buildEdadTextField(
      int? filtroEdad, Function(String) onChanged, VoidCallback onClear,
      {required bool isSmall}) {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: filtroEdad != null ? primaryTeal : Colors.grey.shade300,
                width: filtroEdad != null ? 2 : 1,
              ),
              boxShadow: filtroEdad != null
                  ? [
                      BoxShadow(
                        color: primaryTeal.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    keyboardType: TextInputType.number,
                    style: TextStyle(
                      fontSize: isSmall ? 13 : 14,
                      fontWeight: FontWeight.w600,
                      color: primaryTeal,
                    ),
                    decoration: InputDecoration(
                      hintText: "Ej: 18",
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: isSmall ? 12 : 13,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: isSmall ? 10 : 12,
                        vertical: isSmall ? 8 : 10,
                      ),
                    ),
                    onChanged: onChanged,
                  ),
                ),
                if (filtroEdad != null)
                  Container(
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      color: secondaryOrange.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.clear,
                        color: secondaryOrange,
                        size: isSmall ? 16 : 18,
                      ),
                      padding: EdgeInsets.all(isSmall ? 3 : 4),
                      constraints: const BoxConstraints(),
                      onPressed: onClear,
                      tooltip: 'Limpiar filtro de edad',
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (isSmall && filtroEdad != null)
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: primaryTeal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: primaryTeal.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                '≥ $filtroEdad',
                style: TextStyle(
                  color: primaryTeal,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }




Widget _buildSemanaGroup(
    int numeroSemana, Map<DateTime, List<Registro>> registrosSemana, int anio, int mes) {
  int totalRegistros =
      registrosSemana.values.expand((registros) => registros).length;
  String rangoFechas = _getRangoSemana(registrosSemana);

  String nombreSemana;
  String descripcionSemana = '';

  if (numeroSemana == 0) {
    List<DateTime> fechas = registrosSemana.keys.toList()..sort();
    String primerDia = _getNombreDiaSemana(fechas.first.weekday);
    String ultimoDia = _getNombreDiaSemana(fechas.last.weekday);

    nombreSemana = 'Inicio del Mes';
    descripcionSemana = '($primerDia - $ultimoDia)';
  } else {
    nombreSemana = 'Semana $numeroSemana';
    descripcionSemana = '(Lunes - Domingo)';
  }

  // ✅ Clave única para esta semana
  List<DateTime> fechas = registrosSemana.keys.toList()..sort();
  String claveUnicaSemana = fechas.isNotEmpty
      ? '$anio-$mes-semana$numeroSemana'
      : 'semana_$numeroSemana';

  // Inicializar estado de expansión con verificación
  if (!_semanasExpandidas.containsKey(claveUnicaSemana)) {
    _semanasExpandidas[claveUnicaSemana] = false;
  }

  if (!_filtrosSexoPorSemana.containsKey(claveUnicaSemana)) {
    _filtrosSexoPorSemana[claveUnicaSemana] = null;
  }
  if (!_filtrosEdadPorSemana.containsKey(claveUnicaSemana)) {
    _filtrosEdadPorSemana[claveUnicaSemana] = null;
  }
  if (!_controladoresEdadPorSemana.containsKey(claveUnicaSemana)) {
    _controladoresEdadPorSemana[claveUnicaSemana] = TextEditingController();
  }

  List<Registro> todosLosRegistros =
      registrosSemana.values.expand((registros) => registros).toList();

  return Theme(
    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
    child: Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ExpansionTile(
        // ✅ CRÍTICO: Controlar expansión manualmente
        key: ValueKey('semana_$claveUnicaSemana'),
        initiallyExpanded: _semanasExpandidas[claveUnicaSemana] ?? false,
        onExpansionChanged: (expanded) {
          if (mounted) {
            setState(() {
              _semanasExpandidas[claveUnicaSemana] = expanded;
            });
          }
        },
        leading: CircleAvatar(
          backgroundColor: primaryTeal,
          child: Icon(
            Icons.calendar_view_week,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Text(
              nombreSemana,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: numeroSemana == 0
                    ? secondaryOrange.withOpacity(0.1)
                    : primaryTeal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: numeroSemana == 0
                      ? secondaryOrange.withOpacity(0.3)
                      : primaryTeal.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                descripcionSemana,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: numeroSemana == 0 ? secondaryOrange : primaryTeal,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.date_range, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  rangoFechas,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 12),
                Icon(Icons.people_outline, size: 16, color: secondaryOrange),
                const SizedBox(width: 4),
                StreamBuilder<int>(
                  stream: Stream.value(0),
                  builder: (context, snapshot) {
                    List<Registro> registrosFiltrados =
                        todosLosRegistros.where((registro) {
                      final coincideSexo =
                          _filtrosSexoPorSemana[claveUnicaSemana] == null ||
                              registro.sexo ==
                                  _filtrosSexoPorSemana[claveUnicaSemana];
                      final coincideEdad =
                          _filtrosEdadPorSemana[claveUnicaSemana] == null ||
                              registro.edad >=
                                  _filtrosEdadPorSemana[claveUnicaSemana]!;
                      return coincideSexo && coincideEdad;
                    }).toList();

                    return Text(
                      '${registrosFiltrados.length} registros',
                      style: TextStyle(
                        color: secondaryOrange,
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        children: [
          StatefulBuilder(
            builder: (BuildContext context, StateSetter setLocalState) {
              void actualizarFiltroLocal() {
                setLocalState(() {});
              }

              List<Registro> registrosFiltrados =
                  todosLosRegistros.where((registro) {
                final coincideSexo =
                    _filtrosSexoPorSemana[claveUnicaSemana] == null ||
                        registro.sexo ==
                            _filtrosSexoPorSemana[claveUnicaSemana];
                final coincideEdad =
                    _filtrosEdadPorSemana[claveUnicaSemana] == null ||
                        registro.edad >=
                            _filtrosEdadPorSemana[claveUnicaSemana]!;
                return coincideSexo && coincideEdad;
              }).toList();

              return Column(
                children: [
                  Container(
                    margin: const EdgeInsets.all(12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          primaryTeal.withOpacity(0.05),
                          secondaryOrange.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: primaryTeal.withOpacity(0.2),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: primaryTeal.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.filter_alt,
                                color: primaryTeal,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Filtros',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: primaryTeal,
                              ),
                            ),
                            const Spacer(),
                            if (_filtrosSexoPorSemana[claveUnicaSemana] !=
                                    null ||
                                _filtrosEdadPorSemana[claveUnicaSemana] !=
                                    null)
                              InkWell(
                                onTap: () {
                                  _filtrosSexoPorSemana[claveUnicaSemana] =
                                      null;
                                  _filtrosEdadPorSemana[claveUnicaSemana] =
                                      null;
                                  _controladoresEdadPorSemana[
                                          claveUnicaSemana]
                                      ?.clear();
                                  actualizarFiltroLocal();
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: secondaryOrange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: secondaryOrange.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.clear_all,
                                          color: secondaryOrange, size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Limpiar',
                                        style: TextStyle(
                                          color: secondaryOrange,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Icon(Icons.wc, color: Colors.grey[600], size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Sexo:',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Row(
                                children: [
                                  Expanded(
                                    child: InkWell(
                                      onTap: () {
                                        _filtrosSexoPorSemana[
                                                claveUnicaSemana] =
                                            _filtrosSexoPorSemana[
                                                        claveUnicaSemana] ==
                                                    'Hombre'
                                                ? null
                                                : 'Hombre';
                                        actualizarFiltroLocal();
                                      },
                                      borderRadius: BorderRadius.circular(20),
                                      child: AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 200),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 8),
                                        decoration: BoxDecoration(
                                          gradient: _filtrosSexoPorSemana[
                                                      claveUnicaSemana] ==
                                                  'Hombre'
                                              ? LinearGradient(
                                                  colors: [
                                                    primaryTeal,
                                                    primaryTeal
                                                        .withOpacity(0.8)
                                                  ],
                                                )
                                              : null,
                                          color: _filtrosSexoPorSemana[
                                                      claveUnicaSemana] ==
                                                  'Hombre'
                                              ? null
                                              : Colors.grey[100],
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          border: Border.all(
                                            color: _filtrosSexoPorSemana[
                                                        claveUnicaSemana] ==
                                                    'Hombre'
                                                ? primaryTeal
                                                : Colors.grey.shade300,
                                            width: _filtrosSexoPorSemana[
                                                        claveUnicaSemana] ==
                                                    'Hombre'
                                                ? 2
                                                : 1,
                                          ),
                                          boxShadow: _filtrosSexoPorSemana[
                                                      claveUnicaSemana] ==
                                                  'Hombre'
                                              ? [
                                                  BoxShadow(
                                                    color: primaryTeal
                                                        .withOpacity(0.3),
                                                    blurRadius: 8,
                                                    offset:
                                                        const Offset(0, 2),
                                                  ),
                                                ]
                                              : null,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.male,
                                              color: _filtrosSexoPorSemana[
                                                          claveUnicaSemana] ==
                                                      'Hombre'
                                                  ? Colors.white
                                                  : Colors.grey[600],
                                              size: 18,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Hombre',
                                              style: TextStyle(
                                                color: _filtrosSexoPorSemana[
                                                            claveUnicaSemana] ==
                                                        'Hombre'
                                                    ? Colors.white
                                                    : Colors.grey[700],
                                                fontSize: 12,
                                                fontWeight: _filtrosSexoPorSemana[
                                                            claveUnicaSemana] ==
                                                        'Hombre'
                                                    ? FontWeight.bold
                                                    : FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: InkWell(
                                      onTap: () {
                                        _filtrosSexoPorSemana[
                                                claveUnicaSemana] =
                                            _filtrosSexoPorSemana[
                                                        claveUnicaSemana] ==
                                                    'Mujer'
                                                ? null
                                                : 'Mujer';
                                        actualizarFiltroLocal();
                                      },
                                      borderRadius: BorderRadius.circular(20),
                                      child: AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 200),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 8),
                                        decoration: BoxDecoration(
                                          gradient: _filtrosSexoPorSemana[
                                                      claveUnicaSemana] ==
                                                  'Mujer'
                                              ? LinearGradient(
                                                  colors: [
                                                    secondaryOrange,
                                                    secondaryOrange
                                                        .withOpacity(0.8)
                                                  ],
                                                )
                                              : null,
                                          color: _filtrosSexoPorSemana[
                                                      claveUnicaSemana] ==
                                                  'Mujer'
                                              ? null
                                              : Colors.grey[100],
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          border: Border.all(
                                            color: _filtrosSexoPorSemana[
                                                        claveUnicaSemana] ==
                                                    'Mujer'
                                                ? secondaryOrange
                                                : Colors.grey.shade300,
                                            width: _filtrosSexoPorSemana[
                                                        claveUnicaSemana] ==
                                                    'Mujer'
                                                ? 2
                                                : 1,
                                          ),
                                          boxShadow: _filtrosSexoPorSemana[
                                                      claveUnicaSemana] ==
                                                  'Mujer'
                                              ? [
                                                  BoxShadow(
                                                    color: secondaryOrange
                                                        .withOpacity(0.3),
                                                    blurRadius: 8,
                                                    offset:
                                                        const Offset(0, 2),
                                                  ),
                                                ]
                                              : null,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.female,
                                              color: _filtrosSexoPorSemana[
                                                          claveUnicaSemana] ==
                                                      'Mujer'
                                                  ? Colors.white
                                                  : Colors.grey[600],
                                              size: 18,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Mujer',
                                              style: TextStyle(
                                                color: _filtrosSexoPorSemana[
                                                            claveUnicaSemana] ==
                                                        'Mujer'
                                                    ? Colors.white
                                                    : Colors.grey[700],
                                                fontSize: 12,
                                                fontWeight: _filtrosSexoPorSemana[
                                                            claveUnicaSemana] ==
                                                        'Mujer'
                                                    ? FontWeight.bold
                                                    : FontWeight.w500,
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
                          ],
                        ),

                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Icon(Icons.cake,
                                color: Colors.grey[600], size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Edad mínima:',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _filtrosEdadPorSemana[
                                                claveUnicaSemana] !=
                                            null
                                        ? primaryTeal
                                        : Colors.grey.shade300,
                                    width: _filtrosEdadPorSemana[
                                                claveUnicaSemana] !=
                                            null
                                        ? 2
                                        : 1,
                                  ),
                                  boxShadow: _filtrosEdadPorSemana[
                                              claveUnicaSemana] !=
                                          null
                                      ? [
                                          BoxShadow(
                                            color:
                                                primaryTeal.withOpacity(0.1),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller:
                                            _controladoresEdadPorSemana[
                                                claveUnicaSemana],
                                        keyboardType: TextInputType.number,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: primaryTeal,
                                        ),
                                        decoration: InputDecoration(
                                          hintText: "Ej: 18",
                                          hintStyle: TextStyle(
                                            color: Colors.grey[400],
                                            fontSize: 13,
                                          ),
                                          border: InputBorder.none,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 10,
                                          ),
                                        ),
                                        onChanged: (value) {
                                          _filtrosEdadPorSemana[
                                                  claveUnicaSemana] =
                                              int.tryParse(value);
                                          actualizarFiltroLocal();
                                        },
                                      ),
                                    ),
                                    if (_filtrosEdadPorSemana[
                                            claveUnicaSemana] !=
                                        null)
                                      Container(
                                        margin:
                                            const EdgeInsets.only(right: 4),
                                        decoration: BoxDecoration(
                                          color: secondaryOrange
                                              .withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: IconButton(
                                          icon: Icon(Icons.clear,
                                              color: secondaryOrange,
                                              size: 18),
                                          padding: const EdgeInsets.all(4),
                                          constraints:
                                              const BoxConstraints(),
                                          onPressed: () {
                                            _filtrosEdadPorSemana[
                                                claveUnicaSemana] = null;
                                            _controladoresEdadPorSemana[
                                                    claveUnicaSemana]
                                                ?.clear();
                                            actualizarFiltroLocal();
                                          },
                                          tooltip: 'Limpiar filtro de edad',
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            if (_filtrosEdadPorSemana[claveUnicaSemana] !=
                                null)
                              Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: primaryTeal.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: primaryTeal.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    '≥ ${_filtrosEdadPorSemana[claveUnicaSemana]}',
                                    style: TextStyle(
                                      color: primaryTeal,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

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
              );
            },
          ),
        ],
      ),
    ),
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 600;
        final isMediumScreen =
            constraints.maxWidth >= 600 && constraints.maxWidth < 900;

        return SingleChildScrollView(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                // Card de Filtro por Fecha - MEJORADO
                Card(
                  margin: EdgeInsets.all(isSmallScreen ? 12 : 16),
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
                        colors: [Colors.white, primaryTeal.withOpacity(0.08)],
                      ),
                    ),
                    padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    secondaryOrange,
                                    secondaryOrange.withOpacity(0.7)
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: secondaryOrange.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.date_range_rounded,
                                size: isSmallScreen ? 22 : 28,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: isSmallScreen ? 10 : 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Filtrar por Fecha',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 18 : 24,
                                      fontWeight: FontWeight.bold,
                                      color: primaryTeal,
                                    ),
                                  ),
                                  if (_startDate != null && _endDate != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        '${DateFormat('dd/MM/yyyy').format(_startDate!)} - ${DateFormat('dd/MM/yyyy').format(_endDate!)}',
                                        style: TextStyle(
                                          fontSize: isSmallScreen ? 11 : 13,
                                          color: Colors.grey[600],
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: isSmallScreen ? 16 : 20),
                        _buildDateRangeSelector(),
                      ],
                    ),
                  ),
                ),

                // StreamBuilder con diseño mejorado
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('social_profiles')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Container(
                        height: 200,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(primaryTeal),
                                strokeWidth: 3,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Cargando perfiles...',
                                style: TextStyle(
                                  color: primaryTeal,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    List<SocialProfile> allPerfiles =
                        snapshot.data!.docs.map((doc) {
                      return SocialProfile.fromMap(
                          doc.data() as Map<String, dynamic>, doc.id);
                    }).toList();

                    // Filtrar por rango de fechas si está seleccionado
                    List<SocialProfile> filteredPerfiles = allPerfiles;
                    if (_startDate != null && _endDate != null) {
                      filteredPerfiles = allPerfiles.where((perfil) {
                        DateTime createdAt = perfil.createdAt;
                        return createdAt.isAfter(_startDate!
                                .subtract(const Duration(seconds: 1))) &&
                            createdAt.isBefore(
                                _endDate!.add(const Duration(seconds: 1)));
                      }).toList();
                    }

                    if (filteredPerfiles.isEmpty) {
                      return Card(
                        margin: EdgeInsets.all(isSmallScreen ? 12 : 16),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Container(
                          padding: EdgeInsets.all(isSmallScreen ? 20 : 32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding:
                                    EdgeInsets.all(isSmallScreen ? 16 : 20),
                                decoration: BoxDecoration(
                                  color: secondaryOrange.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.search_off_rounded,
                                  size: isSmallScreen ? 40 : 56,
                                  color: secondaryOrange.withOpacity(0.7),
                                ),
                              ),
                              SizedBox(height: isSmallScreen ? 16 : 20),
                              Text(
                                _startDate != null && _endDate != null
                                    ? 'No hay perfiles sociales en el rango seleccionado'
                                    : 'No hay perfiles sociales disponibles',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 15 : 18,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (_startDate != null && _endDate != null) ...[
                                const SizedBox(height: 12),
                                TextButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _startDate = null;
                                      _endDate = null;
                                    });
                                  },
                                  icon: const Icon(Icons.clear_all),
                                  label: const Text('Limpiar filtro'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: primaryTeal,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }

                    // Agrupar perfiles por año, mes y semana
                    Map<int, Map<int, Map<int, List<SocialProfile>>>>
                        groupedPerfiles = {};
                    Set<int> years = {};

                    for (var perfil in filteredPerfiles) {
                      final DateTime date = perfil.createdAt;
                      final int year = date.year;
                      final int month = date.month;
                      final int weekNumber = _getWeekNumber(date);

                      years.add(year);
                      groupedPerfiles[year] ??= {};
                      groupedPerfiles[year]![month] ??= {};
                      groupedPerfiles[year]![month]![weekNumber] ??= [];
                      groupedPerfiles[year]![month]![weekNumber]!.add(perfil);
                    }

                    List<int> orderedYears = years.toList()
                      ..sort((a, b) => b.compareTo(a));

                    return _buildGroupedPerfilesView(
                      context,
                      groupedPerfiles,
                      orderedYears,
                      primaryTeal,
                      secondaryOrange,
                      isSmallScreen,
                      isMediumScreen,
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGroupedPerfilesView(
    BuildContext context,
    Map<int, Map<int, Map<int, List<SocialProfile>>>> groupedPerfiles,
    List<int> years,
    Color primaryTeal,
    Color secondaryOrange,
    bool isSmallScreen,
    bool isMediumScreen,
  ) {
    return Column(
      children: years.map((year) {
        return _buildYearGroupModern(
          context,
          year,
          groupedPerfiles[year]!,
          primaryTeal,
          secondaryOrange,
          isSmallScreen,
          isMediumScreen,
        );
      }).toList(),
    );
  }

  Widget _buildYearGroupModern(
    BuildContext context,
    int year,
    Map<int, Map<int, List<SocialProfile>>> yearData,
    Color primaryTeal,
    Color secondaryOrange,
    bool isSmallScreen,
    bool isMediumScreen,
  ) {
    int totalProfilesInYear = 0;
    yearData.forEach((month, monthData) {
      monthData.forEach((week, profiles) {
        totalProfilesInYear += profiles.length;
      });
    });

    List<int> months = yearData.keys.toList()..sort();

    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 8 : 16,
        vertical: isSmallScreen ? 6 : 8,
      ),
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 12 : 16,
            vertical: isSmallScreen ? 8 : 12,
          ),
          leading: Container(
            padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [secondaryOrange, secondaryOrange.withOpacity(0.7)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: secondaryOrange.withOpacity(0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              Icons.calendar_today_rounded,
              color: Colors.white,
              size: isSmallScreen ? 20 : 24,
            ),
          ),
          title: Text(
            'Año $year',
            style: TextStyle(
              fontSize: isSmallScreen ? 16 : 20,
              fontWeight: FontWeight.bold,
              color: primaryTeal,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Icon(
                  Icons.people_rounded,
                  size: isSmallScreen ? 14 : 16,
                  color: secondaryOrange,
                ),
                const SizedBox(width: 6),
                Text(
                  '$totalProfilesInYear perfiles registrados',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 12 : 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          children: months.map((month) {
            return _buildMonthGroupModern(
              context,
              month,
              year,
              yearData[month]!,
              primaryTeal,
              secondaryOrange,
              isSmallScreen,
              isMediumScreen,
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMonthGroupModern(
    BuildContext context,
    int month,
    int year,
    Map<int, List<SocialProfile>> monthData,
    Color primaryTeal,
    Color secondaryOrange,
    bool isSmallScreen,
    bool isMediumScreen,
  ) {
    int totalProfilesInMonth = 0;
    monthData.forEach((week, profiles) {
      totalProfilesInMonth += profiles.length;
    });

    List<int> weeks = monthData.keys.toList()..sort();

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 8 : 16,
        vertical: isSmallScreen ? 4 : 6,
      ),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 10 : 14,
              vertical: isSmallScreen ? 6 : 8,
            ),
            leading: Container(
              padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
              decoration: BoxDecoration(
                color: primaryTeal.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: primaryTeal.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Icon(
                Icons.event_rounded,
                color: primaryTeal,
                size: isSmallScreen ? 18 : 22,
              ),
            ),
            title: Text(
              _getMonthName(month),
              style: TextStyle(
                fontSize: isSmallScreen ? 15 : 18,
                fontWeight: FontWeight.bold,
                color: primaryTeal,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '$totalProfilesInMonth perfiles',
                style: TextStyle(
                  fontSize: isSmallScreen ? 11 : 13,
                  color: Colors.grey[600],
                ),
              ),
            ),
            children: weeks.map((week) {
              return _buildWeekGroupModern(
                context,
                week,
                month,
                year,
                monthData[week]!,
                primaryTeal,
                secondaryOrange,
                isSmallScreen,
                isMediumScreen,
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildWeekGroupModern(
    BuildContext context,
    int week,
    int month,
    int year,
    List<SocialProfile> profiles,
    Color primaryTeal,
    Color secondaryOrange,
    bool isSmallScreen,
    bool isMediumScreen,
  ) {
    DateTime startDate = _getFirstDayOfWeek(year, month, week);
    DateTime endDate = startDate.add(const Duration(days: 6));

    final totalProfiles = profiles.length;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 6 : 12,
        vertical: isSmallScreen ? 4 : 6,
      ),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 8 : 12,
              vertical: isSmallScreen ? 4 : 6,
            ),
            leading: Container(
              padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    secondaryOrange.withOpacity(0.2),
                    secondaryOrange.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: secondaryOrange.withOpacity(0.4),
                  width: 1.5,
                ),
              ),
              child: Icon(
                Icons.view_week_rounded,
                color: secondaryOrange,
                size: isSmallScreen ? 16 : 20,
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        week == 0 ? 'Inicio del Mes' : 'Semana $week',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 14 : 16,
                          fontWeight: FontWeight.bold,
                          color: primaryTeal,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${DateFormat('dd/MM').format(startDate)} - ${DateFormat('dd/MM').format(endDate)}',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 10 : 12,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 8 : 10,
                    vertical: isSmallScreen ? 4 : 6,
                  ),
                  decoration: BoxDecoration(
                    color: secondaryOrange.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: secondaryOrange.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.person_rounded,
                        size: isSmallScreen ? 12 : 14,
                        color: secondaryOrange,
                      ),
                      SizedBox(width: isSmallScreen ? 3 : 4),
                      Text(
                        '$totalProfiles',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 11 : 13,
                          fontWeight: FontWeight.bold,
                          color: secondaryOrange,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            children: [
              Container(
                constraints: BoxConstraints(
                  maxHeight: isSmallScreen ? 400 : 500,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 8 : 12,
                    vertical: isSmallScreen ? 6 : 8,
                  ),
                  itemCount: profiles.length,
                  itemBuilder: (context, index) {
                    final perfil = profiles[index];
                    return _buildPerfilTileModern(
                      context,
                      perfil,
                      primaryTeal,
                      secondaryOrange,
                      isSmallScreen,
                      isMediumScreen,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPerfilTileModern(
    BuildContext context,
    SocialProfile perfil,
    Color primaryTeal,
    Color secondaryOrange,
    bool isSmallScreen,
    bool isMediumScreen,
  ) {
    final perfilId = perfil.id ?? '';

    return Card(
      margin: EdgeInsets.symmetric(
        vertical: isSmallScreen ? 4 : 6,
        horizontal: 0,
      ),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: primaryTeal.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _mostrarDetallesPerfil(context, perfil),
        child: Padding(
          padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Avatar
                  Hero(
                    tag: 'avatar_${perfil.id}',
                    child: Container(
                      width: isSmallScreen ? 44 : 52,
                      height: isSmallScreen ? 44 : 52,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            secondaryOrange.withOpacity(0.8),
                            secondaryOrange.withOpacity(0.6),
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: secondaryOrange.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          perfil.name.isNotEmpty
                              ? perfil.name[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 18 : 22,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: isSmallScreen ? 10 : 12),

                  // Información
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${perfil.name} ${perfil.lastName}',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 14 : 16,
                            fontWeight: FontWeight.bold,
                            color: primaryTeal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              _getSocialNetworkIcon(perfil.socialNetwork),
                              size: isSmallScreen ? 12 : 14,
                              color: secondaryOrange,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                perfil.socialNetwork,
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 11 : 12,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.access_time_rounded,
                              size: isSmallScreen ? 12 : 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('HH:mm').format(perfil.createdAt),
                              style: TextStyle(
                                fontSize: isSmallScreen ? 11 : 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 8),

              // Botones de acción
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Botón editar
                  _buildActionButton(
                    icon: Icons.edit_rounded,
                    label: isSmallScreen ? '' : 'Editar',
                    color: primaryTeal,
                    onPressed: () => _editarPerfilSocial(context, perfil),
                    isSmallScreen: isSmallScreen,
                  ),

                  const SizedBox(width: 8),

                  // Botón asignar/cambiar
                  if (perfilId.isNotEmpty)
                    StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('social_profiles')
                          .doc(perfilId)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return SizedBox(
                            width: isSmallScreen ? 36 : 80,
                            height: isSmallScreen ? 36 : 36,
                          );
                        }

                        final perfilData =
                            snapshot.data!.data() as Map<String, dynamic>?;
                        final tribuAsignada = perfilData?['tribuAsignada'];
                        final ministerioAsignado =
                            perfilData?['ministerioAsignado'];

                        if (tribuAsignada == null &&
                            ministerioAsignado == null) {
                          return _buildActionButton(
                            icon: Icons.group_add_rounded,
                            label: isSmallScreen ? '' : 'Asignar',
                            color: Colors.blue,
                            onPressed: () => _asignarPerfilAtribu(perfil),
                            isSmallScreen: isSmallScreen,
                          );
                        } else {
                          return _buildActionButton(
                            icon: Icons.swap_horiz_rounded,
                            label: isSmallScreen ? '' : 'Cambiar',
                            color: Colors.orange,
                            onPressed: () => _mostrarConfirmacionCambioSocial(
                                context, perfil),
                            isSmallScreen: isSmallScreen,
                          );
                        }
                      },
                    ),

                  const SizedBox(width: 8),

                  // Botón ver
                  _buildActionButton(
                    icon: Icons.visibility_rounded,
                    label: isSmallScreen ? '' : 'Ver',
                    color: primaryTeal,
                    onPressed: () => _mostrarDetallesPerfil(context, perfil),
                    isSmallScreen: isSmallScreen,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
    required bool isSmallScreen,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 8 : 12,
            vertical: isSmallScreen ? 8 : 8,
          ),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: color,
                size: isSmallScreen ? 16 : 18,
              ),
              if (label.isNotEmpty && !isSmallScreen) ...[
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
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

  void _mostrarDetallesPerfil(
      BuildContext context, SocialProfile perfil) async {
    // ✅ OBTENER DATOS DEL PERFIL Y REGISTRO ASOCIADO
    final perfilDoc = await FirebaseFirestore.instance
        .collection('social_profiles')
        .doc(perfil.id)
        .get();

    final perfilData =
        perfilDoc.exists ? perfilDoc.data() as Map<String, dynamic>? : null;

    final registroAsociadoId = perfilData?['registroAsociadoId'];
    Map<String, dynamic>? registroData;

    if (registroAsociadoId != null &&
        registroAsociadoId.toString().trim().isNotEmpty) {
      try {
        final registroDoc = await FirebaseFirestore.instance
            .collection('registros')
            .doc(registroAsociadoId.toString())
            .get();

        if (registroDoc.exists) {
          registroData = registroDoc.data() as Map<String, dynamic>?;
        }
      } catch (e) {
        print('⚠️ Error al cargar registro: $e');
      }
    }

    // ✅ FUNCIÓN PARA OBTENER VALOR (prioriza registro, luego perfil)
    String obtenerValor(String campoPerfil, String campoRegistro) {
      if (registroData != null && registroData![campoRegistro] != null) {
        final valor = registroData![campoRegistro];
        if (valor.toString().trim().isNotEmpty) {
          return valor.toString();
        }
      }

      if (perfilData != null && perfilData![campoPerfil] != null) {
        final valor = perfilData![campoPerfil];
        if (valor.toString().trim().isNotEmpty) {
          return valor.toString();
        }
      }

      return 'No especificado';
    }

    // ✅ FUNCIÓN PARA VERIFICAR SI UN CAMPO TIENE VALOR
    bool tieneValor(String campoPerfil, String campoRegistro) {
      if (registroData != null && registroData![campoRegistro] != null) {
        final valor = registroData![campoRegistro];
        if (valor.toString().trim().isNotEmpty) {
          return true;
        }
      }

      if (perfilData != null && perfilData![campoPerfil] != null) {
        final valor = perfilData![campoPerfil];
        if (valor.toString().trim().isNotEmpty) {
          return true;
        }
      }

      return false;
    }

    // ✅ FUNCIÓN PARA OBTENER FECHA DE NACIMIENTO
    String obtenerFechaNacimiento() {
      DateTime? fecha;

      // Buscar primero en registro
      if (registroData != null &&
          registroData!.containsKey('fechaNacimiento')) {
        final fechaValue = registroData!['fechaNacimiento'];
        if (fechaValue is Timestamp) {
          fecha = fechaValue.toDate();
        } else if (fechaValue is String) {
          try {
            fecha = DateTime.parse(fechaValue);
          } catch (e) {
            print('Error parsing fechaNacimiento from registro: $e');
          }
        }
      }

      // Luego buscar en perfil social
      if (fecha == null &&
          perfilData != null &&
          perfilData!.containsKey('fechaNacimiento')) {
        final fechaValue = perfilData!['fechaNacimiento'];
        if (fechaValue is Timestamp) {
          fecha = fechaValue.toDate();
        } else if (fechaValue is String) {
          try {
            fecha = DateTime.parse(fechaValue);
          } catch (e) {
            print('Error parsing fechaNacimiento from perfil: $e');
          }
        }
      }

      if (fecha != null) {
        return DateFormat('dd/MM/yyyy').format(fecha);
      }

      return 'No especificada';
    }

    // ✅ FUNCIÓN PARA OBTENER OCUPACIONES (lista → string)
    String obtenerOcupaciones() {
      if (registroData != null && registroData!.containsKey('ocupaciones')) {
        final ocupaciones = registroData!['ocupaciones'];
        if (ocupaciones is List && ocupaciones.isNotEmpty) {
          return ocupaciones.join(', ');
        }
      }
      return 'No especificadas';
    }

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
                              '${obtenerValor('name', 'nombre')} ${obtenerValor('lastName', 'apellido')}',
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

                // Contenido
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      children: [
                        // Información Personal
                        _buildDetailSection(
                          'Información Personal',
                          [
                            _buildDetailItem(Icons.cake, 'Edad',
                                '${obtenerValor('age', 'edad')} años'),
                            _buildDetailItem(
                                _getGenderIcon(obtenerValor('gender', 'sexo')),
                                'Género',
                                _formatGender(obtenerValor('gender', 'sexo'))),
                            _buildDetailItem(
                                Icons.phone,
                                'Teléfono',
                                _formatPhone(
                                    obtenerValor('phone', 'telefono'))),
                            // ✅ CAMPOS OPCIONALES
                            if (tieneValor('estadoCivil', 'estadoCivil'))
                              _buildDetailItem(
                                  Icons.family_restroom,
                                  'Estado Civil',
                                  obtenerValor('estadoCivil', 'estadoCivil')),
                            if (tieneValor('nombrePareja', 'nombrePareja'))
                              _buildDetailItem(
                                  Icons.favorite,
                                  'Nombre de Pareja',
                                  obtenerValor('nombrePareja', 'nombrePareja')),
                            // ✅ FECHA DE NACIMIENTO
                            if (obtenerFechaNacimiento() != 'No especificada')
                              _buildDetailItem(
                                  Icons.calendar_today,
                                  'Fecha de Nacimiento',
                                  obtenerFechaNacimiento()),
                          ],
                        ),

                        const SizedBox(height: 4),
                        const Divider(indent: 20, endIndent: 20),
                        const SizedBox(height: 4),

                        // Ubicación
                        _buildDetailSection(
                          'Ubicación',
                          [
                            _buildDetailItem(Icons.home, 'Dirección',
                                obtenerValor('address', 'direccion')),
                            _buildDetailItem(Icons.location_city, 'Ciudad',
                                obtenerValor('city', 'barrio')),
                          ],
                        ),

                        const SizedBox(height: 4),
                        const Divider(indent: 20, endIndent: 20),
                        const SizedBox(height: 4),

                        // ✅ Ocupaciones (SOLO SI HAY DATOS)
                        if (obtenerOcupaciones() != 'No especificadas') ...[
                          _buildDetailSection(
                            'Ocupaciones',
                            [
                              _buildDetailItem(Icons.work, 'Ocupaciones',
                                  obtenerOcupaciones()),
                              if (tieneValor('descripcionOcupacion',
                                  'descripcionOcupacion'))
                                _buildDetailItem(
                                    Icons.work_outline,
                                    'Descripción',
                                    obtenerValor('descripcionOcupacion',
                                        'descripcionOcupacion')),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Divider(indent: 20, endIndent: 20),
                          const SizedBox(height: 4),
                        ],

                        // ✅ Seguimiento (SOLO SI HAY DATOS)
                        if (tieneValor(
                                'estadoFonovisita', 'estadoFonovisita') ||
                            tieneValor('estadoProceso', 'estadoProceso')) ...[
                          _buildDetailSection(
                            'Seguimiento',
                            [
                              if (tieneValor(
                                  'estadoFonovisita', 'estadoFonovisita'))
                                _buildDetailItem(
                                    Icons.call,
                                    'Estado de Fonovisita',
                                    obtenerValor('estadoFonovisita',
                                        'estadoFonovisita')),
                              if (tieneValor('estadoProceso', 'estadoProceso'))
                                _buildDetailItem(
                                    Icons.track_changes,
                                    'Estado del Proceso',
                                    obtenerValor(
                                        'estadoProceso', 'estadoProceso')),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Divider(indent: 20, endIndent: 20),
                          const SizedBox(height: 4),
                        ],

                        // Información Adicional
                        _buildDetailSection(
                          'Información Adicional',
                          [
                            _buildDetailItem(
                                Icons.favorite,
                                'Petición de Oración',
                                obtenerValor('prayerRequest', 'peticiones')),
                            if (tieneValor('observaciones', 'observaciones'))
                              _buildDetailItem(
                                  Icons.note,
                                  'Observaciones',
                                  obtenerValor(
                                      'observaciones', 'observaciones')),
                            if (tieneValor('observaciones2', 'observaciones2'))
                              _buildDetailItem(
                                  Icons.notes,
                                  'Observaciones 2',
                                  obtenerValor(
                                      'observaciones2', 'observaciones2')),
                            if (tieneValor(
                                'referenciaInvitacion', 'referenciaInvitacion'))
                              _buildDetailItem(
                                  Icons.link,
                                  'Referencia de Invitación',
                                  obtenerValor('referenciaInvitacion',
                                      'referenciaInvitacion')),
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

                // Botones
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

  void _editarPerfilSocial(BuildContext context, SocialProfile perfil) async {
    // Obtener datos actuales
    final perfilDoc = await FirebaseFirestore.instance
        .collection('social_profiles')
        .doc(perfil.id)
        .get();

    final perfilData =
        perfilDoc.exists ? perfilDoc.data() as Map<String, dynamic>? : null;

    final registroAsociadoId = perfilData?['registroAsociadoId'];
    Map<String, dynamic>? registroData;

    if (registroAsociadoId != null &&
        registroAsociadoId.toString().trim().isNotEmpty) {
      try {
        final registroDoc = await FirebaseFirestore.instance
            .collection('registros')
            .doc(registroAsociadoId.toString())
            .get();

        if (registroDoc.exists) {
          registroData = registroDoc.data() as Map<String, dynamic>?;
        }
      } catch (e) {
        print('⚠️ Error al cargar registro asociado: $e');
      }
    }

    // Función para obtener valor inicial
    String obtenerValorInicial(String campoPerfil, String campoRegistro) {
      if (registroData != null && registroData![campoRegistro] != null) {
        final valor = registroData![campoRegistro];
        if (valor.toString().trim().isNotEmpty) {
          return valor.toString();
        }
      }

      if (perfilData != null && perfilData![campoPerfil] != null) {
        final valor = perfilData![campoPerfil];
        if (valor.toString().trim().isNotEmpty) {
          return valor.toString();
        }
      }

      return '';
    }

    bool campoTieneValor(String campoPerfil, String campoRegistro) {
      final valor = obtenerValorInicial(campoPerfil, campoRegistro);
      return valor.trim().isNotEmpty;
    }

    DateTime? obtenerFechaNacimiento() {
      if (registroData != null &&
          registroData!.containsKey('fechaNacimiento')) {
        final fechaValue = registroData!['fechaNacimiento'];
        if (fechaValue is Timestamp) {
          return fechaValue.toDate();
        } else if (fechaValue is String) {
          try {
            return DateTime.parse(fechaValue);
          } catch (e) {
            print('Error parsing fechaNacimiento from registro: $e');
          }
        }
      }

      if (perfilData != null && perfilData!.containsKey('fechaNacimiento')) {
        final fechaValue = perfilData!['fechaNacimiento'];
        if (fechaValue is Timestamp) {
          return fechaValue.toDate();
        } else if (fechaValue is String) {
          try {
            return DateTime.parse(fechaValue);
          } catch (e) {
            print('Error parsing fechaNacimiento from perfil: $e');
          }
        }
      }

      return null;
    }

    // Controllers
    final nombreController =
        TextEditingController(text: obtenerValorInicial('name', 'nombre'));
    final apellidoController = TextEditingController(
        text: obtenerValorInicial('lastName', 'apellido'));
    final telefonoController =
        TextEditingController(text: obtenerValorInicial('phone', 'telefono'));
    final direccionController = TextEditingController(
        text: obtenerValorInicial('address', 'direccion'));
    final ciudadController =
        TextEditingController(text: obtenerValorInicial('city', 'barrio'));
    final edadController =
        TextEditingController(text: obtenerValorInicial('age', 'edad'));
    final sexoController =
        TextEditingController(text: obtenerValorInicial('gender', 'sexo'));
    final peticionesController = TextEditingController(
        text: obtenerValorInicial('prayerRequest', 'peticiones'));
    final estadoFonovisitaController = TextEditingController(
        text: obtenerValorInicial('estadoFonovisita', 'estadoFonovisita'));
    final observacionesController = TextEditingController(
        text: obtenerValorInicial('observaciones', 'observaciones'));
    final estadoProcesoController = TextEditingController(
        text: obtenerValorInicial('estadoProceso', 'estadoProceso'));
    final descripcionOcupacionController = TextEditingController(
        text: obtenerValorInicial(
            'descripcionOcupacion', 'descripcionOcupacion'));
    final estadoCivilController = TextEditingController(
        text: registroData?['estadoCivil']?.toString() ?? '');
    final nombreParejaController = TextEditingController(
        text: registroData?['nombrePareja']?.toString() ?? '');
    final observaciones2Controller = TextEditingController(
        text: registroData?['observaciones2']?.toString() ?? '');
    final referenciaInvitacionController = TextEditingController(
        text: registroData?['referenciaInvitacion']?.toString() ?? '');
    final ocupacionesController = TextEditingController(
        text: (registroData?['ocupaciones'] as List?)?.join(', ') ?? '');

    String? estadoFonovisitaSeleccionado =
        obtenerValorInicial('estadoFonovisita', 'estadoFonovisita');
    DateTime? fechaNacimiento = obtenerFechaNacimiento();

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final screenWidth = constraints.maxWidth;
                final screenHeight = constraints.maxHeight;
                final isVerySmallScreen = screenWidth < 400;
                final isSmallScreen = screenWidth < 600;
                final isMediumScreen = screenWidth >= 600 && screenWidth < 900;

                final dialogWidth = isVerySmallScreen
                    ? screenWidth * 0.95
                    : isSmallScreen
                        ? screenWidth * 0.90
                        : isMediumScreen
                            ? screenWidth * 0.75
                            : screenWidth * 0.60;

                final titleFontSize = isVerySmallScreen
                    ? 18.0
                    : isSmallScreen
                        ? 20.0
                        : 24.0;
                final sectionFontSize = isVerySmallScreen
                    ? 14.0
                    : isSmallScreen
                        ? 15.0
                        : 16.0;
                final iconSize = isVerySmallScreen
                    ? 20.0
                    : isSmallScreen
                        ? 22.0
                        : 24.0;
                final padding = isVerySmallScreen
                    ? 12.0
                    : isSmallScreen
                        ? 16.0
                        : 20.0;

                return Dialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  elevation: 12,
                  insetPadding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 10 : 20,
                    vertical: isSmallScreen ? 10 : 24,
                  ),
                  child: Container(
                    width: dialogWidth,
                    constraints: BoxConstraints(
                      maxHeight: screenHeight * 0.95,
                      maxWidth: 700,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white,
                          secondaryOrange.withOpacity(0.03),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: secondaryOrange.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header con degradado
                        Container(
                          padding: EdgeInsets.all(padding),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                secondaryOrange,
                                secondaryOrange.withOpacity(0.85)
                              ],
                            ),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(24),
                              topRight: Radius.circular(24),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: secondaryOrange.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding:
                                    EdgeInsets.all(isVerySmallScreen ? 8 : 10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.edit_rounded,
                                  color: Colors.white,
                                  size: iconSize,
                                ),
                              ),
                              SizedBox(width: isSmallScreen ? 10 : 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Editar Perfil Social',
                                      style: TextStyle(
                                        fontSize: titleFontSize,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    if (!isVerySmallScreen)
                                      Text(
                                        'Actualiza la información del perfil',
                                        style: TextStyle(
                                          fontSize: sectionFontSize - 3,
                                          color: Colors.white.withOpacity(0.9),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => Navigator.pop(context),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    child: Icon(
                                      Icons.close_rounded,
                                      color: Colors.white,
                                      size: iconSize,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Contenido scrollable
                        Expanded(
                          child: SingleChildScrollView(
                            child: Padding(
                              padding: EdgeInsets.all(padding),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Información Personal
                                  _buildEditSectionHeader(
                                    'Información Personal',
                                    Icons.person_rounded,
                                    primaryTeal,
                                    sectionFontSize,
                                    iconSize,
                                  ),
                                  const SizedBox(height: 12),

                                  _buildModernTextField(
                                    controller: nombreController,
                                    label: 'Nombre',
                                    icon: Icons.badge_rounded,
                                    isSmallScreen: isSmallScreen,
                                  ),
                                  const SizedBox(height: 12),

                                  _buildModernTextField(
                                    controller: apellidoController,
                                    label: 'Apellido',
                                    icon: Icons.person_outline_rounded,
                                    isSmallScreen: isSmallScreen,
                                  ),

                                  if (campoTieneValor('age', 'edad') ||
                                      campoTieneValor('gender', 'sexo')) ...[
                                    const SizedBox(height: 12),
                                    if (!isVerySmallScreen &&
                                        campoTieneValor('age', 'edad') &&
                                        campoTieneValor('gender', 'sexo'))
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _buildModernTextField(
                                              controller: edadController,
                                              label: 'Edad',
                                              icon: Icons.cake_rounded,
                                              keyboardType:
                                                  TextInputType.number,
                                              isSmallScreen: isSmallScreen,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: _buildModernTextField(
                                              controller: sexoController,
                                              label: 'Sexo/Género',
                                              icon: Icons.wc_rounded,
                                              isSmallScreen: isSmallScreen,
                                            ),
                                          ),
                                        ],
                                      )
                                    else ...[
                                      if (campoTieneValor('age', 'edad'))
                                        _buildModernTextField(
                                          controller: edadController,
                                          label: 'Edad',
                                          icon: Icons.cake_rounded,
                                          keyboardType: TextInputType.number,
                                          isSmallScreen: isSmallScreen,
                                        ),
                                      if (campoTieneValor('age', 'edad') &&
                                          campoTieneValor('gender', 'sexo'))
                                        const SizedBox(height: 12),
                                      if (campoTieneValor('gender', 'sexo'))
                                        _buildModernTextField(
                                          controller: sexoController,
                                          label: 'Sexo/Género',
                                          icon: Icons.wc_rounded,
                                          isSmallScreen: isSmallScreen,
                                        ),
                                    ],
                                  ],

                                  if (campoTieneValor('phone', 'telefono')) ...[
                                    const SizedBox(height: 12),
                                    _buildModernTextField(
                                      controller: telefonoController,
                                      label: 'Teléfono',
                                      icon: Icons.phone_rounded,
                                      keyboardType: TextInputType.phone,
                                      isSmallScreen: isSmallScreen,
                                    ),
                                  ],

                                  if (campoTieneValor(
                                      'address', 'direccion')) ...[
                                    const SizedBox(height: 12),
                                    _buildModernTextField(
                                      controller: direccionController,
                                      label: 'Dirección',
                                      icon: Icons.home_rounded,
                                      isSmallScreen: isSmallScreen,
                                    ),
                                  ],

                                  if (campoTieneValor('city', 'barrio')) ...[
                                    const SizedBox(height: 12),
                                    _buildModernTextField(
                                      controller: ciudadController,
                                      label: 'Ciudad',
                                      icon: Icons.location_city_rounded,
                                      isSmallScreen: isSmallScreen,
                                    ),
                                  ],

                                  if (campoTieneValor(
                                      'prayerRequest', 'peticiones')) ...[
                                    const SizedBox(height: 12),
                                    _buildModernTextField(
                                      controller: peticionesController,
                                      label: 'Petición de Oración',
                                      icon: Icons.favorite_border_rounded,
                                      maxLines: 2,
                                      isSmallScreen: isSmallScreen,
                                    ),
                                  ],

                                  // Campos adicionales de registro
                                  if (registroData != null) ...[
                                    if (estadoCivilController.text
                                        .trim()
                                        .isNotEmpty) ...[
                                      const SizedBox(height: 12),
                                      _buildModernTextField(
                                        controller: estadoCivilController,
                                        label: 'Estado Civil',
                                        icon: Icons.family_restroom_rounded,
                                        isSmallScreen: isSmallScreen,
                                      ),
                                    ],
                                    if (nombreParejaController.text
                                        .trim()
                                        .isNotEmpty) ...[
                                      const SizedBox(height: 12),
                                      _buildModernTextField(
                                        controller: nombreParejaController,
                                        label: 'Nombre de Pareja',
                                        icon: Icons.favorite_rounded,
                                        isSmallScreen: isSmallScreen,
                                      ),
                                    ],
                                    if (ocupacionesController.text
                                        .trim()
                                        .isNotEmpty) ...[
                                      const SizedBox(height: 12),
                                      _buildModernTextField(
                                        controller: ocupacionesController,
                                        label: 'Ocupaciones',
                                        icon: Icons.work_rounded,
                                        isSmallScreen: isSmallScreen,
                                      ),
                                    ],
                                    if (referenciaInvitacionController.text
                                        .trim()
                                        .isNotEmpty) ...[
                                      const SizedBox(height: 12),
                                      _buildModernTextField(
                                        controller:
                                            referenciaInvitacionController,
                                        label: 'Referencia de Invitación',
                                        icon: Icons.link_rounded,
                                        isSmallScreen: isSmallScreen,
                                      ),
                                    ],
                                  ],

                                  // Fecha de nacimiento
                                  if (fechaNacimiento != null ||
                                      registroData != null) ...[
                                    const SizedBox(height: 12),
                                    _buildDateSelector(
                                      context: context,
                                      selectedDate: fechaNacimiento,
                                      onDateSelected: (DateTime? picked) {
                                        setDialogState(() {
                                          fechaNacimiento = picked;
                                        });
                                      },
                                      isSmallScreen: isSmallScreen,
                                    ),
                                  ],

                                  const SizedBox(height: 20),

                                  // Seguimiento
                                  _buildEditSectionHeader(
                                    'Seguimiento',
                                    Icons.track_changes_rounded,
                                    secondaryOrange,
                                    sectionFontSize,
                                    iconSize,
                                  ),
                                  const SizedBox(height: 12),

                                  _buildModernDropdown(
                                    value:
                                        estadoFonovisitaSeleccionado?.isEmpty ??
                                                true
                                            ? null
                                            : estadoFonovisitaSeleccionado,
                                    label: 'Estado de Fonovisita',
                                    icon: Icons.call_rounded,
                                    items: [
                                      'Contactada',
                                      'No Contactada',
                                      '# Errado',
                                      'Apagado',
                                      'Buzón',
                                      'Número No Activado',
                                      '# Equivocado',
                                      'Difícil contacto'
                                    ],
                                    onChanged: (valor) {
                                      setDialogState(() {
                                        estadoFonovisitaSeleccionado = valor;
                                        estadoFonovisitaController.text =
                                            valor ?? '';
                                      });
                                    },
                                    isSmallScreen: isSmallScreen,
                                  ),

                                  if (campoTieneValor(
                                      'estadoProceso', 'estadoProceso')) ...[
                                    const SizedBox(height: 12),
                                    _buildModernTextField(
                                      controller: estadoProcesoController,
                                      label: 'Estado del Proceso',
                                      icon: Icons.trending_up_rounded,
                                      isSmallScreen: isSmallScreen,
                                    ),
                                  ],

                                  if (campoTieneValor('descripcionOcupacion',
                                      'descripcionOcupacion')) ...[
                                    const SizedBox(height: 12),
                                    _buildModernTextField(
                                      controller:
                                          descripcionOcupacionController,
                                      label: 'Descripción de Ocupación',
                                      icon: Icons.work_outline_rounded,
                                      maxLines: 2,
                                      isSmallScreen: isSmallScreen,
                                    ),
                                  ],

                                  const SizedBox(height: 12),
                                  _buildModernTextField(
                                    controller: observacionesController,
                                    label: 'Observaciones',
                                    icon: Icons.note_rounded,
                                    maxLines: 3,
                                    isSmallScreen: isSmallScreen,
                                  ),

                                  if (registroData != null &&
                                      observaciones2Controller.text
                                          .trim()
                                          .isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    _buildModernTextField(
                                      controller: observaciones2Controller,
                                      label: 'Observaciones 2',
                                      icon: Icons.notes_rounded,
                                      maxLines: 3,
                                      isSmallScreen: isSmallScreen,
                                    ),
                                  ],

                                  const SizedBox(height: 30),

                                  // Botones al final del contenido scrollable
                                  Container(
                                    padding: EdgeInsets.all(padding),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: Colors.grey.shade200,
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          style: TextButton.styleFrom(
                                            padding: EdgeInsets.symmetric(
                                              horizontal:
                                                  isSmallScreen ? 16 : 24,
                                              vertical: isSmallScreen ? 12 : 14,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                          child: Text(
                                            'Cancelar',
                                            style: TextStyle(
                                              color: Colors.grey[700],
                                              fontSize: isSmallScreen ? 14 : 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        ElevatedButton.icon(
                                          onPressed: () {
                                            _guardarEdicionPerfilSocialSincronizado(
                                              context,
                                              perfil,
                                              nombreController,
                                              apellidoController,
                                              telefonoController,
                                              direccionController,
                                              ciudadController,
                                              edadController,
                                              sexoController,
                                              peticionesController,
                                              estadoFonovisitaController,
                                              observacionesController,
                                              estadoProcesoController,
                                              descripcionOcupacionController,
                                              estadoCivilController,
                                              nombreParejaController,
                                              observaciones2Controller,
                                              referenciaInvitacionController,
                                              ocupacionesController,
                                              fechaNacimiento,
                                              registroAsociadoId?.toString(),
                                            );
                                          },
                                          icon: Icon(
                                            Icons.save_rounded,
                                            size: isSmallScreen ? 18 : 20,
                                          ),
                                          label: Text(
                                            'Guardar',
                                            style: TextStyle(
                                              fontSize: isSmallScreen ? 14 : 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: primaryTeal,
                                            foregroundColor: Colors.white,
                                            padding: EdgeInsets.symmetric(
                                              horizontal:
                                                  isSmallScreen ? 20 : 28,
                                              vertical: isSmallScreen ? 12 : 14,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            elevation: 4,
                                            shadowColor:
                                                primaryTeal.withOpacity(0.4),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Espacio final adicional
                                  SizedBox(height: isSmallScreen ? 40 : 20),
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
      },
    );
  }

  Future<void> _guardarEdicionPerfilSocialSincronizado(
    BuildContext context,
    SocialProfile perfil,
    TextEditingController nombreController,
    TextEditingController apellidoController,
    TextEditingController telefonoController,
    TextEditingController direccionController,
    TextEditingController ciudadController,
    TextEditingController edadController,
    TextEditingController sexoController,
    TextEditingController peticionesController,
    TextEditingController estadoFonovisitaController,
    TextEditingController observacionesController,
    TextEditingController estadoProcesoController,
    TextEditingController descripcionOcupacionController,
    TextEditingController estadoCivilController,
    TextEditingController nombreParejaController,
    TextEditingController observaciones2Controller,
    TextEditingController referenciaInvitacionController,
    TextEditingController ocupacionesController,
    DateTime? fechaNacimiento,
    String? registroAsociadoId,
  ) async {
    if (perfil.id == null || perfil.id!.isEmpty) {
      _mostrarError('El perfil no tiene un ID válido');
      return;
    }

    try {
      setState(() => _isLoading = true);

      print('\n💾 === INICIANDO GUARDADO SINCRONIZADO ===');
      print('📋 Perfil ID: ${perfil.id}');
      print('📋 Registro Asociado ID: $registroAsociadoId');

      // ✅ PREPARAR DATOS PARA PERFIL SOCIAL
      Map<String, dynamic> updateDataPerfil = {
        'name': nombreController.text.trim(),
        'lastName': apellidoController.text.trim(),
        'phone': telefonoController.text.trim(),
        'address': direccionController.text.trim(),
        'city': ciudadController.text.trim(),
        'age': int.tryParse(edadController.text) ?? perfil.age,
        'gender': sexoController.text.trim(),
        'prayerRequest': peticionesController.text.trim().isEmpty
            ? null
            : peticionesController.text.trim(),
        'estadoFonovisita': estadoFonovisitaController.text.trim(),
        'observaciones': observacionesController.text.trim(),
        'estadoProceso': estadoProcesoController.text.trim(),
        'descripcionOcupacion': descripcionOcupacionController.text.trim(),
      };

      // ✅ AGREGAR FECHA DE NACIMIENTO SI EXISTE
      if (fechaNacimiento != null) {
        updateDataPerfil['fechaNacimiento'] =
            Timestamp.fromDate(fechaNacimiento);
      }

      // ✅ 1. ACTUALIZAR PERFIL SOCIAL
      await FirebaseFirestore.instance
          .collection('social_profiles')
          .doc(perfil.id!)
          .update(updateDataPerfil);

      print('✅ Perfil social actualizado');

      // ✅ 2. SI EXISTE REGISTRO ASOCIADO, SINCRONIZARLO
      bool registroSincronizado = false;

      if (registroAsociadoId != null && registroAsociadoId.trim().isNotEmpty) {
        final registroId = registroAsociadoId.trim();

        try {
          final registroDoc = await FirebaseFirestore.instance
              .collection('registros')
              .doc(registroId)
              .get();

          if (registroDoc.exists) {
            print('📝 Sincronizando con registro: $registroId');

            // ✅ MAPEO COMPLETO DE CAMPOS (perfil → registro)
            Map<String, dynamic> updateDataRegistro = {
              'nombre': nombreController.text.trim(),
              'apellido': apellidoController.text.trim(),
              'telefono': telefonoController.text.trim(),
              'direccion': direccionController.text.trim(),
              'barrio': ciudadController.text.trim(),
              'edad': int.tryParse(edadController.text) ?? perfil.age,
              'sexo': sexoController.text.trim(),
              'peticiones': peticionesController.text.trim(),
              'estadoFonovisita': estadoFonovisitaController.text.trim(),
              'observaciones': observacionesController.text.trim(),
              'estadoProceso': estadoProcesoController.text.trim(),
              'descripcionOcupacion':
                  descripcionOcupacionController.text.trim(),
            };

            // ✅ AGREGAR CAMPOS QUE SOLO EXISTEN EN REGISTRO
            if (estadoCivilController.text.trim().isNotEmpty) {
              updateDataRegistro['estadoCivil'] =
                  estadoCivilController.text.trim();
            }
            if (nombreParejaController.text.trim().isNotEmpty) {
              updateDataRegistro['nombrePareja'] =
                  nombreParejaController.text.trim();
            }
            if (observaciones2Controller.text.trim().isNotEmpty) {
              updateDataRegistro['observaciones2'] =
                  observaciones2Controller.text.trim();
            }
            if (referenciaInvitacionController.text.trim().isNotEmpty) {
              updateDataRegistro['referenciaInvitacion'] =
                  referenciaInvitacionController.text.trim();
            }
            if (ocupacionesController.text.trim().isNotEmpty) {
              updateDataRegistro['ocupaciones'] = ocupacionesController.text
                  .split(',')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList();
            }
            if (fechaNacimiento != null) {
              updateDataRegistro['fechaNacimiento'] =
                  Timestamp.fromDate(fechaNacimiento);
            }

            await FirebaseFirestore.instance
                .collection('registros')
                .doc(registroId)
                .update(updateDataRegistro);

            print('✅ Registro sincronizado exitosamente');
            registroSincronizado = true;
          } else {
            print('⚠️ El registro asociado no existe: $registroId');

            // Limpiar referencia inválida
            await FirebaseFirestore.instance
                .collection('social_profiles')
                .doc(perfil.id!)
                .update({'registroAsociadoId': null});
          }
        } catch (e) {
          print('⚠️ Error al sincronizar con registro: $e');
        }
      } else {
        print('ℹ️ No hay registro asociado para sincronizar');
      }

      print('🏁 === FIN GUARDADO ===\n');

      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.pop(context);

        String mensajeExito = 'Perfil actualizado correctamente';
        if (registroSincronizado) {
          mensajeExito += '\n✓ Sincronizado con registro';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text(mensajeExito)),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e, stackTrace) {
      print('❌ Error: $e');
      print('Stack: $stackTrace');

      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.pop(context);
        _mostrarError('Error al actualizar: ${e.toString()}');
      }
    }
  }

  Future<void> _guardarEdicionPerfilSocial(
    BuildContext context,
    SocialProfile perfil,
    TextEditingController nombreController,
    TextEditingController apellidoController,
    TextEditingController telefonoController,
    TextEditingController direccionController,
    TextEditingController ciudadController,
    TextEditingController edadController,
    TextEditingController sexoController,
    TextEditingController peticionesController,
    TextEditingController estadoFonovisitaController,
    TextEditingController observacionesController,
    TextEditingController estadoProcesoController,
    TextEditingController descripcionOcupacionController,
  ) async {
    if (perfil.id == null || perfil.id!.isEmpty) {
      _mostrarError('El perfil no tiene un ID válido');
      return;
    }

    try {
      setState(() => _isLoading = true);

      print('\n💾 === INICIANDO GUARDADO SINCRONIZADO ===');
      print('📋 Perfil ID: ${perfil.id}');

      // ✅ PREPARAR DATOS PARA ACTUALIZAR
      Map<String, dynamic> updateData = {
        'name': nombreController.text.trim(),
        'lastName': apellidoController.text.trim(),
        'phone': telefonoController.text.trim(),
        'address': direccionController.text.trim(),
        'city': ciudadController.text.trim(),
        'age': int.tryParse(edadController.text) ?? perfil.age,
        'gender': sexoController.text.trim(),
        'prayerRequest': peticionesController.text.trim().isEmpty
            ? null
            : peticionesController.text.trim(),
        'estadoFonovisita': estadoFonovisitaController.text.trim(),
        'observaciones': observacionesController.text.trim(),
        'estadoProceso': estadoProcesoController.text.trim(),
        'descripcionOcupacion': descripcionOcupacionController.text.trim(),
      };

      // ✅ 1. ACTUALIZAR PERFIL SOCIAL
      await FirebaseFirestore.instance
          .collection('social_profiles')
          .doc(perfil.id!)
          .update(updateData);

      print('✅ Perfil social actualizado');

      // ✅ 2. VERIFICAR Y ACTUALIZAR REGISTRO ASOCIADO
      final perfilDoc = await FirebaseFirestore.instance
          .collection('social_profiles')
          .doc(perfil.id!)
          .get();

      if (!perfilDoc.exists) {
        throw Exception('El perfil social no existe');
      }

      final perfilData = perfilDoc.data() as Map<String, dynamic>?;
      final registroAsociadoId = perfilData?['registroAsociadoId'];

      bool registroSincronizado = false;

      if (registroAsociadoId != null &&
          registroAsociadoId.toString().trim().isNotEmpty) {
        final registroId = registroAsociadoId.toString().trim();

        try {
          final registroDoc = await FirebaseFirestore.instance
              .collection('registros')
              .doc(registroId)
              .get();

          if (registroDoc.exists) {
            print('📝 Sincronizando con registro: $registroId');

            // ✅ MAPEO CORRECTO DE CAMPOS
            Map<String, dynamic> updateDataRegistro = {
              'nombre': nombreController.text.trim(),
              'apellido': apellidoController.text.trim(),
              'telefono': telefonoController.text.trim(),
              'direccion': direccionController.text.trim(),
              'barrio': ciudadController.text.trim(),
              'edad': int.tryParse(edadController.text) ?? perfil.age,
              'sexo': sexoController.text.trim(),
              'peticiones': peticionesController.text.trim(),
              'estadoFonovisita': estadoFonovisitaController.text.trim(),
              'observaciones': observacionesController.text.trim(),
              'estadoProceso': estadoProcesoController.text.trim(),
              'descripcionOcupacion':
                  descripcionOcupacionController.text.trim(),
            };

            await FirebaseFirestore.instance
                .collection('registros')
                .doc(registroId)
                .update(updateDataRegistro);

            print('✅ Registro sincronizado exitosamente');
            registroSincronizado = true;
          } else {
            print('⚠️ El registro asociado no existe: $registroId');

            // Limpiar referencia inválida
            await FirebaseFirestore.instance
                .collection('social_profiles')
                .doc(perfil.id!)
                .update({'registroAsociadoId': null});
          }
        } catch (e) {
          print('⚠️ Error al sincronizar con registro: $e');
        }
      } else {
        print('ℹ️ No hay registro asociado para sincronizar');
      }

      print('🏁 === FIN GUARDADO ===\n');

      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.pop(context);

        String mensajeExito = 'Perfil actualizado correctamente';
        if (registroSincronizado) {
          mensajeExito += '\n✓ Sincronizado con registro';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text(mensajeExito)),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e, stackTrace) {
      print('❌ Error: $e');
      print('Stack: $stackTrace');

      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.pop(context);
        _mostrarError('Error al actualizar: ${e.toString()}');
      }
    }
  }

  Future<void> _asignarPerfilAtribu(SocialProfile perfil) async {
    // ✅ VALIDACIÓN CRÍTICA: Verificar contexto montado
    if (!mounted) {
      print('⚠️ Widget no está montado, cancelando asignación');
      return;
    }

    // ✅ VALIDACIÓN CRÍTICA: Verificar que perfil.id no sea null
    if (perfil.id == null || perfil.id!.isEmpty) {
      print('❌ Error: El perfil no tiene un ID válido');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Expanded(child: Text('Error: El perfil no tiene un ID válido')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    try {
      print('\n🔄 === INICIANDO PROCESO DE ASIGNACIÓN ===');
      print('📋 Perfil ID: ${perfil.id}');

      // ✅ Mostrar indicador de carga ANTES de cualquier operación
      if (mounted) {
        setState(() => _isLoading = true);
      }

      // ✅ 1. OBTENER TRIBUS Y MINISTERIOS
      final tribusSnapshot = await FirebaseFirestore.instance
          .collection('tribus')
          .where('categoria', isEqualTo: 'Ministerio Juvenil')
          .get();

      final ministerios = ['Ministerio de Damas', 'Ministerio de Caballeros'];

      if (tribusSnapshot.docs.isEmpty && ministerios.isEmpty) {
        print('⚠️ No hay tribus o ministerios disponibles');
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No hay tribus o ministerios disponibles'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      // ✅ 2. PREPARAR OPCIONES PARA EL DROPDOWN
      List<DropdownMenuItem<String>> opciones = [];

      for (var min in ministerios) {
        opciones.add(DropdownMenuItem(
          value: min,
          child: Row(
            children: [
              Icon(
                min.contains('Damas') ? Icons.female : Icons.male,
                color: primaryTeal,
                size: 18,
              ),
              SizedBox(width: 8),
              Text(min),
            ],
          ),
        ));
      }

      opciones.add(DropdownMenuItem(
        value: 'separator',
        enabled: false,
        child: Divider(thickness: 2, color: Colors.grey),
      ));

      opciones.add(DropdownMenuItem(
        value: 'juveniles_title',
        enabled: false,
        child: Text(
          'Tribus Juveniles',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
      ));

      for (var doc in tribusSnapshot.docs) {
        final nombre = doc['nombre'] ?? 'Sin nombre';
        opciones.add(DropdownMenuItem(
          value: doc.id,
          child: Text(nombre),
        ));
      }

      String? opcionSeleccionada;

      // ✅ Ocultar loading antes de mostrar el diálogo
      if (mounted) {
        setState(() => _isLoading = false);
      }

      // ✅ 3. MOSTRAR DIÁLOGO Y ESPERAR SELECCIÓN
      if (!mounted) return;

      final bool? confirmado = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return StatefulBuilder(
            builder: (BuildContext context, StateSetter setDialogState) {
              return AlertDialog(
                title: Text(
                  'Asignar a Ministerio o Tribu',
                  style: TextStyle(
                    color: primaryTeal,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: opcionSeleccionada,
                      items: opciones,
                      onChanged: (value) {
                        if (value != 'separator' &&
                            value != 'juveniles_title') {
                          setDialogState(() {
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    child:
                        Text('Cancelar', style: TextStyle(color: Colors.grey)),
                  ),
                  ElevatedButton(
                    onPressed: opcionSeleccionada == null
                        ? null
                        : () => Navigator.of(dialogContext).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: secondaryOrange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text('Asignar'),
                  ),
                ],
              );
            },
          );
        },
      );

      // ✅ VERIFICAR SI SE CANCELÓ O NO HAY CONTEXTO
      if (confirmado != true || opcionSeleccionada == null) {
        print('ℹ️ Asignación cancelada por el usuario');
        return;
      }

      if (!mounted) {
        print('⚠️ Widget desmontado después del diálogo');
        return;
      }

      // ✅ 4. PROCESAR LA ASIGNACIÓN
      setState(() => _isLoading = true);

      try {
        String? ministerioAsignado;
        String? tribuAsignada;
        String? nombreTribu;

        if (opcionSeleccionada!.contains('Ministerio')) {
          ministerioAsignado = opcionSeleccionada;
          tribuAsignada = null;
          nombreTribu = null;
        } else {
          tribuAsignada = opcionSeleccionada;
          ministerioAsignado = 'Ministerio Juvenil';

          final tribuDoc = tribusSnapshot.docs.firstWhere(
            (doc) => doc.id == opcionSeleccionada,
            orElse: () => throw Exception('Tribu no encontrada'),
          );
          nombreTribu = tribuDoc['nombre'] ?? 'Tribu sin nombre';
        }

        print('\n📝 Preparando asignación:');
        print('  - Ministerio: $ministerioAsignado');
        print('  - Tribu: $tribuAsignada');
        print('  - Nombre Tribu: $nombreTribu');

        // ✅ PREPARAR DATOS DE ASIGNACIÓN
        Map<String, dynamic> asignacionData = {
          'ministerioAsignado': ministerioAsignado,
          'tribuAsignada': tribuAsignada,
          'nombreTribu': nombreTribu,
          'fechaAsignacion': FieldValue.serverTimestamp(),
          'yaAsignado': true,
        };

        // ✅ 5. ACTUALIZAR PERFIL SOCIAL
        await FirebaseFirestore.instance
            .collection('social_profiles')
            .doc(perfil.id!)
            .update(asignacionData);

        print('✅ Perfil social actualizado con asignación');

        // ✅ 6. VERIFICAR SI EXISTE REGISTRO ASOCIADO
        final perfilDoc = await FirebaseFirestore.instance
            .collection('social_profiles')
            .doc(perfil.id!)
            .get();

        if (!perfilDoc.exists) {
          throw Exception(
              'El perfil social no existe después de la actualización');
        }

        final perfilData = perfilDoc.data() as Map<String, dynamic>;
        final registroAsociadoId = perfilData['registroAsociadoId'];

        bool registroActualizado = false;

        // ✅ 7. SI EXISTE REGISTRO ASOCIADO, ACTUALIZARLO
        if (registroAsociadoId != null &&
            registroAsociadoId.toString().trim().isNotEmpty) {
          final registroId = registroAsociadoId.toString().trim();

          try {
            final registroDoc = await FirebaseFirestore.instance
                .collection('registros')
                .doc(registroId)
                .get();

            if (registroDoc.exists) {
              // ✅ ACTUALIZAR REGISTRO EXISTENTE
              await FirebaseFirestore.instance
                  .collection('registros')
                  .doc(registroId)
                  .update(asignacionData);

              print('✅ Registro asociado actualizado con asignación');
              registroActualizado = true;
            } else {
              print('⚠️ El registro asociado no existe: $registroId');
              // ✅ CREAR NUEVO REGISTRO A PARTIR DEL PERFIL SOCIAL
              await _crearRegistroDesdePerfilSocial(perfil, asignacionData);
              registroActualizado = true;
            }
          } catch (e) {
            print('⚠️ Error al actualizar registro asociado: $e');
            // ✅ INTENTAR CREAR REGISTRO COMO FALLBACK
            await _crearRegistroDesdePerfilSocial(perfil, asignacionData);
            registroActualizado = true;
          }
        } else {
          // ✅ 8. NO HAY REGISTRO ASOCIADO, CREAR UNO NUEVO
          print('ℹ️ No hay registro asociado, creando uno nuevo...');
          await _crearRegistroDesdePerfilSocial(perfil, asignacionData);
          registroActualizado = true;
        }

        // ✅ 9. VERIFICACIÓN FINAL
        await Future.delayed(Duration(milliseconds: 300));

        final verificacion = await FirebaseFirestore.instance
            .collection('social_profiles')
            .doc(perfil.id!)
            .get();

        if (verificacion.exists) {
          final data = verificacion.data() as Map<String, dynamic>;
          print('\n=== VERIFICACIÓN FINAL ===');
          print('ministerioAsignado: ${data['ministerioAsignado']}');
          print('tribuAsignada: ${data['tribuAsignada']}');
          print('nombreTribu: ${data['nombreTribu']}');
          print('yaAsignado: ${data['yaAsignado']}');
          print('registroAsociadoId: ${data['registroAsociadoId']}');
          print('========================\n');
        }

        // ✅ 10. MOSTRAR MENSAJE DE ÉXITO
        if (mounted) {
          setState(() => _isLoading = false);

          String mensaje = '✓ Asignación completada exitosamente';
          if (registroActualizado) {
            mensaje += '\n✓ Registro sincronizado';
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      mensaje,
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 3),
            ),
          );
        }

        print('🎉 === ASIGNACIÓN COMPLETADA EXITOSAMENTE ===\n');
      } catch (e, stackTrace) {
        print('❌ Error durante la asignación: $e');
        print('Stack trace: $stackTrace');

        if (mounted) {
          setState(() => _isLoading = false);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.white, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text('Error al asignar: ${e.toString()}'),
                  ),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      print('❌ Error general en el proceso: $e');
      print('Stack trace: $stackTrace');

      if (mounted) {
        setState(() => _isLoading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text('Error: ${e.toString()}'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  /// Crea un registro en la colección 'registros' a partir de un perfil social
  Future<void> _crearRegistroDesdePerfilSocial(
    SocialProfile perfil,
    Map<String, dynamic> asignacionData,
  ) async {
    try {
      print('\n📝 === CREANDO REGISTRO DESDE PERFIL SOCIAL ===');
      print('📋 Perfil ID: ${perfil.id}');

      // ✅ OBTENER DATOS COMPLETOS DEL PERFIL SOCIAL
      final perfilDoc = await FirebaseFirestore.instance
          .collection('social_profiles')
          .doc(perfil.id)
          .get();

      if (!perfilDoc.exists) {
        throw Exception('El perfil social no existe');
      }

      final perfilData = perfilDoc.data() as Map<String, dynamic>;

      // ✅ MAPEO COMPLETO: perfil social → registro
      Map<String, dynamic> nuevoRegistro = {
        // Datos básicos
        'nombre': perfilData['name'] ?? '',
        'apellido': perfilData['lastName'] ?? '',
        'telefono': perfilData['phone'] ?? '',
        'direccion': perfilData['address'] ?? '',
        'barrio': perfilData['city'] ?? '',
        'edad': perfilData['age'] ?? 0,
        'sexo': perfilData['gender'] ?? '',

        // Datos adicionales
        'peticiones': perfilData['prayerRequest'] ?? '',
        'estadoFonovisita': perfilData['estadoFonovisita'] ?? '',
        'observaciones': perfilData['observaciones'] ?? '',
        'estadoProceso': perfilData['estadoProceso'] ?? '',
        'descripcionOcupacion': perfilData['descripcionOcupacion'] ?? '',

        // Datos de asignación
        ...asignacionData,

        // Metadatos
        'fecha': perfilData['createdAt'] != null
            ? (perfilData['createdAt'] is Timestamp
                ? perfilData['createdAt']
                : Timestamp.fromDate(DateTime.parse(perfilData['createdAt'])))
            : FieldValue.serverTimestamp(),
        'servicio': perfilData['socialNetwork'] ?? 'Red Social',
        'tipo': 'nuevo',
        'activo': true,
        'origenPerfilSocial': true,
        'perfilSocialId': perfil.id,

        // Campos opcionales del perfil social
        'estadoCivil': perfilData['estadoCivil'] ?? '',
        'nombrePareja': perfilData['nombrePareja'] ?? '',
        'ocupaciones': [],
        'referenciaInvitacion': '',
        'observaciones2': perfilData['observaciones2'] ?? '',
      };

      // ✅ CREAR NUEVO DOCUMENTO EN REGISTROS
      final nuevoRegistroRef = await FirebaseFirestore.instance
          .collection('registros')
          .add(nuevoRegistro);

      print('✅ Nuevo registro creado con ID: ${nuevoRegistroRef.id}');

      // ✅ ACTUALIZAR PERFIL SOCIAL CON LA REFERENCIA AL REGISTRO
      await FirebaseFirestore.instance
          .collection('social_profiles')
          .doc(perfil.id)
          .update({
        'registroAsociadoId': nuevoRegistroRef.id,
      });

      print(
          '✅ Perfil social actualizado con registroAsociadoId: ${nuevoRegistroRef.id}');
      print('🎉 === REGISTRO CREADO Y VINCULADO EXITOSAMENTE ===\n');
    } catch (e, stackTrace) {
      print('❌ Error al crear registro desde perfil social: $e');
      print('Stack trace: $stackTrace');
      throw e; // Re-lanzar para que el método padre lo maneje
    }
  }

  void _mostrarConfirmacionCambioSocial(
      BuildContext context, SocialProfile perfil) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Confirmar Cambio',
              style:
                  TextStyle(color: primaryTeal, fontWeight: FontWeight.bold)),
          content: Text(
              '¿Está seguro de cambiar la asignación de este perfil? La asignación actual será eliminada.',
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
                _cambiarAsignacionPerfilSocial(perfil);
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

  Future<void> _cambiarAsignacionPerfilSocial(SocialProfile perfil) async {
    try {
      setState(() => _isLoading = true);

      print('\n🔄 === INICIANDO CAMBIO DE ASIGNACIÓN ===');
      print('📋 Perfil ID: ${perfil.id}');

      // ✅ OBTENER DATOS DEL PERFIL SOCIAL
      final perfilDoc = await FirebaseFirestore.instance
          .collection('social_profiles')
          .doc(perfil.id)
          .get();

      if (!perfilDoc.exists) {
        throw Exception('El perfil social no existe');
      }

      final perfilData = perfilDoc.data() as Map<String, dynamic>;
      final registroAsociadoId = perfilData['registroAsociadoId'];

      print('📋 RegistroAsociadoId: $registroAsociadoId');

      // ✅ LIMPIAR ASIGNACIÓN EN AMBAS COLECCIONES
      // 1. Limpiar en perfil social
      await FirebaseFirestore.instance
          .collection('social_profiles')
          .doc(perfil.id)
          .update({
        'nombreTribu': null,
        'tribuAsignada': null,
        'ministerioAsignado': null,
        'coordinadorAsignado': null,
        'timoteoAsignado': null,
        'nombreTimoteo': null,
        'fechaAsignacion': null,
        'yaAsignado': false,
      });

      print('✅ Asignación limpiada en perfil social');

      // 2. Limpiar en registro asociado si existe
      if (registroAsociadoId != null &&
          registroAsociadoId.toString().trim().isNotEmpty) {
        final registroId = registroAsociadoId.toString().trim();

        try {
          final registroDoc = await FirebaseFirestore.instance
              .collection('registros')
              .doc(registroId)
              .get();

          if (registroDoc.exists) {
            // ✅ LIMPIAR SOLO CAMPOS DE ASIGNACIÓN EN EL REGISTRO
            Map<String, dynamic> camposAResetear = {
              'nombreTribu': null,
              'tribuAsignada': null,
              'ministerioAsignado': null,
              'coordinadorAsignado': null,
              'timoteoAsignado': null,
              'nombreTimoteo': null,
              'coordinadorNombre': null,
              'fechaAsignacion': null,
              'fechaAsignacionTribu': null,
              'fechaAsignacionCoordinador': null,
            };

            await FirebaseFirestore.instance
                .collection('registros')
                .doc(registroId)
                .update(camposAResetear);

            print('✅ Campos de asignación limpiados en el registro');
          } else {
            print('⚠️ El registro asociado no existe: $registroId');

            // Limpiar referencia inválida
            await FirebaseFirestore.instance
                .collection('social_profiles')
                .doc(perfil.id)
                .update({'registroAsociadoId': null});
          }
        } catch (e) {
          print('⚠️ Error al verificar/actualizar registro: $e');
        }
      } else {
        print('ℹ️ No hay registro asociado para limpiar');
      }

      print('🏁 === FIN CAMBIO DE ASIGNACIÓN ===\n');

      setState(() => _isLoading = false);

      // Llamar a la función de asignación nuevamente
      _asignarPerfilAtribu(perfil);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Asignación limpiada correctamente.',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e, stackTrace) {
      print('❌ Error al cambiar asignación: $e');
      print('Stack trace: $stackTrace');
      setState(() => _isLoading = false);

      String mensajeError = 'Error al cambiar asignación';
      if (e.toString().contains('not-found')) {
        mensajeError = 'No se encontró el registro asociado';
      } else if (e.toString().contains('permission-denied')) {
        mensajeError = 'No tienes permisos para realizar esta acción';
      } else {
        mensajeError = 'Error: ${e.toString()}';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensajeError),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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
    // Controllers
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
    final edadController =
        TextEditingController(text: registro.edad?.toString() ?? '0');
    final peticionesController =
        TextEditingController(text: registro.peticiones ?? '');
    final sexoController = TextEditingController(text: registro.sexo ?? '');

    String? estadoFonovisitaSeleccionado = registro.estadoFonovisita;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final screenWidth = constraints.maxWidth;
                final screenHeight = constraints.maxHeight;
                final isVerySmallScreen = screenWidth < 400;
                final isSmallScreen = screenWidth < 600;
                final isMediumScreen = screenWidth >= 600 && screenWidth < 900;

                // Responsive sizing
                final dialogWidth = isVerySmallScreen
                    ? screenWidth * 0.95
                    : isSmallScreen
                        ? screenWidth * 0.90
                        : isMediumScreen
                            ? screenWidth * 0.75
                            : screenWidth * 0.60;

                final titleFontSize = isVerySmallScreen
                    ? 18.0
                    : isSmallScreen
                        ? 20.0
                        : 24.0;
                final sectionFontSize = isVerySmallScreen
                    ? 14.0
                    : isSmallScreen
                        ? 15.0
                        : 16.0;
                final iconSize = isVerySmallScreen
                    ? 20.0
                    : isSmallScreen
                        ? 22.0
                        : 24.0;
                final padding = isVerySmallScreen
                    ? 12.0
                    : isSmallScreen
                        ? 16.0
                        : 20.0;

                return Dialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  elevation: 12,
                  insetPadding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 10 : 20,
                    vertical: isSmallScreen ? 10 : 24,
                  ),
                  child: Container(
                    width: dialogWidth,
                    constraints: BoxConstraints(
                      maxHeight: screenHeight * 0.95,
                      maxWidth: 700,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white,
                          primaryTeal.withOpacity(0.03),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: primaryTeal.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header fijo con degradado
                        Container(
                          padding: EdgeInsets.all(padding),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                primaryTeal,
                                primaryTeal.withOpacity(0.85)
                              ],
                            ),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(24),
                              topRight: Radius.circular(24),
                            ),
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
                                padding:
                                    EdgeInsets.all(isVerySmallScreen ? 8 : 10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.edit_rounded,
                                  color: Colors.white,
                                  size: iconSize,
                                ),
                              ),
                              SizedBox(width: isSmallScreen ? 10 : 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Editar Registro',
                                      style: TextStyle(
                                        fontSize: titleFontSize,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    if (!isVerySmallScreen)
                                      Text(
                                        'Actualiza la información del registro',
                                        style: TextStyle(
                                          fontSize: sectionFontSize - 3,
                                          color: Colors.white.withOpacity(0.9),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => Navigator.pop(context),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    child: Icon(
                                      Icons.close_rounded,
                                      color: Colors.white,
                                      size: iconSize,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Contenido scrollable
                        Expanded(
                          child: SingleChildScrollView(
                            child: Padding(
                              padding: EdgeInsets.all(padding),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Sección: Información Personal
                                  _buildEditSectionHeader(
                                    'Información Personal',
                                    Icons.person_rounded,
                                    primaryTeal,
                                    sectionFontSize,
                                    iconSize,
                                  ),
                                  const SizedBox(height: 12),

                                  _buildModernTextField(
                                    controller: nombreController,
                                    label: 'Nombre',
                                    icon: Icons.badge_rounded,
                                    isSmallScreen: isSmallScreen,
                                  ),
                                  const SizedBox(height: 12),

                                  _buildModernTextField(
                                    controller: apellidoController,
                                    label: 'Apellido',
                                    icon: Icons.person_outline_rounded,
                                    isSmallScreen: isSmallScreen,
                                  ),
                                  const SizedBox(height: 12),

                                  // Edad y Sexo en fila (si hay espacio)
                                  if (!isVerySmallScreen)
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildModernTextField(
                                            controller: edadController,
                                            label: 'Edad',
                                            icon: Icons.cake_rounded,
                                            keyboardType: TextInputType.number,
                                            isSmallScreen: isSmallScreen,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: _buildModernTextField(
                                            controller: sexoController,
                                            label: 'Sexo',
                                            icon: Icons.wc_rounded,
                                            isSmallScreen: isSmallScreen,
                                          ),
                                        ),
                                      ],
                                    )
                                  else ...[
                                    _buildModernTextField(
                                      controller: edadController,
                                      label: 'Edad',
                                      icon: Icons.cake_rounded,
                                      keyboardType: TextInputType.number,
                                      isSmallScreen: isSmallScreen,
                                    ),
                                    const SizedBox(height: 12),
                                    _buildModernTextField(
                                      controller: sexoController,
                                      label: 'Sexo',
                                      icon: Icons.wc_rounded,
                                      isSmallScreen: isSmallScreen,
                                    ),
                                  ],

                                  const SizedBox(height: 20),

                                  // Sección: Contacto
                                  _buildEditSectionHeader(
                                    'Contacto',
                                    Icons.contact_phone_rounded,
                                    secondaryOrange,
                                    sectionFontSize,
                                    iconSize,
                                  ),
                                  const SizedBox(height: 12),

                                  _buildModernTextField(
                                    controller: telefonoController,
                                    label: 'Teléfono',
                                    icon: Icons.phone_rounded,
                                    keyboardType: TextInputType.phone,
                                    isSmallScreen: isSmallScreen,
                                  ),
                                  const SizedBox(height: 12),

                                  _buildModernTextField(
                                    controller: direccionController,
                                    label: 'Dirección',
                                    icon: Icons.home_rounded,
                                    isSmallScreen: isSmallScreen,
                                  ),
                                  const SizedBox(height: 12),

                                  _buildModernTextField(
                                    controller: barrioController,
                                    label: 'Barrio',
                                    icon: Icons.location_city_rounded,
                                    isSmallScreen: isSmallScreen,
                                  ),

                                  const SizedBox(height: 20),

                                  // Sección: Información Adicional
                                  _buildEditSectionHeader(
                                    'Información Adicional',
                                    Icons.info_rounded,
                                    primaryTeal,
                                    sectionFontSize,
                                    iconSize,
                                  ),
                                  const SizedBox(height: 12),

                                  _buildModernTextField(
                                    controller: estadoCivilController,
                                    label: 'Estado Civil',
                                    icon: Icons.favorite_rounded,
                                    isSmallScreen: isSmallScreen,
                                  ),
                                  const SizedBox(height: 12),

                                  _buildModernTextField(
                                    controller: nombreParejaController,
                                    label: 'Nombre de Pareja',
                                    icon: Icons.people_rounded,
                                    isSmallScreen: isSmallScreen,
                                  ),
                                  const SizedBox(height: 12),

                                  _buildModernTextField(
                                    controller: ocupacionesController,
                                    label: 'Ocupaciones (separadas por coma)',
                                    icon: Icons.work_rounded,
                                    isSmallScreen: isSmallScreen,
                                  ),
                                  const SizedBox(height: 12),

                                  _buildModernTextField(
                                    controller: descripcionOcupacionController,
                                    label: 'Descripción Ocupación',
                                    icon: Icons.description_rounded,
                                    maxLines: 2,
                                    isSmallScreen: isSmallScreen,
                                  ),
                                  const SizedBox(height: 12),

                                  _buildModernTextField(
                                    controller: peticionesController,
                                    label: 'Peticiones',
                                    icon: Icons.favorite_border_rounded,
                                    maxLines: 2,
                                    isSmallScreen: isSmallScreen,
                                  ),
                                  const SizedBox(height: 12),

                                  _buildModernTextField(
                                    controller: referenciaInvitacionController,
                                    label: 'Referencia Invitación',
                                    icon: Icons.link_rounded,
                                    isSmallScreen: isSmallScreen,
                                  ),

                                  const SizedBox(height: 20),

                                  // Sección: Seguimiento
                                  _buildEditSectionHeader(
                                    'Seguimiento',
                                    Icons.track_changes_rounded,
                                    secondaryOrange,
                                    sectionFontSize,
                                    iconSize,
                                  ),
                                  const SizedBox(height: 12),

                                  // Dropdown Estado de Fonovisita
                                  _buildModernDropdown(
                                    value: estadoFonovisitaSeleccionado,
                                    label: 'Estado de Fonovisita',
                                    icon: Icons.call_rounded,
                                    items: [
                                      'Contactada',
                                      'No Contactada',
                                      '# Errado',
                                      'Apagado',
                                      'Buzón',
                                      'Número No Activado',
                                      '# Equivocado',
                                      'Difícil contacto'
                                    ],
                                    onChanged: (valor) {
                                      setDialogState(() {
                                        estadoFonovisitaSeleccionado = valor;
                                        estadoFonovisitaController.text =
                                            valor ?? '';
                                      });
                                    },
                                    isSmallScreen: isSmallScreen,
                                  ),

                                  const SizedBox(height: 12),

                                  _buildModernTextField(
                                    controller: observacionesController,
                                    label: 'Observaciones',
                                    icon: Icons.note_rounded,
                                    maxLines: 3,
                                    isSmallScreen: isSmallScreen,
                                  ),
                                  const SizedBox(height: 12),

                                  _buildModernTextField(
                                    controller: observaciones2Controller,
                                    label: 'Observaciones 2',
                                    icon: Icons.notes_rounded,
                                    maxLines: 3,
                                    isSmallScreen: isSmallScreen,
                                  ),

                                  const SizedBox(height: 30),

                                  // Botones al final del contenido scrollable
                                  Container(
                                    padding: EdgeInsets.all(padding),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: Colors.grey.shade200,
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          style: TextButton.styleFrom(
                                            padding: EdgeInsets.symmetric(
                                              horizontal:
                                                  isSmallScreen ? 16 : 24,
                                              vertical: isSmallScreen ? 12 : 14,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                          child: Text(
                                            'Cancelar',
                                            style: TextStyle(
                                              color: Colors.grey[700],
                                              fontSize: isSmallScreen ? 14 : 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        ElevatedButton.icon(
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
                                          icon: Icon(
                                            Icons.save_rounded,
                                            size: isSmallScreen ? 18 : 20,
                                          ),
                                          label: Text(
                                            'Guardar',
                                            style: TextStyle(
                                              fontSize: isSmallScreen ? 14 : 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: primaryTeal,
                                            foregroundColor: Colors.white,
                                            padding: EdgeInsets.symmetric(
                                              horizontal:
                                                  isSmallScreen ? 20 : 28,
                                              vertical: isSmallScreen ? 12 : 14,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            elevation: 4,
                                            shadowColor:
                                                primaryTeal.withOpacity(0.4),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Espacio final adicional
                                  SizedBox(height: isSmallScreen ? 40 : 20),
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

  Widget _buildEditSectionHeader(
    String title,
    IconData icon,
    Color color,
    double fontSize,
    double iconSize,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(
            color: color,
            width: 4,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: iconSize),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    required bool isSmallScreen,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: TextStyle(
          fontSize: isSmallScreen ? 14 : 15,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: primaryTeal,
            fontSize: isSmallScreen ? 13 : 14,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryTeal.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
            ),
            child: Icon(
              icon,
              color: primaryTeal,
              size: isSmallScreen ? 20 : 22,
            ),
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primaryTeal, width: 2),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 12 : 16,
            vertical: isSmallScreen ? 14 : 16,
          ),
        ),
      ),
    );
  }

  Widget _buildModernDropdown({
    required String? value,
    required String label,
    required IconData icon,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required bool isSmallScreen,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: primaryTeal,
            fontSize: isSmallScreen ? 13 : 14,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryTeal.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
            ),
            child: Icon(
              icon,
              color: primaryTeal,
              size: isSmallScreen ? 20 : 22,
            ),
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primaryTeal, width: 2),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 12 : 16,
            vertical: isSmallScreen ? 8 : 10,
          ),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            isDense: true,
            items: items.map((estado) {
              return DropdownMenuItem(
                value: estado,
                child: Text(
                  estado,
                  style: TextStyle(fontSize: isSmallScreen ? 14 : 15),
                ),
              );
            }).toList(),
            onChanged: onChanged,
            icon: Icon(
              Icons.arrow_drop_down_rounded,
              color: primaryTeal,
              size: isSmallScreen ? 24 : 28,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateSelector({
    required BuildContext context,
    required DateTime? selectedDate,
    required ValueChanged<DateTime?> onDateSelected,
    required bool isSmallScreen,
  }) {
    return InkWell(
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate:
              selectedDate ?? DateTime.now().subtract(Duration(days: 365 * 25)),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(
                  primary: primaryTeal,
                  onPrimary: Colors.white,
                  surface: Colors.white,
                  onSurface: Colors.black,
                ),
              ),
              child: child ?? const SizedBox.shrink(),
            );
          },
        );

        if (picked != null) {
          onDateSelected(picked);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(isSmallScreen ? 14 : 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selectedDate != null ? primaryTeal : Colors.grey.shade300,
            width: selectedDate != null ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryTeal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.calendar_today_rounded,
                color: primaryTeal,
                size: isSmallScreen ? 20 : 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fecha de Nacimiento',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 12 : 13,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    selectedDate != null
                        ? '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'
                        : 'Seleccionar fecha',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 14 : 15,
                      fontWeight: FontWeight.w500,
                      color: selectedDate != null
                          ? Colors.black87
                          : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: primaryTeal,
              size: isSmallScreen ? 24 : 28,
            ),
          ],
        ),
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

  Widget _buildExpandableDetailsTable(List<ChartData> data,
      bool isVerySmallScreen, StateSetter setDialogState) {
    if (data.isEmpty) return const SizedBox.shrink();

    final total = data.fold(0, (sum, item) => sum + item.value);

    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setLocalState) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          constraints: BoxConstraints(
            maxWidth: double.infinity,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _detailsTableExpanded
                  ? [Colors.white, primaryTeal.withOpacity(0.05)]
                  : [Colors.white, Colors.white],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: primaryTeal
                    .withOpacity(_detailsTableExpanded ? 0.15 : 0.08),
                blurRadius: _detailsTableExpanded ? 12 : 6,
                offset: Offset(0, _detailsTableExpanded ? 4 : 2),
              ),
            ],
            border: Border.all(
              color:
                  primaryTeal.withOpacity(_detailsTableExpanded ? 0.3 : 0.15),
              width: _detailsTableExpanded ? 2 : 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ✅ Header clickeable
              InkWell(
                onTap: () {
                  setLocalState(() {
                    _detailsTableExpanded = !_detailsTableExpanded;
                  });
                },
                borderRadius: BorderRadius.circular(15),
                child: Container(
                  padding: EdgeInsets.all(isVerySmallScreen ? 12 : 16),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: EdgeInsets.all(isVerySmallScreen ? 8 : 10),
                        decoration: BoxDecoration(
                          color: primaryTeal
                              .withOpacity(_detailsTableExpanded ? 0.2 : 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.table_chart_rounded,
                          color: primaryTeal,
                          size: isVerySmallScreen ? 20 : 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Detalle de Datos",
                              style: TextStyle(
                                fontSize: isVerySmallScreen ? 14 : 18,
                                fontWeight: FontWeight.bold,
                                color: primaryTeal,
                              ),
                            ),
                            Text(
                              "Total de registros: $total",
                              style: TextStyle(
                                fontSize: isVerySmallScreen ? 11 : 13,
                                color: primaryTeal.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      AnimatedRotation(
                        duration: const Duration(milliseconds: 300),
                        turns: _detailsTableExpanded ? 0.5 : 0,
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: primaryTeal,
                          size: isVerySmallScreen ? 24 : 28,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ✅ Tabla expandible con animación suave
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: _detailsTableExpanded
                    ? Container(
                        constraints: BoxConstraints(
                          maxHeight: isVerySmallScreen ? 250 : 300,
                        ),
                        width: double.infinity,
                        padding: EdgeInsets.all(isVerySmallScreen ? 12 : 16),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              headingRowColor: MaterialStateProperty.all(
                                primaryTeal.withOpacity(0.1),
                              ),
                              border: TableBorder.all(
                                color: primaryTeal.withOpacity(0.3),
                                width: 1.5,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              columns: [
                                DataColumn(
                                  label: Text(
                                    'Período',
                                    style: TextStyle(
                                      fontSize: isVerySmallScreen ? 11 : 14,
                                      fontWeight: FontWeight.bold,
                                      color: primaryTeal,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Cantidad',
                                    style: TextStyle(
                                      fontSize: isVerySmallScreen ? 11 : 14,
                                      fontWeight: FontWeight.bold,
                                      color: primaryTeal,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    '%',
                                    style: TextStyle(
                                      fontSize: isVerySmallScreen ? 11 : 14,
                                      fontWeight: FontWeight.bold,
                                      color: primaryTeal,
                                    ),
                                  ),
                                ),
                              ],
                              rows: [
                                ...data.map((item) {
                                  final percentage =
                                      ((item.value / total) * 100)
                                          .toStringAsFixed(1);
                                  return DataRow(
                                    cells: [
                                      DataCell(
                                        SizedBox(
                                          width: isVerySmallScreen ? 100 : 150,
                                          child: Text(
                                            item.label,
                                            style: TextStyle(
                                              fontSize:
                                                  isVerySmallScreen ? 10 : 13,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          item.value.toString(),
                                          style: TextStyle(
                                            fontSize:
                                                isVerySmallScreen ? 10 : 13,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          "$percentage%",
                                          style: TextStyle(
                                            fontSize:
                                                isVerySmallScreen ? 10 : 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                                // Fila de total
                                DataRow(
                                  color: MaterialStateProperty.all(
                                    secondaryOrange.withOpacity(0.15),
                                  ),
                                  cells: [
                                    DataCell(
                                      Text(
                                        'TOTAL',
                                        style: TextStyle(
                                          fontSize: isVerySmallScreen ? 11 : 14,
                                          fontWeight: FontWeight.bold,
                                          color: secondaryOrange,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        total.toString(),
                                        style: TextStyle(
                                          fontSize: isVerySmallScreen ? 11 : 14,
                                          fontWeight: FontWeight.bold,
                                          color: secondaryOrange,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        '100.0%',
                                        style: TextStyle(
                                          fontSize: isVerySmallScreen ? 11 : 14,
                                          fontWeight: FontWeight.bold,
                                          color: secondaryOrange,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
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
