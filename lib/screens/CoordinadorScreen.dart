import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'TimoteosScreen.dart';
import '../utils/email_service.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:async';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/gestures.dart';

// Color scheme based on the COCEP logo
const kPrimaryColor = Color(0xFF1B8C8C); // Turquesa
const kSecondaryColor = Color(0xFFFF4D2E); // Naranja/rojo
const kAccentColor = Color(0xFFFFB800); // Amarillo
const kBackgroundColor = Color(0xFFF5F7FA); // Gris muy claro para el fondo
const kTextLightColor = Color(0xFFF5F7FA); // For text on dark backgrounds
const kTextDarkColor = Color(0xFF2D3748); // For text on light backgrounds
const kCardColor = Colors.white; // Color for cards

class CoordinadorScreen extends StatefulWidget {
  final String coordinadorId;
  final String coordinadorNombre;

  const CoordinadorScreen({
    Key? key,
    required this.coordinadorId,
    required this.coordinadorNombre,
  }) : super(key: key);

  @override
  State<CoordinadorScreen> createState() => _CoordinadorScreenState();
}

class _CoordinadorScreenState extends State<CoordinadorScreen>
    with SingleTickerProviderStateMixin {
  // Variables para el manejo de sesión
  Timer? _inactivityTimer;
  static const Duration _inactivityDuration = Duration(minutes: 15);

  // Controller para las pestañas
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  // Métodos para manejo de sesión
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
                color: kSecondaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.logout_rounded,
                color: kSecondaryColor,
                size: 24,
              ),
            ),
            SizedBox(width: 12),
            Text(
              'Cerrar Sesión',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: kTextDarkColor,
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
          backgroundColor: kPrimaryColor,
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

  Future<Map<String, dynamic>> obtenerDatosTribu() async {
    var coordinadorSnapshot = await FirebaseFirestore.instance
        .collection('coordinadores')
        .doc(widget.coordinadorId)
        .get();

    if (!coordinadorSnapshot.exists)
      return {'tribuId': '', 'categoriaTribu': ''};

    var tribuId = coordinadorSnapshot.data()?['tribuId'] ?? '';

    if (tribuId.isEmpty) return {'tribuId': '', 'categoriaTribu': ''};

    var tribuSnapshot = await FirebaseFirestore.instance
        .collection('tribus')
        .doc(tribuId)
        .get();

    var categoriaTribu = tribuSnapshot.data()?['categoriaTribu'] ?? '';

    return {'tribuId': tribuId, 'categoriaTribu': categoriaTribu};
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: obtenerDatosTribu(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Scaffold(
            backgroundColor: kBackgroundColor,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TweenAnimationBuilder(
                    tween: Tween<double>(begin: 0, end: 1),
                    duration: Duration(seconds: 1),
                    builder: (context, double value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: kPrimaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.local_fire_department,
                            color: kAccentColor,
                            size: 70,
                          ),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 24),
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(kPrimaryColor),
                    strokeWidth: 3,
                  ),
                  SizedBox(height: 16),
                  Text(
                    "Cargando información...",
                    style: TextStyle(
                      color: kPrimaryColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        String tribuId = snapshot.data!['tribuId'];
        String categoriaTribu = snapshot.data!['categoriaTribu'];

        return DefaultTabController(
          length: 4,
          child: Scaffold(
            backgroundColor: kBackgroundColor,
            appBar: AppBar(
              elevation: 0,
              backgroundColor: kPrimaryColor,
              titleSpacing: 12,
              title: Row(
                children: [
                  // Logo mejorado con mejor visibilidad
                  Hero(
                    tag: 'coordinador_logo',
                    child: Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 6,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Container(
                        height: 36,
                        width: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(
                            color: kPrimaryColor.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/Cocep_.png',
                            height: 36,
                            width: 36,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                decoration: BoxDecoration(
                                  color: kAccentColor.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.local_fire_department,
                                  color: kPrimaryColor,
                                  size: 20,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  // Avatar del coordinador
                  /*Hero(
                    tag: 'coordinador_avatar',
                    child: Container(
                      padding: EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      /*child: CircleAvatar(
                        radius: 16,
                        backgroundColor: kAccentColor.withOpacity(0.2),
                        child: Icon(
                          Icons.person,
                          color: kPrimaryColor,
                          size: 18,
                        ),
                      ),*/
                    ),
                  ),*/
                  SizedBox(width: 12),
                  // Información del coordinador
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Coordinador',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          widget.coordinadorNombre,
                          style: TextStyle(
                            fontSize: MediaQuery.of(context).size.width < 400
                                ? 16
                                : 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                Container(
                  margin: EdgeInsets.only(right: 8),
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
                      color: Colors.white.withOpacity(0.4),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _confirmarCerrarSesion,
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.logout_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Salir',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                shadows: [
                                  Shadow(
                                    offset: Offset(0, 1),
                                    blurRadius: 2,
                                    color: Colors.black.withOpacity(0.3),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              bottom: PreferredSize(
                preferredSize: Size.fromHeight(kToolbarHeight + 15),
                child: Container(
                  decoration: BoxDecoration(
                    color: kPrimaryColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicatorWeight: 3,
                    indicator: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: kAccentColor,
                          width: 3,
                        ),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          kAccentColor.withOpacity(0.1),
                        ],
                      ),
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white60,
                    labelStyle: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                    tabs: [
                      Tab(
                        icon: Icon(Icons.people),
                        text: 'Timoteos',
                        iconMargin: EdgeInsets.only(bottom: 4),
                      ),
                      Tab(
                        icon: Icon(Icons.assignment_ind),
                        text: 'Asignados',
                        iconMargin: EdgeInsets.only(bottom: 4),
                      ),
                      Tab(
                        icon: Icon(Icons.warning_amber_rounded),
                        text: 'Alertas',
                        iconMargin: EdgeInsets.only(bottom: 4),
                      ),
                      Tab(
                        icon: Icon(Icons.calendar_today),
                        text: 'Asistencia',
                        iconMargin: EdgeInsets.only(bottom: 4),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            body: TabBarView(
              controller: _tabController,
              children: [
                CustomTabContent(
                  child: TimoteosTab(coordinadorId: widget.coordinadorId),
                  icon: Icons.people,
                  title: 'Timoteos',
                  description: 'Gestiona los timoteos a tu cargo',
                ),
                CustomTabContent(
                  child:
                      PersonasAsignadasTab(coordinadorId: widget.coordinadorId),
                  icon: Icons.assignment_ind,
                  title: 'Personas Asignadas',
                  description: 'Administra las personas asignadas a tu grupo',
                ),
                CustomTabContent(
                  child: AlertasTab(coordinadorId: widget.coordinadorId),
                  icon: Icons.warning_amber_rounded,
                  title: 'Alertas Pendientes',
                  description: 'Revisa las alertas que requieren tu atención',
                ),
                CustomTabContent(
                  child: AsistenciasCoordinadorTab(
                    tribuId: tribuId,
                    categoriaTribu: categoriaTribu,
                    coordinadorId: widget.coordinadorId,
                  ),
                  icon: Icons.calendar_today,
                  title: 'Registro de Asistencia',
                  description: 'Gestiona la asistencia de tu grupo',
                ),
              ],
            ),
            floatingActionButton: AnimatedBuilder(
              animation: _tabController,
              builder: (context, child) {
                if (_tabController.index == 3) {
                  return FloatingActionButton(
                    backgroundColor: kSecondaryColor,
                    child: Icon(Icons.add, color: Colors.white),
                    onPressed: () {
                      _resetInactivityTimer();
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        builder: (context) => buildActionSheet(
                          context,
                          () {
                            _resetInactivityTimer();
                            print('Registrar nuevo joven');
                          },
                        ),
                      );
                    },
                  );
                }
                return SizedBox.shrink();
              },
            ),
          ),
        );
      },
    );
  }

  Widget buildActionSheet(
      BuildContext context, VoidCallback onRegistrarNuevoJoven) {
    return Container(
      padding: EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Text(
            'Registrar Asistencia',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: kTextDarkColor,
            ),
          ),
          SizedBox(height: 24),
          _buildActionButton(
            context,
            'Registrar Asistencia',
            Icons.check_circle_outline,
            kSecondaryColor,
            () {
              _resetInactivityTimer();
              Navigator.pop(context);
              onRegistrarNuevoJoven();
            },
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: kTextDarkColor,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: color,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

// Wrapper widget to add consistent header to each tab
class CustomTabContent extends StatelessWidget {
  final Widget child;
  final IconData icon;
  final String title;
  final String description;

  const CustomTabContent({
    Key? key,
    required this.child,
    required this.icon,
    required this.title,
    required this.description,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kPrimaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: kPrimaryColor,
                  size: 24,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: kTextDarkColor,
                      ),
                    ),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Divider(),
        Expanded(child: child),
      ],
    );
  }
}

class AsistenciasCoordinadorTab extends StatefulWidget {
  final String tribuId;
  final String categoriaTribu;
  final String coordinadorId;

  const AsistenciasCoordinadorTab({
    Key? key,
    required this.tribuId,
    required this.categoriaTribu,
    required this.coordinadorId,
  }) : super(key: key);

  @override
  _AsistenciasCoordinadorTabState createState() =>
      _AsistenciasCoordinadorTabState();
}

class _AsistenciasCoordinadorTabState extends State<AsistenciasCoordinadorTab> {
  DateTime _selectedDate = DateTime.now();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool _isMassiveMode = false;
  bool _isProcessingMassive = false;
  DateTime _massiveSelectedDate = DateTime.now();
  bool _massiveDefaultAttendance = true;
  Map<String, bool> _selectedAttendances = {};
  List<DocumentSnapshot> _filteredRegistros = [];
  TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String obtenerNombreServicio(String categoriaTribu, DateTime fecha) {
    Intl.defaultLocale = 'es';
    String diaSemana = DateFormat('EEEE', 'es').format(fecha).toLowerCase();

    final Map<String, Map<String, String>> servicios = {
      "Ministerio de Damas": {
        "martes": "Servicio de Damas",
        "viernes": "Viernes de Poder",
        "domingo": "Servicio Dominical"
      },
      "Ministerio de Caballeros": {
        "jueves": "Servicio de Caballeros",
        "viernes": "Viernes de Poder",
        "sábado": "Servicio de Caballeros",
        "domingo": "Servicio Dominical"
      },
      "Ministerio Juvenil": {
        "viernes": "Viernes de Poder",
        "sábado": "Impacto Juvenil",
        "domingo": "Servicio Dominical"
      }
    };

    if (servicios.containsKey(categoriaTribu) &&
        servicios[categoriaTribu]!.containsKey(diaSemana)) {
      return servicios[categoriaTribu]![diaSemana]!;
    }

    return "Reunión General";
  }

  /// Bloquea asistencia si el registro tiene 3+ faltas y existe una alerta no revisada.
  /// Considera 'pendiente' o 'en_revision' (o 'procesada'==false) como NO revisada.
  Future<bool> _tieneBloqueoPorFaltas(
      String registroId, int faltasActuales) async {
    try {
      if (faltasActuales < 3) return false;

      final qs = await FirebaseFirestore.instance
          .collection('alertas')
          .where('registroId', isEqualTo: registroId)
          .where('tipo', isEqualTo: 'faltasConsecutivas')
          .where('procesada', isEqualTo: false)
          .limit(1)
          .get();

      if (qs.docs.isEmpty) {
        // Si no hay 'procesada:false', revisar por estado explícito
        final qs2 = await FirebaseFirestore.instance
            .collection('alertas')
            .where('registroId', isEqualTo: registroId)
            .where('tipo', isEqualTo: 'faltasConsecutivas')
            .where('estado', whereIn: ['pendiente', 'en_revision'])
            .limit(1)
            .get();
        return qs2.docs.isNotEmpty;
      }

      return true; // Hay una alerta pendiente/no procesada
    } catch (e) {
      // En caso de error, por seguridad no bloquear
      print('Error verificando bloqueo por faltas: $e');
      return false;
    }
  }

  Stream<QuerySnapshot> obtenerAsistenciasPorCoordinador(String coordinadorId) {
    return FirebaseFirestore.instance
        .collection('asistencias')
        .where('coordinadorId', isEqualTo: coordinadorId)
        .snapshots();
  }

  List<DocumentSnapshot> _filtrarRegistros(List<DocumentSnapshot> docs) {
    try {
      var filtered = docs.where((doc) {
        try {
          final data = doc.data();
          if (data is Map<String, dynamic>) {
            final categoria = data['categoria']?.toString() ?? '';
            final categoriaMatch = categoria == widget.categoriaTribu ||
                widget.categoriaTribu.isEmpty;

            if (!categoriaMatch) return false;

            if (_searchQuery.isEmpty) return true;

            final nombre = data['nombre']?.toString().toLowerCase() ?? '';
            final apellido = data['apellido']?.toString().toLowerCase() ?? '';
            final nombreCompleto = '$nombre $apellido';

            return nombreCompleto.contains(_searchQuery.toLowerCase());
          }
          return false;
        } catch (e) {
          print('Error filtrando documento individual: $e');
          return false;
        }
      }).toList();

      // Ordenar por nombre para consistencia
      filtered.sort((a, b) {
        try {
          final dataA = a.data() as Map<String, dynamic>?;
          final dataB = b.data() as Map<String, dynamic>?;

          final nombreA =
              '${dataA?['nombre'] ?? ''} ${dataA?['apellido'] ?? ''}'.trim();
          final nombreB =
              '${dataB?['nombre'] ?? ''} ${dataB?['apellido'] ?? ''}'.trim();

          return nombreA.compareTo(nombreB);
        } catch (e) {
          return 0;
        }
      });

      return filtered;
    } catch (e) {
      print('Error en _filtrarRegistros: $e');
      return [];
    }
  }

  String _determinarMinisterio(String nombreServicio) {
    if (nombreServicio.toLowerCase().contains("damas"))
      return "Ministerio de Damas";
    if (nombreServicio.toLowerCase().contains("caballeros"))
      return "Ministerio de Caballeros";
    if (nombreServicio.toLowerCase().contains("juvenil") ||
        nombreServicio.toLowerCase().contains("impacto"))
      return "Ministerio Juvenil";
    if (nombreServicio.toLowerCase().contains("familiar"))
      return "Ministerio Familiar";
    if (nombreServicio.toLowerCase().contains("poder"))
      return "Viernes de Poder";
    if (nombreServicio.toLowerCase().contains("dominical"))
      return "Servicio Dominical";
    return "Otro Ministerio";
  }

  Future<void> _registrarAsistencia(DocumentSnapshot registro) async {
    try {
      final data = registro.data() as Map<String, dynamic>?;
      if (data == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: Datos del registro no válidos')),
          );
        }
        return;
      }

      final nombre = data['nombre']?.toString() ?? '';
      final apellido = data['apellido']?.toString() ?? '';

      if (nombre.isEmpty && apellido.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: Nombre y apellido requeridos')),
          );
        }
        return;
      }

      // === BLOQUEO POR FALTAS NO REVISADAS ===
      final int faltasActuales =
          (data['faltasConsecutivas'] as num?)?.toInt() ?? 0;
      final bool bloqueo =
          await _tieneBloqueoPorFaltas(registro.id, faltasActuales);
      if (bloqueo) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Este registro tiene 3+ faltas y una alerta sin revisar. No se puede tomar asistencia hasta que sea revisada.',
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 4),
            ),
          );
        }
        return;
      }
      // === FIN BLOQUEO ===

      DateTime selectedDate = DateTime.now();
      bool asistio = true;
      bool isProcessing = false;

      // Obtener la categoría con validación
      final tribuId = data['tribuId']?.toString() ?? widget.tribuId;
      String categoriaTribu = data['categoria']?.toString() ??
          data['ministerioAsignado']?.toString() ??
          widget.categoriaTribu;

      // Verificar desde Firestore de forma segura
      if (tribuId.isNotEmpty && mounted) {
        try {
          final tribuDoc = await FirebaseFirestore.instance
              .collection('tribus')
              .doc(tribuId)
              .get();

          if (tribuDoc.exists && tribuDoc.data() != null) {
            final tribuData = tribuDoc.data() as Map<String, dynamic>;
            categoriaTribu =
                tribuData['categoria']?.toString() ?? categoriaTribu;
          }
        } catch (e) {
          print('Error al obtener tribu: $e');
          // Continúa con la categoría actual
        }
      }

      if (!mounted) return;

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => StatefulBuilder(
          builder: (builderContext, dialogSetState) {
            return WillPopScope(
              onWillPop: () async => !isProcessing,
              child: AlertDialog(
                title: Text('Registrar Asistencia'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Discípulo: $nombre $apellido',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton.icon(
                        icon: Icon(Icons.calendar_today),
                        label: Text('Seleccionar Fecha'),
                        onPressed: isProcessing
                            ? null
                            : () async {
                                try {
                                  final DateTime? pickedDate =
                                      await showDatePicker(
                                    context: builderContext,
                                    initialDate: selectedDate,
                                    firstDate: DateTime.now()
                                        .subtract(Duration(days: 30)),
                                    lastDate: DateTime.now(),
                                  );

                                  if (pickedDate != null &&
                                      pickedDate != selectedDate) {
                                    dialogSetState(() {
                                      selectedDate = pickedDate;
                                    });
                                  }
                                } catch (e) {
                                  print('Error al seleccionar fecha: $e');
                                }
                              },
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Fecha seleccionada: ${DateFormat('dd/MM/yyyy').format(selectedDate)}',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      SizedBox(height: 16),
                      ListTile(
                        title: Text('¿Asistió al servicio?'),
                        subtitle: Text(obtenerNombreServicio(
                            categoriaTribu, selectedDate)),
                        trailing: Switch(
                          value: asistio,
                          onChanged: isProcessing
                              ? null
                              : (value) {
                                  dialogSetState(() {
                                    asistio = value;
                                  });
                                },
                        ),
                      ),
                      if (isProcessing) ...[
                        SizedBox(height: 16),
                        CircularProgressIndicator(),
                        SizedBox(height: 8),
                        Text('Procesando...'),
                      ],
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: isProcessing
                        ? null
                        : () => Navigator.of(dialogContext).pop(),
                    child: Text('Cancelar'),
                  ),
                  ElevatedButton(
                    onPressed: isProcessing
                        ? null
                        : () async {
                            dialogSetState(() {
                              isProcessing = true;
                            });

                            try {
                              // Verificar si ya existe una asistencia
                              final startOfDay = DateTime(selectedDate.year,
                                  selectedDate.month, selectedDate.day);
                              final endOfDay =
                                  startOfDay.add(Duration(days: 1));

                              final yaRegistrada = await FirebaseFirestore
                                  .instance
                                  .collection('asistencias')
                                  .where('jovenId', isEqualTo: registro.id)
                                  .where('fecha',
                                      isGreaterThanOrEqualTo:
                                          Timestamp.fromDate(startOfDay))
                                  .where('fecha',
                                      isLessThan: Timestamp.fromDate(endOfDay))
                                  .limit(1)
                                  .get();

                              if (yaRegistrada.docs.isNotEmpty) {
                                Navigator.of(dialogContext).pop();
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            'Ya se ha registrado asistencia para esta persona en esta fecha')),
                                  );
                                }
                                return;
                              }

                              final String nombreServicio =
                                  obtenerNombreServicio(
                                      categoriaTribu, selectedDate);

                              // Registrar la asistencia
                              await FirebaseFirestore.instance
                                  .collection('asistencias')
                                  .add({
                                'jovenId': registro.id,
                                'nombre': nombre,
                                'apellido': apellido,
                                'nombreCompleto': '$nombre $apellido',
                                'tribuId': tribuId,
                                'categoriaTribu': categoriaTribu,
                                'coordinadorId': widget.coordinadorId,
                                'fecha': Timestamp.fromDate(selectedDate),
                                'nombreServicio': nombreServicio,
                                'asistio': asistio,
                                'diaSemana': DateFormat('EEEE', 'es')
                                    .format(selectedDate),
                              });

                              // Actualizar faltas
                              final int faltasAnteriores =
                                  (data['faltasConsecutivas'] as num?)
                                          ?.toInt() ??
                                      0;
                              final int nuevasFaltas =
                                  asistio ? 0 : faltasAnteriores + 1;

                              // Obtener el timoteoId del joven si está asignado
                              String nombreTimoteo = 'No disponible';
                              String? timoteoId = data['timoteoAsignado'];

                              if (timoteoId != null && timoteoId.isNotEmpty) {
                                final timoteoDoc = await FirebaseFirestore
                                    .instance
                                    .collection('timoteos')
                                    .doc(timoteoId)
                                    .get();

                                if (timoteoDoc.exists) {
                                  final tData = timoteoDoc.data();
                                  final nombreT = tData?['nombre'] ?? '';
                                  final apellidoT = tData?['apellido'] ?? '';
                                  nombreTimoteo = '$nombreT $apellidoT'.trim();
                                }
                              }

                              await registro.reference.update({
                                'ultimaAsistencia':
                                    Timestamp.fromDate(selectedDate),
                                'faltasConsecutivas': nuevasFaltas,
                              });

                              // Generar alerta si es necesario
                              if (!asistio && nuevasFaltas >= 4) {
                                final alertasExistente = await FirebaseFirestore
                                    .instance
                                    .collection('alertas')
                                    .where('registroId', isEqualTo: registro.id)
                                    .where('tipo',
                                        isEqualTo: 'faltasConsecutivas')
                                    .where('procesada', isEqualTo: false)
                                    .limit(1)
                                    .get();

                                if (alertasExistente.docs.isEmpty) {
                                  // ✅ NUEVO: Obtener el token del coordinador específico
                                  String? coordinadorToken;
                                  try {
                                    final coordinadorDoc =
                                        await FirebaseFirestore.instance
                                            .collection('coordinadores')
                                            .doc(widget.coordinadorId)
                                            .get();

                                    if (coordinadorDoc.exists) {
                                      final coordData = coordinadorDoc.data()
                                          as Map<String, dynamic>?;
                                      coordinadorToken = coordData?['fcmToken'];
                                    }
                                  } catch (e) {
                                    print(
                                        'Error obteniendo token del coordinador: $e');
                                  }

                                  // Crear la alerta con el token del coordinador
                                  await FirebaseFirestore.instance
                                      .collection('alertas')
                                      .add({
                                    'tipo': 'faltasConsecutivas',
                                    'registroId': registro.id,
                                    'coordinadorId': widget.coordinadorId,
                                    'coordinadorToken':
                                        coordinadorToken, // ✅ NUEVO: Token específico
                                    'timoteoId': timoteoId ?? 'No asignado',
                                    'nombreJoven': '$nombre $apellido',
                                    'nombreTimoteo': nombreTimoteo,
                                    'cantidadFaltas': nuevasFaltas,
                                    'fecha': Timestamp.now(),
                                    'estado': 'pendiente',
                                    'procesada': false,
                                    'visible': false,
                                    'notificacionEnviada':
                                        false, // ✅ NUEVO: Para controlar envío
                                  });

                                  // ✅ NUEVO: Aquí llamarías a tu Cloud Function o servicio de backend
                                  // para enviar la notificación SOLO a este coordinador específico
                                  print(
                                      '🔔 Alerta creada para coordinador: ${widget.coordinadorId}');
                                  print(
                                      '🔔 Token del coordinador: $coordinadorToken');
                                }
                              }

                              Navigator.of(dialogContext).pop();

                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          'Asistencia registrada correctamente')),
                                );
                              }
                            } catch (e) {
                              print('Error al registrar asistencia: $e');
                              Navigator.of(dialogContext).pop();

                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          'Error al registrar asistencia: ${e.toString()}')),
                                );
                              }
                            }
                          },
                    child: Text('Guardar'),
                  ),
                ],
              ),
            );
          },
        ),
      );
    } catch (e) {
      print('Error general en _registrarAsistencia: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error inesperado: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _procesarAsistenciaMasiva() async {
    if (!mounted || _isProcessingMassive || _selectedAttendances.isEmpty)
      return;

    setState(() {
      _isProcessingMassive = true;
    });

    int procesados = 0;
    int errores = 0;
    int yaRegistrados = 0;
    int totalProcesos = _selectedAttendances.length;

    // Variables para el diálogo
    bool dialogMounted = true;
    late StateSetter dialogSetState;

    try {
      final startOfDay = DateTime(_massiveSelectedDate.year,
          _massiveSelectedDate.month, _massiveSelectedDate.day);
      final endOfDay = startOfDay.add(Duration(days: 1));

      // Mostrar diálogo de progreso con mejor control
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              dialogSetState = setDialogState;
              return WillPopScope(
                onWillPop: () async => false,
                child: AlertDialog(
                  title: Row(
                    children: [
                      Icon(Icons.checklist, color: Color(0xFF147B7C)),
                      SizedBox(width: 8),
                      Text(
                        'Procesando Lista de Asistencia',
                        style: TextStyle(fontSize: 18),
                      ),
                    ],
                  ),
                  content: Container(
                    constraints: BoxConstraints(minWidth: 300),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Color(0xFF147B7C)),
                        ),
                        SizedBox(height: 20),
                        Text(
                          'Procesando: ${procesados + errores + yaRegistrados} de $totalProcesos',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 12),
                        if (procesados > 0)
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle,
                                    color: Colors.green, size: 16),
                                SizedBox(width: 4),
                                Text('Registrados: $procesados',
                                    style: TextStyle(color: Colors.green)),
                              ],
                            ),
                          ),
                        if (yaRegistrados > 0)
                          Container(
                            margin: EdgeInsets.only(top: 4),
                            padding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.warning,
                                    color: Colors.orange, size: 16),
                                SizedBox(width: 4),
                                Text('Ya existían: $yaRegistrados',
                                    style: TextStyle(color: Colors.orange)),
                              ],
                            ),
                          ),
                        if (errores > 0)
                          Container(
                            margin: EdgeInsets.only(top: 4),
                            padding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.error, color: Colors.red, size: 16),
                                SizedBox(width: 4),
                                Text('Errores: $errores',
                                    style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      );

      // Función para actualizar el diálogo de forma segura
      void actualizarDialogo() {
        if (dialogMounted) {
          try {
            dialogSetState(() {
              // Las variables se actualizan automáticamente
            });
          } catch (e) {
            print('Error actualizando diálogo: $e');
            dialogMounted = false;
          }
        }
      }

      // Procesar cada asistencia seleccionada
      List<MapEntry<String, bool>> entries =
          _selectedAttendances.entries.toList();

      for (int i = 0; i < entries.length; i++) {
        if (!mounted || !dialogMounted) break;

        final entry = entries[i];

        try {
          // Buscar el registro correspondiente
          DocumentSnapshot? registro;
          try {
            registro = _filteredRegistros.firstWhere(
              (doc) => doc.id == entry.key,
            );
          } catch (e) {
            print('Registro no encontrado: ${entry.key}');
            errores++;
            actualizarDialogo();
            continue;
          }

          final data = registro.data() as Map<String, dynamic>?;
          if (data == null) {
            errores++;
            actualizarDialogo();
            continue;
          }

          // === BLOQUEO POR FALTAS NO REVISADAS (MODO MASIVO) ===
          final int faltasActuales =
              (data['faltasConsecutivas'] as num?)?.toInt() ?? 0;
          final bool bloqueo =
              await _tieneBloqueoPorFaltas(registro.id, faltasActuales);
          if (bloqueo) {
            // Lo tratamos como "ya registrado / omitido" para no romper el conteo
            yaRegistrados++;
            actualizarDialogo();
            continue;
          }
          // === FIN BLOQUEO ===

          // Verificar si ya existe una asistencia para esta fecha
          final yaRegistrada = await FirebaseFirestore.instance
              .collection('asistencias')
              .where('jovenId', isEqualTo: registro.id)
              .where('fecha',
                  isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
              .where('fecha', isLessThan: Timestamp.fromDate(endOfDay))
              .limit(1)
              .get();

          if (yaRegistrada.docs.isNotEmpty) {
            yaRegistrados++;
            actualizarDialogo();
            continue;
          }

          final nombre = data['nombre']?.toString() ?? '';
          final apellido = data['apellido']?.toString() ?? '';
          final tribuId = data['tribuId']?.toString() ?? widget.tribuId;
          String categoriaTribu = data['categoria']?.toString() ??
              data['ministerioAsignado']?.toString() ??
              widget.categoriaTribu;

          // Verificar categoría desde Firestore si es necesario
          if (tribuId.isNotEmpty) {
            try {
              final tribuDoc = await FirebaseFirestore.instance
                  .collection('tribus')
                  .doc(tribuId)
                  .get();

              if (tribuDoc.exists && tribuDoc.data() != null) {
                final tribuData = tribuDoc.data() as Map<String, dynamic>;
                categoriaTribu =
                    tribuData['categoria']?.toString() ?? categoriaTribu;
              }
            } catch (e) {
              print('Error al obtener tribu: $e');
            }
          }

          final String nombreServicio =
              obtenerNombreServicio(categoriaTribu, _massiveSelectedDate);
          final bool asistio = entry.value;

          // Registrar asistencia
          await FirebaseFirestore.instance.collection('asistencias').add({
            'jovenId': registro.id,
            'nombre': nombre,
            'apellido': apellido,
            'nombreCompleto': '$nombre $apellido',
            'tribuId': tribuId,
            'categoriaTribu': categoriaTribu,
            'coordinadorId': widget.coordinadorId,
            'fecha': Timestamp.fromDate(_massiveSelectedDate),
            'nombreServicio': nombreServicio,
            'asistio': asistio,
            'diaSemana': DateFormat('EEEE', 'es').format(_massiveSelectedDate),
          });

          // Actualizar faltas
          final int faltasAnteriores =
              (data['faltasConsecutivas'] as num?)?.toInt() ?? 0;
          final int nuevasFaltas = asistio ? 0 : faltasAnteriores + 1;

          await registro.reference.update({
            'ultimaAsistencia': Timestamp.fromDate(_massiveSelectedDate),
            'faltasConsecutivas': nuevasFaltas,
          });

          // Generar alerta si es necesario
          if (!asistio && nuevasFaltas >= 4) {
            String nombreTimoteo = 'No disponible';
            String? timoteoId = data['timoteoAsignado'];

            if (timoteoId != null && timoteoId.isNotEmpty) {
              try {
                final timoteoDoc = await FirebaseFirestore.instance
                    .collection('timoteos')
                    .doc(timoteoId)
                    .get();

                if (timoteoDoc.exists) {
                  final tData = timoteoDoc.data();
                  final nombreT = tData?['nombre'] ?? '';
                  final apellidoT = tData?['apellido'] ?? '';
                  nombreTimoteo = '$nombreT $apellidoT'.trim();
                }
              } catch (e) {
                print('Error obteniendo timoteo: $e');
              }
            }

            // Verificar si ya existe una alerta para este registro
            final alertasExistente = await FirebaseFirestore.instance
                .collection('alertas')
                .where('registroId', isEqualTo: registro.id)
                .where('tipo', isEqualTo: 'faltasConsecutivas')
                .where('procesada', isEqualTo: false)
                .limit(1)
                .get();

            if (alertasExistente.docs.isEmpty) {
              // ✅ NUEVO: Obtener el token del coordinador específico
              String? coordinadorToken;
              try {
                final coordinadorDoc = await FirebaseFirestore.instance
                    .collection('coordinadores')
                    .doc(widget.coordinadorId)
                    .get();

                if (coordinadorDoc.exists) {
                  final coordData =
                      coordinadorDoc.data() as Map<String, dynamic>?;
                  coordinadorToken = coordData?['fcmToken'];
                }
              } catch (e) {
                print('Error obteniendo token del coordinador: $e');
              }

              await FirebaseFirestore.instance.collection('alertas').add({
                'tipo': 'faltasConsecutivas',
                'registroId': registro.id,
                'coordinadorId': widget.coordinadorId,
                'coordinadorToken': coordinadorToken, // ✅ NUEVO
                'timoteoId': timoteoId ?? 'No asignado',
                'nombreJoven': '$nombre $apellido',
                'nombreTimoteo': nombreTimoteo,
                'cantidadFaltas': nuevasFaltas,
                'fecha': Timestamp.now(),
                'estado': 'pendiente',
                'procesada': false,
                'visible': false,
                'notificacionEnviada': false, // ✅ NUEVO
              });

              print(
                  '🔔 Alerta masiva creada para coordinador: ${widget.coordinadorId}');
            }
          }

          procesados++;
          actualizarDialogo();
        } catch (e) {
          print('Error procesando asistencia individual: $e');
          errores++;
          actualizarDialogo();
        }

        // Pequeña pausa cada 3 registros para no saturar Firestore
        if (i % 3 == 0) {
          await Future.delayed(Duration(milliseconds: 50));
        }
      }
    } catch (e) {
      print('Error crítico en procesamiento masivo: $e');
      errores++;
    } finally {
      // Marcar diálogo como no montado
      dialogMounted = false;

      // Cerrar diálogo de progreso de forma segura
      if (mounted) {
        try {
          Navigator.of(context, rootNavigator: true).pop();
        } catch (e) {
          print('Error cerrando diálogo: $e');
        }

        // Pequeña pausa antes de actualizar el estado
        await Future.delayed(Duration(milliseconds: 100));

        // Limpiar selecciones y salir del modo masivo
        if (mounted) {
          setState(() {
            _selectedAttendances.clear();
            _isMassiveMode = false;
            _isProcessingMassive = false;
          });

          // Mostrar resultado final
          String mensaje;
          Color color;

          if (errores == 0 && yaRegistrados == 0) {
            mensaje =
                '✓ ¡Perfecto! Se registraron $procesados asistencias correctamente';
            color = Color(0xFF147B7C);
          } else if (errores == 0) {
            mensaje =
                '✓ Completado: $procesados registrados, $yaRegistrados ya existían';
            color = Colors.orange;
          } else {
            mensaje =
                'Completado con advertencias: $procesados registrados, $yaRegistrados ya existían, $errores errores';
            color = Colors.red;
          }

          try {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(mensaje),
                backgroundColor: color,
                duration: Duration(seconds: 5),
                action: SnackBarAction(
                  label: 'OK',
                  textColor: Colors.white,
                  onPressed: () {},
                ),
              ),
            );
          } catch (e) {
            print('Error mostrando SnackBar: $e');
          }
        }
      }
    }
  }

  Widget _buildAsistenciasCalendario(DocumentSnapshot registro) {
    final data = registro.data() as Map<String, dynamic>?;

    if (data == null) {
      return Center(
        child: Text('Error: No se pueden cargar los datos del registro'),
      );
    }

    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('asistencias')
          .where('jovenId', isEqualTo: registro.id)
          .get()
          .timeout(Duration(seconds: 10)),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 8),
                Text('Cargando calendario...'),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          print('Error al cargar asistencias: ${snapshot.error}');
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red),
                SizedBox(height: 8),
                Text(
                  'Error al cargar asistencias',
                  style: TextStyle(color: Colors.red),
                ),
                SizedBox(height: 4),
                Text(
                  'Toca para reintentar',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        final asistencias = snapshot.data?.docs ?? [];
        final Map<DateTime, bool> asistenciaMap = {};

        // Procesar asistencias de forma segura
        for (var asistenciaDoc in asistencias) {
          try {
            final asistenciaData = asistenciaDoc.data();
            if (asistenciaData is Map<String, dynamic>) {
              final fechaField = asistenciaData['fecha'];
              if (fechaField is Timestamp) {
                final fecha = fechaField.toDate();
                final fechaSinHora =
                    DateTime(fecha.year, fecha.month, fecha.day);
                final asistio = asistenciaData['asistio'] is bool
                    ? asistenciaData['asistio'] as bool
                    : false;
                asistenciaMap[fechaSinHora] = asistio;
              }
            }
          } catch (e) {
            print('Error procesando asistencia: $e');
            continue;
          }
        }

        return SafeArea(
          child: Column(
            children: [
              Text(
                'Calendario de Asistencias',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF147B7C),
                ),
              ),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: TableCalendar(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: DateTime.now(),
                  calendarFormat: CalendarFormat.month,
                  startingDayOfWeek: StartingDayOfWeek.monday,
                  locale: 'es_ES',
                  availableCalendarFormats: const {
                    CalendarFormat.month: 'Mes',
                    CalendarFormat.week: 'Semana',
                  },
                  headerStyle: HeaderStyle(
                    titleCentered: true,
                    formatButtonVisible: true,
                    formatButtonDecoration: BoxDecoration(
                      color: Color(0xFF147B7C),
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    formatButtonTextStyle: TextStyle(color: Colors.white),
                    titleTextStyle: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  calendarStyle: CalendarStyle(
                    weekendTextStyle: TextStyle(color: Colors.red),
                    outsideDaysVisible: false,
                  ),
                  calendarBuilders: CalendarBuilders(
                    markerBuilder: (context, date, events) {
                      try {
                        final fechaSinHora =
                            DateTime(date.year, date.month, date.day);
                        if (asistenciaMap.containsKey(fechaSinHora)) {
                          final asistio = asistenciaMap[fechaSinHora] ?? false;
                          return Positioned(
                            bottom: 1,
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: asistio
                                    ? Color(0xFF147B7C)
                                    : Color(0xFFFF4B2B),
                              ),
                              width: 8,
                              height: 8,
                            ),
                          );
                        }
                      } catch (e) {
                        print('Error en markerBuilder: $e');
                      }
                      return null;
                    },
                  ),
                ),
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF147B7C),
                        ),
                      ),
                      SizedBox(width: 4),
                      Text('Asistió'),
                    ],
                  ),
                  SizedBox(width: 24),
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFFF4B2B),
                        ),
                      ),
                      SizedBox(width: 4),
                      Text('No asistió'),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMassiveAttendanceMode() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF147B7C).withOpacity(0.1),
            Color(0xFF147B7C).withOpacity(0.05)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFF147B7C), width: 2),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(0xFF147B7C),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.checklist, color: Colors.white, size: 24),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lista de Asistencia Grupal',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF147B7C),
                        ),
                      ),
                      Text(
                        'Toma asistencia de múltiples personas a la vez',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.red, size: 28),
                  onPressed: _isProcessingMassive
                      ? null
                      : () {
                          setState(() {
                            _isMassiveMode = false;
                            _selectedAttendances.clear();
                          });
                        },
                ),
              ],
            ),

            Divider(
                height: 24,
                thickness: 1,
                color: Color(0xFF147B7C).withOpacity(0.3)),

            // Selector de fecha mejorado
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Color(0xFF147B7C).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.event, color: Color(0xFF147B7C)),
                  SizedBox(width: 8),
                  Text(
                    'Fecha del servicio:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF147B7C),
                    ),
                  ),
                  Spacer(),
                  ElevatedButton.icon(
                    icon: Icon(Icons.calendar_today, size: 18),
                    label: Text(
                        DateFormat('dd/MM/yyyy').format(_massiveSelectedDate)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF147B7C),
                      foregroundColor: Colors.white,
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    onPressed: _isProcessingMassive
                        ? null
                        : () async {
                            final DateTime? pickedDate = await showDatePicker(
                              context: context,
                              initialDate: _massiveSelectedDate,
                              firstDate:
                                  DateTime.now().subtract(Duration(days: 30)),
                              lastDate: DateTime.now(),
                              helpText: 'Seleccionar fecha del servicio',
                              confirmText: 'CONFIRMAR',
                              cancelText: 'CANCELAR',
                            );

                            if (pickedDate != null &&
                                pickedDate != _massiveSelectedDate) {
                              setState(() {
                                _massiveSelectedDate = pickedDate;
                                _selectedAttendances.clear();
                              });
                            }
                          },
                  ),
                ],
              ),
            ),

            SizedBox(height: 16),

            // Controles masivos mejorados
            Text(
              'Acciones rápidas:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF147B7C),
                fontSize: 16,
              ),
            ),
            SizedBox(height: 8),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ElevatedButton.icon(
                    icon: Icon(Icons.check_circle, size: 18),
                    label: Text('Todos Presentes'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onPressed: _isProcessingMassive
                        ? null
                        : () {
                            setState(() {
                              for (var registro in _filteredRegistros) {
                                _selectedAttendances[registro.id] = true;
                              }
                            });
                          },
                  ),
                  SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: Icon(Icons.cancel, size: 18),
                    label: Text('Todos Ausentes'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onPressed: _isProcessingMassive
                        ? null
                        : () {
                            setState(() {
                              for (var registro in _filteredRegistros) {
                                _selectedAttendances[registro.id] = false;
                              }
                            });
                          },
                  ),
                  SizedBox(width: 8),
                  OutlinedButton.icon(
                    icon: Icon(Icons.clear_all, size: 18),
                    label: Text('Limpiar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey[700],
                      side: BorderSide(color: Colors.grey),
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onPressed: _isProcessingMassive
                        ? null
                        : () {
                            setState(() {
                              _selectedAttendances.clear();
                            });
                          },
                  ),
                ],
              ),
            ),

            SizedBox(height: 16),

            // Contador y botón de procesamiento mejorado
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(0xFF147B7C).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.people, color: Color(0xFF147B7C)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Personas seleccionadas: ${_selectedAttendances.length}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF147B7C),
                              ),
                            ),
                            if (_selectedAttendances.isNotEmpty) ...[
                              SizedBox(height: 4),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Text(
                                  'Presentes: ${_selectedAttendances.values.where((v) => v == true).length} | '
                                  'Ausentes: ${_selectedAttendances.values.where((v) => v == false).length}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: _isProcessingMassive
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Icon(Icons.save_alt, size: 18),
                      label: Text(_isProcessingMassive
                          ? 'Guardando...'
                          : 'Guardar Lista de Asistencia'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF147B7C),
                        foregroundColor: Colors.white,
                        padding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      ),
                      onPressed:
                          (_isProcessingMassive || _selectedAttendances.isEmpty)
                              ? null
                              : _procesarAsistenciaMasiva,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Buscar por nombre...',
          prefixIcon: Icon(Icons.search, color: Color(0xFF147B7C)),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide(color: Color(0xFF147B7C)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide(color: Color(0xFF147B7C), width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

// 7. MÉTODO BUILD COMPLETO MEJORADO
// Reemplazar completamente el método build existente con este:

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header fijo - NO se mueve con el scroll
          Container(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              children: [
                Text(
                  'Registro de Asistencias',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF147B7C),
                  ),
                ),
                Spacer(),
                // Botón para activar modo masivo
                ElevatedButton.icon(
                  icon: Icon(_isMassiveMode ? Icons.person : Icons.checklist),
                  label: Text(
                      _isMassiveMode ? 'Registro Individual' : 'Lista Grupal'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _isMassiveMode ? Colors.orange : Color(0xFF147B7C),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  onPressed: _isProcessingMassive
                      ? null
                      : () {
                          setState(() {
                            _isMassiveMode = !_isMassiveMode;
                            _selectedAttendances.clear();
                          });
                        },
                ),
              ],
            ),
          ),

          // Barra de búsqueda fija - NO se mueve con el scroll
          Container(
            color: Colors.white,
            child: _buildSearchBar(),
          ),

          // Contenido con scroll - TODO lo demás puede hacer scroll
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('registros')
                  .where('coordinadorAsignado', isEqualTo: widget.coordinadorId)
                  .snapshots()
                  .handleError((error) {
                print('Error en stream: $error');
                return Stream.empty();
              }),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  print('StreamBuilder error: ${snapshot.error}');
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.red),
                        SizedBox(height: 16),
                        Text(
                          'Error al cargar datos',
                          style: TextStyle(fontSize: 18, color: Colors.red),
                        ),
                        SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            if (mounted) {
                              setState(() {});
                            }
                          },
                          child: Text('Reintentar'),
                        ),
                      ],
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Color(0xFF147B7C)),
                        ),
                        SizedBox(height: 16),
                        Text('Cargando discípulos...'),
                      ],
                    ),
                  );
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 72,
                          color: Color(0xFF147B7C).withOpacity(0.5),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No hay discípulos asignados',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Los discípulos deben ser asignados desde "Personas Asignadas"',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                // Filtrar documentos
                _filteredRegistros = _filtrarRegistros(docs);

                if (_filteredRegistros.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _searchQuery.isNotEmpty
                              ? Icons.search_off
                              : Icons.people_outline,
                          size: 72,
                          color: Color(0xFF147B7C).withOpacity(0.5),
                        ),
                        SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'No se encontraron resultados para "$_searchQuery"'
                              : 'No hay discípulos para esta categoría',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (_searchQuery.isNotEmpty) ...[
                          SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                              });
                            },
                            child: Text('Limpiar búsqueda'),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                // AQUÍ ESTÁ EL CAMBIO PRINCIPAL: SingleChildScrollView que envuelve todo el contenido
                return SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  physics:
                      AlwaysScrollableScrollPhysics(), // Permite scroll siempre
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Modo masivo (si está activado) - DENTRO del scroll
                      if (_isMassiveMode) ...[
                        _buildMassiveAttendanceMode(),
                        SizedBox(height: 16),
                        // Separador visual
                        Container(
                          width: double.infinity,
                          height: 1,
                          color: Color(0xFF147B7C).withOpacity(0.3),
                        ),
                        SizedBox(height: 16),
                      ],

                      // Lista de discípulos - DENTRO del scroll
                      ...List.generate(_filteredRegistros.length, (index) {
                        try {
                          final registro = _filteredRegistros[index];
                          final data = registro.data();

                          if (data is! Map<String, dynamic>) {
                            return SizedBox.shrink();
                          }

                          final dataMap = data as Map<String, dynamic>;
                          final nombre = dataMap['nombre']?.toString() ?? '';
                          final apellido =
                              dataMap['apellido']?.toString() ?? '';
                          final faltas = (dataMap['faltasConsecutivas'] as num?)
                                  ?.toInt() ??
                              0;

                          if (nombre.isEmpty && apellido.isEmpty) {
                            return SizedBox.shrink();
                          }

                          Color cardColor = Colors.white;
                          if (faltas >= 3) {
                            cardColor = Color(0xFFFF4B2B).withOpacity(0.1);
                          }

                          // En modo masivo, mostrar versión simplificada
                          if (_isMassiveMode) {
                            final isSelected =
                                _selectedAttendances.containsKey(registro.id);
                            final attendanceValue =
                                _selectedAttendances[registro.id];

                            return Container(
                              margin: EdgeInsets.only(bottom: 8),
                              child: Card(
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                color: isSelected
                                    ? (attendanceValue == true
                                        ? Colors.green.withOpacity(0.1)
                                        : Colors.red.withOpacity(0.1))
                                    : cardColor,
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: faltas >= 3
                                        ? Color(0xFFFF4B2B)
                                        : Color(0xFF147B7C),
                                    foregroundColor: Colors.white,
                                    child: Text(
                                      '${nombre.isNotEmpty ? nombre[0] : ''}${apellido.isNotEmpty ? apellido[0] : ''}',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  title: Text(
                                    '$nombre $apellido',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: faltas >= 3
                                          ? Color(0xFFFF4B2B)
                                          : Color(0xFF147B7C),
                                    ),
                                  ),
                                  subtitle: Row(
                                    children: [
                                      Icon(
                                        faltas >= 3
                                            ? Icons.warning_amber_outlined
                                            : Icons.check_circle_outline,
                                        size: 16,
                                        color: faltas >= 3
                                            ? Color(0xFFFF4B2B)
                                            : Colors.grey[600],
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        faltas >= 3
                                            ? 'Faltas: $faltas'
                                            : 'Asistencia regular',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: faltas >= 3
                                              ? Color(0xFFFF4B2B)
                                              : Colors.grey[600],
                                        ),
                                      ),
                                      if (isSelected) ...[
                                        SizedBox(width: 8),
                                        Icon(
                                          attendanceValue == true
                                              ? Icons.check_circle
                                              : Icons.cancel,
                                          size: 16,
                                          color: attendanceValue == true
                                              ? Colors.green
                                              : Colors.red,
                                        ),
                                        Text(
                                          attendanceValue == true
                                              ? ' Presente'
                                              : ' Ausente',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: attendanceValue == true
                                                ? Colors.green
                                                : Colors.red,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  trailing: FutureBuilder<bool>(
                                    future: _tieneBloqueoPorFaltas(
                                      registro.id,
                                      (dataMap['faltasConsecutivas'] as num?)
                                              ?.toInt() ??
                                          0,
                                    ),
                                    builder: (context, snap) {
                                      final bool bloqueado = snap.data == true;

                                      if (bloqueado) {
                                        // Mostrar ícono de bloqueo en lugar de botones
                                        return Tooltip(
                                          message:
                                              'Bloqueado: revisar alerta de faltas',
                                          child: Container(
                                            padding: EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.red.shade50,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color: Colors.red.shade200,
                                                width: 1,
                                              ),
                                            ),
                                            child: Icon(
                                              Icons.lock_outline,
                                              color: Colors.red.shade400,
                                              size: 24,
                                            ),
                                          ),
                                        );
                                      }

                                      // Botones normales si no está bloqueado
                                      return Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          // Botón presente
                                          Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              onTap: _isProcessingMassive
                                                  ? null
                                                  : () {
                                                      setState(() {
                                                        _selectedAttendances[
                                                            registro.id] = true;
                                                      });
                                                    },
                                              child: Container(
                                                padding: EdgeInsets.all(8),
                                                child: Icon(
                                                  Icons.check_circle,
                                                  color: (isSelected &&
                                                          attendanceValue ==
                                                              true)
                                                      ? Colors.green
                                                      : Colors.grey,
                                                  size: 28,
                                                ),
                                              ),
                                            ),
                                          ),
                                          // Botón ausente
                                          Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              onTap: _isProcessingMassive
                                                  ? null
                                                  : () {
                                                      setState(() {
                                                        _selectedAttendances[
                                                                registro.id] =
                                                            false;
                                                      });
                                                    },
                                              child: Container(
                                                padding: EdgeInsets.all(8),
                                                child: Icon(
                                                  Icons.cancel,
                                                  color: (isSelected &&
                                                          attendanceValue ==
                                                              false)
                                                      ? Colors.red
                                                      : Colors.grey,
                                                  size: 28,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                              ),
                            );
                          }

                          // Modo individual (versión original mejorada)
                          return Container(
                            margin: EdgeInsets.only(bottom: 12),
                            child: Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              color: cardColor,
                              child: ExpansionTile(
                                initiallyExpanded: false,
                                tilePadding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                leading: CircleAvatar(
                                  backgroundColor: faltas >= 3
                                      ? Color(0xFFFF4B2B)
                                      : Color(0xFF147B7C),
                                  foregroundColor: Colors.white,
                                  child: Text(
                                    '${nombre.isNotEmpty ? nombre[0] : ''}${apellido.isNotEmpty ? apellido[0] : ''}',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                title: Text(
                                  '$nombre $apellido',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: faltas >= 3
                                        ? Color(0xFFFF4B2B)
                                        : Color(0xFF147B7C),
                                  ),
                                ),
                                subtitle: Row(
                                  children: [
                                    Icon(
                                      faltas >= 3
                                          ? Icons.warning_amber_outlined
                                          : Icons.check_circle_outline,
                                      size: 16,
                                      color: faltas >= 3
                                          ? Color(0xFFFF4B2B)
                                          : Colors.grey[600],
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      faltas >= 3
                                          ? 'Faltas: $faltas'
                                          : 'Asistencia regular',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: faltas >= 3
                                            ? Color(0xFFFF4B2B)
                                            : Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: FutureBuilder<bool>(
                                  future: _tieneBloqueoPorFaltas(
                                    registro.id,
                                    (dataMap['faltasConsecutivas'] as num?)
                                            ?.toInt() ??
                                        0,
                                  ),
                                  builder: (context, snap) {
                                    final bool bloqueado = snap.data == true;
                                    final Color colorIcono = bloqueado
                                        ? Colors.grey.shade400
                                        : Color(0xFF147B7C);

                                    return PopupMenuButton<String>(
                                      enabled: !bloqueado,
                                      icon: Icon(
                                        Icons.more_vert,
                                        color: colorIcono,
                                      ),
                                      tooltip: bloqueado
                                          ? 'Bloqueado: 3+ faltas con alerta sin revisar'
                                          : 'Opciones',
                                      onSelected: bloqueado
                                          ? null
                                          : (value) {
                                              try {
                                                if (value == 'asistencia' &&
                                                    mounted) {
                                                  _registrarAsistencia(
                                                      registro);
                                                }
                                              } catch (e) {
                                                print(
                                                    'Error en PopupMenuButton: $e');
                                              }
                                            },
                                      itemBuilder: (context) => [
                                        PopupMenuItem(
                                          value: 'asistencia',
                                          enabled: !bloqueado,
                                          child: Opacity(
                                            opacity: bloqueado ? 0.45 : 1.0,
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.calendar_today,
                                                  color: colorIcono,
                                                  size: 20,
                                                ),
                                                SizedBox(width: 8),
                                                Text(
                                                  'Registrar Asistencia',
                                                  style: TextStyle(
                                                    color: bloqueado
                                                        ? Colors.grey
                                                        : Colors.black87,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                                children: [
                                  Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        FutureBuilder<bool>(
                                          future: _tieneBloqueoPorFaltas(
                                            registro.id,
                                            (dataMap['faltasConsecutivas']
                                                        as num?)
                                                    ?.toInt() ??
                                                0,
                                          ),
                                          builder: (context, snap) {
                                            final bool bloqueado =
                                                snap.data == true;

                                            return Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceEvenly,
                                              children: [
                                                Expanded(
                                                  child: Opacity(
                                                    opacity:
                                                        bloqueado ? 0.45 : 1.0,
                                                    child: ElevatedButton.icon(
                                                      icon: Icon(
                                                          Icons.calendar_today),
                                                      label: Text(bloqueado
                                                          ? 'Bloqueado (revisar alerta)'
                                                          : 'Registrar Asistencia'),
                                                      style: ElevatedButton
                                                          .styleFrom(
                                                        backgroundColor:
                                                            bloqueado
                                                                ? Colors.grey
                                                                    .shade400
                                                                : Color(
                                                                    0xFF147B7C),
                                                        foregroundColor:
                                                            Colors.white,
                                                        padding: EdgeInsets
                                                            .symmetric(
                                                                vertical: 12),
                                                      ),
                                                      onPressed: bloqueado
                                                          ? null
                                                          : () {
                                                              if (mounted) {
                                                                _registrarAsistencia(
                                                                    registro);
                                                              }
                                                            },
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        ),
                                        SizedBox(height: 16),
                                        _buildAsistenciasCalendario(registro),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        } catch (e) {
                          print('Error construyendo item $index: $e');
                          return SizedBox.shrink();
                        }
                      }),

                      // Espacio adicional al final para el FAB
                      SizedBox(height: 80),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _isMassiveMode &&
              _selectedAttendances.isNotEmpty &&
              !_isProcessingMassive
          ? FloatingActionButton.extended(
              onPressed: _procesarAsistenciaMasiva,
              backgroundColor: Color(0xFF147B7C),
              foregroundColor: Colors.white,
              icon: Icon(Icons.save),
              label: Text('Procesar ${_selectedAttendances.length}'),
            )
          : null,
    );
  }
}

class AlertasTab extends StatelessWidget {
  final String coordinadorId;

  const AlertasTab({Key? key, required this.coordinadorId}) : super(key: key);

  Future<void> _marcarEnRevision(String alertaId) async {
    await FirebaseFirestore.instance
        .collection('alertas')
        .doc(alertaId)
        .update({'estado': 'en_revision'});
  }

  Future<void> _marcarRevisado(String alertaId) async {
    await FirebaseFirestore.instance
        .collection('alertas')
        .doc(alertaId)
        .update({'estado': 'revisado'});
  }

  Future<void> _actualizarEstadoAlerta(
      String alertaId, String nuevoEstado) async {
    try {
      final alertaRef =
          FirebaseFirestore.instance.collection('alertas').doc(alertaId);
      final alertaDoc = await alertaRef.get();

      if (nuevoEstado == 'en_revision') {
        await alertaRef.update({
          'estado': nuevoEstado,
          'fechaRevision': FieldValue.serverTimestamp(),
        });
      } else if (nuevoEstado == 'revisado') {
        final registroId = alertaDoc.get('registroId');
        await FirebaseFirestore.instance
            .collection('registros')
            .doc(registroId)
            .update({
          'visible': true,
          'faltasConsecutivas': 0,
        });

        await alertaRef.update({
          'estado': nuevoEstado,
          'procesada': true,
          'fechaResolucion': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error al actualizar estado de alerta: $e');
    }
  }

  Widget _buildAlertCard(BuildContext context, DocumentSnapshot alerta) {
    // Acceso seguro a los datos del documento
    final data = alerta.data() as Map<String, dynamic>? ?? {};

    // Estado y configuración visual
    final estado = data['estado'] ?? 'Desconocido';
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (estado) {
      case 'pendiente':
        statusColor = Colors.red;
        statusText = 'Pendiente';
        statusIcon = Icons.warning_amber_rounded;
        break;
      case 'en_revision':
        statusColor = kAccentColor;
        statusText = 'En Revisión';
        statusIcon = Icons.hourglass_top;
        break;
      case 'revisado':
        statusColor = Colors.green;
        statusText = 'Revisado';
        statusIcon = Icons.check_circle;
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'Desconocido';
        statusIcon = Icons.help_outline;
    }

    return FutureBuilder<DocumentSnapshot>(
      // Obtener el registro relacionado desde Firestore
      future: FirebaseFirestore.instance
          .collection('registros')
          .doc(data['registroId'])
          .get(),
      builder: (context, snapshot) {
        // Obtener direccion y barrio del registro relacionado
        String direccion = 'Dirección no especificada';
        String barrio = 'Barrio no especificado';

        if (snapshot.hasData && snapshot.data != null) {
          final registroData =
              snapshot.data!.data() as Map<String, dynamic>? ?? {};
          direccion = registroData['direccion'] ?? 'Dirección no especificada';
          barrio = registroData['barrio'] ?? 'Barrio no especificado';
        }

        return Container(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: statusColor.withOpacity(0.1),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: statusColor.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: ExpansionTile(
            leading: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(statusIcon, color: statusColor),
            ),
            title: Text(
              data['nombreJoven'] ?? 'Nombre no disponible',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                    SizedBox(width: 4),
                    Text(
                      data['fecha'] != null
                          ? DateFormat('dd/MM/yyyy HH:mm')
                              .format((data['fecha'] as Timestamp).toDate())
                          : 'Sin fecha',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.warning,
                        size: 14,
                        color: statusColor,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Faltas: ${data['cantidadFaltas'] ?? 0}',
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(16),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(
                      'Timoteo asignado',
                      data['nombreTimoteo'] ?? 'No especificado',
                      Icons.person_outline,
                    ),
                    SizedBox(height: 12),
                    _buildInfoRow(
                      'Estado actual',
                      statusText,
                      Icons.info_outline,
                      color: statusColor,
                    ),
                    SizedBox(height: 12),
                    _buildInfoRow(
                      'Dirección',
                      direccion,
                      Icons.home_outlined,
                    ),
                    SizedBox(height: 12),
                    _buildInfoRow(
                      'Barrio',
                      barrio,
                      Icons.location_city_outlined,
                    ),
                    SizedBox(height: 16),
                    _buildActionButtons(context, estado, alerta.id),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon,
      {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color ?? Colors.grey[600]),
        SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color ?? Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(
      BuildContext context, String estado, String alertaId) {
    if (estado == 'pendiente') {
      return _buildActionButton(
        'Marcar en revisión',
        Icons.pending_actions,
        kAccentColor,
        () => _actualizarEstadoAlerta(alertaId, 'en_revision'),
      );
    } else if (estado == 'en_revision') {
      return _buildActionButton(
        'Marcar como revisado',
        Icons.check_circle,
        Colors.green,
        () => _actualizarEstadoAlerta(alertaId, 'revisado'),
      );
    }
    return SizedBox.shrink();
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onPressed: onPressed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kBackgroundColor,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(Icons.notifications, color: kPrimaryColor),
                SizedBox(width: 12),
                Text(
                  'Alertas de Asistencia',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: kPrimaryColor,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('alertas')
                  .where('coordinadorId', isEqualTo: coordinadorId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Error al cargar las alertas',
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(color: kPrimaryColor),
                  );
                }

                final alertas = snapshot.data?.docs
                    .where((doc) => doc['procesada'] == false)
                    .toList();

                if (alertas == null || alertas.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 64,
                          color: Colors.green,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No hay alertas pendientes',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                alertas.sort((a, b) => (b['fecha'] as Timestamp)
                    .compareTo(a['fecha'] as Timestamp));

                return ListView.builder(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  itemCount: alertas.length,
                  itemBuilder: (context, index) =>
                      _buildAlertCard(context, alertas[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class AttendanceHistoryWidget extends StatelessWidget {
  final List<dynamic> asistencias;
  final double height;

  const AttendanceHistoryWidget({
    Key? key,
    required this.asistencias,
    this.height = 100,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: asistencias.length,
        itemBuilder: (context, index) {
          final asistencia = asistencias[index];
          final fecha = asistencia['fecha'].toDate();
          final asistio = asistencia['asistio'];

          return Card(
            color: asistio ? Colors.green[100] : Colors.red[100],
            margin: EdgeInsets.symmetric(horizontal: 4),
            child: Container(
              width: 80,
              padding: EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    asistio ? Icons.check_circle : Icons.cancel,
                    color: asistio ? Colors.green : Colors.red,
                    size: 32,
                  ),
                  SizedBox(height: 4),
                  Text(
                    DateFormat('dd/MM').format(fecha),
                    style: TextStyle(fontSize: 12),
                  ),
                  Text(
                    DateFormat('HH:mm').format(fecha),
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class TimoteosTab extends StatelessWidget {
  final String coordinadorId;

  const TimoteosTab({Key? key, required this.coordinadorId}) : super(key: key);

  Future<void> _editTimoteo(
      BuildContext context, DocumentSnapshot timoteo) async {
    final TextEditingController _nameController =
        TextEditingController(text: timoteo['nombre']);
    final TextEditingController _lastNameController =
        TextEditingController(text: timoteo['apellido']);
    final TextEditingController _userController =
        TextEditingController(text: timoteo['usuario']);
    final TextEditingController _passwordController =
        TextEditingController(text: timoteo['contrasena']);

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Editar Timoteo'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Nombre'),
              ),
              TextField(
                controller: _lastNameController,
                decoration: InputDecoration(labelText: 'Apellido'),
              ),
              TextField(
                controller: _userController,
                decoration: InputDecoration(labelText: 'Usuario'),
              ),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: 'Contraseña'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('timoteos')
                    .doc(timoteo.id)
                    .update({
                  'nombre': _nameController.text,
                  'apellido': _lastNameController.text,
                  'usuario': _userController.text,
                  'contrasena': _passwordController.text,
                });
                Navigator.pop(context);
              },
              child: Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kBackgroundColor,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            margin: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.people_outline, color: kPrimaryColor, size: 24),
                SizedBox(width: 12),
                Text(
                  'Lista de Timoteos',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: kPrimaryColor,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('timoteos')
                  .where('coordinadorId', isEqualTo: coordinadorId)
                  .snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(color: kPrimaryColor),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_off_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No hay Timoteos asignados',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final timoteo = snapshot.data!.docs[index];
                    return Card(
                      elevation: 2,
                      margin: EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          backgroundColor: kPrimaryColor.withOpacity(0.1),
                          child: Text(
                            '${timoteo['nombre'][0]}${timoteo['apellido'][0]}',
                            style: TextStyle(
                              color: kPrimaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          '${timoteo['nombre']} ${timoteo['apellido']}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        subtitle: Text(
                          'Usuario: ${timoteo['usuario']}',
                          style: TextStyle(color: Colors.grey),
                        ),
                        children: [
                          Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.lock_outline,
                                        color: Colors.grey, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'Contraseña: ${timoteo['contrasena']}',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _buildActionButton(
                                      icon: Icons.edit,
                                      label: 'Editar',
                                      color: kPrimaryColor,
                                      onPressed: () =>
                                          _editTimoteo(context, timoteo),
                                    ),
                                    _buildActionButton(
                                      icon: Icons.list,
                                      label: 'Registros',
                                      color: kSecondaryColor,
                                      onPressed: () => _viewAssignedRegistros(
                                          context, timoteo),
                                    ),
                                    _buildActionButton(
                                      icon: Icons.person,
                                      label: 'Perfil',
                                      color: kAccentColor,
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => TimoteoScreen(
                                              timoteoId: timoteo.id,
                                              timoteoNombre:
                                                  '${timoteo['nombre']} ${timoteo['apellido']}',
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: color),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 20),
              SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _viewAssignedRegistros(
    BuildContext context, DocumentSnapshot timoteo) async {
  await showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          child: Scaffold(
            appBar: AppBar(
              title: Text(
                  'Registros de ${timoteo['nombre']} ${timoteo['apellido']}'),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            body: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('registros')
                  .where('timoteoAsignado', isEqualTo: timoteo.id)
                  .snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text('No hay registros asignados a este Timoteo'),
                  );
                }

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final registro = snapshot.data!.docs[index];
                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: ListTile(
                        title: Text(
                          '${registro['nombre']} ${registro['apellido']}',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Teléfono: ${registro['telefono']}'),
                            Text(
                                'Fecha asignación: ${registro['fechaAsignacion']?.toDate().toString() ?? 'N/A'}'),
                          ],
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.person_remove, color: Colors.red),
                          tooltip: 'Quitar asignación',
                          onPressed: () async {
                            try {
                              await FirebaseFirestore.instance
                                  .collection('registros')
                                  .doc(registro.id)
                                  .update({
                                'timoteoAsignado': null,
                                'nombreTimoteo': null,
                                'fechaAsignacion': null,
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content:
                                      Text('Registro desasignado exitosamente'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Error al desasignar el registro: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      );
    },
  );
}

class PersonasAsignadasTab extends StatelessWidget {
  final String coordinadorId;

  const PersonasAsignadasTab({Key? key, required this.coordinadorId})
      : super(key: key);

  Future<void> _asignarATimoteo(
      BuildContext context, DocumentSnapshot registro) async {
    final timoteosSnapshot = await FirebaseFirestore.instance
        .collection('timoteos')
        .where('coordinadorId', isEqualTo: coordinadorId)
        .get();

    if (timoteosSnapshot.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No hay Timoteos disponibles para asignar')),
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Asignar a Timoteo'),
          content: Container(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: timoteosSnapshot.docs.length,
              itemBuilder: (context, index) {
                final timoteo = timoteosSnapshot.docs[index];
                return ListTile(
                  title: Text('${timoteo['nombre']} ${timoteo['apellido']}'),
                  onTap: () async {
                    try {
                      await FirebaseFirestore.instance
                          .collection('registros')
                          .doc(registro.id)
                          .update({
                        'timoteoAsignado': timoteo.id,
                        'nombreTimoteo':
                            '${timoteo['nombre']} ${timoteo['apellido']}',
                        'fechaAsignacion': FieldValue.serverTimestamp(),
                      });

                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Registro asignado exitosamente a ${timoteo['nombre']}'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error al asignar el registro: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

//VER DETALLES DEL REGISTRO
  void _mostrarDetallesRegistro(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    // Definimos colores según los proporcionados en el segundo código
    final primaryTeal = Color(0xFF038C7F);
    final secondaryOrange = Color(0xFFFF5722);
    final accentGrey = Color(0xFF78909C);
    final backgroundGrey = Color(0xFFF5F5F5);

    // Función para formatear fechas
    String formatearFecha(String? fecha) {
      if (fecha == null || fecha.isEmpty) return '';

      // Si la fecha está en formato timestamp de Firestore
      if (fecha.contains('Timestamp')) {
        try {
          // Extraer los segundos del formato "Timestamp(seconds=1234567890, ...)"
          final regex = RegExp(r'seconds=(\d+)');
          final match = regex.firstMatch(fecha);
          if (match != null) {
            final seconds = int.tryParse(match.group(1) ?? '');
            if (seconds != null) {
              final date = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
              return '${date.day}/${date.month}/${date.year}';
            }
          }
        } catch (e) {
          // Si hay error en la conversión, devolver la fecha original
          return fecha;
        }
      }

      // Intentar parsear otras fechas comunes
      try {
        final date = DateTime.parse(fecha);
        return '${date.day}/${date.month}/${date.year}';
      } catch (e) {
        // Si no es parseable, devolver el texto original
        return fecha;
      }
    }

    // Función para calcular la edad a partir de fecha de nacimiento
    int? calcularEdadDesdeData(Map<String, dynamic> data) {
      try {
        var fechaNacimiento;

        if (data.containsKey('fechaNacimiento')) {
          var value = data['fechaNacimiento'];

          if (value is Timestamp) {
            fechaNacimiento = value.toDate();
          } else if (value is String && value.isNotEmpty) {
            // Manejar formato Timestamp en string
            if (value.contains('Timestamp')) {
              final regex = RegExp(r'seconds=(\d+)');
              final match = regex.firstMatch(value);
              if (match != null) {
                final seconds = int.tryParse(match.group(1) ?? '');
                if (seconds != null) {
                  fechaNacimiento =
                      DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
                }
              }
            } else {
              fechaNacimiento = DateTime.parse(value);
            }
          }

          if (fechaNacimiento != null) {
            final hoy = DateTime.now();
            int edad = (hoy.year - fechaNacimiento.year).toInt();
            if (hoy.month < fechaNacimiento.month ||
                (hoy.month == fechaNacimiento.month &&
                    hoy.day < fechaNacimiento.day)) {
              edad--;
            }
            return edad;
          }
        }
        return null;
      } catch (e) {
        return null;
      }
    }

    // Función para calcular próximo cumpleaños
    String? calcularProximoCumpleanosDesdeData(Map<String, dynamic> data) {
      try {
        var fechaNacimiento;

        if (data.containsKey('fechaNacimiento')) {
          var value = data['fechaNacimiento'];

          if (value is Timestamp) {
            fechaNacimiento = value.toDate();
          } else if (value is String && value.isNotEmpty) {
            // Manejar formato Timestamp en string
            if (value.contains('Timestamp')) {
              final regex = RegExp(r'seconds=(\d+)');
              final match = regex.firstMatch(value);
              if (match != null) {
                final seconds = int.tryParse(match.group(1) ?? '');
                if (seconds != null) {
                  fechaNacimiento =
                      DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
                }
              }
            } else {
              fechaNacimiento = DateTime.parse(value);
            }
          }

          if (fechaNacimiento != null) {
            final hoy = DateTime.now();
            DateTime proximoCumpleanos =
                DateTime(hoy.year, fechaNacimiento.month, fechaNacimiento.day);

            if (proximoCumpleanos.isBefore(hoy) ||
                proximoCumpleanos.isAtSameMomentAs(hoy)) {
              proximoCumpleanos = DateTime(
                  hoy.year + 1, fechaNacimiento.month, fechaNacimiento.day);
            }

            final diferencia = proximoCumpleanos.difference(hoy).inDays;

            if (diferencia == 0) {
              return '¡Hoy es su cumpleaños! 🎉';
            } else if (diferencia == 1) {
              return 'Mañana (1 día)';
            } else if (diferencia <= 7) {
              return 'En ${diferencia} días';
            } else if (diferencia <= 30) {
              return 'En ${diferencia} días';
            } else {
              final double mesesDouble = diferencia / 30;
              final int meses = mesesDouble.floor().toInt();
              if (meses == 1) {
                return 'En aproximadamente 1 mes';
              } else {
                return 'En aproximadamente ${meses} meses';
              }
            }
          }
        }
        return null;
      } catch (e) {
        return null;
      }
    }

    // Definimos una lista de secciones y campos agrupados para mejor organización
    final secciones = [
      {
        'titulo': 'Información Personal',
        'icono': Icons.person_outline,
        'color': primaryTeal,
        'campos': [
          {'key': 'nombre', 'label': 'Nombre', 'icon': Icons.badge_outlined},
          {
            'key': 'apellido',
            'label': 'Apellido',
            'icon': Icons.badge_outlined
          },
          {
            'key': 'telefono',
            'label': 'Teléfono',
            'icon': Icons.phone_outlined
          },
          {
            'key': 'edad',
            'label': 'Edad',
            'icon': Icons.calendar_today_outlined
          },
          {'key': 'sexo', 'label': 'Sexo', 'icon': Icons.wc_outlined},
          {
            'key': 'estadoCivil',
            'label': 'Estado Civil',
            'icon': Icons.favorite_border
          },
          {
            'key': 'tieneHijos',
            'label': 'Tiene Hijos',
            'icon': Icons.child_care_outlined
          },
          {
            'key': 'nombrePareja',
            'label': 'Nombre Pareja',
            'icon': Icons.people_outline
          },
        ]
      },
      {
        'titulo': 'Información de Cumpleaños',
        'icono': Icons.celebration_outlined,
        'color': secondaryOrange, // Color naranja para cumpleaños
        'campos': [
          {
            'key': 'fechaNacimiento',
            'label': 'Fecha de Nacimiento',
            'icon': Icons.cake_outlined,
            'esFecha': true
          },
          {
            'key': 'edad',
            'label': 'Edad Actual',
            'icon': Icons.timeline_outlined,
            'esEdadCalculada':
                true // Nueva propiedad para identificar campos calculados
          },
          {
            'key': 'proximoCumpleanos',
            'label': 'Próximo Cumpleaños',
            'icon': Icons.event_available_outlined,
            'esProximoCumpleanos':
                true // Nueva propiedad para próximo cumpleaños
          },
        ]
      },
      {
        'titulo': 'Ubicación',
        'icono': Icons.location_on_outlined,
        'color': primaryTeal,
        'campos': [
          {
            'key': 'direccionBarrio',
            'label': 'Dirección/Barrio',
            'icon': Icons.home_outlined
          },
        ]
      },
      {
        'titulo': 'Ocupación',
        'icono': Icons.work_outline,
        'color': secondaryOrange,
        'campos': [
          {
            'key': 'ocupaciones',
            'label': 'Ocupaciones',
            'icon': Icons.work_outline
          },
          {
            'keys': [
              'descripcionOcupaciones', // AGREGADO: campo plural
              'descripcionOcupacion' // Campo singular existente
            ], // Múltiples keys posibles
            'label': 'Descripción Ocupación',
            'icon': Icons.description_outlined
          },
        ]
      },
      {
        'titulo': 'Información Ministerial',
        'icono': Icons.groups_outlined,
        'color': accentGrey,
        'campos': [
          {
            'key': 'nombreTribu',
            'label': 'Tribu',
            'icon': Icons.group_outlined
          },
          {
            'key': 'ministerioAsignado',
            'label': 'Ministerio',
            'icon': Icons.assignment_ind_outlined
          },
          {
            'key': 'consolidador',
            'label': 'Consolidador',
            'icon': Icons.supervisor_account_outlined
          },
          {
            'key': 'referenciaInvitacion',
            'label': 'Ref. Invitación',
            'icon': Icons.share_outlined
          },
        ]
      },
      {
        'titulo': 'Fechas',
        'icono': Icons.event_outlined,
        'color': secondaryOrange,
        'campos': [
          {
            'key': 'fecha',
            'label': 'Registro',
            'icon': Icons.event_outlined,
            'esFecha': true
          },
          {
            'key': 'fechaAsignacion',
            'label': 'Asignación',
            'icon': Icons.date_range_outlined,
            'esFecha': true
          },
        ]
      },
      {
        'titulo': 'Notas',
        'icono': Icons.note_outlined,
        'color': accentGrey,
        'campos': [
          {
            'key': 'observaciones',
            'label': 'Observaciones',
            'icon': Icons.notes_outlined
          },
          {
            'key': 'peticiones',
            'label': 'Peticiones',
            'icon': Icons.message_outlined
          },
          {
            'key': 'estadoFonovisita',
            'label': 'Estado de Fonovisita',
            'icon': Icons.call_outlined
          },
          {
            'key': 'observaciones2',
            'label': 'Observaciones 2',
            'icon': Icons.note_add_outlined
          },
        ]
      },
      {
        'titulo': 'Estado del Proceso',
        'icono': Icons.track_changes_outlined,
        'color': secondaryOrange,
        'campos': [
          {
            'key': 'estadoProceso',
            'label': 'Estado en la Iglesia',
            'icon': Icons.verified_outlined
          },
        ]
      },
    ];

    // Crear lista de widgets para el contenido del diálogo
    List<Widget> contenidoWidgets = [];

    // Procesar cada sección
    for (var seccion in secciones) {
      // MODIFICACIÓN: Filtrar campos considerando múltiples keys posibles
      final camposConDatos = (seccion['campos'] as List).where((campo) {
        // Para campos con múltiples keys posibles
        if (campo.containsKey('keys')) {
          final keys = campo['keys'] as List<String>;
          return keys.any((key) {
            if (!data.containsKey(key)) return false;
            final value = data[key];
            if (value == null) return false;
            if (value is List) return value.isNotEmpty;
            if (value is String) return value.trim().isNotEmpty;
            return true;
          });
        } else if (campo.containsKey('esEdadCalculada') &&
            campo['esEdadCalculada'] == true) {
          // Para campos de edad calculada
          return calcularEdadDesdeData(data) != null;
        } else if (campo.containsKey('esProximoCumpleanos') &&
            campo['esProximoCumpleanos'] == true) {
          // Para campos de próximo cumpleaños
          return calcularProximoCumpleanosDesdeData(data) != null;
        } else {
          // Para campos con una sola key (lógica original)
          final key = campo['key'] as String;
          if (!data.containsKey(key)) return false;
          final value = data[key];
          if (value == null) return false;
          if (value is List) return value.isNotEmpty;
          if (value is String) return value.trim().isNotEmpty;
          return true;
        }
      }).toList();

      // Solo mostramos secciones con campos con datos
      if (camposConDatos.isNotEmpty) {
        // Añadir título de sección
        contenidoWidgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
            child: Row(
              children: [
                Icon(
                  seccion['icono'] as IconData,
                  color: seccion['color'] as Color,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  seccion['titulo'] as String,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: seccion['color'] as Color,
                  ),
                ),
              ],
            ),
          ),
        );

        // Añadir línea separadora para el título
        contenidoWidgets.add(
          Divider(
            color: (seccion['color'] as Color).withOpacity(0.3),
            thickness: 1,
          ),
        );

        // Añadir campos de esta sección
        for (var campo in camposConDatos) {
          final label = campo['label'] as String;
          final icon = campo['icon'] as IconData;
          final esFecha = campo['esFecha'] as bool? ?? false;

          // MODIFICACIÓN: Obtener valor considerando múltiples keys posibles
          String textoValor = '';
          // NUEVA LÓGICA: Manejar campos calculados especiales
          if (campo.containsKey('esEdadCalculada') &&
              campo['esEdadCalculada'] == true) {
            // Campo de edad calculada
            final edadCalculada = calcularEdadDesdeData(data);
            if (edadCalculada != null) {
              textoValor = '$edadCalculada años';
            }
          } else if (campo.containsKey('esProximoCumpleanos') &&
              campo['esProximoCumpleanos'] == true) {
            // Campo de próximo cumpleaños
            final proximoCumpleanos = calcularProximoCumpleanosDesdeData(data);
            if (proximoCumpleanos != null) {
              textoValor = proximoCumpleanos;
            }
          } else if (campo.containsKey('keys')) {
            // Para campos con múltiples keys posibles
            final keys = campo['keys'] as List<String>;
            for (String key in keys) {
              if (data.containsKey(key) && data[key] != null) {
                var value = data[key];
                if (value is String && value.trim().isNotEmpty) {
                  textoValor = esFecha ? formatearFecha(value) : value;
                  break;
                } else if (value is List && value.isNotEmpty) {
                  textoValor = value.join(', ');
                  break;
                } else if (value is int || value is double) {
                  textoValor = value.toString();
                  break;
                } else if (value is bool) {
                  textoValor = value ? 'Sí' : 'No';
                  break;
                } else if (value != null) {
                  textoValor = esFecha
                      ? formatearFecha(value.toString())
                      : value.toString();
                  break;
                }
              }
            }
          } else {
            // Para campos con una sola key (lógica original)
            final key = campo['key'] as String;
            var value = data[key];

            if (esFecha) {
              textoValor = formatearFecha(value?.toString());
            } else if (value is List) {
              textoValor = (value as List).join(', ');
            } else if (value is int || value is double) {
              textoValor = value.toString();
            } else if (value is bool) {
              textoValor = value ? 'Sí' : 'No';
            } else {
              textoValor = value?.toString() ?? '';
            }
          }

          // Añadir widget de detalle solo si hay texto para mostrar
          if (textoValor.isNotEmpty) {
            contenidoWidgets.add(
              _buildDetalle(label, textoValor, icon, accentGrey, primaryTeal),
            );
          }
        }
      }
    }

    // Si no hay datos para mostrar, mostrar mensaje
    if (contenidoWidgets.isEmpty) {
      contenidoWidgets.add(
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 48,
                  color: accentGrey,
                ),
                SizedBox(height: 16),
                Text(
                  'No hay información disponible',
                  style: TextStyle(
                    fontSize: 16,
                    color: accentGrey,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Mostrar el diálogo
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 5,
        backgroundColor: backgroundGrey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Encabezado del diálogo
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: primaryTeal,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person_outline,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Detalles del Registro',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(50),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Contenido con scrolling
            Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: contenidoWidgets,
                  ),
                ),
              ),
            ),

            // Pie del diálogo
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryTeal,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_outline, size: 18),
                        SizedBox(width: 8),
                        Text('Cerrar'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetalle(String label, String value, IconData iconData,
      Color accentGrey, Color primaryTeal) {
    // Detectar si el campo es "Teléfono" para agregar funcionalidad de copiado
    final esTelefono = label.toLowerCase().contains('teléfono') ||
        label.toLowerCase().contains('telefono');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: primaryTeal.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              iconData,
              size: 16,
              color: primaryTeal,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: accentGrey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                // Si es teléfono, mostrar en un Row con el botón de copiar
                esTelefono
                    ? Row(
                        children: [
                          Expanded(
                            child: Text(
                              value,
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.black87,
                                height: 1.3,
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          // Botón para copiar el teléfono usando Builder para obtener context
                          Builder(
                            builder: (BuildContext builderContext) {
                              return Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () async {
                                    // Copiar al portapapeles
                                    await Clipboard.setData(
                                        ClipboardData(text: value));

                                    // Mostrar feedback visual
                                    ScaffoldMessenger.of(builderContext)
                                        .showSnackBar(
                                      SnackBar(
                                        content: Row(
                                          children: [
                                            Icon(
                                              Icons.check_circle_outline,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                            SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                '¡Teléfono copiado!',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        backgroundColor: primaryTeal,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        margin: EdgeInsets.all(12),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          primaryTeal.withOpacity(0.8),
                                          primaryTeal,
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: primaryTeal.withOpacity(0.3),
                                          blurRadius: 4,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.content_copy_rounded,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      )
                    : Text(
                        value,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.black87,
                          height: 1.3,
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Definimos los colores del segundo código
    final primaryTeal = Color(0xFF038C7F);
    final secondaryOrange = Color(0xFFFF5722);
    final accentGrey = Color(0xFF78909C);
    final backgroundGrey = Color(0xFFF5F5F5);

    return _PersonasAsignadasContent(
      coordinadorId: coordinadorId,
      primaryTeal: primaryTeal,
      secondaryOrange: secondaryOrange,
      accentGrey: accentGrey,
      backgroundGrey: backgroundGrey,
      onEditarRegistro: _editarRegistro,
      onMostrarDetalles: _mostrarDetallesRegistro,
      onRegistrarNuevo: _registrarNuevoMiembro,
      onAsignarTimoteo: _asignarATimoteo,
    );
  }

// ✅ NUEVA FUNCIÓN: Método para obtener el valor de un campo con detección de variantes
  dynamic obtenerValorCampoEdicion(Map<String, dynamic> data, String campo) {
    // Si el campo existe directamente, lo devolvemos
    if (data.containsKey(campo)) {
      return data[campo];
    }

    // ✅ MODIFICACIÓN: Detección especial para descripcionOcupacion
    if (campo == 'descripcionOcupacion') {
      // Buscar primero 'descripcionOcupacion', luego 'descripcionOcupaciones'
      if (data.containsKey('descripcionOcupacion')) {
        return data['descripcionOcupacion'];
      } else if (data.containsKey('descripcionOcupaciones')) {
        return data['descripcionOcupaciones'];
      }
    }

    // Si no se encuentra el campo, devolver null
    return null;
  }

//EDITAR EL DETALLE DEL REGISTRO
  void _editarRegistro(BuildContext context, DocumentSnapshot registro) {
    // Colores de la aplicación
    const Color primaryTeal = Color(0xFF1B998B);
    const Color secondaryOrange = Color(0xFFFF7E00);
    final Color lightTeal = primaryTeal.withOpacity(0.1);

    // Flag para rastrear si hay cambios sin guardar
    bool hayModificaciones = false;

    // Función mejorada para obtener un valor seguro del documento con mejor manejo de nulos
    T? getSafeValue<T>(String field) {
      try {
        // Check if data() is null first
        final data = registro.data();
        if (data == null) return null;

        // Comprobar que data es un Map antes de intentar acceder a sus elementos
        if (data is Map) {
          // ✅ USAR LA NUEVA FUNCIÓN PARA OBTENER EL VALOR CON DETECCIÓN DE VARIANTES
          final value =
              obtenerValorCampoEdicion(data as Map<String, dynamic>, field);

          if (value is T) {
            return value;
          } else if (value != null) {
            // Intentar convertir al tipo correcto si es posible
            if (T == String && value != null) {
              return value.toString() as T;
            } else if (T == int && value is num) {
              return value.toInt() as T;
            } else if (T == double && value is num) {
              return value.toDouble() as T;
            }
          }
        }
        return null;
      } catch (e) {
        print('Error getting field $field: $e');
        return null;
      }
    }

    // Función para calcular la edad
    int _calcularEdad(DateTime fechaNacimiento) {
      final hoy = DateTime.now();
      int edad = hoy.year - fechaNacimiento.year;
      if (hoy.month < fechaNacimiento.month ||
          (hoy.month == fechaNacimiento.month &&
              hoy.day < fechaNacimiento.day)) {
        edad--;
      }
      return edad;
    }

    // Función para calcular el próximo cumpleaños
    String _calcularProximoCumpleanos(DateTime fechaNacimiento) {
      final hoy = DateTime.now();
      DateTime proximoCumpleanos =
          DateTime(hoy.year, fechaNacimiento.month, fechaNacimiento.day);

      if (proximoCumpleanos.isBefore(hoy) ||
          proximoCumpleanos.isAtSameMomentAs(hoy)) {
        proximoCumpleanos =
            DateTime(hoy.year + 1, fechaNacimiento.month, fechaNacimiento.day);
      }

      final diferencia = proximoCumpleanos.difference(hoy).inDays;

      if (diferencia == 0) {
        return '¡Hoy es su cumpleaños! 🎉';
      } else if (diferencia == 1) {
        return 'Mañana (${diferencia} día)';
      } else if (diferencia <= 7) {
        return 'En ${diferencia} días';
      } else if (diferencia <= 30) {
        return 'En ${diferencia} días';
      } else {
        final meses = (diferencia / 30).floor();
        if (meses == 1) {
          return 'En aproximadamente 1 mes';
        } else {
          return 'En aproximadamente ${meses} meses';
        }
      }
    }

    // Controladores para los campos (solo se crean para campos que existen)
    final Map<String, TextEditingController> controllers = {};

    // Estado para campos de selección con valores predeterminados para evitar nulos
    String estadoCivilSeleccionado =
        getSafeValue<String>('estadoCivil') ?? 'Soltero(a)';
    String sexoSeleccionado = getSafeValue<String>('sexo') ?? 'Hombre';

    // NUEVO: Fecha de nacimiento
    DateTime? fechaNacimiento;
    final fechaNacimientoValue = getSafeValue('fechaNacimiento');
    if (fechaNacimientoValue != null) {
      if (fechaNacimientoValue is Timestamp) {
        fechaNacimiento = fechaNacimientoValue.toDate();
      } else if (fechaNacimientoValue is String) {
        try {
          fechaNacimiento = DateTime.parse(fechaNacimientoValue);
        } catch (e) {
          print('Error parsing date string: $e');
        }
      }
    }

    // Opciones para los campos de selección
    final List<String> opcionesEstadoCivil = [
      'Casado(a)',
      'Soltero(a)',
      'Unión Libre',
      'Separado(a)',
      'Viudo(a)',
    ];

    final List<String> opcionesSexo = [
      'Hombre',
      'Mujer',
    ];

    // Definición de campos con sus iconos y tipos
    final Map<String, Map<String, dynamic>> camposDefinicion = {
      'nombre': {'icon': Icons.person, 'type': 'text'},
      'apellido': {'icon': Icons.person_outline, 'type': 'text'},
      'telefono': {'icon': Icons.phone, 'type': 'text'},
      'direccion': {'icon': Icons.location_on, 'type': 'text'},
      'barrio': {'icon': Icons.home, 'type': 'text'},
      'estadoCivil': {'icon': Icons.family_restroom, 'type': 'dropdown'},
      'nombrePareja': {'icon': Icons.favorite, 'type': 'text'},
      'ocupaciones': {'icon': Icons.work, 'type': 'list'},
      'descripcionOcupacion': {'icon': Icons.note, 'type': 'text'},
      'referenciaInvitacion': {'icon': Icons.link, 'type': 'text'},
      'observaciones': {'icon': Icons.comment, 'type': 'text'},
      'estadoFonovisita': {'icon': Icons.assignment, 'type': 'text'},
      'observaciones2': {'icon': Icons.notes, 'type': 'text'},
      'edad': {'icon': Icons.cake, 'type': 'int'},
      'peticiones': {'icon': Icons.volunteer_activism, 'type': 'text'},
      'sexo': {'icon': Icons.wc, 'type': 'dropdown'},
      'estadoProceso': {'icon': Icons.track_changes_outlined, 'type': 'text'},
      'fechaNacimiento': {'icon': Icons.calendar_today, 'type': 'date'},
    };

    // Inicializar controladores de manera segura
    camposDefinicion.forEach((key, value) {
      if (key != 'estadoCivil' && key != 'sexo' && key != 'fechaNacimiento') {
        // Estos se manejan con dropdowns o date picker
        var fieldValue = getSafeValue(key);

        // Crear controladores para todos los campos definidos para evitar errores de nullability
        if (value['type'] == 'list' && fieldValue is List) {
          controllers[key] = TextEditingController(text: fieldValue.join(', '));
        } else if (value['type'] == 'int' && fieldValue != null) {
          controllers[key] = TextEditingController(text: fieldValue.toString());
        } else if (fieldValue != null) {
          controllers[key] = TextEditingController(text: fieldValue.toString());
        } else {
          // Crear controladores vacíos para todos los campos para evitar problemas de nulabilidad
          controllers[key] = TextEditingController();
        }
      }
    });

    // Asegurar que nombrePareja siempre tenga un controlador para evitar null errors
    if (controllers['nombrePareja'] == null) {
      controllers['nombrePareja'] = TextEditingController();
    }

    // Función para verificar si se debe mostrar el campo de nombre de pareja
    bool mostrarNombrePareja() {
      return estadoCivilSeleccionado == 'Casado(a)' ||
          estadoCivilSeleccionado == 'Unión Libre';
    }

    // Función para mostrar el selector de fecha
    Future<void> _seleccionarFecha(StateSetter setState) async {
      final DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: fechaNacimiento ??
            DateTime.now().subtract(Duration(days: 365 * 25)),
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
            child: child!,
          );
        },
      );

      if (pickedDate != null) {
        setState(() {
          fechaNacimiento = pickedDate;
          hayModificaciones = true;
        });
      }
    }

    // Función para mostrar el diálogo de confirmación con manejo seguro de context
    Future<bool> confirmarSalida() async {
      if (!hayModificaciones) return true;

      // Verificar que el contexto sigue siendo válido
      if (!context.mounted) return false;

      bool confirmar = false;
      await showDialog(
        context: context,
        barrierDismissible: true, // Evitar cierre accidental
        builder: (BuildContext dialogContext) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.amber),
              SizedBox(width: 10),
              Text('Cambios sin guardar'),
            ],
          ),
          content: Text(
              '¿Estás seguro de que deseas salir sin guardar los cambios?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                confirmar = false;
              },
              child:
                  Text('Cancelar', style: TextStyle(color: Colors.grey[700])),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: secondaryOrange,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                confirmar = true;
              },
              child: Text('Salir sin guardar'),
            ),
          ],
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
      );

      return confirmar;
    }

    // Mostrar el nombre del registro en lugar del ID con manejo seguro de nulos
    String getNombreCompleto() {
      String nombre = getSafeValue<String>('nombre') ?? '';
      String apellido = getSafeValue<String>('apellido') ?? '';

      if (nombre.isNotEmpty || apellido.isNotEmpty) {
        return '$nombre $apellido'.trim();
      }

      return 'Registro ${registro.id}';
    }

    // Verificar si el contexto es válido antes de mostrar el diálogo
    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: true, // No se cierra al tocar fuera
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(builder: (stateContext, setState) {
          return WillPopScope(
            onWillPop: () async {
              bool confirmar = await confirmarSalida();
              return confirmar;
            },
            child: Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: 500,
                  maxHeight: MediaQuery.of(dialogContext).size.height * 0.8,
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Encabezado
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: lightTeal,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.edit, color: primaryTeal, size: 28),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Editar Registro',
                                  style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: primaryTeal),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Información del registro
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.person,
                                        color: Colors.grey[700], size: 18),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        getNombreCompleto(),
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey[800],
                                          fontWeight: FontWeight.w500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Datos del formulario
                        // Campos normales
                        ...camposDefinicion.entries.map((entry) {
                          final fieldName = entry.key;
                          final fieldData = entry.value;
                          final controller = controllers[fieldName];
                          final fieldIcon =
                              fieldData['icon'] ?? Icons.help_outline;

                          // Manejar dropdown para estado civil
                          if (fieldName == 'estadoCivil') {
                            return _buildDropdownField(
                              label: 'Estado Civil',
                              icon: fieldIcon,
                              value: estadoCivilSeleccionado,
                              items: opcionesEstadoCivil,
                              primaryColor: primaryTeal,
                              onChanged: (newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    estadoCivilSeleccionado = newValue;
                                    hayModificaciones = true;
                                  });
                                }
                              },
                            );
                          }

                          // Manejar dropdown para sexo
                          else if (fieldName == 'sexo') {
                            return _buildDropdownField(
                              label: 'Sexo',
                              icon: fieldIcon,
                              value: sexoSeleccionado,
                              items: opcionesSexo,
                              primaryColor: primaryTeal,
                              onChanged: (newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    sexoSeleccionado = newValue;
                                    hayModificaciones = true;
                                  });
                                }
                              },
                            );
                          }

                          // NUEVO: Manejar campo de fecha de nacimiento
                          else if (fieldName == 'fechaNacimiento') {
                            return Column(
                              children: [
                                // Campo de fecha de nacimiento
                                Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  child: InkWell(
                                    onTap: () => _seleccionarFecha(setState),
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.withOpacity(0.05),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: primaryTeal.withOpacity(0.3),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color:
                                                  primaryTeal.withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Icon(
                                              fieldIcon,
                                              color: primaryTeal,
                                              size: 20,
                                            ),
                                          ),
                                          SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Fecha de Nacimiento',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[600],
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                SizedBox(height: 4),
                                                Text(
                                                  fechaNacimiento != null
                                                      ? '${fechaNacimiento!.day}/${fechaNacimiento!.month}/${fechaNacimiento!.year}'
                                                      : 'Seleccionar fecha',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w500,
                                                    color:
                                                        fechaNacimiento != null
                                                            ? Colors.black87
                                                            : Colors.grey[500],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Icon(
                                            Icons.keyboard_arrow_down,
                                            color: Colors.grey[600],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),

                                // MOSTRAR INFORMACIÓN DE CUMPLEAÑOS SI EXISTE FECHA DE NACIMIENTO
                                if (fechaNacimiento != null)
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Color(0xFF1B998B).withOpacity(0.1),
                                          Color(0xFFFF7E00).withOpacity(0.1),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color:
                                            Color(0xFF1B998B).withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Color(0xFF1B998B)
                                                    .withOpacity(0.2),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Icon(
                                                Icons.celebration,
                                                color: Color(0xFF1B998B),
                                                size: 20,
                                              ),
                                            ),
                                            SizedBox(width: 12),
                                            Text(
                                              'Información de Cumpleaños',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF1B998B),
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  color: Colors.white
                                                      .withOpacity(0.7),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Edad Actual',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey[600],
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                    Text(
                                                      '${_calcularEdad(fechaNacimiento!)} años',
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color:
                                                            Color(0xFF1B998B),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            SizedBox(width: 12),
                                            Expanded(
                                              flex: 2,
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  color: Colors.white
                                                      .withOpacity(0.7),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Próximo Cumpleaños',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey[600],
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                    Text(
                                                      _calcularProximoCumpleanos(
                                                          fechaNacimiento!),
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color:
                                                            Color(0xFFFF7E00),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            );
                          }

                          // Solo mostrar campo de nombre de pareja si es necesario
                          else if (fieldName == 'nombrePareja') {
                            if (mostrarNombrePareja() && controller != null) {
                              return _buildAnimatedTextField(
                                label: 'Nombre de Pareja',
                                icon: fieldIcon,
                                controller: controller,
                                primaryColor: primaryTeal,
                                onChanged: (value) {
                                  hayModificaciones = true;
                                },
                              );
                            } else {
                              return SizedBox.shrink();
                            }
                          }

                          // Campo para Estado en la Iglesia (estadoProceso)
                          else if (fieldName == 'estadoProceso') {
                            return _buildAnimatedTextField(
                              label: 'Estado en la Iglesia',
                              icon: fieldIcon,
                              controller: controller!,
                              primaryColor: primaryTeal,
                              onChanged: (value) {
                                hayModificaciones = true;
                              },
                            );
                          }

                          // Otros campos de texto normales
                          else if (controller != null) {
                            return _buildAnimatedTextField(
                              label: _formatFieldName(fieldName),
                              icon: fieldIcon,
                              controller: controller,
                              primaryColor: primaryTeal,
                              onChanged: (value) {
                                hayModificaciones = true;
                              },
                            );
                          } else {
                            return SizedBox.shrink();
                          }
                        }).toList(),

                        const SizedBox(height: 24),

                        // Botones de acción
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton.icon(
                              onPressed: () async {
                                bool confirmar = await confirmarSalida();
                                if (confirmar && dialogContext.mounted) {
                                  Navigator.pop(dialogContext);
                                }
                              },
                              icon: Icon(Icons.cancel, color: Colors.grey[700]),
                              label: Text('Cancelar',
                                  style: TextStyle(
                                      color: Colors.grey[700], fontSize: 16)),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                              ),
                            ),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: secondaryOrange,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                elevation: 2,
                              ),
                              icon: const Icon(Icons.save, color: Colors.white),
                              label: const Text('Guardar Cambios',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                              onPressed: () async {
                                try {
                                  // Crear mapa para actualización con solo los campos que existen
                                  final Map<String, dynamic> updateData = {};

                                  // Agregar campos de dropdown
                                  updateData['estadoCivil'] =
                                      estadoCivilSeleccionado;
                                  updateData['sexo'] = sexoSeleccionado;

                                  // NUEVO: Agregar fecha de nacimiento
                                  if (fechaNacimiento != null) {
                                    updateData['fechaNacimiento'] =
                                        Timestamp.fromDate(fechaNacimiento!);
                                  }

                                  // Agregar otros campos de texto con manejo seguro
                                  controllers.forEach((key, controller) {
                                    if (controller != null) {
                                      final fieldType =
                                          camposDefinicion[key]?['type'];
                                      if (fieldType == 'list') {
                                        updateData[key] =
                                            controller.text.isEmpty
                                                ? []
                                                : controller.text
                                                    .split(',')
                                                    .map((e) => e.trim())
                                                    .toList();
                                      } else if (fieldType == 'int') {
                                        // Manejo seguro para valores numéricos
                                        int? parsedValue =
                                            int.tryParse(controller.text);
                                        updateData[key] = parsedValue ?? 0;
                                      } else {
                                        updateData[key] = controller.text;
                                      }
                                    }
                                  });

                                  // ✅ LÓGICA ESPECIAL: Al guardar, detectar cuál campo usar para descripcionOcupacion
                                  // Si tenemos datos para descripcionOcupacion, podemos decidir en cuál campo guardarlo
                                  final data = registro.data();
                                  if (data != null &&
                                      data is Map<String, dynamic>) {
                                    // Si ya existe descripcionOcupaciones en los datos originales, guardamos ahí
                                    if (data.containsKey(
                                            'descripcionOcupaciones') &&
                                        !data.containsKey(
                                            'descripcionOcupacion')) {
                                      if (updateData.containsKey(
                                          'descripcionOcupacion')) {
                                        updateData['descripcionOcupaciones'] =
                                            updateData['descripcionOcupacion'];
                                        updateData
                                            .remove('descripcionOcupacion');
                                      }
                                    }
                                    // Si existe descripcionOcupacion original, mantenemos ese campo
                                    // No hacemos nada adicional, el campo se actualiza normalmente
                                  }

                                  // Verificar que tenemos una referencia válida a Firestore
                                  if (FirebaseFirestore.instance != null) {
                                    // Actualizar en Firestore de manera segura
                                    await FirebaseFirestore.instance
                                        .collection('registros')
                                        .doc(registro.id)
                                        .update(updateData);

                                    // Cerrar el diálogo si el contexto sigue siendo válido
                                    if (dialogContext.mounted) {
                                      Navigator.pop(dialogContext);
                                    }

                                    // Mostrar notificación de éxito si el contexto sigue siendo válido
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Row(
                                            children: const [
                                              Icon(Icons.check_circle,
                                                  color: Colors.white),
                                              SizedBox(width: 12),
                                              Text(
                                                'Registro actualizado correctamente',
                                                style: TextStyle(fontSize: 16),
                                              ),
                                            ],
                                          ),
                                          backgroundColor: Colors.green,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          margin: const EdgeInsets.all(12),
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 14, horizontal: 20),
                                          duration: const Duration(seconds: 3),
                                        ),
                                      );
                                    }
                                  } else {
                                    throw Exception(
                                        "No se pudo conectar con Firestore");
                                  }
                                } catch (e) {
                                  // Mostrar error si el contexto sigue siendo válido
                                  if (dialogContext.mounted) {
                                    Navigator.pop(dialogContext);
                                  }

                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Row(
                                          children: [
                                            const Icon(Icons.error,
                                                color: Colors.white),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                'Error al actualizar: ${e.toString()}',
                                                style: const TextStyle(
                                                    fontSize: 16),
                                              ),
                                            ),
                                          ],
                                        ),
                                        backgroundColor: Colors.red,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        margin: const EdgeInsets.all(12),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 14, horizontal: 20),
                                        duration: const Duration(seconds: 5),
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        });
      },
    );
  }

// Widget para campos de texto con animación y mejor diseño
  Widget _buildAnimatedTextField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required Color primaryColor,
    required Function(String) onChanged,
  }) {
    // Asegurar que el controlador nunca sea nulo
    final TextEditingController safeController =
        controller ?? TextEditingController();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        child: TextField(
          controller: safeController,
          onChanged: onChanged,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(
              color: primaryColor.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: Icon(icon, color: primaryColor),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: primaryColor.withOpacity(0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: primaryColor.withOpacity(0.5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: primaryColor, width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          ),
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

// Widget para campos de selección dropdown con mejor manejo de nulos
  Widget _buildDropdownField({
    required String label,
    required IconData icon,
    required String? value,
    required List<String> items,
    required Color primaryColor,
    required Function(String?) onChanged,
  }) {
    // Asegurar que value no sea nulo
    final String safeValue = value ?? (items.isNotEmpty ? items[0] : '');

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: primaryColor.withOpacity(0.5)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Row(
            children: [
              Icon(icon, color: primaryColor),
              SizedBox(width: 12),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: items.contains(safeValue)
                        ? safeValue
                        : (items.isNotEmpty ? items[0] : null),
                    hint: Text(
                      'Seleccionar $label',
                      style: TextStyle(color: Colors.grey),
                    ),
                    icon: Icon(Icons.arrow_drop_down, color: primaryColor),
                    isExpanded: true,
                    onChanged: onChanged,
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 16,
                    ),
                    dropdownColor: Colors.white,
                    items: items.map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(value),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

// Función para formatear nombres de campos
  String _formatFieldName(String fieldName) {
    // Convertir camelCase a palabras separadas y capitalizar
    final formattedName = fieldName.replaceAllMapped(
        RegExp(r'([A-Z])'), (match) => ' ${match.group(0)}');

    return formattedName[0].toUpperCase() + formattedName.substring(1);
  }

// Manejador para inicializar Firebase Messaging de manera segura
  Future<void> initializeFirebaseMessaging() async {
    try {
      // Comprobar si Firebase Messaging está disponible
      if (FirebaseMessaging.instance != null) {
        // Solicitar permisos de manera silenciosa, sin mostrar pop-up si es posible
        NotificationSettings settings =
            await FirebaseMessaging.instance.requestPermission(
          alert: true,
          announcement: false,
          badge: true,
          carPlay: false,
          criticalAlert: false,
          provisional: true, // Usar notificaciones provisionales para iOS
          sound: true,
        );

        // Solo intentar obtener el token si el usuario ha dado permiso
        if (settings.authorizationStatus == AuthorizationStatus.authorized ||
            settings.authorizationStatus == AuthorizationStatus.provisional) {
          // Obtener token de manera segura
          try {
            String? token = await FirebaseMessaging.instance.getToken();
            if (token != null) {
              print('Token FCM: $token');
              // Guardar el token en algún lugar si es necesario
            }
          } catch (e) {
            print('Error al obtener token FCM: $e');
            // No mostrar error al usuario, manejar silenciosamente
          }
        } else {
          print(
              'Permisos de notificación no concedidos: ${settings.authorizationStatus}');
          // No mostrar error al usuario, manejar silenciosamente
        }
      }
    } catch (e) {
      print('Error al inicializar Firebase Messaging: $e');
      // No mostrar error al usuario, manejar silenciosamente
    }
  }

// REEMPLAZAR COMPLETAMENTE el método _registrarNuevoMiembro en PersonasAsignadasTab

  Future<void> _registrarNuevoMiembro(BuildContext context) async {
    // Colores del diseño original
    final primaryTeal = Color(0xFF038C7F);
    final secondaryOrange = Color(0xFFFF5722);
    final accentGrey = Color(0xFF78909C);
    final backgroundGrey = Color(0xFFF5F5F5);

    final _formKey = GlobalKey<FormState>();

    // Listas de opciones
    final List<String> _estadosCiviles = [
      'Casado(a)',
      'Soltero(a)',
      'Unión Libre',
      'Separado(a)',
      'Viudo(a)'
    ];

    final List<String> _ocupaciones = [
      'Estudiante',
      'Profesional',
      'Trabaja',
      'Ama de Casa',
      'Otro'
    ];

    // Variables para almacenar datos del formulario
    String nombre = '';
    String apellido = '';
    String telefono = '';
    String? sexo; // Cambiado a nullable
    int edad = 0;
    String direccion = '';
    String barrio = '';
    String? estadoCivil; // Cambiado a nullable
    String? nombrePareja;
    List<String> ocupacionesSeleccionadas = [];
    String descripcionOcupaciones = '';
    bool? tieneHijos; // Cambiado a nullable
    String referenciaInvitacion = '';
    String? observaciones;
    DateTime? fechaAsignacionTribu;

    // Obtener datos del coordinador y tribu
    String tribuId = '';
    String categoriaTribu = '';
    String nombreTribu = '';
    String ministerioAsignado = '';

    String estadoProceso = ''; // Nueva variable para estado del proceso

    try {
      final coordinadorSnapshot = await FirebaseFirestore.instance
          .collection('coordinadores')
          .doc(coordinadorId)
          .get();

      if (coordinadorSnapshot.exists) {
        final coordinadorData =
            coordinadorSnapshot.data() as Map<String, dynamic>;

        // Obtener tribuId del coordinador
        tribuId = coordinadorData['tribuId'] ?? '';

        // También obtener directamente el nombre de la tribu si está disponible
        String? tribuDirecta =
            coordinadorData['nombreTribu'] ?? coordinadorData['tribu'];

        if (tribuId.isNotEmpty) {
          final tribuSnapshot = await FirebaseFirestore.instance
              .collection('tribus')
              .doc(tribuId)
              .get();

          if (tribuSnapshot.exists) {
            final tribuData = tribuSnapshot.data() as Map<String, dynamic>;
            nombreTribu = tribuData['nombreTribu'] ??
                tribuData['nombre'] ??
                'Desconocida';
            categoriaTribu =
                tribuData['categoriaTribu'] ?? tribuData['categoria'] ?? '';
            ministerioAsignado = tribuData['ministerioAsignado'] ??
                tribuData['ministerio'] ??
                tribuData['categoria'] ??
                _determinarMinisterio(nombreTribu);
          } else {
            // Si no encontramos la tribu por ID, usar el nombre directo del coordinador
            nombreTribu = tribuDirecta ?? 'Tribu no encontrada';
          }
        } else if (tribuDirecta != null && tribuDirecta.isNotEmpty) {
          // Si no hay tribuId pero sí nombre directo, usarlo
          nombreTribu = tribuDirecta;
        } else {
          nombreTribu = 'Sin tribu asignada';
        }

        // Debug: Imprimir para verificar
        print('Coordinador ID: $coordinadorId');
        print('Tribu ID: $tribuId');
        print('Nombre Tribu: $nombreTribu');
      } else {
        print('Coordinador no encontrado');
        nombreTribu = 'Coordinador no encontrado';
      }
    } catch (e) {
      print('Error obteniendo datos del coordinador: $e');
      nombreTribu = 'Error al obtener tribu';
    }

    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        // Crear controladores fuera del StatefulBuilder para persistencia
        final Map<String, TextEditingController> _controllers = {
          'nombre': TextEditingController(text: nombre),
          'apellido': TextEditingController(text: apellido),
          'telefono': TextEditingController(text: telefono),
          'direccion': TextEditingController(text: direccion),
          'barrio': TextEditingController(text: barrio),
          'nombrePareja': TextEditingController(text: nombrePareja ?? ''),
          'descripcionOcupaciones':
              TextEditingController(text: descripcionOcupaciones),
          'referenciaInvitacion':
              TextEditingController(text: referenciaInvitacion),
          'observaciones': TextEditingController(text: observaciones ?? ''),
          'estadoProceso': TextEditingController(text: estadoProceso),
          'edad': TextEditingController(text: edad > 0 ? edad.toString() : ''),
        };

        return StatefulBuilder(
          builder: (stateContext, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 5,
              backgroundColor: backgroundGrey,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: 500,
                  maxHeight: MediaQuery.of(dialogContext).size.height * 0.9,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Encabezado del diálogo
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [primaryTeal, primaryTeal.withOpacity(0.8)],
                        ),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.person_add,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Registrar Nuevo Miembro',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                                ),
                                if (nombreTribu.isNotEmpty)
                                  Text(
                                    'Tribu: $nombreTribu',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 14,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => Navigator.pop(dialogContext),
                              borderRadius: BorderRadius.circular(50),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Contenido con scrolling
                    Expanded(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Información Personal
                                _buildSectionTitle('Información Personal',
                                    Icons.person_outline, primaryTeal),

                                _buildTextFieldWithController(
                                  'Nombre',
                                  Icons.person,
                                  _controllers['nombre']!,
                                  (value) => nombre = value,
                                ),
                                _buildTextFieldWithController(
                                  'Apellido',
                                  Icons.person_outline,
                                  _controllers['apellido']!,
                                  (value) => apellido = value,
                                ),
                                _buildTextFieldWithController(
                                  'Teléfono',
                                  Icons.phone,
                                  _controllers['telefono']!,
                                  (value) => telefono = value,
                                ),
                                _buildDropdown(
                                    'Sexo',
                                    ['Masculino', 'Femenino'],
                                    sexo,
                                    (value) => setState(() => sexo = value)),
                                _buildTextFieldWithController(
                                  'Edad',
                                  Icons.cake,
                                  _controllers['edad']!,
                                  (value) => edad = int.tryParse(value) ?? 0,
                                  keyboardType: TextInputType.number,
                                ),

                                SizedBox(height: 16),

                                // Ubicación
                                _buildSectionTitle('Ubicación',
                                    Icons.location_on_outlined, primaryTeal),

                                _buildTextFieldWithController(
                                  'Dirección',
                                  Icons.location_on,
                                  _controllers['direccion']!,
                                  (value) => direccion = value,
                                ),
                                _buildTextFieldWithController(
                                  'Barrio',
                                  Icons.home,
                                  _controllers['barrio']!,
                                  (value) => barrio = value,
                                ),

                                SizedBox(height: 16),

                                // Estado Civil y Familia
                                _buildSectionTitle('Estado Civil y Familia',
                                    Icons.family_restroom, primaryTeal),

                                // Dropdown de Estado Civil
                                _buildDropdown('Estado Civil', _estadosCiviles,
                                    estadoCivil, (value) {
                                  setState(() {
                                    estadoCivil = value;
                                    if (estadoCivil == 'Casado(a)' ||
                                        estadoCivil == 'Unión Libre') {
                                      nombrePareja = '';
                                    } else {
                                      nombrePareja = 'No aplica';
                                    }
                                  });
                                }),

                                // Campo dinámico para nombre de pareja
                                if (estadoCivil == 'Casado(a)' ||
                                    estadoCivil == 'Unión Libre')
                                  _buildTextFieldWithController(
                                    'Nombre de la Pareja',
                                    Icons.favorite,
                                    _controllers['nombrePareja']!,
                                    (value) => nombrePareja = value,
                                  ),

                                _buildDropdown(
                                    'Tiene Hijos',
                                    ['Sí', 'No'],
                                    tieneHijos == null
                                        ? null
                                        : (tieneHijos! ? 'Sí' : 'No'),
                                    (value) => setState(
                                        () => tieneHijos = (value == 'Sí'))),

                                SizedBox(height: 16),

                                // Ocupación
                                _buildSectionTitle('Ocupación',
                                    Icons.work_outline, primaryTeal),

                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Ocupaciones',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: primaryTeal,
                                        fontSize: 16,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: _ocupaciones.map((ocupacion) {
                                        final isSelected =
                                            ocupacionesSeleccionadas
                                                .contains(ocupacion);
                                        return FilterChip(
                                          label: Text(ocupacion),
                                          selected: isSelected,
                                          onSelected: (selected) {
                                            setState(() {
                                              if (selected) {
                                                ocupacionesSeleccionadas
                                                    .add(ocupacion);
                                              } else {
                                                ocupacionesSeleccionadas
                                                    .remove(ocupacion);
                                              }
                                            });
                                          },
                                          selectedColor:
                                              primaryTeal.withOpacity(0.2),
                                          checkmarkColor: primaryTeal,
                                          backgroundColor: Colors.white,
                                          side: BorderSide(
                                            color: isSelected
                                                ? primaryTeal
                                                : Colors.grey.withOpacity(0.5),
                                          ),
                                          labelStyle: TextStyle(
                                            color: isSelected
                                                ? primaryTeal
                                                : Colors.black87,
                                            fontWeight: isSelected
                                                ? FontWeight.w600
                                                : FontWeight.normal,
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                    if (ocupacionesSeleccionadas.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 12),
                                        child: _buildTextFieldWithController(
                                          'Descripción de Ocupaciones',
                                          Icons.work_outline,
                                          _controllers[
                                              'descripcionOcupaciones']!,
                                          (value) =>
                                              descripcionOcupaciones = value,
                                          isRequired: false,
                                        ),
                                      ),
                                  ],
                                ),

                                SizedBox(height: 16),

                                // Información Ministerial
                                _buildSectionTitle('Información Ministerial',
                                    Icons.groups_outlined, primaryTeal),

                                _buildTextFieldWithController(
                                  'Referencia de Invitación',
                                  Icons.link,
                                  _controllers['referenciaInvitacion']!,
                                  (value) => referenciaInvitacion = value,
                                ),
                                _buildTextFieldWithController(
                                  'Observaciones',
                                  Icons.note,
                                  _controllers['observaciones']!,
                                  (value) => observaciones = value,
                                  isRequired: false,
                                ),

                                _buildTextFieldWithController(
                                  'Estado en la Iglesia',
                                  Icons.track_changes_outlined,
                                  _controllers['estadoProceso']!,
                                  (value) => estadoProceso = value,
                                  isRequired: false,
                                ),

                                // Campo para seleccionar fecha
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  child: TextFormField(
                                    readOnly: true,
                                    decoration: InputDecoration(
                                      labelText:
                                          'Fecha de Asignación de la Tribu',
                                      labelStyle: TextStyle(
                                        color: primaryTeal.withOpacity(0.8),
                                        fontWeight: FontWeight.w500,
                                      ),
                                      prefixIcon: Icon(Icons.calendar_today,
                                          color: primaryTeal),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                            color:
                                                primaryTeal.withOpacity(0.3)),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                            color:
                                                primaryTeal.withOpacity(0.5)),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                            color: primaryTeal, width: 2),
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 16),
                                    ),
                                    validator: (value) =>
                                        fechaAsignacionTribu == null
                                            ? 'Campo obligatorio'
                                            : null,
                                    onTap: () async {
                                      final DateTime? pickedDate =
                                          await showDatePicker(
                                        context: dialogContext,
                                        initialDate: DateTime.now(),
                                        firstDate: DateTime(2000),
                                        lastDate: DateTime(2101),
                                        builder: (context, child) {
                                          return Theme(
                                            data: Theme.of(context).copyWith(
                                              colorScheme: ColorScheme.light(
                                                primary: primaryTeal,
                                                onPrimary: Colors.white,
                                                onSurface: Colors.black,
                                              ),
                                              textButtonTheme:
                                                  TextButtonThemeData(
                                                style: TextButton.styleFrom(
                                                  foregroundColor:
                                                      secondaryOrange,
                                                ),
                                              ),
                                            ),
                                            child: child!,
                                          );
                                        },
                                      );

                                      if (pickedDate != null) {
                                        setState(() {
                                          fechaAsignacionTribu = pickedDate;
                                        });
                                      }
                                    },
                                    controller: TextEditingController(
                                      text: fechaAsignacionTribu != null
                                          ? DateFormat('dd/MM/yyyy')
                                              .format(fechaAsignacionTribu!)
                                          : '',
                                    ),
                                  ),
                                ),

                                SizedBox(height: 16),

                                // Nota informativa
                                Container(
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: primaryTeal.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: primaryTeal.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        color: primaryTeal,
                                        size: 20,
                                      ),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Este miembro será asignado automáticamente a tu coordinación.',
                                          style: TextStyle(
                                            color: primaryTeal,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Botones de acción
                    Container(
                      padding: const EdgeInsets.all(20.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(20),
                          bottomRight: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextButton.icon(
                              onPressed: () => Navigator.pop(dialogContext),
                              icon: Icon(Icons.cancel_outlined,
                                  color: accentGrey),
                              label: Text(
                                'Cancelar',
                                style: TextStyle(
                                  color: accentGrey,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: secondaryOrange,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 3,
                              ),
                              icon: Icon(Icons.save_outlined, size: 20),
                              label: Text(
                                'Registrar Miembro',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onPressed: () async {
                                if (_formKey.currentState!.validate()) {
                                  // Obtener valores de los controladores
                                  nombre = _controllers['nombre']!.text;
                                  apellido = _controllers['apellido']!.text;
                                  telefono = _controllers['telefono']!.text;
                                  direccion = _controllers['direccion']!.text;
                                  barrio = _controllers['barrio']!.text;
                                  nombrePareja =
                                      _controllers['nombrePareja']!.text;
                                  descripcionOcupaciones =
                                      _controllers['descripcionOcupaciones']!
                                          .text;
                                  referenciaInvitacion =
                                      _controllers['referenciaInvitacion']!
                                          .text;
                                  observaciones =
                                      _controllers['observaciones']!.text;
                                  estadoProceso =
                                      _controllers['estadoProceso']!.text;
                                  edad = int.tryParse(
                                          _controllers['edad']!.text) ??
                                      0;

                                  final registro = {
                                    'fechaAsignacionTribu':
                                        fechaAsignacionTribu != null
                                            ? Timestamp.fromDate(
                                                fechaAsignacionTribu!)
                                            : null,
                                    'nombre': nombre,
                                    'apellido': apellido,
                                    'telefono': telefono,
                                    'sexo': sexo,
                                    'edad': edad,
                                    'direccion': direccion,
                                    'barrio': barrio,
                                    'estadoCivil': estadoCivil,
                                    'nombrePareja': nombrePareja,
                                    'ocupaciones': ocupacionesSeleccionadas,
                                    'descripcionOcupaciones':
                                        descripcionOcupaciones,
                                    'tieneHijos': tieneHijos,
                                    'referenciaInvitacion':
                                        referenciaInvitacion,
                                    'observaciones': observaciones,
                                    'tribuAsignada':
                                        tribuId, // ✅ AHORA GUARDA EL ID
                                    'nombreTribu':
                                        nombreTribu, // ✅ AGREGA EL NOMBRE POR SEPARADO
                                    'ministerioAsignado': ministerioAsignado,
                                    'coordinadorAsignado': coordinadorId,
                                    'fechaRegistro':
                                        FieldValue.serverTimestamp(),
                                    'activo': true,
                                    'tribuId':
                                        tribuId, // Este campo puede ser redundante ahora
                                    'categoria': categoriaTribu,

                                    'estadoProceso': estadoProceso,
                                  };

                                  await _guardarRegistroEnFirebase(
                                      dialogContext, registro, tribuId);
                                }
                              },
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
      },
    );
  }

  Widget _buildTextFieldWithController(
    String label,
    IconData icon,
    TextEditingController controller,
    Function(String) onChanged, {
    bool isRequired = true,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final primaryTeal = Color(0xFF038C7F);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        onChanged: onChanged,
        keyboardType: keyboardType,
        validator: isRequired
            ? (value) =>
                value == null || value.isEmpty ? 'Campo obligatorio' : null
            : null,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: primaryTeal.withOpacity(0.8),
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(icon, color: primaryTeal),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primaryTeal.withOpacity(0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primaryTeal.withOpacity(0.5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primaryTeal, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        style: TextStyle(fontSize: 16),
      ),
    );
  }

// Función para determinar el ministerio basado en el nombre de la tribu
  String _determinarMinisterio(String tribuNombre) {
    if (tribuNombre.contains('Juvenil')) return 'Ministerio Juvenil';
    if (tribuNombre.contains('Damas')) return 'Ministerio de Damas';
    if (tribuNombre.contains('Caballeros')) return 'Ministerio de Caballeros';
    return 'Otro';
  }

// Función para guardar registro en Firebase
  Future<void> _guardarRegistroEnFirebase(BuildContext context,
      Map<String, dynamic> registro, String tribuId) async {
    final primaryTeal = Color(0xFF038C7F);

    // Mostrar pantalla de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: primaryTeal),
              SizedBox(height: 16),
              Text(
                'Guardando registro...',
                style: TextStyle(
                  color: primaryTeal,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      await FirebaseFirestore.instance.collection('registros').add(registro);

      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // Cierra el loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Registro guardado correctamente'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: EdgeInsets.all(12),
            padding: EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            duration: Duration(seconds: 3),
          ),
        );
        Navigator.pop(context); // Cierra el diálogo del formulario
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // Cierra el loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text('Error al guardar el registro: $e'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: EdgeInsets.all(12),
            padding: EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

// Widget para títulos de sección
  Widget _buildSectionTitle(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

// Widget para campos de texto
  Widget _buildTextField(
    String label,
    IconData icon,
    Function(String) onChanged, {
    bool isRequired = true,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final primaryTeal = Color(0xFF038C7F);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        onChanged: onChanged,
        keyboardType: keyboardType,
        validator: isRequired
            ? (value) =>
                value == null || value.isEmpty ? 'Campo obligatorio' : null
            : null,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: primaryTeal.withOpacity(0.8),
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(icon, color: primaryTeal),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primaryTeal.withOpacity(0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primaryTeal.withOpacity(0.5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primaryTeal, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        style: TextStyle(fontSize: 16),
      ),
    );
  }

// Widget para dropdowns mejorado
  Widget _buildDropdown(
    String label,
    List<String> items,
    String? selectedValue,
    Function(String?) onChanged,
  ) {
    final primaryTeal = Color(0xFF038C7F);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: DropdownButtonFormField<String>(
        value: selectedValue,
        hint: Text(
          'Seleccionar $label',
          style: TextStyle(
            color: primaryTeal.withOpacity(0.6),
            fontWeight: FontWeight.w400,
          ),
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: primaryTeal.withOpacity(0.8),
            fontWeight: FontWeight.w500,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primaryTeal.withOpacity(0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primaryTeal.withOpacity(0.5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primaryTeal, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        items: items.map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          );
        }).toList(),
        onChanged: onChanged,
        validator: (value) => value == null || value.isEmpty
            ? 'Debe seleccionar una opción'
            : null,
        isExpanded: true,
        icon: Icon(
          Icons.arrow_drop_down,
          color: primaryTeal,
        ),
        style: TextStyle(
          fontSize: 16,
          color: Colors.black87,
        ),
        dropdownColor: Colors.white,
      ),
    );
  }

// Widgets auxiliares para el formulario de registro
  Widget _buildRegistroTextField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required Color primaryColor,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: primaryColor.withOpacity(0.8),
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(icon, color: primaryColor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primaryColor.withOpacity(0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primaryColor.withOpacity(0.5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primaryColor, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        style: TextStyle(fontSize: 16),
      ),
    );
  }

  Widget _buildRegistroDropdown({
    required String label,
    required IconData icon,
    required String value,
    required List<String> items,
    required Color primaryColor,
    required Function(String?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: primaryColor.withOpacity(0.5)),
          color: Colors.white,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          child: Row(
            children: [
              Icon(icon, color: primaryColor),
              SizedBox(width: 16),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: value,
                    icon: Icon(Icons.arrow_drop_down, color: primaryColor),
                    isExpanded: true,
                    onChanged: onChanged,
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 16,
                    ),
                    dropdownColor: Colors.white,
                    items: items.map<DropdownMenuItem<String>>((String item) {
                      return DropdownMenuItem<String>(
                        value: item,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(item),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Nueva clase Stateful para manejar el estado del buscador correctamente
class _PersonasAsignadasContent extends StatefulWidget {
  final String coordinadorId;
  final Color primaryTeal;
  final Color secondaryOrange;
  final Color accentGrey;
  final Color backgroundGrey;
  final Function(BuildContext, DocumentSnapshot) onEditarRegistro;
  final Function(BuildContext, Map<String, dynamic>) onMostrarDetalles;
  final Function(BuildContext) onRegistrarNuevo;
  final Function(BuildContext, DocumentSnapshot) onAsignarTimoteo;

  const _PersonasAsignadasContent({
    Key? key,
    required this.coordinadorId,
    required this.primaryTeal,
    required this.secondaryOrange,
    required this.accentGrey,
    required this.backgroundGrey,
    required this.onEditarRegistro,
    required this.onMostrarDetalles,
    required this.onRegistrarNuevo,
    required this.onAsignarTimoteo,
  }) : super(key: key);

  @override
  _PersonasAsignadasContentState createState() =>
      _PersonasAsignadasContentState();
}

class _PersonasAsignadasContentState extends State<_PersonasAsignadasContent> {
  // Controlador para el buscador
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isAsignadosExpanded = false;
  bool _isNoAsignadosExpanded = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Función para detectar si es un registro reciente
  bool esRegistroReciente(DocumentSnapshot doc) {
    try {
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) return false;

      DateTime? fechaMasReciente;

      final fechaAsignacionCoordinador = data['fechaAsignacionCoordinador'];
      if (fechaAsignacionCoordinador is Timestamp) {
        fechaMasReciente = fechaAsignacionCoordinador.toDate();
      }

      final fechaAsignacionTribu = data['fechaAsignacionTribu'];
      if (fechaAsignacionTribu is Timestamp) {
        DateTime fechaTribu = fechaAsignacionTribu.toDate();
        if (fechaMasReciente == null || fechaTribu.isAfter(fechaMasReciente)) {
          fechaMasReciente = fechaTribu;
        }
      }

      if (fechaMasReciente == null) return false;

      final diferenciaDias = DateTime.now().difference(fechaMasReciente).inDays;
      return diferenciaDias >= 0 && diferenciaDias <= 13;
    } catch (e) {
      print('Error en esRegistroReciente: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: widget.backgroundGrey,
      child: Stack(
        children: [
          // Contenido principal
          StreamBuilder(
            stream: FirebaseFirestore.instance
                .collection('registros')
                .where('coordinadorAsignado', isEqualTo: widget.coordinadorId)
                .snapshots(),
            builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
              // ✅ CAMBIO: Eliminamos el loading y mostramos contenido inmediatamente
              final List<QueryDocumentSnapshot> allDocs =
                  snapshot.hasData ? snapshot.data!.docs : [];

              // Si hay error, mostrar mensaje pero mantener UI funcional
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: Colors.red),
                      SizedBox(height: 16),
                      Text('Error al cargar datos'),
                      TextButton(
                        onPressed: () => setState(() {}),
                        child: Text('Reintentar'),
                      ),
                    ],
                  ),
                );
              }

              // Si no hay datos y no está cargando, mostrar mensaje vacío
              if (allDocs.isEmpty &&
                  snapshot.connectionState != ConnectionState.waiting) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_off,
                          size: 64, color: widget.accentGrey),
                      SizedBox(height: 16),
                      Text(
                        'No hay personas registradas',
                        style: TextStyle(
                          fontSize: 18,
                          color: widget.accentGrey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => widget.onRegistrarNuevo(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.primaryTeal,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                              horizontal: 24, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 3,
                        ),
                        icon: Icon(Icons.person_add, size: 20),
                        label: Text(
                          'Registrar Primer Miembro',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              // ✅ Procesar documentos (aunque esté cargando)
              String searchText = _searchQuery.toLowerCase();

              // Ordenar documentos
              allDocs.sort((a, b) {
                bool aEsReciente = esRegistroReciente(a);
                bool bEsReciente = esRegistroReciente(b);

                if (aEsReciente == bEsReciente) {
                  final dataA = a.data() as Map<String, dynamic>?;
                  final dataB = b.data() as Map<String, dynamic>?;

                  final fechaA =
                      (dataA?['fechaAsignacionCoordinador'] as Timestamp?)
                              ?.toDate() ??
                          DateTime(2000);
                  final fechaB =
                      (dataB?['fechaAsignacionCoordinador'] as Timestamp?)
                              ?.toDate() ??
                          DateTime(2000);

                  return fechaB.compareTo(fechaA);
                }

                return (bEsReciente ? 1 : 0) - (aEsReciente ? 1 : 0);
              });

              // Filtrar documentos según búsqueda
              var filteredDocs = searchText.isEmpty
                  ? allDocs
                  : allDocs.where((doc) {
                      try {
                        final nombre =
                            (doc.data() as Map<String, dynamic>?)?['nombre']
                                    ?.toString()
                                    .toLowerCase() ??
                                '';
                        final apellido =
                            (doc.data() as Map<String, dynamic>?)?['apellido']
                                    ?.toString()
                                    .toLowerCase() ??
                                '';
                        final nombreCompleto = '$nombre $apellido';
                        return nombreCompleto.contains(searchText);
                      } catch (e) {
                        return false;
                      }
                    }).toList();

              // Separar en asignados y no asignados
              final asignados = filteredDocs.where((doc) {
                try {
                  return doc.get('timoteoAsignado') != null;
                } catch (e) {
                  return false;
                }
              }).toList();

              final noAsignados = filteredDocs.where((doc) {
                try {
                  return doc.get('timoteoAsignado') == null;
                } catch (e) {
                  return true;
                }
              }).toList();

              final totalPersonasAsignadas = allDocs.length;
              final totalFiltrados = filteredDocs.length;

              return Column(
                children: [
                  // Buscador
                  Container(
                    margin: EdgeInsets.fromLTRB(16, 16, 16, 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                          if (value.isNotEmpty) {
                            _isAsignadosExpanded = true;
                            _isNoAsignadosExpanded = true;
                          }
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Buscar por nombre o apellido...',
                        prefixIcon:
                            Icon(Icons.search, color: widget.primaryTeal),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon:
                                    Icon(Icons.clear, color: widget.accentGrey),
                                onPressed: () {
                                  setState(() {
                                    _searchController.clear();
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),

                  // Badge de resultados
                  if (_searchQuery.isNotEmpty)
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: widget.primaryTeal.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.filter_alt_outlined,
                            size: 16,
                            color: widget.primaryTeal,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Mostrando $totalFiltrados de $totalPersonasAsignadas registros',
                            style: TextStyle(
                              color: widget.primaryTeal,
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Lista scrolleable
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(16),
                      physics: AlwaysScrollableScrollPhysics(),
                      child: Column(
                        children: [
                          // ✅ Mostrar indicador de carga sutil solo si está cargando y hay datos
                          if (snapshot.connectionState ==
                                  ConnectionState.waiting &&
                              allDocs.isNotEmpty)
                            Container(
                              padding: EdgeInsets.all(8),
                              margin: EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: widget.primaryTeal.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          widget.primaryTeal),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Actualizando...',
                                    style: TextStyle(
                                      color: widget.primaryTeal,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Contador de personas
                          if (allDocs.isNotEmpty)
                            _buildContadorPersonas(
                              totalPersonasAsignadas,
                              allDocs,
                            ),

                          // Personas por asignar
                          if (noAsignados.isNotEmpty) ...[
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isNoAsignadosExpanded =
                                      !_isNoAsignadosExpanded;
                                });
                              },
                              child: _buildExpandableHeader(
                                'Personas por asignar (${noAsignados.length})',
                                Icons.person_add_alt,
                                widget.secondaryOrange,
                                _isNoAsignadosExpanded,
                              ),
                            ),
                            if (_isNoAsignadosExpanded)
                              ...noAsignados
                                  .map((registro) => _buildPersonCard(
                                        context,
                                        registro,
                                        isAssigned: false,
                                        esReciente:
                                            esRegistroReciente(registro),
                                      ))
                                  .toList(),
                            SizedBox(height: 24),
                          ],

                          // Personas asignadas
                          if (asignados.isNotEmpty) ...[
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isAsignadosExpanded = !_isAsignadosExpanded;
                                });
                              },
                              child: _buildExpandableHeader(
                                'Personas asignadas (${asignados.length})',
                                Icons.people,
                                widget.primaryTeal,
                                _isAsignadosExpanded,
                              ),
                            ),
                            if (_isAsignadosExpanded)
                              ...asignados
                                  .map((registro) => _buildPersonCard(
                                        context,
                                        registro,
                                        isAssigned: true,
                                        esReciente:
                                            esRegistroReciente(registro),
                                      ))
                                  .toList(),
                          ],

                          SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // Botón flotante
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton.extended(
              onPressed: () => widget.onRegistrarNuevo(context),
              backgroundColor: widget.secondaryOrange,
              foregroundColor: Colors.white,
              elevation: 6,
              icon: Icon(Icons.person_add, size: 24),
              label: Text(
                'Registrar',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widgets auxiliares
  Widget _buildContadorPersonas(int total, List<DocumentSnapshot> docs) {
    final registrosRecientes =
        docs.where((doc) => esRegistroReciente(doc)).length;

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [widget.primaryTeal, widget.primaryTeal.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: widget.primaryTeal.withOpacity(0.2),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.people_alt_outlined,
              color: Colors.white,
              size: 28,
            ),
          ),
          SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total de Personas',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 4),
              Text(
                '$total',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildCounterBadge(
                'Asignados',
                docs.where((doc) {
                  try {
                    return doc.get('timoteoAsignado') != null;
                  } catch (e) {
                    return false;
                  }
                }).length,
                widget.primaryTeal,
                Colors.white,
              ),
              SizedBox(height: 8),
              _buildCounterBadge(
                'Por asignar',
                docs.where((doc) {
                  try {
                    return doc.get('timoteoAsignado') == null;
                  } catch (e) {
                    return true;
                  }
                }).length,
                widget.secondaryOrange,
                Colors.white,
              ),
              SizedBox(height: 8),
              AnimatedContainer(
                duration: Duration(milliseconds: 300),
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: registrosRecientes > 0
                      ? Colors.orange.withOpacity(0.3)
                      : Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: registrosRecientes > 0
                        ? Colors.orange.withOpacity(0.5)
                        : Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Nuevos',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                    SizedBox(width: 6),
                    Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: registrosRecientes > 0
                            ? Colors.orange.withOpacity(0.4)
                            : Colors.grey.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: registrosRecientes > 0
                          ? Icon(
                              Icons.new_releases,
                              color: Colors.white,
                              size: 12,
                            )
                          : Text(
                              '$registrosRecientes',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExpandableHeader(
    String title,
    IconData icon,
    Color color,
    bool isExpanded,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: isExpanded ? 16 : 8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Spacer(),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              title.contains('por asignar') ? 'Pendientes' : 'Activos',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(width: 8),
          Icon(
            isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
            color: color,
          ),
        ],
      ),
    );
  }

  Widget _buildCounterBadge(
      String label, int count, Color color, Color textColor) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: textColor.withOpacity(0.9),
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
          SizedBox(width: 6),
          Container(
            padding: EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Text(
              '$count',
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonCard(
    BuildContext context,
    DocumentSnapshot registro, {
    required bool isAssigned,
    required bool esReciente,
  }) {
    final data = registro.data() as Map<String, dynamic>;

    String obtenerTextoTiempo() {
      DateTime? fechaMasReciente;
      String tipoAsignacion = '';

      final fechaCoordinador =
          (data['fechaAsignacionCoordinador'] as Timestamp?)?.toDate();
      if (fechaCoordinador != null) {
        fechaMasReciente = fechaCoordinador;
        tipoAsignacion = 'coordinador';
      }

      final fechaTribu = (data['fechaAsignacionTribu'] as Timestamp?)?.toDate();
      if (fechaTribu != null) {
        if (fechaMasReciente == null || fechaTribu.isAfter(fechaMasReciente)) {
          fechaMasReciente = fechaTribu;
          tipoAsignacion = 'tribu';
        }
      }

      if (fechaMasReciente == null) return '';

      final diasTranscurridos =
          DateTime.now().difference(fechaMasReciente).inDays;
      final diasRestantes = 14 - diasTranscurridos;

      String accion = tipoAsignacion == 'coordinador'
          ? 'Asignado a coordinador'
          : 'Asignado a tribu';

      if (diasTranscurridos == 0) {
        return '$accion hoy';
      } else if (diasTranscurridos == 1) {
        return '$accion ayer';
      } else if (diasRestantes > 0) {
        return 'Hace $diasTranscurridos días (${diasRestantes}d restantes)';
      } else {
        return 'Hace $diasTranscurridos días';
      }
    }

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: esReciente
              ? [
                  Color(0xFFFF6B35).withOpacity(0.15),
                  Color(0xFFFF8C42).withOpacity(0.08),
                ]
              : [
                  Colors.white,
                  Colors.grey.shade50,
                ],
        ),
        border: Border.all(
          color: esReciente
              ? Color(0xFFFF6B35).withOpacity(0.4)
              : widget.primaryTeal.withOpacity(0.15),
          width: esReciente ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: esReciente
                ? Color(0xFFFF6B35).withOpacity(0.15)
                : widget.primaryTeal.withOpacity(0.08),
            blurRadius: esReciente ? 12 : 8,
            offset: Offset(0, esReciente ? 6 : 3),
            spreadRadius: esReciente ? 1 : 0,
          ),
        ],
      ),
      child: Stack(
        children: [
          if (esReciente)
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFF4757), Color(0xFFFF3838)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFFFF4757).withOpacity(0.3),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.fiber_new, color: Colors.white, size: 12),
                    SizedBox(width: 4),
                    Text(
                      'NUEVO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: esReciente
                              ? [Color(0xFFFF6B35), Color(0xFFFF8C42)]
                              : isAssigned
                                  ? [
                                      widget.primaryTeal,
                                      widget.primaryTeal.withOpacity(0.8)
                                    ]
                                  : [
                                      widget.secondaryOrange,
                                      widget.secondaryOrange.withOpacity(0.8)
                                    ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (esReciente
                                    ? Color(0xFFFF6B35)
                                    : isAssigned
                                        ? widget.primaryTeal
                                        : widget.secondaryOrange)
                                .withOpacity(0.3),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        backgroundColor: Colors.transparent,
                        radius: 28,
                        child: Text(
                          '${registro.get('nombre')[0]}${registro.get('apellido')[0]}',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${registro.get('nombre')} ${registro.get('apellido')}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: esReciente
                                  ? Color(0xFFFF6B35)
                                  : Colors.black87,
                            ),
                          ),
                          SizedBox(height: 6),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: (esReciente
                                      ? Color(0xFFFF6B35)
                                      : widget.primaryTeal)
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.phone,
                                  size: 14,
                                  color: esReciente
                                      ? Color(0xFFFF6B35)
                                      : widget.primaryTeal,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  registro.get('telefono'),
                                  style: TextStyle(
                                    color: esReciente
                                        ? Color(0xFFFF6B35)
                                        : widget.primaryTeal,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (esReciente)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.green.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.schedule,
                                      size: 12,
                                      color: Colors.green.shade700,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      obtenerTextoTiempo(),
                                      style: TextStyle(
                                        color: Colors.green.shade700,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (isAssigned) ...[
                  Container(
                    margin: EdgeInsets.symmetric(vertical: 16),
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          (esReciente ? Color(0xFFFF6B35) : widget.primaryTeal)
                              .withOpacity(0.3),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:
                          (esReciente ? Color(0xFFFF6B35) : widget.primaryTeal)
                              .withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: (esReciente
                                ? Color(0xFFFF6B35)
                                : widget.primaryTeal)
                            .withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 18,
                          color: esReciente
                              ? Color(0xFFFF6B35)
                              : widget.primaryTeal,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Asignado a: ',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            registro.get('nombreTimoteo'),
                            style: TextStyle(
                              color: esReciente
                                  ? Color(0xFFFF6B35)
                                  : widget.primaryTeal,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                SizedBox(height: 20),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildEnhancedActionButton(
                        icon: Icons.edit_outlined,
                        label: 'Editar',
                        color:
                            esReciente ? Color(0xFFFF6B35) : widget.accentGrey,
                        onPressed: () =>
                            widget.onEditarRegistro(context, registro),
                      ),
                      SizedBox(width: 10),
                      _buildEnhancedActionButton(
                        icon: Icons.visibility_outlined,
                        label: 'Ver',
                        color:
                            esReciente ? Color(0xFFFF6B35) : widget.primaryTeal,
                        onPressed: () => widget.onMostrarDetalles(
                          context,
                          registro.data() as Map<String, dynamic>,
                        ),
                      ),
                      SizedBox(width: 10),
                      if (!isAssigned)
                        _buildEnhancedActionButton(
                          icon: Icons.person_add,
                          label: 'Asignar',
                          color: widget.secondaryOrange,
                          onPressed: () =>
                              widget.onAsignarTimoteo(context, registro),
                        )
                      else
                        _buildEnhancedActionButton(
                          icon: Icons.person_remove,
                          label: 'Desasignar',
                          color: Colors.red.shade400,
                          onPressed: () async {
                            try {
                              await FirebaseFirestore.instance
                                  .collection('registros')
                                  .doc(registro.id)
                                  .update({
                                'timoteoAsignado': null,
                                'nombreTimoteo': null,
                                'fechaAsignacion': null,
                              });
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'Registro desasignado exitosamente'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'Error al desasignar el registro: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      SizedBox(width: 10),
                      Container(
                        decoration: BoxDecoration(
                          color: (esReciente
                                  ? Color(0xFFFF6B35)
                                  : widget.primaryTeal)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: (esReciente
                                    ? Color(0xFFFF6B35)
                                    : widget.primaryTeal)
                                .withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.copy,
                            color: esReciente
                                ? Color(0xFFFF6B35)
                                : widget.primaryTeal,
                            size: 20,
                          ),
                          tooltip: 'Copiar teléfono',
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(text: registro.get('telefono')),
                            );
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content:
                                      Text('Teléfono copiado al portapapeles'),
                                  duration: Duration(seconds: 1),
                                  backgroundColor: esReciente
                                      ? Color(0xFFFF6B35)
                                      : widget.primaryTeal,
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        icon: Icon(icon, size: 16),
        label: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 0,
        ),
        onPressed: onPressed,
      ),
    );
  }
}
