import 'dart:math';
import 'dart:async';

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
import 'package:go_router/go_router.dart';
import 'package:flutter/gestures.dart';

// Constantes de color basadas en el logo
const Color kPrimaryColor = Color(0xFF148B8D); // Color turquesa del logo
const Color kSecondaryColor =
    Color(0xFFFF5722); // Color naranja/rojo de la llama
const Color kAccentColor =
    Color(0xFFFFB74D); // Color amarillo/dorado de la llama
const Color kBackgroundColor = Color(0xFFF8F9FA);
const Color kCardColor = Colors.white;
const Color kTextDarkColor = Color(0xFF2D3748); // Para textos en fondos claros

class TimoteoScreen extends StatefulWidget {
  final String timoteoId;
  final String timoteoNombre;

  const TimoteoScreen({
    Key? key,
    required this.timoteoId,
    required this.timoteoNombre,
  }) : super(key: key);

  @override
  State<TimoteoScreen> createState() => _TimoteoScreenState();
}

class _TimoteoScreenState extends State<TimoteoScreen>
    with SingleTickerProviderStateMixin {
  // Variables para el manejo de sesión
  Timer? _inactivityTimer;
  static const Duration _inactivityDuration = Duration(minutes: 15);

  // Controller para las pestañas
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
            Container(
              padding: EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(Icons.error_outline, color: Colors.white, size: 20),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Sesión expirada por inactividad',
                style: TextStyle(
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
        duration: Duration(seconds: 3),
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
                color: kSecondaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.logout_rounded,
                color: kSecondaryColor,
                size: 24,
              ),
            ),
            SizedBox(width: 12),
            Text(
              'Cerrar Sesión',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: kTextDarkColor,
              ),
            ),
          ],
        ),
        content: Text(
          '¿Estás seguro que deseas cerrar sesión?',
          style: TextStyle(
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
              style: TextStyle(
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
              style: TextStyle(fontWeight: FontWeight.w600),
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
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          backgroundColor: kPrimaryColor,
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
                      widget.timoteoNombre,
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
              onPressed: () {
                _resetInactivityTimer();
              },
              tooltip: 'Notificaciones',
            ),
            Container(
              margin: EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _confirmarCerrarSesion,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.logout_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Salir',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
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
            controller: _tabController,
            children: [
              PerfilTab(timoteoId: widget.timoteoId),
              JovenesAsignadosTab(timoteoId: widget.timoteoId),
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

  /// Bloquea asistencia si el registro tiene 3+ faltas y existe una alerta no revisada.
  Future<bool> _tieneBloqueoPorFaltas(
      String registroId, int faltasActuales) async {
    try {
      if (faltasActuales < 3) return false;

      // Primero verificar por procesada: false
      final qs = await FirebaseFirestore.instance
          .collection('alertas')
          .where('registroId', isEqualTo: registroId)
          .where('tipo', isEqualTo: 'faltasConsecutivas')
          .where('procesada', isEqualTo: false)
          .limit(1)
          .get();

      if (qs.docs.isNotEmpty) return true;

      // Si no hay procesada:false, verificar por estado
      final qs2 = await FirebaseFirestore.instance
          .collection('alertas')
          .where('registroId', isEqualTo: registroId)
          .where('tipo', isEqualTo: 'faltasConsecutivas')
          .where('estado', whereIn: ['pendiente', 'en_revision'])
          .limit(1)
          .get();

      return qs2.docs.isNotEmpty;
    } catch (e) {
      print('Error verificando bloqueo por faltas: $e');
      return false; // Por seguridad, no bloquear en caso de error
    }
  }

  Future<void> _registrarAsistencia(
      BuildContext context, DocumentSnapshot registro) async {
    try {
      final registroRef =
          FirebaseFirestore.instance.collection('registros').doc(registro.id);

      final DateTime? fechaSeleccionada = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate:
            DateTime.now().subtract(Duration(days: 90)), // Extendido a 3 meses
        lastDate: DateTime.now(),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: Color(0xFF147B7C),
                onPrimary: Colors.white,
                surface: Colors.white,
              ),
            ),
            child: child!,
          );
        },
      );

      if (fechaSeleccionada == null) return;

// === BLOQUEO POR FALTAS NO REVISADAS ===
// Obtener datos actualizados del registro
      final registroActualizado = await FirebaseFirestore.instance
          .collection('registros')
          .doc(registro.id)
          .get();

      if (!registroActualizado.exists) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(child: Text('El registro no existe')),
                ],
              ),
              backgroundColor: Color(0xFFFF4B2B),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
        return;
      }

      final dataActualizada =
          registroActualizado.data() as Map<String, dynamic>;
      final int faltasActuales =
          (dataActualizada['faltasConsecutivas'] as num?)?.toInt() ?? 0;
      final bool bloqueo =
          await _tieneBloqueoPorFaltas(registro.id, faltasActuales);

      if (bloqueo) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(Icons.block, color: Colors.white, size: 20),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Este registro tiene 3+ faltas con alerta sin revisar. No se puede registrar asistencia hasta que la alerta sea revisada.',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor: Color(0xFFFF4B2B),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              margin: EdgeInsets.all(16),
              duration: Duration(seconds: 4),
            ),
          );
        }
        return;
      }
// === FIN BLOQUEO ===

// Verificar duplicados ANTES de mostrar el diálogo
      final yaRegistrada = await FirebaseFirestore.instance
          .collection('asistencias')
          .where('jovenId', isEqualTo: registro.id)
          .where('fecha',
              isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime(
                  fechaSeleccionada.year,
                  fechaSeleccionada.month,
                  fechaSeleccionada.day)))
          .where('fecha',
              isLessThan: Timestamp.fromDate(DateTime(fechaSeleccionada.year,
                  fechaSeleccionada.month, fechaSeleccionada.day + 1)))
          .get();

      if (yaRegistrada.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.warning, color: Colors.white),
                SizedBox(width: 8),
                Expanded(child: Text('Ya existe registro para esta fecha')),
              ],
            ),
            backgroundColor: Color(0xFFFF4B2B),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        return;
      }

      final bool? asistio = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 8,
          child: Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  Color(0xFF147B7C).withOpacity(0.05),
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(0xFF147B7C).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.calendar_today,
                    size: 32,
                    color: Color(0xFF147B7C),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Registrar Asistencia',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF147B7C),
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    DateFormat('EEEE, dd \'de\' MMMM \'de\' yyyy', 'es')
                        .format(fechaSeleccionada),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: 24),
                Text(
                  '¿${registro.get('nombre')} asistió al servicio?',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFFF4B2B),
                            foregroundColor: Colors.white,
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => Navigator.pop(context, false),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.cancel_outlined, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'No Asistió',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF147B7C),
                            foregroundColor: Colors.white,
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => Navigator.pop(context, true),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle_outline, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Sí Asistió',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancelar',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      if (asistio == null) return;

      // Procesar de manera asíncrona sin bloquear la UI
      _procesarRegistroAsistencia(
          context, registro, fechaSeleccionada, asistio);

      // Mostrar confirmación inmediata
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                asistio ? Icons.check_circle : Icons.cancel,
                color: Colors.white,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  asistio
                      ? 'Asistencia registrada correctamente'
                      : 'Falta registrada correctamente',
                ),
              ),
            ],
          ),
          backgroundColor: asistio ? Color(0xFF147B7C) : Color(0xFFFF4B2B),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('Error en _registrarAsistencia: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 8),
              Expanded(child: Text('Error al procesar: ${e.toString()}')),
            ],
          ),
          backgroundColor: Color(0xFFFF4B2B),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

// AGREGAR ESTE MÉTODO DESPUÉS DEL MÉTODO _registrarAsistencia
  Future<void> _procesarRegistroAsistencia(
      BuildContext context,
      DocumentSnapshot registro,
      DateTime fechaSeleccionada,
      bool asistio) async {
    try {
      final registroRef =
          FirebaseFirestore.instance.collection('registros').doc(registro.id);
      final doc = await registroRef.get();

      if (!doc.exists) {
        print('El registro no existe');
        return;
      }

      final data = doc.data() as Map<String, dynamic>;

      // Obtener información de tribu de manera segura
      DocumentSnapshot? timoteoDoc;
      String? tribuId;
      String categoriaTribu = "General";

      try {
        timoteoDoc = await FirebaseFirestore.instance
            .collection('timoteos')
            .doc(timoteoId)
            .get();

        if (timoteoDoc.exists) {
          tribuId = timoteoDoc.get('tribuId');

          if (tribuId != null) {
            final tribuDoc = await FirebaseFirestore.instance
                .collection('tribus')
                .doc(tribuId)
                .get();

            if (tribuDoc.exists) {
              categoriaTribu = tribuDoc.get('categoria') ?? "General";
            }
          }
        }
      } catch (e) {
        print('Error obteniendo información de tribu: $e');
        // Continuar con valores por defecto
      }

      // Obtener nombre del servicio
      String nombreServicio =
          obtenerNombreServicio(categoriaTribu, fechaSeleccionada);

      // Calcular faltas consecutivas
      int faltasConsecutivas = data['faltasConsecutivas'] ?? 0;
      if (!asistio) {
        faltasConsecutivas++;
      } else {
        faltasConsecutivas = 0;
      }

      // Batch para operaciones atómicas
      final batch = FirebaseFirestore.instance.batch();

      // Actualizar registro principal
      batch.update(registroRef, {
        'asistencias': FieldValue.arrayUnion([
          {
            'fecha': Timestamp.fromDate(fechaSeleccionada),
            'asistio': asistio,
            'nombreServicio': nombreServicio,
          }
        ]),
        'faltasConsecutivas': faltasConsecutivas,
        'ultimaAsistencia': Timestamp.fromDate(fechaSeleccionada),
      });

      // Crear documento en colección asistencias
      final asistenciaRef =
          FirebaseFirestore.instance.collection('asistencias').doc();
      batch.set(asistenciaRef, {
        'jovenId': registro.id,
        'tribuId': tribuId,
        'nombre': '${data['nombre']} ${data['apellido']}',
        'fecha': Timestamp.fromDate(fechaSeleccionada),
        'nombreServicio': nombreServicio,
        'asistio': asistio,
        'diaSemana': DateFormat('EEEE', 'es').format(fechaSeleccionada),
        'fechaRegistro': FieldValue.serverTimestamp(),
      });

      // Crear registro en asistenciaTribus si hay tribu
      if (tribuId != null) {
        try {
          final tribusSnapshot = await FirebaseFirestore.instance
              .collection('tribus')
              .where('timoteoId', isEqualTo: timoteoId)
              .limit(1)
              .get();

          if (tribusSnapshot.docs.isNotEmpty) {
            final tribuDoc = tribusSnapshot.docs.first;
            final asistenciaTribuRef =
                FirebaseFirestore.instance.collection('asistenciaTribus').doc();

            batch.set(asistenciaTribuRef, {
              'tribuId': tribuDoc.id,
              'tribuNombre': tribuDoc['nombre'],
              'registroId': registro.id,
              'nombreJoven': '${data['nombre']} ${data['apellido']}',
              'fecha': Timestamp.fromDate(fechaSeleccionada),
              'diaSemana': DateFormat('EEEE', 'es').format(fechaSeleccionada),
              'nombreServicio': nombreServicio,
              'asistio': asistio,
              'fechaRegistro': FieldValue.serverTimestamp(),
            });
          }
        } catch (e) {
          print('Error al crear registro en asistenciaTribus: $e');
          // Continuar sin fallar
        }
      }

      // Ejecutar batch
      await batch.commit();

      // Procesar alertas si es necesario (sin bloquear)
      if (faltasConsecutivas >= 3) {
        _procesarAlertaAsync(
            context, registro, faltasConsecutivas, timoteoDoc, data);
      }
    } catch (e) {
      print('Error en _procesarRegistroAsistencia: $e');
      // No mostrar error al usuario ya que la operación principal podría haber funcionado
    }
  }

// AGREGAR ESTE MÉTODO DESPUÉS DEL MÉTODO _procesarRegistroAsistencia
  Future<void> _procesarAlertaAsync(
      BuildContext context,
      DocumentSnapshot registro,
      int faltasConsecutivas,
      DocumentSnapshot? timoteoDoc,
      Map<String, dynamic> data) async {
    try {
      if (timoteoDoc == null || !timoteoDoc.exists) return;

      final coordinadorId = timoteoDoc.get('coordinadorId');
      if (coordinadorId == null) return;

      // Crear alerta
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
      await FirebaseFirestore.instance
          .collection('registros')
          .doc(registro.id)
          .update({
        'visible': false,
        'estadoAlerta': 'pendiente',
      });

      // Enviar email de manera asíncrona
      try {
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
      } catch (emailError) {
        print('Error enviando email de alerta: $emailError');
        // No interrumpir el flujo por error de email
      }
    } catch (e) {
      print('Error en _procesarAlertaAsync: $e');
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
            child: Container(
              padding: EdgeInsets.all(32),
              margin: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 2,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Color(0xFFFF4B2B).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Color(0xFFFF4B2B),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Error al cargar los datos',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF4B2B),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Por favor, intenta nuevamente',
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

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF147B7C).withOpacity(0.05),
                  Colors.white,
                ],
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF147B7C).withOpacity(0.1),
                          spreadRadius: 8,
                          blurRadius: 16,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFF147B7C)),
                      strokeWidth: 3,
                    ),
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Cargando discípulos...',
                    style: TextStyle(
                      color: Color(0xFF147B7C),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF147B7C).withOpacity(0.05),
                  Colors.white,
                ],
              ),
            ),
            child: Center(
              child: Container(
                padding: EdgeInsets.all(32),
                margin: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 8,
                      blurRadius: 20,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF147B7C).withOpacity(0.1),
                            Color(0xFF147B7C).withOpacity(0.05),
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.people_outline,
                        size: 64,
                        color: Color(0xFF147B7C),
                      ),
                    ),
                    SizedBox(height: 24),
                    Text(
                      'No hay discípulos asignados',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF147B7C),
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Cuando se asignen discípulos,\naparecerán aquí para su seguimiento',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
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
                Color(0xFF147B7C).withOpacity(0.05),
                Colors.white,
              ],
            ),
          ),
          child: Scrollbar(
            thumbVisibility: true,
            thickness: 6,
            radius: Radius.circular(3),
            child: RefreshIndicator(
              onRefresh: () async {
                await Future.delayed(Duration(milliseconds: 500));
              },
              color: Color(0xFF147B7C),
              backgroundColor: Colors.white,
              child: CustomScrollView(
                physics: BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics()),
                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final registro = docs[index];
                          final data = registro.data() as Map<String, dynamic>;

                          final nombre =
                              getFieldSafely<String>(data, 'nombre') ??
                                  'Sin nombre';
                          final apellido =
                              getFieldSafely<String>(data, 'apellido') ?? '';
                          final telefono =
                              getFieldSafely<String>(data, 'telefono') ??
                                  'No disponible';
                          final faltas =
                              getFieldSafely<int>(data, 'faltasConsecutivas') ??
                                  0;
                          final estadoProceso =
                              getFieldSafely<String>(data, 'estadoProceso') ??
                                  'Sin estado';
                          final asistencias =
                              getFieldSafely<List>(data, 'asistencias') ?? [];
                          final visible =
                              getFieldSafely<bool>(data, 'visible') ?? true;

                          // === INDICADOR DE BLOQUEO ===
                          final bool tieneBloqueoPendiente =
                              faltas >= 3 && !visible;

                          return Container(
                            margin: EdgeInsets.only(bottom: 16),
                            child: Card(
                              elevation: 6,
                              shadowColor: Colors.grey.withOpacity(0.3),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.white,
                                      visible
                                          ? Colors.white
                                          : Color(0xFFFF4B2B).withOpacity(0.03),
                                    ],
                                  ),
                                  border: !visible
                                      ? Border.all(
                                          color: Color(0xFFFF4B2B)
                                              .withOpacity(0.3),
                                          width: 2,
                                        )
                                      : null,
                                ),
                                child: ExpansionTile(
                                  tilePadding: EdgeInsets.all(20),
                                  childrenPadding: EdgeInsets.all(0),
                                  backgroundColor: Colors.transparent,
                                  collapsedBackgroundColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  collapsedShape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  leading: Stack(
                                    children: [
                                      Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Color(0xFF147B7C),
                                              Color(0xFF147B7C)
                                                  .withOpacity(0.8),
                                            ],
                                          ),
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Color(0xFF147B7C)
                                                  .withOpacity(0.3),
                                              spreadRadius: 2,
                                              blurRadius: 6,
                                              offset: Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                        child: Center(
                                          child: Text(
                                            nombre.isNotEmpty
                                                ? nombre[0].toUpperCase()
                                                : '?',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                            ),
                                          ),
                                        ),
                                      ),
                                      if (!visible)
                                        Positioned(
                                          top: -2,
                                          right: -2,
                                          child: Container(
                                            width: 20,
                                            height: 20,
                                            decoration: BoxDecoration(
                                              color: Color(0xFFFF4B2B),
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                  color: Colors.white,
                                                  width: 2),
                                            ),
                                            child: Icon(
                                              Icons.warning,
                                              color: Colors.white,
                                              size: 12,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  title: Text(
                                    '$nombre $apellido',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF147B7C),
                                    ),
                                  ),
                                  subtitle: Container(
                                    margin: EdgeInsets.only(top: 8),
                                    child: Wrap(
                                      spacing: 8,
                                      runSpacing: 4,
                                      children: [
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: faltas >= 3
                                                ? Color(0xFFFF4B2B)
                                                    .withOpacity(0.1)
                                                : Color(0xFF147B7C)
                                                    .withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                faltas >= 3
                                                    ? Icons.warning
                                                    : Icons.check_circle,
                                                size: 14,
                                                color: faltas >= 3
                                                    ? Color(0xFFFF4B2B)
                                                    : Color(0xFF147B7C),
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                'Faltas: $faltas',
                                                style: TextStyle(
                                                  color: faltas >= 3
                                                      ? Color(0xFFFF4B2B)
                                                      : Color(0xFF147B7C),
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (!visible)
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Color(0xFFFF4B2B)
                                                  .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              'ALERTA ACTIVA',
                                              style: TextStyle(
                                                color: Color(0xFFFF4B2B),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 10,
                                              ),
                                            ),
                                          ),
                                        // === INDICADOR DE BLOQUEO ===
                                        if (tieneBloqueoPendiente)
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade300,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.block,
                                                  size: 14,
                                                  color: Colors.grey.shade700,
                                                ),
                                                SizedBox(width: 4),
                                                Text(
                                                  'BLOQUEADO',
                                                  style: TextStyle(
                                                    color: Colors.grey.shade700,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 10,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  children: [
                                    Container(
                                      margin: EdgeInsets.only(top: 8),
                                      padding: EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[50],
                                        borderRadius: BorderRadius.only(
                                          bottomLeft: Radius.circular(20),
                                          bottomRight: Radius.circular(20),
                                        ),
                                      ),
                                      child: _buildExpandedContent(
                                        context,
                                        registro,
                                        nombre,
                                        telefono,
                                        estadoProceso,
                                        asistencias,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                        childCount: docs.length,
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
      padding: EdgeInsets.all(16), // Reducido de 24 a 16
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
          SizedBox(height: 12), // Reducido de 16 a 12
          _buildEstadoSection(estadoProceso),
          SizedBox(height: 16), // Reducido de 24 a 16
          _buildActionButtons(context, registro),
          if (asistencias.isNotEmpty) ...[
            SizedBox(height: 16), // Reducido de 24 a 16
            _buildAsistenciasSection(asistencias),
          ],
          SizedBox(height: 8), // Añadido espacio antes de dirección
          Text(
            'Dirección: ${registro.get('direccion') ?? 'No especificada'}',
            style: const TextStyle(
              fontSize: 13, // Reducido de 14 a 13
              color: Color(0xFF147B7C),
            ),
          ),
          SizedBox(height: 3), // Reducido de 4 a 3
          Text(
            'Barrio: ${registro.get('barrio') ?? 'No especificado'}',
            style: const TextStyle(
              fontSize: 13, // Reducido de 14 a 13
              color: Color(0xFF147B7C),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String telefono) {
    return Container(
      padding: EdgeInsets.all(12), // Reducido de 16 a 12
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFF147B7C).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.phone,
              color: Color(0xFF147B7C), size: 20), // Tamaño específico
          SizedBox(width: 10), // Reducido de 12 a 10
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Teléfono de contacto',
                  style: TextStyle(
                    fontSize: 13, // Reducido de 14 a 13
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 2), // Añadido espacio mínimo
                Text(
                  telefono,
                  style: TextStyle(
                    fontSize: 15, // Reducido de 16 a 15
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.copy, color: Color(0xFF147B7C), size: 20),
            padding: EdgeInsets.all(8), // Reducido padding
            constraints:
                BoxConstraints(minWidth: 36, minHeight: 36), // Tamaño mínimo
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
      padding: EdgeInsets.all(12), // Reducido de 16 a 12
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
              Icon(Icons.timeline, color: Color(0xFF147B7C), size: 20),
              SizedBox(width: 10), // Reducido de 12 a 10
              Text(
                'Estado del proceso',
                style: TextStyle(
                  fontSize: 13, // Reducido de 14 a 13
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          SizedBox(height: 6), // Reducido de 8 a 6
          Text(
            estadoProceso,
            style: TextStyle(
              fontSize: 15, // Reducido de 16 a 15
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, DocumentSnapshot registro) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsivo: si la pantalla es muy pequeña, poner botones en columna
        bool isSmallScreen = constraints.maxWidth < 320;

        if (isSmallScreen) {
          return Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: Icon(Icons.edit_note, color: Colors.white, size: 18),
                  label:
                      Text('Actualizar Estado', style: TextStyle(fontSize: 14)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF147B7C),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                        vertical: 12), // Reducido de 16 a 12
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => _actualizarEstado(context, registro),
                ),
              ),
              SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon:
                      Icon(Icons.calendar_today, color: Colors.white, size: 18),
                  label: Text('Registrar Asistencia',
                      style: TextStyle(fontSize: 14)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFFF4B2B),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                        vertical: 12), // Reducido de 16 a 12
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

        return Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                icon: Icon(Icons.edit_note, color: Colors.white, size: 18),
                label:
                    Text('Actualizar Estado', style: TextStyle(fontSize: 14)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF147B7C),
                  foregroundColor: Colors.white,
                  padding:
                      EdgeInsets.symmetric(vertical: 12), // Reducido de 16 a 12
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => _actualizarEstado(context, registro),
              ),
            ),
            SizedBox(width: 8), // Reducido de 12 a 8
            Expanded(
              child: FutureBuilder<bool>(
                future: _tieneBloqueoPorFaltas(
                  registro.id,
                  (registro.data()
                          as Map<String, dynamic>)['faltasConsecutivas'] ??
                      0,
                ),
                builder: (context, snapshot) {
                  final bool bloqueado = snapshot.data == true;
                  final bool cargando =
                      snapshot.connectionState == ConnectionState.waiting;

                  return ElevatedButton.icon(
                    icon: Icon(
                      bloqueado ? Icons.block : Icons.calendar_today,
                      color: Colors.white,
                      size: 18,
                    ),
                    label: Text(
                      bloqueado
                          ? 'Bloqueado'
                          : (cargando
                              ? 'Verificando...'
                              : 'Registrar Asistencia'),
                      style: TextStyle(fontSize: 14),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          bloqueado ? Colors.grey.shade400 : Color(0xFFFF4B2B),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      disabledBackgroundColor: Colors.grey.shade300,
                      disabledForegroundColor: Colors.grey.shade500,
                    ),
                    onPressed: (bloqueado || cargando)
                        ? null
                        : () => _registrarAsistencia(context, registro),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

// Método para agrupar asistencias por año, mes y semana
  Map<int, Map<int, Map<String, List<Map<String, dynamic>>>>>
      agruparAsistenciasPorSemana(List asistencias) {
    final Map<int, Map<int, Map<String, List<Map<String, dynamic>>>>>
        agrupadas = {};

    for (var asistencia in asistencias) {
      try {
        final fecha = (asistencia['fecha'] as Timestamp).toDate();
        final year = fecha.year;
        final month = fecha.month;

        // Calcular el inicio de la semana (lunes)
        final diasDesdeInicioSemana = (fecha.weekday - 1) % 7;
        final inicioSemana =
            fecha.subtract(Duration(days: diasDesdeInicioSemana));
        final finSemana = inicioSemana.add(Duration(days: 6));

        // Crear clave de semana legible
        final claveSemanaDel = DateFormat('dd/MM', 'es').format(inicioSemana);
        final claveSemanaAl = DateFormat('dd/MM', 'es').format(finSemana);
        final claveSemana = '$claveSemanaDel - $claveSemanaAl';

        // Inicializar estructuras si no existen
        agrupadas[year] ??= {};
        agrupadas[year]![month] ??= {};
        agrupadas[year]![month]![claveSemana] ??= [];

        agrupadas[year]![month]![claveSemana]!.add(asistencia);
      } catch (e) {
        print('Error procesando asistencia: $e');
        continue;
      }
    }

    // Ordenar las asistencias dentro de cada semana
    agrupadas.forEach((year, meses) {
      meses.forEach((month, semanas) {
        semanas.forEach((semana, asistenciasSemanales) {
          asistenciasSemanales.sort((a, b) {
            try {
              final fechaA = (a['fecha'] as Timestamp).toDate();
              final fechaB = (b['fecha'] as Timestamp).toDate();
              return fechaB.compareTo(fechaA); // Más reciente primero
            } catch (e) {
              return 0;
            }
          });
        });
      });
    });

    return agrupadas;
  }

  Widget _buildAsistenciasSection(List asistencias) {
    if (asistencias.isEmpty) {
      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Color(0xFF147B7C).withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 40,
              color: Colors.grey[400],
            ),
            SizedBox(height: 8),
            Text(
              'Sin historial de asistencias',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    // Ordenar las asistencias de más reciente a más antigua
    final asistenciasOrdenadas = List.from(asistencias);
    asistenciasOrdenadas.sort((a, b) {
      try {
        return (b['fecha'] as Timestamp)
            .toDate()
            .compareTo((a['fecha'] as Timestamp).toDate());
      } catch (e) {
        return 0;
      }
    });

    final asistenciasAgrupadas =
        agruparAsistenciasPorSemana(asistenciasOrdenadas);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF147B7C), Color(0xFF147B7C).withOpacity(0.8)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.history, color: Colors.white, size: 18),
              SizedBox(width: 6),
              Text(
                'Historial de Asistencias',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${asistencias.length}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            double maxHeight = constraints.maxWidth > 600 ? 350 : 300;

            return Container(
              constraints: BoxConstraints(maxHeight: maxHeight),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Color(0xFF147B7C).withOpacity(0.2)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Scrollbar(
                thumbVisibility: true,
                thickness: 3,
                radius: Radius.circular(2),
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    children: asistenciasAgrupadas.entries.map((entradaAno) {
                      final year = entradaAno.key;
                      final totalAsistenciasAno = entradaAno.value.values.fold(
                          0,
                          (sum, meses) =>
                              sum +
                              meses.values.fold(
                                  0,
                                  (sumMes, semanas) =>
                                      sumMes + semanas.length));

                      return Container(
                        margin: EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          border:
                              Border.all(color: Colors.grey.withOpacity(0.2)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ExpansionTile(
                          initiallyExpanded: year == DateTime.now().year,
                          tilePadding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          childrenPadding: EdgeInsets.only(bottom: 8),
                          backgroundColor: Colors.transparent,
                          collapsedBackgroundColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          collapsedShape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          title: Container(
                            padding: EdgeInsets.symmetric(
                                vertical: 6, horizontal: 10),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color(0xFF147B7C).withOpacity(0.1),
                                  Color(0xFF147B7C).withOpacity(0.05),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.date_range,
                                    color: Color(0xFF147B7C), size: 18),
                                SizedBox(width: 6),
                                Text(
                                  'Año $year',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF147B7C),
                                  ),
                                ),
                                Spacer(),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Color(0xFF147B7C).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '$totalAsistenciasAno',
                                    style: TextStyle(
                                      color: Color(0xFF147B7C),
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          children: entradaAno.value.entries.map((entradaMes) {
                            final month = entradaMes.key;
                            final totalAsistenciasMes = entradaMes.value.values
                                .fold(
                                    0, (sum, semanas) => sum + semanas.length);

                            return Container(
                              margin: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ExpansionTile(
                                initiallyExpanded:
                                    month == DateTime.now().month &&
                                        year == DateTime.now().year,
                                tilePadding: EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 3),
                                childrenPadding: EdgeInsets.all(6),
                                backgroundColor: Colors.transparent,
                                collapsedBackgroundColor: Colors.transparent,
                                title: Row(
                                  children: [
                                    Icon(Icons.calendar_month,
                                        color: Colors.grey[600], size: 14),
                                    SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        DateFormat('MMMM', 'es')
                                            .format(DateTime(year, month)),
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 5, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[300],
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '$totalAsistenciasMes',
                                        style: TextStyle(
                                          color: Colors.grey[700],
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                children: [
                                  // Aquí mostramos las semanas
                                  Column(
                                    children: entradaMes.value.entries
                                        .map((entradaSemana) {
                                      final claveSemana = entradaSemana.key;
                                      final asistenciasSemana =
                                          entradaSemana.value;

                                      return Container(
                                        margin: EdgeInsets.only(bottom: 8),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                              color:
                                                  Colors.grey.withOpacity(0.3)),
                                        ),
                                        child: ExpansionTile(
                                          initiallyExpanded: false,
                                          tilePadding: EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 2),
                                          childrenPadding: EdgeInsets.all(4),
                                          backgroundColor: Colors.transparent,
                                          collapsedBackgroundColor:
                                              Colors.transparent,
                                          title: Row(
                                            children: [
                                              Icon(Icons.view_week,
                                                  color: Colors.grey[500],
                                                  size: 12),
                                              SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  'Semana $claveSemana',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w500,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ),
                                              Container(
                                                padding: EdgeInsets.symmetric(
                                                    horizontal: 4, vertical: 1),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey[200],
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  '${asistenciasSemana.length}',
                                                  style: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          children: [
                                            LayoutBuilder(
                                              builder: (context, constraints) {
                                                int crossAxisCount = constraints
                                                            .maxWidth >
                                                        400
                                                    ? 5
                                                    : constraints.maxWidth > 300
                                                        ? 4
                                                        : 3;

                                                return Container(
                                                  constraints: BoxConstraints(
                                                      maxHeight: 100),
                                                  child: Scrollbar(
                                                    thumbVisibility: false,
                                                    child: GridView.builder(
                                                      shrinkWrap: true,
                                                      physics:
                                                          BouncingScrollPhysics(),
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                              horizontal: 2),
                                                      gridDelegate:
                                                          SliverGridDelegateWithFixedCrossAxisCount(
                                                        crossAxisCount:
                                                            crossAxisCount,
                                                        childAspectRatio: 0.9,
                                                        crossAxisSpacing: 6,
                                                        mainAxisSpacing: 6,
                                                      ),
                                                      itemCount:
                                                          asistenciasSemana
                                                              .length,
                                                      itemBuilder:
                                                          (context, index) {
                                                        final asistencia =
                                                            asistenciasSemana[
                                                                index];
                                                        final bool asistio =
                                                            asistencia[
                                                                    'asistio'] ??
                                                                false;
                                                        final fecha =
                                                            (asistencia['fecha']
                                                                    as Timestamp)
                                                                .toDate();
                                                        final nombreServicio =
                                                            asistencia[
                                                                    'nombreServicio'] ??
                                                                'Servicio';

                                                        return Container(
                                                          decoration:
                                                              BoxDecoration(
                                                            gradient:
                                                                LinearGradient(
                                                              begin: Alignment
                                                                  .topLeft,
                                                              end: Alignment
                                                                  .bottomRight,
                                                              colors:
                                                                  asistio
                                                                      ? [
                                                                          Color(
                                                                              0xFF147B7C),
                                                                          Color(0xFF147B7C)
                                                                              .withOpacity(0.8)
                                                                        ]
                                                                      : [
                                                                          Color(
                                                                              0xFFFF4B2B),
                                                                          Color(0xFFFF4B2B)
                                                                              .withOpacity(0.8)
                                                                        ],
                                                            ),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        10),
                                                            boxShadow: [
                                                              BoxShadow(
                                                                color: (asistio
                                                                        ? Color(
                                                                            0xFF147B7C)
                                                                        : Color(
                                                                            0xFFFF4B2B))
                                                                    .withOpacity(
                                                                        0.3),
                                                                spreadRadius: 1,
                                                                blurRadius: 2,
                                                                offset: Offset(
                                                                    0, 1),
                                                              ),
                                                            ],
                                                          ),
                                                          child: Material(
                                                            color: Colors
                                                                .transparent,
                                                            child: InkWell(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          10),
                                                              onTap: () {
                                                                _mostrarDetalleAsistencia(
                                                                    context,
                                                                    asistencia,
                                                                    asistio);
                                                              },
                                                              child: Padding(
                                                                padding:
                                                                    EdgeInsets
                                                                        .all(6),
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
                                                                      color: Colors
                                                                          .white,
                                                                      size: 16,
                                                                    ),
                                                                    SizedBox(
                                                                        height:
                                                                            2),
                                                                    Text(
                                                                      DateFormat(
                                                                              'dd')
                                                                          .format(
                                                                              fecha),
                                                                      style:
                                                                          TextStyle(
                                                                        fontSize:
                                                                            12,
                                                                        fontWeight:
                                                                            FontWeight.bold,
                                                                        color: Colors
                                                                            .white,
                                                                      ),
                                                                    ),
                                                                    Text(
                                                                      DateFormat(
                                                                              'EEE',
                                                                              'es')
                                                                          .format(
                                                                              fecha)
                                                                          .toUpperCase(),
                                                                      style:
                                                                          TextStyle(
                                                                        fontSize:
                                                                            7,
                                                                        color: Colors
                                                                            .white
                                                                            .withOpacity(0.9),
                                                                        fontWeight:
                                                                            FontWeight.w500,
                                                                      ),
                                                                    ),
                                                                    if (nombreServicio.length <=
                                                                            12 &&
                                                                        crossAxisCount <=
                                                                            4) ...[
                                                                      SizedBox(
                                                                          height:
                                                                              1),
                                                                      Text(
                                                                        nombreServicio,
                                                                        style:
                                                                            TextStyle(
                                                                          fontSize:
                                                                              6,
                                                                          color: Colors
                                                                              .white
                                                                              .withOpacity(0.8),
                                                                          fontWeight:
                                                                              FontWeight.w400,
                                                                        ),
                                                                        textAlign:
                                                                            TextAlign.center,
                                                                        maxLines:
                                                                            1,
                                                                        overflow:
                                                                            TextOverflow.ellipsis,
                                                                      ),
                                                                    ],
                                                                  ],
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
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
            );
          },
        ),
      ],
    );
  }

  void _mostrarDetalleAsistencia(
      BuildContext context, Map<String, dynamic> asistencia, bool asistio) {
    final fecha = (asistencia['fecha'] as Timestamp).toDate();
    final nombreServicio = asistencia['nombreServicio'] ?? 'Servicio';

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                (asistio ? Color(0xFF147B7C) : Color(0xFFFF4B2B))
                    .withOpacity(0.05),
              ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (asistio ? Color(0xFF147B7C) : Color(0xFFFF4B2B))
                      .withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  asistio ? Icons.check_circle : Icons.cancel,
                  color: asistio ? Color(0xFF147B7C) : Color(0xFFFF4B2B),
                  size: 32,
                ),
              ),
              SizedBox(height: 16),
              Text(
                asistio ? 'Asistió al Servicio' : 'No Asistió al Servicio',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: asistio ? Color(0xFF147B7C) : Color(0xFFFF4B2B),
                ),
              ),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.calendar_today,
                            size: 16, color: Colors.grey[600]),
                        SizedBox(width: 8),
                        Text(
                          'Fecha:',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            DateFormat('EEEE, dd \'de\' MMMM \'de\' yyyy', 'es')
                                .format(fecha),
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.event, size: 16, color: Colors.grey[600]),
                        SizedBox(width: 8),
                        Text(
                          'Servicio:',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            nombreServicio,
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF147B7C),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cerrar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
