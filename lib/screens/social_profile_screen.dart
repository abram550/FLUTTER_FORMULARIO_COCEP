// Flutter
import 'package:flutter/material.dart';

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

class _SocialProfileScreenState extends State<SocialProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _prayerRequestController =
      TextEditingController();

  String? _selectedGender; // Cambiado a nullable
  String _selectedSocialNetwork = 'Facebook';

  // Colors from your logo
  static const Color primaryTeal = Color(0xFF2A8B8B);
  static const Color primaryOrange = Color(0xFFFF5733);

  @override
  void dispose() {
    _nameController.dispose();
    _lastNameController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _prayerRequestController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Datos Personales',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Redes Sociales',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: [
                          primaryTeal,
                          primaryTeal.withOpacity(0.8),
                          primaryOrange.withOpacity(0.6),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    right: 30,
                    top: 50,
                    child: Row(
                      children: [
                        Icon(
                          FontAwesomeIcons.facebook,
                          color: Colors.white.withOpacity(0.7),
                          size: 40,
                        ),
                        SizedBox(width: 20),
                        Icon(
                          FontAwesomeIcons.youtube,
                          color: Colors.white.withOpacity(0.7),
                          size: 40,
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(30),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
              ),
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildAnimatedTextField(
                          _nameController, 'Nombre', Icons.person),
                      _buildAnimatedTextField(_lastNameController, 'Apellido',
                          Icons.person_outline),
                      _buildAnimatedTextField(
                          _ageController, 'Edad', Icons.cake,
                          keyboardType: TextInputType.number),
                      _buildGenderSelector(),
                      _buildAnimatedTextField(
                          _phoneController, 'Teléfono', Icons.phone,
                          keyboardType: TextInputType.phone),
                      _buildAnimatedTextField(
                          _addressController, 'Dirección', Icons.home),
                      _buildAnimatedTextField(
                          _cityController, 'Ciudad', Icons.location_city),
                      _buildAnimatedTextField(_prayerRequestController,
                          '¿Por qué quieres que oremos?', Icons.comment,
                          maxLines: 3),
                      _buildEnhancedSocialNetworkSelector(),
                      SizedBox(height: 24),
                      _buildSubmitButton(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedTextField(
      TextEditingController controller, String label, IconData icon,
      {TextInputType? keyboardType, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: primaryTeal.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(color: primaryTeal.withOpacity(0.8)),
            prefixIcon: Icon(icon, color: primaryTeal),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: primaryTeal.withOpacity(0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: primaryTeal.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: primaryTeal, width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor completa este campo';
            }
            if (label == 'Edad') {
              final age = int.tryParse(value);
              if (age == null) {
                return 'Por favor ingresa un número válido';
              }
              if (age < 0 || age > 120) {
                return 'Por favor ingresa una edad válida';
              }
            }
            return null;
          },
        ),
      ),
    );
  }

  Widget _buildGenderSelector() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: primaryTeal.withOpacity(0.3)),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: primaryTeal.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedGender,
              hint: Text('Seleccione su género',
                  style: TextStyle(color: primaryTeal.withOpacity(0.8))),
              isExpanded: true,
              icon: Icon(Icons.arrow_drop_down, color: primaryTeal),
              items: ['Hombre', 'Mujer'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    value,
                    style: TextStyle(color: primaryTeal.withOpacity(0.8)),
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedGender = newValue!;
                });
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedSocialNetworkSelector() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '¿Por cuál red te conectaste?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primaryTeal,
            ),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildEnhancedSocialNetworkOption(
                  'Facebook', FontAwesomeIcons.facebook),
              _buildEnhancedSocialNetworkOption(
                  'YouTube', FontAwesomeIcons.youtube),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedSocialNetworkOption(String network, IconData icon) {
    final isSelected = _selectedSocialNetwork == network;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedSocialNetwork = network;
        });
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? primaryTeal : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? primaryTeal.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.2),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            FaIcon(
              icon,
              size: 32,
              color: isSelected ? Colors.white : primaryTeal,
            ),
            SizedBox(height: 12),
            Text(
              network,
              style: TextStyle(
                color: isSelected ? Colors.white : primaryTeal,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      height: 55,
      child: ElevatedButton(
        onPressed: _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryOrange,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.send, color: Colors.white),
            SizedBox(width: 12),
            Text(
              'Enviar',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        final profile = SocialProfile(
          name: _nameController.text,
          lastName: _lastNameController.text,
          age: int.parse(_ageController.text),
          gender: _selectedGender ?? 'No especificado', // Manejo de null
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

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('¡Perfil guardado exitosamente!'),
            backgroundColor: primaryTeal,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
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
          _selectedGender = null; // Mantener sin seleccionar
          _selectedSocialNetwork = 'Facebook';
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar el perfil: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }
}
