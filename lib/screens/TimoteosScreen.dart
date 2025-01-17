
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:formulario_app/utils/database_utils.dart';
import 'package:formulario_app/utils/email_service.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

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
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Timoteo: $timoteoNombre'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Perfil'),
              Tab(text: 'Jóvenes Asignados'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            PerfilTab(timoteoId: timoteoId),
            JovenesAsignadosTab(timoteoId: timoteoId),
          ],
        ),
      ),
    );
  }
}

class PerfilTab extends StatelessWidget {
  final String timoteoId;

  const PerfilTab({Key? key, required this.timoteoId}) : super(key: key);

  Future<void> _editarPerfil(BuildContext context, Map<String, dynamic> datos) async {
    final TextEditingController _nameController = TextEditingController(text: datos['nombre']);
    final TextEditingController _lastNameController = TextEditingController(text: datos['apellido']);
    final TextEditingController _userController = TextEditingController(text: datos['usuario']);
    final TextEditingController _passwordController = TextEditingController(text: datos['contrasena']);

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Editar Perfil'),
          content: SingleChildScrollView(
            child: Column(
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
                  obscureText: true,
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
              child: Text('Guardar'),
            ),
          ],
        );
      },
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
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Center(child: Text('No se encontró el perfil'));
        }

        final datos = snapshot.data!.data() as Map<String, dynamic>;

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Información Personal',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () => _editarPerfil(context, datos),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      Text('Nombre: ${datos['nombre']}'),
                      Text('Apellido: ${datos['apellido']}'),
                      Text('Usuario: ${datos['usuario']}'),
                      Text('Contraseña: ********'),
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
}

// En TimoteosScreen.dart - JovenesAsignadosTab modificado


class JovenesAsignadosTab extends StatelessWidget {
  final String timoteoId;

  const JovenesAsignadosTab({Key? key, required this.timoteoId}) : super(key: key);


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

  
    Future<void> _actualizarEstadoAlerta(String alertaId, String nuevoEstado) async {
  try {
    final alertaRef = FirebaseFirestore.instance.collection('alertas').doc(alertaId);
    final alertaDoc = await alertaRef.get();
    
    if (!alertaDoc.exists) return;
    
    final data = alertaDoc.data() as Map<String, dynamic>;
    final registroId = data['registroId'];

    // Actualizar el estado de la alerta
    await alertaRef.update({
      'estado': nuevoEstado,
      'procesada': nuevoEstado == 'revisado',
      nuevoEstado == 'revisado' ? 'fechaResolucion' : 'fechaRevision': FieldValue.serverTimestamp(),
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

Future<void> _actualizarEstado(BuildContext context, DocumentSnapshot registro) async {
  // Obtener el estado actual del proceso de manera segura
  String estadoActual = '';
  try {
    final data = registro.data() as Map<String, dynamic>;
    estadoActual = data['estadoProceso'] ?? '';
  } catch (e) {
    print('Error al obtener estado actual: $e');
  }

  final TextEditingController estadoController = TextEditingController(text: estadoActual);
  
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
                hintText: 'Describe el estado actual del joven en la iglesia...',
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
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Estado actualizado correctamente'))
              );
            } catch (e) {
              print('Error al actualizar el estado: $e');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error al actualizar el estado: $e'))
              );
            }
          },
          child: Text('Guardar'),
        ),
      ],
    ),
  );
}


    Map<int, Map<int, List<Map<String, dynamic>>>> agruparAsistenciasPorAnoYMes(List<dynamic> asistencias) {
      final asistenciasAgrupadas = <int, Map<int, List<Map<String, dynamic>>>>{};
      
      for (var asistencia in asistencias) {
        final fecha = (asistencia['fecha'] as Timestamp).toDate();
        final ano = fecha.year;
        final mes = fecha.month;
        
        asistenciasAgrupadas.putIfAbsent(ano, () => {});
        asistenciasAgrupadas[ano]!.putIfAbsent(mes, () => []);
        asistenciasAgrupadas[ano]![mes]!.add(Map<String, dynamic>.from(asistencia));
      }
      
      return Map.fromEntries(
        asistenciasAgrupadas.entries.toList()
          ..sort((a, b) => b.key.compareTo(a.key))
      );
    }

      Future<void> _registrarAsistencia(BuildContext context, DocumentSnapshot registro) async {
        try {
          final registroRef = FirebaseFirestore.instance
              .collection('registros')
              .doc(registro.id);

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
                  Text('Fecha: ${DateFormat('dd/MM/yyyy').format(fechaSeleccionada)}'),
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
            'asistencias': FieldValue.arrayUnion([{
              'fecha': Timestamp.fromDate(fechaSeleccionada),
              'asistio': asistio,
            }]),
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

            // Actualizar visibilidad del registro
            await registroRef.update({
              'visible': false,
              'estadoAlerta': 'pendiente'
            });
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



  Future<void> _enviarAlertaCoordinador(
    DocumentSnapshot registro,
    String telefonoCoordinador,
    int faltas,
  ) async {
    final url = Uri.parse('https://api.whatsapp.com/send').replace(
      queryParameters: {
        'phone': telefonoCoordinador,
        'text': Uri.encodeComponent(
          '🚨 ALERTA DE ASISTENCIA 🚨\n\n'
          'El joven ${registro['nombre']} ${registro['apellido']} '
          'ha acumulado $faltas faltas consecutivas.\n\n'
          'Por favor, realizar seguimiento urgente.'
        ),
      },
    );

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      }
    } catch (e) {
      print('Error al enviar mensaje de WhatsApp: $e');
    }
  }


  


Widget build(BuildContext context) {
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('registros')
        .where('timoteoAsignado', isEqualTo: timoteoId)
        .snapshots(),
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Center(child: Text('Error al cargar los datos'));
      }

      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }

      final docs = snapshot.data?.docs ?? [];

      if (docs.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.person_outline, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('No hay jóvenes asignados todavía'),
            ],
          ),
        );
      }

      return ListView.builder(
        itemCount: docs.length,
        itemBuilder: (context, index) {
          final registro = docs[index];
          final data = registro.data() as Map<String, dynamic>;
          
          // Obtener el estado de la alerta y determinar el color


              // Obtener datos de manera segura
              final nombre = getFieldSafely<String>(data, 'nombre') ?? 'Sin nombre';
              final apellido = getFieldSafely<String>(data, 'apellido') ?? '';
              final telefono = getFieldSafely<String>(data, 'telefono') ?? 'No disponible';
              final faltas = getFieldSafely<int>(data, 'faltasConsecutivas') ?? 0;
              final estadoProceso = getFieldSafely<String>(data, 'estadoProceso') ?? 'Sin estado';
              final asistencias = getFieldSafely<List>(data, 'asistencias') ?? [];

           return Card(
            margin: const EdgeInsets.all(8),
            child: ExpansionTile(
              title: Text(data['nombre'] ?? 'Sin nombre'),
              subtitle: Text('Faltas consecutivas: ${data['faltasConsecutivas'] ?? 0}'),
              children: [
                Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text('Teléfono: $telefono'),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy, color: Colors.blue),
                              tooltip: 'Copiar teléfono',
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: telefono));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Teléfono copiado al portapapeles'),
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('Estado del proceso: $estadoProceso'),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton.icon(
                              icon: const Icon(Icons.edit_note),
                              label: const Text('Actualizar Estado'),
                              onPressed: () => _actualizarEstado(context, registro),
                            ),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.calendar_today),
                              label: const Text('Registrar Asistencia'),
                              onPressed: () => _registrarAsistencia(context, registro),
                            ),
                          ],
                        ),
                        if (asistencias.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          const Text('Historial de Asistencias:'),
                          const SizedBox(height: 8),
                          Container(
                            height: 200,
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ...agruparAsistenciasPorAnoYMes(asistencias)
                                      .entries
                                      .map((entradaAno) {
                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.all(8),
                                          child: Text(
                                            'Año ${entradaAno.key}',
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        ...entradaAno.value.entries.map((entradaMes) {
                                          return Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                                child: Text(
                                                  'Mes ${DateFormat('MMMM').format(DateTime(2024, entradaMes.key))}',
                                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                                ),
                                              ),
                                              Container(
                                                height: 100,
                                                child: ListView.builder(
                                                  scrollDirection: Axis.horizontal,
                                                  itemCount: entradaMes.value.length,
                                                  itemBuilder: (context, index) {
                                                    final asistencia = entradaMes.value[index];
                                                    return Card(
                                                      color: asistencia['asistio']
                                                          ? Colors.green[100]
                                                          : Colors.red[100],
                                                      child: Padding(
                                                        padding: const EdgeInsets.all(8),
                                                        child: Column(
                                                          mainAxisAlignment: MainAxisAlignment.center,
                                                          children: [
                                                            Icon(
                                                              asistencia['asistio']
                                                                  ? Icons.check
                                                                  : Icons.close,
                                                              color: asistencia['asistio']
                                                                  ? Colors.green
                                                                  : Colors.red,
                                                            ),
                                                            Text(
                                                              DateFormat('dd/MM/yy').format(
                                                                (asistencia['fecha'] as Timestamp)
                                                                    .toDate(),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                            ],
                                          );
                                        }).toList(),
                                      ],
                                    );
                                  }).toList(),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}