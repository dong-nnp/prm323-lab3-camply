import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab03/app/app.dart';
import 'package:prm393_lab03/app/router.dart';
import 'package:prm393_lab03/screens/evia/welcome_screen.dart';
import 'package:prm393_lab03/screens/evia/sign_up_screen.dart';
import 'package:prm393_lab03/screens/evia/login_screen.dart';
import 'package:prm393_lab03/screens/evia/discover_screen.dart';
import 'package:prm393_lab03/theme/splash_tokens.dart';
import 'package:prm393_lab03/theme/welcome_tokens.dart';
import 'package:prm393_lab03/models/auth_session.dart';
import 'package:prm393_lab03/viewmodels/authentication_view_model.dart';

import '../helpers/startup_test_auth.dart';

Future<ProviderContainer> openWelcome(WidgetTester tester) async {
  final c = ProviderContainer(
    overrides: [initialLocationProvider.overrideWithValue('/')],
  );
  addTearDown(c.dispose);
  await tester.pumpWidget(
    RepaintBoundary(
      key: const ValueKey('welcome-capture'),
      child: UncontrolledProviderScope(container: c, child: const LabApp()),
    ),
  );
  await tester.runAsync(() async {
    final context = tester.element(find.byType(EviaWelcomeScreen));
    for (final asset in [SplashTokens.asset, WelcomeTokens.heroAsset]) {
      await precacheImage(AssetImage(asset), context);
    }
  });
  await tester.pumpAndSettle();
  return c;
}

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
    await (FontLoader('MaterialIcons')..addFont(
          File(
            '$root/bin/cache/artifacts/material_fonts/materialicons-regular.otf',
          ).readAsBytes().then(ByteData.sublistView),
        ))
        .load();
  });

  for (final size in [
    (390.0, 844.0, 1.0),
    (360.0, 640.0, 1.0),
    (412.0, 844.0, 2.0),
    (360.0, 640.0, 2.0),
  ]) {
    testWidgets('Welcome fits ${size.$1}x${size.$2} text ${size.$3}', (
      tester,
    ) async {
      tester.view.physicalSize = Size(size.$1, size.$2);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = size.$3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await openWelcome(tester);
      expect(find.text('Welcome to Evia!'), findsOneWidget);
      expect(find.byType(FilledButton), findsOneWidget);
      expect(find.byType(OutlinedButton), findsOneWidget);
      expect(find.byType(TextButton), findsOneWidget);
      final assets = tester
          .widgetList<Image>(find.byType(Image))
          .map((image) => (image.image as AssetImage).assetName)
          .toSet();
      expect(assets, {SplashTokens.asset, WelcomeTokens.heroAsset});
      expect(find.byType(BottomNavigationBar), findsNothing);
      expect(tester.takeException(), isNull);
      final dir = Platform.environment['EVIA_WELCOME_CAPTURE_DIR'];
      if (dir != null && size.$3 == 1) {
        await tester.runAsync(() async {
          final boundary = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(const ValueKey('welcome-capture')),
          );
          final image = await boundary.toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await Directory(dir).create(recursive: true);
          await File('$dir/welcome-${size.$1.toInt()}-${size.$2.toInt()}.png')
              .writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
      await tester.ensureVisible(find.text('Explore as Guest'));
      expect(
        tester.getSize(find.widgetWithText(FilledButton, 'Get Started')).height,
        greaterThanOrEqualTo(48),
      );
      expect(tester.takeException(), isNull);
    });
  }

  for (final action in {
    'Get Started': '/signup',
    'Log In': '/login',
    'Explore as Guest': '/discover/guest',
  }.entries) {
    testWidgets('${action.key} opens ${action.value}', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await openWelcome(tester);
      await tester.ensureVisible(find.text(action.key));
      await tester.tap(find.text(action.key));
      await tester.pumpAndSettle();
      expect(
        find.byType(switch (action.value) {
          '/signup' => EviaSignUpScreen,
          '/login' => EviaLoginScreen,
          _ => EviaDiscoverScreen,
        }),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'private deep links send guests to Login; public organizer stays open',
    (tester) async {
      final c = await openWelcome(tester);
      for (final path in [
        '/registration',
        '/my-events/check-in',
        '/rewards/confirm',
        '/profile/saved',
      ]) {
        c.read(routerProvider).go(path);
        await tester.pumpAndSettle();
        expect(
          c.read(routerProvider).routeInformationProvider.value.uri.path,
          '/login',
        );
      }
      c.read(routerProvider).go('/organizer');
      await tester.pumpAndSettle();
      expect(
        c.read(routerProvider).routeInformationProvider.value.uri.path,
        '/organizer',
      );
      await tester.tap(find.text('+ Follow'));
      await tester.pumpAndSettle();
      expect(find.byType(EviaLoginScreen), findsOneWidget);
    },
  );

  for (final handled in [false, true]) {
    testWidgets('authenticated entry bypasses Welcome (handled: $handled)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(412, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final c = ProviderContainer(
        overrides: [
          initialLocationProvider.overrideWithValue('/'),
          authenticationViewModelProvider.overrideWith(
            () => StartupTestAuth(
              Stream.value(
                AuthSession.signedIn('user', personalizationHandled: handled),
              ),
            ),
          ),
        ],
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(container: c, child: const LabApp()),
      );
      await tester.pumpAndSettle();
      expect(find.byType(EviaWelcomeScreen), findsNothing);
      expect(
        c.read(routerProvider).routeInformationProvider.value.uri.path,
        handled ? '/discover' : '/interests',
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Login slides in, reverses on Back, and preserves Welcome', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final c = await openWelcome(tester);
    final originalWelcome = tester.element(find.byType(EviaWelcomeScreen));
    await tester.ensureVisible(find.text('Log In'));
    await tester.tap(find.text('Log In'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 70));

    final login = find.byType(EviaLoginScreen);
    final slide = find
        .ancestor(of: login, matching: find.byType(SlideTransition))
        .first;
    final fade = find
        .ancestor(of: login, matching: find.byType(FadeTransition))
        .first;
    expect(
      tester.widget<SlideTransition>(slide).position.value.dx,
      greaterThan(0),
    );
    expect(
      tester.widget<FadeTransition>(fade).opacity.value,
      inExclusiveRange(0, 1),
    );
    await tester.pumpAndSettle();
    expect(tester.widget<SlideTransition>(slide).position.value, Offset.zero);

    c.read(routerProvider).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 55));
    expect(
      tester.widget<SlideTransition>(slide).position.value.dx,
      greaterThan(0),
    );
    expect(
      tester.widget<FadeTransition>(fade).opacity.value,
      inExclusiveRange(0, 1),
    );
    await tester.pumpAndSettle();
    expect(find.byType(EviaLoginScreen), findsNothing);
    expect(
      tester.element(find.byType(EviaWelcomeScreen)),
      same(originalWelcome),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Login navigation skips motion with reduced motion enabled', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final c = await openWelcome(tester);
    await tester.ensureVisible(find.text('Log In'));
    await tester.tap(find.text('Log In'));
    await tester.pump();
    await tester.pump();
    final login = find.byType(EviaLoginScreen);
    final slide = find
        .ancestor(of: login, matching: find.byType(SlideTransition))
        .first;
    expect(tester.widget<SlideTransition>(slide).position.value, Offset.zero);
    c.read(routerProvider).pop();
    await tester.pumpAndSettle();
    expect(find.byType(EviaLoginScreen), findsNothing);
    expect(find.byType(EviaWelcomeScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
