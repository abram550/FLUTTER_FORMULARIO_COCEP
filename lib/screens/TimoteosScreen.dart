import 'dart:math';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:formulario_app/utils/database_utils.dart';
import 'package:formulario_app/utils/email_service.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/date_symbol_data_local.dart';

// Reemplaza todo el contenido de la clase TimoteoScreen
class TimoteoScreen extends StatelessWidget {
  final String timoteoId;
  final String timoteoNombre;

  const TimoteoScreen({
    Key? key,
    required this.timoteoId,
    required this.timoteoNombre,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: const Color(0xFF148B8D),
          title: Text(
            'Timoteo: $timoteoNombre',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          bottom: TabBar(
            indicatorColor: const Color(0xFFFF4B2B),
            indicatorWeight: 4,
            labelStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 16,
            ),
            tabs: const [
              Tab(
                icon: Icon(Icons.person_outline),
                text: 'Perfil',
              ),
              Tab(
                icon: Icon(Icons.groups_outlined),
                text: 'Discípulos',
              ),
            ],
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF148B8D).withOpacity(0.1),
                Colors.white,
              ],
            ),
          ),
          child: TabBarView(
            children: [
              PerfilTab(timoteoId: timoteoId),
              JovenesAsignadosTab(timoteoId: timoteoId),
            ],
          ),
        ),
      ),
    );
  }
}

// Reemplaza todo el contenido de la clase PerfilTab
class PerfilTab extends StatelessWidget {
  final String timoteoId;

  const PerfilTab({Key? key, required this.timoteoId}) : super(key: key);

  Future<void> _editarPerfil(
      BuildContext context, Map<String, dynamic> datos) async {
    final TextEditingController _nameController =
        TextEditingController(text: datos['nombre']);
    final TextEditingController _lastNameController =
        TextEditingController(text: datos['apellido']);
    final TextEditingController _userController =
        TextEditingController(text: datos['usuario']);
    final TextEditingController _passwordController =
        TextEditingController(text: datos['contrasena']);

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Editar Perfil',
            style: TextStyle(
              color: Color(0xFF148B8D),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField(_nameController, 'Nombre', Icons.person),
                const SizedBox(height: 16),
                _buildTextField(
                    _lastNameController, 'Apellido', Icons.person_outline),
                const SizedBox(height: 16),
                _buildTextField(
                    _userController, 'Usuario', Icons.account_circle),
                const SizedBox(height: 16),
                _buildTextField(_passwordController, 'Contraseña', Icons.lock,
                    isPassword: true),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF4B2B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('timoteos')
                    .doc(timoteoId)
                    .update({
                  'nombre': _nameController.text,
                  'apellido': _lastNameController.text,
                  'usuario': _userController.text,
                  'contrasena': _passwordController.text,
                });
                Navigator.pop(context);
              },
              child: const Text(
                'Guardar',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF148B8D)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFF148B8D)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFF148B8D), width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('timoteos')
          .doc(timoteoId)
          .snapshots(),
      builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF148B8D)),
            ),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(
            child: Text(
              'No se encontró el perfil',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          );
        }

        final datos = snapshot.data!.data() as Map<String, dynamic>;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white,
                        const Color(0xFF148B8D).withOpacity(0.1),
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Información Personal',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF148B8D),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.edit,
                              color: Color(0xFFFF4B2B),
                              size: 28,
                            ),
                            onPressed: () => _editarPerfil(context, datos),
                          ),
                        ],
                      ),
                      const Divider(color: Color(0xFF148B8D), thickness: 2),
                      const SizedBox(height: 20),
                      _buildInfoRow(Icons.person, 'Nombre',
                          datos['nombre'] ?? 'No disponible'),
                      const SizedBox(height: 16),
                      _buildInfoRow(Icons.person_outline, 'Apellido',
                          datos['apellido'] ?? 'No disponible'),
                      const SizedBox(height: 16),
                      _buildInfoRow(Icons.account_circle, 'Usuario',
                          datos['usuario'] ?? 'No disponible'),
                      const SizedBox(height: 16),
                      _buildInfoRow(Icons.lock, 'Contraseña', '********'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF148B8D), size: 24),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class JovenesAsignadosTab extends StatelessWidget {
  final String timoteoId;

  const JovenesAsignadosTab({Key? key, required this.timoteoId})
      : super(key: key);

  T? getFieldSafely<T>(Map<String, dynamic> data, String field) {
    try {
      return data[field] as T?;
    } catch (e) {
      return null;
    }
  }

  Color _getColorBasadoEnAlerta(Map<String, dynamic> data) {
    if (data['visible'] == false) {
      return Colors.red.shade100; // Registro con alerta pendiente
    }
    return Colors.white; // Color por defecto
  }

  Future<void> _actualizarEstadoAlerta(
      String alertaId, String nuevoEstado) async {
    try {
      final alertaRef =
          FirebaseFirestore.instance.collection('alertas').doc(alertaId);
      final alertaDoc = await alertaRef.get();

      if (!alertaDoc.exists) return;

      final data = alertaDoc.data() as Map<String, dynamic>;
      final registroId = data['registroId'];

      // Actualizar el estado de la alerta
      await alertaRef.update({
        'estado': nuevoEstado,
        'procesada': nuevoEstado == 'revisado',
        nuevoEstado == 'revisado' ? 'fechaResolucion' : 'fechaRevision':
            FieldValue.serverTimestamp(),
      });

      // Actualizar el estado en el registro
      await FirebaseFirestore.instance
          .collection('registros')
          .doc(registroId)
          .update({
        'estadoAlerta': nuevoEstado,
        'visible': nuevoEstado == 'revisado',
        if (nuevoEstado == 'revisado') 'faltasConsecutivas': 0,
      });
    } catch (e) {
      print('Error al actualizar estado de alerta: $e');
    }
  }

  Future<void> _actualizarEstado(
      BuildContext context, DocumentSnapshot registro) async {
    // Obtener el estado actual del proceso de manera segura
    String estadoActual = '';
    try {
      final data = registro.data() as Map<String, dynamic>;
      estadoActual = data['estadoProceso'] ?? '';
    } catch (e) {
      print('Error al obtener estado actual: $e');
    }

    final TextEditingController estadoController =
        TextEditingController(text: estadoActual);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Actualizar Estado del Proceso'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: estadoController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Estado actual del proceso',
                  hintText:
                      'Describe el estado actual del joven en la iglesia...',
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
              try {
                await FirebaseFirestore.instance
                    .collection('registros')
                    .doc(registro.id)
                    .set({
                  'estadoProceso': estadoController.text.trim(),
                  'fechaActualizacionEstado': FieldValue.serverTimestamp(),
                }, SetOptions(merge: true));

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Estado actualizado correctamente')));
              } catch (e) {
                print('Error al actualizar el estado: $e');
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Error al actualizar el estado: $e')));
              }
            },
            child: Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Map<int, Map<int, List<Map<String, dynamic>>>> agruparAsistenciasPorAnoYMes(
      List<dynamic> asistencias) {
    final asistenciasAgrupadas = <int, Map<int, List<Map<String, dynamic>>>>{};

    for (var asistencia in asistencias) {
      final fecha = (asistencia['fecha'] as Timestamp).toDate();
      final ano = fecha.year;
      final mes = fecha.month;

      asistenciasAgrupadas.putIfAbsent(ano, () => {});
      asistenciasAgrupadas[ano]!.putIfAbsent(mes, () => []);
      asistenciasAgrupadas[ano]![mes]!
          .add(Map<String, dynamic>.from(asistencia));
    }

    return Map.fromEntries(asistenciasAgrupadas.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key)));
  }

  Future<void> _registrarAsistencia(
      BuildContext context, DocumentSnapshot registro) async {
    try {
      final registroRef =
          FirebaseFirestore.instance.collection('registros').doc(registro.id);

      final DateTime? fechaSeleccionada = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime.now().subtract(Duration(days: 30)),
        lastDate: DateTime.now(),
      );

      if (fechaSeleccionada == null) return;

      final bool? asistio = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('¿Asistió al servicio?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                  'Fecha: ${DateFormat('dd/MM/yyyy').format(fechaSeleccionada)}'),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    onPressed: () => Navigator.pop(context, false),
                    child: Text('No Asistió'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    onPressed: () => Navigator.pop(context, true),
                    child: Text('Sí Asistió'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

      if (asistio == null) return;

      final doc = await registroRef.get();
      final data = doc.data() as Map<String, dynamic>;

      int faltasConsecutivas = data['faltasConsecutivas'] ?? 0;
      if (!asistio) {
        faltasConsecutivas++;
      } else {
        faltasConsecutivas = 0;
      }

      // Actualizar documento con las nuevas asistencias y faltas
      await registroRef.update({
        'asistencias': FieldValue.arrayUnion([
          {
            'fecha': Timestamp.fromDate(fechaSeleccionada),
            'asistio': asistio,
          }
        ]),
        'faltasConsecutivas': faltasConsecutivas,
        'ultimaAsistencia': Timestamp.fromDate(fechaSeleccionada),
      });

      // Crear alerta si las faltas son >= 4
      if (faltasConsecutivas >= 4) {
        // Obtener datos del timoteo
        final timoteoDoc = await FirebaseFirestore.instance
            .collection('timoteos')
            .doc(timoteoId)
            .get();

        if (!timoteoDoc.exists) return;

        final coordinadorId = timoteoDoc.get('coordinadorId');

        // Crear nueva alerta
        await FirebaseFirestore.instance.collection('alertas').add({
          'tipo': 'faltasConsecutivas',
          'registroId': registro.id,
          'timoteoId': timoteoId,
          'coordinadorId': coordinadorId,
          'nombreJoven': '${data['nombre']} ${data['apellido']}',
          'nombreTimoteo': '${timoteoDoc['nombre']} ${timoteoDoc['apellido']}',
          'cantidadFaltas': faltasConsecutivas,
          'fecha': FieldValue.serverTimestamp(),
          'estado': 'pendiente',
          'procesada': false,
        });

        // Enviar correo electrónico
        final coordinadorDoc = await FirebaseFirestore.instance
            .collection('coordinadores')
            .doc(coordinadorId)
            .get();

        if (coordinadorDoc.exists) {
          await EmailService.enviarAlertaFaltas(
            emailCoordinador: coordinadorDoc['email'],
            nombreJoven: '${data['nombre']} ${data['apellido']}',
            nombreTimoteo: '${timoteoDoc['nombre']} ${timoteoDoc['apellido']}',
            faltas: faltasConsecutivas,
          );
        }

        // Actualizar visibilidad del registro
        await registroRef
            .update({'visible': false, 'estadoAlerta': 'pendiente'});
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Asistencia registrada correctamente')),
      );
    } catch (e) {
      print('Error al registrar asistencia: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al registrar asistencia: $e')),
      );
    }
  }

  Future<void> _enviarAlerta(DocumentSnapshot registro, int faltas) async {
    try {
      // Obtener datos del timoteo
      final timoteoDoc = await FirebaseFirestore.instance
          .collection('timoteos')
          .doc(timoteoId)
          .get();

      if (!timoteoDoc.exists) return;

      final coordinadorId = timoteoDoc.get('coordinadorId');

      // Obtener datos del coordinador
      final coordinadorDoc = await FirebaseFirestore.instance
          .collection('coordinadores')
          .doc(coordinadorId)
          .get();

      if (!coordinadorDoc.exists) return;

      // Enviar email al coordinador
      await EmailService.enviarAlertaFaltas(
        emailCoordinador: coordinadorDoc['email'],
        nombreJoven: '${registro['nombre']} ${registro['apellido']}',
        nombreTimoteo: '${timoteoDoc['nombre']} ${timoteoDoc['apellido']}',
        faltas: faltas,
      );

      // Crear alerta en Firestore
      await FirebaseFirestore.instance.collection('alertas').add({
        'tipo': 'faltasConsecutivas',
        'registroId': registro.id,
        'timoteoId': timoteoId,
        'coordinadorId': coordinadorId,
        'nombreJoven': '${registro['nombre']} ${registro['apellido']}',
        'nombreTimoteo': '${timoteoDoc['nombre']} ${timoteoDoc['apellido']}',
        'cantidadFaltas': faltas,
        'fecha': FieldValue.serverTimestamp(),
        'estado': 'pendiente',
        'procesada': false,
        'visible': false,
      });

      print('Alerta creada y email enviado correctamente');
    } catch (e) {
      print('Error al enviar alerta: $e');
      // Puedes mostrar un SnackBar o alguna otra notificación al usuario
    }
  }

  Future<void> _enviarAlertaPorEmail(
      DocumentSnapshot registro, int faltas) async {
    try {
      // Obtener datos del timoteo
      final timoteoDoc = await FirebaseFirestore.instance
          .collection('timoteos')
          .doc(timoteoId)
          .get();

      if (!timoteoDoc.exists) return;

      final coordinadorId = timoteoDoc.get('coordinadorId');

      // Obtener datos del coordinador
      final coordinadorDoc = await FirebaseFirestore.instance
          .collection('coordinadores')
          .doc(coordinadorId)
          .get();

      if (!coordinadorDoc.exists) return;

      // Crear la alerta primero
      final alertaRef =
          await FirebaseFirestore.instance.collection('alertas').add({
        'tipo': 'faltasConsecutivas',
        'registroId': registro.id,
        'timoteoId': timoteoId,
        'coordinadorId': coordinadorId,
        'nombreJoven': '${registro['nombre']} ${registro['apellido']}',
        'nombreTimoteo': '${timoteoDoc['nombre']} ${timoteoDoc['apellido']}',
        'cantidadFaltas': faltas,
        'fecha': FieldValue.serverTimestamp(),
        'estado': 'pendiente',
        'procesada': false,
        'emailEnviado': false
      });

      try {
        // Intentar enviar el email
        await EmailService.enviarAlertaFaltas(
          alertaId: alertaRef.id,
          emailCoordinador: coordinadorDoc['email'],
          nombreJoven: '${registro['nombre']} ${registro['apellido']}',
          nombreTimoteo: '${timoteoDoc['nombre']} ${timoteoDoc['apellido']}',
          faltas: faltas,
        );

        // Si llegamos aquí, el email se envió correctamente
        await alertaRef.update({
          'emailEnviado': true,
          'fechaEnvioEmail': FieldValue.serverTimestamp(),
        });
      } catch (emailError) {
        print('Error al enviar email: $emailError');
        // Actualizar el registro con el error pero no interrumpir el flujo
        await alertaRef.update({
          'emailEnviado': false,
          'errorEmail': emailError.toString(),
          'fechaError': FieldValue.serverTimestamp(),
        });
      }

      // Actualizar el registro independientemente del resultado del email
      await FirebaseFirestore.instance
          .collection('registros')
          .doc(registro.id)
          .update({
        'visible': false,
        'estadoAlerta': 'pendiente',
      });
    } catch (e) {
      print('Error general en _enviarAlertaPorEmail: $e');
      throw Exception('Error al crear o actualizar la alerta: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('registros')
          .where('timoteoAsignado', isEqualTo: timoteoId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Color(0xFFFF4B2B)),
                SizedBox(height: 16),
                Text(
                  'Error al cargar los datos',
                  style: TextStyle(
                    fontSize: 18,
                    color: Color(0xFFFF4B2B),
                  ),
                ),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF147B7C)),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Center(
            child: Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 5,
                    blurRadius: 15,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 72,
                    color: Color(0xFF147B7C),
                  ),
                  SizedBox(height: 24),
                  Text(
                    'No hay discípulos asignados',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF147B7C),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Cuando se asignen discípulos, aparecerán aquí',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF147B7C).withOpacity(0.1),
                Colors.white,
              ],
            ),
          ),
          child: ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final registro = docs[index];
              final data = registro.data() as Map<String, dynamic>;

              final nombre =
                  getFieldSafely<String>(data, 'nombre') ?? 'Sin nombre';
              final apellido = getFieldSafely<String>(data, 'apellido') ?? '';
              final telefono =
                  getFieldSafely<String>(data, 'telefono') ?? 'No disponible';
              final faltas =
                  getFieldSafely<int>(data, 'faltasConsecutivas') ?? 0;
              final estadoProceso =
                  getFieldSafely<String>(data, 'estadoProceso') ?? 'Sin estado';
              final asistencias =
                  getFieldSafely<List>(data, 'asistencias') ?? [];

              return Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                margin: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: ExpansionTile(
                    tilePadding:
                        EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    backgroundColor: Colors.white,
                    collapsedBackgroundColor: Colors.white,
                    leading: CircleAvatar(
                      backgroundColor: Color(0xFF147B7C),
                      child: Text(
                        nombre[0].toUpperCase(),
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      '$nombre $apellido',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF147B7C),
                      ),
                    ),
                    subtitle: Row(
                      children: [
                        Icon(
                          Icons.watch_later_outlined,
                          size: 16,
                          color: faltas >= 3
                              ? Color(0xFFFF4B2B)
                              : Colors.grey[600],
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Faltas consecutivas: $faltas',
                          style: TextStyle(
                            color: faltas >= 3
                                ? Color(0xFFFF4B2B)
                                : Colors.grey[600],
                            fontWeight: faltas >= 3
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                    children: [
                      _buildExpandedContent(
                        context,
                        registro,
                        nombre,
                        telefono,
                        estadoProceso,
                        asistencias,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildExpandedContent(
    BuildContext context,
    DocumentSnapshot registro,
    String nombre,
    String telefono,
    String estadoProceso,
    List asistencias,
  ) {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoSection(telefono),
          SizedBox(height: 16),
          _buildEstadoSection(estadoProceso),
          SizedBox(height: 24),
          _buildActionButtons(context, registro),
          if (asistencias.isNotEmpty) ...[
            SizedBox(height: 24),
            _buildAsistenciasSection(asistencias),
          ],
          Text(
            'Dirección: ${registro.get('direccion') ?? 'No especificada'}',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF147B7C),
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Barrio: ${registro.get('barrio') ?? 'No especificado'}',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF147B7C),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String telefono) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFF147B7C).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.phone, color: Color(0xFF147B7C)),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Teléfono de contacto',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  telefono,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.copy, color: Color(0xFF147B7C)),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: telefono));
              // Show snackbar
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEstadoSection(String estadoProceso) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFF147B7C).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timeline, color: Color(0xFF147B7C)),
              SizedBox(width: 12),
              Text(
                'Estado del proceso',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            estadoProceso,
            style: TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, DocumentSnapshot registro) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            icon: Icon(Icons.edit_note, color: Colors.white),
            label: Text('Actualizar Estado'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF147B7C),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => _actualizarEstado(context, registro),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            icon: Icon(Icons.calendar_today, color: Colors.white),
            label: Text('Registrar Asistencia'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFFF4B2B),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => _registrarAsistencia(context, registro),
          ),
        ),
      ],
    );
  }

  Widget _buildAsistenciasSection(List asistencias) {
    // Ordenar las asistencias de más reciente a más antigua
    asistencias.sort((a, b) => (b['fecha'] as Timestamp)
        .toDate()
        .compareTo((a['fecha'] as Timestamp).toDate()));

    final asistenciasAgrupadas = agruparAsistenciasPorAnoYMes(asistencias);

    return StatefulBuilder(
      builder: (context, setState) {
        Map<int, bool> expandedYears = {};
        Map<String, bool> expandedMonths = {};

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Historial de Asistencias',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF147B7C),
              ),
            ),
            SizedBox(height: 16),
            Container(
              height: 300,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Color(0xFF147B7C).withOpacity(0.2)),
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: asistenciasAgrupadas.entries.map((entradaAno) {
                    final year = entradaAno.key;
                    expandedYears.putIfAbsent(year, () => false);

                    return Card(
                      margin: EdgeInsets.only(bottom: 8),
                      elevation: 0,
                      child: ExpansionTile(
                        initiallyExpanded: expandedYears[year] ?? false,
                        onExpansionChanged: (expanded) {
                          setState(() {
                            expandedYears[year] = expanded;
                          });
                        },
                        title: Container(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: Color(0xFF147B7C).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Año ${entradaAno.key}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF147B7C),
                            ),
                          ),
                        ),
                        children: entradaAno.value.entries.map((entradaMes) {
                          final monthKey = '${year}-${entradaMes.key}';
                          expandedMonths.putIfAbsent(monthKey, () => false);

                          return Card(
                            margin:
                                EdgeInsets.only(left: 16, right: 16, bottom: 8),
                            elevation: 0,
                            child: ExpansionTile(
                              initiallyExpanded:
                                  expandedMonths[monthKey] ?? false,
                              onExpansionChanged: (expanded) {
                                setState(() {
                                  expandedMonths[monthKey] = expanded;
                                });
                              },
                              title: Text(
                                DateFormat('MMMM', 'es')
                                    .format(DateTime(2024, entradaMes.key)),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[700],
                                ),
                              ),
                              children: [
                                Container(
                                  height: 100,
                                  child: StatefulBuilder(
                                    builder: (context, setInnerState) {
                                      final asistenciasMes = entradaMes.value;
                                      final totalAsistencias =
                                          asistenciasMes.length;
                                      final paginas =
                                          (totalAsistencias / 5).ceil();
                                      final PageController pageController =
                                          PageController();

                                      return Column(
                                        children: [
                                          Expanded(
                                            child: PageView.builder(
                                              controller: pageController,
                                              itemCount: paginas,
                                              itemBuilder:
                                                  (context, pageIndex) {
                                                final startIndex =
                                                    pageIndex * 5;
                                                final endIndex = min(
                                                    startIndex + 5,
                                                    asistenciasMes.length);
                                                final pageItems =
                                                    asistenciasMes.sublist(
                                                        startIndex, endIndex);

                                                return ListView.builder(
                                                  scrollDirection:
                                                      Axis.horizontal,
                                                  itemCount: pageItems.length,
                                                  itemBuilder:
                                                      (context, index) {
                                                    final asistencia =
                                                        pageItems[index];
                                                    final bool asistio =
                                                        asistencia['asistio'];

                                                    return Card(
                                                      elevation: 2,
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(12),
                                                      ),
                                                      color: asistio
                                                          ? Color(0xFF147B7C)
                                                              .withOpacity(0.1)
                                                          : Color(0xFFFF4B2B)
                                                              .withOpacity(0.1),
                                                      margin: EdgeInsets.only(
                                                          right: 8, bottom: 4),
                                                      child: Container(
                                                        width: 80,
                                                        padding:
                                                            EdgeInsets.all(8),
                                                        child: Column(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: [
                                                            Icon(
                                                              asistio
                                                                  ? Icons
                                                                      .check_circle
                                                                  : Icons
                                                                      .cancel,
                                                              color: asistio
                                                                  ? Color(
                                                                      0xFF147B7C)
                                                                  : Color(
                                                                      0xFFFF4B2B),
                                                              size: 24,
                                                            ),
                                                            SizedBox(height: 4),
                                                            Text(
                                                              DateFormat(
                                                                      'dd/MM')
                                                                  .format(
                                                                (asistencia['fecha']
                                                                        as Timestamp)
                                                                    .toDate(),
                                                              ),
                                                              style: TextStyle(
                                                                fontSize: 12,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                                color: asistio
                                                                    ? Color(
                                                                        0xFF147B7C)
                                                                    : Color(
                                                                        0xFFFF4B2B),
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
                                          if (paginas > 1)
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: List.generate(
                                                paginas,
                                                (index) => Container(
                                                  width: 8,
                                                  height: 8,
                                                  margin: EdgeInsets.symmetric(
                                                      horizontal: 4),
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: Color(0xFF147B7C)
                                                        .withOpacity(index == 0
                                                            ? 1
                                                            : 0.2),
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
