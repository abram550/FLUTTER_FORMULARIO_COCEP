import 'package:flutter/material.dart';
import 'package:formulario_app/models/registro.dart';
import 'package:formulario_app/services/firestore_service.dart';

class EditRegistroScreen extends StatefulWidget {
  final Registro registro;

  const EditRegistroScreen({super.key, required this.registro});

  @override
  _EditRegistroScreenState createState() => _EditRegistroScreenState();
}

class _EditRegistroScreenState extends State<EditRegistroScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirestoreService _firestoreService = FirestoreService();

  // Controladores
  late TextEditingController _nombreController;
  late TextEditingController _apellidoController;
  late TextEditingController _telefonoController;
  late TextEditingController _servicioController;
  late TextEditingController _direccionController;
  late TextEditingController _barrioController;
  late TextEditingController _nombreParejaController;
  late TextEditingController _descripcionOcupacionController;
  late TextEditingController _referenciaInvitacionController;
  late TextEditingController _observacionesController;
  late TextEditingController _peticionesController;
  late TextEditingController _consolidadorController;

  String _sexo = '';
  int _edad = 0;
  String _estadoCivil = '';
  List<String> _ocupacionesSeleccionadas = [];
  bool _tieneHijos = false;

  final List<String> _estadosCiviles = [
    'Casado(a)',
    'Soltero(a)',
    'Unión Libre',
    'Separado(a)',
    'Viudo(a)',
  ];

  final List<String> _ocupaciones = [
    'Estudiante',
    'Profesional',
    'Trabaja',
    'Ama de Casa',
    'Otro',
  ];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _nombreController = TextEditingController(text: widget.registro.nombre);
    _apellidoController = TextEditingController(text: widget.registro.apellido);
    _telefonoController = TextEditingController(text: widget.registro.telefono);
    _servicioController = TextEditingController(text: widget.registro.servicio);
    _direccionController = TextEditingController(text: widget.registro.direccion);
    _barrioController = TextEditingController(text: widget.registro.barrio);
    _nombreParejaController = TextEditingController(text: widget.registro.nombrePareja ?? '');
    _descripcionOcupacionController = TextEditingController(text: widget.registro.descripcionOcupacion);
    _referenciaInvitacionController = TextEditingController(text: widget.registro.referenciaInvitacion);
    _observacionesController = TextEditingController(text: widget.registro.observaciones ?? '');
    _peticionesController = TextEditingController(text: widget.registro.peticiones ?? '');
    _consolidadorController = TextEditingController(text: widget.registro.consolidador ?? '');

    _sexo = widget.registro.sexo;
    _edad = widget.registro.edad;
    _estadoCivil = widget.registro.estadoCivil;
    _ocupacionesSeleccionadas = List<String>.from(widget.registro.ocupaciones);
    _tieneHijos = widget.registro.tieneHijos;
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _telefonoController.dispose();
    _servicioController.dispose();
    _direccionController.dispose();
    _barrioController.dispose();
    _nombreParejaController.dispose();
    _descripcionOcupacionController.dispose();
    _referenciaInvitacionController.dispose();
    _observacionesController.dispose();
    _peticionesController.dispose();
    _consolidadorController.dispose();
    super.dispose();
  }

  Future<void> _guardarCambios() async {
    if (_formKey.currentState!.validate()) {
      try {
        final registroActualizado = Registro(
          id: widget.registro.id,
          nombre: _nombreController.text,
          apellido: _apellidoController.text,
          telefono: _telefonoController.text,
          servicio: _servicioController.text,
          tipo: widget.registro.tipo,
          fecha: widget.registro.fecha,
          sexo: _sexo,
          edad: _edad,
          direccion: _direccionController.text,
          barrio: _barrioController.text,
          estadoCivil: _estadoCivil,
          nombrePareja: _nombreParejaController.text,
          ocupaciones: _ocupacionesSeleccionadas,
          descripcionOcupacion: _descripcionOcupacionController.text,
          tieneHijos: _tieneHijos,
          referenciaInvitacion: _referenciaInvitacionController.text,
          observaciones: _observacionesController.text,
          peticiones: _peticionesController.text,
          consolidador: _consolidadorController.text,
        );

        await _firestoreService.actualizarRegistro(registroActualizado.id!, registroActualizado);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registro actualizado con éxito')),
        );

        Navigator.of(context).pop();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar: $e')),
        );
      }
    }
  }

  Widget _buildRadioGroup(String title, List<String> options, String value, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        ...options.map((option) => RadioListTile<String>(
              title: Text(option),
              value: option,
              groupValue: value,
              onChanged: onChanged,
            )),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Registro'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (value) => value!.isEmpty ? 'Campo requerido' : null,
              ),
              // Resto de campos del formulario...
              ElevatedButton(
                onPressed: _guardarCambios,
                child: const Text('Guardar Cambios'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
