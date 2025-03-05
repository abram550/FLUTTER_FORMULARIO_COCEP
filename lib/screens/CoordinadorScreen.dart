import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'TimoteosScreen.dart';
import '../utils/email_service.dart';
import 'package:table_calendar/table_calendar.dart';

// Color scheme based on the COCEP logo
const kPrimaryColor = Color(0xFF1B8C8C); // Turquesa
const kSecondaryColor = Color(0xFFFF4D2E); // Naranja/rojo
const kAccentColor = Color(0xFFFFB800); // Amarillo
const kBackgroundColor = Color(0xFFF5F7FA); // Gris muy claro para el fondo
const kTextLightColor = Color(0xFFF5F7FA); // For text on dark backgrounds
const kTextDarkColor = Color(0xFF2D3748); // For text on light backgrounds
const kCardColor = Colors.white; // Color for cards

class CoordinadorScreen extends StatelessWidget {
  final String coordinadorId;
  final String coordinadorNombre;

  const CoordinadorScreen({
    Key? key,
    required this.coordinadorId,
    required this.coordinadorNombre,
  }) : super(key: key);

  Future<Map<String, dynamic>> obtenerDatosTribu() async {
    var coordinadorSnapshot = await FirebaseFirestore.instance
        .collection('coordinadores')
        .doc(coordinadorId)
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
              title: Row(
                children: [
                  Hero(
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
                      child: CircleAvatar(
                        backgroundColor: kAccentColor.withOpacity(0.2),
                        child: Icon(Icons.person, color: kPrimaryColor),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Coordinador',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                        Text(
                          coordinadorNombre,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.refresh, color: Colors.white),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Actualizando datos...'),
                          backgroundColor: kSecondaryColor,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
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
              children: [
                CustomTabContent(
                  child: TimoteosTab(coordinadorId: coordinadorId),
                  icon: Icons.people,
                  title: 'Timoteos',
                  description: 'Gestiona los timoteos a tu cargo',
                ),
                CustomTabContent(
                  child: PersonasAsignadasTab(coordinadorId: coordinadorId),
                  icon: Icons.assignment_ind,
                  title: 'Personas Asignadas',
                  description: 'Administra las personas asignadas a tu grupo',
                ),
                CustomTabContent(
                  child: AlertasTab(coordinadorId: coordinadorId),
                  icon: Icons.warning_amber_rounded,
                  title: 'Alertas Pendientes',
                  description: 'Revisa las alertas que requieren tu atención',
                ),
                CustomTabContent(
                  child: AsistenciasCoordinadorTab(
                    tribuId: tribuId,
                    categoriaTribu: categoriaTribu,
                    coordinadorId: coordinadorId,
                  ),
                  icon: Icons.calendar_today,
                  title: 'Registro de Asistencia',
                  description: 'Gestiona la asistencia de tu grupo',
                ),
              ],
            ),
            floatingActionButton: Builder(
              builder: (context) {
                final tabController = DefaultTabController.of(context);
                if (tabController?.index == 3) {
                  // Solo muestra el botón en Asistencia
                  return FloatingActionButton(
                    backgroundColor: kSecondaryColor,
                    child: Icon(Icons.add, color: Colors.white),
                    onPressed: () {
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
                            // Aquí puedes conectar con la lógica real de registro
                            print('Registrar nuevo joven');
                          },
                        ),
                      );
                    },
                  );
                }
                return SizedBox.shrink(); // Oculta el botón en otras pestañas
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: kTextDarkColor,
            ),
          ),
        ],
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
  final String coordinadorId; // Añadido

  const AsistenciasCoordinadorTab({
    Key? key,
    required this.tribuId,
    required this.categoriaTribu,
    required this.coordinadorId, // Añadido
  }) : super(key: key);

  @override
  _AsistenciasCoordinadorTabState createState() =>
      _AsistenciasCoordinadorTabState();
}

class _AsistenciasCoordinadorTabState extends State<AsistenciasCoordinadorTab> {
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _apellidoController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
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

    // Asegurar que se devuelve el nombre correcto del servicio
    if (servicios.containsKey(categoriaTribu) &&
        servicios[categoriaTribu]!.containsKey(diaSemana)) {
      return servicios[categoriaTribu]![diaSemana]!;
    }

    return "Reunión General";
  }

// Añadir este método en la clase CoordinadorScreen
  Stream<QuerySnapshot> obtenerAsistenciasPorCoordinadorYTribu(
      String tribuId, String categoriaTribu) {
    return FirebaseFirestore.instance
        .collection('asistencias')
        .where('tribuId', isEqualTo: widget.tribuId)
        .where('categoriaTribu', isEqualTo: widget.categoriaTribu)
        .snapshots();
  }

  Stream<QuerySnapshot> obtenerAsistenciasPorCoordinador(String coordinadorId) {
    return FirebaseFirestore.instance
        .collection('asistencias')
        .where('coordinadorId', isEqualTo: coordinadorId)
        .snapshots();
  }

  Future<void> _registrarNuevoJoven() async {
    _nombreController.clear();
    _apellidoController.clear();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Registrar Nuevo Discípulo'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nombreController,
                decoration: InputDecoration(
                  labelText: 'Nombre',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _apellidoController,
                decoration: InputDecoration(
                  labelText: 'Apellido',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_nombreController.text.trim().isEmpty ||
                  _apellidoController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('Por favor complete todos los campos')),
                );
                return;
              }

              try {
                final String nombreCompleto =
                    '${_nombreController.text.trim()} ${_apellidoController.text.trim()}';

                // Obtener la categoría de la tribu desde Firestore
                DocumentSnapshot tribuDoc = await FirebaseFirestore.instance
                    .collection('tribus')
                    .doc(widget.tribuId)
                    .get();

                final String categoriaTribu = tribuDoc.exists
                    ? (tribuDoc['categoria'] ?? widget.categoriaTribu)
                    : widget.categoriaTribu;

                // Guardar en la nueva colección "Persona_asistencia"
                // Dentro del método _registrarNuevoJoven, cuando se añade a la colección 'Persona_asistencia'
                await FirebaseFirestore.instance
                    .collection('Persona_asistencia')
                    .add({
                  'nombre': _nombreController.text.trim(),
                  'apellido': _apellidoController.text.trim(),
                  'nombreCompleto': nombreCompleto,
                  'tribuId': widget.tribuId,
                  'categoriaTribu': categoriaTribu,
                  'coordinadorId': widget.coordinadorId, // Añadido
                  'fechaRegistro': FieldValue.serverTimestamp(),
                  'asistencias': [],
                  'faltasConsecutivas': 0,
                  'jovenId': '', // Agregado para compatibilidad
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Discípulo registrado correctamente')),
                );
                setState(() {});
              } catch (e) {
                print('Error al registrar: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error al registrar: $e')),
                );
              }
            },
            child: Text('Guardar'),
          ),
        ],
      ),
    );
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

  Future<void> _registrarAsistencia(DocumentSnapshot joven) async {
    final data = joven.data() as Map<String, dynamic>;
    final nombre = data['nombre'] ?? '';
    final apellido = data['apellido'] ?? '';
    DateTime selectedDate = DateTime.now();
    bool asistio = true;

    // Obtener la categoría de la tribu desde Firestore antes de registrar la asistencia
    DocumentSnapshot tribuDoc = await FirebaseFirestore.instance
        .collection('tribus')
        .doc(widget.tribuId)
        .get();

    final String categoriaTribu =
        tribuDoc.exists ? (tribuDoc['categoria'] ?? "General") : "General";

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Registrar Asistencia'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Discípulo: $nombre $apellido',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: Icon(Icons.calendar_today),
                  label: Text('Seleccionar Fecha'),
                  onPressed: () async {
                    final DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now().subtract(Duration(days: 30)),
                      lastDate: DateTime.now(),
                    );

                    if (pickedDate != null && pickedDate != selectedDate) {
                      setState(() {
                        selectedDate = pickedDate;
                      });
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
                  subtitle:
                      Text(obtenerNombreServicio(categoriaTribu, selectedDate)),
                  trailing: Switch(
                    value: asistio,
                    onChanged: (value) {
                      setState(() {
                        asistio = value;
                      });
                    },
                  ),
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
                  try {
                    final String nombreServicio =
                        obtenerNombreServicio(categoriaTribu, selectedDate);

                    // Registrar la asistencia en la colección "asistencias"
                    await FirebaseFirestore.instance
                        .collection('asistencias')
                        .add({
                      'jovenId': joven.id,
                      'nombre': nombre,
                      'apellido': apellido,
                      'nombreCompleto': '$nombre $apellido',
                      'tribuId': widget.tribuId,
                      'categoriaTribu': categoriaTribu,
                      'coordinadorId': widget.coordinadorId, // Añadido
                      'fecha': Timestamp.fromDate(selectedDate),
                      'nombreServicio': nombreServicio,
                      'asistio': asistio,
                      'diaSemana':
                          DateFormat('EEEE', 'es').format(selectedDate),
                    });
                    // Actualizar la información de faltas en "Persona_asistencia"
                    await joven.reference.update({
                      'ultimaAsistencia': Timestamp.fromDate(selectedDate),
                      'faltasConsecutivas':
                          asistio ? 0 : (data['faltasConsecutivas'] ?? 0) + 1,
                    });

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('Asistencia registrada correctamente')),
                    );
                  } catch (e) {
                    print('Error al registrar asistencia: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error al registrar asistencia')),
                    );
                  }
                },
                child: Text('Guardar'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _editarJoven(DocumentSnapshot joven) async {
    final data = joven.data() as Map<String, dynamic>;
    _nombreController.text = data['nombre'] ?? '';
    _apellidoController.text = data['apellido'] ?? '';

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Editar Discípulo'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nombreController,
                decoration: InputDecoration(
                  labelText: 'Nombre',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _apellidoController,
                decoration: InputDecoration(
                  labelText: 'Apellido',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_nombreController.text.trim().isEmpty ||
                  _apellidoController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('Por favor complete todos los campos')),
                );
                return;
              }

              try {
                await joven.reference.update({
                  'nombre': _nombreController.text.trim(),
                  'apellido': _apellidoController.text.trim(),
                  'nombreCompleto':
                      '${_nombreController.text.trim()} ${_apellidoController.text.trim()}',
                  'tribuId': widget.tribuId,
                  'categoriaTribu': widget.categoriaTribu,
                });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('Información actualizada correctamente')),
                );
                setState(() {}); // Refrescar la UI
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error al actualizar: $e')),
                );
              }
            },
            child: Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _eliminarJoven(DocumentSnapshot joven) async {
    final data = joven.data() as Map<String, dynamic>;
    final nombre = data['nombre'] ?? '';
    final apellido = data['apellido'] ?? '';

    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmar eliminación'),
        content: Text(
            '¿Está seguro que desea eliminar a $nombre $apellido? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context); // Cerrar el diálogo primero
              try {
                // También eliminar todos los registros de asistencia relacionados
                final QuerySnapshot asistencias = await FirebaseFirestore
                    .instance
                    .collection('asistencias')
                    .where('jovenId', isEqualTo: joven.id)
                    .get();

                // Crear una transacción para eliminar todo en una sola operación
                final WriteBatch batch = FirebaseFirestore.instance.batch();
                batch.delete(joven.reference);

                for (var doc in asistencias.docs) {
                  batch.delete(doc.reference);
                }

                await batch.commit();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Discípulo eliminado correctamente')),
                );
                setState(() {}); // Refrescar la UI explícitamente
              } catch (e) {
                print('Error al eliminar: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error al eliminar: $e')),
                );
              }
            },
            child: Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Widget _buildAsistenciasCalendario(DocumentSnapshot joven) {
    final data = joven.data() as Map<String, dynamic>;

    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('asistencias')
          .where('jovenId', isEqualTo: joven.id)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Text('Error al cargar asistencias: ${snapshot.error}');
        }

        final asistencias = snapshot.data?.docs ?? [];
        final Map<DateTime, bool> asistenciaMap = {};

        for (var asistenciaDoc in asistencias) {
          final asistenciaData = asistenciaDoc.data() as Map<String, dynamic>;
          if (asistenciaData['fecha'] is Timestamp) {
            final fecha = (asistenciaData['fecha'] as Timestamp).toDate();
            // Normalizar la fecha quitando la información de hora
            final fechaSinHora = DateTime(fecha.year, fecha.month, fecha.day);
            asistenciaMap[fechaSinHora] = asistenciaData['asistio'] ?? false;
          }
        }

        return Column(
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
                    final fechaSinHora =
                        DateTime(date.year, date.month, date.day);
                    if (asistenciaMap.containsKey(fechaSinHora)) {
                      final asistio = asistenciaMap[fechaSinHora]!;
                      return Positioned(
                        bottom: 1,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                asistio ? Color(0xFF147B7C) : Color(0xFFFF4B2B),
                          ),
                          width: 8,
                          height: 8,
                        ),
                      );
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      floatingActionButton: FloatingActionButton(
        onPressed: _registrarNuevoJoven,
        backgroundColor: Color(0xFF147B7C),
        child: Icon(Icons.add),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Registro de Asistencias',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF147B7C),
              ),
            ),
          ),
          // Reemplaza el StreamBuilder actual en el método build de _AsistenciasCoordinadorTabState
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Persona_asistencia')
                  .where('coordinadorId',
                      isEqualTo: widget
                          .coordinadorId) // Modificado: filtrar por coordinadorId
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFF147B7C)),
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
                          'No hay discípulos registrados',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Presiona + para agregar un nuevo discípulo',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Filtrar los documentos localmente si es necesario
                final filteredDocs = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  // Si no tiene categoriaTribu o si coincide con la esperada
                  return !data.containsKey('categoriaTribu') ||
                      data['categoriaTribu'] == widget.categoriaTribu ||
                      widget.categoriaTribu.isEmpty;
                }).toList();

                if (filteredDocs.isEmpty) {
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
                          'No hay discípulos para esta categoría',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final joven = filteredDocs[index];
                    final data = joven.data() as Map<String, dynamic>;

                    final nombre = data['nombre'] ?? '';
                    final apellido = data['apellido'] ?? '';
                    final faltas = data['faltasConsecutivas'] ?? 0;

                    Color cardColor = Colors.white;
                    if (faltas >= 3) {
                      cardColor = Color(0xFFFF4B2B).withOpacity(0.1);
                    }

                    return Card(
                      elevation: 2,
                      margin: EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      color: cardColor,
                      child: ExpansionTile(
                        tilePadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
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
                        trailing: PopupMenuButton<String>(
                          icon: Icon(
                            Icons.more_vert,
                            color: Color(0xFF147B7C),
                          ),
                          onSelected: (value) {
                            if (value == 'asistencia') {
                              _registrarAsistencia(joven);
                            } else if (value == 'editar') {
                              _editarJoven(joven);
                            } else if (value == 'eliminar') {
                              _eliminarJoven(joven);
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'asistencia',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    color: Color(0xFF147B7C),
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text('Registrar Asistencia'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'editar',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.edit,
                                    color: Color(0xFF147B7C),
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text('Editar'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'eliminar',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text('Eliminar'),
                                ],
                              ),
                            ),
                          ],
                        ),
                        children: [
                          Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        icon: Icon(Icons.calendar_today),
                                        label: Text('Registrar Asistencia'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Color(0xFF147B7C),
                                          foregroundColor: Colors.white,
                                          padding: EdgeInsets.symmetric(
                                              vertical: 12),
                                        ),
                                        onPressed: () =>
                                            _registrarAsistencia(joven),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 16),
                                _buildAsistenciasCalendario(joven),
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
            'key': 'descripcionOcupacion',
            'label': 'Descripción',
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
      // Modificación dentro de la función _mostrarDetallesRegistro existente
// Agregar estos campos en la sección de 'Notas'
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
    ];

    // Crear lista de widgets para el contenido del diálogo
    List<Widget> contenidoWidgets = [];

    // Procesar cada sección
    for (var seccion in secciones) {
      // Filtrar solo los campos que contienen datos en esta sección
      final camposConDatos = (seccion['campos'] as List).where((campo) {
        final key = campo['key'] as String;

        // Verificamos que el campo exista y no sea nulo ni vacío
        if (!data.containsKey(key)) return false;

        final value = data[key];
        if (value == null) return false;

        // Para listas, verificamos que no estén vacías
        if (value is List) return value.isNotEmpty;

        // Para strings, verificamos que no estén vacías
        if (value is String) return value.trim().isNotEmpty;

        // Para otros tipos de datos (números, booleanos), consideramos que tienen valor
        return true;
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
          final key = campo['key'] as String;
          final label = campo['label'] as String;
          final icon = campo['icon'] as IconData;
          final esFecha = campo['esFecha'] as bool? ?? false;

          // Obtenemos y formateamos el valor de forma segura
          var value = data[key];
          String textoValor;

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

          // Añadir widget de detalle
          contenidoWidgets.add(
            _buildDetalle(label, textoValor, icon, accentGrey, primaryTeal),
          );
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
                Text(
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

    return Container(
      color: backgroundGrey,
      child: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('registros')
            .where('coordinadorAsignado', isEqualTo: coordinadorId)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: primaryTeal),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_off, size: 64, color: accentGrey),
                  SizedBox(height: 16),
                  Text(
                    'No hay personas registradas',
                    style: TextStyle(
                      fontSize: 18,
                      color: accentGrey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          final asignados = snapshot.data!.docs.where((doc) {
            try {
              return doc.get('timoteoAsignado') != null;
            } catch (e) {
              return false;
            }
          }).toList();

          final noAsignados = snapshot.data!.docs.where((doc) {
            try {
              return doc.get('timoteoAsignado') == null;
            } catch (e) {
              return true;
            }
          }).toList();

          // Contador de personas asignadas al coordinador
          final totalPersonasAsignadas = snapshot.data!.docs.length;

          return SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                // Contador de personas asignadas
                Container(
                  margin: EdgeInsets.only(bottom: 16),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [primaryTeal, primaryTeal.withOpacity(0.8)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: primaryTeal.withOpacity(0.2),
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
                            '$totalPersonasAsignadas',
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
                          _buildCounterBadge('Asignados', asignados.length,
                              primaryTeal, Colors.white),
                          SizedBox(height: 8),
                          _buildCounterBadge('Por asignar', noAsignados.length,
                              secondaryOrange, Colors.white),
                        ],
                      ),
                    ],
                  ),
                ),

                if (noAsignados.isNotEmpty) ...[
                  _buildSectionHeader(
                    'Personas por asignar',
                    Icons.person_add_alt,
                    secondaryOrange,
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: noAsignados.length,
                    itemBuilder: (context, index) => _buildPersonCard(
                      context,
                      noAsignados[index],
                      isAssigned: false,
                      primaryTeal: primaryTeal,
                      secondaryOrange: secondaryOrange,
                      accentGrey: accentGrey,
                    ),
                  ),
                  SizedBox(height: 24),
                ],
                if (asignados.isNotEmpty) ...[
                  _buildSectionHeader(
                    'Personas asignadas',
                    Icons.people,
                    primaryTeal,
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: asignados.length,
                    itemBuilder: (context, index) => _buildPersonCard(
                      context,
                      asignados[index],
                      isAssigned: true,
                      primaryTeal: primaryTeal,
                      secondaryOrange: secondaryOrange,
                      accentGrey: accentGrey,
                    ),
                  ),
                ],
              ],
            ),
          );
        },
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

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
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
              title == 'Personas por asignar' ? 'Pendientes' : 'Activos',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w500,
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
    required Color primaryTeal,
    required Color secondaryOrange,
    required Color accentGrey,
  }) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isAssigned ? primaryTeal.withOpacity(0.2) : Colors.transparent,
          width: 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: isAssigned
                      ? primaryTeal.withOpacity(0.1)
                      : secondaryOrange.withOpacity(0.1),
                  radius: 24,
                  child: Text(
                    '${registro.get('nombre')[0]}${registro.get('apellido')[0]}',
                    style: TextStyle(
                      color: isAssigned ? primaryTeal : secondaryOrange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${registro.get('nombre')} ${registro.get('apellido')}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.phone,
                            size: 16,
                            color: accentGrey,
                          ),
                          SizedBox(width: 4),
                          Text(
                            registro.get('telefono'),
                            style: TextStyle(
                              color: accentGrey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (isAssigned) ...[
              Divider(height: 24),
              Row(
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 16,
                    color: accentGrey,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Asignado a: ',
                    style: TextStyle(color: accentGrey),
                  ),
                  Text(
                    registro.get('nombreTimoteo'),
                    style: TextStyle(
                      color: primaryTeal,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Añadido botón de ver detalles
                _buildActionButton(
                  icon: Icons.visibility_outlined,
                  label: 'Ver detalles',
                  color: primaryTeal,
                  onPressed: () {
                    _mostrarDetallesRegistro(
                      context,
                      registro.data() as Map<String, dynamic>,
                    );
                  },
                ),
                SizedBox(width: 8),
                if (!isAssigned)
                  _buildActionButton(
                    icon: Icons.person_add,
                    label: 'Asignar',
                    color: secondaryOrange,
                    onPressed: () => _asignarATimoteo(context, registro),
                  )
                else
                  _buildActionButton(
                    icon: Icons.person_remove,
                    label: 'Desasignar',
                    color: Colors.red,
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
                            content: Text('Registro desasignado exitosamente'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content:
                                Text('Error al desasignar el registro: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                  ),
                SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.copy, color: primaryTeal),
                  tooltip: 'Copiar teléfono',
                  onPressed: () {
                    Clipboard.setData(
                      ClipboardData(text: registro.get('telefono')),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Teléfono copiado al portapapeles'),
                        duration: Duration(seconds: 1),
                        backgroundColor: primaryTeal,
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      onPressed: onPressed,
    );
  }
}
