import '../models/flow1_models.dart';
import '../core/errors/app_exception.dart';
import '../services/backend_service.dart';
import '../models/evia_models.dart';

class Flow1Repository {
  const Flow1Repository(this.backend);
  final BackendService backend;

  Future<List<Map<String, dynamic>>> _pages(
    String operation,
    Map<String, dynamic> input,
  ) async {
    final result = <Map<String, dynamic>>[], cursors = <String>{};
    String? cursor;
    do {
      final response = await backend.call(operation, {
        ...input,
        'limit': 50,
        'cursor': ?cursor,
      });
      result.addAll(jsonRows(response['items']));
      cursor = response['nextCursor'] as String?;
      if (cursor != null && !cursors.add(cursor)) {
        throw const AppException(
          code: 'invalid_cursor',
          message: 'The server returned an invalid next page. Please reload.',
        );
      }
    } while (cursor != null);
    return result;
  }

  Future<Flow1Snapshot> load(bool signedIn) async {
    final rows = await Future.wait(
      [
        'events',
        'organizers',
        'interests',
      ].map((kind) => _pages('getPublicCatalog', {'kind': kind})),
    );
    Map<String, dynamic>? account;
    List<Map<String, dynamic>> followed = [], saved = [], mine = [];
    if (signedIn) {
      account = await backend.call('getAccount');
      final owned = await Future.wait([
        _pages('listOwned', {'kind': 'following'}),
        _pages('listOwned', {'kind': 'bookmarks'}),
        _pages('listMyEvents', {}),
      ]);
      followed = owned[0];
      saved = owned[1];
      mine = owned[2];
    }
    return Flow1Snapshot(
      events: rows[0].map(Flow1Event.new).toList(),
      organizers: rows[1],
      interests: rows[2],
      account: account,
      followed: followed.map((d) => d['organizerId'] as String).toSet(),
      saved: saved.map((d) => d['eventId'] as String).toSet(),
      myEvents: mine,
      selectedInterests: account == null
          ? {}
          : Set<String>.from(jsonMap(account['profile'])['interests'] as List),
    );
  }

  Future<void> follow(String id, bool value) => backend.call(
    value ? 'followOrganizer' : 'unfollowOrganizer',
    {'organizerId': id},
  );
  Future<void> bookmark(String id, bool value) =>
      backend.call('setBookmark', {'eventId': id, 'saved': value});
  Future<void> saveInterests(Set<String> ids) =>
      backend.call('saveInterests', {'interests': ids.toList()});
  Future<void> updateProfile(Map<String, dynamic> profile) =>
      backend.call('updateProfile', profile);
  Future<void> going(String eventId) =>
      backend.call('setWalkInGoing', {'eventId': eventId, 'going': true});
  Future<Flow1Event> event(String id) async =>
      Flow1Event(await backend.call('getEvent', {'eventId': id}));
  Future<Map<String, dynamic>> register(Map<String, dynamic> input) =>
      backend.call('registerForEvent', input);
  Future<Map<String, dynamic>> recoverRegistration(String requestId) async =>
      jsonMap(
        (await backend.call('getOperationStatus', {
          'operationKind': 'register',
          'operationId': requestId,
        }))['result'],
      );
  Future<Map<String, dynamic>> ticket(String id) =>
      backend.call('getTicket', {'eventId': id});
  Future<Map<String, dynamic>> ticketQr(String id) =>
      backend.call('getTicketQr', {'eventId': id});
  Future<Map<String, dynamic>> cancel(String eventId, String requestId) =>
      backend.call('cancelRegistration', {
        'eventId': eventId,
        'requestId': requestId,
      });
  Future<void> stopGoing(String eventId) =>
      backend.call('setWalkInGoing', {'eventId': eventId, 'going': false});
  Future<Map<String, dynamic>> demoAttend(String eventId, String requestId) =>
      backend.call('demoConfirmAttendance', {
        'eventId': eventId,
        'requestId': requestId,
      });
  Future<Map<String, dynamic>> verifyWalkIn(
    Map<String, dynamic> input, {
    bool manual = false,
  }) => backend.call(manual ? 'verifyWalkInCode' : 'verifyWalkInQr', input);
  Future<Map<String, dynamic>> recover(String kind, String requestId) async =>
      jsonMap(
        (await backend.call('getOperationStatus', {
          'operationKind': kind,
          'operationId': requestId,
        }))['result'],
      );
  Future<List<Map<String, dynamic>>> notifications() =>
      _pages('listOwned', {'kind': 'notifications'});
  Future<void> readNotifications(List<String> ids) async {
    for (var i = 0; i < ids.length; i += 30) {
      await backend.call('markNotificationsRead', {
        'notificationIds': ids.sublist(
          i,
          i + 30 > ids.length ? ids.length : i + 30,
        ),
      });
    }
  }

  Future<Map<String, dynamic>> loadRewards() async {
    final rows = await Future.wait([
      backend.call('getAccount'),
      backend.call('getEventMilestones'),
      _pages('getPublicCatalog', {'kind': 'rewards'}),
      _pages('listOwned', {'kind': 'redemptions'}),
      _pages('listOwned', {'kind': 'vouchers'}),
      _pages('listOwned', {'kind': 'ledger'}),
    ]);
    return {
      'account': rows[0],
      'milestones': rows[1],
      'rewards': rows[2],
      'redemptions': rows[3],
      'vouchers': rows[4],
      'ledger': rows[5],
    };
  }

  Future<Map<String, dynamic>> claimDaily() =>
      backend.call('claimDailyCheckin');
  Future<Map<String, dynamic>> claimMilestone(String id, int version) =>
      backend.call('claimEventMilestone', {
        'milestoneId': id,
        'expectedVersion': version,
      });
  Future<Map<String, dynamic>> redeem(Map<String, dynamic> input) =>
      backend.call('redeemReward', input);
  Future<Map<String, dynamic>> voucherCode(String id) =>
      backend.call('getVoucherCode', {'voucherId': id});

  Future<List<Flow1Event>> search(
    String q,
    String category,
    EventFilters filters,
  ) async {
    final now = vietnamTime(DateTime.now());
    final day = DateTime.utc(now.year, now.month, now.day);
    DateTime? from, until;
    switch (filters.date) {
      case 'This week':
        from = day.subtract(Duration(days: day.weekday - 1));
        until = from.add(const Duration(days: 7));
      case 'This month':
        from = DateTime.utc(now.year, now.month);
        until = DateTime.utc(now.year, now.month + 1);
      case 'Next month':
        from = DateTime.utc(now.year, now.month + 1);
        until = DateTime.utc(now.year, now.month + 2);
      case 'Custom range':
        if (filters.rangeStart != null && filters.rangeEnd != null) {
          final a = filters.rangeStart!, b = filters.rangeEnd!;
          from = DateTime.utc(a.year, a.month, a.day);
          until = DateTime.utc(b.year, b.month, b.day + 1);
        }
    }
    const times = {
      'Morning': 'morning',
      'Afternoon': 'afternoon',
      'Evening': 'evening',
    };
    const durations = {
      'Under 1 hour': 'under_hour',
      '1–3 hours': 'one_to_three_hours',
      'Over 3 hours': 'over_three_hours',
    };
    const availability = {
      'Spots Available': 'available',
      'Full': 'full',
      'Unlimited Registration': 'unlimited',
    };
    final selected = category == 'All' ? filters.category : category;
    final rows = await _pages('getPublicCatalog', {
      'kind': 'events',
      if (q.trim().isNotEmpty) 'q': q.trim(),
      if (selected != 'All') 'category': selected.toLowerCase(),
      if (from != null)
        'from': from.subtract(const Duration(hours: 7)).toIso8601String(),
      if (until != null)
        'until': until.subtract(const Duration(hours: 7)).toIso8601String(),
      if (times.containsKey(filters.time)) 'timeOfDay': times[filters.time],
      if (durations.containsKey(filters.duration))
        'duration': durations[filters.duration],
      if (availability.containsKey(filters.availability))
        'availability': availability[filters.availability],
      if (filters.policy != 'Any')
        'participationMode': filters.policy.toLowerCase().contains('walk')
            ? 'walk_in'
            : 'registration',
    });
    return rows.map(Flow1Event.new).toList();
  }
}
