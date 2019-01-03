import 'dart:async';
import 'dart:io';

import 'package:webkit_inspection_protocol/webkit_inspection_protocol.dart';

import 'cdp.dart';
import 'core.dart';

const chromeDevtoolsPort = 9292;

ChromeConnection chrome;

/// Usage:
///
/// ```
/// dart lib/standalone.dart 5858
/// ```
void main(int vmServicePort) async {
  final webUrl = 'http://mdebbar.mtv.corp.google.com:8081'
      '/third_party/dart/butterfly/examples/gallery/web/index.ddc.html';

  // ProcessSignal.sigkill.watch().listen(sig);
  ProcessSignal.sigint.watch().listen(sig);
  ProcessSignal.sigusr1.watch().listen(sig);
  ProcessSignal.sigusr2.watch().listen(sig);

  print('Launching Chrome :$chromeDevtoolsPort');
  chrome = await launchChrome(debugPort: chromeDevtoolsPort, url: webUrl);

  // final tabs = await chrome.getTabs();
  // print(tabs.map((t) => t.title).join('\n'));

  print('Launching server :$vmServicePort');
  final httpServer = await launchServer(port: vmServicePort);

  httpServer.listen((request) async {
    ServiceProtocolServer protocolServer;
    try {
      final socket = await WebSocketTransformer.upgrade(request);
      protocolServer =
          ServiceProtocolServer(socket, chromeDevtoolsPort, webUrl);
      await protocolServer.setup();
    } catch (e) {
      print(e);
      if (protocolServer != null) {
        protocolServer.close();
      }
    }
  });
}

Future<ChromeConnection> launchChrome({int debugPort, String url}) async {
  String cmd;
  final args = [
    '--user-data-dir=.data_dir',
    '--remote-debugging-port=$debugPort',
    url,
  ];

  if (Platform.isMacOS) {
    cmd = '/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome';
  } else if (Platform.isLinux) {
    cmd = 'google-chrome';
  } else {
    final os = Platform.operatingSystem;
    throw Exception("We don't know how to launch Chrome on: $os");
  }

  await Process.start(cmd, args);
  return ChromeConnection('localhost', chromeDevtoolsPort);
}

Future<HttpServer> launchServer({int port}) {
  return HttpServer.bind(InternetAddress.loopbackIPv4, port);
}

Future<ChromeTab> connectToChromeTab(
  ChromeConnection chrome, {
  Duration retryFor = const Duration(seconds: 10),
}) async {
  bool acceptTab(ChromeTab tab) =>
      !tab.isBackgroundPage &&
      !tab.isChromeExtension &&
      !tab.url.startsWith('chrome-devtools://');

  return chrome.getTab(acceptTab, retryFor: retryFor);
}

Future<void> waitForPageLoad(
  WipConnection wip, [
  Duration timeout = const Duration(seconds: 10),
]) async {
  return pollExpression(
    wip,
    'window.__DART_APP_LOADED__ ? "yes" : null',
    (v) => v == 'yes',
  );
}

List<ServiceProtocolServer> protocolServers = [];

class ServiceProtocolServer {
  ServiceProtocolServer(this.socket, this.chromeDevtoolsPort, this.webUrl) {
    protocolServers.add(this);
  }

  final WebSocket socket;
  final int chromeDevtoolsPort;
  final String webUrl;

  ProxyCore _proxy;
  ChromeTab _tab;
  WipConnection _wip;

  // Subscriptions
  List<StreamSubscription> _subs = [];

  void setup() async {
    // Launch Chrome and connect to the Hummingbird tab.
    // In a real scenario, the web app would already be running and connected to
    // DDR/webdev via websocket.
    _tab = await connectToChromeTab(chrome);
    _wip = await _tab.connect();

    await waitForPageLoad(_wip);
    await _wip.debugger.enable();
    await _wip.runtime.enable();
    await _wip.log.enable();
    // await experimental(_wip);

    _proxy = ProxyCore(chrome, (ServiceProtocolEvent event) {
      print('<<< ++++++++ >>>');
      print(event.toJson());
      socket.add(event.toJson());
    });

    // If the Chrome page is closed, disconnect.
    _subs.add(_wip.onClose.listen((_) {
      print('Chrome tab was closed.');
      close();
    }));

    // Handle socket messages.
    _subs.add(socket.listen(
      (message) {
        if (message is String) {
          handleSocketMessage(ServiceProtocolRequest.fromString(message));
        } else {
          print('Received something other than a string: $message');
        }
      },
      onDone: (close),
      onError: (error) {
        print(error);
        close();
      },
    ));
  }

  // Experimental...
  void experimental(WipConnection wip) async {
    final result = await _wip.runtime.evaluate('1 + 2');
    print(result);

    await _wip.console.enable();
    _wip.console.onCleared.listen((_) {
      print('console cleared!');
    });
    _wip.console.onMessage.listen((msg) {
      print('msg: $msg');
    });
    _wip.onNotification.listen((event) {
      print(event.method);
    });
    await _wip.log.enable();
    _wip.log.onEntryAdded.listen((entry) {
      print('[${entry.level}] ${entry.method}: ${entry.text}');
    });
  }

  void handleSocketMessage(ServiceProtocolRequest message) async {
    String json;
    ServiceProtocolResponse response;
    String responseJson;
    try {
      json = message.toJson();
      response = await _proxy.processMessage(message);
      responseJson = response.toJson();
      socket.add(responseJson);
    } finally {
      if (json == null) {
        print('**** Failed to serialize request message: $message');
      } else {
        print('\n-->>>');
        print(json);

        if (response == null) {
          print('**** Failed to generate response');
        } else if (responseJson == null) {
          print('**** Failed to serialize response: $response');
        } else {
          print('<<<--');
          print(responseJson);
        }
      }
    }
  }

  void close() {
    if (!protocolServers.contains(this)) {
      return;
    }
    protocolServers.remove(this);

    print('Closing server...');
    _subs.forEach((sub) => sub.cancel());
    if (_wip != null) {
      _wip.close();
    }
    if (socket != null) {
      socket.close();
    }
  }
}

void sig(ProcessSignal signal) {
  print('Received $signal');
  protocolServers.forEach((server) => server.close());
  exit(1);
}
