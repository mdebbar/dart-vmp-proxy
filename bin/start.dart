import '../lib/standalone.dart' as standalone;


void main(List<String> args) {
  if (args.length != 1) {
    throw new Exception('Usage: dart bin/start.dart <vm-service-port>');
  }
  final vmServicePort = int.parse(args[0]);
  standalone.main(vmServicePort);
}
