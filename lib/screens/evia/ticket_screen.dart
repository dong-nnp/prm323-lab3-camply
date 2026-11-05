import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/mock/activity_mock_data.dart';

import 'package:qr_flutter/qr_flutter.dart';

import '../../core/providers/service_providers.dart';
import '../../core/utils/exception_mapper.dart';
import '../../models/flow1_models.dart';
import '../../models/activity_models.dart';
import '../../viewmodels/flow1_view_model.dart';
import '../../widgets/status_widgets.dart';

import 'package:flutter/foundation.dart';

import '../../theme/app_tokens.dart';
import '../../theme/evia_theme.dart';
import '../../theme/activity_theme.dart';
import '../../viewmodels/activity_view_model.dart';
import '../../widgets/evia_widgets.dart';
import '../../widgets/activity_widgets.dart';

class TicketScreen extends ConsumerWidget {
  const TicketScreen({this.eventId = 'music', super.key});
  final String eventId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final live = ref.watch(realBackendEnabledProvider);
    if (live) ref.watch(flow1ViewModelProvider);
    final remote = live ? ref.watch(flow1TicketProvider(eventId)) : null;
    if (remote != null &&
        (remote.isLoading || remote.hasError || !remote.hasValue)) {
      return EviaPage(
        child: Center(
          child: remote.hasError
              ? AppErrorWidget(
                  message: ExceptionMapper.map(remote.error!).message,
                  onRetry: () => ref.invalidate(flow1TicketProvider(eventId)),
                )
              : const AppLoadingWidget(),
        ),
      );
    }
    final ticket = remote?.asData?.value;
    final details = ticket == null ? null : jsonMap(ticket['ticket']);
    final registration = ticket == null
        ? null
        : jsonMap(ticket['registration']);
    final person = registration == null
        ? null
        : jsonMap(registration['attendeeSnapshot']);
    final qr = ticket?['qr'] == null ? null : jsonMap(ticket!['qr']);
    final event = live
        ? ticket!['eventPresentation'] as RegisteredEvent
        : ref.read(activityViewModelProvider.notifier).event(eventId);
    final cancelled = live
        ? (registration?['state'] == 'cancelled' ||
              details?['status'] == 'revoked')
        : ref.watch(
            activityViewModelProvider.select(
              (s) => s.cancelled.contains(event.id),
            ),
          );
    return EviaPage(
      header: const ActivityHeader(
        'My Ticket',
        screen: '2083:2345',
        backAsset: 'imgContainer2',
      ),
      footer:
          kDebugMode &&
              live &&
              ref
                  .read(activityViewModelProvider.notifier)
                  .demoCheckInAvailable(eventId) &&
              details?['status'] == 'active'
          ? Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.xs,
              ),
              child: TextButton(
                onPressed:
                    ref.watch(activityViewModelProvider).checkingInEventId !=
                        null
                    ? null
                    : () async {
                        final vm = ref.read(activityViewModelProvider.notifier);
                        await vm.demoAttend(eventId);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                ref.read(activityViewModelProvider).message ??
                                    'Please retry.',
                              ),
                            ),
                          );
                        }
                      },
                child: const Text('Demo: xác nhận đã quét'),
              ),
            )
          : null,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            if (event.walkIn)
              const EviaCard(
                child: Text(
                  'This walk-in event does not require a ticket. Scan the event QR at the venue to check in.',
                ),
              )
            else if (cancelled)
              const EviaCard(
                child: Text(
                  'This registration was cancelled. Your ticket is no longer available.',
                ),
              )
            else
              Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.large),
                  border: Border.all(color: AppColors.border),
                  boxShadow: EviaTheme.cardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: ActivityTheme.ticketStripe,
                      child: CustomPaint(painter: _TicketStripe()),
                    ),
                    Container(
                      color: AppColors.primary,
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          EventBadge(
                            event.category.toUpperCase(),
                            category: true,
                            color: AppColors.accent,
                            foreground: AppColors.textPrimary,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            event.title,
                            style: ActivityTheme.title.copyWith(
                              color: AppColors.surface,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Row(
                            children: [
                              const ActivityIcon('2083:2345', 'imgContainer'),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  live
                                      ? 'Organized by ${ref.read(flow1ViewModelProvider).asData?.value.organizerName(Flow1Event(jsonMap(ticket!['event'])).organizerId) ?? 'Organizer'}'
                                      : 'Organized by Student Union',
                                  style: EviaTheme.caption.copyWith(
                                    color: AppColors.surface,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl,
                        vertical: AppSpacing.lg,
                      ),
                      child: _Perforation(),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        children: [
                          EviaCard(
                            color: AppColors.surfaceMuted,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _TicketField(
                                  'DATE & TIME',
                                  event.id == 'music'
                                      ? 'Monday, Oct 26, 2026 • 18:00 – 22:00'
                                      : event.dateLabel,
                                ),
                                _TicketField(
                                  'VENUE',
                                  event.id == 'music'
                                      ? 'Main Stadium · Gate 4'
                                      : event.venue,
                                ),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: _TicketField(
                                        'ATTENDEE',
                                        person?['fullName'] as String? ??
                                            ActivityMockData.attendee,
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.lg),
                                    Expanded(
                                      child: _TicketField(
                                        'STUDENT ID',
                                        person?['studentId'] as String? ??
                                            ActivityMockData.studentId,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Expanded(
                                      child: _TicketField(
                                        'PASS TYPE',
                                        'General',
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.lg),
                                    Expanded(
                                      child: _TicketField(
                                        'TICKET NO.',
                                        details?['ticketNumber'] as String? ??
                                            ActivityMockData.ticketNumber,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          EviaCard(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: live
                                ? (details?['status'] == 'checked_in'
                                      ? const SizedBox(
                                          width: 208,
                                          height: 208,
                                          child: Center(
                                            child: Text('Attendance confirmed'),
                                          ),
                                        )
                                      : (qr != null &&
                                                DateTime.parse(
                                                  qr['expiresAt'] as String,
                                                ).isAfter(
                                                  DateTime.now().toUtc(),
                                                )
                                            ? QrImageView(
                                                data: qr['qrPayload'] as String,
                                                size: 208,
                                                padding: EdgeInsets.zero,
                                              )
                                            : AppErrorWidget(
                                                message: 'Ticket QR is unavailable. Please retry.',
                                                onRetry: () => ref.invalidate(
                                                  flow1TicketProvider(eventId),
                                                ),
                                              )))
                                : const ActivityIcon(
                                    '2083:2345',
                                    'imgSvgTicketQrCode',
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: AppSpacing.lg),
            const ActivityInfo(
              'Show this QR code and your student ID at the entrance.',
              color: AppColors.surface,
              icon: ActivityIcon('2083:2345', 'imgContainer1'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TicketField extends StatelessWidget {
  const _TicketField(this.label, this.value);
  final String label, value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.lg),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: ActivityTheme.smallLabel.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(value, style: EviaTheme.label),
      ],
    ),
  );
}

class _Perforation extends StatelessWidget {
  const _Perforation();
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => Row(
      children: [
        for (var i = 0; i < constraints.maxWidth ~/ AppSpacing.md; i++)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs / 2,
              ),
              child: Container(height: 1, color: AppColors.border),
            ),
          ),
      ],
    ),
  );
}

class _TicketStripe extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.primary);
    final paint = Paint()..color = AppColors.accent;
    for (double x = -AppSpacing.md; x < size.width; x += AppSpacing.xl) {
      canvas.drawPath(
        Path()
          ..moveTo(x, 0)
          ..lineTo(x + AppSpacing.md, 0)
          ..lineTo(x + AppSpacing.md + size.height, size.height)
          ..lineTo(x + size.height, size.height)
          ..close(),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_TicketStripe oldDelegate) => false;
}
