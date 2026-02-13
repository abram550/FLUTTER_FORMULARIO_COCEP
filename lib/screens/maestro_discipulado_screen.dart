import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:formulario_app/services/auth_service.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class MaestroDiscipuladoScreen extends StatefulWidget {
  final String maestroId;
  final String maestroNombre;
  final String? claseAsignadaId;

  const MaestroDiscipuladoScreen({
    Key? key,
    required this.maestroId,
    required this.maestroNombre,
    this.claseAsignadaId,
  }) : super(key: key);

  @override
  State<MaestroDiscipuladoScreen> createState() =>
      _MaestroDiscipuladoScreenState();
}

class _MaestroDiscipuladoScreenState extends State<MaestroDiscipuladoScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  final TextEditingController _searchController = TextEditingController();
  final ValueNotifier<String> _searchQueryNotifier = ValueNotifier<String>('');
  final ValueNotifier<bool> _isSearchActiveNotifier =
      ValueNotifier<bool>(false);

  // Colores COCEP
  static const Color cocepTeal = Color(0xFF1B7F7A);
  static const Color cocepOrange = Color(0xFFFF8C42);
  static const Color cocepYellow = Color(0xFFFFD166);
  static const Color cocepDarkTeal = Color(0xFF0D4C4A);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    _searchQueryNotifier.dispose();
    _isSearchActiveNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('maestrosDiscipulado')
          .doc(widget.maestroId)
          .snapshots(),
      builder: (context, maestroSnapshot) {
        if (maestroSnapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: cocepTeal),
            ),
          );
        }

        if (!maestroSnapshot.hasData || !maestroSnapshot.data!.exists) {
          return _buildSinClaseAsignada();
        }

        final maestroData =
            maestroSnapshot.data!.data() as Map<String, dynamic>;

        // ✅ CORRECCIÓN CRÍTICA: Obtener claseId del documento del maestro
        // Esto funciona tanto si viene del login como del departamento
        final claseActualId = maestroData['claseAsignadaId'];

        // ✅ Verificar que claseActualId existe y es válido
        if (claseActualId != null && claseActualId.toString().isNotEmpty) {
          // ✅ Verificar que la clase realmente existe en Firestore
          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('clasesDiscipulado')
                .doc(claseActualId)
                .snapshots(),
            builder: (context, claseSnapshot) {
              if (claseSnapshot.connectionState == ConnectionState.waiting) {
                return Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(color: cocepTeal),
                  ),
                );
              }

              // ✅ Si la clase no existe, mostrar sin clase
              if (!claseSnapshot.hasData || !claseSnapshot.data!.exists) {
                return _buildSinClaseAsignada();
              }

              // ✅ CRÍTICO: Pasar claseActualId a _buildClaseActiva
              return _buildClaseActiva(claseActualId);
            },
          );
        }

        // ✅ No tiene clase asignada
        return _buildSinClaseAsignada();
      },
    );
  }

  Widget _buildClaseActiva(String claseId) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('clasesDiscipulado')
          .doc(claseId)
          .snapshots(),
      builder: (context, claseSnapshot) {
        if (claseSnapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: cocepTeal),
            ),
          );
        }

        if (!claseSnapshot.hasData || !claseSnapshot.data!.exists) {
          return _buildSinClaseAsignada();
        }

        final claseData = claseSnapshot.data!.data() as Map<String, dynamic>;
        final tipoClase = claseData['tipo'] ?? 'Clase de Discipulado';
        final estado = claseData['estado'] ?? 'activa';

        // ✅ CORRECCIÓN: Mostrar modo solo lectura si está finalizada
        final estaFinalizada = estado == 'finalizada';

        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: _buildAppBar(tipoClase),
          body: Column(
            children: [
              // ✅ Banner si la clase está finalizada
              if (estaFinalizada)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green[700]!, Colors.green[600]!],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.3),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white, size: 28),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Clase Finalizada',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Estos son los registros finales de la clase',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // ✅ Pestaña 1: Tomar asistencia (o solo lectura si finalizada)
                    estaFinalizada
                        ? _buildTomarAsistenciaTabSoloLectura(claseData)
                        : _buildTomarAsistenciaTab(claseData),
                    // ✅ Pestaña 2: Ver asistencias (siempre disponible)
                    _buildVerAsistenciasTab(claseData),
                  ],
                ),
              ),
            ],
          ),
          // ✅ Botón finalizar solo si está activa
          floatingActionButton: estaFinalizada ? null : _buildFloatingButton(),
        );
      },
    );
  }

  Widget _buildTomarAsistenciaTabSoloLectura(Map<String, dynamic> claseData) {
    var discipulos =
        List<Map<String, dynamic>>.from(claseData['discipulosInscritos'] ?? []);

    discipulos.sort((a, b) {
      final nombreA = (a['nombre'] ?? '').toString().toLowerCase();
      final nombreB = (b['nombre'] ?? '').toString().toLowerCase();
      return nombreA.compareTo(nombreB);
    });

    return ListView(
      children: [
        _buildClassHeader(claseData),

        // ✅ Mensaje indicando solo lectura
        Container(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[700], size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'La clase ha finalizado. Los registros se mantienen para tu consulta.',
                  style: TextStyle(
                    color: Colors.blue[900],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),

        if (discipulos.isEmpty)
          Container(
            height: 300,
            child: _buildEmptyState(),
          )
        else
          Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 100),
            child: Column(
              children: discipulos
                  .map((discipulo) => _buildDiscipuloCard(discipulo))
                  .toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildSinClaseAsignada() {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: cocepTeal,
        title: Row(
          children: [
            Image.asset('assets/Cocep_.png', height: 32),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.maestroNombre,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: Center(
        child: Container(
          margin: EdgeInsets.all(24),
          padding: EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: cocepTeal.withOpacity(0.1),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cocepTeal.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.assignment_outlined,
                  size: 64,
                  color: cocepTeal,
                ),
              ),
              SizedBox(height: 24),
              Text(
                'Sin Clase Asignada',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: cocepDarkTeal,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12),
              Text(
                'No tienes una clase asignada actualmente.\nContacta al Departamento de Discipulado.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(String tipoClase) {
    return AppBar(
      elevation: 0,
      backgroundColor: cocepTeal,
      leading: Navigator.canPop(context)
          ? IconButton(
              icon: Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            )
          : null,
      title: Row(
        children: [
          Image.asset('assets/Cocep_.png', height: 32),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tipoClase,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  widget.maestroNombre,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w400,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        LayoutBuilder(
          builder: (context, constraints) {
// ✅ Detectar tamaño de pantalla
            final screenWidth = MediaQuery.of(context).size.width;
            final isVerySmall = screenWidth < 360; // Móviles muy pequeños
            final isSmall = screenWidth < 600; // Móviles normales
            final isMedium = screenWidth < 900; // Tablets
            return Container(
              margin: EdgeInsets.only(
                right: isVerySmall ? 4 : (isSmall ? 8 : 12),
              ),
              constraints: BoxConstraints(
                maxWidth: isVerySmall ? 100 : (isSmall ? 120 : 140),
              ),
              child: TextButton.icon(
                onPressed: () async {
                  // ✅ Mostrar diálogo de confirmación
                  final confirmar = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      title: Row(
                        children: [
                          Icon(Icons.logout_rounded,
                              color: cocepOrange, size: 24),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Cerrar Sesión',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      content: Text(
                        '¿Estás seguro de que deseas cerrar sesión?',
                        style: TextStyle(fontSize: 15, height: 1.5),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(
                            'Cancelar',
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: cocepOrange,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            'Cerrar Sesión',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  );

                  if (confirmar != true) return;

                  // ✅ CRÍTICO: Limpiar SharedPreferences
                  final authService = AuthService();
                  await authService.logout();

                  // ✅ Verificar limpieza
                  final stillAuth = await authService.isAuthenticated();
                  if (stillAuth) {
                    print(
                        '⚠️ ADVERTENCIA: Usuario todavía autenticado después de logout');
                  }

                  // ✅ Redirigir a login
                  if (mounted) {
                    context.go('/login');
                  }
                },
                icon: Icon(
                  Icons.logout_rounded,
                  color: Colors.white,
                  size: isVerySmall ? 16 : (isSmall ? 18 : 20),
                ),
                label: isVerySmall
                    ? Text(
                        'Cerrar\nSesión',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.visible,
                      )
                    : Text(
                        isSmall ? 'Cerrar\nSesión' : 'Cerrar Sesión',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isSmall ? 11 : 13,
                          fontWeight: FontWeight.w600,
                          height: isSmall ? 1.2 : 1.0,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: isSmall ? 2 : 1,
                        overflow: TextOverflow.visible,
                      ),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.15),
                  padding: EdgeInsets.symmetric(
                    horizontal: isVerySmall ? 6 : (isSmall ? 8 : 12),
                    vertical: isVerySmall ? 6 : (isSmall ? 8 : 10),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  minimumSize: Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            );
          },
        ),
      ],
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: Container(
          color: cocepDarkTeal,
          child: TabBar(
            controller: _tabController,
            indicatorColor: cocepYellow,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withOpacity(0.6),
            tabs: [
              Tab(
                icon: Icon(Icons.fact_check_outlined),
                child: Text(
                  'Asistencia',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
              Tab(
                icon: Icon(Icons.analytics_outlined),
                child: Text(
                  'Estadísticas',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClassHeader(Map<String, dynamic> claseData) {
    final totalModulos = claseData['totalModulos'] ?? 0;
    final discipulos =
        List<Map<String, dynamic>>.from(claseData['discipulosInscritos'] ?? []);
    final tipoClase = claseData['tipo'] ?? 'Clase de Discipulado';

    // ✅ Determinar si usar "Lección" o "Módulo"
    final usarLeccion = tipoClase == 'Discipulado 1' ||
        tipoClase == 'Discipulado 2' ||
        tipoClase == 'Discipulado 3' ||
        tipoClase == 'Consolidación';
    final nombreUnidad = usarLeccion ? 'Lecciones' : 'Módulos';

    // ✅ CORRECCIÓN CRÍTICA: Obtener el claseAsignadaId ACTUAL del maestro en tiempo real
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('maestrosDiscipulado')
          .doc(widget.maestroId)
          .snapshots(),
      builder: (context, maestroSnapshot) {
        // Si aún no hay datos del maestro
        if (!maestroSnapshot.hasData) {
          return _buildHeaderSkeleton(
              totalModulos, discipulos.length, nombreUnidad);
        }

        final maestroData =
            maestroSnapshot.data!.data() as Map<String, dynamic>?;

        // Si no existe el documento del maestro
        if (maestroData == null) {
          return _buildHeaderSkeleton(
              totalModulos, discipulos.length, nombreUnidad);
        }

        // ✅ CRÍTICO: Obtener el claseAsignadaId ACTUAL del maestro
        final claseActualId = maestroData['claseAsignadaId'];

        // Si no hay clase asignada
        if (claseActualId == null) {
          return _buildHeaderSkeleton(
              totalModulos, discipulos.length, nombreUnidad);
        }

        // ✅ SOLUCIÓN: Consultar asistencias SOLO de la clase ACTUAL
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('asistenciasDiscipulado')
              .where('claseId',
                  isEqualTo: claseActualId) // ✅ Filtrar por clase ACTUAL
              .snapshots(),
          builder: (context, asistenciasSnap) {
            int modulosCompletados = 0;

            // ✅ Contar módulos únicos SOLO de esta clase
            if (asistenciasSnap.hasData && asistenciasSnap.data != null) {
              modulosCompletados = asistenciasSnap.data!.docs
                  .map((doc) => (doc.data()
                      as Map<String, dynamic>)['numeroModulo'] as int)
                  .toSet()
                  .length;
            }

            double progreso =
                totalModulos > 0 ? modulosCompletados / totalModulos : 0;

            return Container(
              margin: EdgeInsets.fromLTRB(16, 16, 16, 0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [cocepTeal, cocepDarkTeal],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: cocepTeal.withOpacity(0.3),
                    blurRadius: 15,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    Positioned(
                      right: -30,
                      top: -30,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatCard(
                                icon: Icons.school_outlined,
                                label: nombreUnidad,
                                value: '$totalModulos',
                              ),
                              _buildStatCard(
                                icon: Icons.people_outline,
                                label: 'Discípulos',
                                value: '${discipulos.length}',
                              ),
                              _buildStatCard(
                                icon: Icons.check_circle_outline,
                                label: 'Hechos',
                                value: '$modulosCompletados',
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Progreso',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    '${(progreso * 100).toStringAsFixed(0)}%',
                                    style: TextStyle(
                                      color: cocepYellow,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: progreso,
                                  backgroundColor:
                                      Colors.white.withOpacity(0.3),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      cocepYellow),
                                  minHeight: 6,
                                ),
                              ),
                            ],
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

  Widget _buildHeaderSkeleton(
      int totalModulos, int totalDiscipulos, String nombreUnidad) {
    return Container(
      margin: EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cocepTeal, cocepDarkTeal],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: cocepTeal.withOpacity(0.3),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatCard(
                        icon: Icons.school_outlined,
                        label: nombreUnidad,
                        value: '$totalModulos',
                      ),
                      _buildStatCard(
                        icon: Icons.people_outline,
                        label: 'Discípulos',
                        value: '$totalDiscipulos',
                      ),
                      _buildStatCard(
                        icon: Icons.check_circle_outline,
                        label: 'Hechos',
                        value: '0',
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Progreso',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '0%',
                            style: TextStyle(
                              color: cocepYellow,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: 0,
                          backgroundColor: Colors.white.withOpacity(0.3),
                          valueColor:
                              AlwaysStoppedAnimation<Color>(cocepYellow),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Flexible(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        child: Column(
          children: [
            Icon(icon, color: cocepYellow, size: 22),
            SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return ValueListenableBuilder<bool>(
      valueListenable: _isSearchActiveNotifier,
      builder: (context, isActive, _) {
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Colors.grey[50]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: cocepTeal.withOpacity(0.15),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: isActive ? cocepTeal : Colors.grey[300]!,
              width: isActive ? 2 : 1,
            ),
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (value) {
              _searchQueryNotifier.value = value;
              _isSearchActiveNotifier.value = value.isNotEmpty;
            },
            decoration: InputDecoration(
              hintText: 'Buscar discípulo por nombre...',
              hintStyle: TextStyle(
                color: Colors.grey[400],
                fontSize: 15,
              ),
              prefixIcon: Container(
                padding: EdgeInsets.all(12),
                child: Icon(
                  Icons.search_rounded,
                  color: isActive ? cocepTeal : Colors.grey[400],
                  size: 24,
                ),
              ),
              suffixIcon: isActive
                  ? IconButton(
                      icon: Container(
                        padding: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: cocepTeal.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          color: cocepTeal,
                          size: 18,
                        ),
                      ),
                      onPressed: () {
                        _searchController.clear();
                        _searchQueryNotifier.value = '';
                        _isSearchActiveNotifier.value = false;
                      },
                      tooltip: 'Limpiar búsqueda',
                    )
                  : null,
              border: InputBorder.none,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            style: TextStyle(
              fontSize: 15,
              color: cocepDarkTeal,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      },
    );
  }

  Widget _buildTomarAsistenciaTab(Map<String, dynamic> claseData) {
    var discipulos =
        List<Map<String, dynamic>>.from(claseData['discipulosInscritos'] ?? []);
    discipulos.sort((a, b) {
      final nombreA = (a['nombre'] ?? '').toString().toLowerCase();
      final nombreB = (b['nombre'] ?? '').toString().toLowerCase();
      return nombreA.compareTo(nombreB);
    });

    return ListView(
      controller: _scrollController,
      children: [
        _buildClassHeader(claseData),

        // ✅ BOTONES DE ACCIÓN (SE MUEVEN CON EL SCROLL)
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _mostrarDialogoTomarAsistencia(discipulos),
                  icon: Icon(Icons.how_to_reg, size: 20),
                  label: Text(
                    'Registrar Asistencia',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cocepTeal,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                  ),
                ),
              ),
              SizedBox(width: 12),
              if (claseData['inscripcionesCerradas'] != true)
                ElevatedButton(
                  onPressed: () => _mostrarDialogoRegistrarDiscipulo(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cocepOrange,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                  ),
                  child: Icon(Icons.person_add, size: 24),
                ),
            ],
          ),
        ),

        // ✅ BARRA DE BÚSQUEDA (SE MUEVE CON EL SCROLL)
        _buildSearchBar(),

        // ✅ LISTA CON VALUELISTENABLEBUILDER (NO HACE REBUILD COMPLETO)
        ValueListenableBuilder<String>(
          valueListenable: _searchQueryNotifier,
          builder: (context, searchQuery, _) {
            // ✅ FILTRAR DISCÍPULOS
            List<Map<String, dynamic>> discipulosFiltrados = discipulos;
            if (searchQuery.isNotEmpty) {
              discipulosFiltrados = discipulos.where((discipulo) {
                final nombre = _normalizeText(discipulo['nombre'] ?? '');
                final query = _normalizeText(searchQuery);
                return nombre.contains(query);
              }).toList();
            }

            if (discipulosFiltrados.isEmpty) {
              return Container(
                height: 300,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: cocepOrange.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.search_off_rounded,
                          size: 64,
                          color: cocepOrange.withOpacity(0.5),
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No se encontraron resultados',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Intenta con otro término de búsqueda',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 100),
              child: Column(
                children: discipulosFiltrados
                    .map((discipulo) => _buildDiscipuloCard(discipulo))
                    .toList(),
              ),
            );
          },
        ),
      ],
    );
  }

  String _normalizeText(String text) {
    final withoutAccents = text
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('Á', 'a')
        .replaceAll('É', 'e')
        .replaceAll('Í', 'i')
        .replaceAll('Ó', 'o')
        .replaceAll('Ú', 'u')
        .replaceAll('ñ', 'n')
        .replaceAll('Ñ', 'n');
    return withoutAccents.toLowerCase();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cocepTeal.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.people_outline,
              size: 80,
              color: cocepTeal.withOpacity(0.5),
            ),
          ),
          SizedBox(height: 24),
          Text(
            'No hay discípulos registrados',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Presiona el botón + para agregar',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscipuloCard(Map<String, dynamic> discipulo) {
    final nombreTribu = discipulo['tribu']?.toString() ?? 'Sin tribu';
    final nombre = discipulo['nombre'] ?? 'Sin nombre';
    final telefono = discipulo['telefono'] ?? 'N/A';
    final inicial = nombre.isNotEmpty ? nombre[0].toUpperCase() : '?';

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {},
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [cocepTeal, cocepDarkTeal],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      inicial,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
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
                        nombre,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: cocepDarkTeal,
                        ),
                      ),
                      SizedBox(height: 8),
                      Wrap(
                        spacing: 16,
                        runSpacing: 6,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.phone_android,
                                  size: 14, color: Colors.grey[600]),
                              SizedBox(width: 4),
                              Text(
                                telefono,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[700],
                                ),
                              ),
                              if (telefono != 'N/A') ...[
                                SizedBox(width: 4),
                                InkWell(
                                  onTap: () {
                                    Clipboard.setData(
                                        ClipboardData(text: telefono));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Row(
                                          children: [
                                            Icon(Icons.check_circle,
                                                color: Colors.white, size: 18),
                                            SizedBox(width: 8),
                                            Text('Teléfono copiado'),
                                          ],
                                        ),
                                        backgroundColor: cocepTeal,
                                        behavior: SnackBarBehavior.floating,
                                        duration: Duration(seconds: 2),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: cocepTeal.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Icon(
                                      Icons.content_copy,
                                      size: 14,
                                      color: cocepTeal,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.group,
                                  size: 14, color: Colors.grey[600]),
                              SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  nombreTribu,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.church,
                                  size: 14, color: Colors.grey[600]),
                              SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  discipulo['ministerio'] ?? 'N/A',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // ✅ UN SOLO BOTÓN DE OPCIONES
                PopupMenuButton(
                  icon: Icon(Icons.more_vert, color: cocepTeal),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 20, color: cocepTeal),
                          SizedBox(width: 8),
                          Text('Editar'),
                        ],
                      ),
                      onTap: () => Future.delayed(
                        Duration.zero,
                        () => _editarDiscipulo(discipulo),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _mostrarDialogoRegistrarDiscipulo() {
    final formKey = GlobalKey<FormState>();
    final nombreController = TextEditingController();
    final telefonoController = TextEditingController();
    final tribuController = TextEditingController();
    String? ministerioSeleccionado;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: StatefulBuilder(
          builder: (context, setDialogState) => LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 500,
                    minHeight: 100,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [cocepTeal, cocepDarkTeal],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.person_add,
                                  color: Colors.white, size: 24),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Registrar Discípulo',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Flexible(
                          child: SingleChildScrollView(
                            padding: EdgeInsets.all(16),
                            child: Form(
                              key: formKey,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextFormField(
                                    controller: nombreController,
                                    decoration: InputDecoration(
                                      labelText: 'Nombre Completo',
                                      prefixIcon:
                                          Icon(Icons.person, color: cocepTeal),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                            color: cocepTeal, width: 2),
                                      ),
                                    ),
                                    validator: (value) => value?.isEmpty ?? true
                                        ? 'Campo requerido'
                                        : null,
                                  ),
                                  SizedBox(height: 12),
                                  TextFormField(
                                    controller: telefonoController,
                                    decoration: InputDecoration(
                                      labelText: 'Teléfono',
                                      prefixIcon: Icon(Icons.phone_android,
                                          color: cocepTeal),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                            color: cocepTeal, width: 2),
                                      ),
                                    ),
                                    keyboardType: TextInputType.phone,
                                    validator: (value) => value?.isEmpty ?? true
                                        ? 'Campo requerido'
                                        : null,
                                  ),
                                  SizedBox(height: 12),
                                  TextFormField(
                                    controller: tribuController,
                                    decoration: InputDecoration(
                                      labelText: 'Tribu',
                                      prefixIcon:
                                          Icon(Icons.group, color: cocepTeal),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                            color: cocepTeal, width: 2),
                                      ),
                                    ),
                                    validator: (value) => value?.isEmpty ?? true
                                        ? 'Campo requerido'
                                        : null,
                                  ),
                                  SizedBox(height: 12),
                                  DropdownButtonFormField<String>(
                                    decoration: InputDecoration(
                                      labelText: 'Ministerio',
                                      prefixIcon:
                                          Icon(Icons.church, color: cocepTeal),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                            color: cocepTeal, width: 2),
                                      ),
                                    ),
                                    items: [
                                      'Ministerio De Caballeros',
                                      'Ministerio De Damas',
                                      'Ministerio Juvenil'
                                    ].map((ministerio) {
                                      return DropdownMenuItem(
                                        value: ministerio,
                                        child: Text(ministerio,
                                            overflow: TextOverflow.ellipsis),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setDialogState(() {
                                        ministerioSeleccionado = value;
                                      });
                                    },
                                    validator: (value) => value == null
                                        ? 'Selecciona un ministerio'
                                        : null,
                                  ),
                                  SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: Text('Cancelar',
                                              style: TextStyle(
                                                  color: Colors.grey[700])),
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () async {
                                            if (formKey.currentState!
                                                .validate()) {
                                              try {
                                                // ✅ CORRECCIÓN: Obtener claseAsignadaId del maestro en tiempo real
                                                final maestroDoc =
                                                    await FirebaseFirestore
                                                        .instance
                                                        .collection(
                                                            'maestrosDiscipulado')
                                                        .doc(widget.maestroId)
                                                        .get();

                                                if (!maestroDoc.exists) {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                          'Error: No se encontró el maestro'),
                                                      backgroundColor:
                                                          Colors.red,
                                                    ),
                                                  );
                                                  return;
                                                }

                                                final maestroData =
                                                    maestroDoc.data()
                                                        as Map<String, dynamic>;
                                                final claseAsignadaId =
                                                    maestroData[
                                                        'claseAsignadaId'];

                                                // ✅ Verificar que tiene clase asignada
                                                if (claseAsignadaId == null) {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                          'No hay clase asignada actualmente'),
                                                      backgroundColor:
                                                          Colors.red,
                                                    ),
                                                  );
                                                  return;
                                                }

                                                // ✅ Verificar que la clase existe y está activa
                                                final claseDoc =
                                                    await FirebaseFirestore
                                                        .instance
                                                        .collection(
                                                            'clasesDiscipulado')
                                                        .doc(claseAsignadaId)
                                                        .get();

                                                if (!claseDoc.exists) {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                          'La clase no existe o fue eliminada'),
                                                      backgroundColor:
                                                          Colors.red,
                                                    ),
                                                  );
                                                  return;
                                                }

                                                final claseData =
                                                    claseDoc.data();
                                                if (claseData == null) {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                          'Error al leer datos de la clase'),
                                                      backgroundColor:
                                                          Colors.red,
                                                    ),
                                                  );
                                                  return;
                                                }

                                                // ✅ Verificar que la clase esté activa
                                                if (claseData['estado'] !=
                                                    'activa') {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                          'La clase ya fue finalizada'),
                                                      backgroundColor:
                                                          Colors.orange,
                                                    ),
                                                  );
                                                  return;
                                                }

                                                // ✅ Obtener lista de discípulos actual
                                                final discipulos = List<
                                                        Map<String,
                                                            dynamic>>.from(
                                                    claseData[
                                                            'discipulosInscritos'] ??
                                                        []);

                                                // ✅ Generar ID único
                                                final personaId =
                                                    'maestro_${DateTime.now().millisecondsSinceEpoch}';

                                                // ✅ Agregar nuevo discípulo
                                                discipulos.add({
                                                  'personaId': personaId,
                                                  'nombre': nombreController
                                                      .text
                                                      .trim(),
                                                  'telefono': telefonoController
                                                      .text
                                                      .trim(),
                                                  'tribu': tribuController.text
                                                      .trim(),
                                                  'ministerio':
                                                      ministerioSeleccionado,
                                                  'registradoPorMaestro': true,
                                                });

                                                // ✅ Actualizar Firestore con el claseAsignadaId correcto
                                                await FirebaseFirestore.instance
                                                    .collection(
                                                        'clasesDiscipulado')
                                                    .doc(claseAsignadaId)
                                                    .update({
                                                  'discipulosInscritos':
                                                      discipulos,
                                                });

                                                Navigator.pop(context);
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                    content: Row(
                                                      children: [
                                                        Icon(Icons.check_circle,
                                                            color:
                                                                Colors.white),
                                                        SizedBox(width: 12),
                                                        Flexible(
                                                            child: Text(
                                                                'Discípulo registrado exitosamente')),
                                                      ],
                                                    ),
                                                    backgroundColor:
                                                        Colors.green,
                                                    behavior: SnackBarBehavior
                                                        .floating,
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10),
                                                    ),
                                                  ),
                                                );
                                              } catch (e) {
                                                Navigator.pop(context);
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                        'Error al registrar discípulo: $e'),
                                                    backgroundColor: Colors.red,
                                                  ),
                                                );
                                              }
                                            }
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: cocepTeal,
                                            padding: EdgeInsets.symmetric(
                                                vertical: 14),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                          child: Text(
                                            'Registrar',
                                            style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _editarDiscipulo(Map<String, dynamic> discipulo) async {
    final formKey = GlobalKey<FormState>();
    final nombreController = TextEditingController(text: discipulo['nombre']);
    final telefonoController =
        TextEditingController(text: discipulo['telefono']);
    final tribuController = TextEditingController(text: discipulo['tribu']);
    String? ministerioSeleccionado = discipulo['ministerio'];

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: StatefulBuilder(
          builder: (context, setDialogState) => LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 500,
                    minHeight: 100,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [cocepOrange, Color(0xFFE67635)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.edit, color: Colors.white, size: 24),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Editar Discípulo',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Flexible(
                          child: SingleChildScrollView(
                            padding: EdgeInsets.all(16),
                            child: Form(
                              key: formKey,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextFormField(
                                    controller: nombreController,
                                    decoration: InputDecoration(
                                      labelText: 'Nombre Completo',
                                      prefixIcon: Icon(Icons.person,
                                          color: cocepOrange),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                            color: cocepOrange, width: 2),
                                      ),
                                    ),
                                    validator: (value) => value?.isEmpty ?? true
                                        ? 'Campo requerido'
                                        : null,
                                  ),
                                  SizedBox(height: 12),
                                  TextFormField(
                                    controller: telefonoController,
                                    decoration: InputDecoration(
                                      labelText: 'Teléfono',
                                      prefixIcon: Icon(Icons.phone_android,
                                          color: cocepOrange),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                            color: cocepOrange, width: 2),
                                      ),
                                    ),
                                    keyboardType: TextInputType.phone,
                                    validator: (value) => value?.isEmpty ?? true
                                        ? 'Campo requerido'
                                        : null,
                                  ),
                                  SizedBox(height: 12),
                                  TextFormField(
                                    controller: tribuController,
                                    decoration: InputDecoration(
                                      labelText: 'Tribu',
                                      prefixIcon:
                                          Icon(Icons.group, color: cocepOrange),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                            color: cocepOrange, width: 2),
                                      ),
                                    ),
                                    validator: (value) => value?.isEmpty ?? true
                                        ? 'Campo requerido'
                                        : null,
                                  ),
                                  SizedBox(height: 12),
                                  DropdownButtonFormField<String>(
                                    value: ministerioSeleccionado,
                                    decoration: InputDecoration(
                                      labelText: 'Ministerio',
                                      prefixIcon: Icon(Icons.church,
                                          color: cocepOrange),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                            color: cocepOrange, width: 2),
                                      ),
                                    ),
                                    items: [
                                      'Ministerio De Caballeros',
                                      'Ministerio De Damas',
                                      'Ministerio Juvenil'
                                    ].map((ministerio) {
                                      return DropdownMenuItem(
                                        value: ministerio,
                                        child: Text(ministerio,
                                            overflow: TextOverflow.ellipsis),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setDialogState(() {
                                        ministerioSeleccionado = value;
                                      });
                                    },
                                    validator: (value) => value == null
                                        ? 'Selecciona un ministerio'
                                        : null,
                                  ),
                                  SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: Text('Cancelar',
                                              style: TextStyle(
                                                  color: Colors.grey[700])),
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () async {
                                            if (formKey.currentState!
                                                .validate()) {
                                              try {
                                                // ✅ CRÍTICO: Obtener claseAsignadaId ACTUAL del maestro
                                                final maestroDoc =
                                                    await FirebaseFirestore
                                                        .instance
                                                        .collection(
                                                            'maestrosDiscipulado')
                                                        .doc(widget.maestroId)
                                                        .get();

                                                if (!maestroDoc.exists) {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                          'Error: No se encontró el maestro'),
                                                      backgroundColor:
                                                          Colors.red,
                                                    ),
                                                  );
                                                  return;
                                                }

                                                final maestroData =
                                                    maestroDoc.data()
                                                        as Map<String, dynamic>;
                                                final claseAsignadaIdActual =
                                                    maestroData[
                                                        'claseAsignadaId'];

                                                if (claseAsignadaIdActual ==
                                                    null) {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                          'No hay clase asignada actualmente'),
                                                      backgroundColor:
                                                          Colors.red,
                                                    ),
                                                  );
                                                  return;
                                                }

                                                // ✅ Obtener datos de la clase ACTUAL
                                                final claseDoc =
                                                    await FirebaseFirestore
                                                        .instance
                                                        .collection(
                                                            'clasesDiscipulado')
                                                        .doc(
                                                            claseAsignadaIdActual)
                                                        .get();

                                                if (!claseDoc.exists) {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                          'La clase no existe'),
                                                      backgroundColor:
                                                          Colors.red,
                                                    ),
                                                  );
                                                  return;
                                                }

                                                final claseData =
                                                    claseDoc.data()
                                                        as Map<String, dynamic>;
                                                final discipulos = List<
                                                        Map<String,
                                                            dynamic>>.from(
                                                    claseData[
                                                            'discipulosInscritos'] ??
                                                        []);

                                                final index =
                                                    discipulos.indexWhere((d) =>
                                                        d['personaId'] ==
                                                        discipulo['personaId']);

                                                if (index != -1) {
                                                  // ✅ CRÍTICO: Mantener TODOS los campos originales
                                                  final discipuloActualizado = {
                                                    'personaId': discipulo[
                                                        'personaId'], // ✅ MANTENER ID ORIGINAL
                                                    'nombre': nombreController
                                                        .text
                                                        .trim(),
                                                    'telefono':
                                                        telefonoController.text
                                                            .trim(),
                                                    'tribu': tribuController
                                                        .text
                                                        .trim(),
                                                    'tribuId': discipulo[
                                                        'tribuId'], // ✅ MANTENER tribuId ORIGINAL
                                                    'ministerio':
                                                        ministerioSeleccionado,
                                                    'registradoPorMaestro': discipulo[
                                                            'registradoPorMaestro'] ??
                                                        false, // ✅ MANTENER origen
                                                    'fechaInscripcion': discipulo[
                                                        'fechaInscripcion'], // ✅ MANTENER fecha original
                                                  };

                                                  discipulos[index] =
                                                      discipuloActualizado;

                                                  await FirebaseFirestore
                                                      .instance
                                                      .collection(
                                                          'clasesDiscipulado')
                                                      .doc(
                                                          claseAsignadaIdActual)
                                                      .update({
                                                    'discipulosInscritos':
                                                        discipulos,
                                                  });

                                                  Navigator.pop(context);
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    SnackBar(
                                                      content: Row(
                                                        children: [
                                                          Icon(
                                                              Icons
                                                                  .check_circle,
                                                              color:
                                                                  Colors.white),
                                                          SizedBox(width: 12),
                                                          Flexible(
                                                              child: Text(
                                                                  'Discípulo actualizado')),
                                                        ],
                                                      ),
                                                      backgroundColor:
                                                          Colors.green,
                                                      behavior: SnackBarBehavior
                                                          .floating,
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(10),
                                                      ),
                                                    ),
                                                  );
                                                }
                                              } catch (e) {
                                                Navigator.pop(context);
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                        'Error al actualizar: $e'),
                                                    backgroundColor: Colors.red,
                                                  ),
                                                );
                                              }
                                            }
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: cocepOrange,
                                            padding: EdgeInsets.symmetric(
                                                vertical: 14),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                          child: Text(
                                            'Actualizar',
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _mostrarDialogoTomarAsistencia(
      List<Map<String, dynamic>> discipulos) async {
    int? numeroModulo;
    DateTime fechaSeleccionada = DateTime.now();
    Map<String, bool> asistencias = {
      for (var d in discipulos) d['personaId']: true
    };
// ✅ CORRECCIÓN CRÍTICA: Obtener claseAsignadaId ACTUAL del maestro en tiempo real
    final maestroDoc = await FirebaseFirestore.instance
        .collection('maestrosDiscipulado')
        .doc(widget.maestroId)
        .get();
    if (!maestroDoc.exists) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: No se encontró el maestro'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    final maestroData = maestroDoc.data() as Map<String, dynamic>;
    final claseAsignadaId = maestroData['claseAsignadaId'];
    if (claseAsignadaId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No hay clase asignada actualmente'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
// ✅ Ahora obtener la clase con el ID correcto
    final claseDoc = await FirebaseFirestore.instance
        .collection('clasesDiscipulado')
        .doc(claseAsignadaId)
        .get();
    if (!claseDoc.exists) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: La clase no existe'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    final claseData = claseDoc.data();
    if (claseData == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Error: No se pudieron obtener los datos de la clase'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    final totalModulos = claseData['totalModulos'] as int;
    final tipoClase = claseData['tipo'] ?? 'Clase de Discipulado';
// ✅ Determinar si usar "Lección" o "Módulo"
    final usarLeccion = tipoClase == 'Discipulado 1' ||
        tipoClase == 'Discipulado 2' ||
        tipoClase == 'Discipulado 3' ||
        tipoClase == 'Consolidación';
    final nombreUnidad = usarLeccion ? 'Lección' : 'Módulo';
// ✅ Obtener módulo inicial permitido (por defecto 1)
    final moduloInicialPermitido =
        claseData['moduloInicialPermitido'] as int? ?? 1;
// ✅ CORRECCIÓN: Obtener asistencias SOLO de la clase ACTUAL
    final asistenciasRegistradas = await FirebaseFirestore.instance
        .collection('asistenciasDiscipulado')
        .where('claseId',
            isEqualTo: claseAsignadaId) // ✅ Usar claseAsignadaId ACTUAL
        .get();
    Set<int> modulosYaRegistrados = {};
    for (var doc in asistenciasRegistradas.docs) {
      final data = doc.data();
      modulosYaRegistrados.add(data['numeroModulo'] as int);
    }
// ✅ Calcular siguiente módulo considerando el inicial permitido
    int siguienteModulo = moduloInicialPermitido;
    while (modulosYaRegistrados.contains(siguienteModulo) &&
        siguienteModulo <= totalModulos) {
      siguienteModulo++;
    }
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 20),
        child: StatefulBuilder(
          builder: (context, setDialogState) => LayoutBuilder(
            builder: (context, constraints) {
              final screenWidth = MediaQuery.of(context).size.width;
              final isSmallScreen = screenWidth < 600;
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 600,
                    minHeight: 100,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 12 : 20,
                            vertical: isSmallScreen ? 12 : 16,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [cocepTeal, cocepDarkTeal],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.how_to_reg,
                                  color: Colors.white,
                                  size: isSmallScreen ? 22 : 28),
                              SizedBox(width: isSmallScreen ? 8 : 12),
                              Expanded(
                                child: Text(
                                  'Registrar Asistencia',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 16 : 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Flexible(
                          child: SingleChildScrollView(
                            padding: EdgeInsets.all(isSmallScreen ? 12 : 20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // ✅ Indicador visual del módulo inicial
                                if (moduloInicialPermitido > 1)
                                  Container(
                                    margin: EdgeInsets.only(bottom: 16),
                                    padding: EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.blue[50]!,
                                          Colors.blue[100]!,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.blue[300]!,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.info_outline,
                                            color: Colors.blue[700], size: 20),
                                        SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            'Clase en progreso: Iniciando desde $nombreUnidad $moduloInicialPermitido',
                                            style: TextStyle(
                                              color: Colors.blue[900],
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                DropdownButtonFormField<int>(
                                  decoration: InputDecoration(
                                    labelText: nombreUnidad,
                                    helperText:
                                        'Siguiente: $nombreUnidad $siguienteModulo',
                                    helperStyle: TextStyle(
                                      color: cocepTeal,
                                      fontWeight: FontWeight.w600,
                                      fontSize: isSmallScreen ? 11 : 12,
                                    ),
                                    prefixIcon: Icon(Icons.bookmark,
                                        color: cocepTeal,
                                        size: isSmallScreen ? 20 : 24),
                                    border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                          color: cocepTeal, width: 2),
                                    ),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: isSmallScreen ? 8 : 12,
                                      vertical: isSmallScreen ? 12 : 16,
                                    ),
                                  ),
                                  value: numeroModulo,
                                  isExpanded: true,
                                  items: List.generate(
                                    totalModulos - moduloInicialPermitido + 1,
                                    (index) {
                                      final modulo =
                                          moduloInicialPermitido + index;
                                      final yaRegistrado =
                                          modulosYaRegistrados.contains(modulo);
                                      final puedeSeleccionar =
                                          modulo == siguienteModulo;
                                      return DropdownMenuItem<int>(
                                        value: modulo,
                                        enabled: puedeSeleccionar,
                                        child: Text(
                                          '$nombreUnidad $modulo${yaRegistrado ? " ✓" : ""}',
                                          style: TextStyle(
                                            color: yaRegistrado
                                                ? Colors.grey
                                                : puedeSeleccionar
                                                    ? cocepDarkTeal
                                                    : Colors.orange,
                                            fontWeight:
                                                modulo == siguienteModulo
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                            fontSize: isSmallScreen ? 13 : 14,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      );
                                    },
                                  ).toList(),
                                  onChanged: (value) {
                                    setDialogState(() {
                                      numeroModulo = value;
                                    });
                                  },
                                ),
                                SizedBox(height: isSmallScreen ? 12 : 16),
                                InkWell(
                                  onTap: () async {
                                    final fecha = await showDatePicker(
                                      context: context,
                                      initialDate: fechaSeleccionada,
                                      firstDate: DateTime.now()
                                          .subtract(Duration(days: 365)),
                                      lastDate: DateTime.now(),
                                      builder: (context, child) {
                                        return Theme(
                                          data: Theme.of(context).copyWith(
                                            colorScheme: ColorScheme.light(
                                              primary: cocepTeal,
                                              onPrimary: Colors.white,
                                              surface: Colors.white,
                                              onSurface: cocepDarkTeal,
                                            ),
                                          ),
                                          child: child!,
                                        );
                                      },
                                    );
                                    if (fecha != null) {
                                      setDialogState(() {
                                        fechaSeleccionada = fecha;
                                      });
                                    }
                                  },
                                  child: InputDecorator(
                                    decoration: InputDecoration(
                                      labelText: 'Fecha',
                                      prefixIcon: Icon(Icons.calendar_today,
                                          color: cocepTeal,
                                          size: isSmallScreen ? 20 : 24),
                                      border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                            color: cocepTeal, width: 2),
                                      ),
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: isSmallScreen ? 8 : 12,
                                        vertical: isSmallScreen ? 12 : 16,
                                      ),
                                    ),
                                    child: Text(
                                      DateFormat('dd/MM/yyyy')
                                          .format(fechaSeleccionada),
                                      style: TextStyle(
                                          fontSize: isSmallScreen ? 14 : 16),
                                    ),
                                  ),
                                ),
                                SizedBox(height: isSmallScreen ? 12 : 20),
                                Container(
                                  padding:
                                      EdgeInsets.all(isSmallScreen ? 12 : 16),
                                  decoration: BoxDecoration(
                                    color: cocepTeal.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: cocepTeal.withOpacity(0.2),
                                        width: 1),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Wrap(
                                        alignment: WrapAlignment.spaceBetween,
                                        crossAxisAlignment:
                                            WrapCrossAlignment.center,
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          Text(
                                            'Marcar Asistencias',
                                            style: TextStyle(
                                              fontSize: isSmallScreen ? 14 : 16,
                                              fontWeight: FontWeight.bold,
                                              color: cocepDarkTeal,
                                            ),
                                          ),
                                          Wrap(
                                            spacing: 4,
                                            runSpacing: 4,
                                            children: [
                                              TextButton.icon(
                                                onPressed: () {
                                                  setDialogState(() {
                                                    asistencias.updateAll(
                                                        (key, value) => true);
                                                  });
                                                },
                                                icon: Icon(Icons.check_circle,
                                                    size:
                                                        isSmallScreen ? 14 : 16,
                                                    color: Colors.green),
                                                label: Text('Todos',
                                                    style: TextStyle(
                                                        color: Colors.green,
                                                        fontSize: isSmallScreen
                                                            ? 12
                                                            : 14)),
                                                style: TextButton.styleFrom(
                                                  padding: EdgeInsets.symmetric(
                                                      horizontal: isSmallScreen
                                                          ? 8
                                                          : 12,
                                                      vertical: 4),
                                                  minimumSize: Size(0, 0),
                                                  tapTargetSize:
                                                      MaterialTapTargetSize
                                                          .shrinkWrap,
                                                ),
                                              ),
                                              TextButton.icon(
                                                onPressed: () {
                                                  setDialogState(() {
                                                    asistencias.updateAll(
                                                        (key, value) => false);
                                                  });
                                                },
                                                icon: Icon(Icons.cancel,
                                                    size:
                                                        isSmallScreen ? 14 : 16,
                                                    color: Colors.red),
                                                label: Text('Ninguno',
                                                    style: TextStyle(
                                                        color: Colors.red,
                                                        fontSize: isSmallScreen
                                                            ? 12
                                                            : 14)),
                                                style: TextButton.styleFrom(
                                                  padding: EdgeInsets.symmetric(
                                                      horizontal: isSmallScreen
                                                          ? 8
                                                          : 12,
                                                      vertical: 4),
                                                  minimumSize: Size(0, 0),
                                                  tapTargetSize:
                                                      MaterialTapTargetSize
                                                          .shrinkWrap,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: isSmallScreen ? 8 : 12),
                                      ...discipulos.map((discipulo) {
                                        final personaId =
                                            discipulo['personaId'];
                                        final asistio =
                                            asistencias[personaId] ?? true;
                                        return Container(
                                          margin: EdgeInsets.only(bottom: 6),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            border: Border.all(
                                              color: asistio
                                                  ? Colors.green
                                                      .withOpacity(0.3)
                                                  : Colors.red.withOpacity(0.3),
                                              width: 1,
                                            ),
                                          ),
                                          child: CheckboxListTile(
                                            dense: isSmallScreen,
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                              horizontal:
                                                  isSmallScreen ? 8 : 12,
                                              vertical: isSmallScreen ? 0 : 4,
                                            ),
                                            title: Text(
                                              discipulo['nombre'] ??
                                                  'Sin nombre',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: cocepDarkTeal,
                                                fontSize:
                                                    isSmallScreen ? 13 : 14,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            subtitle: Text(
                                              discipulo['telefono'] ?? 'N/A',
                                              style: TextStyle(
                                                  fontSize:
                                                      isSmallScreen ? 11 : 12),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            value: asistio,
                                            activeColor: Colors.green,
                                            checkColor: Colors.white,
                                            onChanged: (value) {
                                              setDialogState(() {
                                                asistencias[personaId] =
                                                    value ?? false;
                                              });
                                            },
                                            secondary: CircleAvatar(
                                              radius: isSmallScreen ? 16 : 20,
                                              backgroundColor: asistio
                                                  ? Colors.green
                                                      .withOpacity(0.2)
                                                  : Colors.red.withOpacity(0.2),
                                              child: Icon(
                                                asistio
                                                    ? Icons.check
                                                    : Icons.close,
                                                color: asistio
                                                    ? Colors.green
                                                    : Colors.red,
                                                size: isSmallScreen ? 16 : 20,
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(20),
                              bottomRight: Radius.circular(20),
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isSmallScreen) ...[
                                SizedBox(
                                  width: double.infinity,
                                  child: TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text('Cancelar',
                                        style: TextStyle(
                                            color: Colors.grey[700],
                                            fontSize: 14)),
                                  ),
                                ),
                                SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () async {
                                      if (numeroModulo == null) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                'Selecciona el número de $nombreUnidad'),
                                            backgroundColor: Colors.orange,
                                          ),
                                        );
                                        return;
                                      }

                                      // ✅ PROTECCIÓN ANTI-DUPLICADOS: Verificar que no existan registros previos
                                      try {
                                        for (var discipulo in discipulos) {
                                          final personaId =
                                              discipulo['personaId'];

                                          // ✅ Verificar si ya existe un registro para este discípulo + módulo + clase
                                          final registrosExistentes =
                                              await FirebaseFirestore.instance
                                                  .collection(
                                                      'asistenciasDiscipulado')
                                                  .where('claseId',
                                                      isEqualTo:
                                                          claseAsignadaId)
                                                  .where('discipuloId',
                                                      isEqualTo: personaId)
                                                  .where('numeroModulo',
                                                      isEqualTo: numeroModulo)
                                                  .get();

                                          // ✅ Si ya existe, saltar este discípulo
                                          if (registrosExistentes
                                              .docs.isNotEmpty) {
                                            continue;
                                          }

                                          // ✅ Si no existe, crear el registro
                                          final asistio =
                                              asistencias[personaId] ?? false;
                                          await FirebaseFirestore.instance
                                              .collection(
                                                  'asistenciasDiscipulado')
                                              .add({
                                            'claseId': claseAsignadaId,
                                            'discipuloId': personaId,
                                            'discipuloNombre':
                                                discipulo['nombre'],
                                            'numeroModulo': numeroModulo,
                                            'asistio': asistio,
                                            'fecha': Timestamp.fromDate(
                                                fechaSeleccionada),
                                            'maestroId': widget.maestroId,
                                            'recuperado': false,
                                          });
                                        }

                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Row(
                                              children: [
                                                Icon(Icons.check_circle,
                                                    color: Colors.white),
                                                SizedBox(width: 12),
                                                Flexible(
                                                  child: Text(
                                                      'Asistencia de $nombreUnidad $numeroModulo registrada'),
                                                ),
                                              ],
                                            ),
                                            backgroundColor: Colors.green,
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                        );
                                        setState(() {});
                                      } catch (e) {
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                'Error al registrar asistencia: $e'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    },
                                    icon: Icon(Icons.save, size: 18),
                                    label: Text('Guardar',
                                        style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: cocepTeal,
                                      padding:
                                          EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                    ),
                                  ),
                                ),
                              ] else ...[
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: Text('Cancelar',
                                            style: TextStyle(
                                                color: Colors.grey[700])),
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      flex: 2,
                                      child: ElevatedButton.icon(
                                        onPressed: () async {
                                          if (numeroModulo == null) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                    'Selecciona el número de $nombreUnidad'),
                                                backgroundColor: Colors.orange,
                                              ),
                                            );
                                            return;
                                          }

                                          // ✅ PROTECCIÓN ANTI-DUPLICADOS: Verificar que no existan registros previos
                                          try {
                                            for (var discipulo in discipulos) {
                                              final personaId =
                                                  discipulo['personaId'];

                                              // ✅ Verificar si ya existe un registro para este discípulo + módulo + clase
                                              final registrosExistentes =
                                                  await FirebaseFirestore
                                                      .instance
                                                      .collection(
                                                          'asistenciasDiscipulado')
                                                      .where('claseId',
                                                          isEqualTo:
                                                              claseAsignadaId)
                                                      .where('discipuloId',
                                                          isEqualTo: personaId)
                                                      .where('numeroModulo',
                                                          isEqualTo:
                                                              numeroModulo)
                                                      .get();

                                              // ✅ Si ya existe, saltar este discípulo
                                              if (registrosExistentes
                                                  .docs.isNotEmpty) {
                                                continue;
                                              }

                                              // ✅ Si no existe, crear el registro
                                              final asistio =
                                                  asistencias[personaId] ??
                                                      false;
                                              await FirebaseFirestore.instance
                                                  .collection(
                                                      'asistenciasDiscipulado')
                                                  .add({
                                                'claseId': claseAsignadaId,
                                                'discipuloId': personaId,
                                                'discipuloNombre':
                                                    discipulo['nombre'],
                                                'numeroModulo': numeroModulo,
                                                'asistio': asistio,
                                                'fecha': Timestamp.fromDate(
                                                    fechaSeleccionada),
                                                'maestroId': widget.maestroId,
                                                'recuperado': false,
                                              });
                                            }

                                            Navigator.pop(context);
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Row(
                                                  children: [
                                                    Icon(Icons.check_circle,
                                                        color: Colors.white),
                                                    SizedBox(width: 12),
                                                    Flexible(
                                                      child: Text(
                                                          'Asistencia de $nombreUnidad $numeroModulo registrada'),
                                                    ),
                                                  ],
                                                ),
                                                backgroundColor: Colors.green,
                                                behavior:
                                                    SnackBarBehavior.floating,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                              ),
                                            );
                                            setState(() {});
                                          } catch (e) {
                                            Navigator.pop(context);
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                    'Error al registrar asistencia: $e'),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        },
                                        icon: Icon(Icons.save),
                                        label: Text('Guardar',
                                            style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600)),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: cocepTeal,
                                          padding: EdgeInsets.symmetric(
                                              vertical: 14),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12)),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildVerAsistenciasTab(Map<String, dynamic> claseData) {
    var discipulos =
        List<Map<String, dynamic>>.from(claseData['discipulosInscritos'] ?? []);

    discipulos.sort((a, b) {
      final nombreA = (a['nombre'] ?? '').toString().toLowerCase();
      final nombreB = (b['nombre'] ?? '').toString().toLowerCase();
      return nombreA.compareTo(nombreB);
    });

    if (discipulos.isEmpty) {
      return _buildEmptyState();
    }

    // ✅ Obtener claseAsignadaId ACTUAL del maestro
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('maestrosDiscipulado')
          .doc(widget.maestroId)
          .snapshots(),
      builder: (context, maestroSnapshot) {
        if (!maestroSnapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(color: cocepTeal),
          );
        }

        final maestroData =
            maestroSnapshot.data!.data() as Map<String, dynamic>?;
        if (maestroData == null) {
          return Center(child: Text('Error al cargar datos del maestro'));
        }

        final claseActualId = maestroData['claseAsignadaId'];
        if (claseActualId == null) {
          return Center(child: Text('No hay clase asignada'));
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('asistenciasDiscipulado')
              .where('claseId', isEqualTo: claseActualId)
              .snapshots(),
          builder: (context, asistenciasSnapshot) {
            if (asistenciasSnapshot.connectionState ==
                ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator(color: cocepTeal));
            }

            // ✅ Consultar reprobaciones manuales en paralelo
            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('reprobacionesManualesdiscipulado')
                  .where('claseId', isEqualTo: claseActualId)
                  .snapshots(),
              builder: (context, reprobacionesSnapshot) {
                Map<String, Map<String, dynamic>> estadisticas = {};

                // Inicializar estadísticas
                for (var discipulo in discipulos) {
                  final personaId = discipulo['personaId'];
                  estadisticas[personaId] = {
                    'personaId': personaId,
                    'nombre': discipulo['nombre'],
                    'telefono': discipulo['telefono'],
                    'tribu': discipulo['tribu'],
                    'ministerio': discipulo['ministerio'],
                    'asistencias': 0,
                    'faltas': 0,
                    'modulosFaltados': <int>[],
                    'modulosAsistidos': <int>[],
                    'aprobado': null,
                    'reprobadoManualmente': false,
                  };
                }

                // ✅ Procesar asistencias
                if (asistenciasSnapshot.hasData &&
                    asistenciasSnapshot.data!.docs.isNotEmpty) {
                  for (var doc in asistenciasSnapshot.data!.docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    final personaId = data['discipuloId'];
                    final numeroModulo = data['numeroModulo'] as int;
                    final recuperado = data['recuperado'] ?? false;

                    if (estadisticas.containsKey(personaId)) {
                      if (data['asistio'] == true) {
                        estadisticas[personaId]!['asistencias']++;
                        (estadisticas[personaId]!['modulosAsistidos']
                                as List<int>)
                            .add(numeroModulo);
                      } else {
                        // ✅ Solo contar como falta si NO fue recuperado
                        if (!recuperado) {
                          estadisticas[personaId]!['faltas']++;
                          (estadisticas[personaId]!['modulosFaltados']
                                  as List<int>)
                              .add(numeroModulo);
                        }
                      }
                    }
                  }
                }

                // ✅ Procesar reprobaciones manuales
                Set<String> reprobadosManualmente = {};
                if (reprobacionesSnapshot.hasData &&
                    reprobacionesSnapshot.data!.docs.isNotEmpty) {
                  for (var doc in reprobacionesSnapshot.data!.docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    final personaId = data['discipuloId'];
                    reprobadosManualmente.add(personaId);
                  }
                }

                // ✅ LÓGICA DE APROBACIÓN/REPROBACIÓN
                final tipoClase = claseData['tipo'] ?? '';
                final esClaseConReprobacionAutomatica =
                    tipoClase == 'Discipulado 1' ||
                        tipoClase == 'Discipulado 2' ||
                        tipoClase == 'Discipulado 3';

                estadisticas.forEach((personaId, stats) {
                  final faltas = stats['faltas'] as int;
                  final fueReprobadoManualmente =
                      reprobadosManualmente.contains(personaId);

                  // Marcar si fue reprobado manualmente
                  stats['reprobadoManualmente'] = fueReprobadoManualmente;

                  if (esClaseConReprobacionAutomatica) {
                    // ✅ Reprobación automática a las 3 faltas
                    stats['aprobado'] = faltas < 3;
                  } else {
                    // ✅ Para Consolidación/Estudios Bíblicos
                    if (fueReprobadoManualmente) {
                      stats['aprobado'] = false;
                    } else {
                      stats['aprobado'] = null; // Aún sin definir
                    }
                  }
                });

                return ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    // ✅ BARRA DE BÚSQUEDA (SE MUEVE CON EL SCROLL)
                    _buildSearchBar(),

                    // ✅ LISTA CON VALUELISTENABLEBUILDER
                    ValueListenableBuilder<String>(
                      valueListenable: _searchQueryNotifier,
                      builder: (context, searchQuery, _) {
                        // ✅ FILTRAR ESTADÍSTICAS
                        Map<String, Map<String, dynamic>>
                            estadisticasFiltradas = {};

                        estadisticas.forEach((personaId, stats) {
                          if (searchQuery.isEmpty) {
                            estadisticasFiltradas[personaId] = stats;
                          } else {
                            final nombre =
                                _normalizeText(stats['nombre'] ?? '');
                            final query = _normalizeText(searchQuery);
                            if (nombre.contains(query)) {
                              estadisticasFiltradas[personaId] = stats;
                            }
                          }
                        });

                        if (estadisticasFiltradas.isEmpty) {
                          return Container(
                            height: 300,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: cocepOrange.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.search_off_rounded,
                                      size: 64,
                                      color: cocepOrange.withOpacity(0.5),
                                    ),
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'No se encontraron resultados',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Intenta con otro término de búsqueda',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        return Padding(
                          padding: EdgeInsets.fromLTRB(16, 0, 16, 100),
                          child: Column(
                            children:
                                estadisticasFiltradas.entries.map((entry) {
                              return _buildEstadisticaCard(
                                  entry.value, claseData);
                            }).toList(),
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildEstadisticaCard(
      Map<String, dynamic> stats, Map<String, dynamic> claseData) {
    final aprobado = stats['aprobado'];
    final faltas = stats['faltas'];
    final asistencias = stats['asistencias'];
    final nombreTribu = stats['tribu']?.toString() ?? 'Sin tribu';
    final nombre = stats['nombre'] ?? 'Sin nombre';
    final inicial = nombre.isNotEmpty ? nombre[0].toUpperCase() : '?';
    final modulosFaltados = List<int>.from(stats['modulosFaltados'] ?? []);
    final modulosAsistidos = List<int>.from(stats['modulosAsistidos'] ?? []);
    final reprobadoManualmente = stats['reprobadoManualmente'] ?? false;

    modulosFaltados.sort();
    modulosAsistidos.sort();

    // ✅ Determinar tipo de clase y nomenclatura
    final tipoClase = claseData['tipo'] ?? '';
    final usarLeccion = tipoClase == 'Discipulado 1' ||
        tipoClase == 'Discipulado 2' ||
        tipoClase == 'Discipulado 3' ||
        tipoClase == 'Consolidación';
    final nombreUnidad = usarLeccion ? 'Lecciones' : 'Módulos';
    final prefijoUnidad = usarLeccion ? 'L' : 'M';

    // ✅ Determinar si es clase con reprobación automática
    final esClaseConReprobacionAutomatica = tipoClase == 'Discipulado 1' ||
        tipoClase == 'Discipulado 2' ||
        tipoClase == 'Discipulado 3';

    // ✅ Determinar estado y color
    Color statusColor;
    if (aprobado == true) {
      statusColor = Colors.green;
    } else if (aprobado == false) {
      statusColor = Colors.red;
    } else {
      // Sin estado definido (Consolidación/Estudios Bíblicos)
      statusColor = faltas >= 3 ? Colors.orange : Colors.grey;
    }

    final estado = claseData['estado'] ?? 'activa';
    final claseActiva = estado == 'activa';

    // ✅ Determinar si mostrar botón de reprobar
    final mostrarBotonReprobar = !esClaseConReprobacionAutomatica &&
        faltas >= 3 &&
        !reprobadoManualmente &&
        claseActiva;

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: statusColor.withOpacity(0.2),
          width: 2,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.all(16),
          childrenPadding: EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  inicial,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(
                  aprobado == true
                      ? Icons.check
                      : aprobado == false
                          ? Icons.close
                          : Icons.help,
                  color: Colors.white,
                  size: 16,
                ),
              ],
            ),
          ),
          title: Text(
            nombre,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: cocepDarkTeal,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.check_circle, size: 16, color: Colors.green),
                  SizedBox(width: 6),
                  Text('$asistencias',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  SizedBox(width: 16),
                  Icon(Icons.cancel, size: 16, color: Colors.red),
                  SizedBox(width: 6),
                  Text('$faltas',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  // ✅ NUEVO: Botón para agregar módulos/lecciones vistos (CONDICIONAL)
                  if (claseActiva) ...[
                    Spacer(),
                    // ✅ StreamBuilder para verificar si hay módulos disponibles
                    StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('maestrosDiscipulado')
                          .doc(widget.maestroId)
                          .snapshots(),
                      builder: (context, maestroSnap) {
                        if (!maestroSnap.hasData) {
                          return SizedBox.shrink();
                        }

                        final maestroData =
                            maestroSnap.data!.data() as Map<String, dynamic>?;
                        final claseActualId = maestroData?['claseAsignadaId'];

                        if (claseActualId == null) {
                          return SizedBox.shrink();
                        }

                        // ✅ Consultar módulos registrados para este discípulo
                        return FutureBuilder<QuerySnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('asistenciasDiscipulado')
                              .where('claseId', isEqualTo: claseActualId)
                              .where('discipuloId',
                                  isEqualTo: stats['personaId'])
                              .get(),
                          builder: (context, asistenciasDiscipuloSnap) {
                            if (asistenciasDiscipuloSnap.connectionState ==
                                ConnectionState.waiting) {
                              return SizedBox.shrink();
                            }

                            Set<int> modulosYaRegistrados = {};
                            if (asistenciasDiscipuloSnap.hasData) {
                              for (var doc
                                  in asistenciasDiscipuloSnap.data!.docs) {
                                final data = doc.data() as Map<String, dynamic>;
                                modulosYaRegistrados
                                    .add(data['numeroModulo'] as int);
                              }
                            }

                            // ✅ Consultar todos los módulos vistos en la clase
                            return FutureBuilder<QuerySnapshot>(
                              future: FirebaseFirestore.instance
                                  .collection('asistenciasDiscipulado')
                                  .where('claseId', isEqualTo: claseActualId)
                                  .get(),
                              builder: (context, todasAsistenciasSnap) {
                                if (todasAsistenciasSnap.connectionState ==
                                    ConnectionState.waiting) {
                                  return SizedBox.shrink();
                                }

                                Set<int> modulosVistos = {};
                                if (todasAsistenciasSnap.hasData) {
                                  for (var doc
                                      in todasAsistenciasSnap.data!.docs) {
                                    final data =
                                        doc.data() as Map<String, dynamic>;
                                    modulosVistos
                                        .add(data['numeroModulo'] as int);
                                  }
                                }

                                // ✅ Determinar módulos disponibles
                                final moduloInicialPermitido =
                                    claseData['moduloInicialPermitido']
                                            as int? ??
                                        1;
                                final totalModulos =
                                    claseData['totalModulos'] as int;

                                List<int> modulosDisponibles = [];
                                for (int i = moduloInicialPermitido;
                                    i <= totalModulos;
                                    i++) {
                                  if (modulosVistos.contains(i) &&
                                      !modulosYaRegistrados.contains(i)) {
                                    modulosDisponibles.add(i);
                                  }
                                }

                                // ✅ SOLO mostrar botón si hay módulos disponibles
                                if (modulosDisponibles.isEmpty) {
                                  return SizedBox.shrink();
                                }

                                // ✅ Mostrar botón
                                return Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () =>
                                        _mostrarDialogoAgregarModuloVisto(
                                      stats,
                                      claseData,
                                      nombreUnidad,
                                      prefijoUnidad,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            cocepOrange.withOpacity(0.2),
                                            cocepOrange.withOpacity(0.1),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: cocepOrange.withOpacity(0.5),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.add_circle_outline,
                                            size: 16,
                                            color: cocepOrange,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'Agregar',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: cocepOrange,
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
                      },
                    ),
                  ],
                ],
              ),
              // ✅ Mostrar estado según tipo de clase
              if (esClaseConReprobacionAutomatica && aprobado != null) ...[
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    aprobado ? 'APROBADO' : 'REPROBADO',
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ] else if (mostrarBotonReprobar) ...[
                // ✅ Botón para reprobar manualmente
                SizedBox(height: 8),
                _buildBotonReprobarManual(stats, claseData, claseActiva),
              ] else if (reprobadoManualmente) ...[
                // ✅ Mostrar badge de reprobado manualmente
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.block, size: 14, color: Colors.red[700]),
                      SizedBox(width: 6),
                      Text(
                        'REPROBADO',
                        style: TextStyle(
                          color: Colors.red[700],
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow(
                      Icons.phone_android, stats['telefono'] ?? 'N/A'),
                  SizedBox(height: 8),
                  _buildInfoRow(Icons.group, nombreTribu),
                  SizedBox(height: 8),
                  _buildInfoRow(Icons.church, stats['ministerio'] ?? 'N/A'),
                  if (modulosAsistidos.isNotEmpty) ...[
                    SizedBox(height: 16),
                    Divider(),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.check_circle, size: 18, color: Colors.green),
                        SizedBox(width: 8),
                        Text(
                          '$nombreUnidad Asistidas',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    // ✅ Obtener módulos recuperados
                    StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('maestrosDiscipulado')
                          .doc(widget.maestroId)
                          .snapshots(),
                      builder: (context, maestroSnap) {
                        if (!maestroSnap.hasData) {
                          return SizedBox.shrink();
                        }

                        final maestroData =
                            maestroSnap.data!.data() as Map<String, dynamic>?;
                        final claseActualId = maestroData?['claseAsignadaId'];

                        if (claseActualId == null) {
                          return SizedBox.shrink();
                        }

                        return FutureBuilder<QuerySnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('asistenciasDiscipulado')
                              .where('claseId', isEqualTo: claseActualId)
                              .where('discipuloId',
                                  isEqualTo: stats['personaId'])
                              .where('recuperado', isEqualTo: true)
                              .get(),
                          builder: (context, recuperadosSnap) {
                            List<int> modulosRecuperados = [];
                            if (recuperadosSnap.hasData) {
                              modulosRecuperados = recuperadosSnap.data!.docs
                                  .map((doc) => (doc.data() as Map<String,
                                      dynamic>)['numeroModulo'] as int)
                                  .toList();
                            }

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: modulosAsistidos.map((modulo) {
                                    final esRecuperado =
                                        modulosRecuperados.contains(modulo);

                                    return Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        gradient: esRecuperado
                                            ? LinearGradient(
                                                colors: [
                                                  Colors.orange[100]!,
                                                  Colors.orange[50]!
                                                ],
                                              )
                                            : null,
                                        color: esRecuperado
                                            ? null
                                            : Colors.green.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: esRecuperado
                                              ? Colors.orange[400]!
                                              : Colors.green.withOpacity(0.3),
                                          width: esRecuperado ? 2 : 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (esRecuperado) ...[
                                            Icon(Icons.restore,
                                                size: 14,
                                                color: Colors.orange[700]),
                                            SizedBox(width: 4),
                                          ],
                                          Text(
                                            '$prefijoUnidad$modulo',
                                            style: TextStyle(
                                              color: esRecuperado
                                                  ? Colors.orange[900]
                                                  : Colors.green[700],
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                                if (modulosRecuperados.isNotEmpty) ...[
                                  SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.orange[100]!,
                                              Colors.orange[50]!
                                            ],
                                          ),
                                          border: Border.all(
                                              color: Colors.orange[400]!,
                                              width: 2),
                                          borderRadius:
                                              BorderRadius.circular(3),
                                        ),
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        'Recuperadas',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.orange[800],
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ],
                  if (modulosFaltados.isNotEmpty) ...[
                    SizedBox(height: 16),
                    Divider(),
                    SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.cancel, size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text(
                              '$nombreUnidad Faltadas',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red[700],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        if (claseActiva)
                          TextButton.icon(
                            onPressed: () => _mostrarDialogoRecuperarModulos(
                              stats['personaId'],
                              modulosFaltados,
                              nombreUnidad,
                              prefijoUnidad,
                            ),
                            icon: Icon(Icons.restore,
                                size: 16, color: cocepOrange),
                            label: Text(
                              'Recuperar',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: cocepOrange,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              minimumSize: Size(0, 0),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: modulosFaltados.map((modulo) {
                        return Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border:
                                Border.all(color: Colors.red.withOpacity(0.3)),
                          ),
                          child: Text(
                            '$prefijoUnidad$modulo',
                            style: TextStyle(
                              color: Colors.red[700],
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBotonReprobarManual(
    Map<String, dynamic> stats,
    Map<String, dynamic> claseData,
    bool claseActiva,
  ) {
    final faltas = stats['faltas'] as int;
    final personaId = stats['personaId'];
    final nombre = stats['nombre'];

    if (!claseActiva) {
      return SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 350;

        return Container(
          padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.orange[50]!, Colors.orange[100]!],
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.orange[300]!, width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado con ícono y texto
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                    decoration: BoxDecoration(
                      color: Colors.orange[200],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange[900],
                      size: isSmallScreen ? 16 : 20,
                    ),
                  ),
                  SizedBox(width: isSmallScreen ? 8 : 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reprobación pendiente',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 12 : 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[900],
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          '$faltas ${faltas == 1 ? "falta" : "faltas"} registrada${faltas == 1 ? "" : "s"}',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 10 : 11,
                            color: Colors.orange[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: isSmallScreen ? 8 : 10),
              // Botón de acción
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _confirmarReprobacionManual(
                    personaId,
                    nombre,
                    claseData,
                  ),
                  icon: Icon(
                    Icons.block,
                    size: isSmallScreen ? 14 : 16,
                  ),
                  label: Text(
                    'Marcar como REPROBADO',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 11 : 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[600],
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      vertical: isSmallScreen ? 10 : 12,
                      horizontal: isSmallScreen ? 12 : 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmarReprobacionManual(
    String personaId,
    String nombre,
    Map<String, dynamic> claseData,
  ) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: BoxConstraints(maxWidth: 400),
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  size: 64,
                  color: Colors.red[600],
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Confirmar Reprobación',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: cocepDarkTeal,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12),
              Text(
                '¿Estás seguro de marcar a "$nombre" como REPROBADO?\n\nEsta acción quedará registrada en el historial.',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        'Cancelar',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[600],
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Reprobar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmar != true) return;

    try {
      // Crear documento de reprobación manual
      await FirebaseFirestore.instance
          .collection('reprobacionesManualesdiscipulado')
          .add({
        'claseId': widget.claseAsignadaId,
        'discipuloId': personaId,
        'discipuloNombre': nombre,
        'maestroId': widget.maestroId,
        'tipoClase': claseData['tipo'],
        'fechaReprobacion': FieldValue.serverTimestamp(),
        'reprobadoManualmente': true,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text('$nombre marcado como REPROBADO'),
              ),
            ],
          ),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );

      setState(() {}); // Refrescar para ocultar el botón
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al marcar reprobación: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _mostrarDialogoRecuperarModulos(
    String personaId,
    List<int> modulosFaltados,
    String nombreUnidad,
    String prefijoUnidad,
  ) async {
    Map<int, bool> modulosSeleccionados = {
      for (var modulo in modulosFaltados) modulo: false
    };

    // ✅ CRÍTICO: Obtener claseAsignadaId ACTUAL
    final maestroDoc = await FirebaseFirestore.instance
        .collection('maestrosDiscipulado')
        .doc(widget.maestroId)
        .get();

    if (!maestroDoc.exists) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: No se encontró el maestro'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final maestroData = maestroDoc.data() as Map<String, dynamic>;
    final claseAsignadaIdActual = maestroData['claseAsignadaId'];

    if (claseAsignadaIdActual == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No hay clase asignada actualmente'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final resultado = await showDialog<Map<int, bool>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            constraints: BoxConstraints(maxWidth: 500),
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [cocepOrange, Color(0xFFE67635)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.restore, color: Colors.white, size: 24),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Marcar $nombreUnidad Recuperadas',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: cocepDarkTeal,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: Colors.blue[700], size: 20),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Selecciona las $nombreUnidad que el discípulo ya recuperó',
                          style:
                              TextStyle(fontSize: 13, color: Colors.blue[900]),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                ...modulosFaltados.map((modulo) {
                  return Container(
                    margin: EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: modulosSeleccionados[modulo]!
                            ? Colors.green.withOpacity(0.3)
                            : Colors.grey.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: CheckboxListTile(
                      title: Text(
                        '$prefijoUnidad$modulo',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: cocepDarkTeal,
                          fontSize: 14,
                        ),
                      ),
                      value: modulosSeleccionados[modulo],
                      activeColor: Colors.green,
                      onChanged: (value) {
                        setDialogState(() {
                          modulosSeleccionados[modulo] = value ?? false;
                        });
                      },
                      secondary: CircleAvatar(
                        radius: 18,
                        backgroundColor: modulosSeleccionados[modulo]!
                            ? Colors.green.withOpacity(0.2)
                            : Colors.grey.withOpacity(0.2),
                        child: Icon(
                          modulosSeleccionados[modulo]!
                              ? Icons.check
                              : Icons.close,
                          color: modulosSeleccionados[modulo]!
                              ? Colors.green
                              : Colors.grey,
                          size: 18,
                        ),
                      ),
                    ),
                  );
                }).toList(),
                SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Cancelar',
                            style: TextStyle(color: Colors.grey[700])),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () =>
                            Navigator.pop(context, modulosSeleccionados),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: cocepOrange,
                          padding: EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Guardar',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (resultado == null) return;

    final modulosRecuperados = resultado.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    if (modulosRecuperados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No seleccionaste ninguna $nombreUnidad'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // ✅ Actualizar asistencias SOLO de la clase ACTUAL
      final asistenciasSnap = await FirebaseFirestore.instance
          .collection('asistenciasDiscipulado')
          .where('claseId', isEqualTo: claseAsignadaIdActual)
          .where('discipuloId', isEqualTo: personaId)
          .get();

      for (var doc in asistenciasSnap.docs) {
        final data = doc.data();
        final numeroModulo = data['numeroModulo'] as int;

        if (modulosRecuperados.contains(numeroModulo) &&
            data['asistio'] == false) {
          await doc.reference.update({
            'asistio': true,
            'recuperado': true,
            'fechaRecuperacion': FieldValue.serverTimestamp(),
          });
        }
      }

      // ✅ Actualizar resultados SOLO de la clase ACTUAL
      final resultadosSnap = await FirebaseFirestore.instance
          .collection('resultadosDiscipulado')
          .where('claseId', isEqualTo: claseAsignadaIdActual)
          .where('discipuloId', isEqualTo: personaId)
          .get();

      for (var doc in resultadosSnap.docs) {
        final data = doc.data();
        final faltasDetalle = List<int>.from(data['faltasDetalle'] ?? []);
        final modulosRecuperadosActuales =
            List<int>.from(data['modulosRecuperados'] ?? []);

        for (var modulo in modulosRecuperados) {
          if (!modulosRecuperadosActuales.contains(modulo)) {
            modulosRecuperadosActuales.add(modulo);
          }
          faltasDetalle.remove(modulo);
        }

        final nuevoTotalFaltas = faltasDetalle.length;
        final nuevoAprobado = nuevoTotalFaltas < 2;

        await doc.reference.update({
          'faltasDetalle': faltasDetalle,
          'modulosRecuperados': modulosRecuperadosActuales,
          'totalFaltas': nuevoTotalFaltas,
          'aprobado': nuevoAprobado,
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${modulosRecuperados.length} $nombreUnidad ${modulosRecuperados.length == 1 ? "marcada" : "marcadas"} como recuperada${modulosRecuperados.length == 1 ? "" : "s"}',
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );

      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: cocepTeal),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingButton() {
    // ✅ CORRECCIÓN: Obtener claseAsignadaId ACTUAL del maestro
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('maestrosDiscipulado')
          .doc(widget.maestroId)
          .snapshots(),
      builder: (context, maestroSnapshot) {
        // Si no hay datos, no mostrar botón
        if (!maestroSnapshot.hasData) {
          return SizedBox.shrink();
        }

        final maestroData =
            maestroSnapshot.data!.data() as Map<String, dynamic>?;
        if (maestroData == null) {
          return SizedBox.shrink();
        }

        // ✅ Obtener claseAsignadaId ACTUAL
        final claseActualId = maestroData['claseAsignadaId'];
        if (claseActualId == null) {
          return SizedBox.shrink();
        }

        // ✅ Consultar el estado de la clase ACTUAL
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('clasesDiscipulado')
              .doc(claseActualId)
              .snapshots(),
          builder: (context, claseSnapshot) {
            // Si no hay datos o no existe la clase
            if (!claseSnapshot.hasData || !claseSnapshot.data!.exists) {
              return SizedBox.shrink();
            }

            final claseData =
                claseSnapshot.data!.data() as Map<String, dynamic>?;
            if (claseData == null) {
              return SizedBox.shrink();
            }

            final estado = claseData['estado'] ?? 'activa';

            // ✅ Si la clase está finalizada, no mostrar botón
            if (estado == 'finalizada') {
              return SizedBox.shrink();
            }

            // ✅ Si la clase está activa, mostrar botón
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.3),
                    blurRadius: 15,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: FloatingActionButton.extended(
                onPressed: _finalizarClase,
                backgroundColor: Colors.red[600],
                icon: Icon(Icons.done_all, size: 24),
                label: Text(
                  'Finalizar Clase',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _finalizarClase() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  size: 64,
                  color: Colors.red[600],
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Finalizar Clase',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: cocepDarkTeal,
                ),
              ),
              SizedBox(height: 12),
              Text(
                '¿Estás seguro de que deseas finalizar esta clase?\n\nSe te permitirá marcar resultados de aprobación antes de finalizar.',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        'Cancelar',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[600],
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Continuar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmar != true) return;
    try {
// ✅ PASO 1: Obtener claseAsignadaId ACTUAL del maestro en tiempo real
      final maestroDoc = await FirebaseFirestore.instance
          .collection('maestrosDiscipulado')
          .doc(widget.maestroId)
          .get();
      if (!maestroDoc.exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: No se encontró el maestro'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final maestroData = maestroDoc.data() as Map<String, dynamic>;
      final claseAsignadaIdActual = maestroData['claseAsignadaId'];

      if (claseAsignadaIdActual == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No hay clase asignada actualmente'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

// ✅ PASO 2: Obtener datos de la clase ACTUAL
      final claseDoc = await FirebaseFirestore.instance
          .collection('clasesDiscipulado')
          .doc(claseAsignadaIdActual)
          .get();

      if (!claseDoc.exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: La clase no existe'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final claseData = claseDoc.data() as Map<String, dynamic>;
      final discipulos = List<Map<String, dynamic>>.from(
          claseData['discipulosInscritos'] ?? []);

// ✅ PASO 3: Obtener asistencias SOLO de esta clase
      final asistenciasSnap = await FirebaseFirestore.instance
          .collection('asistenciasDiscipulado')
          .where('claseId', isEqualTo: claseAsignadaIdActual)
          .get();

      Map<String, Map<String, dynamic>> resultadosCalculados = {};
      for (var discipulo in discipulos) {
        final personaId = discipulo['personaId'];
        int totalAsistencias = 0;
        int totalFaltas = 0;
        List<int> modulosFaltados = [];

        for (var doc in asistenciasSnap.docs) {
          final data = doc.data();
          if (data['discipuloId'] == personaId) {
            if (data['asistio'] == true) {
              totalAsistencias++;
            } else {
              final recuperado = data['recuperado'] ?? false;
              if (!recuperado) {
                totalFaltas++;
                modulosFaltados.add(data['numeroModulo']);
              }
            }
          }
        }

        resultadosCalculados[personaId] = {
          'personaId': personaId,
          'nombre': discipulo['nombre'],
          'telefono': discipulo['telefono'],
          'tribu': discipulo['tribu'],
          'ministerio': discipulo['ministerio'],
          'totalAsistencias': totalAsistencias,
          'totalFaltas': totalFaltas,
          'modulosFaltados': modulosFaltados,
          'aprobadoSugerido': totalFaltas < 2,
        };
      }

      final resultadosFinales = await showDialog<Map<String, bool>>(
        context: context,
        barrierDismissible: false,
        builder: (context) => _DialogoConfirmarResultados(
          resultadosCalculados: resultadosCalculados,
        ),
      );

      if (resultadosFinales == null) return;

// ✅ PASO 4: Guardar resultados en Firestore
      for (var discipulo in discipulos) {
        final personaId = discipulo['personaId'];
        final resultado = resultadosCalculados[personaId]!;
        final aprobado =
            resultadosFinales[personaId] ?? resultado['aprobadoSugerido'];

        await FirebaseFirestore.instance
            .collection('resultadosDiscipulado')
            .add({
          'claseId': claseAsignadaIdActual, // ✅ Usar ID ACTUAL
          'discipuloId': personaId,
          'discipuloNombre': resultado['nombre'],
          'telefono': resultado['telefono'],
          'tribu': resultado['tribu'],
          'ministerio': resultado['ministerio'],
          'totalAsistencias': resultado['totalAsistencias'],
          'totalFaltas': resultado['totalFaltas'],
          'faltasDetalle': resultado['modulosFaltados'],
          'modulosRecuperados': [],
          'aprobado': aprobado,
          'maestroId': widget.maestroId,
          'maestroNombre': widget.maestroNombre,
          'tipoClase': claseData['tipo'],
          'fechaRegistro': FieldValue.serverTimestamp(),
        });
      }

// ✅ PASO 5: Marcar clase como finalizada
      await FirebaseFirestore.instance
          .collection('clasesDiscipulado')
          .doc(claseAsignadaIdActual)
          .update({
        'estado': 'finalizada',
        'fechaFinalizacion': FieldValue.serverTimestamp(),
        'maestroIdFinal': widget.maestroId,
      });

// ✅ PASO 6: NO eliminar claseAsignadaId - mantenerlo para consulta
// Solo se eliminará cuando se asigne una nueva clase desde Departamento

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Clase finalizada exitosamente. Tus datos permanecen guardados.',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: Duration(seconds: 4),
          ),
        );

        setState(() {}); // ✅ Refrescar para mostrar modo solo lectura
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al finalizar clase: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _mostrarDialogoAgregarModuloVisto(
    Map<String, dynamic> stats,
    Map<String, dynamic> claseData,
    String nombreUnidad,
    String prefijoUnidad,
  ) async {
    // ✅ Obtener claseAsignadaId ACTUAL
    final maestroDoc = await FirebaseFirestore.instance
        .collection('maestrosDiscipulado')
        .doc(widget.maestroId)
        .get();

    if (!maestroDoc.exists) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: No se encontró el maestro'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final maestroData = maestroDoc.data() as Map<String, dynamic>;
    final claseAsignadaIdActual = maestroData['claseAsignadaId'];

    if (claseAsignadaIdActual == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No hay clase asignada actualmente'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // ✅ Obtener módulos ya registrados para este discípulo
    final asistenciasSnap = await FirebaseFirestore.instance
        .collection('asistenciasDiscipulado')
        .where('claseId', isEqualTo: claseAsignadaIdActual)
        .where('discipuloId', isEqualTo: stats['personaId'])
        .get();

    Set<int> modulosYaRegistrados = {};
    for (var doc in asistenciasSnap.docs) {
      final data = doc.data();
      modulosYaRegistrados.add(data['numeroModulo'] as int);
    }

    // ✅ Obtener todos los módulos registrados en la clase (por cualquier discípulo)
    final todasAsistenciasSnap = await FirebaseFirestore.instance
        .collection('asistenciasDiscipulado')
        .where('claseId', isEqualTo: claseAsignadaIdActual)
        .get();

    Set<int> modulosVistos = {};
    for (var doc in todasAsistenciasSnap.docs) {
      final data = doc.data();
      modulosVistos.add(data['numeroModulo'] as int);
    }

    // ✅ Determinar módulos disponibles (vistos pero no registrados para este discípulo)
    final moduloInicialPermitido =
        claseData['moduloInicialPermitido'] as int? ?? 1;
    final totalModulos = claseData['totalModulos'] as int;

    List<int> modulosDisponibles = [];
    for (int i = moduloInicialPermitido; i <= totalModulos; i++) {
      if (modulosVistos.contains(i) && !modulosYaRegistrados.contains(i)) {
        modulosDisponibles.add(i);
      }
    }

    if (modulosDisponibles.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No hay $nombreUnidad vistos disponibles para agregar',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
      return;
    }

    modulosDisponibles.sort();

    // ✅ Mostrar diálogo
    int? moduloSeleccionado;
    bool? aprobo;

    final resultado = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final screenWidth = MediaQuery.of(context).size.width;
              final isSmallScreen = screenWidth < 600;

              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 500,
                    minHeight: 100,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header
                        Container(
                          padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [cocepOrange, Color(0xFFE67635)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding:
                                    EdgeInsets.all(isSmallScreen ? 10 : 12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.add_task,
                                  color: Colors.white,
                                  size: isSmallScreen ? 22 : 26,
                                ),
                              ),
                              SizedBox(width: isSmallScreen ? 10 : 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Agregar $nombreUnidad',
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 16 : 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      stats['nombre'] ?? '',
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 12 : 13,
                                        color: Colors.white.withOpacity(0.9),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Body
                        Flexible(
                          child: SingleChildScrollView(
                            padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Info banner
                                Container(
                                  padding:
                                      EdgeInsets.all(isSmallScreen ? 10 : 12),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[50],
                                    borderRadius: BorderRadius.circular(12),
                                    border:
                                        Border.all(color: Colors.blue[200]!),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.info_outline,
                                          color: Colors.blue[700],
                                          size: isSmallScreen ? 18 : 20),
                                      SizedBox(width: isSmallScreen ? 8 : 12),
                                      Expanded(
                                        child: Text(
                                          'Selecciona la $nombreUnidad que el discípulo vio e indica si aprobó o no',
                                          style: TextStyle(
                                            fontSize: isSmallScreen ? 12 : 13,
                                            color: Colors.blue[900],
                                            height: 1.4,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: isSmallScreen ? 16 : 20),

                                // Dropdown de módulos
                                DropdownButtonFormField<int>(
                                  decoration: InputDecoration(
                                    labelText: 'Seleccionar $nombreUnidad',
                                    labelStyle: TextStyle(
                                        fontSize: isSmallScreen ? 13 : 14),
                                    prefixIcon: Icon(
                                      Icons.bookmark,
                                      color: cocepOrange,
                                      size: isSmallScreen ? 20 : 24,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                          color: cocepOrange, width: 2),
                                    ),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: isSmallScreen ? 10 : 12,
                                      vertical: isSmallScreen ? 12 : 16,
                                    ),
                                  ),
                                  value: moduloSeleccionado,
                                  isExpanded: true,
                                  items: modulosDisponibles.map((modulo) {
                                    return DropdownMenuItem<int>(
                                      value: modulo,
                                      child: Text(
                                        '$nombreUnidad $prefijoUnidad$modulo',
                                        style: TextStyle(
                                          fontSize: isSmallScreen ? 13 : 14,
                                          fontWeight: FontWeight.w600,
                                          color: cocepDarkTeal,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setDialogState(() {
                                      moduloSeleccionado = value;
                                    });
                                  },
                                ),

                                if (moduloSeleccionado != null) ...[
                                  SizedBox(height: isSmallScreen ? 16 : 20),

                                  // Pregunta de aprobación
                                  Text(
                                    '¿El discípulo aprobó esta $nombreUnidad?',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 14 : 15,
                                      fontWeight: FontWeight.w600,
                                      color: cocepDarkTeal,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(height: isSmallScreen ? 12 : 16),

                                  // Botones de selección
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildOpcionButton(
                                          label: 'Aprobó',
                                          icon: Icons.check_circle,
                                          color: Colors.green,
                                          isSelected: aprobo == true,
                                          onTap: () {
                                            setDialogState(() {
                                              aprobo = true;
                                            });
                                          },
                                          isSmallScreen: isSmallScreen,
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: _buildOpcionButton(
                                          label: 'Reprobó',
                                          icon: Icons.cancel,
                                          color: Colors.red,
                                          isSelected: aprobo == false,
                                          onTap: () {
                                            setDialogState(() {
                                              aprobo = false;
                                            });
                                          },
                                          isSmallScreen: isSmallScreen,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),

                        // Footer
                        Container(
                          padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(20),
                              bottomRight: Radius.circular(20),
                            ),
                          ),
                          child: isSmallScreen
                              ? Column(
                                  children: [
                                    SizedBox(
                                      width: double.infinity,
                                      child: TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: Text('Cancelar',
                                            style: TextStyle(
                                                color: Colors.grey[700],
                                                fontSize: 14)),
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: (moduloSeleccionado !=
                                                    null &&
                                                aprobo != null)
                                            ? () => Navigator.pop(context, {
                                                  'modulo': moduloSeleccionado,
                                                  'aprobo': aprobo,
                                                })
                                            : null,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: cocepOrange,
                                          padding: EdgeInsets.symmetric(
                                              vertical: 14),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          disabledBackgroundColor:
                                              Colors.grey[300],
                                        ),
                                        child: Text(
                                          'Guardar',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color:
                                                (moduloSeleccionado != null &&
                                                        aprobo != null)
                                                    ? Colors.white
                                                    : Colors.grey[600],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : Row(
                                  children: [
                                    Expanded(
                                      child: TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: Text('Cancelar',
                                            style: TextStyle(
                                                color: Colors.grey[700])),
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      flex: 2,
                                      child: ElevatedButton(
                                        onPressed: (moduloSeleccionado !=
                                                    null &&
                                                aprobo != null)
                                            ? () => Navigator.pop(context, {
                                                  'modulo': moduloSeleccionado,
                                                  'aprobo': aprobo,
                                                })
                                            : null,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: cocepOrange,
                                          padding: EdgeInsets.symmetric(
                                              vertical: 14),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          disabledBackgroundColor:
                                              Colors.grey[300],
                                        ),
                                        child: Text(
                                          'Guardar',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color:
                                                (moduloSeleccionado != null &&
                                                        aprobo != null)
                                                    ? Colors.white
                                                    : Colors.grey[600],
                                          ),
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
              );
            },
          ),
        ),
      ),
    );

    if (resultado == null) return;

    final modulo = resultado['modulo'] as int;
    final aproboModulo = resultado['aprobo'] as bool;

    try {
      // ✅ Registrar la asistencia
      await FirebaseFirestore.instance
          .collection('asistenciasDiscipulado')
          .add({
        'claseId': claseAsignadaIdActual,
        'discipuloId': stats['personaId'],
        'discipuloNombre': stats['nombre'],
        'numeroModulo': modulo,
        'asistio': aproboModulo,
        'fecha': Timestamp.now(),
        'maestroId': widget.maestroId,
        'agregadoManualmente': true,
        'fechaRegistroManual': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '$nombreUnidad $prefijoUnidad$modulo agregado correctamente como ${aproboModulo ? "APROBADO" : "REPROBADO"}',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );

        setState(() {}); // Refrescar para mostrar cambios
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildOpcionButton({
    required String label,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isSmallScreen,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(
            vertical: isSmallScreen ? 14 : 16,
            horizontal: isSmallScreen ? 12 : 16,
          ),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [color, color.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected ? null : color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : color.withOpacity(0.3),
              width: isSelected ? 2.5 : 1.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.4),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : color,
                size: isSmallScreen ? 32 : 40,
              ),
              SizedBox(height: isSmallScreen ? 6 : 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: isSmallScreen ? 13 : 15,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : color,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _limpiarDuplicadosEnBaseDeDatos() async {
    try {
// Mostrar diálogo de confirmación
      final confirmar = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.cleaning_services, color: cocepOrange, size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Limpiar Duplicados',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Text(
            '¿Deseas eliminar todos los registros duplicados de asistencias?\n\nEsta acción no se puede deshacer.',
            style: TextStyle(fontSize: 15, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child:
                  Text('Cancelar', style: TextStyle(color: Colors.grey[700])),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: cocepOrange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text('Limpiar',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      if (confirmar != true) return;

// Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: cocepTeal),
                  SizedBox(height: 16),
                  Text(
                    'Limpiando duplicados...',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

// ✅ Obtener TODAS las asistencias
      final asistenciasSnap = await FirebaseFirestore.instance
          .collection('asistenciasDiscipulado')
          .get();

// ✅ Agrupar por claseId + discipuloId + numeroModulo
      Map<String, List<QueryDocumentSnapshot>> grupos = {};

      for (var doc in asistenciasSnap.docs) {
        final data = doc.data();
        final claseId = data['claseId'] ?? '';
        final discipuloId = data['discipuloId'] ?? '';
        final numeroModulo = data['numeroModulo']?.toString() ?? '';

        final clave = '$claseId|$discipuloId|$numeroModulo';

        if (!grupos.containsKey(clave)) {
          grupos[clave] = [];
        }
        grupos[clave]!.add(doc);
      }

      int registrosEliminados = 0;

// ✅ Para cada grupo, mantener solo el más reciente
      for (var grupo in grupos.values) {
        if (grupo.length > 1) {
          // Ordenar por fecha (el más reciente primero)
          grupo.sort((a, b) {
            final dataA = a.data() as Map<String, dynamic>;
            final dataB = b.data() as Map<String, dynamic>;

            final fechaA = dataA['fecha'] as Timestamp? ?? Timestamp.now();
            final fechaB = dataB['fecha'] as Timestamp? ?? Timestamp.now();

            return fechaB.compareTo(fechaA);
          });

          // ✅ Mantener el primero (más reciente), eliminar el resto
          for (int i = 1; i < grupo.length; i++) {
            await grupo[i].reference.delete();
            registrosEliminados++;
          }
        }
      }

// Cerrar diálogo de carga
      Navigator.pop(context);

// Mostrar resultado
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Limpieza completada: $registrosEliminados registros duplicados eliminados',
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 4),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );

      setState(() {});
    } catch (e) {
// Cerrar diálogo de carga si está abierto
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al limpiar duplicados: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class _DialogoConfirmarResultados extends StatefulWidget {
  final Map<String, Map<String, dynamic>> resultadosCalculados;

  const _DialogoConfirmarResultados({
    required this.resultadosCalculados,
  });

  @override
  _DialogoConfirmarResultadosState createState() =>
      _DialogoConfirmarResultadosState();
}

class _DialogoConfirmarResultadosState
    extends State<_DialogoConfirmarResultados> {
  Map<String, bool> decisiones = {};

  static const Color cocepTeal = Color(0xFF1B7F7A);
  static const Color cocepOrange = Color(0xFFFF8C42);
  static const Color cocepDarkTeal = Color(0xFF0D4C4A);

  @override
  void initState() {
    super.initState();
    widget.resultadosCalculados.forEach((personaId, resultado) {
      decisiones[personaId] = resultado['aprobadoSugerido'];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 600,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [cocepTeal, cocepDarkTeal],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.assignment_turned_in,
                      color: Colors.white, size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Confirmar Resultados',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView.builder(
                padding: EdgeInsets.all(16),
                shrinkWrap: true,
                itemCount: widget.resultadosCalculados.length,
                itemBuilder: (context, index) {
                  final personaId =
                      widget.resultadosCalculados.keys.elementAt(index);
                  final resultado = widget.resultadosCalculados[personaId]!;
                  final aprobado = decisiones[personaId] ?? false;

                  return Container(
                    margin: EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: aprobado
                            ? Colors.green.withOpacity(0.3)
                            : Colors.red.withOpacity(0.3),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (aprobado ? Colors.green : Colors.red)
                              .withOpacity(0.1),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      resultado['nombre'],
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: cocepDarkTeal,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(Icons.check_circle,
                                            size: 16, color: Colors.green),
                                        SizedBox(width: 4),
                                        Text('${resultado['totalAsistencias']}',
                                            style: TextStyle(fontSize: 14)),
                                        SizedBox(width: 16),
                                        Icon(Icons.cancel,
                                            size: 16, color: Colors.red),
                                        SizedBox(width: 4),
                                        Text('${resultado['totalFaltas']}',
                                            style: TextStyle(fontSize: 14)),
                                      ],
                                    ),
                                    if (resultado['modulosFaltados'].isNotEmpty)
                                      Padding(
                                        padding: EdgeInsets.only(top: 8),
                                        child: Text(
                                          'Faltó: ${(resultado['modulosFaltados'] as List).join(", ")}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.red,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      Icons.check_circle,
                                      color: aprobado
                                          ? Colors.green
                                          : Colors.grey[400],
                                      size: 32,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        decisiones[personaId] = true;
                                      });
                                    },
                                    tooltip: 'Aprobar',
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.cancel,
                                      color: !aprobado
                                          ? Colors.red
                                          : Colors.grey[400],
                                      size: 32,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        decisiones[personaId] = false;
                                      });
                                    },
                                    tooltip: 'Reprobar',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancelar',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, decisiones),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cocepTeal,
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Confirmar y Finalizar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
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
  }
}
