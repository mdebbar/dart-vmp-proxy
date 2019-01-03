import 'dart:async';
import 'dart:convert';

import 'package:webkit_inspection_protocol/webkit_inspection_protocol.dart';

import 'cdp.dart';
import 'enums.dart';
import 'types.dart';

typedef SendEvent = void Function(ServiceProtocolEvent event);

class ProxyCore {
  ProxyCore(this.chrome, this.sendEvent) {
    populateIsolates();
  }

  final ChromeConnection chrome;
  final SendEvent sendEvent;

  final version = Version(major: 3, minor: 5);
  final vm = VM('proxy-vm-123');

  void populateIsolates() {
    // TODO: Get the real isolates.
    final isolate = Isolate(
      id: 'abcd-xyz',
      number: '12345678',
      name: 'isolate-name-could-use-url-here',
      runnable: true,
    );
    isolate.pauseEvent = Event(kind: EventKind.Resume, isolate: isolate);
    vm.isolates.add(isolate);
  }

  FutureOr<ServiceProtocolResponse> processMessage(
    ServiceProtocolRequest request,
  ) {
    switch (request.method) {
      case RequestMethod.getVersion:
        return _getVersion(request);
      case RequestMethod.getVM:
        return _getVM(request);
      case RequestMethod.getIsolate:
        return _getIsolate(request);
      case RequestMethod.setExceptionPauseMode:
        return _setExceptionPauseMode(request);
      case RequestMethod.streamListen:
        return _streamListen(request);
      case RequestMethod.streamCancel:
        return _streamCancel(request);
      // TODO: Implement all cases.
    }

    return Error(code: 100, message: 'Feature is disabled').toResponse(request);
  }

  final _subscribedStreams = Map<String, StreamSubscription>();

  ServiceProtocolResponse _getVersion(ServiceProtocolRequest request) {
    return version.toResponse(request);
  }

  Future<ServiceProtocolResponse> _getVM(ServiceProtocolRequest request) async {
    final dartTabs = await getDartTabs(chrome);
    final isoaltes = await Future.wait(dartTabs.map(getIsolateFromTab));
    vm.isolates.replaceRange(0, vm.isolates.length, isoaltes);
    return vm.toResponse(request);
  }

  ServiceProtocolResponse _getIsolate(ServiceProtocolRequest request) {
    final String isolateId = request.params['isolateId'];
    final isolate = findIsolateInVM(vm, isolateId);
    if (isolate == null) {
      // TODO(mdebbar): if the isolate isn't found, return a Sentinel.
    }
    return isolate.toResponse(request);
  }

  Future<ServiceProtocolResponse> _setExceptionPauseMode(
    ServiceProtocolRequest request,
  ) async {
    final String isolateId = request.params['isolateId'];
    final String mode = request.params['mode']; // One of [ExceptionPauseMode].
    final isolate = findIsolateInVM(vm, isolateId);
    if (isolate == null) {
      return Error(code: 105, message: 'Isolate must be runnable')
          .toResponse(request);
    }

    await setExceptionMode(isolate.wip, mode);
    return Success().toResponse(request);
  }

  ServiceProtocolResponse _streamListen(ServiceProtocolRequest request) {
    final String streamId = request.params['streamId'];
    if (_subscribedStreams.containsKey(streamId)) {
      return Error(code: 103, message: 'Stream already subscribed')
          .toResponse(request);
    }

    StreamSubscription sub;
    switch (streamId) {
      case StreamId.Stdout:
      case StreamId.Debug:
      case StreamId.Stderr:
      // Subscribe to the streams...
    }

    _subscribedStreams[streamId] = sub;
    return Success().toResponse(request);
  }

  ServiceProtocolResponse _streamCancel(ServiceProtocolRequest request) {
    final String streamId = request.params['streamId'];
    if (!_subscribedStreams.containsKey(streamId)) {
      return Error(code: 104, message: 'Stream not subscribed')
          .toResponse(request);
    }
    _subscribedStreams[streamId]?.cancel();
    _subscribedStreams.remove(streamId);

    return Success().toResponse(request);
  }
}

Isolate findIsolateInVM(VM vm, String isolateId) {
  return vm.isolates.firstWhere((iso) => iso.id == isolateId);
}

Future<Isolate> getIsolateFromTab(ChromeTab tab) async {
  final wip = await tab.connect();
  final isolateId = await pollExpression(
    wip,
    'String(window.__DART_APP_ISOLATE_ID__ || "") || null',
    (v) => v is String,
  );
  return Isolate(
    id: 'Isolate/$isolateId',
    number: isolateId,
    name: tab.title,
    runnable: true,
    wip: wip,
  );
}

/// Provides getters with correct types for known keys in the service protocol
/// request:
///
/// 1. method.
/// 2. id.
/// 3. params.
class ServiceProtocolRequest {
  ServiceProtocolRequest.fromMap(this.data);
  ServiceProtocolRequest.fromString(String message)
      : this.fromMap(jsonDecode(message));

  final Map<String, dynamic> data;

  String toJson() => jsonEncode(data);

  String get method => data['method'];
  String get id => data['id'];

  Map<String, dynamic> get params {
    final Map<dynamic, dynamic> m = data['params'];
    return m == null ? null : m.cast<String, dynamic>();
  }
}

class ServiceProtocolResponse {
  ServiceProtocolResponse(this.data);

  // Generic result constructor.
  ServiceProtocolResponse.result(
      ServiceProtocolRequest request, Map<String, dynamic> result)
      : this({'id': request.id, 'result': result});

  // Generic error constructor.
  ServiceProtocolResponse.error(
      ServiceProtocolRequest request, Map<String, dynamic> error)
      : this({'id': request.id, 'error': error});

  final Map<String, dynamic> data;

  String toJson() => jsonEncode(data);
}

class ServiceProtocolEvent {
  ServiceProtocolEvent(this.data);

  ServiceProtocolEvent.forStream(
    String streamId,
    String method, [
    Map<String, dynamic> event = const {},
  ]) : this({
          'method': method,
          'params': {
            'streamId': streamId,
            'event': event,
          }
        });

  final Map<String, dynamic> data;

  String toJson() => jsonEncode(data);
}
