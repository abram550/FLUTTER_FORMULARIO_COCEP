import 'dart:isolate';
import 'dart:async';

class IsolateHelper {
  // Ejecuta una tarea computacional intensiva en un Isolate separado
  static Future<T> compute<T>(FutureOr<T> Function() computation,
      {String? debugLabel}) async {
    final receivePort = ReceivePort();

    await Isolate.spawn(
      (SendPort sendPort) async {
        final result = await computation();
        sendPort.send(result);
      },
      receivePort.sendPort,
      debugName: debugLabel,
    );

    final result = await receivePort.first as T;
    receivePort.close();
    return result;
  }

  // Ejecuta una tarea ligera en un Isolate separado
  static Future<void> runBackground(Future<void> Function() task,
      {String? debugLabel}) async {
    await compute(task, debugLabel: debugLabel);
  }

  // Ejemplo: Uso del helper para una tarea pesada
  static Future<List<int>> exampleHeavyComputation(List<int> input) async {
    return compute(() async {
      // Simula una tarea costosa, como procesamiento de datos
      return input.map((e) => e * 2).toList();
    });
  }
}

// Ejemplo de uso del IsolateHelper
Future<void> main() async {
  final input = List.generate(1000000, (index) => index);

  print('Comenzando tarea pesada...');

  // Ejecuta la tarea en un Isolate
  final result = await IsolateHelper.exampleHeavyComputation(input);

  print(
      'Resultado de la tarea: ${result.take(10)}'); // Muestra los primeros 10 resultados
}
