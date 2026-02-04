// Flutter
import 'package:flutter/material.dart';

// Paquetes externos
import 'package:go_router/go_router.dart';

// Proyecto
import 'package:formulario_app/services/auth_service.dart';
import 'package:formulario_app/utils/error_handler.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'dart:html' as html;

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final _usuarioController = TextEditingController();
  final _contrasenaController = TextEditingController();
  final FocusNode _usuarioFocus = FocusNode();
  final FocusNode _contrasenaFocus = FocusNode();
  bool _isLoading = false;
  bool _obscureText = true;
  late AnimationController _fadeController;
  late AnimationController _floatingController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _floatingAnimation;
  late Animation<double> _scaleAnimation;

  // Colores COCEP
  final Color cocepTeal = const Color(0xFF1D8B96);
  final Color cocepOrange = const Color(0xFFFF5722);

  @override
  void initState() {
    super.initState();

    // ✅ NUEVO: Refrescar página automáticamente solo UNA VEZ
    _verificarYRefrescarPagina();

    // Animación de fade-in
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutBack),
    );

    // Animación flotante para el logo
    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _floatingAnimation = Tween<double>(begin: -8.0, end: 8.0).animate(
      CurvedAnimation(parent: _floatingController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
  }

// ============================================================
// AGREGAR este método NUEVO después del método initState():
// ============================================================

  /// Verifica si la página necesita refrescarse y lo hace solo UNA VEZ
  Future<void> _verificarYRefrescarPagina() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final yaRefrescado = prefs.getBool('loginPageRefreshed') ?? false;

      // Solo refrescar si NO se ha refrescado antes en esta sesión
      if (!yaRefrescado) {
        print('🔄 Refrescando página del login para cargar última versión...');

        // Marcar como refrescado ANTES de refrescar para evitar bucles
        await prefs.setBool('loginPageRefreshed', true);

        // Refrescar la página en Flutter Web
        html.window.location.reload();
      } else {
        print('✅ Página ya refrescada previamente, no se volverá a refrescar');
      }
    } catch (e) {
      print(
          '⚠️ Error al verificar refresh (probablemente no es Flutter Web): $e');
      // No hacer nada si falla (por ejemplo, en app móvil nativa)
    }
  }

  @override
  void dispose() {
    _usuarioController.dispose();
    _contrasenaController.dispose();
    _usuarioFocus.dispose();
    _contrasenaFocus.dispose();
    _fadeController.dispose();
    _floatingController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final result = await _authService.login(
        _usuarioController.text.trim(),
        _contrasenaController.text.trim(),
      );

      if (!mounted) return;

      if (result != null) {
        if (!mounted) return;

        switch (result['role']) {
          case 'adminPastores':
            if (mounted) {
              context.go('/admin_pastores');
            }
            break;
          case 'liderConsolidacion':
            if (mounted) {
              context.go('/admin');
            }
            break;
          case 'coordinador':
            if (mounted) {
              final coordinadorId = result['coordinadorId'] ?? '';
              final coordinadorNombre = result['coordinadorNombre'] ?? '';
              context.go('/coordinador/$coordinadorId/$coordinadorNombre');
            }
            break;
          case 'tribu':
            if (mounted) {
              final tribuId = result['tribuId'] ?? '';
              final nombreTribu = result['nombreTribu'] ?? '';
              context.go('/tribus/$tribuId/$nombreTribu');
            }
            break;
          case 'timoteo':
            if (mounted) {
              final timoteoId = result['timoteoId'] ?? '';
              final timoteoNombre = result['timoteoNombre'] ?? '';
              context.go('/timoteos/$timoteoId/$timoteoNombre');
            }
            break;
          case 'liderMinisterio':
            if (mounted) {
              final ministerio = result['ministerio'] ?? '';
              context
                  .go('/ministerio_lider', extra: {'ministerio': ministerio});
            }
            break;

          case 'departamentoDiscipulado':
            if (mounted) {
              context.go('/departamento_discipulado');
            }
            break;

          case 'maestroDiscipulado':
            if (mounted) {
              final maestroId = result['maestroId'] ?? '';
              final maestroNombre = result['maestroNombre'] ?? '';
              final claseAsignadaId = result['claseAsignadaId'];

              if (claseAsignadaId != null) {
                context.go(
                    '/maestro_discipulado/$maestroId/$maestroNombre?claseAsignadaId=$claseAsignadaId');
              } else {
                context.go('/maestro_discipulado/$maestroId/$maestroNombre');
              }
            }
            break;

          default:
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Rol no reconocido')),
              );
            }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(child: Text('Credenciales inválidas')),
                ],
              ),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text('Ocurrió un error al iniciar sesión')),
              ],
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    // Tamaños responsivos
    final bool isSmallScreen = size.width < 360;
    final bool isMediumScreen = size.width >= 360 && size.width < 600;
    final bool isLargeScreen = size.width >= 600;

    final double horizontalPadding =
        isSmallScreen ? 20 : (isMediumScreen ? 24 : 32);
    final double logoSize = isSmallScreen ? 90 : (isMediumScreen ? 110 : 130);
    final double titleSize = isSmallScreen ? 28 : (isMediumScreen ? 34 : 40);
    final double subtitleSize = isSmallScreen ? 14 : (isMediumScreen ? 16 : 18);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              cocepTeal,
              cocepTeal.withOpacity(0.85),
              const Color(0xFF156B75),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // Círculos decorativos de fondo
            Positioned(
              top: -100,
              right: -100,
              child: _buildDecorativeCircle(250, cocepOrange.withOpacity(0.1)),
            ),
            Positioned(
              bottom: -80,
              left: -80,
              child:
                  _buildDecorativeCircle(200, Colors.white.withOpacity(0.05)),
            ),
            Positioned(
              top: size.height * 0.3,
              right: -50,
              child:
                  _buildDecorativeCircle(150, Colors.white.withOpacity(0.03)),
            ),

            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: horizontalPadding,
                              vertical: keyboardVisible ? 16 : 20,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (!keyboardVisible) ...[
                                  SizedBox(height: isSmallScreen ? 20 : 30),
                                  // Logo animado de COCEP
                                  ScaleTransition(
                                    scale: _scaleAnimation,
                                    child: AnimatedBuilder(
                                      animation: _floatingAnimation,
                                      builder: (context, child) {
                                        return Transform.translate(
                                          offset: Offset(
                                              0, _floatingAnimation.value),
                                          child: child,
                                        );
                                      },
                                      child: Hero(
                                        tag: 'login_logo',
                                        child: Container(
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.white,
                                            boxShadow: [
                                              BoxShadow(
                                                color: cocepOrange
                                                    .withOpacity(0.3),
                                                spreadRadius: 0,
                                                blurRadius: 30,
                                                offset: const Offset(0, 10),
                                              ),
                                              BoxShadow(
                                                color: Colors.black
                                                    .withOpacity(0.1),
                                                spreadRadius: 2,
                                                blurRadius: 15,
                                                offset: const Offset(0, 5),
                                              ),
                                            ],
                                          ),
                                          padding: const EdgeInsets.all(12),
                                          child: ClipOval(
                                            child: Image.asset(
                                              'assets/Cocep_.png',
                                              height: logoSize,
                                              width: logoSize,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: isSmallScreen ? 20 : 28),
                                  // Título con efecto de brillo
                                  ShaderMask(
                                    shaderCallback: (bounds) => LinearGradient(
                                      colors: [
                                        Colors.white,
                                        Colors.white.withOpacity(0.9),
                                      ],
                                    ).createShader(bounds),
                                    child: Text(
                                      'Bienvenido',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: titleSize,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        letterSpacing: 0.5,
                                        height: 1.2,
                                        shadows: [
                                          Shadow(
                                            color:
                                                Colors.black.withOpacity(0.3),
                                            offset: const Offset(0, 3),
                                            blurRadius: 8,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: isSmallScreen ? 8 : 10),
                                  // Subtítulo
                                  Text(
                                    'Inicia sesión en tu cuenta',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: subtitleSize,
                                      color: Colors.white.withOpacity(0.95),
                                      letterSpacing: 0.3,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                  SizedBox(height: isSmallScreen ? 28 : 36),
                                ] else ...[
                                  const SizedBox(height: 12),
                                ],
                                // Tarjeta del formulario con glassmorphism
                                ScaleTransition(
                                  scale: _scaleAnimation,
                                  child: Container(
                                    constraints: BoxConstraints(
                                      maxWidth:
                                          isLargeScreen ? 480 : double.infinity,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.98),
                                      borderRadius: BorderRadius.circular(28),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.15),
                                          spreadRadius: 0,
                                          blurRadius: 40,
                                          offset: const Offset(0, 15),
                                        ),
                                        BoxShadow(
                                          color: cocepOrange.withOpacity(0.1),
                                          spreadRadius: 0,
                                          blurRadius: 25,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(28),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.white,
                                              Colors.grey[50]!,
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                        ),
                                        padding: EdgeInsets.all(
                                            isSmallScreen ? 24 : 32),
                                        child: Form(
                                          key: _formKey,
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              _buildPremiumTextField(
                                                controller: _usuarioController,
                                                focusNode: _usuarioFocus,
                                                label: 'Usuario',
                                                hint: 'Ingresa tu usuario',
                                                icon: Icons
                                                    .person_outline_rounded,
                                                validator: (value) =>
                                                    value?.isEmpty ?? true
                                                        ? 'Ingresa tu usuario'
                                                        : null,
                                                onFieldSubmitted: (_) {
                                                  FocusScope.of(context)
                                                      .requestFocus(
                                                          _contrasenaFocus);
                                                },
                                                textInputAction:
                                                    TextInputAction.next,
                                                fontSize:
                                                    isSmallScreen ? 14 : 16,
                                              ),
                                              SizedBox(
                                                  height:
                                                      isSmallScreen ? 18 : 22),
                                              _buildPremiumTextField(
                                                controller:
                                                    _contrasenaController,
                                                focusNode: _contrasenaFocus,
                                                label: 'Contraseña',
                                                hint: 'Ingresa tu contraseña',
                                                icon:
                                                    Icons.lock_outline_rounded,
                                                obscureText: _obscureText,
                                                suffixIcon: IconButton(
                                                  icon: Icon(
                                                    _obscureText
                                                        ? Icons
                                                            .visibility_outlined
                                                        : Icons
                                                            .visibility_off_outlined,
                                                    color: cocepTeal,
                                                    size:
                                                        isSmallScreen ? 20 : 22,
                                                  ),
                                                  onPressed: () {
                                                    setState(() =>
                                                        _obscureText =
                                                            !_obscureText);
                                                  },
                                                ),
                                                validator: (value) => value
                                                            ?.isEmpty ??
                                                        true
                                                    ? 'Ingresa tu contraseña'
                                                    : null,
                                                onFieldSubmitted: (_) =>
                                                    _login(),
                                                textInputAction:
                                                    TextInputAction.done,
                                                fontSize:
                                                    isSmallScreen ? 14 : 16,
                                              ),
                                              SizedBox(
                                                  height:
                                                      isSmallScreen ? 28 : 36),
                                              // Botón premium con efecto hover
                                              _buildPremiumButton(
                                                isSmallScreen: isSmallScreen,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                if (!keyboardVisible)
                                  SizedBox(height: isSmallScreen ? 20 : 30),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDecorativeCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }

  Widget _buildPremiumTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    bool obscureText = false,
    Widget? suffixIcon,
    void Function(String)? onFieldSubmitted,
    TextInputAction? textInputAction,
    double fontSize = 16,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        obscureText: obscureText,
        textInputAction: textInputAction,
        style: TextStyle(
          color: const Color(0xFF2C3E50),
          fontSize: fontSize,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.3,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: TextStyle(
            color: cocepTeal.withOpacity(0.7),
            fontSize: fontSize - 1,
            fontWeight: FontWeight.w500,
          ),
          hintStyle: TextStyle(
            color: Colors.grey[400],
            fontSize: fontSize - 2,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.only(right: 12),
            child: Icon(
              icon,
              color: cocepTeal,
              size: fontSize + 6,
            ),
          ),
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: cocepTeal, width: 2.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.redAccent, width: 2.5),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 20,
            vertical: fontSize > 14 ? 18 : 16,
          ),
        ),
        validator: validator,
        onFieldSubmitted: onFieldSubmitted,
      ),
    );
  }

  Widget _buildPremiumButton({required bool isSmallScreen}) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: isSmallScreen ? 54 : 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: _isLoading
                ? [Colors.grey[400]!, Colors.grey[400]!]
                : [
                    cocepOrange,
                    const Color(0xFFFF7043),
                  ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: _isLoading
              ? []
              : [
                  BoxShadow(
                    color: cocepOrange.withOpacity(0.4),
                    spreadRadius: 0,
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: cocepOrange.withOpacity(0.2),
                    spreadRadius: 0,
                    blurRadius: 25,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: _isLoading ? null : _login,
            child: Container(
              alignment: Alignment.center,
              child: _isLoading
                  ? SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white.withOpacity(0.9),
                        ),
                        strokeWidth: 3,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'INICIAR SESIÓN',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 16 : 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: isSmallScreen ? 20 : 22,
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
