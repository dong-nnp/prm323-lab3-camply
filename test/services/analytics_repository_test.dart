import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab03/models/analytics_events.dart';
import 'package:prm393_lab03/repositories/analytics_repository.dart';
import 'package:prm393_lab03/core/errors/app_exception.dart';

import '../helpers/fake_analytics_service.dart';

void main() {
  test('schema rejects PII fields, raw search, invalid types and enums', () {
    for (final values in <Map<String, Object>>[
      {'method': 'password', 'email': 'student@example.com'},
      {'method': 'student@example.com'},
      {'method': 1},
    ]) {
      expect(
        () => AnalyticsEvents.validate('login', values),
        throwsArgumentError,
      );
    }
    expect(
      () => AnalyticsEvents.validate('search', {'search_term': 'private'}),
      throwsArgumentError,
    );
    expect(
      () => AnalyticsEvents.validate('search', {
        'search_term': 'private',
        'loaded_count': 2,
        'has_more': 0,
        'outcome': 'data',
      }),
      throwsArgumentError,
    );
    expect(
      () => AnalyticsEvents.validate('search', {
        'search_term': 'free_text_redacted',
        'loaded_count': 2,
        'has_more': 2,
        'outcome': 'data',
      }),
      throwsArgumentError,
    );
    expect(
      () => AnalyticsEvents.validate('search', {
        'search_term': 'free_text_redacted',
        'loaded_count': 2,
        'has_more': 0,
        'outcome': 'unknown',
      }),
      throwsArgumentError,
    );
    AnalyticsEvents.validate('search', {
      'search_term': 'free_text_redacted',
      'loaded_count': 2,
      'has_more': 0,
      'outcome': 'data',
    });
    AnalyticsEvents.validate('search', {
      'search_term': 'technology',
      'loaded_count': 0,
      'has_more': 1,
      'outcome': 'empty',
    });
    expect(
      AnalyticsEvents.redactSearchTerm(query: 'Flutter secret'),
      'free_text_redacted',
    );
    expect(
      AnalyticsEvents.redactSearchTerm(query: '  ', category: 'Technology'),
      'technology',
    );
    expect(AnalyticsEvents.redactSearchTerm(query: '', category: 'All'), 'all');
    expect(
      AnalyticsEvents.redactSearchTerm(query: '', category: 'Custom Label'),
      'free_text_redacted',
    );
    expect(
      () => AnalyticsEvents.validate('view_event', {
        'event_id': 'id',
        'participation_mode': 'anything',
      }),
      throwsArgumentError,
    );
  });
  test('identity order, retry deduplication and logout clear', () async {
    final sdk = FakeAnalyticsService();
    final repo = AnalyticsRepository(sdk, enabled: true);
    final identity = repo.identify('student-a');
    final event = repo.track('login', parameters: {'method': 'password'});
    await Future.wait([identity, event]);
    for (var i = 0; i < 2; i++) {
      await repo.track(
        'register_event',
        once: 'receipt-private',
        parameters: {'event_id': 'event-1', 'deposit_coins': 50},
      );
    }
    expect(sdk.events.map((e) => e.name), ['login', 'register_event']);
    expect(sdk.events.every((e) => e.uid == 'student-a'), isTrue);
    expect(sdk.events.last.parameters.containsKey('request_id'), isFalse);
    await repo.identify(null);
    await repo.track('logout');
    expect(sdk.events.last.uid, isNull);
    await repo.identify('student-b');
    await repo.track(
      'register_event',
      once: 'receipt-private',
      parameters: {'event_id': 'event-1', 'deposit_coins': 50},
    );
    expect(sdk.events.last.uid, 'student-b');
  });
  test('disabled, rejected telemetry and SDK failures do not throw', () async {
    final sdk = FakeAnalyticsService();
    final disabled = AnalyticsRepository(sdk, enabled: false);
    await disabled.identify('student');
    await disabled.track('logout');
    expect(sdk.identities, isEmpty);
    final repo = AnalyticsRepository(sdk, enabled: true);
    sdk.fail = true;
    await repo.identify('student');
    await repo.track('logout');
    sdk.fail = false;
    await repo.track('logout');
    expect(sdk.events, isEmpty);
    await repo.identify(null);
    await repo.track('login', parameters: {'email': 'private'});
    await repo.error(
      'login',
      const AppException(code: 'private', message: 'secret'),
    );
    expect(sdk.events.single.parameters, {
      'action': 'login',
      'error_code': 'unexpected',
    });
  });
}
