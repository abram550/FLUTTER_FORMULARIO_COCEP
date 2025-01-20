import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:universal_html/html.dart' as html;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/registro.dart';
import 'package:excel/excel.dart';

class ExcelService {
  Future<String> exportarRegistros(List<Registro> registros,
      {String? prefix}) async {
    final excel = Excel.createExcel();
    excel.delete('Sheet1');

    final nuevosRegistros =
        registros.where((r) => r.tipo?.toLowerCase() == 'nuevo').toList();
    final visitasRegistros =
        registros.where((r) => r.tipo?.toLowerCase() == 'visita').toList();

    if (nuevosRegistros.isNotEmpty) {
      _configurarHoja(excel, 'Nuevos', nuevosRegistros, [
        'Fecha',
        'Nombre',
        'Apellido',
        'Edad',
        'Sexo',
        'Teléfono',
        'Dirección',
        'Barrio',
        'Estado Civil',
        'Nombre Pareja',
        'Tiene Hijos',
        'Ocupaciones',
        'Referencia',
        'Observaciones',
        'Consolidador'
      ]);
    }

    if (visitasRegistros.isNotEmpty) {
      _configurarHoja(excel, 'Visitas', visitasRegistros, [
        'Fecha',
        'Nombre',
        'Apellido',
        'Teléfono',
        'Servicio',
        'Motivo',
        'Peticiones',
        'Consolidador'
      ]);
    }

    if (nuevosRegistros.isEmpty && visitasRegistros.isEmpty) {
      throw Exception('No hay registros para exportar');
    }

    final String fileName =
        '${prefix ?? 'registros'}_${DateTime.now().millisecondsSinceEpoch}.xlsx';

    return kIsWeb
        ? _exportarWeb(excel, fileName)
        : await _exportarMobile(excel, fileName);
  }

  void _configurarHoja(Excel excel, String sheetName, List<Registro> registros,
      List<String> headers) {
    final sheet = excel[sheetName];

    // Estilos para encabezados
    final headerStyle = CellStyle(
        backgroundColorHex: '#1F497D', // Azul oscuro profesional
        fontColorHex: '#FFFFFF', // Texto blanco
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center);

    // Estilos para filas de datos
    final dataStyleEven = CellStyle(
        backgroundColorHex: '#F2F2F2', // Gris claro para filas pares
        horizontalAlign: HorizontalAlign.Left,
        verticalAlign: VerticalAlign.Center);

    final dataStyleOdd = CellStyle(
        backgroundColorHex: '#FFFFFF', // Blanco para filas impares
        horizontalAlign: HorizontalAlign.Left,
        verticalAlign: VerticalAlign.Center);

    // Configurar encabezados
    for (var i = 0; i < headers.length; i++) {
      final cell =
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = headers[i];
      cell.cellStyle = headerStyle;
    }

    // Agregar datos con estilo alternado
    for (var i = 0; i < registros.length; i++) {
      final registro = registros[i];
      final rowIndex = i + 1;
      final isEvenRow = rowIndex % 2 == 0;

      List<dynamic> rowData;
      if (sheetName == 'Nuevos') {
        rowData = [
          _formatDate(registro.fecha),
          registro.nombre,
          registro.apellido,
          registro.edad?.toString() ?? '',
          registro.sexo,
          registro.telefono,
          registro.direccion,
          registro.barrio,
          registro.estadoCivil,
          registro.nombrePareja ?? '',
          registro.tieneHijos ? 'Sí' : 'No',
          registro.ocupaciones.join(', '),
          registro.referenciaInvitacion,
          registro.observaciones ?? '',
          registro.consolidador ?? ''
        ];
      } else {
        rowData = [
          _formatDate(registro.fecha),
          registro.nombre,
          registro.apellido,
          registro.telefono,
          registro.servicio ?? '',
          registro.motivo ?? '',
          registro.peticiones ?? '',
          registro.consolidador ?? ''
        ];
      }

      for (var j = 0; j < rowData.length; j++) {
        final cell = sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: j, rowIndex: rowIndex));
        cell.value = rowData[j];
        cell.cellStyle = isEvenRow ? dataStyleEven : dataStyleOdd;
      }
    }

    // Ajustar ancho de columnas automáticamente
    for (var i = 0; i < headers.length; i++) {
      sheet.setColWidth(i, 15.0); // Ancho base de 15 unidades
    }
  }

  String _exportarWeb(Excel excel, String fileName) {
    final bytes = excel.save();
    if (bytes == null) throw Exception('Error al codificar el archivo Excel');

    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..click();
    html.Url.revokeObjectUrl(url);
    return fileName;
  }

  Future<String> _exportarMobile(Excel excel, String fileName) async {
    Directory? directory;
    if (Platform.isAndroid) {
      directory = Directory('/storage/emulated/0/Download');
      if (!await directory.exists()) {
        directory = await getExternalStorageDirectory();
      }
    } else if (Platform.isIOS) {
      directory = await getApplicationDocumentsDirectory();
    }

    if (directory == null) {
      throw Exception('No se pudo acceder al directorio de almacenamiento');
    }

    final String filePath = '${directory.path}/$fileName';
    final file = File(filePath);

    final bytes = excel.save();
    if (bytes == null) throw Exception('Error al codificar el archivo Excel');

    await file.writeAsBytes(bytes);
    return filePath;
  }

  String _formatDate(DateTime? fecha) {
    if (fecha == null) return '';
    return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
  }
}
