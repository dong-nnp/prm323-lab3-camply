import 'dart:convert';
import 'dart:typed_data';

import '../core/constants/app_strings.dart';
import '../core/errors/app_exception.dart';
import '../models/activity_models.dart';
import '../services/report_export_service.dart';
import '../services/storage_service.dart';

final class ReportUploadResult {
  const ReportUploadResult({
    required this.storageUri,
    required this.storagePath,
    required this.sizeBytes,
    required this.rowCount,
    required this.contentMatched,
    required this.verifiedPreview,
  });

  final Uri storageUri;
  final String storagePath;
  final int sizeBytes;
  final int rowCount;
  final bool contentMatched;
  final String verifiedPreview;

  int get sizeKb => (sizeBytes / 1024).ceil();
}

final class ReportExportRepository {
  const ReportExportRepository(this._service, {this.storageService});

  static const _linesPerPage = 42;
  static int _sequence = 0;

  final ReportExportService _service;
  final StorageService? storageService;

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

  Future<ReportUploadResult> uploadHistoryPdf({
    required String uid,
    required List<CoinEntry> entries,
    required String filterLabel,
    void Function(double progress)? onProgress,
    String? fileId,
  }) async {
    final storage = storageService;
    if (storage == null) {
      throw const AppException(
        code: 'firebase_service_pending',
        message: AppStrings.servicePending,
      );
    }
    final cleanUid = uid.trim();
    if (cleanUid.isEmpty || cleanUid.contains('/')) {
      throw const AppException(
        code: 'unauthenticated',
        message: 'Phiên đăng nhập không hợp lệ. Vui lòng đăng nhập lại.',
      );
    }
    final safeId = _sanitizeFileToken(
      fileId ??
          '${DateTime.now().toUtc().millisecondsSinceEpoch}_${++_sequence}',
    );
    final storagePath = 'reports/$cleanUid/coin_history_$safeId.pdf';
    final expectedLines = _reportLines(entries, filterLabel: filterLabel);
    final pdfBytes = _buildPdf(expectedLines);

    final uri = await storage.upload(
      path: storagePath,
      bytes: pdfBytes,
      contentType: 'application/pdf',
      onProgress: onProgress,
    );
    final remoteBytes = await storage.readBytes(path: storagePath);
    final matched =
        _bytesEqual(pdfBytes, remoteBytes) &&
        _pdfContainsExpectedLines(remoteBytes, expectedLines);

    final latestSummary = entries.isEmpty
        ? 'No entries'
        : formatPdfRow(entries.first);
    return ReportUploadResult(
      storageUri: uri,
      storagePath: storagePath,
      sizeBytes: remoteBytes.length,
      rowCount: entries.length,
      contentMatched: matched,
      verifiedPreview:
          '${pdfBytes.length} bytes · ${entries.length} rows · $latestSummary',
    );
  }

  static String formatPdfRow(CoinEntry entry) =>
      '${entry.date?.toUtc().toIso8601String() ?? 'no-date'} | ${entry.kind.name} | ${entry.amount}';

  static List<String> _reportLines(
    List<CoinEntry> entries, {
    required String filterLabel,
  }) {
    final safeFilter = _toSafeAscii(
      filterLabel.trim().isEmpty ? 'All' : filterLabel.trim(),
    );
    return [
      'EVIA Coin History Report',
      'Filter: $safeFilter | Items: ${entries.length}',
      'Columns: date | kind | coins',
      for (final entry in entries) _toSafeAscii(formatPdfRow(entry)),
    ];
  }

  static Uint8List buildCoinHistoryPdf(
    List<CoinEntry> entries, {
    String filterLabel = 'All',
  }) => _buildPdf(_reportLines(entries, filterLabel: filterLabel));

  static Uint8List _buildPdf(List<String> lines) {
    final pages = <List<String>>[];
    for (var i = 0; i < lines.length; i += _linesPerPage) {
      final end = (i + _linesPerPage < lines.length)
          ? i + _linesPerPage
          : lines.length;
      pages.add(lines.sublist(i, end));
    }
    if (pages.isEmpty) pages.add(const ['EVIA Coin History Report']);

    final totalObjects = 3 + pages.length * 2;
    final kids = [for (var i = 0; i < pages.length; i++) '${4 + i * 2} 0 R']
        .join(' ');

    final builder = BytesBuilder(copy: false);
    final offsets = List<int>.filled(totalObjects + 1, 0);

    void writeAscii(String value) => builder.add(latin1.encode(value));
    void startObject(int id) {
      offsets[id] = builder.length;
      writeAscii('$id 0 obj\n');
    }

    writeAscii('%PDF-1.4\n');
    startObject(1);
    writeAscii('<< /Type /Catalog /Pages 2 0 R >>\nendobj\n');

    startObject(2);
    writeAscii(
      '<< /Type /Pages /Kids [$kids] /Count ${pages.length} >>\nendobj\n',
    );

    startObject(3);
    writeAscii(
      '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>\nendobj\n',
    );

    for (var i = 0; i < pages.length; i++) {
      final pageObjId = 4 + i * 2;
      final contentObjId = 5 + i * 2;
      final streamText = _pageContentStream(pages[i]);
      final streamBytes = latin1.encode(streamText);

      startObject(pageObjId);
      writeAscii(
        '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] '
        '/Resources << /Font << /F1 3 0 R >> >> '
        '/Contents $contentObjId 0 R >>\nendobj\n',
      );

      startObject(contentObjId);
      writeAscii('<< /Length ${streamBytes.length} >>\nstream\n');
      builder.add(streamBytes);
      writeAscii('\nendstream\nendobj\n');
    }

    final xrefOffset = builder.length;
    writeAscii('xref\n0 ${totalObjects + 1}\n');
    writeAscii('0000000000 65535 f \n');
    for (var id = 1; id <= totalObjects; id++) {
      writeAscii('${offsets[id].toString().padLeft(10, '0')} 00000 n \n');
    }
    writeAscii(
      'trailer\n<< /Size ${totalObjects + 1} /Root 1 0 R >>\n'
      'startxref\n$xrefOffset\n%%EOF\n',
    );
    return builder.takeBytes();
  }

  static String _pageContentStream(List<String> lines) {
    final buf = StringBuffer('BT\n/F1 11 Tf\n50 792 Td\n16 TL\n');
    for (var i = 0; i < lines.length; i++) {
      final escaped = _escapePdfLiteral(lines[i]);
      if (i == 0) {
        buf.writeln('($escaped) Tj');
      } else {
        buf.writeln('T* ($escaped) Tj');
      }
    }
    buf.write('ET');
    return buf.toString();
  }

  static bool _pdfContainsExpectedLines(
    Uint8List remoteBytes,
    List<String> expectedLines,
  ) {
    final decoded = latin1.decode(remoteBytes, allowInvalid: true);
    if (!decoded.startsWith('%PDF-1.4') || !decoded.contains('%%EOF')) {
      return false;
    }
    for (final line in expectedLines) {
      if (!decoded.contains('(${_escapePdfLiteral(line)}) Tj')) return false;
    }
    return true;
  }

  static bool _bytesEqual(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static String _escapePdfLiteral(String text) => text
      .replaceAll('\\', '\\\\')
      .replaceAll('(', '\\(')
      .replaceAll(')', '\\)');

  static String _toSafeAscii(String value) {
    final buf = StringBuffer();
    for (final code in value.codeUnits) {
      buf.write(code >= 0x20 && code <= 0x7E ? String.fromCharCode(code) : '_');
    }
    return buf.toString();
  }

  static String _sanitizeFileToken(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    return cleaned.isEmpty ? 'report' : cleaned;
  }
}
