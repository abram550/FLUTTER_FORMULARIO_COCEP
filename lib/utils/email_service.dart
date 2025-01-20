import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class EmailService {
  static final String _username = 'abrahamfaju18@gmail.com'; // Tu correo de Gmail
  static final String _password = 'srlo vtow qtlo oxkl'; // Contraseña de aplicación de Gmail
  
  static Future<void> enviarAlertaFaltas({
    required String emailCoordinador,
    required String nombreJoven,
    required String nombreTimoteo,
    required int faltas,
  }) async {
    // Configurar servidor SMTP de Gmail
    final smtpServer = gmail(_username, _password);
    
    // Crear el mensaje
    final message = Message()
      ..from = Address(_username, 'Sistema de Alertas')
      ..recipients.add(emailCoordinador)
      ..subject = 'Alerta de Asistencia - $nombreJoven'
      ..text = '''
🚨 ALERTA DE ASISTENCIA

El joven $nombreJoven ha acumulado $faltas faltas consecutivas.
Timoteo asignado: $nombreTimoteo

Por favor, realizar seguimiento urgente.
''';
    
    try {
      final sendReport = await send(message, smtpServer);
      print('Mensaje enviado: ${sendReport.toString()}');
    } catch (e) {
      print('Error al enviar email: $e');
      rethrow;
    }
  }
}