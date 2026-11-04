import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab03/theme/app_tokens.dart';
import 'package:prm393_lab03/theme/splash_tokens.dart';
import 'package:prm393_lab03/widgets/evia_splash_logo.dart';

void main() {
  testWidgets(
    'ticket translates left while via wipes, then holds without a jump',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final controller = AnimationController(
        vsync: tester,
        duration: SplashTokens.duration,
      );
      addTearDown(controller.dispose);
      var ready = false;
      await tester.pumpWidget(
        RepaintBoundary(
          key: const ValueKey('animation-capture'),
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              backgroundColor: AppColors.splashBackground,
              body: Center(
                child: SizedBox(
                  width: SplashTokens.logoWidth,
                  child: EviaSplashLogo(
                    animation: controller,
                    onReady: () => ready = true,
                    reducedMotion: false,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.runAsync(() async {
        for (final asset in SplashTokens.layerAssets) {
          await precacheImage(
            AssetImage(asset),
            tester.element(find.byType(EviaSplashLogo)),
          );
        }
      });
      await tester.pump();
      expect(ready, isTrue);
      final ticket = find.byKey(const ValueKey('splash-ticket'));
      final wipe = find.byKey(const ValueKey('splash-wordmark-reveal'));

      double revealedWidth() {
        final clip = tester.widget<ClipRect>(wipe).clipper!;
        return clip.getClip(tester.getSize(wipe)).width;
      }

      Future<void> frame(int ms, String name) async {
        controller.value = ms / SplashTokens.duration.inMilliseconds;
        await tester.pump();
        final dir = Platform.environment['EVIA_SPLASH_CAPTURE_DIR'];
        if (dir != null) {
          await tester.runAsync(() async {
            final boundary = tester.renderObject<RenderRepaintBoundary>(
              find.byKey(const ValueKey('animation-capture')),
            );
            final image = await boundary.toImage();
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            await Directory(dir).create(recursive: true);
            await File('$dir/frame-$name.png')
                .writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
      }

      await frame(300, 'A-300ms');
      final start = tester.getCenter(ticket).dx;
      expect(start, closeTo(180, 0.01));
      expect(revealedWidth(), 0);

      await frame(600, 'B-600ms');
      final middle = tester.getCenter(ticket).dx;
      expect(middle, lessThan(start));
      expect(revealedWidth(), greaterThan(0));
      expect(revealedWidth(), lessThan(SplashTokens.wordmarkBounds.width));

      await frame(800, 'C-800ms');
      final end = tester.getCenter(ticket).dx;
      expect(end, lessThan(middle));
      expect(revealedWidth(), SplashTokens.wordmarkBounds.width);
      expect(
        start - end,
        closeTo(
          (SplashTokens.canvas.width / 2 -
                  SplashTokens.ticketBounds.center.dx) *
              SplashTokens.logoWidth /
              SplashTokens.canvas.width,
          0.01,
        ),
      );

      await frame(950, 'D-950ms');
      expect(tester.getCenter(ticket).dx, end);
      await frame(1150, 'D-1150ms');
      expect(tester.getCenter(ticket).dx, end);
      expect(
        tester.getCenter(find.byKey(const ValueKey('splash-logo'))),
        const Offset(180, 400),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
