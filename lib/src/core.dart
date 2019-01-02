import 'dart:async';
import 'dart:convert';

import 'package:webkit_inspection_protocol/webkit_inspection_protocol.dart';

import 'enums.dart';
import 'types.dart';

typedef SendEvent = void Function(ServiceProtocolEvent event);

class ProxyCore {
  ProxyCore(this.wip, this.sendEvent) {
    populateIsolates();
  }

  final WipConnection wip;
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

  ServiceProtocolResponse _getVM(ServiceProtocolRequest request) {
    return vm.toResponse(request);
  }

  ServiceProtocolResponse _getIsolate(ServiceProtocolRequest request) {
    final String isolateId = request.params['isolateId'];
    // TODO(mdebbar): if the isolate isn't found, return a Sentinel.
    final isolate = vm.isolates.firstWhere((iso) => iso.id == isolateId);
    return isolate.toResponse(request);
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
        sub = wip.runtime.onConsoleAPICalled.listen((call) {
          if (call.args.isEmpty) return;
          final message = call.args[0];
          if (message.type != 'string') return;
          sendEvent(ServiceProtocolEvent.forStream(
            StreamId.Stdout,
            EventMethod.streamNotify,
            {
              'logRecord': {
                'message': message.value,
              },
            },
          ));
        });
    }

    if (sub != null) {
    _subscribedStreams[streamId] = sub;
    return Success().toResponse(request);
    } else {
      return Error(code: 100, message: 'Feature is disabled')
          .toResponse(request);
    }
  }

  ServiceProtocolResponse _streamCancel(ServiceProtocolRequest request) {
    final String streamId = request.params['streamId'];
    if (!_subscribedStreams.containsKey(streamId)) {
      return Error(code: 104, message: 'Stream not subscribed')
          .toResponse(request);
    }
    _subscribedStreams[streamId].cancel();
    _subscribedStreams.remove(streamId);

    return Success().toResponse(request);
  }
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
