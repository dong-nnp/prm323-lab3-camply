import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_routes.dart';
import '../../models/sign_up_state.dart';
import '../../theme/app_tokens.dart';
import '../../theme/app_motion.dart';
import '../../theme/evia_theme.dart';
import '../../viewmodels/sign_up_view_model.dart';
import '../../widgets/app_button.dart';
import '../../widgets/evia_brand.dart';
import '../../widgets/evia_widgets.dart';

class EviaSignUpScreen extends ConsumerStatefulWidget {
  const EviaSignUpScreen({super.key});
  @override
  ConsumerState<EviaSignUpScreen> createState() => _EviaSignUpScreenState();
}

class _EviaSignUpScreenState extends ConsumerState<EviaSignUpScreen> {
  final _controllers = List.generate(4, (_) => TextEditingController());
  final _focus = List.generate(4, (_) => FocusNode());
  final _keys = List.generate(4, (_) => GlobalKey());
  final _termsKey = GlobalKey();
  final _statusKey = GlobalKey();
  static const _fields = ['name', 'email', 'password', 'confirmation'];
  bool _keyboardOpen = false;
  bool _ensureScheduled = false;

  @override
  void initState() {
    super.initState();
    for (final focus in _focus) {
      focus.addListener(_ensureVisible);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final open = MediaQuery.viewInsetsOf(context).bottom > 0;
    if (open && !_keyboardOpen) _ensureVisible();
    _keyboardOpen = open;
  }

  void _ensureVisible() {
    if (_ensureScheduled) return;
    _ensureScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureScheduled = false;
      if (!mounted || !_keyboardOpen) return;
      final index = _focus.indexWhere((focus) => focus.hasFocus);
      if (index < 0) return;
      final target = _keys[index].currentContext;
      final box = target?.findRenderObject();
      if (target == null || box is! RenderBox || !box.hasSize) return;
      final media = MediaQuery.of(context);
      final top = box.localToGlobal(Offset.zero).dy;
      if (top >= media.padding.top + AppSpacing.sm &&
          top + box.size.height <=
              media.size.height - media.viewInsets.bottom - AppSpacing.sm) {
        return;
      }
      Scrollable.ensureVisible(
        target,
        alignment: 0.15,
        duration: media.disableAnimations
            ? Duration.zero
            : AppMotion.keyboardLayout,
        curve: AppMotion.keyboardCurve,
      );
    });
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final focus in _focus) {
      focus.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    await ref
        .read(signUpViewModelProvider.notifier)
        .createAccount(
          fullName: _controllers[0].text,
          email: _controllers[1].text,
          password: _controllers[2].text,
          confirmation: _controllers[3].text,
        );
    if (!mounted) return;
    final state = ref.read(signUpViewModelProvider);
    final errors = state.errors;
    final first = _fields.indexWhere(errors.containsKey);
    if (first >= 0) {
      _focus[first].requestFocus();
      _ensureVisible();
    } else if (errors.containsKey('terms')) {
      _revealFeedback(_termsKey);
    } else if (state.message != null && !state.isBusy) {
      _revealFeedback(_statusKey);
    }
  }

  void _revealFeedback(GlobalKey key) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final target = key.currentContext;
      if (target == null) return;
      Scrollable.ensureVisible(
        target,
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : AppMotion.keyboardLayout,
        curve: AppMotion.keyboardCurve,
      );
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  Widget _collapse(double compact, Widget child) => IgnorePointer(
    ignoring: compact > 0,
    child: ExcludeSemantics(
      excluding: compact > 0,
      child: ClipRect(
        child: Align(
          alignment: Alignment.topCenter,
          heightFactor: 1 - compact,
          child: Opacity(opacity: 1 - compact, child: child),
        ),
      ),
    ),
  );

  Widget _header(bool busy) => TweenAnimationBuilder<double>(
    tween: Tween(end: _keyboardOpen ? 1 : 0),
    duration: MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : AppMotion.keyboardLayout,
    curve: AppMotion.keyboardCurve,
    onEnd: _ensureVisible,
    builder: (context, compact, _) {
      final width =
          EviaTheme.loginLogoWidth +
          (EviaTheme.compactLoginLogoWidth - EviaTheme.loginLogoWidth) *
              compact;
      return Column(
        children: [
          _collapse(
            compact,
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: busy
                    ? null
                    : () => context.go(AppRoutes.guestDiscover),
                child: const Text('Skip'),
              ),
            ),
          ),
          Transform.translate(
            offset: EviaTheme.authContentOffset,
            child: Column(
              children: [
                SizedBox(height: AppSpacing.sm * compact),
                SizedBox(
                  width: width,
                  height:
                      EviaTheme.loginLogoHeight *
                      width /
                      EviaTheme.loginLogoWidth,
                  child: const EviaLogo(large: true),
                ),
                _collapse(
                  compact,
                  Column(
                    children: [
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Find Events.\nMake Memories.',
                        textAlign: TextAlign.center,
                        style: EviaTheme.label.copyWith(color: EviaTheme.navy),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: AppSpacing.sm * compact),
              ],
            ),
          ),
        ],
      );
    },
  );

  Widget _field(int index, SignUpState state, SignUpViewModel vm) {
    final password = index >= 2;
    final visible = index == 2 ? state.showPassword : state.showConfirmation;
    final labels = [
      'Full name',
      'Email address',
      'Password',
      'Confirm password',
    ];
    final hints = [
      'Enter your full name',
      'you@example.com',
      'Create a password',
      'Re-enter your password',
    ];
    return TextField(
      key: _keys[index],
      controller: _controllers[index],
      focusNode: _focus[index],
      enabled: !state.isBusy,
      obscureText: password && !visible,
      autocorrect: index == 0,
      enableSuggestions: index == 0,
      textCapitalization: index == 0
          ? TextCapitalization.words
          : TextCapitalization.none,
      keyboardType: index == 1
          ? TextInputType.emailAddress
          : TextInputType.text,
      textInputAction: index == 3 ? TextInputAction.done : TextInputAction.next,
      autofillHints: [
        index == 0
            ? AutofillHints.name
            : index == 1
            ? AutofillHints.email
            : AutofillHints.newPassword,
      ],
      onChanged: (_) => vm.edit(_fields[index]),
      onSubmitted: (_) =>
          index == 3 ? _submit() : _focus[index + 1].requestFocus(),
      decoration: InputDecoration(
        labelText: labels[index],
        hintText: hints[index],
        errorText: state.errors[_fields[index]],
        errorMaxLines: 3,
        prefixIcon: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: index == 0
              ? const Icon(Icons.person_outline)
              : FigmaIcon('2083:4509', index == 1 ? 'imgSvg' : 'imgSvg1'),
        ),
        suffixIcon: password
            ? IconButton(
                tooltip:
                    '${visible ? 'Hide' : 'Show'} ${index == 2 ? 'password' : 'confirm password'}',
                onPressed: state.isBusy
                    ? null
                    : index == 2
                    ? vm.togglePassword
                    : vm.toggleConfirmation,
                icon: visible
                    ? const Icon(Icons.visibility_outlined)
                    : const FigmaIcon('2083:4509', 'imgSvg2'),
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(signUpViewModelProvider);
    final vm = ref.read(signUpViewModelProvider.notifier);
    return EviaPage(
      background: AppColors.surface,
      child: Stack(
        children: [
          const Positioned.fill(child: LoginBackdrop()),
          SingleChildScrollView(
            child: AutofillGroup(
              onDisposeAction: AutofillContextAction.cancel,
              child: Column(
                children: [
                  _header(state.isBusy),
                  Transform.translate(
                    offset: EviaTheme.authContentOffset,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xl,
                          vertical: AppSpacing.lg,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(
                            EviaTheme.cardRadius,
                          ),
                          boxShadow: EviaTheme.loginShadow,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    'Create your account',
                                    style: EviaTheme.heading,
                                  ),
                                ),
                                SizedBox(width: AppSpacing.sm),
                                LimeMark(),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            const Text(
                              "Join Evia and discover events you'll love.",
                              style: EviaTheme.caption,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            for (var index = 0; index < 4; index++) ...[
                              _field(index, state, vm),
                              const SizedBox(height: AppSpacing.md),
                            ],
                            Row(
                              key: _termsKey,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Checkbox(
                                  value: state.acceptedTerms,
                                  semanticLabel: 'I agree to the Terms of Service and Privacy Policy',
                                  onChanged: state.isBusy
                                      ? null
                                      : (value) =>
                                            vm.acceptTerms(value ?? false),
                                ),
                                const Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: AppSpacing.md,
                                    ),
                                    child: Text(
                                      'I agree to the Terms of Service and Privacy Policy.',
                                      style: EviaTheme.caption,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (state.errors['terms'] case final String error)
                              Text(
                                error,
                                style: EviaTheme.caption.copyWith(
                                  color: AppColors.error,
                                ),
                              ),
                            const SizedBox(height: AppSpacing.md),
                            if (state.message case final String message) ...[
                              Semantics(
                                key: _statusKey,
                                liveRegion: true,
                                child: Text(
                                  message,
                                  style: EviaTheme.caption.copyWith(
                                    color:
                                        state.verificationRequired ||
                                            state.isBusy
                                        ? EviaTheme.navy
                                        : AppColors.error,
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                            ],
                            AppButton(
                              label:
                                  state.submission ==
                                      SignUpSubmission.waitingForSession
                                  ? 'Signing you in...'
                                  : 'Create Account',
                              isLoading:
                                  state.submission ==
                                      SignUpSubmission.account ||
                                  state.submission ==
                                      SignUpSubmission.waitingForSession,
                              trailing: const FigmaIcon(
                                '2083:4509',
                                'imgVector8',
                              ),
                              onPressed: state.isBusy ? null : _submit,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Row(
                              children: [
                                const Expanded(child: Divider()),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.md,
                                  ),
                                  child: Text(
                                    'or continue with',
                                    style: EviaTheme.caption,
                                  ),
                                ),
                                const Expanded(child: Divider()),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            OutlinedButton(
                              onPressed: state.isBusy
                                  ? null
                                  : vm.continueWithGoogle,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (state.submission ==
                                      SignUpSubmission.google)
                                    const SizedBox.square(
                                      dimension: AppSizes.progressIndicator,
                                      child: CircularProgressIndicator(),
                                    )
                                  else
                                    const FigmaIcon('2083:4509', 'imgSvg3'),
                                  const SizedBox(width: AppSpacing.sm),
                                  const Flexible(
                                    child: Text(
                                      'Continue with Google',
                                      style: EviaTheme.compactTitle,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            const SizedBox(height: AppSpacing.md),
                            Wrap(
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                const Text(
                                  'Already have an account?',
                                  style: EviaTheme.caption,
                                ),
                                TextButton(
                                  onPressed: state.isBusy
                                      ? null
                                      : () => context.go(
                                          Uri(
                                            path: AppRoutes.login,
                                            queryParameters: GoRouterState.of(
                                              context,
                                            ).uri.queryParameters,
                                          ).toString(),
                                        ),
                                  child: const Text('Log In'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
