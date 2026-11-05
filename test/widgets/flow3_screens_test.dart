import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab03/app/router.dart';
import 'package:prm393_lab03/screens/evia/reward_voucher_screen.dart';
import 'package:prm393_lab03/viewmodels/flow3_view_model.dart';
import 'package:prm393_lab03/core/errors/app_exception.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../helpers/flow3_backend.dart';
import 'flow1_screens_test.dart' show open;

void main() {
  for (final width in [360.0, 412.0]) {
    testWidgets(
      'live reward screens fit ${width}dp with 2x text and actual viewport constraints',
      (tester) async {
        final backend = Flow3TestBackend();
        backend.respond('redeemReward', {'requestId': 'render-fixture'});
        for (final route in [
          '/rewards',
          '/rewards/catalog',
          '/rewards/detail?id=server-reward',
          '/rewards/confirm?id=server-reward',
          '/rewards/locker',
          '/rewards/voucher?code=redemption-1',
          '/rewards/milestones',
          '/rewards/history',
        ]) {
          final c = await open(
            tester,
            backend,
            route,
            width: width,
            textScale: 2,
          );
          expect(tester.takeException(), isNull, reason: route);
          await tester.pumpWidget(const SizedBox());
          await tester.pump();
          c.dispose();
        }
      },
    );
  }
  testWidgets(
    'original Daily and milestones use server state, manual claims persist',
    (tester) async {
      final backend = Flow3TestBackend();
      final c = await open(tester, backend, '/rewards', width: 360);
      expect(find.text('1-day streak'), findsOneWidget);
      final pending = Completer<void>();
      backend.handle = (name, input) async {
        if (name == 'claimDailyCheckin') await pending.future;
        return backend.respond(name, input);
      };
      final daily = find.text('Check In · +5 coins');
      await tester.ensureVisible(daily);
      await tester.tap(daily);
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      pending.complete();
      await tester.pumpAndSettle();
      expect(backend.available, 315);
      expect(find.text('Checked In Today · +5 coins'), findsOneWidget);
      c.read(routerProvider).go('/rewards/milestones');
      await tester.pumpAndSettle();
      expect(find.text('Server First'), findsWidgets);
      expect(find.text('Ready to claim'), findsOneWidget);
      await tester.ensureVisible(find.text('Claim reward'));
      await tester.tap(find.text('Claim reward'));
      await tester.pumpAndSettle();
      expect(backend.available, 365);
      expect(find.text('Claimed'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      c.dispose();
    },
  );

  testWidgets(
    'catalog to redemption, restored locker, signed QR and ledger use Firebase contracts',
    (tester) async {
      final backend = Flow3TestBackend();
      final c = await open(tester, backend, '/rewards/catalog', width: 412);
      expect(find.text('Server Café'), findsOneWidget);
      expect(find.text('Campus Café \$10 Voucher'), findsNothing);
      await tester.ensureVisible(find.text('Server Café'));
      await tester.tap(find.text('Server Café'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Redeem for 200 coins'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(
        find.widgetWithText(FilledButton, 'Confirm Redemption'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Confirm Redemption'));
      await tester.pumpAndSettle();
      expect(find.byType(RedemptionSuccessScreen), findsOneWidget);
      expect(backend.available, 110);
      c.invalidate(flow3ViewModelProvider);
      c.read(routerProvider).go('/rewards/locker');
      await tester.pumpAndSettle();
      expect(find.text('Available (1)'), findsOneWidget);
      expect(
        find.text('Demo rewards are stored only during this app session.'),
        findsNothing,
      );
      await tester.ensureVisible(find.text('Server Café'));
      await tester.tap(find.text('Server Café'));
      await tester.pumpAndSettle();
      expect(
        find.text('test-only-voucher-code-12345678901234567890123'),
        findsOneWidget,
      );
      expect(find.byType(QrImageView), findsOneWidget);
      expect(backend.calls.lastWhere((v) => v.name == 'getVoucherCode').input, {
        'voucherId': 'voucher-redemption-1',
      });
      c.read(routerProvider).go('/rewards/history');
      await tester.pumpAndSettle();
      expect(find.text('Reward redemption'), findsOneWidget);
      expect(find.text('-200 coins'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      c.dispose();
    },
  );

  testWidgets(
    'used voucher is archived and never exposes QR, invalid reward does not fall back to Café',
    (tester) async {
      final backend = Flow3TestBackend();
      backend.respond('redeemReward', {'requestId': 'test-issued'});
      backend.voucherStatus = 'used';
      final c = await open(
        tester,
        backend,
        '/rewards/voucher?code=redemption-1',
      );
      expect(find.text('Used'), findsWidgets);
      expect(find.byType(QrImageView), findsNothing);
      expect(backend.calls.where((v) => v.name == 'getVoucherCode'), isEmpty);
      c.read(routerProvider).go('/rewards/detail?id=unknown');
      await tester.pumpAndSettle();
      expect(find.text('Reward unavailable.'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      c.dispose();
    },
  );

  testWidgets(
    'network error offers retry and never falls back to mock rewards',
    (tester) async {
      final backend = Flow3TestBackend();
      backend.handle = (name, input) async {
        if (name == 'getEventMilestones') {
          throw const AppException(
            code: 'unavailable',
            message: 'Rewards offline',
          );
        }
        return backend.respond(name, input);
      };
      final c = await open(tester, backend, '/rewards');
      expect(find.text('Rewards offline'), findsOneWidget);
      expect(find.text('8-day streak'), findsNothing);
      backend.handle = null;
      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle();
      expect(find.text('1-day streak'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      c.dispose();
    },
  );
}
