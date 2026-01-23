import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:formulario_app/screens/maestro_discipulado_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:formulario_app/services/auth_service.dart';

class DepartamentoDiscipuladoScreen extends StatefulWidget {
  const DepartamentoDiscipuladoScreen({Key? key}) : super(key: key);

  @override
  State<DepartamentoDiscipuladoScreen> createState() =>
      _DepartamentoDiscipuladoScreenState();
}

class _DepartamentoDiscipuladoScreenState
    extends State<DepartamentoDiscipuladoScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AuthService _authService = AuthService();
  bool _puedeEditarCredenciales = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _verificarPermisoEdicion();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _verificarPermisoEdicion() async {
    final doc = await FirebaseFirestore.instance
        .collection('departamentoDiscipulado')
        .doc('configuracion')
        .get();

    if (doc.exists) {
      setState(() {
        _puedeEditarCredenciales =
            doc.data()?['puedeEditarCredenciales'] ?? true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            // Header mejorado con degradado
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF2B7A8C), // Teal del logo
                    Color(0xFF1A5968), // Teal más oscuro
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Logo y título
                  Padding(
                    padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
                    child: Row(
                      children: [
                        // Logo circular
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/Cocep_.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        // Título expandible
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Departamento de',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w400,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                'Discipulado',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                  height: 1.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Botones de acción
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_puedeEditarCredenciales)
                              _buildHeaderButton(
                                icon: Icons.vpn_key,
                                tooltip: 'Cambiar Credenciales',
                                onPressed: _mostrarDialogoCambiarCredenciales,
                              ),
                            SizedBox(width: 8),
                            _buildHeaderButton(
                              icon: Icons.logout,
                              tooltip: 'Cerrar Sesión',
                              onPressed: () => context.go('/login'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // TabBar personalizado
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      labelColor: Color(0xFF2B7A8C),
                      unselectedLabelColor: Colors.white.withOpacity(0.7),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      tabs: [
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.school, size: 20),
                              SizedBox(width: 8),
                              Text('Maestros', style: TextStyle(fontSize: 14)),
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.class_, size: 20),
                              SizedBox(width: 8),
                              Text('Activas', style: TextStyle(fontSize: 14)),
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.history, size: 20),
                              SizedBox(width: 8),
                              Text('Historial', style: TextStyle(fontSize: 14)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10),
                ],
              ),
            ),
            // Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildMaestrosTab(),
                  _buildClasesActivasTab(),
                  _buildHistorialTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.all(12),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
        ),
      ),
    );
  }

  Widget _buildMaestrosTab() {
    return Column(
      children: [
        // Botón crear maestro
        Padding(
          padding: EdgeInsets.all(20),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _mostrarDialogoCrearMaestro,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFF7941D), // Naranja del logo
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_add, size: 24),
                  SizedBox(width: 12),
                  Text(
                    'Crear Maestro',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Lista de maestros
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('maestrosDiscipulado')
                // ✅ ELIMINADO: .orderBy('fechaCreacion', descending: true)
                // Ahora ordenaremos manualmente en el código
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF2B7A8C),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.school_outlined,
                          size: 64, color: Colors.grey[400]),
                      SizedBox(height: 16),
                      Text(
                        'No hay maestros registrados',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              }

              // ✅ NUEVO: Ordenar maestros alfabéticamente por nombre
              final maestros = snapshot.data!.docs;
              maestros.sort((a, b) {
                final dataA = a.data() as Map<String, dynamic>;
                final dataB = b.data() as Map<String, dynamic>;

                // Obtener nombres completos
                final nombreA =
                    '${dataA['nombre'] ?? ''} ${dataA['apellido'] ?? ''}'
                        .trim()
                        .toLowerCase();
                final nombreB =
                    '${dataB['nombre'] ?? ''} ${dataB['apellido'] ?? ''}'
                        .trim()
                        .toLowerCase();

                // Comparar alfabéticamente
                return nombreA.compareTo(nombreB);
              });

              return ListView.builder(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
                itemCount: maestros.length,
                itemBuilder: (context, index) {
                  final doc = maestros[index];
                  final data = doc.data() as Map<String, dynamic>;

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
                        onTap: () => _verPerfilMaestro(doc),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Row(
                            children: [
                              // Avatar con inicial
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFF2B7A8C),
                                      Color(0xFF1A5968),
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    // ✅ Mostrar inicial del nombre
                                    (data['nombre'] ?? 'M')[0].toUpperCase(),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 16),
                              // Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${data['nombre']} ${data['apellido']}',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1A5968),
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Usuario: ${data['usuario']}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    if (data['claseAsignadaId'] != null)
                                      FutureBuilder<DocumentSnapshot>(
                                        future: FirebaseFirestore.instance
                                            .collection('clasesDiscipulado')
                                            .doc(data['claseAsignadaId'])
                                            .get(),
                                        builder: (context, claseSnap) {
                                          if (claseSnap.hasData &&
                                              claseSnap.data!.exists) {
                                            final claseData = claseSnap.data!
                                                .data() as Map<String, dynamic>;
                                            return Container(
                                              margin: EdgeInsets.only(top: 8),
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 12, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: Colors.green[50],
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                border: Border.all(
                                                    color: Colors.green[300]!),
                                              ),
                                              child: Text(
                                                '📚 ${claseData['tipo']}',
                                                style: TextStyle(
                                                  color: Colors.green[800],
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            );
                                          }
                                          return SizedBox.shrink();
                                        },
                                      ),
                                  ],
                                ),
                              ),
                              // Menú
                              PopupMenuButton(
                                icon: Icon(Icons.more_vert,
                                    color: Color(0xFF2B7A8C)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    child: Row(
                                      children: [
                                        Icon(Icons.visibility,
                                            size: 20, color: Color(0xFF2B7A8C)),
                                        SizedBox(width: 12),
                                        Text('Ver perfil'),
                                      ],
                                    ),
                                    onTap: () => _verPerfilMaestro(doc),
                                  ),
                                  PopupMenuItem(
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit,
                                            size: 20, color: Color(0xFFF7941D)),
                                        SizedBox(width: 12),
                                        Text('Editar'),
                                      ],
                                    ),
                                    onTap: () => _editarMaestro(doc),
                                  ),
                                  PopupMenuItem(
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete,
                                            size: 20, color: Colors.red),
                                        SizedBox(width: 12),
                                        Text('Eliminar',
                                            style:
                                                TextStyle(color: Colors.red)),
                                      ],
                                    ),
                                    onTap: () => _eliminarMaestro(doc.id,
                                        '${data['nombre']} ${data['apellido']}'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildClasesActivasTab() {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(20),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _mostrarDialogoCrearClase,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFF7941D),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_circle_outline, size: 24),
                  SizedBox(width: 12),
                  Text(
                    'Crear Clase',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('clasesDiscipulado')
                .where('estado', isEqualTo: 'activa')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(color: Color(0xFF2B7A8C)),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.class_outlined,
                          size: 64, color: Colors.grey[400]),
                      SizedBox(height: 16),
                      Text(
                        'No hay clases activas',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              }

              // ✅ Separar clases por estado de inscripciones
              final clasesAbiertas = snapshot.data!.docs
                  .where((doc) =>
                      (doc.data()
                          as Map<String, dynamic>)['inscripcionesCerradas'] !=
                      true)
                  .toList();

              final clasesCerradas = snapshot.data!.docs
                  .where((doc) =>
                      (doc.data()
                          as Map<String, dynamic>)['inscripcionesCerradas'] ==
                      true)
                  .toList();

              // ✅ Ordenar por fecha de inicio (más reciente primero)
              clasesAbiertas.sort((a, b) {
                final fechaA =
                    ((a.data() as Map<String, dynamic>)['fechaInicio']
                                as Timestamp?)
                            ?.toDate() ??
                        DateTime(2000);
                final fechaB =
                    ((b.data() as Map<String, dynamic>)['fechaInicio']
                                as Timestamp?)
                            ?.toDate() ??
                        DateTime(2000);
                return fechaB.compareTo(fechaA);
              });

              clasesCerradas.sort((a, b) {
                final fechaA =
                    ((a.data() as Map<String, dynamic>)['fechaInicio']
                                as Timestamp?)
                            ?.toDate() ??
                        DateTime(2000);
                final fechaB =
                    ((b.data() as Map<String, dynamic>)['fechaInicio']
                                as Timestamp?)
                            ?.toDate() ??
                        DateTime(2000);
                return fechaB.compareTo(fechaA);
              });

              return ListView(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
                children: [
                  // ✅ Sección de Inscripciones Abiertas
                  if (clasesAbiertas.isNotEmpty) ...[
                    _buildSeccionHeader(
                      icon: Icons.lock_open,
                      titulo: 'Inscripciones Abiertas',
                      color: Colors.green,
                      cantidad: clasesAbiertas.length,
                    ),
                    SizedBox(height: 12),
                    ...clasesAbiertas
                        .map((doc) => _buildClaseCardCompacta(doc)),
                    SizedBox(height: 24),
                  ],

                  // ✅ Sección de Inscripciones Cerradas
                  if (clasesCerradas.isNotEmpty) ...[
                    _buildSeccionHeader(
                      icon: Icons.lock,
                      titulo: 'Inscripciones Cerradas',
                      color: Colors.orange,
                      cantidad: clasesCerradas.length,
                    ),
                    SizedBox(height: 12),
                    ...clasesCerradas
                        .map((doc) => _buildClaseCardCompacta(doc)),
                  ],
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSeccionHeader({
    required IconData icon,
    required String titulo,
    required Color color,
    required int cantidad,
  }) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              titulo,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$cantidad',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClaseCardCompacta(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final discipulos =
        List<Map<String, dynamic>>.from(data['discipulosInscritos'] ?? []);
    final inscripcionesCerradas = data['inscripcionesCerradas'] ?? false;

    // ✅ Formatear fecha de manera legible
    String fechaLegible = 'Sin fecha';
    if (data['fechaInicio'] != null) {
      final fecha = (data['fechaInicio'] as Timestamp).toDate();
      fechaLegible = DateFormat('d MMMM yyyy', 'es_ES').format(fecha);
      // Capitalizar primera letra
      fechaLegible = fechaLegible[0].toUpperCase() + fechaLegible.substring(1);
    }

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.all(12),
          childrenPadding: EdgeInsets.zero,
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFF7941D), Color(0xFFE67E22)],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.class_, color: Colors.white, size: 24),
          ),
          title: Text(
            data['tipo'] ?? '',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A5968),
            ),
          ),
          subtitle: Padding(
            padding: EdgeInsets.only(top: 6),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _buildCompactChip(
                  icon: Icons.calendar_today,
                  label: fechaLegible,
                  color: Colors.grey[700]!,
                ),
                if (data['maestroNombre'] != null)
                  _buildCompactChip(
                    icon: Icons.person,
                    label: data['maestroNombre'],
                    color: Colors.green[700]!,
                  ),
                _buildCompactChip(
                  icon: Icons.people,
                  label: '${discipulos.length}',
                  color: Color(0xFFF7941D),
                ),
              ],
            ),
          ),
          trailing: PopupMenuButton(
            icon: Icon(Icons.more_vert, color: Color(0xFF2B7A8C), size: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            itemBuilder: (context) => [
              PopupMenuItem(
                child: Row(
                  children: [
                    Icon(Icons.swap_horiz, size: 18, color: Color(0xFF2B7A8C)),
                    SizedBox(width: 10),
                    Text('Cambiar Maestro', style: TextStyle(fontSize: 14)),
                  ],
                ),
                onTap: () => _cambiarMaestroClase(doc),
              ),
              PopupMenuItem(
                child: Row(
                  children: [
                    Icon(
                      inscripcionesCerradas ? Icons.lock_open : Icons.lock,
                      size: 18,
                      color: inscripcionesCerradas
                          ? Colors.green[700]
                          : Colors.red[700],
                    ),
                    SizedBox(width: 10),
                    Text(
                      inscripcionesCerradas
                          ? 'Abrir Inscripciones'
                          : 'Cerrar Inscripciones',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
                onTap: () => _toggleInscripciones(doc),
              ),
            ],
          ),
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: discipulos.isEmpty
                  ? Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(
                        child: Text(
                          'No hay discípulos inscritos',
                          style:
                              TextStyle(fontSize: 13, color: Colors.grey[600]),
                        ),
                      ),
                    )
                  : Column(
                      children: discipulos
                          .map((discipulo) => Container(
                                decoration: BoxDecoration(
                                  border: Border(
                                    top: BorderSide(
                                        color: Colors.grey[200]!, width: 1),
                                  ),
                                ),
                                child: ListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 4),
                                  leading: CircleAvatar(
                                    radius: 16,
                                    backgroundColor:
                                        Color(0xFF2B7A8C).withOpacity(0.1),
                                    child: Icon(Icons.person_outline,
                                        size: 16, color: Color(0xFF2B7A8C)),
                                  ),
                                  title: Text(
                                    discipulo['nombre'] ?? '',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13),
                                  ),
                                  subtitle: Text(
                                    '${discipulo['tribu'] ?? 'N/A'} • ${discipulo['ministerio'] ?? 'N/A'}',
                                    style: TextStyle(fontSize: 11),
                                  ),
                                  trailing: inscripcionesCerradas
                                      ? IconButton(
                                          icon: Icon(Icons.person_remove,
                                              color: Colors.red[600], size: 18),
                                          tooltip: 'Desasignar',
                                          onPressed: () => _desasignarDiscipulo(
                                              doc.id, discipulo),
                                        )
                                      : null,
                                ),
                              ))
                          .toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w500,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: color,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildHistorialTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('clasesDiscipulado')
          .where('estado', isEqualTo: 'finalizada')
          .orderBy('fechaFinalizacion', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: Color(0xFF2B7A8C)),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 64, color: Colors.grey[400]),
                SizedBox(height: 16),
                Text(
                  'No hay clases finalizadas',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        // ✅ Agrupar clases por año
        Map<int, List<DocumentSnapshot>> clasesPorAno = {};
        for (var doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          if (data['fechaFinalizacion'] != null) {
            final fecha = (data['fechaFinalizacion'] as Timestamp).toDate();
            final ano = fecha.year;

            if (!clasesPorAno.containsKey(ano)) {
              clasesPorAno[ano] = [];
            }
            clasesPorAno[ano]!.add(doc);
          }
        }

        // Ordenar años de más reciente a más antiguo
        final anosOrdenados = clasesPorAno.keys.toList()
          ..sort((a, b) => b.compareTo(a));

        return ListView.builder(
          padding: EdgeInsets.all(20),
          itemCount: anosOrdenados.length,
          itemBuilder: (context, anoIndex) {
            final ano = anosOrdenados[anoIndex];
            final clasesDelAno = clasesPorAno[ano]!;

            return _GrupoAnioClases(
              ano: ano,
              clases: clasesDelAno,
              buildResultadoTile: _buildResultadoTile,
              copyToClipboard: _copyToClipboard,
            );
          },
        );
      },
    );
  }

  Widget _buildResultadoTile(Map<String, dynamic> resData, bool aprobado) {
    final totalAsistencias = resData['totalAsistencias'] ?? 0;
    final totalFaltas = resData['totalFaltas'] ?? 0;
    final tribu = resData['tribu']?.toString() ?? 'Sin tribu';
    final telefono = resData['telefono'] ?? '';
    final faltasDetalle = resData['faltasDetalle'] as List?;
    final tipoClase = resData['tipoClase'] ?? '';

    // ✅ Determinar nomenclatura según tipo de clase
    final usarLeccion = tipoClase == 'Discipulado 1' ||
        tipoClase == 'Discipulado 2' ||
        tipoClase == 'Discipulado 3' ||
        tipoClase == 'Consolidación';
    final nombreUnidad = usarLeccion ? 'Lección' : 'Módulo';
    final prefijoUnidad = usarLeccion ? 'L' : 'M';

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icono
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (aprobado ? Colors.green : Colors.red).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                aprobado ? Icons.check_circle : Icons.cancel,
                color: aprobado ? Colors.green[700] : Colors.red[700],
                size: 24,
              ),
            ),
            SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre del discípulo
                  Text(
                    resData['discipuloNombre'] ?? '',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A5968),
                    ),
                  ),
                  SizedBox(height: 8),

                  // Badges de tribu y ministerio
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _buildBadge(
                        icon: Icons.flag,
                        label: tribu,
                        color: Color(0xFF2B7A8C),
                      ),
                      _buildBadge(
                        icon: Icons.work_outline,
                        label: resData['ministerio'] ?? 'N/A',
                        color: Color(0xFFF7941D),
                      ),
                    ],
                  ),

                  SizedBox(height: 8),

                  // Teléfono con botón de copiar
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '📱 $telefono',
                          style:
                              TextStyle(fontSize: 13, color: Colors.grey[700]),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.copy,
                            size: 18, color: Color(0xFF2B7A8C)),
                        onPressed: () => _copyToClipboard(context, telefono),
                        tooltip: 'Copiar teléfono',
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                      ),
                    ],
                  ),

                  SizedBox(height: 8),

                  // Estadísticas de asistencias y faltas
                  Row(
                    children: [
                      _buildStatChip(
                        label: 'Asistencias',
                        value: totalAsistencias.toString(),
                        color: Colors.green,
                      ),
                      SizedBox(width: 8),
                      _buildStatChip(
                        label: 'Faltas',
                        value: totalFaltas.toString(),
                        color: Colors.red,
                      ),
                    ],
                  ),

                  // ✅ Módulos/Lecciones reprobados (si existen)
                  if (faltasDetalle != null && faltasDetalle.isNotEmpty) ...[
                    SizedBox(height: 12),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.warning_amber,
                                  size: 16, color: Colors.red[700]),
                              SizedBox(width: 6),
                              Text(
                                '${nombreUnidad}s reprobadas:', // ✅ Dinámico
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red[800],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: faltasDetalle.map((modulo) {
                              return Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.red[300]!),
                                ),
                                child: Text(
                                  '$nombreUnidad $prefijoUnidad$modulo', // ✅ "Lección L3" o "Módulo M5"
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.red[900],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
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

  /// ✅ Maneja AMBOS casos: tribu como ID o como texto
  Widget _buildTribuBadge(dynamic tribuData, String? ministerio) {
    // Si tribuData es null
    if (tribuData == null) {
      return Wrap(
        spacing: 8,
        runSpacing: 6,
        children: [
          _buildBadge(
            icon: Icons.flag,
            label: 'Sin tribu',
            color: Colors.grey,
          ),
          _buildBadge(
            icon: Icons.work_outline,
            label: ministerio ?? 'N/A',
            color: Color(0xFFF7941D),
          ),
        ],
      );
    }

    final tribuString = tribuData.toString();
    final pareceId = tribuString.length > 15 && !tribuString.contains(' ');

    if (pareceId) {
      // Es un ID - hacer consulta a Firestore
      return FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('tribus')
            .doc(tribuString)
            .get(),
        builder: (context, tribuSnap) {
          String tribuNombre = 'Sin tribu';

          if (tribuSnap.connectionState == ConnectionState.waiting) {
            tribuNombre = 'Cargando...';
          } else if (tribuSnap.hasData && tribuSnap.data!.exists) {
            final tribuFirebaseData =
                tribuSnap.data!.data() as Map<String, dynamic>;
            tribuNombre = tribuFirebaseData['nombre'] ?? 'Sin nombre';
          }

          return Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _buildBadge(
                icon: Icons.flag,
                label: tribuNombre,
                color: Color(0xFF2B7A8C),
              ),
              _buildBadge(
                icon: Icons.work_outline,
                label: ministerio ?? 'N/A',
                color: Color(0xFFF7941D),
              ),
            ],
          );
        },
      );
    } else {
      return Wrap(
        spacing: 8,
        runSpacing: 6,
        children: [
          _buildBadge(
            icon: Icons.flag,
            label: tribuString,
            color: Color(0xFF2B7A8C),
          ),
          _buildBadge(
            icon: Icons.work_outline,
            label: ministerio ?? 'N/A',
            color: Color(0xFFF7941D),
          ),
        ],
      );
    }
  }

  Widget _buildBadge({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  void _mostrarDialogoCambiarCredenciales() async {
    final usuarioController = TextEditingController();
    final contrasenaController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SingleChildScrollView(
          child: Container(
            constraints: BoxConstraints(maxWidth: 400),
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
                          colors: [Color(0xFFF7941D), Color(0xFFE67E22)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.vpn_key, color: Colors.white, size: 24),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Cambiar Credenciales',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A5968),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.grey),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber,
                          color: Colors.red[700], size: 24),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Solo puedes hacer esto UNA VEZ',
                          style: TextStyle(
                            color: Colors.red[900],
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24),
                TextField(
                  controller: usuarioController,
                  decoration: InputDecoration(
                    labelText: 'Nuevo Usuario',
                    prefixIcon: Icon(Icons.person, color: Color(0xFF2B7A8C)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: Color(0xFF2B7A8C), width: 2),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: contrasenaController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Nueva Contraseña',
                    prefixIcon: Icon(Icons.lock, color: Color(0xFF2B7A8C)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: Color(0xFF2B7A8C), width: 2),
                    ),
                  ),
                ),
                SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: Colors.grey[400]!),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text('Cancelar',
                            style: TextStyle(color: Colors.grey[700])),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (usuarioController.text.isEmpty ||
                              contrasenaController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Completa todos los campos'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                            return;
                          }

                          await FirebaseFirestore.instance
                              .collection('departamentoDiscipulado')
                              .doc('configuracion')
                              .set({
                            'usuario': usuarioController.text.trim(),
                            'contrasena': contrasenaController.text.trim(),
                            'puedeEditarCredenciales': false,
                          });

                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  Icon(Icons.check_circle, color: Colors.white),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                        'Credenciales actualizadas. Ya no podrás cambiarlas.'),
                                  ),
                                ],
                              ),
                              backgroundColor: Colors.green[700],
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          setState(() {
                            _puedeEditarCredenciales = false;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF2B7A8C),
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text('Guardar',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15)),
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

  void _mostrarDialogoCrearMaestro() async {
    final nombreController = TextEditingController();
    final apellidoController = TextEditingController();
    final usuarioController = TextEditingController();
    final contrasenaController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SingleChildScrollView(
          child: Container(
            constraints: BoxConstraints(maxWidth: 450),
            padding: EdgeInsets.all(24),
            child: Form(
              key: formKey,
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
                            colors: [Color(0xFF2B7A8C), Color(0xFF1A5968)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.person_add,
                            color: Colors.white, size: 24),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Crear Maestro',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A5968),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.grey),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),
                  TextField(
                    controller: nombreController,
                    decoration: InputDecoration(
                      labelText: 'Nombre',
                      prefixIcon: Icon(Icons.badge, color: Color(0xFF2B7A8C)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: Color(0xFF2B7A8C), width: 2),
                      ),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: apellidoController,
                    decoration: InputDecoration(
                      labelText: 'Apellido',
                      prefixIcon: Icon(Icons.badge, color: Color(0xFF2B7A8C)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: Color(0xFF2B7A8C), width: 2),
                      ),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: usuarioController,
                    decoration: InputDecoration(
                      labelText: 'Usuario',
                      prefixIcon:
                          Icon(Icons.account_circle, color: Color(0xFF2B7A8C)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: Color(0xFF2B7A8C), width: 2),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: contrasenaController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: Icon(Icons.lock, color: Color(0xFF2B7A8C)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: Color(0xFF2B7A8C), width: 2),
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(color: Colors.grey[400]!),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text('Cancelar',
                              style: TextStyle(color: Colors.grey[700])),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (nombreController.text.isEmpty ||
                                apellidoController.text.isEmpty ||
                                usuarioController.text.isEmpty ||
                                contrasenaController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Completa todos los campos'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                              return;
                            }

                            await FirebaseFirestore.instance
                                .collection('maestrosDiscipulado')
                                .add({
                              'nombre': nombreController.text.trim(),
                              'apellido': apellidoController.text.trim(),
                              'usuario': usuarioController.text.trim(),
                              'contrasena': contrasenaController.text.trim(),
                              'rol': 'maestroDiscipulado',
                              'fechaCreacion': FieldValue.serverTimestamp(),
                              'claseAsignadaId': null,
                            });

                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    Icon(Icons.check_circle,
                                        color: Colors.white),
                                    SizedBox(width: 12),
                                    Text('Maestro creado correctamente'),
                                  ],
                                ),
                                backgroundColor: Colors.green[700],
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFF7941D),
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text('Crear Maestro',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15)),
                        ),
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
  }

  void _mostrarDialogoCrearClase() async {
    String? tipoSeleccionado;
    DateTime? fechaInicio;
    String? maestroId;
    String? maestroNombre;

    final tiposClases = {
      'Discipulado 1': 8,
      'Discipulado 2': 10,
      'Discipulado 3': 12,
      'Consolidación': 10,
      'Estudios Bíblicos': 42,
    };

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: SingleChildScrollView(
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
                            colors: [Color(0xFFF7941D), Color(0xFFE67E22)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child:
                            Icon(Icons.class_, color: Colors.white, size: 24),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Crear Clase de Discipulado',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A5968),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.grey),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),
                  DropdownButtonFormField<String>(
                    value: tipoSeleccionado,
                    decoration: InputDecoration(
                      labelText: 'Tipo de Clase',
                      prefixIcon:
                          Icon(Icons.menu_book, color: Color(0xFF2B7A8C)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: Color(0xFF2B7A8C), width: 2),
                      ),
                    ),
                    items: tiposClases.keys.map((tipo) {
                      return DropdownMenuItem(
                        value: tipo,
                        child: Text('$tipo (${tiposClases[tipo]} módulos)'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        tipoSeleccionado = value;
                      });
                    },
                  ),
                  SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      final fecha = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(Duration(days: 365)),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: ColorScheme.light(
                                primary: Color(0xFF2B7A8C),
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (fecha != null) {
                        setDialogState(() {
                          fechaInicio = fecha;
                        });
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[400]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, color: Color(0xFF2B7A8C)),
                          SizedBox(width: 12),
                          Text(
                            fechaInicio != null
                                ? 'Inicio: ${DateFormat('dd/MM/yyyy').format(fechaInicio!)}'
                                : 'Seleccionar fecha de inicio',
                            style: TextStyle(
                              fontSize: 15,
                              color: fechaInicio != null
                                  ? Colors.black87
                                  : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('maestrosDiscipulado')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      return FutureBuilder<List<QueryDocumentSnapshot>>(
                        future: Future.wait(
                          snapshot.data!.docs.map((doc) async {
                            final data = doc.data() as Map<String, dynamic>;
                            final claseAsignadaId = data['claseAsignadaId'];

                            if (claseAsignadaId == null) return doc;

                            try {
                              final claseDoc = await FirebaseFirestore.instance
                                  .collection('clasesDiscipulado')
                                  .doc(claseAsignadaId)
                                  .get();

                              if (!claseDoc.exists) return doc;

                              final claseData =
                                  claseDoc.data() as Map<String, dynamic>;
                              return claseData['estado'] == 'finalizada'
                                  ? doc
                                  : null;
                            } catch (e) {
                              return doc;
                            }
                          }),
                        ).then((results) => results
                            .whereType<QueryDocumentSnapshot>()
                            .toList()),
                        builder: (context, asyncSnapshot) {
                          if (asyncSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Center(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          final maestrosDisponibles = asyncSnapshot.data ?? [];

                          if (maestrosDisponibles.isEmpty) {
                            return Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.orange[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.orange[200]!),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline,
                                      color: Colors.orange[700]),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'No hay maestros disponibles',
                                      style:
                                          TextStyle(color: Colors.orange[900]),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          return DropdownButtonFormField<String>(
                            value: maestroId,
                            decoration: InputDecoration(
                              labelText: 'Asignar Maestro',
                              prefixIcon:
                                  Icon(Icons.person, color: Color(0xFF2B7A8C)),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                    color: Color(0xFF2B7A8C), width: 2),
                              ),
                            ),
                            items: maestrosDisponibles.map((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              return DropdownMenuItem(
                                value: doc.id,
                                child: Text(
                                    '${data['nombre']} ${data['apellido']}'),
                              );
                            }).toList(),
                            onChanged: (value) {
                              final maestroDoc = maestrosDisponibles.firstWhere(
                                (doc) => doc.id == value,
                              );
                              final data =
                                  maestroDoc.data() as Map<String, dynamic>;
                              setDialogState(() {
                                maestroId = value;
                                maestroNombre =
                                    '${data['nombre']} ${data['apellido']}';
                              });
                            },
                          );
                        },
                      );
                    },
                  ),
                  SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(color: Colors.grey[400]!),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text('Cancelar',
                              style: TextStyle(color: Colors.grey[700])),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (tipoSeleccionado == null ||
                                fechaInicio == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Completa todos los campos requeridos'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                              return;
                            }

                            try {
                              // ✅ PASO 1: Si hay maestro, limpiar TODO del anterior
                              if (maestroId != null) {
                                final maestroDoc = await FirebaseFirestore
                                    .instance
                                    .collection('maestrosDiscipulado')
                                    .doc(maestroId)
                                    .get();

                                if (maestroDoc.exists) {
                                  final maestroData =
                                      maestroDoc.data() as Map<String, dynamic>;
                                  final claseAnteriorId =
                                      maestroData['claseAsignadaId'];

                                  // ✅ Validar que clase anterior esté finalizada
                                  if (claseAnteriorId != null) {
                                    final claseAnteriorDoc =
                                        await FirebaseFirestore.instance
                                            .collection('clasesDiscipulado')
                                            .doc(claseAnteriorId)
                                            .get();

                                    if (claseAnteriorDoc.exists) {
                                      final claseAnteriorData = claseAnteriorDoc
                                          .data() as Map<String, dynamic>;

                                      if (claseAnteriorData['estado'] !=
                                          'finalizada') {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                'El maestro aún tiene una clase activa'),
                                            backgroundColor: Colors.orange,
                                          ),
                                        );
                                        return;
                                      }
                                    }
                                  }

                                  // ✅ CRÍTICO: Eliminar TODA referencia a clases anteriores
                                  await FirebaseFirestore.instance
                                      .collection('maestrosDiscipulado')
                                      .doc(maestroId)
                                      .update({
                                    'claseAsignadaId': FieldValue.delete(),
                                  });

                                  // ✅ Esperar para asegurar que Firestore procese
                                  await Future.delayed(
                                      Duration(milliseconds: 500));
                                }
                              }

                              // ✅ PASO 2: Crear nueva clase DESDE CERO
                              final nuevaClaseRef = await FirebaseFirestore
                                  .instance
                                  .collection('clasesDiscipulado')
                                  .add({
                                'tipo': tipoSeleccionado,
                                'totalModulos': tiposClases[tipoSeleccionado],
                                'fechaInicio': Timestamp.fromDate(fechaInicio!),
                                'maestroId': maestroId,
                                'maestroNombre': maestroNombre,
                                'discipulosInscritos': [], // ✅ VACÍO
                                'estado': 'activa',
                                'fechaCreacion': FieldValue.serverTimestamp(),
                                'moduloInicialPermitido':
                                    1, // ✅ SIEMPRE desde 1
                                'inscripcionesCerradas': false,
                              });

                              // ✅ PASO 3: Asignar nueva clase al maestro
                              if (maestroId != null) {
                                await FirebaseFirestore.instance
                                    .collection('maestrosDiscipulado')
                                    .doc(maestroId)
                                    .update({
                                  'claseAsignadaId': nuevaClaseRef.id,
                                });
                              }

                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      Icon(Icons.check_circle,
                                          color: Colors.white),
                                      SizedBox(width: 12),
                                      Text('Clase creada correctamente'),
                                    ],
                                  ),
                                  backgroundColor: Colors.green[700],
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error al crear clase: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFF7941D),
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text('Crear Clase',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15)),
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _verPerfilMaestro(DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;
    final maestroId = doc.id;
    final maestroNombre = '${data['nombre']} ${data['apellido']}';
    final claseAsignadaId = data['claseAsignadaId'];

    // ✅ CORRECCIÓN: Navegar correctamente al apartado del maestro
    if (claseAsignadaId != null) {
      // Usar pushNamed para que pueda regresar con el botón de back
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => MaestroDiscipuladoScreen(
            maestroId: maestroId,
            maestroNombre: maestroNombre,
            claseAsignadaId: claseAsignadaId,
          ),
        ),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => MaestroDiscipuladoScreen(
            maestroId: maestroId,
            maestroNombre: maestroNombre,
          ),
        ),
      );
    }
  }

  void _editarMaestro(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final nombreController = TextEditingController(text: data['nombre']);
    final apellidoController = TextEditingController(text: data['apellido']);
    final usuarioController = TextEditingController(text: data['usuario']);
    final contrasenaController =
        TextEditingController(text: data['contrasena']);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SingleChildScrollView(
          child: Container(
            constraints: BoxConstraints(maxWidth: 450),
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
                          colors: [Color(0xFFF7941D), Color(0xFFE67E22)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.edit, color: Colors.white, size: 24),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Editar Maestro',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A5968),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.grey),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                SizedBox(height: 24),
                TextField(
                  controller: nombreController,
                  decoration: InputDecoration(
                    labelText: 'Nombre',
                    prefixIcon: Icon(Icons.badge, color: Color(0xFF2B7A8C)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: Color(0xFF2B7A8C), width: 2),
                    ),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                SizedBox(height: 16),
                TextField(
                  controller: apellidoController,
                  decoration: InputDecoration(
                    labelText: 'Apellido',
                    prefixIcon: Icon(Icons.badge, color: Color(0xFF2B7A8C)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: Color(0xFF2B7A8C), width: 2),
                    ),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                SizedBox(height: 16),
                TextField(
                  controller: usuarioController,
                  decoration: InputDecoration(
                    labelText: 'Usuario',
                    prefixIcon:
                        Icon(Icons.account_circle, color: Color(0xFF2B7A8C)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: Color(0xFF2B7A8C), width: 2),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: contrasenaController,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: Icon(Icons.lock, color: Color(0xFF2B7A8C)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: Color(0xFF2B7A8C), width: 2),
                    ),
                  ),
                ),
                SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: Colors.grey[400]!),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text('Cancelar',
                            style: TextStyle(color: Colors.grey[700])),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () async {
                          await FirebaseFirestore.instance
                              .collection('maestrosDiscipulado')
                              .doc(doc.id)
                              .update({
                            'nombre': nombreController.text.trim(),
                            'apellido': apellidoController.text.trim(),
                            'usuario': usuarioController.text.trim(),
                            'contrasena': contrasenaController.text.trim(),
                          });

                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  Icon(Icons.check_circle, color: Colors.white),
                                  SizedBox(width: 12),
                                  Text('Maestro actualizado'),
                                ],
                              ),
                              backgroundColor: Colors.green[700],
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFF7941D),
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text('Guardar',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15)),
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

  void _copyToClipboard(BuildContext context, String text) {
    // Implementación simple sin package externo
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Text('Teléfono copiado: $text'),
          ],
        ),
        backgroundColor: Colors.green[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _eliminarMaestro(String maestroId, String nombreCompleto) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Eliminar Maestro'),
        content: Text('¿Estás seguro de eliminar a $nombreCompleto?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await FirebaseFirestore.instance
          .collection('maestrosDiscipulado')
          .doc(maestroId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Maestro eliminado'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _cambiarMaestroClase(DocumentSnapshot claseDoc) async {
    final claseData = claseDoc.data() as Map<String, dynamic>;
    final maestroActualId = claseData['maestroId'];

    // Obtener maestros disponibles
    final maestrosSnap = await FirebaseFirestore.instance
        .collection('maestrosDiscipulado')
        .where('claseAsignadaId', isNull: true)
        .get();

    if (maestrosSnap.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No hay maestros disponibles'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final nuevoMaestroId = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Seleccionar Nuevo Maestro'),
        content: Container(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: maestrosSnap.docs.length,
            itemBuilder: (context, index) {
              final doc = maestrosSnap.docs[index];
              final data = doc.data() as Map<String, dynamic>;
              return ListTile(
                title: Text('${data['nombre']} ${data['apellido']}'),
                onTap: () => Navigator.pop(context, doc.id),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
        ],
      ),
    );

    if (nuevoMaestroId == null) return;

    try {
      // Obtener datos del nuevo maestro
      final nuevoMaestroDoc = await FirebaseFirestore.instance
          .collection('maestrosDiscipulado')
          .doc(nuevoMaestroId)
          .get();

      final nuevoMaestroData = nuevoMaestroDoc.data() as Map<String, dynamic>;
      final nuevoMaestroNombre =
          '${nuevoMaestroData['nombre']} ${nuevoMaestroData['apellido']}';

      // Obtener asistencias actuales para saber el último módulo registrado
      final asistenciasSnap = await FirebaseFirestore.instance
          .collection('asistenciasDiscipulado')
          .where('claseId', isEqualTo: claseDoc.id)
          .get();

      int ultimoModulo = 0;
      if (asistenciasSnap.docs.isNotEmpty) {
        for (var doc in asistenciasSnap.docs) {
          final modulo = (doc.data())['numeroModulo'] as int;
          if (modulo > ultimoModulo) {
            ultimoModulo = modulo;
          }
        }
      }

      // ✅ Crear registro de cambio de maestro
      await FirebaseFirestore.instance
          .collection('cambiosMaestrosDiscipulado')
          .add({
        'claseId': claseDoc.id,
        'tipoClase': claseData['tipo'],
        'maestroAnteriorId': maestroActualId,
        'maestroAnteriorNombre': claseData['maestroNombre'],
        'moduloInicioAnterior': 1,
        'moduloFinAnterior': ultimoModulo,
        'maestroNuevoId': nuevoMaestroId,
        'maestroNuevoNombre': nuevoMaestroNombre,
        'moduloInicioNuevo': ultimoModulo + 1,
        'fechaCambio': FieldValue.serverTimestamp(),
      });

      // Actualizar clase con nuevo maestro
      await FirebaseFirestore.instance
          .collection('clasesDiscipulado')
          .doc(claseDoc.id)
          .update({
        'maestroId': nuevoMaestroId,
        'maestroNombre': nuevoMaestroNombre,
      });

      // Liberar maestro anterior
      if (maestroActualId != null) {
        await FirebaseFirestore.instance
            .collection('maestrosDiscipulado')
            .doc(maestroActualId)
            .update({
          'claseAsignadaId': null,
        });
      }

      // Asignar clase al nuevo maestro
      await FirebaseFirestore.instance
          .collection('maestrosDiscipulado')
          .doc(nuevoMaestroId)
          .update({
        'claseAsignadaId': claseDoc.id,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Maestro cambiado correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cambiar maestro: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

// ============================================
// MÉTODOS PARA CONTROL DE INSCRIPCIONES
// ============================================

  void _toggleInscripciones(DocumentSnapshot claseDoc) async {
    final data = claseDoc.data() as Map<String, dynamic>;
    final inscripcionesCerradas = data['inscripcionesCerradas'] ?? false;
    final tipoClase = data['tipo'] ?? 'Clase';

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
                  color: (inscripcionesCerradas ? Colors.green : Colors.orange)
                      .withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  inscripcionesCerradas ? Icons.lock_open : Icons.lock,
                  size: 64,
                  color: inscripcionesCerradas
                      ? Colors.green[700]
                      : Colors.orange[700],
                ),
              ),
              SizedBox(height: 20),
              Text(
                inscripcionesCerradas
                    ? 'Abrir Inscripciones'
                    : 'Cerrar Inscripciones',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A5968),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12),
              Text(
                inscripcionesCerradas
                    ? '¿Deseas reabrir las inscripciones para "$tipoClase"?\n\nLas tribus podrán volver a inscribir discípulos.'
                    : '¿Deseas cerrar las inscripciones para "$tipoClase"?\n\nLas tribus ya no podrán inscribir más discípulos. Podrás desasignar discípulos si es necesario.',
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
                        backgroundColor: inscripcionesCerradas
                            ? Colors.green[700]
                            : Colors.orange[700],
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        inscripcionesCerradas ? 'Abrir' : 'Cerrar',
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

    if (confirmar == true) {
      try {
        await FirebaseFirestore.instance
            .collection('clasesDiscipulado')
            .doc(claseDoc.id)
            .update({
          'inscripcionesCerradas': !inscripcionesCerradas,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    inscripcionesCerradas
                        ? 'Inscripciones abiertas correctamente'
                        : 'Inscripciones cerradas correctamente',
                  ),
                ),
              ],
            ),
            backgroundColor:
                inscripcionesCerradas ? Colors.green[700] : Colors.orange[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cambiar estado: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _desasignarDiscipulo(
      String claseId, Map<String, dynamic> discipulo) async {
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
                  Icons.person_remove_outlined,
                  size: 64,
                  color: Colors.red[600],
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Desasignar Discípulo',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A5968),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12),
              Text(
                '¿Estás seguro de desasignar a "${discipulo['nombre']}" de esta clase?\n\nEsta acción puede revertirse volviendo a inscribir al discípulo.',
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
                        'Desasignar',
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

    if (confirmar == true) {
      try {
        final claseDoc = await FirebaseFirestore.instance
            .collection('clasesDiscipulado')
            .doc(claseId)
            .get();

        final claseData = claseDoc.data() as Map<String, dynamic>;
        final discipulos = List<Map<String, dynamic>>.from(
            claseData['discipulosInscritos'] ?? []);

        discipulos.removeWhere((d) => d['personaId'] == discipulo['personaId']);

        await FirebaseFirestore.instance
            .collection('clasesDiscipulado')
            .doc(claseId)
            .update({
          'discipulosInscritos': discipulos,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child:
                      Text('${discipulo['nombre']} desasignado correctamente'),
                ),
              ],
            ),
            backgroundColor: Colors.green[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al desasignar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _ResultadosColapsables extends StatefulWidget {
  final List<QueryDocumentSnapshot> aprobados;
  final List<QueryDocumentSnapshot> reprobados;
  final Widget Function(Map<String, dynamic>, bool) buildResultadoTile;
  final void Function(BuildContext, String) copyToClipboard;

  const _ResultadosColapsables({
    Key? key,
    required this.aprobados,
    required this.reprobados,
    required this.buildResultadoTile,
    required this.copyToClipboard,
  }) : super(key: key);

  @override
  State<_ResultadosColapsables> createState() => _ResultadosColapsablesState();
}

class _ResultadosColapsablesState extends State<_ResultadosColapsables> {
  // ✅ Ambos empiezan expandidos (false)
  bool _aprobadosExpandido = false;
  bool _reprobadosExpandido = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ============================================
        // SECCIÓN DE APROBADOS
        // ============================================
        if (widget.aprobados.isNotEmpty) ...[
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() {
                  _aprobadosExpandido = !_aprobadosExpandido;
                });
              },
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.green[50]!,
                      Colors.green[100]!.withOpacity(0.3),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[200]!, width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    // Icono de estado
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green[600],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.check_circle,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    SizedBox(width: 12),
                    // Texto
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'APROBADOS',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.green[900],
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            '${widget.aprobados.length} ${widget.aprobados.length == 1 ? "discípulo" : "discípulos"}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.green[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Icono de expandir/colapsar
                    AnimatedRotation(
                      turns: _aprobadosExpandido ? 0.5 : 0,
                      duration: Duration(milliseconds: 200),
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.green[700],
                        size: 28,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Lista de aprobados (colapsable)
          AnimatedSize(
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _aprobadosExpandido
                ? Column(
                    children: widget.aprobados.map((resultado) {
                      final resData = resultado.data() as Map<String, dynamic>;
                      return widget.buildResultadoTile(resData, true);
                    }).toList(),
                  )
                : SizedBox.shrink(),
          ),
        ],

        // ============================================
        // SECCIÓN DE REPROBADOS
        // ============================================
        if (widget.reprobados.isNotEmpty) ...[
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() {
                  _reprobadosExpandido = !_reprobadosExpandido;
                });
              },
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.red[50]!,
                      Colors.red[100]!.withOpacity(0.3),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[200]!, width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    // Icono de estado
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red[600],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.cancel,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    SizedBox(width: 12),
                    // Texto
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'REPROBADOS',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.red[900],
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            '${widget.reprobados.length} ${widget.reprobados.length == 1 ? "discípulo" : "discípulos"}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.red[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Icono de expandir/colapsar
                    AnimatedRotation(
                      turns: _reprobadosExpandido ? 0.5 : 0,
                      duration: Duration(milliseconds: 200),
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.red[700],
                        size: 28,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Lista de reprobados (colapsable)
          AnimatedSize(
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _reprobadosExpandido
                ? Column(
                    children: widget.reprobados.map((resultado) {
                      final resData = resultado.data() as Map<String, dynamic>;
                      return widget.buildResultadoTile(resData, false);
                    }).toList(),
                  )
                : SizedBox.shrink(),
          ),
        ],
      ],
    );
  }
}

class _GrupoAnioClases extends StatefulWidget {
  final int ano;
  final List<DocumentSnapshot> clases;
  final Widget Function(Map<String, dynamic>, bool) buildResultadoTile;
  final void Function(BuildContext, String) copyToClipboard;

  const _GrupoAnioClases({
    Key? key,
    required this.ano,
    required this.clases,
    required this.buildResultadoTile,
    required this.copyToClipboard,
  }) : super(key: key);

  @override
  State<_GrupoAnioClases> createState() => _GrupoAnioClasesState();
}

class _GrupoAnioClasesState extends State<_GrupoAnioClases> {
  bool _expandido = false; // ✅ Inicia colapsado

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 20),
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
      child: Column(
        children: [
          // Header del año (clickeable)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() {
                  _expandido = !_expandido;
                });
              },
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF2B7A8C), Color(0xFF1A5968)],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                    bottomLeft: _expandido ? Radius.zero : Radius.circular(16),
                    bottomRight: _expandido ? Radius.zero : Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, color: Colors.white, size: 24),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Año ${widget.ano}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${widget.clases.length} ${widget.clases.length == 1 ? "clase" : "clases"}',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    AnimatedRotation(
                      turns: _expandido ? 0.5 : 0,
                      duration: Duration(milliseconds: 200),
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Lista de clases (colapsable)
          AnimatedSize(
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _expandido
                ? Column(
                    children: widget.clases.asMap().entries.map((entry) {
                      final index = entry.key;
                      final doc = entry.value;
                      final data = doc.data() as Map<String, dynamic>;

                      return _ClaseHistorialCard(
                        claseDoc: doc,
                        claseData: data,
                        buildResultadoTile: widget.buildResultadoTile,
                        copyToClipboard: widget.copyToClipboard,
                        isLast: index == widget.clases.length - 1,
                      );
                    }).toList(),
                  )
                : SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _ClaseHistorialCard extends StatelessWidget {
  final DocumentSnapshot claseDoc;
  final Map<String, dynamic> claseData;
  final Widget Function(Map<String, dynamic>, bool) buildResultadoTile;
  final void Function(BuildContext, String) copyToClipboard;
  final bool isLast;

  const _ClaseHistorialCard({
    Key? key,
    required this.claseDoc,
    required this.claseData,
    required this.buildResultadoTile,
    required this.copyToClipboard,
    required this.isLast,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // ✅ Formatear fecha de finalización
    String fechaFormateada = 'Sin fecha';
    if (claseData['fechaFinalizacion'] != null) {
      final fecha = (claseData['fechaFinalizacion'] as Timestamp).toDate();
      fechaFormateada = DateFormat('MMMM yyyy', 'es_ES').format(fecha);
      // Capitalizar primera letra del mes
      fechaFormateada =
          fechaFormateada[0].toUpperCase() + fechaFormateada.substring(1);
    }

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: isLast
              ? BorderSide.none
              : BorderSide(color: Colors.grey[200]!, width: 1),
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.all(16),
          childrenPadding: EdgeInsets.zero,
          leading: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.history, color: Colors.grey[700], size: 28),
          ),
          title: Text(
            claseData['tipo'] ?? '',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A5968),
            ),
          ),
          subtitle: Padding(
            padding: EdgeInsets.only(top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✅ Fecha formateada de manera clara
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.event_available,
                          size: 16, color: Colors.grey[700]),
                      SizedBox(width: 6),
                      Text(
                        'Finalizada en $fechaFormateada',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                ),
                if (claseData['maestroNombre'] != null) ...[
                  SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.person, size: 16, color: Color(0xFF2B7A8C)),
                      SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          claseData['maestroNombre'],
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF2B7A8C),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
              ),
              child: Column(
                children: [
                  // Historial de maestros
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('cambiosMaestrosDiscipulado')
                        .where('claseId', isEqualTo: claseDoc.id)
                        .orderBy('fechaCambio')
                        .snapshots(),
                    builder: (context, cambiosSnap) {
                      if (cambiosSnap.hasData &&
                          cambiosSnap.data!.docs.isNotEmpty) {
                        return Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            border: Border(
                              bottom: BorderSide(
                                  color: Colors.grey[200]!, width: 1),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.swap_horiz,
                                      color: Colors.blue[700], size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Historial de Maestros',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.blue[900],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12),
                              ...cambiosSnap.data!.docs.map((cambioDoc) {
                                final cambio =
                                    cambioDoc.data() as Map<String, dynamic>;
                                return Container(
                                  margin: EdgeInsets.only(bottom: 12),
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border:
                                        Border.all(color: Colors.blue[200]!),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.person,
                                              size: 16,
                                              color: Colors.grey[600]),
                                          SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              cambio['maestroAnteriorNombre'],
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: Colors.grey[800],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        'Módulos ${cambio['moduloInicioAnterior']} - ${cambio['moduloFinAnterior']}',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600]),
                                      ),
                                      Padding(
                                        padding:
                                            EdgeInsets.symmetric(vertical: 6),
                                        child: Icon(Icons.arrow_downward,
                                            size: 16, color: Colors.blue[400]),
                                      ),
                                      Row(
                                        children: [
                                          Icon(Icons.person,
                                              size: 16,
                                              color: Colors.green[600]),
                                          SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              cambio['maestroNuevoNombre'],
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: Colors.green[800],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        'Desde módulo ${cambio['moduloInicioNuevo']}',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600]),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ],
                          ),
                        );
                      }
                      return SizedBox.shrink();
                    },
                  ),
                  // Resultados
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('resultadosDiscipulado')
                        .where('claseId', isEqualTo: claseDoc.id)
                        .snapshots(),
                    builder: (context, resultadosSnap) {
                      if (!resultadosSnap.hasData ||
                          resultadosSnap.data!.docs.isEmpty) {
                        return Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(
                            child: Text(
                              'No hay resultados registrados',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ),
                        );
                      }

                      final aprobados = resultadosSnap.data!.docs
                          .where((doc) =>
                              (doc.data()
                                  as Map<String, dynamic>)['aprobado'] ==
                              true)
                          .toList();

                      final reprobados = resultadosSnap.data!.docs
                          .where((doc) =>
                              (doc.data()
                                  as Map<String, dynamic>)['aprobado'] ==
                              false)
                          .toList();

                      return _ResultadosColapsables(
                        aprobados: aprobados,
                        reprobados: reprobados,
                        buildResultadoTile: buildResultadoTile,
                        copyToClipboard: copyToClipboard,
                      );
                    },
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
