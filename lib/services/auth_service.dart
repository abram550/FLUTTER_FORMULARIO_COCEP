import 'package:formulario_app/services/background_worker.dart';
import 'dart:async';

import 'package:formulario_app/utils/error_handler.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  final BackgroundWorker _worker = BackgroundWorker();
  
  factory AuthService() => _instance;
  
  AuthService._internal();

  Future<bool> login(String username, String password) async {
    try {
      return await _worker.compute(() async {
        // Simular delay de red
        await Future.delayed(const Duration(milliseconds: 500));
        return username.toLowerCase() == 'admin' && password == '123456789';
      });
    } catch (e, stack) {
      ErrorHandler.logError(e, stack);
      return false;
    }
  }
}
