import '../helpers/startup_test_auth.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab03/app/app.dart';
import 'package:prm393_lab03/app/router.dart';
import 'package:prm393_lab03/screens/evia/rewards_screen.dart';
import 'package:prm393_lab03/widgets/rewards_wallet.dart';

Future<ProviderContainer> open(WidgetTester tester, String route) async {
  tester.view.physicalSize = const Size(390, 884);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final container = ProviderContainer(
    overrides: [
      signedInTestSession,
      initialLocationProvider.overrideWithValue(route),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const LabApp()),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('check-in preview shows Day 8 and cannot award coins', (
    tester,
  ) async {
    await open(tester, '/rewards');
    expect(find.text('8-day streak'), findsOneWidget);
    expect(find.text('Day 2'), findsOneWidget);
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Check In \u00b7 +100 coins'),
    );
    expect(button.onPressed, isNull);
    expect(find.textContaining('Coin service'), findsNothing);
    expect(find.text('How rewards work'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('catalog remains preview and redeem requires API', (
    tester,
  ) async {
    final c = await open(tester, '/rewards/catalog');
    expect(find.text('200 coins'), findsOneWidget);
    expect(find.text('Eligible'), findsNothing);
    c.read(routerProvider).go('/rewards/detail?id=tote');
    await tester.pumpAndSettle();
    expect(find.text('Pickup location not configured'), findsOneWidget);
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Coin API not connected'),
    );
    expect(button.onPressed, isNull);
  });
  testWidgets('preview locker opens its matching voucher', (tester) async {
    await open(tester, '/rewards/locker');
    expect(find.text('Available (1)'), findsOneWidget);
    await tester.tap(find.text('View Reward'));
    await tester.pumpAndSettle();
    expect(find.text('VOUCHER-CC-82914'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('unknown voucher does not fall back to a preview voucher', (
    tester,
  ) async {
    await open(tester, '/rewards/voucher?code=missing');
    expect(find.text('No reward selected'), findsOneWidget);
    expect(find.text('VOUCHER-CC-82914'), findsNothing);
  });
  testWidgets('locker back returns to Rewards with both back controls', (
    tester,
  ) async {
    final c = await open(tester, '/rewards/locker');
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<RewardsScreen>(find.byType(RewardsScreen)).catalog,
      isTrue,
    );
    c.read(routerProvider).go('/rewards/locker');
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(
      tester.widget<RewardsScreen>(find.byType(RewardsScreen)).catalog,
      isTrue,
    );
  });
  testWidgets('tabs retain wallet position and 48dp touch targets', (
    tester,
  ) async {
    await open(tester, '/rewards');
    final rect = tester.getRect(find.byType(RewardsWallet));
    for (final label in ['Earn Coins', 'Redeem Rewards']) {
      final f = find
          .ancestor(of: find.text(label), matching: find.byType(InkWell))
          .first;
      expect(tester.getSize(f).height, greaterThanOrEqualTo(48));
    }
    await tester.tap(find.text('Redeem Rewards'));
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byType(RewardsWallet)), rect);
    expect(tester.takeException(), isNull);
  });
}
