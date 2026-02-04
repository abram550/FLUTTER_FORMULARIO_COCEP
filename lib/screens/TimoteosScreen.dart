// Dart SDK
import 'dart:async';
import 'dart:math';

// Flutter
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';

// Firebase
import 'package:cloud_firestore/cloud_firestore.dart';

// Paquetes externos
import 'package:flutter_animate/flutter_animate.dart';
import 'package:formulario_app/services/auth_service.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

// Proyecto
import 'package:formulario_app/utils/email_service.dart';

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
          duration: Duration(seconds: 1), // ✅ Reducido a 1 segundo
        ),
      );

      // ✅ CRÍTICO: Usar AuthService().logout() para limpiar SharedPreferences
      final authService = AuthService();
      await authService.logout();

      // ✅ NUEVO: Verificar que se limpió correctamente
      final stillAuth = await authService.isAuthenticated();
      if (stillAuth) {
        print(
            '⚠️ ADVERTENCIA: Usuario todavía aparece autenticado después de logout');
      } else {
        print('✅ Logout exitoso - Usuario NO autenticado');
      }

      await Future.delayed(Duration(milliseconds: 500));

      if (mounted) {
        // ✅ NUEVO: Usar pushReplacement en lugar de go para limpiar el stack
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
          toolbarHeight: null, // Permite altura automática
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  kPrimaryColor,
                  kPrimaryColor.withOpacity(0.85),
                ],
              ),
            ),
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(20),
            ),
          ),
          title: LayoutBuilder(
            builder: (context, constraints) {
              // Detectar ancho disponible
              final double availableWidth = constraints.maxWidth;

              // Determinar si es pantalla pequeña
              final bool isSmallScreen = availableWidth < 380;
              final bool isMediumScreen =
                  availableWidth >= 380 && availableWidth < 600;

              return Row(
                children: [
                  // Avatar con animación sutil
                  Hero(
                    tag: 'avatar_${widget.timoteoId}',
                    child: Container(
                      height: isSmallScreen ? 36 : 40,
                      width: isSmallScreen ? 36 : 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.person,
                        color: kPrimaryColor,
                        size: isSmallScreen ? 20 : 24,
                      ),
                    ),
                  ),
                  SizedBox(width: isSmallScreen ? 10 : 12),

                  // Columna con título adaptativo
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Label "Timoteo" - siempre en una línea
                        Text(
                          'Timoteo',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 11 : 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withOpacity(0.85),
                            letterSpacing: 0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 2),

                        // Nombre adaptativo con ajuste automático
                        LayoutBuilder(
                          builder: (context, nameConstraints) {
                            final String nombre = widget.timoteoNombre;

                            // Calcular tamaño de fuente óptimo
                            double fontSize = isSmallScreen ? 16 : 20;
                            int maxLines = 1;

                            // Si el nombre es muy largo, permitir 2 líneas
                            if (nombre.length > 15 && isSmallScreen) {
                              maxLines = 2;
                              fontSize = 14;
                            } else if (nombre.length > 20 && isMediumScreen) {
                              maxLines = 2;
                              fontSize = 16;
                            }

                            return Text(
                              nombre,
                              style: TextStyle(
                                fontSize: fontSize,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                height: 1.2,
                                letterSpacing: 0.2,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.2),
                                    offset: const Offset(0, 1),
                                    blurRadius: 2,
                                  ),
                                ],
                              ),
                              maxLines: maxLines,
                              overflow: TextOverflow.ellipsis,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          actions: [
            // Botón de cerrar sesión - siempre visible con texto
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Container(
                constraints: const BoxConstraints(
                  minWidth: 70,
                  maxWidth: 100,
                ),
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
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.logout_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                            SizedBox(width: 4),
                            SizedBox(
                              width: 58,
                              child: Text(
                                'Cerrar\nsesión',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.3,
                                  height: 1.1,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(50),
            child: TabBar(
              controller: _tabController,
              indicatorColor: kSecondaryColor,
              indicatorWeight: 4,
              indicatorSize: TabBarIndicatorSize.label,
              labelStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 15,
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: [
                Tab(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Si el ancho es muy pequeño, ajustar diseño
                      if (constraints.maxWidth < 100) {
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.person_outline, size: 18),
                            SizedBox(height: 2),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text('Perfil'),
                            ),
                          ],
                        );
                      }
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.person_outline, size: 20),
                          SizedBox(width: 6),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text('Perfil'),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                Tab(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 100) {
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.groups_outlined, size: 18),
                            SizedBox(height: 2),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text('Discípulos'),
                            ),
                          ],
                        );
                      }
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.groups_outlined, size: 20),
                          SizedBox(width: 6),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text('Discípulos'),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
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

    // Variable para controlar la visibilidad de la contraseña
    bool _obscurePassword = true;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (stateContext, setState) {
            return AlertDialog(
              backgroundColor: kCardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: kSecondaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.edit_rounded,
                      color: kSecondaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
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
                    // Campo de contraseña con visibilidad toggle
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: TextStyle(fontSize: 16),
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        labelStyle: TextStyle(color: Colors.grey.shade700),
                        prefixIcon: Container(
                          padding: EdgeInsets.all(8),
                          child: Icon(Icons.lock_outline, color: kPrimaryColor),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: kPrimaryColor,
                            size: 22,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                          tooltip: _obscurePassword
                              ? 'Mostrar contraseña'
                              : 'Ocultar contraseña',
                        ),
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
                          borderSide:
                              BorderSide(color: kPrimaryColor, width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        contentPadding: EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                    'Cancelar',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kSecondaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    elevation: 2,
                  ),
                  child: const Text(
                    'Guardar',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
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
    final int faltas = (data['faltasConsecutivas'] as num?)?.toInt() ?? 0;
    final bool visible = data['visible'] ?? true;
    final String estadoAlerta = data['estadoAlerta'] ?? '';

    // Solo mostrar en rojo si tiene 3+ faltas Y visible es false Y hay alerta activa
    if (faltas >= 3 &&
        !visible &&
        (estadoAlerta == 'pendiente' || estadoAlerta == 'en_revision')) {
      return Colors.red.shade100;
    }

    return Colors.white;
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
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        elevation: 8,
        insetPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Obtener dimensiones de la pantalla
            final screenHeight = MediaQuery.of(context).size.height;
            final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

            // Calcular altura disponible sin el teclado
            final availableHeight = screenHeight - keyboardHeight - 48;

            return Container(
              constraints: BoxConstraints(
                maxWidth: 500,
                maxHeight: availableHeight,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ===== ENCABEZADO CON GRADIENTE =====
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF147B7C),
                          Color(0xFF147B7C).withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF147B7C).withOpacity(0.3),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            Icons.edit_note_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Actualizar Estado',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Estado del proceso del discípulo',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ===== CONTENIDO SCROLLEABLE =====
                  Flexible(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Etiqueta del campo
                          Row(
                            children: [
                              Icon(
                                Icons.timeline_rounded,
                                color: Color(0xFF147B7C),
                                size: 18,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Estado actual del proceso',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF147B7C),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10),

                          // Campo de texto
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Color(0xFF147B7C).withOpacity(0.3),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0xFF147B7C).withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: estadoController,
                              maxLines: 5,
                              maxLength: 500,
                              autofocus: false,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                                height: 1.4,
                              ),
                              decoration: InputDecoration(
                                hintText:
                                    'Describe el estado actual del joven en la iglesia...\n\nEjemplo: Asistiendo regularmente, participando en actividades juveniles...',
                                hintStyle: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 13,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: Color(0xFF147B7C),
                                    width: 2,
                                  ),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                                contentPadding: EdgeInsets.all(14),
                                counterStyle: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: 12),

                          // Nota informativa
                          Container(
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Color(0xFFFFB74D).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Color(0xFFFFB74D).withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Color(0xFFFFB74D),
                                  size: 18,
                                ),
                                SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Esta información ayuda a dar seguimiento al progreso del discípulo en su caminar espiritual.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[700],
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Espacio para evitar que el teclado tape el contenido
                          SizedBox(height: keyboardHeight > 0 ? 20 : 0),
                        ],
                      ),
                    ),
                  ),

                  // ===== BOTONES DE ACCIÓN (SIEMPRE VISIBLES AL FINAL) =====
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: Offset(0, -4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Botón Cancelar
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.grey[700],
                              side: BorderSide(
                                color: Colors.grey[300]!,
                                width: 1.5,
                              ),
                              padding: EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              'Cancelar',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                        SizedBox(width: 10),

                        // Botón Guardar
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            icon: Icon(Icons.check_circle_outline, size: 18),
                            label: Text(
                              'Guardar Cambios',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF147B7C),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            onPressed: () async {
                              // Validar que haya contenido
                              if (estadoController.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        Icon(Icons.warning,
                                            color: Colors.white),
                                        SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                              'Por favor, ingresa un estado'),
                                        ),
                                      ],
                                    ),
                                    backgroundColor: Color(0xFFFF4B2B),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                );
                                return;
                              }

                              try {
                                // Guardar en Firestore
                                await FirebaseFirestore.instance
                                    .collection('registros')
                                    .doc(registro.id)
                                    .set({
                                  'estadoProceso': estadoController.text.trim(),
                                  'fechaActualizacionEstado':
                                      FieldValue.serverTimestamp(),
                                }, SetOptions(merge: true));

                                Navigator.pop(context);

                                // Mostrar confirmación exitosa
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.white.withOpacity(0.2),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.check,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            'Estado actualizado correctamente',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    backgroundColor: Color(0xFF147B7C),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    duration: Duration(seconds: 3),
                                  ),
                                );
                              } catch (e) {
                                print('Error al actualizar el estado: $e');

                                // Mostrar error
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        Icon(Icons.error, color: Colors.white),
                                        SizedBox(width: 12),
                                        Expanded(
                                          child: Text('Error: ${e.toString()}'),
                                        ),
                                      ],
                                    ),
                                    backgroundColor: Color(0xFFFF4B2B),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
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
          return "Servicio Familiar"; // ✅ MODIFICADO: Cambio visual
      }
    } else if (categoriaTribu == "Ministerio de Caballeros") {
      switch (diaSemana) {
        case "jueves":
          return "Servicio de Caballeros";
        case "viernes":
          return "Viernes de Poder";
        case "sábado":
          return "Servicio de Caballeros";
        case "domingo":
          return "Servicio Familiar"; // ✅ MODIFICADO: Cambio visual
      }
    } else if (categoriaTribu == "Ministerio Juvenil") {
      switch (diaSemana) {
        case "viernes":
          return "Viernes de Poder";
        case "sábado":
          return "Impacto Juvenil";
        case "domingo":
          return "Servicio Familiar"; // ✅ MODIFICADO: Cambio visual
      }
    }
    return "Servicio Especial"; // ✅ MODIFICADO: Cambio de "Reunión General" a "Servicio Especial"
  }

// ========================================
// MÉTODO AUXILIAR PARA NORMALIZACIÓN DE NOMBRES DE SERVICIOS
// ========================================
  String _normalizarNombreServicio(String nombreServicio) {
    // Convertir "Servicio Dominical" a "Servicio Familiar" solo para visualización
    if (nombreServicio.toLowerCase().contains('dominical')) {
      return nombreServicio.replaceAll(
          RegExp(r'dominical', caseSensitive: false), 'Familiar');
    }

    // Convertir "Reunión General" a "Servicio Especial" solo para visualización
    if (nombreServicio.toLowerCase().contains('reunión general') ||
        nombreServicio.toLowerCase().contains('reunion general')) {
      return "Servicio Especial";
    }

    return nombreServicio;
  }

  String _desnormalizarNombreServicio(String nombreServicio) {
    // Convertir "Servicio Familiar" de vuelta a "Servicio Dominical" para consultas
    if (nombreServicio.toLowerCase().contains('familiar')) {
      return nombreServicio.replaceAll(
          RegExp(r'familiar', caseSensitive: false), 'Dominical');
    }

    // Convertir "Servicio Especial" de vuelta a "Reunión General" para consultas
    if (nombreServicio.toLowerCase().contains('servicio especial')) {
      return "Reunión General";
    }

    return nombreServicio;
  }

  /// Bloquea asistencia si el registro tiene 3+ faltas Y existe una alerta no revisada.
  Future<bool> _tieneBloqueoPorFaltas(
      String registroId, int faltasActuales) async {
    try {
      // Si tiene menos de 3 faltas, no hay bloqueo
      if (faltasActuales < 3) return false;

      // Verificar si existe alerta activa no procesada
      final qs = await FirebaseFirestore.instance
          .collection('alertas')
          .where('registroId', isEqualTo: registroId)
          .where('tipo', isEqualTo: 'faltasConsecutivas')
          .where('procesada', isEqualTo: false)
          .get();

      if (qs.docs.isEmpty) return false;

      // Verificar estados de las alertas encontradas
      for (var doc in qs.docs) {
        final estado = doc.get('estado') ?? '';
        if (estado == 'pendiente' || estado == 'en_revision') {
          return true;
        }
      }

      return false;
    } catch (e) {
      print('Error verificando bloqueo por faltas: $e');
      return false;
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

      // Verificar bloqueo solo si tiene 3+ faltas
      if (faltasActuales >= 3) {
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
      }
// === FIN BLOQUEO ===

// ===== VALIDACIÓN ANTI-DUPLICACIÓN MEJORADA =====
      // Verificar con ventana de tiempo precisa (00:00:00 - 23:59:59)
      final DateTime inicioDelDia = DateTime(
        fechaSeleccionada.year,
        fechaSeleccionada.month,
        fechaSeleccionada.day,
        0, 0, 0, 0, // Hora exacta: 00:00:00.000
      );
      final DateTime finDelDia = DateTime(
        fechaSeleccionada.year,
        fechaSeleccionada.month,
        fechaSeleccionada.day,
        23, 59, 59, 999, // Hora exacta: 23:59:59.999
      );

      try {
        final yaRegistrada = await FirebaseFirestore.instance
            .collection('asistencias')
            .where('jovenId', isEqualTo: registro.id)
            .where('fecha',
                isGreaterThanOrEqualTo: Timestamp.fromDate(inicioDelDia))
            .where('fecha', isLessThanOrEqualTo: Timestamp.fromDate(finDelDia))
            .limit(1) // Optimización: solo necesitamos saber si existe 1
            .get()
            .timeout(
              Duration(seconds: 10),
              onTimeout: () =>
                  throw TimeoutException('Timeout verificando duplicados'),
            );

        if (yaRegistrada.docs.isNotEmpty) {
          // ✅ CORRECCIÓN: Verificar contexto válido en lugar de mounted
          if (context.mounted) {
            // Obtener información del registro existente para mensaje más informativo
            final registroExistente =
                yaRegistrada.docs.first.data() as Map<String, dynamic>?;
            final nombreServicio =
                registroExistente?['nombreServicio'] ?? 'servicio';

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
                      child: Icon(Icons.warning_amber,
                          color: Colors.white, size: 20),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Asistencia ya registrada',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'Ya existe registro para "$nombreServicio" en esta fecha',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
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
      } catch (e) {
        print('❌ Error verificando duplicados: $e');
        // ✅ CORRECCIÓN: Verificar contexto válido
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Error al verificar asistencias previas. Intenta nuevamente.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      // ===== FIN VALIDACIÓN =====

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

      // Obtener información de tribu
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
      }

      // ✅ OBTENER Y NORMALIZAR NOMBRE DEL SERVICIO
      String nombreServicio =
          obtenerNombreServicio(categoriaTribu, fechaSeleccionada);

      // ✅ NORMALIZACIÓN: Convertir "Dominical" a "Familiar"
      nombreServicio = nombreServicio
          .replaceAll(RegExp(r'dominical', caseSensitive: false), 'Familiar')
          .replaceAll(RegExp(r'reuni[óo]n general', caseSensitive: false),
              'Servicio Especial');

      // ✅ VERIFICAR DUPLICADOS ANTES DE CREAR (clave para evitar duplicación)
      final startOfDay = DateTime(
        fechaSeleccionada.year,
        fechaSeleccionada.month,
        fechaSeleccionada.day,
      );
      final endOfDay = startOfDay.add(Duration(days: 1));

      final existingAttendance = await FirebaseFirestore.instance
          .collection('asistencias')
          .where('jovenId', isEqualTo: registro.id)
          .where('fecha',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('fecha', isLessThan: Timestamp.fromDate(endOfDay))
          .limit(1)
          .get();

      if (existingAttendance.docs.isNotEmpty) {
        print('⚠️ Asistencia ya existe para esta fecha, omitiendo duplicado');
        return;
      }

      // Calcular faltas
      int faltasConsecutivas = data['faltasConsecutivas'] ?? 0;
      if (!asistio) {
        faltasConsecutivas++;
      } else {
        faltasConsecutivas = 0;
      }

      // ✅ BATCH PARA OPERACIONES ATÓMICAS
      final batch = FirebaseFirestore.instance.batch();

      // 1. Actualizar registro principal
      batch.update(registroRef, {
        'asistencias': FieldValue.arrayUnion([
          {
            'fecha': Timestamp.fromDate(fechaSeleccionada),
            'asistio': asistio,
            'nombreServicio': nombreServicio, // ✅ Nombre normalizado
          }
        ]),
        'faltasConsecutivas': faltasConsecutivas,
        'ultimaAsistencia': Timestamp.fromDate(fechaSeleccionada),
      });

      // 2. ✅ CREAR DOCUMENTO EN COLECCIÓN ASISTENCIAS (principal)
      final asistenciaRef =
          FirebaseFirestore.instance.collection('asistencias').doc();
      batch.set(asistenciaRef, {
        'jovenId': registro.id,
        'tribuId': tribuId,
        'nombre': data['nombre'] ?? '',
        'apellido': data['apellido'] ?? '',
        'nombreCompleto': '${data['nombre']} ${data['apellido']}',
        'fecha': Timestamp.fromDate(fechaSeleccionada),
        'nombreServicio': nombreServicio, // ✅ Nombre normalizado
        'asistio': asistio,
        'diaSemana': DateFormat('EEEE', 'es').format(fechaSeleccionada),
        'fechaRegistro': FieldValue.serverTimestamp(),
        'categoriaTribu': categoriaTribu,
        'coordinadorId': timoteoDoc?.get('coordinadorId'),
      });

      // 3. ✅ NO CREAR EN asistenciaTribus para evitar duplicación
      // (Esta colección ya no se usa para visualización)

      // Ejecutar batch
      await batch.commit();
      print('✅ Asistencia registrada correctamente: $nombreServicio');

      // Procesar alertas si es necesario
      if (faltasConsecutivas >= 3) {
        _procesarAlertaAsync(
            context, registro, faltasConsecutivas, timoteoDoc, data);
      }
    } catch (e) {
      print('❌ Error en _procesarRegistroAsistencia: $e');
    }
  }

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

      // Verificar si ya existe una alerta activa para este registro
      final alertasExistentes = await FirebaseFirestore.instance
          .collection('alertas')
          .where('registroId', isEqualTo: registro.id)
          .where('tipo', isEqualTo: 'faltasConsecutivas')
          .where('procesada', isEqualTo: false)
          .get();

      // Si ya existe una alerta activa, no crear otra
      if (alertasExistentes.docs.isNotEmpty) {
        print('Ya existe una alerta activa para este registro');
        return;
      }

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

        final docsOriginales = snapshot.data?.docs ?? [];

        // ===== ORDENAMIENTO ALFABÉTICO A-Z =====
        final docs = List<QueryDocumentSnapshot>.from(docsOriginales);
        docs.sort((a, b) {
          final dataA = a.data() as Map<String, dynamic>;
          final dataB = b.data() as Map<String, dynamic>;

          final nombreA = (dataA['nombre'] ?? '').toString().toLowerCase();
          final nombreB = (dataB['nombre'] ?? '').toString().toLowerCase();

          return nombreA.compareTo(nombreB);
        });

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
                    padding: EdgeInsets.all(12),
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

                          // Verificar estado de alerta
                          final String estadoAlerta =
                              getFieldSafely<String>(data, 'estadoAlerta') ??
                                  '';
                          final bool tieneAlertaActiva =
                              estadoAlerta == 'pendiente' ||
                                  estadoAlerta == 'en_revision';
                          final bool tieneBloqueoPendiente =
                              faltas >= 3 && !visible;

                          return Container(
                            margin: EdgeInsets.only(bottom: 10),
                            child: Card(
                              elevation: tieneAlertaActiva ? 6 : 3,
                              shadowColor: tieneAlertaActiva
                                  ? Color(0xFFFF4B2B).withOpacity(0.4)
                                  : Colors.grey.withOpacity(0.2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: tieneAlertaActiva
                                        ? [
                                            Colors.white,
                                            Color(0xFFFF4B2B).withOpacity(0.03),
                                          ]
                                        : [
                                            Colors.white,
                                            Colors.white,
                                          ],
                                  ),
                                  border: tieneAlertaActiva
                                      ? Border.all(
                                          color: Color(0xFFFF4B2B)
                                              .withOpacity(0.3),
                                          width: 2,
                                        )
                                      : null,
                                ),
                                child: Column(
                                  children: [
                                    // ExpansionTile principal
                                    ExpansionTile(
                                      tilePadding: EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 10),
                                      childrenPadding: EdgeInsets.all(0),
                                      backgroundColor: Colors.transparent,
                                      collapsedBackgroundColor:
                                          Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      collapsedShape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      leading: Stack(
                                        children: [
                                          Container(
                                            width: 40,
                                            height: 40,
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
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ),
                                          ),
                                          if (tieneAlertaActiva)
                                            Positioned(
                                              top: -2,
                                              right: -2,
                                              child: Container(
                                                width: 18,
                                                height: 18,
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
                                                  size: 10,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      title: Text(
                                        '$nombre $apellido',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF147B7C),
                                        ),
                                      ),
                                      subtitle: Container(
                                        margin: EdgeInsets.only(top: 6),
                                        child: Wrap(
                                          spacing: 6,
                                          runSpacing: 4,
                                          children: [
                                            // Badge de faltas
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 6, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: faltas >= 3
                                                    ? Color(0xFFFF4B2B)
                                                        .withOpacity(0.1)
                                                    : Color(0xFF147B7C)
                                                        .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    faltas >= 3
                                                        ? Icons.warning
                                                        : Icons.check_circle,
                                                    size: 11,
                                                    color: faltas >= 3
                                                        ? Color(0xFFFF4B2B)
                                                        : Color(0xFF147B7C),
                                                  ),
                                                  SizedBox(width: 3),
                                                  Text(
                                                    'Faltas: $faltas',
                                                    style: TextStyle(
                                                      color: faltas >= 3
                                                          ? Color(0xFFFF4B2B)
                                                          : Color(0xFF147B7C),
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 10,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),

                                            // Badge de ALERTA ACTIVA
                                            if (tieneAlertaActiva)
                                              Container(
                                                padding: EdgeInsets.symmetric(
                                                    horizontal: 6, vertical: 3),
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      Color(0xFFFF4B2B),
                                                      Color(0xFFFF6B4A),
                                                    ],
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Color(0xFFFF4B2B)
                                                          .withOpacity(0.3),
                                                      blurRadius: 4,
                                                      offset: Offset(0, 2),
                                                    ),
                                                  ],
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons
                                                          .notification_important,
                                                      size: 11,
                                                      color: Colors.white,
                                                    ),
                                                    SizedBox(width: 3),
                                                    Text(
                                                      'ALERTA',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 9,
                                                        letterSpacing: 0.3,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),

                                            // Badge de bloqueado
                                            if (tieneBloqueoPendiente)
                                              Container(
                                                padding: EdgeInsets.symmetric(
                                                    horizontal: 6, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey.shade300,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(Icons.block,
                                                        size: 11,
                                                        color: Colors
                                                            .grey.shade700),
                                                    SizedBox(width: 3),
                                                    Text(
                                                      'BLOQUEADO',
                                                      style: TextStyle(
                                                        color: Colors
                                                            .grey.shade700,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 9,
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
                                          margin: EdgeInsets.only(top: 6),
                                          padding: EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[50],
                                            borderRadius: BorderRadius.only(
                                              bottomLeft: Radius.circular(14),
                                              bottomRight: Radius.circular(14),
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

                                    // ===== BANNER DE ALERTA INFORMATIVO (VISIBLE CUANDO HAY ALERTA) =====
                                    if (tieneAlertaActiva)
                                      Container(
                                        width: double.infinity,
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 10),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.centerLeft,
                                            end: Alignment.centerRight,
                                            colors: [
                                              Color(0xFFFF4B2B)
                                                  .withOpacity(0.08),
                                              Color(0xFFFF6B4A)
                                                  .withOpacity(0.04),
                                            ],
                                          ),
                                          border: Border(
                                            top: BorderSide(
                                              color: Color(0xFFFF4B2B)
                                                  .withOpacity(0.25),
                                              width: 1,
                                            ),
                                          ),
                                          borderRadius: BorderRadius.only(
                                            bottomLeft: Radius.circular(14),
                                            bottomRight: Radius.circular(14),
                                          ),
                                        ),
                                        child: LayoutBuilder(
                                          builder: (context, constraints) {
                                            // Detectar pantallas pequeñas
                                            final isSmallScreen =
                                                constraints.maxWidth < 380;
                                            final isMediumScreen =
                                                constraints.maxWidth >= 380 &&
                                                    constraints.maxWidth < 480;

                                            return Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                // Ícono de advertencia con animación sutil
                                                Container(
                                                  padding: EdgeInsets.all(
                                                      isSmallScreen ? 7 : 8),
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      begin: Alignment.topLeft,
                                                      end:
                                                          Alignment.bottomRight,
                                                      colors: [
                                                        Color(0xFFFF4B2B)
                                                            .withOpacity(0.2),
                                                        Color(0xFFFF6B4A)
                                                            .withOpacity(0.15),
                                                      ],
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Color(0xFFFF4B2B)
                                                            .withOpacity(0.2),
                                                        blurRadius: 4,
                                                        offset: Offset(0, 2),
                                                      ),
                                                    ],
                                                  ),
                                                  child: Icon(
                                                    Icons
                                                        .report_problem_outlined,
                                                    color: Color(0xFFFF4B2B),
                                                    size:
                                                        isSmallScreen ? 15 : 17,
                                                  ),
                                                ),
                                                SizedBox(
                                                    width:
                                                        isSmallScreen ? 8 : 10),

                                                // Texto informativo (responsivo)
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      // Título
                                                      Text(
                                                        'Estado de Alerta Activo',
                                                        style: TextStyle(
                                                          fontSize:
                                                              isSmallScreen
                                                                  ? 11
                                                                  : 12,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color:
                                                              Color(0xFFFF4B2B),
                                                          letterSpacing: 0.3,
                                                        ),
                                                      ),
                                                      SizedBox(height: 4),

                                                      // Descripción adaptativa
                                                      Text(
                                                        isSmallScreen
                                                            ? 'Múltiples inasistencias detectadas. Notifique a su líder o coordinador. Asistencias bloqueadas hasta revisión.'
                                                            : isMediumScreen
                                                                ? 'Este discípulo presenta múltiples inasistencias consecutivas. Como Timoteo, debe notificar este caso a su líder o coordinador. No se pueden registrar nuevas asistencias hasta que la alerta sea revisada.'
                                                                : 'Este discípulo presenta múltiples inasistencias consecutivas. Como Timoteo, debe informar inmediatamente este caso a su líder o coordinador para su evaluación. El registro de nuevas asistencias está bloqueado hasta que la alerta sea revisada y resuelta.',
                                                        style: TextStyle(
                                                          fontSize: isSmallScreen
                                                              ? 9.5
                                                              : isMediumScreen
                                                                  ? 10
                                                                  : 10.5,
                                                          color:
                                                              Colors.grey[700],
                                                          height: 1.35,
                                                          letterSpacing: 0.1,
                                                        ),
                                                        maxLines: isSmallScreen
                                                            ? 3
                                                            : isMediumScreen
                                                                ? 3
                                                                : 2,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
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

  /// Muestra información resumida sin dirección ni barrio (eso va en "Ver Detalles")
  Widget _buildExpandedContent(
    BuildContext context,
    DocumentSnapshot registro,
    String nombre,
    String telefono,
    String estadoProceso,
    List asistencias,
  ) {
    return Container(
      // Padding reducido para hacer la tarjeta más compacta
      padding: EdgeInsets.all(14), // Reducido de 16 a 14
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(16), // Ajustado a 16
          bottomRight: Radius.circular(16), // Ajustado a 16
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sección de información de contacto
          _buildInfoSection(telefono),
          SizedBox(height: 10), // Reducido de 12 a 10

          // Sección de estado del proceso
          _buildEstadoSection(estadoProceso),
          SizedBox(height: 14), // Reducido de 16 a 14

          // Botones de acción
          _buildActionButtons(context, registro),

          // Historial de asistencias (si existen)
          if (asistencias.isNotEmpty) ...[
            SizedBox(height: 14), // Reducido de 16 a 14
            _buildAsistenciasSection(asistencias),
          ],

          // ===== DIRECCIÓN Y BARRIO ELIMINADOS =====
          // Esta información ahora solo aparece en el diálogo "Ver Detalles"
          // para mantener las tarjetas más compactas y limpias
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

  /// Construye la sección del estado del proceso del discípulo
  /// Muestra el estado actual de forma compacta
  Widget _buildEstadoSection(String estadoProceso) {
    return Container(
      padding: EdgeInsets.all(10), // Reducido de 12 a 10
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10), // Reducido de 12 a 10
        border: Border.all(color: Color(0xFF147B7C).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timeline,
                  color: Color(0xFF147B7C), size: 18), // Reducido de 20 a 18
              SizedBox(width: 8), // Reducido de 10 a 8
              Text(
                'Estado del proceso',
                style: TextStyle(
                  fontSize: 12, // Reducido de 13 a 12
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          SizedBox(height: 4), // Reducido de 6 a 4
          Text(
            estadoProceso,
            style: TextStyle(
              fontSize: 14, // Reducido de 15 a 14
              color: Colors.black87,
            ),
            maxLines: 2, // Limitar a 2 líneas para mantener compacto
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// Construye los botones de acción para cada discípulo
  /// Incluye: Actualizar Estado, Ver Detalles y Registrar Asistencia
  /// Los botones son responsivos y se adaptan al tamaño de pantalla
  Widget _buildActionButtons(BuildContext context, DocumentSnapshot registro) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isSmallScreen = constraints.maxWidth < 320;

        if (isSmallScreen) {
          // ===== LAYOUT VERTICAL PARA PANTALLAS PEQUEÑAS =====
          return Column(
            children: [
              // Botón: Actualizar Estado
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: Icon(Icons.edit_note,
                      color: Colors.white, size: 16), // Reducido
                  label: Text('Actualizar Estado',
                      style: TextStyle(fontSize: 13)), // Reducido
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF147B7C),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                        vertical: 10), // Reducido de 12 a 10
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(10), // Reducido de 12 a 10
                    ),
                    elevation: 2,
                  ),
                  onPressed: () => _actualizarEstado(context, registro),
                ),
              ),
              SizedBox(height: 6), // Reducido de 8 a 6

              // Botón: Ver Detalles
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: Icon(Icons.info_outline,
                      color: Colors.white, size: 16), // Reducido
                  label: Text('Ver Detalles',
                      style: TextStyle(fontSize: 13)), // Reducido
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFFFB74D),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 10), // Reducido
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10), // Reducido
                    ),
                    elevation: 2,
                  ),
                  onPressed: () => _mostrarDetallesDiscipulo(context, registro),
                ),
              ),
              SizedBox(height: 6), // Reducido

              // Botón: Registrar Asistencia (con verificación de bloqueo)
              SizedBox(
                width: double.infinity,
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
                        size: 16, // Reducido
                      ),
                      label: Text(
                        bloqueado
                            ? 'Bloqueado'
                            : (cargando
                                ? 'Verificando...'
                                : 'Registrar Asistencia'),
                        style: TextStyle(fontSize: 13), // Reducido
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: bloqueado
                            ? Colors.grey.shade400
                            : Color(0xFFFF4B2B),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 10), // Reducido
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10), // Reducido
                        ),
                        disabledBackgroundColor: Colors.grey.shade300,
                        disabledForegroundColor: Colors.grey.shade500,
                        elevation: 2,
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
        }

        // ===== LAYOUT HORIZONTAL PARA PANTALLAS NORMALES =====
        return Column(
          children: [
            Row(
              children: [
                // Botón: Actualizar Estado
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.edit_note,
                        color: Colors.white, size: 16), // Reducido
                    label: Text('Actualizar',
                        style: TextStyle(
                            fontSize: 13)), // Reducido y texto más corto
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF147B7C),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 10), // Reducido
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10), // Reducido
                      ),
                      elevation: 2,
                    ),
                    onPressed: () => _actualizarEstado(context, registro),
                  ),
                ),
                SizedBox(width: 6), // Reducido de 8 a 6

                // Botón: Ver Detalles
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.info_outline,
                        color: Colors.white, size: 16), // Reducido
                    label: Text('Detalles',
                        style: TextStyle(
                            fontSize: 13)), // Reducido y texto más corto
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFFFB74D),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 10), // Reducido
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10), // Reducido
                      ),
                      elevation: 2,
                    ),
                    onPressed: () =>
                        _mostrarDetallesDiscipulo(context, registro),
                  ),
                ),
              ],
            ),
            SizedBox(height: 6), // Reducido de 8 a 6

            // Botón: Registrar Asistencia (ancho completo)
            SizedBox(
              width: double.infinity,
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
                      size: 16, // Reducido
                    ),
                    label: Text(
                      bloqueado
                          ? 'Bloqueado'
                          : (cargando
                              ? 'Verificando...'
                              : 'Registrar Asistencia'),
                      style: TextStyle(fontSize: 13), // Reducido
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          bloqueado ? Colors.grey.shade400 : Color(0xFFFF4B2B),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 10), // Reducido
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10), // Reducido
                      ),
                      disabledBackgroundColor: Colors.grey.shade300,
                      disabledForegroundColor: Colors.grey.shade500,
                      elevation: 2,
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
                        // ✅ SIN Theme wrapper - esto causaba el error
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
                              // ✅ SIN Theme wrapper
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
                                        // ✅ SIN Theme wrapper
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
                                                  // ✅ SIN Scrollbar interno - esto también causaba conflicto
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
                                                    itemCount: asistenciasSemana
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
                                                      final nombreServicioRaw =
                                                          asistencia[
                                                                  'nombreServicio'] ??
                                                              'Servicio';
                                                      final nombreServicio =
                                                          _normalizarNombreServicio(
                                                              nombreServicioRaw);

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
                                                                  .circular(10),
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
                                                              offset:
                                                                  Offset(0, 1),
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
                                                                          FontWeight
                                                                              .bold,
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
                                                                          .withOpacity(
                                                                              0.9),
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w500,
                                                                    ),
                                                                  ),
                                                                  if (nombreServicio
                                                                              .length <=
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
                                                                          TextAlign
                                                                              .center,
                                                                      maxLines:
                                                                          1,
                                                                      overflow:
                                                                          TextOverflow
                                                                              .ellipsis,
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
    final nombreServicioRaw = asistencia['nombreServicio'] ?? 'Servicio';
    final nombreServicio =
        _normalizarNombreServicio(nombreServicioRaw); // ✅ Aplicar normalización

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

  void _mostrarDetallesDiscipulo(
      BuildContext context, DocumentSnapshot registro) {
    final data = registro.data() as Map<String, dynamic>?;

    if (data == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: No se pueden cargar los datos'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Función para obtener valor seguro
    String obtenerValorSeguro(String campo,
        {String defecto = 'No disponible'}) {
      try {
        final valor = data[campo];
        if (valor == null) return defecto;
        if (valor is String && valor.trim().isEmpty) return defecto;
        if (valor is Timestamp) {
          final fecha = valor.toDate();
          return '${fecha.day}/${fecha.month}/${fecha.year}';
        }
        return valor.toString();
      } catch (e) {
        return defecto;
      }
    }

    // Concatenar observaciones
    String obtenerObservaciones() {
      final obs1 = obtenerValorSeguro('observaciones', defecto: '');
      final obs2 = obtenerValorSeguro('observaciones2', defecto: '');

      if (obs1.isEmpty && obs2.isEmpty) return 'Sin observaciones';
      if (obs1.isEmpty) return obs2;
      if (obs2.isEmpty) return obs1;
      return '$obs1\n\n$obs2';
    }

    /// Calcula la edad actual y muestra la fecha exacta del próximo cumpleaños
    /// Incluye días restantes y fecha completa del cumpleaños
    String calcularEdadYCumpleanos() {
      try {
        final fechaNacimiento = data['fechaNacimiento'];
        if (fechaNacimiento == null) return 'No disponible';

        DateTime fecha;

        // Procesar diferentes formatos de fecha
        if (fechaNacimiento is Timestamp) {
          fecha = fechaNacimiento.toDate();
        } else if (fechaNacimiento is String) {
          if (fechaNacimiento.contains('Timestamp')) {
            final regex = RegExp(r'seconds=(\d+)');
            final match = regex.firstMatch(fechaNacimiento);
            if (match != null) {
              final seconds = int.tryParse(match.group(1) ?? '');
              if (seconds != null) {
                fecha = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
              } else {
                return 'No disponible';
              }
            } else {
              return 'No disponible';
            }
          } else {
            fecha = DateTime.parse(fechaNacimiento);
          }
        } else {
          return 'No disponible';
        }

        final hoy = DateTime.now();

        // Calcular edad actual
        int edad = hoy.year - fecha.year;
        if (hoy.month < fecha.month ||
            (hoy.month == fecha.month && hoy.day < fecha.day)) {
          edad--;
        }

        // Calcular próximo cumpleaños
        DateTime proximoCumpleanos = DateTime(hoy.year, fecha.month, fecha.day);
        if (proximoCumpleanos.isBefore(hoy) ||
            proximoCumpleanos.isAtSameMomentAs(hoy)) {
          proximoCumpleanos = DateTime(hoy.year + 1, fecha.month, fecha.day);
        }

        final diferencia = proximoCumpleanos.difference(hoy).inDays;

        // ===== FORMATO MEJORADO CON FECHA EXACTA =====
        // Muestra edad, fecha exacta del cumpleaños y días restantes
        String fechaCumpleanos = DateFormat('d \'de\' MMMM', 'es')
            .format(DateTime(2000, fecha.month, fecha.day));
        String proximoCumpleanosTexto;

        if (diferencia == 0) {
          proximoCumpleanosTexto = '¡Hoy es su cumpleaños! 🎉';
        } else if (diferencia == 1) {
          proximoCumpleanosTexto = 'Mañana ($fechaCumpleanos)';
        } else if (diferencia <= 7) {
          proximoCumpleanosTexto = 'En $diferencia días ($fechaCumpleanos)';
        } else if (diferencia <= 30) {
          proximoCumpleanosTexto = 'En $diferencia días ($fechaCumpleanos)';
        } else {
          final meses = (diferencia / 30).floor();
          proximoCumpleanosTexto = meses == 1
              ? 'En aproximadamente 1 mes ($fechaCumpleanos)'
              : 'En aproximadamente $meses meses ($fechaCumpleanos)';
        }

        // Retornar edad y fecha completa del cumpleaños
        return '$edad años • Cumple el $fechaCumpleanos • $proximoCumpleanosTexto';
      } catch (e) {
        return 'No disponible';
      }
    }

    final nombre = obtenerValorSeguro('nombre');
    final apellido = obtenerValorSeguro('apellido');
    final direccion = obtenerValorSeguro('direccion');
    final barrio = obtenerValorSeguro('barrio');
    final cumpleanos = calcularEdadYCumpleanos();
    final observaciones = obtenerObservaciones();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 8,
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Responsividad
              final screenWidth = MediaQuery.of(context).size.width;
              final isSmallScreen = screenWidth < 600;
              final dialogWidth = isSmallScreen
                  ? screenWidth * 0.95
                  : (screenWidth < 900 ? screenWidth * 0.7 : 600.0);

              return Container(
                width: dialogWidth,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Encabezado con gradiente
                    Container(
                      padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF147B7C),
                            Color(0xFF147B7C).withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF147B7C).withOpacity(0.3),
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
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              Icons.person_outline,
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
                                  'Información del Discípulo',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: isSmallScreen ? 16 : 18,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  '$nombre $apellido',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: isSmallScreen ? 13 : 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => Navigator.pop(dialogContext),
                              child: Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Icon(
                                  Icons.close_rounded,
                                  color: Colors.white,
                                  size: isSmallScreen ? 20 : 24,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Contenido scrolleable
                    Flexible(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Dirección
                            _buildDetalleCard(
                              context: context,
                              icono: Icons.home_outlined,
                              titulo: 'Dirección',
                              contenido: direccion,
                              color: Color(0xFF147B7C),
                              isSmallScreen: isSmallScreen,
                            ),
                            SizedBox(height: 12),

                            // Barrio
                            _buildDetalleCard(
                              context: context,
                              icono: Icons.location_city_outlined,
                              titulo: 'Barrio',
                              contenido: barrio,
                              color: Color(0xFFFF4B2B),
                              isSmallScreen: isSmallScreen,
                            ),
                            SizedBox(height: 12),

                            // Cumpleaños
                            _buildDetalleCard(
                              context: context,
                              icono: Icons.cake_outlined,
                              titulo: 'Cumpleaños',
                              contenido: cumpleanos,
                              color: Color(0xFFFFB74D),
                              isSmallScreen: isSmallScreen,
                            ),
                            SizedBox(height: 12),

                            // Observaciones (expandible)
                            _buildObservacionesCard(
                              context: context,
                              observaciones: observaciones,
                              isSmallScreen: isSmallScreen,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Footer con botón
                    Container(
                      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: Offset(0, -4),
                          ),
                        ],
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: Icon(Icons.check_circle_outline, size: 20),
                          label: Text(
                            'Cerrar',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF147B7C),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          onPressed: () => Navigator.pop(dialogContext),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  /// Widget para mostrar tarjetas de detalles con texto seleccionable
  /// Permite al usuario copiar la información directamente desde la UI
  Widget _buildDetalleCard({
    required BuildContext context,
    required IconData icono,
    required String titulo,
    required String contenido,
    required Color color,
    required bool isSmallScreen,
  }) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 14 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ícono decorativo
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icono,
              color: color,
              size: isSmallScreen ? 22 : 24,
            ),
          ),
          SizedBox(width: isSmallScreen ? 12 : 16),

          // Contenido con texto seleccionable
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título (no seleccionable)
                Text(
                  titulo,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 13 : 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 6),

                // ===== CONTENIDO SELECCIONABLE =====
                // Permite al usuario seleccionar y copiar el texto
                SelectableText(
                  contenido,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 15 : 16,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                  // Configuración del cursor y selección
                  cursorColor: color,
                  showCursor: true,
                  toolbarOptions: ToolbarOptions(
                    copy: true,
                    selectAll: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Widget para mostrar observaciones en formato expandible
  /// El texto es seleccionable para permitir copiar información
  Widget _buildObservacionesCard({
    required BuildContext context,
    required String observaciones,
    required bool isSmallScreen,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Color(0xFF147B7C).withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF147B7C).withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 14 : 16,
            vertical: 8,
          ),
          childrenPadding: EdgeInsets.fromLTRB(
            isSmallScreen ? 14 : 16,
            0,
            isSmallScreen ? 14 : 16,
            isSmallScreen ? 14 : 16,
          ),
          leading: Container(
            padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
            decoration: BoxDecoration(
              color: Color(0xFF147B7C).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.notes_outlined,
              color: Color(0xFF147B7C),
              size: isSmallScreen ? 22 : 24,
            ),
          ),
          title: Text(
            'Observaciones',
            style: TextStyle(
              fontSize: isSmallScreen ? 15 : 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF147B7C),
            ),
          ),
          subtitle: observaciones != 'Sin observaciones'
              ? Text(
                  'Toca para ver más detalles',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 12 : 13,
                    color: Colors.grey[600],
                  ),
                )
              : null,
          children: [
            Container(
              padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              width: double.infinity,

              // ===== TEXTO SELECCIONABLE =====
              // Permite copiar las observaciones del discípulo
              child: SelectableText(
                observaciones,
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 15,
                  color: Colors.black87,
                  height: 1.5,
                ),
                // Configuración de selección
                cursorColor: Color(0xFF147B7C),
                showCursor: true,
                toolbarOptions: ToolbarOptions(
                  copy: true,
                  selectAll: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
