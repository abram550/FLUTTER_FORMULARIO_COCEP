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

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeConstants.appTheme,
      child: DefaultTabController(
        length: 4, // Cambiado de 3 a 4 para incluir la nueva pestaña
        child: Scaffold(
          appBar: AppBar(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/Cocep_.png', // Asegúrate de tener el logo en assets
                  height: 36, // Ajustado a un tamaño menor
                ),
                SizedBox(width: 12),
                Text(
                  'Tribu: $tribuNombre',
                  style: TextStyle(
                    fontSize: 20, // Reducido
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            bottom: PreferredSize(
              preferredSize:
                  Size.fromHeight(56), // Reducido el tamaño de la pestaña
              child: Container(
                decoration: BoxDecoration(
                  color: ThemeConstants.primaryTeal,
                  border: Border(
                    bottom: BorderSide(
                      color: ThemeConstants.secondaryOrange,
                      width: 2.5, // Reducido
                    ),
                  ),
                ),
                child: TabBar(
                  tabs: [
                    Tab(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people, size: 22), // Icono más pequeño
                          Text(
                            'Timoteos',
                            style: TextStyle(fontSize: 10), // Reducido
                          ),
                        ],
                      ),
                    ),
                    Tab(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.supervised_user_circle, size: 24),
                          Text(
                            'Coordinadores',
                            style: TextStyle(fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                    Tab(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.assignment_ind, size: 24),
                          Text(
                            'Jóvenes',
                            style: TextStyle(fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                    Tab(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.list, size: 24),
                          Text(
                            'Asistencias',
                            style: TextStyle(fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ],
                  indicatorColor: ThemeConstants.secondaryOrange,
                  indicatorWeight: 2.5,
                  labelStyle: TextStyle(fontWeight: FontWeight.bold),
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
                  ThemeConstants.primaryTeal.withOpacity(0.1),
                  Colors.white,
                ],
              ),
            ),
            child: TabBarView(
              children: [
                TimoteosTab(tribuId: tribuId),
                CoordinadoresTab(tribuId: tribuId),
                RegistrosAsignadosTab(tribuId: tribuId),
                AsistenciasTab(tribuId: tribuId), // Nueva pestaña agregada
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AsistenciasTab extends StatelessWidget {
  final String tribuId;

  const AsistenciasTab({Key? key, required this.tribuId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('asistencias')
          .where('tribuId', isEqualTo: tribuId) // Filtrar por tribuId
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor:
                  AlwaysStoppedAnimation<Color>(ThemeConstants.primaryTeal),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_busy,
                    size: 56, color: ThemeConstants.primaryTeal),
                SizedBox(height: 12),
                Text(
                  'No hay asistencias registradas para esta tribu',
                  style: TextStyle(
                    fontSize: 16,
                    color: ThemeConstants.primaryTeal,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        final asistencias = snapshot.data!.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'nombre': data['nombre'],
            'fecha': (data['fecha'] as Timestamp).toDate(),
            'diaSemana': data['diaSemana'],
            'asistio': data['asistio'],
          };
        }).toList();
        final agrupadas = _agruparAsistencias(asistencias);

        return Container(
          padding: EdgeInsets.all(12), // Reducido
          child: ListView.builder(
            itemCount: agrupadas.keys.length,
            itemBuilder: (context, yearIndex) {
              final year = agrupadas.keys.elementAt(yearIndex);
              final months = agrupadas[year]!;

              return Card(
                elevation: 3, // Reducido
                margin: EdgeInsets.only(bottom: 12), // Reducido
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Theme(
                  data: Theme.of(context).copyWith(
                    dividerColor: Colors.transparent,
                  ),
                  child: ExpansionTile(
                    title: Text(
                      'Año $year',
                      style: TextStyle(
                        fontSize: 18, // Reducido
                        fontWeight: FontWeight.bold,
                        color: ThemeConstants.primaryTeal,
                      ),
                    ),
                    children: months.keys.map((month) {
                      return _buildMonthSection(context, month, months[month]!);
                    }).toList(),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildMonthSection(BuildContext context, String month,
      Map<String, List<Map<String, dynamic>>> weeks) {
    final monthName = _getSpanishMonth(month);

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: ThemeConstants.primaryTeal.withOpacity(0.05),
      child: ExpansionTile(
        title: Text(
          monthName,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: ThemeConstants.primaryTeal,
          ),
        ),
        children: weeks.keys.map((week) {
          return _buildWeekSection(context, week, weeks[week]!);
        }).toList(),
      ),
    );
  }

  Widget _buildWeekSection(BuildContext context, String week,
      List<Map<String, dynamic>> asistencias) {
    final viernes = asistencias
        .where((a) => a['diaSemana'] == 'viernes' && a['asistio'])
        .toList();
    final sabado = asistencias
        .where((a) => a['diaSemana'] == 'sábado' && a['asistio'])
        .toList();
    final domingo = asistencias
        .where((a) => a['diaSemana'] == 'domingo' && a['asistio'])
        .toList();
    final totalUnico = {
      ...viernes.map((a) => a['nombre']),
      ...sabado.map((a) => a['nombre']),
      ...domingo.map((a) => a['nombre'])
    }.length;

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ExpansionTile(
        title: Text(
          week,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        children: [
          _buildDaySection(
            'Viernes de Poder',
            viernes,
            Icons.local_fire_department,
            ThemeConstants.secondaryOrange,
          ),
          _buildDaySection(
            'Impacto Juvenil',
            sabado,
            Icons.star,
            ThemeConstants.primaryTeal,
          ),
          _buildDaySection(
            'Servicio Familiar',
            domingo,
            Icons.favorite,
            ThemeConstants.secondaryOrange,
          ),
          _buildTotalSection(
              viernes.length, sabado.length, domingo.length, totalUnico),
        ],
      ),
    );
  }

  Widget _buildDaySection(String title, List<Map<String, dynamic>> asistencias,
      IconData icon, Color color) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: color.withOpacity(0.1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14, // Reduced font size
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                    maxLines: 2, // Allow two lines if needed
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: 8),
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2), // Reduced padding
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${asistencias.length}',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w500,
                      fontSize: 12, // Smaller font size
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
              itemBuilder: (context, index) {
                final asistencia = asistencias[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: color.withOpacity(0.2),
                    child: Text(
                      asistencia['nombre'][0].toUpperCase(),
                      style: TextStyle(color: color),
                    ),
                  ),
                  title: Text(asistencia['nombre']),
                  subtitle: Text(
                    DateFormat('dd/MM/yyyy').format(asistencia['fecha']),
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                );
              },
            ),
          ] else
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'No hay asistencias registradas',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTotalSection(
      int viernesCount, int sabadoCount, int domingoCount, int totalUnico) {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: ThemeConstants.primaryTeal.withOpacity(0.1),
        border: Border.all(
          color: ThemeConstants.primaryTeal.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumen de Asistencia',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: ThemeConstants.primaryTeal,
            ),
          ),
          SizedBox(height: 12),
          _buildTotalRow('Viernes de Poder', viernesCount),
          _buildTotalRow('Impacto Juvenil', sabadoCount),
          _buildTotalRow('Servicio Familiar', domingoCount),
          Divider(height: 24),
          _buildTotalRow('Total de personas únicas', totalUnico, isTotal: true),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, int count, {bool isTotal = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? ThemeConstants.primaryTeal : Colors.grey[700],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: isTotal ? ThemeConstants.primaryTeal : Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isTotal ? Colors.white : Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, Map<String, Map<String, List<Map<String, dynamic>>>>>
      _agruparAsistencias(
    List<Map<String, dynamic>> asistencias,
  ) {
    final Map<String, Map<String, Map<String, List<Map<String, dynamic>>>>>
        agrupadas = {};

    for (var asistencia in asistencias) {
      final fecha = asistencia['fecha'];
      final year = DateFormat('yyyy').format(fecha);
      final month = DateFormat('MMMM').format(fecha);
      final week = 'Semana ${(fecha.day / 7).ceil()}';

      agrupadas.putIfAbsent(year, () => {});
      agrupadas[year]!.putIfAbsent(month, () => {});
      agrupadas[year]![month]!.putIfAbsent(week, () => []);
      agrupadas[year]![month]![week]!.add(asistencia);
    }

    return agrupadas;
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

  const RegistrosAsignadosTab({Key? key, required this.tribuId})
      : super(key: key);

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
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            ThemeConstants.primaryTeal.withOpacity(0.05),
            Colors.white,
          ],
        ),
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('registros')
            .where('tribuAsignada', isEqualTo: tribuId)
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
                    Icons.group_off_outlined,
                    size: 64,
                    color: ThemeConstants.accentGrey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No hay jóvenes asignados a esta tribu',
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
            return !doc.data().toString().contains('coordinadorAsignado') ||
                doc.get('coordinadorAsignado') == null;
          }).toList();

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: ThemeConstants.secondaryOrange,
                  ),
                  SizedBox(height: 16),
                  Text(
                    '¡Todos los jóvenes están asignados!',
                    style: TextStyle(
                      fontSize: 18,
                      color: ThemeConstants.primaryTeal,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          return Padding(
            padding: EdgeInsets.all(16),
            child: ListView.builder(
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final registro = docs[index];
                return Card(
                  margin: EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: ThemeConstants.primaryTeal.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _asignarACoordinador(context, registro),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color:
                                  ThemeConstants.primaryTeal.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                '${registro['nombre'][0]}${registro['apellido'][0]}',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: ThemeConstants.primaryTeal,
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
                                  '${registro['nombre']} ${registro['apellido']}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: ThemeConstants.primaryTeal,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Tel: ${registro['telefono']}',
                                  style: TextStyle(
                                    color: ThemeConstants.accentGrey,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: ThemeConstants.secondaryOrange
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: EdgeInsets.all(8),
                            child: Icon(
                              Icons.person_add,
                              color: ThemeConstants.secondaryOrange,
                              size: 24,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
