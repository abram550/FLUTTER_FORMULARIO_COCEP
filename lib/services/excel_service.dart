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
        'Servicio',
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
        'Estado Fonovisita',
        'Observaciones 2',
        'Consolidador'
      ]);
    }

    if (visitasRegistros.isNotEmpty) {
      _configurarHoja(excel, 'Visitas', visitasRegistros, [
        'Fecha',
        'Servicio',
        'Nombre',
        'Apellido',
        'Teléfono',
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
        'Dirección', // Campo añadido
        'Ciudad',
        'Petición de Oración', // Campo añadido
        'Red Social'
      ]);
    }

    if (nuevosRegistros.isEmpty &&
        visitasRegistros.isEmpty &&
        perfiles.isEmpty) {
      throw Exception('No hay registros para exportar');
    }

    final String fileName =
        '${prefix ?? 'registros_exportacion'}_${DateTime.now().millisecondsSinceEpoch}.xlsx';

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
        perfil.address ?? '', // Campo añadido
        perfil.city,
        perfil.prayerRequest ?? '', // Campo añadido
        perfil.socialNetwork,
      ];

      for (var j = 0; j < rowData.length; j++) {
        final cell = sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: j, rowIndex: rowIndex));
        // Formatear texto para mejorar visibilidad (simulando wrap text)
        String valor = rowData[j].toString();
        // Aplicar saltos de línea a campos largos como dirección y peticiones de oración
        if (valor.length > 30 && (j == 6 || j == 8)) {
          valor = _insertarSaltosDeLinea(valor, 30);
        }
        cell.value = valor;
        cell.cellStyle = isEvenRow ? dataStyleEven : dataStyleOdd;
      }
    }

    // Ajustar ancho de columnas automáticamente
    for (var i = 0; i < headers.length; i++) {
      sheet.setColAutoFit(i); // Usa autofit para ajustar al contenido
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
          _formatDateLongSpanish(registro.fecha), // Fecha en español
          registro.servicio ?? '', // Servicio separado
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
          registro.estadoFonovisita ?? '',
          registro.observaciones2 ?? '',
          registro.consolidador ?? ''
        ];
      } else {
        rowData = [
          _formatDateLongSpanish(registro.fecha), // Fecha en español
          registro.servicio ?? '', // Servicio separado
          registro.nombre,
          registro.apellido,
          registro.telefono,
          registro.motivo ?? '',
          registro.peticiones ?? '',
          registro.consolidador ?? ''
        ];
      }

      for (var j = 0; j < rowData.length; j++) {
        final cell = sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: j, rowIndex: rowIndex));

        String valor = rowData[j].toString();

        // Para campos largos como direcciones, motivo, peticiones u observaciones
        if (valor.length > 30 &&
            (j == 0 || j == 7 || j == 5 || j == 6 || j == 14 || j == 16)) {
          valor = _insertarSaltosDeLinea(valor, 30);
        }

        cell.value = valor;
        cell.cellStyle = isEvenRow ? dataStyleEven : dataStyleOdd;
      }
    }

    // Ajustar ancho de columnas automáticamente
    for (var i = 0; i < headers.length; i++) {
      sheet.setColAutoFit(i);
    }
  }

  // Función para insertar saltos de línea en textos largos
  String _insertarSaltosDeLinea(String texto, int longitudMaxima) {
    if (texto.length <= longitudMaxima) return texto;

    final List<String> palabras = texto.split(' ');
    final StringBuilder = StringBuffer();
    int longitudActual = 0;

    for (final palabra in palabras) {
      if (longitudActual + palabra.length > longitudMaxima) {
        StringBuilder.write('\n');
        longitudActual = 0;
      } else if (longitudActual > 0) {
        StringBuilder.write(' ');
        longitudActual += 1;
      }

      StringBuilder.write(palabra);
      longitudActual += palabra.length;
    }

    return StringBuilder.toString();
  }

// Función para formatear fecha en español con nombre de día y mes
  String _formatDateLongSpanish(DateTime? fecha) {
    if (fecha == null) return '';

    final diasSemana = [
      'lunes',
      'martes',
      'miércoles',
      'jueves',
      'viernes',
      'sábado',
      'domingo'
    ];
    final meses = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre'
    ];

    final diaSemana = diasSemana[fecha.weekday - 1];
    final dia = fecha.day;
    final mes = meses[fecha.month - 1];
    final anio = fecha.year;

    return '$diaSemana, $dia de $mes de $anio';
  }

  String _exportarWeb(Excel excel, String fileName) {
    // Usa encode() en lugar de save() para evitar archivos temporales
    final bytes = excel.encode();
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

    // Usa encode() en lugar de save() para evitar archivos temporales
    final bytes = excel.encode();
    if (bytes == null) throw Exception('Error al codificar el archivo Excel');

    await file.writeAsBytes(bytes);
    return filePath;
  }

  String _formatDate(DateTime? fecha) {
    if (fecha == null) return '';
    return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
  }
}
