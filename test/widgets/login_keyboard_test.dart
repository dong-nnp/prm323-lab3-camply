import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab03/app/app.dart';
import 'package:prm393_lab03/app/router.dart';
import 'package:prm393_lab03/theme/evia_theme.dart';

void main() {
  setUpAll(() async {
    final root = Platform.environment['FLUTTER_ROOT'];
    if (root == null) return;
    final font = FontLoader('Roboto');
    for (final weight in ['regular', 'medium', 'bold']) {
      font.addFont(
        File('$root/bin/cache/artifacts/material_fonts/roboto-$weight.ttf')
            .readAsBytes()
            .then(ByteData.sublistView),
      );
    }
    await font.load();
  });

  for (final viewport in [
    (390.0, 844.0, false),
    (360.0, 640.0, false),
    (360.0, 640.0, true),
  ]) {
    testWidgets(
      'Login preserves fields with keyboard ${viewport.$1}x${viewport.$2}, reduced: ${viewport.$3}',
      (tester) async {
        tester.view.physicalSize = Size(viewport.$1, viewport.$2);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetViewInsets);
        if (viewport.$3) {
          tester.platformDispatcher.accessibilityFeaturesTestValue =
              const FakeAccessibilityFeatures(disableAnimations: true);
          addTearDown(
            tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
          );
        }
        await tester.pumpWidget(
          RepaintBoundary(
            key: const ValueKey('login-capture'),
            child: ProviderScope(
              overrides: [initialLocationProvider.overrideWithValue('/login')],
              child: const LabApp(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.runAsync(() async {
          final context = tester.element(find.byType(LabApp));
          for (final image in tester.widgetList<Image>(find.byType(Image))) {
            await precacheImage(image.image, context);
          }
        });
        await tester.pumpAndSettle();
        final illustration = find.byKey(const ValueKey('login-illustration'));
        final initialIllustrationHeight = tester.getSize(illustration).height;
        final email = find.byType(TextField).first;
        final password = find.byType(TextField).last;
        final emailElement = tester.element(email);
        final passwordElement = tester.element(password);
        final initialLogoWidth = tester
            .getSize(find.bySemanticsLabel('Evia').first)
            .width;

        await tester.enterText(email, 'student@example.com');
        await tester.pumpAndSettle();
        // Focus alone (e.g. a hardware keyboard) must not collapse the artwork.
        expect(tester.getSize(illustration).height, initialIllustrationHeight);
        tester.view.viewInsets = const FakeViewPadding(bottom: 300);
        await tester.pump();
        if (viewport.$3) {
          await tester.pump();
          expect(tester.getSize(illustration).height, 0);
        }
        await tester.pumpAndSettle();
        expect(tester.getSize(illustration).height, 0);
        expect(
          tester.getSize(find.bySemanticsLabel('Evia').first).width,
          lessThan(initialLogoWidth),
        );
        expect(
          tester.getSize(find.bySemanticsLabel('Evia').first).width,
          closeTo(EviaTheme.compactLoginLogoWidth, 0.1),
        );
        if (viewport.$1 == 390) {
          expect(
            tester.getRect(find.bySemanticsLabel('Evia').first).top,
            greaterThanOrEqualTo(0),
          );
        }
        expect(tester.element(email), same(emailElement));
        expect(tester.widget<TextField>(email).focusNode!.hasFocus, isTrue);
        final emailRect = tester.getRect(email);
        expect(emailRect.top, greaterThanOrEqualTo(0));
        expect(emailRect.bottom, lessThanOrEqualTo(viewport.$2 - 300));

        await tester.testTextInput.receiveAction(TextInputAction.next);
        await tester.pumpAndSettle();
        expect(tester.widget<TextField>(password).focusNode!.hasFocus, isTrue);
        expect(tester.getSize(illustration).height, 0);
        await tester.enterText(password, 'test-password');
        await tester.pumpAndSettle();
        expect(
          tester.getRect(password).bottom,
          lessThanOrEqualTo(viewport.$2 - 300),
        );
        final dir = Platform.environment['EVIA_LOGIN_CAPTURE_DIR'];
        if (dir != null && viewport.$1 == 390) {
          await tester.runAsync(() async {
            final boundary = tester.renderObject<RenderRepaintBoundary>(
              find.byKey(const ValueKey('login-capture')),
            );
            final image = await boundary.toImage();
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            await Directory(dir).create(recursive: true);
            await File('$dir/login-keyboard-insets-300dp.png')
                .writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }

        tester.view.resetViewInsets();
        tester.testTextInput.hide();
        await tester.pumpAndSettle();
        expect(tester.getSize(illustration).height, initialIllustrationHeight);
        expect(
          tester.getSize(find.bySemanticsLabel('Evia').first).width,
          initialLogoWidth,
        );
        expect(
          tester.widget<TextField>(email).controller!.text,
          'student@example.com',
        );
        expect(
          tester.widget<TextField>(password).controller!.text,
          'test-password',
        );
        expect(tester.element(password), same(passwordElement));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
}
