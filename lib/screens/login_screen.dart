// Flutter
import 'package:flutter/material.dart';

// Paquetes externos
import 'package:go_router/go_router.dart';

// Proyecto
import 'package:formulario_app/services/auth_service.dart';
import 'package:formulario_app/utils/error_handler.dart';
import 'package:formulario_app/screens/TimoteosScreen.dart';
import 'package:formulario_app/screens/admin_screen.dart';

// Locales
import 'CoordinadorScreen.dart';
import 'TribusScreen.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final _usuarioController = TextEditingController();
  final _contrasenaController = TextEditingController();
  final FocusNode _usuarioFocus = FocusNode();
  final FocusNode _contrasenaFocus = FocusNode();
  bool _isLoading = false;
  bool _obscureText = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Definimos los colores personalizados de COCEP
  final Color cocepTeal = const Color(0xFF1D8B96);
  final Color cocepOrange = const Color(0xFFFF5722);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _usuarioController.dispose();
    _contrasenaController.dispose();
    _usuarioFocus.dispose();
    _contrasenaFocus.dispose();
    _animationController.dispose();
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
            const SnackBar(
              content: Text('Credenciales inválidas'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ocurrió un error al iniciar sesión'),
            backgroundColor: Colors.redAccent,
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

    // Determinamos tamaños responsivos
    final bool isSmallScreen = size.width < 360;
    final bool isMediumScreen = size.width >= 360 && size.width < 600;
    final bool isLargeScreen = size.width >= 600;

    final double horizontalPadding =
        isSmallScreen ? 20 : (isMediumScreen ? 24 : 32);
    final double logoSize = isSmallScreen ? 80 : (isMediumScreen ? 100 : 120);
    final double titleSize = isSmallScreen ? 26 : (isMediumScreen ? 32 : 38);
    final double subtitleSize = isSmallScreen ? 13 : (isMediumScreen ? 15 : 17);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              cocepTeal,
              cocepTeal.withOpacity(0.8),
              cocepTeal.withOpacity(0.6),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
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
                          vertical: keyboardVisible ? 16 : 24,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (!keyboardVisible) ...[
                              SizedBox(height: isSmallScreen ? 10 : 20),
                              // Logo de COCEP
                              Hero(
                                tag: 'login_logo',
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        spreadRadius: 3,
                                        blurRadius: 15,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsets.all(8),
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
                              SizedBox(height: isSmallScreen ? 16 : 24),
                              // Título
                              Text(
                                'Bienvenido',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: titleSize,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.3),
                                      offset: const Offset(0, 2),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: isSmallScreen ? 6 : 8),
                              // Subtítulo
                              Text(
                                'Inicia sesión para continuar',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: subtitleSize,
                                  color: Colors.white.withOpacity(0.9),
                                  letterSpacing: 0.3,
                                ),
                              ),
                              SizedBox(height: isSmallScreen ? 24 : 32),
                            ] else ...[
                              const SizedBox(height: 8),
                            ],
                            // Formulario con fondo blanco
                            Container(
                              constraints: BoxConstraints(
                                maxWidth: isLargeScreen ? 500 : double.infinity,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    spreadRadius: 2,
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              padding: EdgeInsets.all(isSmallScreen ? 20 : 28),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildTextField(
                                      controller: _usuarioController,
                                      focusNode: _usuarioFocus,
                                      label: 'Usuario',
                                      icon: Icons.person_outline,
                                      validator: (value) =>
                                          value?.isEmpty ?? true
                                              ? 'Ingresa tu usuario'
                                              : null,
                                      onFieldSubmitted: (_) {
                                        FocusScope.of(context)
                                            .requestFocus(_contrasenaFocus);
                                      },
                                      textInputAction: TextInputAction.next,
                                      fontSize: isSmallScreen ? 14 : 16,
                                    ),
                                    SizedBox(height: isSmallScreen ? 16 : 20),
                                    _buildTextField(
                                      controller: _contrasenaController,
                                      focusNode: _contrasenaFocus,
                                      label: 'Contraseña',
                                      icon: Icons.lock_outline,
                                      obscureText: _obscureText,
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscureText
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                          color: cocepTeal,
                                          size: isSmallScreen ? 20 : 24,
                                        ),
                                        onPressed: () {
                                          setState(() =>
                                              _obscureText = !_obscureText);
                                        },
                                      ),
                                      validator: (value) =>
                                          value?.isEmpty ?? true
                                              ? 'Ingresa tu contraseña'
                                              : null,
                                      onFieldSubmitted: (_) => _login(),
                                      textInputAction: TextInputAction.done,
                                      fontSize: isSmallScreen ? 14 : 16,
                                    ),
                                    SizedBox(height: isSmallScreen ? 24 : 32),
                                    // Botón de login
                                    Container(
                                      width: double.infinity,
                                      height: isSmallScreen ? 50 : 56,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(28),
                                        gradient: LinearGradient(
                                          colors: [
                                            cocepOrange,
                                            Colors.amber,
                                          ],
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: cocepOrange.withOpacity(0.4),
                                            spreadRadius: 1,
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: ElevatedButton(
                                        onPressed: _isLoading ? null : _login,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          shadowColor: Colors.transparent,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(28),
                                          ),
                                        ),
                                        child: _isLoading
                                            ? SizedBox(
                                                width: 24,
                                                height: 24,
                                                child:
                                                    const CircularProgressIndicator(
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                          Color>(Colors.white),
                                                  strokeWidth: 2.5,
                                                ),
                                              )
                                            : Text(
                                                'INICIAR SESIÓN',
                                                style: TextStyle(
                                                  fontSize:
                                                      isSmallScreen ? 15 : 17,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                  letterSpacing: 1.2,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (!keyboardVisible)
                              SizedBox(height: isSmallScreen ? 16 : 24),
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
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    bool obscureText = false,
    Widget? suffixIcon,
    void Function(String)? onFieldSubmitted,
    TextInputAction? textInputAction,
    double fontSize = 16,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      textInputAction: textInputAction,
      style: TextStyle(
        color: cocepTeal,
        fontSize: fontSize,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: cocepTeal.withOpacity(0.7),
          fontSize: fontSize,
        ),
        prefixIcon: Icon(
          icon,
          color: cocepTeal,
          size: fontSize + 6,
        ),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: cocepTeal.withOpacity(0.3), width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: cocepTeal.withOpacity(0.3), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: cocepTeal, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: fontSize > 14 ? 16 : 14,
        ),
      ),
      validator: validator,
      onFieldSubmitted: onFieldSubmitted,
    );
  }
}
