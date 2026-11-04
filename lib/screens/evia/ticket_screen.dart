import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/mock/activity_mock_data.dart';
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
    final event = ref.read(activityViewModelProvider.notifier).event(eventId);
    final cancelled = ref.watch(
      activityViewModelProvider.select((s) => s.cancelled.contains(event.id)),
    );
    return EviaPage(
      header: const ActivityHeader(
        'My Ticket',
        screen: '2083:2345',
        backAsset: 'imgContainer2',
      ),
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
                                  'Organized by Student Union',
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
                                const Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: _TicketField(
                                        'ATTENDEE',
                                        ActivityMockData.attendee,
                                      ),
                                    ),
                                    SizedBox(width: AppSpacing.lg),
                                    Expanded(
                                      child: _TicketField(
                                        'STUDENT ID',
                                        ActivityMockData.studentId,
                                      ),
                                    ),
                                  ],
                                ),
                                const Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: _TicketField(
                                        'PASS TYPE',
                                        'General',
                                      ),
                                    ),
                                    SizedBox(width: AppSpacing.lg),
                                    Expanded(
                                      child: _TicketField(
                                        'TICKET NO.',
                                        ActivityMockData.ticketNumber,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          const EviaCard(
                            padding: EdgeInsets.all(AppSpacing.md),
                            child: ActivityIcon(
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
