// Test helper: a tiny stand-in for the worker process (JSON lines on stdin/stdout).
import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  stdout.writeln(jsonEncode({'status': 'ready'}));
  await for (final line
      in stdin.transform(utf8.decoder).transform(const LineSplitter())) {
    final req = jsonDecode(line) as Map<String, dynamic>;
    final id = req['id'];
    switch (req['channel']) {
      case 'echo':
        stdout.writeln(jsonEncode({'id': id, 'result': req['data']}));
      case 'fail':
        stdout.writeln(jsonEncode({
          'id': id,
          'error': {
            'code': 'failed',
            'message': 'It did not work.',
            'recovery': 'Try again.'
          }
        }));
      case 'slow':
        await Future<void>.delayed(const Duration(seconds: 3));
        stdout.writeln(jsonEncode({
          'id': id,
          'result': {'late': true}
        }));
      case 'crash':
        exit(3);
      case 'garbage':
        stdout.writeln('this is not json');
        stdout.writeln(jsonEncode({
          'id': id,
          'result': {'after': 'garbage'}
        }));
    }
  }
}
