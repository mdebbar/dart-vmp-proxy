abstract class RequestMethod {
  static const addBreakpoint = 'addBreakpoint';
  static const addBreakpointWithScriptUri = 'addBreakpointWithScriptUri';
  static const addBreakpointAtEntry = 'addBreakpointAtEntry';
  static const evaluate = 'evaluate';
  static const evaluateInFrame = 'evaluateInFrame';
  static const getFlagList = 'getFlagList';
  static const getIsolate = 'getIsolate';
  static const getScripts = 'getScripts';
  static const getObject = 'getObject';
  static const getSourceReport = 'getSourceReport';
  static const getStack = 'getStack';
  static const getVersion = 'getVersion';
  static const getVM = 'getVM';
  static const invoke = 'invoke';
  static const pause = 'pause';
  static const kill = 'kill';
  static const reloadSources = 'reloadSources';
  static const removeBreakpoint = 'removeBreakpoint';
  static const resume = 'resume';
  static const setExceptionPauseMode = 'setExceptionPauseMode';
  static const setFlag = 'setFlag';
  static const setLibraryDebuggable = 'setLibraryDebuggable';
  static const setName = 'setName';
  static const setVMName = 'setVMName';
  static const streamCancel = 'streamCancel';
  static const streamListen = 'streamListen';
}

abstract class EventMethod {
  static const streamNotify = 'streamNotify';
}

abstract class StreamId {
  static const VM = 'VM';
  static const Isolate = 'Isolate';
  static const Debug = 'Debug';
  static const GC = 'GC';
  static const Extension = 'Extension';
  static const Timeline = 'Timeline';
  static const Stdout = 'Stdout';
  static const Stderr = 'Stderr';
}

/// Adding new values to EventKind is considered a backwards compatible change.
/// Clients should ignore unrecognized events.
abstract class EventKind {
  /// Notification that VM identifying information has changed. Currently used
  /// to notify of changes to the VM debugging name via setVMName.
  static const String VMUpdate = 'VMUpdate';

  /// Notification that a new isolate has started.
  static const String IsolateStart = 'IsolateStart';

  /// Notification that an isolate is ready to run.
  static const String IsolateRunnable = 'IsolateRunnable';

  /// Notification that an isolate has exited.
  static const String IsolateExit = 'IsolateExit';

  /// Notification that isolate identifying information has changed.
  /// Currently used to notify of changes to the isolate debugging name
  /// via setName.
  static const String IsolateUpdate = 'IsolateUpdate';

  /// Notification that an isolate has been reloaded.
  static const String IsolateReload = 'IsolateReload';

  /// Notification that an extension RPC was registered on an isolate.
  static const String ServiceExtensionAdded = 'ServiceExtensionAdded';

  /// An isolate has paused at start, before executing code.
  static const String PauseStart = 'PauseStart';

  /// An isolate has paused at exit, before terminating.
  static const String PauseExit = 'PauseExit';

  /// An isolate has paused at a breakpoint or due to stepping.
  static const String PauseBreakpoint = 'PauseBreakpoint';

  /// An isolate has paused due to interruption via pause.
  static const String PauseInterrupted = 'PauseInterrupted';

  /// An isolate has paused due to an exception.
  static const String PauseException = 'PauseException';

  /// An isolate has paused after a service request.
  static const String PausePostRequest = 'PausePostRequest';

  /// An isolate has started or resumed execution.
  static const String Resume = 'Resume';

  /// Indicates an isolate is not yet runnable. Only appears in an Isolate's
  /// pauseEvent. Never sent over a stream.
  static const String None = 'None';

  /// A breakpoint has been added for an isolate.
  static const String BreakpointAdded = 'BreakpointAdded';

  /// An unresolved breakpoint has been resolved for an isolate.
  static const String BreakpointResolved = 'BreakpointResolved';

  /// A breakpoint has been removed.
  static const String BreakpointRemoved = 'BreakpointRemoved';

  /// A garbage collection event.
  static const String GC = 'GC';

  /// Notification of bytes written, for example, to stdout/stderr.
  static const String WriteEvent = 'WriteEvent';

  /// Notification from dart:developer.inspect.
  static const String Inspect = 'Inspect';

  /// Event from dart:developer.postEvent.
  static const String Extension = 'Extension';
}

/// An [ExceptionPauseMode] indicates how the isolate pauses when an exception is
/// thrown.
class ExceptionPauseMode {
  /// Do not pause isolate on thrown exceptions.
  static const String None = 'None';

  /// Pause isolate on unhandled exceptions.
  static const String Unhandled = 'Unhandled';

  /// Pause isolate on all thrown exceptions.
  static const String All = 'All';
}
