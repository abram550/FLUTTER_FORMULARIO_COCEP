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
  ];

  Future<void> exportarRegistros(
      BuildContext context, String tribuId, String tribuNombre) async {
    try {
      // Crear un nuevo libro de Excel
      final excel = Excel.createExcel();

      // Eliminar la hoja por defecto "Sheet1"
      if (excel.sheets.containsKey('Sheet1')) {
        excel.delete('Sheet1');
      }

      // Obtener registros filtrados por tribu
      final registrosSnapshot = await FirebaseFirestore.instance
          .collection('registros')
          .where('tribuAsignada', isEqualTo: tribuId)
          .get();

      if (registrosSnapshot.docs.isEmpty) {
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
      for (var doc in registrosSnapshot.docs) {
        final data = doc.data();
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
              final coordData = coordDoc.data();
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

      // Agrupar registros por coordinador usando nombres reales
      Map<String, List<Map<String, dynamic>>> registrosPorCoordinador = {};

      // CORRECCIÓN: Reemplazar el ID del coordinador con su nombre real en todos los registros
      for (var doc in registrosSnapshot.docs) {
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
        // para asegurar que se use el nombre en todos los lugares
        data['coordinadorAsignado'] = nombreCoordinador;

        // Usar el nombre real del coordinador como clave para agrupar
        if (!registrosPorCoordinador.containsKey(nombreCoordinador)) {
          registrosPorCoordinador[nombreCoordinador] = [];
        }

        registrosPorCoordinador[nombreCoordinador]!.add(data);
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
      var headerRow = ['Coordinador', 'Total de Registros'];
      for (var i = 0; i < headerRow.length; i++) {
        var cell = resumenSheet
            .cell(CellIndex.indexByString('${String.fromCharCode(65 + i)}4'));
        cell.value = headerRow[i];
        cell.cellStyle = headerStyle;
      }

      // Datos del resumen
      int fila = 5;
      int totalRegistros = 0;

      registrosPorCoordinador.forEach((coordinador, registros) {
        var cellCoord = resumenSheet.cell(CellIndex.indexByString('A$fila'));
        cellCoord.value = coordinador;

        var cellTotal = resumenSheet.cell(CellIndex.indexByString('B$fila'));
        cellTotal.value = registros.length;

        // Aplicar estilo para filas alternas
        if (fila % 2 == 1) {
          cellCoord.cellStyle = alternateCellStyle;
          cellTotal.cellStyle = alternateCellStyle;
        }

        totalRegistros += registros.length;
        fila++;
      });

      // Añadir total general
      var cellTotalLabel =
          resumenSheet.cell(CellIndex.indexByString('A${fila + 1}'));
      cellTotalLabel.value = 'TOTAL GENERAL';
      cellTotalLabel.cellStyle = CellStyle(bold: true);

      var cellTotalValue =
          resumenSheet.cell(CellIndex.indexByString('B${fila + 1}'));
      cellTotalValue.value = totalRegistros;
      cellTotalValue.cellStyle = CellStyle(bold: true);

      // Ajustar ancho de columnas en hoja de resumen mediante setColWidth
      resumenSheet.setColWidth(0, 25); // Ancho aproximado de 200px
      resumenSheet.setColWidth(1, 19); // Ancho aproximado de 150px

      // Crear hojas en el Excel para cada coordinador
      registrosPorCoordinador.forEach((coordinador, registros) {
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
            var value = registro[fieldName];

            // Formatear valor según el tipo
            if (value == null) {
              cell.value = '';
            } else if (value is List) {
              cell.value = value.join(', ');
            } else {
              cell.value = value.toString();
            }

            // Aplicar estilo para filas alternas
            if (rowIndex % 2 == 0) {
              cell.cellStyle = alternateCellStyle;
            }
          }
          rowIndex++;
        }

        // Ajustar ancho de columnas (usando setColWidth en lugar de setColumnWidth)
        for (var i = 0; i < camposExportacion.length; i++) {
          // Calcular el ancho basado en el nombre del campo (mínimo 12, máximo 32)
          // Nota: los valores son aproximados ya que la escala es diferente
          int ancho = (camposExportacion[i]['nombre'] as String).length + 3;
          ancho = ancho < 12 ? 12 : (ancho > 32 ? 32 : ancho);
          sheet.setColWidth(i, ancho.toDouble());
        }

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

      // Crear una hoja con todos los registros juntos
      final allSheet = excel['Todos los Registros'];

      // Añadir título
      var cellAllTitulo = allSheet.cell(CellIndex.indexByString('A1'));
      cellAllTitulo.value = 'Todos los Registros - Tribu $tribuNombre';
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

      // CORRECCIÓN: Datos de todos los registros, usando el nombre real del coordinador
      int allRowIndex = 4;
      registrosPorCoordinador.forEach((coordinador, registros) {
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
            var value = registro[fieldName];

            // Formatear valor
            if (value == null) {
              cell.value = '';
            } else if (value is List) {
              cell.value = value.join(', ');
            } else {
              cell.value = value.toString();
            }

            // Aplicar estilo para filas alternas
            if (allRowIndex % 2 == 0) {
              cell.cellStyle = alternateCellStyle;
              cellCoord.cellStyle = alternateCellStyle;
            }
          }
          allRowIndex++;
        }
      });

      // Ajustar ancho de columnas (usando setColWidth en lugar de setColumnWidth)
      allSheet.setColWidth(0, 25); // Coordinador (aproximadamente 200px)
      for (var i = 0; i < camposExportacion.length; i++) {
        // Calcular el ancho basado en el nombre del campo (mínimo 12, máximo 32)
        int ancho = (camposExportacion[i]['nombre'] as String).length + 3;
        ancho = ancho < 12 ? 12 : (ancho > 32 ? 32 : ancho);
        allSheet.setColWidth(i + 1, ancho.toDouble());
      }

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
