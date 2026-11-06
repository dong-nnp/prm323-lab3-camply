import 'package:flutter/services.dart';

abstract interface class ReportExportService {
  /// Returns false when the user cancels the system save dialog.
  Future<bool> saveCsv(Uint8List bytes);
}

final class AndroidReportExportService implements ReportExportService {
  static const _channel = MethodChannel('evia/reports');
  @override
  Future<bool> saveCsv(Uint8List bytes) async =>
      await _channel.invokeMethod<bool>('saveCsv', bytes) ?? false;
}
