import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers/repository_providers.dart';
import '../core/providers/service_providers.dart';
import '../core/errors/app_exception.dart';
import 'activity_view_model.dart';
import 'authentication_view_model.dart';

typedef ReportExportState = ({bool busy, String? message});
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
    return (busy: false, message: null);
  }

  Future<void> exportHistory() async {
    if (state.busy ||
        !ref.read(realBackendEnabledProvider) ||
        !ref.read(hasAuthenticatedSessionProvider)) {
      return;
    }
    final uid = ref.read(authenticationViewModelProvider).asData!.value.userId;
    final activity = ref.read(activityViewModelProvider.notifier);
    if (activity.rewardsData == null || activity.rewardsBusy) return;
    final analytics = ref.read(analyticsRepositoryProvider);
    final rows = activity.historyGroups.expand((g) => g.entries).toList();
    state = (busy: true, message: null);
    try {
      final size = await ref
          .read(reportExportRepositoryProvider)
          .exportHistory(rows);
      if (!ref.mounted ||
          uid !=
              ref.read(authenticationViewModelProvider).asData?.value.userId) {
        return;
      }
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
      state = (
        busy: false,
        message: size == null
            ? 'Đã hủy lưu tệp.'
            : 'Đã lưu báo cáo CSV (${rows.length} giao dịch đã tải).',
      );
    } catch (_) {
      if (!ref.mounted ||
          uid !=
              ref.read(authenticationViewModelProvider).asData?.value.userId) {
        return;
      }
      unawaited(
        analytics.error(
          'generate_report',
          const AppException(
            code: 'report_failed',
            message: 'Report export failed',
          ),
        ),
      );
      state = (
        busy: false,
        message: 'Không lưu được báo cáo. Vui lòng thử lại.',
      );
    }
  }
}
