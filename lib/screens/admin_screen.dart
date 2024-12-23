import 'package:flutter/material.dart';
import 'package:formulario_app/models/registro.dart';
import 'package:formulario_app/services/firestore_service.dart';
import 'package:formulario_app/services/excel_service.dart';
import 'package:intl/intl.dart';

class AdminPanel extends StatefulWidget {
  const AdminPanel({super.key});

  @override
  _AdminPanelState createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> with SingleTickerProviderStateMixin {
  final TextEditingController _nuevoConsolidadorController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  final ExcelService _excelService = ExcelService();
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Colores personalizados basados en el logo
  final Color primaryTeal = const Color(0xFF1C8C8C);
  final Color secondaryOrange = const Color(0xFFFF6B35);

  Map<DateTime, List<Registro>> _registrosPorFecha = {};
Map<int, Map<int, Map<DateTime, List<Registro>>>> _registrosPorAnioMesDia = {};

Map<int, Map<int, Map<DateTime, List<Registro>>>> _registrosFiltrados = {};
bool _mostrarFiltrados = false;


  List<Map<String, String>> _consolidadores = [];

  @override
  void initState() {
    super.initState();
    _loadData();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
    _animationController.forward();
  }

  @override
  void dispose() {
    _nuevoConsolidadorController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      _inicializarStreams();
    } catch (e) {
      _mostrarError('Error cargando datos: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _inicializarStreams() {
  _firestoreService.streamRegistros().listen(
    (registros) {
      if (mounted) {
        setState(() {
          _registrosPorAnioMesDia = _agruparRegistrosPorFecha(registros);
        });
      }
    },
    onError: (error) => _mostrarError('Error cargando registros: $error'),
  );

    _firestoreService.streamConsolidadores().listen(
      (consolidadores) {
        if (mounted) {
          setState(() {
            _consolidadores = consolidadores;
          });
        }
      },
      onError: (error) => _mostrarError('Error cargando consolidadores: $error'),
    );
  }

  void _mostrarError(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

Map<int, Map<int, Map<DateTime, List<Registro>>>> _agruparRegistrosPorFecha(List<Registro> registros) {
  Map<int, Map<int, Map<DateTime, List<Registro>>>> agrupados = {};
  
  for (var registro in registros) {
    final anio = registro.fecha.year;
    final mes = registro.fecha.month;
    final fechaSinHora = DateTime(anio, mes, registro.fecha.day);
    
    agrupados[anio] ??= {};
    agrupados[anio]![mes] ??= {};
    agrupados[anio]![mes]![fechaSinHora] ??= [];
    agrupados[anio]![mes]![fechaSinHora]!.add(registro);
  }
  
  return agrupados;
}

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryTeal,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: primaryTeal,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

 Future<void> _exportarRegistros({bool todos = false}) async {
  setState(() => _isLoading = true);
  try {
    List<Registro> registrosParaExportar = [];
    String prefix;

    if (todos) {
      // Obtener todos los registros
      registrosParaExportar = _registrosPorAnioMesDia.values
          .expand((meses) => meses.values)
          .expand((dias) => dias.values)
          .expand((registros) => registros)
          .toList();
      prefix = 'todos_los_registros';
    } else if (_startDate != null && _endDate != null) {
      // Obtener registros por rango de fechas
      final fechaInicio = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
      final fechaFin = DateTime(_endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59);
      
      registrosParaExportar = _registrosPorAnioMesDia.values
          .expand((meses) => meses.values)
          .expand((dias) => dias.values)
          .expand((registros) => registros)
          .where((registro) {
            final fechaRegistro = DateTime(
              registro.fecha.year, 
              registro.fecha.month, 
              registro.fecha.day,
              registro.fecha.hour,
              registro.fecha.minute,
              registro.fecha.second
            );
            return fechaRegistro.isAfter(fechaInicio.subtract(const Duration(seconds: 1))) &&
                   fechaRegistro.isBefore(fechaFin.add(const Duration(seconds: 1)));
          })
          .toList();
      prefix = 'registros_${DateFormat('dd_MM_yyyy').format(_startDate!)}_a_${DateFormat('dd_MM_yyyy').format(_endDate!)}';
    } else {
      throw Exception('Selecciona un rango de fechas');
    }

    if (registrosParaExportar.isEmpty) {
      throw Exception('No hay registros para el rango de fechas seleccionado');
    }

    final filePath = await _excelService.exportarRegistros(
      registrosParaExportar,
      prefix: prefix,
    );

    if (!mounted) return;
    _mostrarExito('Archivo exportado: $filePath');
  } catch (e) {
    _mostrarError('Error al exportar: $e');
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}

  void _mostrarExito(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(mensaje)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          elevation: 0,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [primaryTeal, primaryTeal.withOpacity(0.8)],
              ),
            ),
          ),
          title: const Text(
            'Panel de Administración',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 24,
            ),
          ),
          bottom: TabBar(
            indicatorColor: secondaryOrange,
            indicatorWeight: 4,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            tabs: [
              Tab(
                icon: Icon(Icons.assignment, color: secondaryOrange),
                text: 'Registros',
              ),
              Tab(
                icon: Icon(Icons.people, color: secondaryOrange),
                text: 'Consolidadores',
              ),
            ],
          ),
        ),
        body: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    primaryTeal.withOpacity(0.1),
                    Colors.white,
                  ],
                ),
              ),
              child: TabBarView(
                children: [
                  _buildRegistrosTab(),
                  _buildConsolidadoresTab(),
                ],
              ),
            ),
            if (_isLoading)
              Container(
                color: Colors.black54,
                child: Center(
                  child: CircularProgressIndicator(
                    color: secondaryOrange,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegistrosTab() {
    return SingleChildScrollView(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            _buildExportCard(),
            _buildRegistrosList(),
          ],
        ),
      ),
    );
  }

  Widget _buildExportCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, primaryTeal.withOpacity(0.1)],
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.file_download, size: 28, color: secondaryOrange),
                const SizedBox(width: 12),
                Text(
                  'Exportar Registros',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: primaryTeal,
                  ),
                ),
              ],
            ),
            const Divider(height: 30),
            _buildDateRangeSelector(),
            const SizedBox(height: 20),
            _buildExportButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRangeSelector() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: primaryTeal.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _startDate != null && _endDate != null
                  ? 'Del ${DateFormat('dd/MM/yyyy').format(_startDate!)} al ${DateFormat('dd/MM/yyyy').format(_endDate!)}'
                  : 'Selecciona un rango de fechas',
              style: TextStyle(
                color: Colors.grey[800],
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () => _selectDateRange(context),
            icon: const Icon(Icons.date_range),
            label: const Text('Seleccionar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryTeal,
              padding: const EdgeInsets.symmetric(
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

  Widget _buildExportButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: (_startDate != null && _endDate != null)
                ? () => _exportarRegistros()
                : null,
            icon: const Icon(Icons.date_range),
            label: const Text('Por Fechas'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryTeal,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _exportarRegistros(todos: true),
            icon: const Icon(Icons.cloud_download),
            label: const Text('Todo'),
            style: ElevatedButton.styleFrom(
              backgroundColor: secondaryOrange,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }

Widget _buildRegistrosList() {
  return Card(
    margin: const EdgeInsets.all(16),
    elevation: 8,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    ),
    child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, primaryTeal.withOpacity(0.05)],
        ),
      ),
      child: Column(
        children: [
          _buildBuscadorFechas(),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(8),
            itemCount: (_mostrarFiltrados ? _registrosFiltrados : _registrosPorAnioMesDia).length,
            itemBuilder: (context, indexAnio) {
              final datos = _mostrarFiltrados ? _registrosFiltrados : _registrosPorAnioMesDia;
              final anio = datos.keys.toList()[indexAnio];
              return _buildAnioGroup(anio, datos[anio]!);
            },
          ),
        ],
      ),
    ),
  );
}

Widget _buildBuscadorFechas() {
  return Padding(
    padding: const EdgeInsets.all(16.0),
    child: Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.search),
            label: Text(_startDate != null && _endDate != null
                ? '${DateFormat('dd/MM/yyyy').format(_startDate!)} - ${DateFormat('dd/MM/yyyy').format(_endDate!)}'
                : 'Buscar por fechas'),
            onPressed: () => _selectDateRange(context).then((value) {
              if (_startDate != null && _endDate != null) {
                _filtrarRegistros();
              }
            }),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryTeal,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        if (_mostrarFiltrados)
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: _limpiarFiltro,
            color: secondaryOrange,
          ),
      ],
    ),
  );
}

void _filtrarRegistros() {
  if (_startDate == null || _endDate == null) return;

  final registrosFiltrados = Map<int, Map<int, Map<DateTime, List<Registro>>>>.from({});

  _registrosPorAnioMesDia.forEach((anio, meses) {
    meses.forEach((mes, dias) {
      dias.forEach((dia, registros) {
        if (dia.isAfter(_startDate!.subtract(const Duration(days: 1))) &&
            dia.isBefore(_endDate!.add(const Duration(days: 1)))) {
          
          registrosFiltrados[anio] ??= {};
          registrosFiltrados[anio]![mes] ??= {};
          registrosFiltrados[anio]![mes]![dia] = registros;
        }
      });
    });
  });

  setState(() {
    _registrosFiltrados = registrosFiltrados;
    _mostrarFiltrados = true;
  });
}

void _limpiarFiltro() {
  setState(() {
    _mostrarFiltrados = false;
    _startDate = null;
    _endDate = null;
  });
}
Widget _buildAnioGroup(int anio, Map<int, Map<DateTime, List<Registro>>> registrosPorMes) {
  return ExpansionTile(
    leading: CircleAvatar(
      backgroundColor: primaryTeal,
      child: Text(
        anio.toString(),
        style: const TextStyle(color: Colors.white),
      ),
    ),
    title: Text(
      'Año $anio',
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 20,
      ),
    ),
    children: registrosPorMes.entries
        .map((mes) => _buildMesGroup(mes.key, mes.value))
        .toList(),
  );
}

Widget _buildMesGroup(int mes, Map<DateTime, List<Registro>> registrosPorDia) {
  final nombreMes = _getNombreMes(mes);
  int totalRegistros = registrosPorDia.values
      .expand((registros) => registros)
      .length;

  return ExpansionTile(
    leading: CircleAvatar(
      backgroundColor: secondaryOrange,
      child: Text(
        mes.toString(),
        style: const TextStyle(color: Colors.white),
      ),
    ),
    title: Text(
      nombreMes,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 18,
      ),
    ),
    subtitle: Text(
      '$totalRegistros registros',
      style: TextStyle(
        color: secondaryOrange,
        fontWeight: FontWeight.w500,
      ),
    ),
    children: registrosPorDia.entries
        .map((entrada) => _buildFechaGroup(entrada.key, entrada.value))
        .toList(),
  );
}

String _getNombreMes(int mes) {
  const meses = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
  ];
  return meses[mes - 1];
}

  Widget _buildFechaGroup(DateTime fecha, List<Registro> registros) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: primaryTeal,
          child: const Icon(Icons.calendar_today, color: Colors.white),
        ),
        title: Text(
          DateFormat('dd/MM/yyyy').format(fecha),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        subtitle: Text(
          '${registros.length} registros',
          style: TextStyle(
            color: secondaryOrange,
            fontWeight: FontWeight.w500,
          ),
        ),
children: registros
            .map((registro) => _buildRegistroTile(registro))
            .toList(),
      ),
    );
  }

  Widget _buildRegistroTile(Registro registro) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, primaryTeal.withOpacity(0.05)],
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: secondaryOrange.withOpacity(0.2),
                  child: Text(
                    registro.nombre[0].toUpperCase(),
                    style: TextStyle(
                      color: secondaryOrange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${registro.nombre} ${registro.apellido}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: primaryTeal,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        registro.servicio,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Icon(Icons.phone, size: 20, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  registro.telefono,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => _editarRegistro(context, registro),
                  icon: const Icon(Icons.edit, size: 20),
                  label: const Text('Editar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryTeal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
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

  Widget _buildConsolidadoresTab() {
    return SingleChildScrollView(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            _buildAgregarConsolidadorCard(),
            _buildConsolidadoresList(),
          ],
        ),
      ),
    );
  }

  Widget _buildAgregarConsolidadorCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, primaryTeal.withOpacity(0.1)],
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person_add, size: 28, color: secondaryOrange),
                const SizedBox(width: 12),
                Text(
                  'Agregar Consolidador',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: primaryTeal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nuevoConsolidadorController,
                    decoration: InputDecoration(
                      labelText: 'Nombre del Consolidador',
                      labelStyle: TextStyle(color: primaryTeal),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: primaryTeal, width: 2),
                      ),
                      prefixIcon: Icon(Icons.person, color: primaryTeal),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () async {
                    if (_nuevoConsolidadorController.text.isNotEmpty) {
                      await _firestoreService.agregarConsolidador(
                        _nuevoConsolidadorController.text,
                      );
                      _nuevoConsolidadorController.clear();
                      _mostrarExito('Consolidador agregado exitosamente');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: secondaryOrange,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Agregar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConsolidadoresList() {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, primaryTeal.withOpacity(0.05)],
          ),
        ),
        child: ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemCount: _consolidadores.length,
          itemBuilder: (context, index) {
            return _buildConsolidadorTile(_consolidadores[index]);
          },
        ),
      ),
    );
  }

  Widget _buildConsolidadorTile(Map<String, String> consolidador) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: secondaryOrange.withOpacity(0.2),
          child: Text(
            (consolidador['nombre'] ?? '')[0].toUpperCase(),
            style: TextStyle(
              color: secondaryOrange,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          consolidador['nombre'] ?? 'Sin nombre',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: primaryTeal,
            fontSize: 16,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit, color: primaryTeal),
              onPressed: () => _editarConsolidador(context, consolidador),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _confirmarEliminarConsolidador(consolidador),
            ),
          ],
        ),
      ),
    );
  }

 Future<void> _confirmarEliminarConsolidador(Map<String, String> consolidador) async {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Row(
        children: [
          Icon(Icons.warning, color: secondaryOrange),
          const SizedBox(width: 5),
          const Text('Confirmar Eliminación'),
        ],
      ),
      content: Container(
        constraints: BoxConstraints(maxWidth: 300),  // Ajusta el ancho del contenido
        child: Text('¿Estás seguro de eliminar a ${consolidador['nombre']}?'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancelar',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(context);
            try {
              await _firestoreService.eliminarConsolidador(consolidador['id']!);
              _mostrarExito('Consolidador eliminado exitosamente');
            } catch (e) {
              _mostrarError('Error al eliminar: $e');
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text('Eliminar'),
        ),
      ],
    ),
  );
}


  void _editarRegistro(BuildContext context, Registro registro) {
    final nombreController = TextEditingController(text: registro.nombre);
    final apellidoController = TextEditingController(text: registro.apellido);
    final telefonoController = TextEditingController(text: registro.telefono);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.edit, color: primaryTeal),
              const SizedBox(width: 8),
              const Text(
                'Editar Registro',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildEditTextField(
                  controller: nombreController,
                  label: 'Nombre',
                  icon: Icons.person,
                ),
                const SizedBox(height: 16),
                _buildEditTextField(
                  controller: apellidoController,
                  label: 'Apellido',
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 16),
                _buildEditTextField(
                  controller: telefonoController,
                  label: 'Teléfono',
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancelar',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () => _guardarEdicionRegistro(
                context,
                registro,
                nombreController.text,
                apellidoController.text,
                telefonoController.text,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryTeal,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEditTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: primaryTeal),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: primaryTeal, width: 2),
        ),
        prefixIcon: Icon(icon, color: primaryTeal),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }

  Future<void> _guardarEdicionRegistro(
    BuildContext context,
    Registro registro,
    String nombre,
    String apellido,
    String telefono,
  ) async {
    try {
      registro.nombre = nombre;
      registro.apellido = apellido;
      registro.telefono = telefono;

      await _firestoreService.actualizarRegistro(registro.id!, registro);
      Navigator.pop(context);
      _mostrarExito('Registro actualizado exitosamente');
    } catch (e) {
      _mostrarError('Error al actualizar: $e');
    }
  }

  void _editarConsolidador(BuildContext context, Map<String, String> consolidador) {
    final controlador = TextEditingController(text: consolidador['nombre']);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.edit, color: primaryTeal),
              const SizedBox(width: 8),
              const Text(
                'Editar Consolidador',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: TextField(
            controller: controlador,
            decoration: InputDecoration(
              labelText: 'Nombre del Consolidador',
              labelStyle: TextStyle(color: primaryTeal),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: primaryTeal, width: 2),
              ),
              prefixIcon: Icon(Icons.person, color: primaryTeal),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancelar',
                style: TextStyle(color: Colors.grey[600]),
),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _firestoreService.actualizarConsolidador(
                    consolidador['id']!,
                    controlador.text,
                  );
                  Navigator.pop(context);
                  _mostrarExito('Consolidador actualizado exitosamente');
                } catch (e) {
                  _mostrarError('Error al actualizar: $e');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryTeal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 3,
              ),
              child: const Text(
                'Guardar',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Método auxiliar para mostrar el mensaje de éxito con animación
  void _mostrarExitoAnimado(String mensaje) {
    showGeneralDialog(
      context: context,
      pageBuilder: (context, animation1, animation2) => Container(),
      transitionBuilder: (context, animation1, animation2, child) {
        return ScaleTransition(
          scale: Tween<double>(begin: 0.5, end: 1.0).animate(animation1),
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: Colors.green.shade50,
            title: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 30),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    mensaje,
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            content: const SizedBox(height: 20),
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black54,
    );

    Future.delayed(const Duration(seconds: 1), () {
      Navigator.of(context).pop();
    });
  }

  // Método auxiliar para efectos de hover en botones
 Widget _buildAnimatedButton({
  required VoidCallback onPressed,
  required Widget child,
  required Color baseColor,
}) {
  return StatefulBuilder(
    builder: (context, setState) {
      bool isHovered = false;

      return MouseRegion(
        onEnter: (_) => setState(() => isHovered = true),
        onExit: (_) => setState(() => isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: isHovered
              ? (Matrix4.identity()..scale(1.05))
              : Matrix4.identity(),
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: isHovered
                  ? baseColor.withOpacity(0.9)
                  : baseColor,
              elevation: isHovered ? 8 : 4,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: child,
          ),
        ),
      );
    },
  );
}


  // Widget para tarjetas con efecto de elevación al hover
  Widget _buildHoverCard({
    required Widget child,
    double initialElevation = 4,
    double hoverElevation = 8,
  }) {
    return StatefulBuilder(
      builder: (context, setState) {
        bool isHovered = false;
        
        return MouseRegion(
          onEnter: (_) => setState(() => isHovered = true),
          onExit: (_) => setState(() => isHovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: isHovered ? hoverElevation : initialElevation,
                  spreadRadius: isHovered ? 2 : 1,
                ),
              ],
            ),
            child: child,
          ),
        );
      },
    );
  }
}