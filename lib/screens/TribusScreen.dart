import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:formulario_app/utils/excel_exporter.dart';
import 'package:formulario_app/utils/theme_constants.dart';
import 'package:intl/intl.dart';
import 'TimoteosScreen.dart';
import 'CoordinadorScreen.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

class TribusScreen extends StatefulWidget {
  final String tribuId;
  final String tribuNombre;

  const TribusScreen({
    Key? key,
    required this.tribuId,
    required this.tribuNombre,
  }) : super(key: key);

  @override
  State<TribusScreen> createState() => _TribusScreenState();
}

class _TribusScreenState extends State<TribusScreen>
    with SingleTickerProviderStateMixin {
  // Variables para el manejo de sesión
  Timer? _inactivityTimer;
  static const Duration _inactivityDuration = Duration(minutes: 15);

  // Controller para las pestañas
  late TabController _tabController;

  // Variables estáticas existentes
  static final List<Map<String, dynamic>> _tabOptions = [
    {'title': 'Timoteos', 'icon': Icons.people, 'key': 'timoteos'},
    {
      'title': 'Coordinadores',
      'icon': Icons.supervised_user_circle,
      'key': 'coordinadores'
    },
    {
      'title': 'Personas Asignadas',
      'icon': Icons.assignment_ind,
      'key': 'asignadas'
    },
    {'title': 'Asistencias', 'icon': Icons.list_alt, 'key': 'asistencias'},
    {'title': 'Eventos', 'icon': Icons.event_note, 'key': 'inscripciones'},
  ];

// Variables para almacenar los filtros seleccionados
  String? _anioSeleccionado;
  String? _mesSeleccionado;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _resetInactivityTimer();

    // Detectar interacciones del usuario
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        GestureBinding.instance.pointerRouter.addGlobalRoute((event) {
          if (mounted) {
            _resetInactivityTimer();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  // Métodos para manejo de sesión
  void _resetInactivityTimer() {
    if (!mounted) return;

    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(_inactivityDuration, () {
      if (mounted) {
        _cerrarSesionPorInactividad();
      }
    });
  }

  Future<void> _cerrarSesionPorInactividad() async {
    if (!mounted) return;

    _inactivityTimer?.cancel();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Sesión expirada por inactividad',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(16),
      ),
    );

    await Future.delayed(Duration(milliseconds: 500));

    if (mounted) {
      context.go('/login');
    }
  }

  Future<void> _confirmarCerrarSesion() async {
    _resetInactivityTimer();

    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.logout_rounded,
                color: Colors.orange,
                size: 24,
              ),
            ),
            SizedBox(width: 12),
            Text(
              'Cerrar Sesión',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Text(
          '¿Estás seguro que deseas cerrar sesión?',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey[700],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              'Cancelar',
              style: GoogleFonts.poppins(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 2,
            ),
            child: Text(
              'Cerrar Sesión',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _inactivityTimer?.cancel();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Container(
                padding: EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check, color: Colors.white, size: 20),
              ),
              SizedBox(width: 12),
              Text(
                'Cerrando sesión...',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          backgroundColor: Color(0xFF1B998B),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: EdgeInsets.all(16),
        ),
      );

      await Future.delayed(Duration(milliseconds: 300));
      if (mounted) {
        context.go('/login');
      }
    }
  }

// Función para determinar el ministerio basado en el nombre de la tribu
  String _determinarMinisterio(String tribuNombre) {
    if (tribuNombre.contains('Juvenil')) return 'Ministerio Juvenil';
    if (tribuNombre.contains('Damas')) return 'Ministerio de Damas';
    if (tribuNombre.contains('Caballeros')) return 'Ministerio de Caballeros';
    return 'Otro';
  }

// Función para guardar registro en Firebase
  void _guardarRegistroEnFirebase(BuildContext context,
      Map<String, dynamic> registro, String tribuId) async {
    _resetInactivityTimer();

    // Mostrar pantalla de carga con diseño mejorado
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: Color(0xFF038C7F),
                strokeWidth: 3,
              ),
              SizedBox(height: 16),
              Text(
                'Guardando registro...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1B998B),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final tribuSnapshot = await FirebaseFirestore.instance
          .collection('tribus')
          .doc(tribuId)
          .get();

      if (!tribuSnapshot.exists) {
        if (context.mounted) {
          Navigator.of(context, rootNavigator: true).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Error: La tribu no existe',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              margin: EdgeInsets.all(16),
            ),
          );
        }
        return;
      }

      final tribuData = tribuSnapshot.data() as Map<String, dynamic>;
      final tribuNombre = tribuData['nombreTribu'] ?? 'Desconocida';
      final ministerioAsignado = tribuData['ministerioAsignado'] ??
          tribuData['ministerio'] ??
          tribuData['categoria'] ??
          _determinarMinisterio(tribuNombre);

      registro['tribuAsignada'] = tribuId;
      registro['ministerioAsignado'] = ministerioAsignado;

      await FirebaseFirestore.instance.collection('registros').add(registro);

      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check, color: Colors.white, size: 20),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Registro guardado correctamente',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: EdgeInsets.all(16),
            duration: Duration(seconds: 3),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Error al guardar el registro: $e',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  void _showRegistroDialog(BuildContext context) {
    _resetInactivityTimer();

    final _formKey = GlobalKey<FormState>();

    final List<String> _estadosCiviles = [
      'Casado(a)',
      'Soltero(a)',
      'Unión Libre',
      'Separado(a)',
      'Viudo(a)'
    ];
    final List<String> _ocupaciones = [
      'Estudiante',
      'Profesional',
      'Trabaja',
      'Ama de Casa',
      'Otro'
    ];
    final List<String> _estadosProceso = [
      'Pendiente',
      'Discipulado 1',
      'Discipulado 2',
      'Discipulado 3',
      'Consolidación',
      'Estudio Bíblico',
      'Escuela de Líderes'
    ];

    // Variables para almacenar datos del formulario
    String nombre = '';
    String apellido = '';
    String telefono = '';
    String sexo = '';
    int edad = 0;
    String direccion = '';
    String barrio = '';
    String estadoCivil = 'Soltero(a)';
    String? nombrePareja = 'No aplica';
    List<String> ocupacionesSeleccionadas = [];
    String descripcionOcupaciones = '';
    bool tieneHijos = false;
    String referenciaInvitacion = '';
    String? observaciones;
    DateTime? fechaAsignacionTribu;
    String estadoProceso = '';

    // StatefulBuilder para manejar estado dinámico
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => StatefulBuilder(builder: (context, setState) {
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;
        final isSmallScreen = screenWidth < 600;
        final isMediumScreen = screenWidth >= 600 && screenWidth < 900;

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 16 : (isMediumScreen ? 32 : 40),
            vertical: isSmallScreen ? 16 : 20,
          ),
          child: Container(
            constraints: BoxConstraints(
              maxWidth:
                  isSmallScreen ? screenWidth : (isMediumScreen ? 650 : 700),
              maxHeight: screenHeight * (isSmallScreen ? 0.95 : 0.9),
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                // Header con gradiente
                Container(
                  padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF1B998B), Color(0xFF038C7F)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(isSmallScreen ? 16 : 24),
                      topRight: Radius.circular(isSmallScreen ? 16 : 24),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.person_add_rounded,
                          color: Colors.white,
                          size: isSmallScreen ? 20 : 24,
                        ),
                      ),
                      SizedBox(width: isSmallScreen ? 12 : 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Registrar Nuevo Miembro',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 16 : 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            if (!isSmallScreen)
                              Text(
                                'Completa la información del nuevo integrante',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close_rounded,
                            color: Colors.white, size: isSmallScreen ? 20 : 24),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
                        ),
                      ),
                    ],
                  ),
                ),

                // Formulario con scroll
                Expanded(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.manual,
                    physics: ClampingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      isSmallScreen ? 16 : 24,
                      isSmallScreen ? 16 : 24,
                      isSmallScreen ? 16 : 24,
                      isSmallScreen ? 16 : 24,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Sección: Información Personal
                          _buildSectionHeader('Información Personal',
                              Icons.person_outline_rounded, isSmallScreen),
                          SizedBox(height: isSmallScreen ? 12 : 16),

                          isSmallScreen
                              ? Column(
                                  children: [
                                    _buildTextField(
                                      'Nombre',
                                      Icons.badge_outlined,
                                      (value) => nombre = value,
                                      isSmallScreen: isSmallScreen,
                                    ),
                                    _buildTextField(
                                      'Apellido',
                                      Icons.person_outline_rounded,
                                      (value) => apellido = value,
                                      isSmallScreen: isSmallScreen,
                                    ),
                                  ],
                                )
                              : Row(
                                  children: [
                                    Expanded(
                                      child: _buildTextField(
                                        'Nombre',
                                        Icons.badge_outlined,
                                        (value) => nombre = value,
                                        isSmallScreen: isSmallScreen,
                                      ),
                                    ),
                                    SizedBox(width: 16),
                                    Expanded(
                                      child: _buildTextField(
                                        'Apellido',
                                        Icons.person_outline_rounded,
                                        (value) => apellido = value,
                                        isSmallScreen: isSmallScreen,
                                      ),
                                    ),
                                  ],
                                ),

                          isSmallScreen
                              ? Column(
                                  children: [
                                    _buildTextField(
                                      'Teléfono',
                                      Icons.phone_outlined,
                                      (value) => telefono = value,
                                      isSmallScreen: isSmallScreen,
                                    ),
                                    _buildTextField(
                                      'Edad',
                                      Icons.cake_outlined,
                                      (value) =>
                                          edad = int.tryParse(value) ?? 0,
                                      isSmallScreen: isSmallScreen,
                                    ),
                                  ],
                                )
                              : Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: _buildTextField(
                                        'Teléfono',
                                        Icons.phone_outlined,
                                        (value) => telefono = value,
                                        isSmallScreen: isSmallScreen,
                                      ),
                                    ),
                                    SizedBox(width: 16),
                                    Expanded(
                                      child: _buildTextField(
                                        'Edad',
                                        Icons.cake_outlined,
                                        (value) =>
                                            edad = int.tryParse(value) ?? 0,
                                        isSmallScreen: isSmallScreen,
                                      ),
                                    ),
                                  ],
                                ),

                          _buildDropdown(
                              'Sexo',
                              ['Masculino', 'Femenino'],
                              (value) => sexo = value,
                              Icons.wc_outlined,
                              isSmallScreen),

                          SizedBox(height: isSmallScreen ? 16 : 24),

                          // Sección: Ubicación
                          _buildSectionHeader('Ubicación',
                              Icons.location_on_outlined, isSmallScreen),
                          SizedBox(height: isSmallScreen ? 12 : 16),

                          _buildTextField('Dirección', Icons.home_outlined,
                              (value) => direccion = value,
                              isSmallScreen: isSmallScreen),
                          _buildTextField(
                              'Barrio',
                              Icons.location_city_outlined,
                              (value) => barrio = value,
                              isSmallScreen: isSmallScreen),

                          SizedBox(height: isSmallScreen ? 16 : 24),

                          // Sección: Estado Civil
                          _buildSectionHeader('Estado Civil',
                              Icons.favorite_outline_rounded, isSmallScreen),
                          SizedBox(height: isSmallScreen ? 12 : 16),

                          _buildDropdown('Estado Civil', _estadosCiviles,
                              (value) {
                            setState(() {
                              estadoCivil = value;
                              if (estadoCivil == 'Casado(a)' ||
                                  estadoCivil == 'Unión Libre') {
                                nombrePareja = '';
                              } else {
                                nombrePareja = 'No aplica';
                              }
                            });
                          }, Icons.favorite_border_rounded, isSmallScreen),

                          // Campo dinámico para nombre de pareja con animación
                          AnimatedContainer(
                            duration: Duration(milliseconds: 300),
                            height: (estadoCivil == 'Casado(a)' ||
                                    estadoCivil == 'Unión Libre')
                                ? null
                                : 0,
                            child: AnimatedOpacity(
                              duration: Duration(milliseconds: 300),
                              opacity: (estadoCivil == 'Casado(a)' ||
                                      estadoCivil == 'Unión Libre')
                                  ? 1.0
                                  : 0.0,
                              child: (estadoCivil == 'Casado(a)' ||
                                      estadoCivil == 'Unión Libre')
                                  ? _buildTextField(
                                      'Nombre de la Pareja',
                                      Icons.favorite_rounded,
                                      (value) => nombrePareja = value,
                                      isSmallScreen: isSmallScreen)
                                  : SizedBox(),
                            ),
                          ),

                          SizedBox(height: isSmallScreen ? 16 : 24),

                          // Sección: Ocupaciones
                          _buildSectionHeader('Ocupaciones',
                              Icons.work_outline_rounded, isSmallScreen),
                          SizedBox(height: isSmallScreen ? 12 : 16),

                          Container(
                            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                            decoration: BoxDecoration(
                              color: Color(0xFF1B998B).withOpacity(0.05),
                              borderRadius: BorderRadius.circular(
                                  isSmallScreen ? 12 : 16),
                              border: Border.all(
                                color: Color(0xFF1B998B).withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Selecciona las ocupaciones que apliquen:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF1B998B),
                                    fontSize: isSmallScreen ? 13 : 14,
                                  ),
                                ),
                                SizedBox(height: isSmallScreen ? 8 : 12),
                                Wrap(
                                  spacing: isSmallScreen ? 6 : 8,
                                  runSpacing: isSmallScreen ? 6 : 8,
                                  children: _ocupaciones.map((ocupacion) {
                                    final isSelected = ocupacionesSeleccionadas
                                        .contains(ocupacion);
                                    return AnimatedContainer(
                                      duration: Duration(milliseconds: 200),
                                      child: FilterChip(
                                        label: Text(
                                          ocupacion,
                                          style: TextStyle(
                                            color: isSelected
                                                ? Colors.white
                                                : Color(0xFF1B998B),
                                            fontWeight: isSelected
                                                ? FontWeight.w600
                                                : FontWeight.w500,
                                            fontSize: isSmallScreen ? 12 : 14,
                                          ),
                                        ),
                                        selected: isSelected,
                                        onSelected: (selected) {
                                          setState(() {
                                            if (selected) {
                                              ocupacionesSeleccionadas
                                                  .add(ocupacion);
                                            } else {
                                              ocupacionesSeleccionadas
                                                  .remove(ocupacion);
                                            }
                                          });
                                        },
                                        selectedColor: Color(0xFF1B998B),
                                        backgroundColor: Colors.white,
                                        side: BorderSide(
                                          color: isSelected
                                              ? Color(0xFF1B998B)
                                              : Color(0xFF1B998B)
                                                  .withOpacity(0.3),
                                          width: 1.5,
                                        ),
                                        elevation: isSelected ? 2 : 0,
                                        shadowColor:
                                            Color(0xFF1B998B).withOpacity(0.3),
                                        padding: EdgeInsets.symmetric(
                                          horizontal: isSmallScreen ? 8 : 12,
                                          vertical: isSmallScreen ? 4 : 8,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),

                          // Campo de descripción con animación
                          AnimatedContainer(
                            duration: Duration(milliseconds: 300),
                            height:
                                ocupacionesSeleccionadas.isNotEmpty ? null : 0,
                            child: AnimatedOpacity(
                              duration: Duration(milliseconds: 300),
                              opacity: ocupacionesSeleccionadas.isNotEmpty
                                  ? 1.0
                                  : 0.0,
                              child: ocupacionesSeleccionadas.isNotEmpty
                                  ? Padding(
                                      padding: EdgeInsets.only(
                                          top: isSmallScreen ? 12 : 16),
                                      child: _buildTextField(
                                        'Descripción de Ocupaciones',
                                        Icons.description_outlined,
                                        (value) =>
                                            descripcionOcupaciones = value,
                                        isRequired: false,
                                        isSmallScreen: isSmallScreen,
                                      ),
                                    )
                                  : SizedBox(),
                            ),
                          ),

                          SizedBox(height: isSmallScreen ? 16 : 24),

                          // Sección: Información Adicional
                          _buildSectionHeader('Información Adicional',
                              Icons.info_outline_rounded, isSmallScreen),
                          SizedBox(height: isSmallScreen ? 12 : 16),

                          _buildDropdown(
                              'Tiene Hijos',
                              ['No', 'Sí'],
                              (value) => tieneHijos = (value == 'Sí'),
                              Icons.child_care_outlined,
                              isSmallScreen),

                          _buildTextField(
                              'Referencia de Invitación',
                              Icons.link_outlined,
                              (value) => referenciaInvitacion = value,
                              isSmallScreen: isSmallScreen),

                          _buildTextField('Observaciones', Icons.note_outlined,
                              (value) => observaciones = value,
                              isRequired: false, isSmallScreen: isSmallScreen),

                          _buildTextFieldConOpciones(
                            'Estado en la Iglesia',
                            Icons.track_changes_outlined,
                            (value) => estadoProceso = value,
                            opciones: _estadosProceso,
                            isRequired: false,
                            isSmallScreen: isSmallScreen,
                          ),

                          // Campo para seleccionar fecha con diseño mejorado
                          Padding(
                            padding: EdgeInsets.symmetric(
                                vertical: isSmallScreen ? 6 : 8),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                    isSmallScreen ? 12 : 16),
                                border: Border.all(
                                  color: fechaAsignacionTribu != null
                                      ? Color(0xFF1B998B)
                                      : Colors.grey.shade300,
                                  width: fechaAsignacionTribu != null ? 2 : 1,
                                ),
                              ),
                              child: TextFormField(
                                readOnly: true,
                                style: TextStyle(
                                    fontSize: isSmallScreen ? 14 : 16),
                                decoration: InputDecoration(
                                  labelText: 'Fecha de Asignación de la Tribu',
                                  labelStyle: TextStyle(
                                    color: fechaAsignacionTribu != null
                                        ? Color(0xFF1B998B)
                                        : Colors.grey.shade600,
                                    fontSize: isSmallScreen ? 13 : 14,
                                  ),
                                  prefixIcon: Container(
                                    margin:
                                        EdgeInsets.all(isSmallScreen ? 8 : 12),
                                    padding:
                                        EdgeInsets.all(isSmallScreen ? 6 : 8),
                                    decoration: BoxDecoration(
                                      color: fechaAsignacionTribu != null
                                          ? Color(0xFF1B998B).withOpacity(0.1)
                                          : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.calendar_today_outlined,
                                      color: fechaAsignacionTribu != null
                                          ? Color(0xFF1B998B)
                                          : Colors.grey.shade600,
                                      size: isSmallScreen ? 18 : 20,
                                    ),
                                  ),
                                  suffixIcon: fechaAsignacionTribu != null
                                      ? Icon(Icons.check_circle,
                                          color: Color(0xFF1B998B),
                                          size: isSmallScreen ? 20 : 24)
                                      : null,
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: isSmallScreen ? 12 : 16,
                                      vertical: isSmallScreen ? 12 : 16),
                                ),
                                validator: (value) =>
                                    fechaAsignacionTribu == null
                                        ? 'Campo obligatorio'
                                        : null,
                                onTap: () async {
                                  final DateTime? pickedDate =
                                      await showDatePicker(
                                    context: context,
                                    initialDate: DateTime.now(),
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime(2101),
                                    builder: (context, child) {
                                      return Theme(
                                        data: Theme.of(context).copyWith(
                                          colorScheme: ColorScheme.light(
                                            primary: Color(0xFF1B998B),
                                            onPrimary: Colors.white,
                                            onSurface: Colors.black,
                                            surface: Colors.white,
                                          ),
                                          textButtonTheme: TextButtonThemeData(
                                            style: TextButton.styleFrom(
                                              foregroundColor:
                                                  Color(0xFFFF7E00),
                                            ),
                                          ),
                                        ),
                                        child: child!,
                                      );
                                    },
                                  );

                                  if (pickedDate != null) {
                                    setState(() {
                                      fechaAsignacionTribu = pickedDate;
                                    });
                                  }
                                },
                                controller: TextEditingController(
                                  text: fechaAsignacionTribu != null
                                      ? DateFormat('dd/MM/yyyy')
                                          .format(fechaAsignacionTribu!)
                                      : '',
                                ),
                              ),
                            ),
                          ),

                          // Espacio antes de los botones
                          SizedBox(height: isSmallScreen ? 24 : 32),

                          // Divisor visual
                          Divider(
                            color: Color(0xFF1B998B).withOpacity(0.2),
                            thickness: 1,
                          ),

                          SizedBox(height: isSmallScreen ? 16 : 20),

                          // Botones de acción DENTRO del scroll
                          isSmallScreen
                              ? Column(
                                  children: [
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Color(0xFFFF7E00),
                                          foregroundColor: Colors.white,
                                          padding: EdgeInsets.symmetric(
                                              vertical: 14),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          elevation: 2,
                                          shadowColor: Color(0xFFFF7E00)
                                              .withOpacity(0.3),
                                        ),
                                        onPressed: () {
                                          if (_formKey.currentState!
                                              .validate()) {
                                            final registro = {
                                              'fechaAsignacionTribu':
                                                  fechaAsignacionTribu != null
                                                      ? Timestamp.fromDate(
                                                          fechaAsignacionTribu!)
                                                      : null,
                                              'nombre': nombre,
                                              'apellido': apellido,
                                              'telefono': telefono,
                                              'sexo': sexo,
                                              'edad': edad,
                                              'direccion': direccion,
                                              'barrio': barrio,
                                              'estadoCivil': estadoCivil,
                                              'nombrePareja': nombrePareja,
                                              'ocupaciones':
                                                  ocupacionesSeleccionadas,
                                              'descripcionOcupaciones':
                                                  descripcionOcupaciones,
                                              'tieneHijos': tieneHijos,
                                              'referenciaInvitacion':
                                                  referenciaInvitacion,
                                              'observaciones': observaciones,
                                              'tribuAsignada': widget.tribuId,
                                              'ministerioAsignado':
                                                  _determinarMinisterio(
                                                      widget.tribuNombre),
                                              'coordinadorAsignado': null,
                                              'fechaRegistro':
                                                  FieldValue.serverTimestamp(),
                                              'activo': true,
                                              'estadoProceso': estadoProceso,
                                            };

                                            _guardarRegistroEnFirebase(context,
                                                registro, widget.tribuId);
                                          }
                                        },
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.save_outlined, size: 18),
                                            SizedBox(width: 8),
                                            Text(
                                              'Guardar Registro',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 15,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 12),
                                    SizedBox(
                                      width: double.infinity,
                                      child: TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.symmetric(
                                              vertical: 14),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            side: BorderSide(
                                                color: Colors.grey.shade300),
                                          ),
                                        ),
                                        child: Text(
                                          'Cancelar',
                                          style: TextStyle(
                                            color: Colors.grey.shade700,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : Row(
                                  children: [
                                    Expanded(
                                      child: TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.symmetric(
                                              vertical: 16),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            side: BorderSide(
                                                color: Colors.grey.shade300),
                                          ),
                                        ),
                                        child: Text(
                                          'Cancelar',
                                          style: TextStyle(
                                            color: Colors.grey.shade700,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 16),
                                    Expanded(
                                      flex: 2,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Color(0xFFFF7E00),
                                          foregroundColor: Colors.white,
                                          padding: EdgeInsets.symmetric(
                                              vertical: 16),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          elevation: 2,
                                          shadowColor: Color(0xFFFF7E00)
                                              .withOpacity(0.3),
                                        ),
                                        onPressed: () {
                                          if (_formKey.currentState!
                                              .validate()) {
                                            final registro = {
                                              'fechaAsignacionTribu':
                                                  fechaAsignacionTribu != null
                                                      ? Timestamp.fromDate(
                                                          fechaAsignacionTribu!)
                                                      : null,
                                              'nombre': nombre,
                                              'apellido': apellido,
                                              'telefono': telefono,
                                              'sexo': sexo,
                                              'edad': edad,
                                              'direccion': direccion,
                                              'barrio': barrio,
                                              'estadoCivil': estadoCivil,
                                              'nombrePareja': nombrePareja,
                                              'ocupaciones':
                                                  ocupacionesSeleccionadas,
                                              'descripcionOcupaciones':
                                                  descripcionOcupaciones,
                                              'tieneHijos': tieneHijos,
                                              'referenciaInvitacion':
                                                  referenciaInvitacion,
                                              'observaciones': observaciones,
                                              'tribuAsignada': widget.tribuId,
                                              'ministerioAsignado':
                                                  _determinarMinisterio(
                                                      widget.tribuNombre),
                                              'coordinadorAsignado': null,
                                              'fechaRegistro':
                                                  FieldValue.serverTimestamp(),
                                              'activo': true,
                                              'estadoProceso': estadoProceso,
                                            };

                                            _guardarRegistroEnFirebase(context,
                                                registro, widget.tribuId);
                                          }
                                        },
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.save_outlined, size: 20),
                                            SizedBox(width: 8),
                                            Text(
                                              'Guardar Registro',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                          // Espacio final
                          SizedBox(height: isSmallScreen ? 16 : 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

// Widget para headers de sección
  Widget _buildSectionHeader(String title, IconData icon, bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 6 : 8),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 4 : 6),
            decoration: BoxDecoration(
              color: Color(0xFF1B998B).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Color(0xFF1B998B),
              size: isSmallScreen ? 16 : 18,
            ),
          ),
          SizedBox(width: isSmallScreen ? 8 : 12),
          Flexible(
            child: Text(
              title,
              style: TextStyle(
                fontSize: isSmallScreen ? 15 : 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B998B),
              ),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF1B998B).withOpacity(0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

// Método auxiliar para campos de texto con diseño mejorado
  Widget _buildTextField(
      String label, IconData icon, Function(String) onChanged,
      {bool isRequired = true, bool isSmallScreen = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 6 : 8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: TextFormField(
          style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(
              color: Colors.grey.shade600,
              fontSize: isSmallScreen ? 13 : 14,
            ),
            prefixIcon: Container(
              margin: EdgeInsets.all(isSmallScreen ? 8 : 12),
              padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
              decoration: BoxDecoration(
                color: Color(0xFF1B998B).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon,
                  color: Color(0xFF1B998B), size: isSmallScreen ? 18 : 20),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
              borderSide: BorderSide(color: Color(0xFF1B998B), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
              borderSide: BorderSide(color: Colors.red.shade400, width: 2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
              borderSide: BorderSide(color: Colors.red.shade400, width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 12 : 16,
              vertical: isSmallScreen ? 12 : 16,
            ),
          ),
          validator: isRequired
              ? (value) =>
                  (value == null || value.isEmpty) ? 'Campo obligatorio' : null
              : null,
          onChanged: onChanged,
        ),
      ),
    );
  }

// Método de construcción de dropdown con diseño mejorado
  Widget _buildDropdown(String label, List<String> options,
      Function(String) onChanged, IconData icon, bool isSmallScreen) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 6 : 8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: DropdownButtonFormField<String>(
          style: TextStyle(
            fontSize: isSmallScreen ? 14 : 16,
            color: Colors.grey.shade800,
          ),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(
              color: Colors.grey.shade600,
              fontSize: isSmallScreen ? 13 : 14,
            ),
            prefixIcon: Container(
              margin: EdgeInsets.all(isSmallScreen ? 8 : 12),
              padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
              decoration: BoxDecoration(
                color: Color(0xFF1B998B).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon,
                  color: Color(0xFF1B998B), size: isSmallScreen ? 18 : 20),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
              borderSide: BorderSide(color: Color(0xFF1B998B), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
              borderSide: BorderSide(color: Colors.red.shade400, width: 2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
              borderSide: BorderSide(color: Colors.red.shade400, width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 12 : 16,
              vertical: isSmallScreen ? 12 : 16,
            ),
          ),
          items: options
              .map((option) => DropdownMenuItem(
                    value: option,
                    child: Text(
                      option,
                      style: TextStyle(
                        color: Colors.grey.shade800,
                        fontWeight: FontWeight.w500,
                        fontSize: isSmallScreen ? 14 : 16,
                      ),
                    ),
                  ))
              .toList(),
          validator: (value) => value == null ? 'Selecciona una opción' : null,
          onChanged: (value) {
            if (value != null) {
              onChanged(value);
            }
          },
          dropdownColor: Colors.white,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Color(0xFF1B998B),
            size: isSmallScreen ? 20 : 24,
          ),
        ),
      ),
    );
  }

// Método de construcción de selección múltiple
  Widget _buildMultiSelect(
      String label, List<String> options, Function(List<String>) onChanged) {
    List<String> selectedOptions = [];

    return StatefulBuilder(
      builder: (context, setState) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
              Wrap(
                spacing: 8,
                children: options.map((option) {
                  final isSelected = selectedOptions.contains(option);
                  return ChoiceChip(
                    label: Text(option),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        selected
                            ? selectedOptions.add(option)
                            : selectedOptions.remove(option);
                      });
                      onChanged(selectedOptions);
                    },
                    selectedColor: Color(0xFF1B998B),
                    labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

// Método auxiliar para campos de texto con opciones predefinidas
  Widget _buildTextFieldConOpciones(
      String label, IconData icon, Function(String) onChanged,
      {List<String>? opciones,
      bool isRequired = true,
      bool isSmallScreen = false}) {
    // Crear un controlador local para manejar el texto
    final TextEditingController localController = TextEditingController();

    return Padding(
      padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 6 : 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: TextFormField(
              controller: localController,
              style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
              decoration: InputDecoration(
                labelText: label,
                labelStyle: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: isSmallScreen ? 13 : 14,
                ),
                prefixIcon: Container(
                  margin: EdgeInsets.all(isSmallScreen ? 8 : 12),
                  padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                  decoration: BoxDecoration(
                    color: Color(0xFF1B998B).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon,
                      color: Color(0xFF1B998B), size: isSmallScreen ? 18 : 20),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
                  borderSide: BorderSide(color: Color(0xFF1B998B), width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
                  borderSide: BorderSide(color: Colors.red.shade400, width: 2),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
                  borderSide: BorderSide(color: Colors.red.shade400, width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 12 : 16,
                  vertical: isSmallScreen ? 12 : 16,
                ),
              ),
              validator: isRequired
                  ? (value) => (value == null || value.isEmpty)
                      ? 'Campo obligatorio'
                      : null
                  : null,
              onChanged: (value) {
                onChanged(value);
              },
            ),
          ),
          if (opciones != null && opciones.isNotEmpty) ...[
            SizedBox(height: isSmallScreen ? 8 : 12),
            Container(
              padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
              decoration: BoxDecoration(
                color: Color(0xFF1B998B).withOpacity(0.05),
                borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
                border: Border.all(
                  color: Color(0xFF1B998B).withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.touch_app_outlined,
                        size: isSmallScreen ? 14 : 16,
                        color: Color(0xFF1B998B),
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Opciones rápidas:',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1B998B),
                          fontSize: isSmallScreen ? 12 : 13,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isSmallScreen ? 6 : 8),
                  Wrap(
                    spacing: isSmallScreen ? 6 : 8,
                    runSpacing: isSmallScreen ? 6 : 8,
                    children: opciones.map((opcion) {
                      return ActionChip(
                        label: Text(
                          opcion,
                          style: TextStyle(
                            color: Color(0xFF1B998B),
                            fontWeight: FontWeight.w500,
                            fontSize: isSmallScreen ? 11 : 13,
                          ),
                        ),
                        onPressed: () {
                          // Actualizar el controlador local
                          localController.text = opcion;
                          // Llamar al callback onChanged
                          onChanged(opcion);
                        },
                        backgroundColor: Colors.white,
                        side: BorderSide(
                          color: Color(0xFF1B998B).withOpacity(0.3),
                          width: 1.5,
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 8 : 10,
                          vertical: isSmallScreen ? 4 : 6,
                        ),
                        elevation: 0,
                        pressElevation: 2,
                        shadowColor: Color(0xFF1B998B).withOpacity(0.3),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryTeal = Color(0xFF1B998B);
    final Color secondaryOrange = Color(0xFFFF7E00);
    final Color lightTeal = Color(0xFFE0F7FA);

    return Theme(
      data: ThemeConstants.appTheme,
      child: DefaultTabController(
        length: 5,
        child: Scaffold(
          appBar: AppBar(
            elevation: 2,
            backgroundColor: primaryTeal,
            titleSpacing: 12,
            title: Row(
              children: [
                // Logo mejorado con mejor visibilidad
                Hero(
                  tag: 'logo',
                  child: Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Container(
                      height: 38,
                      width: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/Cocep_.png',
                          height: 38,
                          width: 38,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                // Título con mejor espaciado
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Tribu',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      Text(
                        widget.tribuNombre,
                        style: GoogleFonts.poppins(
                          fontSize:
                              MediaQuery.of(context).size.width < 400 ? 16 : 18,
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
              // Botón de cerrar sesión mejorado
              Container(
                margin: EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.25),
                      Colors.white.withOpacity(0.15),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.6),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _confirmarCerrarSesion,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      constraints: BoxConstraints(
                        minWidth: 80,
                        minHeight: 40,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.logout_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Salir',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              shadows: [
                                Shadow(
                                  offset: Offset(0, 1),
                                  blurRadius: 2,
                                  color: Colors.black.withOpacity(0.3),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(60),
              child: Container(
                decoration: BoxDecoration(
                  color: primaryTeal,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      offset: Offset(0, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: secondaryOrange,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(10),
                      topRight: Radius.circular(10),
                    ),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white.withOpacity(0.7),
                  tabs: [
                    _buildTab(Icons.people, 'Timoteos'),
                    _buildTab(Icons.supervised_user_circle, 'Coordinadores'),
                    _buildTab(Icons.assignment_ind, 'Personas'),
                    _buildTab(Icons.list_alt, 'Asistencias'),
                    _buildTab(Icons.event_note, 'Eventos'),
                  ],
                ),
              ),
            ),
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [lightTeal, Colors.white],
                stops: [0.0, 0.5],
              ),
            ),
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTabContent(TimoteosTab(tribuId: widget.tribuId)),
                _buildTabContent(CoordinadoresTab(tribuId: widget.tribuId)),
                _buildTabContent(
                  RegistrosAsignadosTab(
                    tribuId: widget.tribuId,
                    tribuNombre: widget.tribuNombre,
                  ),
                ),
                _buildTabContent(AsistenciasTab(tribuId: widget.tribuId)),
                _buildTabContent(InscripcionesTab(tribuId: widget.tribuId)),
              ],
            ),
          ),
          // FloatingActionButton eliminado - Botón movido a pestaña Personas
        ),
      ),
    );
  }

  Widget _buildTab(IconData icon, String text) {
    return Tab(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          SizedBox(height: 4),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(Widget child) {
    return Container(
      padding: EdgeInsets.all(8),
      child: child,
    );
  }

// ✅ NUEVA VERSIÓN: Acepta filtros como parámetros opcionales
  void descargarExcel(BuildContext context, String tribuId, String tribuNombre,
      {String? anioFiltro,
      String? mesFiltro,
      String? estadoFiltro} // ✅ AGREGADO estadoFiltro
      ) async {
    const Color primaryTeal = Color(0xFF1B998B);
    const Color secondaryOrange = Color(0xFFFF7E00);
    final Color lightTeal = primaryTeal.withOpacity(0.1);

    // ✅ Normalizar "Todos" a null
    if (anioFiltro == 'Todos') anioFiltro = null;
    if (mesFiltro == 'Todos') mesFiltro = null;

    print(
        '📊 Exportando con filtros: Año=${anioFiltro ?? "Todos"}, Mes=${mesFiltro ?? "Todos"}');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: lightTeal,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.file_download, color: primaryTeal, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Exportando Registros',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: primaryTeal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(primaryTeal),
                ),
                const SizedBox(height: 20),
                Text(
                  'Preparando el archivo Excel...',
                  style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                ),
              ],
            ),
          ),
        );
      },
    );

    try {
      final excelGenerator = ExcelExporter();

      // ✅ Pasar los filtros al exportador (incluyendo estado)
      await excelGenerator.exportarRegistros(
        context,
        tribuId,
        tribuNombre,
        anioFiltro: anioFiltro,
        mesFiltro: mesFiltro,
        estadoFiltro: estadoFiltro, // ✅ NUEVO
      );

      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();

        // Mensaje personalizado según filtros
        String mensajeExito =
            'Archivo "Datos de las personas - $tribuNombre" generado correctamente';

        if (anioFiltro != null || mesFiltro != null || estadoFiltro != null) {
          mensajeExito += ' (';

          final List<String> filtrosActivos = [];

          if (anioFiltro != null) {
            filtrosActivos.add('Año: $anioFiltro');
          }

          if (mesFiltro != null) {
            final mesesNombres = {
              '1': 'Enero',
              '2': 'Febrero',
              '3': 'Marzo',
              '4': 'Abril',
              '5': 'Mayo',
              '6': 'Junio',
              '7': 'Julio',
              '8': 'Agosto',
              '9': 'Septiembre',
              '10': 'Octubre',
              '11': 'Noviembre',
              '12': 'Diciembre'
            };
            filtrosActivos.add('Mes: ${mesesNombres[mesFiltro] ?? mesFiltro}');
          }

          if (estadoFiltro != null) {
            filtrosActivos.add('Estado: $estadoFiltro');
          }

          mensajeExito += filtrosActivos.join(', ');
          mensajeExito += ')';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(mensajeExito, style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('❌ ERROR al generar Excel: $e');

      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text('Error al generar el archivo: ${e.toString()}',
                      style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _showAddOptions(
      BuildContext context, Color primaryColor, Color secondaryColor) {
    _resetInactivityTimer();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.add_circle_outline, color: primaryColor, size: 28),
                  SizedBox(width: 12),
                  Text(
                    'Agregar Nuevo',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            _buildOptionButton(
              context,
              'Registrar Miembro',
              Icons.person_add_alt_1,
              primaryColor,
              secondaryColor,
              () {
                Navigator.pop(context);
                _showRegistroDialog(context);
              },
            ),
            SizedBox(height: 12),
            _buildOptionButton(
              context,
              'Crear Evento',
              Icons.event_note,
              primaryColor,
              secondaryColor,
              () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (context) => DialogoCrearEvento(
                    tribuId: widget.tribuId,
                    primaryColor: primaryColor,
                    secondaryColor: secondaryColor,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionButton(
    BuildContext context,
    String title,
    IconData icon,
    Color primaryColor,
    Color secondaryColor,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryColor, primaryColor.withOpacity(0.8)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.3),
                blurRadius: 5,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 24),
                SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Spacer(),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Componente de ejemplo para mostrar animación de carga
class AnimatedLoadingIndicator extends StatefulWidget {
  @override
  _AnimatedLoadingIndicatorState createState() =>
      _AnimatedLoadingIndicatorState();
}

class _AnimatedLoadingIndicatorState extends State<AnimatedLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 1),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: RotationTransition(
        turns: _controller,
        child: Container(
          width: 50,
          height: 50,
          child: Icon(
            Icons.local_fire_department,
            color: Color(0xFFFF7E00),
            size: 40,
          ),
        ),
      ),
    );
  }
}

// Ejemplo de cómo podría ser una tarjeta personalizada para los miembros de la tribu
class MiembroCard extends StatelessWidget {
  final String nombre;
  final String rol;
  final String? imageUrl;
  final VoidCallback onTap;

  const MiembroCard({
    Key? key,
    required this.nombre,
    required this.rol,
    this.imageUrl,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Color(0xFF148B9C).withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Color(0xFF148B9C),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: imageUrl != null
                      ? ClipOval(
                          child: Image.network(
                            imageUrl!,
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Icon(
                          Icons.person,
                          size: 30,
                          color: Color(0xFF148B9C),
                        ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nombre,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      rol,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Color(0xFFFF7E00),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

//--------------------------PESTAÑA DE ASISTENCIA
class AsistenciasTab extends StatefulWidget {
  final String tribuId;

  const AsistenciasTab({Key? key, required this.tribuId}) : super(key: key);

  @override
  State<AsistenciasTab> createState() => _AsistenciasTabState();
}

class _AsistenciasTabState extends State<AsistenciasTab>
    with SingleTickerProviderStateMixin {
  // ⬅️ NUEVO: Mixin para TabController

  // ========================================
  // NUEVAS VARIABLES PARA EL SISTEMA DE PESTAÑAS
  // ========================================
  late TabController _tabController;

  // ========================================
  // VARIABLES DE ESTADO ORIGINALES
  // ========================================
  final Map<String, bool> _servicioExpand = {};
  Map<String, Map<String, Map<String, List<Map<String, dynamic>>>>>?
      _cachedDataAsistencias; // ⬅️ NUEVO: Caché separado para asistencias
  Map<String, Map<String, Map<String, List<Map<String, dynamic>>>>>?
      _cachedDataFallas; // ⬅️ NUEVO: Caché separado para fallas
  bool _isFirstLoadAsistencias = true; // ⬅️ NUEVO: Control de carga por pestaña
  bool _isFirstLoadFallas = true; // ⬅️ NUEVO

  // ========================================
  // INICIALIZACIÓN DEL TabController
  // ========================================
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  // ========================================
  // LIMPIEZA DEL TabController
  // ========================================
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ========================================
  // FUNCIÓN MODIFICADA: Ahora recibe parámetro para filtrar
  // true = asistencias, false = fallas
  // ========================================

// ========================================
// MÉTODOS AUXILIARES PARA NOMBRES DE SERVICIOS
// ========================================
  String _displayServiceName(String serviceName) {
    // Reemplazar "Dominical" por "Familiar" solo para mostrar
    if (serviceName.toLowerCase().contains('dominical')) {
      return serviceName.replaceAll(
          RegExp(r'dominical', caseSensitive: false), 'Familiar');
    }
    // Reemplazar "Reunión General" por "Servicio Especial" solo para mostrar
    if (serviceName.toLowerCase().contains('reunión general') ||
        serviceName.toLowerCase().contains('reunion general')) {
      return serviceName.replaceAll(
          RegExp(r'reuni[óo]n general', caseSensitive: false),
          'Servicio Especial');
    }
    return serviceName;
  }

  String _normalizeServiceName(String serviceName) {
    // Normalizar para comparación: aceptar tanto "Dominical" como "Familiar"
    if (serviceName.toLowerCase().contains('familiar')) {
      return serviceName.replaceAll(
          RegExp(r'familiar', caseSensitive: false), 'Dominical');
    }
    return serviceName;
  }

  Stream<QuerySnapshot> obtenerAsistenciasPorTribu(
      String tribuId, bool mostrarAsistencias) {
    return FirebaseFirestore.instance
        .collection('asistencias')
        .where('tribuId', isEqualTo: tribuId)
        .where('asistio',
            isEqualTo: mostrarAsistencias) // ⬅️ MODIFICADO: Filtro dinámico
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ========================================
        // NUEVO: BARRA DE PESTAÑAS
        // ========================================
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF1D8A8A),
            unselectedLabelColor: Colors.grey[600],
            indicatorColor: const Color(0xFF1D8A8A),
            indicatorWeight: 3,
            labelStyle: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
            unselectedLabelStyle: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 15,
            ),
            tabs: [
              Tab(
                icon: Icon(Icons.check_circle_outline),
                text: 'Asistencias',
              ),
              Tab(
                icon: Icon(Icons.cancel_outlined),
                text: 'Inasistencias',
              ),
            ],
          ),
        ),

        // ========================================
        // NUEVO: CONTENIDO DE LAS PESTAÑAS
        // ========================================
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // Pestaña 1: Asistencias (asistio = true)
              _buildContenidoAsistencias(true),

              // Pestaña 2: Fallas (asistio = false)
              _buildContenidoAsistencias(false),
            ],
          ),
        ),
      ],
    );
  }

  // ========================================
  // NUEVA FUNCIÓN: Construye el contenido para cada pestaña
  // Parámetro: mostrarAsistencias (true/false)
  // ========================================

// ========================================
// NUEVA FUNCIÓN OPTIMIZADA: Construye el contenido para cada pestaña
// ========================================
  Widget _buildContenidoAsistencias(bool mostrarAsistencias) {
    // ⬅️ OPTIMIZACIÓN: Determinar qué caché y control usar
    final cachedData =
        mostrarAsistencias ? _cachedDataAsistencias : _cachedDataFallas;
    final isFirstLoad =
        mostrarAsistencias ? _isFirstLoadAsistencias : _isFirstLoadFallas;

    return StreamBuilder<QuerySnapshot>(
      stream: obtenerAsistenciasPorTribu(widget.tribuId, mostrarAsistencias),
      builder: (context, snapshot) {
        // ⬅️ OPTIMIZACIÓN: Si ya hay caché, mostrarlo inmediatamente
        if (cachedData != null && cachedData.isNotEmpty) {
          return _buildListaConDatos(cachedData, mostrarAsistencias);
        }

        // Manejo de carga inicial
        if (snapshot.connectionState == ConnectionState.waiting &&
            isFirstLoad) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 60,
                  width: 60,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      mostrarAsistencias
                          ? const Color(0xFF1D8A8A)
                          : const Color(0xFFE74C3C),
                    ),
                    strokeWidth: 4,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  mostrarAsistencias
                      ? 'Cargando asistencias...'
                      : 'Cargando inasistencias...',
                  style: TextStyle(
                    fontSize: 16,
                    color: mostrarAsistencias
                        ? const Color(0xFF1D8A8A)
                        : const Color(0xFFE74C3C),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        // Manejo de datos vacíos
        if ((!snapshot.hasData || snapshot.data!.docs.isEmpty) && isFirstLoad) {
          // ⬅️ OPTIMIZACIÓN: Actualizar control de primera carga
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                if (mostrarAsistencias) {
                  _isFirstLoadAsistencias = false;
                } else {
                  _isFirstLoadFallas = false;
                }
              });
            }
          });

          return _buildMensajeVacio(mostrarAsistencias, true);
        }

        // Procesamiento de datos
        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          // ⬅️ OPTIMIZACIÓN: Procesar y cachear datos
          final asistencias = snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final nombre = data['nombre'] ?? "Sin nombre";
            final apellido = data['apellido'] ?? '';
            final nombreCompleto =
                apellido.isNotEmpty ? "$nombre $apellido" : nombre;

            return {
              'nombre': nombre,
              'nombreCompleto': nombreCompleto,
              'fecha': (data['fecha'] as Timestamp).toDate(),
              'diaSemana': data['diaSemana'] ?? '',
              'asistio': data['asistio'],
              'nombreServicio': data['nombreServicio'] ?? '',
              'ministerio': _determinarMinisterio(data['nombreServicio'] ?? ''),
            };
          }).toList();

          final datosAgrupados = _agruparAsistenciasPorFecha(asistencias);

          // ⬅️ OPTIMIZACIÓN: Guardar en caché correspondiente
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                if (mostrarAsistencias) {
                  _cachedDataAsistencias = datosAgrupados;
                  _isFirstLoadAsistencias = false;
                } else {
                  _cachedDataFallas = datosAgrupados;
                  _isFirstLoadFallas = false;
                }
              });
            }
          });

          return _buildListaConDatos(datosAgrupados, mostrarAsistencias);
        }

        return _buildMensajeVacio(mostrarAsistencias, true);
      },
    );
  }

// ========================================
// FUNCIÓN CORREGIDA: Construye la lista con datos
// ========================================
  Widget _buildListaConDatos(
    Map<String, Map<String, Map<String, List<Map<String, dynamic>>>>>
        asistenciasAgrupadas,
    bool mostrarAsistencias,
  ) {
    if (asistenciasAgrupadas.isEmpty) {
      return _buildMensajeVacio(mostrarAsistencias, false);
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: mostrarAsistencias
              ? [
                  Colors.white,
                  const Color(0xFF1D8A8A).withOpacity(0.05),
                ]
              : [
                  Colors.white,
                  const Color(0xFFE74C3C).withOpacity(0.05),
                ],
        ),
      ),
      child: ListView.builder(
        // ⬅️ REMOVIDO: PageStorageKey que causaba el error
        padding: EdgeInsets.all(16),
        itemCount: asistenciasAgrupadas.keys.length,
        cacheExtent: 1000,
        itemBuilder: (context, yearIndex) {
          final year = asistenciasAgrupadas.keys.elementAt(yearIndex);
          final months = asistenciasAgrupadas[year]!;

          return Card(
            elevation: 4,
            margin: EdgeInsets.only(bottom: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: mostrarAsistencias
                          ? [
                              const Color(0xFF1D8A8A),
                              const Color(0xFF156D6D),
                            ]
                          : [
                              const Color(0xFFE74C3C),
                              const Color(0xFFC0392B),
                            ],
                    ),
                  ),
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      dividerColor: Colors.transparent,
                      colorScheme: ColorScheme.light(
                        primary: Colors.white,
                      ),
                    ),
                    child: ExpansionTile(
                      // ⬅️ CORREGIDO: Key único sin conflictos
                      key: ValueKey(
                          'year_${year}_${mostrarAsistencias ? "asist" : "fallas"}'),
                      maintainState: true,
                      leading: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.calendar_today,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        'Año $year',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      subtitle: Text(
                        mostrarAsistencias
                            ? 'Registro de asistencias'
                            : 'Registro de inasistencias',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                      iconColor: Colors.white,
                      collapsedIconColor: Colors.white,
                      childrenPadding:
                          EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      children: (() {
                        final sortedMonths = months.keys.toList()
                          ..sort((a, b) =>
                              _monthToNumber(a).compareTo(_monthToNumber(b)));

                        final ordered = sortedMonths.map((month) {
                          return _buildMonthSection(context, month,
                              months[month]!, year, mostrarAsistencias);
                        }).toList();

                        return ordered.reversed.toList();
                      })(),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ========================================
  // FUNCIÓN MODIFICADA: Ahora recibe parámetro mostrarAsistencias
  // ========================================
  Widget _buildMonthSection(
      BuildContext context,
      String month,
      Map<String, List<Map<String, dynamic>>> weeks,
      String year,
      bool mostrarAsistencias) {
    final monthName = _getSpanishMonth(month);
    final IconData monthIcon = _getMonthIcon(month);

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: (mostrarAsistencias
                  ? const Color(0xFF1D8A8A)
                  : const Color(0xFFE74C3C))
              .withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: mostrarAsistencias
                ? [
                    Colors.white,
                    const Color(0xFF1D8A8A).withOpacity(0.08),
                  ]
                : [
                    Colors.white,
                    const Color(0xFFE74C3C)
                        .withOpacity(0.08), // ⬅️ Rojo para fallas
                  ],
          ),
        ),
        child: ExpansionTile(
          maintainState: true,
          leading: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: mostrarAsistencias
                    ? [
                        const Color(0xFF1D8A8A),
                        const Color(0xFF1D8A8A).withOpacity(0.7),
                      ]
                    : [
                        const Color(0xFFE74C3C),
                        const Color(0xFFE74C3C).withOpacity(0.7),
                      ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              monthIcon,
              color: Colors.white,
              size: 20,
            ),
          ),
          title: Text(
            monthName,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: mostrarAsistencias
                  ? const Color(0xFF1D8A8A)
                  : const Color(0xFFE74C3C),
            ),
          ),
          subtitle: Text(
            'Toca para ver semanas',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          iconColor: mostrarAsistencias
              ? const Color(0xFF1D8A8A)
              : const Color(0xFFE74C3C),
          collapsedIconColor: mostrarAsistencias
              ? const Color(0xFF1D8A8A)
              : const Color(0xFFE74C3C),
          children: (() {
            // Ordenar las semanas por la fecha REAL del primer registro
            final sortedWeeks = weeks.entries.toList()
              ..sort((a, b) {
                // Obtener la fecha real del primer registro de cada semana
                final fechaA = a.value.isNotEmpty
                    ? a.value.first['fecha'] as DateTime
                    : DateTime.now();
                final fechaB = b.value.isNotEmpty
                    ? b.value.first['fecha'] as DateTime
                    : DateTime.now();

                // Obtener el martes de cada semana
                final martesA = _obtenerLunesDeLaSemana(fechaA);
                final martesB = _obtenerLunesDeLaSemana(fechaB);

                // Comparar las fechas completas (año, mes, día)
                return martesA.compareTo(martesB);
              });

            // Revertir para mostrar de más reciente a más antigua
            return sortedWeeks.reversed.map((entry) {
              return _buildWeekSection(
                context,
                entry.key,
                entry.value,
                '$monthName $year',
                mostrarAsistencias,
              );
            }).toList();
          })(),
        ),
      ),
    );
  }

  // ========================================
  // FUNCIÓN MODIFICADA: Ahora recibe parámetro mostrarAsistencias
  // ========================================
  Widget _buildWeekSection(
      BuildContext context,
      String week,
      List<Map<String, dynamic>> asistencias,
      String monthYear,
      bool mostrarAsistencias) {
    Map<String, List<Map<String, dynamic>>> porServicio = {};
    Map<String, Set<String>> personasPorServicio = {};
    Set<String> todasLasPersonas = {};

    for (var asistencia in asistencias) {
      final servicio = asistencia['nombreServicio'] ?? 'Otro Servicio';
      final nombre = asistencia['nombre'];

      if (!porServicio.containsKey(servicio)) {
        porServicio[servicio] = [];
        personasPorServicio[servicio] = {};
      }

      porServicio[servicio]!.add(asistencia);
      personasPorServicio[servicio]!.add(nombre);
      todasLasPersonas.add(nombre);
    }

    Map<String, int> resumen = {
      for (var servicio in porServicio.keys)
        servicio: personasPorServicio[servicio]!.length
    };
    resumen[mostrarAsistencias
        ? 'Total del Fin de Semana'
        : 'Total de Fallas'] = todasLasPersonas.length;

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              const Color(0xFFF5A623).withOpacity(0.05),
            ],
          ),
          border: Border.all(
            color: const Color(0xFFF5A623).withOpacity(0.2),
            width: 1,
          ),
        ),
        child: ExpansionTile(
          maintainState: true,
          leading: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFF5A623),
                  const Color(0xFFFF7A00),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.date_range,
              color: Colors.white,
              size: 18,
            ),
          ),
          title: Text(
            _formatearRangoSemana(week, asistencias),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFEE5A24),
            ),
          ),
          subtitle: Text(
            _obtenerRangoFechasCompleto(week, asistencias),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          iconColor: const Color(0xFFEE5A24),
          collapsedIconColor: const Color(0xFFEE5A24),
          children: [
            // ⬅️ ORDENAR por fecha real de asistencia
            ...(() {
              // Convertir entries a lista para poder ordenar
              final serviciosList = porServicio.entries.toList();

              // Ordenar por fecha real del primer registro de asistencia
              serviciosList.sort((a, b) {
                // Obtener la primera fecha de cada servicio
                final fechaA = a.value.isNotEmpty
                    ? a.value.first['fecha'] as DateTime
                    : DateTime.now();
                final fechaB = b.value.isNotEmpty
                    ? b.value.first['fecha'] as DateTime
                    : DateTime.now();

                // Comparar por día de la semana (1=Lunes, 7=Domingo)
                final diaA = fechaA.weekday;
                final diaB = fechaB.weekday;

                return diaA.compareTo(diaB);
              });

              // Mapear a widgets
              return serviciosList.map((entry) {
                final servicio = entry.key;
                final listaAsistencias = entry.value;
                final ministerio = _determinarMinisterio(servicio);

                final groupKey = '$monthYear|$week|$servicio';

                return _buildServicioSection(
                  servicio,
                  ministerio,
                  listaAsistencias,
                  groupKey: groupKey,
                  mostrarAsistencias: mostrarAsistencias,
                );
              }).toList();
            })(),
            _buildTotalSection(resumen, mostrarAsistencias, porServicio),
          ],
        ),
      ),
    );
  }

  // ========================================
  // FUNCIÓN MODIFICADA: Ahora recibe parámetro mostrarAsistencias
  // Cambia los colores y el ícono final según el tipo
  // ========================================

  Widget _buildServicioSection(
    String servicio,
    String ministerio,
    List<Map<String, dynamic>> asistencias, {
    required String groupKey,
    required bool mostrarAsistencias,
  }) {
    // ✅ NORMALIZAR NOMBRE DE SERVICIO PARA VISUALIZACIÓN
    final servicioNormalizado = servicio
        .replaceAll(RegExp(r'dominical', caseSensitive: false), 'Familiar')
        .replaceAll(RegExp(r'reuni[óo]n general', caseSensitive: false),
            'Servicio Especial');

    final color = _getColorByMinisterio(ministerio);
    final icon = _getIconByMinisterio(ministerio);
    final isOpen = _servicioExpand[groupKey] ?? false;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            onTap: () {
              setState(() {
                _servicioExpand[groupKey] = !isOpen;
              });
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color,
                    color.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 400;

                  return Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(isNarrow ? 6 : 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          icon,
                          color: Colors.white,
                          size: isNarrow ? 18 : 20,
                        ),
                      ),
                      SizedBox(width: isNarrow ? 8 : 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              servicioNormalizado, // ✅ CAMBIADO: era "_displayServiceName(servicio)"
                              style: TextStyle(
                                fontSize: isNarrow ? 14 : 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              ministerio,
                              style: TextStyle(
                                fontSize: isNarrow ? 10 : 12,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isNarrow ? 8 : 10,
                          vertical: isNarrow ? 4 : 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${asistencias.length}',
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: isNarrow ? 12 : 14,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      AnimatedRotation(
                        turns: isOpen ? 0.5 : 0.0,
                        duration: Duration(milliseconds: 200),
                        child: Icon(
                          Icons.expand_more,
                          color: Colors.white,
                          size: isNarrow ? 20 : 24,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: SizedBox.shrink(),
            secondChild: asistencias.isNotEmpty
                ? _buildListaAsistencias(asistencias, color, mostrarAsistencias)
                : _buildMensajeVacio(mostrarAsistencias, false),
            crossFadeState:
                isOpen ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: Duration(milliseconds: 200),
            sizeCurve: Curves.easeInOutCubic,
            firstCurve: Curves.easeOut,
            secondCurve: Curves.easeIn,
          ),
        ],
      ),
    );
  }

  // ========================================
  // FUNCIÓN MODIFICADA: Ahora recibe parámetro mostrarAsistencias
  // Cambia el ícono final (check verde para asistencias, X roja para fallas)
  // ========================================
  Widget _buildListaAsistencias(
    List<Map<String, dynamic>> asistencias,
    Color color,
    bool mostrarAsistencias, // ⬅️ NUEVO PARÁMETRO
  ) {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      addAutomaticKeepAlives: true,
      addRepaintBoundaries: true,
      cacheExtent: 0,
      itemCount: asistencias.length,
      padding: EdgeInsets.symmetric(vertical: 8),
      itemBuilder: (context, index) {
        final asistencia = asistencias[index];
        final nombreMostrado = asistencia['nombreCompleto'] ??
            asistencia['nombre'] ??
            'Sin nombre';
        final inicialNombre = nombreMostrado.toString().isNotEmpty
            ? nombreMostrado.toString()[0].toUpperCase()
            : '?';

        return LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 400;

            return Container(
              margin: EdgeInsets.symmetric(
                vertical: 4,
                horizontal: isNarrow ? 6 : 8,
              ),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: ListTile(
                dense: isNarrow,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: isNarrow ? 8 : 16,
                  vertical: isNarrow ? 4 : 8,
                ),
                leading: Container(
                  width: isNarrow ? 35 : 40,
                  height: isNarrow ? 35 : 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color.withOpacity(0.8),
                        color.withOpacity(0.6),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      inicialNombre,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: isNarrow ? 14 : 16,
                      ),
                    ),
                  ),
                ),
                title: Text(
                  nombreMostrado,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: isNarrow ? 13 : 14,
                    color: Colors.black87,
                  ),
                ),
                subtitle: Row(
                  children: [
                    Icon(
                      Icons.event,
                      size: isNarrow ? 10 : 12,
                      color: Colors.grey[600],
                    ),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        DateFormat('EEEE, d MMM', 'es')
                            .format(asistencia['fecha']),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: isNarrow ? 11 : 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                // ⬅️ MODIFICADO: Ícono diferente según el tipo
                trailing: Container(
                  padding: EdgeInsets.all(isNarrow ? 3 : 4),
                  decoration: BoxDecoration(
                    color: (mostrarAsistencias ? Colors.green : Colors.red)
                        .withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    mostrarAsistencias
                        ? Icons.check_circle_rounded
                        : Icons.cancel_rounded, // ⬅️ X roja para fallas
                    color: mostrarAsistencias ? Colors.green : Colors.red,
                    size: isNarrow ? 18 : 20,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

// ========================================
// FUNCIÓN MODIFICADA: Ahora recibe parámetro adicional
// ========================================
  Widget _buildMensajeVacio(bool mostrarAsistencias, bool isInCenter) {
    final widget = Container(
      padding: EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.grey[400],
            size: 20,
          ),
          SizedBox(width: 10),
          Text(
            mostrarAsistencias
                ? 'No hay asistencias registradas'
                : 'No hay inasistencias registradas',
            style: TextStyle(
              color: Colors.grey[500],
              fontStyle: FontStyle.italic,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );

    if (!isInCenter) return widget;

    return Center(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (mostrarAsistencias
                        ? const Color(0xFF1D8A8A)
                        : const Color(0xFFE74C3C))
                    .withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                mostrarAsistencias ? Icons.event_busy : Icons.person_off,
                size: 64,
                color: mostrarAsistencias
                    ? const Color(0xFF1D8A8A)
                    : const Color(0xFFE74C3C),
              ),
            ),
            SizedBox(height: 16),
            Text(
              mostrarAsistencias
                  ? 'No hay asistencias registradas'
                  : 'No hay inasistencias registradas',
              style: TextStyle(
                fontSize: 18,
                color: mostrarAsistencias
                    ? const Color(0xFF1D8A8A)
                    : const Color(0xFFE74C3C),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              mostrarAsistencias
                  ? 'Los datos de asistencia aparecerán aquí'
                  : 'Los datos de inasistencias aparecerán aquí',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========================================
  // FUNCIÓN MODIFICADA: Ahora recibe parámetro mostrarAsistencias
  // ========================================
  Widget _buildTotalSection(
    Map<String, int> resumen,
    bool mostrarAsistencias,
    Map<String, List<Map<String, dynamic>>> porServicio, // ⬅️ NUEVO parámetro
  ) {
    final totalKey =
        mostrarAsistencias ? 'Total del Fin de Semana' : 'Total de Fallas';
    final totalUnico = resumen[totalKey] ?? 0;

    return Container(
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: mostrarAsistencias
              ? [
                  Colors.white,
                  const Color(0xFF1D8A8A).withOpacity(0.1),
                ]
              : [
                  Colors.white,
                  const Color(0xFFE74C3C)
                      .withOpacity(0.1), // ⬅️ Rojo para fallas
                ],
        ),
        boxShadow: [
          BoxShadow(
            color: (mostrarAsistencias
                    ? const Color(0xFF1D8A8A)
                    : const Color(0xFFE74C3C))
                .withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: (mostrarAsistencias
                  ? const Color(0xFF1D8A8A)
                  : const Color(0xFFE74C3C))
              .withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: mostrarAsistencias
                    ? [
                        const Color(0xFF1D8A8A),
                        const Color(0xFF156D6D),
                      ]
                    : [
                        const Color(0xFFE74C3C),
                        const Color(0xFFC0392B),
                      ],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.summarize_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  mostrarAsistencias
                      ? 'Resumen de Asistencia'
                      : 'Resumen de Inasistencias',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                // ⬅️ NUEVO: Ordenar resumen por fecha real de asistencia
                ...(() {
                  // Filtrar y convertir a lista
                  final resumenList =
                      resumen.entries.where((e) => e.key != totalKey).toList();

                  // Ordenar por fecha real del servicio
                  resumenList.sort((a, b) {
                    // Obtener fecha real del servicio desde porServicio
                    final fechaA = porServicio[a.key]?.isNotEmpty == true
                        ? porServicio[a.key]!.first['fecha'] as DateTime
                        : DateTime.now();
                    final fechaB = porServicio[b.key]?.isNotEmpty == true
                        ? porServicio[b.key]!.first['fecha'] as DateTime
                        : DateTime.now();

                    return fechaA.weekday.compareTo(fechaB.weekday);
                  });

                  // Mapear a widgets
                  return resumenList
                      .map((entry) => _buildTotalRow(
                          entry.key, entry.value, mostrarAsistencias))
                      .toList();
                })(),
                SizedBox(height: 8),
                Divider(
                  height: 24,
                  thickness: 1,
                  color: (mostrarAsistencias
                          ? const Color(0xFF1D8A8A)
                          : const Color(0xFFE74C3C))
                      .withOpacity(0.2),
                ),
                _buildTotalRow(totalKey, totalUnico, mostrarAsistencias,
                    isTotal: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ========================================
  // FUNCIÓN MODIFICADA: Ahora recibe parámetro mostrarAsistencias
  // ========================================
  Widget _buildTotalRow(String label, int count, bool mostrarAsistencias,
      {bool isTotal = false}) {
    final color =
        mostrarAsistencias ? const Color(0xFF1D8A8A) : const Color(0xFFE74C3C);

    return Container(
      margin: EdgeInsets.symmetric(vertical: 4),
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: isTotal ? color.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isTotal
            ? Border.all(color: color.withOpacity(0.3), width: 1)
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
                color: isTotal ? color : Colors.grey[700],
                fontSize: isTotal ? 15 : 14,
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: isTotal
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: mostrarAsistencias
                          ? [
                              const Color(0xFF1D8A8A),
                              const Color(0xFF156D6D),
                            ]
                          : [
                              const Color(0xFFE74C3C),
                              const Color(0xFFC0392B),
                            ],
                    )
                  : null,
              color: isTotal ? null : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              boxShadow: isTotal
                  ? [
                      BoxShadow(
                        color: color.withOpacity(0.2),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      )
                    ]
                  : null,
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isTotal ? Colors.white : Colors.grey[700],
                fontSize: isTotal ? 15 : 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ========================================
  // FUNCIONES AUXILIARES (SIN CAMBIOS)
  // ========================================
  Map<String, Map<String, Map<String, List<Map<String, dynamic>>>>>
      _agruparAsistenciasPorFecha(List<Map<String, dynamic>> asistencias) {
    final Map<String, Map<String, Map<String, List<Map<String, dynamic>>>>>
        agrupadas = {};

    for (var asistencia in asistencias) {
      final fecha = asistencia['fecha'];
      final year = DateFormat('yyyy').format(fecha);
      final month = DateFormat('MMMM').format(fecha);

      final DateTime lunes = _obtenerLunesDeLaSemana(fecha);
      final String semanaKey =
          '${lunes.day}-${_obtenerDomingoDeLaSemana(lunes).day}';

      agrupadas.putIfAbsent(year, () => {});
      agrupadas[year]!.putIfAbsent(month, () => {});
      agrupadas[year]![month]!.putIfAbsent(semanaKey, () => []);
      agrupadas[year]![month]![semanaKey]!.add(asistencia);
    }

    return agrupadas;
  }

  DateTime _obtenerLunesDeLaSemana(DateTime fecha) {
    // Calcular el martes de la semana (nueva lógica)
    // DateTime.tuesday = 2
    int diferencia = fecha.weekday - DateTime.tuesday;

    // Si es lunes (weekday = 1), retroceder 6 días para llegar al martes anterior
    if (fecha.weekday == DateTime.monday) {
      diferencia = 6;
    }

    return fecha.subtract(Duration(days: diferencia));
  }

  DateTime _obtenerDomingoDeLaSemana(DateTime martes) {
    // Ahora el rango es Martes a Lunes (7 días después)
    return martes.add(Duration(days: 6));
  }

  String _formatearRangoSemana(
      String week, List<Map<String, dynamic>> asistencias) {
    if (asistencias.isEmpty) return 'Semana $week';

    // Obtener la fecha real del primer registro
    final fechaInicial = asistencias.first['fecha'] as DateTime;
    final martes = _obtenerLunesDeLaSemana(fechaInicial);
    final lunes = _obtenerDomingoDeLaSemana(martes);

    // Formatear según si cruza meses o no
    if (martes.month == lunes.month) {
      // Mismo mes: "Semana 7-13"
      return 'Semana ${martes.day}-${lunes.day}';
    } else {
      // Meses diferentes: "Semana 28 Oct - 3 Nov"
      final mesMartes = _obtenerMesAbreviado(martes.month);
      final mesLunes = _obtenerMesAbreviado(lunes.month);
      return 'Semana ${martes.day} $mesMartes - ${lunes.day} $mesLunes';
    }
  }

  String _obtenerRangoFechasCompleto(
      String week, List<Map<String, dynamic>> asistencias) {
    if (asistencias.isEmpty) return '';

    final fechaInicial = asistencias.first['fecha'] as DateTime;
    final martes = _obtenerLunesDeLaSemana(fechaInicial);
    final lunes = _obtenerDomingoDeLaSemana(martes);

    // Formato: "1 de octubre - 7 de octubre de 2025"
    if (martes.month == lunes.month) {
      return '${martes.day} - ${lunes.day} de ${_getSpanishMonth(_getNombreMesIngles(martes.month))} ${martes.year}';
    } else {
      return '${martes.day} de ${_getSpanishMonth(_getNombreMesIngles(martes.month))} - ${lunes.day} de ${_getSpanishMonth(_getNombreMesIngles(lunes.month))} ${lunes.year}';
    }
  }

  String _obtenerMesAbreviado(int mes) {
    const meses = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic'
    ];
    return meses[mes - 1];
  }

  String _getNombreMesIngles(int mes) {
    const meses = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return meses[mes - 1];
  }

  String _determinarMinisterio(String nombreServicio) {
    final servicioLower = nombreServicio.toLowerCase();

    if (servicioLower.contains("damas")) return "Ministerio de Damas";
    if (servicioLower.contains("caballeros")) return "Ministerio de Caballeros";
    if (servicioLower.contains("juvenil") || servicioLower.contains("impacto"))
      return "Ministerio Juvenil";

    // ✅ MODIFICADO: Aceptar tanto "familiar" como "dominical"
    if (servicioLower.contains("familiar") ||
        servicioLower.contains("dominical")) return "Servicio Familiar";

    if (servicioLower.contains("poder")) return "Viernes de Poder";

    return "Servicio Especial";
  }

  Color _getColorByMinisterio(String ministerio) {
    switch (ministerio) {
      case "Ministerio de Damas":
        return Color(0xFFFF6B8B);
      case "Ministerio de Caballeros":
        return Color(0xFF3498DB);
      case "Ministerio Juvenil":
        return Color(0xFFF5A623);
      case "Servicio Familiar":
        return Color(0xFF2ECC71);
      case "Viernes de Poder":
        return Color(0xFF1D8A8A);
      default:
        return Color(0xFF9B59B6);
    }
  }

  IconData _getIconByMinisterio(String ministerio) {
    switch (ministerio) {
      case "Ministerio de Damas":
        return Icons.volunteer_activism;
      case "Ministerio de Caballeros":
        return Icons.fitness_center;
      case "Ministerio Juvenil":
        return Icons.emoji_people;
      case "Servicio Familiar":
        return Icons.family_restroom;
      case "Viernes de Poder":
        return Icons.local_fire_department;
      default:
        return Icons.star_border_rounded;
    }
  }

  IconData _getMonthIcon(String month) {
    switch (month) {
      case 'January':
        return Icons.ac_unit;
      case 'February':
        return Icons.favorite;
      case 'March':
        return Icons.eco;
      case 'April':
        return Icons.water_drop;
      case 'May':
        return Icons.local_florist;
      case 'June':
        return Icons.wb_sunny;
      case 'July':
        return Icons.beach_access;
      case 'August':
        return Icons.waves;
      case 'September':
        return Icons.school;
      case 'October':
        return Icons.theater_comedy;
      case 'November':
        return Icons.savings;
      case 'December':
        return Icons.celebration;
      default:
        return Icons.calendar_month;
    }
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

  int _monthToNumber(String m) {
    final key = m.toLowerCase().trim();

    const es = {
      'enero': 1,
      'febrero': 2,
      'marzo': 3,
      'abril': 4,
      'mayo': 5,
      'junio': 6,
      'julio': 7,
      'agosto': 8,
      'septiembre': 9,
      'octubre': 10,
      'noviembre': 11,
      'diciembre': 12
    };

    const en = {
      'january': 1,
      'february': 2,
      'march': 3,
      'april': 4,
      'may': 5,
      'june': 6,
      'july': 7,
      'august': 8,
      'september': 9,
      'october': 10,
      'november': 11,
      'december': 12
    };

    return es[key] ?? en[key] ?? 13;
  }
}

//-------------------------------
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

    bool _isProcessing = false;
    bool _passwordVisible = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 10,
              child: Container(
                constraints: BoxConstraints(maxWidth: 500, maxHeight: 680),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white,
                      ThemeConstants.primaryTeal.withOpacity(0.02),
                    ],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header con degradado
                    Container(
                      padding: EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            ThemeConstants.primaryTeal,
                            ThemeConstants.primaryTeal.withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: ThemeConstants.primaryTeal.withOpacity(0.3),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              Icons.supervisor_account,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Nuevo Coordinador',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'Completa los datos del coordinador',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Contenido con scroll
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(24),
                        child: Column(
                          children: [
                            _buildTextField(
                              controller: _nameController,
                              label: 'Nombre',
                              icon: Icons.person_outline,
                              hint: 'Ingresa el nombre',
                            ),
                            SizedBox(height: 16),
                            _buildTextField(
                              controller: _lastNameController,
                              label: 'Apellido',
                              icon: Icons.person,
                              hint: 'Ingresa el apellido',
                            ),
                            SizedBox(height: 16),
                            _buildTextField(
                              controller: _ageController,
                              label: 'Edad',
                              icon: Icons.cake,
                              keyboardType: TextInputType.number,
                              hint: 'Ej: 25',
                            ),
                            SizedBox(height: 16),
                            _buildTextField(
                              controller: _phoneController,
                              label: 'Teléfono',
                              icon: Icons.phone,
                              keyboardType: TextInputType.phone,
                              hint: '+57 300 123 4567',
                              formatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'^\+?[0-9]*$')),
                              ],
                              onChanged: (value) {
                                if (!value.startsWith('+57') &&
                                    value.isNotEmpty) {
                                  String newValue =
                                      '+57${value.replaceAll('+57', '')}';
                                  _phoneController.value = TextEditingValue(
                                    text: newValue,
                                    selection: TextSelection.collapsed(
                                        offset: newValue.length),
                                  );
                                }
                              },
                            ),
                            SizedBox(height: 16),
                            _buildTextField(
                              controller: _userController,
                              label: 'Usuario',
                              icon: Icons.account_circle,
                              hint: 'Nombre de usuario',
                            ),
                            SizedBox(height: 16),
                            StatefulBuilder(
                              builder: (context, setPassState) {
                                return _buildTextField(
                                  controller: _passwordController,
                                  label: 'Contraseña',
                                  icon: Icons.lock_outline,
                                  isPassword: !_passwordVisible,
                                  hint: 'Mínimo 6 caracteres',
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _passwordVisible
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: ThemeConstants.primaryTeal,
                                    ),
                                    onPressed: () {
                                      setPassState(() {
                                        _passwordVisible = !_passwordVisible;
                                      });
                                    },
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Footer con botones
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(24),
                          bottomRight: Radius.circular(24),
                        ),
                        border: Border(
                          top: BorderSide(color: Colors.grey.shade200),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _isProcessing
                                  ? null
                                  : () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                side: BorderSide(
                                  color: ThemeConstants.accentGrey,
                                  width: 2,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Cancelar',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: ThemeConstants.accentGrey,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: _isProcessing
                                  ? null
                                  : () async {
                                      if (_isProcessing) return;

                                      setState(() {
                                        _isProcessing = true;
                                      });

                                      try {
                                        if (_validateFields(
                                            _nameController.text,
                                            _lastNameController.text,
                                            _ageController.text,
                                            _phoneController.text,
                                            _userController.text,
                                            _passwordController.text)) {
                                          await FirebaseFirestore.instance
                                              .collection('coordinadores')
                                              .add({
                                            'nombre':
                                                _nameController.text.trim(),
                                            'apellido':
                                                _lastNameController.text.trim(),
                                            'edad': int.tryParse(
                                                    _ageController.text) ??
                                                0,
                                            'telefono':
                                                _phoneController.text.trim(),
                                            'usuario':
                                                _userController.text.trim(),
                                            'contrasena':
                                                _passwordController.text,
                                            'tribuId': tribuId,
                                          });

                                          Navigator.pop(context);

                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Row(
                                                  children: [
                                                    Icon(Icons.check_circle,
                                                        color: Colors.white),
                                                    SizedBox(width: 12),
                                                    Text(
                                                        'Coordinador creado exitosamente'),
                                                  ],
                                                ),
                                                backgroundColor: Colors.green,
                                                behavior:
                                                    SnackBarBehavior.floating,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                              ),
                                            );
                                          }
                                        } else {
                                          if (context.mounted) {
                                            String errorMessage =
                                                'Error de validación:\n';

                                            if (_nameController.text
                                                .trim()
                                                .isEmpty)
                                              errorMessage +=
                                                  '• Nombre es requerido\n';
                                            if (_lastNameController.text
                                                .trim()
                                                .isEmpty)
                                              errorMessage +=
                                                  '• Apellido es requerido\n';
                                            if (_ageController.text
                                                .trim()
                                                .isEmpty)
                                              errorMessage +=
                                                  '• Edad es requerida\n';
                                            else {
                                              final ageInt = int.tryParse(
                                                  _ageController.text.trim());
                                              if (ageInt == null ||
                                                  ageInt <= 0 ||
                                                  ageInt > 120) {
                                                errorMessage +=
                                                    '• Edad debe ser un número entre 1 y 120\n';
                                              }
                                            }
                                            if (_phoneController.text
                                                .trim()
                                                .isEmpty)
                                              errorMessage +=
                                                  '• Teléfono es requerido\n';
                                            else if (!RegExp(r'^\+57[0-9]{10}$')
                                                .hasMatch(_phoneController.text
                                                    .trim())) {
                                              errorMessage +=
                                                  '• Teléfono debe tener formato +57XXXXXXXXXX\n';
                                            }
                                            if (_userController.text
                                                .trim()
                                                .isEmpty)
                                              errorMessage +=
                                                  '• Usuario es requerido\n';
                                            else if (_userController.text
                                                    .trim()
                                                    .length <
                                                3) {
                                              errorMessage +=
                                                  '• Usuario debe tener al menos 3 caracteres\n';
                                            }
                                            if (_passwordController.text
                                                .trim()
                                                .isEmpty)
                                              errorMessage +=
                                                  '• Contraseña es requerida\n';
                                            else if (_passwordController.text
                                                    .trim()
                                                    .length <
                                                6) {
                                              errorMessage +=
                                                  '• Contraseña debe tener al menos 6 caracteres\n';
                                            }

                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content:
                                                    Text(errorMessage.trim()),
                                                backgroundColor: Colors.red,
                                                duration: Duration(seconds: 4),
                                                behavior:
                                                    SnackBarBehavior.floating,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                              ),
                                            );
                                          }
                                        }
                                      } catch (e) {
                                        print('Error al crear coordinador: $e');
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                  'Error al crear coordinador: $e'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      } finally {
                                        setState(() {
                                          _isProcessing = false;
                                        });
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: ThemeConstants.secondaryOrange,
                                padding: EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                              child: _isProcessing
                                  ? SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.white),
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.save, size: 20),
                                        SizedBox(width: 8),
                                        Text(
                                          'Guardar',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
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
    String? hint,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 14,
          ),
          labelStyle: TextStyle(
            color: ThemeConstants.primaryTeal,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Container(
            margin: EdgeInsets.all(12),
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  ThemeConstants.primaryTeal.withOpacity(0.1),
                  ThemeConstants.primaryTeal.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: ThemeConstants.primaryTeal,
              size: 20,
            ),
          ),
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Colors.grey.shade300,
              width: 1.5,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Colors.grey.shade300,
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: ThemeConstants.primaryTeal,
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Colors.red.shade400,
              width: 2,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Colors.red.shade400,
              width: 2,
            ),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        obscureText: isPassword,
        keyboardType: keyboardType,
        inputFormatters: formatters,
        onChanged: onChanged,
        style: TextStyle(
          fontSize: 15,
          color: Colors.grey.shade800,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  bool _validateFields(String name, String lastName, String age, String phone,
      String user, String password) {
    // Validaciones básicas - campos requeridos
    if (name.trim().isEmpty ||
        lastName.trim().isEmpty ||
        age.trim().isEmpty ||
        phone.trim().isEmpty ||
        user.trim().isEmpty ||
        password.trim().isEmpty) {
      return false;
    }

    // Validar edad (debe ser un número válido entre 1 y 120)
    final ageInt = int.tryParse(age.trim());
    if (ageInt == null || ageInt <= 0 || ageInt > 120) {
      return false;
    }

    // Validar teléfono (debe empezar con +57 y tener exactamente 10 dígitos después)
    final phoneRegex = RegExp(r'^\+57[0-9]{10}$');
    if (!phoneRegex.hasMatch(phone.trim())) {
      return false;
    }

    // Validar que el usuario tenga al menos 3 caracteres
    if (user.trim().length < 3) {
      return false;
    }

    // Validar que la contraseña tenga al menos 6 caracteres
    if (password.trim().length < 6) {
      return false;
    }

    return true;
  }

  Future<void> _editarCoordinador(
      BuildContext context, DocumentSnapshot coordinador) async {
    final nombreController = TextEditingController(text: coordinador['nombre']);
    final apellidoController =
        TextEditingController(text: coordinador['apellido']);
    final usuarioController =
        TextEditingController(text: coordinador['usuario']);
    final contrasenaController = TextEditingController();

    bool _isProcessing = false;
    bool _passwordVisible = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            elevation: 10,
            child: Container(
              constraints: BoxConstraints(maxWidth: 500, maxHeight: 580),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    ThemeConstants.secondaryOrange.withOpacity(0.02),
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header con gradiente
                  Container(
                    padding: EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          ThemeConstants.secondaryOrange,
                          ThemeConstants.secondaryOrange.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                              ThemeConstants.secondaryOrange.withOpacity(0.3),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Editar Coordinador',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Actualiza los datos del coordinador',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Contenido con scroll
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        children: [
                          _buildTextField(
                            controller: nombreController,
                            label: 'Nombre',
                            icon: Icons.person_outline,
                            hint: 'Ingresa el nombre',
                          ),
                          SizedBox(height: 16),
                          _buildTextField(
                            controller: apellidoController,
                            label: 'Apellido',
                            icon: Icons.person,
                            hint: 'Ingresa el apellido',
                          ),
                          SizedBox(height: 16),
                          _buildTextField(
                            controller: usuarioController,
                            label: 'Usuario',
                            icon: Icons.account_circle,
                            hint: 'Nombre de usuario',
                          ),
                          SizedBox(height: 16),
                          StatefulBuilder(
                            builder: (context, setPassState) {
                              return _buildTextField(
                                controller: contrasenaController,
                                label: 'Nueva Contraseña (opcional)',
                                icon: Icons.lock_outline,
                                isPassword: !_passwordVisible,
                                hint: 'Dejar vacío para mantener la actual',
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _passwordVisible
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: ThemeConstants.secondaryOrange,
                                  ),
                                  onPressed: () {
                                    setPassState(() {
                                      _passwordVisible = !_passwordVisible;
                                    });
                                  },
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Footer con botones
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(24),
                        bottomRight: Radius.circular(24),
                      ),
                      border: Border(
                        top: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isProcessing
                                ? null
                                : () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              side: BorderSide(
                                color: ThemeConstants.accentGrey,
                                width: 2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Cancelar',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: ThemeConstants.accentGrey,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: _isProcessing
                                ? null
                                : () async {
                                    if (_isProcessing) return;

                                    setState(() {
                                      _isProcessing = true;
                                    });

                                    try {
                                      final Map<String, dynamic>
                                          datosActualizados = {
                                        'nombre': nombreController.text.trim(),
                                        'apellido':
                                            apellidoController.text.trim(),
                                        'usuario':
                                            usuarioController.text.trim(),
                                      };

                                      if (contrasenaController.text
                                          .trim()
                                          .isNotEmpty) {
                                        datosActualizados['contrasena'] =
                                            contrasenaController.text.trim();
                                      }

                                      await FirebaseFirestore.instance
                                          .collection('coordinadores')
                                          .doc(coordinador.id)
                                          .update(datosActualizados);

                                      Navigator.pop(context);

                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Row(
                                              children: [
                                                Icon(Icons.check_circle,
                                                    color: Colors.white),
                                                SizedBox(width: 12),
                                                Text(
                                                    'Coordinador actualizado exitosamente'),
                                              ],
                                            ),
                                            backgroundColor: Colors.green,
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      print(
                                          'Error al actualizar coordinador: $e');
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                'Error al actualizar coordinador: $e'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    } finally {
                                      setState(() {
                                        _isProcessing = false;
                                      });
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ThemeConstants.secondaryOrange,
                              padding: EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            child: _isProcessing
                                ? SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.save, size: 20),
                                      SizedBox(width: 8),
                                      Text(
                                        'Guardar Cambios',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 10,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white,
                  ThemeConstants.primaryTeal.withOpacity(0.02),
                ],
              ),
            ),
            child: Column(
              children: [
                // Header personalizado
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        ThemeConstants.primaryTeal,
                        ThemeConstants.primaryTeal.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: ThemeConstants.primaryTeal.withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.groups,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Timoteos Asignados',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              '${coordinador['nombre']} ${coordinador['apellido']}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => Navigator.pop(context),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Contenido con lista de timoteos
                Expanded(
                  child: StreamBuilder(
                    stream: FirebaseFirestore.instance
                        .collection('timoteos')
                        .where('coordinadorId', isEqualTo: coordinador.id)
                        .snapshots(),
                    builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                color: ThemeConstants.primaryTeal,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Cargando timoteos...',
                                style: TextStyle(
                                  color: ThemeConstants.accentGrey,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: ThemeConstants.primaryTeal
                                      .withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.person_off,
                                  size: 64,
                                  color: ThemeConstants.primaryTeal
                                      .withOpacity(0.5),
                                ),
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No hay timoteos asignados',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: ThemeConstants.accentGrey,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Este coordinador no tiene timoteos',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: ThemeConstants.accentGrey
                                      .withOpacity(0.7),
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
                          return Container(
                            margin: EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white,
                                  ThemeConstants.primaryTeal.withOpacity(0.03),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                              border: Border.all(
                                color:
                                    ThemeConstants.primaryTeal.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: ListTile(
                              contentPadding: EdgeInsets.all(16),
                              leading: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      ThemeConstants.primaryTeal,
                                      ThemeConstants.primaryTeal
                                          .withOpacity(0.7),
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: ThemeConstants.primaryTeal
                                          .withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    '${timoteo['nombre'][0]}${timoteo['apellido'][0]}'
                                        .toUpperCase(),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                              ),
                              title: Text(
                                '${timoteo['nombre']} ${timoteo['apellido']}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.account_circle,
                                        size: 16,
                                        color: ThemeConstants.accentGrey,
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        'Usuario: ${timoteo['usuario']}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: ThemeConstants.accentGrey,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.lock_outline,
                                        size: 16,
                                        color: ThemeConstants.accentGrey,
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        'Contraseña: ${timoteo['contrasena']}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: ThemeConstants.accentGrey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                        title: Row(
                                          children: [
                                            Icon(
                                              Icons.warning_amber_rounded,
                                              color: Colors.orange,
                                            ),
                                            SizedBox(width: 12),
                                            Text('Confirmar'),
                                          ],
                                        ),
                                        content: Text(
                                          '¿Desasignar este timoteo del coordinador?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            child: Text('Cancelar'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red,
                                            ),
                                            child: Text('Desasignar'),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirm == true) {
                                      await FirebaseFirestore.instance
                                          .collection('timoteos')
                                          .doc(timoteo.id)
                                          .update({
                                        'coordinadorId': null,
                                        'nombreCoordinador': null,
                                      });

                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                'Timoteo desasignado correctamente'),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      }
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.person_remove,
                                      color: Colors.red,
                                      size: 24,
                                    ),
                                  ),
                                ),
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
          ),
        );
      },
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
            Colors.white,
            ThemeConstants.primaryTeal.withOpacity(0.03),
          ],
        ),
      ),
      child: Column(
        children: [
          // Botón de crear coordinador mejorado
          Container(
            width: double.infinity,
            margin: EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  ThemeConstants.secondaryOrange,
                  ThemeConstants.secondaryOrange.withOpacity(0.8),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: ThemeConstants.secondaryOrange.withOpacity(0.3),
                  blurRadius: 12,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _crearCoordinador(context),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.group_add,
                          size: 26,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Crear Coordinador',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Lista de coordinadores
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('coordinadores')
                  .where('tribuId', isEqualTo: tribuId)
                  .snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: ThemeConstants.primaryTeal.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: CircularProgressIndicator(
                            color: ThemeConstants.primaryTeal,
                            strokeWidth: 3,
                          ),
                        ),
                        SizedBox(height: 20),
                        Text(
                          'Cargando coordinadores...',
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

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: ThemeConstants.accentGrey.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.groups,
                            size: 80,
                            color: ThemeConstants.accentGrey.withOpacity(0.5),
                          ),
                        ),
                        SizedBox(height: 24),
                        Text(
                          'No hay coordinadores registrados',
                          style: TextStyle(
                            fontSize: 20,
                            color: ThemeConstants.accentGrey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Presiona el botón superior para crear uno',
                          style: TextStyle(
                            fontSize: 14,
                            color: ThemeConstants.accentGrey.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final coordinador = snapshot.data!.docs[index];
                    final iniciales =
                        '${coordinador['nombre'][0]}${coordinador['apellido'][0]}'
                            .toUpperCase();

                    return Container(
                      margin: EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white,
                            ThemeConstants.primaryTeal.withOpacity(0.03),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                        border: Border.all(
                          color: ThemeConstants.primaryTeal.withOpacity(0.15),
                          width: 1,
                        ),
                      ),
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          dividerColor: Colors.transparent,
                        ),
                        child: ExpansionTile(
                          tilePadding: EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          childrenPadding: EdgeInsets.all(0),
                          leading: Hero(
                            tag: 'coordinador_${coordinador.id}',
                            child: Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    ThemeConstants.primaryTeal,
                                    ThemeConstants.primaryTeal.withOpacity(0.7),
                                  ],
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: ThemeConstants.primaryTeal
                                        .withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  iniciales,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          title: Text(
                            '${coordinador['nombre']} ${coordinador['apellido']}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: ThemeConstants.primaryTeal,
                              fontSize: 17,
                            ),
                          ),
                          subtitle: Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.cake,
                                  size: 14,
                                  color: ThemeConstants.accentGrey,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  '${coordinador['edad']} años',
                                  style: TextStyle(
                                    color: ThemeConstants.accentGrey,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          trailing: Icon(
                            Icons.expand_more,
                            color: ThemeConstants.primaryTeal,
                          ),
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.circular(20),
                                  bottomRight: Radius.circular(20),
                                ),
                              ),
                              padding: EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildInfoRow(Icons.phone, 'Teléfono',
                                      coordinador['telefono']),
                                  SizedBox(height: 12),
                                  _buildInfoRow(Icons.person, 'Usuario',
                                      coordinador['usuario']),
                                  SizedBox(height: 12),
                                  _buildInfoRow(Icons.lock, 'Contraseña',
                                      coordinador['contrasena']),
                                  SizedBox(height: 20),
                                  Divider(
                                      height: 1, color: Colors.grey.shade300),
                                  SizedBox(height: 16),
                                  // Botones de acción mejorados
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    alignment: WrapAlignment.center,
                                    children: [
                                      _buildActionButton(
                                        icon: Icons.edit,
                                        label: 'Editar',
                                        color: ThemeConstants.primaryTeal,
                                        onPressed: () => _editarCoordinador(
                                            context, coordinador),
                                      ),
                                      _buildActionButton(
                                        icon: Icons.group,
                                        label: 'Timoteos',
                                        color: ThemeConstants.secondaryOrange,
                                        onPressed: () => _verTimoteosAsignados(
                                            context, coordinador),
                                      ),
                                      _buildActionButton(
                                        icon: Icons.arrow_forward,
                                        label: 'Ver más',
                                        color: Colors.blue,
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
                                      _buildActionButton(
                                        icon: Icons.delete,
                                        label: 'Eliminar',
                                        color: Colors.red,
                                        onPressed: () => _eliminarCoordinador(
                                            context, coordinador),
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
        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    double fontSize = 14,
    double iconSize = 20,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color,
            color.withOpacity(0.8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: padding,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: Colors.white,
                  size: iconSize,
                ),
                if (label.isNotEmpty) ...[
                  SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: fontSize,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
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

    bool _isProcessing = false;
    bool _passwordVisible = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          // Responsive measurements
          final screenWidth = MediaQuery.of(context).size.width;
          final screenHeight = MediaQuery.of(context).size.height;
          final isSmallScreen = screenWidth < 600;
          final isMediumScreen = screenWidth >= 600 && screenWidth < 900;

          final dialogWidth = isSmallScreen
              ? screenWidth * 0.9
              : (isMediumScreen ? 500.0 : 550.0);
          final dialogMaxHeight = screenHeight * 0.85;

          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(isSmallScreen ? 20 : 24),
            ),
            elevation: 10,
            child: Container(
              width: dialogWidth,
              constraints: BoxConstraints(
                maxHeight: dialogMaxHeight,
                maxWidth: dialogWidth,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(isSmallScreen ? 20 : 24),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    ThemeConstants.primaryTeal.withOpacity(0.02),
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header con gradiente
                  Container(
                    padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          ThemeConstants.primaryTeal,
                          ThemeConstants.primaryTeal.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(isSmallScreen ? 20 : 24),
                        topRight: Radius.circular(isSmallScreen ? 20 : 24),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: ThemeConstants.primaryTeal.withOpacity(0.3),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius:
                                BorderRadius.circular(isSmallScreen ? 12 : 16),
                          ),
                          child: Icon(
                            Icons.edit_note,
                            color: Colors.white,
                            size: isSmallScreen ? 24 : 28,
                          ),
                        ),
                        SizedBox(width: isSmallScreen ? 12 : 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Editar Timoteo',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 18 : 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              if (!isSmallScreen)
                                Text(
                                  'Actualiza la información del timoteo',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _isProcessing
                                ? null
                                : () => Navigator.pop(context),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.close,
                                color: Colors.white,
                                size: isSmallScreen ? 20 : 22,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Contenido con scroll
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
                      child: Column(
                        children: [
                          _buildResponsiveTextField(
                            controller: nombreController,
                            label: 'Nombre',
                            icon: Icons.person_outline,
                            hint: 'Ingresa el nombre',
                            isSmallScreen: isSmallScreen,
                          ),
                          SizedBox(height: isSmallScreen ? 12 : 16),
                          _buildResponsiveTextField(
                            controller: apellidoController,
                            label: 'Apellido',
                            icon: Icons.person,
                            hint: 'Ingresa el apellido',
                            isSmallScreen: isSmallScreen,
                          ),
                          SizedBox(height: isSmallScreen ? 12 : 16),
                          _buildResponsiveTextField(
                            controller: usuarioController,
                            label: 'Usuario',
                            icon: Icons.account_circle,
                            hint: 'Nombre de usuario',
                            isSmallScreen: isSmallScreen,
                          ),
                          SizedBox(height: isSmallScreen ? 12 : 16),
                          _buildResponsiveTextField(
                            controller: contrasenaController,
                            label: 'Nueva Contraseña (opcional)',
                            icon: Icons.lock_outline,
                            isPassword: !_passwordVisible,
                            hint: 'Dejar vacío para mantener la actual',
                            isSmallScreen: isSmallScreen,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _passwordVisible
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: ThemeConstants.primaryTeal,
                                size: isSmallScreen ? 20 : 22,
                              ),
                              onPressed: () {
                                setState(() {
                                  _passwordVisible = !_passwordVisible;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Footer con botones
                  Container(
                    padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(isSmallScreen ? 20 : 24),
                        bottomRight: Radius.circular(isSmallScreen ? 20 : 24),
                      ),
                      border: Border(
                        top: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                    child: isSmallScreen
                        ? Column(
                            children: [
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isProcessing
                                      ? null
                                      : () async {
                                          if (_isProcessing) return;

                                          setState(() {
                                            _isProcessing = true;
                                          });

                                          try {
                                            final Map<String, dynamic>
                                                datosActualizados = {
                                              'nombre':
                                                  nombreController.text.trim(),
                                              'apellido': apellidoController
                                                  .text
                                                  .trim(),
                                              'usuario':
                                                  usuarioController.text.trim(),
                                            };

                                            if (contrasenaController.text
                                                .trim()
                                                .isNotEmpty) {
                                              datosActualizados['contrasena'] =
                                                  contrasenaController.text
                                                      .trim();
                                            }

                                            await FirebaseFirestore.instance
                                                .collection('timoteos')
                                                .doc(timoteo.id)
                                                .update(datosActualizados);

                                            Navigator.pop(context);

                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Row(
                                                    children: [
                                                      Icon(Icons.check_circle,
                                                          color: Colors.white),
                                                      SizedBox(width: 12),
                                                      Expanded(
                                                        child: Text(
                                                          'Timoteo actualizado exitosamente',
                                                          style: TextStyle(
                                                              fontSize: 14),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  backgroundColor: Colors.green,
                                                  behavior:
                                                      SnackBarBehavior.floating,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                  ),
                                                ),
                                              );
                                            }
                                          } catch (e) {
                                            print(
                                                'Error al actualizar timoteo: $e');
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                      'Error al actualizar: $e'),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                            }
                                          } finally {
                                            setState(() {
                                              _isProcessing = false;
                                            });
                                          }
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: ThemeConstants.primaryTeal,
                                    padding: EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 2,
                                  ),
                                  child: _isProcessing
                                      ? SizedBox(
                                          height: 18,
                                          width: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Colors.white),
                                          ),
                                        )
                                      : Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.save, size: 18),
                                            SizedBox(width: 8),
                                            Text(
                                              'Guardar Cambios',
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                              SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: _isProcessing
                                      ? null
                                      : () => Navigator.pop(context),
                                  style: OutlinedButton.styleFrom(
                                    padding: EdgeInsets.symmetric(vertical: 14),
                                    side: BorderSide(
                                      color: ThemeConstants.accentGrey,
                                      width: 2,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    'Cancelar',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: ThemeConstants.accentGrey,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _isProcessing
                                      ? null
                                      : () => Navigator.pop(context),
                                  style: OutlinedButton.styleFrom(
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    side: BorderSide(
                                      color: ThemeConstants.accentGrey,
                                      width: 2,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    'Cancelar',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: ThemeConstants.accentGrey,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: ElevatedButton(
                                  onPressed: _isProcessing
                                      ? null
                                      : () async {
                                          if (_isProcessing) return;

                                          setState(() {
                                            _isProcessing = true;
                                          });

                                          try {
                                            final Map<String, dynamic>
                                                datosActualizados = {
                                              'nombre':
                                                  nombreController.text.trim(),
                                              'apellido': apellidoController
                                                  .text
                                                  .trim(),
                                              'usuario':
                                                  usuarioController.text.trim(),
                                            };

                                            if (contrasenaController.text
                                                .trim()
                                                .isNotEmpty) {
                                              datosActualizados['contrasena'] =
                                                  contrasenaController.text
                                                      .trim();
                                            }

                                            await FirebaseFirestore.instance
                                                .collection('timoteos')
                                                .doc(timoteo.id)
                                                .update(datosActualizados);

                                            Navigator.pop(context);

                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Row(
                                                    children: [
                                                      Icon(Icons.check_circle,
                                                          color: Colors.white),
                                                      SizedBox(width: 12),
                                                      Text(
                                                          'Timoteo actualizado exitosamente'),
                                                    ],
                                                  ),
                                                  backgroundColor: Colors.green,
                                                  behavior:
                                                      SnackBarBehavior.floating,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                  ),
                                                ),
                                              );
                                            }
                                          } catch (e) {
                                            print(
                                                'Error al actualizar timoteo: $e');
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                      'Error al actualizar timoteo: $e'),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                            }
                                          } finally {
                                            setState(() {
                                              _isProcessing = false;
                                            });
                                          }
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: ThemeConstants.primaryTeal,
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 2,
                                  ),
                                  child: _isProcessing
                                      ? SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Colors.white),
                                          ),
                                        )
                                      : Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.save, size: 20),
                                            SizedBox(width: 8),
                                            Text(
                                              'Guardar Cambios',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Widget helper para campos de texto responsive
  Widget _buildResponsiveTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    String? hint,
    Widget? suffixIcon,
    required bool isSmallScreen,
  }) {
    final iconSize = isSmallScreen ? 18.0 : 20.0;
    final fontSize = isSmallScreen ? 14.0 : 15.0;
    final labelSize = isSmallScreen ? 13.0 : 14.0;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        style: TextStyle(
          fontSize: fontSize,
          color: Colors.grey.shade800,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.grey.shade400,
            fontSize: labelSize,
          ),
          labelStyle: TextStyle(
            color: ThemeConstants.primaryTeal,
            fontWeight: FontWeight.w500,
            fontSize: labelSize,
          ),
          prefixIcon: Container(
            margin: EdgeInsets.all(isSmallScreen ? 10 : 12),
            padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  ThemeConstants.primaryTeal.withOpacity(0.1),
                  ThemeConstants.primaryTeal.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: ThemeConstants.primaryTeal,
              size: iconSize,
            ),
          ),
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Colors.grey.shade300,
              width: 1.5,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Colors.grey.shade300,
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: ThemeConstants.primaryTeal,
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Colors.red.shade400,
              width: 2,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Colors.red.shade400,
              width: 2,
            ),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 12 : 16,
            vertical: isSmallScreen ? 14 : 16,
          ),
        ),
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

                // ✅ CAMBIO: Ya no filtramos, mostramos todos los timoteos
                final docs = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final timoteo = docs[index];
                    // ✅ Verificar si está asignado a un coordinador
                    final bool estaAsignado =
                        timoteo.data().toString().contains('coordinadorId') &&
                            timoteo.get('coordinadorId') != null;

                    return Card(
                      elevation: 3,
                      margin: EdgeInsets.symmetric(vertical: 8),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          // ✅ CAMBIO: Borde diferente según estado de asignación
                          border: Border.all(
                            color: estaAsignado
                                ? ThemeConstants.secondaryOrange
                                    .withOpacity(0.5)
                                : ThemeConstants.primaryTeal.withOpacity(0.3),
                            width: estaAsignado ? 2 : 1,
                          ),
                          // ✅ Fondo ligeramente diferente si está asignado
                          color: estaAsignado
                              ? ThemeConstants.secondaryOrange.withOpacity(0.05)
                              : Colors.white,
                        ),
                        child: ExpansionTile(
                          leading: CircleAvatar(
                            // ✅ Color diferente del avatar según estado
                            backgroundColor: estaAsignado
                                ? ThemeConstants.secondaryOrange
                                : ThemeConstants.primaryTeal,
                            child: Text(
                              '${timoteo['nombre'][0]}${timoteo['apellido'][0]}',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${timoteo['nombre']} ${timoteo['apellido']}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: estaAsignado
                                        ? ThemeConstants.secondaryOrange
                                        : ThemeConstants.primaryTeal,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              // ✅ Indicador visual si está asignado
                              if (estaAsignado)
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: ThemeConstants.secondaryOrange
                                        .withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: ThemeConstants.secondaryOrange,
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        size: 14,
                                        color: ThemeConstants.secondaryOrange,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'Asignado',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: ThemeConstants.secondaryOrange,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          // ✅ Mostrar coordinador asignado como subtitle si existe
                          subtitle: estaAsignado
                              ? Padding(
                                  padding: EdgeInsets.only(top: 4),
                                  child: Text(
                                    'Coordinador: ${timoteo['nombreCoordinador'] ?? 'Sin nombre'}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: ThemeConstants.accentGrey,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                )
                              : null,
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
                                  // ✅ Mostrar info del coordinador si está asignado
                                  if (estaAsignado) ...[
                                    SizedBox(height: 8),
                                    _buildInfoRow(
                                      Icons.supervisor_account,
                                      'Coordinador',
                                      timoteo['nombreCoordinador'] ??
                                          'Sin asignar',
                                    ),
                                  ],
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
                                          estaAsignado
                                              ? Icons.person_remove
                                              : Icons.person_add,
                                          color: ThemeConstants.secondaryOrange,
                                        ),
                                        tooltip: estaAsignado
                                            ? 'Reasignar Coordinador'
                                            : 'Asignar a Coordinador',
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

//--Clase de la pestaña de Personas
class RegistrosAsignadosTab extends StatefulWidget {
  final String tribuId;
  final String tribuNombre;

  const RegistrosAsignadosTab({
    Key? key,
    required this.tribuId,
    required this.tribuNombre,
  }) : super(key: key);

  @override
  State<RegistrosAsignadosTab> createState() => _RegistrosAsignadosTabState();
}

class _RegistrosAsignadosTabState extends State<RegistrosAsignadosTab> {
  final TextEditingController _searchController = TextEditingController();

// ✅ NUEVO: Variable de estado para el término de búsqueda
  String _searchTerm = '';

// ✅ NUEVO: FocusNode para controlar el foco del campo de texto
  final FocusNode _searchFocusNode = FocusNode();

// ✅ NUEVO: Variables para filtros de fecha
  String? _anioSeleccionado;
  String? _mesSeleccionado;
  List<String> _aniosDisponibles = [];
  bool _cargandoAnios = false;

// ✅ AGREGADO: Variables para el nuevo filtro de Estado en la Iglesia
  String _tipoBusqueda = 'nombre'; // 'nombre' o 'estado'
  final TextEditingController _searchEstadoController = TextEditingController();
  String _searchEstadoTerm = '';
  final FocusNode _searchEstadoFocusNode = FocusNode();

// 🆕 NUEVA VARIABLE: Control de expansión del panel de filtros
  bool _filtrosExpandidos = false;

  @override
  void initState() {
    super.initState();
    // ✅ NUEVO: Listener para actualizar el término de búsqueda en tiempo real
    _searchController.addListener(() {
      setState(() {
        _searchTerm = _searchController.text.toLowerCase();
      });
    });

    // ✅ AGREGADO: Listener para búsqueda por estado
    _searchEstadoController.addListener(() {
      setState(() {
        _searchEstadoTerm = _searchEstadoController.text.toLowerCase();
      });
    });

    // ✅ NUEVO: Cargar años disponibles
    _cargarAniosDisponibles();
  }

  @override
  void dispose() {
    // ✅ NUEVO: Limpieza de recursos
    _searchController.dispose();
    _searchFocusNode.dispose();
    // ✅ AGREGADO: Limpieza de recursos del nuevo controlador
    _searchEstadoController.dispose();
    _searchEstadoFocusNode.dispose();
    super.dispose();
  }

// ✅ NUEVO: Método para cargar años disponibles
  Future<void> _cargarAniosDisponibles() async {
    setState(() {
      _cargandoAnios = true;
    });

    try {
      final registrosSnapshot = await FirebaseFirestore.instance
          .collection('registros')
          .where('tribuAsignada', isEqualTo: widget.tribuId)
          .get();

      Set<String> aniosSet = {};

      for (var doc in registrosSnapshot.docs) {
        final data = doc.data();

        // Buscar en múltiples campos de fecha
        final fechaTribu = data['fechaAsignacionTribu'] as Timestamp?;
        final fechaAsignacion = data['fechaAsignacion'] as Timestamp?;

        DateTime? fecha;
        if (fechaTribu != null) {
          fecha = fechaTribu.toDate();
        } else if (fechaAsignacion != null) {
          fecha = fechaAsignacion.toDate();
        }

        if (fecha != null) {
          aniosSet.add(fecha.year.toString());
        }
      }

      setState(() {
        _aniosDisponibles = aniosSet.toList()..sort((a, b) => b.compareTo(a));
        _cargandoAnios = false;
      });
    } catch (e) {
      print('Error al cargar años: $e');
      setState(() {
        _cargandoAnios = false;
      });
    }
  }

// ✅ NUEVO: Método para obtener el nombre del mes en español
  String _obtenerNombreMes(int mes) {
    const meses = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre'
    ];
    return meses[mes - 1];
  }

// ✅ NUEVO: Método para filtrar registros por fecha
  bool _cumpleFiltroFecha(DocumentSnapshot doc) {
    // Si no hay filtros activos, mostrar todo
    if (_anioSeleccionado == null && _mesSeleccionado == null) {
      return true;
    }

    final data = doc.data() as Map<String, dynamic>;

    // Buscar fecha de asignación
    final fechaTribu = data['fechaAsignacionTribu'] as Timestamp?;
    final fechaAsignacion = data['fechaAsignacion'] as Timestamp?;

    DateTime? fecha;
    if (fechaTribu != null) {
      fecha = fechaTribu.toDate();
    } else if (fechaAsignacion != null) {
      fecha = fechaAsignacion.toDate();
    }

    // Si no tiene fecha, no pasa el filtro
    if (fecha == null) return false;

    // Verificar año
    if (_anioSeleccionado != null && _anioSeleccionado != 'Todos') {
      if (fecha.year.toString() != _anioSeleccionado) {
        return false;
      }
    }

    // Verificar mes
    if (_mesSeleccionado != null && _mesSeleccionado != 'Todos') {
      int mesNumero = int.parse(_mesSeleccionado!);
      if (fecha.month != mesNumero) {
        return false;
      }
    }

    return true;
  }

// ✅ NUEVO: Método para filtrar registros por estado en la iglesia
  bool _cumpleFiltroEstado(DocumentSnapshot doc) {
    // Si no hay término de búsqueda de estado, no filtrar
    if (_searchEstadoTerm.isEmpty) {
      return true;
    }

    final data = doc.data() as Map<String, dynamic>;
    final estadoProceso =
        (data['estadoProceso'] as String? ?? '').toLowerCase();

    // Búsqueda flexible: contiene el término
    return estadoProceso.contains(_searchEstadoTerm);
  }

  void _limpiarFiltros() {
    setState(() {
      _anioSeleccionado = null;
      _mesSeleccionado = null;
      _searchController.clear();
      _searchEstadoController.clear();
      _searchTerm = '';
      _searchEstadoTerm = '';
    });
  }

  // ✅ MANTENER: Funciones originales sin cambios
  Future<void> _asignarACoordinador(
      BuildContext context, DocumentSnapshot registro) async {
    final coordinadoresSnapshot = await FirebaseFirestore.instance
        .collection('coordinadores')
        .where('tribuId', isEqualTo: widget.tribuId)
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

//logica para editar los registro

  // ✅ NUEVA FUNCIÓN: Método para obtener el valor de un campo con detección de variantes
  dynamic obtenerValorCampoEdicion(Map<String, dynamic> data, String campo) {
    // Si el campo existe directamente, lo devolvemos
    if (data.containsKey(campo)) {
      return data[campo];
    }

    // ✅ MODIFICACIÓN: Detección especial para descripcionOcupacion
    if (campo == 'descripcionOcupacion') {
      // Buscar primero 'descripcionOcupacion', luego 'descripcionOcupaciones'
      if (data.containsKey('descripcionOcupacion')) {
        return data['descripcionOcupacion'];
      } else if (data.containsKey('descripcionOcupaciones')) {
        return data['descripcionOcupaciones'];
      }
    }

    // Si no se encuentra el campo, devolver null
    return null;
  }

  void _editarRegistro(BuildContext context, DocumentSnapshot registro) {
    // Colores de la aplicación
    const Color primaryTeal = Color(0xFF1B998B);
    const Color secondaryOrange = Color(0xFFFF7E00);
    final Color lightTeal = primaryTeal.withOpacity(0.1);

    // Flag para rastrear si hay cambios sin guardar
    bool hayModificaciones = false;

    // Función mejorada para obtener un valor seguro del documento con mejor manejo de nulos
    T? getSafeValue<T>(String field) {
      try {
        final data = registro.data();
        if (data == null) return null;

        if (data is Map) {
          final value =
              obtenerValorCampoEdicion(data as Map<String, dynamic>, field);

          if (value is T) {
            return value;
          } else if (value != null) {
            if (T == String && value != null) {
              return value.toString() as T;
            } else if (T == int && value is num) {
              return value.toInt() as T;
            } else if (T == double && value is num) {
              return value.toDouble() as T;
            }
          }
        }
        return null;
      } catch (e) {
        print('Error getting field $field: $e');
        return null;
      }
    }

    // Función para calcular la edad
    int _calcularEdad(DateTime fechaNacimiento) {
      final hoy = DateTime.now();
      int edad = hoy.year - fechaNacimiento.year;
      if (hoy.month < fechaNacimiento.month ||
          (hoy.month == fechaNacimiento.month &&
              hoy.day < fechaNacimiento.day)) {
        edad--;
      }
      return edad;
    }

    // Función para calcular el próximo cumpleaños
    String _calcularProximoCumpleanos(DateTime fechaNacimiento) {
      final hoy = DateTime.now();
      DateTime proximoCumpleanos =
          DateTime(hoy.year, fechaNacimiento.month, fechaNacimiento.day);

      if (proximoCumpleanos.isBefore(hoy) ||
          proximoCumpleanos.isAtSameMomentAs(hoy)) {
        proximoCumpleanos =
            DateTime(hoy.year + 1, fechaNacimiento.month, fechaNacimiento.day);
      }

      final diferencia = proximoCumpleanos.difference(hoy).inDays;

      if (diferencia == 0) {
        return '¡Hoy es su cumpleaños! 🎉';
      } else if (diferencia == 1) {
        return 'Mañana (${diferencia} día)';
      } else if (diferencia <= 7) {
        return 'En ${diferencia} días';
      } else if (diferencia <= 30) {
        return 'En ${diferencia} días';
      } else {
        final meses = (diferencia / 30).floor();
        if (meses == 1) {
          return 'En aproximadamente 1 mes';
        } else {
          return 'En aproximadamente ${meses} meses';
        }
      }
    }

    // Controladores para los campos
    final Map<String, TextEditingController> controllers = {};

    // Estado para campos de selección
    String estadoCivilSeleccionado =
        getSafeValue<String>('estadoCivil') ?? 'Soltero(a)';
    String sexoSeleccionado = getSafeValue<String>('sexo') ?? 'Hombre';

    // Estado activo del registro
    bool estadoActivo = getSafeValue<bool>('activo') ?? true;

    // ✅ NUEVO: Variable para controlar el estado anterior
    bool estadoActivoAnterior = estadoActivo;

    // Fecha de nacimiento
    DateTime? fechaNacimiento;
    final fechaNacimientoValue = getSafeValue('fechaNacimiento');
    if (fechaNacimientoValue != null) {
      if (fechaNacimientoValue is Timestamp) {
        fechaNacimiento = fechaNacimientoValue.toDate();
      } else if (fechaNacimientoValue is String) {
        try {
          fechaNacimiento = DateTime.parse(fechaNacimientoValue);
        } catch (e) {
          print('Error parsing date string: $e');
        }
      }
    }

    // Opciones para los campos de selección
    final List<String> opcionesEstadoCivil = [
      'Casado(a)',
      'Soltero(a)',
      'Unión Libre',
      'Separado(a)',
      'Viudo(a)',
    ];

    final List<String> opcionesSexo = [
      'Hombre',
      'Mujer',
    ];

    // Definición de campos con sus iconos y tipos
    final Map<String, Map<String, dynamic>> camposDefinicion = {
      'nombre': {'icon': Icons.person, 'type': 'text'},
      'apellido': {'icon': Icons.person_outline, 'type': 'text'},
      'telefono': {'icon': Icons.phone, 'type': 'text'},
      'direccion': {'icon': Icons.location_on, 'type': 'text'},
      'barrio': {'icon': Icons.home, 'type': 'text'},
      'estadoCivil': {'icon': Icons.family_restroom, 'type': 'dropdown'},
      'nombrePareja': {'icon': Icons.favorite, 'type': 'text'},
      'ocupaciones': {'icon': Icons.work, 'type': 'list'},
      'descripcionOcupacion': {'icon': Icons.note, 'type': 'text'},
      'referenciaInvitacion': {'icon': Icons.link, 'type': 'text'},
      'observaciones': {'icon': Icons.comment, 'type': 'text'},
      'estadoFonovisita': {'icon': Icons.assignment, 'type': 'text'},
      'observaciones2': {'icon': Icons.notes, 'type': 'text'},
      'edad': {'icon': Icons.cake, 'type': 'int'},
      'peticiones': {'icon': Icons.volunteer_activism, 'type': 'text'},
      'sexo': {'icon': Icons.wc, 'type': 'dropdown'},
      'estadoProceso': {'icon': Icons.track_changes_outlined, 'type': 'text'},
      'fechaNacimiento': {'icon': Icons.calendar_today, 'type': 'date'},
    };

    // Inicializar controladores de manera segura
    camposDefinicion.forEach((key, value) {
      if (key != 'estadoCivil' && key != 'sexo' && key != 'fechaNacimiento') {
        var fieldValue = getSafeValue(key);

        if (value['type'] == 'list' && fieldValue is List) {
          controllers[key] = TextEditingController(text: fieldValue.join(', '));
        } else if (value['type'] == 'int' && fieldValue != null) {
          controllers[key] = TextEditingController(text: fieldValue.toString());
        } else if (fieldValue != null) {
          controllers[key] = TextEditingController(text: fieldValue.toString());
        } else {
          controllers[key] = TextEditingController();
        }
      }
    });

    if (controllers['nombrePareja'] == null) {
      controllers['nombrePareja'] = TextEditingController();
    }

    // Función para verificar si se debe mostrar el campo de nombre de pareja
    bool mostrarNombrePareja() {
      return estadoCivilSeleccionado == 'Casado(a)' ||
          estadoCivilSeleccionado == 'Unión Libre';
    }

    // Función para mostrar el selector de fecha
    Future<void> _seleccionarFecha(StateSetter setState) async {
      final DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: fechaNacimiento ??
            DateTime.now().subtract(Duration(days: 365 * 25)),
        firstDate: DateTime(1900),
        lastDate: DateTime.now(),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: primaryTeal,
                onPrimary: Colors.white,
                surface: Colors.white,
                onSurface: Colors.black,
              ),
            ),
            child: child!,
          );
        },
      );

      if (pickedDate != null) {
        setState(() {
          fechaNacimiento = pickedDate;
          hayModificaciones = true;
        });
      }
    }

    // ✅ NUEVA FUNCIÓN: Mostrar diálogo de observaciones al desactivar
    Future<String?> _mostrarDialogoObservacionesDesactivacion() async {
      final TextEditingController observacionesController =
          TextEditingController();
      String? resultado;

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange,
                    size: 24,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Observaciones Requeridas',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: primaryTeal,
                    ),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.orange.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: Colors.orange, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Por favor, explica la razón por la cual esta persona ya no forma parte de la iglesia.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.orange[800],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: observacionesController,
                    maxLines: 5,
                    maxLength: 500,
                    decoration: InputDecoration(
                      labelText: 'Observaciones *',
                      labelStyle: TextStyle(
                        color: primaryTeal.withOpacity(0.8),
                        fontWeight: FontWeight.w500,
                      ),
                      hintText: 'Describe el motivo de la desactivación...',
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                      prefixIcon: Container(
                        margin: EdgeInsets.all(12),
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: primaryTeal.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child:
                            Icon(Icons.edit_note, color: primaryTeal, size: 20),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: primaryTeal.withOpacity(0.3)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: primaryTeal.withOpacity(0.5)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: primaryTeal, width: 2),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: Colors.red.shade400, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      counterStyle:
                          TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    style: TextStyle(fontSize: 15),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  resultado = null;
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Cancelar',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  if (observacionesController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.white),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Las observaciones son obligatorias al desactivar un registro',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        margin: EdgeInsets.all(16),
                      ),
                    );
                    return;
                  }

                  resultado = observacionesController.text.trim();
                  Navigator.of(dialogContext).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: secondaryOrange,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 2,
                ),
                child: Text(
                  'Guardar Observación',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          );
        },
      );

      observacionesController.dispose();
      return resultado;
    }

    // Función para mostrar el diálogo de confirmación
    Future<bool> confirmarSalida() async {
      if (!hayModificaciones) return true;

      if (!context.mounted) return false;

      bool confirmar = false;
      await showDialog(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext dialogContext) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.amber),
              SizedBox(width: 10),
              Text('Cambios sin guardar'),
            ],
          ),
          content: Text(
              '¿Estás seguro de que deseas salir sin guardar los cambios?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                confirmar = false;
              },
              child:
                  Text('Cancelar', style: TextStyle(color: Colors.grey[700])),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: secondaryOrange,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                confirmar = true;
              },
              child: Text('Salir sin guardar'),
            ),
          ],
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
      );

      return confirmar;
    }

    // Mostrar el nombre del registro
    String getNombreCompleto() {
      String nombre = getSafeValue<String>('nombre') ?? '';
      String apellido = getSafeValue<String>('apellido') ?? '';

      if (nombre.isNotEmpty || apellido.isNotEmpty) {
        return '$nombre $apellido'.trim();
      }

      return 'Registro ${registro.id}';
    }

    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(builder: (stateContext, setState) {
          return WillPopScope(
            onWillPop: () async {
              bool confirmar = await confirmarSalida();
              return confirmar;
            },
            child: Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: 500,
                  maxHeight: MediaQuery.of(dialogContext).size.height * 0.85,
                ),
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.manual,
                  physics: ClampingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Encabezado
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: lightTeal,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.edit, color: primaryTeal, size: 28),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Editar Registro',
                                  style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: primaryTeal),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Información del registro
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.person,
                                        color: Colors.grey[700], size: 18),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        getNombreCompleto(),
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey[800],
                                          fontWeight: FontWeight.w500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Switch para estado activo/inactivo
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: estadoActivo
                                ? Colors.green.withOpacity(0.1)
                                : Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: estadoActivo
                                  ? Colors.green.withOpacity(0.3)
                                  : Colors.red.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    estadoActivo
                                        ? Icons.check_circle
                                        : Icons.cancel,
                                    color: estadoActivo
                                        ? Colors.green
                                        : Colors.red,
                                    size: 24,
                                  ),
                                  SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Estado del Registro',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        estadoActivo ? "Activo" : "No Activo",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: estadoActivo
                                              ? Colors.green[700]
                                              : Colors.red[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Switch(
                                value: estadoActivo,
                                activeColor: secondaryOrange,
                                inactiveThumbColor: Colors.grey[400],
                                inactiveTrackColor: Colors.grey[300],
                                onChanged: (value) async {
                                  // ✅ NUEVA LÓGICA: Si está desactivando, pedir observaciones
                                  if (!value && estadoActivoAnterior) {
                                    final observacion =
                                        await _mostrarDialogoObservacionesDesactivacion();

                                    if (observacion != null &&
                                        observacion.isNotEmpty) {
                                      // Guardar la observación en el campo de observaciones
                                      if (controllers['observaciones'] !=
                                          null) {
                                        final observacionActual =
                                            controllers['observaciones']!.text;
                                        final nuevaObservacion = observacionActual
                                                .isEmpty
                                            ? 'MOTIVO DESACTIVACIÓN: $observacion'
                                            : '$observacionActual\n\nMOTIVO DESACTIVACIÓN: $observacion';
                                        controllers['observaciones']!.text =
                                            nuevaObservacion;
                                      }

                                      setState(() {
                                        estadoActivo = value;
                                        estadoActivoAnterior = value;
                                        hayModificaciones = true;
                                      });
                                    }
                                  } else {
                                    // Si está activando, no pedir observaciones
                                    setState(() {
                                      estadoActivo = value;
                                      estadoActivoAnterior = value;
                                      hayModificaciones = true;
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Mostrar advertencia si el registro está inactivo
                        if (!estadoActivo)
                          Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.orange.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline,
                                    color: Colors.orange, size: 20),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Al desactivar este registro, se eliminarán automáticamente las asignaciones de coordinador y timoteo.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.orange[800],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Campos del formulario (resto del código sin cambios)
                        ...camposDefinicion.entries.map((entry) {
                          final fieldName = entry.key;
                          final fieldData = entry.value;
                          final controller = controllers[fieldName];
                          final fieldIcon =
                              fieldData['icon'] ?? Icons.help_outline;

                          if (fieldName == 'estadoCivil') {
                            return _buildDropdownField(
                              label: 'Estado Civil',
                              icon: fieldIcon,
                              value: estadoCivilSeleccionado,
                              items: opcionesEstadoCivil,
                              primaryColor: primaryTeal,
                              onChanged: (newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    estadoCivilSeleccionado = newValue;
                                    hayModificaciones = true;
                                  });
                                }
                              },
                            );
                          } else if (fieldName == 'sexo') {
                            return _buildDropdownField(
                              label: 'Sexo',
                              icon: fieldIcon,
                              value: sexoSeleccionado,
                              items: opcionesSexo,
                              primaryColor: primaryTeal,
                              onChanged: (newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    sexoSeleccionado = newValue;
                                    hayModificaciones = true;
                                  });
                                }
                              },
                            );
                          } else if (fieldName == 'fechaNacimiento') {
                            return Column(
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  child: InkWell(
                                    onTap: () => _seleccionarFecha(setState),
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.withOpacity(0.05),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: primaryTeal.withOpacity(0.3),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color:
                                                  primaryTeal.withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Icon(
                                              fieldIcon,
                                              color: primaryTeal,
                                              size: 20,
                                            ),
                                          ),
                                          SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Fecha de Nacimiento',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[600],
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                SizedBox(height: 4),
                                                Text(
                                                  fechaNacimiento != null
                                                      ? '${fechaNacimiento!.day}/${fechaNacimiento!.month}/${fechaNacimiento!.year}'
                                                      : 'Seleccionar fecha',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w500,
                                                    color:
                                                        fechaNacimiento != null
                                                            ? Colors.black87
                                                            : Colors.grey[500],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Icon(
                                            Icons.keyboard_arrow_down,
                                            color: Colors.grey[600],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                if (fechaNacimiento != null)
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Color(0xFF1B998B).withOpacity(0.1),
                                          Color(0xFFFF7E00).withOpacity(0.1),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color:
                                            Color(0xFF1B998B).withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Color(0xFF1B998B)
                                                    .withOpacity(0.2),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Icon(
                                                Icons.celebration,
                                                color: Color(0xFF1B998B),
                                                size: 20,
                                              ),
                                            ),
                                            SizedBox(width: 12),
                                            Text(
                                              'Información de Cumpleaños',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF1B998B),
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  color: Colors.white
                                                      .withOpacity(0.7),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Edad Actual',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey[600],
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                    Text(
                                                      '${_calcularEdad(fechaNacimiento!)} años',
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color:
                                                            Color(0xFF1B998B),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            SizedBox(width: 12),
                                            Expanded(
                                              flex: 2,
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  color: Colors.white
                                                      .withOpacity(0.7),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Próximo Cumpleaños',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey[600],
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                    Text(
                                                      _calcularProximoCumpleanos(
                                                          fechaNacimiento!),
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color:
                                                            Color(0xFFFF7E00),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            );
                          } else if (fieldName == 'nombrePareja') {
                            if (mostrarNombrePareja() && controller != null) {
                              return _buildAnimatedTextField(
                                label: 'Nombre de Pareja',
                                icon: fieldIcon,
                                controller: controller,
                                primaryColor: primaryTeal,
                                onChanged: (value) {
                                  hayModificaciones = true;
                                },
                              );
                            } else {
                              return SizedBox.shrink();
                            }
                          } else if (fieldName == 'estadoProceso') {
                            return _buildAnimatedTextFieldConOpciones(
                              label: 'Estado en la Iglesia',
                              icon: fieldIcon,
                              controller: controller!,
                              primaryColor: primaryTeal,
                              opciones: [
                                'Pendiente',
                                'Discipulado 1',
                                'Discipulado 2',
                                'Discipulado 3',
                                'Consolidación',
                                'Estudio Bíblico',
                                'Escuela de Líderes'
                              ],
                              onChanged: (value) {
                                hayModificaciones = true;
                              },
                            );
                          } else if (controller != null) {
                            return _buildAnimatedTextField(
                              label: _formatFieldName(fieldName),
                              icon: fieldIcon,
                              controller: controller,
                              primaryColor: primaryTeal,
                              onChanged: (value) {
                                hayModificaciones = true;
                              },
                            );
                          } else {
                            return SizedBox.shrink();
                          }
                        }).toList(),

                        const SizedBox(height: 24),

                        // Botones de acción
                        SafeArea(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton.icon(
                                onPressed: () async {
                                  bool confirmar = await confirmarSalida();
                                  if (confirmar && dialogContext.mounted) {
                                    Navigator.pop(dialogContext);
                                  }
                                },
                                icon:
                                    Icon(Icons.cancel, color: Colors.grey[700]),
                                label: Text('Cancelar',
                                    style: TextStyle(
                                        color: Colors.grey[700], fontSize: 16)),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                ),
                              ),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: secondaryOrange,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  elevation: 2,
                                ),
                                icon:
                                    const Icon(Icons.save, color: Colors.white),
                                label: const Text('Guardar Cambios',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold)),
                                onPressed: () async {
                                  try {
                                    final Map<String, dynamic> updateData = {};

                                    updateData['estadoCivil'] =
                                        estadoCivilSeleccionado;
                                    updateData['sexo'] = sexoSeleccionado;

                                    if (fechaNacimiento != null) {
                                      updateData['fechaNacimiento'] =
                                          Timestamp.fromDate(fechaNacimiento!);
                                    }

                                    updateData['activo'] = estadoActivo;
                                    if (!estadoActivo) {
                                      updateData['coordinadorAsignado'] = null;
                                      updateData['coordinadorNombre'] = null;
                                      updateData['timoteoAsignado'] = null;
                                      updateData['nombreTimoteo'] = null;
                                    }

                                    controllers.forEach((key, controller) {
                                      if (controller != null) {
                                        final fieldType =
                                            camposDefinicion[key]?['type'];
                                        if (fieldType == 'list') {
                                          updateData[key] =
                                              controller.text.isEmpty
                                                  ? []
                                                  : controller.text
                                                      .split(',')
                                                      .map((e) => e.trim())
                                                      .toList();
                                        } else if (fieldType == 'int') {
                                          int? parsedValue =
                                              int.tryParse(controller.text);
                                          updateData[key] = parsedValue ?? 0;
                                        } else {
                                          updateData[key] = controller.text;
                                        }
                                      }
                                    });

                                    final data = registro.data();
                                    if (data != null &&
                                        data is Map<String, dynamic>) {
                                      if (data.containsKey(
                                              'descripcionOcupaciones') &&
                                          !data.containsKey(
                                              'descripcionOcupacion')) {
                                        if (updateData.containsKey(
                                            'descripcionOcupacion')) {
                                          updateData['descripcionOcupaciones'] =
                                              updateData[
                                                  'descripcionOcupacion'];
                                          updateData
                                              .remove('descripcionOcupacion');
                                        }
                                      }
                                    }

                                    if (FirebaseFirestore.instance != null) {
                                      await FirebaseFirestore.instance
                                          .collection('registros')
                                          .doc(registro.id)
                                          .update(updateData);

                                      if (dialogContext.mounted) {
                                        Navigator.pop(dialogContext);
                                      }

                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Row(
                                              children: const [
                                                Icon(Icons.check_circle,
                                                    color: Colors.white),
                                                SizedBox(width: 12),
                                                Text(
                                                  'Registro actualizado correctamente',
                                                  style:
                                                      TextStyle(fontSize: 16),
                                                ),
                                              ],
                                            ),
                                            backgroundColor: Colors.green,
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            margin: const EdgeInsets.all(12),
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 14, horizontal: 20),
                                            duration:
                                                const Duration(seconds: 3),
                                          ),
                                        );
                                      }
                                    } else {
                                      throw Exception(
                                          "No se pudo conectar con Firestore");
                                    }
                                  } catch (e) {
                                    if (dialogContext.mounted) {
                                      Navigator.pop(dialogContext);
                                    }
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Row(
                                            children: [
                                              const Icon(Icons.error,
                                                  color: Colors.white),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Text(
                                                  'Error al actualizar: ${e.toString()}',
                                                  style: const TextStyle(
                                                      fontSize: 16),
                                                ),
                                              ),
                                            ],
                                          ),
                                          backgroundColor: Colors.red,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          margin: const EdgeInsets.all(12),
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 14, horizontal: 20),
                                          duration: const Duration(seconds: 5),
                                        ),
                                      );
                                    }
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Definimos colores según los proporcionados
    final primaryTeal = Color(0xFF038C7F);
    final secondaryOrange = Color(0xFFFF5722);
    final accentGrey = Color(0xFF78909C);
    final backgroundGrey = Color(0xFFF5F5F5);

    return GestureDetector(
      onTap: () {
        // Solo desfocus si no estamos scrolleando
        FocusScope.of(context).requestFocus(FocusNode());
      },
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    primaryTeal.withOpacity(0.05),
                    backgroundGrey,
                  ],
                ),
              ),
              child: Column(
                children: [
                  // 🎯 SECCIÓN DE CONTROLES SUPERIORES
                  Container(
                    margin: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: primaryTeal.withOpacity(0.15),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // 🆕 ENCABEZADO CON BOTÓN DE COLAPSAR
                        InkWell(
                          onTap: () {
                            setState(() {
                              _filtrosExpandidos = !_filtrosExpandidos;
                            });
                          },
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                            bottomLeft: _filtrosExpandidos
                                ? Radius.zero
                                : Radius.circular(16),
                            bottomRight: _filtrosExpandidos
                                ? Radius.zero
                                : Radius.circular(16),
                          ),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  primaryTeal.withOpacity(0.1),
                                  primaryTeal.withOpacity(0.05),
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(16),
                                topRight: Radius.circular(16),
                                bottomLeft: _filtrosExpandidos
                                    ? Radius.zero
                                    : Radius.circular(16),
                                bottomRight: _filtrosExpandidos
                                    ? Radius.zero
                                    : Radius.circular(16),
                              ),
                              border: Border(
                                bottom: _filtrosExpandidos
                                    ? BorderSide(
                                        color: primaryTeal.withOpacity(0.2),
                                        width: 1)
                                    : BorderSide.none,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: primaryTeal.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.filter_list_rounded,
                                    color: primaryTeal,
                                    size: 20,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Filtros de Búsqueda',
                                        style: GoogleFonts.poppins(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: primaryTeal,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                      if (!_filtrosExpandidos) ...[
                                        SizedBox(height: 2),
                                        Text(
                                          _obtenerTextoFiltrosActivos(),
                                          style: GoogleFonts.poppins(
                                            fontSize: 11,
                                            color: accentGrey,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                if (_hayFiltrosActivos())
                                  Container(
                                    margin: EdgeInsets.only(right: 8),
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: secondaryOrange.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: secondaryOrange.withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: BoxDecoration(
                                            color: secondaryOrange,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          _contarFiltrosActivos().toString(),
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: secondaryOrange,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                AnimatedRotation(
                                  turns: _filtrosExpandidos ? 0.5 : 0,
                                  duration: Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                  child: Container(
                                    padding: EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: primaryTeal.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      color: primaryTeal,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // 🔽 CONTENIDO EXPANDIBLE DE FILTROS CON SCROLL INDEPENDIENTE
                        AnimatedSize(
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          child: _filtrosExpandidos
                              ? ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxHeight:
                                        MediaQuery.of(context).size.height *
                                            0.4,
                                  ),
                                  child: SingleChildScrollView(
                                    physics: ClampingScrollPhysics(),
                                    child: Column(
                                      children: [
                                        // 🔍 BARRA DE BÚSQUEDA
                                        Padding(
                                          padding: EdgeInsets.fromLTRB(
                                              12, 12, 12, 8),
                                          child: Column(
                                            children: [
                                              // Selector de tipo de búsqueda
                                              Container(
                                                padding: EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 6),
                                                decoration: BoxDecoration(
                                                  color: primaryTeal
                                                      .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  border: Border.all(
                                                    color: primaryTeal
                                                        .withOpacity(0.3),
                                                    width: 1,
                                                  ),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.filter_list_rounded,
                                                      color: primaryTeal,
                                                      size: 18,
                                                    ),
                                                    SizedBox(width: 8),
                                                    Text(
                                                      'Buscar por:',
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: primaryTeal,
                                                      ),
                                                    ),
                                                    SizedBox(width: 12),
                                                    Expanded(
                                                      child: Row(
                                                        children: [
                                                          Expanded(
                                                            child: InkWell(
                                                              onTap: () {
                                                                setState(() {
                                                                  _tipoBusqueda =
                                                                      'nombre';
                                                                  _searchEstadoController
                                                                      .clear();
                                                                  _searchEstadoTerm =
                                                                      '';
                                                                });
                                                              },
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          8),
                                                              child: Container(
                                                                padding: EdgeInsets
                                                                    .symmetric(
                                                                  horizontal:
                                                                      12,
                                                                  vertical: 8,
                                                                ),
                                                                decoration:
                                                                    BoxDecoration(
                                                                  color: _tipoBusqueda ==
                                                                          'nombre'
                                                                      ? primaryTeal
                                                                      : Colors
                                                                          .transparent,
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              8),
                                                                  border: Border
                                                                      .all(
                                                                    color: _tipoBusqueda ==
                                                                            'nombre'
                                                                        ? primaryTeal
                                                                        : primaryTeal
                                                                            .withOpacity(0.3),
                                                                    width: 1.5,
                                                                  ),
                                                                ),
                                                                child: Row(
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .center,
                                                                  children: [
                                                                    Icon(
                                                                      Icons
                                                                          .person_search_rounded,
                                                                      color: _tipoBusqueda ==
                                                                              'nombre'
                                                                          ? Colors
                                                                              .white
                                                                          : primaryTeal,
                                                                      size: 16,
                                                                    ),
                                                                    SizedBox(
                                                                        width:
                                                                            6),
                                                                    Flexible(
                                                                      child:
                                                                          Text(
                                                                        'Nombre',
                                                                        style:
                                                                            TextStyle(
                                                                          fontSize:
                                                                              12,
                                                                          fontWeight:
                                                                              FontWeight.w600,
                                                                          color: _tipoBusqueda == 'nombre'
                                                                              ? Colors.white
                                                                              : primaryTeal,
                                                                        ),
                                                                        overflow:
                                                                            TextOverflow.ellipsis,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                          SizedBox(width: 8),
                                                          Expanded(
                                                            child: InkWell(
                                                              onTap: () {
                                                                setState(() {
                                                                  _tipoBusqueda =
                                                                      'estado';
                                                                  _searchController
                                                                      .clear();
                                                                  _searchTerm =
                                                                      '';
                                                                });
                                                              },
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          8),
                                                              child: Container(
                                                                padding: EdgeInsets
                                                                    .symmetric(
                                                                  horizontal:
                                                                      12,
                                                                  vertical: 8,
                                                                ),
                                                                decoration:
                                                                    BoxDecoration(
                                                                  color: _tipoBusqueda ==
                                                                          'estado'
                                                                      ? secondaryOrange
                                                                      : Colors
                                                                          .transparent,
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              8),
                                                                  border: Border
                                                                      .all(
                                                                    color: _tipoBusqueda ==
                                                                            'estado'
                                                                        ? secondaryOrange
                                                                        : secondaryOrange
                                                                            .withOpacity(0.3),
                                                                    width: 1.5,
                                                                  ),
                                                                ),
                                                                child: Row(
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .center,
                                                                  children: [
                                                                    Icon(
                                                                      Icons
                                                                          .track_changes_rounded,
                                                                      color: _tipoBusqueda ==
                                                                              'estado'
                                                                          ? Colors
                                                                              .white
                                                                          : secondaryOrange,
                                                                      size: 16,
                                                                    ),
                                                                    SizedBox(
                                                                        width:
                                                                            6),
                                                                    Flexible(
                                                                      child:
                                                                          Text(
                                                                        'Estado',
                                                                        style:
                                                                            TextStyle(
                                                                          fontSize:
                                                                              12,
                                                                          fontWeight:
                                                                              FontWeight.w600,
                                                                          color: _tipoBusqueda == 'estado'
                                                                              ? Colors.white
                                                                              : secondaryOrange,
                                                                        ),
                                                                        overflow:
                                                                            TextOverflow.ellipsis,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              SizedBox(height: 8),

                                              // Campo de búsqueda
                                              AnimatedSwitcher(
                                                duration:
                                                    Duration(milliseconds: 300),
                                                transitionBuilder:
                                                    (Widget child,
                                                        Animation<double>
                                                            animation) {
                                                  return FadeTransition(
                                                    opacity: animation,
                                                    child: SlideTransition(
                                                      position: Tween<Offset>(
                                                        begin: Offset(0.0, 0.2),
                                                        end: Offset.zero,
                                                      ).animate(animation),
                                                      child: child,
                                                    ),
                                                  );
                                                },
                                                child: Container(
                                                  key: ValueKey<String>(
                                                      _tipoBusqueda),
                                                  decoration: BoxDecoration(
                                                    color: backgroundGrey
                                                        .withOpacity(0.5),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                    border: Border.all(
                                                      color: (_tipoBusqueda ==
                                                                  'nombre'
                                                              ? primaryTeal
                                                              : secondaryOrange)
                                                          .withOpacity(0.3),
                                                      width: 1.5,
                                                    ),
                                                  ),
                                                  child: TextField(
                                                    controller: _tipoBusqueda ==
                                                            'nombre'
                                                        ? _searchController
                                                        : _searchEstadoController,
                                                    focusNode: _tipoBusqueda ==
                                                            'nombre'
                                                        ? _searchFocusNode
                                                        : _searchEstadoFocusNode,
                                                    textInputAction:
                                                        TextInputAction.search,
                                                    enableInteractiveSelection:
                                                        true,
                                                    style: TextStyle(
                                                      fontSize: 15,
                                                      color: Colors.black87,
                                                    ),
                                                    decoration: InputDecoration(
                                                      hintText: _tipoBusqueda ==
                                                              'nombre'
                                                          ? 'Buscar por nombre o apellido...'
                                                          : 'Buscar por estado (ej: Discipulado 1)...',
                                                      hintStyle: TextStyle(
                                                        color: Colors.grey[400],
                                                        fontSize: 14,
                                                      ),
                                                      prefixIcon: Container(
                                                        margin:
                                                            EdgeInsets.all(8),
                                                        padding:
                                                            EdgeInsets.all(6),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: (_tipoBusqueda ==
                                                                      'nombre'
                                                                  ? primaryTeal
                                                                  : secondaryOrange)
                                                              .withOpacity(0.1),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(8),
                                                        ),
                                                        child: Icon(
                                                          _tipoBusqueda == 'nombre'
                                                              ? Icons
                                                                  .search_rounded
                                                              : Icons
                                                                  .track_changes_rounded,
                                                          color: _tipoBusqueda ==
                                                                  'nombre'
                                                              ? primaryTeal
                                                              : secondaryOrange,
                                                          size: 20,
                                                        ),
                                                      ),
                                                      suffixIcon: (_tipoBusqueda ==
                                                                  'nombre'
                                                              ? _searchController
                                                                  .text
                                                                  .isNotEmpty
                                                              : _searchEstadoController
                                                                  .text
                                                                  .isNotEmpty)
                                                          ? IconButton(
                                                              icon: Icon(
                                                                Icons
                                                                    .close_rounded,
                                                                color:
                                                                    accentGrey,
                                                                size: 20,
                                                              ),
                                                              onPressed: () {
                                                                setState(() {
                                                                  if (_tipoBusqueda ==
                                                                      'nombre') {
                                                                    _searchController
                                                                        .clear();
                                                                    _searchTerm =
                                                                        '';
                                                                    _searchFocusNode
                                                                        .requestFocus();
                                                                  } else {
                                                                    _searchEstadoController
                                                                        .clear();
                                                                    _searchEstadoTerm =
                                                                        '';
                                                                    _searchEstadoFocusNode
                                                                        .requestFocus();
                                                                  }
                                                                });
                                                              },
                                                            )
                                                          : null,
                                                      border: InputBorder.none,
                                                      contentPadding:
                                                          EdgeInsets.symmetric(
                                                        vertical: 12,
                                                        horizontal: 4,
                                                      ),
                                                      isDense: true,
                                                    ),
                                                    onSubmitted: (value) {
                                                      if (_tipoBusqueda ==
                                                          'nombre') {
                                                        _searchFocusNode
                                                            .unfocus();
                                                      } else {
                                                        _searchEstadoFocusNode
                                                            .unfocus();
                                                      }
                                                    },
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        // 📅 FILTROS DE FECHA
                                        Padding(
                                          padding:
                                              EdgeInsets.fromLTRB(12, 0, 12, 8),
                                          child: LayoutBuilder(
                                            builder: (context, constraints) {
                                              final isSmallScreen =
                                                  constraints.maxWidth < 600;

                                              return Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        Icons
                                                            .filter_list_rounded,
                                                        color: primaryTeal,
                                                        size: 18,
                                                      ),
                                                      SizedBox(width: 6),
                                                      Text(
                                                        'Filtrar por fecha de asignación',
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: primaryTeal,
                                                          fontSize: 13,
                                                          letterSpacing: 0.2,
                                                        ),
                                                      ),
                                                      Spacer(),
                                                      if (_anioSeleccionado !=
                                                              null ||
                                                          _mesSeleccionado !=
                                                              null)
                                                        InkWell(
                                                          onTap:
                                                              _limpiarFiltros,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(6),
                                                          child: Container(
                                                            padding: EdgeInsets
                                                                .symmetric(
                                                              horizontal: 8,
                                                              vertical: 4,
                                                            ),
                                                            decoration:
                                                                BoxDecoration(
                                                              color: secondaryOrange
                                                                  .withOpacity(
                                                                      0.1),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          6),
                                                            ),
                                                            child: Row(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .min,
                                                              children: [
                                                                Icon(
                                                                  Icons
                                                                      .clear_rounded,
                                                                  color:
                                                                      secondaryOrange,
                                                                  size: 14,
                                                                ),
                                                                SizedBox(
                                                                    width: 4),
                                                                Text(
                                                                  'Limpiar',
                                                                  style:
                                                                      TextStyle(
                                                                    color:
                                                                        secondaryOrange,
                                                                    fontSize:
                                                                        11,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                  SizedBox(height: 10),
                                                  isSmallScreen
                                                      ? Column(
                                                          children: [
                                                            _buildDropdownFiltroCompacto(
                                                              label: 'Año',
                                                              icon: Icons
                                                                  .calendar_today_rounded,
                                                              value:
                                                                  _anioSeleccionado,
                                                              items: [
                                                                'Todos',
                                                                ..._aniosDisponibles
                                                              ],
                                                              onChanged:
                                                                  (value) {
                                                                setState(() {
                                                                  _anioSeleccionado =
                                                                      value;
                                                                });
                                                              },
                                                              primaryTeal:
                                                                  primaryTeal,
                                                              accentGrey:
                                                                  accentGrey,
                                                              backgroundGrey:
                                                                  backgroundGrey,
                                                            ),
                                                            SizedBox(height: 8),
                                                            _buildDropdownFiltroCompacto(
                                                              label: 'Mes',
                                                              icon: Icons
                                                                  .event_rounded,
                                                              value:
                                                                  _mesSeleccionado,
                                                              items: [
                                                                'Todos',
                                                                '1',
                                                                '2',
                                                                '3',
                                                                '4',
                                                                '5',
                                                                '6',
                                                                '7',
                                                                '8',
                                                                '9',
                                                                '10',
                                                                '11',
                                                                '12'
                                                              ],
                                                              itemBuilder:
                                                                  (value) {
                                                                if (value ==
                                                                    'Todos')
                                                                  return 'Todos';
                                                                return _obtenerNombreMes(
                                                                    int.parse(
                                                                        value));
                                                              },
                                                              onChanged:
                                                                  (value) {
                                                                setState(() {
                                                                  _mesSeleccionado =
                                                                      value;
                                                                });
                                                              },
                                                              primaryTeal:
                                                                  primaryTeal,
                                                              accentGrey:
                                                                  accentGrey,
                                                              backgroundGrey:
                                                                  backgroundGrey,
                                                            ),
                                                          ],
                                                        )
                                                      : Row(
                                                          children: [
                                                            Expanded(
                                                              child:
                                                                  _buildDropdownFiltroCompacto(
                                                                label: 'Año',
                                                                icon: Icons
                                                                    .calendar_today_rounded,
                                                                value:
                                                                    _anioSeleccionado,
                                                                items: [
                                                                  'Todos',
                                                                  ..._aniosDisponibles
                                                                ],
                                                                onChanged:
                                                                    (value) {
                                                                  setState(() {
                                                                    _anioSeleccionado =
                                                                        value;
                                                                  });
                                                                },
                                                                primaryTeal:
                                                                    primaryTeal,
                                                                accentGrey:
                                                                    accentGrey,
                                                                backgroundGrey:
                                                                    backgroundGrey,
                                                              ),
                                                            ),
                                                            SizedBox(width: 10),
                                                            Expanded(
                                                              child:
                                                                  _buildDropdownFiltroCompacto(
                                                                label: 'Mes',
                                                                icon: Icons
                                                                    .event_rounded,
                                                                value:
                                                                    _mesSeleccionado,
                                                                items: [
                                                                  'Todos',
                                                                  '1',
                                                                  '2',
                                                                  '3',
                                                                  '4',
                                                                  '5',
                                                                  '6',
                                                                  '7',
                                                                  '8',
                                                                  '9',
                                                                  '10',
                                                                  '11',
                                                                  '12'
                                                                ],
                                                                itemBuilder:
                                                                    (value) {
                                                                  if (value ==
                                                                      'Todos')
                                                                    return 'Todos';
                                                                  return _obtenerNombreMes(
                                                                      int.parse(
                                                                          value));
                                                                },
                                                                onChanged:
                                                                    (value) {
                                                                  setState(() {
                                                                    _mesSeleccionado =
                                                                        value;
                                                                  });
                                                                },
                                                                primaryTeal:
                                                                    primaryTeal,
                                                                accentGrey:
                                                                    accentGrey,
                                                                backgroundGrey:
                                                                    backgroundGrey,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                ],
                                              );
                                            },
                                          ),
                                        ),

                                        // 📥 BOTÓN DE DESCARGAR EXCEL
                                        Padding(
                                          padding: EdgeInsets.fromLTRB(
                                              12, 4, 12, 12),
                                          child: SizedBox(
                                            width: double.infinity,
                                            child: ElevatedButton.icon(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    secondaryOrange,
                                                foregroundColor: Colors.white,
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 16,
                                                  vertical: 14,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                elevation: 2,
                                              ),
                                              icon: Icon(Icons.download_rounded,
                                                  size: 20),
                                              label: Text(
                                                'Descargar Excel',
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w600,
                                                  letterSpacing: 0.3,
                                                ),
                                              ),
                                              onPressed: () {
                                                final tribusState = context
                                                    .findAncestorStateOfType<
                                                        _TribusScreenState>();
                                                if (tribusState != null) {
                                                  String? estadoActivo;
                                                  if (_tipoBusqueda ==
                                                          'estado' &&
                                                      _searchEstadoTerm
                                                          .isNotEmpty) {
                                                    estadoActivo =
                                                        _searchEstadoTerm;
                                                  }
                                                  tribusState.descargarExcel(
                                                    context,
                                                    widget.tribuId,
                                                    widget.tribuNombre,
                                                    anioFiltro:
                                                        _anioSeleccionado,
                                                    mesFiltro: _mesSeleccionado,
                                                    estadoFiltro: estadoActivo,
                                                  );
                                                } else {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        'Error: No se pudo acceder al contexto de descarga',
                                                      ),
                                                      backgroundColor:
                                                          Colors.red,
                                                    ),
                                                  );
                                                }
                                              },
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
// 📋 CONTENIDO PRINCIPAL - LISTA DE REGISTROS
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('registros')
                          .where('tribuAsignada', isEqualTo: widget.tribuId)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                                ConnectionState.waiting &&
                            !snapshot.hasData) {
                          return Container();
                        }

                        if (!snapshot.hasData ||
                            snapshot.data?.docs.isEmpty == true) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.group_off_outlined,
                                  size: 64,
                                  color: accentGrey,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'No hay jóvenes asignados a esta tribu',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: accentGrey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        final allDocs = snapshot.data?.docs ?? [];
                        var filteredDocs = allDocs;

                        if (_tipoBusqueda == 'nombre' &&
                            _searchTerm.isNotEmpty) {
                          filteredDocs = filteredDocs.where((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final nombre =
                                (data['nombre'] as String? ?? '').toLowerCase();
                            final apellido = (data['apellido'] as String? ?? '')
                                .toLowerCase();
                            final nombreCompleto =
                                '$nombre $apellido'.toLowerCase();

                            return nombre.contains(_searchTerm) ||
                                apellido.contains(_searchTerm) ||
                                nombreCompleto.contains(_searchTerm);
                          }).toList();
                        } else if (_tipoBusqueda == 'estado' &&
                            _searchEstadoTerm.isNotEmpty) {
                          filteredDocs = filteredDocs
                              .where((doc) => _cumpleFiltroEstado(doc))
                              .toList();
                        }

                        if (_anioSeleccionado != null ||
                            _mesSeleccionado != null) {
                          filteredDocs = filteredDocs
                              .where((doc) => _cumpleFiltroFecha(doc))
                              .toList();
                        }

                        filteredDocs.sort((a, b) {
                          final dataA = a.data() as Map<String, dynamic>;
                          final dataB = b.data() as Map<String, dynamic>;

                          bool esRegistroNuevo(Map<String, dynamic> data) {
                            DateTime? fechaTribu =
                                (data['fechaAsignacionTribu'] as Timestamp?)
                                        ?.toDate() ??
                                    (data['fechaAsignacion'] as Timestamp?)
                                        ?.toDate();
                            DateTime? fechaCoord =
                                (data['fechaAsignacionCoordinador']
                                        as Timestamp?)
                                    ?.toDate();
                            DateTime? fechaTimoteo =
                                (data['fechaAsignacionTimoteo'] as Timestamp?)
                                    ?.toDate();

                            DateTime? fechaMasReciente = [
                              fechaTribu,
                              fechaCoord,
                              fechaTimoteo
                            ].whereType<DateTime>().fold<DateTime?>(
                                null,
                                (prev, curr) =>
                                    prev == null || curr.isAfter(prev)
                                        ? curr
                                        : prev);

                            return fechaMasReciente != null &&
                                DateTime.now()
                                        .difference(fechaMasReciente)
                                        .inDays <=
                                    14;
                          }

                          bool nuevoA = esRegistroNuevo(dataA);
                          bool nuevoB = esRegistroNuevo(dataB);

                          if (nuevoA && !nuevoB) return -1;
                          if (!nuevoA && nuevoB) return 1;

                          final nombreA =
                              '${dataA['nombre'] ?? ''} ${dataA['apellido'] ?? ''}'
                                  .toLowerCase();
                          final nombreB =
                              '${dataB['nombre'] ?? ''} ${dataB['apellido'] ?? ''}'
                                  .toLowerCase();
                          return nombreA.compareTo(nombreB);
                        });

                        if (filteredDocs.isEmpty) {
                          String mensaje;
                          if (_tipoBusqueda == 'nombre' &&
                              _searchTerm.isNotEmpty) {
                            mensaje =
                                'No se encontraron resultados para "$_searchTerm"';
                          } else if (_tipoBusqueda == 'estado' &&
                              _searchEstadoTerm.isNotEmpty) {
                            mensaje =
                                'No hay registros con estado "$_searchEstadoTerm"';
                          } else {
                            mensaje =
                                'No hay registros con los filtros aplicados';
                          }

                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _searchTerm.isNotEmpty
                                      ? Icons.search_off_rounded
                                      : Icons.filter_list_off_rounded,
                                  size: 64,
                                  color: accentGrey,
                                ),
                                SizedBox(height: 16),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 32),
                                  child: Text(
                                    mensaje,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: accentGrey,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _searchController.clear();
                                      _searchEstadoController.clear();
                                      _searchTerm = '';
                                      _searchEstadoTerm = '';
                                      _limpiarFiltros();
                                    });
                                  },
                                  icon: Icon(Icons.refresh_rounded, size: 20),
                                  label: Text('Limpiar todo'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryTeal,
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        List<DocumentSnapshot> registrosActivos = [];
                        List<DocumentSnapshot> registrosInactivos = [];
                        List<DocumentSnapshot> sinCoordinador = [];
                        Map<String, List<DocumentSnapshot>> porCoordinador = {};
                        List<String> idsCoordinadores = [];

                        for (var doc in filteredDocs) {
                          var data = doc.data() as Map<String, dynamic>;
                          bool activo = data['activo'] ?? true;

                          if (activo) {
                            registrosActivos.add(doc);
                          } else {
                            registrosInactivos.add(doc);
                          }
                        }

                        for (var doc in registrosActivos) {
                          var data = doc.data() as Map<String, dynamic>;
                          if (data['coordinadorAsignado'] == null) {
                            sinCoordinador.add(doc);
                          } else {
                            String coordinadorId = data['coordinadorAsignado'];
                            if (!porCoordinador.containsKey(coordinadorId)) {
                              porCoordinador[coordinadorId] = [];
                              idsCoordinadores.add(coordinadorId);
                            }
                            porCoordinador[coordinadorId]!.add(doc);
                          }
                        }

                        return FutureBuilder<Map<String, String>>(
                          future: obtenerNombresCoordinadores(idsCoordinadores),
                          builder: (context, futureSnapshot) {
                            Map<String, String> nombresCoordinadores =
                                futureSnapshot.data ?? {};

                            Map<String, bool> groupExpandedStates = {};
                            Map<String, bool> expandedStates = {};

                            if (_searchTerm.isNotEmpty) {
                              if (sinCoordinador.isNotEmpty) {
                                groupExpandedStates['Sin_Coordinador'] = true;
                              }

                              porCoordinador.keys.forEach((key) {
                                groupExpandedStates['Coordinador_${key}'] =
                                    true;
                              });

                              if (registrosInactivos.isNotEmpty) {
                                groupExpandedStates['Registros_No_Activos'] =
                                    true;
                              }

                              for (var doc in filteredDocs) {
                                expandedStates[doc.id] = true;
                              }
                            }

                            return Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: ListView(
                                keyboardDismissBehavior:
                                    ScrollViewKeyboardDismissBehavior.onDrag,
                                children: [
                                  if (sinCoordinador.isNotEmpty)
                                    _buildGrupo(
                                      context,
                                      'Sin Coordinador',
                                      sinCoordinador,
                                      primaryTeal,
                                      secondaryOrange,
                                      accentGrey,
                                      backgroundGrey,
                                      expandedStates,
                                      groupExpandedStates,
                                    ),
                                  ...porCoordinador.entries.map(
                                    (entry) => _buildGrupo(
                                      context,
                                      'Coordinador: ${nombresCoordinadores[entry.key] ?? "Desconocido"}',
                                      entry.value,
                                      primaryTeal,
                                      secondaryOrange,
                                      accentGrey,
                                      backgroundGrey,
                                      expandedStates,
                                      groupExpandedStates,
                                    ),
                                  ),
                                  if (registrosInactivos.isNotEmpty)
                                    _buildGrupoInactivos(
                                      context,
                                      'Registros No Activos',
                                      registrosInactivos,
                                      primaryTeal,
                                      secondaryOrange,
                                      accentGrey,
                                      backgroundGrey,
                                      expandedStates,
                                      groupExpandedStates,
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
            ),

            // 🎯 BOTÓN FLOTANTE PARA REGISTRAR MIEMBRO
            Positioned(
              right: 16,
              bottom: 16,
              child: Material(
                elevation: 6,
                shadowColor: secondaryOrange.withOpacity(0.3),
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  onTap: () {
                    final tribusState =
                        context.findAncestorStateOfType<_TribusScreenState>();
                    if (tribusState != null) {
                      tribusState._showRegistroDialog(context);
                    }
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal:
                          MediaQuery.of(context).size.width < 360 ? 12 : 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          secondaryOrange,
                          secondaryOrange.withOpacity(0.85),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: secondaryOrange.withOpacity(0.25),
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.person_add_alt_1_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        if (MediaQuery.of(context).size.width >= 360) ...[
                          SizedBox(width: 10),
                          Text(
                            'Registrar',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

// 🎨 MÉTODO AUXILIAR PARA DROPDOWNS COMPACTOS
  Widget _buildDropdownFiltroCompacto({
    required String label,
    required IconData icon,
    required String? value,
    required List<String> items,
    String Function(String)? itemBuilder,
    required Function(String?) onChanged,
    required Color primaryTeal,
    required Color accentGrey,
    required Color backgroundGrey,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundGrey.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: primaryTeal.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: primaryTeal,
            size: 16,
          ),
          SizedBox(width: 8),
          Text(
            '$label:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: accentGrey,
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value ?? 'Todos',
                isDense: true,
                isExpanded: true,
                icon: Icon(
                  Icons.arrow_drop_down_rounded,
                  color: primaryTeal,
                  size: 20,
                ),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
                items: items.map((item) {
                  String displayText =
                      itemBuilder != null ? itemBuilder(item) : item;
                  return DropdownMenuItem<String>(
                    value: item == 'Todos' ? null : item,
                    child: Text(
                      displayText,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // NUEVO: Método específico para construir el grupo de registros inactivos
  Widget _buildGrupoInactivos(
    BuildContext context,
    String titulo,
    List<DocumentSnapshot> registros,
    Color primaryTeal,
    Color secondaryOrange,
    Color accentGrey,
    Color backgroundGrey,
    Map<String, bool> expandedStates,
    Map<String, bool> groupExpandedStates,
  ) {
    String groupKey = 'Registros_No_Activos';
    bool isGroupExpanded = groupExpandedStates[groupKey] ?? false;

    return StatefulBuilder(
      builder: (context, setStateLocal) {
        return Container(
          margin: EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.1),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: Colors.red.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              // Encabezado del grupo inactivo
              InkWell(
                onTap: () {
                  setStateLocal(() {
                    groupExpandedStates[groupKey] = !isGroupExpanded;
                    isGroupExpanded = groupExpandedStates[groupKey]!;
                  });
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.red.withOpacity(0.1),
                        Colors.red.withOpacity(0.05),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.cancel_outlined,
                          color: Colors.red[700],
                          size: 20,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              titulo,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.red[700],
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              '${registros.length} registro${registros.length != 1 ? 's' : ''} inactivo${registros.length != 1 ? 's' : ''}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.red[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${registros.length}',
                          style: TextStyle(
                            color: Colors.red[700],
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      AnimatedRotation(
                        turns: isGroupExpanded ? 0.5 : 0,
                        duration: Duration(milliseconds: 200),
                        child: Icon(
                          Icons.expand_more,
                          color: Colors.red[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Lista de registros inactivos
              AnimatedContainer(
                duration: Duration(milliseconds: 300),
                height: isGroupExpanded ? null : 0,
                child: isGroupExpanded
                    ? Column(
                        children: registros.map((registro) {
                          final data = registro.data() as Map<String, dynamic>;
                          final nombre = data['nombre'] ?? '';
                          final apellido = data['apellido'] ?? '';
                          final telefono = data['telefono'] ?? '';
                          final edad = data['edad']?.toString() ?? '';
                          final sexo = data['sexo'] ?? '';

                          bool isExpanded =
                              expandedStates[registro.id] ?? false;

                          return Container(
                            margin: EdgeInsets.fromLTRB(16, 0, 16, 8),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.red.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                InkWell(
                                  onTap: () {
                                    setStateLocal(() {
                                      expandedStates[registro.id] = !isExpanded;
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: EdgeInsets.all(12),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 20,
                                          backgroundColor:
                                              Colors.red.withOpacity(0.2),
                                          child: Icon(
                                            sexo.toLowerCase() == 'mujer'
                                                ? Icons.female
                                                : Icons.male,
                                            color: Colors.red[700],
                                            size: 20,
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '$nombre $apellido',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14,
                                                  color: Colors.red[800],
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              if (telefono.isNotEmpty)
                                                Text(
                                                  telefono,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.red[600],
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        if (edad.isNotEmpty)
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color:
                                                  Colors.red.withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              '$edad años',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.red[700],
                                              ),
                                            ),
                                          ),
                                        SizedBox(width: 8),
                                        // Botón de editar
                                        IconButton(
                                          onPressed: () {
                                            _editarRegistro(context, registro);
                                          },
                                          icon: Icon(
                                            Icons.edit,
                                            color: Colors.red[600],
                                            size: 18,
                                          ),
                                          constraints: BoxConstraints(
                                            minWidth: 32,
                                            minHeight: 32,
                                          ),
                                          padding: EdgeInsets.all(4),
                                        ),
                                        AnimatedRotation(
                                          turns: isExpanded ? 0.5 : 0,
                                          duration: Duration(milliseconds: 200),
                                          child: Icon(
                                            Icons.expand_more,
                                            color: Colors.red[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                // Detalles expandidos
                                if (isExpanded)
                                  Container(
                                    padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Divider(
                                            color: Colors.red.withOpacity(0.3)),
                                        SizedBox(height: 8),
                                        _buildDetalleInactivo(
                                            'Dirección', data['direccion']),
                                        _buildDetalleInactivo(
                                            'Barrio', data['barrio']),
                                        _buildDetalleInactivo('Estado Civil',
                                            data['estadoCivil']),
                                        if (data['nombrePareja'] != null &&
                                            data['nombrePareja']
                                                .toString()
                                                .isNotEmpty)
                                          _buildDetalleInactivo(
                                              'Pareja', data['nombrePareja']),
                                        _buildDetalleInactivo('Ocupación',
                                            data['descripcionOcupacion']),
                                        if (data['observaciones'] != null &&
                                            data['observaciones']
                                                .toString()
                                                .isNotEmpty)
                                          _buildDetalleInactivo('Observaciones',
                                              data['observaciones']),

                                        // Información de estado inactivo
                                        SizedBox(height: 8),
                                        Container(
                                          padding: EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.red.withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(Icons.info_outline,
                                                  color: Colors.red[700],
                                                  size: 16),
                                              SizedBox(width: 6),
                                              Text(
                                                'Registro inactivo - Sin asignaciones',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.red[700],
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }).toList(),
                      )
                    : SizedBox.shrink(),
              ),
            ],
          ),
        );
      },
    );
  }

  // NUEVO: Método auxiliar para mostrar detalles en registros inactivos
  Widget _buildDetalleInactivo(String label, dynamic value) {
    if (value == null || value.toString().isEmpty) return SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.red[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.toString(),
              style: TextStyle(
                fontSize: 11,
                color: Colors.red[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

// Nueva función para obtener nombres de coordinadores
  Future<Map<String, String>> obtenerNombresCoordinadores(
      List<String> coordinadorIds) async {
    Map<String, String> nombresCoordinadores = {};

    if (coordinadorIds.isEmpty) return nombresCoordinadores;

    try {
      var snapshot = await FirebaseFirestore.instance
          .collection('coordinadores')
          .where(FieldPath.documentId, whereIn: coordinadorIds)
          .get();

      for (var doc in snapshot.docs) {
        var data = doc.data();
        nombresCoordinadores[doc.id] = "${data['nombre']} ${data['apellido']}";
      }
    } catch (e) {
      print("Error obteniendo nombres de coordinadores: $e");
    }

    return nombresCoordinadores;
  }

  Widget _buildGrupo(
      BuildContext context,
      String titulo,
      List<DocumentSnapshot> registros,
      Color primaryTeal,
      Color secondaryOrange,
      Color accentGrey,
      Color backgroundGrey,
      Map<String, bool> expandedStates,
      Map<String, bool> groupExpandedStates) {
    final String groupId = titulo.replaceAll(' ', '_');

    // Inicializa el estado de expansión del grupo si no existe
    groupExpandedStates[groupId] ??= false;

    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        return Card(
          margin: EdgeInsets.only(bottom: 16),
          elevation: 3,
          shadowColor: primaryTeal.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: primaryTeal.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              // Encabezado del grupo
              GestureDetector(
                onTap: () {
                  setState(() {
                    groupExpandedStates[groupId] =
                        !groupExpandedStates[groupId]!;
                  });
                },
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: primaryTeal.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: primaryTeal.withOpacity(0.5),
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            titulo.contains('Sin')
                                ? Icons.person_off_outlined
                                : Icons.supervisor_account,
                            color: primaryTeal,
                            size: 24,
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              titulo,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: primaryTeal,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '${registros.length} ${registros.length == 1 ? 'joven' : 'jóvenes'}',
                              style: TextStyle(
                                color: accentGrey,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        groupExpandedStates[groupId]!
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        size: 24,
                        color: primaryTeal,
                      ),
                    ],
                  ),
                ),
              ),
              // Lista de registros si el grupo está expandido
              if (groupExpandedStates[groupId]!)
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: registros.length,
                  itemBuilder: (context, index) {
                    final registro = registros[index];
                    final data = registro.data() as Map<String, dynamic>? ?? {};
                    final registroId = registro.id;

                    // Acceso seguro con valores por defecto
                    final nombre = data['nombre'] as String? ?? '';
                    final apellido = data['apellido'] as String? ?? '';
                    final telefono =
                        data['telefono'] as String? ?? 'No disponible';
                    final ministerioAsignado =
                        data['ministerioAsignado'] ?? 'Sin ministerio';

                    String iniciales = '';
                    if (nombre.isNotEmpty && nombre.length >= 1) {
                      iniciales += nombre[0];
                    }
                    if (apellido.isNotEmpty && apellido.length >= 1) {
                      iniciales += apellido[0];
                    }
                    if (iniciales.isEmpty) {
                      iniciales = '?';
                    }

                    // Determinamos un color de fondo aleatorio pero consistente para las iniciales
                    final List<Color> avatarColors = [
                      primaryTeal,
                      secondaryOrange,
                      accentGrey,
                    ];

                    // Usamos la suma de los códigos de caracteres para generar un índice
                    int colorIndex = 0;
                    if (iniciales.isNotEmpty) {
                      colorIndex = iniciales.codeUnits.reduce((a, b) => a + b) %
                          avatarColors.length;
                    }

                    // Utilizamos un StatefulBuilder para manejar el estado de expansión
                    return StatefulBuilder(
                      builder: (BuildContext context, StateSetter setState) {
                        // Inicializamos el estado de expansión si no existe
                        expandedStates[registroId] ??= false;

                        // FUNCIONALIDAD: Detectar si es un registro nuevo
                        DateTime? fechaTribu = (data['fechaAsignacionTribu']
                                    as Timestamp?)
                                ?.toDate() ??
                            (data['fechaAsignacion'] as Timestamp?)?.toDate();
                        DateTime? fechaCoord =
                            (data['fechaAsignacionCoordinador'] as Timestamp?)
                                ?.toDate();
                        DateTime? fechaTimoteo =
                            (data['fechaAsignacionTimoteo'] as Timestamp?)
                                ?.toDate();

                        // Obtener la fecha más reciente de asignación
                        DateTime? fechaMasReciente = [
                          fechaTribu,
                          fechaCoord,
                          fechaTimoteo
                        ].whereType<DateTime>().fold<DateTime?>(
                            null,
                            (prev, curr) => prev == null || curr.isAfter(prev)
                                ? curr
                                : prev);

                        bool esNuevo = fechaMasReciente != null &&
                            DateTime.now()
                                    .difference(fechaMasReciente)
                                    .inDays <=
                                14;

                        int diasDesdeAsignacion = fechaMasReciente != null
                            ? DateTime.now().difference(fechaMasReciente).inDays
                            : 0;

                        // Colores dinámicos según antiguedad
                        Color colorTarjeta =
                            esNuevo ? Colors.amber.shade50 : Colors.white;
                        Color colorBorde = esNuevo
                            ? Colors.amber.withOpacity(0.4)
                            : primaryTeal.withOpacity(0.1);
                        Color colorSombra = esNuevo
                            ? Colors.amber.withOpacity(0.2)
                            : primaryTeal.withOpacity(0.1);

                        return Container(
                          margin:
                              EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Stack(
                            children: [
                              Card(
                                margin: EdgeInsets.zero,
                                elevation: esNuevo ? 4 : 2,
                                shadowColor: colorSombra,
                                color: colorTarjeta,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: colorBorde,
                                    width: esNuevo ? 2 : 1,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    // Indicador visual para registros nuevos
                                    if (esNuevo)
                                      Container(
                                        width: double.infinity,
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.amber.shade100,
                                              Colors.amber.shade200,
                                            ],
                                            begin: Alignment.centerLeft,
                                            end: Alignment.centerRight,
                                          ),
                                          borderRadius: BorderRadius.only(
                                            topLeft: Radius.circular(10),
                                            topRight: Radius.circular(10),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.fiber_new,
                                              color: Colors.amber.shade700,
                                              size: 16,
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              diasDesdeAsignacion == 0
                                                  ? 'RECIÉN ASIGNADO'
                                                  : 'NUEVO - ${diasDesdeAsignacion} día${diasDesdeAsignacion != 1 ? 's' : ''}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.amber.shade700,
                                              ),
                                            ),
                                            Spacer(),
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.amber.shade700,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                '${14 - diasDesdeAsignacion} días restantes',
                                                style: TextStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                    // Parte superior de la tarjeta con información básica
                                    GestureDetector(
                                      onTap: () {
                                        // NUEVO: Imprimir ID del registro en consola
                                        print(
                                            "ID del registro seleccionado:: ${registro.id}, Nombre: $nombre $apellido");

                                        setState(() {
                                          // Invertimos el estado de expansión al tocar
                                          expandedStates[registroId] =
                                              !expandedStates[registroId]!;
                                        });
                                      },
                                      child: Padding(
                                        padding: EdgeInsets.all(16),
                                        child: Row(
                                          children: [
                                            // Avatar con iniciales
                                            Container(
                                              width: 40,
                                              height: 40,
                                              decoration: BoxDecoration(
                                                color: avatarColors[colorIndex]
                                                    .withOpacity(0.2),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                border: Border.all(
                                                  color:
                                                      avatarColors[colorIndex]
                                                          .withOpacity(0.5),
                                                  width: 1.5,
                                                ),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  iniciales,
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: avatarColors[
                                                        colorIndex],
                                                  ),
                                                ),
                                              ),
                                            ),
                                            SizedBox(width: 16),
                                            // Información del registro
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    '$nombre $apellido',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: primaryTeal,
                                                    ),
                                                  ),
                                                  SizedBox(height: 4),
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        Icons.phone_outlined,
                                                        size: 14,
                                                        color: accentGrey,
                                                      ),
                                                      SizedBox(width: 4),
                                                      Text(
                                                        telefono,
                                                        style: TextStyle(
                                                          color: accentGrey,
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  SizedBox(height: 4),
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        Icons
                                                            .account_tree_outlined,
                                                        size: 14,
                                                        color: accentGrey,
                                                      ),
                                                      SizedBox(width: 4),
                                                      Text(
                                                        'Ministerio: $ministerioAsignado',
                                                        style: TextStyle(
                                                          color: accentGrey,
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            // Botones de acción
                                            Row(
                                              children: [
                                                // Botón de ver detalles
                                                Material(
                                                  color: Colors.transparent,
                                                  child: InkWell(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                    onTap: () {
                                                      // NUEVO: Imprimir ID cuando se ven detalles
                                                      print(
                                                          "ID del registro Ver detalles del registro: ${registro.id}, Nombre: $nombre $apellido");

                                                      _mostrarDetallesRegistro(
                                                        context,
                                                        data,
                                                        primaryTeal,
                                                        secondaryOrange,
                                                        accentGrey,
                                                        backgroundGrey,
                                                      );
                                                    },
                                                    child: Container(
                                                      padding:
                                                          EdgeInsets.all(10),
                                                      decoration: BoxDecoration(
                                                        color: primaryTeal
                                                            .withOpacity(0.1),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(12),
                                                      ),
                                                      child: Icon(
                                                        Icons
                                                            .visibility_outlined,
                                                        color: primaryTeal,
                                                        size: 22,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(width: 8),
                                                // Botón condicional basado en si tiene coordinador asignado
                                                data.containsKey(
                                                            'coordinadorAsignado') &&
                                                        data['coordinadorAsignado'] !=
                                                            null
                                                    ? Material(
                                                        color:
                                                            Colors.transparent,
                                                        child: InkWell(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(12),
                                                          onTap: () {
                                                            // NUEVO: Imprimir ID cuando se quita asignación
                                                            print(
                                                                "Quitar asignación del registro: ${registro.id}");
                                                            _quitarAsignacion(
                                                                context,
                                                                registroId,
                                                                primaryTeal);
                                                          },
                                                          child: Container(
                                                            padding:
                                                                EdgeInsets.all(
                                                                    10),
                                                            decoration:
                                                                BoxDecoration(
                                                              color: Colors.red
                                                                  .withOpacity(
                                                                      0.1),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          12),
                                                            ),
                                                            child: Icon(
                                                              Icons
                                                                  .person_remove_outlined,
                                                              color: Colors.red,
                                                              size: 22,
                                                            ),
                                                          ),
                                                        ),
                                                      )
                                                    : !data.containsKey(
                                                                'coordinadorAsignado') ||
                                                            data['coordinadorAsignado'] ==
                                                                null
                                                        ? Material(
                                                            color: Colors
                                                                .transparent,
                                                            child: InkWell(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          12),
                                                              onTap: () {
                                                                // NUEVO: Imprimir ID cuando se asigna coordinador
                                                                print(
                                                                    "Asignar coordinador al registro: ${registro.id}");
                                                                _asignarACoordinador(
                                                                    context,
                                                                    registro);
                                                              },
                                                              child: Container(
                                                                padding:
                                                                    EdgeInsets
                                                                        .all(
                                                                            10),
                                                                decoration:
                                                                    BoxDecoration(
                                                                  color: secondaryOrange
                                                                      .withOpacity(
                                                                          0.1),
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              12),
                                                                ),
                                                                child: Icon(
                                                                  Icons
                                                                      .person_add_alt_1_outlined,
                                                                  color:
                                                                      secondaryOrange,
                                                                  size: 22,
                                                                ),
                                                              ),
                                                            ),
                                                          )
                                                        : SizedBox(),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    // Información adicional para registros nuevos
                                    if (esNuevo && fechaMasReciente != null)
                                      Container(
                                        margin: EdgeInsets.symmetric(
                                            horizontal: 16),
                                        padding: EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.amber.shade50,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                            color: Colors.amber.shade200,
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.schedule_outlined,
                                              size: 14,
                                              color: Colors.amber.shade700,
                                            ),
                                            SizedBox(width: 6),
                                            Text(
                                              'Asignado el: ${fechaMasReciente.day}/${fechaMasReciente.month}/${fechaMasReciente.year}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.amber.shade700,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            Spacer(),
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: diasDesdeAsignacion <= 3
                                                    ? Colors.red.shade100
                                                    : Colors.blue.shade100,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                diasDesdeAsignacion <= 3
                                                    ? 'PRIORIDAD ALTA'
                                                    : 'Seguimiento',
                                                style: TextStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                  color: diasDesdeAsignacion <=
                                                          3
                                                      ? Colors.red.shade700
                                                      : Colors.blue.shade700,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                    // Botón para expandir en la parte inferior de la tarjeta
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: Padding(
                                        padding: EdgeInsets.only(
                                            right: 16, bottom: 8),
                                        child: InkWell(
                                          onTap: () {
                                            setState(() {
                                              // Invertimos el estado de expansión con el botón
                                              expandedStates[registroId] =
                                                  !expandedStates[registroId]!;
                                            });
                                          },
                                          child: Container(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 4),
                                            decoration: BoxDecoration(
                                              color:
                                                  primaryTeal.withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  expandedStates[registroId]!
                                                      ? 'Menos'
                                                      : 'Más',
                                                  style: TextStyle(
                                                    color: primaryTeal,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                SizedBox(width: 4),
                                                Icon(
                                                  expandedStates[registroId]!
                                                      ? Icons.keyboard_arrow_up
                                                      : Icons
                                                          .keyboard_arrow_down,
                                                  size: 16,
                                                  color: primaryTeal,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),

                                    // Sección expandible
                                    if (expandedStates[registroId]!)
                                      Container(
                                        padding: EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color:
                                              backgroundGrey.withOpacity(0.5),
                                          borderRadius: BorderRadius.only(
                                            bottomLeft: Radius.circular(16),
                                            bottomRight: Radius.circular(16),
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Detalles Adicionales',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: primaryTeal,
                                              ),
                                            ),
                                            SizedBox(height: 16),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceEvenly,
                                              children: [
                                                Column(
                                                  children: [
                                                    Material(
                                                      color: Colors.transparent,
                                                      child: InkWell(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(12),
                                                        onTap: () {
                                                          // Lógica para editar registro
                                                          _editarRegistro(
                                                              context,
                                                              registro);
                                                        },
                                                        child: Container(
                                                          padding:
                                                              EdgeInsets.all(
                                                                  12),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: primaryTeal
                                                                .withOpacity(
                                                                    0.1),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        12),
                                                          ),
                                                          child: Column(
                                                            children: [
                                                              Icon(
                                                                Icons
                                                                    .edit_outlined,
                                                                color:
                                                                    primaryTeal,
                                                                size: 28,
                                                              ),
                                                              SizedBox(
                                                                  height: 4),
                                                              Text(
                                                                'Editar',
                                                                style:
                                                                    TextStyle(
                                                                  color:
                                                                      primaryTeal,
                                                                  fontSize: 12,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Column(
                                                  children: [
                                                    Material(
                                                      color: Colors.transparent,
                                                      child: InkWell(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(12),
                                                        onTap: () {
                                                          // Lógica para cambiar ministerio o tribu
                                                          _cambiarMinisterioTribu(
                                                              context,
                                                              registro);
                                                        },
                                                        child: Container(
                                                          padding:
                                                              EdgeInsets.all(
                                                                  12),
                                                          decoration:
                                                              BoxDecoration(
                                                            color:
                                                                secondaryOrange
                                                                    .withOpacity(
                                                                        0.1),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        12),
                                                          ),
                                                          child: Column(
                                                            children: [
                                                              Icon(
                                                                Icons
                                                                    .swap_horiz_outlined,
                                                                color:
                                                                    secondaryOrange,
                                                                size: 28,
                                                              ),
                                                              SizedBox(
                                                                  height: 4),
                                                              Text(
                                                                'Cambiar',
                                                                style:
                                                                    TextStyle(
                                                                  color:
                                                                      secondaryOrange,
                                                                  fontSize: 12,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),

                              // Badge flotante para registros muy nuevos (0-2 días)
                              if (esNuevo && diasDesdeAsignacion <= 2)
                                Positioned(
                                  top: -5,
                                  right: -5,
                                  child: Container(
                                    padding: EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.red.shade400,
                                          Colors.red.shade600
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.red.withOpacity(0.3),
                                          blurRadius: 4,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.priority_high,
                                      color: Colors.white,
                                      size: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

// Agregar después de la función _editarRegistro o antes del método build
  Future<void> _cambiarMinisterioTribu(
      BuildContext context, DocumentSnapshot registro) async {
    if (context == null || registro == null) {
      print('Error: Contexto o registro nulo');
      return;
    }

    final registroId = registro.id;
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    final Color primaryTeal = Color(0xFF038C7F);
    final Color secondaryOrange = Color(0xFFFF5722);
    final Color accentGrey = Color(0xFF78909C);

    try {
      final registroDoc =
          await _firestore.collection('registros').doc(registroId).get();
      if (!registroDoc.exists) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('El registro no existe o ha sido eliminado.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      List<DropdownMenuItem<String>> opciones = [];
      String? opcionSeleccionada;

      try {
        opciones.addAll([
          DropdownMenuItem(
            value: 'Ministerio de Damas',
            child: _buildOption(
                'Ministerio de Damas', Icons.female, Colors.pinkAccent),
          ),
          DropdownMenuItem(
            value: 'Ministerio de Caballeros',
            child: _buildOption(
                'Ministerio de Caballeros', Icons.male, Colors.blueAccent),
          ),
          DropdownMenuItem(
            value: 'separator',
            enabled: false,
            child: Divider(thickness: 2, color: Colors.grey.shade400),
          ),
          DropdownMenuItem(
            value: 'juveniles_title',
            enabled: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'Tribus del Ministerio Juvenil',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: primaryTeal,
                    fontSize: 16),
              ),
            ),
          ),
        ]);

        final tribusSnapshot = await _firestore
            .collection('tribus')
            .where('categoria', isEqualTo: 'Ministerio Juvenil')
            .get();

        final sortedDocs = tribusSnapshot.docs
          ..sort((a, b) => (a.data()?['nombre'] as String? ?? '')
              .compareTo(b.data()?['nombre'] as String? ?? ''));

        for (var doc in sortedDocs) {
          final nombre = doc.data()?['nombre'] ?? 'Sin nombre';
          opciones.add(DropdownMenuItem(
            value: doc.id,
            child: _buildOption(nombre, Icons.people, primaryTeal),
          ));
        }

        if (opciones.length <= 4 && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('No hay tribus juveniles disponibles para asignar.'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }

        // Obtener el valor actual para preseleccionar
        final data = registroDoc.data() as Map<String, dynamic>?;
        if (data == null) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Error: No se pudieron cargar los datos del registro.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        final ministerioActual = data['ministerioAsignado'] as String?;
        final tribuActual = data['tribuAsignada'] as String?;

        if (ministerioActual != null &&
            ministerioActual.contains('Ministerio')) {
          opcionSeleccionada = ministerioActual;
        } else if (tribuActual != null) {
          opcionSeleccionada = tribuActual;
        }

        if (!context.mounted) return;

        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return StatefulBuilder(
              builder: (context, setState) {
                return AlertDialog(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  title: Row(
                    children: [
                      Icon(Icons.swap_horiz, color: primaryTeal),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Cambiar Ministerio o Tribu',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: primaryTeal),
                        ),
                      ),
                    ],
                  ),
                  content: Container(
                    width: double.maxFinite,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Seleccione el nuevo ministerio o tribu para:',
                          style: TextStyle(fontSize: 14, color: accentGrey),
                        ),
                        SizedBox(height: 5),
                        Text(
                          '${data['nombre'] ?? ''} ${data['apellido'] ?? ''}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: secondaryOrange,
                          ),
                        ),
                        SizedBox(height: 15),
                        Text(
                          'Asignación actual:',
                          style: TextStyle(fontSize: 14, color: accentGrey),
                        ),
                        SizedBox(height: 5),
                        Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: primaryTeal.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                            border:
                                Border.all(color: primaryTeal.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                ministerioActual?.contains('Damas') == true
                                    ? Icons.female
                                    : ministerioActual
                                                ?.contains('Caballeros') ==
                                            true
                                        ? Icons.male
                                        : Icons.people,
                                color: primaryTeal,
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  ministerioActual == null
                                      ? 'Sin asignación'
                                      : tribuActual != null
                                          ? 'Ministerio Juvenil - ${data['nombreTribu'] ?? 'Tribu sin nombre'}'
                                          : ministerioActual.contains('Damas')
                                              ? 'Ministerio de Damas'
                                              : ministerioActual
                                                      .contains('Caballeros')
                                                  ? 'Ministerio de Caballeros'
                                                  : ministerioActual,
                                  style: TextStyle(color: primaryTeal),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 20),
                        DropdownButtonFormField<String>(
                          value: opcionSeleccionada,
                          items: opciones,
                          onChanged: (value) {
                            if (value != null &&
                                value != 'separator' &&
                                value != 'juveniles_title') {
                              setState(() {
                                opcionSeleccionada = value;
                              });
                            }
                          },
                          decoration: InputDecoration(
                            labelText: 'Nueva asignación',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: primaryTeal),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: primaryTeal, width: 2),
                            ),
                            labelStyle: TextStyle(color: primaryTeal),
                            prefixIcon:
                                Icon(Icons.swap_horiz, color: primaryTeal),
                          ),
                          isExpanded: true,
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancelar',
                        style: TextStyle(color: accentGrey),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryTeal,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: opcionSeleccionada == null
                          ? null
                          : () async {
                              try {
                                // Mostrar confirmación antes de realizar el cambio
                                String mensajeConfirmacion =
                                    opcionSeleccionada!.contains('Ministerio')
                                        ? opcionSeleccionada!
                                        : 'Ministerio Juvenil - ' +
                                            await _obtenerNombreTribu(
                                                opcionSeleccionada!);

                                bool confirmar = await _mostrarConfirmacion(
                                  context,
                                  'Confirmar cambio',
                                  '¿Está seguro de cambiar a "$mensajeConfirmacion"?',
                                  primaryTeal,
                                  secondaryOrange,
                                );

                                if (confirmar) {
                                  Navigator.pop(context);
                                  if (context.mounted) {
                                    // ✅ LLAMAR A LA FUNCIÓN CORREGIDA
                                    await _procesarCambioAsignacionCorregida(
                                        context,
                                        registroId,
                                        opcionSeleccionada!,
                                        primaryTeal,
                                        _firestore,
                                        tribusSnapshot);
                                  }
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'Error al procesar la confirmación: ${e.toString()}'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                      child: Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        child: Text('Cambiar'),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al cargar las opciones: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error inesperado: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

// ✅ FUNCIÓN NUEVA CORREGIDA: Procesa el cambio de asignación correctamente
  Future<void> _procesarCambioAsignacionCorregida(
    BuildContext context,
    String registroId,
    String seleccion,
    Color primaryTeal,
    FirebaseFirestore firestore,
    QuerySnapshot tribusSnapshot,
  ) async {
    try {
      print('=== INICIO PROCESAMIENTO CAMBIO ASIGNACIÓN ===');
      print('Registro ID: $registroId');
      print('Selección: $seleccion');

      // ✅ LÓGICA CORREGIDA: Determinar datos de asignación
      String? ministerioAsignado;
      String? tribuAsignada;
      String? nombreTribu;

      if (seleccion.contains('Ministerio')) {
        // Es un ministerio directo (Damas o Caballeros)
        ministerioAsignado = seleccion;
        tribuAsignada = null;
        nombreTribu = null;
      } else {
        // Es una tribu del Ministerio Juvenil
        ministerioAsignado = 'Ministerio Juvenil'; // ✅ CORRECCIÓN PRINCIPAL
        tribuAsignada = seleccion;

        // Obtener el nombre de la tribu
        try {
          final tribuDoc = tribusSnapshot.docs.firstWhere(
            (doc) => doc.id == seleccion,
            orElse: () => throw Exception('Tribu no encontrada en snapshot'),
          );
          nombreTribu = tribuDoc['nombre'] ?? 'Tribu sin nombre';
        } catch (e) {
          // Si no se encuentra en el snapshot, consultar directamente
          final tribuDocDirecto =
              await firestore.collection('tribus').doc(seleccion).get();
          if (tribuDocDirecto.exists) {
            nombreTribu =
                tribuDocDirecto.data()?['nombre'] ?? 'Tribu sin nombre';
          } else {
            nombreTribu = 'Tribu sin nombre';
          }
        }
      }

      print('Ministerio a asignar: $ministerioAsignado');
      print('Tribu a asignar: $tribuAsignada');
      print('Nombre tribu: $nombreTribu');

      // ✅ PREPARAR DATOS DE ACTUALIZACIÓN
      Map<String, dynamic> updateData = {
        'ministerioAsignado': ministerioAsignado,
        'tribuAsignada': tribuAsignada,
        'fechaAsignacion': FieldValue.serverTimestamp(),
        // Limpiar campos relacionados con coordinador y timoteo
        'coordinadorAsignado': null,
        'timoteoAsignado': null,
        'nombreTimoteo': null,
      };

      // Agregar o limpiar nombreTribu según corresponda
      if (nombreTribu != null) {
        updateData['nombreTribu'] = nombreTribu;
      } else {
        updateData['nombreTribu'] = null;
      }

      print('Datos a actualizar: $updateData');

      // ✅ ACTUALIZAR EN FIRESTORE
      await firestore
          .collection('registros')
          .doc(registroId)
          .update(updateData);

      // ✅ VERIFICACIÓN POST-ACTUALIZACIÓN
      await Future.delayed(Duration(milliseconds: 500));
      final docVerificacion =
          await firestore.collection('registros').doc(registroId).get();

      if (docVerificacion.exists) {
        final data = docVerificacion.data() as Map<String, dynamic>;
        print('=== VERIFICACIÓN POST-ACTUALIZACIÓN ===');
        print('ministerioAsignado guardado: ${data['ministerioAsignado']}');
        print('tribuAsignada guardada: ${data['tribuAsignada']}');
        print('nombreTribu guardado: ${data['nombreTribu']}');
        print('=======================================');
      }

      // ✅ MOSTRAR MENSAJE DE ÉXITO
      if (context.mounted) {
        String mensajeExito;
        if (ministerioAsignado != null && tribuAsignada != null) {
          mensajeExito =
              '✅ Cambiado a tribu "$nombreTribu" del $ministerioAsignado';
        } else if (ministerioAsignado != null) {
          mensajeExito = '✅ Cambiado al $ministerioAsignado';
        } else {
          mensajeExito = '✅ Asignación cambiada exitosamente';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 10),
                Expanded(child: Text(mensajeExito)),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: EdgeInsets.all(12),
            duration: Duration(seconds: 4),
          ),
        );
      }

      print('=== FIN PROCESAMIENTO EXITOSO ===');
    } catch (e) {
      print('❌ ERROR en _procesarCambioAsignacionCorregida: $e');
      print('Stack trace: ${StackTrace.current}');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 10),
                Expanded(
                  child: Text('❌ Error al cambiar asignación: ${e.toString()}'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: EdgeInsets.all(12),
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<bool> _mostrarConfirmacion(
    BuildContext context,
    String titulo,
    String mensaje,
    Color primaryColor,
    Color secondaryColor,
  ) async {
    if (context == null) {
      print('Error: Contexto nulo en mostrarConfirmacion');
      return false;
    }

    bool resultado = false;

    try {
      await showDialog(
        context: context,
        builder: (dialogContext) {
          if (dialogContext == null) return Container();

          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Icon(Icons.help_outline, color: primaryColor),
                SizedBox(width: 10),
                Text(titulo,
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: primaryColor)),
              ],
            ),
            content: Text(mensaje ?? 'Confirmar acción'),
            actions: [
              TextButton(
                onPressed: () {
                  resultado = false;
                  Navigator.pop(dialogContext);
                },
                child: Text('Cancelar', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  resultado = true;
                  Navigator.pop(dialogContext);
                },
                child: Text('Confirmar'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      print('Error en diálogo de confirmación: $e');
      return false;
    }

    return resultado;
  }

  Future<String> _obtenerNombreTribu(String tribuId) async {
    if (tribuId == null || tribuId.isEmpty) {
      return 'Tribu sin nombre';
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('tribus')
          .doc(tribuId)
          .get();
      if (doc.exists && doc.data() != null) {
        return doc.data()?['nombre'] ?? 'Tribu sin nombre';
      }
    } catch (e) {
      print('Error al obtener nombre de tribu: $e');
    }
    return 'Tribu sin nombre';
  }

// ✅ FUNCIÓN AUXILIAR: Para construir opciones del dropdown
/*Widget _buildOption(String text, IconData icon, Color color) {
  return Row(
    children: [
      Icon(icon, color: color, size: 18),
      SizedBox(width: 8),
      Expanded(child: Text(text)),
    ],
  );
}*/

  Future<void> _procesarCambioAsignacion(
    BuildContext context,
    String registroId,
    String opcionSeleccionada,
    Color primaryColor,
  ) async {
    if (context == null || registroId == null || opcionSeleccionada == null) {
      print('Error: Parámetros nulos en _procesarCambioAsignacion');
      return;
    }

    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    BuildContext? dialogContext;

    // Mostrar indicador de carga y capturar su contexto
    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (loadingContext) {
        dialogContext = loadingContext; // Guardar el contexto del diálogo
        return Center(
          child: CircularProgressIndicator(color: primaryColor),
        );
      },
    );

    try {
      Map<String, dynamic> datosActualizacion = {
        'tribuAsignada': null,
        'ministerioAsignado': null,
        'coordinadorAsignado': null,
        'timoteoAsignado': null,
        'nombreTimoteo': null,
        'fechaAsignacion': FieldValue.serverTimestamp(),
      };

      String mensajeExito = '';

      if (opcionSeleccionada.contains('Ministerio')) {
        // Es un ministerio
        datosActualizacion['ministerioAsignado'] = opcionSeleccionada;
        datosActualizacion['tribuAsignada'] = null;
        datosActualizacion['nombreTribu'] = null;
        mensajeExito =
            'Registro asignado a "$opcionSeleccionada" correctamente';
      } else {
        // Es una tribu
        datosActualizacion['ministerioAsignado'] = 'Ministerio Juvenil';
        datosActualizacion['tribuAsignada'] = opcionSeleccionada;

        String nombreTribu = 'Sin nombre';
        try {
          // Obtener el nombre de la tribu
          final tribuDoc = await _firestore
              .collection('tribus')
              .doc(opcionSeleccionada)
              .get();
          if (tribuDoc.exists && tribuDoc.data() != null) {
            nombreTribu = tribuDoc.data()?['nombre'] ?? 'Sin nombre';
          }
        } catch (e) {
          print('Error al obtener nombre de tribu: $e');
        }

        datosActualizacion['nombreTribu'] = nombreTribu;
        mensajeExito =
            'Registro asignado a "Ministerio Juvenil - $nombreTribu" correctamente';
      }

      // Realizar la actualización
      await _firestore
          .collection('registros')
          .doc(registroId)
          .update(datosActualizacion);

      // Cerrar el diálogo de carga siempre, usando el contexto específico del diálogo
      if (dialogContext != null && Navigator.canPop(dialogContext!)) {
        Navigator.pop(dialogContext!);
      }

      // Mostrar mensaje de éxito
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text(mensajeExito),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error en _procesarCambioAsignacion: $e');

      // Cerrar el diálogo de carga siempre, usando el contexto específico del diálogo
      if (dialogContext != null && Navigator.canPop(dialogContext!)) {
        Navigator.pop(dialogContext!);
      } else {
        // Intento alternativo de cierre
        try {
          if (context.mounted) {
            Navigator.of(context, rootNavigator: true).pop();
          }
        } catch (navError) {
          print('Error al cerrar diálogo alternativo: $navError');
        }
      }

      // Mostrar error
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cambiar asignación: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

// Agregar esta función para cerrar el diálogo de forma segura
  void _cerrarDialogo(BuildContext context) {
    if (context.mounted && Navigator.canPop(context)) {
      try {
        Navigator.of(context, rootNavigator: true).pop();
      } catch (e) {
        print('Error al cerrar diálogo: $e');
      }
    }
  }

  Widget _buildOption(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon ?? Icons.error_outline, color: color),
        SizedBox(width: 10),
        Text(title ?? 'Opción', style: TextStyle(fontSize: 16)),
      ],
    );
  }

// Widget para campos de texto con animación y mejor diseño
  Widget _buildAnimatedTextField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required Color primaryColor,
    required Function(String) onChanged,
  }) {
    // Asegurar que el controlador nunca sea nulo
    final TextEditingController safeController =
        controller ?? TextEditingController();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        child: TextField(
          controller: safeController,
          onChanged: onChanged,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(
              color: primaryColor.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: Icon(icon, color: primaryColor),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: primaryColor.withOpacity(0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: primaryColor.withOpacity(0.5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: primaryColor, width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          ),
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

// Widget para campos de texto con animación y opciones predefinidas
  Widget _buildAnimatedTextFieldConOpciones({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required Color primaryColor,
    required List<String> opciones,
    required Function(String) onChanged,
  }) {
    final TextEditingController safeController =
        controller ?? TextEditingController();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            child: TextField(
              controller: safeController,
              onChanged: onChanged,
              decoration: InputDecoration(
                labelText: label,
                labelStyle: TextStyle(
                  color: primaryColor.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                ),
                prefixIcon: Icon(icon, color: primaryColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: primaryColor.withOpacity(0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: primaryColor.withOpacity(0.5)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: primaryColor, width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
              style: const TextStyle(fontSize: 16),
            ),
          ),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: primaryColor.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.touch_app_outlined,
                      size: 14,
                      color: primaryColor,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Opciones rápidas:',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: primaryColor,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: opciones.map((opcion) {
                    return ActionChip(
                      label: Text(
                        opcion,
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                      onPressed: () {
                        safeController.text = opcion;
                        onChanged(opcion);
                      },
                      backgroundColor: Colors.white,
                      side: BorderSide(
                        color: primaryColor.withOpacity(0.3),
                        width: 1.5,
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      elevation: 0,
                      pressElevation: 2,
                      shadowColor: primaryColor.withOpacity(0.3),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

// Widget para campos de selección dropdown con mejor manejo de nulos
  Widget _buildDropdownField({
    required String label,
    required IconData icon,
    required String? value,
    required List<String> items,
    required Color primaryColor,
    required Function(String?) onChanged,
  }) {
    // Asegurar que value no sea nulo
    final String safeValue = value ?? (items.isNotEmpty ? items[0] : '');

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: primaryColor.withOpacity(0.5)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Row(
            children: [
              Icon(icon, color: primaryColor),
              SizedBox(width: 12),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: items.contains(safeValue)
                        ? safeValue
                        : (items.isNotEmpty ? items[0] : null),
                    hint: Text(
                      'Seleccionar $label',
                      style: TextStyle(color: Colors.grey),
                    ),
                    icon: Icon(Icons.arrow_drop_down, color: primaryColor),
                    isExpanded: true,
                    onChanged: onChanged,
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 16,
                    ),
                    dropdownColor: Colors.white,
                    items: items.map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(value),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

// Función para formatear nombres de campos
  String _formatFieldName(String fieldName) {
    // Convertir camelCase a palabras separadas y capitalizar
    final formattedName = fieldName.replaceAllMapped(
        RegExp(r'([A-Z])'), (match) => ' ${match.group(0)}');

    return formattedName[0].toUpperCase() + formattedName.substring(1);
  }

// Manejador para inicializar Firebase Messaging de manera segura
  Future<void> initializeFirebaseMessaging() async {
    try {
      // Comprobar si Firebase Messaging está disponible
      if (FirebaseMessaging.instance != null) {
        // Solicitar permisos de manera silenciosa, sin mostrar pop-up si es posible
        NotificationSettings settings =
            await FirebaseMessaging.instance.requestPermission(
          alert: true,
          announcement: false,
          badge: true,
          carPlay: false,
          criticalAlert: false,
          provisional: true, // Usar notificaciones provisionales para iOS
          sound: true,
        );

        // Solo intentar obtener el token si el usuario ha dado permiso
        if (settings.authorizationStatus == AuthorizationStatus.authorized ||
            settings.authorizationStatus == AuthorizationStatus.provisional) {
          // Obtener token de manera segura
          try {
            String? token = await FirebaseMessaging.instance.getToken();
            if (token != null) {
              print('Token FCM: $token');
              // Guardar el token en algún lugar si es necesario
            }
          } catch (e) {
            print('Error al obtener token FCM: $e');
            // No mostrar error al usuario, manejar silenciosamente
          }
        } else {
          print(
              'Permisos de notificación no concedidos: ${settings.authorizationStatus}');
          // No mostrar error al usuario, manejar silenciosamente
        }
      }
    } catch (e) {
      print('Error al inicializar Firebase Messaging: $e');
      // No mostrar error al usuario, manejar silenciosamente
    }
  }

  void _quitarAsignacion(
      BuildContext context, String registroId, Color primaryTeal) async {
    // Mostrar diálogo de confirmación
    bool confirmar = await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(
                "Confirmar",
                style: TextStyle(
                  color: primaryTeal,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Text(
                "¿Estás seguro de quitar la asignación del coordinador?",
                style: TextStyle(fontSize: 16),
              ),
              actions: [
                TextButton(
                  child: Text(
                    "Cancelar",
                    style: TextStyle(color: Colors.grey),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                ),
                TextButton(
                  child: Text(
                    "Confirmar",
                    style: TextStyle(
                        color: primaryTeal, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                ),
              ],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            );
          },
        ) ??
        false;

    if (confirmar) {
      try {
        await FirebaseFirestore.instance
            .collection('registros')
            .doc(registroId)
            .update({
          'coordinadorAsignado': null,
          'coordinadorNombre': null,
          'timoteoAsignado': null,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Se ha quitado la asignación correctamente",
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: primaryTeal,
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
            content: Text(
              "Error al quitar la asignación: ${e.toString()}",
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: EdgeInsets.all(10),
          ),
        );
      }
    }
  }

  void _mostrarDetallesRegistro(
    BuildContext context,
    Map<String, dynamic> data,
    Color primaryTeal,
    Color secondaryOrange,
    Color accentGrey,
    Color backgroundGrey,
  ) {
    // Función para formatear fechas
    String formatearFecha(String? fecha) {
      if (fecha == null || fecha.isEmpty) return '';

      // Si la fecha está en formato timestamp de Firestore
      if (fecha.contains('Timestamp')) {
        try {
          // Extraer los segundos del formato "Timestamp(seconds=1234567890, ...)"
          final regex = RegExp(r'seconds=(\d+)');
          final match = regex.firstMatch(fecha);
          if (match != null) {
            final seconds = int.tryParse(match.group(1) ?? '');
            if (seconds != null) {
              final date = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
              return '${date.day}/${date.month}/${date.year}';
            }
          }
        } catch (e) {
          // Si hay error en la conversión, devolver la fecha original
          return fecha;
        }
      }

      // Intentar parsear otras fechas comunes
      try {
        final date = DateTime.parse(fecha);
        return '${date.day}/${date.month}/${date.year}';
      } catch (e) {
        // Si no es parseable, devolver el texto original
        return fecha;
      }
    }

    // Función para calcular la edad a partir de fecha de nacimiento
    int? calcularEdadDesdeData(Map<String, dynamic> data) {
      try {
        var fechaNacimiento;

        if (data.containsKey('fechaNacimiento')) {
          var value = data['fechaNacimiento'];

          if (value is Timestamp) {
            fechaNacimiento = value.toDate();
          } else if (value is String && value.isNotEmpty) {
            // Manejar formato Timestamp en string
            if (value.contains('Timestamp')) {
              final regex = RegExp(r'seconds=(\d+)');
              final match = regex.firstMatch(value);
              if (match != null) {
                final seconds = int.tryParse(match.group(1) ?? '');
                if (seconds != null) {
                  fechaNacimiento =
                      DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
                }
              }
            } else {
              fechaNacimiento = DateTime.parse(value);
            }
          }

          if (fechaNacimiento != null) {
            final hoy = DateTime.now();
            int edad = (hoy.year - fechaNacimiento.year).toInt();
            if (hoy.month < fechaNacimiento.month ||
                (hoy.month == fechaNacimiento.month &&
                    hoy.day < fechaNacimiento.day)) {
              edad--;
            }
            return edad;
          }
        }
        return null;
      } catch (e) {
        return null;
      }
    }

    // Función para calcular próximo cumpleaños
    String? calcularProximoCumpleanosDesdeData(Map<String, dynamic> data) {
      try {
        var fechaNacimiento;

        if (data.containsKey('fechaNacimiento')) {
          var value = data['fechaNacimiento'];

          if (value is Timestamp) {
            fechaNacimiento = value.toDate();
          } else if (value is String && value.isNotEmpty) {
            // Manejar formato Timestamp en string
            if (value.contains('Timestamp')) {
              final regex = RegExp(r'seconds=(\d+)');
              final match = regex.firstMatch(value);
              if (match != null) {
                final seconds = int.tryParse(match.group(1) ?? '');
                if (seconds != null) {
                  fechaNacimiento =
                      DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
                }
              }
            } else {
              fechaNacimiento = DateTime.parse(value);
            }
          }

          if (fechaNacimiento != null) {
            final hoy = DateTime.now();
            DateTime proximoCumpleanos =
                DateTime(hoy.year, fechaNacimiento.month, fechaNacimiento.day);

            if (proximoCumpleanos.isBefore(hoy) ||
                proximoCumpleanos.isAtSameMomentAs(hoy)) {
              proximoCumpleanos = DateTime(
                  hoy.year + 1, fechaNacimiento.month, fechaNacimiento.day);
            }

            final diferencia = proximoCumpleanos.difference(hoy).inDays;

            if (diferencia == 0) {
              return '¡Hoy es su cumpleaños! 🎉';
            } else if (diferencia == 1) {
              return 'Mañana (1 día)';
            } else if (diferencia <= 7) {
              return 'En ${diferencia} días';
            } else if (diferencia <= 30) {
              return 'En ${diferencia} días';
            } else {
              final double mesesDouble = diferencia / 30;
              final int meses = mesesDouble.floor().toInt(); // CORRECCIÓN AQUÍ
              if (meses == 1) {
                return 'En aproximadamente 1 mes';
              } else {
                return 'En aproximadamente ${meses} meses';
              }
            }
          }
        }
        return null;
      } catch (e) {
        return null;
      }
    }

    // Definimos una lista de secciones y campos agrupados para mejor organización
    final secciones = [
      {
        'titulo': 'Información Personal',
        'icono': Icons.person_outline,
        'color': primaryTeal,
        'campos': [
          {'key': 'nombre', 'label': 'Nombre', 'icon': Icons.badge_outlined},
          {
            'key': 'apellido',
            'label': 'Apellido',
            'icon': Icons.badge_outlined
          },
          {
            'key': 'telefono',
            'label': 'Teléfono',
            'icon': Icons.phone_outlined
          },
          {
            'key': 'edad',
            'label': 'Edad',
            'icon': Icons.calendar_today_outlined
          },
          {'key': 'sexo', 'label': 'Sexo', 'icon': Icons.wc_outlined},
          {
            'key': 'estadoCivil',
            'label': 'Estado Civil',
            'icon': Icons.favorite_border
          },
          {
            'key': 'tieneHijos',
            'label': 'Tiene Hijos',
            'icon': Icons.child_care_outlined
          },
          {
            'key': 'nombrePareja',
            'label': 'Nombre Pareja',
            'icon': Icons.people_outline
          },
        ]
      },
      {
        'titulo': 'Información de Cumpleaños',
        'icono': Icons.celebration_outlined,
        'color': secondaryOrange, // Color naranja para cumpleaños
        'campos': [
          {
            'key': 'fechaNacimiento',
            'label': 'Fecha de Nacimiento',
            'icon': Icons.cake_outlined,
            'esFecha': true
          },
          {
            'key': 'edad',
            'label': 'Edad Actual',
            'icon': Icons.timeline_outlined,
            'esEdadCalculada':
                true // Nueva propiedad para identificar campos calculados
          },
          {
            'key': 'proximoCumpleanos',
            'label': 'Próximo Cumpleaños',
            'icon': Icons.event_available_outlined,
            'esProximoCumpleanos':
                true // Nueva propiedad para próximo cumpleaños
          },
        ]
      },
      {
        'titulo': 'Ubicación',
        'icono': Icons.location_on_outlined,
        'color': primaryTeal,
        'campos': [
          {
            'key': 'direccionBarrio',
            'label': 'Dirección/Barrio',
            'icon': Icons.home_outlined
          },
        ]
      },
      {
        'titulo': 'Ocupación',
        'icono': Icons.work_outline,
        'color': secondaryOrange,
        'campos': [
          {
            'key': 'ocupaciones',
            'label': 'Ocupaciones',
            'icon': Icons.work_outline
          },
          // MODIFICACIÓN: Aquí se detectarán ambos campos automáticamente
          {
            'keys': [
              'descripcionOcupaciones',
              'descripcionOcupacion'
            ], // Múltiples keys posibles
            'label': 'Descripción Ocupación',
            'icon': Icons.description_outlined
          },
        ]
      },
      {
        'titulo': 'Información Ministerial',
        'icono': Icons.groups_outlined,
        'color': accentGrey,
        'campos': [
          {
            'key': 'nombreTribu',
            'label': 'Tribu',
            'icon': Icons.group_outlined
          },
          {
            'key': 'ministerioAsignado',
            'label': 'Ministerio',
            'icon': Icons.assignment_ind_outlined
          },
          {
            'key': 'consolidador',
            'label': 'Consolidador',
            'icon': Icons.supervisor_account_outlined
          },
          {
            'key': 'referenciaInvitacion',
            'label': 'Ref. Invitación',
            'icon': Icons.share_outlined
          },
        ]
      },
      {
        'titulo': 'Fechas',
        'icono': Icons.event_outlined,
        'color': secondaryOrange,
        'campos': [
          {
            'key': 'fecha',
            'label': 'Registro',
            'icon': Icons.event_outlined,
            'esFecha': true
          },
          {
            'key': 'fechaAsignacion',
            'label': 'Asignación',
            'icon': Icons.date_range_outlined,
            'esFecha': true
          },
        ]
      },
      {
        'titulo': 'Notas',
        'icono': Icons.note_outlined,
        'color': accentGrey,
        'campos': [
          {
            'key': 'observaciones',
            'label': 'Observaciones',
            'icon': Icons.notes_outlined
          },
          {
            'key': 'peticiones',
            'label': 'Peticiones',
            'icon': Icons.message_outlined
          },
          {
            'key': 'estadoFonovisita',
            'label': 'Estado de Fonovisita',
            'icon': Icons.call_outlined
          },
          {
            'key': 'observaciones2',
            'label': 'Observaciones 2',
            'icon': Icons.note_add_outlined
          },
        ]
      },
      {
        'titulo': 'Estado del Proceso',
        'icono': Icons.track_changes_outlined,
        'color': secondaryOrange,
        'campos': [
          {
            'key': 'estadoProceso',
            'label': 'Estado en la Iglesia',
            'icon': Icons.verified_outlined
          },
        ]
      },
    ];

    // Crear lista de widgets para el contenido del diálogo
    List<Widget> contenidoWidgets = [];

    // Procesar cada sección
    for (var seccion in secciones) {
      // Filtrar solo los campos que contienen datos en esta sección
      final camposConDatos = (seccion['campos'] as List).where((campo) {
        // MODIFICACIÓN: Manejo de campos con múltiples keys posibles
        if (campo.containsKey('keys')) {
          // Para campos con múltiples keys posibles
          final keys = campo['keys'] as List<String>;
          return keys.any((key) {
            if (!data.containsKey(key)) return false;
            final value = data[key];
            if (value == null) return false;
            if (value is List) return value.isNotEmpty;
            if (value is String) return value.trim().isNotEmpty;
            return true;
          });
        } else if (campo.containsKey('esEdadCalculada') &&
            campo['esEdadCalculada'] == true) {
          // Para campos de edad calculada
          return calcularEdadDesdeData(data) != null;
        } else if (campo.containsKey('esProximoCumpleanos') &&
            campo['esProximoCumpleanos'] == true) {
          // Para campos de próximo cumpleaños
          return calcularProximoCumpleanosDesdeData(data) != null;
        } else {
          // Para campos con una sola key
          final key = campo['key'] as String;
          if (!data.containsKey(key)) return false;
          final value = data[key];
          if (value == null) return false;
          if (value is List) return value.isNotEmpty;
          if (value is String) return value.trim().isNotEmpty;
          return true;
        }
      }).toList();

      // Solo mostramos secciones con campos con datos
      if (camposConDatos.isNotEmpty) {
        // Añadir título de sección
        contenidoWidgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
            child: Row(
              children: [
                Icon(
                  seccion['icono'] as IconData,
                  color: seccion['color'] as Color,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  seccion['titulo'] as String,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: seccion['color'] as Color,
                  ),
                ),
              ],
            ),
          ),
        );

        // Añadir línea separadora para el título
        contenidoWidgets.add(
          Divider(
            color: (seccion['color'] as Color).withOpacity(0.3),
            thickness: 1,
          ),
        );

        // Añadir campos de esta sección
        for (var campo in camposConDatos) {
          final label = campo['label'] as String;
          final icon = campo['icon'] as IconData;
          final esFecha = campo['esFecha'] as bool? ?? false;

          // Obtener el valor considerando múltiples keys posibles y campos calculados
          String textoValor = '';
          // NUEVA LÓGICA: Manejar campos calculados especiales
          if (campo.containsKey('esEdadCalculada') &&
              campo['esEdadCalculada'] == true) {
            // Campo de edad calculada
            final edadCalculada = calcularEdadDesdeData(data);
            if (edadCalculada != null) {
              textoValor = '$edadCalculada años';
            }
          } else if (campo.containsKey('esProximoCumpleanos') &&
              campo['esProximoCumpleanos'] == true) {
            // Campo de próximo cumpleaños
            final proximoCumpleanos = calcularProximoCumpleanosDesdeData(data);
            if (proximoCumpleanos != null) {
              textoValor = proximoCumpleanos;
            }
          } else if (campo.containsKey('keys')) {
            // LÓGICA ORIGINAL: Para campos con múltiples keys posibles
            final keys = campo['keys'] as List<String>;
            for (String key in keys) {
              if (data.containsKey(key) && data[key] != null) {
                var value = data[key];
                if (value is String && value.trim().isNotEmpty) {
                  textoValor = esFecha ? formatearFecha(value) : value;
                  break;
                } else if (value is List && value.isNotEmpty) {
                  textoValor = value.join(', ');
                  break;
                } else if (value is int || value is double) {
                  textoValor = value.toString();
                  break;
                } else if (value is bool) {
                  textoValor = value ? 'Sí' : 'No';
                  break;
                } else if (value != null) {
                  textoValor = esFecha
                      ? formatearFecha(value.toString())
                      : value.toString();
                  break;
                }
              }
            }
          } else {
            // LÓGICA ORIGINAL: Para campos con una sola key
            final key = campo['key'] as String;
            var value = data[key];
            if (esFecha) {
              textoValor = formatearFecha(value?.toString());
            } else if (value is List) {
              textoValor = (value as List).join(', ');
            } else if (value is int || value is double) {
              textoValor = value.toString();
            } else if (value is bool) {
              textoValor = value ? 'Sí' : 'No';
            } else {
              textoValor = value?.toString() ?? '';
            }
          }

          // Añadir widget de detalle solo si hay texto para mostrar
          if (textoValor.isNotEmpty) {
            contenidoWidgets.add(
              _buildDetalle(label, textoValor, icon, accentGrey, primaryTeal),
            );
          }
        }
      }
    }

    // Si no hay datos para mostrar, mostrar mensaje
    if (contenidoWidgets.isEmpty) {
      contenidoWidgets.add(
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 48,
                  color: accentGrey,
                ),
                SizedBox(height: 16),
                Text(
                  'No hay información disponible',
                  style: TextStyle(
                    fontSize: 16,
                    color: accentGrey,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Mostrar el diálogo
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 5,
        backgroundColor: backgroundGrey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Encabezado del diálogo
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: primaryTeal,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person_outline,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Detalles del Registro',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(50),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Contenido con scrolling
            Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: contenidoWidgets,
                  ),
                ),
              ),
            ),

            // Pie del diálogo
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryTeal,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_outline, size: 18),
                        SizedBox(width: 8),
                        Text('Cerrar'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetalle(String label, String value, IconData iconData,
      Color accentGrey, Color primaryTeal) {
    // Detectar si el campo es "Teléfono" para agregar funcionalidad de copiado
    final esTelefono = label.toLowerCase().contains('teléfono') ||
        label.toLowerCase().contains('telefono');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: primaryTeal.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              iconData,
              size: 16,
              color: primaryTeal,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: accentGrey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                // Si es teléfono, mostrar en un Row con el botón de copiar
                esTelefono
                    ? Row(
                        children: [
                          Expanded(
                            child: Text(
                              value,
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.black87,
                                height: 1.3,
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          // Botón para copiar el teléfono usando Builder para obtener context
                          Builder(
                            builder: (BuildContext builderContext) {
                              return Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () async {
                                    // Copiar al portapapeles
                                    await Clipboard.setData(
                                        ClipboardData(text: value));

                                    // Mostrar feedback visual
                                    ScaffoldMessenger.of(builderContext)
                                        .showSnackBar(
                                      SnackBar(
                                        content: Row(
                                          children: [
                                            Icon(
                                              Icons.check_circle_outline,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                            SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                '¡Teléfono copiado!',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        backgroundColor: primaryTeal,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        margin: EdgeInsets.all(12),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          primaryTeal.withOpacity(0.8),
                                          primaryTeal,
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: primaryTeal.withOpacity(0.3),
                                          blurRadius: 4,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.content_copy_rounded,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      )
                    : Text(
                        value,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.black87,
                          height: 1.3,
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

// ✅ NUEVO: Widget helper para crear dropdowns de filtro
  Widget _buildDropdownFiltro({
    required String label,
    required IconData icon,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    required Color primaryTeal,
    required Color accentGrey,
    String Function(String)? itemBuilder,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: value != null && value != 'Todos'
              ? primaryTeal
              : accentGrey.withOpacity(0.3),
          width: value != null && value != 'Todos' ? 2 : 1,
        ),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: value != null && value != 'Todos' ? primaryTeal : accentGrey,
            fontSize: 13,
            fontWeight: value != null && value != 'Todos'
                ? FontWeight.w600
                : FontWeight.normal,
          ),
          prefixIcon: Icon(
            icon,
            color: value != null && value != 'Todos' ? primaryTeal : accentGrey,
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        icon: Icon(
          Icons.arrow_drop_down,
          color: primaryTeal,
        ),
        dropdownColor: Colors.white,
        isExpanded: true,
        items: items.map((item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(
              itemBuilder != null ? itemBuilder(item) : item,
              style: TextStyle(
                fontSize: 14,
                fontWeight: item == value ? FontWeight.w600 : FontWeight.normal,
                color: item == 'Todos' ? accentGrey : Colors.black87,
              ),
            ),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

// 🆕 MÉTODOS AUXILIARES PARA EL PANEL DE FILTROS

  /// Verifica si hay filtros activos
  bool _hayFiltrosActivos() {
    return (_tipoBusqueda == 'nombre' && _searchTerm.isNotEmpty) ||
        (_tipoBusqueda == 'estado' && _searchEstadoTerm.isNotEmpty) ||
        _anioSeleccionado != null ||
        _mesSeleccionado != null;
  }

  /// Cuenta cuántos filtros están activos
  int _contarFiltrosActivos() {
    int count = 0;
    if (_tipoBusqueda == 'nombre' && _searchTerm.isNotEmpty) count++;
    if (_tipoBusqueda == 'estado' && _searchEstadoTerm.isNotEmpty) count++;
    if (_anioSeleccionado != null) count++;
    if (_mesSeleccionado != null) count++;
    return count;
  }

  /// Obtiene un texto descriptivo de los filtros activos
  String _obtenerTextoFiltrosActivos() {
    List<String> filtros = [];

    if (_tipoBusqueda == 'nombre' && _searchTerm.isNotEmpty) {
      filtros.add('Nombre: "$_searchTerm"');
    }
    if (_tipoBusqueda == 'estado' && _searchEstadoTerm.isNotEmpty) {
      filtros.add('Estado: "$_searchEstadoTerm"');
    }
    if (_anioSeleccionado != null) {
      filtros.add('Año: $_anioSeleccionado');
    }
    if (_mesSeleccionado != null) {
      final mesesNombres = {
        '1': 'Ene',
        '2': 'Feb',
        '3': 'Mar',
        '4': 'Abr',
        '5': 'May',
        '6': 'Jun',
        '7': 'Jul',
        '8': 'Ago',
        '9': 'Sep',
        '10': 'Oct',
        '11': 'Nov',
        '12': 'Dic'
      };
      filtros.add('Mes: ${mesesNombres[_mesSeleccionado]}');
    }

    if (filtros.isEmpty) {
      return 'Sin filtros aplicados • Toca para expandir';
    }

    return filtros.join(' • ');
  }
}

//----------------------------------------------------------------------------------------------

// la clase InscripcionesTab existente

class InscripcionesTab extends StatefulWidget {
  final String tribuId;

  const InscripcionesTab({Key? key, required this.tribuId}) : super(key: key);

  @override
  _InscripcionesTabState createState() => _InscripcionesTabState();
}

class _InscripcionesTabState extends State<InscripcionesTab> {
  final Color primaryTeal = Color(0xFF1B998B);
  final Color secondaryOrange = Color(0xFFFF7E00);
  final Color lightTeal = Color(0xFFE0F7FA);

  // Estado para alternar entre eventos y cumpleaños
  bool mostrandoCumpleanos = false;

// Sistema de iconos por tipo de evento
  IconData _getIconoPorTipo(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'encuentro':
        return Icons.groups;
      case 'raíces':
        return Icons.nature_people;
      case 'reencuentro':
        return Icons.handshake;
      case 'personalizado':
        return Icons.star;
      default:
        return Icons.event;
    }
  }

  Color _getColorPorTipo(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'encuentro':
        return Colors.blue;
      case 'raíces':
        return Colors.green;
      case 'reencuentro':
        return Colors.purple;
      case 'personalizado':
        return Colors.orange;
      default:
        return primaryTeal;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [lightTeal, Colors.white],
          stops: [0.0, 0.5],
        ),
      ),
      child: Column(
        children: [
          // Header con botón para crear evento
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: primaryTeal,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  offset: Offset(0, 2),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Column(
              children: [
                // Toggle buttons
                Container(
                  margin: EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: !mostrandoCumpleanos
                                ? Colors.white
                                : Colors.white.withOpacity(0.3),
                            foregroundColor: !mostrandoCumpleanos
                                ? primaryTeal
                                : Colors.white,
                            elevation: !mostrandoCumpleanos ? 2 : 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: Icon(Icons.event_note, size: 20),
                          label: Text('Eventos',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          onPressed: () =>
                              setState(() => mostrandoCumpleanos = false),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: mostrandoCumpleanos
                                ? Colors.white
                                : Colors.white.withOpacity(0.3),
                            foregroundColor: mostrandoCumpleanos
                                ? primaryTeal
                                : Colors.white,
                            elevation: mostrandoCumpleanos ? 2 : 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: Icon(Icons.cake, size: 20),
                          label: Text('Cumpleaños',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          onPressed: () =>
                              setState(() => mostrandoCumpleanos = true),
                        ),
                      ),
                    ],
                  ),
                ),
                // Header title and action button
                Row(
                  children: [
                    Icon(mostrandoCumpleanos ? Icons.cake : Icons.event_note,
                        color: Colors.white, size: 28),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        mostrandoCumpleanos
                            ? 'Cumpleaños del Mes'
                            : 'Eventos e Inscripciones',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (!mostrandoCumpleanos)
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: secondaryOrange,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: Icon(Icons.add, color: Colors.white),
                        label: Text('Crear Evento',
                            style: TextStyle(color: Colors.white)),
                        onPressed: () => _mostrarDialogoCrearEvento(),
                      ),
                  ],
                ),
              ],
            ),
          ),
          // Lista de eventos
          Expanded(
            child: mostrandoCumpleanos
                ? _buildCumpleanosView()
                : _buildEventosView(),
          ),
        ],
      ),
    );
  }

  // AÑADIR AL FINAL DE LA CLASE _InscripcionesTabState
  Widget _buildEventosView() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('eventos')
          .where('tribuId', isEqualTo: widget.tribuId)
          .where('estado', isNotEqualTo: 'cancelado')
          .orderBy('estado')
          .orderBy('fechaInicio', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        // Debug info
        print('StreamBuilder state: ${snapshot.connectionState}');
        print('Has data: ${snapshot.hasData}');
        if (snapshot.hasData) {
          print('Documents count: ${snapshot.data!.docs.length}');
        }
        if (snapshot.hasError) {
          print('StreamBuilder error: ${snapshot.error}');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: primaryTeal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(primaryTeal),
                    strokeWidth: 3,
                  ),
                ),
                SizedBox(height: 24),
                Text(
                  'Cargando eventos...',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Container(
              padding: EdgeInsets.all(24),
              margin: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
                  SizedBox(height: 16),
                  Text(
                    'Error al cargar eventos',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.red[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Por favor, intenta nuevamente',
                    style: TextStyle(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {}); // Forzar rebuild
                    },
                    icon: Icon(Icons.refresh),
                    label: Text('Reintentar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[400],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Container(
              padding: EdgeInsets.all(32),
              margin: EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.grey.shade50,
                    Colors.grey.shade100,
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Icon(Icons.event_busy,
                        size: 48, color: Colors.grey[500]),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'No hay eventos creados',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Crea tu primer evento tocando\nel botón "Crear Evento"',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 14,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        final eventos = snapshot.data!.docs;
        print('Eventos encontrados: ${eventos.length}');

        // Debug: imprimir información de cada evento
        for (var evento in eventos) {
          final data = evento.data() as Map<String, dynamic>;
          print('Evento: ${data['nombre']}, TribuId: ${data['tribuId']}');
        }

        final eventosAgrupados = _agruparEventosPorFecha(eventos);

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {}); // Forzar refresh
          },
          color: primaryTeal,
          child: ListView(
            padding: EdgeInsets.all(16),
            children: eventosAgrupados.entries.map((anioEntry) {
              return Container(
                margin: EdgeInsets.symmetric(vertical: 8),
                child: Card(
                  key: ValueKey('anio_${anioEntry.key}'),
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white,
                          primaryTeal.withOpacity(0.02),
                        ],
                      ),
                    ),
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        dividerColor: Colors.transparent,
                      ),
                      child: ExpansionTile(
                        initiallyExpanded: false, // Cerrado por defecto
                        tilePadding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        childrenPadding: EdgeInsets.all(0),
                        leading: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: primaryTeal.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.calendar_today,
                            color: primaryTeal,
                            size: 24,
                          ),
                        ),
                        title: Text(
                          'Año ${anioEntry.key}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: primaryTeal,
                            letterSpacing: 0.3,
                          ),
                        ),
                        subtitle: Text(
                          '${anioEntry.value.values.expand((x) => x).length} eventos',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                        children: anioEntry.value.entries.map((mesEntry) {
                          return Container(
                            margin: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: secondaryOrange.withOpacity(0.02),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: secondaryOrange.withOpacity(0.1),
                                width: 1,
                              ),
                            ),
                            child: Theme(
                              data: Theme.of(context).copyWith(
                                dividerColor: Colors.transparent,
                              ),
                              child: ExpansionTile(
                                initiallyExpanded: false, // Cerrado por defecto
                                tilePadding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 4),
                                leading: Container(
                                  padding: EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: secondaryOrange.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.date_range,
                                    color: secondaryOrange,
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  _nombreMes(mesEntry.key),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: secondaryOrange,
                                  ),
                                ),
                                subtitle: Text(
                                  '${mesEntry.value.length} eventos',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                                children: [
                                  // Grid responsivo de eventos
                                  Container(
                                    padding: EdgeInsets.all(12),
                                    child: LayoutBuilder(
                                      builder: (context, constraints) {
                                        return Wrap(
                                          spacing: 8.0,
                                          runSpacing: 8.0,
                                          children:
                                              mesEntry.value.map((eventoDoc) {
                                            return _buildEventCard(eventoDoc);
                                          }).toList(),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildCumpleanosView() {
    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('registros')
          .where('tribuAsignada', isEqualTo: widget.tribuId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(primaryTeal),
                ),
                SizedBox(height: 16),
                Text(
                  'Cargando cumpleañeros...',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 80, color: Colors.red[300]),
                SizedBox(height: 16),
                Text(
                  'Error al cargar cumpleaños',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.red[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        // Filtrar registros con cumpleaños en el mes actual
        final cumpleanieros = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          if (data['fechaNacimiento'] == null) return false;

          final fechaNacimiento =
              (data['fechaNacimiento'] as Timestamp).toDate();
          return fechaNacimiento.month == currentMonth;
        }).toList();

        if (cumpleanieros.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cake_outlined, size: 80, color: Colors.grey[400]),
                SizedBox(height: 16),
                Text(
                  'No hay cumpleaños este mes',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Los cumpleaños aparecerán aquí cuando llegue su mes',
                  style: TextStyle(color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        // Ordenar por día de cumpleaños
        cumpleanieros.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aDate = (aData['fechaNacimiento'] as Timestamp).toDate();
          final bDate = (bData['fechaNacimiento'] as Timestamp).toDate();
          return aDate.day.compareTo(bDate.day);
        });

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: Column(
            children: [
              // Header del mes actual
              Container(
                margin: EdgeInsets.all(12),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        colors: [primaryTeal, primaryTeal.withOpacity(0.8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_month,
                            color: Colors.white, size: 28),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '🎉 ${_nombreMes(currentMonth)} $currentYear',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${cumpleanieros.length} cumpleaños',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Lista de cumpleañeros
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  itemCount: cumpleanieros.length,
                  itemBuilder: (context, index) {
                    final data =
                        cumpleanieros[index].data() as Map<String, dynamic>;
                    return _buildCumpleanosCard(data);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCumpleanosCard(Map<String, dynamic> data) {
    final fechaNacimiento = (data['fechaNacimiento'] as Timestamp).toDate();
    final now = DateTime.now();
    final diaCumple = fechaNacimiento.day;

    final nombre = data['nombre'] ?? '';
    final apellido = data['apellido'] ?? '';
    final edad = _calcularEdad(fechaNacimiento, now);
    final sexo = data['sexo'] ?? '';
    final telefono = data['telefono'] ?? '';
    final barrio = data['barrio'] ?? '';

    // Verificar si es hoy
    final esHoy = now.day == diaCumple && now.month == fechaNacimiento.month;

    return Card(
      elevation: esHoy ? 8 : 4,
      margin: EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: esHoy
            ? BorderSide(color: secondaryOrange, width: 2)
            : BorderSide.none,
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: esHoy
              ? LinearGradient(
                  colors: [secondaryOrange.withOpacity(0.1), Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
        ),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  // Día del cumpleaños
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: esHoy
                            ? [
                                secondaryOrange,
                                secondaryOrange.withOpacity(0.8)
                              ]
                            : [
                                primaryTeal.withOpacity(0.2),
                                primaryTeal.withOpacity(0.1)
                              ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: esHoy
                          ? [
                              BoxShadow(
                                color: secondaryOrange.withOpacity(0.3),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$diaCumple',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: esHoy ? Colors.white : primaryTeal,
                            ),
                          ),
                          if (esHoy)
                            Text(
                              'HOY',
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 16),

                  // Información principal
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                "$nombre $apellido",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            if (esHoy)
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: secondaryOrange,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '🎂 HOY',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.cake_outlined,
                                size: 16, color: Colors.grey[600]),
                            SizedBox(width: 4),
                            Text(
                              "Cumple $edad años",
                              style: TextStyle(
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500),
                            ),
                            SizedBox(width: 16),
                            Icon(
                              sexo.toLowerCase() == 'masculino'
                                  ? Icons.male
                                  : Icons.female,
                              size: 16,
                              color: sexo.toLowerCase() == 'masculino'
                                  ? Colors.blue
                                  : Colors.pink,
                            ),
                            SizedBox(width: 4),
                            Text(
                              sexo,
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),

              // Información de contacto
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    if (telefono.isNotEmpty)
                      Row(
                        children: [
                          Icon(Icons.phone, size: 16, color: primaryTeal),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              telefono,
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                          ),
                        ],
                      ),
                    if (telefono.isNotEmpty && barrio.isNotEmpty)
                      SizedBox(height: 8),
                    if (barrio.isNotEmpty)
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 16, color: primaryTeal),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              barrio,
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _calcularEdad(DateTime fechaNacimiento, DateTime fechaActual) {
    int edad = fechaActual.year - fechaNacimiento.year;
    if (fechaActual.month < fechaNacimiento.month ||
        (fechaActual.month == fechaNacimiento.month &&
            fechaActual.day < fechaNacimiento.day)) {
      edad--;
    }
    return edad + 1; // +1 porque queremos la edad que va a cumplir
  }

  Widget _buildEventCard(DocumentSnapshot eventoDoc) {
    final evento = eventoDoc.data() as Map<String, dynamic>;
    final fechaInicio = (evento['fechaInicio'] as Timestamp).toDate();
    final fechaFin = (evento['fechaFin'] as Timestamp).toDate();
    final ahora = DateTime.now();
    final cumplido = ahora.isAfter(fechaFin);
    final estado = evento['estado'] ?? 'activo';

    // Cálculo responsivo del ancho de las tarjetas
    final screenWidth = MediaQuery.of(context).size.width;
    double cardWidth;

    if (screenWidth > 900) {
      // Pantallas muy grandes - 4 columnas
      cardWidth = (screenWidth - 80) / 4;
    } else if (screenWidth > 600) {
      // Pantallas medianas - 3 columnas
      cardWidth = (screenWidth - 60) / 3;
    } else if (screenWidth > 400) {
      // Pantallas pequeñas - 2 columnas
      cardWidth = (screenWidth - 40) / 2;
    } else {
      // Pantallas muy pequeñas - 1 columna
      cardWidth = screenWidth - 24;
    }

    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: cardWidth,
      child: Card(
        key: ValueKey(eventoDoc.id),
        elevation: 6,
        margin: EdgeInsets.all(6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: estado == 'cancelado'
                ? Colors.red.shade400
                : cumplido
                    ? Colors.green.shade400
                    : primaryTeal,
            width: 2.5,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: estado == 'cancelado'
                  ? [Colors.red[50]!, Colors.red[100]!]
                  : cumplido
                      ? [Colors.green[50]!, Colors.green[100]!]
                      : [Colors.white, lightTeal.withOpacity(0.2)],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => _abrirDetalleEvento(eventoDoc),
              onLongPress: () => _mostrarOpcionesEvento(eventoDoc),
              child: Padding(
                padding: EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header mejorado con animación
                    Row(
                      children: [
                        Hero(
                          tag: 'avatar_${eventoDoc.id}',
                          child: AnimatedContainer(
                            duration: Duration(milliseconds: 200),
                            child: CircleAvatar(
                              radius: 24,
                              backgroundColor: estado == 'cancelado'
                                  ? Colors.red.shade400
                                  : cumplido
                                      ? Colors.green.shade400
                                      : _getColorPorTipo(
                                          evento['tipo'] ?? 'encuentro'),
                              child: Icon(
                                estado == 'cancelado'
                                    ? Icons.cancel_outlined
                                    : cumplido
                                        ? Icons.check_circle_outlined
                                        : _getIconoPorTipo(
                                            evento['tipo'] ?? 'encuentro'),
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                evento['nombre'] ?? 'Sin nombre',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: estado == 'cancelado'
                                      ? Colors.red[700]
                                      : cumplido
                                          ? Colors.green[700]
                                          : Colors.black87,
                                  letterSpacing: 0.3,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 6),
                              // Chip de tipo mejorado
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      _getColorPorTipo(
                                              evento['tipo'] ?? 'encuentro')
                                          .withOpacity(0.2),
                                      _getColorPorTipo(
                                              evento['tipo'] ?? 'encuentro')
                                          .withOpacity(0.1),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _getColorPorTipo(
                                            evento['tipo'] ?? 'encuentro')
                                        .withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  evento['tipo'] ?? 'Encuentro',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: _getColorPorTipo(
                                        evento['tipo'] ?? 'encuentro'),
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),

                    // Fechas con diseño mejorado
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.shade200,
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildFechaRow(
                            Icons.play_circle_outline,
                            'Inicio',
                            DateFormat('dd/MM/yyyy').format(fechaInicio),
                            Colors.green.shade600,
                          ),
                          Divider(height: 16, color: Colors.grey.shade300),
                          _buildFechaRow(
                            Icons.stop_circle_outlined,
                            'Fin',
                            DateFormat('dd/MM/yyyy').format(fechaFin),
                            Colors.red.shade600,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 12),

                    // Estado mejorado con gradiente
                    Container(
                      width: double.infinity,
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: estado == 'cancelado'
                              ? [Colors.red.shade400, Colors.red.shade600]
                              : cumplido
                                  ? [
                                      Colors.green.shade400,
                                      Colors.green.shade600
                                    ]
                                  : [primaryTeal, primaryTeal.withOpacity(0.8)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: (estado == 'cancelado'
                                    ? Colors.red
                                    : cumplido
                                        ? Colors.green
                                        : primaryTeal)
                                .withOpacity(0.3),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            estado == 'cancelado'
                                ? Icons.cancel
                                : cumplido
                                    ? Icons.check_circle
                                    : Icons.schedule,
                            color: Colors.white,
                            size: 16,
                          ),
                          SizedBox(width: 6),
                          Text(
                            estado == 'cancelado'
                                ? 'CANCELADO'
                                : cumplido
                                    ? 'CUMPLIDO'
                                    : 'ACTIVO',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 12),

                    // Footer mejorado
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Contador de inscritos mejorado
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                secondaryOrange.withOpacity(0.2),
                                secondaryOrange.withOpacity(0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: secondaryOrange.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.people_outline,
                                  size: 16, color: secondaryOrange),
                              SizedBox(width: 4),
                              Text(
                                '${(evento['inscripciones'] as List?)?.length ?? 0}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: secondaryOrange,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Botón de opciones mejorado
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () => _mostrarOpcionesEvento(eventoDoc),
                              child: Padding(
                                padding: EdgeInsets.all(8),
                                child: Icon(
                                  Icons.more_vert,
                                  size: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

// Widget auxiliar para las filas de fecha
  Widget _buildFechaRow(
      IconData icon, String label, String fecha, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        Spacer(),
        Text(
          fecha,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[800],
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _mostrarOpcionesEvento(DocumentSnapshot eventoDoc) {
    final evento = eventoDoc.data() as Map<String, dynamic>;
    final estado = evento['estado'] ?? 'activo';
    final fechaFin = (evento['fechaFin'] as Timestamp).toDate();
    final cumplido = DateTime.now().isAfter(fechaFin);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(Icons.settings, color: primaryTeal),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Opciones de Evento',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: primaryTeal,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Opciones
            if (estado != 'cancelado') ...[
              ListTile(
                leading: Icon(Icons.visibility, color: primaryTeal),
                title: Text('Ver Detalles'),
                onTap: () {
                  Navigator.pop(context);
                  _abrirDetalleEvento(eventoDoc);
                },
              ),
              if (!cumplido) ...[
                ListTile(
                  leading: Icon(Icons.edit, color: secondaryOrange),
                  title: Text('Editar Evento'),
                  onTap: () {
                    Navigator.pop(context);
                    _editarEvento(eventoDoc);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.cancel, color: Colors.red),
                  title: Text('Cancelar Evento'),
                  onTap: () {
                    Navigator.pop(context);
                    _cancelarEvento(eventoDoc);
                  },
                ),
              ],
            ],

            if (estado == 'cancelado')
              ListTile(
                leading: Icon(Icons.restore, color: Colors.green),
                title: Text('Reactivar Evento'),
                onTap: () {
                  Navigator.pop(context);
                  _reactivarEvento(eventoDoc);
                },
              ),

            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _editarEvento(DocumentSnapshot eventoDoc) {
    showDialog(
      context: context,
      builder: (context) => DialogoEditarEvento(
        eventoDoc: eventoDoc,
        primaryColor: primaryTeal,
        secondaryColor: secondaryOrange,
      ),
    );
  }

  void _cancelarEvento(DocumentSnapshot eventoDoc) async {
    final confirmacion = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Cancelar Evento'),
          ],
        ),
        content: Text(
          '¿Estás seguro de que quieres cancelar este evento?\n\nEsta acción no afectará las inscripciones existentes, pero el evento aparecerá como cancelado.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('No'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Sí, Cancelar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmacion == true) {
      try {
        await FirebaseFirestore.instance
            .collection('eventos')
            .doc(eventoDoc.id)
            .update({
          'estado': 'cancelado',
          'fechaCancelacion': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Evento cancelado correctamente'),
            backgroundColor: Colors.orange,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cancelar evento: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _reactivarEvento(DocumentSnapshot eventoDoc) async {
    try {
      await FirebaseFirestore.instance
          .collection('eventos')
          .doc(eventoDoc.id)
          .update({
        'estado': 'activo',
        'fechaReactivacion': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Evento reactivado correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al reactivar evento: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Map<int, Map<int, List<DocumentSnapshot>>> _agruparEventosPorFecha(
      List<DocumentSnapshot> eventos) {
    Map<int, Map<int, List<DocumentSnapshot>>> agrupados = {};

    print('Agrupando ${eventos.length} eventos');

    for (var evento in eventos) {
      try {
        final data = evento.data() as Map<String, dynamic>;

        // Verificar que existe fechaInicio
        if (data['fechaInicio'] == null) {
          print('Evento ${evento.id} no tiene fechaInicio');
          continue;
        }

        final fechaInicio = (data['fechaInicio'] as Timestamp).toDate();
        final anio = fechaInicio.year;
        final mes = fechaInicio.month;

        print('Evento: ${data['nombre']}, Año: $anio, Mes: $mes');

        // Inicializar estructuras si no existen
        if (agrupados[anio] == null) {
          agrupados[anio] = {};
        }
        if (agrupados[anio]![mes] == null) {
          agrupados[anio]![mes] = [];
        }

        agrupados[anio]![mes]!.add(evento);
      } catch (e) {
        print('Error al procesar evento ${evento.id}: $e');
      }
    }

    // Ordenar los eventos dentro de cada mes por fecha
    agrupados.forEach((anio, meses) {
      meses.forEach((mes, eventosDelMes) {
        eventosDelMes.sort((a, b) {
          try {
            final dataA = a.data() as Map<String, dynamic>;
            final dataB = b.data() as Map<String, dynamic>;
            final fechaA = (dataA['fechaInicio'] as Timestamp).toDate();
            final fechaB = (dataB['fechaInicio'] as Timestamp).toDate();
            return fechaA.compareTo(fechaB);
          } catch (e) {
            print('Error al ordenar eventos: $e');
            return 0;
          }
        });
      });
    });

    print('Eventos agrupados por año: ${agrupados.keys.toList()}');

    return agrupados;
  }

  String _nombreMes(int mes) {
    const meses = [
      '',
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre'
    ];
    return meses[mes];
  }

  void _mostrarDialogoCrearEvento() {
    showDialog(
      context: context,
      builder: (context) => DialogoCrearEvento(
        tribuId: widget.tribuId,
        primaryColor: primaryTeal,
        secondaryColor: secondaryOrange,
      ),
    );
  }

  void _abrirDetalleEvento(DocumentSnapshot eventoDoc) {
    showBottomSheet(
      context: context,
      builder: (context) => DetalleEventoModal(
        eventoDoc: eventoDoc,
        tribuId: widget.tribuId,
        primaryColor: primaryTeal,
        secondaryColor: secondaryOrange,
      ),
    );
  }
}

//----------------------------------------------------------------------------------------------

class DialogoCrearEvento extends StatefulWidget {
  final String tribuId;
  final Color primaryColor;
  final Color secondaryColor;

  const DialogoCrearEvento({
    Key? key,
    required this.tribuId,
    required this.primaryColor,
    required this.secondaryColor,
  }) : super(key: key);

  @override
  _DialogoCrearEventoState createState() => _DialogoCrearEventoState();
}

class _DialogoCrearEventoState extends State<DialogoCrearEvento> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();

  String tipoSeleccionado = 'Encuentro';
  DateTime? fechaInicio;
  DateTime? fechaFin;

  final List<String> tiposEvento = [
    'Encuentro',
    'Raíces',
    'Reencuentro',
    'Personalizado'
  ];

  @override
  void dispose() {
    _nombreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: widget.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.event_note,
                          color: widget.primaryColor, size: 28),
                      SizedBox(width: 12),
                      Text(
                        'Crear Nuevo Evento',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: widget.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),

                // Tipo de evento
                Text(
                  'Tipo de Evento',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: widget.primaryColor,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: tipoSeleccionado,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon:
                        Icon(Icons.category, color: widget.primaryColor),
                  ),
                  items: tiposEvento.map((tipo) {
                    return DropdownMenuItem(
                      value: tipo,
                      child: Row(
                        children: [
                          Icon(
                            tipo == 'Personalizado' ? Icons.edit : Icons.event,
                            color: widget.secondaryColor,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(tipo),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (valor) {
                    setState(() {
                      tipoSeleccionado = valor!;
                      if (tipoSeleccionado != 'Personalizado') {
                        _nombreController.text = tipoSeleccionado;
                      } else {
                        _nombreController.clear();
                      }
                    });
                  },
                  validator: (value) =>
                      value == null ? 'Selecciona un tipo' : null,
                ),
                SizedBox(height: 16),

                // Nombre personalizado
                if (tipoSeleccionado == 'Personalizado') ...[
                  Text(
                    'Nombre del Evento',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: widget.primaryColor,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 8),
                  TextFormField(
                    controller: _nombreController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: Icon(Icons.title, color: widget.primaryColor),
                      hintText: 'Ingresa el nombre del evento',
                    ),
                    validator: (value) {
                      if (tipoSeleccionado == 'Personalizado' &&
                          (value == null || value.isEmpty)) {
                        return 'El nombre es obligatorio';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                ],

                // Fecha de inicio
                Text(
                  'Fecha de Inicio',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: widget.primaryColor,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 8),
                InkWell(
                  onTap: () => _seleccionarFechaInicio(),
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, color: widget.primaryColor),
                        SizedBox(width: 12),
                        Text(
                          fechaInicio == null
                              ? 'Seleccionar fecha de inicio'
                              : DateFormat('dd/MM/yyyy').format(fechaInicio!),
                          style: TextStyle(
                            color: fechaInicio == null
                                ? Colors.grey
                                : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),

                // Fecha de fin
                Text(
                  'Fecha de Fin',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: widget.primaryColor,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 8),
                InkWell(
                  onTap:
                      fechaInicio == null ? null : () => _seleccionarFechaFin(),
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: fechaInicio == null
                            ? Colors.grey[300]!
                            : Colors.grey,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.event_available,
                          color: fechaInicio == null
                              ? Colors.grey[300]
                              : widget.primaryColor,
                        ),
                        SizedBox(width: 12),
                        Text(
                          fechaFin == null
                              ? 'Seleccionar fecha de fin'
                              : DateFormat('dd/MM/yyyy').format(fechaFin!),
                          style: TextStyle(
                            color:
                                fechaFin == null ? Colors.grey : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 24),

                // Botones
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancelar',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.secondaryColor,
                        padding:
                            EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _crearEvento,
                      child: Text(
                        'Crear Evento',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _seleccionarFechaInicio() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: widget.primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (fecha != null) {
      setState(() {
        fechaInicio = fecha;
        fechaFin = null; // Reset fecha fin
      });
    }
  }

  Future<void> _seleccionarFechaFin() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: fechaInicio!,
      firstDate: fechaInicio!,
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: widget.primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (fecha != null) {
      setState(() {
        fechaFin = fecha;
      });
    }
  }

  // =============================================================================
// UBICACIÓN: Dentro de la clase _DialogoCrearEventoState
// REEMPLAZA tu función _crearEvento() actual con esta versión completa
// =============================================================================

  /// Función auxiliar para obtener el nombre de la tribu desde Firebase
  /// Parámetro: tribuId - ID de la tribu en Firebase
  /// Retorna: Nombre de la tribu o "Sin nombre" si hay error
  Future<String> _obtenerNombreTribu(String tribuId) async {
    try {
      // Consultar el documento de la tribu en Firebase
      final doc = await FirebaseFirestore.instance
          .collection('tribus')
          .doc(tribuId)
          .get();

      // Verificar si el documento existe y tiene datos
      if (doc.exists && doc.data() != null) {
        return doc.data()?['nombre'] ?? 'Sin nombre';
      }
    } catch (e) {
      // En caso de error, loggear para debugging
      print('Error al obtener nombre de tribu: $e');
    }
    // Valor por defecto si no se puede obtener el nombre
    return 'Sin nombre';
  }

  /// Función principal para crear un nuevo evento en Firebase
  /// Incluye validaciones, formato automático del nombre y eliminación automática
  void _crearEvento() async {
    // ===== VALIDACIONES INICIALES =====

    // Validar que el formulario esté correctamente llenado
    if (!_formKey.currentState!.validate()) return;

    // Validar que ambas fechas estén seleccionadas
    if (fechaInicio == null || fechaFin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Por favor selecciona las fechas del evento'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // ===== MOSTRAR INDICADOR DE CARGA =====

    // Mostrar diálogo de loading mientras se procesa
    showDialog(
      context: context,
      barrierDismissible: false, // No se puede cerrar tocando fuera
      builder: (context) => Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(widget.primaryColor),
        ),
      ),
    );

    try {
      // ===== CONSTRUCCIÓN DEL NOMBRE AUTOMÁTICO =====

      // Determinar el nombre base según el tipo seleccionado
      final nombreBase = tipoSeleccionado == 'Personalizado'
          ? _nombreController.text.trim() // Usar texto personalizado
          : tipoSeleccionado; // Usar tipo predefinido (Encuentro, Raíces, etc.)

      // Construir nombre completo: "TipoEvento - NombreTribu"
      final nombre =
          '$nombreBase - ${await _obtenerNombreTribu(widget.tribuId)}';

      // ===== CONFIGURACIÓN DE FECHAS =====

      // Crear fecha de inicio con hora 00:00:00 para que empiece al inicio del día
      final fechaInicioConHora = DateTime(fechaInicio!.year, fechaInicio!.month,
          fechaInicio!.day, 0, 0, 0 // Hora: 00:00:00
          );

      // Crear fecha de fin con hora 23:59:59 para que termine al final del día
      final fechaFinConHora = DateTime(fechaFin!.year, fechaFin!.month,
          fechaFin!.day, 23, 59, 59 // Hora: 23:59:59
          );

      // ===== FECHA DE ELIMINACIÓN AUTOMÁTICA =====

      // Calcular cuándo se eliminará automáticamente (1 año después del fin)
      final fechaEliminacionAutomatica = DateTime(
          fechaFinConHora.year + 1, // Agregar 1 año
          fechaFinConHora.month,
          fechaFinConHora.day,
          23,
          59,
          59 // Al final del día de eliminación
          );

      // ===== GUARDAR EN FIREBASE =====

      // Crear el documento del evento en la colección 'eventos'
      await FirebaseFirestore.instance.collection('eventos').add({
        // Información básica del evento
        'nombre': nombre, // Nombre con formato: "Tipo - Tribu"
        'tipo': tipoSeleccionado, // Tipo original seleccionado

        // Fechas del evento (convertidas a Timestamp de Firebase)
        'fechaInicio': Timestamp.fromDate(fechaInicioConHora),
        'fechaFin': Timestamp.fromDate(fechaFinConHora),

        // NUEVO: Fecha de eliminación automática
        'fechaEliminacionAutomatica':
            Timestamp.fromDate(fechaEliminacionAutomatica),

        // Relación con la tribu
        'tribuId': widget.tribuId,

        // Lista vacía para inscripciones (se llenará después)
        'inscripciones': <Map<String, dynamic>>[],

        // Metadatos del evento
        'fechaCreacion':
            FieldValue.serverTimestamp(), // Fecha actual del servidor
        'estado': 'activo', // Estado inicial del evento

        // Información adicional para el sistema de eliminación
        'eliminacionAutomatica':
            true, // Indica que se eliminará automáticamente
        'añosParaEliminar': 1, // Configuración: eliminar después de 1 año
      });

      // ===== CERRAR LOADING Y DIÁLOGO =====

      Navigator.of(context, rootNavigator: true).pop(); // Cerrar loading
      Navigator.pop(context); // Cerrar diálogo de crear evento

      // ===== MOSTRAR CONFIRMACIÓN DE ÉXITO =====

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Evento "$nombre" creado correctamente'),
                    Text(
                      'Se eliminará automáticamente el ${DateFormat('dd/MM/yyyy').format(fechaEliminacionAutomatica)}',
                      style: TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: Duration(seconds: 4), // Mostrar por 4 segundos
        ),
      );
    } catch (e) {
      // ===== MANEJO DE ERRORES =====

      Navigator.of(context, rootNavigator: true).pop(); // Cerrar loading

      // Mostrar mensaje de error al usuario
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al crear el evento: $e'),
          backgroundColor: Colors.red,
        ),
      );

      // Log detallado para debugging (solo visible en consola de desarrollo)
      print('Error detallado al crear evento: $e');
    }
  }

// =============================================================================
// FUNCIÓN ADICIONAL: Sistema de limpieza automática
// UBICACIÓN: Colócala también dentro de la clase _DialogoCrearEventoState
// O mejor aún, en un archivo separado como 'services/limpieza_service.dart'
// =============================================================================

  /// Función para eliminar eventos que ya cumplieron su fecha de eliminación automática
  /// Se debe ejecutar periódicamente (por ejemplo, al iniciar la app)
  static Future<void> eliminarEventosVencidos() async {
    try {
      final ahora = DateTime.now();

      print('🧹 Iniciando limpieza de eventos vencidos...');

      // Buscar eventos cuya fecha de eliminación automática ya pasó
      final querySnapshot = await FirebaseFirestore.instance
          .collection('eventos')
          .where('fechaEliminacionAutomatica',
              isLessThan: Timestamp.fromDate(ahora))
          .get();

      print(
          '📋 Encontrados ${querySnapshot.docs.length} eventos para eliminar');

      if (querySnapshot.docs.isEmpty) {
        print('✅ No hay eventos para eliminar');
        return;
      }

      // Eliminar eventos en lotes para mejor rendimiento
      WriteBatch batch = FirebaseFirestore.instance.batch();
      int contador = 0;
      List<String> nombresEliminados = [];

      for (var doc in querySnapshot.docs) {
        // Agregar operación de eliminación al batch
        batch.delete(doc.reference);
        contador++;

        // Guardar nombre para log
        final data = doc.data() as Map<String, dynamic>;
        nombresEliminados.add(data['nombre'] ?? 'Sin nombre');

        // Firebase permite máximo 500 operaciones por batch
        if (contador >= 500) {
          await batch.commit();
          batch = FirebaseFirestore.instance.batch();
          contador = 0;
          print('🗑️ Eliminado lote de 500 eventos');
        }
      }

      // Ejecutar el último batch si tiene operaciones pendientes
      if (contador > 0) {
        await batch.commit();
      }

      // Log de eventos eliminados
      print('✅ Eliminados ${querySnapshot.docs.length} eventos vencidos:');
      for (String nombre in nombresEliminados) {
        print('   - $nombre');
      }
    } catch (e) {
      print('❌ Error al eliminar eventos vencidos: $e');
    }
  }
}

// AGREGA esta clase DESPUÉS de la clase DialogoCrearEvento

class DialogoEditarEvento extends StatefulWidget {
  final DocumentSnapshot eventoDoc;
  final Color primaryColor;
  final Color secondaryColor;

  const DialogoEditarEvento({
    Key? key,
    required this.eventoDoc,
    required this.primaryColor,
    required this.secondaryColor,
  }) : super(key: key);

  @override
  _DialogoEditarEventoState createState() => _DialogoEditarEventoState();
}

class _DialogoEditarEventoState extends State<DialogoEditarEvento> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();

  String tipoSeleccionado = 'Encuentro';
  DateTime? fechaInicio;
  DateTime? fechaFin;
  bool _isLoading = false;

  final List<String> tiposEvento = [
    'Encuentro',
    'Raíces',
    'Reencuentro',
    'Personalizado'
  ];

  @override
  void initState() {
    super.initState();
    _cargarDatosEvento();
  }

  void _cargarDatosEvento() {
    final data = widget.eventoDoc.data() as Map<String, dynamic>;

    setState(() {
      tipoSeleccionado = data['tipo'] ?? 'Encuentro';
      _nombreController.text = data['nombre'] ?? '';
      fechaInicio = (data['fechaInicio'] as Timestamp).toDate();
      fechaFin = (data['fechaFin'] as Timestamp).toDate();
    });
  }

  @override
  void dispose() {
    _nombreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: widget.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.edit_note,
                          color: widget.primaryColor, size: 28),
                      SizedBox(width: 12),
                      Text(
                        'Editar Evento',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: widget.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),

                // Tipo de evento
                Text(
                  'Tipo de Evento',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: widget.primaryColor,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: tipoSeleccionado,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon:
                        Icon(Icons.category, color: widget.primaryColor),
                  ),
                  items: tiposEvento.map((tipo) {
                    return DropdownMenuItem(
                      value: tipo,
                      child: Row(
                        children: [
                          Icon(
                            tipo == 'Personalizado' ? Icons.edit : Icons.event,
                            color: widget.secondaryColor,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(tipo),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (valor) {
                    setState(() {
                      tipoSeleccionado = valor!;
                      if (tipoSeleccionado != 'Personalizado') {
                        _nombreController.text = tipoSeleccionado;
                      }
                    });
                  },
                  validator: (value) =>
                      value == null ? 'Selecciona un tipo' : null,
                ),
                SizedBox(height: 16),

                // Nombre del evento
                Text(
                  'Nombre del Evento',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: widget.primaryColor,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 8),
                TextFormField(
                  controller: _nombreController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: Icon(Icons.title, color: widget.primaryColor),
                    hintText: 'Ingresa el nombre del evento',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'El nombre es obligatorio';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),

                // Fecha de inicio
                Text(
                  'Fecha de Inicio',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: widget.primaryColor,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 8),
                InkWell(
                  onTap: _isLoading ? null : () => _seleccionarFechaInicio(),
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, color: widget.primaryColor),
                        SizedBox(width: 12),
                        Text(
                          fechaInicio == null
                              ? 'Seleccionar fecha de inicio'
                              : DateFormat('dd/MM/yyyy').format(fechaInicio!),
                          style: TextStyle(
                            color: fechaInicio == null
                                ? Colors.grey
                                : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),

                // Fecha de fin
                Text(
                  'Fecha de Fin',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: widget.primaryColor,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 8),
                InkWell(
                  onTap: _isLoading || fechaInicio == null
                      ? null
                      : () => _seleccionarFechaFin(),
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: fechaInicio == null || _isLoading
                            ? Colors.grey[300]!
                            : Colors.grey,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.event_available,
                          color: fechaInicio == null || _isLoading
                              ? Colors.grey[300]
                              : widget.primaryColor,
                        ),
                        SizedBox(width: 12),
                        Text(
                          fechaFin == null
                              ? 'Seleccionar fecha de fin'
                              : DateFormat('dd/MM/yyyy').format(fechaFin!),
                          style: TextStyle(
                            color:
                                fechaFin == null ? Colors.grey : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 24),

                // Botones
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed:
                          _isLoading ? null : () => Navigator.pop(context),
                      child: Text(
                        'Cancelar',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.secondaryColor,
                        padding:
                            EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _isLoading ? null : _actualizarEvento,
                      child: _isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              'Actualizar Evento',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _seleccionarFechaInicio() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: fechaInicio ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: widget.primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (fecha != null) {
      setState(() {
        fechaInicio = fecha;
        // Solo resetear fecha fin si la nueva fecha inicio es posterior
        if (fechaFin != null && fecha.isAfter(fechaFin!)) {
          fechaFin = null;
        }
      });
    }
  }

  Future<void> _seleccionarFechaFin() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: fechaFin ?? fechaInicio!,
      firstDate: fechaInicio!,
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: widget.primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (fecha != null) {
      setState(() {
        fechaFin = fecha;
      });
    }
  }

  void _actualizarEvento() async {
    if (!_formKey.currentState!.validate()) return;
    if (fechaInicio == null || fechaFin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Por favor selecciona las fechas del evento'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final nombre = _nombreController.text.trim();

      // Crear las fechas con hora específica para mejor control
      final fechaInicioConHora = DateTime(
          fechaInicio!.year, fechaInicio!.month, fechaInicio!.day, 0, 0, 0);

      final fechaFinConHora =
          DateTime(fechaFin!.year, fechaFin!.month, fechaFin!.day, 23, 59, 59);

      // Actualizar el evento
      await FirebaseFirestore.instance
          .collection('eventos')
          .doc(widget.eventoDoc.id)
          .update({
        'nombre': nombre,
        'tipo': tipoSeleccionado,
        'fechaInicio': Timestamp.fromDate(fechaInicioConHora),
        'fechaFin': Timestamp.fromDate(fechaFinConHora),
        'fechaActualizacion': FieldValue.serverTimestamp(),
      });

      Navigator.pop(context); // Cerrar diálogo

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Evento "$nombre" actualizado correctamente'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar el evento: $e'),
          backgroundColor: Colors.red,
        ),
      );
      print('Error detallado al actualizar evento: $e'); // Para debugging
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

//----------------------------------------------------------------------

class DetalleEventoModal extends StatefulWidget {
  final DocumentSnapshot eventoDoc;
  final String tribuId;
  final Color primaryColor;
  final Color secondaryColor;

  const DetalleEventoModal({
    Key? key,
    required this.eventoDoc,
    required this.tribuId,
    required this.primaryColor,
    required this.secondaryColor,
  }) : super(key: key);

  @override
  _DetalleEventoModalState createState() => _DetalleEventoModalState();
}

class _DetalleEventoModalState extends State<DetalleEventoModal> {
  List<Map<String, dynamic>> inscripciones = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _cargarInscripciones();
  }

  void _cargarInscripciones() {
    final data = widget.eventoDoc.data() as Map<String, dynamic>;
    setState(() {
      inscripciones =
          List<Map<String, dynamic>>.from(data['inscripciones'] ?? []);
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.eventoDoc.data() as Map<String, dynamic>;
    final nombre = data['nombre'] ?? 'Sin nombre';
    final fechaInicio = (data['fechaInicio'] as Timestamp).toDate();
    final fechaFin = (data['fechaFin'] as Timestamp).toDate();
    final ahora = DateTime.now();
    final cumplido = ahora.isAfter(fechaFin);

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              // Handle para arrastrar
              Container(
                margin: EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header del evento
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      widget.primaryColor,
                      widget.primaryColor.withOpacity(0.8)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.white,
                          child: Icon(
                            cumplido ? Icons.check : Icons.event,
                            color: widget.primaryColor,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                nombre,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Del ${DateFormat('dd/MM/yyyy').format(fechaInicio)} al ${DateFormat('dd/MM/yyyy').format(fechaFin)}',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (cumplido)
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'CUMPLIDO',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatCard(
                          'Inscritos',
                          inscripciones.length.toString(),
                          Icons.people,
                        ),
                        _buildStatCard(
                          'Confirmados',
                          inscripciones
                              .where((i) => i['asistio'] == true)
                              .length
                              .toString(),
                          Icons.check_circle,
                        ),
                        _buildStatCard(
                          'Total Abonos',
                          '\$${inscripciones.fold<int>(0, (sum, i) => sum + (i['abono'] as int? ?? 0))}',
                          Icons.monetization_on,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Boton para agregar persona
              if (!cumplido)
                Container(
                  padding: EdgeInsets.all(16),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.secondaryColor,
                      padding:
                          EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: Icon(Icons.person_add, color: Colors.white),
                    label: Text(
                      'Inscribir Persona',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: isLoading ? null : _mostrarDialogoInscribir,
                  ),
                ),

              // Lista de inscritos
              Expanded(
                child: inscripciones.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_add_disabled,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No hay personas inscritas',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Agrega la primera persona al evento',
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        itemCount: inscripciones.length,
                        itemBuilder: (context, index) {
                          final inscripcion = inscripciones[index];
                          return Card(
                            margin: EdgeInsets.symmetric(vertical: 4),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    widget.primaryColor.withOpacity(0.1),
                                child: Text(
                                  inscripcion['nombre'][0].toUpperCase(),
                                  style: TextStyle(
                                    color: widget.primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                inscripcion['nombre'],
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                'Abono: \$${inscripcion['abono']}',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              trailing: cumplido
                                  ? Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: inscripcion['asistio'] == true
                                            ? Colors.green.withOpacity(0.1)
                                            : Colors.red.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        inscripcion['asistio'] == true
                                            ? 'Asistio'
                                            : 'No asistio',
                                        style: TextStyle(
                                          color: inscripcion['asistio'] == true
                                              ? Colors.green
                                              : Colors.red,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    )
                                  : Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: Icon(Icons.edit,
                                              color: widget.secondaryColor),
                                          onPressed: () => _editarAbono(index),
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            inscripcion['asistio'] == true
                                                ? Icons.check_circle
                                                : Icons.radio_button_unchecked,
                                            color:
                                                inscripcion['asistio'] == true
                                                    ? Colors.green
                                                    : Colors.grey,
                                          ),
                                          onPressed: () =>
                                              _toggleAsistencia(index),
                                        ),
                                      ],
                                    ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoInscribir() async {
    setState(() => isLoading = true);

    try {
      // ✅ OPTIMIZACIÓN: Consultas en paralelo
      final results = await Future.wait([
        // Consulta 1: Obtener personas de la tribu
        FirebaseFirestore.instance
            .collection('registros')
            .where('tribuAsignada', isEqualTo: widget.tribuId)
            .where('activo', isEqualTo: true) // ✅ Solo personas activas
            .get(),

        // Consulta 2: Obtener eventos activos de la tribu
        FirebaseFirestore.instance
            .collection('eventos')
            .where('tribuId', isEqualTo: widget.tribuId)
            .where('estado', isEqualTo: 'activo')
            .get(),
      ]);

      final personasSnapshot = results[0] as QuerySnapshot;
      final eventosActivosSnapshot = results[1] as QuerySnapshot;

      // ✅ OPTIMIZACIÓN: Crear Set de personas con inscripciones activas
      final Set<String> personasConInscripcionActiva = {};
      final ahora = DateTime.now();

      for (var eventoDoc in eventosActivosSnapshot.docs) {
        // Saltar el evento actual
        if (eventoDoc.id == widget.eventoDoc.id) continue;

        final eventoData = eventoDoc.data() as Map<String, dynamic>;
        final fechaFin = (eventoData['fechaFin'] as Timestamp).toDate();

        // Solo verificar eventos que no han terminado
        if (fechaFin.isAfter(ahora)) {
          final inscripciones = List<Map<String, dynamic>>.from(
              eventoData['inscripciones'] ?? []);

          for (var inscripcion in inscripciones) {
            personasConInscripcionActiva
                .add(inscripcion['personaId'] as String);
          }
        }
      }

      // ✅ OPTIMIZACIÓN: Filtrar usando Set (O(1) lookup)
      final personasDisponibles = personasSnapshot.docs.where((doc) {
        // Filtrar personas ya inscritas en este evento
        if (inscripciones.any((i) => i['personaId'] == doc.id)) {
          return false;
        }

        // Filtrar personas con inscripciones activas en otros eventos
        if (personasConInscripcionActiva.contains(doc.id)) {
          return false;
        }

        // Validar que tenga datos básicos
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) return false;

        final nombre = data['nombre']?.toString().trim() ?? '';
        return nombre.isNotEmpty && nombre != 'Sin nombre';
      }).toList();

      setState(() => isLoading = false);

      if (personasDisponibles.isEmpty) {
        final totalPersonas = personasSnapshot.docs.length;
        final yaInscritas = inscripciones.length;
        final conInscripcionesActivas = personasConInscripcionActiva.length;

        String mensaje;
        if (yaInscritas == totalPersonas) {
          mensaje =
              'Todas las personas de la tribu ya están inscritas en este evento';
        } else if (conInscripcionesActivas > 0) {
          mensaje =
              'Las personas restantes tienen inscripciones activas en otros eventos. Deben completar esos eventos primero.';
        } else {
          mensaje = 'No hay más personas disponibles para inscribir';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mensaje),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
          ),
        );
        return;
      }

      final seleccion = await showDialog<DocumentSnapshot>(
        context: context,
        builder: (context) => _DialogoBuscarPersona(
          personas: personasDisponibles,
          primaryColor: widget.primaryColor,
          secondaryColor: widget.secondaryColor,
        ),
      );

      if (seleccion != null) {
        await _inscribirPersona(seleccion);
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar personas: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Función auxiliar para verificar inscripciones activas
  Future<bool> _tieneInscripcionActiva(String personaId) async {
    try {
      final eventosSnapshot = await FirebaseFirestore.instance
          .collection('eventos')
          .where('tribuId', isEqualTo: widget.tribuId)
          .where('estado', isEqualTo: 'activo')
          .get();

      final ahora = DateTime.now();

      for (var eventoDoc in eventosSnapshot.docs) {
        // Saltar el evento actual
        if (eventoDoc.id == widget.eventoDoc.id) continue;

        final eventoData = eventoDoc.data();
        final fechaFin = (eventoData['fechaFin'] as Timestamp).toDate();

        // Solo verificar eventos que no han terminado
        if (fechaFin.isAfter(ahora)) {
          final inscripciones = List<Map<String, dynamic>>.from(
              eventoData['inscripciones'] ?? []);

          if (inscripciones.any((i) => i['personaId'] == personaId)) {
            return true;
          }
        }
      }
      return false;
    } catch (e) {
      print('Error verificando inscripciones activas: $e');
      return false;
    }
  }

  Future<void> _inscribirPersona(DocumentSnapshot personaDoc) async {
    try {
      // ✅ Validar que el documento tenga datos
      if (!personaDoc.exists || personaDoc.data() == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('Error: La persona seleccionada no tiene datos válidos'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final personaData = personaDoc.data() as Map<String, dynamic>;

      // ✅ Validar campos requeridos con valores por defecto seguros
      final nombre = personaData['nombre']?.toString().trim() ?? 'Sin nombre';
      final apellido = personaData['apellido']?.toString().trim() ?? '';
      final nombreCompleto = apellido.isNotEmpty ? '$nombre $apellido' : nombre;

      // ✅ Validar que el nombre no esté vacío
      if (nombreCompleto.isEmpty || nombreCompleto == 'Sin nombre') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: La persona no tiene un nombre válido'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // ✅ Crear inscripción con validación
      final nuevaInscripcion = {
        'personaId': personaDoc.id,
        'nombre': nombreCompleto,
        'abono': 0,
        'asistio': false,
        'fechaInscripcion': Timestamp.now(),
      };

      // ✅ Actualizar estado local primero
      if (mounted) {
        setState(() {
          inscripciones.add(nuevaInscripcion);
        });
      }

      // ✅ Guardar en Firebase
      await FirebaseFirestore.instance
          .collection('eventos')
          .doc(widget.eventoDoc.id)
          .update({
        'inscripciones': inscripciones,
      });

      // ✅ Mostrar confirmación
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text('$nombreCompleto inscrito correctamente')),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e, stackTrace) {
      // ✅ Manejo de errores mejorado
      print('❌ Error al inscribir persona: $e');
      print('Stack trace: $stackTrace');

      // Revertir cambios en caso de error
      if (mounted) {
        setState(() {
          if (inscripciones.isNotEmpty) {
            inscripciones.removeLast();
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text('Error al inscribir: ${e.toString()}'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _editarAbono(int index) async {
    final controller =
        TextEditingController(text: inscripciones[index]['abono'].toString());

    final resultado = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: [
            Icon(Icons.monetization_on, color: widget.primaryColor),
            SizedBox(width: 8),
            Text('Editar Abono'),
          ],
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            prefixText: '\$ ',
            labelText: 'Abono en COP',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.secondaryColor,
            ),
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text('Guardar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (resultado != null) {
      final abono = int.tryParse(resultado.replaceAll(',', '')) ?? 0;
      await _actualizarInscripcion(index, {'abono': abono});
    }
  }

  void _toggleAsistencia(int index) async {
    final nuevaAsistencia = !inscripciones[index]['asistio'];
    await _actualizarInscripcion(index, {'asistio': nuevaAsistencia});
  }

  Future<void> _actualizarInscripcion(
      int index, Map<String, dynamic> cambios) async {
    try {
      setState(() {
        inscripciones[index].addAll(cambios);
      });

      await FirebaseFirestore.instance
          .collection('eventos')
          .doc(widget.eventoDoc.id)
          .update({
        'inscripciones': inscripciones,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Actualizado correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class _DialogoBuscarPersona extends StatefulWidget {
  final List<DocumentSnapshot> personas;
  final Color primaryColor;
  final Color secondaryColor;

  const _DialogoBuscarPersona({
    Key? key,
    required this.personas,
    required this.primaryColor,
    required this.secondaryColor,
  }) : super(key: key);

  @override
  _DialogoBuscarPersonaState createState() => _DialogoBuscarPersonaState();
}

class _DialogoBuscarPersonaState extends State<_DialogoBuscarPersona> {
  final TextEditingController _searchController = TextEditingController();
  List<DocumentSnapshot> personasFiltradas = [];

  @override
  void initState() {
    super.initState();
    personasFiltradas = widget.personas;
    _searchController.addListener(_filtrarPersonas);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filtrarPersonas);
    _searchController.dispose();
    super.dispose();
  }

  void _filtrarPersonas() {
    final query = _searchController.text.toLowerCase().trim();

    setState(() {
      if (query.isEmpty) {
        personasFiltradas = widget.personas;
      } else {
        personasFiltradas = widget.personas.where((doc) {
          try {
            final data = doc.data() as Map<String, dynamic>?;

            // ✅ Validar que data no sea null
            if (data == null) return false;

            // ✅ Manejo seguro de campos
            final nombre = data['nombre']?.toString().toLowerCase() ?? '';
            final apellido = data['apellido']?.toString().toLowerCase() ?? '';
            final nombreCompleto = '$nombre $apellido'.trim();

            return nombreCompleto.contains(query);
          } catch (e) {
            print('Error filtrando persona: $e');
            return false;
          }
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.7,
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: widget.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.person_search,
                      color: widget.primaryColor, size: 28),
                  SizedBox(width: 12),
                  Text(
                    'Buscar Persona',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: widget.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),

            // Barra de búsqueda
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o registro...',
                prefixIcon: Icon(Icons.search, color: widget.primaryColor),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: widget.primaryColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: widget.primaryColor, width: 2),
                ),
              ),
            ),
            SizedBox(height: 16),

            // Contador de resultados
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${personasFiltradas.length} persona(s) encontrada(s)',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ),
            SizedBox(height: 12),

            // Lista de personas
            Expanded(
              child: personasFiltradas.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.person_off,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No se encontraron personas',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Intenta con otro término de búsqueda',
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: personasFiltradas.length,
                      itemBuilder: (context, index) {
                        final doc = personasFiltradas[index];

                        try {
                          final data = doc.data() as Map<String, dynamic>?;

                          // ✅ Validar que data no sea null
                          if (data == null) {
                            return SizedBox.shrink();
                          }

                          // ✅ Manejo seguro de campos
                          final nombre =
                              data['nombre']?.toString() ?? 'Sin nombre';
                          final apellido = data['apellido']?.toString() ?? '';
                          final nombreCompleto = apellido.isNotEmpty
                              ? '$nombre $apellido'
                              : nombre;

                          return Card(
                            margin: EdgeInsets.symmetric(vertical: 4),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    widget.primaryColor.withOpacity(0.1),
                                child: Text(
                                  nombreCompleto.isNotEmpty
                                      ? nombreCompleto[0].toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    color: widget.primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                nombreCompleto,
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                'ID: ${doc.id}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 13,
                                ),
                              ),
                              trailing: Icon(
                                Icons.add_circle_outline,
                                color: widget.secondaryColor,
                              ),
                              onTap: () => Navigator.pop(context, doc),
                            ),
                          );
                        } catch (e) {
                          print('Error mostrando persona: $e');
                          return SizedBox.shrink();
                        }
                      },
                    ),
            ),

            // Botón cancelar
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancelar',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// AGREGA esta clase al final del archivo, después de todas las demás clases
// Esta clase permite el arrastre y reordenamiento de los cards de eventos

class ReorderableWrap extends StatefulWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final Function(int oldIndex, int newIndex)? onReorder;

  const ReorderableWrap({
    Key? key,
    required this.children,
    this.spacing = 0.0,
    this.runSpacing = 0.0,
    this.onReorder,
  }) : super(key: key);

  @override
  _ReorderableWrapState createState() => _ReorderableWrapState();
}

class _ReorderableWrapState extends State<ReorderableWrap>
    with TickerProviderStateMixin {
  List<Widget> _children = [];
  int? _draggedIndex;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _children = List.from(widget.children);

    _scaleController = AnimationController(
      duration: Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ReorderableWrap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.children != oldWidget.children) {
      _children = List.from(widget.children);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: widget.spacing,
      runSpacing: widget.runSpacing,
      children: _children.asMap().entries.map((entry) {
        final index = entry.key;
        final child = entry.value;

        return AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, _) {
            return LongPressDraggable<int>(
              data: index,
              hapticFeedbackOnStart: true,
              feedback: Material(
                elevation: 12,
                borderRadius: BorderRadius.circular(16),
                shadowColor: Colors.black45,
                child: Transform.scale(
                  scale: 1.1,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Opacity(
                      opacity: 0.9,
                      child: child,
                    ),
                  ),
                ),
              ),
              childWhenDragging: Transform.scale(
                scale: 0.95,
                child: Opacity(
                  opacity: 0.5,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.grey.withOpacity(0.5),
                        width: 2,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: child,
                  ),
                ),
              ),
              onDragStarted: () {
                setState(() {
                  _draggedIndex = index;
                });
                _scaleController.forward();

                // Feedback háptico
                HapticFeedback.mediumImpact();
              },
              onDragEnd: (details) {
                setState(() {
                  _draggedIndex = null;
                });
                _scaleController.reverse();
              },
              child: DragTarget<int>(
                onWillAccept: (draggedIndex) {
                  return draggedIndex != null && draggedIndex != index;
                },
                onAccept: (draggedIndex) {
                  if (widget.onReorder != null) {
                    widget.onReorder!(draggedIndex, index);
                  }

                  setState(() {
                    final draggedChild = _children.removeAt(draggedIndex);
                    _children.insert(index, draggedChild);
                    _draggedIndex = null;
                  });

                  // Feedback háptico al soltar
                  HapticFeedback.lightImpact();
                },
                onMove: (details) {
                  // Feedback visual mientras se arrastra sobre el target
                  HapticFeedback.selectionClick();
                },
                builder: (context, candidateData, rejectedData) {
                  final isTarget = candidateData.isNotEmpty;
                  final isDragging = _draggedIndex == index;

                  return AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: isTarget
                          ? Border.all(
                              color: Colors.blue,
                              width: 3,
                            )
                          : null,
                      boxShadow: isTarget
                          ? [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.3),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    transform: Matrix4.identity()..scale(isTarget ? 1.02 : 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: isTarget
                            ? Colors.blue.withOpacity(0.05)
                            : Colors.transparent,
                      ),
                      child: child,
                    ),
                  );
                },
              ),
            );
          },
        );
      }).toList(),
    );
  }
}
//--------------------------------------------------------------------------------------------------------
