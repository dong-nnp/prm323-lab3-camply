import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab03/viewmodels/evia_view_model.dart';
import 'package:prm393_lab03/app/app.dart';
import 'package:prm393_lab03/app/router.dart';
import 'package:prm393_lab03/core/providers/service_providers.dart';
import 'package:prm393_lab03/models/auth_session.dart';
import 'package:prm393_lab03/models/firebase_status.dart';
import 'package:prm393_lab03/screens/evia/splash_screen.dart';
import 'package:prm393_lab03/theme/splash_tokens.dart';
import 'package:prm393_lab03/viewmodels/authentication_view_model.dart';
import 'package:prm393_lab03/viewmodels/startup_view_model.dart';

import '../helpers/fake_firebase_initializer.dart';
import '../helpers/startup_test_auth.dart';

Future<void> _precacheSplash(WidgetTester tester) async {
  await tester.runAsync(() async {
    final context = tester.element(find.byType(EviaSplashScreen));
    for (final asset in [SplashTokens.asset, ...SplashTokens.layerAssets]) {
      await precacheImage(AssetImage(asset), context);
    }
  });
}

void main() {
  testWidgets(
    'assembled original artwork is centered at phone widths without extra text',
    (tester) async {
      for (final width in [360.0, 412.0]) {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1;
        await tester.pumpWidget(
          ProviderScope(
            overrides: [startupDestinationProvider.overrideWithValue(null)],
            child: const RepaintBoundary(
              key: ValueKey('splash-capture'),
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                home: EviaSplashScreen(),
              ),
            ),
          ),
        );
        await _precacheSplash(tester);
        await tester.pumpAndSettle();
        final assets = tester
            .widgetList<Image>(find.byType(Image))
            .map((image) => (image.image as AssetImage).assetName);
        expect(assets.toSet(), SplashTokens.layerAssets.toSet());
        expect(find.byType(Text), findsNothing);
        final logo = find.byKey(const ValueKey('splash-logo'));
        expect(tester.getCenter(logo), Offset(width / 2, 400));
        expect(tester.takeException(), isNull);
        final captureDir = Platform.environment['EVIA_SPLASH_CAPTURE_DIR'];
        if (captureDir != null) {
          final boundary = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(const ValueKey('splash-capture')),
          );
          await tester.runAsync(() async {
            final image = await boundary.toImage();
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            await Directory(captureDir).create(recursive: true);
            await File('$captureDir/splash-${width.toInt()}.png')
                .writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
        await tester.pumpWidget(const SizedBox());
      }
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    },
  );

  testWidgets('waits for startup then replaces splash once', (tester) async {
    final pending = Completer<FirebaseStatus>();
    final c = ProviderContainer(
      overrides: [
        firebaseInitializerProvider.overrideWithValue(
          FakeFirebaseInitializer(() => pending.future),
        ),
        authenticationViewModelProvider.overrideWith(
          () => StartupTestAuth(Stream.value(const AuthSession.signedOut())),
        ),
      ],
    );
    addTearDown(c.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: c, child: const LabApp()),
    );
    await _precacheSplash(tester);
    await tester.pumpAndSettle();
    expect(find.byType(EviaSplashScreen), findsOneWidget);
    pending.complete(FirebaseStatus.notConfigured);
    await tester.pumpAndSettle();
    expect(c.read(routerProvider).routeInformationProvider.value.uri.path, '/');
    expect(find.byType(EviaSplashScreen), findsNothing);
    expect(c.read(routerProvider).canPop(), isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion bypasses the 1200ms animation', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [startupDestinationProvider.overrideWithValue(null)],
        child: const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: EviaSplashScreen(),
        ),
      ),
    );
    await _precacheSplash(tester);
    await tester.pump();
    expect(tester.hasRunningAnimations, isFalse);
    expect(find.byKey(const ValueKey('splash-ticket')), findsNothing);
    expect(
      (tester.widget<Image>(find.byType(Image)).image as AssetImage).assetName,
      SplashTokens.asset,
    );
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });

  for (final handled in [false, true]) {
    testWidgets('signed-in startup routes correctly (handled: $handled)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(412, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final c = ProviderContainer(
        overrides: [
          firebaseInitializerProvider.overrideWithValue(
            FakeFirebaseInitializer(() async => FirebaseStatus.notConfigured),
          ),
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
      await _precacheSplash(tester);
      await tester.pumpAndSettle();
      expect(
        c.read(routerProvider).routeInformationProvider.value.uri.path,
        handled ? '/discover' : '/interests',
      );
      if (!handled) {
        expect(find.text('Skip'), findsOneWidget);
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();
        expect(
          c.read(routerProvider).routeInformationProvider.value.uri.path,
          '/interests',
        );
        expect(c.read(eviaViewModelProvider).personalizedUsers, isEmpty);
      }
      expect(tester.takeException(), isNull);
    });
  }
}
