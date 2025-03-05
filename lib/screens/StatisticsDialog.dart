import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class StatisticsDialog extends StatefulWidget {
  const StatisticsDialog({Key? key}) : super(key: key);

  @override
  _StatisticsDialogState createState() => _StatisticsDialogState();
}

class _StatisticsDialogState extends State<StatisticsDialog>
    with SingleTickerProviderStateMixin {
  // Colores basados en la imagen del logo
  final Color primaryColor = const Color(0xFF1D8B8E); // Verde-azulado
  final Color accentColor = const Color(0xFFF5A623); // Amarillo-naranja
  final Color flameColor = const Color(0xFFFF5722); // Rojo-naranja (llama)
  final Color backgroundColor =
      const Color(0xFFF5F7FA); // Gris claro para fondo
  final Color textColor = const Color(0xFF2C3E50); // Azul oscuro para texto

  String selectedGraph = "barras";
  String selectedFilter = "anual";
  int? selectedYear;
  String? selectedMonth;
  int? selectedWeek;
  String selectedMinistry = "Todos";
  String? selectedTribe;

  List<int> availableYears = [];
  List<String> months = [
    "Enero",
    "Febrero",
    "Marzo",
    "Abril",
    "Mayo",
    "Junio",
    "Julio",
    "Agosto",
    "Septiembre",
    "Octubre",
    "Noviembre",
    "Diciembre"
  ];
  List<String> weeks = [
    "Semana 1",
    "Semana 2",
    "Semana 3",
    "Semana 4",
    "Semana 5"
  ];

  Map<String, List<String>> ministerioTribus = {};
  bool isLoading = true;
  bool hasError = false;
  String errorMessage = "";

  late TabController _tabController;

  final List<Color> chartColors = [
    const Color(0xFF1D8B8E), // Verde-azulado
    const Color(0xFFF5A623), // Amarillo-naranja
    const Color(0xFFFF5722), // Rojo-naranja
    const Color(0xFF3498DB), // Azul claro
    const Color(0xFF9B59B6), // Púrpura
    const Color(0xFF2ECC71), // Verde
    const Color(0xFFE74C3C), // Rojo
  ];

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('es_ES');
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          switch (_tabController.index) {
            case 0:
              selectedGraph = "barras";
              break;
            case 1:
              selectedGraph = "lineal";
              break;
            case 2:
              selectedGraph = "circular";
              break;
          }
        });
      }
    });
    _loadAvailableData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Carga los datos disponibles desde Firestore
  Future<void> _loadAvailableData() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });

    try {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('registros').get();

      Set<int> years = {};
      Map<String, List<String>> ministerioTribusMap = {
        "Todos": [],
      };

      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        DateTime? date;

        if (data['fechaAsignacion'] != null) {
          date = (data['fechaAsignacion'] as Timestamp).toDate();
        } else if (data['fechaAsignacionTribu'] != null) {
          date = (data['fechaAsignacionTribu'] as Timestamp).toDate();
        }

        if (date != null) {
          years.add(date.year);
        }

        // Organizar tribus por ministerio
        final ministerio = data['ministerioAsignado'] as String?;
        final tribuNombre = data['nombreTribu'] as String?;
        final tribuId = data['tribuAsignada'] as String?;

        if (ministerio != null && tribuNombre != null && tribuId != null) {
          if (!ministerioTribusMap.containsKey(ministerio)) {
            ministerioTribusMap[ministerio] = [];
          }

          // Agregar solo si no existe ya
          String tribuDisplay = "$tribuNombre ($tribuId)";
          if (!ministerioTribusMap[ministerio]!.contains(tribuDisplay)) {
            ministerioTribusMap[ministerio]!.add(tribuDisplay);
          }

          // También agregar a "Todos"
          if (!ministerioTribusMap["Todos"]!.contains(tribuDisplay)) {
            ministerioTribusMap["Todos"]!.add(tribuDisplay);
          }
        }
      }

      setState(() {
        availableYears = years.toList()
          ..sort((a, b) => b.compareTo(a)); // Orden descendente
        ministerioTribus = ministerioTribusMap;

        // Valores predeterminados actualizados
        selectedYear = null; // Inicialmente, mostrar todos los años
        selectedMonth = null;
        selectedWeek = null;

        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        hasError = true;
        errorMessage = "Error al cargar datos: $e";
      });
    }
  }

// Método para obtener el número de semana de manera más consistente
  int getWeekOfMonth(DateTime date) {
    // Obtener el primer día del mes
    final firstDayOfMonth = DateTime(date.year, date.month, 1);

    // Calcular el número de días desde el inicio del mes
    int daysPassed = date.day - 1;

    // Ajustar para que la semana comience el lunes (1)
    int firstWeekday = firstDayOfMonth.weekday;

    // Calcular la semana del mes
    return ((daysPassed + firstWeekday - 1) ~/ 7) + 1;
  }

  // Filtrar datos según selecciones del usuario
  Future<Map<String, int>> fetchStatistics() async {
    Map<String, int> dataCount = {};

    try {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('registros').get();

      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        DateTime? date;

        if (data['fechaAsignacion'] != null) {
          date = (data['fechaAsignacion'] as Timestamp).toDate();
        } else if (data['fechaAsignacionTribu'] != null) {
          date = (data['fechaAsignacionTribu'] as Timestamp).toDate();
        }

        if (date == null) continue;

        // Aplicar filtros
        if (selectedYear != null && date.year != selectedYear) continue;

        // Aplicar filtro de ministerio
        if (selectedMinistry != "Todos" &&
            data['ministerioAsignado'] != selectedMinistry) continue;

        // Aplicar filtro de tribu
        if (selectedTribe != null) {
          String tribuDisplay =
              "${data['nombreTribu']} (${data['tribuAsignada']})";
          if (tribuDisplay != selectedTribe) continue;
        }

        // Crear clave para la agrupación de datos según el tipo de filtro
        String key;

        if (selectedFilter == "semanal") {
          // Solo se filtran por mes cuando estamos en vista semanal
          if (selectedMonth != null && months[date.month - 1] != selectedMonth)
            continue;

          int weekNum = getWeekOfMonth(date);
          key = "Semana $weekNum";
        } else if (selectedFilter == "mensual") {
          // En vista mensual, mostramos todos los meses
          key = months[date.month - 1];
        } else {
          // Vista anual
          key = date.year.toString();
        }

        dataCount[key] = (dataCount[key] ?? 0) + 1;
      }

      // Ordenar las claves
      var sortedKeys = dataCount.keys.toList();

      if (selectedFilter == "semanal") {
        sortedKeys.sort((a, b) {
          int aNum = int.parse(a.split(" ")[1]);
          int bNum = int.parse(b.split(" ")[1]);
          return aNum.compareTo(bNum);
        });
      } else if (selectedFilter == "mensual") {
        sortedKeys.sort((a, b) {
          return months.indexOf(a).compareTo(months.indexOf(b));
        });
      } else {
        sortedKeys.sort();
      }

      Map<String, int> sortedData = {};
      for (var key in sortedKeys) {
        sortedData[key] = dataCount[key]!;
      }

      return sortedData;
    } catch (e) {
      setState(() {
        hasError = true;
        errorMessage = "Error al obtener estadísticas: $e";
      });
      return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    // Obtener el tamaño de la pantalla para hacer cálculos adaptativos
    final Size screenSize = MediaQuery.of(context).size;

    return Dialog(
      backgroundColor: backgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: screenSize.width * 0.95,
          maxHeight: screenSize.height * 0.9,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Calculamos una altura fija para el chart basada en el constraint
            final double chartHeight = constraints.maxHeight * 0.4;

            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight * 0.85,
                  minWidth: constraints.maxWidth,
                ),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  width: screenSize.width * 0.9,
                  child: isLoading
                      ? _buildLoadingState()
                      : hasError
                          ? _buildErrorState()
                          : _buildContentWithFixedChart(chartHeight),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: primaryColor),
          const SizedBox(height: 20),
          Text("Cargando datos...",
              style: TextStyle(color: textColor, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: flameColor, size: 48),
          const SizedBox(height: 20),
          Text("Error",
              style: TextStyle(
                  color: textColor, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text(errorMessage,
              style: TextStyle(color: textColor, fontSize: 16),
              textAlign: TextAlign.center),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
            ),
            onPressed: _loadAvailableData,
            child: const Text("Reintentar"),
          ),
        ],
      ),
    );
  }

// Versión modificada de _buildContent que acepta una altura fija para el chart
  Widget _buildContentWithFixedChart(double chartHeight) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(),
        const SizedBox(height: 10),
        _buildTabBar(),
        const SizedBox(height: 15),
        _buildFilters(),
        const Divider(height: 30),
        // En lugar de Expanded, usamos un Container con altura fija
        Container(
          height: chartHeight,
          child: _buildChart(),
        ),
        const SizedBox(height: 10),
        _buildCloseButton(),
      ],
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(),
        const SizedBox(height: 10),
        _buildTabBar(),
        const SizedBox(height: 15),
        _buildFilters(),
        const Divider(height: 30),
        Expanded(child: _buildChart()),
        const SizedBox(height: 10),
        _buildCloseButton(),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.bar_chart, color: primaryColor, size: 28),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Estadísticas COCEP",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              Text(
                "Visualización de datos de ministerios y tribus",
                style: TextStyle(
                  fontSize: 14,
                  color: textColor.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          color: primaryColor,
        ),
        labelColor: Colors.white,
        unselectedLabelColor: textColor,
        tabs: const [
          Tab(
            icon: Icon(Icons.bar_chart),
            text: "Barras",
          ),
          Tab(
            icon: Icon(Icons.show_chart),
            text: "Líneas",
          ),
          Tab(
            icon: Icon(Icons.pie_chart),
            text: "Círculos",
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Filtros",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 15),
          Wrap(
            spacing: 20,
            runSpacing: 15,
            children: [
              _buildFilterGroup(
                title: "Período",
                child: ToggleButtons(
                  onPressed: (index) {
                    setState(() {
                      if (index == 0) {
                        selectedFilter = "anual";
                        selectedMonth = null;
                        selectedWeek = null;
                      } else if (index == 1) {
                        selectedFilter = "mensual";
                        selectedMonth = null;
                        selectedWeek = null;
                      } else {
                        selectedFilter = "semanal";
                        selectedMonth = months[DateTime.now().month - 1];
                        selectedWeek = null; // No pre-select specific week
                      }
                    });
                  },
                  borderRadius: BorderRadius.circular(20),
                  selectedBorderColor: primaryColor,
                  selectedColor: Colors.white,
                  fillColor: primaryColor,
                  color: textColor,
                  constraints:
                      const BoxConstraints(minWidth: 80, minHeight: 36),
                  isSelected: [
                    selectedFilter == "anual",
                    selectedFilter == "mensual",
                    selectedFilter == "semanal",
                  ],
                  children: const [
                    Text("Anual"),
                    Text("Mensual"),
                    Text("Semanal"),
                  ],
                ),
              ),
              _buildFilterGroup(
                title: "Año",
                child: DropdownButton<int?>(
                  value: selectedYear,
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text("Todos los años"),
                    ),
                    ...availableYears.map((int year) {
                      return DropdownMenuItem<int?>(
                        value: year,
                        child: Text(year.toString()),
                      );
                    }).toList(),
                  ],
                  onChanged: (value) => setState(() => selectedYear = value),
                  underline: Container(height: 1, color: primaryColor),
                ),
              ),
              if (selectedFilter == "semanal")
                _buildFilterGroup(
                  title: "Mes",
                  child: DropdownButton<String>(
                    value: selectedMonth,
                    items: months.map((String month) {
                      return DropdownMenuItem<String>(
                        value: month,
                        child: Text(month),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => selectedMonth = value),
                    underline: Container(height: 1, color: primaryColor),
                  ),
                ),
              _buildFilterGroup(
                title: "Ministerio",
                child: DropdownButton<String>(
                  value: selectedMinistry,
                  items: ministerioTribus.keys.map((String ministry) {
                    return DropdownMenuItem<String>(
                      value: ministry,
                      child: Text(ministry),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedMinistry = value!;
                      selectedTribe = null; // Reset selected tribe
                    });
                  },
                  underline: Container(height: 1, color: primaryColor),
                ),
              ),
              if (ministerioTribus.containsKey(selectedMinistry) &&
                  ministerioTribus[selectedMinistry]!.isNotEmpty)
                _buildFilterGroup(
                  title: "Tribu",
                  child: DropdownButton<String>(
                    value: selectedTribe,
                    hint: const Text("Seleccione tribu"),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text("Todas las tribus"),
                      ),
                      ...ministerioTribus[selectedMinistry]!
                          .map((String tribe) {
                        // Extraer solo el nombre de la tribu sin el paréntesis
                        String tribeName = tribe.split(" (")[0];
                        return DropdownMenuItem<String>(
                          value: tribe,
                          child: Text(tribeName),
                        );
                      }).toList(),
                    ],
                    onChanged: (value) => setState(() => selectedTribe = value),
                    underline: Container(height: 1, color: primaryColor),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterGroup({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: textColor.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 5),
        child,
      ],
    );
  }

  Widget _buildChart() {
    return FutureBuilder<Map<String, int>>(
      future: fetchStatistics(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: primaryColor));
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: flameColor, size: 40),
                const SizedBox(height: 15),
                Text("Error al cargar datos",
                    style: TextStyle(color: textColor)),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline, color: accentColor, size: 40),
                const SizedBox(height: 15),
                Text(
                  "No hay datos para los filtros seleccionados",
                  style: TextStyle(color: textColor),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  _getChartTitle(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
              Expanded(
                child: selectedGraph == "barras"
                    ? _buildBarChart(snapshot.data!)
                    : selectedGraph == "lineal"
                        ? _buildLineChart(snapshot.data!)
                        : _buildPieChart(snapshot.data!),
              ),
              const SizedBox(height: 10),
              _buildChartLegend(snapshot.data!),
            ],
          ),
        );
      },
    );
  }

  String _getChartTitle() {
    String period = selectedFilter == "anual"
        ? "Anual${selectedYear == null ? ' (Todos los años)' : ' ($selectedYear)'}"
        : selectedFilter == "mensual"
            ? "Mensual${selectedYear == null ? ' (Todos los años)' : ' ($selectedYear)'}"
            : "Semanal${selectedMonth != null ? ' ($selectedMonth)' : ''}${selectedYear == null ? ' (Todos los años)' : ' ($selectedYear)'}";

    String ministry = selectedMinistry == "Todos"
        ? "Todos los ministerios"
        : "Ministerio: $selectedMinistry";

    String tribe = selectedTribe == null
        ? "Todas las tribus"
        : "Tribu: ${selectedTribe!.split(" (")[0]}";

    return "$period - $ministry - $tribe";
  }

  Widget _buildBarChart(Map<String, int> data) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: data.values.isEmpty
              ? 10
              : (data.values.reduce((a, b) => a > b ? a : b) * 1.2),
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              tooltipBgColor: Colors.white.withOpacity(0.8),
              tooltipPadding: const EdgeInsets.all(8),
              tooltipMargin: 8,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                String xValue = data.keys.elementAt(group.x.toInt());
                return BarTooltipItem(
                  '$xValue\n',
                  TextStyle(color: textColor, fontWeight: FontWeight.bold),
                  children: [
                    TextSpan(
                      text: '${rod.toY.toInt()} registros',
                      style: TextStyle(
                          color: primaryColor, fontWeight: FontWeight.w500),
                    ),
                  ],
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value >= 0 && value < data.length) {
                    String text = data.keys.elementAt(value.toInt());
                    // Acortar el texto si es demasiado largo
                    if (text.length > 5 && data.length > 6) {
                      text = text.substring(0, 3) + "..";
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        text,
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    );
                  }
                  return const SizedBox();
                },
                reservedSize: 30,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: data.values.isEmpty
                    ? 2
                    : (data.values.reduce((a, b) => a > b ? a : b) / 5)
                        .ceilToDouble(),
                getTitlesWidget: (value, meta) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Text(
                      value.toInt().toString(),
                      style: TextStyle(
                        color: textColor,
                        fontSize: 10,
                      ),
                    ),
                  );
                },
                reservedSize: 30,
              ),
            ),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey.withOpacity(0.2),
                strokeWidth: 1,
              );
            },
          ),
          borderData: FlBorderData(
            show: false,
          ),
          barGroups: data.entries.map((entry) {
            final index = data.keys.toList().indexOf(entry.key);
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: entry.value.toDouble(),
                  color: chartColors[index % chartColors.length],
                  width: 15,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(6),
                    topRight: Radius.circular(6),
                  ),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: data.values.isEmpty
                        ? 10
                        : (data.values.reduce((a, b) => a > b ? a : b) * 1.2),
                    color: chartColors[index % chartColors.length]
                        .withOpacity(0.1),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
        swapAnimationDuration: const Duration(milliseconds: 250),
      ),
    );
  }

  Widget _buildLineChart(Map<String, int> data) {
    final spots = data.entries.map((entry) {
      final index = data.keys.toList().indexOf(entry.key);
      return FlSpot(index.toDouble(), entry.value.toDouble());
    }).toList();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, Colors.grey.shade50],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      margin: const EdgeInsets.all(12.0),
      padding: const EdgeInsets.fromLTRB(8, 24, 8, 12),
      child: LineChart(
        LineChartData(
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              tooltipBgColor: Colors.white,
              tooltipRoundedRadius: 12,
              tooltipMargin: 8,
              tooltipPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              getTooltipItems: (List<LineBarSpot> touchedSpots) {
                return touchedSpots.map((LineBarSpot touchedSpot) {
                  final spotIndex = touchedSpot.x.toInt();
                  if (spotIndex >= 0 && spotIndex < data.keys.length) {
                    final String period = data.keys.elementAt(spotIndex);
                    final int value = touchedSpot.y.toInt();
                    return LineTooltipItem(
                      '$period\n',
                      TextStyle(
                        color: Colors.blueGrey.shade800,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      children: [
                        TextSpan(
                          text: '$value ',
                          style: TextStyle(
                            color: accentColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        TextSpan(
                          text:
                              'registros 📈', // Se reemplaza el ícono con emoji
                          style: TextStyle(
                            color: Colors.blueGrey.shade600,
                            fontWeight: FontWeight.w400,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    );
                  }
                  return null;
                }).toList();
              },
            ),
            touchSpotThreshold: 20,
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value >= 0 && value < data.length) {
                    String text = data.keys.elementAt(value.toInt());
                    // Acortar texto si es muy largo
                    if (text.length > 5) {
                      text = text.substring(0, 3);
                    }
                    return Container(
                      padding: const EdgeInsets.only(top: 10.0),
                      decoration: BoxDecoration(
                        border: value.toInt() % 2 == 0
                            ? Border(
                                top: BorderSide(
                                  color: Colors.grey.withOpacity(0.3),
                                  width: 1,
                                ),
                              )
                            : null,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 12,
                            color: Colors.blueGrey.shade400,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            text,
                            style: TextStyle(
                              color: Colors.blueGrey.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox();
                },
                reservedSize: 50,
                interval: 1,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: data.values.isEmpty
                    ? 2
                    : (data.values.reduce((a, b) => a > b ? a : b) / 5)
                        .ceilToDouble(),
                getTitlesWidget: (value, meta) {
                  return Container(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.bar_chart,
                          size: 10,
                          color: Colors.blueGrey.shade400,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          value.toInt().toString(),
                          style: TextStyle(
                            color: Colors.blueGrey.shade600,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                },
                reservedSize: 50,
              ),
            ),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey.withOpacity(0.15),
                strokeWidth: 1,
                dashArray: [5, 5],
              );
            },
            checkToShowHorizontalLine: (value) {
              return value %
                      (data.values.isEmpty
                          ? 2
                          : (data.values.reduce((a, b) => a > b ? a : b) / 5)
                              .ceilToDouble()) ==
                  0;
            },
          ),
          borderData: FlBorderData(
            show: true,
            border: Border(
              bottom: BorderSide(color: Colors.grey.withOpacity(0.3), width: 1),
              left: BorderSide(color: Colors.grey.withOpacity(0.3), width: 1),
            ),
          ),
          minX: 0,
          maxX: (data.length - 1).toDouble(),
          minY: 0,
          maxY: data.values.isEmpty
              ? 10
              : (data.values.reduce((a, b) => a > b ? a : b) * 1.2),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.35,
              color: accentColor,
              gradient: LinearGradient(
                colors: [
                  accentColor.withOpacity(0.8),
                  accentColor,
                ],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 6,
                    color: Colors.white,
                    strokeWidth: 3,
                    strokeColor: accentColor,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    accentColor.withOpacity(0.4),
                    accentColor.withOpacity(0.1),
                    accentColor.withOpacity(0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              shadow: const Shadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ),
          ],
          extraLinesData: ExtraLinesData(
            horizontalLines: data.values.isNotEmpty
                ? [
                    HorizontalLine(
                      y: data.values.reduce((a, b) => a > b ? a : b).toDouble(),
                      color: Colors.redAccent.withOpacity(0.5),
                      strokeWidth: 1,
                      dashArray: [5, 5],
                      label: HorizontalLineLabel(
                        show: true,
                        alignment: Alignment.topRight,
                        padding: const EdgeInsets.only(right: 8, bottom: 4),
                        style: TextStyle(
                          color: Colors.redAccent.withOpacity(0.8),
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                        labelResolver: (line) => 'Máximo',
                      ),
                    ),
                    HorizontalLine(
                      y: (data.values.reduce((sum, value) => sum + value) /
                              data.values.length)
                          .toDouble(),
                      color: Colors.amber.withOpacity(0.5),
                      strokeWidth: 1,
                      dashArray: [5, 5],
                      label: HorizontalLineLabel(
                        show: true,
                        alignment: Alignment.topRight,
                        padding: const EdgeInsets.only(right: 8, bottom: 4),
                        style: TextStyle(
                          color: Colors.amber.withOpacity(0.8),
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                        labelResolver: (line) => 'Promedio',
                      ),
                    ),
                  ]
                : [],
          ),
        ),
      ),
    );
  }

  Widget _buildPieChart(Map<String, int> data) {
    return data.isEmpty
        ? Center(
            child: Text("No hay datos disponibles",
                style: TextStyle(color: textColor)))
        : PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  // Implementar interactividad si se desea
                },
                enabled: true,
              ),
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: _getSections(data),
            ),
          );
  }

  List<PieChartSectionData> _getSections(Map<String, int> data) {
    return data.entries.map((entry) {
      final index = data.keys.toList().indexOf(entry.key);
      final value = entry.value;
      final total = data.values.reduce((sum, item) => sum + item);
      final percentage =
          total > 0 ? (value / total * 100).toStringAsFixed(1) : '0.0';

      return PieChartSectionData(
        color: chartColors[index % chartColors.length],
        value: value.toDouble(),
        title: '$percentage%',
        radius: 100,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        badgeWidget: _Badge(
          entry.key,
          size: 40,
          borderColor: chartColors[index % chartColors.length],
        ),
        badgePositionPercentageOffset: 1.2,
      );
    }).toList();
  }

  Widget _buildChartLegend(Map<String, int> data) {
    final total = data.values.fold(0, (sum, item) => sum + item);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Total de registros: $total",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              if (selectedGraph == "circular")
                const Text(
                  "Toca las secciones para más detalles",
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: data.entries.map((entry) {
              final index = data.keys.toList().indexOf(entry.key);
              final color = chartColors[index % chartColors.length];

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "${entry.key}: ${entry.value}",
                    style: TextStyle(
                      fontSize: 12,
                      color: textColor,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCloseButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      onPressed: () => Navigator.pop(context),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.close),
          SizedBox(width: 8),
          Text("Cerrar", style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String title;
  final double size;
  final Color borderColor;

  const _Badge(
    this.title, {
    Key? key,
    required this.size,
    required this.borderColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: PieChart.defaultDuration,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: borderColor,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            offset: const Offset(2, 2),
            blurRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: Text(
          title.length > 3 ? title.substring(0, 3) : title,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: borderColor,
          ),
        ),
      ),
    );
  }
}
