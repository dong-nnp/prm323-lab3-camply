import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab03/app/app.dart';
import 'package:prm393_lab03/app/router.dart';
import 'package:prm393_lab03/viewmodels/evia_view_model.dart';
import 'package:prm393_lab03/viewmodels/activity_view_model.dart';
import 'package:prm393_lab03/viewmodels/registration_view_model.dart';

import '../helpers/startup_test_auth.dart';

const screens = <String, double>{
  '/': 844,
  '/interests': 979,
  '/discover': 1577,
  '/discover/guest': 1422,
  '/explore': 974,
  '/filters': 1726,
  '/explore/results': 926,
  '/following/events': 896,
  '/following/organizers': 884,
};

void main() {
  for (final viewport in [
    (360.0, 1.0),
    (412.0, 1.0),
    (360.0, 2.0),
    (412.0, 2.0),
  ]) {
    testWidgets(
      'all nine screens fit ${viewport.$1}dp at ${viewport.$2}x text',
      (tester) async {
        tester.view.physicalSize = Size(viewport.$1, 800);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = viewport.$2;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        for (final route in screens.keys) {
          await tester.pumpWidget(
            ProviderScope(
              key: ValueKey(route),
              overrides: [
                initialLocationProvider.overrideWithValue(route),
                if (route == '/discover' || route.startsWith('/following/'))
                  signedInTestSession,
              ],
              child: const LabApp(),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: 'Screen: $route');
          expect(find.byType(Scaffold), findsWidgets);
        }
      },
    );
  }

  testWidgets(
    'guest searches inline, filters results and opens the selected schedule',
    (tester) async {
      tester.view.physicalSize = const Size(390, 884);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [initialLocationProvider.overrideWithValue('/login')],
          child: const LabApp(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();
      expect(find.text('Popular Events'), findsOneWidget);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(LabApp)),
      );
      final router = container.read(routerProvider);
      await tester.tap(find.text('Search events, organizers...'));
      await tester.pumpAndSettle();
      expect(
        router.routerDelegate.currentConfiguration.last.matchedLocation,
        '/discover/guest',
      );
      expect(find.text('Recent Searches'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'workshop');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(find.text('3 events found'), findsOneWidget);
      await tester.tap(find.byTooltip('Filter events'));
      await tester.pumpAndSettle();
      expect(
        router.routerDelegate.currentConfiguration.last.matchedLocation,
        '/filters',
      );
      await tester.tap(find.text('Music').first);
      await tester.tap(find.text('Apply Filters'));
      await tester.pumpAndSettle();
      expect(find.text('No events found'), findsOneWidget);
      await tester.tap(find.text('Clear all'));
      await tester.pumpAndSettle();
      expect(find.text('3 events found'), findsOneWidget);
      expect(
        router.routerDelegate.currentConfiguration.last.matchedLocation,
        '/discover/guest',
      );
      final result = find.text('Design Thinking Bootcamp').first;
      await tester.ensureVisible(result);
      await tester.tap(result);
      await tester.pumpAndSettle();
      expect(
        router.routerDelegate.currentConfiguration.last.matchedLocation,
        '/event/schedule',
      );
      expect(find.text('Room A203'), findsOneWidget);
      expect(find.text('Main Stadium, University Campus'), findsNothing);
      await tester.ensureVisible(find.text('Location'));
      await tester.tap(find.text('Location'));
      await tester.pumpAndSettle();
      expect(
        router.routerDelegate.currentConfiguration.last.matchedLocation,
        '/event/location',
      );
      router.pop();
      await tester.pumpAndSettle();
      expect(
        router.routerDelegate.currentConfiguration.last.matchedLocation,
        '/discover/guest',
      );
      expect(find.text('3 events found'), findsOneWidget);
      router.go('/following/organizers');
      await tester.pumpAndSettle();
      expect(
        router.routerDelegate.currentConfiguration.last.matchedLocation,
        '/login',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Following separates confirmed registrations from followed organizers',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            initialLocationProvider.overrideWithValue(
              '/event/schedule?event=ai-recommended',
            ),
            signedInTestSession,
          ],
          child: const LabApp(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Tech Center'), findsOneWidget);
      expect(find.text('CS Students Only'), findsOneWidget);
      await tester.tap(find.text('Register Now'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm Registration'));
      await tester.pumpAndSettle(const Duration(milliseconds: 800));
      expect(find.text('Registration Successful!'), findsOneWidget);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(LabApp)),
      );
      final router = container.read(routerProvider);
      container.read(registrationViewModelProvider.notifier).markGoing();
      router.go('/following/events');
      await tester.pumpAndSettle();
      expect(find.text('AI & Future Careers Workshop'), findsOneWidget);
      expect(find.text('Tech Center'), findsOneWidget);
      expect(find.text('Registered'), findsOneWidget);
      expect(find.text('Campus Club Fair'), findsNothing);
      await tester.tap(find.text('Organizers'));
      await tester.pumpAndSettle();
      expect(find.text('0 Active'), findsOneWidget);
      final follow = find.widgetWithText(FilledButton, 'Follow').first;
      await tester.ensureVisible(follow);
      await tester.tap(follow);
      await tester.pumpAndSettle();
      expect(find.text('1 Active'), findsOneWidget);
      expect(find.text('AI & Future Careers Workshop'), findsNothing);
      container
          .read(activityViewModelProvider.notifier)
          .cancelRegistration('ai');
      router.go('/following/events');
      await tester.pumpAndSettle();
      expect(find.text('No registered events'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'interests enforce minimum selection and login never fakes success',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [initialLocationProvider.overrideWithValue('/interests')],
          child: const LabApp(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Technology'));
      await tester.pumpAndSettle();
      expect(find.text('2 interests selected'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Continue'))
            .onPressed,
        isNull,
      );
      final container = ProviderScope.containerOf(
        tester.element(find.byType(LabApp)),
      );
      container.read(routerProvider).go('/login');
      await tester.pumpAndSettle();
      final login = find.text('Log in');
      await tester.ensureVisible(login);
      await tester.tap(login);
      await tester.pumpAndSettle();
      expect(find.text('Please enter a valid email address.'), findsOneWidget);
      expect(container.read(eviaViewModelProvider).results, isFalse);
    },
  );

  // Opt-in local render evidence; no binary golden files are added to the repo.
  if (Platform.environment['EVIA_CAPTURE_DIR'] case final String captureDir) {
    testWidgets('render all requested frames for visual inspection', (
      tester,
    ) async {
      final fonts = Platform.environment['FLUTTER_ROOT'];
      if (fonts != null) {
        final loader = FontLoader('Roboto');
        for (final weight in ['regular', 'medium', 'bold']) {
          loader.addFont(
            File('$fonts/bin/cache/artifacts/material_fonts/roboto-$weight.ttf')
                .readAsBytes()
                .then(ByteData.sublistView),
          );
        }
        await loader.load();
      }
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final boundaryKey = GlobalKey();
      var index = 0;
      for (final entry in screens.entries) {
        tester.view.physicalSize = Size(390, entry.value);
        await tester.pumpWidget(
          RepaintBoundary(
            key: boundaryKey,
            child: ProviderScope(
              key: ValueKey(entry.key),
              overrides: [
                initialLocationProvider.overrideWithValue(entry.key),
                if (entry.key == '/discover' ||
                    entry.key.startsWith('/following/'))
                  signedInTestSession,
              ],
              child: const LabApp(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: entry.key);
        final boundary =
            boundaryKey.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final rendered = await boundary.toImage();
        final bytes = await rendered.toByteData(format: ui.ImageByteFormat.png);
        await tester.runAsync(() async {
          await Directory(captureDir).create(recursive: true);
          await File('$captureDir/${index++}.png')
              .writeAsBytes(bytes!.buffer.asUint8List());
        });
        rendered.dispose();
      }
    });
  }
}
