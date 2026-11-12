import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab03/core/errors/app_exception.dart';
import 'package:prm393_lab03/core/providers/repository_providers.dart';
import 'package:prm393_lab03/core/providers/service_providers.dart';
import 'package:prm393_lab03/models/activity_models.dart';
import 'package:prm393_lab03/models/auth_session.dart';
import 'package:prm393_lab03/repositories/report_export_repository.dart';
import 'package:prm393_lab03/services/pending_firebase_services.dart';
import 'package:prm393_lab03/services/report_export_service.dart';
import 'package:prm393_lab03/services/storage_service.dart';
import 'package:prm393_lab03/viewmodels/authentication_view_model.dart';
import 'package:prm393_lab03/viewmodels/flow1_view_model.dart';
import 'package:prm393_lab03/viewmodels/flow3_view_model.dart';
import 'package:prm393_lab03/viewmodels/report_export_view_model.dart';

import '../helpers/fake_analytics_service.dart';
import '../helpers/flow3_backend.dart';
import '../helpers/sign_up_test_service.dart';

class _MemoryStorageService implements StorageService {
  final Map<String, Uint8List> files = {};
  final List<String> uploadedContentTypes = [];
  Completer<Uri>? uploadGate;
  bool tamperReadBack = false;
  bool failUpload = false;

  @override
  Future<Uri> upload({
    required String path,
    required Uint8List bytes,
    required String contentType,
    void Function(double progress)? onProgress,
  }) async {
    onProgress?.call(0.5);
    if (failUpload) {
      throw const AppException(
        code: 'permission-denied',
        message: 'Permission denied',
      );
    }
    uploadedContentTypes.add(contentType);
    files[path] = bytes;
    if (uploadGate != null) {
      final uri = await uploadGate!.future;
      onProgress?.call(1.0);
      return uri;
    }
    onProgress?.call(1.0);
    return Uri.parse('gs://test-bucket/$path');
  }

  @override
  Future<Uint8List> readBytes({
    required String path,
    int maxSizeBytes = 5 * 1024 * 1024,
  }) async {
    final stored = files[path];
    if (stored == null) {
      throw const AppException(code: 'NOT_FOUND', message: 'Missing file');
    }
    if (tamperReadBack) {
      return Uint8List.fromList(utf8.encode('%PDF-1.4\ntampered\n%%EOF\n'));
    }
    return stored;
  }
}

class _StubReportExportService implements ReportExportService {
  @override
  Future<bool> saveCsv(Uint8List bytes) async => true;
}

void main() {
  test('PendingFirebaseServices storage methods fail explicitly', () async {
    const pending = PendingFirebaseServices();
    await expectLater(
      () => pending.upload(
        path: 'reports/u1/a.pdf',
        bytes: Uint8List(0),
        contentType: 'application/pdf',
      ),
      throwsA(
        isA<AppException>().having(
          (e) => e.code,
          'code',
          'firebase_service_pending',
        ),
      ),
    );
    await expectLater(
      () => pending.readBytes(path: 'reports/u1/a.pdf'),
      throwsA(
        isA<AppException>().having(
          (e) => e.code,
          'code',
          'firebase_service_pending',
        ),
      ),
    );
  });

  test('ReportExportRepository builds PDF 1.4, uploads to owner path, and verifies read-back', () async {
    final storage = _MemoryStorageService();
    final repo = ReportExportRepository(
      _StubReportExportService(),
      storageService: storage,
    );
    final progress = <double>[];
    final entries = [
      CoinEntry(
        'Attendance bonus (Private Email)',
        'Sub',
        100,
        CoinKind.earned,
        0,
        date: DateTime.utc(2026, 11, 12, 10, 30),
      ),
    ];

    final result = await repo.uploadHistoryPdf(
      uid: 'uid-123',
      entries: entries,
      filterLabel: 'Earned',
      fileId: 'tc15-check',
      onProgress: progress.add,
    );

    expect(result.storagePath, 'reports/uid-123/coin_history_tc15-check.pdf');
    expect(result.rowCount, 1);
    expect(result.contentMatched, isTrue);
    expect(progress, [0.5, 1.0]);
    expect(storage.uploadedContentTypes, ['application/pdf']);

    final uploadedText = utf8.decode(
      storage.files[result.storagePath]!,
      allowMalformed: true,
    );
    expect(uploadedText, startsWith('%PDF-1.4\n'));
    expect(uploadedText, contains('%%EOF'));
    expect(uploadedText, contains('EVIA Coin History Report'));
    expect(uploadedText, contains('2026-11-12T10:30:00.000Z | earned | 100'));
    expect(uploadedText, isNot(contains('Private Email')));
  });

  test('ReportExportRepository detects read-back mismatch and validates uid/storage', () async {
    final unconfigured = ReportExportRepository(_StubReportExportService());
    await expectLater(
      () => unconfigured.uploadHistoryPdf(
        uid: 'uid-1',
        entries: const [],
        filterLabel: 'All',
      ),
      throwsA(
        isA<AppException>().having(
          (e) => e.code,
          'code',
          'firebase_service_pending',
        ),
      ),
    );

    final storage = _MemoryStorageService()..tamperReadBack = true;
    final repo = ReportExportRepository(
      _StubReportExportService(),
      storageService: storage,
    );
    await expectLater(
      () => repo.uploadHistoryPdf(
        uid: '../bad',
        entries: const [],
        filterLabel: 'All',
      ),
      throwsA(
        isA<AppException>().having((e) => e.code, 'code', 'unauthenticated'),
      ),
    );

    final mismatch = await repo.uploadHistoryPdf(
      uid: 'uid-1',
      entries: const [],
      filterLabel: 'All',
      fileId: 'tamper',
    );
    expect(mismatch.contentMatched, isFalse);
  });

  test('ReportExportViewModel uploads PDF, prevents duplicates, and emits AN-16/action_error', () async {
    final backend = Flow3TestBackend();
    final auth = SignUpTestService()
      ..session = const AuthSession.signedIn('storage-user-1');
    final analytics = FakeAnalyticsService();
    final storage = _MemoryStorageService();
    final c = ProviderContainer(
      overrides: [
        realBackendEnabledProvider.overrideWithValue(true),
        analyticsEnabledProvider.overrideWithValue(true),
        authenticationServiceProvider.overrideWithValue(auth),
        backendServiceProvider.overrideWithValue(backend),
        analyticsServiceProvider.overrideWithValue(analytics),
        storageServiceProvider.overrideWithValue(storage),
        reportExportServiceProvider.overrideWithValue(
          _StubReportExportService(),
        ),
      ],
    );
    addTearDown(() async {
      c.dispose();
      await auth.close();
    });

    c.listen(authenticationViewModelProvider, (_, _) {});
    await c.read(authenticationViewModelProvider.future);
    c.listen(flow1ViewModelProvider, (_, _) {});
    await c.read(flow1ViewModelProvider.future);
    c.listen(flow3ViewModelProvider, (_, _) {});
    await c.read(flow3ViewModelProvider.future);
    await c
        .read(flow3ViewModelProvider.notifier)
        .redeem(c.read(flow3ViewModelProvider).requireValue.rewards.single);
    await c.read(analyticsRepositoryProvider).identify('storage-user-1');
    analytics.events.clear();

    c.listen(reportExportViewModelProvider, (_, _) {});
    storage.uploadGate = Completer<Uri>();
    final vm = c.read(reportExportViewModelProvider.notifier);
    final first = vm.uploadHistoryToCloud();
    await vm.uploadHistoryToCloud();
    expect(c.read(reportExportViewModelProvider).uploading, isTrue);

    storage.uploadGate!.complete(
      Uri.parse('gs://test-bucket/reports/storage-user-1/report.pdf'),
    );
    await first;
    await c.read(analyticsRepositoryProvider).identify('storage-user-1');

    final exportState = c.read(reportExportViewModelProvider);
    expect(exportState.uploading, isFalse);
    expect(exportState.uploadFailed, isFalse);
    expect(exportState.verifiedContentMatch, isTrue);
    expect(
      exportState.uploadedPath,
      startsWith('reports/storage-user-1/coin_history_'),
    );
    expect(analytics.events.single.name, 'upload_report');
    expect(
      analytics.events.single.parameters['report_type'],
      'coin_history_pdf',
    );

    analytics.events.clear();
    storage
      ..uploadGate = null
      ..failUpload = true;
    await vm.uploadHistoryToCloud();
    await c.read(analyticsRepositoryProvider).identify('storage-user-1');

    expect(c.read(reportExportViewModelProvider).uploadFailed, isTrue);
    expect(analytics.events.single.name, 'action_error');
    expect(analytics.events.single.parameters, {
      'action': 'upload_report',
      'error_code': 'permission-denied',
    });
  });
}
