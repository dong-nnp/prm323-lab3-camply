import 'dart:convert';
import 'dart:typed_data';

import '../models/activity_models.dart';
import '../services/report_export_service.dart';

final class ReportExportRepository {
  const ReportExportRepository(this._service);
  final ReportExportService _service;

  Future<int?> exportHistory(List<CoinEntry> entries) async {
    // Export only the loaded selection; never include names or voucher codes.
    final csv = StringBuffer('\ufeffdate,kind,coins\r\n');
    for (final entry in entries) {
      csv.writeln(
        '${entry.date?.toIso8601String() ?? ''},${entry.kind.name},${entry.amount}\r',
      );
    }
    final bytes = Uint8List.fromList(utf8.encode(csv.toString()));
    return await _service.saveCsv(bytes) ? (bytes.length / 1024).ceil() : null;
  }
}
