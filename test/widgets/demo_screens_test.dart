import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab03/app/app.dart';
import 'package:prm393_lab03/app/router.dart';
import 'package:prm393_lab03/core/providers/service_providers.dart';
import 'package:prm393_lab03/screens/evia/demo_screens_screen.dart';
import 'package:prm393_lab03/viewmodels/activity_view_model.dart';
import 'package:prm393_lab03/viewmodels/registration_view_model.dart';

import '../helpers/startup_test_auth.dart';

void main() {
  testWidgets('demo menu opens result screens and registration succeeds', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          demoAuthEnabledProvider.overrideWithValue(true),
          signedInTestSession,
          initialLocationProvider.overrideWithValue('/profile/demo'),
          registrationDelayProvider.overrideWithValue(Duration.zero),
        ],
        child: const LabApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Demo screens'), findsOneWidget);
    final context = tester.element(find.byType(DemoScreensScreen));
    final container = ProviderScope.containerOf(context);
    final router = container.read(routerProvider);
    for (final route in demoScreenRoutes) {
      expect(
        router.configuration.findMatch(Uri.parse(route.$2)).isError,
        isFalse,
        reason: route.$2,
      );
    }
    router.push('/registration');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm Registration'));
    await tester.pumpAndSettle();
    expect(find.text('Registration Successful!'), findsOneWidget);
    expect(container.read(activityViewModelProvider).available, 1900);
    expect(tester.takeException(), isNull);
    router.go('/profile/demo');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reset demo'));
    await tester.pumpAndSettle();
    expect(container.read(activityViewModelProvider).available, 2000);
  });

  for (final width in [360.0, 412.0]) {
    testWidgets('demo menu fits ${width}dp at 2x text', (tester) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            demoAuthEnabledProvider.overrideWithValue(true),
            signedInTestSession,
            initialLocationProvider.overrideWithValue('/profile/demo'),
          ],
          child: const LabApp(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Demo screens'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('demo menu is unavailable in ordinary builds', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          demoAuthEnabledProvider.overrideWithValue(false),
          signedInTestSession,
          initialLocationProvider.overrideWithValue('/profile/demo'),
        ],
        child: const LabApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(DemoScreensScreen), findsNothing);
  });
}
