import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab03/app/app.dart';
import 'package:prm393_lab03/app/router.dart';
import 'package:prm393_lab03/viewmodels/evia_view_model.dart';

import '../helpers/startup_test_auth.dart';

Future<ProviderContainer> open(WidgetTester tester, String route) async {
  tester.view.physicalSize = const Size(390, 884);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final c = ProviderContainer(
    overrides: [
      signedInTestSession,
      initialLocationProvider.overrideWithValue(route),
    ],
  );
  addTearDown(c.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: c, child: const LabApp()),
  );
  await tester.pumpAndSettle();
  return c;
}

void main() {
  testWidgets('Skip reports an unavailable save and keeps onboarding open', (
    tester,
  ) async {
    final c = await open(tester, '/interests');
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    expect(
      c.read(routerProvider).routeInformationProvider.value.uri.path,
      '/interests',
    );
    expect(c.read(eviaViewModelProvider).personalizedUsers, isEmpty);
    final message = c.read(eviaViewModelProvider).message;
    expect(message, isNotNull);
    expect(find.text(message!), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'full event offers browsing rather than a waitlist or fake registration',
    (tester) async {
      final c = await open(tester, '/registration/full');
      expect(find.text('Join Waitlist'), findsNothing);
      final browse = find.text('Explore Other Events');
      await tester.ensureVisible(browse);
      await tester.tap(browse);
      await tester.pumpAndSettle();
      expect(
        c.read(routerProvider).routeInformationProvider.value.uri.path,
        '/explore',
      );
    },
  );

  testWidgets(
    'unsupported verification filters are hidden and milestone claims are distinct from unlocked progress',
    (tester) async {
      final c = await open(tester, '/filters');
      expect(find.text('Waitlist Available'), findsNothing);
      expect(find.text('Host University Only'), findsNothing);
      expect(find.byType(Switch), findsNothing);
      c.read(routerProvider).go('/rewards/milestones');
      await tester.pumpAndSettle();
      expect(find.text('Ready to claim'), findsNWidgets(2));
      expect(find.text('Not reached'), findsNWidgets(3));
      expect(find.text('Claimed'), findsNothing);
      expect(find.text('Claim reward'), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    },
  );
}
