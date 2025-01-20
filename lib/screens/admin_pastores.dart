import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'TribusScreen.dart';
import 'admin_screen.dart';
import 'package:fl_chart/fl_chart.dart';

const Color kPrimaryColor = Color(0xFF1B998B); // Turquesa
const Color kSecondaryColor = Color(0xFFFF4B3E); // Naranja/rojo
const Color kBackgroundColor =
    Color(0xFFF5F7FA); // Gris muy claro para el fondo
const Color kTextColor = Color(0xFF2C3E50); // Azul oscuro para texto

class AdminPastores extends StatefulWidget {
  const AdminPastores({Key? key}) : super(key: key);
  // Constantes de colores basadas en el logo

  @override
  _AdminPastoresState createState() => _AdminPastoresState();
}

class _AdminPastoresState extends State<AdminPastores>
    with SingleTickerProviderStateMixin {
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
      // Primero crear el documento en la colección tribus
      DocumentReference tribuRef = await _firestore.collection('tribus').add({
        'nombre': _nombreTribuController.text,
        'nombreLider': _nombreLiderController.text,
        'apellidoLider': _apellidoLiderController.text,
        'usuario': _usuarioTribuController.text,
        'contrasena': _contrasenaTribuController
            .text, // Contraseña sin cifrar para referencia
        'rol': 'tribu',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Luego crear el usuario en la colección usuarios con referencia al ID de la tribu
      await _firestore.collection('usuarios').add({
        'usuario': _usuarioTribuController.text,
        'contrasena': _contrasenaTribuController
            .text, // Guardar sin cifrar para mantener consistencia
        'rol': 'tribu',
        'tribuId': tribuRef.id, // Guardar el ID real del documento de la tribu
        'nombre': _nombreTribuController.text, // Guardar el nombre de la tribu
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
      print('Iniciando edición de tribu con ID: $docId'); // Log para depuración

      // Actualizar documento en la colección tribus
      await _firestore.collection('tribus').doc(docId).update({
        'nombre': datos['nombre'],
        'nombreLider': datos['nombreLider'],
        'apellidoLider': datos['apellidoLider'],
        'usuario': datos['usuario'].trim(),
        'contrasena': datos['contrasena'].trim(),
      });

      print(
          'Tribu actualizada, buscando usuario correspondiente'); // Log para depuración

      // Actualizar en la colección de usuarios
      final usuarioSnapshot = await _firestore
          .collection('usuarios')
          .where('tribuId',
              isEqualTo: docId) // Ahora buscamos por el ID real de la tribu
          .get();

      if (usuarioSnapshot.docs.isNotEmpty) {
        print('Usuario encontrado, actualizando datos'); // Log para depuración

        await usuarioSnapshot.docs.first.reference.update({
          'usuario': datos['usuario'].trim(),
          'contrasena': datos['contrasena']
              .trim(), // Guardamos sin cifrar para mantener consistencia
          'nombre':
              datos['nombre'], // Actualizamos también el nombre de la tribu
        });

        print('Usuario actualizado exitosamente'); // Log para depuración
      } else {
        print(
            'No se encontró usuario asociado a la tribu'); // Log para depuración
      }

      _mostrarSnackBar('Tribu actualizada exitosamente');
    } catch (e) {
      print('Error al actualizar tribu: $e'); // Log para depuración
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
        'contrasena':
            _contrasenaLiderConsolidacionController.text, // Sin cifrar
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Crear usuario en la colección de usuarios
      await _firestore.collection('usuarios').add({
        'usuario': _usuarioLiderConsolidacionController.text,
        'contrasena':
            _contrasenaLiderConsolidacionController.text, // Sin cifrar
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

  Future<void> _editarLiderConsolidacion(
      String docId, Map<String, dynamic> datos) async {
    try {
      // Actualizar el documento en la colección 'lideresConsolidacion'
      await _firestore.collection('lideresConsolidacion').doc(docId).update({
        'nombre': datos['nombre'],
        'apellido': datos['apellido'],
        'usuario': datos['usuario'],
        'contrasena': datos['contrasena'], // Sin cifrar
      });

      // Buscar y actualizar el usuario en la colección 'usuarios'
      final usuarioSnapshot = await _firestore
          .collection('usuarios')
          .where('rol', isEqualTo: 'liderConsolidacion')
          .where('usuario',
              isEqualTo:
                  datos['usuario']) // Asegurarse de filtrar por usuario también
          .get();

      if (usuarioSnapshot.docs.isNotEmpty) {
        await usuarioSnapshot.docs.first.reference.update({
          'usuario': datos['usuario'],
          'contrasena': datos['contrasena'], // Sin cifrar
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
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: kPrimaryColor,
        title: Row(
          children: [
            Image.asset(
              'assets/Cocep_.png', // Asegúrate de tener el logo en assets
              height: 40,
            ),
            const SizedBox(width: 12),
            const Text(
              'Panel de Administración',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: [
            Tab(
              icon: Icon(Icons.groups),
              text: 'Tribus',
            ),
            Tab(
              icon: Icon(Icons.person_outline),
              text: 'Líder de Consolidación',
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
              kPrimaryColor.withOpacity(0.1),
              kBackgroundColor,
            ],
          ),
        ),
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildTribusTab(),
            _buildLiderConsolidacionTab(),
          ],
        ),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: () =>
                      setState(() => _mostrarFormularioTribu = true),
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text('Crear Nueva Tribu'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B998B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _mostrarDialogoSeleccionTribus,
                  icon: const Icon(Icons.merge_type, color: Colors.white),
                  label: const Text('Unir Tribus'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B998B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
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

  Future<void> _mostrarDialogoSeleccionTribus() async {
    String? tribu1Id;
    String? tribu2Id;
    String? nuevoNombre;
    String? nuevoNombreLider;
    String? nuevoApellidoLider;
    String? nuevoUsuario;
    String? nuevaContrasena;
    bool mantenerDatos = true;

    final tribusSnapshot = await _firestore.collection('tribus').get();

    if (tribusSnapshot.docs.length < 2) {
      _mostrarSnackBar('Se necesitan al menos 2 tribus para realizar la unión');
      return;
    }

    final List<DropdownMenuItem<String>> tribuItems =
        tribusSnapshot.docs.map((doc) {
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
              title: Row(
                children: const [
                  Icon(Icons.merge_type, color: Color(0xFF1B998B)),
                  SizedBox(width: 10),
                  Text('Unir Tribus'),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Selecciona las tribus que deseas unir:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      items: tribuItems,
                      onChanged: (value) {
                        setState(() {
                          tribu1Id = value;
                        });
                      },
                      decoration: InputDecoration(
                        labelText: 'Primera tribu',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      items: tribuItems
                          .where((item) => item.value != tribu1Id)
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          tribu2Id = value;
                        });
                      },
                      decoration: InputDecoration(
                        labelText: 'Segunda tribu',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    CheckboxListTile(
                      value: mantenerDatos,
                      onChanged: (value) {
                        setState(() {
                          mantenerDatos = value ?? true;
                        });
                      },
                      title: const Text('Mantener datos de la primera tribu'),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    if (!mantenerDatos) ...[
                      const SizedBox(height: 16),
                      TextField(
                        onChanged: (value) => nuevoNombre = value,
                        decoration: InputDecoration(
                          labelText: 'Nuevo nombre de tribu',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        onChanged: (value) => nuevoNombreLider = value,
                        decoration: InputDecoration(
                          labelText: 'Nuevo nombre del líder',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        onChanged: (value) => nuevoApellidoLider = value,
                        decoration: InputDecoration(
                          labelText: 'Nuevo apellido del líder',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        onChanged: (value) => nuevoUsuario = value,
                        decoration: InputDecoration(
                          labelText: 'Nuevo usuario',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        onChanged: (value) => nuevaContrasena = value,
                        decoration: InputDecoration(
                          labelText: 'Nueva contraseña',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        obscureText: true,
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: tribu1Id == null || tribu2Id == null
                      ? null
                      : () {
                          Navigator.pop(context);
                          _unirTribusConNuevosDatos(
                            tribu1Id!,
                            tribu2Id!,
                            mantenerDatos,
                            nuevoNombre,
                            nuevoNombreLider,
                            nuevoApellidoLider,
                            nuevoUsuario,
                            nuevaContrasena,
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B998B),
                  ),
                  child: const Text('Unir'),
                ),
              ],
            );
          },
        );
      },
    );
  }

 Future<void> _unirTribusConNuevosDatos(
  String tribu1Id,
  String tribu2Id,
  bool mantenerDatos,
  String? nuevoNombre,
  String? nuevoNombreLider,
  String? nuevoApellidoLider,
  String? nuevoUsuario,
  String? nuevaContrasena,
) async {
  try {
    // Obtener datos de ambas tribus
    final tribu1Doc = await _firestore.collection('tribus').doc(tribu1Id).get();
    final tribu2Doc = await _firestore.collection('tribus').doc(tribu2Id).get();

    if (!tribu1Doc.exists || !tribu2Doc.exists) {
      throw Exception('Una o ambas tribus no existen');
    }

    final tribu1Data = tribu1Doc.data()!;
    final tribu2Data = tribu2Doc.data()!;

    // Obtener el nombre original de la tribu2 para el historial
    final nombreTribu2Original = tribu2Data['nombre'];

    // Si no se mantienen los datos, actualizar la tribu1 con los nuevos datos
    if (!mantenerDatos) {
      await _firestore.collection('tribus').doc(tribu1Id).update({
        'nombre': nuevoNombre ?? tribu1Data['nombre'],
        'nombreLider': nuevoNombreLider ?? tribu1Data['nombreLider'],
        'apellidoLider': nuevoApellidoLider ?? tribu1Data['apellidoLider'],
        'usuario': nuevoUsuario ?? tribu1Data['usuario'],
        'contrasena': nuevaContrasena ?? tribu1Data['contrasena'],
      });

      // Actualizar el usuario correspondiente
      final usuarioTribu1Snapshot = await _firestore
          .collection('usuarios')
          .where('tribuId', isEqualTo: tribu1Id)
          .get();

      if (usuarioTribu1Snapshot.docs.isNotEmpty) {
        await _firestore.collection('usuarios').doc(usuarioTribu1Snapshot.docs.first.id).update({
          'usuario': nuevoUsuario ?? tribu1Data['usuario'],
          'contrasena': nuevaContrasena ?? tribu1Data['contrasena'],
          'nombre': nuevoNombre ?? tribu1Data['nombre'],
        });
      }
    }

    // Obtener todos los registros de la tribu2
    final registrosTribu2 = await _firestore
        .collection('registros')
        .where('tribuAsignada', isEqualTo: tribu2Id)
        .get();

    // Transferir registros uno por uno para asegurar la transferencia
    for (var registro in registrosTribu2.docs) {
      final datosRegistro = Map<String, dynamic>.from(registro.data());
      
      // Actualizar los campos necesarios
      datosRegistro['tribuId'] = tribu1Id;
      datosRegistro['tribuAsignada'] = tribu1Id; // Actualizar el campo tribuAsignada
      datosRegistro['tribuOriginal'] = nombreTribu2Original;
      datosRegistro['fechaUnionTribus'] = FieldValue.serverTimestamp();
      
      // Mantener la fecha original de asignación
      if (datosRegistro.containsKey('fechaAsignacionTribu')) {
        datosRegistro['fechaAsignacionTribu'] = registro.data()['fechaAsignacionTribu'];
      }
      
      // Crear nuevo registro en la tribu1
      await _firestore.collection('registros').add(datosRegistro);
    }

    // Transferir coordinadores y timoteos
    final colecciones = ['coordinadores', 'timoteos'];

    for (var coleccion in colecciones) {
      final snapshot = await _firestore
          .collection(coleccion)
          .where('tribuId', isEqualTo: tribu2Id)
          .get();

      // Transferir documentos uno por uno
      for (var doc in snapshot.docs) {
        final datosDoc = Map<String, dynamic>.from(doc.data());
        
        datosDoc['tribuId'] = tribu1Id;
        datosDoc['tribuAsignada'] = tribu1Id; // Actualizar el campo tribuAsignada si existe
        datosDoc['tribuOriginal'] = nombreTribu2Original;
        datosDoc['fechaUnionTribus'] = FieldValue.serverTimestamp();
        
        // Crear nuevo documento
        await _firestore.collection(coleccion).add(datosDoc);
      }
    }

    // Crear historial de unión
    await _firestore.collection('historialUnionTribus').add({
      'tribuDestinoId': tribu1Id,
      'tribuDestinoNombre': mantenerDatos ? tribu1Data['nombre'] : (nuevoNombre ?? tribu1Data['nombre']),
      'tribuOrigenId': tribu2Id,
      'tribuOrigenNombre': nombreTribu2Original,
      'fechaUnion': FieldValue.serverTimestamp(),
      'mantuvoDatos': mantenerDatos,
      'cantidadRegistrosTransferidos': registrosTribu2.docs.length,
    });

    // Una vez que todos los datos se han transferido, eliminar los datos originales
    // Eliminar registros de la tribu2
    for (var registro in registrosTribu2.docs) {
      await registro.reference.delete();
    }

    // Eliminar coordinadores y timoteos de la tribu2
    for (var coleccion in colecciones) {
      final snapshot = await _firestore
          .collection(coleccion)
          .where('tribuId', isEqualTo: tribu2Id)
          .get();
      
      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
    }

    // Eliminar usuario de la tribu2
    final usuarioTribu2Snapshot = await _firestore
        .collection('usuarios')
        .where('tribuId', isEqualTo: tribu2Id)
        .get();

    if (usuarioTribu2Snapshot.docs.isNotEmpty) {
      await usuarioTribu2Snapshot.docs.first.reference.delete();
    }

    // Finalmente, eliminar la tribu2
    await tribu2Doc.reference.delete();

    _mostrarSnackBar('Las tribus se han unido exitosamente');
  } catch (e) {
    print('Error detallado: $e');
    _mostrarSnackBar('Error al unir las tribus: $e');
  }
}

  Widget _buildLiderConsolidacionTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!_existeLiderConsolidacion &&
              !_mostrarFormularioLiderConsolidacion)
            ElevatedButton(
              onPressed: () =>
                  setState(() => _mostrarFormularioLiderConsolidacion = true),
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
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Color(0xFFF5F5F5)],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.groups, color: Color(0xFF1B998B), size: 28),
                SizedBox(width: 12),
                Text(
                  'Nueva Tribu',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildInputField(
              controller: _nombreTribuController,
              label: 'Nombre de la Tribu',
              icon: Icons.church,
            ),
            const SizedBox(height: 16),
            _buildInputField(
              controller: _nombreLiderController,
              label: 'Nombre del Líder',
              icon: Icons.person,
            ),
            const SizedBox(height: 16),
            _buildInputField(
              controller: _apellidoLiderController,
              label: 'Apellido del Líder',
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 16),
            _buildInputField(
              controller: _usuarioTribuController,
              label: 'Usuario',
              icon: Icons.account_circle,
            ),
            const SizedBox(height: 16),
            _buildInputField(
              controller: _contrasenaTribuController,
              label: 'Contraseña',
              icon: Icons.lock_outline,
              isPassword: true,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () {
                    setState(() => _mostrarFormularioTribu = false);
                    _limpiarFormularioTribu();
                  },
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Cancelar'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[700],
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _crearTribu,
                  icon: const Icon(Icons.save),
                  label: const Text('Guardar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B998B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF1B998B)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF1B998B)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF1B998B), width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildFormularioLiderConsolidacion() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Color(0xFFF5F5F5)],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.person_add, color: Color(0xFF1B998B), size: 28),
                SizedBox(width: 12),
                Text(
                  'Nuevo Líder de Consolidación',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildInputField(
              controller: _nombreLiderConsolidacionController,
              label: 'Nombre',
              icon: Icons.person,
            ),
            const SizedBox(height: 16),
            _buildInputField(
              controller: _apellidoLiderConsolidacionController,
              label: 'Apellido',
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 16),
            _buildInputField(
              controller: _usuarioLiderConsolidacionController,
              label: 'Usuario',
              icon: Icons.account_circle,
            ),
            const SizedBox(height: 16),
            _buildInputField(
              controller: _contrasenaLiderConsolidacionController,
              label: 'Contraseña',
              icon: Icons.lock_outline,
              isPassword: true,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () {
                    setState(
                        () => _mostrarFormularioLiderConsolidacion = false);
                    _limpiarFormularioLiderConsolidacion();
                  },
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Cancelar'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[700],
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _crearLiderConsolidacion,
                  icon: const Icon(Icons.save),
                  label: const Text('Guardar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B998B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
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
    stream: _firestore
        .collection('tribus')
        .orderBy('createdAt', descending: true)
        .snapshots(),
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return _buildErrorWidget('Error: ${snapshot.error}');
      }

      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1B998B)),
          ),
        );
      }

      final tribus = snapshot.data?.docs ?? [];

      if (tribus.isEmpty) {
        return _buildEmptyState();
      }

      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: tribus.length,
        itemBuilder: (context, index) {
          final tribu = tribus[index];
          final data = tribu.data() as Map<String, dynamic>;

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ExpansionTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFF1B998B),
                child: Icon(Icons.groups, color: Colors.white),
              ),
              title: Text(
                data['nombre'] ?? '',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Color(0xFF2C3E50),
                ),
              ),
              subtitle: Text(
                'Líder: ${data['nombreLider']} ${data['apellidoLider']}',
                style: TextStyle(color: Colors.grey[600]),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow('Usuario:', data['usuario']),
                      _buildInfoRow('Contraseña:', data['contrasena']),
                      const SizedBox(height: 16),
                      _buildEstadisticasTribu(tribu.id),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Color(0xFF1B998B)),
                            onPressed: () => _mostrarDialogoEditarTribu(tribu.id, data),
                            tooltip: 'Editar',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _mostrarDialogoConfirmarEliminarTribu(tribu.id),
                            tooltip: 'Eliminar',
                          ),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.visibility),
                            label: const Text('Ver Detalles'),
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
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1B998B),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
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
  );
}

Widget _buildEstadisticasTribu(String tribuId) {
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
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('No hay registros asignados a esta tribu.'),
          ),
        );
      }

      final registros = snapshot.data!.docs;
      // Modificamos la estructura para organizar por año y luego por mes
      final Map<int, Map<String, int>> registrosPorAnio = {};

      for (var registro in registros) {
        final fecha = (registro['fechaAsignacionTribu'] as Timestamp).toDate();
        final ano = fecha.year;
        final mesNombre = _getMesNombre(fecha.month);
        
        // Inicializar el año si no existe
        if (!registrosPorAnio.containsKey(ano)) {
          registrosPorAnio[ano] = {};
        }
        
        // Inicializar el mes si no existe
        if (!registrosPorAnio[ano]!.containsKey(mesNombre)) {
          registrosPorAnio[ano]![mesNombre] = 0;
        }
        
        registrosPorAnio[ano]![mesNombre] = registrosPorAnio[ano]![mesNombre]! + 1;
      }

      // Ordenar los años de más reciente a más antiguo
      final anosOrdenados = registrosPorAnio.keys.toList()..sort((a, b) => b.compareTo(a));

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cantidad de Registros Asignados',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 16),
          ...anosOrdenados.map((ano) {
            final registrosAnio = registrosPorAnio[ano]!;
            final totalAnual = registrosAnio.values.reduce((a, b) => a + b);
            
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ExpansionTile(
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Año $ano',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    Text(
                      'Total: $totalAnual',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B998B),
                      ),
                    ),
                  ],
                ),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.grey[50],
                    child: Column(
                      children: [
                        ...registrosAnio.entries.map((entry) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                entry.key,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF2C3E50),
                                ),
                              ),
                              Text(
                                '${entry.value} registros',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF1B998B),
                                ),
                              ),
                            ],
                          ),
                        )).toList(),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      );
    },
  );
}

String _getMesNombre(int mes) {
  switch (mes) {
    case 1: return 'Enero';
    case 2: return 'Febrero';
    case 3: return 'Marzo';
    case 4: return 'Abril';
    case 5: return 'Mayo';
    case 6: return 'Junio';
    case 7: return 'Julio';
    case 8: return 'Agosto';
    case 9: return 'Septiembre';
    case 10: return 'Octubre';
    case 11: return 'Noviembre';
    case 12: return 'Diciembre';
    default: return '';
  }
}

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(
            Icons.groups_outlined,
            size: 64,
            color: Color(0xFF1B998B),
          ),
          SizedBox(height: 16),
          Text(
            'No hay tribus creadas',
            style: TextStyle(
              fontSize: 18,
              color: Color(0xFF2C3E50),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            error,
            style: const TextStyle(
              fontSize: 18,
              color: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _mostrarDialogoUnirTribus(
      String tribu1Id, String tribu1Nombre) async {
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

    final List<DropdownMenuItem<String>> tribuItems =
        tribusSnapshot.docs.map((doc) {
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
                          _confirmarUnionTribus(
                              tribu1Id, tribu2Id!, tribu1Nombre, tribu2Nombre!);
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

  Future<void> _confirmarUnionTribus(String tribu1Id, String tribu2Id,
      String tribu1Nombre, String tribu2Nombre) async {
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
      final tribu1Doc =
          await _firestore.collection('tribus').doc(tribu1Id).get();
      final tribu2Doc =
          await _firestore.collection('tribus').doc(tribu2Id).get();

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
          return _buildErrorWidget('Error: ${snapshot.error}');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1B998B)),
            ),
          );
        }

        final lideres = snapshot.data?.docs ?? [];

        if (lideres.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(
                  Icons.groups_outlined,
                  size: 64,
                  color: Color(0xFF1B998B),
                ),
                SizedBox(height: 16),
                Text(
                  'No hay líderes de consolidación registrados',
                  style: TextStyle(
                    fontSize: 18,
                    color: Color(0xFF2C3E50),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: lideres.length,
          itemBuilder: (context, index) {
            final lider = lideres[index];
            final data = lider.data() as Map<String, dynamic>;

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ExpansionTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFF1B998B),
                  child: Icon(Icons.person, color: Colors.white),
                ),
                title: Text(
                  '${data['nombre']} ${data['apellido']}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                subtitle: Text(
                  'Usuario: ${data['usuario']}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow('Usuario:', data['usuario']),
                        _buildInfoRow('Contraseña:', data['contrasena']),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit,
                                  color: Color(0xFF1B998B)),
                              onPressed: () =>
                                  _mostrarDialogoEditarLiderConsolidacion(
                                      lider.id, data),
                              tooltip: 'Editar',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () =>
                                  _mostrarDialogoConfirmarEliminarLiderConsolidacion(
                                      lider.id),
                              tooltip: 'Eliminar',
                            ),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.visibility),
                              label: const Text('Ver Detalles'),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AdminPanel(),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1B998B),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
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
    );
  }

  Future<void> _mostrarDialogoEditarTribu(
      String docId, Map<String, dynamic> datos) async {
    final nombreController = TextEditingController(text: datos['nombre']);
    final nombreLiderController =
        TextEditingController(text: datos['nombreLider']);
    final apellidoLiderController =
        TextEditingController(text: datos['apellidoLider']);
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
                decoration:
                    const InputDecoration(labelText: 'Nombre de la Tribu'),
              ),
              TextField(
                controller: nombreLiderController,
                decoration:
                    const InputDecoration(labelText: 'Nombre del Líder'),
              ),
              TextField(
                controller: apellidoLiderController,
                decoration:
                    const InputDecoration(labelText: 'Apellido del Líder'),
              ),
              TextField(
                controller: usuarioController,
                decoration: const InputDecoration(labelText: 'Usuario'),
              ),
              TextField(
                controller: contrasenaController,
                decoration: const InputDecoration(
                    labelText: 'Nueva Contraseña (opcional)'),
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

  Future<void> _mostrarDialogoEditarLiderConsolidacion(
      String docId, Map<String, dynamic> datos) async {
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
                decoration: const InputDecoration(
                    labelText: 'Nueva Contraseña (opcional)'),
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

  Future<void> _mostrarDialogoConfirmarEliminarLiderConsolidacion(
      String docId) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: const Text(
            '¿Está seguro que desea eliminar este líder de consolidación?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _firestore
                    .collection('lideresConsolidacion')
                    .doc(docId)
                    .delete();

                // También eliminar de la colección de usuarios
                final usuarioSnapshot = await _firestore
                    .collection('usuarios')
                    .where('rol', isEqualTo: 'liderConsolidacion')
                    .get();

                if (usuarioSnapshot.docs.isNotEmpty) {
                  await usuarioSnapshot.docs.first.reference.delete();
                }

                setState(() => _existeLiderConsolidacion = false);
                _mostrarSnackBar(
                    'Líder de consolidación eliminado exitosamente');
              } catch (e) {
                _mostrarSnackBar(
                    'Error al eliminar el líder de consolidación: $e');
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