import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'TimoteosScreen.dart';
import 'CoordinadorScreen.dart';

class TribusScreen extends StatelessWidget {
  final String tribuId;
  final String tribuNombre;

  const TribusScreen({Key? key, required this.tribuId, required this.tribuNombre})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, // Se elimina la pestaña de "Asistencia"
      child: Scaffold(
        appBar: AppBar(
          title: Text('Tribu: $tribuNombre'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Timoteos'),
              Tab(text: 'Coordinadores'),
              Tab(text: 'Jóvenes Asignados'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            TimoteosTab(tribuId: tribuId),
            CoordinadoresTab(tribuId: tribuId),
            RegistrosAsignadosTab(tribuId: tribuId),
          ],
        ),
      ),
    );
  }
}

class CoordinadoresTab extends StatelessWidget {
  final String tribuId;

  const CoordinadoresTab({Key? key, required this.tribuId}) : super(key: key);


  Future<void> _crearCoordinador(BuildContext context) async {
    final TextEditingController _nameController = TextEditingController();
    final TextEditingController _lastNameController = TextEditingController();
    final TextEditingController _ageController = TextEditingController();
    final TextEditingController _userController = TextEditingController();
    final TextEditingController _passwordController = TextEditingController();
    final TextEditingController _phoneController = TextEditingController();
    final TextEditingController _emailController = TextEditingController();


  await showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('Crear Coordinador'),
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
                controller: _ageController,
                decoration: InputDecoration(labelText: 'Edad'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Teléfono'),
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\+?[0-9]*$')), // Solo números y +
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
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Correo Electrónico'),
                keyboardType: TextInputType.emailAddress,
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
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('coordinadores').add({
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
            },
            child: Text('Guardar'),
          ),
        ],
      );
    },
  );
}

   Future<void> _eliminarCoordinador(BuildContext context, DocumentSnapshot coordinador) async {
  // Mostrar diálogo de confirmación
  bool? confirmacion = await showDialog<bool>(
    context: context,
    barrierDismissible: false, // Evita que el diálogo se cierre al tocar fuera
    builder: (BuildContext dialogContext) => AlertDialog(
      title: const Text('Confirmar eliminación'),
      content: const Text('¿Estás seguro de eliminar este coordinador? Los timoteos y registros asignados volverán a estar disponibles para asignación.'),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(dialogContext).pop(false); // Cierra el diálogo con false
          },
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(dialogContext).pop(true); // Cierra el diálogo con true
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
      batch.update(timoteo.reference, {
        'coordinadorId': null,
        'nombreCoordinador': null
      });
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Coordinador eliminado correctamente'))
      );
    }
  } catch (e) {
    print('Error al eliminar coordinador: $e');
    // Mostrar mensaje de error
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar el coordinador: $e'))
      );
    }
  }
}


  Future<void> _verTimoteosAsignados(BuildContext context, DocumentSnapshot coordinador) async {
    await showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.8,
            child: Scaffold(
              appBar: AppBar(
                title: Text('Timoteos de ${coordinador['nombre']} ${coordinador['apellido']}'),
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
                            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                            child: ListTile(
                              title: Text('${timoteo['nombre']} ${timoteo['apellido']}'),
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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton(
            onPressed: () => _crearCoordinador(context),
            child: Text('Crear Coordinador'),
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
                return Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(child: Text('No hay coordinadores'));
              }

              return ListView.builder(
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final coordinador = snapshot.data!.docs[index];
                  return Card(
                    child: ExpansionTile(
                      title: Text(
                        '${coordinador['nombre']} ${coordinador['apellido']}',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('Edad: ${coordinador['edad']}'),
                      children: [
                        ListTile(
                          title: Text('Usuario: ${coordinador['usuario']}'),
                          subtitle: Text('Contraseña: ${coordinador['contrasena']}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.group),
                                tooltip: 'Ver timoteos asignados',
                                onPressed: () => _verTimoteosAsignados(context, coordinador),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                tooltip: 'Eliminar Coordinador',
                                onPressed: () => _eliminarCoordinador(context, coordinador),
                              ),
                              IconButton(
                                icon: Icon(Icons.arrow_forward),
                                tooltip: 'Ir a pantalla de coordinador',
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => CoordinadorScreen(
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
        return AlertDialog(
          title: Text('Crear Timoteo'),
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
                await FirebaseFirestore.instance.collection('timoteos').add({
                  'nombre': _nameController.text,
                  'apellido': _lastNameController.text,
                  'usuario': _userController.text,
                  'contrasena': _passwordController.text,
                  'tribuId': tribuId,
                  'coordinadorId': null, // Agregamos este campo explícitamente
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

Future<void> _eliminarTimoteo(BuildContext context, DocumentSnapshot timoteo) async {
  // Mostrar diálogo de confirmación
  bool? confirmacion = await showDialog<bool>(
    context: context,
    barrierDismissible: false, // Evita que el diálogo se cierre al tocar fuera
    builder: (BuildContext dialogContext) => AlertDialog(
      title: const Text('Confirmar eliminación'),
      content: const Text('¿Estás seguro de eliminar este timoteo?'),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(dialogContext).pop(false); // Cierra el diálogo con false
          },
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(dialogContext).pop(true); // Cierra el diálogo con true
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
      batch.update(registro.reference, {
        'timoteoAsignado': null,
        'nombreTimoteo': null
      });
    }

    // Eliminar el timoteo
    batch.delete(timoteo.reference);
    
    await batch.commit();
    
    // Mostrar mensaje de éxito
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Timoteo eliminado correctamente'))
      );
    }
  } catch (e) {
    // Mostrar mensaje de error
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar el timoteo: $e'))
      );
    }
  }
}



  
  
  Future<void> _asignarACoordinador(BuildContext context, DocumentSnapshot timoteo) async {
    final coordinadoresSnapshot = await FirebaseFirestore.instance
        .collection('coordinadores')
        .where('tribuId', isEqualTo: tribuId)
        .get();

    if (coordinadoresSnapshot.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No hay coordinadores disponibles para asignar')),
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
                child: Text('${coordinador['nombre']} ${coordinador['apellido']}'),
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
                      'nombreCoordinador': '${coordinador['nombre']} ${coordinador['apellido']}',
                    });

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Timoteo asignado exitosamente a ${coordinador['nombre']}'),
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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton(
            onPressed: () => _createTimoteo(context),
            child: Text('Crear Timoteo'),
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
                return Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(child: Text('No hay Timoteos disponibles.'));
              }

              // Filtrar los documentos que no tienen coordinadorId o tienen coordinadorId null
              final docs = snapshot.data!.docs.where((doc) {
                return !doc.data().toString().contains('coordinadorId') || 
                       doc.get('coordinadorId') == null;
              }).toList();

              if (docs.isEmpty) {
                return Center(child: Text('No hay Timoteos sin asignar.'));
              }

              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final timoteo = docs[index];
                  return Card(
  margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
  child: ListTile(
    title: Text('${timoteo['nombre']} ${timoteo['apellido']}'),
    subtitle: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Usuario: ${timoteo['usuario']}'),
        Text('Contraseña: ${timoteo['contrasena']}'),
      ],
    ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            tooltip: 'Eliminar Timoteo',
                            onPressed: () => _eliminarTimoteo(context, timoteo),
                          ),
                          IconButton(
                            icon: Icon(Icons.person_add),
                            tooltip: 'Asignar a Coordinador',
                            onPressed: () => _asignarACoordinador(context, timoteo),
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
    );
  }
}

class RegistrosAsignadosTab extends StatelessWidget {
  final String tribuId;

  const RegistrosAsignadosTab({Key? key, required this.tribuId}) : super(key: key);

  Future<void> _asignarACoordinador(BuildContext context, DocumentSnapshot registro) async {
    final coordinadoresSnapshot = await FirebaseFirestore.instance
        .collection('coordinadores')
        .where('tribuId', isEqualTo: tribuId)
        .get();

    if (coordinadoresSnapshot.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay coordinadores disponibles')),
      );
      return;
    }

    String? selectedCoordinador;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Asignar a Coordinador'),
          content: DropdownButtonFormField<String>(
            items: coordinadoresSnapshot.docs.map((coordinador) {
              return DropdownMenuItem(
                value: coordinador.id,
                child: Text('${coordinador['nombre']} ${coordinador['apellido']}'),
              );
            }).toList(),
            onChanged: (value) {
              selectedCoordinador = value;
            },
            decoration: const InputDecoration(labelText: 'Seleccione un coordinador'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedCoordinador != null) {
                  try {
                    await FirebaseFirestore.instance
                        .collection('registros')
                        .doc(registro.id)
                        .update({
                      'coordinadorAsignado': selectedCoordinador,
                      'fechaAsignacionCoordinador': FieldValue.serverTimestamp(),
                    });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Registro asignado exitosamente al coordinador seleccionado'),
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
                }
              },
              child: const Text('Asignar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('registros')
          .where('tribuAsignada', isEqualTo: tribuId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text('No hay jóvenes asignados a esta tribu'),
          );
        }

        // Filtrar los documentos que no tienen coordinadorAsignado
        final docs = snapshot.data!.docs.where((doc) {
          return !doc.data().toString().contains('coordinadorAsignado') ||
                 doc.get('coordinadorAsignado') == null;
        }).toList();

        if (docs.isEmpty) {
          return const Center(
            child: Text('No hay jóvenes sin asignar en esta tribu'),
          );
        }

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final registro = docs[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ListTile(
                title: Text(
                  '${registro['nombre']} ${registro['apellido']}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Teléfono: ${registro['telefono']}',
                  style: const TextStyle(color: Colors.grey),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.person_add, color: Colors.green),
                  tooltip: 'Asignar a Coordinador',
                  onPressed: () => _asignarACoordinador(context, registro),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
