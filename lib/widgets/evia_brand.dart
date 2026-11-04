import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/constants/figma_assets.dart';
import '../theme/app_tokens.dart';
import '../theme/evia_theme.dart';
import 'evia_widgets.dart';

class EviaLogo extends StatelessWidget {
  const EviaLogo({this.large = false, this.interests = false, super.key});
  final bool large, interests;
  @override
  Widget build(BuildContext context) => Image.asset(
    FigmaAssets.path(
      large
          ? '2083:4509'
          : interests
          ? '2088:2'
          : '2083:456',
      interests ? 'imgEvia' : 'imgEviaLogo',
    ),
    width: large ? EviaTheme.loginLogoWidth : EviaTheme.logoWidth,
    height: large ? EviaTheme.loginLogoHeight : null,
    fit: BoxFit.contain,
    semanticLabel: 'Evia',
  );
}

/// The collage uses the measured rotations/crops of the original Figma artwork.
class LoginCollage extends StatelessWidget {
  const LoginCollage({super.key});
  static const _screen = '2083:4509';
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final scale = constraints.maxWidth / 358;
      Widget photo(String asset, double width, double height, double angle) =>
          Transform.rotate(
            angle: angle * math.pi / 180,
            child: Container(
              width: width * scale,
              height: height * scale,
              padding: const EdgeInsets.all(AppSpacing.xs),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.extraLarge),
                boxShadow: EviaTheme.loginShadow,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.large),
                child: Image.asset(
                  FigmaAssets.path(_screen, asset),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          );
      return SizedBox(
        height: EviaTheme.collageHeight * scale,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 9 * scale,
              top: 12 * scale,
              child: photo(
                'imgConferenceHallStageWithScreenAndAudienceSeats',
                184,
                184,
                -6,
              ),
            ),
            Positioned(
              right: 3 * scale,
              top: 3 * scale,
              child: photo(
                'imgHackathonLaptopWorkstationsAndBanner',
                172,
                114,
                5,
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: photo(
                'imgConcertStageWithVibrantVioletAndBlueLights',
                182,
                116,
                7,
              ),
            ),
            const Positioned(left: 0, top: 0, child: LimeMark()),
            const Positioned(right: 0, bottom: 0, child: LimeMark()),
          ],
        ),
      );
    },
  );
}

class LimeMark extends StatelessWidget {
  const LimeMark({super.key});
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Transform.rotate(
        angle: -math.pi / 4,
        child: Container(
          width: AppSpacing.xs,
          height: AppSpacing.md,
          color: AppColors.accent,
        ),
      ),
      const SizedBox(width: AppSpacing.sm),
      Transform.rotate(
        angle: -math.pi / 12,
        child: Container(
          width: AppSpacing.xs,
          height: AppSpacing.md,
          color: AppColors.accent,
        ),
      ),
    ],
  );
}

class LoginBackdrop extends StatelessWidget {
  const LoginBackdrop({super.key});
  @override
  Widget build(BuildContext context) => const ClipRect(
    child: Stack(
      children: [
        Positioned(
          left: -50,
          top: -30,
          child: FigmaIcon('2083:4509', 'imgVector'),
        ),
        Positioned(
          right: -50,
          top: -30,
          child: FigmaIcon('2083:4509', 'imgVector1'),
        ),
        Positioned(
          left: -60,
          bottom: -46,
          child: FigmaIcon('2083:4509', 'imgVector2'),
        ),
        Positioned(
          right: -60,
          bottom: -37,
          child: FigmaIcon('2083:4509', 'imgVector3'),
        ),
      ],
    ),
  );
}
