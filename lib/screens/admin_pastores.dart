// Dart SDK
import 'dart:async';
import 'dart:convert';

// Flutter
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

// Firebase
import 'package:cloud_firestore/cloud_firestore.dart';

// Paquetes externos
import 'package:crypto/crypto.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

// Proyecto
import 'package:formulario_app/services/auth_service.dart';
import 'package:formulario_app/services/credentials_service.dart';
import 'package:formulario_app/screens/StatisticsDialog.dart';

// Locales
import 'TribusScreen.dart' hide showDialog;
import 'admin_screen.dart';

// Colors based on the COCEP logo
const Color kPrimaryColor = Color(0xFF1B998B); // Turquoise
const Color kSecondaryColor = Color(0xFFFF4B3E); // Orange/red
const Color kAccentColor = Color(0xFFFFBE3D); // Yellow/gold from flame
const Color kBackgroundColor = Color(0xFFF5F7FA); // Light gray for background
const Color kTextColor = Color(0xFF2C3E50); // Dark blue for text
const Color kCardColor = Colors.white; // White for cards

class AdminPastores extends StatefulWidget {
  const AdminPastores({Key? key}) : super(key: key);

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
  String? categoriaSeleccionada;

// NUEVAS VARIABLES DE BLOQUEO
  int _intentosFallidos = 0;
  DateTime? _tiempoBloqueo;
  String? _horaBloqueo;
  static const int _maxIntentos = 3;
  static const Duration _duracionBloqueo = Duration(hours: 12);
  Timer? _contadorBloqueoTimer;

  Timer? _inactivityTimer;
  static const Duration _inactivityDuration =
      Duration(minutes: 15); // Cambia aquí el tiempo si necesitas

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _verificarLiderConsolidacion();
    _resetInactivityTimer();
    _cargarEstadoBloqueo(); // ✅ NUEVA LÍNEA

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
    _contadorBloqueoTimer?.cancel(); // ✅ NUEVA LÍNEA
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

    // Cancelar cualquier timer activo
    _inactivityTimer?.cancel();

    // Mostrar mensaje de sesión expirada
    _mostrarSnackBar('Sesión expirada por inactividad', isSuccess: false);

    // Pequeña pausa para que se vea el mensaje
    await Future.delayed(Duration(milliseconds: 500));

    // Navegar al login (cambia '/login' por tu ruta correcta si es diferente)
    if (mounted) {
      context.go('/login');
    }
  }

  Future<void> _confirmarCerrarSesion() async {
    // Resetear timer mientras se muestra el diálogo
    _resetInactivityTimer();

    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.logout,
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
                borderRadius: BorderRadius.circular(8),
              ),
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
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 2,
            ),
            child: Text(
              'Cerrar Sesión',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _inactivityTimer?.cancel();
      _mostrarSnackBar('Cerrando sesión...', isSuccess: true);
      await Future.delayed(Duration(milliseconds: 300));
      if (mounted) {
        context.go('/login'); // Cambia esta ruta si tu login tiene otra ruta
      }
    }
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

// ✅ MÉTODO 1: Verificar si usuario está bloqueado
  bool _estaUsuarioBloqueado() {
    if (_tiempoBloqueo == null) return false;

    final ahora = DateTime.now();
    if (ahora.isBefore(_tiempoBloqueo!)) {
      return true;
    } else {
      _tiempoBloqueo = null;
      _horaBloqueo = null;
      _intentosFallidos = 0;
      _guardarEstadoBloqueo();
      return false;
    }
  }

  // ✅ MÉTODO 2: Calcular tiempo restante de bloqueo
  Duration _tiempoRestanteBloqueo() {
    if (_tiempoBloqueo == null) return Duration.zero;
    final ahora = DateTime.now();
    return _tiempoBloqueo!.difference(ahora);
  }

  // ✅ MÉTODO 3: Cargar estado de bloqueo desde Firestore

  Future<void> _cargarEstadoBloqueo() async {
    try {
      final authService = AuthService();
      String userId = await authService.getUserId();

      // ✅ NUEVO: Si userId está vacío, obtener el rol y asignar ID específico
      if (userId.isEmpty) {
        final userRole = await authService.getCurrentUserRole();
        if (userRole == 'adminPastores') {
          userId = 'admin_cocep_unique_id';
          print('✅ Usando ID fijo para admin: $userId');
        } else {
          print('⚠️ No se pudo obtener userId para rol: $userRole');
          return;
        }
      }

      print('🔍 Cargando estado de bloqueo para userId: $userId');

      final doc = await FirebaseFirestore.instance
          .collection('bloqueos_usuarios')
          .doc(userId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        final tiempoBloqueoTimestamp = data['tiempoBloqueo'] as Timestamp?;

        if (tiempoBloqueoTimestamp != null) {
          final tiempoBloqueoRecuperado = tiempoBloqueoTimestamp.toDate();
          final horaBloqueoRecuperada = data['horaBloqueo'] as String?;
          final intentosFallidosRecuperados =
              data['intentosFallidos'] as int? ?? 0;

          print('🔍 Bloqueo encontrado en Firestore:');
          print('   - Tiempo bloqueo: $tiempoBloqueoRecuperado');
          print('   - Hora bloqueo: $horaBloqueoRecuperada');
          print('   - Intentos fallidos: $intentosFallidosRecuperados');

          final ahora = DateTime.now();
          if (ahora.isBefore(tiempoBloqueoRecuperado)) {
            if (mounted) {
              setState(() {
                _tiempoBloqueo = tiempoBloqueoRecuperado;
                _horaBloqueo = horaBloqueoRecuperada;
                _intentosFallidos = intentosFallidosRecuperados;
              });
            }
            print('🔒 Usuario sigue bloqueado hasta: $tiempoBloqueoRecuperado');
          } else {
            print('✅ El bloqueo ya expiró, limpiando estado...');
            if (mounted) {
              setState(() {
                _tiempoBloqueo = null;
                _horaBloqueo = null;
                _intentosFallidos = 0;
              });
            }
            await _guardarEstadoBloqueo();
          }
        }
      } else {
        print('ℹ️ No existe documento de bloqueo para este usuario');
      }
    } catch (e) {
      print('❌ Error al cargar estado de bloqueo: $e');
    }
  }

  // ✅ MÉTODO 4: Guardar estado de bloqueo en Firestore

  Future<void> _guardarEstadoBloqueo() async {
    try {
      print('💾 Guardando estado de bloqueo:');
      print('   - Tiempo bloqueo: $_tiempoBloqueo');
      print('   - Hora bloqueo: $_horaBloqueo');
      print('   - Intentos fallidos: $_intentosFallidos');

      final authService = AuthService();
      String userId = await authService.getUserId();

      // ✅ NUEVO: Si userId está vacío, obtener el rol y asignar ID específico
      if (userId.isEmpty) {
        final userRole = await authService.getCurrentUserRole();
        if (userRole == 'adminPastores') {
          userId = 'admin_cocep_unique_id';
          print('✅ Usando ID fijo para admin: $userId');
        } else {
          print('⚠️ No se pudo obtener userId para rol: $userRole');
          return;
        }
      }

      if (_tiempoBloqueo == null) {
        // Eliminar el documento si no hay bloqueo
        await FirebaseFirestore.instance
            .collection('bloqueos_usuarios')
            .doc(userId)
            .delete();
        print('🗑️ Documento de bloqueo eliminado para userId: $userId');
      } else {
        // Guardar estado de bloqueo
        await FirebaseFirestore.instance
            .collection('bloqueos_usuarios')
            .doc(userId)
            .set({
          'tiempoBloqueo': Timestamp.fromDate(_tiempoBloqueo!),
          'horaBloqueo': _horaBloqueo,
          'intentosFallidos': _intentosFallidos,
          'userId': userId,
          'ultimaActualizacion': FieldValue.serverTimestamp(),
        });
        print('✅ Estado de bloqueo guardado correctamente en Firestore');
      }
    } catch (e) {
      print('❌ Error al guardar estado de bloqueo: $e');
    }
  }

  //Mostrar ventana de bloqueo

// ✅ REEMPLAZA COMPLETAMENTE el método _mostrarVentanaBloqueo
// Busca en tu código (aproximadamente línea 340) y reemplaza toda la función:

  Future<void> _mostrarVentanaBloqueo(BuildContext context) async {
    _contadorBloqueoTimer?.cancel();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            _contadorBloqueoTimer?.cancel();
            _contadorBloqueoTimer =
                Timer.periodic(Duration(seconds: 1), (timer) {
              if (!_estaUsuarioBloqueado()) {
                timer.cancel();
                Navigator.of(dialogContext).pop();
                return;
              }
              if (mounted) {
                setState(() {});
              }
            });

            final tiempoRestante = _tiempoRestanteBloqueo();
            final horas = tiempoRestante.inHours;
            final minutos = tiempoRestante.inMinutes.remainder(60);
            final segundos = tiempoRestante.inSeconds.remainder(60);

            final horaDesbloqueo = _tiempoBloqueo?.toLocal();
            final horaDesbloqueoStr = horaDesbloqueo != null
                ? DateFormat('hh:mm a', 'es').format(horaDesbloqueo)
                : 'Desconocida';

            // ✅ Responsive Layout Builder
            return LayoutBuilder(
              builder: (context, constraints) {
                final mediaQuery = MediaQuery.of(dialogContext);
                final screenWidth = mediaQuery.size.width;
                final screenHeight = mediaQuery.size.height;
                final isSmallScreen = screenWidth < 400;
                final isMediumScreen = screenWidth >= 400 && screenWidth < 600;
                final isLargeScreen = screenWidth >= 600;

                // ✅ Tamaños adaptativos refinados
                final titleFontSize =
                    isSmallScreen ? 22.0 : (isMediumScreen ? 26.0 : 30.0);
                final subtitleFontSize =
                    isSmallScreen ? 13.0 : (isMediumScreen ? 15.0 : 17.0);
                final iconSize =
                    isSmallScreen ? 48.0 : (isMediumScreen ? 64.0 : 72.0);
                final padding =
                    isSmallScreen ? 20.0 : (isMediumScreen ? 24.0 : 32.0);
                final timeDigitSize =
                    isSmallScreen ? 32.0 : (isMediumScreen ? 40.0 : 48.0);
                final timeLabelSize =
                    isSmallScreen ? 10.0 : (isMediumScreen ? 12.0 : 14.0);
                final contentFontSize =
                    isSmallScreen ? 14.0 : (isMediumScreen ? 16.0 : 18.0);
                final infoPadding =
                    isSmallScreen ? 16.0 : (isMediumScreen ? 20.0 : 24.0);

                // ✅ Constraints adaptativos
                final maxWidth = isSmallScreen
                    ? screenWidth * 0.92
                    : (isMediumScreen ? 480.0 : 560.0);
                final maxHeight = isSmallScreen
                    ? screenHeight * 0.88
                    : (isMediumScreen ? screenHeight * 0.82 : 720.0);

                return Dialog(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  insetPadding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 16 : 24,
                    vertical: isSmallScreen ? 20 : 24,
                  ),
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: maxWidth,
                      maxHeight: maxHeight,
                    ),
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(isSmallScreen ? 24 : 32),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 32,
                          spreadRadius: 4,
                          offset: Offset(0, 12),
                        ),
                        BoxShadow(
                          color: Colors.red.withOpacity(0.2),
                          blurRadius: 24,
                          spreadRadius: -4,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius:
                          BorderRadius.circular(isSmallScreen ? 24 : 32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // ✅ Header Premium con degradado mejorado
                          Container(
                            padding: EdgeInsets.symmetric(
                              vertical: padding,
                              horizontal: padding * 0.8,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFFD32F2F), // Rojo más elegante
                                  Color(0xFFC62828),
                                  Color(0xFFB71C1C),
                                ],
                                stops: [0.0, 0.5, 1.0],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.shade900.withOpacity(0.4),
                                  blurRadius: 20,
                                  offset: Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                // Icono animado premium
                                TweenAnimationBuilder(
                                  tween: Tween<double>(begin: 0.0, end: 1.0),
                                  duration: Duration(milliseconds: 1000),
                                  curve: Curves.elasticOut,
                                  builder: (context, double value, child) {
                                    return Transform.scale(
                                      scale: value,
                                      child: Container(
                                        padding: EdgeInsets.all(isSmallScreen
                                            ? 16
                                            : (isMediumScreen ? 20 : 24)),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color:
                                                Colors.white.withOpacity(0.6),
                                            width: isSmallScreen ? 3 : 4,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Colors.white.withOpacity(0.3),
                                              blurRadius: 20,
                                              spreadRadius: 2,
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          Icons.lock_clock_rounded,
                                          color: Colors.white,
                                          size: iconSize,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                SizedBox(height: isSmallScreen ? 16 : 24),
                                // Título con mejor tipografía
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 16),
                                  child: Column(
                                    children: [
                                      Text(
                                        'Acceso Bloqueado',
                                        style: GoogleFonts.poppins(
                                          fontSize: titleFontSize,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                          letterSpacing: 0.5,
                                          height: 1.2,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      SizedBox(height: isSmallScreen ? 6 : 10),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: isSmallScreen ? 12 : 16,
                                          vertical: isSmallScreen ? 6 : 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.15),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          border: Border.all(
                                            color:
                                                Colors.white.withOpacity(0.3),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.security_rounded,
                                              color: Colors.white
                                                  .withOpacity(0.95),
                                              size: isSmallScreen ? 14 : 16,
                                            ),
                                            SizedBox(width: 6),
                                            Text(
                                              'Seguridad Activada',
                                              style: GoogleFonts.poppins(
                                                fontSize: subtitleFontSize - 2,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.white
                                                    .withOpacity(0.95),
                                                letterSpacing: 0.3,
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

                          // ✅ Contenido con mejor diseño
                          Flexible(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.white,
                                    Colors.grey.shade50,
                                  ],
                                ),
                              ),
                              child: SingleChildScrollView(
                                padding: EdgeInsets.all(padding),
                                physics: BouncingScrollPhysics(),
                                child: Column(
                                  children: [
                                    // Alerta principal con mejor diseño
                                    Container(
                                      padding: EdgeInsets.all(infoPadding),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Colors.orange.shade50,
                                            Colors.orange.shade100
                                                .withOpacity(0.5),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(
                                            isSmallScreen ? 16 : 20),
                                        border: Border.all(
                                          color: Colors.orange.shade400,
                                          width: 2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.orange.withOpacity(0.15),
                                            blurRadius: 12,
                                            offset: Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        children: [
                                          Container(
                                            padding: EdgeInsets.all(
                                                isSmallScreen ? 10 : 12),
                                            decoration: BoxDecoration(
                                              color: Colors.orange.shade600,
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.orange.shade400
                                                      .withOpacity(0.4),
                                                  blurRadius: 8,
                                                  spreadRadius: 2,
                                                ),
                                              ],
                                            ),
                                            child: Icon(
                                              Icons.warning_rounded,
                                              color: Colors.white,
                                              size: isSmallScreen
                                                  ? 28
                                                  : (isMediumScreen ? 32 : 36),
                                            ),
                                          ),
                                          SizedBox(
                                              height: isSmallScreen ? 12 : 16),
                                          Text(
                                            'Límite de Intentos Excedido',
                                            style: GoogleFonts.poppins(
                                              fontSize: contentFontSize + 2,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.orange.shade900,
                                              letterSpacing: 0.3,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                          SizedBox(
                                              height: isSmallScreen ? 8 : 12),
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal:
                                                  isSmallScreen ? 12 : 16,
                                              vertical: isSmallScreen ? 8 : 10,
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                                  Colors.white.withOpacity(0.7),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: Colors.orange.shade200,
                                                width: 1,
                                              ),
                                            ),
                                            child: Text(
                                              'Por motivos de seguridad, la función de eliminación ha sido bloqueada temporalmente.',
                                              style: GoogleFonts.poppins(
                                                fontSize: contentFontSize - 2,
                                                color: Colors.orange.shade800,
                                                height: 1.4,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    SizedBox(height: isSmallScreen ? 20 : 28),

                                    // Información de horarios mejorada
                                    if (_horaBloqueo != null)
                                      Container(
                                        padding: EdgeInsets.all(infoPadding),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                              isSmallScreen ? 16 : 20),
                                          border: Border.all(
                                            color: Colors.grey.shade300,
                                            width: 1.5,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black
                                                  .withOpacity(0.05),
                                              blurRadius: 12,
                                              offset: Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          children: [
                                            // Bloqueado
                                            _buildTimeInfoRow(
                                              icon: Icons.lock_clock_rounded,
                                              iconColor: Colors.red.shade600,
                                              iconBgColor: Colors.red.shade50,
                                              label: 'Bloqueado',
                                              time: _horaBloqueo!,
                                              contentFontSize: contentFontSize,
                                              isSmallScreen: isSmallScreen,
                                            ),

                                            SizedBox(
                                                height:
                                                    isSmallScreen ? 12 : 16),

                                            // Divider elegante
                                            Container(
                                              height: 1,
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    Colors.transparent,
                                                    Colors.grey.shade300,
                                                    Colors.transparent,
                                                  ],
                                                ),
                                              ),
                                            ),

                                            SizedBox(
                                                height:
                                                    isSmallScreen ? 12 : 16),

                                            // Desbloqueado
                                            _buildTimeInfoRow(
                                              icon: Icons.lock_open_rounded,
                                              iconColor: Colors.green.shade600,
                                              iconBgColor: Colors.green.shade50,
                                              label: 'Se desbloqueará',
                                              time: horaDesbloqueoStr,
                                              contentFontSize: contentFontSize,
                                              isSmallScreen: isSmallScreen,
                                            ),
                                          ],
                                        ),
                                      ),

                                    SizedBox(height: isSmallScreen ? 20 : 28),

                                    // ✅ Contador de tiempo premium
                                    Container(
                                      padding: EdgeInsets.all(isSmallScreen
                                          ? 20
                                          : (isMediumScreen ? 24 : 28)),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Colors.red.shade50,
                                            Colors.red.shade100,
                                            Colors.red.shade50,
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(
                                            isSmallScreen ? 20 : 24),
                                        border: Border.all(
                                          color: Colors.red.shade300,
                                          width: 2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.red.withOpacity(0.2),
                                            blurRadius: 16,
                                            offset: Offset(0, 6),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Container(
                                                padding: EdgeInsets.all(
                                                    isSmallScreen ? 6 : 8),
                                                decoration: BoxDecoration(
                                                  color: Colors.red.shade600,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  Icons.timer_rounded,
                                                  color: Colors.white,
                                                  size: isSmallScreen ? 16 : 20,
                                                ),
                                              ),
                                              SizedBox(width: 10),
                                              Text(
                                                'Tiempo Restante',
                                                style: GoogleFonts.poppins(
                                                  fontSize: contentFontSize,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.red.shade900,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(
                                              height: isSmallScreen ? 16 : 24),

                                          // ✅ Layout adaptativo para el contador
                                          isSmallScreen
                                              ? Column(
                                                  children: [
                                                    _buildTimeUnit(
                                                        horas,
                                                        'Horas',
                                                        timeDigitSize,
                                                        timeLabelSize,
                                                        isSmallScreen),
                                                    SizedBox(height: 12),
                                                    _buildTimeUnit(
                                                        minutos,
                                                        'Minutos',
                                                        timeDigitSize,
                                                        timeLabelSize,
                                                        isSmallScreen),
                                                    SizedBox(height: 12),
                                                    _buildTimeUnit(
                                                        segundos,
                                                        'Segundos',
                                                        timeDigitSize,
                                                        timeLabelSize,
                                                        isSmallScreen),
                                                  ],
                                                )
                                              : Wrap(
                                                  alignment:
                                                      WrapAlignment.center,
                                                  crossAxisAlignment:
                                                      WrapCrossAlignment.center,
                                                  spacing:
                                                      isSmallScreen ? 8 : 16,
                                                  children: [
                                                    _buildTimeUnit(
                                                        horas,
                                                        'Horas',
                                                        timeDigitSize,
                                                        timeLabelSize,
                                                        isSmallScreen),
                                                    Text(
                                                      ':',
                                                      style:
                                                          GoogleFonts.poppins(
                                                        fontSize: timeDigitSize,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        color:
                                                            Colors.red.shade700,
                                                        height: 1,
                                                      ),
                                                    ),
                                                    _buildTimeUnit(
                                                        minutos,
                                                        'Minutos',
                                                        timeDigitSize,
                                                        timeLabelSize,
                                                        isSmallScreen),
                                                    Text(
                                                      ':',
                                                      style:
                                                          GoogleFonts.poppins(
                                                        fontSize: timeDigitSize,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        color:
                                                            Colors.red.shade700,
                                                        height: 1,
                                                      ),
                                                    ),
                                                    _buildTimeUnit(
                                                        segundos,
                                                        'Segundos',
                                                        timeDigitSize,
                                                        timeLabelSize,
                                                        isSmallScreen),
                                                  ],
                                                ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // ✅ Footer Premium
                          Container(
                            padding: EdgeInsets.all(padding),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border(
                                top: BorderSide(
                                  color: Colors.grey.shade200,
                                  width: 1,
                                ),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 12,
                                  offset: Offset(0, -4),
                                ),
                              ],
                            ),
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  _contadorBloqueoTimer?.cancel();
                                  Navigator.of(dialogContext).pop();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red.shade600,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(
                                    vertical: isSmallScreen ? 14 : 18,
                                    horizontal: isSmallScreen ? 24 : 32,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        isSmallScreen ? 12 : 16),
                                  ),
                                  elevation: 4,
                                  shadowColor:
                                      Colors.red.shade600.withOpacity(0.4),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.check_circle_rounded,
                                      size: isSmallScreen ? 20 : 24,
                                    ),
                                    SizedBox(width: isSmallScreen ? 8 : 12),
                                    Text(
                                      'Entendido',
                                      style: GoogleFonts.poppins(
                                        fontSize: isSmallScreen ? 15 : 18,
                                        fontWeight: FontWeight.w700,
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
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    ).then((_) {
      _contadorBloqueoTimer?.cancel();
    });
  }

// ✅ NUEVO MÉTODO para las filas de información de tiempo
  Widget _buildTimeInfoRow({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String label,
    required String time,
    required double contentFontSize,
    required bool isSmallScreen,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
          decoration: BoxDecoration(
            color: iconBgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: iconColor.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: isSmallScreen ? 20 : 24,
          ),
        ),
        SizedBox(width: isSmallScreen ? 12 : 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: contentFontSize - 4,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                  letterSpacing: 0.3,
                ),
              ),
              SizedBox(height: 4),
              Text(
                time,
                style: GoogleFonts.poppins(
                  fontSize: contentFontSize + 2,
                  fontWeight: FontWeight.w700,
                  color: iconColor,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

// ✅ REEMPLAZA el método _buildTimeUnit con esta versión premium
  Widget _buildTimeUnit(int value, String label, double digitSize,
      double labelSize, bool isSmallScreen) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 16 : 24,
            vertical: isSmallScreen ? 12 : 16,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFD32F2F),
                Color(0xFFC62828),
                Color(0xFFB71C1C),
              ],
            ),
            borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
            boxShadow: [
              BoxShadow(
                color: Colors.red.shade900.withOpacity(0.4),
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
              BoxShadow(
                color: Colors.red.withOpacity(0.2),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: Text(
            value.toString().padLeft(2, '0'),
            style: GoogleFonts.poppins(
              fontSize: digitSize,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 2,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.3),
                  offset: Offset(0, 2),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: isSmallScreen ? 6 : 10),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 8 : 12,
            vertical: isSmallScreen ? 4 : 6,
          ),
          decoration: BoxDecoration(
            color: Colors.red.shade700,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: labelSize,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.8,
            ),
          ),
        ),
      ],
    );
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
        _contrasenaTribuController.text.isEmpty ||
        categoriaSeleccionada == null) {
      _mostrarSnackBar('Por favor complete todos los campos');
      return;
    }

    try {
      // Crear el documento en la colección tribus
      DocumentReference tribuRef = await _firestore.collection('tribus').add({
        'nombre': _nombreTribuController.text,
        'nombreLider': _nombreLiderController.text,
        'apellidoLider': _apellidoLiderController.text,
        'usuario': _usuarioTribuController.text,
        'contrasena': _contrasenaTribuController.text,
        'categoria': categoriaSeleccionada,
        'rol': 'tribu',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Crear el usuario en la colección usuarios
      await _firestore.collection('usuarios').add({
        'usuario': _usuarioTribuController.text,
        'contrasena': _contrasenaTribuController.text,
        'rol': 'tribu',
        'tribuId': tribuRef.id,
        'nombre': _nombreTribuController.text,
        'categoria': categoriaSeleccionada,
      });

      _limpiarFormularioTribu();
      _mostrarSnackBar('Tribu creada exitosamente');
      setState(() => _mostrarFormularioTribu = false);
    } catch (e) {
      _mostrarSnackBar('Error al crear la tribu: $e');
    }
  }

// Variables de estado para loading
  bool _isEditingTribu = false;

// Colores definidos
  final Color primaryColor = Color(0xFF1B998B);
  final Color backgroundColor = Color(0xFFF5F5F5);

// Función para editar tribu - CORREGIDA
  Future<void> _editarTribu(String docId, Map<String, dynamic> datos) async {
    try {
      setState(() => _isEditingTribu = true);

      print('Iniciando edición de tribu con ID: $docId');

      // Primero obtenemos los datos actuales de la tribu para preservar campos que no se están editando
      final tribuDoc = await _firestore.collection('tribus').doc(docId).get();
      if (!tribuDoc.exists) {
        throw Exception('La tribu no existe');
      }

      final datosActuales = tribuDoc.data() as Map<String, dynamic>;

      // Preparar datos para actualización, preservando campos existentes
      final datosActualizacion = <String, dynamic>{
        'nombre': datos['nombre']?.toString().trim() ?? datosActuales['nombre'],
        'nombreLider': datos['nombreLider']?.toString().trim() ??
            datosActuales['nombreLider'],
        'apellidoLider': datos['apellidoLider']?.toString().trim() ??
            datosActuales['apellidoLider'],
        'usuario':
            datos['usuario']?.toString().trim() ?? datosActuales['usuario'],
        'contrasena': datos['contrasena']?.toString().trim() ??
            datosActuales['contrasena'],
        'categoria': datos['categoria'] ??
            datosActuales['categoria'], // Preserva la categoría
        // Preservar otros campos importantes
        'rol': datosActuales['rol'] ?? 'tribu',
        'createdAt': datosActuales['createdAt'],
      };

      // Actualizar documento en la colección tribus
      await _firestore
          .collection('tribus')
          .doc(docId)
          .update(datosActualizacion);
      print('Tribu actualizada exitosamente');

      // Actualizar en la colección de usuarios
      final usuarioQuery = await _firestore
          .collection('usuarios')
          .where('tribuId', isEqualTo: docId)
          .limit(1)
          .get();

      if (usuarioQuery.docs.isNotEmpty) {
        print('Usuario encontrado, actualizando datos');

        final usuarioDoc = usuarioQuery.docs.first;
        await usuarioDoc.reference.update({
          'usuario': datosActualizacion['usuario'],
          'contrasena': datosActualizacion['contrasena'],
          'nombre': datosActualizacion['nombre'],
          'categoria': datosActualizacion['categoria'],
          'rol': 'tribu',
        });

        print('Usuario actualizado exitosamente');
      } else {
        print('No se encontró usuario asociado, creando nuevo usuario');
        // Si no existe el usuario, lo creamos
        await _firestore.collection('usuarios').add({
          'usuario': datosActualizacion['usuario'],
          'contrasena': datosActualizacion['contrasena'],
          'rol': 'tribu',
          'tribuId': docId,
          'nombre': datosActualizacion['nombre'],
          'categoria': datosActualizacion['categoria'],
        });
      }

      _mostrarSnackBar('Tribu actualizada exitosamente', isSuccess: true);

      // Pequeña pausa para mostrar el feedback antes de cerrar
      await Future.delayed(Duration(milliseconds: 300));
    } catch (e) {
      print('Error al actualizar tribu: $e');
      _mostrarSnackBar('Error al actualizar la tribu: ${e.toString()}',
          isSuccess: false);
    } finally {
      if (mounted) {
        setState(() => _isEditingTribu = false);
      }
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
        'contrasena': _contrasenaLiderConsolidacionController.text,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Crear usuario en la colección de usuarios
      await _firestore.collection('usuarios').add({
        'usuario': _usuarioLiderConsolidacionController.text,
        'contrasena': _contrasenaLiderConsolidacionController.text,
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

// Variables de estado para loading
  bool _isEditingLiderConsolidacion = false;

// Función para editar líder de consolidación - CORREGIDA Y MEJORADA
  Future<void> _editarLiderConsolidacion(
      String docId, Map<String, dynamic> datos) async {
    try {
      setState(() => _isEditingLiderConsolidacion = true);

      print('Iniciando edición de líder de consolidación con ID: $docId');

      // Primero obtenemos los datos actuales para preservar información
      final liderDoc =
          await _firestore.collection('lideresConsolidacion').doc(docId).get();
      if (!liderDoc.exists) {
        throw Exception('El líder de consolidación no existe');
      }

      final datosActuales = liderDoc.data() as Map<String, dynamic>;

      // Preparar datos para actualización, preservando campos existentes
      final datosActualizacion = <String, dynamic>{
        'nombre': datos['nombre']?.toString().trim() ?? datosActuales['nombre'],
        'apellido':
            datos['apellido']?.toString().trim() ?? datosActuales['apellido'],
        'usuario':
            datos['usuario']?.toString().trim() ?? datosActuales['usuario'],
        'contrasena': datos['contrasena']?.toString().trim() ??
            datosActuales['contrasena'],
        // Preservar otros campos importantes
        'rol': datosActuales['rol'] ?? 'liderConsolidacion',
        'createdAt': datosActuales['createdAt'],
      };

      // Verificar si el nuevo usuario ya existe (si se está cambiando)
      if (datos['usuario']?.toString().trim() != datosActuales['usuario']) {
        final usuarioExistente = await _firestore
            .collection('usuarios')
            .where('usuario', isEqualTo: datosActualizacion['usuario'])
            .limit(1)
            .get();

        if (usuarioExistente.docs.isNotEmpty) {
          throw Exception('El nombre de usuario ya está en uso');
        }
      }

      // Actualizar el documento en la colección 'lideresConsolidacion'
      await _firestore
          .collection('lideresConsolidacion')
          .doc(docId)
          .update(datosActualizacion);
      print('Líder de consolidación actualizado exitosamente');

      // Buscar y actualizar el usuario en la colección 'usuarios'
      // Buscar por el usuario anterior para evitar problemas
      final usuarioQuery = await _firestore
          .collection('usuarios')
          .where('rol', isEqualTo: 'liderConsolidacion')
          .where('usuario', isEqualTo: datosActuales['usuario'])
          .limit(1)
          .get();

      if (usuarioQuery.docs.isNotEmpty) {
        print('Usuario encontrado, actualizando datos');

        await usuarioQuery.docs.first.reference.update({
          'usuario': datosActualizacion['usuario'],
          'contrasena': datosActualizacion['contrasena'],
          'nombre': datosActualizacion['nombre'],
          'apellido': datosActualizacion['apellido'],
          'rol': 'liderConsolidacion',
        });

        print('Usuario actualizado exitosamente');
      } else {
        print('No se encontró usuario asociado, creando nuevo usuario');
        // Si no existe el usuario, lo creamos
        await _firestore.collection('usuarios').add({
          'usuario': datosActualizacion['usuario'],
          'contrasena': datosActualizacion['contrasena'],
          'rol': 'liderConsolidacion',
          'nombre': datosActualizacion['nombre'],
          'apellido': datosActualizacion['apellido'],
        });
      }

      _mostrarSnackBar('Líder de consolidación actualizado exitosamente',
          isSuccess: true);

      // Pequeña pausa para mostrar el feedback antes de cerrar
      await Future.delayed(Duration(milliseconds: 300));
    } catch (e) {
      print('Error al actualizar líder de consolidación: $e');
      _mostrarSnackBar('Error al actualizar el líder: ${e.toString()}',
          isSuccess: false);
    } finally {
      if (mounted) {
        setState(() => _isEditingLiderConsolidacion = false);
      }
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

  void _mostrarSnackBar(String mensaje, {bool isSuccess = true}) {
    if (!mounted) return;

    // Resetear timer cuando hay actividad
    _resetInactivityTimer();

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isSuccess ? Icons.check_circle_rounded : Icons.error_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                mensaje,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isSuccess ? primaryColor : Colors.red[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: EdgeInsets.all(16),
        duration: Duration(seconds: isSuccess ? 2 : 4),
        elevation: 6,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: kPrimaryColor,
        automaticallyImplyLeading: false,
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
        toolbarHeight:
            MediaQuery.of(context).size.height * 0.10, // Altura dinámica
        title: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = MediaQuery.of(context).size.width;
            final isSmallScreen = screenWidth < 400;
            final isMediumScreen = screenWidth >= 400 && screenWidth < 600;

            return Row(
              children: [
                // Logo con animación sutil
                Hero(
                  tag: 'logo_cocep',
                  child: Container(
                    padding: EdgeInsets.all(isSmallScreen ? 3 : 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Container(
                      height: isSmallScreen ? 36 : 42,
                      width: isSmallScreen ? 36 : 42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/Cocep_.png',
                          height: isSmallScreen ? 36 : 42,
                          width: isSmallScreen ? 36 : 42,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: isSmallScreen ? 8 : 12),

                // Título responsivo con múltiples líneas
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Panel de',
                        style: GoogleFonts.poppins(
                          color: Colors.white.withOpacity(0.95),
                          fontWeight: FontWeight.w600,
                          fontSize:
                              isSmallScreen ? 14 : (isMediumScreen ? 16 : 18),
                          height: 1.1,
                          letterSpacing: 0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Administración',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize:
                              isSmallScreen ? 16 : (isMediumScreen ? 18 : 22),
                          height: 1.1,
                          letterSpacing: 0.5,
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
                  ),
                ),

                SizedBox(width: isSmallScreen ? 6 : 8),

                // Botón de cerrar sesión mejorado y responsivo
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _confirmarCerrarSesion,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 8 : 12,
                        vertical: isSmallScreen ? 8 : 10,
                      ),
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
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.logout_rounded,
                            color: Colors.white,
                            size: isSmallScreen ? 18 : 20,
                          ),
                          if (!isSmallScreen) ...[
                            SizedBox(width: 6),
                            Text(
                              'Cerrar\nsesión',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                height: 1.1,
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
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(55),
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            height: 45,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white.withOpacity(0.15),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              labelColor: kPrimaryColor,
              unselectedLabelColor: Colors.white,
              labelStyle: GoogleFonts.poppins(
                fontSize: MediaQuery.of(context).size.width < 400 ? 11 : 13,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: GoogleFonts.poppins(
                fontSize: MediaQuery.of(context).size.width < 400 ? 10 : 12,
                fontWeight: FontWeight.w500,
              ),
              isScrollable: MediaQuery.of(context).size.width < 500,
              labelPadding: EdgeInsets.symmetric(horizontal: 8),
              tabs: [
                Tab(
                  height: 35,
                  icon: Icon(
                    Icons.emoji_people,
                    size: MediaQuery.of(context).size.width < 400 ? 18 : 20,
                  ),
                  text: 'Juvenil',
                ),
                Tab(
                  height: 35,
                  icon: Icon(
                    Icons.handshake,
                    size: MediaQuery.of(context).size.width < 400 ? 18 : 20,
                  ),
                  text: 'Líder de Consolidación',
                ),
                Tab(
                  height: 35,
                  icon: Icon(
                    Icons.woman,
                    size: MediaQuery.of(context).size.width < 400 ? 18 : 20,
                  ),
                  text: 'Damas',
                ),
                Tab(
                  height: 35,
                  icon: Icon(
                    Icons.man,
                    size: MediaQuery.of(context).size.width < 400 ? 18 : 20,
                  ),
                  text: 'Caballeros',
                ),
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
            _buildMinisterioTab('Ministerio de Damas'),
            _buildMinisterioTab('Ministerio de Caballeros'),
          ],
        ),
      ),
      floatingActionButton: Container(
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom +
              100, // Margen adaptativo más grande
          right: 16,
        ),
        child: FloatingActionButton.extended(
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => StatisticsDialog(),
            );
          },
          backgroundColor: Colors.orange,
          elevation: 8,
          label: Text(
            'Estadísticas',
            style: GoogleFonts.poppins(
              fontSize: MediaQuery.of(context).size.width < 400 ? 12 : 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          icon: Icon(
            Icons.bar_chart,
            size: MediaQuery.of(context).size.width < 400 ? 18 : 24,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      extendBody: false,
    );
  }

  Widget _buildMinisterioTab(String ministerio) {
    return Column(
      children: [
        // Using StreamBuilder to check if leader exists to show/hide button
        StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('lideresMinisterio')
              .where('ministerio', isEqualTo: ministerio)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData)
              return const Center(
                  child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1B998B)),
              ));

            final docs = snapshot.data!.docs;
            // Only show create button if no leader exists
            if (docs.isEmpty) {
              return Container(
                margin: const EdgeInsets.all(16),
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _crearLiderMinisterio(ministerio),
                  icon: const Icon(Icons.add_circle),
                  label: Text('Crear Líder de $ministerio'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B998B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                ),
              );
            } else {
              return const SizedBox.shrink(); // Hide button if leader exists
            }
          },
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('lideresMinisterio')
                .where('ministerio', isEqualTo: ministerio)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return const Center(
                    child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1B998B)),
                ));

              final docs = snapshot.data!.docs;

              if (docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_add, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No hay líder de $ministerio asignado',
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

              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 4,
                    shadowColor: const Color(0xFF1B998B).withOpacity(0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(
                        color: Color(0xFF1B998B),
                        width: 1,
                      ),
                    ),
                    child: ExpansionTile(
                      leading: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFF26419), Color(0xFFFF9E00)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const CircleAvatar(
                          backgroundColor: Colors.white,
                          child: Icon(Icons.person, color: Color(0xFF1B998B)),
                        ),
                      ),
                      title: Text(
                        '${data['nombre']} ${data['apellido']}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      subtitle: RichText(
                        text: TextSpan(
                          style: const TextStyle(color: Color(0xFF5D6D7E)),
                          children: [
                            const WidgetSpan(
                              child: Icon(Icons.account_circle,
                                  size: 16, color: Color(0xFF1B998B)),
                              alignment: PlaceholderAlignment.middle,
                            ),
                            const TextSpan(text: ' '),
                            TextSpan(text: '${data['usuario']}'),
                          ],
                        ),
                      ),
                      trailing: const Icon(Icons.expand_more,
                          color: Color(0xFF1B998B)),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color:
                                      const Color(0xFF1B998B).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xFF1B998B)
                                        .withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.password,
                                        size: 16, color: Color(0xFF1B998B)),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Contraseña: ${data['contrasena']}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  // New edit button for leader
                                  IconButton(
                                    icon: const Icon(Icons.edit,
                                        color: Color(0xFF1B998B)),
                                    onPressed: () {
                                      // Add function to edit leader
                                      _editarLiderMinisterio(
                                          docs[index].id, data);
                                    },
                                    tooltip: 'Editar líder',
                                    style: IconButton.styleFrom(
                                      backgroundColor: const Color(0xFF1B998B)
                                          .withOpacity(0.1),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.visibility),
                                    label: const Text('Ir a pantalla'),
                                    onPressed: () {
                                      context.push('/ministerio_lider', extra: {
                                        'ministerio': data['ministerio']
                                      });
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1B998B),
                                      foregroundColor: Colors.white,
                                      elevation: 3,
                                      shadowColor: const Color(0xFF1B998B)
                                          .withOpacity(0.5),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Divider(thickness: 1),
                        StreamBuilder<QuerySnapshot>(
                          stream: _firestore.collection('tribus').snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData)
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Color(0xFF1B998B)),
                                  ),
                                ),
                              );

                            final allTribus = snapshot.data!.docs;

                            // Filtrar las tribus por ministerio en memoria
                            final tribus = allTribus.where((doc) {
                              final tribuData =
                                  doc.data() as Map<String, dynamic>;
                              return tribuData['categoria'] == ministerio;
                            }).toList();

                            // Ordenar por fecha de creación
                            // Ordenar por fecha de creación manualmente (con manejo de nulos)
                            tribus.sort((a, b) {
                              try {
                                final aData = a.data() as Map<String, dynamic>;
                                final bData = b.data() as Map<String, dynamic>;

                                // Verificar si ambos tienen createdAt
                                if (!aData.containsKey('createdAt') ||
                                    aData['createdAt'] == null) {
                                  return 1; // Mover al final
                                }
                                if (!bData.containsKey('createdAt') ||
                                    bData['createdAt'] == null) {
                                  return -1; // Mover al final
                                }

                                final aDate = aData['createdAt'] as Timestamp;
                                final bDate = bData['createdAt'] as Timestamp;
                                return bDate
                                    .compareTo(aDate); // orden descendente
                              } catch (e) {
                                print('Error al ordenar tribus: $e');
                                return 0; // Mantener orden si hay error
                              }
                            });

                            if (tribus.isEmpty) {
                              return Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Center(
                                  child: Column(
                                    children: [
                                      Icon(Icons.groups_outlined,
                                          size: 48, color: Colors.grey[400]),
                                      const SizedBox(height: 8),
                                      Text(
                                        'No hay tribus en este ministerio',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFF1B998B),
                                              Color(0xFF2BCFB1)
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.groups,
                                                size: 18, color: Colors.white),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Tribus (${tribus.length})',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: tribus.length,
                                  itemBuilder: (context, index) {
                                    final tribu = tribus[index];
                                    final tribuData =
                                        tribu.data() as Map<String, dynamic>;
                                    return Card(
                                      margin: const EdgeInsets.fromLTRB(
                                          16, 0, 16, 16),
                                      elevation: 2,
                                      shadowColor: Colors.grey.withOpacity(0.3),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        side: BorderSide(
                                          color: const Color(0xFF1B998B)
                                              .withOpacity(0.2),
                                          width: 1,
                                        ),
                                      ),
                                      child: ExpansionTile(
                                        leading: Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [
                                                Color(0xFF1B998B),
                                                Color(0xFF2BCFB1)
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(30),
                                          ),
                                          child: const CircleAvatar(
                                            backgroundColor: Colors.white,
                                            child: Icon(Icons.groups,
                                                color: Color(0xFF1B998B)),
                                          ),
                                        ),
                                        title: Text(
                                          tribuData['nombre'] ?? '',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                            color: Color(0xFF2C3E50),
                                          ),
                                        ),
                                        subtitle: RichText(
                                          text: TextSpan(
                                            style: const TextStyle(
                                                color: Color(0xFF5D6D7E)),
                                            children: [
                                              const WidgetSpan(
                                                child: Icon(Icons.person,
                                                    size: 14,
                                                    color: Color(0xFF1B998B)),
                                                alignment:
                                                    PlaceholderAlignment.middle,
                                              ),
                                              const TextSpan(text: ' '),
                                              TextSpan(
                                                  text:
                                                      '${tribuData['nombreLider']} ${tribuData['apellidoLider']}'),
                                            ],
                                          ),
                                        ),
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.all(16.0),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                _buildInfoRowEnhanced(
                                                  'Usuario:',
                                                  tribuData['usuario'] ?? '',
                                                  Icons.account_circle,
                                                ),
                                                const SizedBox(height: 8),
                                                _buildInfoRowEnhanced(
                                                  'Contraseña:',
                                                  tribuData['contrasena'] ?? '',
                                                  Icons.password,
                                                ),
                                                const SizedBox(height: 16),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.all(12),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        const Color(0xFF1B998B)
                                                            .withOpacity(0.05),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                    border: Border.all(
                                                      color: const Color(
                                                              0xFF1B998B)
                                                          .withOpacity(0.2),
                                                    ),
                                                  ),
                                                  child:
                                                      _buildEstadisticasTribu(
                                                          tribu.id),
                                                ),
                                                const SizedBox(height: 16),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.end,
                                                  children: [
                                                    IconButton(
                                                      icon: const Icon(
                                                          Icons.edit),
                                                      onPressed: () =>
                                                          _mostrarDialogoEditarTribu(
                                                              tribu.id,
                                                              tribuData),
                                                      tooltip: 'Editar',
                                                      style:
                                                          IconButton.styleFrom(
                                                        backgroundColor:
                                                            const Color(
                                                                    0xFF1B998B)
                                                                .withOpacity(
                                                                    0.1),
                                                        foregroundColor:
                                                            const Color(
                                                                0xFF1B998B),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    IconButton(
                                                      icon: const Icon(
                                                          Icons.delete),
                                                      onPressed: () =>
                                                          _mostrarDialogoConfirmarEliminarTribu(
                                                              tribu.id),
                                                      tooltip: 'Eliminar',
                                                      style:
                                                          IconButton.styleFrom(
                                                        backgroundColor: Colors
                                                            .red
                                                            .withOpacity(0.1),
                                                        foregroundColor:
                                                            Colors.red,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    ElevatedButton.icon(
                                                      icon: const Icon(
                                                          Icons.visibility),
                                                      label: const Text(
                                                          'Ver Detalles'),
                                                      onPressed: () {
                                                        Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (context) =>
                                                                TribusScreen(
                                                              tribuId: tribu.id,
                                                              tribuNombre:
                                                                  tribuData[
                                                                          'nombre'] ??
                                                                      '',
                                                            ),
                                                          ),
                                                        );
                                                      },
                                                      style: ElevatedButton
                                                          .styleFrom(
                                                        backgroundColor:
                                                            const Color(
                                                                0xFF1B998B),
                                                        foregroundColor:
                                                            Colors.white,
                                                        elevation: 2,
                                                        shadowColor:
                                                            const Color(
                                                                    0xFF1B998B)
                                                                .withOpacity(
                                                                    0.5),
                                                        shape:
                                                            RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(10),
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
                                ),
                              ],
                            );
                          },
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

// Enhanced info row with icon
  Widget _buildInfoRowEnhanced(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1B998B).withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF1B998B)),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Color(0xFF2C3E50)),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

// Method to edit ministry leader (you'll need to implement this function)
  void _editarLiderMinisterio(String id, Map<String, dynamic> data) {
    // Create a form to edit the leader's information
    final nombreController = TextEditingController(text: data['nombre']);
    final apellidoController = TextEditingController(text: data['apellido']);
    final usuarioController = TextEditingController(text: data['usuario']);
    final contrasenaController =
        TextEditingController(text: data['contrasena']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.edit, color: Color(0xFF1B998B)),
            const SizedBox(width: 8),
            Text('Editar Líder de ${data['ministerio']}'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person, color: Color(0xFF1B998B)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: apellidoController,
                decoration: const InputDecoration(
                  labelText: 'Apellido',
                  border: OutlineInputBorder(),
                  prefixIcon:
                      Icon(Icons.person_outline, color: Color(0xFF1B998B)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: usuarioController,
                decoration: const InputDecoration(
                  labelText: 'Usuario',
                  border: OutlineInputBorder(),
                  prefixIcon:
                      Icon(Icons.account_circle, color: Color(0xFF1B998B)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: contrasenaController,
                decoration: const InputDecoration(
                  labelText: 'Contraseña',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.password, color: Color(0xFF1B998B)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              // Update the leader information in Firestore
              _firestore.collection('lideresMinisterio').doc(id).update({
                'nombre': nombreController.text.trim(),
                'apellido': apellidoController.text.trim(),
                'usuario': usuarioController.text.trim(),
                'contrasena': contrasenaController.text.trim(),
              }).then((_) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Líder actualizado con éxito'),
                    backgroundColor: Color(0xFF1B998B),
                  ),
                );
              }).catchError((error) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $error'),
                    backgroundColor: Colors.red,
                  ),
                );
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B998B),
              foregroundColor: Colors.white,
            ),
            child: const Text('Guardar'),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _actionButton(
      String text, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton.icon(
      icon: Icon(icon, color: Colors.white, size: 18),
      label: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      onPressed: onPressed,
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: kTextColor.withOpacity(0.7)),
      prefixIcon: Icon(icon, color: kPrimaryColor),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: kPrimaryColor.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: kPrimaryColor, width: 2),
      ),
      contentPadding: EdgeInsets.symmetric(vertical: 16),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: kPrimaryColor.withOpacity(0.5)),
      ),
    );
  }

// Función para crear líder de ministerio - MEJORADA
  Future<void> _crearLiderMinisterio(String ministerio) async {
    try {
      // Verificar si ya existe un líder para el ministerio
      final snapshot = await _firestore
          .collection('lideresMinisterio')
          .where('ministerio', isEqualTo: ministerio)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        _mostrarSnackBar('Ya existe un líder para este ministerio',
            isSuccess: false);
        return;
      }

      // Mostrar diálogo para capturar datos del líder
      final TextEditingController nombreController = TextEditingController();
      final TextEditingController apellidoController = TextEditingController();
      final TextEditingController usuarioController = TextEditingController();
      final TextEditingController contrasenaController =
          TextEditingController();
      bool isCreatingLeader = false;

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setDialogState) => AlertDialog(
              backgroundColor: backgroundColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Container(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.admin_panel_settings_rounded,
                        color: primaryColor,
                        size: 24,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Crear Líder',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                          Text(
                            'Ministerio: $ministerio',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              content: Container(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildEditTextField(
                        controller: nombreController,
                        label: 'Nombre',
                        icon: Icons.person_rounded,
                        enabled: !isCreatingLeader,
                      ),
                      SizedBox(height: 16),
                      _buildEditTextField(
                        controller: apellidoController,
                        label: 'Apellido',
                        icon: Icons.person_outline_rounded,
                        enabled: !isCreatingLeader,
                      ),
                      SizedBox(height: 16),
                      _buildEditTextField(
                        controller: usuarioController,
                        label: 'Usuario',
                        icon: Icons.account_circle_rounded,
                        enabled: !isCreatingLeader,
                      ),
                      SizedBox(height: 16),
                      _buildEditTextField(
                        controller: contrasenaController,
                        label: 'Contraseña',
                        icon: Icons.lock_rounded,
                        obscureText: true,
                        enabled: !isCreatingLeader,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                Container(
                  width: double.maxFinite,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: isCreatingLeader
                              ? null
                              : () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            'Cancelar',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isCreatingLeader
                              ? null
                              : () async {
                                  if (nombreController.text.trim().isEmpty ||
                                      apellidoController.text.trim().isEmpty ||
                                      usuarioController.text.trim().isEmpty ||
                                      contrasenaController.text
                                          .trim()
                                          .isEmpty) {
                                    _mostrarSnackBar(
                                        'Complete todos los campos',
                                        isSuccess: false);
                                    return;
                                  }

                                  setDialogState(() => isCreatingLeader = true);

                                  try {
                                    // Verificar si el usuario ya existe
                                    final usuarioExistente = await _firestore
                                        .collection('usuarios')
                                        .where('usuario',
                                            isEqualTo:
                                                usuarioController.text.trim())
                                        .limit(1)
                                        .get();

                                    if (usuarioExistente.docs.isNotEmpty) {
                                      _mostrarSnackBar('El usuario ya existe',
                                          isSuccess: false);
                                      setDialogState(
                                          () => isCreatingLeader = false);
                                      return;
                                    }

                                    // Crear líder en Firebase
                                    await _firestore
                                        .collection('lideresMinisterio')
                                        .add({
                                      'nombre': nombreController.text.trim(),
                                      'apellido':
                                          apellidoController.text.trim(),
                                      'usuario': usuarioController.text.trim(),
                                      'contrasena':
                                          contrasenaController.text.trim(),
                                      'ministerio': ministerio,
                                      'createdAt': FieldValue.serverTimestamp(),
                                    });

                                    // Crear usuario en la colección de usuarios
                                    await _firestore
                                        .collection('usuarios')
                                        .add({
                                      'usuario': usuarioController.text.trim(),
                                      'contrasena':
                                          contrasenaController.text.trim(),
                                      'rol': 'liderMinisterio',
                                      'ministerio': ministerio,
                                      'nombre': nombreController.text.trim(),
                                      'apellido':
                                          apellidoController.text.trim(),
                                    });

                                    Navigator.pop(context);
                                    _mostrarSnackBar(
                                        'Líder creado exitosamente',
                                        isSuccess: true);

                                    if (mounted) {
                                      setState(() {});
                                    }
                                  } catch (e) {
                                    print('Error al crear líder: $e');
                                    _mostrarSnackBar(
                                        'Error al crear el líder: ${e.toString()}',
                                        isSuccess: false);
                                    setDialogState(
                                        () => isCreatingLeader = false);
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 2,
                          ),
                          child: isCreatingLeader
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.white),
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Text('Creando...'),
                                  ],
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_rounded, size: 18),
                                    SizedBox(width: 6),
                                    Text(
                                      'Crear',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600),
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
          );
        },
      );
    } catch (e) {
      print('Error en _crearLiderMinisterio: $e');
      _mostrarSnackBar('Error inesperado: ${e.toString()}', isSuccess: false);
    }
  }

  Widget _buildTribusTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!_mostrarFormularioTribu)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF1B998B).withOpacity(0.1),
                    const Color(0xFF1B998B).withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: const Color(0xFF1B998B).withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  bool isSmallScreen = constraints.maxWidth < 600;

                  return isSmallScreen
                      ? Column(
                          children: [
                            _buildActionButton(
                              onPressed: () => setState(
                                  () => _mostrarFormularioTribu = true),
                              icon: Icons.add_circle_outline,
                              label: 'Crear Nueva Tribu',
                              color: const Color(0xFF1B998B),
                              isFullWidth: true,
                            ),
                            const SizedBox(height: 12),
                            _buildActionButton(
                              onPressed: _mostrarDialogoSeleccionTribus,
                              icon: Icons.merge_type,
                              label: 'Unir Tribus',
                              color: const Color(0xFF1B998B),
                              isFullWidth: true,
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF1B998B),
                                  const Color(0xFF159B8C),
                                ],
                              ),
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: _buildActionButton(
                                onPressed: () => setState(
                                    () => _mostrarFormularioTribu = true),
                                icon: Icons.add_circle_outline,
                                label: 'Crear Nueva Tribu',
                                color: const Color(0xFF1B998B),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildActionButton(
                                onPressed: _mostrarDialogoSeleccionTribus,
                                icon: Icons.merge_type,
                                label: 'Unir Tribus',
                                color: const Color(0xFF1B998B),
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFF1B998B),
                                    const Color(0xFF159B8C),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                },
              ),
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

  Widget _buildActionButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color color,
    Gradient? gradient,
    bool isFullWidth = false,
  }) {
    return Container(
      width: isFullWidth ? double.infinity : null,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: gradient == null ? color : null,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
          shadowColor: color.withOpacity(0.3),
        ).copyWith(
          backgroundColor: gradient != null
              ? MaterialStateProperty.all(Colors.transparent)
              : null,
        ),
      ),
    );
  }

  Future<void> _mostrarDialogoSeleccionTribus() async {
    String? ministerioSeleccionado;
    String? tribu1Id;
    String? tribu2Id;
    String? nuevoNombre;
    String? nuevoNombreLider;
    String? nuevoApellidoLider;
    String? nuevoUsuario;
    String? nuevaContrasena;
    bool mantenerDatos = true;
    bool isLoading = false;

    final List<Map<String, dynamic>> ministerios = [
      {
        'nombre': 'Ministerio Juvenil',
        'icon': Icons.group,
        'color': const Color(0xFF1B998B),
      },
      {
        'nombre': 'Ministerio de Damas',
        'icon': Icons.woman,
        'color': const Color(0xFF1B998B),
      },
      {
        'nombre': 'Ministerio de Caballeros',
        'icon': Icons.man,
        'color': const Color(0xFF1B998B),
      },
    ];

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF1B998B),
                            const Color(0xFF159B8C),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.merge_type,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 15),
                    const Expanded(
                      child: Text(
                        'Unir Tribus por Ministerio',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              content: SingleChildScrollView(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.8,
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Selección de Ministerio
                      const Text(
                        '1. Selecciona el Ministerio',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF1B998B).withOpacity(0.3),
                          ),
                        ),
                        child: DropdownButtonFormField<String>(
                          value: ministerioSeleccionado,
                          decoration: InputDecoration(
                            prefixIcon: Container(
                              margin: const EdgeInsets.all(8),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1B998B).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.church,
                                color: const Color(0xFF1B998B),
                                size: 20,
                              ),
                            ),
                            labelText: 'Ministerio',
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                          items: ministerios.map((ministerio) {
                            return DropdownMenuItem<String>(
                              value: ministerio['nombre'],
                              child: Row(
                                children: [
                                  Icon(
                                    ministerio['icon'],
                                    color: ministerio['color'],
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    ministerio['nombre'],
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: isLoading
                              ? null
                              : (value) {
                                  setState(() {
                                    ministerioSeleccionado = value;
                                    tribu1Id = null;
                                    tribu2Id = null;
                                  });
                                },
                        ),
                      ),

                      if (ministerioSeleccionado != null) ...[
                        const SizedBox(height: 24),
                        const Text(
                          '2. Selecciona las Tribus a Unir',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        const SizedBox(height: 12),
                        FutureBuilder<QuerySnapshot>(
                          future: _firestore
                              .collection('tribus')
                              .where('categoria',
                                  isEqualTo: ministerioSeleccionado)
                              .get(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Container(
                                height: 100,
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 30,
                                        height: 30,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 3,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            const Color(0xFF1B998B),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      const Text(
                                        'Cargando tribus...',
                                        style: TextStyle(
                                          color: Color(0xFF7F8C8D),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            if (snapshot.hasError) {
                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.red.withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.error_outline,
                                        color: Colors.red),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Error al cargar las tribus',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            if (!snapshot.hasData ||
                                snapshot.data!.docs.isEmpty) {
                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.orange.withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.info_outline,
                                        color: Colors.orange),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'No hay tribus disponibles en este ministerio',
                                        style: TextStyle(
                                            color: Colors.orange.shade700),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            final tribus = snapshot.data!.docs;

                            if (tribus.length < 2) {
                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.orange.withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.warning_outlined,
                                        color: Colors.orange),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Se necesitan al menos 2 tribus para realizar la unión',
                                        style: TextStyle(
                                            color: Colors.orange.shade700),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            final dropdownItems = tribus.map((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              return DropdownMenuItem<String>(
                                value: doc.id,
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1B998B)
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Icon(
                                        Icons.groups,
                                        color: const Color(0xFF1B998B),
                                        size: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        data['nombre'] ?? 'Sin nombre',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList();

                            return Column(
                              children: [
                                // Primera Tribu
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFF1B998B)
                                          .withOpacity(0.3),
                                    ),
                                  ),
                                  child: DropdownButtonFormField<String>(
                                    value: tribu1Id,
                                    decoration: InputDecoration(
                                      prefixIcon: Container(
                                        margin: const EdgeInsets.all(8),
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1B998B)
                                              .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          '1',
                                          style: TextStyle(
                                            color: const Color(0xFF1B998B),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      labelText: 'Primera Tribu (Destino)',
                                      border: InputBorder.none,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 16,
                                      ),
                                    ),
                                    items: dropdownItems,
                                    onChanged: isLoading
                                        ? null
                                        : (value) {
                                            setState(() {
                                              tribu1Id = value;
                                              if (tribu2Id == value) {
                                                tribu2Id = null;
                                              }
                                            });
                                          },
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Segunda Tribu
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFF1B998B)
                                          .withOpacity(0.3),
                                    ),
                                  ),
                                  child: DropdownButtonFormField<String>(
                                    value: tribu2Id,
                                    decoration: InputDecoration(
                                      prefixIcon: Container(
                                        margin: const EdgeInsets.all(8),
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          '2',
                                          style: TextStyle(
                                            color: Colors.orange.shade700,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      labelText: 'Segunda Tribu (Se eliminará)',
                                      border: InputBorder.none,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 16,
                                      ),
                                    ),
                                    items: dropdownItems
                                        .where((item) => item.value != tribu1Id)
                                        .toList(),
                                    onChanged: isLoading
                                        ? null
                                        : (value) {
                                            setState(() {
                                              tribu2Id = value;
                                            });
                                          },
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],

                      if (tribu1Id != null && tribu2Id != null) ...[
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF1B998B).withOpacity(0.1),
                                const Color(0xFF1B998B).withOpacity(0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF1B998B).withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: const Color(0xFF1B998B),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  const Expanded(
                                    child: Text(
                                      'Configuración de Unión',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2C3E50),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              CheckboxListTile(
                                value: mantenerDatos,
                                onChanged: isLoading
                                    ? null
                                    : (value) {
                                        setState(() {
                                          mantenerDatos = value ?? true;
                                        });
                                      },
                                title: const Text(
                                  'Mantener datos de la primera tribu',
                                  style: TextStyle(fontSize: 14),
                                ),
                                subtitle: const Text(
                                  'Si se desmarca, podrás establecer nuevos datos',
                                  style: TextStyle(
                                      fontSize: 12, color: Color(0xFF7F8C8D)),
                                ),
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                activeColor: const Color(0xFF1B998B),
                              ),
                            ],
                          ),
                        ),
                        if (!mantenerDatos) ...[
                          const SizedBox(height: 16),
                          const Text(
                            '3. Nuevos Datos para la Tribu Unificada',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildCustomTextField(
                            onChanged: (value) => nuevoNombre = value,
                            labelText: 'Nuevo nombre de tribu',
                            icon: Icons.group_outlined,
                            enabled: !isLoading,
                          ),
                          const SizedBox(height: 12),
                          _buildCustomTextField(
                            onChanged: (value) => nuevoNombreLider = value,
                            labelText: 'Nuevo nombre del líder',
                            icon: Icons.person_outline,
                            enabled: !isLoading,
                          ),
                          const SizedBox(height: 12),
                          _buildCustomTextField(
                            onChanged: (value) => nuevoApellidoLider = value,
                            labelText: 'Nuevo apellido del líder',
                            icon: Icons.person_outline,
                            enabled: !isLoading,
                          ),
                          const SizedBox(height: 12),
                          _buildCustomTextField(
                            onChanged: (value) => nuevoUsuario = value,
                            labelText: 'Nuevo usuario',
                            icon: Icons.account_circle_outlined,
                            enabled: !isLoading,
                          ),
                          const SizedBox(height: 12),
                          _buildCustomTextField(
                            onChanged: (value) => nuevaContrasena = value,
                            labelText: 'Nueva contraseña',
                            icon: Icons.lock_outline,
                            isPassword: true,
                            enabled: !isLoading,
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(context),
                  child: Text(
                    'Cancelar',
                    style: TextStyle(
                      color: isLoading ? Colors.grey : const Color(0xFF7F8C8D),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF1B998B),
                        const Color(0xFF159B8C),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ElevatedButton.icon(
                    onPressed:
                        (tribu1Id != null && tribu2Id != null && !isLoading)
                            ? () async {
                                setState(() {
                                  isLoading = true;
                                });

                                try {
                                  Navigator.pop(context);
                                  await _confirmarUnionTribusConClave(
                                    tribu1Id!,
                                    tribu2Id!,
                                    mantenerDatos,
                                    nuevoNombre,
                                    nuevoNombreLider,
                                    nuevoApellidoLider,
                                    nuevoUsuario,
                                    nuevaContrasena,
                                  );
                                } catch (e) {
                                  setState(() {
                                    isLoading = false;
                                  });
                                  _mostrarSnackBar(
                                      'Error al unir las tribus: ${e.toString()}');
                                }
                              }
                            : null,
                    icon: isLoading
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Icon(Icons.merge_type,
                            color: Colors.white, size: 18),
                    label: Text(
                      isLoading ? 'Uniendo...' : 'Unir Tribus',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _confirmarUnionTribusConClave(
    String tribu1Id,
    String tribu2Id,
    bool mantenerDatos,
    String? nuevoNombre,
    String? nuevoNombreLider,
    String? nuevoApellidoLider,
    String? nuevoUsuario,
    String? nuevaContrasena,
  ) async {
    final TextEditingController claveController = TextEditingController();
    bool isProcessing = false;
    bool obscurePassword = true;

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Container(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.security_rounded,
                    color: Colors.orange[700],
                    size: 24,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Confirmar Unión',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[700],
                        ),
                      ),
                      Text(
                        'Autorización requerida',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          content: Container(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: Colors.orange[700],
                          size: 20,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Esta acción unirá las tribus seleccionadas. Ingrese la clave de seguridad para continuar.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.orange[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Ingrese la clave de confirmación:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: claveController,
                      obscureText: obscurePassword,
                      enabled: !isProcessing,
                      enableInteractiveSelection: false,
                      autocorrect: false,
                      enableSuggestions: false,
                      keyboardType: TextInputType.visiblePassword,
                      style: TextStyle(
                        color: isProcessing ? Colors.grey[400] : Colors.black87,
                        fontSize: 16,
                        letterSpacing: obscurePassword ? 3 : 0,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Clave de confirmación',
                        hintText: 'Ingrese la clave',
                        hintStyle: TextStyle(
                          color: Colors.grey[400],
                          letterSpacing: 0,
                        ),
                        prefixIcon: Container(
                          margin: EdgeInsets.all(8),
                          padding: EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isProcessing
                                ? Colors.grey.withOpacity(0.1)
                                : Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.lock_rounded,
                            color: isProcessing
                                ? Colors.grey[400]
                                : Colors.orange[700],
                            size: 20,
                          ),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            color: isProcessing
                                ? Colors.grey[400]
                                : Colors.grey[600],
                            size: 20,
                          ),
                          onPressed: isProcessing
                              ? null
                              : () {
                                  setDialogState(() {
                                    obscurePassword = !obscurePassword;
                                  });
                                },
                        ),
                        border: InputBorder.none,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        labelStyle: TextStyle(
                          color: isProcessing
                              ? Colors.grey[400]
                              : Colors.orange[700],
                          fontSize: 14,
                        ),
                        floatingLabelStyle: TextStyle(
                          color: Colors.orange[700],
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            Container(
              width: double.maxFinite,
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: isProcessing
                          ? null
                          : () {
                              claveController.clear();
                              Navigator.pop(context);
                            },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Cancelar',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isProcessing
                          ? null
                          : () async {
                              if (claveController.text.isEmpty) {
                                _mostrarSnackBar(
                                    'Por favor ingrese la clave de confirmación',
                                    isSuccess: false);
                                return;
                              }

                              if (!CredentialsService.validateDeletionKey(
                                  claveController.text)) {
                                _mostrarSnackBar(
                                    'Clave incorrecta. Operación cancelada.',
                                    isSuccess: false);
                                claveController.clear();
                                return;
                              }

                              setDialogState(() => isProcessing = true);

                              try {
                                claveController.clear();
                                Navigator.pop(context);

                                await _unirTribusConNuevosDatos(
                                  tribu1Id,
                                  tribu2Id,
                                  mantenerDatos,
                                  nuevoNombre,
                                  nuevoNombreLider,
                                  nuevoApellidoLider,
                                  nuevoUsuario,
                                  nuevaContrasena,
                                );
                              } catch (e) {
                                setDialogState(() => isProcessing = false);
                                _mostrarSnackBar(
                                    'Error al unir las tribus: ${e.toString()}',
                                    isSuccess: false);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[600],
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 2,
                      ),
                      child: isProcessing
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text('Procesando...'),
                              ],
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.merge_type_rounded, size: 18),
                                SizedBox(width: 6),
                                Text(
                                  'Confirmar Unión',
                                  style: TextStyle(fontWeight: FontWeight.w600),
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
  }

  Widget _buildCustomTextField({
    required Function(String) onChanged,
    required String labelText,
    required IconData icon,
    bool isPassword = false,
    bool enabled = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF1B998B).withOpacity(0.3),
        ),
      ),
      child: TextField(
        onChanged: onChanged,
        obscureText: isPassword,
        enabled: enabled,
        decoration: InputDecoration(
          prefixIcon: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF1B998B).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF1B998B),
              size: 20,
            ),
          ),
          labelText: labelText,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          labelStyle: TextStyle(
            color: enabled ? const Color(0xFF7F8C8D) : Colors.grey,
          ),
        ),
      ),
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
    // Mostrar loading overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            content: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF1B998B),
                          const Color(0xFF159B8C),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Icon(
                      Icons.merge_type,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Uniendo Tribus',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Por favor espera mientras se procesan los datos...',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF7F8C8D),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 20),
                  LinearProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      const Color(0xFF1B998B),
                    ),
                    backgroundColor: const Color(0xFF1B998B).withOpacity(0.2),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    try {
      print(
          '\n🔄 ════════════════════════════════════════════════════════════');
      print('   INICIANDO UNIÓN DE TRIBUS CON NUEVOS DATOS');
      print('════════════════════════════════════════════════════════════\n');
      print('📍 Tribu DESTINO (1): $tribu1Id');
      print('📍 Tribu ORIGEN (2): $tribu2Id');
      print('📝 Mantener datos: $mantenerDatos\n');

      // Validaciones iniciales
      if (tribu1Id.isEmpty || tribu2Id.isEmpty) {
        throw Exception('IDs de tribus no válidos');
      }

      if (tribu1Id == tribu2Id) {
        throw Exception('No se puede unir una tribu consigo misma');
      }

      // =========================================================================
      // PASO 1: Obtener datos de ambas tribus
      // =========================================================================
      print('🔍 Obteniendo datos de las tribus...');

      final futures = await Future.wait([
        _firestore.collection('tribus').doc(tribu1Id).get(),
        _firestore.collection('tribus').doc(tribu2Id).get(),
      ]).timeout(
        const Duration(seconds: 10),
        onTimeout: () =>
            throw Exception('Tiempo de espera agotado al obtener las tribus'),
      );

      final tribu1Doc = futures[0];
      final tribu2Doc = futures[1];

      if (!tribu1Doc.exists) {
        throw Exception('La primera tribu no existe o fue eliminada');
      }

      if (!tribu2Doc.exists) {
        throw Exception('La segunda tribu no existe o fue eliminada');
      }

      final tribu1Data = tribu1Doc.data()!;
      final tribu2Data = tribu2Doc.data()!;

      print('✅ Tribu 1: ${tribu1Data['nombre']}');
      print('✅ Tribu 2: ${tribu2Data['nombre']}');

      // Validar que ambas tribus pertenezcan al mismo ministerio
      if (tribu1Data['categoria'] != tribu2Data['categoria']) {
        throw Exception('Las tribus deben pertenecer al mismo ministerio');
      }

      print(
          '✅ Ambas tribus del mismo ministerio: ${tribu1Data['categoria']}\n');

      // Obtener nombres para el historial
      final nombreTribu2Original = tribu2Data['nombre'] ?? 'Sin nombre';
      final nombreTribu1Original = tribu1Data['nombre'] ?? 'Sin nombre';

      // =========================================================================
      // PASO 2: Actualizar datos de tribu1 si es necesario
      // =========================================================================
      if (!mantenerDatos) {
        print('📝 Actualizando datos de la tribu destino...');

        if (nuevoNombre?.trim().isEmpty ?? true) {
          throw Exception('El nuevo nombre de tribu es requerido');
        }
        if (nuevoNombreLider?.trim().isEmpty ?? true) {
          throw Exception('El nuevo nombre del líder es requerido');
        }
        if (nuevoApellidoLider?.trim().isEmpty ?? true) {
          throw Exception('El nuevo apellido del líder es requerido');
        }
        if (nuevoUsuario?.trim().isEmpty ?? true) {
          throw Exception('El nuevo usuario es requerido');
        }
        if (nuevaContrasena?.trim().isEmpty ?? true) {
          throw Exception('La nueva contraseña es requerida');
        }

        await _firestore.collection('tribus').doc(tribu1Id).update({
          'nombre': nuevoNombre!.trim(),
          'nombreLider': nuevoNombreLider!.trim(),
          'apellidoLider': nuevoApellidoLider!.trim(),
          'usuario': nuevoUsuario!.trim(),
          'contrasena': nuevaContrasena!.trim(),
          'fechaActualizacion': FieldValue.serverTimestamp(),
        });

        print('✅ Datos de tribu1 actualizados');

        // Actualizar usuario
        final usuarioTribu1Snapshot = await _firestore
            .collection('usuarios')
            .where('tribuId', isEqualTo: tribu1Id)
            .limit(1)
            .get()
            .timeout(
              const Duration(seconds: 5),
              onTimeout: () =>
                  throw Exception('Tiempo agotado al buscar usuario'),
            );

        if (usuarioTribu1Snapshot.docs.isNotEmpty) {
          await usuarioTribu1Snapshot.docs.first.reference.update({
            'usuario': nuevoUsuario!.trim(),
            'contrasena': nuevaContrasena!.trim(),
            'nombre': nuevoNombre!.trim(),
            'fechaActualizacion': FieldValue.serverTimestamp(),
          });
          print('✅ Usuario de tribu1 actualizado\n');
        }
      }

      // =========================================================================
      // PASO 3: Obtener TODOS los documentos a transferir
      // =========================================================================
      print('📊 Obteniendo documentos a transferir...\n');

      final results = await Future.wait([
        _firestore
            .collection('eventos')
            .where('tribuId', isEqualTo: tribu2Id)
            .get(),
        _firestore
            .collection('coordinadores')
            .where('tribuId', isEqualTo: tribu2Id)
            .get(),
        _firestore
            .collection('timoteos')
            .where('tribuId', isEqualTo: tribu2Id)
            .get(),
        _firestore
            .collection('asistencias')
            .where('tribuId', isEqualTo: tribu2Id)
            .get(),
        _firestore
            .collection('registros')
            .where('tribuAsignada', isEqualTo: tribu2Id)
            .get(),
      ]).timeout(
        const Duration(seconds: 15),
        onTimeout: () =>
            throw Exception('Tiempo agotado al obtener documentos'),
      );

      final eventosSnapshot = results[0];
      final coordinadoresSnapshot = results[1];
      final timoteosSnapshot = results[2];
      final asistenciasSnapshot = results[3];
      final registrosSnapshot = results[4];

      print('📅 Eventos encontrados: ${eventosSnapshot.docs.length}');
      print(
          '👥 Coordinadores encontrados: ${coordinadoresSnapshot.docs.length}');
      print('🎓 Timoteos encontrados: ${timoteosSnapshot.docs.length}');
      print('📋 Asistencias encontradas: ${asistenciasSnapshot.docs.length}');
      print('📝 Registros encontrados: ${registrosSnapshot.docs.length}\n');

      // =========================================================================
      // PASO 4: TRANSFERIR EVENTOS (CRÍTICO - CON LOGS DETALLADOS)
      // =========================================================================
      if (eventosSnapshot.docs.isNotEmpty) {
        print('📅 ══════════════════════════════════════════════════════');
        print('   TRANSFIRIENDO EVENTOS (PROCESO CRÍTICO)');
        print('══════════════════════════════════════════════════════\n');

        const batchSize = 400;
        int eventosTransferidos = 0;

        for (int i = 0; i < eventosSnapshot.docs.length; i += batchSize) {
          final batch = _firestore.batch();
          final end = (i + batchSize < eventosSnapshot.docs.length)
              ? i + batchSize
              : eventosSnapshot.docs.length;
          final lote = eventosSnapshot.docs.sublist(i, end);

          print(
              '📦 Procesando lote ${(i ~/ batchSize) + 1} (${lote.length} eventos):\n');

          for (var eventoDoc in lote) {
            final eventoData = eventoDoc.data() as Map<String, dynamic>;

            print('   📅 Evento: ${eventoData['nombre']}');
            print('      ID: ${eventoDoc.id}');
            print('      TribuId actual: ${eventoData['tribuId']}');
            print('      → Cambiando a: $tribu1Id');

            batch.update(eventoDoc.reference, {
              'tribuId': tribu1Id,
              'tribuOriginal': tribu2Id,
              'nombreTribuOriginal': nombreTribu2Original,
              'fechaTransferencia': FieldValue.serverTimestamp(),
            });

            eventosTransferidos++;
            print('      ✅ Marcado para transferencia\n');
          }

          print('💾 Ejecutando batch commit...');
          await batch.commit();
          print('✅ Lote ${(i ~/ batchSize) + 1} completado\n');
        }

        print('═══════════════════════════════════════════════════════');
        print('✅ EVENTOS TRANSFERIDOS: $eventosTransferidos');
        print('═══════════════════════════════════════════════════════\n');
      } else {
        print('ℹ️ No hay eventos para transferir\n');
      }

      // =========================================================================
      // PASO 5: Transferir otras colecciones
      // =========================================================================
      Future<void> transferirColeccion(
        List<QueryDocumentSnapshot> docs,
        String nombre,
        String campo,
        String emoji,
      ) async {
        if (docs.isEmpty) {
          print('$emoji $nombre: No hay documentos\n');
          return;
        }

        print('$emoji Transfiriendo ${docs.length} $nombre...');

        const batchSize = 400;
        for (int i = 0; i < docs.length; i += batchSize) {
          final batch = _firestore.batch();
          final end =
              (i + batchSize < docs.length) ? i + batchSize : docs.length;
          final lote = docs.sublist(i, end);

          for (var doc in lote) {
            batch.update(doc.reference, {
              campo: tribu1Id,
              'tribuOriginal': tribu2Id,
              'fechaTransferencia': FieldValue.serverTimestamp(),
            });
          }

          await batch.commit();
        }

        print('   ✅ $nombre transferidos correctamente\n');
      }

      await transferirColeccion(
          coordinadoresSnapshot.docs, 'coordinadores', 'tribuId', '👥');
      await transferirColeccion(
          timoteosSnapshot.docs, 'timoteos', 'tribuId', '🎓');
      await transferirColeccion(
          asistenciasSnapshot.docs, 'asistencias', 'tribuId', '📋');
      await transferirColeccion(
          registrosSnapshot.docs, 'registros', 'tribuAsignada', '📝');

      // =========================================================================
      // PASO 6: Eliminar usuario de tribu2
      // =========================================================================
      print('🗑️ Eliminando usuario de tribu2...');

      final usuarioTribu2Snapshot = await _firestore
          .collection('usuarios')
          .where('tribuId', isEqualTo: tribu2Id)
          .limit(1)
          .get()
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () =>
                throw Exception('Tiempo agotado al buscar usuario de tribu2'),
          );

      final batchFinal = _firestore.batch();

      if (usuarioTribu2Snapshot.docs.isNotEmpty) {
        batchFinal.delete(usuarioTribu2Snapshot.docs.first.reference);
        print('   ✅ Usuario marcado para eliminación');
      }

      // =========================================================================
      // PASO 7: Crear historial
      // =========================================================================
      final historialRef = _firestore.collection('historialUnionTribus').doc();
      batchFinal.set(historialRef, {
        'tribuDestinoId': tribu1Id,
        'tribuDestinoNombre': mantenerDatos
            ? nombreTribu1Original
            : (nuevoNombre?.trim() ?? nombreTribu1Original),
        'tribuOrigenId': tribu2Id,
        'tribuOrigenNombre': nombreTribu2Original,
        'ministerio': tribu1Data['categoria'] ?? 'Sin categoría',
        'fechaUnion': FieldValue.serverTimestamp(),
        'mantuvoDatos': mantenerDatos,
        'cantidadEventosTransferidos': eventosSnapshot.docs.length,
        'cantidadRegistrosTransferidos': registrosSnapshot.docs.length,
        'cantidadAsistenciasTransferidas': asistenciasSnapshot.docs.length,
        'cantidadCoordinadoresTransferidos': coordinadoresSnapshot.docs.length,
        'cantidadTimoteosTransferidos': timoteosSnapshot.docs.length,
        'procesadoPor': 'Sistema',
        'estado': 'Completado',
      });

      // =========================================================================
      // PASO 8: Eliminar la tribu2
      // =========================================================================
      print('🗑️ Eliminando tribu2...');
      batchFinal.delete(tribu2Doc.reference);

      await batchFinal.commit().timeout(
            const Duration(seconds: 30),
            onTimeout: () =>
                throw Exception('Tiempo agotado al guardar los cambios'),
          );

      print('   ✅ Tribu eliminada\n');

      // =========================================================================
      // RESUMEN FINAL
      // =========================================================================
      print('╔════════════════════════════════════════════════════════╗');
      print('║         ✅ UNIÓN COMPLETADA EXITOSAMENTE               ║');
      print('╚════════════════════════════════════════════════════════╝\n');
      print('📊 Resumen de transferencias:');
      print('   • Eventos: ${eventosSnapshot.docs.length}');
      print('   • Coordinadores: ${coordinadoresSnapshot.docs.length}');
      print('   • Timoteos: ${timoteosSnapshot.docs.length}');
      print('   • Asistencias: ${asistenciasSnapshot.docs.length}');
      print('   • Registros: ${registrosSnapshot.docs.length}');
      print('\n════════════════════════════════════════════════════════\n');

      // Cerrar loading dialog
      Navigator.of(context, rootNavigator: true).pop();

      // Mostrar mensaje de éxito con detalles
      _mostrarDialogoExito(
        nombreTribu1Original,
        nombreTribu2Original,
        registrosSnapshot.docs.length,
        asistenciasSnapshot.docs.length,
        mantenerDatos
            ? nombreTribu1Original
            : (nuevoNombre?.trim() ?? nombreTribu1Original),
      );
    } catch (e, stackTrace) {
      // Cerrar loading dialog si está abierto
      try {
        Navigator.of(context, rootNavigator: true).pop();
      } catch (_) {}

      print('\n╔════════════════════════════════════════════════════════╗');
      print('║            ❌ ERROR EN UNIÓN DE TRIBUS                 ║');
      print('╚════════════════════════════════════════════════════════╝\n');
      print('Error detallado: $e');
      print('\nStack trace:');
      print(stackTrace);
      print('\n════════════════════════════════════════════════════════\n');

      String mensajeError = 'Error desconocido';
      if (e.toString().contains('Tiempo')) {
        mensajeError =
            'La operación tardó demasiado tiempo. Intenta nuevamente.';
      } else if (e.toString().contains('network')) {
        mensajeError =
            'Error de conexión. Verifica tu internet e intenta nuevamente.';
      } else if (e.toString().contains('permission')) {
        mensajeError = 'No tienes permisos para realizar esta operación.';
      } else {
        mensajeError = e.toString().replaceFirst('Exception: ', '');
      }

      _mostrarDialogoError(mensajeError);
    }
  }

  void _mostrarDialogoExito(
    String nombreTribu1,
    String nombreTribu2,
    int registrosTransferidos,
    int asistenciasTransferidas,
    String nombreFinal,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.green,
                        Colors.green.shade600,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: const Icon(
                    Icons.check_circle_outline,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  '¡Unión Exitosa!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.green.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Resumen de la operación:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildResumenItem(
                        Icons.arrow_forward,
                        '$nombreTribu2 → $nombreFinal',
                        'Tribu unificada',
                      ),
                      _buildResumenItem(
                        Icons.people,
                        '$registrosTransferidos',
                        'Registros transferidos',
                      ),
                      _buildResumenItem(
                        Icons.event_available,
                        '$asistenciasTransferidas',
                        'Asistencias transferidas',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            Container(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Refrescar la lista de tribus
                  setState(() {});
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Entendido',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildResumenItem(IconData icon, String valor, String descripcion) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.green.shade600,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$valor ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                      fontSize: 14,
                    ),
                  ),
                  TextSpan(
                    text: descripcion,
                    style: const TextStyle(
                      color: Color(0xFF7F8C8D),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoError(String mensaje) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.red,
                        Colors.red.shade600,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: const Icon(
                    Icons.error_outline,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Error en la Unión',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.red.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    mensaje,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            Container(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Cerrar',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
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
    final List<String> categoriasTribu = [
      "Ministerio Juvenil",
      "Ministerio de Damas",
      "Ministerio de Caballeros"
    ];

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
            const SizedBox(height: 16),
            // Nuevo campo de categoría
            DropdownButtonFormField<String>(
              value: categoriaSeleccionada,
              decoration: InputDecoration(
                labelText: 'Categoría de Tribu',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: categoriasTribu.map((categoria) {
                return DropdownMenuItem(
                  value: categoria,
                  child: Text(categoria),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  categoriaSeleccionada = value;
                });
              },
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
      stream: _firestore.collection('tribus').snapshots(),
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

        final allTribus = snapshot.data?.docs ?? [];

        // Filtrar las tribus del ministerio juvenil en memoria
        final tribus = allTribus.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['categoria'] == 'Ministerio Juvenil';
        }).toList();

        if (tribus.isEmpty) {
          return _buildEmptyState();
        }

        // Ordenar por fecha de creación manualmente
// Ordenar por fecha de creación (con manejo de nulos)
        tribus.sort((a, b) {
          try {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;

            // Verificar si ambos tienen createdAt
            if (!aData.containsKey('createdAt') || aData['createdAt'] == null) {
              return 1; // Mover al final
            }
            if (!bData.containsKey('createdAt') || bData['createdAt'] == null) {
              return -1; // Mover al final
            }

            final aDate = aData['createdAt'] as Timestamp;
            final bDate = bData['createdAt'] as Timestamp;
            return bDate.compareTo(aDate);
          } catch (e) {
            print('Error al ordenar tribus: $e');
            return 0;
          }
        });

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
                        //  _buildEstadisticasTribu(tribu.id),
                        // const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit,
                                  color: Color(0xFF1B998B)),
                              onPressed: () =>
                                  _mostrarDialogoEditarTribu(tribu.id, data),
                              tooltip: 'Editar',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () =>
                                  _mostrarDialogoConfirmarEliminarTribu(
                                      tribu.id),
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
          final data = registro.data() as Map<String, dynamic>;

          if (data.containsKey('fechaAsignacionTribu') &&
              data['fechaAsignacionTribu'] != null) {
            final fecha = (data['fechaAsignacionTribu'] as Timestamp).toDate();
            final ano = fecha.year;
            final mesNombre = _getMesNombre(fecha.month);

            if (!registrosPorAnio.containsKey(ano)) {
              registrosPorAnio[ano] = {};
            }

            if (!registrosPorAnio[ano]!.containsKey(mesNombre)) {
              registrosPorAnio[ano]![mesNombre] = 0;
            }

            registrosPorAnio[ano]![mesNombre] =
                registrosPorAnio[ano]![mesNombre]! + 1;
          } else {
            print('Registro sin fechaAsignacionTribu: ${registro.id}');
          }
        }

        // Ordenar los años de más reciente a más antiguo
        final anosOrdenados = registrosPorAnio.keys.toList()
          ..sort((a, b) => b.compareTo(a));

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
                          ...registrosAnio.entries
                              .map((entry) => Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 4),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
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
                                  ))
                              .toList(),
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
      case 1:
        return 'Enero';
      case 2:
        return 'Febrero';
      case 3:
        return 'Marzo';
      case 4:
        return 'Abril';
      case 5:
        return 'Mayo';
      case 6:
        return 'Junio';
      case 7:
        return 'Julio';
      case 8:
        return 'Agosto';
      case 9:
        return 'Septiembre';
      case 10:
        return 'Octubre';
      case 11:
        return 'Noviembre';
      case 12:
        return 'Diciembre';
      default:
        return '';
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
      print('\n🔄 ═══════════════════════════════════════════════════════');
      print('   INICIANDO UNIÓN DE TRIBUS');
      print('═══════════════════════════════════════════════════════\n');
      print('📍 Tribu DESTINO (1): $tribu1Id');
      print('📍 Tribu ORIGEN (2): $tribu2Id\n');

      // =========================================================================
      // PASO 1: Verificar que ambas tribus existan
      // =========================================================================
      print('🔍 Verificando existencia de tribus...');

      final tribu1Doc =
          await _firestore.collection('tribus').doc(tribu1Id).get();
      final tribu2Doc =
          await _firestore.collection('tribus').doc(tribu2Id).get();

      if (!tribu1Doc.exists) {
        throw Exception('La tribu destino (ID: $tribu1Id) no existe');
      }
      if (!tribu2Doc.exists) {
        throw Exception('La tribu origen (ID: $tribu2Id) no existe');
      }

      final tribu1Data = tribu1Doc.data()!;
      final tribu2Data = tribu2Doc.data()!;

      print('✅ Tribu 1: ${tribu1Data['nombre']}');
      print('✅ Tribu 2: ${tribu2Data['nombre']}\n');

      // =========================================================================
      // PASO 2: Obtener TODOS los documentos a transferir
      // =========================================================================
      print('📊 Obteniendo documentos a transferir...\n');

      final results = await Future.wait([
        _firestore
            .collection('eventos')
            .where('tribuId', isEqualTo: tribu2Id)
            .get(),
        _firestore
            .collection('coordinadores')
            .where('tribuId', isEqualTo: tribu2Id)
            .get(),
        _firestore
            .collection('timoteos')
            .where('tribuId', isEqualTo: tribu2Id)
            .get(),
        _firestore
            .collection('asistencias')
            .where('tribuId', isEqualTo: tribu2Id)
            .get(),
        _firestore
            .collection('registros')
            .where('tribuAsignada', isEqualTo: tribu2Id)
            .get(),
        _firestore
            .collection('usuarios')
            .where('tribuId', isEqualTo: tribu2Id)
            .limit(1)
            .get(),
      ]);

      final eventosSnapshot = results[0];
      final coordinadoresSnapshot = results[1];
      final timoteosSnapshot = results[2];
      final asistenciasSnapshot = results[3];
      final registrosSnapshot = results[4];
      final usuarioTribu2Snapshot = results[5];

      print('📅 Eventos encontrados: ${eventosSnapshot.docs.length}');
      print(
          '👥 Coordinadores encontrados: ${coordinadoresSnapshot.docs.length}');
      print('🎓 Timoteos encontrados: ${timoteosSnapshot.docs.length}');
      print('📋 Asistencias encontradas: ${asistenciasSnapshot.docs.length}');
      print('📝 Registros encontrados: ${registrosSnapshot.docs.length}');
      print(
          '👤 Usuario encontrado: ${usuarioTribu2Snapshot.docs.isEmpty ? "No" : "Sí"}\n');

      // =========================================================================
      // PASO 3: Transferir por lotes (máximo 500 operaciones por batch)
      // =========================================================================
      int totalOperaciones = 0;

      // Helper para procesar en lotes
      Future<void> procesarEnLotes(
        List<QueryDocumentSnapshot> docs,
        String coleccion,
        String campoId,
        String emoji,
      ) async {
        if (docs.isEmpty) {
          print('$emoji $coleccion: No hay documentos para transferir');
          return;
        }

        print(
            '$emoji Transfiriendo ${docs.length} documento(s) de $coleccion...');

        // Procesar en lotes de 400 (margen de seguridad vs límite de 500)
        const batchSize = 400;

        for (int i = 0; i < docs.length; i += batchSize) {
          final batch = _firestore.batch();
          final end =
              (i + batchSize < docs.length) ? i + batchSize : docs.length;
          final lote = docs.sublist(i, end);

          for (var doc in lote) {
            batch.update(doc.reference, {
              campoId: tribu1Id,
              'tribuOriginal': tribu2Id,
              'fechaTransferencia': FieldValue.serverTimestamp(),
            });
            totalOperaciones++;
          }

          await batch.commit();
          print(
              '   ✅ Lote ${(i ~/ batchSize) + 1} completado (${lote.length} docs)');
        }
      }

      // Transferir cada colección
      await procesarEnLotes(eventosSnapshot.docs, 'eventos', 'tribuId', '📅');
      await procesarEnLotes(
          coordinadoresSnapshot.docs, 'coordinadores', 'tribuId', '👥');
      await procesarEnLotes(timoteosSnapshot.docs, 'timoteos', 'tribuId', '🎓');
      await procesarEnLotes(
          asistenciasSnapshot.docs, 'asistencias', 'tribuId', '📋');
      await procesarEnLotes(
          registrosSnapshot.docs, 'registros', 'tribuAsignada', '📝');

      print('');

      // =========================================================================
      // PASO 4: Eliminar usuario de tribu2 y la tribu misma
      // =========================================================================
      final batchFinal = _firestore.batch();

      if (usuarioTribu2Snapshot.docs.isNotEmpty) {
        print('🗑️ Eliminando usuario de tribu2...');
        batchFinal.delete(usuarioTribu2Snapshot.docs.first.reference);
        print('   ✅ Usuario marcado para eliminación');
      }

      print('🗑️ Eliminando tribu2...');
      batchFinal.delete(tribu2Doc.reference);
      print('   ✅ Tribu marcada para eliminación\n');

      await batchFinal.commit();
      print('✅ Eliminaciones completadas\n');

      // =========================================================================
      // PASO 5: Crear historial (opcional, no crítico)
      // =========================================================================
      try {
        await _firestore.collection('historialUnionTribus').add({
          'tribu1Id': tribu1Id,
          'tribu1Nombre': tribu1Data['nombre'],
          'tribu2Id': tribu2Id,
          'tribu2Nombre': tribu2Data['nombre'],
          'fechaUnion': FieldValue.serverTimestamp(),
          'eventosTransferidos': eventosSnapshot.docs.length,
          'coordinadoresTransferidos': coordinadoresSnapshot.docs.length,
          'timoteosTransferidos': timoteosSnapshot.docs.length,
          'asistenciasTransferidas': asistenciasSnapshot.docs.length,
          'registrosTransferidos': registrosSnapshot.docs.length,
          'totalOperaciones': totalOperaciones,
        });
        print('📊 Historial de unión creado\n');
      } catch (e) {
        print('⚠️ No se pudo crear historial (no crítico): $e\n');
      }

      // =========================================================================
      // RESUMEN FINAL
      // =========================================================================
      print('╔═══════════════════════════════════════════════════════╗');
      print('║           ✅ UNIÓN COMPLETADA EXITOSAMENTE            ║');
      print('╚═══════════════════════════════════════════════════════╝');
      print('');
      print('📊 Resumen de transferencias:');
      print('   • Eventos: ${eventosSnapshot.docs.length}');
      print('   • Coordinadores: ${coordinadoresSnapshot.docs.length}');
      print('   • Timoteos: ${timoteosSnapshot.docs.length}');
      print('   • Asistencias: ${asistenciasSnapshot.docs.length}');
      print('   • Registros: ${registrosSnapshot.docs.length}');
      print('   • Total operaciones: $totalOperaciones');
      print('');
      print(
          '🎯 Tribu "${tribu2Data['nombre']}" fusionada con "${tribu1Data['nombre']}"');
      print('═══════════════════════════════════════════════════════\n');

      _mostrarSnackBar(
        'Tribus unidas exitosamente. ${eventosSnapshot.docs.length} eventos transferidos.',
        isSuccess: true,
      );
    } catch (e, stackTrace) {
      print('\n╔═══════════════════════════════════════════════════════╗');
      print('║              ❌ ERROR EN UNIÓN DE TRIBUS              ║');
      print('╚═══════════════════════════════════════════════════════╝\n');
      print('Error: $e');
      print('\nStack trace:');
      print(stackTrace);
      print('\n═══════════════════════════════════════════════════════\n');

      _mostrarSnackBar(
        'Error al unir las tribus: ${e.toString()}',
        isSuccess: false,
      );
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
    final nombreController =
        TextEditingController(text: datos['nombre']?.toString() ?? '');
    final nombreLiderController =
        TextEditingController(text: datos['nombreLider']?.toString() ?? '');
    final apellidoLiderController =
        TextEditingController(text: datos['apellidoLider']?.toString() ?? '');
    final usuarioController =
        TextEditingController(text: datos['usuario']?.toString() ?? '');
    final contrasenaController = TextEditingController();

    String? categoriaSeleccionadaEdit = datos['categoria']?.toString();
    bool isLoading = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Container(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.edit_rounded,
                    color: primaryColor,
                    size: 24,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Editar Tribu',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      Text(
                        'Modifica los datos necesarios',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          content: Container(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildEditTextField(
                    controller: nombreController,
                    label: 'Nombre de la Tribu',
                    icon: Icons.group_rounded,
                    enabled: !isLoading,
                  ),
                  SizedBox(height: 16),
                  _buildEditTextField(
                    controller: nombreLiderController,
                    label: 'Nombre del Líder',
                    icon: Icons.person_rounded,
                    enabled: !isLoading,
                  ),
                  SizedBox(height: 16),
                  _buildEditTextField(
                    controller: apellidoLiderController,
                    label: 'Apellido del Líder',
                    icon: Icons.person_outline_rounded,
                    enabled: !isLoading,
                  ),
                  SizedBox(height: 16),
                  _buildEditTextField(
                    controller: usuarioController,
                    label: 'Usuario',
                    icon: Icons.account_circle_rounded,
                    enabled: !isLoading,
                  ),
                  SizedBox(height: 16),
                  _buildEditTextField(
                    controller: contrasenaController,
                    label: 'Nueva Contraseña (opcional)',
                    icon: Icons.lock_rounded,
                    obscureText: true,
                    enabled: !isLoading,
                  ),
                  SizedBox(height: 16),
                  // Dropdown para categoría
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: primaryColor.withOpacity(0.3)),
                    ),
                    child: DropdownButtonFormField<String>(
                      value: categoriaSeleccionadaEdit,
                      decoration: InputDecoration(
                        labelText: 'Categoría',
                        prefixIcon:
                            Icon(Icons.category_rounded, color: primaryColor),
                        border: InputBorder.none,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        labelStyle: TextStyle(color: primaryColor),
                      ),
                      dropdownColor: backgroundColor,
                      items: [
                        'Ministerio Juvenil',
                        'Ministerio de Damas',
                        'Ministerio de Caballeros'
                      ].map((categoria) {
                        return DropdownMenuItem<String>(
                          value: categoria,
                          child: Text(categoria),
                        );
                      }).toList(),
                      onChanged: isLoading
                          ? null
                          : (value) {
                              setDialogState(() {
                                categoriaSeleccionadaEdit = value;
                              });
                            },
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            Container(
              width: double.maxFinite,
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed:
                          isLoading ? null : () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Cancelar',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () async {
                              // Validaciones
                              if (nombreController.text.trim().isEmpty ||
                                  nombreLiderController.text.trim().isEmpty ||
                                  apellidoLiderController.text.trim().isEmpty ||
                                  usuarioController.text.trim().isEmpty ||
                                  categoriaSeleccionadaEdit == null) {
                                _mostrarSnackBar(
                                    'Por favor complete todos los campos obligatorios',
                                    isSuccess: false);
                                return;
                              }

                              setDialogState(() => isLoading = true);

                              try {
                                final datosActualizados = {
                                  'nombre': nombreController.text.trim(),
                                  'nombreLider':
                                      nombreLiderController.text.trim(),
                                  'apellidoLider':
                                      apellidoLiderController.text.trim(),
                                  'usuario': usuarioController.text.trim(),
                                  'categoria': categoriaSeleccionadaEdit,
                                  'contrasena': contrasenaController.text
                                          .trim()
                                          .isNotEmpty
                                      ? contrasenaController.text.trim()
                                      : datos['contrasena'],
                                };

                                await _editarTribu(docId, datosActualizados);

                                if (mounted) {
                                  Navigator.pop(context);
                                }
                              } catch (e) {
                                setDialogState(() => isLoading = false);
                                _mostrarSnackBar(
                                    'Error inesperado: ${e.toString()}',
                                    isSuccess: false);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 2,
                      ),
                      child: isLoading
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text('Guardando...'),
                              ],
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.save_rounded, size: 18),
                                SizedBox(width: 6),
                                Text(
                                  'Guardar',
                                  style: TextStyle(fontWeight: FontWeight.w600),
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
  }

// Widget helper para campos de texto - NUEVO
  Widget _buildEditTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    bool enabled = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        enabled: enabled,
        style: TextStyle(
          color: enabled ? Colors.black87 : Colors.grey[400],
        ),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(
            icon,
            color: enabled ? primaryColor : Colors.grey[400],
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          labelStyle: TextStyle(
            color: enabled ? primaryColor : Colors.grey[400],
          ),
        ),
      ),
    );
  }

// Función para mostrar diálogo de edición - COMPLETAMENTE MEJORADA
  Future<void> _mostrarDialogoEditarLiderConsolidacion(
      String docId, Map<String, dynamic> datos) async {
    final nombreController =
        TextEditingController(text: datos['nombre']?.toString() ?? '');
    final apellidoController =
        TextEditingController(text: datos['apellido']?.toString() ?? '');
    final usuarioController =
        TextEditingController(text: datos['usuario']?.toString() ?? '');
    final contrasenaController = TextEditingController();

    bool isLoading = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Container(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.supervisor_account_rounded,
                    color: primaryColor,
                    size: 24,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Editar Líder',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      Text(
                        'Líder de Consolidación',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          content: Container(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildConsolidationTextField(
                    controller: nombreController,
                    label: 'Nombre',
                    icon: Icons.person_rounded,
                    enabled: !isLoading,
                  ),
                  SizedBox(height: 16),
                  _buildConsolidationTextField(
                    controller: apellidoController,
                    label: 'Apellido',
                    icon: Icons.person_outline_rounded,
                    enabled: !isLoading,
                  ),
                  SizedBox(height: 16),
                  _buildConsolidationTextField(
                    controller: usuarioController,
                    label: 'Usuario',
                    icon: Icons.account_circle_rounded,
                    enabled: !isLoading,
                  ),
                  SizedBox(height: 16),
                  _buildConsolidationTextField(
                    controller: contrasenaController,
                    label: 'Nueva Contraseña (opcional)',
                    icon: Icons.lock_rounded,
                    obscureText: true,
                    enabled: !isLoading,
                  ),
                  SizedBox(height: 12),
                  // Información adicional
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: primaryColor.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: primaryColor,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Si no ingresa una nueva contraseña, se mantendrá la actual',
                            style: TextStyle(
                              fontSize: 12,
                              color: primaryColor.withOpacity(0.8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            Container(
              width: double.maxFinite,
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed:
                          isLoading ? null : () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Cancelar',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () async {
                              // Validaciones
                              if (nombreController.text.trim().isEmpty ||
                                  apellidoController.text.trim().isEmpty ||
                                  usuarioController.text.trim().isEmpty) {
                                _mostrarSnackBar(
                                    'Por favor complete todos los campos obligatorios',
                                    isSuccess: false);
                                return;
                              }

                              // Validar formato de usuario
                              if (usuarioController.text.trim().length < 3) {
                                _mostrarSnackBar(
                                    'El usuario debe tener al menos 3 caracteres',
                                    isSuccess: false);
                                return;
                              }

                              setDialogState(() => isLoading = true);

                              try {
                                final datosActualizados = {
                                  'nombre': nombreController.text.trim(),
                                  'apellido': apellidoController.text.trim(),
                                  'usuario': usuarioController.text.trim(),
                                  'contrasena': contrasenaController.text
                                          .trim()
                                          .isNotEmpty
                                      ? contrasenaController.text.trim()
                                      : datos['contrasena'],
                                };

                                await _editarLiderConsolidacion(
                                    docId, datosActualizados);

                                if (mounted) {
                                  Navigator.pop(context);
                                }
                              } catch (e) {
                                setDialogState(() => isLoading = false);
                                _mostrarSnackBar(
                                    'Error inesperado: ${e.toString()}',
                                    isSuccess: false);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 2,
                      ),
                      child: isLoading
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text('Guardando...'),
                              ],
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.save_rounded, size: 18),
                                SizedBox(width: 6),
                                Text(
                                  'Guardar',
                                  style: TextStyle(fontWeight: FontWeight.w600),
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
  }

// Widget helper específico para campos de consolidación - NUEVO
  Widget _buildConsolidationTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    bool enabled = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        enabled: enabled,
        style: TextStyle(
          color: enabled ? Colors.black87 : Colors.grey[400],
          fontSize: 16,
        ),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Container(
            margin: EdgeInsets.all(8),
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: enabled
                  ? primaryColor.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: enabled ? primaryColor : Colors.grey[400],
              size: 20,
            ),
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          labelStyle: TextStyle(
            color: enabled ? primaryColor : Colors.grey[400],
            fontSize: 14,
          ),
          floatingLabelStyle: TextStyle(
            color: primaryColor,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

// REEMPLAZA COMPLETAMENTE la función _mostrarDialogoConfirmarEliminarTribu
// Busca en tu código (aproximadamente línea 1870) y reemplaza toda la función:

  Future<void> _mostrarDialogoConfirmarEliminarTribu(String docId) async {
    _resetInactivityTimer();
    await _cargarEstadoBloqueo();

    if (_estaUsuarioBloqueado()) {
      await _mostrarVentanaBloqueo(context);
      return;
    }

    final TextEditingController claveController = TextEditingController();
    bool isDeleting = false;
    bool obscurePassword = true;

    // ✅ IMPORTANTE: Guardamos el context del State principal
    final BuildContext mainContext = context;

    return showDialog(
      context: mainContext,
      barrierDismissible: true, // ✅ Permitir cerrar al tocar fuera

      builder: (BuildContext dialogContext) => WillPopScope(
        onWillPop: () async => !isDeleting,
        child: StatefulBuilder(
          builder: (context, setDialogState) {
            // ✅ Recalcula en cada rebuild para actualizar con el teclado
            return LayoutBuilder(
              builder: (context, constraints) {
                final mediaQuery = MediaQuery.of(dialogContext);
                final screenWidth = mediaQuery.size.width;
                final screenHeight = mediaQuery.size.height;
                final keyboardHeight = mediaQuery.viewInsets.bottom;

                // ✅ Previene que el diálogo se salga de la pantalla
                final availableHeight = screenHeight - keyboardHeight - 48;

                final isSmallScreen = screenWidth < 400;
                final isMediumScreen = screenWidth >= 400 && screenWidth < 600;

                final titleFontSize = isSmallScreen ? 18.0 : 20.0;
                final subtitleFontSize = isSmallScreen ? 12.0 : 14.0;
                final contentFontSize = isSmallScreen ? 13.0 : 14.0;
                final iconSize = isSmallScreen ? 20.0 : 24.0;
                final padding = isSmallScreen ? 12.0 : 16.0;

                return Dialog(
                  backgroundColor: Colors.transparent,
                  insetPadding: EdgeInsets.only(
                    left: isSmallScreen ? 16 : 24,
                    right: isSmallScreen ? 16 : 24,
                    top: 24,
                    bottom: 24,
                  ),
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: 500,
                      maxHeight: screenHeight -
                          keyboardHeight -
                          48, // ✅ Altura máxima adaptativa
                    ),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ✅ Header
                        Container(
                          padding: EdgeInsets.all(padding),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.warning_rounded,
                                  color: Colors.red,
                                  size: iconSize,
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Eliminar Tribu',
                                      style: TextStyle(
                                        fontSize: titleFontSize,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red[700],
                                      ),
                                    ),
                                    Text(
                                      'Esta acción no se puede deshacer',
                                      style: TextStyle(
                                        fontSize: subtitleFontSize,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // ✅ Content con scroll
                        Flexible(
                          child: SingleChildScrollView(
                            padding: EdgeInsets.all(padding),
                            keyboardDismissBehavior:
                                ScrollViewKeyboardDismissBehavior.manual,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: EdgeInsets.all(padding),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.red.withOpacity(0.2),
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.info_outline_rounded,
                                        color: Colors.red[700],
                                        size: isSmallScreen ? 18 : 20,
                                      ),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          '¿Está seguro que desea eliminar esta tribu? Esta acción eliminará todos los datos relacionados.',
                                          style: TextStyle(
                                            fontSize: contentFontSize,
                                            color: Colors.red[700],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: padding),
                                Text(
                                  'Ingrese la clave de confirmación:',
                                  style: TextStyle(
                                    fontSize: contentFontSize,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[800],
                                  ),
                                ),
                                SizedBox(height: 12),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.red.withOpacity(0.3),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 4,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: TextField(
                                    controller: claveController,
                                    obscureText: obscurePassword,
                                    enabled: !isDeleting,
                                    enableInteractiveSelection: false,
                                    autocorrect: false,
                                    enableSuggestions: false,
                                    keyboardType: TextInputType.visiblePassword,
                                    style: TextStyle(
                                      color: isDeleting
                                          ? Colors.grey[400]
                                          : Colors.black87,
                                      fontSize: isSmallScreen ? 14 : 16,
                                      letterSpacing: obscurePassword ? 3 : 0,
                                    ),
                                    decoration: InputDecoration(
                                      labelText: 'Clave de confirmación',
                                      hintText: 'Ingrese la clave',
                                      hintStyle: TextStyle(
                                        color: Colors.grey[400],
                                        letterSpacing: 0,
                                      ),
                                      prefixIcon: Container(
                                        margin: EdgeInsets.all(8),
                                        padding: EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: isDeleting
                                              ? Colors.grey.withOpacity(0.1)
                                              : Colors.red.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          Icons.lock_rounded,
                                          color: isDeleting
                                              ? Colors.grey[400]
                                              : Colors.red[700],
                                          size: isSmallScreen ? 18 : 20,
                                        ),
                                      ),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          obscurePassword
                                              ? Icons.visibility_off_rounded
                                              : Icons.visibility_rounded,
                                          color: isDeleting
                                              ? Colors.grey[400]
                                              : Colors.grey[600],
                                          size: isSmallScreen ? 18 : 20,
                                        ),
                                        onPressed: isDeleting
                                            ? null
                                            : () {
                                                setDialogState(() {
                                                  obscurePassword =
                                                      !obscurePassword;
                                                });
                                              },
                                      ),
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 16,
                                      ),
                                      labelStyle: TextStyle(
                                        color: isDeleting
                                            ? Colors.grey[400]
                                            : Colors.red[700],
                                        fontSize: contentFontSize,
                                      ),
                                      floatingLabelStyle: TextStyle(
                                        color: Colors.red[700],
                                        fontSize: isSmallScreen ? 14 : 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    onChanged: (value) {
                                      setDialogState(() {});
                                    },
                                  ),
                                ),
                                // ✅ Espaciado extra cuando el teclado está visible
                                SizedBox(height: keyboardHeight > 0 ? 80 : 0),
                              ],
                            ),
                          ),
                        ),

                        // ✅ Actions (siempre visible al final)
                        Container(
                          padding: EdgeInsets.all(padding),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(20),
                              bottomRight: Radius.circular(20),
                            ),
                            border: Border(
                              top: BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextButton(
                                  onPressed: isDeleting
                                      ? null
                                      : () {
                                          claveController.clear();
                                          Navigator.of(dialogContext).pop();
                                        },
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.symmetric(
                                      vertical: isSmallScreen ? 10 : 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: Text(
                                    'Cancelar',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w600,
                                      fontSize: isSmallScreen ? 13 : 14,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: (isDeleting ||
                                          claveController.text.isEmpty)
                                      ? null
                                      : () async {
                                          // ✅ Validar clave
                                          if (!CredentialsService
                                              .validateDeletionKey(
                                                  claveController.text)) {
                                            _intentosFallidos++;

                                            if (_intentosFallidos >=
                                                _maxIntentos) {
                                              final ahoraUtc =
                                                  DateTime.now().toUtc();
                                              final ahoraColombia = ahoraUtc
                                                  .subtract(Duration(hours: 5));

                                              setDialogState(() {
                                                _tiempoBloqueo = DateTime.now()
                                                    .add(_duracionBloqueo);
                                                _horaBloqueo =
                                                    DateFormat('hh:mm a', 'es')
                                                        .format(ahoraColombia);
                                              });

                                              await _guardarEstadoBloqueo();

                                              // ✅ Cerrar diálogo con su propio context
                                              if (Navigator.of(dialogContext)
                                                  .canPop()) {
                                                Navigator.of(dialogContext)
                                                    .pop();
                                              }

                                              // ✅ Mostrar ventana de bloqueo con context principal
                                              if (mounted) {
                                                await _mostrarVentanaBloqueo(
                                                    mainContext);
                                              }
                                            } else {
                                              final intentosRestantes =
                                                  _maxIntentos -
                                                      _intentosFallidos;
                                              _mostrarSnackBar(
                                                intentosRestantes == 1
                                                    ? '⚠️ ÚLTIMO INTENTO: Si fallas nuevamente, serás bloqueado por 12 horas.'
                                                    : 'Clave incorrecta. Te quedan $intentosRestantes ${intentosRestantes == 1 ? 'intento' : 'intentos'}.',
                                                isSuccess: false,
                                              );
                                              claveController.clear();
                                            }
                                            return;
                                          }

                                          // ✅ Iniciar proceso de eliminación
                                          setDialogState(
                                              () => isDeleting = true);

                                          try {
                                            print(
                                                '🗑️ Iniciando eliminación de tribu: $docId');

                                            // ✅ Eliminar tribu
                                            await _firestore
                                                .collection('tribus')
                                                .doc(docId)
                                                .delete();
                                            print(
                                                '✅ Tribu eliminada de colección tribus');

                                            // ✅ Eliminar usuario asociado
                                            final usuarioSnapshot =
                                                await _firestore
                                                    .collection('usuarios')
                                                    .where('tribuId',
                                                        isEqualTo: docId)
                                                    .limit(1)
                                                    .get();

                                            if (usuarioSnapshot
                                                .docs.isNotEmpty) {
                                              await usuarioSnapshot
                                                  .docs.first.reference
                                                  .delete();
                                              print(
                                                  '✅ Usuario asociado eliminado');
                                            }

                                            claveController.clear();

                                            // ✅ Actualizar estado del widget principal
                                            if (mounted) {
                                              setState(() {
                                                _intentosFallidos = 0;
                                                _tiempoBloqueo = null;
                                                _horaBloqueo = null;
                                              });
                                              await _guardarEstadoBloqueo();
                                              print(
                                                  '✅ Estado actualizado correctamente');
                                            }

                                            // ✅ Cerrar diálogo con su propio context
                                            if (Navigator.of(dialogContext)
                                                .canPop()) {
                                              Navigator.of(dialogContext).pop();
                                              print('✅ Diálogo cerrado');
                                            }

                                            // ✅ Mostrar mensaje de éxito con context principal
                                            if (mounted) {
                                              _mostrarSnackBar(
                                                'Tribu eliminada exitosamente',
                                                isSuccess: true,
                                              );
                                              print(
                                                  '✅ Eliminación completada exitosamente');
                                            }
                                          } catch (e, stackTrace) {
                                            print(
                                                '❌ Error al eliminar tribu: $e');
                                            print('Stack trace: $stackTrace');

                                            claveController.clear();
                                            setDialogState(
                                                () => isDeleting = false);

                                            // ✅ Mostrar error con context principal
                                            if (mounted) {
                                              _mostrarSnackBar(
                                                'Error al eliminar la tribu: ${e.toString()}',
                                                isSuccess: false,
                                              );
                                            }
                                          }
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red[600],
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(
                                      vertical: isSmallScreen ? 10 : 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    elevation: 2,
                                  ),
                                  child: isDeleting
                                      ? Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            SizedBox(
                                              width: 14,
                                              height: 14,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                        Color>(Colors.white),
                                              ),
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              'Eliminando...',
                                              style: TextStyle(
                                                fontSize:
                                                    isSmallScreen ? 12 : 14,
                                              ),
                                            ),
                                          ],
                                        )
                                      : Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.delete_rounded,
                                              size: isSmallScreen ? 16 : 18,
                                            ),
                                            SizedBox(width: 6),
                                            Text(
                                              'Eliminar',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize:
                                                    isSmallScreen ? 13 : 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ], // Cierre de children del Row de botones
                          ), // Cierre del Row
                        ), // Cierre del Container de acciones
                      ], // Cierre de children de Column
                    ), // Cierre de Column
                  ), // Cierre de Container del Dialog
                ); // Cierre de Dialog
              }, // Cierre de builder de LayoutBuilder
            ); // Cierre de LayoutBuilder
          }, // Cierre de builder de StatefulBuilder
        ), // Cierre de StatefulBuilder
      ), // Cierre de child de WillPopScope
    ); // Cierre de WillPopScope
  } // Cierre de función _mostrarDialogoConfirmarEliminarLiderConsolidacion

// REEMPLAZA COMPLETAMENTE la función _mostrarDialogoConfirmarEliminarLiderConsolidacion
// Busca en tu código (aproximadamente línea 2150) y reemplaza toda la función:

  Future<void> _mostrarDialogoConfirmarEliminarLiderConsolidacion(
      String docId) async {
    _resetInactivityTimer();
    await _cargarEstadoBloqueo();

    if (_estaUsuarioBloqueado()) {
      await _mostrarVentanaBloqueo(context);
      return;
    }

    final TextEditingController claveController = TextEditingController();
    bool isDeleting = false;
    bool obscurePassword = true;

    // ✅ IMPORTANTE: Guardamos el context del State principal
    final BuildContext mainContext = context;

    return showDialog(
      context: mainContext,
      barrierDismissible: true, // ✅ Permitir cerrar al tocar fuera

      builder: (BuildContext dialogContext) => WillPopScope(
        onWillPop: () async => !isDeleting,
        child: StatefulBuilder(
          builder: (context, setDialogState) {
            // ✅ Recalcula en cada rebuild para actualizar con el teclado
            return LayoutBuilder(
              builder: (context, constraints) {
                final mediaQuery = MediaQuery.of(dialogContext);
                final screenWidth = mediaQuery.size.width;
                final screenHeight = mediaQuery.size.height;
                final keyboardHeight = mediaQuery.viewInsets.bottom;

                // ✅ Previene que el diálogo se salga de la pantalla
                final availableHeight = screenHeight - keyboardHeight - 48;

                final isSmallScreen = screenWidth < 400;
                final isMediumScreen = screenWidth >= 400 && screenWidth < 600;

                final titleFontSize = isSmallScreen ? 18.0 : 20.0;
                final subtitleFontSize = isSmallScreen ? 12.0 : 14.0;
                final contentFontSize = isSmallScreen ? 13.0 : 14.0;
                final iconSize = isSmallScreen ? 20.0 : 24.0;
                final padding = isSmallScreen ? 12.0 : 16.0;

                return Dialog(
                  backgroundColor: Colors.transparent,
                  insetPadding: EdgeInsets.only(
                    left: isSmallScreen ? 16 : 24,
                    right: isSmallScreen ? 16 : 24,
                    top: 24,
                    bottom: 24,
                  ),
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: 500,
                      maxHeight: screenHeight - keyboardHeight - 48,
                    ),

                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ✅ Header
                        Container(
                          padding: EdgeInsets.all(padding),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.warning_rounded,
                                  color: Colors.red,
                                  size: iconSize,
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Eliminar Líder',
                                      style: TextStyle(
                                        fontSize: titleFontSize,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red[700],
                                      ),
                                    ),
                                    Text(
                                      'Esta acción no se puede deshacer',
                                      style: TextStyle(
                                        fontSize: subtitleFontSize,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // ✅ Content con scroll
                        Flexible(
                          child: SingleChildScrollView(
                            padding: EdgeInsets.all(padding),
                            keyboardDismissBehavior:
                                ScrollViewKeyboardDismissBehavior.manual,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: EdgeInsets.all(padding),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.red.withOpacity(0.2),
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.info_outline_rounded,
                                        color: Colors.red[700],
                                        size: isSmallScreen ? 18 : 20,
                                      ),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          '¿Está seguro que desea eliminar este líder de consolidación? Esta acción eliminará todos los datos relacionados.',
                                          style: TextStyle(
                                            fontSize: contentFontSize,
                                            color: Colors.red[700],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: padding),
                                Text(
                                  'Ingrese la clave de confirmación:',
                                  style: TextStyle(
                                    fontSize: contentFontSize,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[800],
                                  ),
                                ),
                                SizedBox(height: 12),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.red.withOpacity(0.3),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 4,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: TextField(
                                    controller: claveController,
                                    obscureText: obscurePassword,
                                    enabled: !isDeleting,
                                    enableInteractiveSelection: false,
                                    autocorrect: false,
                                    enableSuggestions: false,
                                    keyboardType: TextInputType.visiblePassword,
                                    style: TextStyle(
                                      color: isDeleting
                                          ? Colors.grey[400]
                                          : Colors.black87,
                                      fontSize: isSmallScreen ? 14 : 16,
                                      letterSpacing: obscurePassword ? 3 : 0,
                                    ),
                                    decoration: InputDecoration(
                                      labelText: 'Clave de confirmación',
                                      hintText: 'Ingrese la clave',
                                      hintStyle: TextStyle(
                                        color: Colors.grey[400],
                                        letterSpacing: 0,
                                      ),
                                      prefixIcon: Container(
                                        margin: EdgeInsets.all(8),
                                        padding: EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: isDeleting
                                              ? Colors.grey.withOpacity(0.1)
                                              : Colors.red.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          Icons.lock_rounded,
                                          color: isDeleting
                                              ? Colors.grey[400]
                                              : Colors.red[700],
                                          size: isSmallScreen ? 18 : 20,
                                        ),
                                      ),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          obscurePassword
                                              ? Icons.visibility_off_rounded
                                              : Icons.visibility_rounded,
                                          color: isDeleting
                                              ? Colors.grey[400]
                                              : Colors.grey[600],
                                          size: isSmallScreen ? 18 : 20,
                                        ),
                                        onPressed: isDeleting
                                            ? null
                                            : () {
                                                setDialogState(() {
                                                  obscurePassword =
                                                      !obscurePassword;
                                                });
                                              },
                                      ),
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 16,
                                      ),
                                      labelStyle: TextStyle(
                                        color: isDeleting
                                            ? Colors.grey[400]
                                            : Colors.red[700],
                                        fontSize: contentFontSize,
                                      ),
                                      floatingLabelStyle: TextStyle(
                                        color: Colors.red[700],
                                        fontSize: isSmallScreen ? 14 : 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    onChanged: (value) {
                                      setDialogState(() {});
                                    },
                                  ),
                                ),
                                // ✅ Espaciado extra cuando el teclado está visible
                                SizedBox(height: keyboardHeight > 0 ? 80 : 0),
                              ],
                            ),
                          ),
                        ),

                        // ✅ Actions (siempre visible al final)
                        Container(
                          padding: EdgeInsets.all(padding),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(20),
                              bottomRight: Radius.circular(20),
                            ),
                            border: Border(
                              top: BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextButton(
                                  onPressed: isDeleting
                                      ? null
                                      : () {
                                          claveController.clear();
                                          Navigator.of(dialogContext).pop();
                                        },
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.symmetric(
                                      vertical: isSmallScreen ? 10 : 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: Text(
                                    'Cancelar',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w600,
                                      fontSize: isSmallScreen ? 13 : 14,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: (isDeleting ||
                                          claveController.text.isEmpty)
                                      ? null
                                      : () async {
                                          // ✅ Validar clave
                                          if (!CredentialsService
                                              .validateDeletionKey(
                                                  claveController.text)) {
                                            _intentosFallidos++;

                                            if (_intentosFallidos >=
                                                _maxIntentos) {
                                              final ahoraUtc =
                                                  DateTime.now().toUtc();
                                              final ahoraColombia = ahoraUtc
                                                  .subtract(Duration(hours: 5));

                                              setDialogState(() {
                                                _tiempoBloqueo = DateTime.now()
                                                    .add(_duracionBloqueo);
                                                _horaBloqueo =
                                                    DateFormat('hh:mm a', 'es')
                                                        .format(ahoraColombia);
                                              });

                                              await _guardarEstadoBloqueo();

                                              // ✅ Cerrar diálogo con su propio context
                                              if (Navigator.of(dialogContext)
                                                  .canPop()) {
                                                Navigator.of(dialogContext)
                                                    .pop();
                                              }

                                              // ✅ Mostrar ventana de bloqueo con context principal
                                              if (mounted) {
                                                await _mostrarVentanaBloqueo(
                                                    mainContext);
                                              }
                                            } else {
                                              final intentosRestantes =
                                                  _maxIntentos -
                                                      _intentosFallidos;
                                              _mostrarSnackBar(
                                                intentosRestantes == 1
                                                    ? '⚠️ ÚLTIMO INTENTO: Si fallas nuevamente, serás bloqueado por 12 horas.'
                                                    : 'Clave incorrecta. Te quedan $intentosRestantes ${intentosRestantes == 1 ? 'intento' : 'intentos'}.',
                                                isSuccess: false,
                                              );
                                              claveController.clear();
                                            }
                                            return;
                                          }

                                          // ✅ Iniciar proceso de eliminación
                                          setDialogState(
                                              () => isDeleting = true);

                                          try {
                                            print(
                                                '🗑️ Iniciando eliminación de líder de consolidación: $docId');

                                            // ✅ Eliminar líder de consolidación
                                            await _firestore
                                                .collection(
                                                    'lideresConsolidacion')
                                                .doc(docId)
                                                .delete();
                                            print(
                                                '✅ Líder eliminado de colección lideresConsolidacion');

                                            // ✅ Eliminar usuario asociado
                                            final usuarioSnapshot =
                                                await _firestore
                                                    .collection('usuarios')
                                                    .where(
                                                        'rol',
                                                        isEqualTo:
                                                            'liderConsolidacion')
                                                    .get();

                                            if (usuarioSnapshot
                                                .docs.isNotEmpty) {
                                              await usuarioSnapshot
                                                  .docs.first.reference
                                                  .delete();
                                              print(
                                                  '✅ Usuario asociado eliminado');
                                            }

                                            claveController.clear();

                                            // ✅ Actualizar estado del widget principal
                                            if (mounted) {
                                              setState(() {
                                                _intentosFallidos = 0;
                                                _tiempoBloqueo = null;
                                                _horaBloqueo = null;
                                                _existeLiderConsolidacion =
                                                    false;
                                              });
                                              await _guardarEstadoBloqueo();
                                              print(
                                                  '✅ Estado actualizado correctamente');
                                            }

                                            // ✅ Cerrar diálogo con su propio context
                                            if (Navigator.of(dialogContext)
                                                .canPop()) {
                                              Navigator.of(dialogContext).pop();
                                              print('✅ Diálogo cerrado');
                                            }

                                            // ✅ Mostrar mensaje de éxito con context principal
                                            if (mounted) {
                                              _mostrarSnackBar(
                                                'Líder de consolidación eliminado exitosamente',
                                                isSuccess: true,
                                              );
                                              print(
                                                  '✅ Eliminación completada exitosamente');
                                            }
                                          } catch (e, stackTrace) {
                                            print(
                                                '❌ Error al eliminar líder de consolidación: $e');
                                            print('Stack trace: $stackTrace');

                                            claveController.clear();
                                            setDialogState(
                                                () => isDeleting = false);

                                            // ✅ Mostrar error con context principal
                                            if (mounted) {
                                              _mostrarSnackBar(
                                                'Error al eliminar el líder: ${e.toString()}',
                                                isSuccess: false,
                                              );
                                            }
                                          }
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red[600],
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(
                                      vertical: isSmallScreen ? 10 : 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    elevation: 2,
                                  ),
                                  child: isDeleting
                                      ? Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            SizedBox(
                                              width: 14,
                                              height: 14,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                        Color>(Colors.white),
                                              ),
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              'Eliminando...',
                                              style: TextStyle(
                                                fontSize:
                                                    isSmallScreen ? 12 : 14,
                                              ),
                                            ),
                                          ],
                                        )
                                      : Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.delete_rounded,
                                              size: isSmallScreen ? 16 : 18,
                                            ),
                                            SizedBox(width: 6),
                                            Text(
                                              'Eliminar',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize:
                                                    isSmallScreen ? 13 : 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ], // Cierre de children del Row de botones
                          ), // Cierre del Row
                        ), // Cierre del Container de acciones
                      ], // Cierre de children de Column
                    ), // Cierre de Column
                  ), // Cierre de Container del Dialog
                ); // Cierre de Dialog
              }, // Cierre de builder de LayoutBuilder
            ); // Cierre de LayoutBuilder
          }, // Cierre de builder de StatefulBuilder
        ),
      ),
    );
  }
}


