import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.claseAsignadaId == null) {
      return _buildSinClaseAsignada();
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('clasesDiscipulado')
          .doc(widget.claseAsignadaId)
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

        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: _buildAppBar(tipoClase),
          body: Column(
            children: [
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTomarAsistenciaTab(claseData),
                    _buildVerAsistenciasTab(claseData),
                  ],
                ),
              ),
            ],
          ),
          floatingActionButton: _buildFloatingButton(),
        );
      },
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
        Container(
          margin: EdgeInsets.only(right: 8),
          child: IconButton(
            icon: Icon(Icons.logout_rounded, color: Colors.white),
            tooltip: 'Cerrar Sesión',
            onPressed: () => context.go('/login'),
          ),
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

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('asistenciasDiscipulado')
          .where('claseId', isEqualTo: widget.claseAsignadaId)
          .snapshots(),
      builder: (context, asistenciasSnap) {
        int modulosCompletados = 0;
        if (asistenciasSnap.hasData) {
          modulosCompletados = asistenciasSnap.data!.docs
              .map((doc) =>
                  (doc.data() as Map<String, dynamic>)['numeroModulo'] as int)
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
                            label: 'Módulos',
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
      },
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

        // ✅ REEMPLAZAR SECCIÓN DE BOTONES (después de _buildClassHeader)
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
              // ✅ OCULTAR BOTÓN SI INSCRIPCIONES CERRADAS
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
                if (discipulo['registradoPorMaestro'] == true)
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
                                        child: Text(
                                          ministerio,
                                          overflow: TextOverflow.ellipsis,
                                        ),
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
                                          child: Text(
                                            'Cancelar',
                                            style: TextStyle(
                                                color: Colors.grey[700]),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () async {
                                            if (formKey.currentState!
                                                .validate()) {
                                              final claseDoc =
                                                  await FirebaseFirestore
                                                      .instance
                                                      .collection(
                                                          'clasesDiscipulado')
                                                      .doc(widget
                                                          .claseAsignadaId)
                                                      .get();

                                              final claseData = claseDoc.data()
                                                  as Map<String, dynamic>;
                                              final discipulos = List<
                                                      Map<String,
                                                          dynamic>>.from(
                                                  claseData[
                                                          'discipulosInscritos'] ??
                                                      []);

                                              final personaId =
                                                  'maestro_${DateTime.now().millisecondsSinceEpoch}';

                                              discipulos.add({
                                                'personaId': personaId,
                                                'nombre': nombreController.text
                                                    .trim(),
                                                'telefono': telefonoController
                                                    .text
                                                    .trim(),
                                                'tribu':
                                                    tribuController.text.trim(),
                                                'ministerio':
                                                    ministerioSeleccionado,
                                                'registradoPorMaestro': true,
                                              });

                                              await FirebaseFirestore.instance
                                                  .collection(
                                                      'clasesDiscipulado')
                                                  .doc(widget.claseAsignadaId)
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
                                                          color: Colors.white),
                                                      SizedBox(width: 12),
                                                      Flexible(
                                                        child: Text(
                                                            'Discípulo registrado exitosamente'),
                                                      ),
                                                    ],
                                                  ),
                                                  backgroundColor: Colors.green,
                                                  behavior:
                                                      SnackBarBehavior.floating,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                  ),
                                                ),
                                              );
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

// ========================================
// MODIFICACIÓN 5: Actualizar _editarDiscipulo
// REEMPLAZA el método _editarDiscipulo completo
// ========================================

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
                                        child: Text(
                                          ministerio,
                                          overflow: TextOverflow.ellipsis,
                                        ),
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
                                          child: Text(
                                            'Cancelar',
                                            style: TextStyle(
                                                color: Colors.grey[700]),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () async {
                                            if (formKey.currentState!
                                                .validate()) {
                                              final claseDoc =
                                                  await FirebaseFirestore
                                                      .instance
                                                      .collection(
                                                          'clasesDiscipulado')
                                                      .doc(widget
                                                          .claseAsignadaId)
                                                      .get();

                                              final claseData = claseDoc.data()
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
                                                discipulos[index] = {
                                                  'personaId':
                                                      discipulo['personaId'],
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
                                                };

                                                await FirebaseFirestore.instance
                                                    .collection(
                                                        'clasesDiscipulado')
                                                    .doc(widget.claseAsignadaId)
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
                                                              'Discípulo actualizado'),
                                                        ),
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

    // ✅ OBTENER CONFIGURACIÓN DE LA CLASE
    final claseDoc = await FirebaseFirestore.instance
        .collection('clasesDiscipulado')
        .doc(widget.claseAsignadaId)
        .get();

    final claseData = claseDoc.data() as Map<String, dynamic>;
    final totalModulos = claseData['totalModulos'] as int;

    // ✅ NUEVO: Obtener módulo inicial permitido (por defecto 1)
    final moduloInicialPermitido =
        claseData['moduloInicialPermitido'] as int? ?? 1;

    // ✅ Obtener asistencias ya registradas
    final asistenciasRegistradas = await FirebaseFirestore.instance
        .collection('asistenciasDiscipulado')
        .where('claseId', isEqualTo: widget.claseAsignadaId)
        .get();

    Set<int> modulosYaRegistrados = {};
    for (var doc in asistenciasRegistradas.docs) {
      final data = doc.data();
      modulosYaRegistrados.add(data['numeroModulo'] as int);
    }

    // ✅ MODIFICADO: Calcular siguiente módulo considerando el inicial permitido
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
                                // ✅ NUEVO: Indicador visual del módulo inicial
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
                                            'Clase en progreso: Iniciando desde módulo $moduloInicialPermitido',
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
                                    labelText: 'Módulo',
                                    helperText:
                                        'Siguiente: Módulo $siguienteModulo',
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
                                  // ✅ MODIFICADO: Generar lista desde moduloInicialPermitido
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
                                          'Módulo $modulo${yaRegistrado ? " ✓" : ""}',
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
                                                'Selecciona el número de módulo'),
                                            backgroundColor: Colors.orange,
                                          ),
                                        );
                                        return;
                                      }
                                      for (var discipulo in discipulos) {
                                        final personaId =
                                            discipulo['personaId'];
                                        final asistio =
                                            asistencias[personaId] ?? false;
                                        await FirebaseFirestore.instance
                                            .collection(
                                                'asistenciasDiscipulado')
                                            .add({
                                          'claseId': widget.claseAsignadaId,
                                          'discipuloId': personaId,
                                          'discipuloNombre':
                                              discipulo['nombre'],
                                          'numeroModulo': numeroModulo,
                                          'asistio': asistio,
                                          'fecha': Timestamp.fromDate(
                                              fechaSeleccionada),
                                          'maestroId': widget.maestroId,
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
                                                      'Asistencia del Módulo $numeroModulo registrada')),
                                            ],
                                          ),
                                          backgroundColor: Colors.green,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10)),
                                        ),
                                      );
                                      setState(() {});
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
                                                    'Selecciona el número de módulo'),
                                                backgroundColor: Colors.orange,
                                              ),
                                            );
                                            return;
                                          }
                                          for (var discipulo in discipulos) {
                                            final personaId =
                                                discipulo['personaId'];
                                            final asistio =
                                                asistencias[personaId] ?? false;
                                            await FirebaseFirestore.instance
                                                .collection(
                                                    'asistenciasDiscipulado')
                                                .add({
                                              'claseId': widget.claseAsignadaId,
                                              'discipuloId': personaId,
                                              'discipuloNombre':
                                                  discipulo['nombre'],
                                              'numeroModulo': numeroModulo,
                                              'asistio': asistio,
                                              'fecha': Timestamp.fromDate(
                                                  fechaSeleccionada),
                                              'maestroId': widget.maestroId,
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
                                                          'Asistencia del Módulo $numeroModulo registrada')),
                                                ],
                                              ),
                                              backgroundColor: Colors.green,
                                              behavior:
                                                  SnackBarBehavior.floating,
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          10)),
                                            ),
                                          );
                                          setState(() {});
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

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('asistenciasDiscipulado')
          .where('claseId', isEqualTo: widget.claseAsignadaId)
          .snapshots(),
      builder: (context, asistenciasSnap) {
        if (asistenciasSnap.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: cocepTeal),
          );
        }

        Map<String, Map<String, dynamic>> estadisticas = {};

        for (var discipulo in discipulos) {
          final personaId = discipulo['personaId'];
          estadisticas[personaId] = {
            'nombre': discipulo['nombre'],
            'telefono': discipulo['telefono'],
            'tribu': discipulo['tribu'],
            'ministerio': discipulo['ministerio'],
            'asistencias': 0,
            'faltas': 0,
            'modulosFaltados': <int>[],
            'modulosAsistidos': <int>[],
            'aprobado': null,
          };
        }

        if (asistenciasSnap.hasData) {
          for (var doc in asistenciasSnap.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final personaId = data['discipuloId'];
            final numeroModulo = data['numeroModulo'] as int;

            if (estadisticas.containsKey(personaId)) {
              if (data['asistio'] == true) {
                estadisticas[personaId]!['asistencias']++;
                (estadisticas[personaId]!['modulosAsistidos'] as List<int>)
                    .add(numeroModulo);
              } else {
                estadisticas[personaId]!['faltas']++;
                (estadisticas[personaId]!['modulosFaltados'] as List<int>)
                    .add(numeroModulo);
              }
            }
          }

          estadisticas.forEach((personaId, stats) {
            final faltas = stats['faltas'] as int;
            stats['aprobado'] = faltas < 2;
          });
        }

        return ListView.builder(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 100),
          itemCount: estadisticas.length,
          itemBuilder: (context, index) {
            final personaId = estadisticas.keys.elementAt(index);
            final stats = estadisticas[personaId]!;
            return _buildEstadisticaCard(stats);
          },
        );
      },
    );
  }

  Widget _buildEstadisticaCard(Map<String, dynamic> stats) {
    final aprobado = stats['aprobado'];
    final faltas = stats['faltas'];
    final asistencias = stats['asistencias'];
    final nombreTribu = stats['tribu']?.toString() ?? 'Sin tribu';
    final nombre = stats['nombre'] ?? 'Sin nombre';
    final inicial = nombre.isNotEmpty ? nombre[0].toUpperCase() : '?';
    final modulosFaltados = List<int>.from(stats['modulosFaltados'] ?? []);
    final modulosAsistidos = List<int>.from(stats['modulosAsistidos'] ?? []);

    modulosFaltados.sort();
    modulosAsistidos.sort();

    Color statusColor = aprobado == true
        ? Colors.green
        : aprobado == false
            ? Colors.red
            : Colors.grey;

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
                ],
              ),
              if (aprobado != null) ...[
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
                          'Módulos Asistidos',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: modulosAsistidos.map((modulo) {
                        return Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: Colors.green.withOpacity(0.3)),
                          ),
                          child: Text(
                            'M$modulo',
                            style: TextStyle(
                              color: Colors.green[700],
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                  if (modulosFaltados.isNotEmpty) ...[
                    SizedBox(height: 16),
                    Divider(),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.cancel, size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text(
                          'Módulos Faltados',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red[700],
                            fontSize: 14,
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
                            'M$modulo',
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
      final claseDoc = await FirebaseFirestore.instance
          .collection('clasesDiscipulado')
          .doc(widget.claseAsignadaId)
          .get();

      final claseData = claseDoc.data() as Map<String, dynamic>;
      final discipulos = List<Map<String, dynamic>>.from(
          claseData['discipulosInscritos'] ?? []);

      final asistenciasSnap = await FirebaseFirestore.instance
          .collection('asistenciasDiscipulado')
          .where('claseId', isEqualTo: widget.claseAsignadaId)
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
              totalFaltas++;
              modulosFaltados.add(data['numeroModulo']);
            }
          }
        }

        resultadosCalculados[personaId] = {
          'nombre': discipulo['nombre'],
          'telefono': discipulo['telefono'],
          'tribu':
              discipulo['tribu'], // ✅ TEXTO DIRECTO desde discipulosInscritos
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

      // ✅ AQUÍ ESTÁ EL CAMBIO IMPORTANTE
      for (var discipulo in discipulos) {
        final personaId = discipulo['personaId'];
        final resultado = resultadosCalculados[personaId]!;
        final aprobado =
            resultadosFinales[personaId] ?? resultado['aprobadoSugerido'];

        await FirebaseFirestore.instance
            .collection('resultadosDiscipulado')
            .add({
          'claseId': widget.claseAsignadaId,
          'discipuloId': personaId,
          'discipuloNombre': resultado['nombre'],
          'telefono': resultado['telefono'],
          'tribu': resultado['tribu'], // ✅ GUARDAMOS LA TRIBU COMO TEXTO
          'ministerio': resultado['ministerio'],
          'totalAsistencias': resultado['totalAsistencias'],
          'totalFaltas': resultado['totalFaltas'],
          'faltasDetalle': resultado['modulosFaltados'],
          'aprobado': aprobado,
          'maestroId': widget.maestroId,
          'maestroNombre': widget.maestroNombre,
          'tipoClase': claseData['tipo'],
          'fechaRegistro': FieldValue.serverTimestamp(),
        });
      }

      await FirebaseFirestore.instance
          .collection('clasesDiscipulado')
          .doc(widget.claseAsignadaId)
          .update({
        'estado': 'finalizada',
        'fechaFinalizacion': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance
          .collection('maestrosDiscipulado')
          .doc(widget.maestroId)
          .update({
        'claseAsignadaId': null,
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
                    'Clase finalizada. Ya estás disponible para nuevas asignaciones.',
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

        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        setState(() {});
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
