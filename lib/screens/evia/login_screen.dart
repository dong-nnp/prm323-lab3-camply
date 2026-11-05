import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_tokens.dart';
import '../../theme/app_motion.dart';
import '../../theme/evia_theme.dart';
import '../../viewmodels/evia_view_model.dart';
import '../../widgets/app_button.dart';
import '../../widgets/evia_brand.dart';
import '../../widgets/evia_widgets.dart';

class EviaLoginScreen extends ConsumerStatefulWidget {
  const EviaLoginScreen({super.key});
  @override
  ConsumerState<EviaLoginScreen> createState() => _EviaLoginScreenState();
}

class _EviaLoginScreenState extends ConsumerState<EviaLoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _emailKey = GlobalKey();
  final _passwordKey = GlobalKey();
  bool _keyboardOpen = false;
  bool _visibilityScheduled = false;

  @override
  void initState() {
    super.initState();
    _emailFocus.addListener(_scheduleEnsureVisible);
    _passwordFocus.addListener(_scheduleEnsureVisible);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final open = MediaQuery.viewInsetsOf(context).bottom > 0;
    if (open && !_keyboardOpen) _scheduleEnsureVisible();
    _keyboardOpen = open;
  }

  void _scheduleEnsureVisible() {
    if (_visibilityScheduled) return;
    _visibilityScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _visibilityScheduled = false;
      if (!mounted || !_keyboardOpen) return;
      final fieldContext = _emailFocus.hasFocus
          ? _emailKey.currentContext
          : _passwordFocus.hasFocus
          ? _passwordKey.currentContext
          : null;
      final box = fieldContext?.findRenderObject();
      if (fieldContext == null || box is! RenderBox || !box.hasSize) return;
      final media = MediaQuery.of(context);
      final top = box.localToGlobal(Offset.zero).dy;
      final bottom = top + box.size.height;
      if (top >= media.padding.top + AppSpacing.sm &&
          bottom <=
              media.size.height - media.viewInsets.bottom - AppSpacing.sm) {
        return;
      }
      Scrollable.ensureVisible(
        fieldContext,
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
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(eviaViewModelProvider);
    final vm = ref.read(eviaViewModelProvider.notifier);
    return EviaPage(
      background: AppColors.surface,
      child: Stack(
        children: [
          const Positioned.fill(child: LoginBackdrop()),
          SingleChildScrollView(
            child: Column(
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(end: _keyboardOpen ? 1 : 0),
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : AppMotion.keyboardLayout,
                  curve: AppMotion.keyboardCurve,
                  onEnd: _scheduleEnsureVisible,
                  builder: (context, compact, _) {
                    final logoWidth =
                        EviaTheme.loginLogoWidth +
                        (EviaTheme.compactLoginLogoWidth -
                                EviaTheme.loginLogoWidth) *
                            compact;
                    return Column(
                      children: [
                        _CollapsingHeaderSection(
                          compact: compact,
                          child: Column(
                            children: [
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () =>
                                      context.go('/discover/guest'),
                                  child: const Text('Skip'),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Transform.translate(
                          offset: EviaTheme.authContentOffset,
                          child: Column(
                            children: [
                              SizedBox(height: AppSpacing.sm * compact),
                              SizedBox(
                                width: logoWidth,
                                height:
                                    EviaTheme.loginLogoHeight *
                                    logoWidth /
                                    EviaTheme.loginLogoWidth,
                                child: const EviaLogo(large: true),
                              ),
                              _CollapsingHeaderSection(
                                key: const ValueKey('login-illustration'),
                                compact: compact,
                                child: Column(
                                  children: [
                                    const SizedBox(height: AppSpacing.xs),
                                    Text(
                                      'Find Events.\nMake Memories.',
                                      textAlign: TextAlign.center,
                                      style: EviaTheme.label.copyWith(
                                        color: EviaTheme.navy,
                                      ),
                                    ),
                                    const Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: AppSpacing.lg,
                                      ),
                                      child: LoginCollage(),
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
                ),
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
                            children: [
                              Expanded(
                                child: Text(
                                  'Welcome back!',
                                  style: EviaTheme.loginHeading,
                                ),
                              ),
                              LimeMark(),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          const Text(
                            "Discover events and experiences you'll love.",
                            style: EviaTheme.caption,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TextField(
                            key: _emailKey,
                            controller: _email,
                            focusNode: _emailFocus,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            onSubmitted: (_) => _passwordFocus.requestFocus(),
                            autofillHints: const [AutofillHints.email],
                            decoration: const InputDecoration(
                              hintText: 'Email address',
                              prefixIcon: Padding(
                                padding: EdgeInsets.all(AppSpacing.md),
                                child: FigmaIcon('2083:4509', 'imgSvg'),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TextField(
                            key: _passwordKey,
                            controller: _password,
                            focusNode: _passwordFocus,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) =>
                                vm.login(_email.text, _password.text),
                            obscureText: !state.showPassword,
                            autofillHints: const [AutofillHints.password],
                            decoration: InputDecoration(
                              hintText: 'Password',
                              prefixIcon: const Padding(
                                padding: EdgeInsets.all(AppSpacing.md),
                                child: FigmaIcon('2083:4509', 'imgSvg1'),
                              ),
                              suffixIcon: IconButton(
                                tooltip: state.showPassword
                                    ? 'Hide password'
                                    : 'Show password',
                                onPressed: vm.togglePassword,
                                icon: state.showPassword
                                    ? const Icon(Icons.visibility_outlined)
                                    : const FigmaIcon('2083:4509', 'imgSvg2'),
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: state.isLoggingIn
                                  ? null
                                  : () => vm.resetPassword(_email.text),
                              child: const Text('Forgot password?'),
                            ),
                          ),
                          if (state.message != null)
                            Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.md,
                              ),
                              child: Text(
                                state.message!,
                                style: EviaTheme.caption.copyWith(
                                  color: AppColors.error,
                                ),
                              ),
                            ),
                          AppButton(
                            label: 'Log in',
                            isLoading: state.isLoggingIn,
                            trailing: const FigmaIcon(
                              '2083:4509',
                              'imgVector8',
                            ),
                            onPressed: () =>
                                vm.login(_email.text, _password.text),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.md,
                            ),
                            child: Row(
                              children: [
                                const Expanded(child: Divider()),
                                Flexible(
                                  flex: 3,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.md,
                                    ),
                                    child: Text(
                                      'or continue with',
                                      textAlign: TextAlign.center,
                                      style: EviaTheme.caption,
                                    ),
                                  ),
                                ),
                                const Expanded(child: Divider()),
                              ],
                            ),
                          ),
                          OutlinedButton(
                            onPressed: state.isLoggingIn
                                ? null
                                : vm.continueWithGoogle,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.border),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                FigmaIcon('2083:4509', 'imgSvg3'),
                                SizedBox(width: AppSpacing.sm),
                                Flexible(
                                  child: Text(
                                    'Continue with Google',
                                    style: EviaTheme.compactTitle,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              const Text(
                                "Don't have an account?",
                                style: EviaTheme.caption,
                              ),
                              TextButton(
                                onPressed: () => context.go(
                                  Uri(
                                    path: '/signup',
                                    queryParameters: GoRouterState.of(context)
                                        .uri
                                        .queryParameters,
                                  ).toString(),
                                ),
                                child: const Text('Sign up'),
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
        ],
      ),
    );
  }
}

/// Header-only animation: the form and its focused fields keep their elements.
class _CollapsingHeaderSection extends StatelessWidget {
  const _CollapsingHeaderSection({
    required this.compact,
    required this.child,
    super.key,
  });
  final double compact;
  final Widget child;
  @override
  Widget build(BuildContext context) => IgnorePointer(
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
}
