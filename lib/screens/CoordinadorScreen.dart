import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'TimoteosScreen.dart';
import '../utils/email_service.dart';

// Coloca esto al inicio del archivo, después de los imports
const kPrimaryColor = Color(0xFF1B8C8C); // Turquesa
const kSecondaryColor = Color(0xFFFF4D2E); // Naranja/rojo
const kAccentColor = Color(0xFFFFB800); // Amarillo
const kBackgroundColor = Color(0xFFF5F7FA); // Gris muy claro para el fondo

class CoordinadorScreen extends StatelessWidget {
  final String coordinadorId;
  final String coordinadorNombre;

  const CoordinadorScreen({
    Key? key,
    required this.coordinadorId,
    required this.coordinadorNombre,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: kBackgroundColor,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: kPrimaryColor,
          title: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, color: kPrimaryColor),
              ),
              SizedBox(width: 12),
              Column(
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
                    ),
                  ),
                ],
              ),
            ],
          ),
          bottom: TabBar(
            indicator: UnderlineTabIndicator(
              borderSide: BorderSide(width: 3, color: kAccentColor),
              insets: EdgeInsets.symmetric(horizontal: 40),
            ),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            labelStyle: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            tabs: [
              Tab(
                icon: Icon(Icons.people),
                text: 'Timoteos',
              ),
              Tab(
                icon: Icon(Icons.assignment_ind),
                text: 'Asignados',
              ),
              Tab(
                icon: Icon(Icons.warning),
                text: 'Alertas',
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            TimoteosTab(coordinadorId: coordinadorId),
            PersonasAsignadasTab(coordinadorId: coordinadorId),
            AlertasTab(coordinadorId: coordinadorId),
          ],
        ),
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
          final registroData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
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

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kBackgroundColor,
      child: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('registros')
            .where('coordinadorAsignado', isEqualTo: coordinadorId)
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
                  Icon(Icons.person_off, size: 64, color: Colors.grey[400]),
                  SizedBox(height: 16),
                  Text(
                    'No hay personas registradas',
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

          return SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                if (noAsignados.isNotEmpty) ...[
                  _buildSectionHeader(
                    'Personas por asignar',
                    Icons.person_add_alt,
                    kSecondaryColor,
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: noAsignados.length,
                    itemBuilder: (context, index) => _buildPersonCard(
                      context,
                      noAsignados[index],
                      isAssigned: false,
                    ),
                  ),
                  SizedBox(height: 24),
                ],
                if (asignados.isNotEmpty) ...[
                  _buildSectionHeader(
                    'Personas asignadas',
                    Icons.people,
                    kPrimaryColor,
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: asignados.length,
                    itemBuilder: (context, index) => _buildPersonCard(
                      context,
                      asignados[index],
                      isAssigned: true,
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

  Widget _buildPersonCard(BuildContext context, DocumentSnapshot registro,
      {required bool isAssigned}) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color:
              isAssigned ? kPrimaryColor.withOpacity(0.2) : Colors.transparent,
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
                      ? kPrimaryColor.withOpacity(0.1)
                      : kSecondaryColor.withOpacity(0.1),
                  radius: 24,
                  child: Text(
                    '${registro.get('nombre')[0]}${registro.get('apellido')[0]}',
                    style: TextStyle(
                      color: isAssigned ? kPrimaryColor : kSecondaryColor,
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
                            color: Colors.grey[600],
                          ),
                          SizedBox(width: 4),
                          Text(
                            registro.get('telefono'),
                            style: TextStyle(
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
            if (isAssigned) ...[
              Divider(height: 24),
              Row(
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Asignado a: ',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  Text(
                    registro.get('nombreTimoteo'),
                    style: TextStyle(
                      color: kPrimaryColor,
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
                if (!isAssigned)
                  _buildActionButton(
                    icon: Icons.person_add,
                    label: 'Asignar',
                    color: kSecondaryColor,
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
                  icon: Icon(Icons.copy, color: kPrimaryColor),
                  tooltip: 'Copiar teléfono',
                  onPressed: () {
                    Clipboard.setData(
                      ClipboardData(text: registro.get('telefono')),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Teléfono copiado al portapapeles'),
                        duration: Duration(seconds: 1),
                        backgroundColor: kPrimaryColor,
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
