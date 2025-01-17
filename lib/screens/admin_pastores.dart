import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'TribusScreen.dart';
import 'admin_screen.dart';

class AdminPastores extends StatefulWidget {
  const AdminPastores({Key? key}) : super(key: key);

  @override
  _AdminPastoresState createState() => _AdminPastoresState();
}

class _AdminPastoresState extends State<AdminPastores> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Controladores para Tribus
  final _nombreTribuController = TextEditingController();
  final _nombreLiderController = TextEditingController();
  final _apellidoLiderController = TextEditingController();
  final _usuarioTribuController = TextEditingController();
  final _contrasenaTribuController = TextEditingController();

  // Controladores para Líder de Consolidación
  final _nombreLiderConsolidacionController = TextEditingController();
  final _apellidoLiderConsolidacionController = TextEditingController();
  final _usuarioLiderConsolidacionController = TextEditingController();
  final _contrasenaLiderConsolidacionController = TextEditingController();

  bool _mostrarFormularioTribu = false;
  bool _mostrarFormularioLiderConsolidacion = false;
  bool _existeLiderConsolidacion = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _verificarLiderConsolidacion();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nombreTribuController.dispose();
    _nombreLiderController.dispose();
    _apellidoLiderController.dispose();
    _usuarioTribuController.dispose();
    _contrasenaTribuController.dispose();
    _nombreLiderConsolidacionController.dispose();
    _apellidoLiderConsolidacionController.dispose();
    _usuarioLiderConsolidacionController.dispose();
    _contrasenaLiderConsolidacionController.dispose();
    super.dispose();
  }

  Future<void> _verificarLiderConsolidacion() async {
    final snapshot = await _firestore
        .collection('usuarios')
        .where('rol', isEqualTo: 'liderConsolidacion')
        .get();
    setState(() {
      _existeLiderConsolidacion = snapshot.docs.isNotEmpty;
    });
  }

  String _hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  // Métodos para Tribus
  Future<void> _crearTribu() async {
    if (_nombreTribuController.text.isEmpty ||
        _nombreLiderController.text.isEmpty ||
        _apellidoLiderController.text.isEmpty ||
        _usuarioTribuController.text.isEmpty ||
        _contrasenaTribuController.text.isEmpty) {
      _mostrarSnackBar('Por favor complete todos los campos');
      return;
    }

    try {
      await _firestore.collection('tribus').add({
        'nombre': _nombreTribuController.text,
        'nombreLider': _nombreLiderController.text,
        'apellidoLider': _apellidoLiderController.text,
        'usuario': _usuarioTribuController.text,
        'contrasena': _hashPassword(_contrasenaTribuController.text),
        'rol': 'tribu',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // También crear el usuario en la colección de usuarios
      await _firestore.collection('usuarios').add({
        'usuario': _usuarioTribuController.text,
        'contrasena': _hashPassword(_contrasenaTribuController.text),
        'rol': 'tribu',
        'tribuId': _nombreTribuController.text,
      });

      _limpiarFormularioTribu();
      _mostrarSnackBar('Tribu creada exitosamente');
      setState(() => _mostrarFormularioTribu = false);
    } catch (e) {
      _mostrarSnackBar('Error al crear la tribu: $e');
    }
  }

  Future<void> _editarTribu(String docId, Map<String, dynamic> datos) async {
    try {
      await _firestore.collection('tribus').doc(docId).update({
        'nombre': datos['nombre'],
        'nombreLider': datos['nombreLider'],
        'apellidoLider': datos['apellidoLider'],
        'usuario': datos['usuario'],
        'contrasena': _hashPassword(datos['contrasena']),
      });

      // Actualizar también en la colección de usuarios
      final usuarioSnapshot = await _firestore
          .collection('usuarios')
          .where('tribuId', isEqualTo: datos['nombreAntiguo'])
          .get();
      
      if (usuarioSnapshot.docs.isNotEmpty) {
        await usuarioSnapshot.docs.first.reference.update({
          'usuario': datos['usuario'],
          'contrasena': _hashPassword(datos['contrasena']),
          'tribuId': datos['nombre'],
        });
      }

      _mostrarSnackBar('Tribu actualizada exitosamente');
    } catch (e) {
      _mostrarSnackBar('Error al actualizar la tribu: $e');
    }
  }

  // Métodos para Líder de Consolidación
  Future<void> _crearLiderConsolidacion() async {
    if (_existeLiderConsolidacion) {
      _mostrarSnackBar('Ya existe un líder de consolidación');
      return;
    }

    if (_nombreLiderConsolidacionController.text.isEmpty ||
        _apellidoLiderConsolidacionController.text.isEmpty ||
        _usuarioLiderConsolidacionController.text.isEmpty ||
        _contrasenaLiderConsolidacionController.text.isEmpty) {
      _mostrarSnackBar('Por favor complete todos los campos');
      return;
    }

    try {
      await _firestore.collection('lideresConsolidacion').add({
        'nombre': _nombreLiderConsolidacionController.text,
        'apellido': _apellidoLiderConsolidacionController.text,
        'usuario': _usuarioLiderConsolidacionController.text,
        'contrasena': _hashPassword(_contrasenaLiderConsolidacionController.text),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Crear usuario en la colección de usuarios
      await _firestore.collection('usuarios').add({
        'usuario': _usuarioLiderConsolidacionController.text,
        'contrasena': _hashPassword(_contrasenaLiderConsolidacionController.text),
        'rol': 'liderConsolidacion',
      });

      _limpiarFormularioLiderConsolidacion();
      _mostrarSnackBar('Líder de consolidación creado exitosamente');
      setState(() {
        _mostrarFormularioLiderConsolidacion = false;
        _existeLiderConsolidacion = true;
      });
    } catch (e) {
      _mostrarSnackBar('Error al crear el líder de consolidación: $e');
    }
  }

  Future<void> _editarLiderConsolidacion(String docId, Map<String, dynamic> datos) async {
    try {
      await _firestore.collection('lideresConsolidacion').doc(docId).update({
        'nombre': datos['nombre'],
        'apellido': datos['apellido'],
        'usuario': datos['usuario'],
        'contrasena': _hashPassword(datos['contrasena']),
      });

      // Actualizar también en la colección de usuarios
      final usuarioSnapshot = await _firestore
          .collection('usuarios')
          .where('rol', isEqualTo: 'liderConsolidacion')
          .get();
      
      if (usuarioSnapshot.docs.isNotEmpty) {
        await usuarioSnapshot.docs.first.reference.update({
          'usuario': datos['usuario'],
          'contrasena': _hashPassword(datos['contrasena']),
        });
      }

      _mostrarSnackBar('Líder de consolidación actualizado exitosamente');
    } catch (e) {
      _mostrarSnackBar('Error al actualizar el líder de consolidación: $e');
    }
  }

  

  void _limpiarFormularioTribu() {
    _nombreTribuController.clear();
    _nombreLiderController.clear();
    _apellidoLiderController.clear();
    _usuarioTribuController.clear();
    _contrasenaTribuController.clear();
  }

  void _limpiarFormularioLiderConsolidacion() {
    _nombreLiderConsolidacionController.clear();
    _apellidoLiderConsolidacionController.clear();
    _usuarioLiderConsolidacionController.clear();
    _contrasenaLiderConsolidacionController.clear();
  }

  void _mostrarSnackBar(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje)),
    );
  }

  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Administración'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Tribus'),
            Tab(text: 'Líder de Consolidación'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTribusTab(),
          _buildLiderConsolidacionTab(),
        ],
      ),
    );
  }

  Widget _buildTribusTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!_mostrarFormularioTribu)
            ElevatedButton(
              onPressed: () => setState(() => _mostrarFormularioTribu = true),
              child: const Text('Crear Nueva Tribu'),
            ),
          if (_mostrarFormularioTribu) ...[
            _buildFormularioTribu(),
            const SizedBox(height: 20),
          ],
          const SizedBox(height: 20),
          _buildListaTribus(),
        ],
      ),
    );
  }

  Widget _buildLiderConsolidacionTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!_existeLiderConsolidacion && !_mostrarFormularioLiderConsolidacion)
            ElevatedButton(
              onPressed: () => setState(() => _mostrarFormularioLiderConsolidacion = true),
              child: const Text('Crear Líder de Consolidación'),
            ),
          if (_mostrarFormularioLiderConsolidacion) ...[
            _buildFormularioLiderConsolidacion(),
            const SizedBox(height: 20),
          ],
          const SizedBox(height: 20),
          _buildListaLideresConsolidacion(),
        ],
      ),
    );
  }

  Widget _buildFormularioTribu() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nueva Tribu',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nombreTribuController,
              decoration: const InputDecoration(labelText: 'Nombre de la Tribu'),
            ),
            TextField(
              controller: _nombreLiderController,
              decoration: const InputDecoration(labelText: 'Nombre del Líder'),
            ),
            TextField(
              controller: _apellidoLiderController,
              decoration: const InputDecoration(labelText: 'Apellido del Líder'),
            ),
            TextField(
              controller: _usuarioTribuController,
              decoration: const InputDecoration(labelText: 'Usuario'),
            ),
            TextField(
              controller: _contrasenaTribuController,
              decoration: const InputDecoration(labelText: 'Contraseña'),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() => _mostrarFormularioTribu = false);
                    _limpiarFormularioTribu();
                  },
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _crearTribu,
                  child: const Text('Guardar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormularioLiderConsolidacion() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nuevo Líder de Consolidación',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nombreLiderConsolidacionController,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            TextField(
              controller: _apellidoLiderConsolidacionController,
              decoration: const InputDecoration(labelText: 'Apellido'),
            ),
            TextField(
              controller: _usuarioLiderConsolidacionController,
              decoration: const InputDecoration(labelText: 'Usuario'),
            ),
            TextField(
              controller: _contrasenaLiderConsolidacionController,
              decoration: const InputDecoration(labelText: 'Contraseña'),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() => _mostrarFormularioLiderConsolidacion = false);
                    _limpiarFormularioLiderConsolidacion();
                  },
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _crearLiderConsolidacion,
                  child: const Text('Guardar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildListaTribus() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('tribus').orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final tribus = snapshot.data?.docs ?? [];

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: tribus.length,
          itemBuilder: (context, index) {
            final tribu = tribus[index];
            final data = tribu.data() as Map<String, dynamic>;

            return Card(
              margin: const EdgeInsets.only(bottom: 8.0),
              child: ListTile(
                title: Text(data['nombre'] ?? ''),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Líder: ${data['nombreLider']} ${data['apellidoLider']}'),
                    Text('Usuario: ${data['usuario']}'),
                  ],
                ),
                trailing: Wrap(
                  spacing: 8, // Espacio entre widgets
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _mostrarDialogoEditarTribu(tribu.id, data),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _mostrarDialogoConfirmarEliminarTribu(tribu.id),
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TribusScreen(
                              tribuId: tribu.id,
                              tribuNombre: data['nombre'] ?? '',
                            ),
                          ),
                        );
                      },
                    ),
                    ElevatedButton(
                      onPressed: () => _mostrarDialogoUnirTribus(tribu.id, data['nombre']),
                      child: const Text('Unir'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

   Future<void> _mostrarDialogoUnirTribus(String tribu1Id, String tribu1Nombre) async {
    String? tribu2Id;
    String? tribu2Nombre;

    final tribusSnapshot = await _firestore
        .collection('tribus')
        .where(FieldPath.documentId, isNotEqualTo: tribu1Id)
        .get();

    if (tribusSnapshot.docs.isEmpty) {
      _mostrarSnackBar('No hay otras tribus disponibles para unir');
      return;
    }

    final List<DropdownMenuItem<String>> tribuItems = tribusSnapshot.docs.map((doc) {
      final data = doc.data();
      return DropdownMenuItem(
        value: doc.id,
        child: Text(data['nombre']),
      );
    }).toList();

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Unir con tribu: $tribu1Nombre'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Selecciona la tribu con la que deseas unir:'),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    items: tribuItems,
                    onChanged: (value) {
                      setState(() {
                        tribu2Id = value;
                        tribu2Nombre = tribusSnapshot.docs
                            .firstWhere((doc) => doc.id == value)
                            .data()['nombre'];
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: 'Seleccionar tribu',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: tribu2Id == null
                      ? null
                      : () {
                          Navigator.pop(context);
                          _confirmarUnionTribus(tribu1Id, tribu2Id!, tribu1Nombre, tribu2Nombre!);
                        },
                  child: const Text('Siguiente'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _confirmarUnionTribus(
      String tribu1Id, String tribu2Id, String tribu1Nombre, String tribu2Nombre) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar unión'),
          content: Text(
              '¿Estás seguro que deseas unir las tribus "$tribu1Nombre" y "$tribu2Nombre"?\n\nEsta acción no se puede deshacer.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _unirTribus(tribu1Id, tribu2Id);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Unir tribus'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _unirTribus(String tribu1Id, String tribu2Id) async {
    try {
      final batch = _firestore.batch();
      
      // Obtener datos de ambas tribus
      final tribu1Doc = await _firestore.collection('tribus').doc(tribu1Id).get();
      final tribu2Doc = await _firestore.collection('tribus').doc(tribu2Id).get();
      
      if (!tribu1Doc.exists || !tribu2Doc.exists) {
        throw Exception('Una o ambas tribus no existen');
      }

      // Actualizar todas las colecciones relacionadas
      final colecciones = ['coordinadores', 'timoteos', 'registros'];
      
      for (var coleccion in colecciones) {
        final snapshot = await _firestore
            .collection(coleccion)
            .where('tribuId', isEqualTo: tribu2Id)
            .get();
        
        for (var doc in snapshot.docs) {
          batch.update(doc.reference, {'tribuId': tribu1Id});
        }
      }

      // Actualizar usuario de la tribu
      final usuarioTribu2Snapshot = await _firestore
          .collection('usuarios')
          .where('tribuId', isEqualTo: tribu2Doc.data()!['nombre'])
          .get();
      
      if (usuarioTribu2Snapshot.docs.isNotEmpty) {
        batch.delete(usuarioTribu2Snapshot.docs.first.reference);
      }

      // Eliminar la tribu2
      batch.delete(tribu2Doc.reference);

      // Ejecutar todas las operaciones
      await batch.commit();

      _mostrarSnackBar('Las tribus se han unido exitosamente');
    } catch (e) {
      _mostrarSnackBar('Error al unir las tribus: $e');
    }
  }



Widget _buildListaLideresConsolidacion() {
  return StreamBuilder<QuerySnapshot>(
    stream: _firestore.collection('lideresConsolidacion').snapshots(),
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Text('Error: ${snapshot.error}');
      }

      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }

      final lideres = snapshot.data?.docs ?? [];

      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: lideres.length,
        itemBuilder: (context, index) {
          final lider = lideres[index];
          final data = lider.data() as Map<String, dynamic>;

          return Card(
            margin: const EdgeInsets.only(bottom: 8.0),
            child: ListTile(
              title: Text('${data['nombre']} ${data['apellido']}'),
              subtitle: Text('Usuario: ${data['usuario']}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _mostrarDialogoEditarLiderConsolidacion(lider.id, data),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _mostrarDialogoConfirmarEliminarLiderConsolidacion(lider.id),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AdminPanel(), 
                        ),
                      );
                    },
                    child: Text('Ir a AdminPanel'),
                  ),

                ],
              ),
            ),
          );
        },
      );
    },
  );
}


  Future<void> _mostrarDialogoEditarTribu(String docId, Map<String, dynamic> datos) async {
    final nombreController = TextEditingController(text: datos['nombre']);
    final nombreLiderController = TextEditingController(text: datos['nombreLider']);
    final apellidoLiderController = TextEditingController(text: datos['apellidoLider']);
    final usuarioController = TextEditingController(text: datos['usuario']);
    final contrasenaController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Tribu'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nombreController,
                decoration: const InputDecoration(labelText: 'Nombre de la Tribu'),
              ),
              TextField(
                controller: nombreLiderController,
                decoration: const InputDecoration(labelText: 'Nombre del Líder'),
              ),
              TextField(
                controller: apellidoLiderController,
                decoration: const InputDecoration(labelText: 'Apellido del Líder'),
              ),
              TextField(
                controller: usuarioController,
                decoration: const InputDecoration(labelText: 'Usuario'),
              ),
              TextField(
                controller: contrasenaController,
                decoration: const InputDecoration(labelText: 'Nueva Contraseña (opcional)'),
                obscureText: true,
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
            onPressed: () {
              final datosActualizados = {
                'nombre': nombreController.text,
                'nombreLider': nombreLiderController.text,
                'apellidoLider': apellidoLiderController.text,
                'usuario': usuarioController.text,
                'nombreAntiguo': datos['nombre'],
                'contrasena': contrasenaController.text.isNotEmpty
                    ? contrasenaController.text
                    : datos['contrasena'],
              };
              Navigator.pop(context);
              _editarTribu(docId, datosActualizados);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _mostrarDialogoEditarLiderConsolidacion(String docId, Map<String, dynamic> datos) async {
    final nombreController = TextEditingController(text: datos['nombre']);
    final apellidoController = TextEditingController(text: datos['apellido']);
    final usuarioController = TextEditingController(text: datos['usuario']);
    final contrasenaController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Líder de Consolidación'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                decoration: const InputDecoration(labelText: 'Nueva Contraseña (opcional)'),
                obscureText: true,
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
            onPressed: () {
              final datosActualizados = {
                'nombre': nombreController.text,
                'apellido': apellidoController.text,
                'usuario': usuarioController.text,
                'contrasena': contrasenaController.text.isNotEmpty
                    ? contrasenaController.text
                    : datos['contrasena'],
              };
              Navigator.pop(context);
              _editarLiderConsolidacion(docId, datosActualizados);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _mostrarDialogoConfirmarEliminarTribu(String docId) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: const Text('¿Está seguro que desea eliminar esta tribu?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _firestore.collection('tribus').doc(docId).delete();
                _mostrarSnackBar('Tribu eliminada exitosamente');
              } catch (e) {
                _mostrarSnackBar('Error al eliminar la tribu: $e');
              }
            },
            child: const Text('Eliminar'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),
        ],
      ),
    );
  }

  Future<void> _mostrarDialogoConfirmarEliminarLiderConsolidacion(String docId) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: const Text('¿Está seguro que desea eliminar este líder de consolidación?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _firestore.collection('lideresConsolidacion').doc(docId).delete();
                
                // También eliminar de la colección de usuarios
                final usuarioSnapshot = await _firestore
                    .collection('usuarios')
                    .where('rol', isEqualTo: 'liderConsolidacion')
                    .get();
                
                if (usuarioSnapshot.docs.isNotEmpty) {
                  await usuarioSnapshot.docs.first.reference.delete();
                }
                
                setState(() => _existeLiderConsolidacion = false);
                _mostrarSnackBar('Líder de consolidación eliminado exitosamente');
              } catch (e) {
                _mostrarSnackBar('Error al eliminar el líder de consolidación: $e');
              }
            },
            child: const Text('Eliminar'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),
        ],
      ),
    );
  }
}