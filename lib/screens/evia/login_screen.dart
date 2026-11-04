import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_tokens.dart';
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
  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _unavailable(String feature) => ScaffoldMessenger.of(context)
      .showSnackBar(
        SnackBar(
          content: Text(
            '$feature is currently unavailable. Use Skip to explore.',
          ),
        ),
      );
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
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                  ),
                  child: Row(
                    children: [
                      Text('9:41', style: EviaTheme.label),
                      const Spacer(),
                      const FigmaIcon('2083:4509', 'imgSvgCellularIcon'),
                      const SizedBox(width: AppSpacing.xs),
                      const FigmaIcon('2083:4509', 'imgVector4'),
                      const SizedBox(width: AppSpacing.xs),
                      Stack(
                        alignment: Alignment.centerLeft,
                        children: [
                          const FigmaIcon('2083:4509', 'imgVector5'),
                          const Padding(
                            padding: EdgeInsets.all(2),
                            child: FigmaIcon('2083:4509', 'imgVector6'),
                          ),
                        ],
                      ),
                      const FigmaIcon('2083:4509', 'imgVector7'),
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.go('/discover/guest'),
                    child: const Text('Skip'),
                  ),
                ),
                const EviaLogo(large: true),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Find Events.\nMake Memories.',
                  textAlign: TextAlign.center,
                  style: EviaTheme.label.copyWith(color: EviaTheme.navy),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: LoginCollage(),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                      vertical: AppSpacing.lg,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(EviaTheme.cardRadius),
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
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
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
                          controller: _password,
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
                            onPressed: () => _unavailable('Password recovery'),
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
                          trailing: const FigmaIcon('2083:4509', 'imgVector8'),
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
                        ),
                        OutlinedButton(
                          onPressed: () => _unavailable('Google sign-in'),
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
                              onPressed: () => context.push('/interests'),
                              child: const Text('Sign up'),
                            ),
                          ],
                        ),
                      ],
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
