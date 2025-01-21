import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class EmailService {
  static final String _username = 'abrahamfaju18@gmail.com';
  static final String _password = 'srlo vtow qtlo oxkl';

  static Future<void> enviarAlertaFaltas({
    required String emailCoordinador,
    required String nombreJoven,
    required String nombreTimoteo,
    required int faltas,
    String? alertaId,
  }) async {
    try {
      if (kIsWeb) {
        await _enviarPorFunctions(
          alertaId: alertaId,
          emailCoordinador: emailCoordinador,
          nombreJoven: nombreJoven,
          nombreTimoteo: nombreTimoteo,
          faltas: faltas,
        );
      } else {
        await _enviarDirecto(
          emailCoordinador: emailCoordinador,
          nombreJoven: nombreJoven,
          nombreTimoteo: nombreTimoteo,
          faltas: faltas,
        );
      }
    } catch (e) {
      print('Error en enviarAlertaFaltas: $e');
      throw Exception('No se pudo enviar el email: $e');
    }
  }

  static Future<void> _enviarPorFunctions({
    String? alertaId,
    required String emailCoordinador,
    required String nombreJoven,
    required String nombreTimoteo,
    required int faltas,
  }) async {
    try {
      final callable = FirebaseFunctions.instanceFor(region: 'us-central1')
          .httpsCallable('enviarAlertaFaltas');
      
      final result = await callable.call({
        'alertaId': alertaId,
        'emailCoordinador': emailCoordinador,
        'nombreJoven': nombreJoven,
        'nombreTimoteo': nombreTimoteo,
        'faltas': faltas,
      });

      if (result.data['success'] != true) {
        throw Exception(result.data['message'] ?? 'Error desconocido');
      }
    } catch (e) {
      print('Error en _enviarPorFunctions: $e');
      throw Exception('Error al enviar por Firebase Functions: $e');
    }
  }

  static Future<void> _enviarDirecto({
    required String emailCoordinador,
    required String nombreJoven,
    required String nombreTimoteo,
    required int faltas,
  }) async {
    try {
      final smtpServer = gmail(_username, _password);

      final message = Message()
        ..from = Address(_username, 'Sistema de Alertas')
        ..recipients.add(emailCoordinador.trim())
        ..subject = 'Alerta de Asistencia - $nombreJoven'
        ..text = '''
🚨 ALERTA DE ASISTENCIA

El joven $nombreJoven ha acumulado $faltas faltas consecutivas.
Timoteo asignado: $nombreTimoteo

Por favor, realizar seguimiento urgente.

Este es un mensaje automático, no responder a este correo.
''';

      final sendReport = await send(message, smtpServer);
      print('Email enviado exitosamente: ${sendReport.toString()}');
    } catch (e) {
      print('Error en _enviarDirecto: $e');
      throw Exception('Error al enviar email directo: $e');
    }
  }
}