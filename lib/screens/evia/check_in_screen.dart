import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/activity_assets.dart';
import '../../data/mock/activity_mock_data.dart';
import '../../theme/app_tokens.dart';
import '../../theme/evia_theme.dart';
import '../../theme/activity_theme.dart';
import '../../viewmodels/activity_view_model.dart';
import '../../widgets/app_button.dart';
import '../../widgets/evia_widgets.dart';
import '../../widgets/coin_icon.dart';
import '../../widgets/activity_widgets.dart';
import '../../widgets/event_qr_camera.dart';
import '../../core/providers/service_providers.dart';
import '../../models/flow1_models.dart';
import '../../viewmodels/flow1_view_model.dart';
import '../../widgets/status_widgets.dart';

class EventCheckInScreen extends ConsumerWidget {
  const EventCheckInScreen({this.eventId = '', super.key});
  final String eventId;
  Future<void> _enterCode(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Consumer(
        builder: (dialogContext, ref, _) => AlertDialog(
          title: const Text('Enter event code'),
          content: TextField(
            controller: controller,
            textCapitalization: TextCapitalization.characters,
            maxLength: 9,
            decoration: const InputDecoration(
              labelText: 'Event code',
              hintText: 'ABCD-EFGH',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed:
                  ref.watch(activityViewModelProvider).checkingInEventId != null
                  ? null
                  : () async {
                      final vm = ref.read(activityViewModelProvider.notifier);
                      final success = ref.read(realBackendEnabledProvider)
                          ? await vm.verifyWalkIn(
                              eventId,
                              controller.text,
                              manual: true,
                            )
                          : vm.checkIn(controller.text);
                      if (!context.mounted || !dialogContext.mounted) return;
                      final message =
                          ref.read(activityViewModelProvider).message ??
                          'Please retry.';
                      if (success) Navigator.pop(dialogContext);
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text(message)));
                    },
              child: const Text('Check in'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(activityViewModelProvider);
    final vm = ref.read(activityViewModelProvider.notifier);
    final live = ref.watch(realBackendEnabledProvider);
    final snapshot = live
        ? ref.watch(flow1ViewModelProvider).asData?.value
        : null;
    final event = snapshot?.events.where((e) => e.id == eventId).firstOrNull;
    final confirmed = state.verified.contains(live ? eventId : 'club-live');
    if (live && (event == null || !event.walkIn)) {
      return const EviaPage(
        child: AppErrorWidget(
          message: 'Open a walk-in event from My Events to check in.',
        ),
      );
    }
    void flash() => vm.toggleFlashlight();
    return EviaPage(
      header: ActivityHeader(
        'Event Check In',
        screen: '2083:1776',
        backAsset: 'imgContainer7',
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Toggle flashlight preview',
              onPressed: flash,
              icon: const ActivityIcon('2083:1776', 'imgContainer8'),
            ),
            IconButton(
              tooltip: 'Profile',
              onPressed: () => context.push('/'),
              icon: const CircleAvatar(
                backgroundColor: AppColors.primary,
                child: ActivityIcon('2083:1776', 'imgContainer9'),
              ),
            ),
          ],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            EviaCard(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Row(
                children: [
                  SizedBox.square(
                    dimension: EviaTheme.thumbnail - AppSpacing.lg,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.medium),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Image.asset(
                              ActivityAssets.image('2083:1776', 0),
                              fit: BoxFit.cover,
                            ),
                          ),
                          const Positioned(
                            top: AppSpacing.xs,
                            left: AppSpacing.xs,
                            child: EventBadge(
                              'CLUB',
                              category: true,
                              color: AppColors.accent,
                              foreground: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event?.title ?? 'Campus Club Fair',
                          style: EviaTheme.cardTitle,
                        ),
                        _ScanMeta(
                          event == null
                              ? 'Nov 10, 2026 · 10:00'
                              : eventDate(event.start),
                          'imgContainer',
                        ),
                        _ScanMeta(
                          event?.venue['name'] as String? ?? 'Central Plaza',
                          'imgContainer1',
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: AppSpacing.xs,
                          children: [
                            const EventBadge('Walk-in allowed'),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const CoinIcon(),
                                const SizedBox(width: AppSpacing.xs),
                                EventBadge(
                                  '+${event?.reward ?? 80} coins',
                                  color: AppColors.warningSurface,
                                  foreground: AppColors.warning,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            const Text('Scan the Event QR', style: ActivityTheme.title),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Scan the QR code displayed by the organizer to verify your attendance.',
              textAlign: TextAlign.center,
              style: EviaTheme.caption,
            ),
            const SizedBox(height: AppSpacing.xl),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.medium),
              child: SizedBox(
                height: ActivityTheme.scannerHeight,
                width: double.infinity,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: live
                          ? EventQrCamera(
                              enabled:
                                  !confirmed && state.checkingInEventId == null,
                              torch: state.flashlight,
                              onScan: (value) async {
                                await vm.verifyWalkIn(eventId, value);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        ref
                                                .read(activityViewModelProvider)
                                                .message ??
                                            'Please retry.',
                                      ),
                                    ),
                                  );
                                }
                              },
                            )
                          : Image.asset(
                              ActivityAssets.path(
                                '2083:1776',
                                'imgSimulatedCameraBackgroundWithBlurAndDarkTint',
                              ),
                              fit: BoxFit.cover,
                              color: ActivityTheme.cameraMultiply,
                              colorBlendMode: BlendMode.modulate,
                            ),
                    ),
                    const Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: ActivityTheme.scannerTint,
                        ),
                      ),
                    ),
                    Positioned(
                      left: AppSpacing.lg,
                      top: AppSpacing.md,
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: ActivityTheme.photoScrim,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.circle,
                              size: AppSpacing.sm,
                              color: AppColors.success,
                            ),
                            SizedBox(width: AppSpacing.xs),
                            Text(
                              'CAMERA PREVIEW',
                              style: TextStyle(color: AppColors.surface),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      right: AppSpacing.md,
                      top: AppSpacing.sm,
                      child: IconButton(
                        tooltip: 'Flashlight preview',
                        onPressed: flash,
                        icon: state.flashlight
                            ? const Icon(
                                Icons.flashlight_on,
                                color: AppColors.accent,
                              )
                            : const ActivityIcon('2083:1776', 'imgContainer3'),
                      ),
                    ),
                    Center(
                      child: SizedBox.square(
                        dimension: ActivityTheme.scannerFrameSize,
                        child: CustomPaint(painter: _ScannerReticle()),
                      ),
                    ),
                    Positioned(
                      left: AppSpacing.lg,
                      right: AppSpacing.lg,
                      bottom: AppSpacing.lg,
                      child: Container(
                        decoration: BoxDecoration(
                          color: ActivityTheme.photoScrim,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        child: const Row(
                          children: [
                            ActivityIcon('2083:1776', 'imgContainer4'),
                            SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                'Align the QR code inside the frame',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: AppColors.surface),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const _ScanMeta(
              "Check-in is available only during the event's check-in window.",
              'imgContainer5',
            ),
            const SizedBox(height: AppSpacing.xl),
            ActivityInfo(
              live
                  ? confirmed
                        ? 'Attendance confirmed.'
                        : state.checkingInEventId != null
                        ? 'Confirming attendance…'
                        : 'Attendance and coins are confirmed by the server.'
                  : ActivityViewModel.coinServiceMessage,
              icon: const ActivityIcon('2083:1776', 'imgContainer6'),
            ),
            const SizedBox(height: AppSpacing.section),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  vm.demoAvailable
                      ? 'Demo code: ${ActivityMockData.demoCheckInCode}'
                      : 'Having trouble scanning?',
                  style: EviaTheme.caption,
                ),
                TextButton(
                  onPressed:
                      live && !confirmed && state.checkingInEventId == null ||
                          vm.coinServiceAvailable
                      ? () => _enterCode(context, ref)
                      : null,
                  child: const Text('Enter code'),
                ),
              ],
            ),
            if (confirmed)
              AppButton(
                label: 'Attendance confirmed',
                onPressed: () => context.go('/my-events'),
              ),
          ],
        ),
      ),
    );
  }
}

class _ScannerReticle extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bracket = Paint()
      ..color = AppColors.surface
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    for (final corner in [
      (false, false),
      (true, false),
      (false, true),
      (true, true),
    ]) {
      canvas.save();
      canvas.translate(corner.$1 ? size.width : 0, corner.$2 ? size.height : 0);
      canvas.scale(corner.$1 ? -1 : 1, corner.$2 ? -1 : 1);
      canvas.drawPath(
        Path()
          ..moveTo(0, AppSpacing.xl)
          ..lineTo(0, AppRadius.small)
          ..quadraticBezierTo(0, 0, AppRadius.small, 0)
          ..lineTo(AppSpacing.xl, 0),
        bracket,
      );
      canvas.restore();
    }
    final center = Offset(size.width / 2, size.height / 2);
    final crosshair = Paint()
      ..color = AppColors.surface.withValues(alpha: .4)
      ..strokeWidth = 2;
    canvas.drawLine(
      center - const Offset(AppSpacing.lg, 0),
      center + const Offset(AppSpacing.lg, 0),
      crosshair,
    );
    canvas.drawLine(
      center - const Offset(0, AppSpacing.lg),
      center + const Offset(0, AppSpacing.lg),
      crosshair,
    );
    final beam = Rect.fromLTWH(
      AppSpacing.md,
      size.height / 2 - 13,
      size.width - AppSpacing.xl,
      AppSpacing.xs,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(beam, const Radius.circular(AppRadius.pill)),
      Paint()
        ..shader = const LinearGradient(
          colors: [Colors.transparent, AppColors.primary, Colors.transparent],
        ).createShader(beam),
    );
  }

  @override
  bool shouldRepaint(_ScannerReticle oldDelegate) => false;
}

class _ScanMeta extends StatelessWidget {
  const _ScanMeta(this.label, this.icon);
  final String label, icon;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.xs),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ActivityIcon('2083:1776', icon),
        const SizedBox(width: AppSpacing.xs),
        Expanded(child: Text(label, style: EviaTheme.caption)),
      ],
    ),
  );
}
