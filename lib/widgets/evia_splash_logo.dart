import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/splash_tokens.dart';

/// Original artwork assembled in one coordinate system. The ticket's movement
/// scales with the viewport; the wordmark stays at its final alignment.
class EviaSplashLogo extends StatefulWidget {
  const EviaSplashLogo({
    required this.animation,
    required this.onReady,
    required this.reducedMotion,
    super.key,
  });

  final Animation<double> animation;
  final VoidCallback onReady;
  final bool reducedMotion;

  @override
  State<EviaSplashLogo> createState() => _EviaSplashLogoState();
}

class _EviaSplashLogoState extends State<EviaSplashLogo> {
  final _loaded = <String>{};
  bool _reportedReady = false;

  Widget _image(String asset, {Key? key}) => Image.asset(
    asset,
    key: key,
    fit: BoxFit.contain,
    excludeFromSemantics: true,
    frameBuilder: (_, child, frame, sync) {
      if (sync || frame != null) {
        _loaded.add(asset);
        final requiredAssets = widget.reducedMotion
            ? [SplashTokens.asset]
            : SplashTokens.layerAssets;
        if (!_reportedReady && requiredAssets.every(_loaded.contains)) {
          _reportedReady = true;
          widget.onReady();
        }
      }
      return child;
    },
  );

  double _phase(double milliseconds, double start, double end) =>
      ((milliseconds - start) / (end - start)).clamp(0, 1);

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'EVIA',
    image: true,
    child: AspectRatio(
      key: const ValueKey('splash-logo'),
      aspectRatio: SplashTokens.canvas.aspectRatio,
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox.fromSize(
          size: SplashTokens.canvas,
          child: AnimatedBuilder(
            animation: widget.animation,
            builder: (context, _) {
              if (widget.reducedMotion) {
                return Stack(
                  children: [
                    Positioned.fromRect(
                      rect: SplashTokens.originalBounds,
                      child: _image(SplashTokens.asset),
                    ),
                  ],
                );
              }
              final time =
                  widget.animation.value * SplashTokens.duration.inMilliseconds;
              final entrance = Curves.easeOutCubic.transform(
                _phase(time, 0, SplashTokens.ticketEnterEnd),
              );
              final movement = Curves.easeInOutCubic.transform(
                _phase(
                  time,
                  SplashTokens.ticketMoveStart,
                  SplashTokens.assemblyEnd,
                ),
              );
              final reveal = Curves.easeInOutCubic.transform(
                _phase(
                  time,
                  SplashTokens.wordmarkStart,
                  SplashTokens.assemblyEnd,
                ),
              );
              final accent = _phase(
                time,
                SplashTokens.raysStart,
                SplashTokens.raysEnd,
              );
              final ticket = SplashTokens.ticketBounds;
              final dx =
                  (SplashTokens.canvas.width / 2 - ticket.center.dx) *
                  (1 - movement);
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fromRect(
                    rect: SplashTokens.wordmarkBounds,
                    child: ClipRect(
                      key: const ValueKey('splash-wordmark-reveal'),
                      clipper: _WordmarkWipe(reveal),
                      child: _image(SplashTokens.wordmarkAsset),
                    ),
                  ),
                  Positioned.fromRect(
                    rect: ticket,
                    child: Transform.translate(
                      offset: Offset(dx, 0),
                      child: Transform.scale(
                        scale:
                            SplashTokens.initialScale +
                            (1 - SplashTokens.initialScale) * entrance,
                        child: Opacity(
                          opacity: entrance,
                          child: _image(
                            SplashTokens.ticketAsset,
                            key: const ValueKey('splash-ticket'),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned.fromRect(
                    rect: SplashTokens.raysBounds,
                    child: Transform.translate(
                      offset: Offset(dx, 0),
                      child: Transform.scale(
                        scale:
                            1 +
                            SplashTokens.accentPulse *
                                math.sin(math.pi * accent),
                        child: Opacity(
                          opacity: Curves.easeOut.transform(
                            (accent * 2).clamp(0, 1),
                          ),
                          child: _image(SplashTokens.raysAsset),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    ),
  );
}

class _WordmarkWipe extends CustomClipper<Rect> {
  const _WordmarkWipe(this.progress);
  final double progress;

  @override
  Rect getClip(Size size) =>
      Rect.fromLTWH(0, 0, size.width * progress, size.height);

  @override
  bool shouldReclip(_WordmarkWipe oldClipper) =>
      oldClipper.progress != progress;
}
