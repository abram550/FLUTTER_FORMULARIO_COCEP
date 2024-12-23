import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import '../models/registro.dart';

class ExcelService {
  Future<String> exportarRegistros(List<Registro> registros, {String? prefix}) async {
    final excel = Excel.createExcel();
    
    // Separar registros por tipo
    final nuevosRegistros = registros.where((r) => r.tipo?.toLowerCase() == 'nuevo').toList();
    final visitasRegistros = registros.where((r) => r.tipo?.toLowerCase() == 'visita').toList();
    
    // Crear hojas nuevas
    final sheetNuevos = excel['Nuevos'];
    final sheetVisitas = excel['Visitas'];
    
    // Eliminar la hoja por defecto
    if (excel.sheets.containsKey('Sheet1')) {
      excel.sheets.remove('Sheet1');
    }

    // Estilos mejorados
    final headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: '#1E88E5',
      fontColorHex: '#FFFFFF',
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      textWrapping: TextWrapping.WrapText,
      fontSize: 12
    );

    final subHeaderStyle = CellStyle(
      bold: true,
      backgroundColorHex: '#64B5F6',
      fontColorHex: '#FFFFFF',
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      fontSize: 11
    );

    final contentStyle = CellStyle(
      horizontalAlign: HorizontalAlign.Left,
      verticalAlign: VerticalAlign.Center,
      textWrapping: TextWrapping.WrapText,
      fontSize: 11
    );

    final alternateRowStyle = CellStyle(
      backgroundColorHex: '#F5F5F5',
      horizontalAlign: HorizontalAlign.Left,
      verticalAlign: VerticalAlign.Center,
      textWrapping: TextWrapping.WrapText,
      fontSize: 11
    );

    // Headers específicos para Nuevos
    final headersNuevos = [
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
    ];

    // Headers específicos para Visitas
    final headersVisitas = [
      'Fecha',
      'Nombre',
      'Apellido',
      'Teléfono',
      'Servicio',
      'Motivo',
      'Peticiones',
      'Consolidador'
    ];

    try {
      // Configurar hoja de Nuevos si hay registros
      if (nuevosRegistros.isNotEmpty) {
        // Configurar título de la hoja
        var titleCell = sheetNuevos.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0));
        titleCell.value = 'Registro de Personas Nuevas';
        titleCell.cellStyle = CellStyle(
          bold: true,
          fontSize: 14,
          backgroundColorHex: '#1565C0',
          fontColorHex: '#FFFFFF',
          horizontalAlign: HorizontalAlign.Center
        );
        sheetNuevos.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
                         CellIndex.indexByColumnRow(columnIndex: headersNuevos.length - 1, rowIndex: 0));

        // Configurar headers
        for (var i = 0; i < headersNuevos.length; i++) {
          var cell = sheetNuevos.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 1));
          cell.value = headersNuevos[i];
          cell.cellStyle = headerStyle;
          // Eliminar esta línea (no compatible)
          // sheetNuevos.setColumnWidth(i, 15.0);
        }


        // Agregar datos
        for (var i = 0; i < nuevosRegistros.length; i++) {
          var registro = nuevosRegistros[i];
          var rowIndex = i + 2;
          var style = i % 2 == 0 ? contentStyle : alternateRowStyle;

          var rowData = [
            _formatDate(registro.fecha),
            registro.nombre,
            registro.apellido,
            registro.edad.toString(),
            registro.sexo,
            registro.telefono,
            registro.direccion,
            registro.barrio,
            registro.estadoCivil,
            registro.nombrePareja ?? '',
            registro.tieneHijos ? 'Sí' : 'No',
            registro.ocupaciones.join(', '),
            registro.descripcionOcupacion,
            registro.referenciaInvitacion,
            registro.observaciones ?? ''
          ];

          for (var j = 0; j < rowData.length; j++) {
            var cell = sheetNuevos.cell(CellIndex.indexByColumnRow(columnIndex: j, rowIndex: rowIndex));
            cell.value = rowData[j];
            cell.cellStyle = style;
          }
        }
      }

      // Configurar hoja de Visitas si hay registros
      if (visitasRegistros.isNotEmpty) {
        // Configurar título de la hoja
        var titleCell = sheetVisitas.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0));
        titleCell.value = 'Registro de Visitas';
        titleCell.cellStyle = CellStyle(
          bold: true,
          fontSize: 14,
          backgroundColorHex: '#1565C0',
          fontColorHex: '#FFFFFF',
          horizontalAlign: HorizontalAlign.Center
        );
        sheetVisitas.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
                          CellIndex.indexByColumnRow(columnIndex: headersVisitas.length - 1, rowIndex: 0));

        // Configurar headers
        for (var i = 0; i < headersVisitas.length; i++) {
          var cell = sheetVisitas.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 1));
          cell.value = headersVisitas[i];
          cell.cellStyle = headerStyle;
          // Eliminar esta línea (no compatible)
          // sheetVisitas.setColumnWidth(i, 15.0);
        }


        // Agregar datos
        for (var i = 0; i < visitasRegistros.length; i++) {
          var registro = visitasRegistros[i];
          var rowIndex = i + 2;
          var style = i % 2 == 0 ? contentStyle : alternateRowStyle;

          var rowData = [
            _formatDate(registro.fecha),
            registro.nombre,
            registro.apellido,
            registro.telefono,
            registro.servicio,
            registro.motivo ?? '',
            registro.peticiones ?? '',
            registro.consolidador ?? '',
            registro.observaciones ?? '',
            registro.referenciaInvitacion
          ];

          for (var j = 0; j < rowData.length; j++) {
            var cell = sheetVisitas.cell(CellIndex.indexByColumnRow(columnIndex: j, rowIndex: rowIndex));
            cell.value = rowData[j];
            cell.cellStyle = style;
          }
        }
      }

      // Verificar si hay registros para exportar
      if (nuevosRegistros.isEmpty && visitasRegistros.isEmpty) {
        throw Exception('No hay registros para exportar');
      }

      // Guardar archivo
      final String path = await _getDocumentsPath();
      final String fileName = '${prefix ?? 'registros'}_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final String filePath = '$path/$fileName';

      final file = File(filePath);
      await file.writeAsBytes(excel.encode()!);
      return filePath;
    } catch (e) {
      throw Exception('Error al generar el archivo Excel: $e');
    }
  }

  String _formatDate(DateTime fecha) {
    return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
  }

  Future<String> _getDocumentsPath() async {
    try {
      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Documents');
      } else if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      }
      
      if (directory == null || !directory.existsSync()) {
        throw Exception('No se pudo acceder a la carpeta de Documentos.');
      }
      
      return directory.path;
    } catch (e) {
      throw Exception('Error al obtener la ruta de documentos: $e');
    }
  }
}