import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab03/widgets/status_widgets.dart';
import 'package:prm393_lab03/core/errors/app_exception.dart';
import 'package:prm393_lab03/viewmodels/flow1_view_model.dart';

import '../helpers/flow1_backend.dart';
import 'flow1_screens_test.dart' show open;

void main() {
  testWidgets(
    'ticket refresh failure hides previous ticket and renders an error safely',
    (tester) async {
      var missing = false;
      final backend = Flow1TestBackend()..registered = true;
      backend.handle = (name, input) async {
        if (name == 'getTicket' && missing) {
          throw const AppException(
            code: 'NOT_REGISTERED',
            message: 'No registration for this event.',
          );
        }
        return backend.respond(name, input);
      };
      final c = await open(
        tester,
        backend,
        '/my-events/ticket?event=server-event-17',
      );
      try {
        expect(find.text('EVIA-SERVER-17'), findsOneWidget);
        expect(find.text('Demo: xác nhận đã quét'), findsNothing);
        missing = true;
        c.invalidate(flow1TicketProvider('server-event-17'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byType(AppErrorWidget), findsOneWidget);
        expect(find.text('EVIA-SERVER-17'), findsNothing);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        c.dispose();
      }
    },
  );

  testWidgets(
    'revoked ticket uses server cancellation state even when cache is stale',
    (tester) async {
      final backend = Flow1TestBackend()..registered = true;
      backend.handle = (name, input) async {
        final response = backend.respond(name, input);
        if (name == 'getTicket') {
          (response['registration'] as Map)['state'] = 'cancelled';
          (response['ticket'] as Map)['status'] = 'revoked';
        }
        return response;
      };
      final c = await open(
        tester,
        backend,
        '/my-events/ticket?event=server-event-17',
      );
      try {
        expect(tester.takeException(), isNull);
        expect(
          find.text(
            'This registration was cancelled. Your ticket is no longer available.',
          ),
          findsOneWidget,
        );
        expect(backend.calls.where((v) => v.name == 'getTicketQr'), isEmpty);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        c.dispose();
      }
    },
  );

  testWidgets(
    'ticket for a deleted event reports unavailable without a render exception',
    (tester) async {
      final backend = Flow1TestBackend()..registered = true;
      backend.handle = (name, input) async {
        final response = backend.respond(name, input);
        if (name == 'getTicket') response['event'] = null;
        return response;
      };
      final c = await open(
        tester,
        backend,
        '/my-events/ticket?event=server-event-17',
      );
      try {
        expect(tester.takeException(), isNull);
        expect(find.byType(AppErrorWidget), findsOneWidget);
        expect(backend.calls.where((v) => v.name == 'getTicketQr'), isEmpty);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        c.dispose();
      }
    },
  );
  testWidgets(
    'ticket renders authoritative response when My Events cache has no registration',
    (tester) async {
      final backend = Flow1TestBackend()..registered = true;
      backend.handle = (name, input) async => name == 'listMyEvents'
          ? {'items': <Map<String, dynamic>>[], 'nextCursor': null}
          : backend.respond(name, input);
      final c = await open(
        tester,
        backend,
        '/my-events/ticket?event=server-event-17',
      );
      try {
        expect(tester.takeException(), isNull);
        expect(find.text('Server event title'), findsOneWidget);
        expect(find.text('EVIA-SERVER-17'), findsOneWidget);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        c.dispose();
      }
    },
  );

  testWidgets(
    'missing cancellation registration uses existing error state instead of throwing',
    (tester) async {
      final c = await open(
        tester,
        Flow1TestBackend(),
        '/my-events/cancel?event=server-event-17',
      );
      try {
        expect(tester.takeException(), isNull);
        expect(find.byType(AppErrorWidget), findsOneWidget);
        expect(find.text('Yes, Cancel'), findsNothing);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        c.dispose();
      }
    },
  );
  testWidgets(
    'confirmed cancellation closes the pushed dialog after server refresh',
    (tester) async {
      var cancelled = false;
      final backend = Flow1TestBackend()..registered = true;
      backend.handle = (name, input) async {
        if (name == 'cancelRegistration') {
          cancelled = true;
          return {
            'state': 'cancelled',
            'depositRefunded': 15,
            'wallet': {'availableCoins': 165, 'heldCoins': 0},
          };
        }
        final result = backend.respond(name, input);
        if (cancelled && name == 'listMyEvents') {
          ((result['items'] as List).single as Map)['registration'] = {
            'state': 'cancelled',
          };
        }
        if (cancelled && name == 'getAccount') {
          result['wallet'] = {'availableCoins': 165, 'heldCoins': 0};
        }
        return result;
      };
      final c = await open(tester, backend, '/my-events');
      await tester.scrollUntilVisible(
        find.text('Cancel'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Yes, Cancel'));
      await tester.pumpAndSettle();
      tester
          .widget<TextButton>(
            find
                .ancestor(
                  of: find.text('Yes, Cancel'),
                  matching: find.byType(TextButton),
                )
                .first,
          )
          .onPressed!();
      await tester.pumpAndSettle();
      expect(cancelled, isTrue);
      expect(find.text('Cancel Registration?'), findsNothing);
      expect(find.text('No events on this date'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      c.dispose();
    },
  );
  testWidgets(
    'ticket demo button waits for server and replaces QR with confirmed state',
    (tester) async {
      var attended = false;
      final confirmation = Completer<void>();
      final backend = Flow1TestBackend()..registered = true;
      backend.handle = (name, input) async {
        if (name == 'demoConfirmAttendance') {
          await confirmation.future;
          attended = true;
          return {
            'eventId': 'server-event-17',
            'coinsGranted': 100,
            'isDemo': true,
          };
        }
        final response = backend.respond(name, input);
        if (name == 'getPublicCatalog' && input['kind'] == 'events') {
          response['items'] = [
            {...testEvent(), 'isDemo': true},
          ];
        }
        if (name == 'getAccount') {
          (response['profile'] as Map)['demoAttendanceEnabled'] = true;
          (response['profile'] as Map)['isDemo'] = true;
        }
        if (attended && name == 'getTicket') {
          (response['ticket'] as Map)['status'] = 'checked_in';
          (response['registration'] as Map)['state'] = 'attended';
        }
        if (attended && name == 'listMyEvents') {
          final row = (response['items'] as List).single as Map;
          row['attendance'] = {
            'rewardCoinsGranted': 100,
            'verifiedAt': '2026-11-05T03:00:00Z',
          };
          row['registration'] = {'state': 'attended'};
        }
        return response;
      };
      final c = await open(
        tester,
        backend,
        '/my-events/ticket?event=server-event-17',
      );
      final button = find.widgetWithText(TextButton, 'Demo: xác nhận đã quét');
      expect(button.hitTestable(), findsOneWidget);
      expect(
        find.ancestor(of: button, matching: find.byType(Scrollable)),
        findsNothing,
      );
      await tester.pump(const Duration(seconds: 1));
      expect(attended, isFalse);
      expect(
        backend.calls.where((v) => v.name == 'demoConfirmAttendance'),
        isEmpty,
      );
      await c.read(flow1ViewModelProvider.notifier).refresh();
      await tester.pumpAndSettle();
      expect(
        backend.calls.where((v) => v.name == 'demoConfirmAttendance'),
        isEmpty,
      );
      await tester.tap(button);
      await tester.pump();
      expect(tester.widget<TextButton>(button).onPressed, isNull);
      expect(find.text('Attendance confirmed'), findsNothing);
      confirmation.complete();
      await tester.pumpAndSettle();
      expect(find.text('Attendance confirmed'), findsWidgets);
      expect(find.text('Demo: xác nhận đã quét'), findsNothing);
      expect(
        backend.calls.where((v) => v.name == 'demoConfirmAttendance'),
        hasLength(1),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      c.dispose();
    },
  );

  testWidgets(
    'notifications render server data and mark-read action without mock notices',
    (tester) async {
      var read = false;
      final backend = Flow1TestBackend();
      backend.handle = (name, input) async {
        if (name == 'listOwned' && input['kind'] == 'notifications') {
          return {
            'items': [
              {
                'id': 'notice-17',
                'type': 'new_event',
                'title': 'Actual server notice',
                'body': 'Server event update',
                'entityType': 'event',
                'entityId': 'server-event-17',
                'createdAt': '2026-11-05T03:00:00Z',
                'readAt': read ? '2026-11-05T04:00:00Z' : null,
              },
            ],
            'nextCursor': null,
          };
        }
        if (name == 'markNotificationsRead') {
          read = true;
          return {'updatedCount': 1};
        }
        return backend.respond(name, input);
      };
      final c = await open(
        tester,
        backend,
        '/profile/notifications',
        width: 360,
      );
      expect(find.text('Actual server notice'), findsOneWidget);
      expect(find.text('Server event update'), findsOneWidget);
      await tester.tap(find.text('Mark all read'));
      await tester.pumpAndSettle();
      expect(find.text('NEW'), findsNothing);
      expect(
        backend.calls.where((v) => v.name == 'markNotificationsRead'),
        hasLength(1),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      c.dispose();
    },
  );
}
