import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/flow_assets.dart';
import '../../data/mock/registration_mock_data.dart';
import '../../models/registration_models.dart';
import '../../theme/app_tokens.dart';
import '../../theme/evia_theme.dart';
import '../../viewmodels/registration_view_model.dart';
import '../../widgets/activity_widgets.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_feedback.dart';
import '../../widgets/evia_widgets.dart';
import '../../widgets/coin_icon.dart';
import '../../widgets/event_flow_widgets.dart';
import '../../viewmodels/flow1_view_model.dart';
import '../../core/providers/service_providers.dart';
import '../../core/utils/exception_mapper.dart';
import '../../widgets/status_widgets.dart';
import 'registration_form_screen.dart';

class RegistrationResultScreen extends ConsumerWidget {
  const RegistrationResultScreen({required this.view, this.eventId, super.key});
  final String view;
  final String? eventId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final going = view == 'going',
        full = view == 'full',
        failed = view == 'failed';
    final screen = going
        ? '2083:5861'
        : full
        ? '2083:5931'
        : failed
        ? '2083:6200'
        : '2083:4961';
    final vm = ref.read(registrationViewModelProvider.notifier);
    final state = ref.watch(registrationViewModelProvider);
    final live = ref.watch(realBackendEnabledProvider);
    final id = eventId ?? state.eventId;
    final ticket = live && !going && !failed && !full
        ? ref.watch(flow1TicketProvider(id))
        : null;
    if (ticket != null && !ticket.hasValue) {
      if (!ticket.hasError) {
        return RegistrationLoadingOverlay(
          background:
              state.eventId == id && state.status == RegistrationStatus.success
              ? RegistrationFormScreen(eventId: id, resume: true)
              : const EviaPage(child: SizedBox.expand()),
        );
      }
      return EviaPage(
        child: Center(
          child: AppErrorWidget(
            message: ExceptionMapper.map(ticket.error!).message,
            onRetry: () => ref.invalidate(flow1TicketProvider(id)),
          ),
        ),
      );
    }
    final event = going && !live && state.status != RegistrationStatus.going
        ? RegistrationMockData.club
        : vm.event(id);
    void back() {
      vm.backToForm();
      context.go(
        live
            ? '/registration?resume=true&event=$id'
            : '/registration?resume=true',
      );
    }

    Future<void> retry() async {
      final status = await vm.submit();
      if (!context.mounted) return;
      if (status == RegistrationStatus.success) {
        context.go(
          live ? '/registration/success?event=$id' : '/registration/success',
        );
      } else if (status == RegistrationStatus.idle) {
        back();
      } else if (status == RegistrationStatus.failed) {
        AppFeedback.show(
          context,
          ref.read(registrationViewModelProvider).message ??
              'Please try again.',
          isError: true,
        );
      }
    }

    return EviaPage(
      header: failed
          ? ActivityHeader(
              'Event Registration',
              screen: screen,
              backAsset: 'imgContainer1',
            )
          : null,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: failed
                  ? 150
                  : full
                  ? AppSpacing.xl
                  : going
                  ? 0
                  : 100,
            ),
            Center(
              child: Image.asset(
                FlowAssets.image(screen, 0),
                width: 220,
                height: going || full ? 144 : 190,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              failed
                  ? "Couldn't submit\nregistration"
                  : full
                  ? 'Registration Unavailable'
                  : going
                  ? "You're Going!"
                  : 'Registration Successful!',
              textAlign: TextAlign.center,
              style: going || failed
                  ? EviaTheme.heading
                  : EviaTheme.section.copyWith(fontSize: 22),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              failed
                  ? state.message ??
                        'Registration service is unavailable. Please try again.'
                  : full
                  ? "Sorry, the last spots were just taken. Your registration wasn't completed."
                  : going
                  ? 'Added to My Events. See you there!'
                  : "You're registered — see you there!",
              textAlign: TextAlign.center,
              style: EviaTheme.caption,
            ),
            SizedBox(height: full ? 90 : AppSpacing.xl),
            if (!failed)
              FlowEventSummary(screen: screen, event: event, full: full),
            if (failed) ...[
              const SizedBox(height: 150),
              AppButton(
                label: 'Try Again',
                isLoading: state.status == RegistrationStatus.loading,
                onPressed: state.status == RegistrationStatus.loading
                    ? null
                    : retry,
                leading: ActivityIcon(screen, 'imgContainer'),
              ),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton(
                onPressed: back,
                child: const Text('Back to Form'),
              ),
            ] else ...[
              const SizedBox(height: AppSpacing.lg),
              if (going) ...[
                _ResultNotice(
                  screen: screen,
                  icon: 'imgContainer2',
                  title: 'Check in at the event',
                  body: "When check-in opens, scan the organizer's QR code at the venue to verify your attendance.",
                ),
                const SizedBox(height: AppSpacing.md),
                if (event.coins > 0)
                  _ResultNotice(
                    screen: screen,
                    icon: 'imgContainer3',
                    title: 'Earn +${event.coins} coins after verified check-in',
                    leading: const CoinIcon(),
                    body: 'Coins and milestone progress are credited upon scanning the event QR at the door.',
                    color: AppColors.warningSurface,
                  ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ActivityIcon(screen, 'imgMargin'),
                    const SizedBox(width: AppSpacing.sm),
                    const Flexible(
                      child: Text(
                        'No ticket or coin deposit required.\nMarking Going saves this to your schedule, but does not guarantee a reserved seat.',
                        style: EviaTheme.caption,
                      ),
                    ),
                  ],
                ),
              ] else if (full)
                Padding(
                  padding: const EdgeInsets.only(top: 60),
                  child: _ResultNotice(
                    screen: screen,
                    icon: 'imgContainer2',
                    title: '',
                    body: 'Registration is full. You can try again if another attendee cancels and a place opens.',
                  ),
                )
              else ...[
                if (event.deposit > 0)
                  _ResultNotice(
                    screen: screen,
                    icon: 'imgContainer2',
                    title: '${event.deposit} coins on hold',
                    body: 'Your event deposit is temporarily locked.',
                  ),
                const SizedBox(height: AppSpacing.md),
                _ResultNotice(
                  screen: screen,
                  icon: 'imgContainer3',
                  title: '',
                  body: "We'll notify you about important updates before the event.",
                ),
              ],
              SizedBox(height: full ? 72 : AppSpacing.xl),
              AppButton(
                label: going
                    ? 'View My Events'
                    : full
                    ? 'Explore Other Events'
                    : 'View My Digital Ticket',
                leading: going || full
                    ? null
                    : ActivityIcon(screen, 'imgContainer4'),
                trailing: going || full
                    ? ActivityIcon(
                        screen,
                        going ? 'imgContainer4' : 'imgContainer3',
                      )
                    : ActivityIcon(screen, 'imgContainer5'),
                onPressed: () {
                  if (full) {
                    context.go('/explore');
                  } else {
                    context.go(
                      going
                          ? '/my-events'
                          : '/my-events/ticket?event=${event.id}',
                    );
                  }
                },
              ),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton(
                onPressed: () => context.go(
                  going || full
                      ? Uri(
                          path: '/event/schedule',
                          queryParameters: {
                            'event':
                                going &&
                                    state.status != RegistrationStatus.going
                                ? event.id
                                : state.eventId,
                          },
                        ).toString()
                      : '/discover',
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!going)
                      ActivityIcon(
                        screen,
                        full ? 'imgContainer4' : 'imgContainer6',
                      ),
                    const SizedBox(width: AppSpacing.sm),
                    Flexible(
                      child: Text(
                        going || full ? 'Back to Event' : 'Back to Discover',
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}

class _ResultNotice extends StatelessWidget {
  const _ResultNotice({
    required this.screen,
    required this.icon,
    required this.title,
    required this.body,
    this.color = AppColors.primarySoft,
    this.leading,
  });
  final String screen, icon, title, body;
  final Color color;
  final Widget? leading;
  @override
  Widget build(BuildContext context) => EviaCard(
    color: color,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        leading ?? ActivityIcon(screen, icon),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title.isNotEmpty) ...[
                Text(title, style: EviaTheme.label),
                const SizedBox(height: AppSpacing.xs),
              ],
              Text(body, style: EviaTheme.caption),
            ],
          ),
        ),
      ],
    ),
  );
}
