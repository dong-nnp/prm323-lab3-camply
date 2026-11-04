import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_routes.dart';
import '../../theme/app_tokens.dart';
import '../../theme/splash_tokens.dart';
import '../../theme/welcome_tokens.dart';
import '../../widgets/app_button.dart';

class EviaWelcomeScreen extends StatelessWidget {
  const EviaWelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) => Theme(
    data: WelcomeTokens.theme(Theme.of(context)),
    child: Scaffold(
      backgroundColor: AppColors.entryBackground,
      body: DecoratedBox(
        decoration: WelcomeTokens.background,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final heroHeight =
                  (constraints.maxHeight - WelcomeTokens.nonHeroSpace).clamp(
                    WelcomeTokens.heroMinHeight,
                    WelcomeTokens.heroMaxHeight,
                  );
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: AppSizes.contentMaxWidth,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.xl,
                          AppSpacing.section,
                          AppSpacing.xl,
                          AppSpacing.xl,
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight:
                                (constraints.maxHeight -
                                        AppSpacing.section -
                                        AppSpacing.xl)
                                    .clamp(0, double.infinity),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Column(
                                children: [
                                  const _OfficialLogo(),
                                  const SizedBox(height: AppSpacing.section),
                                  Image.asset(
                                    WelcomeTokens.heroAsset,
                                    height: heroHeight,
                                    fit: BoxFit.contain,
                                    semanticLabel: 'Evia mascot welcoming you to events and rewards',
                                  ),
                                  const SizedBox(height: AppSpacing.xl),
                                  const Text(
                                    'Welcome to Evia!',
                                    textAlign: TextAlign.center,
                                    style: WelcomeTokens.heading,
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  const Text(
                                    'Discover exciting events, join what you love, and earn rewards along the way.',
                                    textAlign: TextAlign.center,
                                    style: WelcomeTokens.description,
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.xl),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  AppButton(
                                    label: 'Get Started',
                                    trailing: const Icon(Icons.arrow_forward),
                                    onPressed: () =>
                                        context.push(AppRoutes.signUp),
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  OutlinedButton(
                                    onPressed: () =>
                                        context.push(AppRoutes.login),
                                    child: const Text('Log In'),
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  TextButton(
                                    onPressed: () =>
                                        context.go(AppRoutes.guestDiscover),
                                    child: const Text('Explore as Guest'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    ),
  );
}

class _OfficialLogo extends StatelessWidget {
  const _OfficialLogo();
  @override
  Widget build(BuildContext context) => SizedBox(
    width: WelcomeTokens.logoWidth,
    child: AspectRatio(
      aspectRatio: SplashTokens.canvas.aspectRatio,
      child: FittedBox(
        child: SizedBox.fromSize(
          size: SplashTokens.canvas,
          child: Stack(
            children: [
              Positioned.fromRect(
                rect: SplashTokens.originalBounds,
                child: Image.asset(SplashTokens.asset, semanticLabel: 'EVIA'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
