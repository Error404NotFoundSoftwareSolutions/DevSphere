// Capability: CAP-OSS-LAB. Tests: TC-OSS-11
// Implemented here: the open-source lab is on the dashboard and its id is a real lab folder
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:desktop/features/dashboard/dashboard_data.dart';

void main() {
  test('TC-OSS-11 the open-source lab is listed and points at an existing lab folder', () {
    final a = SampleData.byId('oss-first-contribution-001');
    expect(a.id, 'oss-first-contribution-001');
    expect(a.kinds, contains('Featured'));
    final lab = Directory('../../content/labs/${a.id}');
    expect(lab.existsSync(), isTrue, reason: 'expected ${lab.path}');
    expect(File('${lab.path}/lab.yaml').existsSync(), isTrue);
  });
}
