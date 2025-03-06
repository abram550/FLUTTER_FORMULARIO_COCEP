import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:formulario_app/utils/theme_constants.dart';
import 'package:intl/intl.dart';
import 'TimoteosScreen.dart';
import 'CoordinadorScreen.dart';

class TribusScreen extends StatelessWidget {
  final String tribuId;
  final String tribuNombre;

  const TribusScreen({
    Key? key,
    required this.tribuId,
    required this.tribuNombre,
  }) : super(key: key);

// Función para determinar el ministerio basado en el nombre de la tribu
  String _determinarMinisterio(String tribuNombre) {
    if (tribuNombre.contains('Juvenil')) return 'Ministerio Juvenil';
    if (tribuNombre.contains('Damas')) return 'Ministerio de Damas';
    if (tribuNombre.contains('Caballeros')) return 'Ministerio de Caballeros';
    return 'Otro';
  }

// Función para guardar registro en Firebase
  void _guardarRegistroEnFirebase(BuildContext context,
      Map<String, dynamic> registro, String tribuId) async {
    // Mostrar pantalla de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF038C7F),
        ),
      ),
    );

    try {
      final tribuSnapshot = await FirebaseFirestore.instance
          .collection('tribus')
          .doc(tribuId)
          .get();

      if (!tribuSnapshot.exists) {
        if (context.mounted) {
          Navigator.of(context, rootNavigator: true).pop(); // Cierra el loading
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error: La tribu no existe'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final tribuData = tribuSnapshot.data() as Map<String, dynamic>;
      final tribuNombre = tribuData['nombreTribu'] ?? 'Desconocida';
      final ministerioAsignado = tribuData['ministerioAsignado'] ??
          tribuData['ministerio'] ??
          tribuData['categoria'] ??
          _determinarMinisterio(tribuNombre);

      registro['tribuAsignada'] = tribuId;
      registro['ministerioAsignado'] = ministerioAsignado;

      await FirebaseFirestore.instance.collection('registros').add(registro);

      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // Cierra el loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Registro guardado correctamente'),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // Cierra el loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar el registro: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showRegistroDialog(BuildContext context) {
    final _formKey = GlobalKey<FormState>();

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
    String sexo = '';
    int edad = 0;
    String direccion = '';
    String barrio = '';
    String estadoCivil = 'Soltero(a)';
    String? nombrePareja = 'No aplica';
    List<String> ocupacionesSeleccionadas = [];
    String descripcionOcupaciones = ''; // Single field instead of Map
    bool tieneHijos = false;
    String referenciaInvitacion = '';
    String? observaciones;
    DateTime? fechaAsignacionTribu;

    // StatefulBuilder para manejar estado dinámico
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setState) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Registrar Nuevo Miembro',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B998B))),
                    _buildTextField(
                        'Nombre', Icons.person, (value) => nombre = value),
                    _buildTextField('Apellido', Icons.person_outline,
                        (value) => apellido = value),
                    _buildTextField(
                        'Teléfono', Icons.phone, (value) => telefono = value),
                    _buildDropdown('Sexo', ['Masculino', 'Femenino'],
                        (value) => sexo = value),
                    _buildTextField('Edad', Icons.cake,
                        (value) => edad = int.tryParse(value) ?? 0),
                    _buildTextField('Dirección', Icons.location_on,
                        (value) => direccion = value),
                    _buildTextField(
                        'Barrio', Icons.home, (value) => barrio = value),

                    // Dropdown de Estado Civil
                    _buildDropdown('Estado Civil', _estadosCiviles, (value) {
                      setState(() {
                        estadoCivil = value;
                        // Lógica para nombre de pareja
                        if (estadoCivil == 'Casado(a)' ||
                            estadoCivil == 'Unión Libre') {
                          nombrePareja =
                              ''; // Campo vacío para que puedan escribir
                        } else {
                          nombrePareja = 'No aplica';
                        }
                      });
                    }),

                    // Campo dinámico para nombre de pareja
                    if (estadoCivil == 'Casado(a)' ||
                        estadoCivil == 'Unión Libre')
                      _buildTextField('Nombre de la Pareja', Icons.favorite,
                          (value) => nombrePareja = value),

                    // Ocupaciones con descripción única
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Ocupaciones',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1B998B))),
                        Wrap(
                          spacing: 8,
                          children: _ocupaciones.map((ocupacion) {
                            final isSelected =
                                ocupacionesSeleccionadas.contains(ocupacion);
                            return ChoiceChip(
                              label: Text(ocupacion),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    ocupacionesSeleccionadas.add(ocupacion);
                                  } else {
                                    ocupacionesSeleccionadas.remove(ocupacion);
                                  }
                                });
                              },
                              selectedColor: Color(0xFF1B998B),
                              labelStyle: TextStyle(
                                  color:
                                      isSelected ? Colors.white : Colors.black),
                            );
                          }).toList(),
                        ),

                        // Single description field ONLY when occupations are selected
                        if (ocupacionesSeleccionadas.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: _buildTextField(
                                'Descripción de Ocupaciones',
                                Icons.work_outline,
                                (value) => descripcionOcupaciones = value,
                                isRequired: false),
                          ),
                      ],
                    ),

                    _buildDropdown('Tiene Hijos', ['Sí', 'No'],
                        (value) => tieneHijos = (value == 'Sí')),
                    _buildTextField('Referencia de Invitación', Icons.link,
                        (value) => referenciaInvitacion = value),
                    _buildTextField('Observaciones', Icons.note,
                        (value) => observaciones = value,
                        isRequired: false),
// Campo para seleccionar fecha
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: TextFormField(
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Fecha de Asignación de la Tribu',
                          prefixIcon: Icon(Icons.calendar_today,
                              color: Color(0xFF1B998B)),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (value) => fechaAsignacionTribu == null
                            ? 'Campo obligatorio'
                            : null,
                        onTap: () async {
                          final DateTime? pickedDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2101),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: ColorScheme.light(
                                    primary: Color(0xFF1B998B),
                                    onPrimary: Colors.white,
                                    onSurface: Colors.black,
                                  ),
                                  textButtonTheme: TextButtonThemeData(
                                    style: TextButton.styleFrom(
                                      foregroundColor: Color(0xFFFF7E00),
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

                    // Botones de acción
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('Cancelar'),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFFFF7E00),
                            ),
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
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
                                      descripcionOcupaciones, // Single description field
                                  'tieneHijos': tieneHijos,
                                  'referenciaInvitacion': referenciaInvitacion,
                                  'observaciones': observaciones,
                                  'tribuAsignada': tribuNombre,
                                  'ministerioAsignado':
                                      _determinarMinisterio(tribuNombre),
                                  'coordinadorAsignado': null,
                                  'fechaRegistro': FieldValue.serverTimestamp(),
                                };

                                _guardarRegistroEnFirebase(
                                    context, registro, tribuId);
                              }
                            },
                            child: Text('Guardar',
                                style: TextStyle(color: Colors.white)),
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
      }),
    );
  }

// Método auxiliar para campos de texto con opción de requerido
  Widget _buildTextField(
      String label, IconData icon, Function(String) onChanged,
      {bool isRequired = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Color(0xFF1B998B)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        validator: isRequired
            ? (value) => value!.isEmpty ? 'Campo obligatorio' : null
            : null, // Sin validación si no es requerido
        onChanged: onChanged,
      ),
    );
  }

// Método de construcción de dropdown
  Widget _buildDropdown(
      String label, List<String> options, Function(String) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        items: options
            .map((option) =>
                DropdownMenuItem(value: option, child: Text(option)))
            .toList(),
        validator: (value) => value == null ? 'Selecciona una opción' : null,
        onChanged: (value) => onChanged(value!),
      ),
    );
  }

// Método de construcción de selección múltiple
  Widget _buildMultiSelect(
      String label, List<String> options, Function(List<String>) onChanged) {
    List<String> selectedOptions = [];

    return StatefulBuilder(
      builder: (context, setState) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
              Wrap(
                spacing: 8,
                children: options.map((option) {
                  final isSelected = selectedOptions.contains(option);
                  return ChoiceChip(
                    label: Text(option),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        selected
                            ? selectedOptions.add(option)
                            : selectedOptions.remove(option);
                      });
                      onChanged(selectedOptions);
                    },
                    selectedColor: Color(0xFF1B998B),
                    labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Define colors based on the COCEP logo
    final Color primaryTeal = Color(0xFF1B998B);
    final Color secondaryOrange = Color(0xFFFF7E00);
    final Color lightTeal = Color(0xFFE0F7FA);

    return Theme(
      data: ThemeConstants.appTheme,
      child: DefaultTabController(
        length: 4,
        child: Scaffold(
          appBar: AppBar(
            elevation: 0,
            backgroundColor: primaryTeal,
            title: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Hero(
                  tag: 'logo',
                  child: Image.asset(
                    'assets/Cocep_.png',
                    height: 42,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  'Tribu: $tribuNombre',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        offset: Offset(1, 1),
                        blurRadius: 3.0,
                        color: Colors.black.withOpacity(0.3),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(60),
              child: Container(
                decoration: BoxDecoration(
                  color: primaryTeal,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      offset: Offset(0, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: TabBar(
                  indicator: BoxDecoration(
                    color: secondaryOrange,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(10),
                      topRight: Radius.circular(10),
                    ),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white.withOpacity(0.7),
                  tabs: [
                    _buildTab(Icons.people, 'Timoteos'),
                    _buildTab(Icons.supervised_user_circle, 'Coordinadores'),
                    _buildTab(Icons.assignment_ind, 'Personas Asignadas'),
                    _buildTab(Icons.list_alt, 'Asistencias'),
                  ],
                ),
              ),
            ),
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  lightTeal,
                  Colors.white,
                ],
                stops: [0.0, 0.5],
              ),
            ),
            child: TabBarView(
              children: [
                _buildTabContent(TimoteosTab(tribuId: tribuId)),
                _buildTabContent(CoordinadoresTab(tribuId: tribuId)),
                _buildTabContent(RegistrosAsignadosTab(
                    tribuId: tribuId,
                    tribuNombre: tribuNombre)), // Aquí modificamos
                _buildTabContent(AsistenciasTab(tribuId: tribuId)),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: secondaryOrange,
            child: Icon(Icons.add, color: Colors.white),
            onPressed: () {
              _showAddOptions(context, primaryTeal, secondaryOrange);
            },
            elevation: 4,
          ),
        ),
      ),
    );
  }

  Widget _buildTab(IconData icon, String text) {
    return Tab(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24),
            SizedBox(height: 4),
            Text(
              text,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent(Widget content) {
    return Card(
      margin: EdgeInsets.all(12),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: content,
      ),
    );
  }

  void _showAddOptions(
      BuildContext context, Color primaryColor, Color secondaryColor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            /*Text(
              'Agregar Nuevo',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            SizedBox(height: 20),
            _buildOptionButton(
              context,
              'Agregar Timoteo',
              Icons.person_add,
              primaryColor,
              secondaryColor,
              () {
                Navigator.pop(context);
                // Aquí iría la lógica para agregar un Timoteo
              },
            ),
            SizedBox(height: 12),
            _buildOptionButton(
              context,
              'Agregar Coordinador',
              Icons.supervisor_account,
              primaryColor,
              secondaryColor,
              () {
                Navigator.pop(context);

                 _crearCoordinador(context),
              },
            ),
            SizedBox(height: 12),*/
            _buildOptionButton(
              context,
              'Registrar Miembro',
              Icons.person_add_alt_1,
              primaryColor,
              secondaryColor,
              () {
                Navigator.pop(context);
                _showRegistroDialog(context);
              },
            ),
            SizedBox(height: 12),
            /*_buildOptionButton(
              context,
              'Registrar Asistencia',
              Icons.edit_calendar,
              primaryColor,
              secondaryColor,
              () {
                Navigator.pop(context);
                // Aquí iría la lógica para registrar asistencia
              },
            ),*/
          ],
        ),
      ),
    );
  }

  Widget _buildOptionButton(
    BuildContext context,
    String title,
    IconData icon,
    Color primaryColor,
    Color secondaryColor,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryColor, primaryColor.withOpacity(0.8)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.3),
                blurRadius: 5,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 24),
                SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Spacer(),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Componente de ejemplo para mostrar animación de carga
class AnimatedLoadingIndicator extends StatefulWidget {
  @override
  _AnimatedLoadingIndicatorState createState() =>
      _AnimatedLoadingIndicatorState();
}

class _AnimatedLoadingIndicatorState extends State<AnimatedLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 1),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: RotationTransition(
        turns: _controller,
        child: Container(
          width: 50,
          height: 50,
          child: Icon(
            Icons.local_fire_department,
            color: Color(0xFFFF7E00),
            size: 40,
          ),
        ),
      ),
    );
  }
}

// Ejemplo de cómo podría ser una tarjeta personalizada para los miembros de la tribu
class MiembroCard extends StatelessWidget {
  final String nombre;
  final String rol;
  final String? imageUrl;
  final VoidCallback onTap;

  const MiembroCard({
    Key? key,
    required this.nombre,
    required this.rol,
    this.imageUrl,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Color(0xFF148B9C).withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Color(0xFF148B9C),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: imageUrl != null
                      ? ClipOval(
                          child: Image.network(
                            imageUrl!,
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Icon(
                          Icons.person,
                          size: 30,
                          color: Color(0xFF148B9C),
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
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      rol,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Color(0xFFFF7E00),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AsistenciasTab extends StatelessWidget {
  final String tribuId;

  const AsistenciasTab({Key? key, required this.tribuId}) : super(key: key);

  // Función para obtener asistencias del segundo código
  Stream<QuerySnapshot> obtenerAsistenciasPorTribu(String tribuId) {
    return FirebaseFirestore.instance
        .collection('asistencias')
        .where('tribuId', isEqualTo: tribuId)
        .where('asistio', isEqualTo: true) // Mantener el filtro de asistentes
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: obtenerAsistenciasPorTribu(tribuId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 60,
                  width: 60,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      const Color(0xFF1D8A8A), // Color teal principal del logo
                    ),
                    strokeWidth: 4,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Cargando asistencias...',
                  style: TextStyle(
                    fontSize: 16,
                    color: const Color(0xFF1D8A8A),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1D8A8A).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.event_busy,
                      size: 64,
                      color: const Color(0xFF1D8A8A),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No hay asistencias registradas',
                    style: TextStyle(
                      fontSize: 18,
                      color: const Color(0xFF1D8A8A),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Los datos de asistencia aparecerán aquí',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Convertir los datos de Firestore en una lista de mapas
        final asistencias = snapshot.data!.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final nombre = data['nombre'] ?? "Sin nombre";
          final apellido = data['apellido'] ?? '';
          final nombreCompleto =
              apellido.isNotEmpty ? "$nombre $apellido" : nombre;

          return {
            'nombre': nombre,
            'nombreCompleto': nombreCompleto,
            'fecha': (data['fecha'] as Timestamp).toDate(),
            'diaSemana': data['diaSemana'] ?? '',
            'asistio': data['asistio'],
            'nombreServicio': data['nombreServicio'] ?? '',
            'ministerio': _determinarMinisterio(data['nombreServicio'] ?? ''),
          };
        }).toList();

        // Agrupar las asistencias por año, mes y semana
        final asistenciasAgrupadas = _agruparAsistenciasPorFecha(asistencias);

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white,
                const Color(0xFF1D8A8A).withOpacity(0.05),
              ],
            ),
          ),
          child: ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: asistenciasAgrupadas.keys.length,
            itemBuilder: (context, yearIndex) {
              final year = asistenciasAgrupadas.keys.elementAt(yearIndex);
              final months = asistenciasAgrupadas[year]!;

              return Card(
                elevation: 4,
                margin: EdgeInsets.only(bottom: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF1D8A8A),
                            const Color(0xFF156D6D),
                          ],
                        ),
                      ),
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          dividerColor: Colors.transparent,
                          colorScheme: ColorScheme.light(
                            primary: Colors.white,
                          ),
                        ),
                        child: ExpansionTile(
                          leading: Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.calendar_today,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            'Año $year',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          subtitle: Text(
                            'Registro de asistencias',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                          iconColor: Colors.white,
                          collapsedIconColor: Colors.white,
                          childrenPadding:
                              EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                          children: months.keys.map((month) {
                            return _buildMonthSection(
                                context, month, months[month]!, year);
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildMonthSection(BuildContext context, String month,
      Map<String, List<Map<String, dynamic>>> weeks, String year) {
    final monthName = _getSpanishMonth(month);
    final IconData monthIcon = _getMonthIcon(month);

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: const Color(0xFF1D8A8A).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              Colors.white,
              const Color(0xFF1D8A8A).withOpacity(0.08),
            ],
          ),
        ),
        child: ExpansionTile(
          leading: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF1D8A8A),
                  const Color(0xFF1D8A8A).withOpacity(0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              monthIcon,
              color: Colors.white,
              size: 20,
            ),
          ),
          title: Text(
            monthName,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1D8A8A),
            ),
          ),
          subtitle: Text(
            'Toca para ver semanas',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          iconColor: const Color(0xFF1D8A8A),
          collapsedIconColor: const Color(0xFF1D8A8A),
          children: weeks.keys.map((week) {
            return _buildWeekSection(
                context, week, weeks[week]!, '$monthName $year');
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildWeekSection(BuildContext context, String week,
      List<Map<String, dynamic>> asistencias, String monthYear) {
    // Agrupar por servicio
    Map<String, List<Map<String, dynamic>>> porServicio = {};

    // Obtener nombres únicos de personas que asistieron a cada servicio
    Map<String, Set<String>> personasPorServicio = {};
    Set<String> todasLasPersonas = {};

    for (var asistencia in asistencias) {
      final servicio = asistencia['nombreServicio'] ?? 'Otro Servicio';
      final nombre = asistencia['nombre'];

      if (!porServicio.containsKey(servicio)) {
        porServicio[servicio] = [];
        personasPorServicio[servicio] = {};
      }

      porServicio[servicio]!.add(asistencia);
      personasPorServicio[servicio]!.add(nombre);
      todasLasPersonas.add(nombre);
    }

    Map<String, int> resumen = {
      for (var servicio in porServicio.keys)
        servicio: personasPorServicio[servicio]!.length
    };
    resumen['Total de personas únicas'] = todasLasPersonas.length;

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              const Color(0xFFF5A623).withOpacity(0.05),
            ],
          ),
          border: Border.all(
            color: const Color(0xFFF5A623).withOpacity(0.2),
            width: 1,
          ),
        ),
        child: ExpansionTile(
          leading: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFF5A623),
                  const Color(0xFFFF7A00),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.date_range,
              color: Colors.white,
              size: 18,
            ),
          ),
          title: Text(
            'Semana $week',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFEE5A24),
            ),
          ),
          subtitle: Text(
            monthYear,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          iconColor: const Color(0xFFEE5A24),
          collapsedIconColor: const Color(0xFFEE5A24),
          children: [
            ...porServicio.entries.map((entry) {
              final servicio = entry.key;
              final listaAsistencias = entry.value;
              final ministerio = _determinarMinisterio(servicio);

              return _buildServicioSection(
                servicio,
                ministerio,
                listaAsistencias,
              );
            }).toList(),
            _buildTotalSection(resumen),
          ],
        ),
      ),
    );
  }

  Widget _buildServicioSection(
    String servicio,
    String ministerio,
    List<Map<String, dynamic>> asistencias,
  ) {
    final color = _getColorByMinisterio(ministerio);
    final icon = _getIconByMinisterio(ministerio);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color,
                  color.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        servicio,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        ministerio,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${asistencias.length}',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (asistencias.isNotEmpty) ...[
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: asistencias.length,
              padding: EdgeInsets.symmetric(vertical: 8),
              itemBuilder: (context, index) {
                final asistencia = asistencias[index];
                final nombreMostrado =
                    asistencia['nombreCompleto'] ?? asistencia['nombre'];
                final inicialNombre =
                    nombreMostrado.toString()[0].toUpperCase();

                return Container(
                  margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            color.withOpacity(0.8),
                            color.withOpacity(0.6),
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          inicialNombre,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      nombreMostrado,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    subtitle: Row(
                      children: [
                        Icon(
                          Icons.event,
                          size: 12,
                          color: Colors.grey[600],
                        ),
                        SizedBox(width: 4),
                        Text(
                          "${DateFormat('EEEE, d MMM', 'es').format(asistencia['fecha'])}",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    trailing: Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_circle_rounded,
                        color: Colors.green,
                        size: 20,
                      ),
                    ),
                  ),
                );
              },
            ),
          ] else
            Container(
              padding: EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.grey[400],
                    size: 20,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'No hay asistencias registradas',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontStyle: FontStyle.italic,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTotalSection(Map<String, int> resumen) {
    final totalUnico = resumen['Total de personas únicas'] ?? 0;

    return Container(
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            const Color(0xFF1D8A8A).withOpacity(0.1),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1D8A8A).withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: const Color(0xFF1D8A8A).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF1D8A8A),
                  const Color(0xFF156D6D),
                ],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.summarize_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  'Resumen de Asistencia',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                ...resumen.entries
                    .where((e) => e.key != 'Total de personas únicas')
                    .map(
                      (entry) => _buildTotalRow(entry.key, entry.value),
                    ),
                SizedBox(height: 8),
                Divider(
                  height: 24,
                  thickness: 1,
                  color: const Color(0xFF1D8A8A).withOpacity(0.2),
                ),
                _buildTotalRow('Total de personas únicas', totalUnico,
                    isTotal: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, int count, {bool isTotal = false}) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4),
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: isTotal
            ? const Color(0xFF1D8A8A).withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isTotal
            ? Border.all(
                color: const Color(0xFF1D8A8A).withOpacity(0.3), width: 1)
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
                color: isTotal ? const Color(0xFF1D8A8A) : Colors.grey[700],
                fontSize: isTotal ? 15 : 14,
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: isTotal
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF1D8A8A),
                        const Color(0xFF156D6D),
                      ],
                    )
                  : null,
              color: isTotal ? null : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              boxShadow: isTotal
                  ? [
                      BoxShadow(
                        color: const Color(0xFF1D8A8A).withOpacity(0.2),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      )
                    ]
                  : null,
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isTotal ? Colors.white : Colors.grey[700],
                fontSize: isTotal ? 15 : 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, Map<String, Map<String, List<Map<String, dynamic>>>>>
      _agruparAsistenciasPorFecha(List<Map<String, dynamic>> asistencias) {
    final Map<String, Map<String, Map<String, List<Map<String, dynamic>>>>>
        agrupadas = {};

    for (var asistencia in asistencias) {
      final fecha = asistencia['fecha'];
      final year = DateFormat('yyyy').format(fecha);
      final month = DateFormat('MMMM').format(fecha);

      // Modificado: Obtener el número de la semana considerando que comienza el lunes
      final DateTime lunes = _obtenerLunesDeLaSemana(fecha);
      final String semanaKey =
          '${lunes.day}-${_obtenerDomingoDeLaSemana(lunes).day}';

      agrupadas.putIfAbsent(year, () => {});
      agrupadas[year]!.putIfAbsent(month, () => {});
      agrupadas[year]![month]!.putIfAbsent(semanaKey, () => []);
      agrupadas[year]![month]![semanaKey]!.add(asistencia);
    }

    return agrupadas;
  }

  // Nuevo método para obtener el lunes de la semana actual
  DateTime _obtenerLunesDeLaSemana(DateTime fecha) {
    int diferencia = fecha.weekday - DateTime.monday;
    return fecha.subtract(Duration(days: diferencia));
  }

  // Nuevo método para obtener el domingo de la semana
  DateTime _obtenerDomingoDeLaSemana(DateTime lunes) {
    return lunes.add(Duration(days: 6)); // 6 días después del lunes es domingo
  }

  /// Determina el ministerio basado en el nombre del servicio
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

  /// Retorna el color según el ministerio con los colores del logo
  Color _getColorByMinisterio(String ministerio) {
    switch (ministerio) {
      case "Ministerio de Damas":
        return Color(0xFFFF6B8B); // Rosa más vibrante
      case "Ministerio de Caballeros":
        return Color(0xFF3498DB); // Azul más vibrante
      case "Ministerio Juvenil":
        return Color(0xFFF5A623); // Naranja del logo
      case "Ministerio Familiar":
        return Color(0xFF9B59B6); // Púrpura más vibrante
      case "Viernes de Poder":
        return Color(0xFF1D8A8A); // Teal del logo
      case "Servicio Dominical":
        return Color(0xFF2ECC71); // Verde más vibrante
      default:
        return Color(0xFF7F8C8D); // Gris acento más vibrante
    }
  }

  /// Retorna íconos mejorados según el ministerio
  IconData _getIconByMinisterio(String ministerio) {
    switch (ministerio) {
      case "Ministerio de Damas":
        return Icons.volunteer_activism;
      case "Ministerio de Caballeros":
        return Icons.fitness_center;
      case "Ministerio Juvenil":
        return Icons.emoji_people;
      case "Ministerio Familiar":
        return Icons.family_restroom;
      case "Viernes de Poder":
        return Icons.flash_on;
      case "Servicio Dominical":
        return Icons.church;
      default:
        return Icons.groups_2;
    }
  }

  /// Retorna íconos únicos según el mes
  IconData _getMonthIcon(String month) {
    switch (month) {
      case 'January':
        return Icons.ac_unit;
      case 'February':
        return Icons.favorite;
      case 'March':
        return Icons.eco;
      case 'April':
        return Icons.water_drop;
      case 'May':
        return Icons.local_florist;
      case 'June':
        return Icons.wb_sunny;
      case 'July':
        return Icons.beach_access;
      case 'August':
        return Icons.waves;
      case 'September':
        return Icons.school;
      case 'October':
        return Icons.theater_comedy;
      case 'November':
        return Icons.savings;
      case 'December':
        return Icons.celebration;
      default:
        return Icons.calendar_month;
    }
  }

  String _getSpanishMonth(String month) {
    final months = {
      'January': 'Enero',
      'February': 'Febrero',
      'March': 'Marzo',
      'April': 'Abril',
      'May': 'Mayo',
      'June': 'Junio',
      'July': 'Julio',
      'August': 'Agosto',
      'September': 'Septiembre',
      'October': 'Octubre',
      'November': 'Noviembre',
      'December': 'Diciembre',
    };
    return months[month] ?? month;
  }
}

class CoordinadoresTab extends StatelessWidget {
  final String tribuId;

  const CoordinadoresTab({Key? key, required this.tribuId}) : super(key: key);

  Future<void> _crearCoordinador(BuildContext context) async {
    final _nameController = TextEditingController();
    final _lastNameController = TextEditingController();
    final _ageController = TextEditingController();
    final _userController = TextEditingController();
    final _passwordController = TextEditingController();
    final _phoneController = TextEditingController();
    final _emailController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: SingleChildScrollView(
            child: Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.supervisor_account,
                        color: ThemeConstants.secondaryOrange,
                        size: 32,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Nuevo Coordinador',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: ThemeConstants.primaryTeal,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),
                  _buildTextField(
                    controller: _nameController,
                    label: 'Nombre',
                    icon: Icons.person_outline,
                  ),
                  SizedBox(height: 16),
                  _buildTextField(
                    controller: _lastNameController,
                    label: 'Apellido',
                    icon: Icons.person,
                  ),
                  SizedBox(height: 16),
                  _buildTextField(
                    controller: _ageController,
                    label: 'Edad',
                    icon: Icons.cake,
                    keyboardType: TextInputType.number,
                  ),
                  SizedBox(height: 16),
                  _buildTextField(
                    controller: _phoneController,
                    label: 'Teléfono',
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                    formatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\+?[0-9]*$')),
                    ],
                    onChanged: (value) {
                      if (!value.startsWith('+57')) {
                        _phoneController.text = '+57$value';
                        _phoneController.selection = TextSelection.fromPosition(
                          TextPosition(offset: _phoneController.text.length),
                        );
                      }
                    },
                  ),
                  SizedBox(height: 16),
                  _buildTextField(
                    controller: _emailController,
                    label: 'Correo Electrónico',
                    icon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  SizedBox(height: 16),
                  _buildTextField(
                    controller: _userController,
                    label: 'Usuario',
                    icon: Icons.account_circle,
                  ),
                  SizedBox(height: 16),
                  _buildTextField(
                    controller: _passwordController,
                    label: 'Contraseña',
                    icon: Icons.lock_outline,
                    isPassword: true,
                  ),
                  SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Cancelar'),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                        ),
                      ),
                      SizedBox(width: 12),
                      ElevatedButton.icon(
                        icon: Icon(Icons.save),
                        label: Text('Guardar'),
                        onPressed: () async {
                          if (_validateFields(
                              _nameController.text,
                              _lastNameController.text,
                              _ageController.text,
                              _phoneController.text,
                              _emailController.text,
                              _userController.text,
                              _passwordController.text)) {
                            await FirebaseFirestore.instance
                                .collection('coordinadores')
                                .add({
                              'nombre': _nameController.text,
                              'apellido': _lastNameController.text,
                              'edad': int.tryParse(_ageController.text) ?? 0,
                              'telefono': _phoneController.text,
                              'email': _emailController.text,
                              'usuario': _userController.text,
                              'contrasena': _passwordController.text,
                              'tribuId': tribuId,
                            });
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content:
                                    Text('Coordinador creado exitosamente'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Por favor completa todos los campos correctamente'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    TextInputType? keyboardType,
    List<TextInputFormatter>? formatters,
    Function(String)? onChanged,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: ThemeConstants.primaryTeal),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: ThemeConstants.primaryTeal),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: ThemeConstants.primaryTeal.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: ThemeConstants.primaryTeal, width: 2),
        ),
      ),
      obscureText: isPassword,
      keyboardType: keyboardType,
      inputFormatters: formatters,
      onChanged: onChanged,
    );
  }

  bool _validateFields(String name, String lastName, String age, String phone,
      String email, String user, String password) {
    return name.isNotEmpty &&
        lastName.isNotEmpty &&
        age.isNotEmpty &&
        phone.isNotEmpty &&
        email.isNotEmpty &&
        user.isNotEmpty &&
        password.isNotEmpty;
  }

  Future<void> _editarCoordinador(
      BuildContext context, DocumentSnapshot coordinador) async {
    final nombreController = TextEditingController(text: coordinador['nombre']);
    final apellidoController =
        TextEditingController(text: coordinador['apellido']);
    final usuarioController =
        TextEditingController(text: coordinador['usuario']);
    final contrasenaController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Coordinador'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: nombreController,
                decoration: const InputDecoration(labelText: 'Nombre'),
              ),
              TextField(
                controller: apellidoController,
                decoration: const InputDecoration(labelText: 'Apellido'),
              ),
              TextField(
                controller: usuarioController,
                decoration: const InputDecoration(labelText: 'Usuario'),
              ),
              TextField(
                controller: contrasenaController,
                decoration: const InputDecoration(
                    labelText: 'Nueva Contraseña (opcional)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final Map<String, dynamic> datosActualizados = {
                'nombre': nombreController.text,
                'apellido': apellidoController.text,
                'usuario': usuarioController.text,
              };

              if (contrasenaController.text.isNotEmpty) {
                datosActualizados['contrasena'] =
                    contrasenaController.text; // Guardar nueva contraseña
              }

              await FirebaseFirestore.instance
                  .collection('coordinadores')
                  .doc(coordinador.id)
                  .update(datosActualizados);

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Coordinador actualizado exitosamente')),
              );
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _eliminarCoordinador(
      BuildContext context, DocumentSnapshot coordinador) async {
    // Mostrar diálogo de confirmación
    bool? confirmacion = await showDialog<bool>(
      context: context,
      barrierDismissible:
          false, // Evita que el diálogo se cierre al tocar fuera
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: const Text(
            '¿Estás seguro de eliminar este coordinador? Los timoteos y registros asignados volverán a estar disponibles para asignación.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext)
                  .pop(false); // Cierra el diálogo con false
            },
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext)
                  .pop(true); // Cierra el diálogo con true
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    // Si no se confirmó la eliminación o se cerró el diálogo, no hacer nada
    if (confirmacion != true) return;

    try {
      final batch = FirebaseFirestore.instance.batch();

      // Obtener y actualizar timoteos asignados
      final timoteos = await FirebaseFirestore.instance
          .collection('timoteos')
          .where('coordinadorId', isEqualTo: coordinador.id)
          .get();

      for (var timoteo in timoteos.docs) {
        batch.update(timoteo.reference,
            {'coordinadorId': null, 'nombreCoordinador': null});
      }

      // Obtener y actualizar registros asignados
      final registros = await FirebaseFirestore.instance
          .collection('registros')
          .where('coordinadorAsignado', isEqualTo: coordinador.id)
          .get();

      for (var registro in registros.docs) {
        batch.update(registro.reference, {
          'coordinadorAsignado': null,
          'nombreCoordinador': null,
          'estado': 'pendiente'
        });
      }

      // Eliminar coordinador
      batch.delete(coordinador.reference);

      await batch.commit();

      // Mostrar mensaje de éxito
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Coordinador eliminado correctamente')));
      }
    } catch (e) {
      print('Error al eliminar coordinador: $e');
      // Mostrar mensaje de error
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar el coordinador: $e')));
      }
    }
  }

  Future<void> _verTimoteosAsignados(
      BuildContext context, DocumentSnapshot coordinador) async {
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
                    'Timoteos de ${coordinador['nombre']} ${coordinador['apellido']}'),
                actions: [
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              body: StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection('timoteos')
                    .where('coordinadorId', isEqualTo: coordinador.id)
                    .snapshots(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text('No hay timoteos asignados'));
                  }

                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final timoteo = snapshot.data!.docs[index];
                      return Card(
                        margin:
                            EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        child: ListTile(
                          title: Text(
                              '${timoteo['nombre']} ${timoteo['apellido']}'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Usuario: ${timoteo['usuario']}'),
                              Text('Contraseña: ${timoteo['contrasena']}'),
                            ],
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.remove_circle_outline),
                            onPressed: () async {
                              await FirebaseFirestore.instance
                                  .collection('timoteos')
                                  .doc(timoteo.id)
                                  .update({'coordinadorId': null});
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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            margin: EdgeInsets.only(bottom: 20),
            child: ElevatedButton.icon(
              icon: Icon(Icons.group_add, size: 24),
              label: Text(
                'Crear Coordinador',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: ThemeConstants.secondaryOrange,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
              onPressed: () => _crearCoordinador(context),
            ),
          ),
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('coordinadores')
                  .where('tribuId', isEqualTo: tribuId)
                  .snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: ThemeConstants.primaryTeal,
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.groups,
                          size: 64,
                          color: ThemeConstants.accentGrey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No hay coordinadores registrados',
                          style: TextStyle(
                            fontSize: 18,
                            color: ThemeConstants.accentGrey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final coordinador = snapshot.data!.docs[index];
                    return Card(
                      elevation: 3,
                      margin: EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          backgroundColor: ThemeConstants.primaryTeal,
                          child: Text(
                            '${coordinador['nombre'][0]}${coordinador['apellido'][0]}',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          '${coordinador['nombre']} ${coordinador['apellido']}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: ThemeConstants.primaryTeal,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Text(
                          'Edad: ${coordinador['edad']} años',
                          style: TextStyle(color: ThemeConstants.accentGrey),
                        ),
                        children: [
                          Container(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildInfoRow(Icons.phone, 'Teléfono',
                                    coordinador['telefono']),
                                SizedBox(height: 8),
                                _buildInfoRow(
                                    Icons.email, 'Email', coordinador['email']),
                                SizedBox(height: 8),
                                _buildInfoRow(Icons.person, 'Usuario',
                                    coordinador['usuario']),
                                SizedBox(height: 8),
                                _buildInfoRow(Icons.lock, 'Contraseña',
                                    coordinador['contrasena']),
                                Divider(height: 24),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _buildActionButton(
                                      icon: Icons.edit,
                                      label: '',
                                      color: ThemeConstants.primaryTeal,
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 12),
                                      iconSize: 30, // Ajuste del tamaño
                                      onPressed: () => _editarCoordinador(
                                          context, coordinador),
                                    ),
                                    _buildActionButton(
                                      icon: Icons.group,
                                      label: '',
                                      color: ThemeConstants.secondaryOrange,
                                      onPressed: () => _verTimoteosAsignados(
                                          context, coordinador),
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 12),
                                      iconSize:
                                          30, // Cambiar el tamaño del ícono (aumentado)
                                      // Ajuste del tamaño
                                    ),
                                    _buildActionButton(
                                      icon: Icons.delete,
                                      label:
                                          '', // Mantener sin texto si no necesitas un label
                                      color: Colors.red,
                                      onPressed: () => _eliminarCoordinador(
                                          context, coordinador),
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ), // Ajuste del tamaño
                                      iconSize:
                                          30, // Cambiar el tamaño del ícono (aumentado)
                                    ),
                                    _buildActionButton(
                                      icon: Icons.arrow_forward,
                                      label: '',
                                      color: Colors.blue,
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 12),
                                      iconSize: 30, // Ajuste del tamaño
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                CoordinadorScreen(
                                              coordinadorId: coordinador.id,
                                              coordinadorNombre:
                                                  '${coordinador['nombre']} ${coordinador['apellido']}',
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

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: ThemeConstants.accentGrey),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: ThemeConstants.accentGrey,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ],
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
    EdgeInsets padding =
        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    double fontSize = 14, // Tamaño por defecto del texto
    double iconSize = 24, // Tamaño por defecto del ícono
  }) {
    return TextButton.icon(
      icon: Icon(icon,
          color: color, size: iconSize), // Aquí se ajusta el tamaño del ícono
      label: Text(
        label,
        style: TextStyle(color: color, fontSize: fontSize),
      ),
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: padding,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

class TimoteosTab extends StatelessWidget {
  final String tribuId;

  const TimoteosTab({Key? key, required this.tribuId}) : super(key: key);

  Future<void> _createTimoteo(BuildContext context) async {
    final TextEditingController _nameController = TextEditingController();
    final TextEditingController _lastNameController = TextEditingController();
    final TextEditingController _userController = TextEditingController();
    final TextEditingController _passwordController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.person_add,
                      color: ThemeConstants.secondaryOrange,
                      size: 30,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Crear Timoteo',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: ThemeConstants.primaryTeal,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Nombre',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _lastNameController,
                  decoration: InputDecoration(
                    labelText: 'Apellido',
                    prefixIcon: Icon(Icons.family_restroom),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _userController,
                  decoration: InputDecoration(
                    labelText: 'Usuario',
                    prefixIcon: Icon(Icons.account_circle),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  obscureText: true,
                ),
                SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancelar'),
                      style: TextButton.styleFrom(
                        padding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                    SizedBox(width: 8),
                    ElevatedButton.icon(
                      icon: Icon(Icons.save),
                      label: Text('Guardar'),
                      onPressed: () async {
                        if (_nameController.text.isNotEmpty &&
                            _lastNameController.text.isNotEmpty &&
                            _userController.text.isNotEmpty &&
                            _passwordController.text.isNotEmpty) {
                          await FirebaseFirestore.instance
                              .collection('timoteos')
                              .add({
                            'nombre': _nameController.text,
                            'apellido': _lastNameController.text,
                            'usuario': _userController.text,
                            'contrasena': _passwordController.text,
                            'tribuId': tribuId,
                            'coordinadorId': null,
                          });
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Timoteo creado exitosamente'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content:
                                  Text('Por favor completa todos los campos'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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

  Future<void> _editarTimoteo(
      BuildContext context, DocumentSnapshot timoteo) async {
    final nombreController = TextEditingController(text: timoteo['nombre']);
    final apellidoController = TextEditingController(text: timoteo['apellido']);
    final usuarioController = TextEditingController(text: timoteo['usuario']);
    final contrasenaController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Timoteo'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: nombreController,
                decoration: const InputDecoration(labelText: 'Nombre'),
              ),
              TextField(
                controller: apellidoController,
                decoration: const InputDecoration(labelText: 'Apellido'),
              ),
              TextField(
                controller: usuarioController,
                decoration: const InputDecoration(labelText: 'Usuario'),
              ),
              TextField(
                controller: contrasenaController,
                decoration: const InputDecoration(
                    labelText: 'Nueva Contraseña (opcional)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final Map<String, dynamic> datosActualizados = {
                'nombre': nombreController.text,
                'apellido': apellidoController.text,
                'usuario': usuarioController.text,
              };

              if (contrasenaController.text.isNotEmpty) {
                datosActualizados['contrasena'] =
                    contrasenaController.text; // Guardar nueva contraseña
              }

              await FirebaseFirestore.instance
                  .collection('timoteos')
                  .doc(timoteo.id)
                  .update(datosActualizados);

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Timoteo actualizado exitosamente')),
              );
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _eliminarTimoteo(
      BuildContext context, DocumentSnapshot timoteo) async {
    // Mostrar diálogo de confirmación
    bool? confirmacion = await showDialog<bool>(
      context: context,
      barrierDismissible:
          false, // Evita que el diálogo se cierre al tocar fuera
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: const Text('¿Estás seguro de eliminar este timoteo?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext)
                  .pop(false); // Cierra el diálogo con false
            },
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext)
                  .pop(true); // Cierra el diálogo con true
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    // Si no se confirmó la eliminación o se cerró el diálogo, no hacer nada
    if (confirmacion != true) return;

    try {
      final batch = FirebaseFirestore.instance.batch();

      // Obtener registros asignados al timoteo
      final registros = await FirebaseFirestore.instance
          .collection('registros')
          .where('timoteoAsignado', isEqualTo: timoteo.id)
          .get();

      // Actualizar cada registro para remover la asignación del timoteo
      for (var registro in registros.docs) {
        batch.update(registro.reference,
            {'timoteoAsignado': null, 'nombreTimoteo': null});
      }

      // Eliminar el timoteo
      batch.delete(timoteo.reference);

      await batch.commit();

      // Mostrar mensaje de éxito
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Timoteo eliminado correctamente')));
      }
    } catch (e) {
      // Mostrar mensaje de error
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar el timoteo: $e')));
      }
    }
  }

  Future<void> _asignarACoordinador(
      BuildContext context, DocumentSnapshot timoteo) async {
    final coordinadoresSnapshot = await FirebaseFirestore.instance
        .collection('coordinadores')
        .where('tribuId', isEqualTo: tribuId)
        .get();

    if (coordinadoresSnapshot.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('No hay coordinadores disponibles para asignar')),
      );
      return;
    }

    String? coordinadorSeleccionado;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Asignar a un Coordinador'),
          content: DropdownButtonFormField<String>(
            items: coordinadoresSnapshot.docs.map((coordinador) {
              return DropdownMenuItem(
                value: coordinador.id,
                child:
                    Text('${coordinador['nombre']} ${coordinador['apellido']}'),
              );
            }).toList(),
            onChanged: (value) {
              coordinadorSeleccionado = value;
            },
            decoration: InputDecoration(labelText: 'Selecciona un coordinador'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (coordinadorSeleccionado != null) {
                  try {
                    final coordinador = coordinadoresSnapshot.docs.firstWhere(
                      (doc) => doc.id == coordinadorSeleccionado,
                    );

                    await FirebaseFirestore.instance
                        .collection('timoteos')
                        .doc(timoteo.id)
                        .update({
                      'coordinadorId': coordinador.id,
                      'nombreCoordinador':
                          '${coordinador['nombre']} ${coordinador['apellido']}',
                    });

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Timoteo asignado exitosamente a ${coordinador['nombre']}'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error al asignar el Timoteo: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: Text('Asignar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            margin: EdgeInsets.only(bottom: 20),
            child: ElevatedButton.icon(
              icon: Icon(Icons.add_circle_outline, size: 24),
              label: Text(
                'Crear Timoteo',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: ThemeConstants.secondaryOrange,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
              onPressed: () => _createTimoteo(context),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('timoteos')
                  .where('tribuId', isEqualTo: tribuId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: ThemeConstants.primaryTeal,
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: ThemeConstants.accentGrey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No hay Timoteos disponibles',
                          style: TextStyle(
                            fontSize: 18,
                            color: ThemeConstants.accentGrey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final docs = snapshot.data!.docs.where((doc) {
                  return !doc.data().toString().contains('coordinadorId') ||
                      doc.get('coordinadorId') == null;
                }).toList();

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final timoteo = docs[index];
                    return Card(
                      elevation: 3,
                      margin: EdgeInsets.symmetric(vertical: 8),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: ThemeConstants.primaryTeal.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: ExpansionTile(
                          leading: CircleAvatar(
                            backgroundColor: ThemeConstants.primaryTeal,
                            child: Text(
                              '${timoteo['nombre'][0]}${timoteo['apellido'][0]}',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            '${timoteo['nombre']} ${timoteo['apellido']}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: ThemeConstants.primaryTeal,
                              fontSize: 16,
                            ),
                          ),
                          children: [
                            Padding(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildInfoRow(
                                    Icons.person_outline,
                                    'Usuario',
                                    timoteo['usuario'],
                                  ),
                                  SizedBox(height: 8),
                                  _buildInfoRow(
                                    Icons.lock_outline,
                                    'Contraseña',
                                    timoteo['contrasena'],
                                  ),
                                  SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.edit,
                                            color: ThemeConstants.primaryTeal),
                                        tooltip: 'Editar Timoteo',
                                        onPressed: () =>
                                            _editarTimoteo(context, timoteo),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.delete,
                                            color: Colors.red),
                                        tooltip: 'Eliminar Timoteo',
                                        onPressed: () =>
                                            _eliminarTimoteo(context, timoteo),
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          Icons.person_add,
                                          color: ThemeConstants.secondaryOrange,
                                        ),
                                        tooltip: 'Asignar a Coordinador',
                                        onPressed: () => _asignarACoordinador(
                                            context, timoteo),
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
            ),
          ),
        ],
      ),
    );
  }
}

Widget _buildInfoRow(IconData icon, String label, String value) {
  return Row(
    children: [
      Icon(icon, size: 20, color: ThemeConstants.accentGrey),
      SizedBox(width: 8),
      Text(
        '$label: ',
        style: TextStyle(
          color: ThemeConstants.accentGrey,
          fontWeight: FontWeight.w500,
        ),
      ),
      Text(
        value,
        style: TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  );
}

class RegistrosAsignadosTab extends StatelessWidget {
  final String tribuId;
  final String tribuNombre;

  const RegistrosAsignadosTab({
    Key? key,
    required this.tribuId,
    required this.tribuNombre, // Asegúrate que esté definido aquí
  }) : super(key: key);

  Future<void> _asignarACoordinador(
      BuildContext context, DocumentSnapshot registro) async {
    final coordinadoresSnapshot = await FirebaseFirestore.instance
        .collection('coordinadores')
        .where('tribuId', isEqualTo: tribuId)
        .get();

    if (coordinadoresSnapshot.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white),
              SizedBox(width: 8),
              Text('No hay coordinadores disponibles'),
            ],
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: EdgeInsets.all(10),
        ),
      );
      return;
    }

    String? selectedCoordinador;

    await showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: ThemeConstants.primaryTeal.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.people_alt_rounded,
                    color: ThemeConstants.secondaryOrange,
                    size: 30,
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Asignar a Coordinador',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: ThemeConstants.primaryTeal,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: ThemeConstants.primaryTeal.withOpacity(0.3),
                  ),
                ),
                child: DropdownButtonFormField<String>(
                  items: coordinadoresSnapshot.docs.map((coordinador) {
                    return DropdownMenuItem(
                      value: coordinador.id,
                      child: Text(
                        '${coordinador['nombre']} ${coordinador['apellido']}',
                        style: TextStyle(
                          color: ThemeConstants.primaryTeal,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    selectedCoordinador = value;
                  },
                  decoration: InputDecoration(
                    labelText: 'Seleccione un coordinador',
                    labelStyle: TextStyle(color: ThemeConstants.accentGrey),
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  icon: Icon(Icons.arrow_drop_down,
                      color: ThemeConstants.primaryTeal),
                ),
              ),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancelar',
                      style: TextStyle(
                        color: ThemeConstants.accentGrey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                  SizedBox(width: 12),
                  ElevatedButton.icon(
                    icon: Icon(Icons.check_circle_outline),
                    label: Text('Asignar'),
                    onPressed: () async {
                      if (selectedCoordinador != null) {
                        try {
                          await FirebaseFirestore.instance
                              .collection('registros')
                              .doc(registro.id)
                              .update({
                            'coordinadorAsignado': selectedCoordinador,
                            'fechaAsignacionCoordinador':
                                FieldValue.serverTimestamp(),
                          });
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  Icon(Icons.check_circle, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text('¡Asignación exitosa!'),
                                ],
                              ),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              margin: EdgeInsets.all(10),
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
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ThemeConstants.secondaryOrange,
                      foregroundColor: Colors.white,
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
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
  }

  @override
  Widget build(BuildContext context) {
    // Definimos colores según los proporcionados
    final primaryTeal = Color(0xFF038C7F);
    final secondaryOrange = Color(0xFFFF5722);
    final accentGrey = Color(0xFF78909C);
    final backgroundGrey = Color(0xFFF5F5F5);

    // Controlador para el campo de búsqueda
    final TextEditingController searchController = TextEditingController();
    // Estado de búsqueda
    bool isSearching = false;
    // Término de búsqueda
    String searchTerm = '';

    return StatefulBuilder(builder: (context, setState) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              primaryTeal.withOpacity(0.05),
              backgroundGrey,
            ],
          ),
        ),
        child: Column(
          children: [
            // Barra de búsqueda
            Padding(
              padding: EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: primaryTeal.withOpacity(0.1),
                      blurRadius: 5,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar por nombre o apellido...',
                    prefixIcon: Icon(
                      Icons.search,
                      color: primaryTeal,
                    ),
                    suffixIcon: searchController.text.isNotEmpty || isSearching
                        ? IconButton(
                            icon: Icon(
                              Icons.close,
                              color: accentGrey,
                            ),
                            onPressed: () {
                              searchController.clear();
                              setState(() {
                                isSearching = false;
                                searchTerm = '';
                              });
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 15),
                  ),
                  onChanged: (value) {
                    setState(() {
                      searchTerm = value.toLowerCase();
                      isSearching = value.isNotEmpty;
                    });
                  },
                ),
              ),
            ),

            // Contenido principal con StreamBuilder
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('registros')
                    .where('tribuAsignada', isEqualTo: tribuId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: primaryTeal,
                      ),
                    );
                  }

                  if (!snapshot.hasData ||
                      snapshot.data?.docs.isEmpty == true) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.group_off_outlined,
                            size: 64,
                            color: accentGrey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No hay jóvenes asignados a esta tribu',
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

                  final allDocs = snapshot.data?.docs ?? [];

// Filtrar documentos según el término de búsqueda
                  final filteredDocs = isSearching
                      ? allDocs.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final nombre =
                              (data['nombre'] as String? ?? '').toLowerCase();
                          final apellido =
                              (data['apellido'] as String? ?? '').toLowerCase();
                          final nombreCompleto =
                              '$nombre $apellido'.toLowerCase();

                          // Buscar en nombre, apellido o nombre completo
                          return nombre.contains(searchTerm) ||
                              apellido.contains(searchTerm) ||
                              nombreCompleto.contains(searchTerm);
                        }).toList()
                      : allDocs;

                  // Si hay búsqueda y no se encuentran resultados
                  if (isSearching && filteredDocs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: accentGrey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No se encontraron resultados para "$searchTerm"',
                            style: TextStyle(
                              fontSize: 18,
                              color: accentGrey,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  // Organizar los registros en dos grupos
                  List<DocumentSnapshot> sinCoordinador = [];
                  Map<String, List<DocumentSnapshot>> porCoordinador = {};
                  List<String> idsCoordinadores = [];

                  for (var doc in filteredDocs) {
                    var data = doc.data() as Map<String, dynamic>;
                    if (data['coordinadorAsignado'] == null) {
                      sinCoordinador.add(doc);
                    } else {
                      String coordinadorId = data['coordinadorAsignado'];
                      if (!porCoordinador.containsKey(coordinadorId)) {
                        porCoordinador[coordinadorId] = [];
                        idsCoordinadores.add(coordinadorId);
                      }
                      porCoordinador[coordinadorId]!.add(doc);
                    }
                  }

                  return FutureBuilder<Map<String, String>>(
                    future: obtenerNombresCoordinadores(idsCoordinadores),
                    builder: (context, futureSnapshot) {
                      if (!futureSnapshot.hasData) {
                        return Center(child: CircularProgressIndicator());
                      }

                      Map<String, String> nombresCoordinadores =
                          futureSnapshot.data ?? {};

                      // Para la búsqueda, forzamos a que los grupos estén expandidos
                      Map<String, bool> groupExpandedStates = {};
                      Map<String, bool> expandedStates = {};

                      // Si estamos buscando, expandimos todos los grupos automáticamente
                      if (isSearching) {
                        if (sinCoordinador.isNotEmpty) {
                          groupExpandedStates['Sin_Coordinador'] = true;
                        }

                        porCoordinador.keys.forEach((key) {
                          groupExpandedStates['Coordinador_${key}'] = true;
                        });

                        // Expandimos todos los registros encontrados
                        for (var doc in filteredDocs) {
                          expandedStates[doc.id] = true;
                        }
                      }

                      return Padding(
                        padding: EdgeInsets.all(16),
                        child: ListView(
                          children: [
                            if (sinCoordinador.isNotEmpty)
                              _buildGrupo(
                                context,
                                'Sin Coordinador',
                                sinCoordinador,
                                primaryTeal,
                                secondaryOrange,
                                accentGrey,
                                backgroundGrey,
                                expandedStates,
                                groupExpandedStates,
                              ),
                            ...porCoordinador.entries
                                .map((entry) => _buildGrupo(
                                      context,
                                      'Coordinador: ${nombresCoordinadores[entry.key] ?? "Desconocido"}',
                                      entry.value,
                                      primaryTeal,
                                      secondaryOrange,
                                      accentGrey,
                                      backgroundGrey,
                                      expandedStates,
                                      groupExpandedStates,
                                    )),
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
    });
  }

// Nueva función para obtener nombres de coordinadores
  Future<Map<String, String>> obtenerNombresCoordinadores(
      List<String> coordinadorIds) async {
    Map<String, String> nombresCoordinadores = {};

    if (coordinadorIds.isEmpty) return nombresCoordinadores;

    try {
      var snapshot = await FirebaseFirestore.instance
          .collection('coordinadores')
          .where(FieldPath.documentId, whereIn: coordinadorIds)
          .get();

      for (var doc in snapshot.docs) {
        var data = doc.data();
        nombresCoordinadores[doc.id] = "${data['nombre']} ${data['apellido']}";
      }
    } catch (e) {
      print("Error obteniendo nombres de coordinadores: $e");
    }

    return nombresCoordinadores;
  }

  Widget _buildGrupo(
      BuildContext context,
      String titulo,
      List<DocumentSnapshot> registros,
      Color primaryTeal,
      Color secondaryOrange,
      Color accentGrey,
      Color backgroundGrey,
      Map<String, bool> expandedStates,
      Map<String, bool> groupExpandedStates) {
    final String groupId = titulo.replaceAll(' ', '_');

    // Inicializa el estado de expansión del grupo si no existe
    groupExpandedStates[groupId] ??= false;

    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        return Card(
          margin: EdgeInsets.only(bottom: 16),
          elevation: 3,
          shadowColor: primaryTeal.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: primaryTeal.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              // Encabezado del grupo
              GestureDetector(
                onTap: () {
                  setState(() {
                    groupExpandedStates[groupId] =
                        !groupExpandedStates[groupId]!;
                  });
                },
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: primaryTeal.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: primaryTeal.withOpacity(0.5),
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            titulo.contains('Sin')
                                ? Icons.person_off_outlined
                                : Icons.supervisor_account,
                            color: primaryTeal,
                            size: 24,
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              titulo,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: primaryTeal,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '${registros.length} ${registros.length == 1 ? 'joven' : 'jóvenes'}',
                              style: TextStyle(
                                color: accentGrey,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        groupExpandedStates[groupId]!
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        size: 24,
                        color: primaryTeal,
                      ),
                    ],
                  ),
                ),
              ),
              // Lista de registros si el grupo está expandido
              if (groupExpandedStates[groupId]!)
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: registros.length,
                  itemBuilder: (context, index) {
                    final registro = registros[index];
                    final data = registro.data() as Map<String, dynamic>? ?? {};
                    final registroId = registro.id;

                    // Acceso seguro con valores por defecto
                    final nombre = data['nombre'] as String? ?? '';
                    final apellido = data['apellido'] as String? ?? '';
                    final telefono =
                        data['telefono'] as String? ?? 'No disponible';
                    final ministerioAsignado =
                        data['ministerioAsignado'] ?? 'Sin ministerio';

                    String iniciales = '';
                    if (nombre.isNotEmpty && nombre.length >= 1) {
                      iniciales += nombre[0];
                    }
                    if (apellido.isNotEmpty && apellido.length >= 1) {
                      iniciales += apellido[0];
                    }
                    if (iniciales.isEmpty) {
                      iniciales = '?';
                    }

                    // Determinamos un color de fondo aleatorio pero consistente para las iniciales
                    final List<Color> avatarColors = [
                      primaryTeal,
                      secondaryOrange,
                      accentGrey,
                    ];

                    // Usamos la suma de los códigos de caracteres para generar un índice
                    int colorIndex = 0;
                    if (iniciales.isNotEmpty) {
                      colorIndex = iniciales.codeUnits.reduce((a, b) => a + b) %
                          avatarColors.length;
                    }

                    // Utilizamos un StatefulBuilder para manejar el estado de expansión
                    return StatefulBuilder(
                      builder: (BuildContext context, StateSetter setState) {
                        // Inicializamos el estado de expansión si no existe
                        expandedStates[registroId] ??= false;

                        return Card(
                          margin:
                              EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          elevation: 2,
                          shadowColor: primaryTeal.withOpacity(0.1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: primaryTeal.withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              // Parte superior de la tarjeta con información básica
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    // Invertimos el estado de expansión al tocar
                                    expandedStates[registroId] =
                                        !expandedStates[registroId]!;
                                  });
                                },
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      // Avatar con iniciales
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: avatarColors[colorIndex]
                                              .withOpacity(0.2),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: Border.all(
                                            color: avatarColors[colorIndex]
                                                .withOpacity(0.5),
                                            width: 1.5,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            iniciales,
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: avatarColors[colorIndex],
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 16),
                                      // Información del registro
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '$nombre $apellido',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: primaryTeal,
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.phone_outlined,
                                                  size: 14,
                                                  color: accentGrey,
                                                ),
                                                SizedBox(width: 4),
                                                Text(
                                                  telefono,
                                                  style: TextStyle(
                                                    color: accentGrey,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.account_tree_outlined,
                                                  size: 14,
                                                  color: accentGrey,
                                                ),
                                                SizedBox(width: 4),
                                                Text(
                                                  'Ministerio: $ministerioAsignado',
                                                  style: TextStyle(
                                                    color: accentGrey,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Botones de acción
                                      Row(
                                        children: [
                                          // Botón de ver detalles
                                          Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              onTap: () =>
                                                  _mostrarDetallesRegistro(
                                                context,
                                                data,
                                                primaryTeal,
                                                secondaryOrange,
                                                accentGrey,
                                                backgroundGrey,
                                              ),
                                              child: Container(
                                                padding: EdgeInsets.all(10),
                                                decoration: BoxDecoration(
                                                  color: primaryTeal
                                                      .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Icon(
                                                  Icons.visibility_outlined,
                                                  color: primaryTeal,
                                                  size: 22,
                                                ),
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          // Botón condicional basado en si tiene coordinador asignado
                                          data.containsKey(
                                                      'coordinadorAsignado') &&
                                                  data['coordinadorAsignado'] !=
                                                      null
                                              ? Material(
                                                  color: Colors.transparent,
                                                  child: InkWell(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                    onTap: () =>
                                                        _quitarAsignacion(
                                                            context,
                                                            registroId,
                                                            primaryTeal),
                                                    child: Container(
                                                      padding:
                                                          EdgeInsets.all(10),
                                                      decoration: BoxDecoration(
                                                        color: Colors.red
                                                            .withOpacity(0.1),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(12),
                                                      ),
                                                      child: Icon(
                                                        Icons
                                                            .person_remove_outlined,
                                                        color: Colors.red,
                                                        size: 22,
                                                      ),
                                                    ),
                                                  ),
                                                )
                                              : !data.containsKey(
                                                          'coordinadorAsignado') ||
                                                      data['coordinadorAsignado'] ==
                                                          null
                                                  ? Material(
                                                      color: Colors.transparent,
                                                      child: InkWell(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(12),
                                                        onTap: () =>
                                                            _asignarACoordinador(
                                                                context,
                                                                registro),
                                                        child: Container(
                                                          padding:
                                                              EdgeInsets.all(
                                                                  10),
                                                          decoration:
                                                              BoxDecoration(
                                                            color:
                                                                secondaryOrange
                                                                    .withOpacity(
                                                                        0.1),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        12),
                                                          ),
                                                          child: Icon(
                                                            Icons
                                                                .person_add_alt_1_outlined,
                                                            color:
                                                                secondaryOrange,
                                                            size: 22,
                                                          ),
                                                        ),
                                                      ),
                                                    )
                                                  : SizedBox(),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // Botón para expandir en la parte inferior de la tarjeta
                              Align(
                                alignment: Alignment.centerRight,
                                child: Padding(
                                  padding:
                                      EdgeInsets.only(right: 16, bottom: 8),
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        // Invertimos el estado de expansión con el botón
                                        expandedStates[registroId] =
                                            !expandedStates[registroId]!;
                                      });
                                    },
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: primaryTeal.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            expandedStates[registroId]!
                                                ? 'Menos'
                                                : 'Más',
                                            style: TextStyle(
                                              color: primaryTeal,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(width: 4),
                                          Icon(
                                            expandedStates[registroId]!
                                                ? Icons.keyboard_arrow_up
                                                : Icons.keyboard_arrow_down,
                                            size: 16,
                                            color: primaryTeal,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              // Sección expandible
                              if (expandedStates[registroId]!)
                                Container(
                                  padding: EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: backgroundGrey.withOpacity(0.5),
                                    borderRadius: BorderRadius.only(
                                      bottomLeft: Radius.circular(16),
                                      bottomRight: Radius.circular(16),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Detalles Adicionales',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: primaryTeal,
                                        ),
                                      ),
                                      SizedBox(height: 16),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          Column(
                                            children: [
                                              Material(
                                                color: Colors.transparent,
                                                child: InkWell(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  onTap: () {
                                                    // Lógica para editar registro
                                                    _editarRegistro(
                                                        context, registro);
                                                  },
                                                  child: Container(
                                                    padding: EdgeInsets.all(12),
                                                    decoration: BoxDecoration(
                                                      color: primaryTeal
                                                          .withOpacity(0.1),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                    ),
                                                    child: Column(
                                                      children: [
                                                        Icon(
                                                          Icons.edit_outlined,
                                                          color: primaryTeal,
                                                          size: 28,
                                                        ),
                                                        SizedBox(height: 4),
                                                        Text(
                                                          'Editar',
                                                          style: TextStyle(
                                                            color: primaryTeal,
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          Column(
                                            children: [
                                              Material(
                                                color: Colors.transparent,
                                                child: InkWell(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  onTap: () {
                                                    // Lógica para cambiar ministerio o tribu
                                                    _cambiarMinisterioTribu(
                                                        context, registro);
                                                  },
                                                  child: Container(
                                                    padding: EdgeInsets.all(12),
                                                    decoration: BoxDecoration(
                                                      color: secondaryOrange
                                                          .withOpacity(0.1),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                    ),
                                                    child: Column(
                                                      children: [
                                                        Icon(
                                                          Icons
                                                              .swap_horiz_outlined,
                                                          color:
                                                              secondaryOrange,
                                                          size: 28,
                                                        ),
                                                        SizedBox(height: 4),
                                                        Text(
                                                          'Cambiar',
                                                          style: TextStyle(
                                                            color:
                                                                secondaryOrange,
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
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
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

// Agregar después de la función _editarRegistro o antes del método build
  Future<void> _cambiarMinisterioTribu(
      BuildContext context, DocumentSnapshot registro) async {
    if (context == null || registro == null) {
      print('Error: Contexto o registro nulo');
      return;
    }

    final registroId = registro.id;
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    final Color primaryTeal = Color(0xFF038C7F);
    final Color secondaryOrange = Color(0xFFFF5722);
    final Color accentGrey = Color(0xFF78909C);

    try {
      final registroDoc =
          await _firestore.collection('registros').doc(registroId).get();
      if (!registroDoc.exists) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('El registro no existe o ha sido eliminado.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      List<DropdownMenuItem<String>> opciones = [];
      String? opcionSeleccionada;

      try {
        opciones.addAll([
          DropdownMenuItem(
            value: 'Ministerio de Damas',
            child: _buildOption(
                'Ministerio de Damas', Icons.female, Colors.pinkAccent),
          ),
          DropdownMenuItem(
            value: 'Ministerio de Caballeros',
            child: _buildOption(
                'Ministerio de Caballeros', Icons.male, Colors.blueAccent),
          ),
          DropdownMenuItem(
            value: 'separator',
            enabled: false,
            child: Divider(thickness: 2, color: Colors.grey.shade400),
          ),
          DropdownMenuItem(
            value: 'juveniles_title',
            enabled: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'Tribus del Ministerio Juvenil',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: primaryTeal,
                    fontSize: 16),
              ),
            ),
          ),
        ]);

        final tribusSnapshot = await _firestore
            .collection('tribus')
            .where('categoria', isEqualTo: 'Ministerio Juvenil')
            .get();

        final sortedDocs = tribusSnapshot.docs
          ..sort((a, b) => (a.data()?['nombre'] as String? ?? '')
              .compareTo(b.data()?['nombre'] as String? ?? ''));

        for (var doc in sortedDocs) {
          final nombre = doc.data()?['nombre'] ?? 'Sin nombre';
          opciones.add(DropdownMenuItem(
            value: doc.id,
            child: _buildOption(nombre, Icons.people, primaryTeal),
          ));
        }

        if (opciones.length <= 4 && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('No hay tribus juveniles disponibles para asignar.'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }

        // Obtener el valor actual para preseleccionar
        final data = registroDoc.data() as Map<String, dynamic>?;
        if (data == null) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Error: No se pudieron cargar los datos del registro.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        final ministerioActual = data['ministerioAsignado'] as String?;
        final tribuActual = data['tribuAsignada'] as String?;

        if (ministerioActual != null &&
            ministerioActual.contains('Ministerio')) {
          opcionSeleccionada = ministerioActual;
        } else if (tribuActual != null) {
          opcionSeleccionada = tribuActual;
        }

        if (!context.mounted) return;

        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return StatefulBuilder(
              builder: (context, setState) {
                return AlertDialog(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  title: Row(
                    children: [
                      Icon(Icons.swap_horiz, color: primaryTeal),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Cambiar Ministerio o Tribu',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: primaryTeal),
                        ),
                      ),
                    ],
                  ),
                  content: Container(
                    width: double.maxFinite,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Seleccione el nuevo ministerio o tribu para:',
                          style: TextStyle(fontSize: 14, color: accentGrey),
                        ),
                        SizedBox(height: 5),
                        Text(
                          '${data['nombre'] ?? ''} ${data['apellido'] ?? ''}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: secondaryOrange,
                          ),
                        ),
                        SizedBox(height: 15),
                        Text(
                          'Asignación actual:',
                          style: TextStyle(fontSize: 14, color: accentGrey),
                        ),
                        SizedBox(height: 5),
                        Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: primaryTeal.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                            border:
                                Border.all(color: primaryTeal.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                ministerioActual?.contains('Damas') == true
                                    ? Icons.female
                                    : ministerioActual
                                                ?.contains('Caballeros') ==
                                            true
                                        ? Icons.male
                                        : Icons.people,
                                color: primaryTeal,
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  ministerioActual == null
                                      ? 'Sin asignación'
                                      : tribuActual != null
                                          ? 'Ministerio Juvenil - ${data['nombreTribu'] ?? 'Tribu sin nombre'}'
                                          : ministerioActual.contains('Damas')
                                              ? 'Ministerio de Damas'
                                              : ministerioActual
                                                      .contains('Caballeros')
                                                  ? 'Ministerio de Caballeros'
                                                  : ministerioActual,
                                  style: TextStyle(color: primaryTeal),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 20),
                        DropdownButtonFormField<String>(
                          value: opcionSeleccionada,
                          items: opciones,
                          onChanged: (value) {
                            if (value != null &&
                                value != 'separator' &&
                                value != 'juveniles_title') {
                              setState(() {
                                opcionSeleccionada = value;
                              });
                            }
                          },
                          decoration: InputDecoration(
                            labelText: 'Nueva asignación',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: primaryTeal),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: primaryTeal, width: 2),
                            ),
                            labelStyle: TextStyle(color: primaryTeal),
                            prefixIcon:
                                Icon(Icons.swap_horiz, color: primaryTeal),
                          ),
                          isExpanded: true,
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancelar',
                        style: TextStyle(color: accentGrey),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryTeal,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: opcionSeleccionada == null
                          ? null
                          : () async {
                              try {
                                // Mostrar confirmación antes de realizar el cambio
                                String mensajeConfirmacion =
                                    opcionSeleccionada!.contains('Ministerio')
                                        ? opcionSeleccionada!
                                        : 'Ministerio Juvenil - ' +
                                            await _obtenerNombreTribu(
                                                opcionSeleccionada!);

                                bool confirmar = await _mostrarConfirmacion(
                                  context,
                                  'Confirmar cambio',
                                  '¿Está seguro de cambiar a "$mensajeConfirmacion"?',
                                  primaryTeal,
                                  secondaryOrange,
                                );

                                if (confirmar) {
                                  Navigator.pop(context);
                                  if (context.mounted) {
                                    _procesarCambioAsignacion(
                                        context,
                                        registroId,
                                        opcionSeleccionada!,
                                        primaryTeal);
                                  }
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'Error al procesar la confirmación: ${e.toString()}'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                      child: Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        child: Text('Cambiar'),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al cargar las opciones: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error inesperado: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<bool> _mostrarConfirmacion(
    BuildContext context,
    String titulo,
    String mensaje,
    Color primaryColor,
    Color secondaryColor,
  ) async {
    if (context == null) {
      print('Error: Contexto nulo en mostrarConfirmacion');
      return false;
    }

    bool resultado = false;

    try {
      await showDialog(
        context: context,
        builder: (dialogContext) {
          if (dialogContext == null) return Container();

          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Icon(Icons.help_outline, color: primaryColor),
                SizedBox(width: 10),
                Text(titulo,
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: primaryColor)),
              ],
            ),
            content: Text(mensaje ?? 'Confirmar acción'),
            actions: [
              TextButton(
                onPressed: () {
                  resultado = false;
                  Navigator.pop(dialogContext);
                },
                child: Text('Cancelar', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  resultado = true;
                  Navigator.pop(dialogContext);
                },
                child: Text('Confirmar'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      print('Error en diálogo de confirmación: $e');
      return false;
    }

    return resultado;
  }

  Future<String> _obtenerNombreTribu(String tribuId) async {
    if (tribuId == null || tribuId.isEmpty) {
      return 'Tribu sin nombre';
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('tribus')
          .doc(tribuId)
          .get();
      if (doc.exists && doc.data() != null) {
        return doc.data()?['nombre'] ?? 'Tribu sin nombre';
      }
    } catch (e) {
      print('Error al obtener nombre de tribu: $e');
    }
    return 'Tribu sin nombre';
  }

  Future<void> _procesarCambioAsignacion(
    BuildContext context,
    String registroId,
    String opcionSeleccionada,
    Color primaryColor,
  ) async {
    if (context == null || registroId == null || opcionSeleccionada == null) {
      print('Error: Parámetros nulos en _procesarCambioAsignacion');
      return;
    }

    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    BuildContext? dialogContext;

    // Mostrar indicador de carga y capturar su contexto
    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (loadingContext) {
        dialogContext = loadingContext; // Guardar el contexto del diálogo
        return Center(
          child: CircularProgressIndicator(color: primaryColor),
        );
      },
    );

    try {
      Map<String, dynamic> datosActualizacion = {
        'tribuAsignada': null,
        'ministerioAsignado': null,
        'coordinadorAsignado': null,
        'timoteoAsignado': null,
        'nombreTimoteo': null,
        'fechaAsignacion': FieldValue.serverTimestamp(),
      };

      String mensajeExito = '';

      if (opcionSeleccionada.contains('Ministerio')) {
        // Es un ministerio
        datosActualizacion['ministerioAsignado'] = opcionSeleccionada;
        datosActualizacion['tribuAsignada'] = null;
        datosActualizacion['nombreTribu'] = null;
        mensajeExito =
            'Registro asignado a "$opcionSeleccionada" correctamente';
      } else {
        // Es una tribu
        datosActualizacion['ministerioAsignado'] = 'Ministerio Juvenil';
        datosActualizacion['tribuAsignada'] = opcionSeleccionada;

        String nombreTribu = 'Sin nombre';
        try {
          // Obtener el nombre de la tribu
          final tribuDoc = await _firestore
              .collection('tribus')
              .doc(opcionSeleccionada)
              .get();
          if (tribuDoc.exists && tribuDoc.data() != null) {
            nombreTribu = tribuDoc.data()?['nombre'] ?? 'Sin nombre';
          }
        } catch (e) {
          print('Error al obtener nombre de tribu: $e');
        }

        datosActualizacion['nombreTribu'] = nombreTribu;
        mensajeExito =
            'Registro asignado a "Ministerio Juvenil - $nombreTribu" correctamente';
      }

      // Realizar la actualización
      await _firestore
          .collection('registros')
          .doc(registroId)
          .update(datosActualizacion);

      // Cerrar el diálogo de carga siempre, usando el contexto específico del diálogo
      if (dialogContext != null && Navigator.canPop(dialogContext!)) {
        Navigator.pop(dialogContext!);
      }

      // Mostrar mensaje de éxito
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text(mensajeExito),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error en _procesarCambioAsignacion: $e');

      // Cerrar el diálogo de carga siempre, usando el contexto específico del diálogo
      if (dialogContext != null && Navigator.canPop(dialogContext!)) {
        Navigator.pop(dialogContext!);
      } else {
        // Intento alternativo de cierre
        try {
          if (context.mounted) {
            Navigator.of(context, rootNavigator: true).pop();
          }
        } catch (navError) {
          print('Error al cerrar diálogo alternativo: $navError');
        }
      }

      // Mostrar error
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cambiar asignación: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

// Agregar esta función para cerrar el diálogo de forma segura
  void _cerrarDialogo(BuildContext context) {
    if (context.mounted && Navigator.canPop(context)) {
      try {
        Navigator.of(context, rootNavigator: true).pop();
      } catch (e) {
        print('Error al cerrar diálogo: $e');
      }
    }
  }

  Widget _buildOption(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon ?? Icons.error_outline, color: color),
        SizedBox(width: 10),
        Text(title ?? 'Opción', style: TextStyle(fontSize: 16)),
      ],
    );
  }

//logica para ediar los registro
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
          // Comprobar que el campo existe y es del tipo correcto
          final value = data[field];
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

    // Controladores para los campos (solo se crean para campos que existen)
    final Map<String, TextEditingController> controllers = {};

    // Estado para campos de selección con valores predeterminados para evitar nulos
    String estadoCivilSeleccionado =
        getSafeValue<String>('estadoCivil') ?? 'Soltero(a)';
    String sexoSeleccionado = getSafeValue<String>('sexo') ?? 'Hombre';

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
    };

    // Inicializar controladores de manera segura
    camposDefinicion.forEach((key, value) {
      if (key != 'estadoCivil' && key != 'sexo') {
        // Estos se manejan con dropdowns
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

    // Función para mostrar el diálogo de confirmación con manejo seguro de context
    Future<bool> confirmarSalida() async {
      if (!hayModificaciones) return true;

      // Verificar que el contexto sigue siendo válido
      if (!context.mounted) return false;

      bool confirmar = false;
      await showDialog(
        context: context,
        barrierDismissible: false, // Evitar cierre accidental
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
      barrierDismissible: false, // No se cierra al tocar fuera
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

  void _quitarAsignacion(
      BuildContext context, String registroId, Color primaryTeal) async {
    // Mostrar diálogo de confirmación
    bool confirmar = await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(
                "Confirmar",
                style: TextStyle(
                  color: primaryTeal,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Text(
                "¿Estás seguro de quitar la asignación del coordinador?",
                style: TextStyle(fontSize: 16),
              ),
              actions: [
                TextButton(
                  child: Text(
                    "Cancelar",
                    style: TextStyle(color: Colors.grey),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                ),
                TextButton(
                  child: Text(
                    "Confirmar",
                    style: TextStyle(
                        color: primaryTeal, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                ),
              ],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            );
          },
        ) ??
        false;

    if (confirmar) {
      try {
        await FirebaseFirestore.instance
            .collection('registros')
            .doc(registroId)
            .update({
          'coordinadorAsignado': null,
          'coordinadorNombre': null,
          'timoteoAsignado': null,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Se ha quitado la asignación correctamente",
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: primaryTeal,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: EdgeInsets.all(10),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Error al quitar la asignación: ${e.toString()}",
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: EdgeInsets.all(10),
          ),
        );
      }
    }
  }

  void _mostrarDetallesRegistro(
    BuildContext context,
    Map<String, dynamic> data,
    Color primaryTeal,
    Color secondaryOrange,
    Color accentGrey,
    Color backgroundGrey,
  ) {
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
            'key': 'descripcionOcupaciones',
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
}
