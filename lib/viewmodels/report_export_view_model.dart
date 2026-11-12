import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/errors/app_exception.dart';
import '../core/providers/repository_providers.dart';
import '../core/providers/service_providers.dart';
import '../core/utils/exception_mapper.dart';
import 'activity_view_model.dart';
import 'authentication_view_model.dart';

final class ReportExportState {
  const ReportExportState({
    this.busy = false,
    this.message,
    this.uploading = false,
    this.progress,
    this.uploadMessage,
    this.uploadFailed = false,
    this.uploadedPath,
    this.uploadedSizeBytes,
    this.verifiedContentMatch,
    this.verifiedSummary,
  });

  final bool busy;
  final String? message;
  final bool uploading;
  final double? progress;
  final String? uploadMessage;
  final bool uploadFailed;
  final String? uploadedPath;
  final int? uploadedSizeBytes;
  final bool? verifiedContentMatch;
  final String? verifiedSummary;

  ReportExportState copyWith({
    bool? busy,
    String? message,
    bool clearMessage = false,
    bool? uploading,
    double? progress,
    bool clearProgress = false,
    String? uploadMessage,
    bool clearUploadMessage = false,
    bool? uploadFailed,
    String? uploadedPath,
    int? uploadedSizeBytes,
    bool? verifiedContentMatch,
    String? verifiedSummary,
    bool clearUploadResult = false,
  }) => ReportExportState(
    busy: busy ?? this.busy,
    message: clearMessage ? null : message ?? this.message,
    uploading: uploading ?? this.uploading,
    progress: clearProgress ? null : progress ?? this.progress,
    uploadMessage: clearUploadMessage
        ? null
        : uploadMessage ?? this.uploadMessage,
    uploadFailed: uploadFailed ?? this.uploadFailed,
    uploadedPath: clearUploadResult ? null : uploadedPath ?? this.uploadedPath,
    uploadedSizeBytes: clearUploadResult
        ? null
        : uploadedSizeBytes ?? this.uploadedSizeBytes,
    verifiedContentMatch: clearUploadResult
        ? null
        : verifiedContentMatch ?? this.verifiedContentMatch,
    verifiedSummary: clearUploadResult
        ? null
        : verifiedSummary ?? this.verifiedSummary,
  );
}

final reportExportViewModelProvider =
    NotifierProvider.autoDispose<ReportExportViewModel, ReportExportState>(
      ReportExportViewModel.new,
    );

class ReportExportViewModel extends Notifier<ReportExportState> {
  @override
  ReportExportState build() {
    ref.watch(
      authenticationViewModelProvider.select((a) => a.asData?.value.userId),
    );
    return const ReportExportState();
  }

  String? get _currentUid =>
      ref.read(authenticationViewModelProvider).asData?.value.userId;

  bool _sameActiveSession(String uid) => ref.mounted && uid == _currentUid;

  Future<void> exportHistory() async {
    if (state.busy ||
        !ref.read(realBackendEnabledProvider) ||
        !ref.read(hasAuthenticatedSessionProvider)) {
      return;
    }
    final uid = _currentUid;
    if (uid == null || uid.isEmpty) return;
    final activity = ref.read(activityViewModelProvider.notifier);
    if (activity.rewardsData == null || activity.rewardsBusy) return;
    final analytics = ref.read(analyticsRepositoryProvider);
    final rows = activity.historyGroups.expand((g) => g.entries).toList();
    state = state.copyWith(busy: true, clearMessage: true);
    try {
      final size = await ref
          .read(reportExportRepositoryProvider)
          .exportHistory(rows);
      if (!_sameActiveSession(uid)) return;
      if (size != null) {
        unawaited(
          analytics.track(
            'generate_report',
            parameters: {
              'report_type': 'coin_history_csv',
              'file_size_kb': size,
            },
          ),
        );
      }
      state = state.copyWith(
        busy: false,
        message: size == null
            ? 'Đã hủy lưu tệp.'
            : 'Đã lưu báo cáo CSV (${rows.length} giao dịch đã tải).',
      );
    } catch (_) {
      if (!_sameActiveSession(uid)) return;
      unawaited(
        analytics.error(
          'generate_report',
          const AppException(
            code: 'report_failed',
            message: 'Report export failed',
          ),
        ),
      );
      state = state.copyWith(
        busy: false,
        message: 'Không lưu được báo cáo. Vui lòng thử lại.',
      );
    }
  }

  Future<void> uploadHistoryToCloud() async {
    if (state.uploading ||
        !ref.read(realBackendEnabledProvider) ||
        !ref.read(hasAuthenticatedSessionProvider)) {
      return;
    }
    final uid = _currentUid;
    if (uid == null || uid.isEmpty) return;
    final activity = ref.read(activityViewModelProvider.notifier);
    if (activity.rewardsData == null || activity.rewardsBusy) return;
    final filterLabel = ref.read(activityViewModelProvider).historyFilter;
    final analytics = ref.read(analyticsRepositoryProvider);
    final rows = activity.historyGroups.expand((g) => g.entries).toList();

    state = state.copyWith(
      uploading: true,
      progress: 0.0,
      clearUploadMessage: true,
      uploadFailed: false,
      clearUploadResult: true,
    );
    try {
      final result = await ref
          .read(reportExportRepositoryProvider)
          .uploadHistoryPdf(
            uid: uid,
            entries: rows,
            filterLabel: filterLabel,
            onProgress: (fraction) {
              if (!_sameActiveSession(uid)) return;
              state = state.copyWith(progress: fraction.clamp(0.0, 1.0));
            },
          );
      if (!_sameActiveSession(uid)) return;
      if (!result.contentMatched) {
        throw const AppException(
          code: 'report_failed',
          message: 'Tệp đã tải lên nhưng đối chiếu nội dung không khớp.',
        );
      }
      unawaited(
        analytics.track(
          'upload_report',
          parameters: {
            'report_type': 'coin_history_pdf',
            'file_size_kb': result.sizeKb,
          },
        ),
      );
      state = state.copyWith(
        uploading: false,
        progress: 1.0,
        uploadFailed: false,
        uploadedPath: result.storagePath,
        uploadedSizeBytes: result.sizeBytes,
        verifiedContentMatch: result.contentMatched,
        verifiedSummary: result.verifiedPreview,
        uploadMessage:
            'Đã tải báo cáo PDF lên Cloud Storage (${result.rowCount} giao dịch, ${result.sizeBytes} bytes).',
      );
    } catch (error) {
      if (!_sameActiveSession(uid)) return;
      final mapped = ExceptionMapper.map(error);
      unawaited(analytics.error('upload_report', mapped));
      state = state.copyWith(
        uploading: false,
        clearProgress: true,
        uploadFailed: true,
        clearUploadResult: true,
        uploadMessage: mapped.message,
      );
    }
  }
}
