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
import 'package:flutter_animate/flutter_animate.dart';

// Constantes de color basadas en el logo
const Color kPrimaryColor = Color(0xFF148B8D); // Color turquesa del logo
const Color kSecondaryColor =
    Color(0xFFFF5722); // Color naranja/rojo de la llama
const Color kAccentColor =
    Color(0xFFFFB74D); // Color amarillo/dorado de la llama
const Color kBackgroundColor = Color(0xFFF8F9FA);
const Color kCardColor = Colors.white;

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
        backgroundColor: kBackgroundColor,
        appBar: AppBar(
          elevation: 2,
          backgroundColor: kPrimaryColor,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(20),
            ),
          ),
          title: Row(
            children: [
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.person,
                  color: kPrimaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Timoteo',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white70,
                      ),
                    ),
                    Text(
                      timoteoNombre,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
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
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {},
              tooltip: 'Notificaciones',
            ),
          ],
          bottom: TabBar(
            indicatorColor: kSecondaryColor,
            indicatorWeight: 4,
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 16,
            ),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.person_outline),
                    SizedBox(width: 8),
                    Text('Perfil'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.groups_outlined),
                    SizedBox(width: 8),
                    Text('Discípulos'),
                  ],
                ),
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
                kPrimaryColor.withOpacity(0.05),
                kBackgroundColor,
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
          backgroundColor: kCardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(
                Icons.edit,
                color: kSecondaryColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                'Editar Perfil',
                style: TextStyle(
                  color: kPrimaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
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
              child: Text(
                'Cancelar',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kSecondaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                elevation: 2,
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
                // Mostrar SnackBar de confirmación
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Perfil actualizado correctamente'),
                    backgroundColor: kPrimaryColor,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              },
              child: const Text(
                'Guardar',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
      style: TextStyle(fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade700),
        prefixIcon: Icon(icon, color: kPrimaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: kPrimaryColor, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: EdgeInsets.symmetric(vertical: 16),
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
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(kPrimaryColor),
            ),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.person_off_outlined,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                const Text(
                  'No se encontró el perfil',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        final datos = snapshot.data!.data() as Map<String, dynamic>;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tarjeta de bienvenida
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        kPrimaryColor,
                        kPrimaryColor.withOpacity(0.8),
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white,
                        child: Text(
                          datos['nombre']?.substring(0, 1).toUpperCase() ?? 'T',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: kPrimaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '¡Bienvenido!',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                            Text(
                              '${datos['nombre'] ?? ''} ${datos['apellido'] ?? ''}',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2, end: 0),

              const SizedBox(height: 20),

              // Tarjeta de información personal
              Card(
                elevation: 2,
                shadowColor: Colors.black26,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: kCardColor,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.person,
                                color: kPrimaryColor,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Información Personal',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: kPrimaryColor,
                                ),
                              ),
                            ],
                          ),
                          InkWell(
                            onTap: () => _editarPerfil(context, datos),
                            borderRadius: BorderRadius.circular(30),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: kSecondaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Icon(
                                Icons.edit,
                                color: kSecondaryColor,
                                size: 22,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(color: kPrimaryColor, thickness: 1),
                      const SizedBox(height: 16),
                      _buildInfoRow(Icons.person, 'Nombre',
                          datos['nombre'] ?? 'No disponible'),
                      const SizedBox(height: 20),
                      _buildInfoRow(Icons.person_outline, 'Apellido',
                          datos['apellido'] ?? 'No disponible'),
                      const SizedBox(height: 20),
                      _buildInfoRow(Icons.account_circle, 'Usuario',
                          datos['usuario'] ?? 'No disponible'),
                      const SizedBox(height: 20),
                      _buildInfoRow(Icons.lock, 'Contraseña', '••••••••'),
                    ],
                  ),
                ),
              )
                  .animate()
                  .fadeIn(duration: 300.ms, delay: 100.ms)
                  .slideY(begin: 0.2, end: 0),

              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: kPrimaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: kPrimaryColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionButton(
    BuildContext context, {
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: EdgeInsets.only(bottom: 8),
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(icon, color: kPrimaryColor, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey.shade400,
              size: 16,
            ),
          ],
        ),
      ),
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

  String obtenerNombreServicio(String categoriaTribu, DateTime fecha) {
    final String diaSemana = DateFormat('EEEE', 'es').format(fecha);

    if (categoriaTribu == "Ministerio de Damas") {
      switch (diaSemana) {
        case "martes":
          return "Servicio de Damas";
        case "viernes":
          return "Viernes de Poder";
        case "domingo":
          return "Servicio Dominical";
      }
    } else if (categoriaTribu == "Ministerio de Caballeros") {
      switch (diaSemana) {
        case "jueves":
          return "Servicio de Caballeros";
        case "viernes":
          return "Viernes de Poder";
        case "sábado":
          return "Servicio de Caballero";
        case "domingo":
          return "Servicio Dominical";
      }
    } else if (categoriaTribu == "Ministerio Juvenil") {
      switch (diaSemana) {
        case "viernes":
          return "Viernes de Poder";
        case "sábado":
          return "Impacto Juvenil";
        case "domingo":
          return "Servicio Dominical";
      }
    }
    return "Reunión General"; // Nombre por defecto si no coincide con ningún caso.
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

      // Obtener el ID de la tribu del Timoteo
      final timoteoDoc = await FirebaseFirestore.instance
          .collection('timoteos')
          .doc(timoteoId)
          .get();
      final tribuId = timoteoDoc.get('tribuId');

      // Obtener la categoría de la tribu
      final tribuDoc = await FirebaseFirestore.instance
          .collection('tribus')
          .doc(tribuId)
          .get();
      final categoriaTribu =
          tribuDoc.exists ? tribuDoc.get('categoria') : "General";

      // Obtener el nombre específico del servicio basado en la tribu y el día
      String nombreServicio =
          obtenerNombreServicio(categoriaTribu, fechaSeleccionada);

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
            'nombreServicio':
                nombreServicio, // Registrar el servicio con nombre específico
          }
        ]),
        'faltasConsecutivas': faltasConsecutivas,
        'ultimaAsistencia': Timestamp.fromDate(fechaSeleccionada),
      });

      // Registrar la asistencia en la colección de asistencias
      await FirebaseFirestore.instance.collection('asistencias').add({
        'registroId': registro.id,
        'tribuId': tribuId,
        'nombre': '${data['nombre']} ${data['apellido']}',
        'fecha': Timestamp.fromDate(fechaSeleccionada),
        'nombreServicio':
            nombreServicio, // Nombre correcto del servicio según el día y tribu
        'asistio': asistio,
        'diaSemana': DateFormat('EEEE', 'es').format(fechaSeleccionada),
      });

      // Mantener el registro de asistencia por tribu si aplica
      final tribusSnapshot = await FirebaseFirestore.instance
          .collection('tribus')
          .where('timoteoId', isEqualTo: timoteoId)
          .limit(1)
          .get();

      if (tribusSnapshot.docs.isNotEmpty) {
        final tribuDoc = tribusSnapshot.docs.first;

        await FirebaseFirestore.instance.collection('asistenciaTribus').add({
          'tribuId': tribuDoc.id,
          'tribuNombre': tribuDoc['nombre'],
          'registroId': registro.id,
          'nombreJoven': '${data['nombre']} ${data['apellido']}',
          'fecha': Timestamp.fromDate(fechaSeleccionada),
          'diaSemana': DateFormat('EEEE', 'es').format(fechaSeleccionada),
          'nombreServicio': nombreServicio,
          'asistio': asistio,
        });
      }

      // Crear alerta si las faltas son >= 4
      if (faltasConsecutivas >= 4) {
        // Obtener datos del timoteo
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
                                                            if (asistencia
                                                                .containsKey(
                                                                    'nombreServicio')) ...[
                                                              SizedBox(
                                                                  height: 2),
                                                              Text(
                                                                asistencia[
                                                                    'nombreServicio'],
                                                                style:
                                                                    TextStyle(
                                                                  fontSize: 10,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w400,
                                                                  color: asistio
                                                                      ? Color(
                                                                          0xFF147B7C)
                                                                      : Color(
                                                                          0xFFFF4B2B),
                                                                ),
                                                                textAlign:
                                                                    TextAlign
                                                                        .center,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                              ),
                                                            ],
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
