import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:screenshot/screenshot.dart';
import 'dart:typed_data';
import 'dart:html' as html;
import 'dart:ui' as ui;

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

  final ScreenshotController _barChartController = ScreenshotController();
  final ScreenshotController _lineChartController = ScreenshotController();
  final ScreenshotController _pieChartController = ScreenshotController();
// Overlay entry para renderizado invisible
  OverlayEntry? _overlayEntry;

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
    // Limpiar overlay si existe
    if (_overlayEntry != null) {
      try {
        _overlayEntry!.remove();
      } catch (_) {}
      _overlayEntry = null;
    }
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

// ===== MÉTODO COMPLETO PARA DESCARGAR GRÁFICA =====
  /// Descarga la gráfica actualmente seleccionada como imagen PNG
  /// Se renderiza en alta resolución (1600x900) para garantizar legibilidad
  Future<void> _downloadChart() async {
    try {
      // Verificar que el contexto es válido
      if (!mounted) {
        return;
      }

      // Obtener los datos actuales de la gráfica
      final data = await fetchStatistics();

      if (data.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('No hay datos para descargar'),
              backgroundColor: flameColor,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      // Mostrar indicador de carga
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 15),
                Text('Generando imagen...'),
              ],
            ),
            duration: const Duration(seconds: 5),
            backgroundColor: primaryColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      await Future.delayed(const Duration(milliseconds: 300));

      // Determinar qué controlador usar según el tipo de gráfica
      ScreenshotController controller;
      Widget chartContent;

      if (selectedGraph == "barras") {
        controller = _barChartController;
        chartContent = _buildBarChart(data, false, false);
      } else if (selectedGraph == "lineal") {
        controller = _lineChartController;
        chartContent = _buildLineChart(data, false, false);
      } else {
        controller = _pieChartController;
        chartContent = _buildPieChart(data, false, false);
      }

      // Crear widget de gráfica
      final chartWidget = Screenshot(
        controller: controller,
        child: Container(
          width: 1600,
          height: 900,
          color: backgroundColor,
          padding: const EdgeInsets.all(40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child:
                          Icon(Icons.bar_chart, color: primaryColor, size: 36),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Estadísticas COCEP",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _getChartTitle(),
                            style: TextStyle(
                              fontSize: 16,
                              color: textColor.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          DateFormat('dd/MM/yyyy', 'es_ES')
                              .format(DateTime.now()),
                          style: TextStyle(
                            fontSize: 14,
                            color: textColor.withOpacity(0.6),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          DateFormat('HH:mm', 'es_ES').format(DateTime.now()),
                          style: TextStyle(
                            fontSize: 12,
                            color: textColor.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: chartContent,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: _buildChartLegend(data, false),
              ),
            ],
          ),
        ),
      );

      if (!mounted) return;

      final overlay = Overlay.of(context);
      if (overlay == null) {
        throw Exception('No se pudo acceder al Overlay');
      }

      _overlayEntry = OverlayEntry(
        builder: (overlayContext) => Positioned(
          top: -10000, // Fuera de la pantalla
          left: 0,
          child: IgnorePointer(
            child: Material(
              color: Colors.transparent,
              child: MediaQuery(
                data: const MediaQueryData(
                  size: Size(1600, 900),
                  devicePixelRatio: 2.0,
                  textScaleFactor: 1.0,
                ),
                child: Directionality(
                  textDirection: ui.TextDirection.ltr,
                  child: DefaultTextStyle(
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      color: Colors.black,
                    ),
                    child: chartWidget,
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      overlay.insert(_overlayEntry!);

      // Esperar renderizado
      await Future.delayed(const Duration(milliseconds: 200));
      await WidgetsBinding.instance.endOfFrame;
      await Future.delayed(const Duration(milliseconds: 200));

      Uint8List? imageBytes;

      try {
        imageBytes = await controller.capture(
          pixelRatio: 2.0,
          delay: const Duration(milliseconds: 100),
        );
      } catch (captureError) {
        print('Error al capturar: $captureError');
        await Future.delayed(const Duration(milliseconds: 200));
        imageBytes = await controller.capture(
          pixelRatio: 2.0,
          delay: const Duration(milliseconds: 100),
        );
      }

      if (_overlayEntry != null) {
        try {
          _overlayEntry!.remove();
        } catch (_) {}
        _overlayEntry = null;
      }

      if (imageBytes == null || imageBytes.isEmpty) {
        throw Exception('No se pudo capturar la imagen');
      }

      final timestamp =
          DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
      final chartType = selectedGraph == "barras"
          ? "Barras"
          : selectedGraph == "lineal"
              ? "Lineal"
              : "Circular";

      String filterInfo = "";
      if (selectedYear != null) filterInfo += "_${selectedYear}";
      if (selectedMonth != null) filterInfo += "_${selectedMonth}";
      if (selectedMinistry != "Todos") {
        filterInfo += "_${selectedMinistry.replaceAll(' ', '_')}";
      }

      final fileName = 'Grafica_${chartType}${filterInfo}_$timestamp.png';

      try {
        final blob = html.Blob([imageBytes], 'image/png');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', fileName)
          ..style.display = 'none';

        html.document.body?.append(anchor);
        anchor.click();

        await Future.delayed(const Duration(milliseconds: 100));
        anchor.remove();
        html.Url.revokeObjectUrl(url);
      } catch (downloadError) {
        print('Error en descarga: $downloadError');
        throw Exception('Error al iniciar la descarga');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '¡Descarga exitosa!',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        fileName,
                        style: const TextStyle(fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF2ECC71),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e, stackTrace) {
      if (_overlayEntry != null) {
        try {
          _overlayEntry!.remove();
        } catch (_) {}
        _overlayEntry = null;
      }

      print('Error al descargar gráfica: $e');
      print('Stack trace: $stackTrace');

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.error_outline, color: Colors.white),
                    SizedBox(width: 10),
                    Text(
                      'Error al descargar gráfica',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                const Text(
                  'Por favor, intenta nuevamente',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
            backgroundColor: flameColor,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'REINTENTAR',
              textColor: Colors.white,
              onPressed: _downloadChart,
            ),
          ),
        );
      }
    }
  }
// ===== FIN DEL MÉTODO CORREGIDO =====

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
      // Obtener snapshot con timeout para evitar bloqueos
      QuerySnapshot? snapshot;

      try {
        snapshot = await FirebaseFirestore.instance
            .collection('registros')
            .get()
            .timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            throw Exception('Tiempo de espera agotado al cargar datos');
          },
        );
      } catch (connectionError) {
        print('Error de conexión: $connectionError');
        if (mounted) {
          setState(() {
            hasError = true;
            errorMessage = "Error de conexión con la base de datos";
          });
        }
        return {};
      }

      // Validar que el snapshot no sea nulo y tenga documentos
      if (snapshot == null) {
        print('Snapshot es nulo');
        return {};
      }

      if (snapshot.docs.isEmpty) {
        print('No hay documentos en la colección');
        return {};
      }

      // Procesar cada documento con validaciones
      for (var doc in snapshot.docs) {
        try {
          // Validar que el documento tenga datos
          if (!doc.exists) continue;

          var data = doc.data() as Map<String, dynamic>?;

          // Validar que data no sea nulo
          if (data == null || data.isEmpty) {
            print('Documento ${doc.id} no tiene datos');
            continue;
          }

          DateTime? date;

          // Intentar obtener fecha de asignación con validación
          try {
            if (data.containsKey('fechaAsignacion') &&
                data['fechaAsignacion'] != null) {
              date = (data['fechaAsignacion'] as Timestamp).toDate();
            } else if (data.containsKey('fechaAsignacionTribu') &&
                data['fechaAsignacionTribu'] != null) {
              date = (data['fechaAsignacionTribu'] as Timestamp).toDate();
            }
          } catch (dateError) {
            print(
                'Error al procesar fecha del documento ${doc.id}: $dateError');
            continue;
          }

          // Si no hay fecha válida, saltar este documento
          if (date == null) {
            print('Documento ${doc.id} no tiene fecha válida');
            continue;
          }

          // Validar que la fecha sea razonable (no futuras ni muy antiguas)
          final now = DateTime.now();
          if (date.isAfter(now) || date.year < 2000) {
            print('Fecha inválida en documento ${doc.id}: $date');
            continue;
          }

          // Aplicar filtro de año con validación
          if (selectedYear != null && date.year != selectedYear) continue;

          // Aplicar filtro de ministerio con validación de null
          if (selectedMinistry != "Todos") {
            final ministerio = data['ministerioAsignado'] as String?;
            if (ministerio == null || ministerio != selectedMinistry) continue;
          }

          // Aplicar filtro de tribu con validaciones
          if (selectedTribe != null) {
            final nombreTribu = data['nombreTribu'] as String?;
            final tribuAsignada = data['tribuAsignada'] as String?;

            if (nombreTribu == null || tribuAsignada == null) continue;

            String tribuDisplay = "$nombreTribu ($tribuAsignada)";
            if (tribuDisplay != selectedTribe) continue;
          }

          // Crear clave para la agrupación de datos según el tipo de filtro
          String? key;

          try {
            if (selectedFilter == "semanal") {
              // Validar mes en vista semanal
              if (selectedMonth != null) {
                if (date.month < 1 || date.month > 12) {
                  print('Mes inválido: ${date.month}');
                  continue;
                }
                if (months[date.month - 1] != selectedMonth) continue;
              }

              int weekNum = getWeekOfMonth(date);

              // Validar número de semana
              if (weekNum < 1 || weekNum > 6) {
                print('Número de semana inválido: $weekNum');
                continue;
              }

              key = "Semana $weekNum";
            } else if (selectedFilter == "mensual") {
              // Validar mes
              if (date.month < 1 || date.month > 12) {
                print('Mes inválido: ${date.month}');
                continue;
              }
              key = months[date.month - 1];
            } else {
              // Vista anual
              key = date.year.toString();
            }
          } catch (keyError) {
            print('Error al generar clave para documento ${doc.id}: $keyError');
            continue;
          }

          // Validar que se generó una clave
          if (key == null || key.isEmpty) {
            print('Clave inválida generada para documento ${doc.id}');
            continue;
          }

          // Incrementar contador de forma segura
          dataCount[key] = (dataCount[key] ?? 0) + 1;
        } catch (docError) {
          print('Error procesando documento ${doc.id}: $docError');
          continue; // Continuar con el siguiente documento
        }
      }

      // Si no hay datos después de aplicar filtros, retornar vacío
      if (dataCount.isEmpty) {
        print('No hay datos después de aplicar filtros');
        return {};
      }

      // Ordenar las claves de forma segura
      Map<String, int> sortedData = {};

      try {
        var sortedKeys = dataCount.keys.toList();

        if (selectedFilter == "semanal") {
          sortedKeys.sort((a, b) {
            try {
              // Extraer número de semana de forma segura
              final aParts = a.split(" ");
              final bParts = b.split(" ");

              if (aParts.length < 2 || bParts.length < 2) return 0;

              int aNum = int.tryParse(aParts[1]) ?? 0;
              int bNum = int.tryParse(bParts[1]) ?? 0;

              return aNum.compareTo(bNum);
            } catch (e) {
              print('Error al ordenar semanas: $e');
              return 0;
            }
          });
        } else if (selectedFilter == "mensual") {
          sortedKeys.sort((a, b) {
            try {
              int aIndex = months.indexOf(a);
              int bIndex = months.indexOf(b);

              // Si algún mes no se encuentra, ponerlo al final
              if (aIndex == -1) return 1;
              if (bIndex == -1) return -1;

              return aIndex.compareTo(bIndex);
            } catch (e) {
              print('Error al ordenar meses: $e');
              return 0;
            }
          });
        } else {
          // Ordenar años
          sortedKeys.sort((a, b) {
            try {
              int aYear = int.tryParse(a) ?? 0;
              int bYear = int.tryParse(b) ?? 0;
              return aYear.compareTo(bYear);
            } catch (e) {
              print('Error al ordenar años: $e');
              return 0;
            }
          });
        }

        // Crear mapa ordenado de forma segura
        for (var key in sortedKeys) {
          final value = dataCount[key];
          if (value != null && value > 0) {
            sortedData[key] = value;
          }
        }
      } catch (sortError) {
        print('Error al ordenar datos: $sortError');
        // Si falla el ordenamiento, retornar los datos sin ordenar
        sortedData = dataCount;
      }

      // Validar que hay datos ordenados
      if (sortedData.isEmpty) {
        print('No hay datos después de ordenar');
        return {};
      }

      print('Datos procesados exitosamente: ${sortedData.length} entradas');
      return sortedData;
    } catch (e, stackTrace) {
      print('Error crítico en fetchStatistics: $e');
      print('Stack trace: $stackTrace');

      if (mounted) {
        setState(() {
          hasError = true;
          errorMessage = "Error al obtener estadísticas: ${e.toString()}";
        });
      }

      return {};
    }
  }

// Agregar después del método fetchStatistics()
  bool _validateData(Map<String, int> data) {
    if (data.isEmpty) {
      print('No hay datos disponibles');
      return false;
    }

    if (data.values.any((value) => value < 0)) {
      print('Datos inválidos detectados');
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final bool isSmallScreen = screenSize.width < 600;
    final bool isVerySmallScreen = screenSize.width < 400;

    return Dialog(
      backgroundColor: backgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: BoxConstraints(
          maxWidth:
              isSmallScreen ? screenSize.width * 0.95 : screenSize.width * 0.9,
          maxHeight: screenSize.height * 0.95,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double chartHeight = isVerySmallScreen
                ? constraints.maxHeight * 0.35
                : isSmallScreen
                    ? constraints.maxHeight * 0.4
                    : constraints.maxHeight * 0.45;

            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight * 0.85,
                  minWidth: constraints.maxWidth,
                ),
                child: Container(
                  padding: EdgeInsets.all(isVerySmallScreen ? 12 : 20),
                  width: constraints.maxWidth,
                  child: isLoading
                      ? _buildLoadingState()
                      : hasError
                          ? _buildErrorState()
                          : _buildContentWithFixedChart(
                              chartHeight, isSmallScreen, isVerySmallScreen),
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

  Widget _buildContentWithFixedChart(
      double chartHeight, bool isSmallScreen, bool isVerySmallScreen) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(isVerySmallScreen), // Pasar el parámetro
        SizedBox(height: isVerySmallScreen ? 8 : 10),
        _buildTabBar(isVerySmallScreen),
        SizedBox(height: isVerySmallScreen ? 10 : 15),
        _buildFilters(isSmallScreen, isVerySmallScreen),
        const Divider(height: 30),
        Container(
          height: chartHeight,
          child:
              _buildChart(isSmallScreen, isVerySmallScreen), // Pasar parámetros
        ),
        const SizedBox(height: 10),
        _buildCloseButton(),
      ],
    );
  }

  Widget _buildContent(
      [bool isSmallScreen = false, bool isVerySmallScreen = false]) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(isVerySmallScreen),
        const SizedBox(height: 10),
        _buildTabBar(isVerySmallScreen),
        const SizedBox(height: 15),
        _buildFilters(isSmallScreen, isVerySmallScreen),
        const Divider(height: 30),
        Expanded(child: _buildChart(isSmallScreen, isVerySmallScreen)),
        const SizedBox(height: 10),
        _buildCloseButton(),
      ],
    );
  }

  Widget _buildHeader([bool isVerySmallScreen = false]) {
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

  Widget _buildTabBar(bool isVerySmallScreen) {
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
        labelStyle: TextStyle(fontSize: isVerySmallScreen ? 11 : 14),
        unselectedLabelStyle: TextStyle(fontSize: isVerySmallScreen ? 11 : 14),
        tabs: [
          Tab(
            icon: Icon(Icons.bar_chart, size: isVerySmallScreen ? 18 : 24),
            text: "Barras",
          ),
          Tab(
            icon: Icon(Icons.show_chart, size: isVerySmallScreen ? 18 : 24),
            text: "Líneas",
          ),
          Tab(
            icon: Icon(Icons.pie_chart, size: isVerySmallScreen ? 18 : 24),
            text: "Círculos",
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(bool isSmallScreen, bool isVerySmallScreen) {
    return Container(
      padding: EdgeInsets.all(isVerySmallScreen ? 10 : 15),
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
              fontSize: isVerySmallScreen ? 14 : 16,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          SizedBox(height: isVerySmallScreen ? 10 : 15),
          isSmallScreen
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildFilterGroup(
                      title: "Período",
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
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
                                selectedMonth =
                                    months[DateTime.now().month - 1];
                                selectedWeek = null;
                              }
                            });
                          },
                          borderRadius: BorderRadius.circular(20),
                          selectedBorderColor: primaryColor,
                          selectedColor: Colors.white,
                          fillColor: primaryColor,
                          color: textColor,
                          constraints: BoxConstraints(
                              minWidth: isVerySmallScreen ? 60 : 80,
                              minHeight: isVerySmallScreen ? 32 : 36),
                          isSelected: [
                            selectedFilter == "anual",
                            selectedFilter == "mensual",
                            selectedFilter == "semanal",
                          ],
                          children: [
                            Text("Anual",
                                style: TextStyle(
                                    fontSize: isVerySmallScreen ? 11 : 14)),
                            Text("Mensual",
                                style: TextStyle(
                                    fontSize: isVerySmallScreen ? 11 : 14)),
                            Text("Semanal",
                                style: TextStyle(
                                    fontSize: isVerySmallScreen ? 11 : 14)),
                          ],
                        ),
                      ),
                      isSmallScreen: isSmallScreen,
                      isVerySmallScreen: isVerySmallScreen,
                    ),
                    SizedBox(height: isVerySmallScreen ? 12 : 15),
                    _buildFilterGroup(
                      title: "Año",
                      child: DropdownButton<int?>(
                        value: selectedYear,
                        isExpanded: true,
                        style: TextStyle(
                            fontSize: isVerySmallScreen ? 12 : 14,
                            color: textColor),
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
                        onChanged: (value) =>
                            setState(() => selectedYear = value),
                        underline: Container(height: 1, color: primaryColor),
                      ),
                      isSmallScreen: isSmallScreen,
                      isVerySmallScreen: isVerySmallScreen,
                    ),
                    if (selectedFilter == "semanal") ...[
                      SizedBox(height: isVerySmallScreen ? 12 : 15),
                      _buildFilterGroup(
                        title: "Mes",
                        child: DropdownButton<String>(
                          value: selectedMonth,
                          isExpanded: true,
                          style: TextStyle(
                              fontSize: isVerySmallScreen ? 12 : 14,
                              color: textColor),
                          items: months.map((String month) {
                            return DropdownMenuItem<String>(
                              value: month,
                              child: Text(month),
                            );
                          }).toList(),
                          onChanged: (value) =>
                              setState(() => selectedMonth = value),
                          underline: Container(height: 1, color: primaryColor),
                        ),
                        isSmallScreen: isSmallScreen,
                        isVerySmallScreen: isVerySmallScreen,
                      ),
                    ],
                    SizedBox(height: isVerySmallScreen ? 12 : 15),
                    _buildFilterGroup(
                      title: "Ministerio",
                      child: DropdownButton<String>(
                        value: selectedMinistry,
                        isExpanded: true,
                        style: TextStyle(
                            fontSize: isVerySmallScreen ? 12 : 14,
                            color: textColor),
                        items: ministerioTribus.keys.map((String ministry) {
                          return DropdownMenuItem<String>(
                            value: ministry,
                            child: Text(ministry),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedMinistry = value!;
                            selectedTribe = null;
                          });
                        },
                        underline: Container(height: 1, color: primaryColor),
                      ),
                      isSmallScreen: isSmallScreen,
                      isVerySmallScreen: isVerySmallScreen,
                    ),
                    if (ministerioTribus.containsKey(selectedMinistry) &&
                        ministerioTribus[selectedMinistry]!.isNotEmpty) ...[
                      SizedBox(height: isVerySmallScreen ? 12 : 15),
                      _buildFilterGroup(
                        title: "Tribu",
                        child: DropdownButton<String>(
                          value: selectedTribe,
                          hint: Text("Seleccione tribu",
                              style: TextStyle(
                                  fontSize: isVerySmallScreen ? 12 : 14)),
                          isExpanded: true,
                          style: TextStyle(
                              fontSize: isVerySmallScreen ? 12 : 14,
                              color: textColor),
                          items: [
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Text("Todas las tribus"),
                            ),
                            ...ministerioTribus[selectedMinistry]!
                                .map((String tribe) {
                              String tribeName = tribe.split(" (")[0];
                              return DropdownMenuItem<String>(
                                value: tribe,
                                child: Text(tribeName),
                              );
                            }).toList(),
                          ],
                          onChanged: (value) =>
                              setState(() => selectedTribe = value),
                          underline: Container(height: 1, color: primaryColor),
                        ),
                        isSmallScreen: isSmallScreen,
                        isVerySmallScreen: isVerySmallScreen,
                      ),
                    ],
                  ],
                )
              : Wrap(
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
                              selectedWeek = null;
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
                      isSmallScreen: isSmallScreen,
                      isVerySmallScreen: isVerySmallScreen,
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
                        onChanged: (value) =>
                            setState(() => selectedYear = value),
                        underline: Container(height: 1, color: primaryColor),
                      ),
                      isSmallScreen: isSmallScreen,
                      isVerySmallScreen: isVerySmallScreen,
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
                          onChanged: (value) =>
                              setState(() => selectedMonth = value),
                          underline: Container(height: 1, color: primaryColor),
                        ),
                        isSmallScreen: isSmallScreen,
                        isVerySmallScreen: isVerySmallScreen,
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
                            selectedTribe = null;
                          });
                        },
                        underline: Container(height: 1, color: primaryColor),
                      ),
                      isSmallScreen: isSmallScreen,
                      isVerySmallScreen: isVerySmallScreen,
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
                              String tribeName = tribe.split(" (")[0];
                              return DropdownMenuItem<String>(
                                value: tribe,
                                child: Text(tribeName),
                              );
                            }).toList(),
                          ],
                          onChanged: (value) =>
                              setState(() => selectedTribe = value),
                          underline: Container(height: 1, color: primaryColor),
                        ),
                        isSmallScreen: isSmallScreen,
                        isVerySmallScreen: isVerySmallScreen,
                      ),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildFilterGroup(
      {required String title,
      required Widget child,
      bool isSmallScreen = false,
      bool isVerySmallScreen = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: isVerySmallScreen ? 11 : 12,
            color: textColor.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 5),
        child,
      ],
    );
  }

  Widget _buildChart(
      [bool isSmallScreen = false, bool isVerySmallScreen = false]) {
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
                    ? _buildBarChart(
                        snapshot.data!, isSmallScreen, isVerySmallScreen)
                    : selectedGraph == "lineal"
                        ? _buildLineChart(
                            snapshot.data!, isSmallScreen, isVerySmallScreen)
                        : _buildPieChart(
                            snapshot.data!, isSmallScreen, isVerySmallScreen),
              ),
              const SizedBox(height: 10),
              _buildChartLegend(snapshot.data!, isVerySmallScreen),
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

  Widget _buildBarChart(
      Map<String, int> data, bool isSmallScreen, bool isVerySmallScreen) {
    return Padding(
      padding: EdgeInsets.all(isVerySmallScreen ? 4.0 : 8.0),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: data.values.isEmpty
              ? 10
              : (data.values.reduce((a, b) => a > b ? a : b) * 1.2),
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              tooltipBgColor: Colors.white.withOpacity(0.9),
              tooltipPadding: EdgeInsets.all(isVerySmallScreen ? 6 : 8),
              tooltipMargin: isVerySmallScreen ? 6 : 8,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                String xValue = data.keys.elementAt(group.x.toInt());
                return BarTooltipItem(
                  '$xValue\n',
                  TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: isVerySmallScreen ? 11 : 13,
                  ),
                  children: [
                    TextSpan(
                      text: '${rod.toY.toInt()} registros',
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.w500,
                        fontSize: isVerySmallScreen ? 10 : 12,
                      ),
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
                    if (isVerySmallScreen && text.length > 3) {
                      text = text.substring(0, 2) + "..";
                    } else if (text.length > 5 && data.length > 6) {
                      text = text.substring(0, 3) + "..";
                    }
                    return Padding(
                      padding:
                          EdgeInsets.only(top: isVerySmallScreen ? 4.0 : 8.0),
                      child: Text(
                        text,
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: isVerySmallScreen ? 8 : 10,
                        ),
                      ),
                    );
                  }
                  return const SizedBox();
                },
                reservedSize: isVerySmallScreen ? 25 : 30,
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
                    padding:
                        EdgeInsets.only(right: isVerySmallScreen ? 4.0 : 8.0),
                    child: Text(
                      value.toInt().toString(),
                      style: TextStyle(
                        color: textColor,
                        fontSize: isVerySmallScreen ? 8 : 10,
                      ),
                    ),
                  );
                },
                reservedSize: isVerySmallScreen ? 25 : 30,
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
          borderData: FlBorderData(show: false),
          barGroups: data.entries.map((entry) {
            final index = data.keys.toList().indexOf(entry.key);
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: entry.value.toDouble(),
                  color: chartColors[index % chartColors.length],
                  width: isVerySmallScreen ? 12 : 15,
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

  Widget _buildLineChart(
      Map<String, int> data, bool isSmallScreen, bool isVerySmallScreen) {
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
      margin: EdgeInsets.all(isVerySmallScreen ? 6.0 : 12.0),
      padding: EdgeInsets.fromLTRB(
          isVerySmallScreen ? 4 : 8,
          isVerySmallScreen ? 16 : 24,
          isVerySmallScreen ? 4 : 8,
          isVerySmallScreen ? 6 : 12),
      child: LineChart(
        LineChartData(
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              tooltipBgColor: Colors.white,
              tooltipRoundedRadius: isVerySmallScreen ? 8 : 12,
              tooltipMargin: isVerySmallScreen ? 6 : 8,
              tooltipPadding: EdgeInsets.symmetric(
                  horizontal: isVerySmallScreen ? 10 : 16,
                  vertical: isVerySmallScreen ? 6 : 10),
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
                        fontSize: isVerySmallScreen ? 11 : 14,
                      ),
                      children: [
                        TextSpan(
                          text: '$value ',
                          style: TextStyle(
                            color: accentColor,
                            fontWeight: FontWeight.w600,
                            fontSize: isVerySmallScreen ? 13 : 16,
                          ),
                        ),
                        TextSpan(
                          text: 'registros 📈',
                          style: TextStyle(
                            color: Colors.blueGrey.shade600,
                            fontWeight: FontWeight.w400,
                            fontSize: isVerySmallScreen ? 11 : 14,
                          ),
                        ),
                      ],
                    );
                  }
                  return null;
                }).toList();
              },
            ),
            touchSpotThreshold: isVerySmallScreen ? 15 : 20,
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value >= 0 && value < data.length) {
                    String text = data.keys.elementAt(value.toInt());
                    if (isVerySmallScreen && text.length > 3) {
                      text = text.substring(0, 2);
                    } else if (text.length > 5) {
                      text = text.substring(0, 3);
                    }
                    return Container(
                      padding:
                          EdgeInsets.only(top: isVerySmallScreen ? 6.0 : 10.0),
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
                            size: isVerySmallScreen ? 8 : 12,
                            color: Colors.blueGrey.shade400,
                          ),
                          SizedBox(height: isVerySmallScreen ? 2 : 4),
                          Text(
                            text,
                            style: TextStyle(
                              color: Colors.blueGrey.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: isVerySmallScreen ? 8 : 12,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox();
                },
                reservedSize: isVerySmallScreen ? 35 : 50,
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
                    padding:
                        EdgeInsets.only(right: isVerySmallScreen ? 6.0 : 12.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.bar_chart,
                          size: isVerySmallScreen ? 6 : 10,
                          color: Colors.blueGrey.shade400,
                        ),
                        SizedBox(width: isVerySmallScreen ? 2 : 4),
                        Text(
                          value.toInt().toString(),
                          style: TextStyle(
                            color: Colors.blueGrey.shade600,
                            fontSize: isVerySmallScreen ? 8 : 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                },
                reservedSize: isVerySmallScreen ? 35 : 50,
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
              barWidth: isVerySmallScreen ? 3 : 4,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: isVerySmallScreen ? 4 : 6,
                    color: Colors.white,
                    strokeWidth: isVerySmallScreen ? 2 : 3,
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
                        padding: EdgeInsets.only(
                            right: isVerySmallScreen ? 4 : 8,
                            bottom: isVerySmallScreen ? 2 : 4),
                        style: TextStyle(
                          color: Colors.redAccent.withOpacity(0.8),
                          fontWeight: FontWeight.bold,
                          fontSize: isVerySmallScreen ? 8 : 10,
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
                        padding: EdgeInsets.only(
                            right: isVerySmallScreen ? 4 : 8,
                            bottom: isVerySmallScreen ? 2 : 4),
                        style: TextStyle(
                          color: Colors.amber.withOpacity(0.8),
                          fontWeight: FontWeight.bold,
                          fontSize: isVerySmallScreen ? 8 : 10,
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

  Widget _buildPieChart(
      Map<String, int> data, bool isSmallScreen, bool isVerySmallScreen) {
    return data.isEmpty
        ? Center(
            child: Text(
              "No hay datos disponibles",
              style: TextStyle(
                color: textColor,
                fontSize: isVerySmallScreen ? 12 : 14,
              ),
            ),
          )
        : PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  // Implementar interactividad si se desea
                },
                enabled: true,
              ),
              sectionsSpace: isVerySmallScreen ? 1 : 2,
              centerSpaceRadius: isVerySmallScreen ? 25 : 40,
              sections: _getSections(data, isVerySmallScreen),
            ),
          );
  }

  List<PieChartSectionData> _getSections(
      Map<String, int> data, bool isVerySmallScreen) {
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
        radius: isVerySmallScreen ? 70 : 100,
        titleStyle: TextStyle(
          fontSize: isVerySmallScreen ? 10 : 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        badgeWidget: _Badge(
          entry.key,
          size: isVerySmallScreen ? 25 : 40,
          borderColor: chartColors[index % chartColors.length],
          isVerySmallScreen: isVerySmallScreen,
        ),
        badgePositionPercentageOffset: isVerySmallScreen ? 1.1 : 1.2,
      );
    }).toList();
  }

  Widget _buildChartLegend(Map<String, int> data, bool isVerySmallScreen) {
    final total = data.values.fold(0, (sum, item) => sum + item);

    return Container(
      padding: EdgeInsets.symmetric(vertical: isVerySmallScreen ? 6 : 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  "Total de registros: $total",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    fontSize: isVerySmallScreen ? 11 : 14,
                  ),
                ),
              ),
              if (selectedGraph == "circular" && !isVerySmallScreen)
                const Text(
                  "Toca las secciones para más detalles",
                  style: TextStyle(
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),
          SizedBox(height: isVerySmallScreen ? 6 : 8),
          isVerySmallScreen
              ? SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: data.entries.map((entry) {
                      final index = data.keys.toList().indexOf(entry.key);
                      final color = chartColors[index % chartColors.length];

                      return Container(
                        margin: const EdgeInsets.only(right: 12),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              "${entry.key}: ${entry.value}",
                              style: TextStyle(
                                fontSize: 10,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                )
              : Wrap(
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

// ===== REEMPLAZAR MÉTODO _buildCloseButton() COMPLETO =====
  /// Construye los botones de acción (Descargar y Cerrar)
  Widget _buildCloseButton() {
    return Row(
      children: [
        // Botón de descarga
        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor, // Color amarillo-naranja distintivo
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 3,
            ),
            onPressed: _downloadChart, // Llamar al método de descarga
            icon: const Icon(Icons.download_rounded, size: 22),
            label: const Text(
              "Descargar Gráfica",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 15), // Espacio entre botones
        // Botón de cerrar
        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 3,
            ),
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded, size: 22),
            label: const Text(
              "Cerrar",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
// ===== FIN DEL REEMPLAZO =====
}
 
class _Badge extends StatelessWidget {
  final String title;
  final double size;
  final Color borderColor;
  final bool isVerySmallScreen;

  const _Badge(
    this.title, {
    Key? key,
    required this.size,
    required this.borderColor,
    this.isVerySmallScreen = false,
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
          width: isVerySmallScreen ? 1.5 : 2,
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
          title.length > (isVerySmallScreen ? 2 : 3)
              ? title.substring(0, isVerySmallScreen ? 2 : 3)
              : title,
          style: TextStyle(
            fontSize: isVerySmallScreen ? 7 : 10,
            fontWeight: FontWeight.bold,
            color: borderColor,
          ),
        ),
      ),
    );
  }
}
