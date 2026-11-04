import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/mock/registration_mock_data.dart';
import '../../models/registration_models.dart';
import '../../theme/app_tokens.dart';
import '../../theme/evia_theme.dart';
import '../../theme/flow_theme.dart';
import '../../viewmodels/activity_view_model.dart';
import '../../viewmodels/registration_view_model.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/activity_widgets.dart';
import '../../widgets/evia_widgets.dart';
import '../../widgets/event_flow_widgets.dart';

class RegistrationFormScreen extends ConsumerStatefulWidget {
  const RegistrationFormScreen({
    this.view = 'default',
    this.eventId = 'music-live',
    this.resume = false,
    super.key,
  });
  final String view, eventId;
  final bool resume;
  @override
  ConsumerState<RegistrationFormScreen> createState() =>
      _RegistrationFormScreenState();
}

class _RegistrationFormScreenState
    extends ConsumerState<RegistrationFormScreen> {
  final _fields = <String, TextEditingController>{
    for (final key in ['name', 'studentId', 'email', 'phone'])
      key: TextEditingController(),
  };
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted && !widget.resume) {
        ref
            .read(registrationViewModelProvider.notifier)
            .preset(widget.view, widget.eventId);
      }
    });
  }

  @override
  void dispose() {
    for (final field in _fields.values) {
      field.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    final status = await ref
        .read(registrationViewModelProvider.notifier)
        .submit();
    if (!mounted) return;
    switch (status) {
      case RegistrationStatus.success:
        context.go('/registration/success');
      case RegistrationStatus.failed:
        context.push('/registration/failed');
      case RegistrationStatus.full:
        context.go('/registration/full');
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(registrationViewModelProvider);
    final vm = ref.read(registrationViewModelProvider.notifier);
    final legacy = widget.view.startsWith('legacy') || widget.view == 'loading';
    final errors = widget.view.endsWith('error') || state.errors.isNotEmpty;
    final loading =
        widget.view == 'loading' || state.status == RegistrationStatus.loading;
    final screen = widget.view == 'loading'
        ? '2083:5987'
        : legacy
        ? errors
              ? '2083:4627'
              : '2083:5029'
        : errors
        ? '2083:5329'
        : '2083:5709';
    final event = vm.event(state.eventId);
    final data = {
      'name': state.name,
      'studentId': state.studentId,
      'email': state.email,
      'phone': state.phone,
    };
    for (final entry in data.entries) {
      if (_fields[entry.key]!.text != entry.value) {
        _fields[entry.key]!.value = TextEditingValue(
          text: entry.value,
          selection: TextSelection.collapsed(offset: entry.value.length),
        );
      }
    }
    final backAsset = screen == '2083:5987'
        ? 'imgContainer2'
        : legacy && !errors
        ? 'imgContainer5'
        : legacy || errors
        ? 'imgButtonGoBackSvg'
        : 'imgContainer9';
    final body = SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FlowEventSummary(
            screen: screen,
            event: event,
            form: true,
            legacy: legacy,
            legacyError: screen == '2083:4627',
          ),
          const SizedBox(height: AppSpacing.xl),
          const Text('Your Information', style: EviaTheme.section),
          const SizedBox(height: AppSpacing.xs),
          Text(
            legacy
                ? 'Please provide your student details to reserve your ticket.'
                : 'Confirm your student details to reserve your spot.',
            style: EviaTheme.caption,
          ),
          const SizedBox(height: AppSpacing.xl),
          for (var index = 0; index < 4; index++) ...[
            _RegistrationField(
              index: index,
              controller:
                  _fields[['name', 'studentId', 'email', 'phone'][index]]!,
              screen: screen,
              legacy: legacy,
              errors: errors,
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          if (!legacy) ...[
            _DepositSummary(screen: screen),
            const SizedBox(height: AppSpacing.lg),
          ],
          if (widget.view != 'loading') ...[
            _RegistrationNotice(screen: screen, legacy: legacy),
            const SizedBox(height: AppSpacing.lg),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (screen == '2083:5709')
                  Semantics(
                    checked: state.agreed,
                    label: 'Accept registration and deposit terms',
                    child: InkWell(
                      onTap: loading ? null : () => vm.agree(!state.agreed),
                      child: SizedBox.square(
                        dimension: AppSizes.minimumTouchTarget,
                        child: Center(
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: state.agreed
                                  ? AppColors.primary
                                  : AppColors.surface,
                              border: Border.all(color: AppColors.border),
                              borderRadius: BorderRadius.circular(
                                AppSpacing.xs,
                              ),
                            ),
                            child: state.agreed
                                ? const Center(
                                    child: ActivityIcon(
                                      '2083:5709',
                                      'imgContainer7',
                                    ),
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  Checkbox(
                    value: state.agreed,
                    onChanged: loading
                        ? null
                        : (value) => vm.agree(value ?? false),
                    side: BorderSide(
                      color: state.errors.containsKey('terms') && !legacy
                          ? FlowTheme.error
                          : AppColors.border,
                    ),
                  ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: legacy
                        ? const Text(
                            "I understand that I'll receive an attendance reminder before the event.",
                          )
                        : Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              const Text('I agree to the '),
                              InkWell(
                                onTap: () => _terms(context),
                                child: const Text(
                                  'event registration and deposit terms.',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ],
          if (state.errors.containsKey('terms') && !legacy)
            Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.lg,
                top: AppSpacing.sm,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ActivityIcon('2083:5329', 'imgSvg5'),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      state.errors['terms']!,
                      style: FlowTheme.helpText.copyWith(
                        color: FlowTheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
    final footer = Container(
      color: AppColors.surface,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: SizedBox(
        width: double.infinity,
        child: AppButton(
          label: 'Confirm Registration',
          onPressed: loading || (legacy && !state.agreed) ? null : _submit,
          trailing: widget.view == 'loading'
              ? null
              : ActivityIcon(
                  screen,
                  legacy
                      ? errors
                            ? 'imgVector'
                            : 'imgContainer4'
                      : errors
                      ? 'imgVector2'
                      : 'imgContainer8',
                ),
        ),
      ),
    );
    final page = Column(
      children: [
        ActivityHeader(
          'Event Registration',
          screen: screen,
          backAsset: backAsset,
        ),
        Expanded(child: body),
        footer,
      ],
    );
    return EviaPage(
      child: loading
          ? ActivityOverlay(
              background: page,
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ActivityIcon(
                    '2083:5987',
                    'imgSmoothAnimatedSvgCircleSpinner',
                  ),
                  SizedBox(height: AppSpacing.xl),
                  Text(
                    'Confirming your\nregistration...',
                    textAlign: TextAlign.center,
                    style: EviaTheme.section,
                  ),
                  SizedBox(height: AppSpacing.sm),
                  Text('Please wait a moment.', style: EviaTheme.caption),
                  SizedBox(height: AppSpacing.lg),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.circle,
                        size: AppSpacing.xs,
                        color: AppColors.primary,
                      ),
                      SizedBox(width: AppSpacing.sm),
                      Icon(
                        Icons.circle,
                        size: AppSpacing.xs,
                        color: AppColors.accent,
                      ),
                      SizedBox(width: AppSpacing.sm),
                      Icon(
                        Icons.circle,
                        size: AppSpacing.xs,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ],
              ),
            )
          : page,
    );
  }
}

void _terms(BuildContext context) => showActivityHelp(
  context,
  'Registration and deposit terms',
  'A 100-coin deposit is temporarily held for this event. Attendance rewards are credited only after verified check-in. Refunds and cancellations follow the event deposit policy.',
);

class _RegistrationField extends ConsumerWidget {
  const _RegistrationField({
    required this.index,
    required this.controller,
    required this.screen,
    required this.legacy,
    required this.errors,
  });
  final int index;
  final TextEditingController controller;
  final String screen;
  final bool legacy, errors;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(registrationViewModelProvider);
    final vm = ref.read(registrationViewModelProvider.notifier);
    final field = ['name', 'studentId', 'email', 'phone'][index];
    final label = [
      'Full Name',
      'Student ID',
      legacy && screen != '2083:4627' ? 'Email' : 'University Email',
      'Phone Number',
    ][index];
    final error = state.errors[field];
    final loadingReference = screen == '2083:5987';
    final leading = legacy
        ? errors
              ? null
              : ['imgIcon', 'imgIcon1', 'imgIcon2', 'imgIcon3'][index]
        : errors
        ? ['imgSvg3', 'imgSvg6', 'imgSvg7', 'imgSvg8'][index]
        : ['imgIcon', 'imgIcon1', 'imgIcon2', 'imgIcon3'][index];
    final suffix = legacy ? 'imgSvg3' : 'imgSvg4';
    final errorAsset = legacy ? 'imgSvg4' : 'imgSvg5';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextField(
          label: label,
          controller: controller,
          onChanged: (value) => vm.edit(field, value),
          keyboardType: index == 2
              ? TextInputType.emailAddress
              : index == 3
              ? TextInputType.phone
              : TextInputType.text,
          hintText: [
            'e.g. Alex Morgan',
            'e.g. STU-2024-890',
            'e.g. alex.m@university.edu',
            'e.g., +1 (555) 019-2834',
          ][index],
          labelWidget: Row(
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    text: label,
                    children: [
                      TextSpan(
                        text: index == 3 ? ' (optional)' : ' *',
                        style: index == 3
                            ? FlowTheme.helpText
                            : FlowTheme.required,
                      ),
                    ],
                  ),
                  style: FlowTheme.fieldLabel,
                ),
              ),
              if (!legacy &&
                  !errors &&
                  index == 1 &&
                  state.studentId == RegistrationMockData.studentId)
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: AppColors.successSurface,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ActivityIcon('2083:5709', 'imgContainer3'),
                      SizedBox(width: AppSpacing.xs),
                      Text(
                        'Account verified',
                        style: TextStyle(color: AppColors.success),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          prefixIcon: loadingReference || leading == null
              ? null
              : Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Center(
                    widthFactor: 1,
                    heightFactor: 1,
                    child: ActivityIcon(screen, leading),
                  ),
                ),
          suffixIcon: error == null || loadingReference
              ? null
              : Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Center(
                    widthFactor: 1,
                    heightFactor: 1,
                    child: ActivityIcon(screen, suffix),
                  ),
                ),
          errorText: error,
          errorWidget: error == null || loadingReference
              ? null
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ActivityIcon(screen, errorAsset),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        error,
                        style: FlowTheme.helpText.copyWith(
                          color: FlowTheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
        if (screen == '2083:5029' && (index == 1 || index == 2))
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Row(
              children: [
                ActivityIcon(
                  screen,
                  index == 1 ? 'imgContainer2' : 'imgContainer3',
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    index == 1
                        ? 'Must match your student ID card'
                        : 'Ticket pass will be delivered here',
                    style: EviaTheme.caption,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _DepositSummary extends ConsumerWidget {
  const _DepositSummary({required this.screen});
  final String screen;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balance = ref.watch(
      activityViewModelProvider.select((s) => s.available),
    );
    final error = screen == '2083:5329';
    return EviaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (error) ...[
            const Text('Coins & Deposit', style: EviaTheme.cardTitle),
            const SizedBox(height: AppSpacing.lg),
          ],
          Row(
            children: [
              CircleAvatar(
                radius: AppSpacing.lg,
                backgroundColor: AppColors.warningSurface,
                child: error
                    ? const LayeredFlowCoin(screen: '2083:5329', symbol: 'C')
                    : ActivityIcon(screen, 'imgContainer4'),
              ),
              const SizedBox(width: AppSpacing.md),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Attendance Reward', style: EviaTheme.label),
                    Text(
                      'Earned after verified event check-in',
                      style: EviaTheme.caption,
                    ),
                  ],
                ),
              ),
              const Flexible(
                child: Text(
                  '+120 coins',
                  textAlign: TextAlign.right,
                  style: TextStyle(color: AppColors.warning),
                ),
              ),
            ],
          ),
          const Divider(height: AppSpacing.xl),
          Row(
            children: [
              CircleAvatar(
                radius: AppSpacing.lg,
                backgroundColor: AppColors.primarySoft,
                child: ActivityIcon(
                  screen,
                  error ? 'imgSvg9' : 'imgContainer5',
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Registration Deposit', style: EviaTheme.label),
                    Text(
                      'Temporarily held in your wallet',
                      style: EviaTheme.caption,
                    ),
                  ],
                ),
              ),
              const Flexible(child: Text('100 coins', style: EviaTheme.label)),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(AppRadius.small),
            ),
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                Text('Available Coins: $balance', style: EviaTheme.caption),
                const Text('•'),
                const Text('Deposit: 100', style: EviaTheme.caption),
                const Text('•'),
                Text(
                  'After: ${balance - 100}',
                  style: EviaTheme.caption.copyWith(color: AppColors.primary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RegistrationNotice extends StatelessWidget {
  const _RegistrationNotice({required this.screen, required this.legacy});
  final String screen;
  final bool legacy;
  @override
  Widget build(BuildContext context) => EviaCard(
    color: AppColors.primarySoft,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (screen != '2083:5987')
          ActivityIcon(
            screen,
            legacy
                ? screen == '2083:4627'
                      ? 'imgSvg5'
                      : 'imgSvg'
                : screen == '2083:5329'
                ? 'imgSvg10'
                : 'imgContainer6',
          ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Before You Register', style: EviaTheme.label),
              const SizedBox(height: AppSpacing.sm),
              Text(
                legacy
                    ? "We'll ask you to confirm your attendance 2–3 days before the event."
                    : "A 100-coin deposit will be temporarily held. Check in at the event to receive attendance rewards. Refunds and cancellations follow the event's deposit policy.",
                style: FlowTheme.helpText,
              ),
              if (legacy) ...[
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  "If you can't attend, please cancel to free up your spot. Your ticket stays valid even if you miss the reminder.",
                  style: FlowTheme.helpText,
                ),
              ] else
                TextButton(
                  onPressed: () => _terms(context),
                  child: const Text('View deposit & cancellation policy →'),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}
