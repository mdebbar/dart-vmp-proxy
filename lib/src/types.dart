import 'package:webkit_inspection_protocol/webkit_inspection_protocol.dart';

import 'core.dart';
import 'enums.dart';

abstract class IRequestToResponse {
  ServiceProtocolResponse toResponse(ServiceProtocolRequest request);
}

abstract class IRefable {
  Map<String, dynamic> asRef();
}

Map<String, dynamic> ref(IRefable item) {
  return item.asRef();
}

List<Map<String, dynamic>> refList(List<IRefable> list) {
  return list.map(ref).toList();
}

class Error implements IRequestToResponse {
  Error({this.code, this.message});

  final int code;
  final String message;

  ServiceProtocolResponse toResponse(ServiceProtocolRequest request) {
    return ServiceProtocolResponse.error(request, {
      'code': code,
      'message': message,
    });
  }
}

abstract class Response implements IRequestToResponse {
  Response(this.type);

  final String type;

  Map<String, dynamic> toResult() {
    return {'type': type};
  }

  ServiceProtocolResponse toResponse(ServiceProtocolRequest request) {
    return ServiceProtocolResponse.result(request, toResult());
  }
}

// Types

class Event extends Response {
  Event({this.kind, this.isolate}) : super('Event');

  final String kind;
  final Isolate isolate;

  @override
  Map<String, dynamic> toResult() {
    return super.toResult()
      ..addAll({
        'kind': kind,
        'isloate': ref(isolate),
      });
  }
}

class Isolate extends Response implements IRefable {
  Isolate({
    this.id,
    this.number,
    this.name,
    this.runnable = true,
    this.wip,
  }) : super('Isolate') {
    pauseEvent = Event(kind: EventKind.Resume, isolate: this);
  }

  final String id;
  final String number;
  final String name;
  final bool runnable;
  Event pauseEvent;
  WipConnection wip;

  @override
  Map<String, dynamic> toResult() {
    return super.toResult()
      ..addAll({
        'id': id,
        'number': number,
        'name': name,
        'runnable': runnable,
        'pauseEvent': pauseEvent.toResult(),
      });
  }

  Map<String, dynamic> asRef() {
    return {
      'id': id,
      'number': number,
      'name': name,
    };
  }
}

class Success extends Response {
  Success() : super('Success');
}

class Version extends Response {
  Version({this.major, this.minor}) : super('Version');

  final int major;
  final int minor;

  @override
  Map<String, dynamic> toResult() {
    return super.toResult()
      ..addAll({
        'major': major,
        'minor': minor,
      });
  }
}

class VM extends Response {
  VM(this.name) : super('VM');

  final String name;
  final List<Isolate> isolates = [];

  @override
  Map<String, dynamic> toResult() {
    return super.toResult()
      ..addAll({
        'name': name,
        'isolates': refList(isolates),
      });
  }
}
