import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'dart:async';

class ExcelExporter {
  // Definición de los campos que queremos exportar
  final List<Map<String, dynamic>> camposExportacion = [
    {'nombre': 'Nombre', 'campo': 'nombre'},
    {'nombre': 'Apellido', 'campo': 'apellido'},
    {'nombre': 'Teléfono', 'campo': 'telefono'},
    {'nombre': 'Edad', 'campo': 'edad'},
    {'nombre': 'Sexo', 'campo': 'sexo'},
    {'nombre': 'Estado Civil', 'campo': 'estadoCivil'},
    {'nombre': 'Dirección', 'campo': 'direccion'},
    {'nombre': 'Barrio', 'campo': 'barrio'},
    {'nombre': 'Nombre de Pareja', 'campo': 'nombrePareja'},
    {'nombre': 'Ocupaciones', 'campo': 'ocupaciones'},
    {'nombre': 'Descripción Ocupación', 'campo': 'descripcionOcupacion'},
    {'nombre': 'Referencia Invitación', 'campo': 'referenciaInvitacion'},
    {'nombre': 'Observaciones', 'campo': 'observaciones'},
    {'nombre': 'Estado Fonovisita', 'campo': 'estadoFonovisita'},
    {'nombre': 'Observaciones 2', 'campo': 'observaciones2'},
    {'nombre': 'Peticiones', 'campo': 'peticiones'},
    {'nombre': 'Estado en la Iglesia', 'campo': 'estadoProceso'},
    {'nombre': 'Activo', 'campo': 'activo'},
    {
      'nombre': 'Fecha de Nacimiento',
      'campo': 'fechaNacimiento'
    }, // ✅ NUEVO CAMPO
  ];

// ✅ MEJORADO: Método para obtener el valor de un campo con detección de variantes
  dynamic obtenerValorCampo(Map<String, dynamic> registro, String campo) {
    // Si el campo existe directamente, lo devolvemos
    if (registro.containsKey(campo)) {
      return registro[campo];
    }

    // ✅ MODIFICACIÓN: Detección especial para descripcionOcupacion
    if (campo == 'descripcionOcupacion') {
      // Buscar primero 'descripcionOcupacion', luego 'descripcionOcupaciones'
      if (registro.containsKey('descripcionOcupacion')) {
        return registro['descripcionOcupacion'];
      } else if (registro.containsKey('descripcionOcupaciones')) {
        return registro['descripcionOcupaciones'];
      }
    }

    // ✅ CORREGIDO: Detección especial para fechaNacimiento - manejo robusto de Timestamp
    if (campo == 'fechaNacimiento') {
      if (registro.containsKey('fechaNacimiento') &&
          registro['fechaNacimiento'] != null) {
        var fecha = registro['fechaNacimiento'];

        // Si es un Timestamp de Firebase, convertir a DateTime
        if (fecha is Timestamp) {
          return fecha.toDate();
        }
        // Si ya es DateTime, devolverlo directamente
        else if (fecha is DateTime) {
          return fecha;
        }
        // Si es String, intentar parsearlo
        else if (fecha is String) {
          try {
            return DateTime.parse(fecha);
          } catch (e) {
            print('Error al parsear fecha desde String: $e');
            return null;
          }
        }
        // Si es un Map (como puede venir de algunos casos de Firebase)
        else if (fecha is Map) {
          try {
            // Intentar extraer seconds si viene como Map
            if (fecha.containsKey('seconds')) {
              int seconds = fecha['seconds'];
              return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
            }
          } catch (e) {
            print('Error al procesar fecha desde Map: $e');
            return null;
          }
        }
      }
    }

    // Si no se encuentra el campo, devolver null
    return null;
  }

  // ✅ NUEVO: Método mejorado para ajustar ancho de columnas
  void ajustarAnchoColumnas(Sheet sheet, {bool incluirCoordinador = false}) {
    int offset = incluirCoordinador ? 1 : 0;

    if (incluirCoordinador) {
      sheet.setColWidth(0, 25); // Coordinador
    }

    for (var i = 0; i < camposExportacion.length; i++) {
      String nombreCampo = camposExportacion[i]['nombre'] as String;
      String campo = camposExportacion[i]['campo'] as String;

      // Calcular ancho base según el nombre del campo
      int anchoBase = nombreCampo.length + 3;

      // Ajustes especiales según el tipo de campo
      int anchoFinal;
      switch (campo) {
        case 'nombre':
        case 'apellido':
        case 'direccion':
          anchoFinal = anchoBase < 18 ? 18 : (anchoBase > 30 ? 30 : anchoBase);
          break;
        case 'telefono':
          anchoFinal = 15;
          break;
        case 'fechaNacimiento':
          anchoFinal = 18; // Para formato DD/MM/YYYY
          break;
        case 'descripcionOcupacion':
        case 'observaciones':
        case 'observaciones2':
        case 'referenciaInvitacion':
          anchoFinal = anchoBase < 20 ? 20 : (anchoBase > 35 ? 35 : anchoBase);
          break;
        case 'ocupaciones':
        case 'peticiones':
          anchoFinal = anchoBase < 25 ? 25 : (anchoBase > 40 ? 40 : anchoBase);
          break;
        default:
          anchoFinal = anchoBase < 12 ? 12 : (anchoBase > 32 ? 32 : anchoBase);
      }

      sheet.setColWidth(i + offset, anchoFinal.toDouble());
    }
  }

// ✅ CORREGIDO: Método mejorado para formatear valores con manejo robusto de fechas
  String formatearValor(dynamic value, String fieldName) {
    if (value == null) {
      return '';
    } else if (value is List) {
      return value.join(', ');
    } else if (fieldName == 'activo') {
      return value == true ? 'Sí' : 'No';
    } else if (fieldName == 'fechaNacimiento') {
      // Manejar diferentes tipos de fecha
      DateTime? fechaDateTime;

      if (value is Timestamp) {
        fechaDateTime = value.toDate();
      } else if (value is DateTime) {
        fechaDateTime = value;
      } else if (value is String) {
        try {
          fechaDateTime = DateTime.parse(value);
        } catch (e) {
          return value
              .toString(); // Si no se puede parsear, mostrar el string original
        }
      } else {
        return value
            .toString(); // Para cualquier otro tipo, mostrar como string
      }

      // Formatear fecha como DD/MM/YYYY (solo la fecha de nacimiento)
      if (fechaDateTime != null) {
        return '${fechaDateTime.day.toString().padLeft(2, '0')}/${fechaDateTime.month.toString().padLeft(2, '0')}/${fechaDateTime.year}';
      } else {
        return '';
      }
    } else {
      return value.toString();
    }
  }

  Future<void> exportarRegistros(
    BuildContext context,
    String tribuId,
    String tribuNombre, {
    String? anioFiltro,
    String? mesFiltro,
  }) async {
    try {
      // Crear un nuevo libro de Excel
      final excel = Excel.createExcel();

      // Eliminar la hoja por defecto "Sheet1"
      if (excel.sheets.containsKey('Sheet1')) {
        excel.delete('Sheet1');
      }

      // Obtener registros filtrados por tribu
      // ✅ MODIFICADO: Obtener registros filtrados por tribu
      var query = FirebaseFirestore.instance
          .collection('registros')
          .where('tribuAsignada', isEqualTo: tribuId);

// ✅ NUEVO: Aplicar filtro de año si está activo
      if (anioFiltro != null && anioFiltro != 'Todos') {
        int anio = int.parse(anioFiltro);
        DateTime inicioAnio = DateTime(anio, 1, 1);
        DateTime finAnio = DateTime(anio, 12, 31, 23, 59, 59);

        query = query.where('fechaAsignacionTribu',
            isGreaterThanOrEqualTo: Timestamp.fromDate(inicioAnio),
            isLessThanOrEqualTo: Timestamp.fromDate(finAnio));
      }

      final registrosSnapshot = await query.get();

// ✅ NUEVO: Aplicar filtro de mes en memoria si está activo
      List<QueryDocumentSnapshot<Map<String, dynamic>>> registrosFiltrados =
          registrosSnapshot.docs;

      if (mesFiltro != null && mesFiltro != 'Todos') {
        int mes = int.parse(mesFiltro);
        registrosFiltrados = registrosFiltrados.where((doc) {
          final data = doc.data();
          final fechaTribu = data['fechaAsignacionTribu'] as Timestamp?;
          final fechaAsignacion = data['fechaAsignacion'] as Timestamp?;

          DateTime? fecha;
          if (fechaTribu != null) {
            fecha = fechaTribu.toDate();
          } else if (fechaAsignacion != null) {
            fecha = fechaAsignacion.toDate();
          }

          if (fecha == null) return false;

          // Verificar año y mes si está especificado
          if (anioFiltro != null && anioFiltro != 'Todos') {
            return fecha.year == int.parse(anioFiltro) && fecha.month == mes;
          } else {
            return fecha.month == mes;
          }
        }).toList();
      }

// ✅ MODIFICADO: Usar registrosFiltrados en lugar de registrosSnapshot.docs
      if (registrosFiltrados.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.info, color: Colors.white),
                  SizedBox(width: 12),
                  Text('No hay registros para exportar'),
                ],
              ),
              backgroundColor: Colors.blue,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      // MEJORA 1: Obtener nombres reales de coordinadores de manera más eficiente
      // Preparar para obtener los nombres reales de los coordinadores
      Map<String, String> coordinadoresCache = {};

      // Obtener todos los IDs de coordinadores primero para hacer batch query
      Set<String> coordinadorIds = {};

      // Recopilar todos los IDs de coordinadores primero
      for (var doc in registrosFiltrados) {
        final data = doc.data() as Map<String, dynamic>;
        final coordinadorId = data['coordinadorAsignado'] ?? 'Sin Coordinador';
        if (coordinadorId != 'Sin Coordinador') {
          coordinadorIds.add(coordinadorId);
        }
      }

      // Recuperar la información de todos los coordinadores de una vez
      if (coordinadorIds.isNotEmpty) {
        try {
          // Obtener todos los documentos de coordinadores en lotes para evitar muchas consultas
          // Dividir en batches de 10 para evitar limitaciones de Firebase
          final List<String> coordinadorIdsList = coordinadorIds.toList();
          for (int i = 0; i < coordinadorIdsList.length; i += 10) {
            final int endIndex = (i + 10 < coordinadorIdsList.length)
                ? i + 10
                : coordinadorIdsList.length;
            final List<String> batchIds =
                coordinadorIdsList.sublist(i, endIndex);

            final coordinadoresQuery = await FirebaseFirestore.instance
                .collection('coordinadores')
                .where(FieldPath.documentId, whereIn: coordinadorIds.toList())
                .get();

            // Guardar en caché los nombres completos de los coordinadores
            for (var coordDoc in coordinadoresQuery.docs) {
              final coordData = coordDoc.data() as Map<String, dynamic>;
              String nombreCompleto = coordDoc.id; // Por defecto, usar el ID

              // Comprobar si existen los campos nombre y apellido
              if (coordData.containsKey('nombre')) {
                if (coordData.containsKey('apellido')) {
                  nombreCompleto =
                      '${coordData['nombre']} ${coordData['apellido']}';
                } else {
                  nombreCompleto = coordData['nombre'];
                }
              }

              coordinadoresCache[coordDoc.id] = nombreCompleto;
            }
          }
        } catch (e) {
          print('Error al obtener nombres de coordinadores: $e');
          // En caso de error, se usarán los IDs como nombres
        }
      }

      // ✅ Separar registros activos y no activos
      List<Map<String, dynamic>> registrosActivos = [];
      List<Map<String, dynamic>> registrosNoActivos = [];

      // CORRECCIÓN: Procesar todos los registros y separarlos por estado activo
      for (var doc in registrosFiltrados) {
        final data = doc.data();

        // Añadir el ID del documento a los datos
        data['id'] = doc.id;

        final coordinadorId = data['coordinadorAsignado'] ?? 'Sin Coordinador';

        // Obtener el nombre real si está en el cache, de lo contrario usar "Sin Coordinador" o el ID
        String nombreCoordinador;
        if (coordinadorId != 'Sin Coordinador' &&
            coordinadoresCache.containsKey(coordinadorId)) {
          nombreCoordinador = coordinadoresCache[coordinadorId]!;
        } else if (coordinadorId == 'Sin Coordinador') {
          nombreCoordinador = 'Sin Coordinador';
        } else {
          nombreCoordinador =
              coordinadorId; // Si no hay nombre, usar el ID como fallback
        }

        // CORRECCIÓN: Reemplazar el ID del coordinador con su nombre real en los datos
        data['coordinadorAsignado'] = nombreCoordinador;

        // ✅ Separar registros según estado activo
        if (data['activo'] == true) {
          registrosActivos.add(data);
        } else {
          registrosNoActivos.add(data);
        }
      }

      // Agrupar registros ACTIVOS por coordinador usando nombres reales
      Map<String, List<Map<String, dynamic>>> registrosActivosPorCoordinador =
          {};

      for (var registro in registrosActivos) {
        final nombreCoordinador = registro['coordinadorAsignado'];

        if (!registrosActivosPorCoordinador.containsKey(nombreCoordinador)) {
          registrosActivosPorCoordinador[nombreCoordinador] = [];
        }

        registrosActivosPorCoordinador[nombreCoordinador]!.add(registro);
      }

      // Crear una hoja de resumen
      final resumenSheet = excel['Resumen'];

      // Estilo para encabezados
      var headerStyle = CellStyle(
        backgroundColorHex: '#1B998B',
        fontColorHex: '#FFFFFF',
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
      );

      // Estilo para filas alternas
      var alternateCellStyle = CellStyle(
        backgroundColorHex: '#E6F3F1',
      );

      // Añadir título al resumen
      var cellTitulo = resumenSheet.cell(CellIndex.indexByString('A1'));
      cellTitulo.value = 'Resumen de Registros - Tribu $tribuNombre';
      cellTitulo.cellStyle = CellStyle(
        bold: true,
        fontSize: 14,
        horizontalAlign: HorizontalAlign.Center,
      );

      // Combinar celdas para el título
      resumenSheet.merge(
          CellIndex.indexByString('A1'), CellIndex.indexByString('C1'));

      // Añadir fecha de exportación
      var cellFecha = resumenSheet.cell(CellIndex.indexByString('A2'));
      cellFecha.value =
          'Fecha de exportación: ${DateTime.now().toString().substring(0, 16)}';
      resumenSheet.merge(
          CellIndex.indexByString('A2'), CellIndex.indexByString('C2'));

      // Encabezados de resumen
      var headerRow = ['Hoja', 'Total de Registros'];
      for (var i = 0; i < headerRow.length; i++) {
        var cell = resumenSheet
            .cell(CellIndex.indexByString('${String.fromCharCode(65 + i)}4'));
        cell.value = headerRow[i];
        cell.cellStyle = headerStyle;
      }

      // Datos del resumen
      int fila = 5;
      int totalRegistrosActivos = 0;

      // ✅ Resumen de registros activos por coordinador
      registrosActivosPorCoordinador.forEach((coordinador, registros) {
        var cellCoord = resumenSheet.cell(CellIndex.indexByString('A$fila'));
        cellCoord.value = coordinador;

        var cellTotal = resumenSheet.cell(CellIndex.indexByString('B$fila'));
        cellTotal.value = registros.length;

        // Aplicar estilo para filas alternas
        if (fila % 2 == 1) {
          cellCoord.cellStyle = alternateCellStyle;
          cellTotal.cellStyle = alternateCellStyle;
        }

        totalRegistrosActivos += registros.length;
        fila++;
      });

      // ✅ Añadir fila para registros no activos
      var cellNoActivos = resumenSheet.cell(CellIndex.indexByString('A$fila'));
      cellNoActivos.value = 'No Activos';
      var cellTotalNoActivos =
          resumenSheet.cell(CellIndex.indexByString('B$fila'));
      cellTotalNoActivos.value = registrosNoActivos.length;

      if (fila % 2 == 1) {
        cellNoActivos.cellStyle = alternateCellStyle;
        cellTotalNoActivos.cellStyle = alternateCellStyle;
      }
      fila++;

      // Añadir total general
      var cellTotalLabel =
          resumenSheet.cell(CellIndex.indexByString('A${fila + 1}'));
      cellTotalLabel.value = 'TOTAL GENERAL';
      cellTotalLabel.cellStyle = CellStyle(bold: true);

      var cellTotalValue =
          resumenSheet.cell(CellIndex.indexByString('B${fila + 1}'));
      cellTotalValue.value = totalRegistrosActivos + registrosNoActivos.length;
      cellTotalValue.cellStyle = CellStyle(bold: true);

      // Ajustar ancho de columnas en hoja de resumen
      resumenSheet.setColWidth(0, 25); // Ancho aproximado de 200px
      resumenSheet.setColWidth(1, 19); // Ancho aproximado de 150px

      // Crear hojas en el Excel para cada coordinador (SOLO REGISTROS ACTIVOS)
      registrosActivosPorCoordinador.forEach((coordinador, registros) {
        // Crear una hoja para cada coordinador (limitar nombre a 31 caracteres para Excel)
        String sheetName = coordinador.length > 25
            ? '${coordinador.substring(0, 25)}...'
            : coordinador;

        // Asegurarse de que el nombre de la hoja sea único
        int counter = 1;
        String finalSheetName = sheetName;
        while (excel.sheets.containsKey(finalSheetName)) {
          finalSheetName = '${sheetName}_$counter';
          counter++;
        }

        final sheet = excel[finalSheetName];

        // Añadir título
        var cellSheetTitulo = sheet.cell(CellIndex.indexByString('A1'));
        cellSheetTitulo.value =
            'Registros de $coordinador - Tribu $tribuNombre';
        cellSheetTitulo.cellStyle = CellStyle(
          bold: true,
          fontSize: 14,
          horizontalAlign: HorizontalAlign.Center,
        );

        // Combinar celdas para el título (desde A1 hasta la última columna)
        int lastColumnIndex = camposExportacion.length - 1;
        String lastColumn =
            String.fromCharCode(65 + (lastColumnIndex > 25 ? 1 : 0)) +
                (lastColumnIndex > 25
                    ? String.fromCharCode(65 + (lastColumnIndex % 26))
                    : String.fromCharCode(65 + lastColumnIndex));
        sheet.merge(CellIndex.indexByString('A1'),
            CellIndex.indexByString('${lastColumn}1'));

        // Encabezados de columnas (fila 3)
        List<String> headers = camposExportacion
            .map((campo) => campo['nombre'] as String)
            .toList();
        for (var i = 0; i < headers.length; i++) {
          String columnLetter = i > 25
              ? '${String.fromCharCode(65 + (i ~/ 26) - 1)}${String.fromCharCode(65 + (i % 26))}'
              : String.fromCharCode(65 + i);

          var cell = sheet.cell(CellIndex.indexByString('${columnLetter}3'));
          cell.value = headers[i];
          cell.cellStyle = headerStyle;
        }

        // Datos
        int rowIndex = 4;
        for (var registro in registros) {
          for (var i = 0; i < camposExportacion.length; i++) {
            String columnLetter = i > 25
                ? '${String.fromCharCode(65 + (i ~/ 26) - 1)}${String.fromCharCode(65 + (i % 26))}'
                : String.fromCharCode(65 + i);

            var cell =
                sheet.cell(CellIndex.indexByString('$columnLetter$rowIndex'));
            var fieldName = camposExportacion[i]['campo'] as String;

            // ✅ USAR EL NUEVO MÉTODO PARA OBTENER EL VALOR
            var value = obtenerValorCampo(registro, fieldName);

            // ✅ USAR EL NUEVO MÉTODO PARA FORMATEAR VALOR
            cell.value = formatearValor(value, fieldName);

            // Aplicar estilo para filas alternas
            if (rowIndex % 2 == 0) {
              cell.cellStyle = alternateCellStyle;
            }
          }
          rowIndex++;
        }

        // ✅ USAR MÉTODO MEJORADO PARA AJUSTAR COLUMNAS
        ajustarAnchoColumnas(sheet);

        // En lugar de freezeRows, podemos usar una configuración de estilo para destacar la fila de encabezados
        // Asegurando que todas las celdas de la fila de encabezados tengan el estilo adecuado
        for (var i = 0; i < camposExportacion.length; i++) {
          String columnLetter = i > 25
              ? '${String.fromCharCode(65 + (i ~/ 26) - 1)}${String.fromCharCode(65 + (i % 26))}'
              : String.fromCharCode(65 + i);

          var headerCell =
              sheet.cell(CellIndex.indexByString('${columnLetter}3'));
          headerCell.cellStyle = headerStyle;
        }
      });

      // ✅ Crear hoja con todos los registros ACTIVOS
      final allSheet = excel['Todos los Registros Activos'];

      // Añadir título
      var cellAllTitulo = allSheet.cell(CellIndex.indexByString('A1'));
      cellAllTitulo.value = 'Todos los Registros Activos - Tribu $tribuNombre';
      cellAllTitulo.cellStyle = CellStyle(
        bold: true,
        fontSize: 14,
        horizontalAlign: HorizontalAlign.Center,
      );

      // Combinar celdas para el título
      int lastAllColumnIndex = camposExportacion.length;
      String lastAllColumn =
          String.fromCharCode(65 + (lastAllColumnIndex > 25 ? 1 : 0)) +
              (lastAllColumnIndex > 25
                  ? String.fromCharCode(65 + (lastAllColumnIndex % 26))
                  : String.fromCharCode(65 + lastAllColumnIndex));
      allSheet.merge(CellIndex.indexByString('A1'),
          CellIndex.indexByString('${lastAllColumn}1'));

      // Encabezados de columnas (añadiendo Coordinador al inicio)
      List<String> allHeaders = ['Coordinador'] +
          camposExportacion.map((campo) => campo['nombre'] as String).toList();
      for (var i = 0; i < allHeaders.length; i++) {
        String columnLetter = i > 25
            ? '${String.fromCharCode(65 + (i ~/ 26) - 1)}${String.fromCharCode(65 + (i % 26))}'
            : String.fromCharCode(65 + i);

        var cell = allSheet.cell(CellIndex.indexByString('${columnLetter}3'));
        cell.value = allHeaders[i];
        cell.cellStyle = headerStyle;
      }

      // CORRECCIÓN: Datos de todos los registros ACTIVOS, usando el nombre real del coordinador
      int allRowIndex = 4;
      registrosActivosPorCoordinador.forEach((coordinador, registros) {
        for (var registro in registros) {
          // Añadir coordinador con su nombre real (esto ya está en "coordinador")
          var cellCoord =
              allSheet.cell(CellIndex.indexByString('A$allRowIndex'));
          cellCoord.value = coordinador; // Ya tenemos el nombre real aquí

          // Añadir datos del registro
          for (var i = 0; i < camposExportacion.length; i++) {
            String columnLetter = (i + 1) > 25
                ? '${String.fromCharCode(65 + ((i + 1) ~/ 26) - 1)}${String.fromCharCode(65 + ((i + 1) % 26))}'
                : String.fromCharCode(65 + (i + 1));

            var cell = allSheet
                .cell(CellIndex.indexByString('$columnLetter$allRowIndex'));
            var fieldName = camposExportacion[i]['campo'] as String;

            // ✅ USAR EL NUEVO MÉTODO PARA OBTENER EL VALOR
            var value = obtenerValorCampo(registro, fieldName);

            // ✅ USAR EL NUEVO MÉTODO PARA FORMATEAR VALOR
            cell.value = formatearValor(value, fieldName);

            // Aplicar estilo para filas alternas
            if (allRowIndex % 2 == 0) {
              cell.cellStyle = alternateCellStyle;
              cellCoord.cellStyle = alternateCellStyle;
            }
          }
          allRowIndex++;
        }
      });

      // ✅ USAR MÉTODO MEJORADO PARA AJUSTAR COLUMNAS
      ajustarAnchoColumnas(allSheet, incluirCoordinador: true);

      // En lugar de freezeRows/freezeColumns, aplicamos un estilo destacado
      // Asegurando que todas las celdas de la fila de encabezados tengan el estilo adecuado
      for (var i = 0; i < allHeaders.length; i++) {
        String columnLetter = i > 25
            ? '${String.fromCharCode(65 + (i ~/ 26) - 1)}${String.fromCharCode(65 + (i % 26))}'
            : String.fromCharCode(65 + i);

        var headerCell =
            allSheet.cell(CellIndex.indexByString('${columnLetter}3'));
        headerCell.cellStyle = headerStyle;
      }

      // ✅ Crear hoja exclusiva para registros NO ACTIVOS
      if (registrosNoActivos.isNotEmpty) {
        final noActivosSheet = excel['No Activos'];

        // Añadir título
        var cellNoActivosTitulo =
            noActivosSheet.cell(CellIndex.indexByString('A1'));
        cellNoActivosTitulo.value = 'Registros No Activos - Tribu $tribuNombre';
        cellNoActivosTitulo.cellStyle = CellStyle(
          bold: true,
          fontSize: 14,
          horizontalAlign: HorizontalAlign.Center,
          backgroundColorHex: '#FF6B6B', // Color rojo suave para diferenciar
          fontColorHex: '#FFFFFF',
        );

        // Combinar celdas para el título
        int lastNoActivosColumnIndex = camposExportacion.length;
        String lastNoActivosColumn =
            String.fromCharCode(65 + (lastNoActivosColumnIndex > 25 ? 1 : 0)) +
                (lastNoActivosColumnIndex > 25
                    ? String.fromCharCode(65 + (lastNoActivosColumnIndex % 26))
                    : String.fromCharCode(65 + lastNoActivosColumnIndex));
        noActivosSheet.merge(CellIndex.indexByString('A1'),
            CellIndex.indexByString('${lastNoActivosColumn}1'));

        // Estilo especial para encabezados de no activos
        var headerNoActivosStyle = CellStyle(
          backgroundColorHex: '#FF6B6B',
          fontColorHex: '#FFFFFF',
          bold: true,
          horizontalAlign: HorizontalAlign.Center,
        );

        // Encabezados de columnas (añadiendo Coordinador al inicio)
        List<String> noActivosHeaders = ['Coordinador'] +
            camposExportacion
                .map((campo) => campo['nombre'] as String)
                .toList();
        for (var i = 0; i < noActivosHeaders.length; i++) {
          String columnLetter = i > 25
              ? '${String.fromCharCode(65 + (i ~/ 26) - 1)}${String.fromCharCode(65 + (i % 26))}'
              : String.fromCharCode(65 + i);

          var cell =
              noActivosSheet.cell(CellIndex.indexByString('${columnLetter}3'));
          cell.value = noActivosHeaders[i];
          cell.cellStyle = headerNoActivosStyle;
        }

        // Datos de registros no activos
        int noActivosRowIndex = 4;
        for (var registro in registrosNoActivos) {
          // Añadir coordinador
          var cellCoord = noActivosSheet
              .cell(CellIndex.indexByString('A$noActivosRowIndex'));
          cellCoord.value = registro['coordinadorAsignado'];

          // Añadir datos del registro
          for (var i = 0; i < camposExportacion.length; i++) {
            String columnLetter = (i + 1) > 25
                ? '${String.fromCharCode(65 + ((i + 1) ~/ 26) - 1)}${String.fromCharCode(65 + ((i + 1) % 26))}'
                : String.fromCharCode(65 + (i + 1));

            var cell = noActivosSheet.cell(
                CellIndex.indexByString('$columnLetter$noActivosRowIndex'));
            var fieldName = camposExportacion[i]['campo'] as String;

            // ✅ USAR EL NUEVO MÉTODO PARA OBTENER EL VALOR
            var value = obtenerValorCampo(registro, fieldName);

            // ✅ USAR EL NUEVO MÉTODO PARA FORMATEAR VALOR
            cell.value = formatearValor(value, fieldName);

            // Aplicar estilo para filas alternas con color suave
            if (noActivosRowIndex % 2 == 0) {
              var noActivosAlternateStyle = CellStyle(
                backgroundColorHex: '#FFE5E5', // Color rosa muy suave
              );
              cell.cellStyle = noActivosAlternateStyle;
              cellCoord.cellStyle = noActivosAlternateStyle;
            }
          }
          noActivosRowIndex++;
        }

        // ✅ USAR MÉTODO MEJORADO PARA AJUSTAR COLUMNAS
        ajustarAnchoColumnas(noActivosSheet, incluirCoordinador: true);
      }

      // MEJORA 2: Solución al problema de descarga duplicada
      // CORRECCIÓN: Uso de bytes.encode() en lugar de bytes.save() para evitar descargas múltiples
      final bytes = excel.encode();
      if (bytes != null) {
        // Crear un único blob con los datos del Excel
        final blob = html.Blob([
          Uint8List.fromList(bytes)
        ], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
        final url = html.Url.createObjectUrlFromBlob(blob);

        // Crear un elemento de enlace invisible con el nombre de archivo correcto
        final anchor = html.AnchorElement(href: url)
          ..setAttribute(
              'download', 'Datos de las personas - $tribuNombre.xlsx')
          ..style.display = 'none';

        // Añadir al DOM, hacer clic y luego remover para evitar múltiples descargas
        html.document.body?.append(anchor);
        anchor.click();

        // Importante: remover del DOM después de usar y revocar la URL del objeto
        // para liberar recursos y evitar fugas de memoria
        Future.delayed(Duration.zero, () {
          anchor.remove();
          html.Url.revokeObjectUrl(url);
        });

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Text(
                      'Archivo "Datos de las personas - $tribuNombre.xlsx" descargado correctamente'),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Error al generar el archivo Excel'),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        throw Exception('No se pudo generar el archivo Excel');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 12),
                Text('Error: $e'),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      print('Error en exportarRegistros: $e');
    }
  }
}
