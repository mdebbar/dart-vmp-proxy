import 'package:webkit_inspection_protocol/webkit_inspection_protocol.dart';

typedef Condition = bool Function(String value);

Future<String> pollExpression(
  WipConnection wip,
  String expression,
  Condition condition, [
  Duration timeout = const Duration(seconds: 10),
]) async {
  final start = DateTime.now();
  final end = start.add(timeout);
  while (true) {
    try {
      final value = await evaluateInWip(wip, expression);
      if (condition(value)) {
        return value;
      }
    } catch (e) {
      print(e.runtimeType);
      if (end.isBefore(DateTime.now())) {
        rethrow;
      }
    }
    await Future.delayed(Duration(milliseconds: 25));
  }
}

Future<String> evaluateInWip(WipConnection wip, String expression) async {
  final result = await wip.runtime.evaluate(expression);
  return result.value;
}

Future<String> evaluateInTab(ChromeTab tab, String expression) async {
  final wip = await tab.connect();
  return evaluateInWip(wip, expression);
}
