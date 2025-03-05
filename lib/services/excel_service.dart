import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:universal_html/html.dart' as html;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';
import '../models/registro.dart';
import '../models/social_profile.dart';

class ExcelService {
  Future<String> exportarRegistros(
      List<Registro> registros, List<SocialProfile> perfiles,
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

    if (perfiles.isNotEmpty) {
      _configurarHojaPerfiles(excel, 'Perfiles Sociales', perfiles, [
        'Fecha',
        'Nombre',
        'Apellido',
        'Edad',
        'Género',
        'Teléfono',
        'Ciudad',
        'Red Social'
      ]);
    }

    if (nuevosRegistros.isEmpty &&
        visitasRegistros.isEmpty &&
        perfiles.isEmpty) {
      throw Exception('No hay registros para exportar');
    }

    final String fileName =
        '${prefix ?? 'registros'}_${DateTime.now().millisecondsSinceEpoch}.xlsx';

    return kIsWeb
        ? _exportarWeb(excel, fileName)
        : await _exportarMobile(excel, fileName);
  }

  void _configurarHojaPerfiles(Excel excel, String sheetName,
      List<SocialProfile> perfiles, List<String> headers) {
    final sheet = excel[sheetName];

    // Definición de estilos
    final headerStyle = CellStyle(
        backgroundColorHex: '#1F497D',
        fontColorHex: '#FFFFFF',
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center);

    final dataStyleEven = CellStyle(
        backgroundColorHex: '#F2F2F2',
        horizontalAlign: HorizontalAlign.Left,
        verticalAlign: VerticalAlign.Center);

    final dataStyleOdd = CellStyle(
        backgroundColorHex: '#FFFFFF',
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
    for (var i = 0; i < perfiles.length; i++) {
      final perfil = perfiles[i];
      final rowIndex = i + 1;
      final isEvenRow = rowIndex % 2 == 0;

      final rowData = [
        DateFormat('dd/MM/yyyy').format(perfil.createdAt),
        perfil.name,
        perfil.lastName,
        perfil.age.toString(),
        perfil.gender,
        perfil.phone,
        perfil.city,
        perfil.socialNetwork,
      ];

      for (var j = 0; j < rowData.length; j++) {
        final cell = sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: j, rowIndex: rowIndex));
        cell.value = rowData[j];
        cell.cellStyle = isEvenRow ? dataStyleEven : dataStyleOdd;
      }
    }

    // Ajustar ancho de columnas automáticamente
    for (var i = 0; i < headers.length; i++) {
      sheet.setColWidth(i, 15.0);
    }
  }

  void _configurarHoja(Excel excel, String sheetName, List<Registro> registros,
      List<String> headers) {
    final sheet = excel[sheetName];

    // Estilos para encabezados
    final headerStyle = CellStyle(
        backgroundColorHex: '#1F497D',
        fontColorHex: '#FFFFFF',
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center);

    // Estilos para filas de datos
    final dataStyleEven = CellStyle(
        backgroundColorHex: '#F2F2F2',
        horizontalAlign: HorizontalAlign.Left,
        verticalAlign: VerticalAlign.Center);

    final dataStyleOdd = CellStyle(
        backgroundColorHex: '#FFFFFF',
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
      sheet.setColWidth(i, 15.0);
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
