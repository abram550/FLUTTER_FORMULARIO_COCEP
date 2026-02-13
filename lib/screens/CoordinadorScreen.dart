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
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:formulario_app/services/auth_service.dart';

// Paquetes externos
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:url_launcher/url_launcher.dart';

// Proyecto
import '../utils/email_service.dart';

// Locales
import 'TimoteosScreen.dart';

// Color scheme based on the COCEP logo
const kPrimaryColor = Color(0xFF1B8C8C); // Turquesa
const kSecondaryColor = Color(0xFFFF4D2E); // Naranja/rojo
const kAccentColor = Color(0xFFFFB800); // Amarillo
const kBackgroundColor = Color(0xFFF5F7FA); // Gris muy claro para el fondo
const kTextLightColor = Color(0xFFF5F7FA); // For text on dark backgrounds
const kTextDarkColor = Color(0xFF2D3748); // For text on light backgrounds
const kCardColor = Colors.white; // Color for cards

class CoordinadorScreen extends StatefulWidget {
  final String coordinadorId;
  final String coordinadorNombre;

  const CoordinadorScreen({
    Key? key,
    required this.coordinadorId,
    required this.coordinadorNombre,
  }) : super(key: key);

  @override
  State<CoordinadorScreen> createState() => _CoordinadorScreenState();
}

class _CoordinadorScreenState extends State<CoordinadorScreen>
    with SingleTickerProviderStateMixin {
  // Variables para el manejo de sesión
  Timer? _inactivityTimer;
  static const Duration _inactivityDuration = Duration(minutes: 15);

  // Controller para las pestañas
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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

  Future<Map<String, dynamic>> obtenerDatosTribu() async {
    var coordinadorSnapshot = await FirebaseFirestore.instance
        .collection('coordinadores')
        .doc(widget.coordinadorId)
        .get();

    if (!coordinadorSnapshot.exists)
      return {'tribuId': '', 'categoriaTribu': ''};

    var tribuId = coordinadorSnapshot.data()?['tribuId'] ?? '';

    if (tribuId.isEmpty) return {'tribuId': '', 'categoriaTribu': ''};

    var tribuSnapshot = await FirebaseFirestore.instance
        .collection('tribus')
        .doc(tribuId)
        .get();

    var categoriaTribu = tribuSnapshot.data()?['categoriaTribu'] ?? '';

    return {'tribuId': tribuId, 'categoriaTribu': categoriaTribu};
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: obtenerDatosTribu(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Scaffold(
            backgroundColor: kBackgroundColor,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TweenAnimationBuilder(
                    tween: Tween<double>(begin: 0, end: 1),
                    duration: Duration(seconds: 1),
                    builder: (context, double value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: kPrimaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.local_fire_department,
                            color: kAccentColor,
                            size: 70,
                          ),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 24),
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(kPrimaryColor),
                    strokeWidth: 3,
                  ),
                  SizedBox(height: 16),
                  Text(
                    "Cargando información...",
                    style: TextStyle(
                      color: kPrimaryColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        String tribuId = snapshot.data!['tribuId'];
        String categoriaTribu = snapshot.data!['categoriaTribu'];

        return DefaultTabController(
          length: 4,
          child: Scaffold(
            backgroundColor: kBackgroundColor,
            appBar: AppBar(
              elevation: 0,
              backgroundColor: kPrimaryColor,
              automaticallyImplyLeading: true,
              iconTheme: IconThemeData(color: Colors.white),
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
              toolbarHeight: MediaQuery.of(context).size.height * 0.09,
              title: LayoutBuilder(
                builder: (context, constraints) {
                  final screenWidth = MediaQuery.of(context).size.width;
                  final isVerySmallScreen = screenWidth < 360;
                  final isSmallScreen = screenWidth < 400;
                  final isMediumScreen =
                      screenWidth >= 400 && screenWidth < 600;

                  // Analizar nombre del coordinador
                  final coordinadorNombre = widget.coordinadorNombre;
                  final palabras = coordinadorNombre.split(' ');
                  final nombreLargo = coordinadorNombre.length > 18;

                  // Determinar estructura de líneas basado en longitud y pantalla
                  final usarDosLineas = (nombreLargo && isSmallScreen) ||
                      (coordinadorNombre.length > 24 && isMediumScreen);
                  final usarTresLineas =
                      coordinadorNombre.length > 25 && isVerySmallScreen;

                  return Row(
                    children: [
                      // Logo COCEP con animación Hero
                      Hero(
                        tag: 'coordinador_logo_${widget.coordinadorId}',
                        child: Container(
                          padding: EdgeInsets.all(isVerySmallScreen ? 3 : 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Container(
                            height: isVerySmallScreen
                                ? 34
                                : (isSmallScreen ? 36 : 36),
                            width: isVerySmallScreen
                                ? 34
                                : (isSmallScreen ? 36 : 36),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              border: Border.all(
                                color: kPrimaryColor.withOpacity(0.1),
                                width: 1,
                              ),
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/Cocep_.png',
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    decoration: BoxDecoration(
                                      color: kAccentColor.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.local_fire_department,
                                      color: kPrimaryColor,
                                      size: isVerySmallScreen ? 18 : 20,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: isVerySmallScreen ? 8 : 12),

                      // Nombre del coordinador con diseño adaptativo
                      Expanded(
                        child: usarTresLineas
                            ? _buildCoordinadorTresLineas(
                                palabras, isVerySmallScreen)
                            : usarDosLineas
                                ? _buildCoordinadorDosLineas(
                                    coordinadorNombre, palabras, isSmallScreen)
                                : _buildCoordinadorUnaLinea(coordinadorNombre,
                                    isSmallScreen, isMediumScreen),
                      ),

                      SizedBox(width: isVerySmallScreen ? 4 : 8),

                      // Botón de salir mejorado
                      Container(
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
                            color: Colors.white.withOpacity(0.5),
                            width: 1.5,
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
                            borderRadius: BorderRadius.circular(12),
                            onTap: _confirmarCerrarSesion,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isVerySmallScreen ? 10 : 12,
                                vertical: isVerySmallScreen ? 8 : 8,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.logout_rounded,
                                    color: Colors.white,
                                    size: isVerySmallScreen ? 16 : 18,
                                  ),
                                  SizedBox(width: 4),
                                  SizedBox(
                                    width: isVerySmallScreen ? 55 : null,
                                    child: Text(
                                      'Cerrar\nsesión',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: isVerySmallScreen ? 11 : 12,
                                        fontWeight: FontWeight.w600,
                                        height: 1.1,
                                        shadows: [
                                          Shadow(
                                            offset: Offset(0, 1),
                                            blurRadius: 2,
                                            color:
                                                Colors.black.withOpacity(0.3),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              bottom: PreferredSize(
                preferredSize: Size.fromHeight(kToolbarHeight + 15),
                child: Container(
                  decoration: BoxDecoration(
                    color: kPrimaryColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final screenWidth = MediaQuery.of(context).size.width;
                      final isVerySmallScreen = screenWidth < 360;
                      final isSmallScreen = screenWidth < 500;

                      return TabBar(
                        controller: _tabController,
                        indicatorWeight: 3,
                        indicator: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: kAccentColor,
                              width: 3,
                            ),
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              kAccentColor.withOpacity(0.1),
                            ],
                          ),
                        ),
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.white60,
                        isScrollable: isSmallScreen,
                        labelPadding: EdgeInsets.symmetric(
                          horizontal: isVerySmallScreen ? 8 : 12,
                        ),
                        labelStyle: TextStyle(
                          fontSize: isVerySmallScreen ? 12 : 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                        tabs: [
                          _buildCoordinadorTab(
                            Icons.people,
                            'Timoteos',
                            isVerySmallScreen,
                          ),
                          _buildCoordinadorTab(
                            Icons.assignment_ind,
                            'Asignados',
                            isVerySmallScreen,
                          ),
                          _buildCoordinadorTab(
                            Icons.warning_amber_rounded,
                            'Alertas',
                            isVerySmallScreen,
                          ),
                          _buildCoordinadorTab(
                            Icons.calendar_today,
                            'Asistencia',
                            isVerySmallScreen,
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
            body: TabBarView(
              controller: _tabController,
              children: [
                CustomTabContent(
                  child: TimoteosTab(coordinadorId: widget.coordinadorId),
                  icon: Icons.people,
                  title: 'Timoteos',
                  description: 'Gestiona los timoteos a tu cargo',
                ),
                PersonasAsignadasTab(
                  coordinadorId: widget.coordinadorId,
                ),
                CustomTabContent(
                  child: AlertasTab(coordinadorId: widget.coordinadorId),
                  icon: Icons.warning_amber_rounded,
                  title: 'Alertas Pendientes',
                  description: 'Revisa las alertas que requieren tu atención',
                ),
                CustomTabContent(
                  child: AsistenciasCoordinadorTab(
                    tribuId: tribuId,
                    categoriaTribu: categoriaTribu,
                    coordinadorId: widget.coordinadorId,
                  ),
                  icon: Icons.calendar_today,
                  title: 'Registro de Asistencia',
                  description: 'Gestiona la asistencia de tu grupo',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCoordinadorUnaLinea(
      String coordinadorNombre, bool isSmallScreen, bool isMediumScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Coordinador',
          style: TextStyle(
            fontSize: isSmallScreen ? 11 : 12,
            color: Colors.white.withOpacity(0.85),
            fontWeight: FontWeight.w500,
            height: 1.1,
          ),
        ),
        SizedBox(height: 2),
        Text(
          coordinadorNombre,
          style: TextStyle(
            fontSize: isSmallScreen ? 16 : (isMediumScreen ? 18 : 18),
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
            color: Colors.white,
            height: 1.2,
            shadows: [
              Shadow(
                offset: Offset(0, 1),
                blurRadius: 3,
                color: Colors.black.withOpacity(0.2),
              ),
            ],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildCoordinadorDosLineas(
      String coordinadorNombre, List<String> palabras, bool isSmallScreen) {
    // División inteligente: nombre(s) en primera línea, apellido(s) en segunda
    String primeraLinea, segundaLinea;

    if (palabras.length >= 3) {
      // Si tiene 3+ palabras, dividir aproximadamente a la mitad
      final mitad = (palabras.length / 2).ceil();
      primeraLinea = palabras.sublist(0, mitad).join(' ');
      segundaLinea = palabras.sublist(mitad).join(' ');
    } else if (palabras.length == 2) {
      // Si tiene 2 palabras, una en cada línea
      primeraLinea = palabras[0];
      segundaLinea = palabras[1];
    } else {
      // Si tiene 1 palabra, mostrar en segunda línea
      primeraLinea = 'Coordinador';
      segundaLinea = palabras[0];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          primeraLinea,
          style: TextStyle(
            fontSize: isSmallScreen ? 13 : 15,
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.95),
            height: 1.1,
            letterSpacing: 0.2,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          segundaLinea,
          style: TextStyle(
            fontSize: isSmallScreen ? 15 : 17,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            height: 1.1,
            letterSpacing: 0.3,
            shadows: [
              Shadow(
                offset: Offset(0, 1),
                blurRadius: 3,
                color: Colors.black.withOpacity(0.2),
              ),
            ],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildCoordinadorTresLineas(
      List<String> palabras, bool isVerySmallScreen) {
    // Para pantallas muy pequeñas, dividir en 3 líneas
    String primeraLinea = 'Coordinador';
    String segundaLinea = '';
    String terceraLinea = '';

    if (palabras.length >= 2) {
      segundaLinea = palabras[0];
      terceraLinea = palabras.sublist(1).join(' ');
    } else if (palabras.length == 1) {
      segundaLinea = palabras[0];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          primeraLinea,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: Colors.white.withOpacity(0.8),
            height: 1.0,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (segundaLinea.isNotEmpty)
          Text(
            segundaLinea,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.95),
              height: 1.0,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        if (terceraLinea.isNotEmpty)
          Text(
            terceraLinea,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.0,
              shadows: [
                Shadow(
                  offset: Offset(0, 1),
                  blurRadius: 2,
                  color: Colors.black.withOpacity(0.2),
                ),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }

  Widget _buildCoordinadorTab(
      IconData icon, String text, bool isVerySmallScreen) {
    return Tab(
      icon: Icon(
        icon,
        size: isVerySmallScreen ? 20 : 24,
      ),
      text: text,
      iconMargin: EdgeInsets.only(bottom: 4),
    );
  }

  Widget buildActionSheet(
      BuildContext context, VoidCallback onRegistrarNuevoJoven) {
    return Container(
      padding: EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Text(
            'Registrar Asistencia',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: kTextDarkColor,
            ),
          ),
          SizedBox(height: 24),
          _buildActionButton(
            context,
            'Registrar Asistencia',
            Icons.check_circle_outline,
            kSecondaryColor,
            () {
              _resetInactivityTimer();
              Navigator.pop(context);
              onRegistrarNuevoJoven();
            },
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: kTextDarkColor,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: color,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

// Wrapper widget to add consistent header to each tab
class CustomTabContent extends StatelessWidget {
  final Widget child;
  final IconData icon;
  final String title;
  final String description;

  const CustomTabContent({
    Key? key,
    required this.child,
    required this.icon,
    required this.title,
    required this.description,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kPrimaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: kPrimaryColor,
                  size: 24,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: kTextDarkColor,
                      ),
                    ),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Divider(),
        Expanded(child: child),
      ],
    );
  }
}

class AsistenciasCoordinadorTab extends StatefulWidget {
  final String tribuId;
  final String categoriaTribu;
  final String coordinadorId;

  const AsistenciasCoordinadorTab({
    Key? key,
    required this.tribuId,
    required this.categoriaTribu,
    required this.coordinadorId,
  }) : super(key: key);

  @override
  _AsistenciasCoordinadorTabState createState() =>
      _AsistenciasCoordinadorTabState();
}

class _AsistenciasCoordinadorTabState extends State<AsistenciasCoordinadorTab> {
  DateTime _selectedDate = DateTime.now();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool _isProcessingMassive = false;
  DateTime _massiveSelectedDate = DateTime.now();
  Map<String, bool> _selectedAttendances = {};
  List<DocumentSnapshot> _filteredRegistros = [];
  TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  String obtenerNombreServicio(String categoriaTribu, DateTime fecha) {
    Intl.defaultLocale = 'es';
    String diaSemana = DateFormat('EEEE', 'es').format(fecha).toLowerCase();

    final Map<String, Map<String, String>> servicios = {
      "Ministerio de Damas": {
        "martes": "Servicio de Damas",
        "viernes": "Viernes de Poder",
        "domingo": "Servicio Familiar"
      },
      "Ministerio de Caballeros": {
        "jueves": "Servicio de Caballeros",
        "viernes": "Viernes de Poder",
        "sábado": "Servicio de Caballeros",
        "domingo": "Servicio Familiar"
      },
      "Ministerio Juvenil": {
        "viernes": "Viernes de Poder",
        "sábado": "Impacto Juvenil",
        "domingo": "Servicio Familiar"
      }
    };

    if (servicios.containsKey(categoriaTribu) &&
        servicios[categoriaTribu]!.containsKey(diaSemana)) {
      return servicios[categoriaTribu]![diaSemana]!;
    }

    return "Servicio Especial";
  }

  Future<bool> _tieneBloqueoPorFaltas(
      String registroId, int faltasActuales) async {
    try {
      if (faltasActuales < 3) return false;

      final qs = await FirebaseFirestore.instance
          .collection('alertas')
          .where('registroId', isEqualTo: registroId)
          .where('tipo', isEqualTo: 'faltasConsecutivas')
          .where('procesada', isEqualTo: false)
          .limit(1)
          .get();

      if (qs.docs.isEmpty) {
        final qs2 = await FirebaseFirestore.instance
            .collection('alertas')
            .where('registroId', isEqualTo: registroId)
            .where('tipo', isEqualTo: 'faltasConsecutivas')
            .where('estado', whereIn: ['pendiente', 'en_revision'])
            .limit(1)
            .get();
        return qs2.docs.isNotEmpty;
      }

      return true;
    } catch (e) {
      print('Error verificando bloqueo por faltas: $e');
      return false;
    }
  }

  List<DocumentSnapshot> _filtrarRegistros(List<DocumentSnapshot> docs) {
    try {
      var filtered = docs.where((doc) {
        try {
          final data = doc.data();
          if (data is Map<String, dynamic>) {
            final categoria = data['categoria']?.toString() ?? '';
            final categoriaMatch = categoria == widget.categoriaTribu ||
                widget.categoriaTribu.isEmpty;

            if (!categoriaMatch) return false;

            if (_searchQuery.isEmpty) return true;

            final nombre = data['nombre']?.toString().toLowerCase() ?? '';
            final apellido = data['apellido']?.toString().toLowerCase() ?? '';
            final nombreCompleto = '$nombre $apellido';

            return nombreCompleto.contains(_searchQuery.toLowerCase());
          }
          return false;
        } catch (e) {
          print('Error filtrando documento individual: $e');
          return false;
        }
      }).toList();

      // Ordenar alfabéticamente (A-Z)
      filtered.sort((a, b) {
        try {
          final dataA = a.data() as Map<String, dynamic>?;
          final dataB = b.data() as Map<String, dynamic>?;

          final nombreA =
              '${dataA?['nombre'] ?? ''} ${dataA?['apellido'] ?? ''}'.trim();
          final nombreB =
              '${dataB?['nombre'] ?? ''} ${dataB?['apellido'] ?? ''}'.trim();

          return nombreA.compareTo(nombreB);
        } catch (e) {
          return 0;
        }
      });

      return filtered;
    } catch (e) {
      print('Error en _filtrarRegistros: $e');
      return [];
    }
  }

  Future<void> _procesarAsistenciaMasiva() async {
    if (!mounted || _isProcessingMassive || _selectedAttendances.isEmpty)
      return;

    setState(() {
      _isProcessingMassive = true;
    });

    int procesados = 0;
    int errores = 0;
    int yaRegistrados = 0;
    int totalProcesos = _selectedAttendances.length;

    bool dialogMounted = true;
    late StateSetter dialogSetState;

    try {
      final startOfDay = DateTime(_massiveSelectedDate.year,
          _massiveSelectedDate.month, _massiveSelectedDate.day);
      final endOfDay = startOfDay.add(Duration(days: 1));

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              dialogSetState = setDialogState;
              return WillPopScope(
                onWillPop: () async => false,
                child: AlertDialog(
                  title: Row(
                    children: [
                      Icon(Icons.checklist, color: Color(0xFF147B7C)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Procesando Lista de Asistencia',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ],
                  ),
                  content: Container(
                    constraints: BoxConstraints(minWidth: 300),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Color(0xFF147B7C)),
                        ),
                        SizedBox(height: 20),
                        Text(
                          'Procesando: ${procesados + errores + yaRegistrados} de $totalProcesos',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 12),
                        if (procesados > 0)
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle,
                                    color: Colors.green, size: 16),
                                SizedBox(width: 4),
                                Text('Registrados: $procesados',
                                    style: TextStyle(color: Colors.green)),
                              ],
                            ),
                          ),
                        if (yaRegistrados > 0)
                          Container(
                            margin: EdgeInsets.only(top: 4),
                            padding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.warning,
                                    color: Colors.orange, size: 16),
                                SizedBox(width: 4),
                                Text('Ya existían: $yaRegistrados',
                                    style: TextStyle(color: Colors.orange)),
                              ],
                            ),
                          ),
                        if (errores > 0)
                          Container(
                            margin: EdgeInsets.only(top: 4),
                            padding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.error, color: Colors.red, size: 16),
                                SizedBox(width: 4),
                                Text('Errores: $errores',
                                    style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      );

      void actualizarDialogo() {
        if (dialogMounted) {
          try {
            dialogSetState(() {});
          } catch (e) {
            print('Error actualizando diálogo: $e');
            dialogMounted = false;
          }
        }
      }

      List<MapEntry<String, bool>> entries =
          _selectedAttendances.entries.toList();

      for (int i = 0; i < entries.length; i++) {
        if (!mounted || !dialogMounted) break;

        final entry = entries[i];

        try {
          late DocumentSnapshot registro;
          try {
            registro = _filteredRegistros.firstWhere(
              (doc) => doc.id == entry.key,
            );
          } catch (e) {
            print('Registro no encontrado: ${entry.key}');
            errores++;
            actualizarDialogo();
            continue;
          }

          final data = registro.data() as Map<String, dynamic>?;
          if (data == null) {
            errores++;
            actualizarDialogo();
            continue;
          }

          final int faltasActuales =
              (data['faltasConsecutivas'] as num?)?.toInt() ?? 0;
          bool bloqueo = false;
          if (faltasActuales >= 3) {
            bloqueo = await _tieneBloqueoPorFaltas(registro.id, faltasActuales);
          }
          if (bloqueo) {
            yaRegistrados++;
            actualizarDialogo();
            continue;
          }

          try {
            final yaRegistrada = await FirebaseFirestore.instance
                .collection('asistencias')
                .where('jovenId', isEqualTo: registro.id)
                .where('fecha',
                    isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
                .where('fecha',
                    isLessThanOrEqualTo: Timestamp.fromDate(DateTime(
                        startOfDay.year,
                        startOfDay.month,
                        startOfDay.day,
                        23,
                        59,
                        59,
                        999)))
                .limit(1)
                .get()
                .timeout(
              Duration(seconds: 5),
              onTimeout: () {
                print('⚠️ Timeout verificando duplicado para: ${registro.id}');
                errores++;
                return Future.error('Timeout');
              },
            );

            if (yaRegistrada.docs.isNotEmpty) {
              yaRegistrados++;
              actualizarDialogo();
              continue;
            }
          } on TimeoutException catch (e) {
            print('⏱️ Timeout en validación: $e');
            errores++;
            actualizarDialogo();
            continue;
          } catch (e) {
            print('❌ Error verificando duplicado en modo masivo: $e');
            errores++;
            actualizarDialogo();
            continue;
          }

          final nombre = data['nombre']?.toString() ?? '';
          final apellido = data['apellido']?.toString() ?? '';
          final tribuId = data['tribuId']?.toString() ?? widget.tribuId;
          String categoriaTribu = data['categoria']?.toString() ??
              data['ministerioAsignado']?.toString() ??
              widget.categoriaTribu;

          if (tribuId.isNotEmpty) {
            try {
              final tribuDoc = await FirebaseFirestore.instance
                  .collection('tribus')
                  .doc(tribuId)
                  .get();

              if (tribuDoc.exists && tribuDoc.data() != null) {
                final tribuData = tribuDoc.data() as Map<String, dynamic>;
                categoriaTribu =
                    tribuData['categoria']?.toString() ?? categoriaTribu;
              }
            } catch (e) {
              print('Error al obtener tribu: $e');
            }
          }

          final String nombreServicio =
              obtenerNombreServicio(categoriaTribu, _massiveSelectedDate);
          final bool asistio = entry.value;

          await FirebaseFirestore.instance.collection('asistencias').add({
            'jovenId': registro.id,
            'nombre': nombre,
            'apellido': apellido,
            'nombreCompleto': '$nombre $apellido',
            'tribuId': tribuId,
            'categoriaTribu': categoriaTribu,
            'coordinadorId': widget.coordinadorId,
            'fecha': Timestamp.fromDate(_massiveSelectedDate),
            'nombreServicio': nombreServicio,
            'asistio': asistio,
            'diaSemana': DateFormat('EEEE', 'es').format(_massiveSelectedDate),
          });

          final int faltasAnteriores =
              (data['faltasConsecutivas'] as num?)?.toInt() ?? 0;
          final int nuevasFaltas = asistio ? 0 : faltasAnteriores + 1;

          await registro.reference.update({
            'ultimaAsistencia': Timestamp.fromDate(_massiveSelectedDate),
            'faltasConsecutivas': nuevasFaltas,
          });

          if (!asistio && nuevasFaltas >= 4) {
            String nombreTimoteo = 'No disponible';
            String? timoteoId = data['timoteoAsignado'];

            if (timoteoId != null && timoteoId.isNotEmpty) {
              try {
                final timoteoDoc = await FirebaseFirestore.instance
                    .collection('timoteos')
                    .doc(timoteoId)
                    .get();

                if (timoteoDoc.exists) {
                  final tData = timoteoDoc.data();
                  final nombreT = tData?['nombre'] ?? '';
                  final apellidoT = tData?['apellido'] ?? '';
                  nombreTimoteo = '$nombreT $apellidoT'.trim();
                }
              } catch (e) {
                print('Error obteniendo timoteo: $e');
              }
            }

            final alertasExistente = await FirebaseFirestore.instance
                .collection('alertas')
                .where('registroId', isEqualTo: registro.id)
                .where('tipo', isEqualTo: 'faltasConsecutivas')
                .where('procesada', isEqualTo: false)
                .limit(1)
                .get();

            if (alertasExistente.docs.isEmpty) {
              await FirebaseFirestore.instance.collection('alertas').add({
                'tipo': 'faltasConsecutivas',
                'registroId': registro.id,
                'coordinadorId': widget.coordinadorId,
                'timoteoId': timoteoId ?? 'No asignado',
                'nombreJoven': '$nombre $apellido',
                'nombreTimoteo': nombreTimoteo,
                'cantidadFaltas': nuevasFaltas,
                'fecha': Timestamp.now(),
                'estado': 'pendiente',
                'procesada': false,
                'visible': false,
              });
            }
          }

          procesados++;
          actualizarDialogo();
        } catch (e) {
          print('Error procesando asistencia individual: $e');
          errores++;
          actualizarDialogo();
        }

        if (i % 3 == 0) {
          await Future.delayed(Duration(milliseconds: 50));
        }
      }
    } catch (e) {
      print('Error crítico en procesamiento masivo: $e');
      errores++;
    } finally {
      dialogMounted = false;

      if (mounted) {
        try {
          Navigator.of(context, rootNavigator: true).pop();
        } catch (e) {
          print('Error cerrando diálogo: $e');
        }

        await Future.delayed(Duration(milliseconds: 100));

        if (mounted) {
          setState(() {
            _selectedAttendances.clear();
            _isProcessingMassive = false;
          });

          String mensaje;
          Color color;

          if (errores == 0 && yaRegistrados == 0) {
            mensaje =
                '✓ ¡Perfecto! Se registraron $procesados asistencias correctamente';
            color = Color(0xFF147B7C);
          } else if (errores == 0) {
            mensaje =
                '✓ Completado: $procesados registrados, $yaRegistrados ya existían';
            color = Colors.orange;
          } else {
            mensaje =
                'Completado con advertencias: $procesados registrados, $yaRegistrados ya existían, $errores errores';
            color = Colors.red;
          }

          try {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(mensaje),
                backgroundColor: color,
                duration: Duration(seconds: 5),
                action: SnackBarAction(
                  label: 'OK',
                  textColor: Colors.white,
                  onPressed: () {},
                ),
              ),
            );
          } catch (e) {
            print('Error mostrando SnackBar: $e');
          }
        }
      }
    }
  }

  Widget _buildSearchBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        decoration: InputDecoration(
          hintText: 'Buscar por nombre...',
          prefixIcon: Icon(Icons.search, color: Color(0xFF147B7C)),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide(color: Color(0xFF147B7C)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide(color: Color(0xFF147B7C), width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      key: _scaffoldKey,
      body: Column(
        children: [
          // Barra de búsqueda
          _buildSearchBar(),

          // Contenido principal con scroll
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('registros')
                  .where('coordinadorAsignado', isEqualTo: widget.coordinadorId)
                  .snapshots()
                  .handleError((error) {
                print('Error en stream: $error');
                return Stream.empty();
              }),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.red),
                        SizedBox(height: 16),
                        Text(
                          'Error al cargar datos',
                          style: TextStyle(fontSize: 18, color: Colors.red),
                        ),
                        SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            if (mounted) {
                              setState(() {});
                            }
                          },
                          child: Text('Reintentar'),
                        ),
                      ],
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Color(0xFF147B7C)),
                        ),
                        SizedBox(height: 16),
                        Text('Cargando discípulos...'),
                      ],
                    ),
                  );
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 72,
                          color: Color(0xFF147B7C).withOpacity(0.5),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No hay discípulos asignados',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Los discípulos deben ser asignados desde "Personas Asignadas"',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                _filteredRegistros = _filtrarRegistros(docs);

                if (_filteredRegistros.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _searchQuery.isNotEmpty
                              ? Icons.search_off
                              : Icons.people_outline,
                          size: 72,
                          color: Color(0xFF147B7C).withOpacity(0.5),
                        ),
                        SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'No se encontraron resultados para "$_searchQuery"'
                              : 'No hay discípulos para esta categoría',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (_searchQuery.isNotEmpty) ...[
                          SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                              });
                            },
                            child: Text('Limpiar búsqueda'),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return SingleChildScrollView(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 16,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                  ),
                  physics: AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Selector de fecha y controles
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFF147B7C).withOpacity(0.1),
                              Color(0xFF147B7C).withOpacity(0.05)
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: Color(0xFF147B7C), width: 2),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Color(0xFF147B7C),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(Icons.checklist,
                                      color: Colors.white, size: 24),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Lista de Asistencia Grupal',
                                        style: TextStyle(
                                          fontSize: isSmallScreen ? 16 : 18,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF147B7C),
                                        ),
                                      ),
                                      Text(
                                        'Toma asistencia de múltiples personas',
                                        style: TextStyle(
                                          fontSize: isSmallScreen ? 12 : 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            Divider(height: 24),
                            // Selector de fecha
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: Color(0xFF147B7C).withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.event, color: Color(0xFF147B7C)),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Fecha del servicio:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF147B7C),
                                        fontSize: isSmallScreen ? 13 : 14,
                                      ),
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    icon: Icon(Icons.calendar_today, size: 18),
                                    label: Text(DateFormat('dd/MM/yyyy')
                                        .format(_massiveSelectedDate)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Color(0xFF147B7C),
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 8),
                                    ),
                                    onPressed: _isProcessingMassive
                                        ? null
                                        : () async {
                                            final DateTime? pickedDate =
                                                await showDatePicker(
                                              context: context,
                                              initialDate: _massiveSelectedDate,
                                              firstDate: DateTime.now()
                                                  .subtract(Duration(days: 30)),
                                              lastDate: DateTime.now(),
                                            );

                                            if (pickedDate != null &&
                                                pickedDate !=
                                                    _massiveSelectedDate) {
                                              setState(() {
                                                _massiveSelectedDate =
                                                    pickedDate;
                                                _selectedAttendances.clear();
                                              });
                                            }
                                          },
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 16),
                            // Botones rápidos
                            Text(
                              'Acciones rápidas:',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF147B7C),
                                fontSize: isSmallScreen ? 14 : 16,
                              ),
                            ),
                            SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              alignment: WrapAlignment.center,
                              children: [
                                ElevatedButton.icon(
                                  icon: Icon(Icons.check_circle, size: 18),
                                  label: Text('Todos Presentes'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                  ),
                                  onPressed: _isProcessingMassive
                                      ? null
                                      : () {
                                          setState(() {
                                            for (var registro
                                                in _filteredRegistros) {
                                              _selectedAttendances[
                                                  registro.id] = true;
                                            }
                                          });
                                        },
                                ),
                                ElevatedButton.icon(
                                  icon: Icon(Icons.cancel, size: 18),
                                  label: Text('Todos Ausentes'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                  ),
                                  onPressed: _isProcessingMassive
                                      ? null
                                      : () {
                                          setState(() {
                                            for (var registro
                                                in _filteredRegistros) {
                                              _selectedAttendances[
                                                  registro.id] = false;
                                            }
                                          });
                                        },
                                ),
                                OutlinedButton.icon(
                                  icon: Icon(Icons.clear_all, size: 18),
                                  label: Text('Limpiar'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.grey[700],
                                    side: BorderSide(color: Colors.grey),
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                  ),
                                  onPressed: _isProcessingMassive
                                      ? null
                                      : () {
                                          setState(() {
                                            _selectedAttendances.clear();
                                          });
                                        },
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            // Contador y botón de guardar
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Color(0xFF147B7C).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.people,
                                          color: Color(0xFF147B7C)),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Personas seleccionadas: ${_selectedAttendances.length}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF147B7C),
                                                fontSize:
                                                    isSmallScreen ? 13 : 14,
                                              ),
                                            ),
                                            if (_selectedAttendances
                                                .isNotEmpty) ...[
                                              SizedBox(height: 4),
                                              Text(
                                                'Presentes: ${_selectedAttendances.values.where((v) => v == true).length} | '
                                                'Ausentes: ${_selectedAttendances.values.where((v) => v == false).length}',
                                                style: TextStyle(
                                                  fontSize:
                                                      isSmallScreen ? 11 : 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      icon: _isProcessingMassive
                                          ? SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                        Color>(Colors.white),
                                              ),
                                            )
                                          : Icon(Icons.save_alt, size: 18),
                                      label: Text(_isProcessingMassive
                                          ? 'Guardando...'
                                          : 'Guardar Lista de Asistencia'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Color(0xFF147B7C),
                                        foregroundColor: Colors.white,
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 20, vertical: 16),
                                      ),
                                      onPressed: (_isProcessingMassive ||
                                              _selectedAttendances.isEmpty)
                                          ? null
                                          : _procesarAsistenciaMasiva,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 16),

                      // Lista de discípulos (ordenada alfabéticamente)
                      ...List.generate(_filteredRegistros.length, (index) {
                        try {
                          final registro = _filteredRegistros[index];
                          final data = registro.data();

                          if (data is! Map<String, dynamic>) {
                            return SizedBox.shrink();
                          }

                          final dataMap = data as Map<String, dynamic>;
                          final nombre = dataMap['nombre']?.toString() ?? '';
                          final apellido =
                              dataMap['apellido']?.toString() ?? '';
                          final faltas = (dataMap['faltasConsecutivas'] as num?)
                                  ?.toInt() ??
                              0;

                          if (nombre.isEmpty && apellido.isEmpty) {
                            return SizedBox.shrink();
                          }

                          Color cardColor = Colors.white;
                          if (faltas >= 3) {
                            cardColor = Color(0xFFFF4B2B).withOpacity(0.1);
                          }

                          final isSelected =
                              _selectedAttendances.containsKey(registro.id);
                          final attendanceValue =
                              _selectedAttendances[registro.id];

                          return FutureBuilder<bool>(
                            future: _tieneBloqueoPorFaltas(registro.id, faltas),
                            builder: (context, snap) {
                              final bool bloqueado = snap.data == true;

                              return Container(
                                margin: EdgeInsets.only(bottom: 8),
                                child: Card(
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  color: isSelected
                                      ? (attendanceValue == true
                                          ? Colors.green.withOpacity(0.1)
                                          : Colors.red.withOpacity(0.1))
                                      : cardColor,
                                  child: Column(
                                    children: [
                                      ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor: faltas >= 3
                                              ? Color(0xFFFF4B2B)
                                              : Color(0xFF147B7C),
                                          foregroundColor: Colors.white,
                                          child: Text(
                                            '${nombre.isNotEmpty ? nombre[0] : ''}${apellido.isNotEmpty ? apellido[0] : ''}',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        title: Text(
                                          '$nombre $apellido',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: isSmallScreen ? 14 : 16,
                                            color: faltas >= 3
                                                ? Color(0xFFFF4B2B)
                                                : Color(0xFF147B7C),
                                          ),
                                        ),
                                        subtitle: Row(
                                          children: [
                                            Icon(
                                              faltas >= 3
                                                  ? Icons.warning_amber_outlined
                                                  : Icons.check_circle_outline,
                                              size: 16,
                                              color: faltas >= 3
                                                  ? Color(0xFFFF4B2B)
                                                  : Colors.grey[600],
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              faltas >= 3
                                                  ? 'Faltas: $faltas'
                                                  : 'Asistencia regular',
                                              style: TextStyle(
                                                fontSize:
                                                    isSmallScreen ? 12 : 14,
                                                color: faltas >= 3
                                                    ? Color(0xFFFF4B2B)
                                                    : Colors.grey[600],
                                              ),
                                            ),
                                            if (isSelected) ...[
                                              SizedBox(width: 8),
                                              Icon(
                                                attendanceValue == true
                                                    ? Icons.check_circle
                                                    : Icons.cancel,
                                                size: 16,
                                                color: attendanceValue == true
                                                    ? Colors.green
                                                    : Colors.red,
                                              ),
                                              Text(
                                                attendanceValue == true
                                                    ? ' Presente'
                                                    : ' Ausente',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: attendanceValue == true
                                                      ? Colors.green
                                                      : Colors.red,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        trailing: bloqueado
                                            ? Tooltip(
                                                message:
                                                    'Bloqueado: revisar alerta de faltas',
                                                child: Container(
                                                  padding: EdgeInsets.all(8),
                                                  decoration: BoxDecoration(
                                                    color: Colors.red.shade50,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                    border: Border.all(
                                                      color:
                                                          Colors.red.shade200,
                                                      width: 1,
                                                    ),
                                                  ),
                                                  child: Icon(
                                                    Icons.lock_outline,
                                                    color: Colors.red.shade400,
                                                    size: 24,
                                                  ),
                                                ),
                                              )
                                            : Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Material(
                                                    color: Colors.transparent,
                                                    child: InkWell(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20),
                                                      onTap:
                                                          _isProcessingMassive
                                                              ? null
                                                              : () {
                                                                  setState(() {
                                                                    _selectedAttendances[
                                                                        registro
                                                                            .id] = true;
                                                                  });
                                                                },
                                                      child: Container(
                                                        padding:
                                                            EdgeInsets.all(8),
                                                        child: Icon(
                                                          Icons.check_circle,
                                                          color: (isSelected &&
                                                                  attendanceValue ==
                                                                      true)
                                                              ? Colors.green
                                                              : Colors.grey,
                                                          size: 28,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  Material(
                                                    color: Colors.transparent,
                                                    child: InkWell(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20),
                                                      onTap:
                                                          _isProcessingMassive
                                                              ? null
                                                              : () {
                                                                  setState(() {
                                                                    _selectedAttendances[
                                                                        registro
                                                                            .id] = false;
                                                                  });
                                                                },
                                                      child: Container(
                                                        padding:
                                                            EdgeInsets.all(8),
                                                        child: Icon(
                                                          Icons.cancel,
                                                          color: (isSelected &&
                                                                  attendanceValue ==
                                                                      false)
                                                              ? Colors.red
                                                              : Colors.grey,
                                                          size: 28,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                      ),
                                      // Mensaje de alerta activa
                                      if (bloqueado)
                                        Container(
                                          width: double.infinity,
                                          padding: EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.red.shade50,
                                            borderRadius: BorderRadius.only(
                                              bottomLeft: Radius.circular(12),
                                              bottomRight: Radius.circular(12),
                                            ),
                                            border: Border(
                                              top: BorderSide(
                                                color: Colors.red.shade200,
                                                width: 1,
                                              ),
                                            ),
                                          ),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Icon(
                                                Icons.info_outline,
                                                color: Colors.red.shade700,
                                                size: isSmallScreen ? 18 : 20,
                                              ),
                                              SizedBox(width: 8),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Estado de Alerta Activa',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color:
                                                            Colors.red.shade700,
                                                        fontSize: isSmallScreen
                                                            ? 12
                                                            : 13,
                                                      ),
                                                    ),
                                                    SizedBox(height: 4),
                                                    Text(
                                                      'Este discípulo tiene $faltas faltas consecutivas. Debe revisar la alerta pendiente antes de registrar nueva asistencia.',
                                                      style: TextStyle(
                                                        fontSize: isSmallScreen
                                                            ? 11
                                                            : 12,
                                                        color:
                                                            Colors.red.shade600,
                                                        height: 1.3,
                                                      ),
                                                    ),
                                                    SizedBox(height: 6),
                                                    Text(
                                                      'Vaya a la pestaña "Alertas" para revisar y gestionar esta situación.',
                                                      style: TextStyle(
                                                        fontSize: isSmallScreen
                                                            ? 10
                                                            : 11,
                                                        color:
                                                            Colors.red.shade500,
                                                        fontStyle:
                                                            FontStyle.italic,
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
                                ),
                              );
                            },
                          );
                        } catch (e) {
                          print('Error construyendo item $index: $e');
                          return SizedBox.shrink();
                        }
                      }),

                      SizedBox(height: 80),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class AlertasTab extends StatelessWidget {
  final String coordinadorId;

  const AlertasTab({Key? key, required this.coordinadorId}) : super(key: key);

  Future<void> _marcarEnRevision(String alertaId) async {
    await FirebaseFirestore.instance
        .collection('alertas')
        .doc(alertaId)
        .update({'estado': 'en_revision'});
  }

  Future<void> _marcarRevisado(String alertaId) async {
    await FirebaseFirestore.instance
        .collection('alertas')
        .doc(alertaId)
        .update({'estado': 'revisado'});
  }

  Future<void> _actualizarEstadoAlerta(
      String alertaId, String nuevoEstado) async {
    try {
      final alertaRef =
          FirebaseFirestore.instance.collection('alertas').doc(alertaId);
      final alertaDoc = await alertaRef.get();

      if (nuevoEstado == 'en_revision') {
        await alertaRef.update({
          'estado': nuevoEstado,
          'fechaRevision': FieldValue.serverTimestamp(),
        });
      } else if (nuevoEstado == 'revisado') {
        final registroId = alertaDoc.get('registroId');
        await FirebaseFirestore.instance
            .collection('registros')
            .doc(registroId)
            .update({
          'visible': true,
          'faltasConsecutivas': 0,
        });

        await alertaRef.update({
          'estado': nuevoEstado,
          'procesada': true,
          'fechaResolucion': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error al actualizar estado de alerta: $e');
    }
  }

  Widget _buildAlertCard(BuildContext context, DocumentSnapshot alerta) {
    // Acceso seguro a los datos del documento
    final data = alerta.data() as Map<String, dynamic>? ?? {};

    // Estado y configuración visual
    final estado = data['estado'] ?? 'Desconocido';
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (estado) {
      case 'pendiente':
        statusColor = Colors.red;
        statusText = 'Pendiente';
        statusIcon = Icons.warning_amber_rounded;
        break;
      case 'en_revision':
        statusColor = kAccentColor;
        statusText = 'En Revisión';
        statusIcon = Icons.hourglass_top;
        break;
      case 'revisado':
        statusColor = Colors.green;
        statusText = 'Revisado';
        statusIcon = Icons.check_circle;
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'Desconocido';
        statusIcon = Icons.help_outline;
    }

    return FutureBuilder<DocumentSnapshot>(
      // Obtener el registro relacionado desde Firestore
      future: FirebaseFirestore.instance
          .collection('registros')
          .doc(data['registroId'])
          .get(),
      builder: (context, snapshot) {
        // Obtener direccion y barrio del registro relacionado
        String direccion = 'Dirección no especificada';
        String barrio = 'Barrio no especificado';

        if (snapshot.hasData && snapshot.data != null) {
          final registroData =
              snapshot.data!.data() as Map<String, dynamic>? ?? {};
          direccion = registroData['direccion'] ?? 'Dirección no especificada';
          barrio = registroData['barrio'] ?? 'Barrio no especificado';
        }

        return Container(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: statusColor.withOpacity(0.1),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: statusColor.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: ExpansionTile(
            leading: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(statusIcon, color: statusColor),
            ),
            title: Text(
              data['nombreJoven'] ?? 'Nombre no disponible',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                    SizedBox(width: 4),
                    Text(
                      data['fecha'] != null
                          ? DateFormat('dd/MM/yyyy HH:mm')
                              .format((data['fecha'] as Timestamp).toDate())
                          : 'Sin fecha',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.warning,
                        size: 14,
                        color: statusColor,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Faltas: ${data['cantidadFaltas'] ?? 0}',
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(16),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(
                      'Timoteo asignado',
                      data['nombreTimoteo'] ?? 'No especificado',
                      Icons.person_outline,
                    ),
                    SizedBox(height: 12),
                    _buildInfoRow(
                      'Estado actual',
                      statusText,
                      Icons.info_outline,
                      color: statusColor,
                    ),
                    SizedBox(height: 12),
                    _buildInfoRow(
                      'Dirección',
                      direccion,
                      Icons.home_outlined,
                    ),
                    SizedBox(height: 12),
                    _buildInfoRow(
                      'Barrio',
                      barrio,
                      Icons.location_city_outlined,
                    ),
                    SizedBox(height: 16),
                    _buildActionButtons(context, estado, alerta.id),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon,
      {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color ?? Colors.grey[600]),
        SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color ?? Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(
      BuildContext context, String estado, String alertaId) {
    if (estado == 'pendiente') {
      return _buildActionButton(
        'Marcar en revisión',
        Icons.pending_actions,
        kAccentColor,
        () => _actualizarEstadoAlerta(alertaId, 'en_revision'),
      );
    } else if (estado == 'en_revision') {
      return _buildActionButton(
        'Marcar como revisado',
        Icons.check_circle,
        Colors.green,
        () => _actualizarEstadoAlerta(alertaId, 'revisado'),
      );
    }
    return SizedBox.shrink();
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onPressed: onPressed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kBackgroundColor,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(Icons.notifications, color: kPrimaryColor),
                SizedBox(width: 12),
                Text(
                  'Alertas de Asistencia',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: kPrimaryColor,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('alertas')
                  .where('coordinadorId', isEqualTo: coordinadorId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Error al cargar las alertas',
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(color: kPrimaryColor),
                  );
                }

                final alertas = snapshot.data?.docs
                    .where((doc) => doc['procesada'] == false)
                    .toList();

                if (alertas == null || alertas.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 64,
                          color: Colors.green,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No hay alertas pendientes',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                alertas.sort((a, b) => (b['fecha'] as Timestamp)
                    .compareTo(a['fecha'] as Timestamp));

                return ListView.builder(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  itemCount: alertas.length,
                  itemBuilder: (context, index) =>
                      _buildAlertCard(context, alertas[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class AttendanceHistoryWidget extends StatelessWidget {
  final List<dynamic> asistencias;
  final double height;

  const AttendanceHistoryWidget({
    Key? key,
    required this.asistencias,
    this.height = 100,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: asistencias.length,
        itemBuilder: (context, index) {
          final asistencia = asistencias[index];
          final fecha = asistencia['fecha'].toDate();
          final asistio = asistencia['asistio'];

          return Card(
            color: asistio ? Colors.green[100] : Colors.red[100],
            margin: EdgeInsets.symmetric(horizontal: 4),
            child: Container(
              width: 80,
              padding: EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    asistio ? Icons.check_circle : Icons.cancel,
                    color: asistio ? Colors.green : Colors.red,
                    size: 32,
                  ),
                  SizedBox(height: 4),
                  Text(
                    DateFormat('dd/MM').format(fecha),
                    style: TextStyle(fontSize: 12),
                  ),
                  Text(
                    DateFormat('HH:mm').format(fecha),
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class TimoteosTab extends StatelessWidget {
  final String coordinadorId;

  const TimoteosTab({Key? key, required this.coordinadorId}) : super(key: key);

  Future<void> _editTimoteo(
      BuildContext context, DocumentSnapshot timoteo) async {
    const Color primaryTeal = Color(0xFF1B8C8C);
    const Color secondaryOrange = Color(0xFFFF4D2E);
    const Color accentYellow = Color(0xFFFFB800);

    final TextEditingController _nameController =
        TextEditingController(text: timoteo['nombre']);
    final TextEditingController _lastNameController =
        TextEditingController(text: timoteo['apellido']);
    final TextEditingController _userController =
        TextEditingController(text: timoteo['usuario']);
    final TextEditingController _passwordController =
        TextEditingController(text: timoteo['contrasena']);

    bool _isPasswordVisible = false;
    bool _isSaving = false;

    final FocusNode _nameFocus = FocusNode();
    final FocusNode _lastNameFocus = FocusNode();
    final FocusNode _userFocus = FocusNode();
    final FocusNode _passwordFocus = FocusNode();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            // ✅ DIMENSIONES RESPONSIVAS
            final mediaQuery = MediaQuery.of(dialogContext);
            final screenWidth = mediaQuery.size.width;
            final screenHeight = mediaQuery.size.height;
            final keyboardHeight = mediaQuery.viewInsets.bottom;

            final isVerySmallScreen = screenWidth < 360;
            final isSmallScreen = screenWidth < 600;
            final isMediumScreen = screenWidth >= 600 && screenWidth < 900;

            // ✅ TAMAÑOS ADAPTATIVOS
            final horizontalPadding =
                isVerySmallScreen ? 16.0 : (isSmallScreen ? 20.0 : 24.0);
            final verticalPadding =
                isVerySmallScreen ? 16.0 : (isSmallScreen ? 20.0 : 24.0);
            final titleFontSize =
                isVerySmallScreen ? 18.0 : (isSmallScreen ? 20.0 : 22.0);
            final labelFontSize =
                isVerySmallScreen ? 13.0 : (isSmallScreen ? 14.0 : 15.0);
            final contentFontSize =
                isVerySmallScreen ? 14.0 : (isSmallScreen ? 15.0 : 16.0);
            final iconSize =
                isVerySmallScreen ? 20.0 : (isSmallScreen ? 22.0 : 24.0);
            final borderRadius =
                isVerySmallScreen ? 16.0 : (isSmallScreen ? 20.0 : 24.0);

            // ✅ DIÁLOGO COMPLETAMENTE ADAPTATIVO
            return Align(
              alignment: Alignment.center,
              child: Container(
                width: isVerySmallScreen
                    ? screenWidth * 0.95
                    : (isSmallScreen
                        ? 600.0
                        : (isMediumScreen ? 650.0 : 700.0)),
                height: screenHeight * 0.75,
                margin: EdgeInsets.symmetric(
                  horizontal: isVerySmallScreen ? 12 : 16,
                  vertical: 24,
                ),
                decoration: BoxDecoration(
                  color: Color(0xFFF5F7FA),
                  borderRadius: BorderRadius.circular(borderRadius),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ============================================================
                    // ENCABEZADO FIJO
                    // ============================================================
                    Container(
                      padding: EdgeInsets.all(horizontalPadding),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [primaryTeal, primaryTeal.withOpacity(0.8)],
                        ),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(borderRadius),
                          topRight: Radius.circular(borderRadius),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(isVerySmallScreen ? 8 : 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 2),
                            ),
                            child: Icon(Icons.edit_rounded,
                                color: Colors.white, size: iconSize),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Editar Timoteo',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: titleFontSize,
                                      letterSpacing: 0.5,
                                    ),
                                    maxLines: 1,
                                  ),
                                ),
                                if (!isVerySmallScreen) SizedBox(height: 4),
                                if (!isVerySmallScreen)
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      'Actualiza la información',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: labelFontSize,
                                      ),
                                      maxLines: 1,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ============================================================
                    // FORMULARIO CON SCROLL
                    // ============================================================
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.only(bottom: keyboardHeight),
                        physics: ClampingScrollPhysics(),
                        child: Padding(
                          padding: EdgeInsets.all(horizontalPadding),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(height: verticalPadding * 0.5),

                              // Campo Nombre
                              _buildResponsiveTextField(
                                controller: _nameController,
                                focusNode: _nameFocus,
                                label: 'Nombre',
                                icon: Icons.person_outline,
                                primaryColor: primaryTeal,
                                fontSize: contentFontSize,
                                iconSize: iconSize,
                                borderRadius: borderRadius * 0.7,
                                onSubmitted: (_) =>
                                    _lastNameFocus.requestFocus(),
                              ),
                              SizedBox(height: verticalPadding * 0.7),

                              // Campo Apellido
                              _buildResponsiveTextField(
                                controller: _lastNameController,
                                focusNode: _lastNameFocus,
                                label: 'Apellido',
                                icon: Icons.person,
                                primaryColor: primaryTeal,
                                fontSize: contentFontSize,
                                iconSize: iconSize,
                                borderRadius: borderRadius * 0.7,
                                onSubmitted: (_) => _userFocus.requestFocus(),
                              ),
                              SizedBox(height: verticalPadding * 0.7),

                              // Campo Usuario
                              _buildResponsiveTextField(
                                controller: _userController,
                                focusNode: _userFocus,
                                label: 'Usuario',
                                icon: Icons.account_circle_outlined,
                                primaryColor: primaryTeal,
                                fontSize: contentFontSize,
                                iconSize: iconSize,
                                borderRadius: borderRadius * 0.7,
                                onSubmitted: (_) =>
                                    _passwordFocus.requestFocus(),
                              ),
                              SizedBox(height: verticalPadding * 0.7),

                              // Campo Contraseña
                              _buildResponsiveTextField(
                                controller: _passwordController,
                                focusNode: _passwordFocus,
                                label: 'Contraseña',
                                icon: Icons.lock_outline,
                                primaryColor: primaryTeal,
                                fontSize: contentFontSize,
                                iconSize: iconSize,
                                borderRadius: borderRadius * 0.7,
                                isPassword: true,
                                isPasswordVisible: _isPasswordVisible,
                                onToggleVisibility: () {
                                  setState(() {
                                    _isPasswordVisible = !_isPasswordVisible;
                                  });
                                },
                                onSubmitted: (_) {
                                  FocusScope.of(context).unfocus();
                                },
                              ),

                              SizedBox(height: verticalPadding * 1.5),

                              // Divider
                              Container(
                                height: 1,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      primaryTeal.withOpacity(0.3),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),

                              SizedBox(height: verticalPadding * 1.5),

                              // ============================================================
                              // BOTONES AL FINAL DEL SCROLL
                              // ============================================================
                              isSmallScreen
                                  ? Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Botón Guardar (móvil)
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: secondaryOrange,
                                              foregroundColor: Colors.white,
                                              padding: EdgeInsets.symmetric(
                                                  vertical: isVerySmallScreen
                                                      ? 12
                                                      : 14),
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          borderRadius * 0.5)),
                                              elevation: 2,
                                            ),
                                            icon: _isSaving
                                                ? SizedBox(
                                                    height: iconSize * 0.8,
                                                    width: iconSize * 0.8,
                                                    child:
                                                        CircularProgressIndicator(
                                                      strokeWidth: 2.5,
                                                      valueColor:
                                                          AlwaysStoppedAnimation<
                                                                  Color>(
                                                              Colors.white),
                                                    ),
                                                  )
                                                : Icon(Icons.save_rounded,
                                                    size: iconSize * 0.8),
                                            label: Text(
                                              _isSaving
                                                  ? 'Guardando...'
                                                  : 'Guardar Cambios',
                                              style: TextStyle(
                                                  fontSize: contentFontSize,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            onPressed: _isSaving
                                                ? null
                                                : () => _guardarCambios(
                                                    context,
                                                    timoteo,
                                                    _nameController,
                                                    _lastNameController,
                                                    _userController,
                                                    _passwordController,
                                                    setState,
                                                    (value) =>
                                                        _isSaving = value),
                                          ),
                                        ),
                                        SizedBox(height: 12),
                                        SizedBox(
                                          width: double.infinity,
                                          child: TextButton.icon(
                                            onPressed: _isSaving
                                                ? null
                                                : () => Navigator.pop(context),
                                            style: TextButton.styleFrom(
                                              padding: EdgeInsets.symmetric(
                                                  vertical: isVerySmallScreen
                                                      ? 12
                                                      : 14),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        borderRadius * 0.5),
                                                side: BorderSide(
                                                    color: Colors.grey.shade300,
                                                    width: 1.5),
                                              ),
                                            ),
                                            icon: Icon(Icons.close_rounded,
                                                size: iconSize * 0.8),
                                            label: Text('Cancelar',
                                                style: TextStyle(
                                                    fontSize: contentFontSize,
                                                    fontWeight:
                                                        FontWeight.w600)),
                                          ),
                                        ),
                                      ],
                                    )
                                  : Row(
                                      children: [
                                        Expanded(
                                          child: TextButton.icon(
                                            onPressed: _isSaving
                                                ? null
                                                : () => Navigator.pop(context),
                                            style: TextButton.styleFrom(
                                              padding: EdgeInsets.symmetric(
                                                  vertical: 16),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        borderRadius * 0.5),
                                                side: BorderSide(
                                                    color: Colors.grey.shade300,
                                                    width: 1.5),
                                              ),
                                            ),
                                            icon: Icon(Icons.close_rounded,
                                                size: iconSize * 0.8),
                                            label: Text('Cancelar',
                                                style: TextStyle(
                                                    fontSize: contentFontSize,
                                                    fontWeight:
                                                        FontWeight.w600)),
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        Expanded(
                                          flex: 2,
                                          child: ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: secondaryOrange,
                                              foregroundColor: Colors.white,
                                              padding: EdgeInsets.symmetric(
                                                  vertical: 16),
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          borderRadius * 0.5)),
                                              elevation: 2,
                                            ),
                                            icon: _isSaving
                                                ? SizedBox(
                                                    height: iconSize * 0.8,
                                                    width: iconSize * 0.8,
                                                    child: CircularProgressIndicator(
                                                        strokeWidth: 2.5,
                                                        valueColor:
                                                            AlwaysStoppedAnimation<
                                                                    Color>(
                                                                Colors.white)),
                                                  )
                                                : Icon(Icons.save_rounded,
                                                    size: iconSize * 0.8),
                                            label: Text(
                                                _isSaving
                                                    ? 'Guardando...'
                                                    : 'Guardar Cambios',
                                                style: TextStyle(
                                                    fontSize: contentFontSize,
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            onPressed: _isSaving
                                                ? null
                                                : () => _guardarCambios(
                                                    context,
                                                    timoteo,
                                                    _nameController,
                                                    _lastNameController,
                                                    _userController,
                                                    _passwordController,
                                                    setState,
                                                    (value) =>
                                                        _isSaving = value),
                                          ),
                                        ),
                                      ],
                                    ),

                              SizedBox(height: verticalPadding),
                            ],
                          ),
                        ),
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

    _nameController.dispose();
    _lastNameController.dispose();
    _userController.dispose();
    _passwordController.dispose();
    _nameFocus.dispose();
    _lastNameFocus.dispose();
    _userFocus.dispose();
    _passwordFocus.dispose();
  }

// ============================================================
// WIDGET AUXILIAR PARA CAMPOS DE TEXTO RESPONSIVOS
// ============================================================

// REEMPLAZAR el método _buildResponsiveTextField dentro de _editTimoteo
// (aproximadamente línea 1270)

  Widget _buildResponsiveTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required IconData icon,
    required Color primaryColor,
    required double fontSize,
    required double iconSize,
    required double borderRadius,
    bool isPassword = false,
    bool isPasswordVisible = false,
    VoidCallback? onToggleVisibility,
    Function(String)? onSubmitted,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.08),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      margin: EdgeInsets.only(bottom: 16),
      child: Builder(
        builder: (fieldContext) {
          return TextField(
            controller: controller,
            focusNode: focusNode,
            obscureText: isPassword && !isPasswordVisible,
            textInputAction: TextInputAction.next,
            onTap: () {
              // Auto-scroll cuando el campo recibe foco
              Future.delayed(Duration(milliseconds: 300), () {
                if (fieldContext.mounted) {
                  try {
                    Scrollable.ensureVisible(
                      fieldContext,
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      alignment:
                          0.3, // Posiciona el campo en el tercio superior
                    );
                  } catch (e) {
                    print('Error en ensureVisible: $e');
                  }
                }
              });
            },
            onSubmitted: onSubmitted,
            style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w500,
                color: Colors.black87),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(
                  color: primaryColor.withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                  fontSize: fontSize * 0.9),
              prefixIcon: Container(
                margin: EdgeInsets.all(12),
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: primaryColor, size: iconSize * 0.85),
              ),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                          isPasswordVisible
                              ? Icons.visibility_rounded
                              : Icons.visibility_off_rounded,
                          color: primaryColor.withOpacity(0.7),
                          size: iconSize * 0.9),
                      onPressed: onToggleVisibility,
                    )
                  : null,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(borderRadius),
                  borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(borderRadius),
                  borderSide:
                      BorderSide(color: Colors.grey.shade200, width: 1)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(borderRadius),
                  borderSide: BorderSide(color: primaryColor, width: 2)),
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            ),
          );
        },
      ),
    );
  }

// ============================================================
// FUNCIÓN AUXILIAR PARA GUARDAR CAMBIOS
// ============================================================
  Future<void> _guardarCambios(
    BuildContext context,
    DocumentSnapshot timoteo,
    TextEditingController nameController,
    TextEditingController lastNameController,
    TextEditingController userController,
    TextEditingController passwordController,
    StateSetter setState,
    Function(bool) setIsSaving,
  ) async {
    setState(() {
      setIsSaving(true);
    });

    try {
      await FirebaseFirestore.instance
          .collection('timoteos')
          .doc(timoteo.id)
          .update({
        'nombre': nameController.text,
        'apellido': lastNameController.text,
        'usuario': userController.text,
        'contrasena': passwordController.text,
      });

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle),
                  child: Icon(Icons.check_circle_rounded,
                      color: Colors.white, size: 20),
                ),
                SizedBox(width: 12),
                Expanded(
                    child: Text('Timoteo actualizado exitosamente',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15))),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: EdgeInsets.all(16),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() {
        setIsSaving(false);
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Expanded(
                    child: Text('Error al actualizar: $e',
                        style: TextStyle(fontWeight: FontWeight.w600))),
              ],
            ),
            backgroundColor: Color(0xFFFF4D2E),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: EdgeInsets.all(16),
          ),
        );
      }
    }
  }

// ============================================================
// WIDGET AUXILIAR PARA CAMPOS DE TEXTO MEJORADOS
// ============================================================
  Widget _buildEnhancedTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color primaryColor,
    bool isPassword = false,
    bool isPasswordVisible = false,
    VoidCallback? onToggleVisibility,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.08),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword && !isPasswordVisible,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: primaryColor.withOpacity(0.7),
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
          prefixIcon: Container(
            margin: EdgeInsets.all(12),
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: primaryColor,
              size: 20,
            ),
          ),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    isPasswordVisible
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                    color: primaryColor.withOpacity(0.7),
                    size: 22,
                  ),
                  onPressed: onToggleVisibility,
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: Colors.grey.shade200,
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: primaryColor,
              width: 2,
            ),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 18,
          ),
        ),
      ),
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
            kPrimaryColor.withOpacity(0.02),
          ],
        ),
      ),
      child: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('timoteos')
            .where('coordinadorId', isEqualTo: coordinadorId)
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
                      color: kPrimaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: CircularProgressIndicator(
                      color: kPrimaryColor,
                      strokeWidth: 3,
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Cargando timoteos...',
                    style: TextStyle(
                      fontSize: 16,
                      color: kPrimaryColor,
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
                      color: Colors.grey.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person_off_outlined,
                      size: 72,
                      color: Colors.grey.shade400,
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'No hay Timoteos asignados',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Los timoteos aparecerán aquí',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final timoteo = snapshot.data!.docs[index];
              final iniciales =
                  '${timoteo['nombre'][0]}${timoteo['apellido'][0]}'
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
                      kPrimaryColor.withOpacity(0.02),
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
                    color: kPrimaryColor.withOpacity(0.12),
                    width: 1,
                  ),
                ),
                child: Theme(
                  data: Theme.of(context).copyWith(
                    dividerColor: Colors.transparent,
                  ),
                  child: ExpansionTile(
                    tilePadding:
                        EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    childrenPadding: EdgeInsets.zero,
                    leading: Hero(
                      tag: 'timoteo_${timoteo.id}',
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              kPrimaryColor,
                              kPrimaryColor.withOpacity(0.7),
                            ],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: kPrimaryColor.withOpacity(0.3),
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
                              fontSize: 18,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      '${timoteo['nombre']} ${timoteo['apellido']}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: kPrimaryColor,
                        fontSize: 17,
                      ),
                    ),
                    subtitle: Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Row(
                        children: [
                          Icon(
                            Icons.account_circle_outlined,
                            size: 16,
                            color: Colors.grey.shade600,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Usuario: ${timoteo['usuario']}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    trailing: Icon(
                      Icons.expand_more,
                      color: kPrimaryColor,
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
                            _TimoteoPasswordField(
                              password: timoteo['contrasena'] ?? '',
                              primaryColor: kPrimaryColor,
                            ),

                            SizedBox(height: 16),

                            // Divisor
                            Divider(height: 1, color: Colors.grey.shade300),
                            SizedBox(height: 16),

                            // Botones de acción mejorados
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              alignment: WrapAlignment.center,
                              children: [
                                _buildModernActionButton(
                                  icon: Icons.edit_rounded,
                                  label: 'Editar',
                                  color: kPrimaryColor,
                                  onPressed: () =>
                                      _editTimoteo(context, timoteo),
                                ),
                                _buildModernActionButton(
                                  icon: Icons.list_alt_rounded,
                                  label: 'Registros',
                                  color: kSecondaryColor,
                                  onPressed: () =>
                                      _viewAssignedRegistros(context, timoteo),
                                ),
                                _buildModernActionButton(
                                  icon: Icons.person_rounded,
                                  label: 'Ver Perfil',
                                  color: kAccentColor,
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => TimoteoScreen(
                                          timoteoId: timoteo.id,
                                          timoteoNombre:
                                              '${timoteo['nombre']} ${timoteo['apellido']}',
                                        ),
                                      ),
                                    );
                                  },
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
    );
  }

  Widget _buildModernActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
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
            color: color.withOpacity(0.25),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: Colors.white,
                  size: 18,
                ),
                SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TimoteoPasswordField extends StatefulWidget {
  final String password;
  final Color primaryColor;

  const _TimoteoPasswordField({
    Key? key,
    required this.password,
    required this.primaryColor,
  }) : super(key: key);

  @override
  _TimoteoPasswordFieldState createState() => _TimoteoPasswordFieldState();
}

class _TimoteoPasswordFieldState extends State<_TimoteoPasswordField> {
  bool _isVisible = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.primaryColor.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: widget.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.lock_outline,
              color: widget.primaryColor,
              size: 20,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Contraseña',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  _isVisible ? widget.password : '••••••••',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: _isVisible ? 0 : 2,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              _isVisible ? Icons.visibility : Icons.visibility_off,
              color: widget.primaryColor,
              size: 20,
            ),
            onPressed: () {
              setState(() {
                _isVisible = !_isVisible;
              });
            },
            tooltip: _isVisible ? 'Ocultar' : 'Mostrar',
          ),
        ],
      ),
    );
  }
}

Future<void> _viewAssignedRegistros(
    BuildContext context, DocumentSnapshot timoteo) async {
  // Colores del tema
  const Color primaryTeal = Color(0xFF1B8C8C);
  const Color secondaryOrange = Color(0xFFFF4D2E);
  const Color accentYellow = Color(0xFFFFB800);
  const Color backgroundGrey = Color(0xFFF5F7FA);

  await showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      // ============================================================
      // RESPONSIVIDAD: Detectar tamaño de pantalla
      // ============================================================
      final screenWidth = MediaQuery.of(context).size.width;
      final screenHeight = MediaQuery.of(context).size.height;
      final isSmallScreen = screenWidth < 600;
      final isMediumScreen = screenWidth >= 600 && screenWidth < 1024;
      final isLargeScreen = screenWidth >= 1024;

      // Calcular dimensiones responsivas
      double dialogWidth;
      double dialogHeight;
      double horizontalPadding;
      double avatarRadius;
      double titleFontSize;
      double contentPadding;

      if (isSmallScreen) {
        // Móviles pequeños (< 600px)
        dialogWidth = screenWidth * 0.95;
        dialogHeight = screenHeight * 0.85;
        horizontalPadding = 16;
        avatarRadius = 24;
        titleFontSize = 18;
        contentPadding = 12;
      } else if (isMediumScreen) {
        // Tablets (600px - 1024px)
        dialogWidth = screenWidth * 0.75;
        dialogHeight = screenHeight * 0.80;
        horizontalPadding = 24;
        avatarRadius = 28;
        titleFontSize = 20;
        contentPadding = 16;
      } else {
        // Desktop/Web (> 1024px)
        dialogWidth = 800; // Ancho fijo para desktop
        dialogHeight = screenHeight * 0.85;
        horizontalPadding = 32;
        avatarRadius = 32;
        titleFontSize = 22;
        contentPadding = 20;
      }

      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 16 : 32,
          vertical: isSmallScreen ? 24 : 40,
        ),
        child: Container(
          width: dialogWidth,
          height: dialogHeight,
          constraints: BoxConstraints(
            maxWidth: isLargeScreen ? 900 : double.infinity,
            maxHeight: screenHeight * 0.90,
          ),
          decoration: BoxDecoration(
            color: backgroundGrey,
            borderRadius: BorderRadius.circular(isSmallScreen ? 20 : 24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              // ============================================================
              // ENCABEZADO RESPONSIVO
              // ============================================================
              Container(
                padding: EdgeInsets.all(contentPadding),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      primaryTeal,
                      primaryTeal.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(isSmallScreen ? 20 : 24),
                    topRight: Radius.circular(isSmallScreen ? 20 : 24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primaryTeal.withOpacity(0.3),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Avatar responsivo
                    Hero(
                      tag: 'timoteo_${timoteo.id}',
                      child: Container(
                        padding: EdgeInsets.all(isSmallScreen ? 2 : 3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.5),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: avatarRadius,
                          backgroundColor: accentYellow,
                          child: Text(
                            '${timoteo['nombre'][0]}${timoteo['apellido'][0]}',
                            style: TextStyle(
                              color: primaryTeal,
                              fontWeight: FontWeight.bold,
                              fontSize: avatarRadius * 0.7,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: isSmallScreen ? 12 : 16),
                    // Información del timoteo
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${timoteo['nombre']} ${timoteo['apellido']}',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: titleFontSize,
                              letterSpacing: 0.5,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          SizedBox(height: 4),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isSmallScreen ? 8 : 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.assignment_ind,
                                  color: Colors.white,
                                  size: isSmallScreen ? 12 : 14,
                                ),
                                SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    'Registros Asignados',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: isSmallScreen ? 11 : 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Botón de cerrar responsivo
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
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

              // ============================================================
              // CONTENIDO RESPONSIVO CON STREAMBUILDER
              // ============================================================
              Expanded(
                child: StreamBuilder(
                  stream: FirebaseFirestore.instance
                      .collection('registros')
                      .where('timoteoAsignado', isEqualTo: timoteo.id)
                      .snapshots(),
                  builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryTeal.withOpacity(0.2),
                                    blurRadius: 12,
                                    offset: Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: CircularProgressIndicator(
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(primaryTeal),
                                strokeWidth: 3,
                              ),
                            ),
                            SizedBox(height: 20),
                            Text(
                              'Cargando registros...',
                              style: TextStyle(
                                color: primaryTeal,
                                fontSize: isSmallScreen ? 14 : 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: EdgeInsets.all(horizontalPadding),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding:
                                    EdgeInsets.all(isSmallScreen ? 20 : 24),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.1),
                                      blurRadius: 12,
                                      offset: Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.inbox_outlined,
                                  size: isSmallScreen ? 48 : 64,
                                  color: Colors.grey.shade400,
                                ),
                              ),
                              SizedBox(height: 20),
                              Text(
                                'Sin registros asignados',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 16 : 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Este timoteo aún no tiene personas asignadas',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 13 : 14,
                                  color: Colors.grey.shade500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final registros = snapshot.data!.docs;

                    return Column(
                      children: [
                        // Badge con contador responsivo
                        Container(
                          margin: EdgeInsets.all(horizontalPadding),
                          padding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 16 : 20,
                            vertical: isSmallScreen ? 10 : 12,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                primaryTeal.withOpacity(0.1),
                                accentYellow.withOpacity(0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: primaryTeal.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.people_alt_rounded,
                                color: primaryTeal,
                                size: isSmallScreen ? 20 : 24,
                              ),
                              SizedBox(width: isSmallScreen ? 8 : 12),
                              Flexible(
                                child: Text(
                                  'Total: ',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 14 : 16,
                                    color: Colors.grey.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Text(
                                '${registros.length}',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 18 : 20,
                                  fontWeight: FontWeight.bold,
                                  color: primaryTeal,
                                ),
                              ),
                              Flexible(
                                child: Text(
                                  ' persona${registros.length != 1 ? 's' : ''}',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 14 : 16,
                                    color: Colors.grey.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Lista de registros responsiva (Grid en pantallas grandes)
                        Expanded(
                          child: isLargeScreen
                              ? _buildGridView(
                                  registros,
                                  primaryTeal,
                                  secondaryOrange,
                                  accentYellow,
                                  horizontalPadding,
                                )
                              : _buildListView(
                                  registros,
                                  primaryTeal,
                                  secondaryOrange,
                                  accentYellow,
                                  horizontalPadding,
                                  isSmallScreen,
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
      );
    },
  );
}

// WIDGET AUXILIAR: ListView para móviles/tablets
Widget _buildListView(
  List<QueryDocumentSnapshot> registros,
  Color primaryTeal,
  Color secondaryOrange,
  Color accentYellow,
  double horizontalPadding,
  bool isSmallScreen,
) {
  return ListView.builder(
    padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
    itemCount: registros.length,
    itemBuilder: (context, index) {
      return _buildRegistroCard(
        context,
        registros[index],
        primaryTeal,
        secondaryOrange,
        accentYellow,
        isSmallScreen,
      );
    },
  );
}

Widget _buildGridView(
  List<QueryDocumentSnapshot> registros,
  Color primaryTeal,
  Color secondaryOrange,
  Color accentYellow,
  double horizontalPadding,
) {
  return GridView.builder(
    padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2, // 2 columnas en desktop
      childAspectRatio: 3.5, // Ajustar proporción
      crossAxisSpacing: 16,
      mainAxisSpacing: 12,
    ),
    itemCount: registros.length,
    itemBuilder: (context, index) {
      return _buildRegistroCard(
        context,
        registros[index],
        primaryTeal,
        secondaryOrange,
        accentYellow,
        false, // No es pantalla pequeña
      );
    },
  );
}

Widget _buildRegistroCard(
  BuildContext context,
  QueryDocumentSnapshot registro,
  Color primaryTeal,
  Color secondaryOrange,
  Color accentYellow,
  bool isSmallScreen,
) {
  final data = registro.data() as Map<String, dynamic>;

  return Container(
    margin: EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 8,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          HapticFeedback.lightImpact();
        },
        child: Padding(
          padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
          child: Row(
            children: [
              // Avatar con gradiente
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      primaryTeal,
                      primaryTeal.withOpacity(0.7),
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: primaryTeal.withOpacity(0.3),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: isSmallScreen ? 20 : 24,
                  backgroundColor: Colors.transparent,
                  child: Text(
                    '${data['nombre']?[0] ?? '?'}${data['apellido']?[0] ?? '?'}',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: isSmallScreen ? 14 : 16,
                    ),
                  ),
                ),
              ),
              SizedBox(width: isSmallScreen ? 12 : 16),
              // Información
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${data['nombre'] ?? 'Sin nombre'} ${data['apellido'] ?? ''}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isSmallScreen ? 14 : 16,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 6 : 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: primaryTeal.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.phone,
                                size: isSmallScreen ? 10 : 12,
                                color: primaryTeal,
                              ),
                              SizedBox(width: 4),
                              Text(
                                data['telefono'] ?? 'Sin teléfono',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 11 : 12,
                                  fontWeight: FontWeight.w600,
                                  color: primaryTeal,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (data['fechaAsignacion'] != null)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isSmallScreen ? 6 : 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: accentYellow.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: isSmallScreen ? 10 : 12,
                                  color: Colors.orange.shade800,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  DateFormat('dd/MM/yy').format(
                                      (data['fechaAsignacion'] as Timestamp)
                                          .toDate()),
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 10 : 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.orange.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              // Botón de desasignar
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () async {
                    HapticFeedback.mediumImpact();

                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        title: Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: secondaryOrange,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Confirmar',
                                style: TextStyle(
                                    fontSize: isSmallScreen ? 16 : 18),
                              ),
                            ),
                          ],
                        ),
                        content: Text(
                          '¿Deseas desasignar a ${data['nombre']} ${data['apellido']}?',
                          style: TextStyle(fontSize: isSmallScreen ? 14 : 15),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text(
                              'Cancelar',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: secondaryOrange,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              'Desasignar',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      try {
                        await FirebaseFirestore.instance
                            .collection('registros')
                            .doc(registro.id)
                            .update({
                          'timoteoAsignado': null,
                          'nombreTimoteo': null,
                          'fechaAsignacion': null,
                        });

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  Icon(Icons.check_circle, color: Colors.white),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Desasignado exitosamente',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ],
                              ),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  Icon(Icons.error, color: Colors.white),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Error: $e',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ],
                              ),
                              backgroundColor: secondaryOrange,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        }
                      }
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                    decoration: BoxDecoration(
                      color: secondaryOrange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: secondaryOrange.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.person_remove_rounded,
                      color: secondaryOrange,
                      size: isSmallScreen ? 18 : 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class PersonasAsignadasTab extends StatelessWidget {
  final String coordinadorId;

  const PersonasAsignadasTab({Key? key, required this.coordinadorId})
      : super(key: key);

  Future<void> _asignarATimoteo(
      BuildContext context, DocumentSnapshot registro) async {
    // Obtener lista de timoteos del coordinador
    final timoteosSnapshot = await FirebaseFirestore.instance
        .collection('timoteos')
        .where('coordinadorId', isEqualTo: coordinadorId)
        .get();

    if (timoteosSnapshot.docs.isEmpty) {
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
                child: Icon(Icons.warning, color: Colors.white, size: 20),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'No hay Timoteos disponibles para asignar',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: kSecondaryColor,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: EdgeInsets.all(16),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: kPrimaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.person_add,
                  color: kPrimaryColor,
                  size: 24,
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Asignar a Timoteo',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: kTextDarkColor,
                ),
              ),
            ],
          ),
          content: Container(
            width: double.maxFinite,
            constraints: BoxConstraints(maxHeight: 400),
            // ============================================================
            // ⚠️ FUNCIONALIDAD DE LÍMITE DE 10 PERSONAS - TEMPORALMENTE DESACTIVADA
            // ============================================================
            // TODO EL SIGUIENTE BLOQUE ESTÁ COMENTADO:
            // - Valida que cada timoteo tenga máximo 10 personas asignadas
            // - Muestra el contador "X/10 asignados"
            // - Bloquea la asignación cuando se alcanza el límite
            // - Ordena timoteos por cantidad de asignados
            //
            // Para reactivar: Descomenta desde aquí hasta el comentario de cierre
            // y comenta el ListView.builder simple que está debajo.
            // ============================================================
            /*
  child: FutureBuilder<List<Map<String, dynamic>>>(
    future: _obtenerTimoteosConConteo(timoteosSnapshot.docs),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(kPrimaryColor),
              ),
              SizedBox(height: 16),
              Text(
                'Cargando timoteos...',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        );
      }

      if (snapshot.hasError) {
        return Center(
          child: Text(
            'Error al cargar timoteos',
            style: TextStyle(color: Colors.red),
          ),
        );
      }

      final timoteosConConteo = snapshot.data ?? [];

      return ListView.builder(
        shrinkWrap: true,
        itemCount: timoteosConConteo.length,
        itemBuilder: (context, index) {
          final timoteoData = timoteosConConteo[index];
          final timoteoDoc = timoteoData['doc'] as DocumentSnapshot;
          final cantidadAsignados = timoteoData['cantidad'] as int;
          final bool estaLleno = cantidadAsignados >= 10;

          return Container(
            margin: EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: estaLleno
                    ? Colors.grey.withOpacity(0.3)
                    : kPrimaryColor.withOpacity(0.3),
                width: 1,
              ),
              color: estaLleno
                  ? Colors.grey.withOpacity(0.05)
                  : Colors.white,
            ),
            child: ListTile(
              enabled: !estaLleno,
              leading: CircleAvatar(
                backgroundColor: estaLleno
                    ? Colors.grey.withOpacity(0.3)
                    : kPrimaryColor.withOpacity(0.1),
                child: Text(
                  '${timoteoDoc['nombre'][0]}${timoteoDoc['apellido'][0]}',
                  style: TextStyle(
                    color: estaLleno ? Colors.grey : kPrimaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                '${timoteoDoc['nombre']} ${timoteoDoc['apellido']}',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: estaLleno ? Colors.grey : Colors.black87,
                ),
              ),
              subtitle: Row(
                children: [
                  Icon(
                    Icons.people,
                    size: 14,
                    color: estaLleno ? Colors.grey : kPrimaryColor,
                  ),
                  SizedBox(width: 4),
                  Text(
                    '$cantidadAsignados/10 asignados',
                    style: TextStyle(
                      fontSize: 13,
                      color:
                          estaLleno ? Colors.grey : Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (estaLleno) ...[
                    SizedBox(width: 8),
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'COMPLETO',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              trailing: estaLleno
                  ? Icon(Icons.block, color: Colors.grey)
                  : Icon(Icons.arrow_forward_ios,
                      color: kPrimaryColor, size: 16),
              onTap: estaLleno
                  ? () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color:
                                      Colors.white.withOpacity(0.2),
                                  borderRadius:
                                      BorderRadius.circular(6),
                                ),
                                child: Icon(Icons.block,
                                    color: Colors.white, size: 20),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Un Timoteo solo puede tener 10 almas asignadas',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          backgroundColor: kSecondaryColor,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(12)),
                          margin: EdgeInsets.all(16),
                          duration: Duration(seconds: 3),
                        ),
                      );
                    }
                  : () async {
                      try {
                        await FirebaseFirestore.instance
                            .collection('registros')
                            .doc(registro.id)
                            .update({
                          'timoteoAsignado': timoteoDoc.id,
                          'nombreTimoteo':
                              '${timoteoDoc['nombre']} ${timoteoDoc['apellido']}',
                          'fechaAsignacion':
                              FieldValue.serverTimestamp(),
                        });

                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color:
                                        Colors.white.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.check,
                                      color: Colors.white, size: 20),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Registro asignado exitosamente a ${timoteoDoc['nombre']}',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            backgroundColor: kPrimaryColor,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(12)),
                            margin: EdgeInsets.all(16),
                            duration: Duration(seconds: 3),
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                Icon(Icons.error,
                                    color: Colors.white, size: 20),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Error al asignar el registro: $e',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            backgroundColor: kSecondaryColor,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(12)),
                            margin: EdgeInsets.all(16),
                          ),
                        );
                      }
                    },
            ),
          );
        },
      );
    },
  ),
  */
            // ============================================================
            // FIN DEL BLOQUE COMENTADO - LÍMITE DE 10 PERSONAS
            // ============================================================

            // ============================================================
            // VERSIÓN TEMPORAL SIN LÍMITE (ACTIVA)
            // ============================================================
            // Esta versión simple permite asignar personas sin restricciones.
            // Comentar este bloque cuando se reactive el límite arriba.
            // ============================================================
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: timoteosSnapshot.docs.length,
              itemBuilder: (context, index) {
                final timoteoDoc = timoteosSnapshot.docs[index];

                return Container(
                  margin: EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: kPrimaryColor.withOpacity(0.3),
                      width: 1,
                    ),
                    color: Colors.white,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: kPrimaryColor.withOpacity(0.1),
                      child: Text(
                        '${timoteoDoc['nombre'][0]}${timoteoDoc['apellido'][0]}',
                        style: TextStyle(
                          color: kPrimaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      '${timoteoDoc['nombre']} ${timoteoDoc['apellido']}',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    subtitle: Text(
                      'Disponible para asignación',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: Icon(Icons.arrow_forward_ios,
                        color: kPrimaryColor, size: 16),
                    onTap: () async {
                      try {
                        await FirebaseFirestore.instance
                            .collection('registros')
                            .doc(registro.id)
                            .update({
                          'timoteoAsignado': timoteoDoc.id,
                          'nombreTimoteo':
                              '${timoteoDoc['nombre']} ${timoteoDoc['apellido']}',
                          'fechaAsignacion': FieldValue.serverTimestamp(),
                        });

                        Navigator.pop(context);
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
                                  child: Icon(Icons.check,
                                      color: Colors.white, size: 20),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Registro asignado exitosamente a ${timoteoDoc['nombre']}',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            backgroundColor: kPrimaryColor,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            margin: EdgeInsets.all(16),
                            duration: Duration(seconds: 3),
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                Icon(Icons.error,
                                    color: Colors.white, size: 20),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Error al asignar el registro: $e',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            backgroundColor: kSecondaryColor,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            margin: EdgeInsets.all(16),
                          ),
                        );
                      }
                    },
                  ),
                );
              },
            ),
            // ============================================================
            // FIN VERSIÓN TEMPORAL SIN LÍMITE
            // ============================================================
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
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

// ============================================================
// ⚠️ MÉTODO AUXILIAR PARA LÍMITE - TEMPORALMENTE DESACTIVADO
// ============================================================
// Este método:
// - Cuenta cuántas personas tiene asignadas cada timoteo
// - Ordena los timoteos por cantidad de asignados (menos a más)
// - Retorna la información para mostrar "X/10 asignados"
//
// Para reactivar: Descomenta todo el método
// ============================================================
/*
Future<List<Map<String, dynamic>>> _obtenerTimoteosConConteo(
    List<QueryDocumentSnapshot> timoteosDocs) async {
  List<Map<String, dynamic>> resultado = [];

  for (var timoteoDoc in timoteosDocs) {
    // Contar cuántos registros tiene asignados este timoteo
    final registrosAsignados = await FirebaseFirestore.instance
        .collection('registros')
        .where('timoteoAsignado', isEqualTo: timoteoDoc.id)
        .get();

    resultado.add({
      'doc': timoteoDoc,
      'cantidad': registrosAsignados.docs.length,
    });
  }

  // Ordenar: primero los que tienen menos asignados
  resultado
      .sort((a, b) => (a['cantidad'] as int).compareTo(b['cantidad'] as int));

  return resultado;
}
*/
// ============================================================
// FIN MÉTODO AUXILIAR COMENTADO
// ============================================================

//VER DETALLES DEL REGISTRO
  void _mostrarDetallesRegistro(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    // Definimos colores según los proporcionados en el segundo código
    final primaryTeal = Color(0xFF038C7F);
    final secondaryOrange = Color(0xFFFF5722);
    final accentGrey = Color(0xFF78909C);
    final backgroundGrey = Color(0xFFF5F5F5);

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

// ✅ FUNCIÓN CORREGIDA 1: Calcular edad con manejo robusto de null
    int? calcularEdadDesdeData(Map<String, dynamic> data) {
      try {
        DateTime? fechaNacimiento;

        if (data.containsKey('fechaNacimiento')) {
          var value = data['fechaNacimiento'];

          // ✅ VALIDACIÓN: Si es null, retornar null inmediatamente
          if (value == null) {
            return null;
          }

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
              try {
                fechaNacimiento = DateTime.parse(value);
              } catch (e) {
                print('⚠️ Error al parsear fecha: $e');
                return null;
              }
            }
          }

          // ✅ VALIDACIÓN ADICIONAL: Verificar que fechaNacimiento no sea null
          if (fechaNacimiento != null) {
            final hoy = DateTime.now();
            int edad = hoy.year - fechaNacimiento.year;

            // Ajustar si aún no ha cumplido años este año
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
        print('❌ Error en calcularEdadDesdeData: $e');
        return null;
      }
    }

// ✅ FUNCIÓN CORREGIDA 2: Calcular próximo cumpleaños con manejo robusto de null
    String? calcularProximoCumpleanosDesdeData(Map<String, dynamic> data) {
      try {
        DateTime? fechaNacimiento;

        if (data.containsKey('fechaNacimiento')) {
          var value = data['fechaNacimiento'];

          // ✅ VALIDACIÓN: Si es null, retornar null inmediatamente
          if (value == null) {
            return null;
          }

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
              try {
                fechaNacimiento = DateTime.parse(value);
              } catch (e) {
                print('⚠️ Error al parsear fecha: $e');
                return null;
              }
            }
          }

          // ✅ VALIDACIÓN ADICIONAL: Verificar que fechaNacimiento no sea null
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
              return 'En $diferencia días';
            } else if (diferencia <= 30) {
              return 'En $diferencia días';
            } else {
              final double mesesDouble = diferencia / 30;
              final int meses = mesesDouble.floor();
              if (meses == 1) {
                return 'En aproximadamente 1 mes';
              } else {
                return 'En aproximadamente $meses meses';
              }
            }
          }
        }
        return null;
      } catch (e) {
        print('❌ Error en calcularProximoCumpleanosDesdeData: $e');
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
          {
            'keys': [
              'descripcionOcupaciones', // AGREGADO: campo plural
              'descripcionOcupacion' // Campo singular existente
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
      // MODIFICACIÓN: Filtrar campos considerando múltiples keys posibles
      final camposConDatos = (seccion['campos'] as List).where((campo) {
        // Para campos con múltiples keys posibles
        if (campo.containsKey('keys')) {
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
          // Para campos con una sola key (lógica original)
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

          // MODIFICACIÓN: Obtener valor considerando múltiples keys posibles
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
            // Para campos con múltiples keys posibles
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
            // Para campos con una sola key (lógica original)
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

  @override
  Widget build(BuildContext context) {
    // Definimos los colores del segundo código
    final primaryTeal = Color(0xFF038C7F);
    final secondaryOrange = Color(0xFFFF5722);
    final accentGrey = Color(0xFF78909C);
    final backgroundGrey = Color(0xFFF5F5F5);

    return _PersonasAsignadasContent(
      coordinadorId: coordinadorId,
      primaryTeal: primaryTeal,
      secondaryOrange: secondaryOrange,
      accentGrey: accentGrey,
      backgroundGrey: backgroundGrey,
      onEditarRegistro: _editarRegistro,
      onMostrarDetalles: _mostrarDetallesRegistro,
      onRegistrarNuevo: _registrarNuevoMiembro,
      onAsignarTimoteo: _asignarATimoteo,
    );
  }

  dynamic obtenerValorCampoEdicion(Map<String, dynamic> data, String campo) {
    // Si el campo existe directamente, lo devolvemos (con validación null)
    if (data.containsKey(campo) && data[campo] != null) {
      return data[campo];
    }

    // ✅ CORRECCIÓN CRÍTICA: Detección especial para descripcionOcupacion
    if (campo == 'descripcionOcupacion') {
      // Buscar primero 'descripcionOcupacion', luego 'descripcionOcupaciones'
      if (data.containsKey('descripcionOcupacion') &&
          data['descripcionOcupacion'] != null) {
        return data['descripcionOcupacion'];
      } else if (data.containsKey('descripcionOcupaciones') &&
          data['descripcionOcupaciones'] != null) {
        return data['descripcionOcupaciones'];
      }
    }

    // Si no se encuentra el campo o es null, devolver null
    return null;
  }

//EDITAR EL DETALLE DEL REGISTRO

  void _editarRegistro(BuildContext context, DocumentSnapshot registro) {
    // Colores de la aplicación
    const Color primaryTeal = Color(0xFF1B998B);
    const Color secondaryOrange = Color(0xFFFF7E00);
    final Color lightTeal = primaryTeal.withOpacity(0.1);

    // Flag para rastrear si hay cambios sin guardar
    bool hayModificaciones = false;

    // ✅ NUEVO: FocusNodes para navegación entre campos
    final Map<String, FocusNode> focusNodes = {};

    // Función mejorada para obtener un valor seguro del documento
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
          fechaNacimiento = null; // ✅ ASEGURAR que quede null en caso de error
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

    // Inicializar controladores y FocusNodes
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

        // ✅ NUEVO: Crear FocusNode para cada campo
        focusNodes[key] = FocusNode();
      }
    });

    if (controllers['nombrePareja'] == null) {
      controllers['nombrePareja'] = TextEditingController();
      focusNodes['nombrePareja'] = FocusNode();
    }

    // ✅ NUEVO: Lista ordenada de campos para navegación
    final List<String> camposOrdenados = [
      'nombre',
      'apellido',
      'telefono',
      'direccion',
      'barrio',
      'nombrePareja',
      'ocupaciones',
      'descripcionOcupacion',
      'referenciaInvitacion',
      'observaciones',
      'estadoFonovisita',
      'observaciones2',
      'edad',
      'peticiones',
      'estadoProceso',
    ];

    // ✅ NUEVO: Función para ir al siguiente campo
    void _irAlSiguienteCampo(String campoActual) {
      final index = camposOrdenados.indexOf(campoActual);
      if (index != -1 && index < camposOrdenados.length - 1) {
        final siguienteCampo = camposOrdenados[index + 1];
        if (focusNodes.containsKey(siguienteCampo)) {
          focusNodes[siguienteCampo]?.requestFocus();
        }
      } else {
        FocusScope.of(context).unfocus();
      }
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
            child: child ?? const SizedBox.shrink(),
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

    // Función para mostrar diálogo de observaciones al desactivar
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
        return MediaQuery.removeViewInsets(
          context: dialogContext,
          removeBottom: true,
          child: StatefulBuilder(
            builder: (stateContext, setState) {
              return WillPopScope(
                onWillPop: () async {
                  final bool confirmar = await confirmarSalida();
                  return confirmar;
                },
                child: Dialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // ✅ RESPONSIVE: Calcular tamaños dinámicos
                      final mediaQuery = MediaQuery.of(dialogContext);
                      final screenWidth = mediaQuery.size.width;
                      final screenHeight = mediaQuery.size.height;
                      final bottomInset = mediaQuery.viewInsets.bottom;

                      final isVerySmallScreen = screenWidth < 360;
                      final isSmallScreen = screenWidth < 600;
                      final isMediumScreen =
                          screenWidth >= 600 && screenWidth < 900;

                      // ✅ Tamaños adaptativos mejorados
                      final horizontalPadding = isVerySmallScreen
                          ? 12.0
                          : (isSmallScreen
                              ? 16.0
                              : (isMediumScreen ? 20.0 : 24.0));
                      final verticalPadding = isVerySmallScreen
                          ? 12.0
                          : (isSmallScreen
                              ? 16.0
                              : (isMediumScreen ? 20.0 : 24.0));
                      final headerPadding = isVerySmallScreen
                          ? 14.0
                          : (isSmallScreen
                              ? 16.0
                              : (isMediumScreen ? 20.0 : 24.0));
                      final titleFontSize = isVerySmallScreen
                          ? 18.0
                          : (isSmallScreen
                              ? 20.0
                              : (isMediumScreen ? 22.0 : 24.0));
                      final labelFontSize = isVerySmallScreen
                          ? 13.0
                          : (isSmallScreen
                              ? 14.0
                              : (isMediumScreen ? 15.0 : 16.0));
                      final contentFontSize = isVerySmallScreen
                          ? 14.0
                          : (isSmallScreen
                              ? 15.0
                              : (isMediumScreen ? 16.0 : 17.0));
                      final buttonFontSize = isVerySmallScreen
                          ? 13.0
                          : (isSmallScreen
                              ? 14.0
                              : (isMediumScreen ? 15.0 : 16.0));
                      final iconSize = isVerySmallScreen
                          ? 20.0
                          : (isSmallScreen
                              ? 22.0
                              : (isMediumScreen ? 24.0 : 26.0));
                      final borderRadius = isVerySmallScreen
                          ? 10.0
                          : (isSmallScreen
                              ? 12.0
                              : (isMediumScreen ? 14.0 : 16.0));

                      final maxWidth = isVerySmallScreen
                          ? screenWidth * 0.95
                          : (isSmallScreen
                              ? 600.0
                              : (isMediumScreen ? 650.0 : 700.0));

                      return Container(
                        constraints: BoxConstraints(
                          maxWidth: maxWidth,
                          maxHeight: screenHeight *
                              0.85, // ✅ maxHeight en lugar de height
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // ✅ Encabezado RESPONSIVE
                            Container(
                              padding: EdgeInsets.all(headerPadding),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    primaryTeal,
                                    primaryTeal.withOpacity(0.85)
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(20),
                                  topRight: Radius.circular(20),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryTeal.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(
                                        isVerySmallScreen ? 6 : 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      Icons.edit_rounded,
                                      color: Colors.white,
                                      size: iconSize,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        FittedBox(
                                          fit: BoxFit.scaleDown,
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            'Editar Registro',
                                            style: GoogleFonts.poppins(
                                              fontSize: titleFontSize,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                            maxLines: 1,
                                          ),
                                        ),
                                        if (!isVerySmallScreen)
                                          FittedBox(
                                            fit: BoxFit.scaleDown,
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              'Modifica la información del miembro',
                                              style: GoogleFonts.poppins(
                                                fontSize: labelFontSize - 2,
                                                color: Colors.white
                                                    .withOpacity(0.9),
                                              ),
                                              maxLines: 1,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () async {
                                      focusNodes.values
                                          .forEach((fn) => fn.dispose());
                                      bool confirmar = await confirmarSalida();
                                      if (confirmar && dialogContext.mounted) {
                                        Navigator.pop(dialogContext);
                                      }
                                    },
                                    icon: Icon(Icons.close_rounded,
                                        color: Colors.white, size: iconSize),
                                    style: IconButton.styleFrom(
                                      backgroundColor:
                                          Colors.white.withOpacity(0.2),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10)),
                                      padding: EdgeInsets.all(
                                          isVerySmallScreen ? 6 : 8),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // ✅ CONTENIDO CON SCROLL + BOTONES AL FINAL
                            Expanded(
                              child: SingleChildScrollView(
                                keyboardDismissBehavior:
                                    ScrollViewKeyboardDismissBehavior.manual,
                                physics: ClampingScrollPhysics(),
                                padding: EdgeInsets.fromLTRB(
                                  horizontalPadding,
                                  horizontalPadding,
                                  horizontalPadding,
                                  horizontalPadding + bottomInset,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(height: verticalPadding * 0.5),

                                    // Información del registro
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Container(
                                            padding: EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color:
                                                  Colors.grey.withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      borderRadius),
                                              border: Border.all(
                                                color: Colors.grey
                                                    .withOpacity(0.3),
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(Icons.person,
                                                    color: Colors.grey[700],
                                                    size: iconSize * 0.8),
                                                SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    getNombreCompleto(),
                                                    style: GoogleFonts.poppins(
                                                      fontSize: labelFontSize,
                                                      color: Colors.grey[800],
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: verticalPadding),

                                    // ✅ CAMPOS DEL FORMULARIO CON NAVEGACIÓN
                                    ...camposDefinicion.entries.map((entry) {
                                      final fieldName = entry.key;
                                      final fieldData = entry.value;
                                      final controller = controllers[fieldName];
                                      final fieldIcon = fieldData['icon'] ??
                                          Icons.help_outline;
                                      final focusNode = focusNodes[fieldName];

                                      if (fieldName == 'estadoCivil') {
                                        return _buildDropdownFieldResponsive(
                                          label: 'Estado Civil',
                                          icon: fieldIcon,
                                          value: estadoCivilSeleccionado,
                                          items: opcionesEstadoCivil,
                                          primaryColor: primaryTeal,
                                          fontSize: contentFontSize,
                                          iconSize: iconSize,
                                          borderRadius: borderRadius,
                                          onChanged: (newValue) {
                                            if (newValue != null) {
                                              setState(() {
                                                estadoCivilSeleccionado =
                                                    newValue;
                                                hayModificaciones = true;
                                              });
                                            }
                                          },
                                        );
                                      } else if (fieldName == 'sexo') {
                                        return _buildDropdownFieldResponsive(
                                          label: 'Sexo',
                                          icon: fieldIcon,
                                          value: sexoSeleccionado,
                                          items: opcionesSexo,
                                          primaryColor: primaryTeal,
                                          fontSize: contentFontSize,
                                          iconSize: iconSize,
                                          borderRadius: borderRadius,
                                          onChanged: (newValue) {
                                            if (newValue != null) {
                                              setState(() {
                                                sexoSeleccionado = newValue;
                                                hayModificaciones = true;
                                              });
                                            }
                                          },
                                        );
                                      } else if (fieldName ==
                                          'fechaNacimiento') {
                                        return Column(
                                          children: [
                                            Container(
                                              margin: EdgeInsets.only(
                                                  bottom: verticalPadding),
                                              child: InkWell(
                                                onTap: () =>
                                                    _seleccionarFecha(setState),
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        borderRadius),
                                                child: Container(
                                                  padding: EdgeInsets.all(
                                                      horizontalPadding),
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey
                                                        .withOpacity(0.05),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            borderRadius),
                                                    border: Border.all(
                                                      color: primaryTeal
                                                          .withOpacity(0.3),
                                                      width: 1,
                                                    ),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      Container(
                                                        padding:
                                                            EdgeInsets.all(8),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: primaryTeal
                                                              .withOpacity(0.1),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(8),
                                                        ),
                                                        child: Icon(
                                                          fieldIcon,
                                                          color: primaryTeal,
                                                          size: iconSize * 0.8,
                                                        ),
                                                      ),
                                                      SizedBox(width: 12),
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text(
                                                              'Fecha de Nacimiento',
                                                              style: GoogleFonts
                                                                  .poppins(
                                                                fontSize:
                                                                    labelFontSize -
                                                                        2,
                                                                color: Colors
                                                                    .grey[600],
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                              ),
                                                              maxLines: 1,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                            ),
                                                            SizedBox(height: 4),
                                                            Text(
                                                              fechaNacimiento !=
                                                                      null
                                                                  ? '${fechaNacimiento!.day}/${fechaNacimiento!.month}/${fechaNacimiento!.year}'
                                                                  : 'Seleccionar fecha',
                                                              style: GoogleFonts
                                                                  .poppins(
                                                                fontSize:
                                                                    contentFontSize,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                                color: fechaNacimiento !=
                                                                        null
                                                                    ? Colors
                                                                        .black87
                                                                    : Colors.grey[
                                                                        500],
                                                              ),
                                                              maxLines: 1,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      Icon(
                                                        Icons
                                                            .keyboard_arrow_down,
                                                        color: Colors.grey[600],
                                                        size: iconSize,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                            if (fechaNacimiento != null)
                                              Container(
                                                margin: EdgeInsets.only(
                                                    bottom: verticalPadding),
                                                padding: EdgeInsets.all(
                                                    horizontalPadding),
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      Color(0xFF1B998B)
                                                          .withOpacity(0.1),
                                                      Color(0xFFFF7E00)
                                                          .withOpacity(0.1),
                                                    ],
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          borderRadius),
                                                  border: Border.all(
                                                    color: Color(0xFF1B998B)
                                                        .withOpacity(0.3),
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
                                                          padding:
                                                              EdgeInsets.all(8),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: Color(
                                                                    0xFF1B998B)
                                                                .withOpacity(
                                                                    0.2),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        8),
                                                          ),
                                                          child: Icon(
                                                            Icons.celebration,
                                                            color: Color(
                                                                0xFF1B998B),
                                                            size:
                                                                iconSize * 0.8,
                                                          ),
                                                        ),
                                                        SizedBox(width: 12),
                                                        Expanded(
                                                          child: Text(
                                                            'Información de Cumpleaños',
                                                            style: GoogleFonts
                                                                .poppins(
                                                              fontSize:
                                                                  labelFontSize,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color: Color(
                                                                  0xFF1B998B),
                                                            ),
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    SizedBox(height: 12),
                                                    isSmallScreen
                                                        ? Column(
                                                            children: [
                                                              Container(
                                                                width: double
                                                                    .infinity,
                                                                padding:
                                                                    EdgeInsets
                                                                        .all(
                                                                            12),
                                                                decoration:
                                                                    BoxDecoration(
                                                                  color: Colors
                                                                      .white
                                                                      .withOpacity(
                                                                          0.7),
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              8),
                                                                ),
                                                                child: Column(
                                                                  crossAxisAlignment:
                                                                      CrossAxisAlignment
                                                                          .start,
                                                                  children: [
                                                                    Text(
                                                                      'Edad Actual',
                                                                      style: GoogleFonts
                                                                          .poppins(
                                                                        fontSize:
                                                                            labelFontSize -
                                                                                2,
                                                                        color: Colors
                                                                            .grey[600],
                                                                        fontWeight:
                                                                            FontWeight.w500,
                                                                      ),
                                                                    ),
                                                                    Text(
                                                                      '${_calcularEdad(fechaNacimiento!)} años',
                                                                      style: GoogleFonts
                                                                          .poppins(
                                                                        fontSize:
                                                                            contentFontSize,
                                                                        fontWeight:
                                                                            FontWeight.bold,
                                                                        color: Color(
                                                                            0xFF1B998B),
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                              SizedBox(
                                                                  height: 12),
                                                              Container(
                                                                width: double
                                                                    .infinity,
                                                                padding:
                                                                    EdgeInsets
                                                                        .all(
                                                                            12),
                                                                decoration:
                                                                    BoxDecoration(
                                                                  color: Colors
                                                                      .white
                                                                      .withOpacity(
                                                                          0.7),
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              8),
                                                                ),
                                                                child: Column(
                                                                  crossAxisAlignment:
                                                                      CrossAxisAlignment
                                                                          .start,
                                                                  children: [
                                                                    Text(
                                                                      'Próximo Cumpleaños',
                                                                      style: GoogleFonts
                                                                          .poppins(
                                                                        fontSize:
                                                                            labelFontSize -
                                                                                2,
                                                                        color: Colors
                                                                            .grey[600],
                                                                        fontWeight:
                                                                            FontWeight.w500,
                                                                      ),
                                                                    ),
                                                                    Text(
                                                                      _calcularProximoCumpleanos(
                                                                          fechaNacimiento!),
                                                                      style: GoogleFonts
                                                                          .poppins(
                                                                        fontSize:
                                                                            labelFontSize,
                                                                        fontWeight:
                                                                            FontWeight.bold,
                                                                        color: Color(
                                                                            0xFFFF7E00),
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ],
                                                          )
                                                        : Row(
                                                            children: [
                                                              Expanded(
                                                                child:
                                                                    Container(
                                                                  padding:
                                                                      EdgeInsets
                                                                          .all(
                                                                              12),
                                                                  decoration:
                                                                      BoxDecoration(
                                                                    color: Colors
                                                                        .white
                                                                        .withOpacity(
                                                                            0.7),
                                                                    borderRadius:
                                                                        BorderRadius
                                                                            .circular(8),
                                                                  ),
                                                                  child: Column(
                                                                    crossAxisAlignment:
                                                                        CrossAxisAlignment
                                                                            .start,
                                                                    children: [
                                                                      Text(
                                                                        'Edad Actual',
                                                                        style: GoogleFonts
                                                                            .poppins(
                                                                          fontSize:
                                                                              labelFontSize - 2,
                                                                          color:
                                                                              Colors.grey[600],
                                                                          fontWeight:
                                                                              FontWeight.w500,
                                                                        ),
                                                                      ),
                                                                      Text(
                                                                        '${_calcularEdad(fechaNacimiento!)} años',
                                                                        style: GoogleFonts
                                                                            .poppins(
                                                                          fontSize:
                                                                              contentFontSize,
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
                                                              SizedBox(
                                                                  width: 12),
                                                              Expanded(
                                                                flex: 2,
                                                                child:
                                                                    Container(
                                                                  padding:
                                                                      EdgeInsets
                                                                          .all(
                                                                              12),
                                                                  decoration:
                                                                      BoxDecoration(
                                                                    color: Colors
                                                                        .white
                                                                        .withOpacity(
                                                                            0.7),
                                                                    borderRadius:
                                                                        BorderRadius
                                                                            .circular(8),
                                                                  ),
                                                                  child: Column(
                                                                    crossAxisAlignment:
                                                                        CrossAxisAlignment
                                                                            .start,
                                                                    children: [
                                                                      Text(
                                                                        'Próximo Cumpleaños',
                                                                        style: GoogleFonts
                                                                            .poppins(
                                                                          fontSize:
                                                                              labelFontSize - 2,
                                                                          color:
                                                                              Colors.grey[600],
                                                                          fontWeight:
                                                                              FontWeight.w500,
                                                                        ),
                                                                      ),
                                                                      Text(
                                                                        _calcularProximoCumpleanos(
                                                                            fechaNacimiento!),
                                                                        style: GoogleFonts
                                                                            .poppins(
                                                                          fontSize:
                                                                              labelFontSize,
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
                                        if (mostrarNombrePareja() &&
                                            controller != null) {
                                          return _buildAnimatedTextFieldResponsive(
                                            label: 'Nombre de Pareja',
                                            icon: fieldIcon,
                                            controller: controller,
                                            focusNode: focusNode!,
                                            primaryColor: primaryTeal,
                                            fontSize: contentFontSize,
                                            iconSize: iconSize,
                                            borderRadius: borderRadius,
                                            onChanged: (value) {
                                              hayModificaciones = true;
                                            },
                                            onSubmitted: (value) {
                                              _irAlSiguienteCampo(fieldName);
                                            },
                                          );
                                        } else {
                                          return SizedBox.shrink();
                                        }
                                      } else if (fieldName == 'estadoProceso') {
                                        return _buildAnimatedTextFieldConOpcionesResponsive(
                                          label: 'Estado del Proceso',
                                          icon: fieldIcon,
                                          controller: controller!,
                                          focusNode: focusNode!,
                                          primaryColor: primaryTeal,
                                          fontSize: contentFontSize,
                                          iconSize: iconSize,
                                          borderRadius: borderRadius,
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
                                          onSubmitted: (value) {
                                            _irAlSiguienteCampo(fieldName);
                                          },
                                        );
                                      } else if (controller != null &&
                                          focusNode != null) {
                                        return _buildAnimatedTextFieldResponsive(
                                          label: _formatFieldName(fieldName),
                                          icon: fieldIcon,
                                          controller: controller,
                                          focusNode: focusNode,
                                          primaryColor: primaryTeal,
                                          fontSize: contentFontSize,
                                          iconSize: iconSize,
                                          borderRadius: borderRadius,
                                          onChanged: (value) {
                                            hayModificaciones = true;
                                          },
                                          onSubmitted: (value) {
                                            _irAlSiguienteCampo(fieldName);
                                          },
                                        );
                                      } else {
                                        return SizedBox.shrink();
                                      }
                                    }).toList(),

                                    SizedBox(height: verticalPadding),
                                    Divider(
                                        color: primaryTeal.withOpacity(0.2),
                                        thickness: 1),
                                    SizedBox(height: verticalPadding),

                                    // ✅ BOTONES AL FINAL DEL SCROLL (NO FIJOS)

                                    isSmallScreen
                                        ? Column(
                                            children: [
                                              SizedBox(
                                                width: double.infinity,
                                                child: ElevatedButton.icon(
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        secondaryOrange,
                                                    foregroundColor:
                                                        Colors.white,
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                            vertical: 14),
                                                    shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                                borderRadius)),
                                                    elevation: 2,
                                                  ),
                                                  icon: Icon(Icons.save_rounded,
                                                      size: iconSize * 0.8),
                                                  label: Text('Guardar Cambios',
                                                      style: GoogleFonts.poppins(
                                                          fontSize:
                                                              buttonFontSize,
                                                          fontWeight:
                                                              FontWeight.bold)),
                                                  onPressed: () async {
                                                    try {
                                                      final Map<String, dynamic>
                                                          updateData = {};

                                                      // Recopilar datos de los campos
                                                      updateData[
                                                              'estadoCivil'] =
                                                          estadoCivilSeleccionado;
                                                      updateData['sexo'] =
                                                          sexoSeleccionado;

                                                      // ✅ CORRECCIÓN CRÍTICA: Manejo seguro de fecha de nacimiento
                                                      if (fechaNacimiento !=
                                                          null) {
                                                        updateData[
                                                                'fechaNacimiento'] =
                                                            Timestamp.fromDate(
                                                                fechaNacimiento!);
                                                      } else {
                                                        // ✅ Si no hay fecha, NO incluirla en la actualización
                                                        // Esto evita sobrescribir con null si ya existía una fecha
                                                        // updateData['fechaNacimiento'] = null; // ❌ NO hacer esto
                                                      }

                                                      controllers.forEach(
                                                          (key, controller) {
                                                        if (controller !=
                                                            null) {
                                                          final fieldType =
                                                              camposDefinicion[
                                                                  key]?['type'];
                                                          if (fieldType ==
                                                              'list') {
                                                            updateData[
                                                                key] = controller
                                                                    .text
                                                                    .isEmpty
                                                                ? []
                                                                : controller
                                                                    .text
                                                                    .split(',')
                                                                    .map((e) =>
                                                                        e.trim())
                                                                    .toList();
                                                          } else if (fieldType ==
                                                              'int') {
                                                            int? parsedValue =
                                                                int.tryParse(
                                                                    controller
                                                                        .text);
                                                            updateData[key] =
                                                                parsedValue ??
                                                                    0;
                                                          } else {
                                                            updateData[key] =
                                                                controller.text;
                                                          }
                                                        }
                                                      });

                                                      // Manejar campo descripcionOcupacion vs descripcionOcupaciones
                                                      final data =
                                                          registro.data();
                                                      if (data != null &&
                                                          data is Map<String,
                                                              dynamic>) {
                                                        if (data.containsKey(
                                                                'descripcionOcupaciones') &&
                                                            !data.containsKey(
                                                                'descripcionOcupacion')) {
                                                          if (updateData
                                                              .containsKey(
                                                                  'descripcionOcupacion')) {
                                                            updateData[
                                                                    'descripcionOcupaciones'] =
                                                                updateData[
                                                                    'descripcionOcupacion'];
                                                            updateData.remove(
                                                                'descripcionOcupacion');
                                                          }
                                                        }
                                                      }

                                                      if (FirebaseFirestore
                                                              .instance !=
                                                          null) {
                                                        // ✅ 1. ACTUALIZAR REGISTRO
                                                        await FirebaseFirestore
                                                            .instance
                                                            .collection(
                                                                'registros')
                                                            .doc(registro.id)
                                                            .update(updateData);

                                                        print(
                                                            '✅ Registro actualizado');

                                                        // ✅ 2. VERIFICAR SI HAY PERFIL SOCIAL ASOCIADO Y SINCRONIZARLO
                                                        final registroActualizado =
                                                            await FirebaseFirestore
                                                                .instance
                                                                .collection(
                                                                    'registros')
                                                                .doc(
                                                                    registro.id)
                                                                .get();

                                                        if (registroActualizado
                                                            .exists) {
                                                          final registroData =
                                                              registroActualizado
                                                                      .data()
                                                                  as Map<String,
                                                                      dynamic>?;
                                                          final perfilSocialId =
                                                              registroData?[
                                                                  'perfilSocialId'];

                                                          if (perfilSocialId !=
                                                                  null &&
                                                              perfilSocialId
                                                                  .toString()
                                                                  .trim()
                                                                  .isNotEmpty) {
                                                            try {
                                                              final perfilDoc = await FirebaseFirestore
                                                                  .instance
                                                                  .collection(
                                                                      'social_profiles')
                                                                  .doc(perfilSocialId
                                                                      .toString())
                                                                  .get();

                                                              if (perfilDoc
                                                                  .exists) {
                                                                print(
                                                                    '📝 Sincronizando con perfil social: $perfilSocialId');

                                                                // ✅ MAPEO COMPLETO (registro → perfil)
                                                                Map<String,
                                                                        dynamic>
                                                                    updateDataPerfil =
                                                                    {
                                                                  'name': updateData[
                                                                      'nombre'],
                                                                  'lastName':
                                                                      updateData[
                                                                          'apellido'],
                                                                  'phone':
                                                                      updateData[
                                                                          'telefono'],
                                                                  'address':
                                                                      updateData[
                                                                          'direccion'],
                                                                  'city': updateData[
                                                                      'barrio'],
                                                                  'age':
                                                                      updateData[
                                                                          'edad'],
                                                                  'gender':
                                                                      updateData[
                                                                          'sexo'],
                                                                  'prayerRequest':
                                                                      updateData[
                                                                          'peticiones'],
                                                                  'estadoFonovisita':
                                                                      updateData[
                                                                          'estadoFonovisita'],
                                                                  'observaciones':
                                                                      updateData[
                                                                          'observaciones'],
                                                                  'estadoProceso':
                                                                      updateData[
                                                                          'estadoProceso'],
                                                                };

                                                                // Manejar descripcionOcupacion
                                                                if (updateData
                                                                    .containsKey(
                                                                        'descripcionOcupacion')) {
                                                                  updateDataPerfil[
                                                                          'descripcionOcupacion'] =
                                                                      updateData[
                                                                          'descripcionOcupacion'];
                                                                } else if (updateData
                                                                    .containsKey(
                                                                        'descripcionOcupaciones')) {
                                                                  updateDataPerfil[
                                                                          'descripcionOcupacion'] =
                                                                      updateData[
                                                                          'descripcionOcupaciones'];
                                                                }

                                                                // Remover valores null
                                                                updateDataPerfil
                                                                    .removeWhere((key,
                                                                            value) =>
                                                                        value ==
                                                                        null);

                                                                await FirebaseFirestore
                                                                    .instance
                                                                    .collection(
                                                                        'social_profiles')
                                                                    .doc(perfilSocialId
                                                                        .toString())
                                                                    .update(
                                                                        updateDataPerfil);

                                                                print(
                                                                    '✅ Perfil social sincronizado');
                                                              } else {
                                                                print(
                                                                    '⚠️ El perfil social no existe: $perfilSocialId');

                                                                // Limpiar referencia inválida
                                                                await FirebaseFirestore
                                                                    .instance
                                                                    .collection(
                                                                        'registros')
                                                                    .doc(
                                                                        registro
                                                                            .id)
                                                                    .update({
                                                                  'perfilSocialId':
                                                                      null
                                                                });
                                                              }
                                                            } catch (e) {
                                                              print(
                                                                  '⚠️ Error al sincronizar perfil social: $e');
                                                            }
                                                          } else {
                                                            print(
                                                                'ℹ️ No hay perfil social asociado para sincronizar');
                                                          }
                                                        }

                                                        // ✅ Limpiar recursos
                                                        focusNodes.values
                                                            .forEach((fn) =>
                                                                fn.dispose());

                                                        if (dialogContext
                                                            .mounted) {
                                                          Navigator.pop(
                                                              dialogContext);
                                                        }

                                                        if (context.mounted) {
                                                          ScaffoldMessenger.of(
                                                                  context)
                                                              .showSnackBar(
                                                            SnackBar(
                                                              content: Row(
                                                                children: const [
                                                                  Icon(
                                                                      Icons
                                                                          .check_circle,
                                                                      color: Colors
                                                                          .white),
                                                                  SizedBox(
                                                                      width:
                                                                          12),
                                                                  Text(
                                                                    'Registro actualizado correctamente',
                                                                    style: TextStyle(
                                                                        fontSize:
                                                                            16),
                                                                  ),
                                                                ],
                                                              ),
                                                              backgroundColor:
                                                                  Colors.green,
                                                              behavior:
                                                                  SnackBarBehavior
                                                                      .floating,
                                                              shape:
                                                                  RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            10),
                                                              ),
                                                              margin: EdgeInsets
                                                                  .all(12),
                                                              padding: EdgeInsets
                                                                  .symmetric(
                                                                      vertical:
                                                                          14,
                                                                      horizontal:
                                                                          20),
                                                              duration:
                                                                  Duration(
                                                                      seconds:
                                                                          3),
                                                            ),
                                                          );
                                                        }
                                                      } else {
                                                        throw Exception(
                                                            "No se pudo conectar con Firestore");
                                                      }
                                                    } catch (e) {
                                                      focusNodes.values.forEach(
                                                          (fn) => fn.dispose());

                                                      if (dialogContext
                                                          .mounted) {
                                                        Navigator.pop(
                                                            dialogContext);
                                                      }
                                                      if (context.mounted) {
                                                        ScaffoldMessenger.of(
                                                                context)
                                                            .showSnackBar(
                                                          SnackBar(
                                                            content: Row(
                                                              children: [
                                                                Icon(
                                                                    Icons.error,
                                                                    color: Colors
                                                                        .white),
                                                                SizedBox(
                                                                    width: 12),
                                                                Expanded(
                                                                  child: Text(
                                                                    'Error al actualizar: ${e.toString()}',
                                                                    style: TextStyle(
                                                                        fontSize:
                                                                            16),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                            backgroundColor:
                                                                Colors.red,
                                                            behavior:
                                                                SnackBarBehavior
                                                                    .floating,
                                                            shape:
                                                                RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          10),
                                                            ),
                                                            margin:
                                                                EdgeInsets.all(
                                                                    12),
                                                            padding: EdgeInsets
                                                                .symmetric(
                                                                    vertical:
                                                                        14,
                                                                    horizontal:
                                                                        20),
                                                            duration: Duration(
                                                                seconds: 5),
                                                          ),
                                                        );
                                                      }
                                                    }
                                                  },
                                                ),
                                              ),
                                              SizedBox(height: 12),
                                              SizedBox(
                                                width: double.infinity,
                                                child: TextButton.icon(
                                                  onPressed: () async {
                                                    focusNodes.values.forEach(
                                                        (fn) => fn.dispose());

                                                    bool confirmar =
                                                        await confirmarSalida();
                                                    if (confirmar &&
                                                        dialogContext.mounted) {
                                                      Navigator.pop(
                                                          dialogContext);
                                                    }
                                                  },
                                                  icon: Icon(
                                                      Icons.cancel_rounded,
                                                      size: iconSize * 0.8),
                                                  label: Text('Cancelar',
                                                      style: GoogleFonts.poppins(
                                                          fontSize:
                                                              buttonFontSize,
                                                          fontWeight:
                                                              FontWeight.w600)),
                                                  style: TextButton.styleFrom(
                                                    foregroundColor:
                                                        Colors.grey[700],
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                            vertical: 14),
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              borderRadius),
                                                      side: BorderSide(
                                                          color: Colors
                                                              .grey.shade300,
                                                          width: 2),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                        : Row(
                                            children: [
                                              Expanded(
                                                child: TextButton.icon(
                                                  onPressed: () async {
                                                    focusNodes.values.forEach(
                                                        (fn) => fn.dispose());

                                                    bool confirmar =
                                                        await confirmarSalida();
                                                    if (confirmar &&
                                                        dialogContext.mounted) {
                                                      Navigator.pop(
                                                          dialogContext);
                                                    }
                                                  },
                                                  icon: Icon(
                                                      Icons.cancel_rounded,
                                                      size: iconSize * 0.8),
                                                  label: Text('Cancelar',
                                                      style: GoogleFonts.poppins(
                                                          fontSize:
                                                              buttonFontSize,
                                                          fontWeight:
                                                              FontWeight.w600)),
                                                  style: TextButton.styleFrom(
                                                    foregroundColor:
                                                        Colors.grey[700],
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                            vertical: 16),
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              borderRadius),
                                                      side: BorderSide(
                                                          color: Colors
                                                              .grey.shade300,
                                                          width: 2),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              SizedBox(width: 16),
                                              Expanded(
                                                flex: 2,
                                                child: ElevatedButton.icon(
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        secondaryOrange,
                                                    foregroundColor:
                                                        Colors.white,
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                            vertical: 16),
                                                    shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                                borderRadius)),
                                                    elevation: 2,
                                                  ),
                                                  icon: Icon(Icons.save_rounded,
                                                      size: iconSize * 0.8),
                                                  label: Text('Guardar Cambios',
                                                      style: GoogleFonts.poppins(
                                                          fontSize:
                                                              buttonFontSize,
                                                          fontWeight:
                                                              FontWeight.bold)),
                                                  onPressed: () async {
                                                    try {
                                                      final Map<String, dynamic>
                                                          updateData = {};

                                                      updateData[
                                                              'estadoCivil'] =
                                                          estadoCivilSeleccionado;
                                                      updateData['sexo'] =
                                                          sexoSeleccionado;

                                                      if (fechaNacimiento !=
                                                          null) {
                                                        updateData[
                                                                'fechaNacimiento'] =
                                                            Timestamp.fromDate(
                                                                fechaNacimiento!);
                                                      }

                                                      controllers.forEach(
                                                          (key, controller) {
                                                        if (controller !=
                                                            null) {
                                                          final fieldType =
                                                              camposDefinicion[
                                                                  key]?['type'];
                                                          if (fieldType ==
                                                              'list') {
                                                            updateData[
                                                                key] = controller
                                                                    .text
                                                                    .isEmpty
                                                                ? []
                                                                : controller
                                                                    .text
                                                                    .split(',')
                                                                    .map((e) =>
                                                                        e.trim())
                                                                    .toList();
                                                          } else if (fieldType ==
                                                              'int') {
                                                            int? parsedValue =
                                                                int.tryParse(
                                                                    controller
                                                                        .text);
                                                            updateData[key] =
                                                                parsedValue ??
                                                                    0;
                                                          } else {
                                                            updateData[key] =
                                                                controller.text;
                                                          }
                                                        }
                                                      });

                                                      final data =
                                                          registro.data();
                                                      if (data != null &&
                                                          data is Map<String,
                                                              dynamic>) {
                                                        if (data.containsKey(
                                                                'descripcionOcupaciones') &&
                                                            !data.containsKey(
                                                                'descripcionOcupacion')) {
                                                          if (updateData
                                                              .containsKey(
                                                                  'descripcionOcupacion')) {
                                                            updateData[
                                                                    'descripcionOcupaciones'] =
                                                                updateData[
                                                                    'descripcionOcupacion'];
                                                            updateData.remove(
                                                                'descripcionOcupacion');
                                                          }
                                                        }
                                                      }

                                                      if (FirebaseFirestore
                                                              .instance !=
                                                          null) {
                                                        await FirebaseFirestore
                                                            .instance
                                                            .collection(
                                                                'registros')
                                                            .doc(registro.id)
                                                            .update(updateData);

                                                        print(
                                                            '✅ Registro actualizado');

                                                        final registroActualizado =
                                                            await FirebaseFirestore
                                                                .instance
                                                                .collection(
                                                                    'registros')
                                                                .doc(
                                                                    registro.id)
                                                                .get();

                                                        if (registroActualizado
                                                            .exists) {
                                                          final registroData =
                                                              registroActualizado
                                                                      .data()
                                                                  as Map<String,
                                                                      dynamic>?;
                                                          final perfilSocialId =
                                                              registroData?[
                                                                  'perfilSocialId'];

                                                          if (perfilSocialId !=
                                                                  null &&
                                                              perfilSocialId
                                                                  .toString()
                                                                  .trim()
                                                                  .isNotEmpty) {
                                                            try {
                                                              final perfilDoc = await FirebaseFirestore
                                                                  .instance
                                                                  .collection(
                                                                      'social_profiles')
                                                                  .doc(perfilSocialId
                                                                      .toString())
                                                                  .get();

                                                              if (perfilDoc
                                                                  .exists) {
                                                                print(
                                                                    '📝 Sincronizando con perfil social: $perfilSocialId');

                                                                Map<String,
                                                                        dynamic>
                                                                    updateDataPerfil =
                                                                    {
                                                                  'name': updateData[
                                                                      'nombre'],
                                                                  'lastName':
                                                                      updateData[
                                                                          'apellido'],
                                                                  'phone':
                                                                      updateData[
                                                                          'telefono'],
                                                                  'address':
                                                                      updateData[
                                                                          'direccion'],
                                                                  'city': updateData[
                                                                      'barrio'],
                                                                  'age':
                                                                      updateData[
                                                                          'edad'],
                                                                  'gender':
                                                                      updateData[
                                                                          'sexo'],
                                                                  'prayerRequest':
                                                                      updateData[
                                                                          'peticiones'],
                                                                  'estadoFonovisita':
                                                                      updateData[
                                                                          'estadoFonovisita'],
                                                                  'observaciones':
                                                                      updateData[
                                                                          'observaciones'],
                                                                  'estadoProceso':
                                                                      updateData[
                                                                          'estadoProceso'],
                                                                };

                                                                if (updateData
                                                                    .containsKey(
                                                                        'descripcionOcupacion')) {
                                                                  updateDataPerfil[
                                                                          'descripcionOcupacion'] =
                                                                      updateData[
                                                                          'descripcionOcupacion'];
                                                                } else if (updateData
                                                                    .containsKey(
                                                                        'descripcionOcupaciones')) {
                                                                  updateDataPerfil[
                                                                          'descripcionOcupacion'] =
                                                                      updateData[
                                                                          'descripcionOcupaciones'];
                                                                }

                                                                updateDataPerfil
                                                                    .removeWhere((key,
                                                                            value) =>
                                                                        value ==
                                                                        null);

                                                                await FirebaseFirestore
                                                                    .instance
                                                                    .collection(
                                                                        'social_profiles')
                                                                    .doc(perfilSocialId
                                                                        .toString())
                                                                    .update(
                                                                        updateDataPerfil);

                                                                print(
                                                                    '✅ Perfil social sincronizado');
                                                              } else {
                                                                print(
                                                                    '⚠️ El perfil social no existe: $perfilSocialId');

                                                                await FirebaseFirestore
                                                                    .instance
                                                                    .collection(
                                                                        'registros')
                                                                    .doc(
                                                                        registro
                                                                            .id)
                                                                    .update({
                                                                  'perfilSocialId':
                                                                      null
                                                                });
                                                              }
                                                            } catch (e) {
                                                              print(
                                                                  '⚠️ Error al sincronizar perfil social: $e');
                                                            }
                                                          } else {
                                                            print(
                                                                'ℹ️ No hay perfil social asociado para sincronizar');
                                                          }
                                                        }

                                                        focusNodes.values
                                                            .forEach((fn) =>
                                                                fn.dispose());

                                                        if (dialogContext
                                                            .mounted) {
                                                          Navigator.pop(
                                                              dialogContext);
                                                        }

                                                        if (context.mounted) {
                                                          ScaffoldMessenger.of(
                                                                  context)
                                                              .showSnackBar(
                                                            SnackBar(
                                                              content: Row(
                                                                children: const [
                                                                  Icon(
                                                                      Icons
                                                                          .check_circle,
                                                                      color: Colors
                                                                          .white),
                                                                  SizedBox(
                                                                      width:
                                                                          12),
                                                                  Text(
                                                                    'Registro actualizado correctamente',
                                                                    style: TextStyle(
                                                                        fontSize:
                                                                            16),
                                                                  ),
                                                                ],
                                                              ),
                                                              backgroundColor:
                                                                  Colors.green,
                                                              behavior:
                                                                  SnackBarBehavior
                                                                      .floating,
                                                              shape:
                                                                  RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            10),
                                                              ),
                                                              margin: EdgeInsets
                                                                  .all(12),
                                                              padding: EdgeInsets
                                                                  .symmetric(
                                                                      vertical:
                                                                          14,
                                                                      horizontal:
                                                                          20),
                                                              duration:
                                                                  Duration(
                                                                      seconds:
                                                                          3),
                                                            ),
                                                          );
                                                        }
                                                      } else {
                                                        throw Exception(
                                                            "No se pudo conectar con Firestore");
                                                      }
                                                    } catch (e) {
                                                      focusNodes.values.forEach(
                                                          (fn) => fn.dispose());

                                                      if (dialogContext
                                                          .mounted) {
                                                        Navigator.pop(
                                                            dialogContext);
                                                      }
                                                      if (context.mounted) {
                                                        ScaffoldMessenger.of(
                                                                context)
                                                            .showSnackBar(
                                                          SnackBar(
                                                            content: Row(
                                                              children: [
                                                                Icon(
                                                                    Icons.error,
                                                                    color: Colors
                                                                        .white),
                                                                SizedBox(
                                                                    width: 12),
                                                                Expanded(
                                                                  child: Text(
                                                                    'Error al actualizar: ${e.toString()}',
                                                                    style: TextStyle(
                                                                        fontSize:
                                                                            16),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                            backgroundColor:
                                                                Colors.red,
                                                            behavior:
                                                                SnackBarBehavior
                                                                    .floating,
                                                            shape:
                                                                RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          10),
                                                            ),
                                                            margin:
                                                                EdgeInsets.all(
                                                                    12),
                                                            padding: EdgeInsets
                                                                .symmetric(
                                                                    vertical:
                                                                        14,
                                                                    horizontal:
                                                                        20),
                                                            duration: Duration(
                                                                seconds: 5),
                                                          ),
                                                        );
                                                      }
                                                    }
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),

                                    SizedBox(height: verticalPadding),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

// ✅ MÉTODOS AUXILIARES RESPONSIVE ACTUALIZADOS
  Widget _buildAnimatedTextFieldResponsive({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required FocusNode focusNode,
    required Color primaryColor,
    required double fontSize,
    required double iconSize,
    required double borderRadius,
    required Function(String) onChanged,
    required Function(String) onSubmitted,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.0),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        child: Builder(
          builder: (fieldContext) {
            return TextField(
              controller: controller,
              focusNode: focusNode,
              textInputAction: TextInputAction.next,
              onTap: () {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Scrollable.ensureVisible(
                    fieldContext,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    alignment: 0.2,
                  );
                });
              },
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              style: GoogleFonts.poppins(fontSize: fontSize),
              decoration: InputDecoration(
                labelText: label,
                labelStyle: GoogleFonts.poppins(
                  color: primaryColor.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                  fontSize: fontSize - 2,
                ),
                prefixIcon: Container(
                  margin: EdgeInsets.all(10),
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: primaryColor, size: iconSize * 0.8),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(borderRadius),
                  borderSide: BorderSide(color: primaryColor.withOpacity(0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(borderRadius),
                  borderSide: BorderSide(color: primaryColor.withOpacity(0.5)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(borderRadius),
                  borderSide: BorderSide(color: primaryColor, width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAnimatedTextFieldConOpcionesResponsive({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required FocusNode focusNode,
    required Color primaryColor,
    required double fontSize,
    required double iconSize,
    required double borderRadius,
    required List<String> opciones,
    required Function(String) onChanged,
    required Function(String) onSubmitted,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedContainer(
            duration: Duration(milliseconds: 300),
            child: Builder(
              builder: (fieldContext) {
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  textInputAction: TextInputAction.next,
                  onTap: () {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      Scrollable.ensureVisible(
                        fieldContext,
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        alignment: 0.2,
                      );
                    });
                  },
                  onChanged: onChanged,
                  onSubmitted: onSubmitted,
                  style: GoogleFonts.poppins(fontSize: fontSize),
                  decoration: InputDecoration(
                    labelText: label,
                    labelStyle: GoogleFonts.poppins(
                      color: primaryColor.withOpacity(0.8),
                      fontWeight: FontWeight.w500,
                      fontSize: fontSize - 2,
                    ),
                    prefixIcon: Container(
                      margin: EdgeInsets.all(10),
                      padding: EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child:
                          Icon(icon, color: primaryColor, size: iconSize * 0.8),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(borderRadius),
                      borderSide:
                          BorderSide(color: primaryColor.withOpacity(0.3)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(borderRadius),
                      borderSide:
                          BorderSide(color: primaryColor.withOpacity(0.5)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(borderRadius),
                      borderSide: BorderSide(color: primaryColor, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(borderRadius),
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
                      size: iconSize * 0.6,
                      color: primaryColor,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Opciones rápidas:',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500,
                        color: primaryColor,
                        fontSize: fontSize - 3,
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
                        style: GoogleFonts.poppins(
                          color: primaryColor,
                          fontWeight: FontWeight.w500,
                          fontSize: fontSize - 4,
                        ),
                      ),
                      onPressed: () {
                        controller.text = opcion;
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

  Widget _buildDropdownFieldResponsive({
    required String label,
    required IconData icon,
    required String? value,
    required List<String> items,
    required Color primaryColor,
    required double fontSize,
    required double iconSize,
    required double borderRadius,
    required Function(String?) onChanged,
  }) {
    final String safeValue = value ?? (items.isNotEmpty ? items[0] : '');
    return Padding(
      padding: EdgeInsets.only(bottom: 16.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(color: primaryColor.withOpacity(0.5)),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
          child: Row(
            children: [
              Container(
                margin: EdgeInsets.only(right: 12),
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: primaryColor, size: iconSize * 0.8),
              ),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: items.contains(safeValue)
                        ? safeValue
                        : (items.isNotEmpty ? items[0] : null),
                    hint: Text(
                      'Seleccionar $label',
                      style: GoogleFonts.poppins(
                          color: Colors.grey, fontSize: fontSize),
                    ),
                    icon: Icon(Icons.arrow_drop_down,
                        color: primaryColor, size: iconSize),
                    isExpanded: true,
                    onChanged: onChanged,
                    style: GoogleFonts.poppins(
                      color: Colors.black87,
                      fontSize: fontSize,
                    ),
                    dropdownColor: Colors.white,
                    items: items.map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
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

  Future<void> _registrarNuevoMiembro(BuildContext context) async {
    // Colores del diseño original
    final primaryTeal = Color(0xFF038C7F);
    final secondaryOrange = Color(0xFFFF5722);
    final accentGrey = Color(0xFF78909C);
    final backgroundGrey = Color(0xFFF5F5F5);

    final _formKey = GlobalKey<FormState>();

    // Listas de opciones
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

    // Variables para almacenar datos del formulario
    String nombre = '';
    String apellido = '';
    String telefono = '';
    String? sexo;
    int edad = 0;
    String direccion = '';
    String barrio = '';
    String? estadoCivil;
    String? nombrePareja;
    List<String> ocupacionesSeleccionadas = [];
    String descripcionOcupaciones = '';
    bool? tieneHijos;
    String referenciaInvitacion = '';
    String? observaciones;
    DateTime? fechaAsignacionTribu;

    // Obtener datos del coordinador y tribu
    String tribuId = '';
    String categoriaTribu = '';
    String nombreTribu = '';
    String ministerioAsignado = '';
    String estadoProceso = '';

    try {
      final coordinadorSnapshot = await FirebaseFirestore.instance
          .collection('coordinadores')
          .doc(coordinadorId)
          .get();

      if (coordinadorSnapshot.exists) {
        final coordinadorData =
            coordinadorSnapshot.data() as Map<String, dynamic>;

        tribuId = coordinadorData['tribuId'] ?? '';
        String? tribuDirecta =
            coordinadorData['nombreTribu'] ?? coordinadorData['tribu'];

        if (tribuId.isNotEmpty) {
          final tribuSnapshot = await FirebaseFirestore.instance
              .collection('tribus')
              .doc(tribuId)
              .get();

          if (tribuSnapshot.exists) {
            final tribuData = tribuSnapshot.data() as Map<String, dynamic>;
            nombreTribu = tribuData['nombreTribu'] ??
                tribuData['nombre'] ??
                'Desconocida';
            categoriaTribu =
                tribuData['categoriaTribu'] ?? tribuData['categoria'] ?? '';
            ministerioAsignado = tribuData['ministerioAsignado'] ??
                tribuData['ministerio'] ??
                tribuData['categoria'] ??
                _determinarMinisterio(nombreTribu);
          } else {
            nombreTribu = tribuDirecta ?? 'Tribu no encontrada';
          }
        } else if (tribuDirecta != null && tribuDirecta.isNotEmpty) {
          nombreTribu = tribuDirecta;
        } else {
          nombreTribu = 'Sin tribu asignada';
        }
      } else {
        nombreTribu = 'Coordinador no encontrado';
      }
    } catch (e) {
      print('Error obteniendo datos del coordinador: $e');
      nombreTribu = 'Error al obtener tribu';
    }
    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: false,
      isDismissible: true,
      builder: (BuildContext dialogContext) {
        return _RegistroNuevoMiembroStateful(
          coordinadorId: coordinadorId,
          tribuId: tribuId,
          categoriaTribu: categoriaTribu,
          nombreTribu: nombreTribu,
          ministerioAsignado: ministerioAsignado,
          primaryTeal: primaryTeal,
          secondaryOrange: secondaryOrange,
          accentGrey: accentGrey,
          backgroundGrey: backgroundGrey,
        );
      },
    );
  }

// Función para determinar el ministerio basado en el nombre de la tribu
  String _determinarMinisterio(String tribuNombre) {
    if (tribuNombre.contains('Juvenil')) return 'Ministerio Juvenil';
    if (tribuNombre.contains('Damas')) return 'Ministerio de Damas';
    if (tribuNombre.contains('Caballeros')) return 'Ministerio de Caballeros';
    return 'Otro';
  }

// Función para guardar registro en Firebase
  Future<void> _guardarRegistroEnFirebase(BuildContext context,
      Map<String, dynamic> registro, String tribuId) async {
    final primaryTeal = Color(0xFF038C7F);

    // Mostrar pantalla de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: primaryTeal),
              SizedBox(height: 16),
              Text(
                'Guardando registro...',
                style: TextStyle(
                  color: primaryTeal,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      await FirebaseFirestore.instance.collection('registros').add(registro);

      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // Cierra el loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Registro guardado correctamente'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: EdgeInsets.all(12),
            padding: EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            duration: Duration(seconds: 3),
          ),
        );
        Navigator.pop(context); // Cierra el diálogo del formulario
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // Cierra el loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text('Error al guardar el registro: $e'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: EdgeInsets.all(12),
            padding: EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

// Widget para campos de texto
  Widget _buildTextField(
    String label,
    IconData icon,
    Function(String) onChanged, {
    bool isRequired = true,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final primaryTeal = Color(0xFF038C7F);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        onChanged: onChanged,
        keyboardType: keyboardType,
        validator: isRequired
            ? (value) =>
                value == null || value.isEmpty ? 'Campo obligatorio' : null
            : null,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: primaryTeal.withOpacity(0.8),
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(icon, color: primaryTeal),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primaryTeal.withOpacity(0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primaryTeal.withOpacity(0.5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primaryTeal, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        style: TextStyle(fontSize: 16),
      ),
    );
  }

// Widget para dropdowns mejorado
  Widget _buildDropdown(
    String label,
    List<String> items,
    String? selectedValue,
    Function(String?) onChanged,
  ) {
    final primaryTeal = Color(0xFF038C7F);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: DropdownButtonFormField<String>(
        value: selectedValue,
        hint: Text(
          'Seleccionar $label',
          style: TextStyle(
            color: primaryTeal.withOpacity(0.6),
            fontWeight: FontWeight.w400,
          ),
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: primaryTeal.withOpacity(0.8),
            fontWeight: FontWeight.w500,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primaryTeal.withOpacity(0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primaryTeal.withOpacity(0.5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primaryTeal, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        items: items.map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          );
        }).toList(),
        onChanged: onChanged,
        validator: (value) => value == null || value.isEmpty
            ? 'Debe seleccionar una opción'
            : null,
        isExpanded: true,
        icon: Icon(
          Icons.arrow_drop_down,
          color: primaryTeal,
        ),
        style: TextStyle(
          fontSize: 16,
          color: Colors.black87,
        ),
        dropdownColor: Colors.white,
      ),
    );
  }

// Widgets auxiliares para el formulario de registro
  Widget _buildRegistroTextField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required Color primaryColor,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
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
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        style: TextStyle(fontSize: 16),
      ),
    );
  }

  Widget _buildRegistroDropdown({
    required String label,
    required IconData icon,
    required String value,
    required List<String> items,
    required Color primaryColor,
    required Function(String?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: primaryColor.withOpacity(0.5)),
          color: Colors.white,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          child: Row(
            children: [
              Icon(icon, color: primaryColor),
              SizedBox(width: 16),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: value,
                    icon: Icon(Icons.arrow_drop_down, color: primaryColor),
                    isExpanded: true,
                    onChanged: onChanged,
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 16,
                    ),
                    dropdownColor: Colors.white,
                    items: items.map<DropdownMenuItem<String>>((String item) {
                      return DropdownMenuItem<String>(
                        value: item,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(item),
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
}

// Nueva clase Stateful para manejar el estado del buscador correctamente
class _PersonasAsignadasContent extends StatefulWidget {
  final String coordinadorId;
  final Color primaryTeal;
  final Color secondaryOrange;
  final Color accentGrey;
  final Color backgroundGrey;
  final Function(BuildContext, DocumentSnapshot) onEditarRegistro;
  final Function(BuildContext, Map<String, dynamic>) onMostrarDetalles;
  final Function(BuildContext) onRegistrarNuevo;
  final Function(BuildContext, DocumentSnapshot) onAsignarTimoteo;

  const _PersonasAsignadasContent({
    Key? key,
    required this.coordinadorId,
    required this.primaryTeal,
    required this.secondaryOrange,
    required this.accentGrey,
    required this.backgroundGrey,
    required this.onEditarRegistro,
    required this.onMostrarDetalles,
    required this.onRegistrarNuevo,
    required this.onAsignarTimoteo,
  }) : super(key: key);

  @override
  _PersonasAsignadasContentState createState() =>
      _PersonasAsignadasContentState();
}

class _PersonasAsignadasContentState extends State<_PersonasAsignadasContent> {
  // Controlador para el buscador
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isAsignadosExpanded = false;
  bool _isNoAsignadosExpanded = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Función para detectar si es un registro reciente
  bool esRegistroReciente(DocumentSnapshot doc) {
    try {
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) return false;

      DateTime? fechaMasReciente;

      final fechaAsignacionCoordinador = data['fechaAsignacionCoordinador'];
      if (fechaAsignacionCoordinador is Timestamp) {
        fechaMasReciente = fechaAsignacionCoordinador.toDate();
      }

      final fechaAsignacionTribu = data['fechaAsignacionTribu'];
      if (fechaAsignacionTribu is Timestamp) {
        DateTime fechaTribu = fechaAsignacionTribu.toDate();
        if (fechaMasReciente == null || fechaTribu.isAfter(fechaMasReciente)) {
          fechaMasReciente = fechaTribu;
        }
      }

      if (fechaMasReciente == null) return false;

      final diferenciaDias = DateTime.now().difference(fechaMasReciente).inDays;
      return diferenciaDias >= 0 && diferenciaDias <= 13;
    } catch (e) {
      print('Error en esRegistroReciente: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // ============================================================
    // ✅ DETECTAR TAMAÑO DE PANTALLA PARA RESPONSIVIDAD
    // ============================================================
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isVerySmallScreen = screenWidth < 360;
    final isSmallScreen = screenWidth < 600;

    return Stack(
      children: [
        Container(
          color: widget.backgroundGrey,
          child: Column(
            children: [
              // ============================================================
              // CONTENIDO PRINCIPAL CON SCROLL
              // ============================================================
              Expanded(
                child: StreamBuilder(
                  stream: FirebaseFirestore.instance
                      .collection('registros')
                      .where('coordinadorAsignado',
                          isEqualTo: widget.coordinadorId)
                      .snapshots(),
                  builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                    final List<QueryDocumentSnapshot> allDocs =
                        snapshot.hasData ? snapshot.data!.docs : [];

                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline,
                                size: 48, color: Colors.red),
                            SizedBox(height: 16),
                            Text('Error al cargar datos'),
                            TextButton(
                              onPressed: () => setState(() {}),
                              child: Text('Reintentar'),
                            ),
                          ],
                        ),
                      );
                    }

                    if (allDocs.isEmpty &&
                        snapshot.connectionState != ConnectionState.waiting) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_off,
                                size: 64, color: widget.accentGrey),
                            SizedBox(height: 16),
                            Text(
                              'No hay personas registradas',
                              style: TextStyle(
                                  fontSize: 18,
                                  color: widget.accentGrey,
                                  fontWeight: FontWeight.w500),
                            ),
                            SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: () => widget.onRegistrarNuevo(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: widget.primaryTeal,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 16),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                elevation: 3,
                              ),
                              icon: Icon(Icons.person_add, size: 20),
                              label: Text('Registrar Primer Miembro',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      );
                    }

                    String searchText = _searchQuery.toLowerCase();
                    allDocs.sort((a, b) {
                      bool aEsReciente = esRegistroReciente(a);
                      bool bEsReciente = esRegistroReciente(b);
                      if (aEsReciente == bEsReciente) {
                        final dataA = a.data() as Map<String, dynamic>?;
                        final dataB = b.data() as Map<String, dynamic>?;
                        final fechaA =
                            (dataA?['fechaAsignacionCoordinador'] as Timestamp?)
                                    ?.toDate() ??
                                DateTime(2000);
                        final fechaB =
                            (dataB?['fechaAsignacionCoordinador'] as Timestamp?)
                                    ?.toDate() ??
                                DateTime(2000);
                        return fechaB.compareTo(fechaA);
                      }
                      return (bEsReciente ? 1 : 0) - (aEsReciente ? 1 : 0);
                    });

                    var filteredDocs = searchText.isEmpty
                        ? allDocs
                        : allDocs.where((doc) {
                            try {
                              final nombre = (doc.data()
                                          as Map<String, dynamic>?)?['nombre']
                                      ?.toString()
                                      .toLowerCase() ??
                                  '';
                              final apellido = (doc.data()
                                          as Map<String, dynamic>?)?['apellido']
                                      ?.toString()
                                      .toLowerCase() ??
                                  '';
                              final nombreCompleto = '$nombre $apellido';
                              return nombreCompleto.contains(searchText);
                            } catch (e) {
                              return false;
                            }
                          }).toList();

                    final asignados = filteredDocs.where((doc) {
                      try {
                        return doc.get('timoteoAsignado') != null;
                      } catch (e) {
                        return false;
                      }
                    }).toList();

                    final noAsignados = filteredDocs.where((doc) {
                      try {
                        return doc.get('timoteoAsignado') == null;
                      } catch (e) {
                        return true;
                      }
                    }).toList();

                    return CustomScrollView(
                      slivers: [
                        // Header con título y descripción (NO FIJO)
                        SliverToBoxAdapter(
                          child: Container(
                            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                            color: Colors.white,
                            child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: widget.primaryTeal.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.assignment_ind,
                                    color: widget.primaryTeal,
                                    size: 24,
                                  ),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Personas Asignadas',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: widget.primaryTeal,
                                        ),
                                      ),
                                      Text(
                                        'Administra las personas asignadas a tu grupo',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Divider
                        SliverToBoxAdapter(
                          child: Divider(height: 1),
                        ),

                        // Buscador (NO FIJO)
                        SliverToBoxAdapter(
                          child: Container(
                            color: widget.backgroundGrey,
                            padding: EdgeInsets.all(16),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final screenWidth =
                                    MediaQuery.of(context).size.width;
                                final isVerySmall = screenWidth < 360;

                                return Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(
                                        isVerySmall ? 10 : 12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 10,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: TextField(
                                    controller: _searchController,
                                    onChanged: (value) {
                                      setState(() {
                                        _searchQuery = value;
                                        if (value.isNotEmpty) {
                                          _isAsignadosExpanded = true;
                                          _isNoAsignadosExpanded = true;
                                        }
                                      });
                                    },
                                    style: TextStyle(
                                      fontSize: isVerySmall ? 13 : 15,
                                      color: Colors.black87,
                                    ),
                                    decoration: InputDecoration(
                                      hintText:
                                          'Buscar por nombre o apellido...',
                                      hintStyle: TextStyle(
                                        fontSize: isVerySmall ? 12 : 14,
                                        color: Colors.grey[400],
                                      ),
                                      prefixIcon: Container(
                                        margin:
                                            EdgeInsets.all(isVerySmall ? 6 : 8),
                                        padding:
                                            EdgeInsets.all(isVerySmall ? 4 : 6),
                                        decoration: BoxDecoration(
                                          color: widget.primaryTeal
                                              .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          Icons.search,
                                          color: widget.primaryTeal,
                                          size: isVerySmall ? 18 : 20,
                                        ),
                                      ),
                                      suffixIcon: _searchQuery.isNotEmpty
                                          ? IconButton(
                                              icon: Icon(
                                                Icons.clear,
                                                color: widget.accentGrey,
                                                size: isVerySmall ? 18 : 20,
                                              ),
                                              onPressed: () {
                                                setState(() {
                                                  _searchController.clear();
                                                  _searchQuery = '';
                                                });
                                              },
                                            )
                                          : null,
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: isVerySmall ? 12 : 16,
                                        vertical: isVerySmall ? 12 : 14,
                                      ),
                                      isDense: true,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),

                        // Badge de resultados
                        if (_searchQuery.isNotEmpty)
                          SliverToBoxAdapter(
                            child: Container(
                              color: widget.backgroundGrey,
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final screenWidth =
                                      MediaQuery.of(context).size.width;
                                  final isVerySmall = screenWidth < 360;

                                  return Container(
                                    margin: EdgeInsets.only(bottom: 16),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isVerySmall ? 10 : 12,
                                      vertical: isVerySmall ? 6 : 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          widget.primaryTeal.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(
                                          isVerySmall ? 16 : 20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.filter_alt_outlined,
                                          size: isVerySmall ? 14 : 16,
                                          color: widget.primaryTeal,
                                        ),
                                        SizedBox(width: isVerySmall ? 4 : 6),
                                        Flexible(
                                          child: Text(
                                            'Mostrando ${filteredDocs.length} de ${allDocs.length} registros',
                                            style: TextStyle(
                                              color: widget.primaryTeal,
                                              fontWeight: FontWeight.w500,
                                              fontSize: isVerySmall ? 11 : 13,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),

                        // Resto del contenido
                        SliverToBoxAdapter(
                          child: Container(
                            color: widget.backgroundGrey,
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              children: [
                                if (snapshot.connectionState ==
                                        ConnectionState.waiting &&
                                    allDocs.isNotEmpty)
                                  Container(
                                    padding: EdgeInsets.all(8),
                                    margin: EdgeInsets.only(bottom: 12),
                                    decoration: BoxDecoration(
                                      color:
                                          widget.primaryTeal.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    widget.primaryTeal),
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Text('Actualizando...',
                                            style: TextStyle(
                                                color: widget.primaryTeal,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500)),
                                      ],
                                    ),
                                  ),

                                if (allDocs.isNotEmpty)
                                  _buildContadorPersonas(
                                      allDocs.length, allDocs),

                                if (noAsignados.isNotEmpty) ...[
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _isNoAsignadosExpanded =
                                            !_isNoAsignadosExpanded;
                                      });
                                    },
                                    child: _buildExpandableHeader(
                                      'Personas por asignar (${noAsignados.length})',
                                      Icons.person_add_alt,
                                      widget.secondaryOrange,
                                      _isNoAsignadosExpanded,
                                    ),
                                  ),
                                  if (_isNoAsignadosExpanded)
                                    ...noAsignados
                                        .map((registro) => _buildPersonCard(
                                            context, registro,
                                            isAssigned: false,
                                            esReciente:
                                                esRegistroReciente(registro)))
                                        .toList(),
                                  SizedBox(height: 24),
                                ],

                                if (asignados.isNotEmpty) ...[
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _isAsignadosExpanded =
                                            !_isAsignadosExpanded;
                                      });
                                    },
                                    child: _buildExpandableHeader(
                                      'Personas asignadas (${asignados.length})',
                                      Icons.people,
                                      widget.primaryTeal,
                                      _isAsignadosExpanded,
                                    ),
                                  ),
                                  if (_isAsignadosExpanded)
                                    ...asignados
                                        .map((registro) => _buildPersonCard(
                                            context, registro,
                                            isAssigned: true,
                                            esReciente:
                                                esRegistroReciente(registro)))
                                        .toList(),
                                ],

                                // ✅ Espacio para el FAB (responsive)
                                SizedBox(
                                    height: isVerySmallScreen
                                        ? 80
                                        : (isSmallScreen ? 90 : 100)),
                              ],
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
        ),

        // ============================================================
        // ✅ BOTÓN FLOTANTE RESPONSIVE (SIEMPRE VISIBLE)
        // ============================================================
        Positioned(
          bottom: isVerySmallScreen ? 16 : (isSmallScreen ? 20 : 24),
          right: isVerySmallScreen ? 16 : (isSmallScreen ? 20 : 24),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(isVerySmallScreen ? 14 : 16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  widget.secondaryOrange,
                  widget.secondaryOrange.withOpacity(0.8),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.secondaryOrange.withOpacity(0.4),
                  blurRadius: isVerySmallScreen ? 12 : 16,
                  offset: Offset(0, isVerySmallScreen ? 4 : 6),
                  spreadRadius: isVerySmallScreen ? 1 : 2,
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => widget.onRegistrarNuevo(context),
                borderRadius:
                    BorderRadius.circular(isVerySmallScreen ? 14 : 16),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal:
                        isVerySmallScreen ? 16 : (isSmallScreen ? 20 : 24),
                    vertical:
                        isVerySmallScreen ? 12 : (isSmallScreen ? 14 : 16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: EdgeInsets.all(isVerySmallScreen ? 6 : 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.person_add_rounded,
                          color: Colors.white,
                          size: isVerySmallScreen
                              ? 18
                              : (isSmallScreen ? 20 : 22),
                        ),
                      ),
                      SizedBox(width: isVerySmallScreen ? 8 : 12),
                      Text(
                        'Registrar',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isVerySmallScreen
                              ? 14
                              : (isSmallScreen ? 15 : 16),
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Widgets auxiliares
  Widget _buildContadorPersonas(int total, List<DocumentSnapshot> docs) {
    final registrosRecientes =
        docs.where((doc) => esRegistroReciente(doc)).length;

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [widget.primaryTeal, widget.primaryTeal.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: widget.primaryTeal.withOpacity(0.2),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.people_alt_outlined,
              color: Colors.white,
              size: 28,
            ),
          ),
          SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total de Personas',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 4),
              Text(
                '$total',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildCounterBadge(
                'Asignados',
                docs.where((doc) {
                  try {
                    return doc.get('timoteoAsignado') != null;
                  } catch (e) {
                    return false;
                  }
                }).length,
                widget.primaryTeal,
                Colors.white,
              ),
              SizedBox(height: 8),
              _buildCounterBadge(
                'Por asignar',
                docs.where((doc) {
                  try {
                    return doc.get('timoteoAsignado') == null;
                  } catch (e) {
                    return true;
                  }
                }).length,
                widget.secondaryOrange,
                Colors.white,
              ),
              SizedBox(height: 8),
              AnimatedContainer(
                duration: Duration(milliseconds: 300),
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: registrosRecientes > 0
                      ? Colors.orange.withOpacity(0.3)
                      : Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: registrosRecientes > 0
                        ? Colors.orange.withOpacity(0.5)
                        : Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Nuevos',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                    SizedBox(width: 6),
                    Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: registrosRecientes > 0
                            ? Colors.orange.withOpacity(0.4)
                            : Colors.grey.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: registrosRecientes > 0
                          ? Icon(
                              Icons.new_releases,
                              color: Colors.white,
                              size: 12,
                            )
                          : Text(
                              '$registrosRecientes',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExpandableHeader(
    String title,
    IconData icon,
    Color color,
    bool isExpanded,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: isExpanded ? 16 : 8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Spacer(),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              title.contains('por asignar') ? 'Pendientes' : 'Activos',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(width: 8),
          Icon(
            isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
            color: color,
          ),
        ],
      ),
    );
  }

  Widget _buildCounterBadge(
      String label, int count, Color color, Color textColor) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: textColor.withOpacity(0.9),
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
          SizedBox(width: 6),
          Container(
            padding: EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Text(
              '$count',
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonCard(
    BuildContext context,
    DocumentSnapshot registro, {
    required bool isAssigned,
    required bool esReciente,
  }) {
    final data = registro.data() as Map<String, dynamic>;

    String obtenerTextoTiempo() {
      DateTime? fechaMasReciente;
      String tipoAsignacion = '';

      final fechaCoordinador =
          (data['fechaAsignacionCoordinador'] as Timestamp?)?.toDate();
      if (fechaCoordinador != null) {
        fechaMasReciente = fechaCoordinador;
        tipoAsignacion = 'coordinador';
      }

      final fechaTribu = (data['fechaAsignacionTribu'] as Timestamp?)?.toDate();
      if (fechaTribu != null) {
        if (fechaMasReciente == null || fechaTribu.isAfter(fechaMasReciente)) {
          fechaMasReciente = fechaTribu;
          tipoAsignacion = 'tribu';
        }
      }

      if (fechaMasReciente == null) return '';

      final diasTranscurridos =
          DateTime.now().difference(fechaMasReciente).inDays;
      final diasRestantes = 14 - diasTranscurridos;

      String accion = tipoAsignacion == 'coordinador'
          ? 'Asignado a coordinador'
          : 'Asignado a tribu';

      if (diasTranscurridos == 0) {
        return '$accion hoy';
      } else if (diasTranscurridos == 1) {
        return '$accion ayer';
      } else if (diasRestantes > 0) {
        return 'Hace $diasTranscurridos días (${diasRestantes}d restantes)';
      } else {
        return 'Hace $diasTranscurridos días';
      }
    }

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: esReciente
              ? [
                  Color(0xFFFF6B35).withOpacity(0.15),
                  Color(0xFFFF8C42).withOpacity(0.08),
                ]
              : [
                  Colors.white,
                  Colors.grey.shade50,
                ],
        ),
        border: Border.all(
          color: esReciente
              ? Color(0xFFFF6B35).withOpacity(0.4)
              : widget.primaryTeal.withOpacity(0.15),
          width: esReciente ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: esReciente
                ? Color(0xFFFF6B35).withOpacity(0.15)
                : widget.primaryTeal.withOpacity(0.08),
            blurRadius: esReciente ? 12 : 8,
            offset: Offset(0, esReciente ? 6 : 3),
            spreadRadius: esReciente ? 1 : 0,
          ),
        ],
      ),
      child: Stack(
        children: [
          if (esReciente)
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFF4757), Color(0xFFFF3838)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFFFF4757).withOpacity(0.3),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.fiber_new, color: Colors.white, size: 12),
                    SizedBox(width: 4),
                    Text(
                      'NUEVO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: esReciente
                              ? [Color(0xFFFF6B35), Color(0xFFFF8C42)]
                              : isAssigned
                                  ? [
                                      widget.primaryTeal,
                                      widget.primaryTeal.withOpacity(0.8)
                                    ]
                                  : [
                                      widget.secondaryOrange,
                                      widget.secondaryOrange.withOpacity(0.8)
                                    ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (esReciente
                                    ? Color(0xFFFF6B35)
                                    : isAssigned
                                        ? widget.primaryTeal
                                        : widget.secondaryOrange)
                                .withOpacity(0.3),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        backgroundColor: Colors.transparent,
                        radius: 28,
                        child: Text(
                          '${registro.get('nombre')[0]}${registro.get('apellido')[0]}',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${registro.get('nombre')} ${registro.get('apellido')}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: esReciente
                                  ? Color(0xFFFF6B35)
                                  : Colors.black87,
                            ),
                          ),
                          SizedBox(height: 6),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: (esReciente
                                      ? Color(0xFFFF6B35)
                                      : widget.primaryTeal)
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.phone,
                                  size: 14,
                                  color: esReciente
                                      ? Color(0xFFFF6B35)
                                      : widget.primaryTeal,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  registro.get('telefono'),
                                  style: TextStyle(
                                    color: esReciente
                                        ? Color(0xFFFF6B35)
                                        : widget.primaryTeal,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (esReciente)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.green.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.schedule,
                                      size: 12,
                                      color: Colors.green.shade700,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      obtenerTextoTiempo(),
                                      style: TextStyle(
                                        color: Colors.green.shade700,
                                        fontSize: 11,
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
                if (isAssigned) ...[
                  Container(
                    margin: EdgeInsets.symmetric(vertical: 16),
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          (esReciente ? Color(0xFFFF6B35) : widget.primaryTeal)
                              .withOpacity(0.3),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:
                          (esReciente ? Color(0xFFFF6B35) : widget.primaryTeal)
                              .withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: (esReciente
                                ? Color(0xFFFF6B35)
                                : widget.primaryTeal)
                            .withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 18,
                          color: esReciente
                              ? Color(0xFFFF6B35)
                              : widget.primaryTeal,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Asignado a: ',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            registro.get('nombreTimoteo'),
                            style: TextStyle(
                              color: esReciente
                                  ? Color(0xFFFF6B35)
                                  : widget.primaryTeal,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                SizedBox(height: 20),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildEnhancedActionButton(
                        icon: Icons.edit_outlined,
                        label: 'Editar',
                        color:
                            esReciente ? Color(0xFFFF6B35) : widget.accentGrey,
                        onPressed: () =>
                            widget.onEditarRegistro(context, registro),
                      ),
                      SizedBox(width: 10),
                      _buildEnhancedActionButton(
                        icon: Icons.visibility_outlined,
                        label: 'Ver',
                        color:
                            esReciente ? Color(0xFFFF6B35) : widget.primaryTeal,
                        onPressed: () => widget.onMostrarDetalles(
                          context,
                          registro.data() as Map<String, dynamic>,
                        ),
                      ),
                      SizedBox(width: 10),
                      if (!isAssigned)
                        _buildEnhancedActionButton(
                          icon: Icons.person_add,
                          label: 'Asignar',
                          color: widget.secondaryOrange,
                          onPressed: () =>
                              widget.onAsignarTimoteo(context, registro),
                        )
                      else
                        _buildEnhancedActionButton(
                          icon: Icons.person_remove,
                          label: 'Desasignar',
                          color: Colors.red.shade400,
                          onPressed: () async {
                            try {
                              await FirebaseFirestore.instance
                                  .collection('registros')
                                  .doc(registro.id)
                                  .update({
                                'timoteoAsignado': null,
                                'nombreTimoteo': null,
                                'fechaAsignacion': null,
                              });
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'Registro desasignado exitosamente'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'Error al desasignar el registro: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      SizedBox(width: 10),
                      Container(
                        decoration: BoxDecoration(
                          color: (esReciente
                                  ? Color(0xFFFF6B35)
                                  : widget.primaryTeal)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: (esReciente
                                    ? Color(0xFFFF6B35)
                                    : widget.primaryTeal)
                                .withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.copy,
                            color: esReciente
                                ? Color(0xFFFF6B35)
                                : widget.primaryTeal,
                            size: 20,
                          ),
                          tooltip: 'Copiar teléfono',
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(text: registro.get('telefono')),
                            );
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content:
                                      Text('Teléfono copiado al portapapeles'),
                                  duration: Duration(seconds: 1),
                                  backgroundColor: esReciente
                                      ? Color(0xFFFF6B35)
                                      : widget.primaryTeal,
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
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        icon: Icon(icon, size: 16),
        label: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 0,
        ),
        onPressed: onPressed,
      ),
    );
  }
}

// CLASE AUXILIAR PARA EVITAR RECONSTRUCCIÓN COMPLETA
class _RegistroNuevoMiembroModal extends StatefulWidget {
  final BuildContext dialogContext;
  final Color backgroundGrey;
  final Color primaryTeal;
  final String nombreTribu;
  final GlobalKey<FormState> formKey;
  final Map<String, TextEditingController> controllers;
  final Map<String, FocusNode> focusNodes;
  final ScrollController scrollController;
  final Map<String, GlobalKey> fieldKeys;
  final List<String> estadosCiviles;
  final List<String> ocupaciones;
  final String? sexo;
  final String? estadoCivil;
  final String? nombrePareja;
  final List<String> ocupacionesSeleccionadas;
  final bool? tieneHijos;
  final DateTime? fechaAsignacionTribu;
  final String estadoProceso;
  final Color accentGrey;
  final Color secondaryOrange;
  final Function(String?) onSexoChanged;
  final Function(String?) onEstadoCivilChanged;
  final Function(List<String>) onOcupacionesChanged;
  final Function(bool?) onTieneHijosChanged;
  final Function(DateTime?) onFechaAsignacionChanged;
  final Function(String) onEstadoProcesoChanged;
  final VoidCallback onGuardar;
  final VoidCallback onCancelar;

  const _RegistroNuevoMiembroModal({
    Key? key,
    required this.dialogContext,
    required this.backgroundGrey,
    required this.primaryTeal,
    required this.nombreTribu,
    required this.formKey,
    required this.controllers,
    required this.focusNodes,
    required this.scrollController,
    required this.fieldKeys,
    required this.estadosCiviles,
    required this.ocupaciones,
    required this.sexo,
    required this.estadoCivil,
    required this.nombrePareja,
    required this.ocupacionesSeleccionadas,
    required this.tieneHijos,
    required this.fechaAsignacionTribu,
    required this.estadoProceso,
    required this.accentGrey,
    required this.secondaryOrange,
    required this.onSexoChanged,
    required this.onEstadoCivilChanged,
    required this.onOcupacionesChanged,
    required this.onTieneHijosChanged,
    required this.onFechaAsignacionChanged,
    required this.onEstadoProcesoChanged,
    required this.onGuardar,
    required this.onCancelar,
  }) : super(key: key);

  @override
  _RegistroNuevoMiembroModalState createState() =>
      _RegistroNuevoMiembroModalState();
}

class _RegistroNuevoMiembroModalState
    extends State<_RegistroNuevoMiembroModal> {
  late String? _sexoLocal;
  late String? _estadoCivilLocal;
  late List<String> _ocupacionesLocal;
  late bool? _tieneHijosLocal;
  late DateTime? _fechaLocal;
  late String _estadoProcesoLocal;

  @override
  void initState() {
    super.initState();
    _sexoLocal = widget.sexo;
    _estadoCivilLocal = widget.estadoCivil;
    _ocupacionesLocal = List.from(widget.ocupacionesSeleccionadas);
    _tieneHijosLocal = widget.tieneHijos;
    _fechaLocal = widget.fechaAsignacionTribu;
    _estadoProcesoLocal = widget.estadoProceso;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(widget.dialogContext).size.height * 0.95,
      decoration: BoxDecoration(
        color: widget.backgroundGrey,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // ENCABEZADO FIJO
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  widget.primaryTeal,
                  widget.primaryTeal.withOpacity(0.8)
                ],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child:
                        Icon(Icons.person_add, color: Colors.white, size: 24),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Registrar Nuevo Miembro',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        if (widget.nombreTribu.isNotEmpty)
                          Text(
                            'Tribu: ${widget.nombreTribu}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: widget.onCancelar,
                      borderRadius: BorderRadius.circular(50),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Icon(Icons.close, color: Colors.white, size: 24),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // CONTENIDO SCROLLEABLE
          Expanded(
            child: SingleChildScrollView(
              controller: widget.scrollController,
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom:
                    MediaQuery.of(widget.dialogContext).viewInsets.bottom + 20,
              ),
              physics: const ClampingScrollPhysics(),
              child: Form(
                key: widget.formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Información Personal',
                        Icons.person_outline, widget.primaryTeal, false),
                    _buildResponsiveTextField(
                        'Nombre',
                        Icons.person,
                        widget.controllers['nombre']!,
                        widget.focusNodes['nombre']!,
                        (value) {},
                        nextFocus: widget.focusNodes['apellido'],
                        context: widget.dialogContext,
                        fieldKey: widget.fieldKeys['nombre']),
                    _buildResponsiveTextField(
                        'Apellido',
                        Icons.person_outline,
                        widget.controllers['apellido']!,
                        widget.focusNodes['apellido']!,
                        (value) {},
                        nextFocus: widget.focusNodes['telefono'],
                        context: widget.dialogContext,
                        fieldKey: widget.fieldKeys['apellido']),
                    _buildResponsiveTextField(
                        'Teléfono',
                        Icons.phone,
                        widget.controllers['telefono']!,
                        widget.focusNodes['telefono']!,
                        (value) {},
                        nextFocus: widget.focusNodes['edad'],
                        keyboardType: TextInputType.phone,
                        context: widget.dialogContext,
                        fieldKey: widget.fieldKeys['telefono']),
                    _buildDropdown(
                        'Sexo', ['Masculino', 'Femenino'], _sexoLocal, (value) {
                      setState(() => _sexoLocal = value);
                      widget.onSexoChanged(value);
                    }),
                    _buildResponsiveTextField(
                        'Edad',
                        Icons.cake,
                        widget.controllers['edad']!,
                        widget.focusNodes['edad']!,
                        (value) {},
                        keyboardType: TextInputType.number,
                        nextFocus: widget.focusNodes['direccion'],
                        context: widget.dialogContext,
                        fieldKey: widget.fieldKeys['edad']),
                    SizedBox(height: 16),
                    _buildSectionTitle('Ubicación', Icons.location_on_outlined,
                        widget.primaryTeal, false),
                    _buildResponsiveTextField(
                        'Dirección',
                        Icons.location_on,
                        widget.controllers['direccion']!,
                        widget.focusNodes['direccion']!,
                        (value) {},
                        nextFocus: widget.focusNodes['barrio'],
                        context: widget.dialogContext,
                        fieldKey: widget.fieldKeys['direccion']),
                    _buildResponsiveTextField(
                        'Barrio',
                        Icons.home,
                        widget.controllers['barrio']!,
                        widget.focusNodes['barrio']!,
                        (value) {},
                        context: widget.dialogContext,
                        fieldKey: widget.fieldKeys['barrio']),
                    SizedBox(height: 16),
                    _buildSectionTitle('Estado Civil y Familia',
                        Icons.family_restroom, widget.primaryTeal, false),
                    _buildDropdown('Estado Civil', widget.estadosCiviles,
                        _estadoCivilLocal, (value) {
                      setState(() => _estadoCivilLocal = value);
                      widget.onEstadoCivilChanged(value);
                    }),
                    if (_estadoCivilLocal == 'Casado(a)' ||
                        _estadoCivilLocal == 'Unión Libre')
                      _buildResponsiveTextField(
                          'Nombre de la Pareja',
                          Icons.favorite,
                          widget.controllers['nombrePareja']!,
                          widget.focusNodes['nombrePareja']!,
                          (value) {},
                          context: widget.dialogContext,
                          fieldKey: widget.fieldKeys['nombrePareja']),
                    _buildDropdown(
                        'Tiene Hijos',
                        ['Sí', 'No'],
                        _tieneHijosLocal == null
                            ? null
                            : (_tieneHijosLocal! ? 'Sí' : 'No'), (value) {
                      setState(() => _tieneHijosLocal = (value == 'Sí'));
                      widget.onTieneHijosChanged(_tieneHijosLocal);
                    }),
                    SizedBox(height: 16),
                    _buildSectionTitle('Ocupación', Icons.work_outline,
                        widget.primaryTeal, false),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Ocupaciones',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: widget.primaryTeal,
                                fontSize: 16)),
                        SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: widget.ocupaciones.map((ocupacion) {
                            final isSelected =
                                _ocupacionesLocal.contains(ocupacion);
                            return FilterChip(
                              label: Text(ocupacion),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    _ocupacionesLocal.add(ocupacion);
                                  } else {
                                    _ocupacionesLocal.remove(ocupacion);
                                  }
                                });
                                widget.onOcupacionesChanged(_ocupacionesLocal);
                              },
                              selectedColor:
                                  widget.primaryTeal.withOpacity(0.2),
                              checkmarkColor: widget.primaryTeal,
                              backgroundColor: Colors.white,
                              side: BorderSide(
                                  color: isSelected
                                      ? widget.primaryTeal
                                      : Colors.grey.withOpacity(0.5)),
                              labelStyle: TextStyle(
                                  color: isSelected
                                      ? widget.primaryTeal
                                      : Colors.black87,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal),
                            );
                          }).toList(),
                        ),
                        if (_ocupacionesLocal.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: _buildResponsiveTextField(
                                'Descripción de Ocupaciones',
                                Icons.work_outline,
                                widget.controllers['descripcionOcupaciones']!,
                                widget.focusNodes['descripcionOcupaciones']!,
                                (value) {},
                                isRequired: false,
                                context: widget.dialogContext,
                                fieldKey:
                                    widget.fieldKeys['descripcionOcupaciones']),
                          ),
                      ],
                    ),
                    SizedBox(height: 16),
                    _buildSectionTitle('Información Ministerial',
                        Icons.groups_outlined, widget.primaryTeal, false),
                    _buildResponsiveTextField(
                        'Referencia de Invitación',
                        Icons.link,
                        widget.controllers['referenciaInvitacion']!,
                        widget.focusNodes['referenciaInvitacion']!,
                        (value) {},
                        nextFocus: widget.focusNodes['observaciones'],
                        context: widget.dialogContext,
                        fieldKey: widget.fieldKeys['referenciaInvitacion']),
                    _buildResponsiveTextField(
                        'Observaciones',
                        Icons.note,
                        widget.controllers['observaciones']!,
                        widget.focusNodes['observaciones']!,
                        (value) {},
                        isRequired: false,
                        nextFocus: widget.focusNodes['estadoProceso'],
                        context: widget.dialogContext,
                        fieldKey: widget.fieldKeys['observaciones']),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildResponsiveTextField(
                            'Estado del Proceso',
                            Icons.track_changes_outlined,
                            widget.controllers['estadoProceso']!,
                            widget.focusNodes['estadoProceso']!,
                            (value) {},
                            isRequired: false,
                            context: widget.dialogContext,
                            fieldKey: widget.fieldKeys['estadoProceso']),
                        SizedBox(height: 8),
                        Text('Opciones rápidas:',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: widget.primaryTeal,
                                fontSize: 14)),
                        SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            'Pendiente',
                            'Discipulado 1',
                            'Discipulado 2',
                            'Discipulado 3',
                            'Consolidación',
                            'Estudio Bíblico',
                            'Escuela de Líderes'
                          ].map((estado) {
                            final isSelected = _estadoProcesoLocal == estado;
                            return FilterChip(
                              label: Text(estado),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  _estadoProcesoLocal = selected ? estado : '';
                                  widget.controllers['estadoProceso']!.text =
                                      _estadoProcesoLocal;
                                });
                                widget.onEstadoProcesoChanged(
                                    _estadoProcesoLocal);
                              },
                              selectedColor:
                                  widget.primaryTeal.withOpacity(0.2),
                              checkmarkColor: widget.primaryTeal,
                              backgroundColor: Colors.white,
                              side: BorderSide(
                                  color: isSelected
                                      ? widget.primaryTeal
                                      : Colors.grey.withOpacity(0.5)),
                              labelStyle: TextStyle(
                                  color: isSelected
                                      ? widget.primaryTeal
                                      : Colors.black87,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    _buildResponsiveDateField(
                        'Fecha de Asignación de la Tribu',
                        Icons.calendar_today,
                        _fechaLocal,
                        widget.primaryTeal,
                        widget.secondaryOrange, (pickedDate) {
                      setState(() => _fechaLocal = pickedDate);
                      widget.onFechaAsignacionChanged(pickedDate);
                    }, widget.dialogContext),
                    SizedBox(height: 16),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: widget.primaryTeal.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: widget.primaryTeal.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: widget.primaryTeal, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                                'Este miembro será asignado automáticamente al coordinador.',
                                style: TextStyle(
                                    color: widget.primaryTeal,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500)),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton.icon(
                            onPressed: widget.onCancelar,
                            icon: Icon(Icons.cancel_outlined,
                                color: widget.accentGrey),
                            label: Text('Cancelar',
                                style: TextStyle(
                                    color: widget.accentGrey,
                                    fontWeight: FontWeight.w500)),
                            style: TextButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12))),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: widget.secondaryOrange,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                elevation: 3),
                            icon: Icon(Icons.save_outlined),
                            label: Text('Registrar',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            onPressed: widget.onGuardar,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(
      String title, IconData icon, Color color, bool isSmall) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, color: color, size: isSmall ? 18 : 20),
          SizedBox(width: 8),
          Flexible(
              child: Text(title,
                  style: TextStyle(
                      fontSize: isSmall ? 16 : 18,
                      fontWeight: FontWeight.bold,
                      color: color),
                  overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  Widget _buildResponsiveTextField(
    String label,
    IconData icon,
    TextEditingController controller,
    FocusNode focusNode,
    Function(String) onChanged, {
    bool isRequired = true,
    TextInputType keyboardType = TextInputType.text,
    FocusNode? nextFocus,
    VoidCallback? onFieldFocus,
    required BuildContext context,
    GlobalKey? fieldKey,
  }) {
    final primaryTeal = Color(0xFF038C7F);
    final isSmallScreen = MediaQuery.of(context).size.width < 360;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Container(
        key: fieldKey,
        child: TextFormField(
          controller: controller,
          focusNode: focusNode,
          onChanged: onChanged,
          keyboardType: keyboardType,
          textInputAction:
              nextFocus != null ? TextInputAction.next : TextInputAction.done,
          onFieldSubmitted: (_) {
            if (nextFocus != null) {
              Future.delayed(Duration(milliseconds: 100), () {
                if (context.mounted) {
                  FocusScope.of(context).requestFocus(nextFocus);
                }
              });
            }
          },
          validator: isRequired
              ? (value) =>
                  value == null || value.isEmpty ? 'Campo obligatorio' : null
              : null,
          style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(
              color: primaryTeal.withOpacity(0.8),
              fontWeight: FontWeight.w500,
              fontSize: isSmallScreen ? 13 : 14,
            ),
            prefixIcon:
                Icon(icon, color: primaryTeal, size: isSmallScreen ? 20 : 24),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: primaryTeal.withOpacity(0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: primaryTeal.withOpacity(0.5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: primaryTeal, width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 12 : 16,
              vertical: isSmallScreen ? 12 : 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, String? selectedValue,
      Function(String?) onChanged) {
    final primaryTeal = Color(0xFF038C7F);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: DropdownButtonFormField<String>(
        value: selectedValue,
        hint: Text('Seleccionar $label',
            style: TextStyle(
                color: primaryTeal.withOpacity(0.6),
                fontWeight: FontWeight.w400)),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
              color: primaryTeal.withOpacity(0.8), fontWeight: FontWeight.w500),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: primaryTeal.withOpacity(0.3))),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: primaryTeal.withOpacity(0.5))),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: primaryTeal, width: 2)),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        items: items.map((String value) {
          return DropdownMenuItem<String>(
              value: value,
              child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(value)));
        }).toList(),
        onChanged: onChanged,
        validator: (value) => value == null || value.isEmpty
            ? 'Debe seleccionar una opción'
            : null,
        isExpanded: true,
        icon: Icon(Icons.arrow_drop_down, color: primaryTeal),
        style: TextStyle(fontSize: 16, color: Colors.black87),
        dropdownColor: Colors.white,
      ),
    );
  }

  Widget _buildResponsiveDateField(
      String label,
      IconData icon,
      DateTime? selectedDate,
      Color primaryColor,
      Color secondaryColor,
      Function(DateTime?) onDateSelected,
      BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 360;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        readOnly: true,
        style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
              color: primaryColor.withOpacity(0.8),
              fontWeight: FontWeight.w500,
              fontSize: isSmallScreen ? 13 : 14),
          prefixIcon:
              Icon(icon, color: primaryColor, size: isSmallScreen ? 20 : 24),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: primaryColor.withOpacity(0.3))),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: primaryColor.withOpacity(0.5))),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: primaryColor, width: 2)),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 12 : 16,
              vertical: isSmallScreen ? 12 : 16),
        ),
        validator: (value) => selectedDate == null ? 'Campo obligatorio' : null,
        onTap: () async {
          final DateTime? pickedDate = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime(2101),
            builder: (context, child) {
              return Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: ColorScheme.light(
                      primary: primaryColor,
                      onPrimary: Colors.white,
                      onSurface: Colors.black),
                  textButtonTheme: TextButtonThemeData(
                      style: TextButton.styleFrom(
                          foregroundColor: secondaryColor)),
                ),
                child: child!,
              );
            },
          );
          if (pickedDate != null) {
            onDateSelected(pickedDate);
          }
        },
        controller: TextEditingController(
            text: selectedDate != null
                ? DateFormat('dd/MM/yyyy').format(selectedDate)
                : ''),
      ),
    );
  }
}

class _RegistroNuevoMiembroStateful extends StatefulWidget {
  final String coordinadorId;
  final String tribuId;
  final String categoriaTribu;
  final String nombreTribu;
  final String ministerioAsignado;
  final Color primaryTeal;
  final Color secondaryOrange;
  final Color accentGrey;
  final Color backgroundGrey;

  const _RegistroNuevoMiembroStateful({
    Key? key,
    required this.coordinadorId,
    required this.tribuId,
    required this.categoriaTribu,
    required this.nombreTribu,
    required this.ministerioAsignado,
    required this.primaryTeal,
    required this.secondaryOrange,
    required this.accentGrey,
    required this.backgroundGrey,
  }) : super(key: key);

  @override
  _RegistroNuevoMiembroStatefulState createState() =>
      _RegistroNuevoMiembroStatefulState();
}

class _RegistroNuevoMiembroStatefulState
    extends State<_RegistroNuevoMiembroStateful> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  // Controladores
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, FocusNode> _focusNodes = {};
  final Map<String, GlobalKey> _fieldKeys = {};

  // Estados
  String? _sexo;
  String? _estadoCivil;
  List<String> _ocupacionesSeleccionadas = [];
  bool? _tieneHijos;
  DateTime? _fechaAsignacionTribu;
  String _estadoProceso = '';

  // Estados de expansión de secciones
  bool _seccionPersonalExpanded = true;
  bool _seccionUbicacionExpanded = true;
  bool _seccionFamiliaExpanded = true;
  bool _seccionOcupacionExpanded = true;
  bool _seccionMinisterialExpanded = true;

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

  // ✅ Opciones completas de Estado del Proceso
  final List<String> _estadosProceso = [
    'Pendiente',
    'Discipulado 1',
    'Discipulado 2',
    'Discipulado 3',
    'Consolidación',
    'Estudio Bíblico',
    'Escuela de Líderes'
  ];

  @override
  void initState() {
    super.initState();

    final fields = [
      'nombre',
      'apellido',
      'telefono',
      'direccion',
      'barrio',
      'nombrePareja',
      'descripcionOcupaciones',
      'referenciaInvitacion',
      'observaciones',
      'estadoProceso',
      'edad'
    ];

    for (var field in fields) {
      _controllers[field] = TextEditingController();
      _focusNodes[field] = FocusNode();
      _fieldKeys[field] = GlobalKey();
    }
  }

  @override
  void dispose() {
    _controllers.forEach((key, controller) => controller.dispose());
    _focusNodes.forEach((key, node) => node.dispose());
    _scrollController.dispose();
    super.dispose();
  }

  // Calcular progreso del formulario
  double _calcularProgreso() {
    int camposLlenos = 0;
    int totalCampos = 11; // Campos obligatorios

    if (_controllers['nombre']!.text.isNotEmpty) camposLlenos++;
    if (_controllers['apellido']!.text.isNotEmpty) camposLlenos++;
    if (_controllers['telefono']!.text.isNotEmpty) camposLlenos++;
    if (_sexo != null) camposLlenos++;
    if (_controllers['edad']!.text.isNotEmpty) camposLlenos++;
    if (_controllers['direccion']!.text.isNotEmpty) camposLlenos++;
    if (_controllers['barrio']!.text.isNotEmpty) camposLlenos++;
    if (_estadoCivil != null) camposLlenos++;
    if (_tieneHijos != null) camposLlenos++;
    if (_controllers['referenciaInvitacion']!.text.isNotEmpty) camposLlenos++;
    if (_fechaAsignacionTribu != null) camposLlenos++;

    return camposLlenos / totalCampos;
  }

  Future<void> _guardarRegistro() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text('Por favor completa todos los campos obligatorios'),
              ),
            ],
          ),
          backgroundColor: widget.secondaryOrange,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: EdgeInsets.all(16),
        ),
      );
      return;
    }

    final registro = {
      'fechaAsignacionTribu': _fechaAsignacionTribu != null
          ? Timestamp.fromDate(_fechaAsignacionTribu!)
          : null,
      'nombre': _controllers['nombre']!.text,
      'apellido': _controllers['apellido']!.text,
      'telefono': _controllers['telefono']!.text,
      'sexo': _sexo,
      'edad': int.tryParse(_controllers['edad']!.text) ?? 0,
      'direccion': _controllers['direccion']!.text,
      'barrio': _controllers['barrio']!.text,
      'estadoCivil': _estadoCivil,
      'nombrePareja': _controllers['nombrePareja']!.text,
      'ocupaciones': _ocupacionesSeleccionadas,
      'descripcionOcupaciones': _controllers['descripcionOcupaciones']!.text,
      'tieneHijos': _tieneHijos,
      'referenciaInvitacion': _controllers['referenciaInvitacion']!.text,
      'observaciones': _controllers['observaciones']!.text,
      'tribuAsignada': widget.tribuId,
      'nombreTribu': widget.nombreTribu,
      'ministerioAsignado': widget.ministerioAsignado,
      'coordinadorAsignado': widget.coordinadorId,
      'fechaRegistro': FieldValue.serverTimestamp(),
      'fechaAsignacionCoordinador': FieldValue.serverTimestamp(),
      'activo': true,
      'tribuId': widget.tribuId,
      'categoria': widget.categoriaTribu,
      'estadoProceso': _controllers['estadoProceso']!.text,
    };

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (loadingContext) => WillPopScope(
        onWillPop: () async => false,
        child: Center(
          child: Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: widget.primaryTeal.withOpacity(0.3),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: widget.primaryTeal.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: CircularProgressIndicator(
                    color: widget.primaryTeal,
                    strokeWidth: 3,
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'Guardando registro...',
                  style: TextStyle(
                    color: widget.primaryTeal,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Por favor espera',
                  style: TextStyle(
                    color: widget.accentGrey,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      await FirebaseFirestore.instance.collection('registros').add(registro);

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      await Future.delayed(Duration(milliseconds: 150));

      if (!mounted) return;
      Navigator.of(context).pop();
      await Future.delayed(Duration(milliseconds: 100));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_circle, color: Colors.white, size: 20),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '¡Registro exitoso!',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      'El miembro ha sido registrado correctamente',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: EdgeInsets.all(16),
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      await Future.delayed(Duration(milliseconds: 100));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text('Error al guardar: $e')),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: EdgeInsets.all(16),
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return Container(
      height: MediaQuery.of(context).size.height * 0.95,
      decoration: BoxDecoration(
        color: widget.backgroundGrey,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Encabezado Premium
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 14 : 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  widget.primaryTeal,
                  widget.primaryTeal.withOpacity(0.85)
                ],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.primaryTeal.withOpacity(0.3),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.3),
                              Colors.white.withOpacity(0.1)
                            ],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(Icons.person_add_rounded,
                            color: Colors.white, size: isSmallScreen ? 22 : 24),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Nuevo Miembro',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: isSmallScreen ? 17 : 19,
                                letterSpacing: 0.5,
                              ),
                            ),
                            if (widget.nombreTribu.isNotEmpty)
                              Container(
                                margin: EdgeInsets.only(top: 4),
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  widget.nombreTribu,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.95),
                                    fontSize: isSmallScreen ? 11 : 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
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
                            padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.close_rounded,
                                color: Colors.white,
                                size: isSmallScreen ? 20 : 22),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  // Barra de progreso
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return AnimatedContainer(
                          duration: Duration(milliseconds: 300),
                          width: constraints.maxWidth * _calcularProgreso(),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                widget.secondaryOrange,
                                Colors.orange.shade300
                              ],
                            ),
                            borderRadius: BorderRadius.circular(3),
                            boxShadow: [
                              BoxShadow(
                                color: widget.secondaryOrange.withOpacity(0.5),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progreso del formulario',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: isSmallScreen ? 10 : 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${(_calcularProgreso() * 100).toInt()}%',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isSmallScreen ? 11 : 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Contenido con scroll
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                controller: _scrollController,
                padding: EdgeInsets.only(
                  left: isSmallScreen ? 12 : 16,
                  right: isSmallScreen ? 12 : 16,
                  top: isSmallScreen ? 12 : 16,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                ),
                children: [
                  // Sección Personal
                  _buildExpandableSection(
                    title: 'Información Personal',
                    icon: Icons.person_outline_rounded,
                    isExpanded: _seccionPersonalExpanded,
                    onToggle: () => setState(() =>
                        _seccionPersonalExpanded = !_seccionPersonalExpanded),
                    children: [
                      _buildTextField('Nombre', Icons.badge_rounded, 'nombre'),
                      _buildTextField(
                          'Apellido', Icons.person_outline_rounded, 'apellido'),
                      _buildTextField(
                          'Teléfono', Icons.phone_rounded, 'telefono',
                          keyboardType: TextInputType.phone),
                      _buildEnhancedDropdown('Sexo', ['Masculino', 'Femenino'],
                          _sexo, (value) => setState(() => _sexo = value)),
                      _buildTextField('Edad', Icons.cake_rounded, 'edad',
                          keyboardType: TextInputType.number),
                    ],
                  ),

                  SizedBox(height: isSmallScreen ? 12 : 16),

                  // Sección Ubicación
                  _buildExpandableSection(
                    title: 'Ubicación',
                    icon: Icons.location_on_rounded,
                    isExpanded: _seccionUbicacionExpanded,
                    onToggle: () => setState(() =>
                        _seccionUbicacionExpanded = !_seccionUbicacionExpanded),
                    children: [
                      _buildTextField(
                          'Dirección', Icons.home_rounded, 'direccion'),
                      _buildTextField(
                          'Barrio', Icons.location_city_rounded, 'barrio'),
                    ],
                  ),

                  SizedBox(height: isSmallScreen ? 12 : 16),

                  // Sección Familia
                  _buildExpandableSection(
                    title: 'Estado Civil y Familia',
                    icon: Icons.family_restroom_rounded,
                    isExpanded: _seccionFamiliaExpanded,
                    onToggle: () => setState(() =>
                        _seccionFamiliaExpanded = !_seccionFamiliaExpanded),
                    children: [
                      _buildEnhancedDropdown(
                          'Estado Civil',
                          _estadosCiviles,
                          _estadoCivil,
                          (value) => setState(() => _estadoCivil = value)),
                      if (_estadoCivil == 'Casado(a)' ||
                          _estadoCivil == 'Unión Libre')
                        _buildTextField('Nombre de Pareja',
                            Icons.favorite_rounded, 'nombrePareja'),
                      _buildEnhancedDropdown(
                        'Tiene Hijos',
                        ['Sí', 'No'],
                        _tieneHijos == null
                            ? null
                            : (_tieneHijos! ? 'Sí' : 'No'),
                        (value) =>
                            setState(() => _tieneHijos = (value == 'Sí')),
                      ),
                    ],
                  ),

                  SizedBox(height: isSmallScreen ? 12 : 16),

                  // Sección Ocupación
                  _buildExpandableSection(
                    title: 'Ocupación',
                    icon: Icons.work_rounded,
                    isExpanded: _seccionOcupacionExpanded,
                    onToggle: () => setState(() =>
                        _seccionOcupacionExpanded = !_seccionOcupacionExpanded),
                    children: [
                      _buildOcupacionesChips(),
                      if (_ocupacionesSeleccionadas.isNotEmpty)
                        _buildTextField('Descripción',
                            Icons.description_rounded, 'descripcionOcupaciones',
                            isRequired: false),
                    ],
                  ),

                  SizedBox(height: isSmallScreen ? 12 : 16),

                  // Sección Ministerial
                  _buildExpandableSection(
                    title: 'Información Ministerial',
                    icon: Icons.groups_rounded,
                    isExpanded: _seccionMinisterialExpanded,
                    onToggle: () => setState(() => _seccionMinisterialExpanded =
                        !_seccionMinisterialExpanded),
                    children: [
                      _buildTextField('Referencia de Invitación',
                          Icons.link_rounded, 'referenciaInvitacion'),
                      _buildTextField(
                          'Observaciones', Icons.note_rounded, 'observaciones',
                          isRequired: false, maxLines: 3),
                      _buildEstadoProcesoField(),
                      _buildEnhancedDateField(),
                    ],
                  ),

                  SizedBox(height: isSmallScreen ? 16 : 20),

                  // Info Card
                  Container(
                    padding: EdgeInsets.all(isSmallScreen ? 12 : 14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          widget.primaryTeal.withOpacity(0.08),
                          widget.primaryTeal.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: widget.primaryTeal.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: widget.primaryTeal.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.info_outline_rounded,
                            color: widget.primaryTeal,
                            size: isSmallScreen ? 18 : 20,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Este miembro será asignado automáticamente al coordinador.',
                            style: TextStyle(
                              color: widget.primaryTeal,
                              fontSize: isSmallScreen ? 12 : 13,
                              fontWeight: FontWeight.w500,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: isSmallScreen ? 20 : 24),

                  // Botones de acción
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                                vertical: isSmallScreen ? 12 : 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: BorderSide(
                                color: widget.accentGrey, width: 1.5),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.close_rounded,
                                  size: isSmallScreen ? 18 : 20),
                              SizedBox(width: 6),
                              Text(
                                'Cancelar',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 14 : 15,
                                  fontWeight: FontWeight.w600,
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
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: LinearGradient(
                              colors: [
                                widget.secondaryOrange,
                                widget.secondaryOrange.withOpacity(0.8),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: widget.secondaryOrange.withOpacity(0.4),
                                blurRadius: 12,
                                offset: Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _guardarRegistro,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              shadowColor: Colors.transparent,
                              padding: EdgeInsets.symmetric(
                                  vertical: isSmallScreen ? 12 : 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle_rounded,
                                    size: isSmallScreen ? 20 : 22),
                                SizedBox(width: 8),
                                Text(
                                  'Registrar',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 15 : 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget para secciones expandibles
  Widget _buildExpandableSection({
    required String title,
    required IconData icon,
    required bool isExpanded,
    required VoidCallback onToggle,
    required List<Widget> children,
  }) {
    final isSmallScreen = MediaQuery.of(context).size.width < 360;

    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isExpanded
              ? widget.primaryTeal.withOpacity(0.3)
              : Colors.grey.withOpacity(0.2),
          width: isExpanded ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isExpanded
                ? widget.primaryTeal.withOpacity(0.1)
                : Colors.black.withOpacity(0.03),
            blurRadius: isExpanded ? 12 : 6,
            offset: Offset(0, isExpanded ? 4 : 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onToggle,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(16),
                bottom: isExpanded ? Radius.zero : Radius.circular(16),
              ),
              child: Container(
                padding: EdgeInsets.all(isSmallScreen ? 14 : 16),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            widget.primaryTeal.withOpacity(0.15),
                            widget.primaryTeal.withOpacity(0.08),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        icon,
                        color: widget.primaryTeal,
                        size: isSmallScreen ? 20 : 22,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 15 : 17,
                          fontWeight: FontWeight.bold,
                          color: widget.primaryTeal,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: Duration(milliseconds: 300),
                      child: Container(
                        padding: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: widget.primaryTeal.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: widget.primaryTeal,
                          size: isSmallScreen ? 20 : 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isExpanded)
            Container(
              padding: EdgeInsets.fromLTRB(
                isSmallScreen ? 12 : 16,
                0,
                isSmallScreen ? 12 : 16,
                isSmallScreen ? 12 : 16,
              ),
              child: Column(
                children: children,
              ),
            ),
        ],
      ),
    );
  }

  // TextField mejorado
  Widget _buildTextField(
    String label,
    IconData icon,
    String field, {
    bool isRequired = true,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    final isSmallScreen = MediaQuery.of(context).size.width < 360;

    return Padding(
      padding: EdgeInsets.only(bottom: isSmallScreen ? 14 : 16),
      child: TextFormField(
        controller: _controllers[field],
        focusNode: _focusNodes[field],
        keyboardType: keyboardType,
        maxLines: maxLines,
        textInputAction: TextInputAction.next,
        onChanged: (_) => setState(() {}),
        validator: isRequired
            ? (value) =>
                value == null || value.isEmpty ? 'Campo obligatorio' : null
            : null,
        style: TextStyle(fontSize: isSmallScreen ? 14 : 15),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: widget.primaryTeal.withOpacity(0.7),
            fontWeight: FontWeight.w500,
            fontSize: isSmallScreen ? 13 : 14,
          ),
          prefixIcon: Container(
            margin: EdgeInsets.all(isSmallScreen ? 10 : 12),
            padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  widget.primaryTeal.withOpacity(0.15),
                  widget.primaryTeal.withOpacity(0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon,
                color: widget.primaryTeal, size: isSmallScreen ? 18 : 20),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: widget.primaryTeal, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.red.shade300, width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.red, width: 2),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
          contentPadding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 14 : 16,
            vertical: isSmallScreen ? 14 : 16,
          ),
        ),
      ),
    );
  }

  // Dropdown mejorado
  Widget _buildEnhancedDropdown(
    String label,
    List<String> items,
    String? value,
    Function(String?) onChanged,
  ) {
    final isSmallScreen = MediaQuery.of(context).size.width < 360;

    return Padding(
      padding: EdgeInsets.only(bottom: isSmallScreen ? 14 : 16),
      child: DropdownButtonFormField<String>(
        value: value,
        hint: Text(
          'Seleccionar $label',
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: isSmallScreen ? 13 : 14,
          ),
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: widget.primaryTeal.withOpacity(0.7),
            fontWeight: FontWeight.w500,
            fontSize: isSmallScreen ? 13 : 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: widget.primaryTeal, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.red.shade300, width: 1.5),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
          contentPadding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 14 : 16,
            vertical: isSmallScreen ? 14 : 16,
          ),
        ),
        items: items.map((item) {
          return DropdownMenuItem(
            value: item,
            child: Text(
              item,
              style: TextStyle(fontSize: isSmallScreen ? 14 : 15),
            ),
          );
        }).toList(),
        onChanged: (newValue) {
          onChanged(newValue);
          setState(() {});
        },
        validator: (value) => value == null ? 'Campo obligatorio' : null,
        icon: Icon(Icons.arrow_drop_down_rounded,
            color: widget.primaryTeal, size: isSmallScreen ? 24 : 26),
        dropdownColor: Colors.white,
        isExpanded: true,
      ),
    );
  }

  // Chips de ocupaciones mejorados
  Widget _buildOcupacionesChips() {
    final isSmallScreen = MediaQuery.of(context).size.width < 360;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Icon(Icons.work_outline_rounded,
                  color: widget.primaryTeal, size: isSmallScreen ? 16 : 18),
              SizedBox(width: 8),
              Text(
                'Selecciona ocupaciones',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: widget.primaryTeal,
                  fontSize: isSmallScreen ? 13 : 14,
                ),
              ),
            ],
          ),
        ),
        Wrap(
          spacing: isSmallScreen ? 6 : 8,
          runSpacing: isSmallScreen ? 6 : 8,
          children: _ocupaciones.map((ocupacion) {
            final isSelected = _ocupacionesSeleccionadas.contains(ocupacion);
            return AnimatedContainer(
              duration: Duration(milliseconds: 200),
              child: FilterChip(
                label: Text(
                  ocupacion,
                  style: TextStyle(fontSize: isSmallScreen ? 12 : 13),
                ),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _ocupacionesSeleccionadas.add(ocupacion);
                    } else {
                      _ocupacionesSeleccionadas.remove(ocupacion);
                    }
                  });
                },
                selectedColor: widget.primaryTeal.withOpacity(0.2),
                backgroundColor: Colors.white,
                checkmarkColor: widget.primaryTeal,
                side: BorderSide(
                  color: isSelected
                      ? widget.primaryTeal
                      : Colors.grey.withOpacity(0.3),
                  width: isSelected ? 2 : 1,
                ),
                labelStyle: TextStyle(
                  color: isSelected ? widget.primaryTeal : Colors.grey.shade700,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 10 : 12,
                  vertical: isSmallScreen ? 6 : 8,
                ),
                elevation: isSelected ? 2 : 0,
                pressElevation: 4,
              ),
            );
          }).toList(),
        ),
        SizedBox(height: isSmallScreen ? 12 : 16),
      ],
    );
  }

  // Campo de Estado del Proceso mejorado
  Widget _buildEstadoProcesoField() {
    final isSmallScreen = MediaQuery.of(context).size.width < 360;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(
            'Estado del Proceso', Icons.track_changes_rounded, 'estadoProceso',
            isRequired: false),
        Container(
          padding: EdgeInsets.all(isSmallScreen ? 12 : 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                widget.primaryTeal.withOpacity(0.05),
                widget.primaryTeal.withOpacity(0.02),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.primaryTeal.withOpacity(0.15),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.touch_app_rounded,
                      color: widget.primaryTeal, size: isSmallScreen ? 16 : 18),
                  SizedBox(width: 8),
                  Text(
                    'Opciones rápidas',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: widget.primaryTeal,
                      fontSize: isSmallScreen ? 13 : 14,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Wrap(
                spacing: isSmallScreen ? 6 : 8,
                runSpacing: isSmallScreen ? 6 : 8,
                children: _estadosProceso.map((estado) {
                  final isSelected =
                      _controllers['estadoProceso']!.text == estado;
                  return AnimatedContainer(
                    duration: Duration(milliseconds: 200),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _controllers['estadoProceso']!.text = estado;
                          });
                          HapticFeedback.lightImpact();
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 12 : 14,
                            vertical: isSmallScreen ? 8 : 10,
                          ),
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? LinearGradient(
                                    colors: [
                                      widget.primaryTeal,
                                      widget.primaryTeal.withOpacity(0.8),
                                    ],
                                  )
                                : null,
                            color: isSelected ? null : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? widget.primaryTeal
                                  : Colors.grey.withOpacity(0.3),
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color:
                                          widget.primaryTeal.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: Offset(0, 4),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isSelected)
                                Padding(
                                  padding: EdgeInsets.only(right: 6),
                                  child: Icon(
                                    Icons.check_circle_rounded,
                                    color: Colors.white,
                                    size: isSmallScreen ? 14 : 16,
                                  ),
                                ),
                              Text(
                                estado,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.grey.shade700,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  fontSize: isSmallScreen ? 12 : 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        SizedBox(height: isSmallScreen ? 14 : 16),
      ],
    );
  }

  // Campo de fecha mejorado
  Widget _buildEnhancedDateField() {
    final isSmallScreen = MediaQuery.of(context).size.width < 360;

    return Padding(
      padding: EdgeInsets.only(bottom: isSmallScreen ? 14 : 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _fechaAsignacionTribu ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2101),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: ColorScheme.light(
                      primary: widget.primaryTeal,
                      onPrimary: Colors.white,
                      surface: Colors.white,
                      onSurface: Colors.black87,
                    ),
                    dialogBackgroundColor: Colors.white,
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) {
              setState(() => _fechaAsignacionTribu = picked);
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.all(isSmallScreen ? 14 : 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _fechaAsignacionTribu != null
                    ? widget.primaryTeal.withOpacity(0.5)
                    : Colors.grey.withOpacity(0.3),
                width: _fechaAsignacionTribu != null ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        widget.secondaryOrange.withOpacity(0.15),
                        widget.secondaryOrange.withOpacity(0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.calendar_today_rounded,
                    color: widget.secondaryOrange,
                    size: isSmallScreen ? 20 : 22,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fecha de Asignación de Tribu',
                        style: TextStyle(
                          color: widget.primaryTeal.withOpacity(0.7),
                          fontSize: isSmallScreen ? 12 : 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        _fechaAsignacionTribu != null
                            ? DateFormat('dd/MM/yyyy')
                                .format(_fechaAsignacionTribu!)
                            : 'Seleccionar fecha',
                        style: TextStyle(
                          color: _fechaAsignacionTribu != null
                              ? Colors.black87
                              : Colors.grey.shade500,
                          fontSize: isSmallScreen ? 15 : 16,
                          fontWeight: _fechaAsignacionTribu != null
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: widget.secondaryOrange.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: widget.secondaryOrange,
                    size: isSmallScreen ? 14 : 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
