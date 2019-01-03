import 'package:webkit_inspection_protocol/webkit_inspection_protocol.dart';

import '../enums.dart';

Future<void> setExceptionMode(WipConnection wip, String mode) async {
  await wip.debugger.enable();
  await wip.debugger.setPauseOnExceptions(exceptionModeToPauseState(mode));
}

PauseState exceptionModeToPauseState(String exceptionMode) {
  switch (exceptionMode) {
    case ExceptionPauseMode.All:
      return PauseState.all;
    case ExceptionPauseMode.None:
      return PauseState.none;
    case ExceptionPauseMode.Unhandled:
      return PauseState.uncaught;
  }
  throw new Exception('Unexpected `ExceptionMode`: $exceptionMode');
}
