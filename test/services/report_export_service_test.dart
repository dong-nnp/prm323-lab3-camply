import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab03/services/report_export_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('evia/reports');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));
  test(
    'native export sends bytes and distinguishes saved from cancelled',
    () async {
      var saved = true;
      messenger.setMockMethodCallHandler(channel, (call) async {
        expect(call.method, 'saveCsv');
        expect(call.arguments, orderedEquals([1, 2, 3]));
        return saved;
      });
      final service = AndroidReportExportService();
      expect(await service.saveCsv(Uint8List.fromList([1, 2, 3])), isTrue);
      saved = false;
      expect(await service.saveCsv(Uint8List.fromList([1, 2, 3])), isFalse);
    },
  );
  test('native write error propagates to the ViewModel error path', () async {
    messenger.setMockMethodCallHandler(
      channel,
      (_) async => throw PlatformException(code: 'report_failed'),
    );
    await expectLater(
      AndroidReportExportService().saveCsv(Uint8List(0)),
      throwsA(isA<PlatformException>()),
    );
  });
}
