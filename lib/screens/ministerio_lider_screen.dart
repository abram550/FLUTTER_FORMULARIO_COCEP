import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MinisterioLiderScreen extends StatefulWidget {
  final String ministerio; // 'Ministerio de Damas' o 'Ministerio de Caballeros'
  const MinisterioLiderScreen({Key? key, required this.ministerio})
      : super(key: key);

  @override
  _MinisterioLiderScreenState createState() => _MinisterioLiderScreenState();
}

class _MinisterioLiderScreenState extends State<MinisterioLiderScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // COCEP colors based on the logo
  final Color primaryColor = const Color(0xFF1E8A9C); // Teal/turquoise
  final Color secondaryColor = const Color(0xFFFF5722); // Orange/red
  final Color accentColor = const Color(0xFFFFB74D); // Light orange
  final Color grayColor = const Color(0xFF9E9E9E); // Gray
  final Color backgroundColor = const Color(0xFFF5F5F5); // Light background

  @override
  void initState() {
    super.initState();
    // Dos pestañas: Tribus y Personas asignadas
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Pestaña 1: Mostrar tribus del ministerio sin botón de eliminar
  Widget _buildTribusTab() {
    return Container(
      color: backgroundColor,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('tribus')
            .where('categoria', isEqualTo: widget.ministerio)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(secondaryColor),
              ),
            );

          final tribus = snapshot.data!.docs;
          if (tribus.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.group_off,
                    size: 80,
                    color: grayColor.withOpacity(0.6),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No hay tribus registradas en este ministerio.',
                    style: TextStyle(
                      fontSize: 16,
                      color: grayColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(12.0),
            child: ListView.builder(
              itemCount: tribus.length,
              itemBuilder: (context, index) {
                final data = tribus[index].data() as Map<String, dynamic>;
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 3,
                  shadowColor: primaryColor.withOpacity(0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: primaryColor.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: [
                          Colors.white,
                          primaryColor.withOpacity(0.1),
                        ],
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16),
                      leading: CircleAvatar(
                        backgroundColor: primaryColor,
                        child: Icon(
                          Icons.groups,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(
                        data['nombre'] ?? 'Sin nombre',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: primaryColor,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Row(
                          children: [
                            Icon(
                              Icons.person,
                              size: 16,
                              color: secondaryColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Líder: ${data['nombreLider'] ?? 'No asignado'}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
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
    );
  }

  /// Pestaña 2: Mostrar personas asignadas para el ministerio actual
/// Pestaña 2: Mostrar personas asignadas para el ministerio actual con grupos y búsqueda
Widget _buildPersonasAsignadasTab() {
  // Controller para el campo de búsqueda
  final TextEditingController searchController = TextEditingController();
  // Variable para el estado de búsqueda
  final ValueNotifier<String> searchQuery = ValueNotifier<String>('');
  // Variables para controlar la expansión de los grupos
  final ValueNotifier<bool> assignedExpanded = ValueNotifier<bool>(true);
  final ValueNotifier<bool> unassignedExpanded = ValueNotifier<bool>(true);

  return Container(
    color: backgroundColor,
    child: Column(
      children: [
        // Campo de búsqueda
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.1),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o apellido...',
                prefixIcon: Icon(Icons.search, color: primaryColor),
                suffixIcon: ValueListenableBuilder<String>(
                  valueListenable: searchQuery,
                  builder: (context, query, _) {
                    return query.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.close, color: secondaryColor),
                            onPressed: () {
                              searchController.clear();
                              searchQuery.value = '';
                              FocusScope.of(context).unfocus();
                            },
                          )
                        : SizedBox.shrink();
                  },
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              onChanged: (value) {
                searchQuery.value = value;
              },
            ),
          ),
        ),
        
        // Lista de registros agrupados
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('registros')
                .where('ministerioAsignado', isEqualTo: widget.ministerio)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(secondaryColor),
                  ),
                );
              }

              final registros = snapshot.data!.docs;

              if (registros.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.person_off,
                        size: 80,
                        color: grayColor.withOpacity(0.6),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No hay personas asignadas a este ministerio.',
                        style: TextStyle(
                          fontSize: 16,
                          color: grayColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }

              // Filtrar registros según la búsqueda
              return ValueListenableBuilder<String>(
                valueListenable: searchQuery,
                builder: (context, query, _) {
                  // Agrupar registros en asignados y no asignados
                  final registrosFiltrados = registros.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final nombre = data['nombre']?.toString().toLowerCase() ?? '';
                    final apellido = data['apellido']?.toString().toLowerCase() ?? '';
                    final nombreCompleto = '$nombre $apellido';
                    
                    return query.isEmpty ||
                        nombre.contains(query.toLowerCase()) ||
                        apellido.contains(query.toLowerCase()) ||
                        nombreCompleto.contains(query.toLowerCase());
                  }).toList();

                  final registrosAsignados = registrosFiltrados
                      .where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return data['nombreTribu'] != null;
                      })
                      .toList();

                  final registrosNoAsignados = registrosFiltrados
                      .where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return data['nombreTribu'] == null;
                      })
                      .toList();

                  // Si hay búsqueda activa, expandir automáticamente
                  if (query.isNotEmpty) {
                    assignedExpanded.value = registrosAsignados.isNotEmpty;
                    unassignedExpanded.value = registrosNoAsignados.isNotEmpty;
                  }

                  return ListView(
                    padding: const EdgeInsets.all(12.0),
                    children: [
                      // Grupo de registros asignados
                      if (registrosAsignados.isNotEmpty)
                        _buildGroupHeader(
                          title: 'Con tribu asignada',
                          count: registrosAsignados.length,
                          icon: Icons.check_circle_outline,
                          color: secondaryColor,
                          expandedNotifier: assignedExpanded,
                        ),
                      
                      // Lista de registros asignados
                      ValueListenableBuilder<bool>(
                        valueListenable: assignedExpanded,
                        builder: (context, expanded, _) {
                          return expanded && registrosAsignados.isNotEmpty
                              ? Column(
                                  children: registrosAsignados.map((doc) {
                                    final data = doc.data() as Map<String, dynamic>;
                                    return _buildPersonaCard(doc.id, data, true);
                                  }).toList(),
                                )
                              : SizedBox.shrink();
                        },
                      ),

                      const SizedBox(height: 16),

                      // Grupo de registros no asignados
                      if (registrosNoAsignados.isNotEmpty)
                        _buildGroupHeader(
                          title: 'Sin tribu asignada',
                          count: registrosNoAsignados.length,
                          icon: Icons.person_outline,
                          color: accentColor,
                          expandedNotifier: unassignedExpanded,
                        ),
                      
                      // Lista de registros no asignados
                      ValueListenableBuilder<bool>(
                        valueListenable: unassignedExpanded,
                        builder: (context, expanded, _) {
                          return expanded && registrosNoAsignados.isNotEmpty
                              ? Column(
                                  children: registrosNoAsignados.map((doc) {
                                    final data = doc.data() as Map<String, dynamic>;
                                    return _buildPersonaCard(doc.id, data, false);
                                  }).toList(),
                                )
                              : SizedBox.shrink();
                        },
                      ),

                      // Mensaje si no hay resultados en la búsqueda
                      if (query.isNotEmpty && registrosFiltrados.isEmpty)
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(height: 32),
                              Icon(
                                Icons.search_off,
                                size: 64,
                                color: grayColor.withOpacity(0.6),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No se encontraron resultados para "$query"',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: grayColor,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                    ],
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
/// Construye un encabezado para grupo de registros con contador y botón expandible
Widget _buildGroupHeader({
  required String title,
  required int count,
  required IconData icon,
  required Color color,
  required ValueNotifier<bool> expandedNotifier,
}) {
  return ValueListenableBuilder<bool>(
    valueListenable: expandedNotifier,
    builder: (context, expanded, _) {
      return GestureDetector(
        onTap: () => expandedNotifier.value = !expanded,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                color.withOpacity(0.1),
                color.withOpacity(0.2),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$count ${count == 1 ? 'persona' : 'personas'}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: color,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}


/// Construye una tarjeta para mostrar la información de una persona
Widget _buildPersonaCard(String docId, Map<String, dynamic> data, bool tieneTribuAsignada) {
  final String nombre = data['nombre'] ?? '';
  final String apellido = data['apellido'] ?? '';
  final String nombreTribu = data['nombreTribu'] ?? 'Sin tribu asignada';

  return Card(
    margin: const EdgeInsets.only(bottom: 12, left: 8, right: 2),
    elevation: 2,
    shadowColor: primaryColor.withOpacity(0.3),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            Colors.white,
            tieneTribuAsignada
                ? accentColor.withOpacity(0.1)
                : grayColor.withOpacity(0.1),
          ],
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        leading: CircleAvatar(
          backgroundColor: tieneTribuAsignada ? secondaryColor : grayColor,
          child: Text(
            nombre.isNotEmpty ? nombre[0] : '?',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          '$nombre $apellido',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Row(
            children: [
              Icon(
                tieneTribuAsignada ? Icons.group : Icons.group_off,
                size: 16,
                color: tieneTribuAsignada ? secondaryColor : grayColor,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Tribu: $nombreTribu',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: Icon(Icons.visibility_outlined, color: primaryColor),
                tooltip: 'Ver detalles',
                onPressed: () => _mostrarDetallesRegistroActualizado(data),
              ),
            ),
            const SizedBox(width: 8),
            // Condicionalmente mostrar botón de asignar o cambiar tribu
            if (data['nombreTribu'] == null)
              Container(
                decoration: BoxDecoration(
                  color: secondaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: Icon(Icons.group_add, color: secondaryColor),
                  tooltip: 'Asignar tribu',
                  onPressed: () => _mostrarDialogoAsignarTribu(docId, data),
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: Icon(Icons.swap_horiz, color: accentColor),
                  tooltip: 'Cambiar tribu',
                  onPressed: () => _mostrarDialogoCambiarTribu(docId, data),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

  void _mostrarDetallesRegistroActualizado(Map<String, dynamic> data) {
    // Función para formatear fechas
    String formatearFecha(dynamic fecha) {
      if (fecha == null) return 'Fecha no disponible';
      if (fecha is Timestamp) {
        final date = fecha.toDate();
        return '${date.day}/${date.month}/${date.year}';
      }
      return fecha.toString();
    }

    // Función para formatear valores según el tipo de campo
    String formatearValor(String key, dynamic valor) {
      if (valor == null) return 'No disponible';

      // Formateo para campos booleanos
      if (valor is bool) {
        if (key == 'tieneHijos') {
          return valor ? 'Sí' : 'No';
        }
        return valor ? 'Sí' : 'No';
      }

      // Formateo para campos específicos
      switch (key) {
        case 'sexo':
          if (valor.toString().toLowerCase() == 'm') return 'Masculino';
          if (valor.toString().toLowerCase() == 'f') return 'Femenino';
          return valor.toString();
        case 'estadoCivil':
          final estados = {
            'soltero': 'Soltero/a',
            'casado': 'Casado/a',
            'divorciado': 'Divorciado/a',
            'viudo': 'Viudo/a',
            'comprometido': 'Comprometido/a',
            'unionlibre': 'Unión libre'
          };
          return estados[valor.toString().toLowerCase()] ?? valor.toString();
        case 'edad':
          return '$valor años';
        case 'telefono':
          // Formatear teléfono si es un número
          if (valor is num ||
              (valor is String && int.tryParse(valor) != null)) {
            return valor.toString().replaceAllMapped(
                RegExp(r'(\d{3})(\d{3})(\d+)'),
                (Match m) => '${m[1]}-${m[2]}-${m[3]}');
          }
          return valor.toString();
        default:
          return valor.toString();
      }
    }

    // Definición de secciones con sus campos
    final secciones = [
      {
        'titulo': 'Información Personal',
        'icono': Icons.person_outline,
        'color': primaryColor,
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
        'titulo': 'Ubicación',
        'icono': Icons.location_on_outlined,
        'color': primaryColor,
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
        'color': secondaryColor,
        'campos': [
          {
            'key': 'ocupaciones',
            'label': 'Ocupaciones',
            'icon': Icons.work_outline
          },
          {
            'key': 'descripcionOcupacion',
            'label': 'Descripción',
            'icon': Icons.description_outlined
          },
        ]
      },
      {
        'titulo': 'Información Ministerial',
        'icono': Icons.groups_outlined,
        'color': accentColor,
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
        'color': secondaryColor,
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
        'color': accentColor,
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
    ];

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 5,
        backgroundColor: backgroundColor,
        child: Container(
          width: double.maxFinite,
          constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Título
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: primaryColor,
                    child: Text(
                      data['nombre'] != null && data['nombre'].isNotEmpty
                          ? data['nombre'][0]
                          : '?',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${data['nombre'] ?? 'Sin nombre'} ${data['apellido'] ?? ''}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: primaryColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Contenido con detalles organizados por secciones
              Divider(color: primaryColor.withOpacity(0.3)),
              Expanded(
                child: ListView(
                  children: secciones.map((seccion) {
                    // Filtrar campos que no son null
                    final camposConDatos =
                        (seccion['campos'] as List).where((campo) {
                      final key = campo['key'] as String;
                      final esFecha = campo['esFecha'] == true;

                      if (esFecha) {
                        return data[key] != null;
                      }

                      // Para booleanos, mostrar aunque sea false
                      if (data[key] is bool) {
                        return true;
                      }

                      return data[key] != null &&
                          data[key].toString().isNotEmpty;
                    }).toList();

                    // No mostrar secciones sin datos
                    if (camposConDatos.isEmpty) {
                      return Container();
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Encabezado de sección con ícono y título
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 10.0),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: (seccion['color'] as Color)
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  seccion['icono'] as IconData,
                                  color: seccion['color'] as Color,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                seccion['titulo'] as String,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: seccion['color'] as Color,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Campos de la sección
                        ...camposConDatos.map((campo) {
                          final key = campo['key'] as String;
                          final esFecha = campo['esFecha'] == true;
                          final valor = esFecha
                              ? formatearFecha(data[key])
                              : formatearValor(key, data[key]);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8, left: 8),
                            elevation: 0,
                            color: primaryColor.withOpacity(0.05),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                children: [
                                  Icon(campo['icon'] as IconData,
                                      color: secondaryColor, size: 20),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          campo['label'] as String,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: primaryColor,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          valor,
                                          style: TextStyle(
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),

                        Divider(color: primaryColor.withOpacity(0.1)),
                      ],
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              // Botón cerrar
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cerrar',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
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

  void _mostrarDialogoCambiarTribu(
      String registroId, Map<String, dynamic> datosPersona) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Column(
            children: [
              Icon(
                Icons.swap_horiz,
                color: accentColor,
                size: 36,
              ),
              const SizedBox(height: 12),
              Text(
                '¿Cambiar tribu asignada?',
                style: TextStyle(
                  color: primaryColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${datosPersona['nombre']} ${datosPersona['apellido']} está actualmente en la tribu:',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  datosPersona['nombreTribu'] ?? 'Sin tribu asignada',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '¿Estás seguro de que deseas cambiar la tribu asignada?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          actionsPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancelar',
                style: TextStyle(color: grayColor),
              ),
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                backgroundColor: grayColor.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                // Eliminar asignación previa
                await _cambiarAsignacionRegistro(registroId);

                // Cerrar el diálogo y abrir el de asignar tribu
                Navigator.pop(context);
                _mostrarDialogoAsignarTribu(registroId, datosPersona);
              },
              child: Text(
                'Continuar',
                style: TextStyle(color: Colors.white),
              ),
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                backgroundColor: secondaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _cambiarAsignacionRegistro(String registroId) async {
    try {
      await _firestore.collection('registros').doc(registroId).update({
        'nombreTribu': null,
        'tribuAsignada': null,
        'coordinadorAsignado': null,
        'timoteoAsignado': null,
        'nombreTimoteo': null,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Asignación eliminada correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cambiar la asignación: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Diálogo para asignar una tribu a una persona
  void _mostrarDialogoAsignarTribu(
      String registroId, Map<String, dynamic> datosPersona) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Column(
            children: [
              Icon(
                Icons.group_add,
                color: secondaryColor,
                size: 36,
              ),
              const SizedBox(height: 12),
              Text(
                'Asignar tribu a ${datosPersona['nombre']} ${datosPersona['apellido']}',
                style: TextStyle(
                  color: primaryColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('tribus')
                .where('categoria', isEqualTo: widget.ministerio)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(secondaryColor),
                  ),
                );
              }

              final tribus = snapshot.data!.docs;
              if (tribus.isEmpty) {
                return Container(
                  height: 120,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: accentColor,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No hay tribus disponibles para asignar',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: grayColor),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Container(
                width: double.maxFinite,
                height: 300,
                child: ListView.separated(
                  itemCount: tribus.length,
                  separatorBuilder: (context, index) => Divider(
                    color: primaryColor.withOpacity(0.2),
                  ),
                  itemBuilder: (context, index) {
                    final tribu = tribus[index].data() as Map<String, dynamic>;
                    final tribuId = tribus[index].id;

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 6, horizontal: 4),
                      leading: CircleAvatar(
                        backgroundColor: primaryColor,
                        child: Icon(
                          Icons.groups,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        tribu['nombre'] ?? '',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          'Líder: ${tribu['nombreLider'] ?? ''} ${tribu['apellidoLider'] ?? ''}',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _asignarTribu(
                            registroId, tribuId, tribu['nombre'] ?? '');
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      tileColor: index % 2 == 0
                          ? Colors.white
                          : primaryColor.withOpacity(0.05),
                    );
                  },
                ),
              );
            },
          ),
          actionsPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancelar',
                style: TextStyle(color: grayColor),
              ),
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                backgroundColor: grayColor.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Asigna una tribu a una persona en la base de datos
  Future<void> _asignarTribu(
      String registroId, String tribuId, String nombreTribu) async {
    try {
      await _firestore.collection('registros').doc(registroId).update({
        'tribuAsignada': tribuId,
        'nombreTribu': nombreTribu,
        'ministerioAsignado':
            widget.ministerio, // Guardamos el ministerio asignado
        'fechaAsignacion': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Text('Tribu asignada correctamente'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: EdgeInsets.all(12),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('Error al asignar tribu: $e')),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: EdgeInsets.all(12),
        ),
      );
    }
  }

  // Diálogo con todos los detalles de un registro
  void _mostrarDetallesRegistro(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Column(
            children: [
              CircleAvatar(
                backgroundColor: primaryColor,
                radius: 28,
                child: Text(
                  data['nombre'] != null && data['nombre'].isNotEmpty
                      ? data['nombre'][0]
                      : '?',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '${data['nombre'] ?? ''} ${data['apellido'] ?? ''}',
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Container(
            width: double.maxFinite,
            height: 400,
            child: SingleChildScrollView(
              child: Column(
                children: data.entries
                    .where((entry) => entry.value != null && entry.key != 'id')
                    .map((entry) {
                  var valor = entry.value;
                  if (valor is Timestamp) {
                    valor = valor.toDate().toString();
                  }
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    elevation: 0,
                    color: primaryColor.withOpacity(0.05),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            _getIconForField(entry.key),
                            size: 20,
                            color: secondaryColor,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${_formatFieldName(entry.key)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: primaryColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  valor.toString(),
                                  style: TextStyle(
                                    fontSize: 14,
                                  ),
                                ),
                              ],
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
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cerrar',
                style: TextStyle(color: Colors.white),
              ),
              style: TextButton.styleFrom(
                backgroundColor: primaryColor,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Determina el icono apropiado para cada campo
IconData _getIconForField(String fieldName) {
  if (fieldName.contains('nombre') || fieldName.contains('apellido')) {
    return Icons.person;
  } else if (fieldName.contains('tribu')) {
    return Icons.groups;
  } else if (fieldName.contains('ministerio')) {
    return Icons.business;
  } else if (fieldName.contains('fecha')) {
    return Icons.calendar_today;
  } else if (fieldName.contains('telefono') || fieldName.contains('celular')) {
    return Icons.phone;
  } else if (fieldName.contains('email') || fieldName.contains('correo')) {
    return Icons.email;
  } else if (fieldName.contains('direccion')) {
    return Icons.home;
  } else if (fieldName.contains('estadoFonovisita')) {
    return Icons.call_outlined;
  } else if (fieldName.contains('observaciones2')) {
    return Icons.note_add_outlined;
  } else {
    return Icons.info_outline;
  }
}
  // Convierte nombres de campos camelCase a formato legible
  String _formatFieldName(String fieldName) {
    final result = fieldName.replaceAllMapped(
      RegExp(r'([A-Z])'),
      (match) => ' ${match.group(0)}',
    );
    return result.substring(0, 1).toUpperCase() + result.substring(1);
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Text(value),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.ministerio,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
        backgroundColor: primaryColor,
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: secondaryColor,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: TextStyle(fontWeight: FontWeight.bold),
          tabs: [
            Tab(
              icon: Icon(Icons.groups),
              text: 'Tribus',
            ),
            Tab(
              icon: Icon(Icons.people),
              text: 'Personas Asignadas',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTribusTab(),
          _buildPersonasAsignadasTab(),
        ],
      ),
    );
  }
}
