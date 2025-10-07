import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:formulario_app/models/registro.dart';
import 'package:formulario_app/screens/login_screen.dart';
import 'package:formulario_app/services/database_service.dart';
import 'package:formulario_app/services/firestore_service.dart';
import 'package:formulario_app/services/sync_service.dart';
import 'package:google_fonts/google_fonts.dart';

class FormularioPage extends StatefulWidget {
  const FormularioPage({super.key});

  @override
  State<FormularioPage> createState() => _FormularioPageState();
}

class _FormularioPageState extends State<FormularioPage> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseService _databaseService = DatabaseService();
  final FirestoreService _firestoreService = FirestoreService();
  final SyncService _syncService = SyncService();

  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _direccionController = TextEditingController();
  final _barrioController = TextEditingController();
  final _nombreParejaController = TextEditingController();
  final _descripcionOcupacionController = TextEditingController();
  final _referenciaInvitacionController = TextEditingController();
  final _observacionesController = TextEditingController();
  final _otroPeticionController = TextEditingController();
  final _otroConsolidadorController = TextEditingController();
  final _otroMotivoController = TextEditingController();
  final Map<String, GlobalKey> _fieldKeys = {
    'servicio': GlobalKey(),
    'tipoPersona': GlobalKey(),
    'sexo': GlobalKey(),
    'estadoCivil': GlobalKey(),
    'tieneHijos': GlobalKey(),
  };

  String? _servicioSeleccionado;
  String? _tipoPersona;
  String? _sexo;
  int? _edad;
  String? _estadoCivil;
  List<String> _ocupacionesSeleccionadas = [];
  bool? _tieneHijos;
  String? _motivoVisita;
  List<String> _peticionesSeleccionadas = [];
  String? _consolidadorSeleccionado;
  List<String> _consolidadores = [];
  bool _isLoading = false;
  String? _tieneHijosError;

  final List<String> _servicios = [
    "Viernes De Poder",
    "Servicio Prejuvenil",
    "Impacto Juvenil",
    "Servicio Familiar",
    "Servicio De Damas",
    "Servicio De Caballeros",
    "Servicio Especial",
  ];

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

  final List<String> _motivosVisita = [
    "Vive en otra ciudad",
    "Se congrega en otra iglesia evangélica",
    "Otro"
  ];

  final List<String> _peticionesOracion = [
    "Salud",
    "Finanzas",
    "Familia",
    "Estudios",
    "Restauración interior",
    "Otro",
  ];

  @override
  void initState() {
    super.initState();
    _cargarConsolidadores();
  }

  void _cargarConsolidadores() {
    _firestoreService.streamConsolidadores().listen((consolidadores) {
      setState(() {
        _consolidadores = consolidadores.map((c) => c['nombre'] ?? '').toList();
      });
    });
  }

  Widget _buildQuestionTitle(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0, top: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.teal.shade700,
            ),
          ),
          if (description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                description,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  InputDecoration _getInputDecoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: GoogleFonts.poppins(color: Colors.teal.shade600),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.teal.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.teal.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.teal.shade400, width: 2),
      ),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }


Future<void> _enviarFormulario() async {
  if (_formKey.currentState!.validate()) {
    if (_servicioSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Por favor, seleccione un servicio',
              style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
        ),
      );
      await _scrollToFirstError();
      return;
    }

    if (_tipoPersona == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Por favor, indique si es Nuevo o Visita',
              style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
        ),
      );
      await _scrollToFirstError();
      return;
    }

    if (_sexo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Por favor, seleccione su género',
              style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
        ),
      );
      await _scrollToFirstError();
      return;
    }

    if (_estadoCivil == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Por favor, seleccione su estado civil',
              style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
        ),
      );
      await _scrollToFirstError();
      return;
    }

    if (_tieneHijos == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Por favor, indique si tiene hijos',
              style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
        ),
      );
      await _scrollToFirstError();
      return;
    }

    setState(() => _isLoading = true);

    try {
      final registro = Registro(
        nombre: _nombreController.text,
        apellido: _apellidoController.text,
        telefono: _telefonoController.text,
        servicio: _servicioSeleccionado ?? '',
        tipo: _tipoPersona,
        fecha: DateTime.now(),
        motivo: _tipoPersona == 'Visita'
            ? (_motivoVisita == 'Otro'
                ? _otroMotivoController.text
                : _motivoVisita)
            : null,
        peticiones: _peticionesSeleccionadas.map((peticion) {
          if (peticion == 'Otro') {
            return _otroPeticionController.text;
          }
          return peticion;
        }).join(', '),
        consolidador: (_consolidadorSeleccionado == 'Otro'
            ? _otroConsolidadorController.text
            : _consolidadorSeleccionado),
        sexo: _sexo ?? '',
        edad: _edad ?? 0,
        direccion: _direccionController.text,
        barrio: _barrioController.text,
        estadoCivil: _estadoCivil ?? '',
        nombrePareja: _nombreParejaController.text,
        ocupaciones: _ocupacionesSeleccionadas.map((ocupacion) {
          if (ocupacion == 'Otro') {
            return _descripcionOcupacionController.text;
          }
          return ocupacion;
        }).toList(),
        descripcionOcupacion: _descripcionOcupacionController.text,
        tieneHijos: _tieneHijos ?? false,
        referenciaInvitacion: _referenciaInvitacionController.text,
        observaciones: _observacionesController.text,
      );

      var connectivityResult = await Connectivity().checkConnectivity();

      if (connectivityResult != ConnectivityResult.none) {
        await _firestoreService.insertRegistro(registro);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Registro enviado exitosamente a la nube',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        await _databaseService.insertRegistroPendiente(registro);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Sin conexión: Registro guardado localmente',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }

      _limpiarFormulario();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error al procesar el registro: $e',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  } else {
    await _scrollToFirstError();
  }
}

  void _limpiarFormulario() {
    _formKey.currentState!.reset();
    _nombreController.clear();
    _apellidoController.clear();
    _telefonoController.clear();
    _direccionController.clear();
    _barrioController.clear();
    _nombreParejaController.clear();
    _descripcionOcupacionController.clear();
    _referenciaInvitacionController.clear();
    _observacionesController.clear();
    _otroPeticionController.clear();
    _otroConsolidadorController.clear();
    _otroMotivoController.clear();

    setState(() {
      _servicioSeleccionado = null;
      _tipoPersona = null;
      _sexo = null;
      _edad = null;
      _estadoCivil = null;
      _ocupacionesSeleccionadas = [];
      _tieneHijos = null;
      _motivoVisita = null;
      _peticionesSeleccionadas = [];
      _consolidadorSeleccionado = null;
    });
  }

Future<void> _scrollToFirstError() async {
  await Future.delayed(const Duration(milliseconds: 100));
  
  if (_servicioSeleccionado == null && _fieldKeys['servicio']?.currentContext != null) {
    Scrollable.ensureVisible(
      _fieldKeys['servicio']!.currentContext!,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      alignment: 0.2,
    );
    return;
  }
  
  if (_tipoPersona == null && _fieldKeys['tipoPersona']?.currentContext != null) {
    Scrollable.ensureVisible(
      _fieldKeys['tipoPersona']!.currentContext!,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      alignment: 0.2,
    );
    return;
  }
  
  if (_tipoPersona == 'Nuevo' && _sexo == null && _fieldKeys['sexo']?.currentContext != null) {
    Scrollable.ensureVisible(
      _fieldKeys['sexo']!.currentContext!,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      alignment: 0.2,
    );
    return;
  }
  
  if (_tipoPersona == 'Nuevo' && _estadoCivil == null && _fieldKeys['estadoCivil']?.currentContext != null) {
    Scrollable.ensureVisible(
      _fieldKeys['estadoCivil']!.currentContext!,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      alignment: 0.2,
    );
    return;
  }
  
  if (_tipoPersona == 'Nuevo' && _tieneHijos == null && _fieldKeys['tieneHijos']?.currentContext != null) {
    Scrollable.ensureVisible(
      _fieldKeys['tieneHijos']!.currentContext!,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      alignment: 0.2,
    );
    return;
  }
}


  Widget _buildPersonalDataSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildQuestionTitle(
              'Información Personal',
              'Por favor, comparte sus datos básicos de contacto.',
            ),
            TextFormField(
              controller: _nombreController,
              decoration: _getInputDecoration('Nombre'),
              textCapitalization: TextCapitalization.sentences,
              validator: (value) =>
                  value!.isEmpty ? 'Por favor, ingrese su nombre' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _apellidoController,
              decoration: _getInputDecoration('Apellido'),
              textCapitalization: TextCapitalization.sentences,
              validator: (value) =>
                  value!.isEmpty ? 'Por favor, ingrese su apellido' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _telefonoController,
              decoration: _getInputDecoration('Teléfono'),
              keyboardType: TextInputType.phone,
              validator: (value) => value!.isEmpty
                  ? 'Por favor, ingresa su numero telefónico'
                  : null,
            ),
          ],
        ),
      ),
    );
  }


Widget _buildServiceSection() {
  return Card(
    key: _fieldKeys['servicio'],
    elevation: 4,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildQuestionTitle(
            'Servicio al que Asististe',
            'Selecciona el servicio al que has asistido hoy.',
          ),
          DropdownButtonFormField<String>(
            value: _servicioSeleccionado,
            decoration: _getInputDecoration('Selecciona un servicio'),
            items: _servicios
                .map((servicio) => DropdownMenuItem(
                      value: servicio,
                      child: Text(servicio, style: GoogleFonts.poppins()),
                    ))
                .toList(),
            onChanged: (value) =>
                setState(() => _servicioSeleccionado = value),
            validator: (value) =>
                value == null ? 'Por favor, selecciona un servicio' : null,
          ),
        ],
      ),
    ),
  );
}

Widget _buildPersonTypeSection() {
  return Card(
    key: _fieldKeys['tipoPersona'],
    elevation: 4,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildQuestionTitle(
            '¿Nuevo o Visita?',
            'Nuevo es aquel que nos visita por primera vez. Visita es aquella persona que se congrega en otra iglesia, solo está en la ciudad por un tiempo corto, entre otras. Es decir, que no se le puede hacer un proceso de consolidación.',
          ),
          RadioListTile<String>(
            title: Text('Nuevo', style: GoogleFonts.poppins()),
            value: 'Nuevo',
            groupValue: _tipoPersona,
            onChanged: (value) => setState(() => _tipoPersona = value),
            activeColor: Colors.teal.shade700,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          ),
          RadioListTile<String>(
            title: Text('Visita', style: GoogleFonts.poppins()),
            value: 'Visita',
            groupValue: _tipoPersona,
            onChanged: (value) => setState(() => _tipoPersona = value),
            activeColor: Colors.teal.shade700,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildNewPersonSection() {
    return Column(
      children: [
        _buildGenderSection(),
        const SizedBox(height: 24),
        _buildAgeSection(),
        const SizedBox(height: 24),
        _buildAddressSection(),
        const SizedBox(height: 24),
        _buildCivilStatusSection(),
        const SizedBox(height: 24),
        _buildOccupationSection(),
        const SizedBox(height: 24),
        _buildChildrenSection(),
        const SizedBox(height: 24),
        _buildReferenceSection(),
      ],
    );
  }


Widget _buildGenderSection() {
  return Card(
    key: _fieldKeys['sexo'],
    elevation: 4,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildQuestionTitle(
            'Género',
            'Por favor, seleccione su género',
          ),
          RadioListTile<String>(
            title: Text('Hombre', style: GoogleFonts.poppins()),
            value: 'Hombre',
            groupValue: _sexo,
            onChanged: (value) => setState(() => _sexo = value),
            activeColor: Colors.teal.shade700,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          ),
          RadioListTile<String>(
            title: Text('Mujer', style: GoogleFonts.poppins()),
            value: 'Mujer',
            groupValue: _sexo,
            onChanged: (value) => setState(() => _sexo = value),
            activeColor: Colors.teal.shade700,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildAgeSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildQuestionTitle(
              'Edad',
              'Indique su edad',
            ),
            TextFormField(
              decoration: _getInputDecoration('Edad'),
              keyboardType: TextInputType.number,
              onChanged: (value) => setState(() => _edad = int.tryParse(value)),
              validator: (value) =>
                  value!.isEmpty ? 'Por favor, ingrese su edad' : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildQuestionTitle(
              'Dirección',
              'Comparte su información de residencia',
            ),
            TextFormField(
              controller: _direccionController,
              decoration: _getInputDecoration('Dirección completa'),
              textCapitalization: TextCapitalization.sentences,
              validator: (value) =>
                  value!.isEmpty ? 'Por favor, ingrese su dirección' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _barrioController,
              decoration: _getInputDecoration('Barrio'),
              textCapitalization: TextCapitalization.sentences,
              validator: (value) =>
                  value!.isEmpty ? 'Por favor, ingrese su barrio' : null,
            ),
          ],
        ),
      ),
    );
  }


Widget _buildCivilStatusSection() {
  return Card(
    key: _fieldKeys['estadoCivil'],
    elevation: 4,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildQuestionTitle(
            'Estado Civil',
            'Indique su estado civil actual',
          ),
          DropdownButtonFormField<String>(
            value: _estadoCivil,
            decoration: _getInputDecoration('Selecciona su estado civil'),
            items: _estadosCiviles
                .map((estado) => DropdownMenuItem(
                      value: estado,
                      child: Text(estado, style: GoogleFonts.poppins()),
                    ))
                .toList(),
            onChanged: (value) {
              setState(() {
                _estadoCivil = value;
                _nombreParejaController.text =
                    (value == 'Casado(a)' || value == 'Unión Libre')
                        ? ''
                        : 'No Aplica';
              });
            },
            validator: (value) =>
                value == null ? 'Selecciona su estado civil' : null,
          ),
          if (_estadoCivil == 'Casado(a)' || _estadoCivil == 'Unión Libre')
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: TextFormField(
                controller: _nombreParejaController,
                decoration: _getInputDecoration('Nombre de su pareja'),
                textCapitalization: TextCapitalization.sentences,
                validator: (value) => value!.isEmpty
                    ? 'Por favor, ingrese el nombre de su pareja'
                    : null,
              ),
            ),
        ],
      ),
    ),
  );
}

  Widget _buildOccupationSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildQuestionTitle(
              'Ocupación',
              'Selecciona todas las ocupaciones que apliquen',
            ),
            ..._ocupaciones.map((ocupacion) => CheckboxListTile(
                  title: Text(ocupacion, style: GoogleFonts.poppins()),
                  value: _ocupacionesSeleccionadas.contains(ocupacion),
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _ocupacionesSeleccionadas.add(ocupacion);
                      } else {
                        _ocupacionesSeleccionadas.remove(ocupacion);
                      }
                    });
                  },
                  activeColor: Colors.teal.shade700,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                )),
            if (_ocupacionesSeleccionadas.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: TextFormField(
                  controller: _descripcionOcupacionController,
                  decoration: _getInputDecoration('Especifica su ocupación'),
                  textCapitalization: TextCapitalization.sentences,
                  validator: (value) => value!.isEmpty
                      ? 'Por favor, especifica su ocupación'
                      : null,
                ),
              ),
          ],
        ),
      ),
    );
  }


Widget _buildChildrenSection() {
  return Card(
    key: _fieldKeys['tieneHijos'],
    elevation: 4,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildQuestionTitle(
            'Hijos',
            '¿Tienes hijos?',
          ),
          RadioListTile<bool>(
            title: Text('Sí', style: GoogleFonts.poppins()),
            value: true,
            groupValue: _tieneHijos,
            onChanged: (value) => setState(() {
              _tieneHijos = value;
              _tieneHijosError = null;
            }),
            activeColor: Colors.teal.shade700,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          ),
          RadioListTile<bool>(
            title: Text('No', style: GoogleFonts.poppins()),
            value: false,
            groupValue: _tieneHijos,
            onChanged: (value) => setState(() {
              _tieneHijos = value;
              _tieneHijosError = null;
            }),
            activeColor: Colors.teal.shade700,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          ),
          if (_tieneHijosError != null)
            Padding(
              padding: const EdgeInsets.only(left: 8.0, top: 4.0),
              child: Text(
                _tieneHijosError!,
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
        ],
      ),
    ),
  );
}

// Función para validar antes de continuar
  bool _validateForm() {
    if (_tieneHijos == null) {
      setState(() {
        _tieneHijosError = 'Debes seleccionar una opción';
      });
      return false;
    }
    return true;
  }

  Widget _buildReferenceSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildQuestionTitle(
              'Referencia',
              '¿Quién te invitó a nuestra iglesia?',
            ),
            TextFormField(
              controller: _referenciaInvitacionController,
              decoration:
                  _getInputDecoration('Nombre y apellidos de quien lo Invita'),
              textCapitalization: TextCapitalization.sentences,
              validator: (value) =>
                  value!.isEmpty ? 'Por favor, indica quién te invitó' : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildObservationsSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildQuestionTitle(
              'Observaciones',
              'Comparte cualquier información adicional que consideres relevante',
            ),
            TextFormField(
              controller: _observacionesController,
              decoration: _getInputDecoration('Observaciones adicionales'),
              textCapitalization: TextCapitalization.sentences,
              maxLines: 3,
              validator: (value) => value!.isEmpty
                  ? 'Por favor, ingrese sus observaciones'
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisitSection() {
    return Column(
      children: [
        _buildVisitReasonSection(),
        const SizedBox(height: 24),
        _buildPrayerRequestSection(),
        const SizedBox(height: 24),
        _buildConsolidatorField(),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildVisitReasonSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildQuestionTitle(
              'Motivo de Visita',
              'Cuéntanos por qué nos visitas hoy',
            ),
            // Wrapped in Flexible to prevent overflow
            DropdownButtonFormField<String>(
              isExpanded: true, // Añadido para prevenir desbordamiento
              value: _motivoVisita,
              decoration: _getInputDecoration('Selecciona el motivo'),
              items: _motivosVisita
                  .map((motivo) => DropdownMenuItem(
                        value: motivo,
                        child: Text(
                          motivo,
                          style: GoogleFonts.poppins(),
                          overflow: TextOverflow.ellipsis, // Maneja texto largo
                        ),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => _motivoVisita = value),
              validator: (value) =>
                  value == null ? 'Por favor, selecciona un motivo' : null,
            ),
            if (_motivoVisita == 'Otro')
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: TextFormField(
                  controller: _otroMotivoController,
                  decoration:
                      _getInputDecoration('Especifica el motivo de su visita'),
                  textCapitalization: TextCapitalization.sentences,
                  validator: (value) =>
                      value!.isEmpty ? 'Por favor, especifica el motivo' : null,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrayerRequestSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildQuestionTitle(
              'Petición de Oración',
              '¿Por qué te gustaría que oremos?',
            ),
            ..._peticionesOracion.map((peticion) => CheckboxListTile(
                  title: Text(peticion, style: GoogleFonts.poppins()),
                  value: _peticionesSeleccionadas.contains(peticion),
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _peticionesSeleccionadas.add(peticion);
                      } else {
                        _peticionesSeleccionadas.remove(peticion);
                      }
                    });
                  },
                  activeColor: Colors.teal.shade700,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                )),
            if (_peticionesSeleccionadas.contains('Otro'))
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: TextFormField(
                  controller: _otroPeticionController,
                  decoration:
                      _getInputDecoration('Especifica su petición de oración'),
                  validator: (value) => value!.isEmpty
                      ? 'Por favor, especifica su petición'
                      : null,
                  textCapitalization: TextCapitalization.sentences,
                ),
              ),
            if (_peticionesSeleccionadas.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0, left: 8.0),
                child: Text(
                  'Por favor, seleccione al menos una petición',
                  style: GoogleFonts.poppins(
                    color: Colors.red,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildConsolidatorField() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildQuestionTitle(
              'Consolidador',
              'Por favor, selecciona o ingresa el nombre de tu consolidador',
            ),
            DropdownButtonFormField<String>(
              value: _consolidadorSeleccionado,
              decoration: _getInputDecoration('Selecciona tu consolidador'),
              items: _consolidadores
                  .map((consolidador) => DropdownMenuItem(
                        value: consolidador,
                        child: Text(consolidador, style: GoogleFonts.poppins()),
                      ))
                  .toList(),
              onChanged: (value) =>
                  setState(() => _consolidadorSeleccionado = value),
              validator: (value) => value == null
                  ? 'Por favor, selecciona un consolidador'
                  : null,
            ),
            if (_consolidadorSeleccionado == 'Otro')
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: TextFormField(
                  controller: _otroConsolidadorController,
                  decoration: _getInputDecoration(
                      'Especifica el nombre del consolidador'),
                  validator: (value) => value!.isEmpty
                      ? 'Por favor, ingresa el nombre del consolidador'
                      : null,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _enviarFormulario,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.teal.shade700,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.send_rounded),
                  const SizedBox(width: 8),
                  Text(
                    'Enviar Formulario',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // Helper method to create consistent section cards
  Widget _buildSectionCard({
    required String title,
    required String description,
    required List<Widget> children,
    IconData? icon,
  }) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.teal.shade50,
              Colors.white,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: Colors.teal.shade700, size: 24),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal.shade700,
                          ),
                        ),
                        Text(
                          description,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...children,
            ],
          ),
        ),
      ),
    );
  }

  // Update the existing sections to use the new helper method
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.teal.shade700,
        title: Row(
          children: [
            const Icon(
              Icons.article_rounded,
              color: Colors.white,
              size: 28,
            ),
            const SizedBox(width: 8),
            Text(
              'TOMA DE DATOS CONSOLIDACIÓN',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16.5, // Ajusta el tamaño de la fuente aquí
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.admin_panel_settings, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
            tooltip: 'Admin Login',
          ),
        ],
      ),
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.teal.shade50, Colors.white],
            ),
          ),
          child: Stack(
            children: [
              RefreshIndicator(
                onRefresh: () async {
                  setState(() {
                    _cargarConsolidadores();
                  });
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPersonalDataSection(),
                        const SizedBox(height: 16),
                        _buildServiceSection(),
                        const SizedBox(height: 16),
                        _buildPersonTypeSection(),
                        if (_tipoPersona == 'Nuevo') ...[
                          const SizedBox(height: 16),
                          _buildNewPersonSection(),
                          const SizedBox(height: 24),
                          _buildPrayerRequestSection(),
                          const SizedBox(height: 24),
                          _buildObservationsSection(),
                          const SizedBox(height: 24),
                          _buildConsolidatorField(),
                          // Mueve Observaciones aquí
                        ] else if (_tipoPersona == 'Visita') ...[
                          const SizedBox(height: 16),
                          _buildVisitSection(),
                        ],
                        const SizedBox(height: 32),
                        _buildSubmitButton(),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
              if (_isLoading)
                Container(
                  color: Colors.black.withOpacity(0.3),
                  child: Center(
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.teal.shade700,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Procesando...',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: Colors.teal.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
