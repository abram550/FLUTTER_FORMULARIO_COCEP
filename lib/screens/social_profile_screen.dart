// Flutter
import 'package:flutter/material.dart';
import 'dart:math' as math;

// Paquetes externos
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// Proyecto / Locales
import '../models/social_profile.dart';

class SocialProfileScreen extends StatefulWidget {
  const SocialProfileScreen({super.key});

  @override
  _SocialProfileScreenState createState() => _SocialProfileScreenState();
}

class _SocialProfileScreenState extends State<SocialProfileScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _prayerRequestController =
      TextEditingController();

  final FocusNode _nameFocus = FocusNode();
  final FocusNode _lastNameFocus = FocusNode();
  final FocusNode _ageFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _addressFocus = FocusNode();
  final FocusNode _cityFocus = FocusNode();
  final FocusNode _prayerRequestFocus = FocusNode();

  String? _selectedGender;
  String _selectedSocialNetwork = 'Facebook';
  bool _isSubmitting = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Colores del logo COCEP
  static const Color primaryTeal = Color(0xFF1D8B96);
  static const Color primaryOrange = Color(0xFFFF5722);
  static const Color amberGold = Color(0xFFFFC107);
  static const Color lightTeal = Color(0xFF4DB8C4);
  static const Color backgroundGray = Color(0xFFF8F9FA);

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _lastNameController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _prayerRequestController.dispose();
    _nameFocus.dispose();
    _lastNameFocus.dispose();
    _ageFocus.dispose();
    _phoneFocus.dispose();
    _addressFocus.dispose();
    _cityFocus.dispose();
    _prayerRequestFocus.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;

    return Scaffold(
      backgroundColor: backgroundGray,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // AppBar Premium con Logo

          SliverAppBar(
            expandedHeight: isSmallScreen ? 220.0 : 260.0,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: primaryTeal,
            // AppBar colapsado premium
            title: AnimatedOpacity(
              opacity: 1.0,
              duration: const Duration(milliseconds: 300),
              child: Row(
                children: [
                  // Logo pequeño en el appbar colapsado
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(4),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/Cocep_.png',
                        height: 32,
                        width: 32,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Datos Personales',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isSmallScreen ? 16 : 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),
                        Text(
                          'Redes Sociales',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: isSmallScreen ? 11 : 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Indicador de redes sociales en el appbar colapsado
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.2),
                          Colors.white.withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FaIcon(
                          FontAwesomeIcons.share,
                          color: Colors.white,
                          size: 14,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Social',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            flexibleSpace: FlexibleSpaceBar(
              titlePadding: EdgeInsets.zero,
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Gradiente de fondo con colores del logo
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          primaryTeal,
                          lightTeal,
                          primaryOrange.withOpacity(0.3),
                        ],
                      ),
                    ),
                  ),
                  // Figuras geométricas animadas de fondo
                  Positioned(
                    right: -40,
                    top: -40,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(seconds: 3),
                      builder: (context, value, child) {
                        return Transform.rotate(
                          angle: value * 0.5,
                          child: Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  amberGold.withOpacity(0.12),
                                  amberGold.withOpacity(0.05),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Positioned(
                    left: -20,
                    top: 100,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(seconds: 4),
                      builder: (context, value, child) {
                        return Transform.rotate(
                          angle: -value * 0.3,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withOpacity(0.08),
                                  Colors.white.withOpacity(0.02),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  // Triángulos decorativos sutiles
                  Positioned(
                    right: isSmallScreen ? 10 : 30,
                    bottom: isSmallScreen ? 100 : 120,
                    child: CustomPaint(
                      size: Size(
                          isSmallScreen ? 40 : 60, isSmallScreen ? 40 : 60),
                      painter: TrianglePainter(
                        color: Colors.white.withOpacity(0.06),
                      ),
                    ),
                  ),
                  Positioned(
                    left: isSmallScreen ? 15 : 40,
                    top: isSmallScreen ? 160 : 180,
                    child: CustomPaint(
                      size: Size(
                          isSmallScreen ? 30 : 50, isSmallScreen ? 30 : 50),
                      painter: TrianglePainter(
                        color: primaryOrange.withOpacity(0.08),
                      ),
                    ),
                  ),
                  // Puntos decorativos responsivos
                  Positioned(
                    right: isSmallScreen ? 15 : 25,
                    bottom: isSmallScreen ? 115 : 130,
                    child: Column(
                      children: List.generate(
                        3,
                        (index) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            children: List.generate(
                              3,
                              (i) => Container(
                                margin: EdgeInsets.symmetric(
                                  horizontal: isSmallScreen ? 3 : 4,
                                ),
                                width: isSmallScreen ? 3 : 4,
                                height: isSmallScreen ? 3 : 4,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.25),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Logo COCEP con animación premium flotante
                  Positioned(
                    top: isSmallScreen ? 60 : 70,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: _AnimatedFloatingLogo(
                        isSmallScreen: isSmallScreen,
                      ),
                    ),
                  ),
                  // Iconos de redes sociales horizontales a la derecha - Responsivos
                  Positioned(
                    right: isSmallScreen ? 15 : 25,
                    bottom: isSmallScreen ? 45 : 55,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildIndividualSocialIcon(
                          FontAwesomeIcons.facebook,
                          isSmallScreen,
                        ),
                        SizedBox(width: isSmallScreen ? 12 : 15),
                        _buildIndividualSocialIcon(
                          FontAwesomeIcons.youtube,
                          isSmallScreen,
                        ),
                        // Instagram comentado pero listo para usar
                        // SizedBox(width: isSmallScreen ? 12 : 15),
                        // _buildIndividualSocialIcon(
                        //   FontAwesomeIcons.instagram,
                        //   isSmallScreen,
                        // ),
                      ],
                    ),
                  ),
                  // Curva inferior con efecto de sombra
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: -1,
                    child: Container(
                      height: 35,
                      decoration: BoxDecoration(
                        color: backgroundGray,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(30),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: primaryTeal.withOpacity(0.2),
                            blurRadius: 15,
                            offset: const Offset(0, -5),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Contenido del formulario
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                color: backgroundGray,
                child: Padding(
                  padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Mensaje de bienvenida
                        _buildWelcomeMessage(isSmallScreen),
                        SizedBox(height: 24),
                        // Tarjeta de información personal
                        _buildSectionCard(
                          title: 'Información Personal',
                          icon: Icons.person_outline_rounded,
                          children: [
                            _buildPremiumTextField(
                              _nameController,
                              _nameFocus,
                              'Nombre',
                              Icons.person_outline_rounded,
                              hint: 'Ingresa tu nombre',
                              onFieldSubmitted: (_) {
                                FocusScope.of(context)
                                    .requestFocus(_lastNameFocus);
                              },
                              textInputAction: TextInputAction.next,
                            ),
                            _buildPremiumTextField(
                              _lastNameController,
                              _lastNameFocus,
                              'Apellido',
                              Icons.badge_outlined,
                              hint: 'Ingresa tu apellido',
                              onFieldSubmitted: (_) {
                                FocusScope.of(context).requestFocus(_ageFocus);
                              },
                              textInputAction: TextInputAction.next,
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildPremiumTextField(
                                    _ageController,
                                    _ageFocus,
                                    'Edad',
                                    Icons.cake_outlined,
                                    keyboardType: TextInputType.number,
                                    hint: 'Ej: 25',
                                    onFieldSubmitted: (_) {
                                      FocusScope.of(context)
                                          .requestFocus(_phoneFocus);
                                    },
                                    textInputAction: TextInputAction.next,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(child: _buildGenderSelector()),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
                        // Tarjeta de contacto
                        _buildSectionCard(
                          title: 'Información de Contacto',
                          icon: Icons.contacts_outlined,
                          children: [
                            _buildPremiumTextField(
                              _phoneController,
                              _phoneFocus,
                              'Teléfono',
                              Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                              hint: 'Ej: +57 300 123 4567',
                              onFieldSubmitted: (_) {
                                FocusScope.of(context)
                                    .requestFocus(_addressFocus);
                              },
                              textInputAction: TextInputAction.next,
                            ),
                            _buildPremiumTextField(
                              _addressController,
                              _addressFocus,
                              'Dirección',
                              Icons.home_outlined,
                              hint: 'Ingresa tu dirección',
                              onFieldSubmitted: (_) {
                                FocusScope.of(context).requestFocus(_cityFocus);
                              },
                              textInputAction: TextInputAction.next,
                            ),
                            _buildPremiumTextField(
                              _cityController,
                              _cityFocus,
                              'Ciudad',
                              Icons.location_city_outlined,
                              hint: 'Ingresa tu ciudad',
                              onFieldSubmitted: (_) {
                                FocusScope.of(context)
                                    .requestFocus(_prayerRequestFocus);
                              },
                              textInputAction: TextInputAction.next,
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
                        // Tarjeta de petición de oración
                        _buildSectionCard(
                          title: 'Petición de Oración',
                          icon: Icons.favorite_outline_rounded,
                          children: [
                            _buildPremiumTextField(
                              _prayerRequestController,
                              _prayerRequestFocus,
                              '¿Por qué quieres que oremos?',
                              Icons.comment_outlined,
                              maxLines: 4,
                              hint:
                                  'Comparte tu petición de oración con nosotros...',
                              onFieldSubmitted: (_) {
                                _prayerRequestFocus.unfocus();
                              },
                              textInputAction: TextInputAction.done,
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
                        // Selector de redes sociales mejorado
                        _buildEnhancedSocialNetworkSelector(isSmallScreen),
                        SizedBox(height: 32),
                        // Botón de envío premium
                        _buildPremiumSubmitButton(isSmallScreen),
                        SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeMessage(bool isSmallScreen) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryTeal.withOpacity(0.1),
            amberGold.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: primaryTeal.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryOrange, amberGold],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: primaryOrange.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.volunteer_activism_rounded,
              color: Colors.white,
              size: isSmallScreen ? 28 : 32,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¡Gracias por conectarte!',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 16 : 18,
                    fontWeight: FontWeight.bold,
                    color: primaryTeal,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Dios te bendiga abundantemente',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 13 : 14,
                    color: const Color(0xFF2C3E50),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDecorativeIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: FaIcon(
        icon,
        color: Colors.white.withOpacity(0.8),
        size: 20,
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryTeal.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        primaryTeal.withOpacity(0.15),
                        lightTeal.withOpacity(0.15),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: primaryTeal,
                    size: 24,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primaryTeal,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumTextField(
    TextEditingController controller,
    FocusNode focusNode,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
    int maxLines = 1,
    String? hint,
    void Function(String)? onFieldSubmitted,
    TextInputAction? textInputAction,
  }) {
    // Detectar si es pantalla pequeña
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: keyboardType,
        maxLines: maxLines,
        textInputAction: textInputAction,
        onFieldSubmitted: onFieldSubmitted,
        style: TextStyle(
          color: const Color(0xFF2C3E50),
          fontSize: isSmallScreen ? 14 : 15,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: TextStyle(
            color: primaryTeal.withOpacity(0.7),
            fontSize: isSmallScreen ? 12 : 14,
            fontWeight: FontWeight.w500,
          ),
          hintStyle: TextStyle(
            color: Colors.grey[400],
            fontSize: isSmallScreen ? 11 : 13,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.only(right: 12),
            child: Icon(
              icon,
              color: primaryTeal,
              size: isSmallScreen ? 20 : 22,
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: primaryTeal, width: 2.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.redAccent, width: 2.5),
          ),
          filled: true,
          fillColor: backgroundGray,
          contentPadding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 12 : 16,
            vertical: maxLines > 1
                ? (isSmallScreen ? 14 : 16)
                : (isSmallScreen ? 12 : 14),
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Por favor completa este campo';
          }
          if (label == 'Edad') {
            final age = int.tryParse(value);
            if (age == null) {
              return 'Ingresa un número válido';
            }
            if (age < 0 || age > 120) {
              return 'Ingresa una edad válida';
            }
          }
          return null;
        },
      ),
    );
  }

  Widget _buildGenderSelector() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.grey[300]!,
          width: 1.5,
        ),
        color: backgroundGray,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _selectedGender,
            hint: Row(
              children: [
                Icon(Icons.wc_outlined, color: primaryTeal, size: 20),
                SizedBox(width: 8),
                Text(
                  'Género',
                  style: TextStyle(
                    color: primaryTeal.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            isExpanded: true,
            icon: Icon(Icons.arrow_drop_down_rounded, color: primaryTeal),
            items: ['Hombre', 'Mujer'].map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(
                  value,
                  style: TextStyle(
                    color: const Color(0xFF2C3E50),
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _selectedGender = newValue;
              });
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedSocialNetworkSelector(bool isSmallScreen) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryTeal.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primaryTeal.withOpacity(0.15),
                      lightTeal.withOpacity(0.15),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.share_outlined,
                  color: primaryTeal,
                  size: 24,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  '¿Por cuál red te conectaste?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primaryTeal,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Wrap(
            spacing: isSmallScreen ? 12 : 16,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              _buildSocialNetworkOption(
                'Facebook',
                FontAwesomeIcons.facebook,
                const Color(0xFF1877F2),
                isSmallScreen,
              ),
              _buildSocialNetworkOption(
                'YouTube',
                FontAwesomeIcons.youtube,
                const Color(0xFFFF0000),
                isSmallScreen,
              ),
              // Instagram - Comentado pero listo para activar
              // _buildSocialNetworkOption(
              //   'Instagram',
              //   FontAwesomeIcons.instagram,
              //   const Color(0xFFE4405F),
              //   isSmallScreen,
              // ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSocialNetworkOption(
    String network,
    IconData icon,
    Color brandColor,
    bool isSmallScreen,
  ) {
    final isSelected = _selectedSocialNetwork == network;
    final width = isSmallScreen ? 140.0 : 160.0;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedSocialNetwork = network;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [brandColor, brandColor.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : backgroundGray,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? brandColor : Colors.grey[300]!,
            width: isSelected ? 2 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: brandColor.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(
              icon,
              size: isSmallScreen ? 32 : 36,
              color: isSelected ? Colors.white : brandColor,
            ),
            SizedBox(height: 12),
            Text(
              network,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF2C3E50),
                fontWeight: FontWeight.bold,
                fontSize: isSmallScreen ? 14 : 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumSubmitButton(bool isSmallScreen) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: isSmallScreen ? 56 : 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: _isSubmitting
            ? null
            : LinearGradient(
                colors: [primaryOrange, amberGold],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
        color: _isSubmitting ? Colors.grey[400] : null,
        boxShadow: _isSubmitting
            ? []
            : [
                BoxShadow(
                  color: primaryOrange.withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _isSubmitting ? null : _submitForm,
          child: Container(
            alignment: Alignment.center,
            child: _isSubmitting
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
                      Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: isSmallScreen ? 20 : 22,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'ENVIAR',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 16 : 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildIndividualSocialIcon(IconData icon, bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
        border: Border.all(
          color: Colors.white.withOpacity(0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: FaIcon(
        icon,
        color: Colors.white,
        size: isSmallScreen ? 22 : 26,
      ),
    );
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning_outlined, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text('Por favor completa todos los campos requeridos'),
              ),
            ],
          ),
          backgroundColor: Colors.orange[700],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final profile = SocialProfile(
        name: _nameController.text,
        lastName: _lastNameController.text,
        age: int.parse(_ageController.text),
        gender: _selectedGender!,
        phone: _phoneController.text,
        address: _addressController.text,
        city: _cityController.text,
        prayerRequest: _prayerRequestController.text,
        socialNetwork: _selectedSocialNetwork,
        createdAt: DateTime.now(),
      );

      await FirebaseFirestore.instance
          .collection('social_profiles')
          .add(profile.toMap());

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text('¡Perfil guardado exitosamente!')),
            ],
          ),
          backgroundColor: primaryTeal,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );

      // Limpiar formulario
      _formKey.currentState!.reset();
      _nameController.clear();
      _lastNameController.clear();
      _ageController.clear();
      _phoneController.clear();
      _addressController.clear();
      _cityController.clear();
      _prayerRequestController.clear();

      setState(() {
        _selectedGender = null;
        _selectedSocialNetwork = 'Facebook';
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text('Error al guardar el perfil: $e')),
            ],
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}

class _AnimatedFloatingLogo extends StatefulWidget {
  final bool isSmallScreen;

  const _AnimatedFloatingLogo({required this.isSmallScreen});

  @override
  State<_AnimatedFloatingLogo> createState() => _AnimatedFloatingLogoState();
}

class _AnimatedFloatingLogoState extends State<_AnimatedFloatingLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: -8.0, end: 8.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _animation.value),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 20,
                  spreadRadius: 1,
                  offset: Offset(0, 5 + _animation.value / 2),
                ),
                BoxShadow(
                  color:
                      _SocialProfileScreenState.primaryTeal.withOpacity(0.15),
                  blurRadius: 30,
                  spreadRadius: -5,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(
                  color: Colors.white.withOpacity(0.5),
                  width: 3,
                ),
              ),
              padding: const EdgeInsets.all(8),
              child: ClipOval(
                child: Image.asset(
                  'assets/Cocep_.png',
                  height: widget.isSmallScreen ? 60 : 70,
                  width: widget.isSmallScreen ? 60 : 70,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class TrianglePainter extends CustomPainter {
  final Color color;

  TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
