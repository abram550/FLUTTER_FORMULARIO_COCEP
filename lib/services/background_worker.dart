import 'dart:isolate';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:formulario_app/utils/error_handler.dart';

class BackgroundWorker {
  static final BackgroundWorker _instance = BackgroundWorker._internal();
  
  factory BackgroundWorker() => _instance;
  
  BackgroundWorker._internal();

  Future<T> compute<T>(Future<T> Function() computation) async {
    if (!kIsWeb) {
      return await Isolate.run(computation);
    } else {
      return await computation();
    }
  }

  Future<void> runTask(Future<void> Function() task) async {
    try {
      if (!kIsWeb) {
        await Isolate.run(task);
      } else {
        await task();
      }
    } catch (e, stack) {
      ErrorHandler.logError(e, stack);
      rethrow;
    }
  }
}