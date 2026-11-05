import 'package:prm393_lab03/services/backend_service.dart';
import 'package:prm393_lab03/core/errors/app_exception.dart';

Map<String, dynamic> testEvent({int? spots = 2, int deposit = 50}) => {
  'id': 'server-event-17',
  'title': 'Server event title',
  'organizerId': 'server-club-4',
  'category': 'technology',
  'status': 'published',
  'participationMode': 'registration',
  'depositCoins': deposit,
  'attendanceRewardCoins': 100,
  'spotsRemaining': spots,
  'startAt': '2030-12-01T02:00:00Z',
  'endAt': '2030-12-01T04:00:00Z',
  'venue': {'name': 'Server venue'},
  'registrationTerms': {'version': 'server-v2', 'text': 'Server terms'},
};

class Flow1TestBackend implements BackendService {
  final calls = <({String name, Map<String, dynamic> input})>[];
  Future<Map<String, dynamic>> Function(String, Map<String, dynamic>)? handle;
  Set<String> selected = {'technology', 'music', 'sports'};
  bool onboarded = true, following = false, bookmarked = false;
  bool registered = false;
  List<Map<String, dynamic>> get interests => [
    for (final id in ['technology', 'music', 'sports', 'arts'])
      {'id': id, 'label': 'Server $id'},
  ];
  @override
  Future<Map<String, dynamic>> call(
    String operation, [
    Map<String, dynamic> input = const {},
  ]) async {
    calls.add((name: operation, input: Map.of(input)));
    return handle != null
        ? handle!(operation, input)
        : respond(operation, input);
  }

  Map<String, dynamic> respond(String operation, Map<String, dynamic> input) {
    switch (operation) {
      case 'getPublicCatalog':
        return {
          'items': switch (input['kind']) {
            'events' => [testEvent()],
            'organizers' => [
              {
                'id': 'server-club-4',
                'name': 'Server club',
                'description': 'Club description',
                'followerCount': 7,
              },
            ],
            'interests' => interests,
            _ => <Map<String, dynamic>>[],
          },
          'nextCursor': null,
        };
      case 'getAccount':
        return {
          'profile': {
            'displayName': 'Server user',
            'studentId': 'SE123456',
            'universityEmail': 'student@fpt.edu.vn',
            'interests': selected.toList(),
            'onboardingCompleted': onboarded,
          },
          'wallet': {'availableCoins': 200, 'heldCoins': 0},
        };
      case 'listOwned':
        return {
          'items': input['kind'] == 'following'
              ? [
                  if (following) {'organizerId': 'server-club-4'},
                ]
              : [
                  if (bookmarked) {'eventId': 'server-event-17'},
                ],
          'nextCursor': null,
        };
      case 'listMyEvents':
        return {
          'items': <Map<String, dynamic>>[
            if (registered)
              {
                'event': testEvent(),
                'registration': {'state': 'registered'},
                'going': false,
                'attendance': null,
                'past': false,
              },
          ],
          'nextCursor': null,
        };
      case 'getEvent':
        return testEvent();
      case 'saveInterests':
        selected = Set<String>.from(input['interests'] as List);
        onboarded = true;
        return {};
      case 'followOrganizer':
        following = true;
        return {};
      case 'unfollowOrganizer':
        following = false;
        return {};
      case 'setBookmark':
        bookmarked = input['saved'] as bool;
        return {};
      case 'registerForEvent':
        registered = true;
        return {'ticketId': 'server-ticket', 'eventId': input['eventId']};
      case 'getTicket':
        if (!registered) {
          throw const AppException(
            code: 'NOT_REGISTERED',
            message: 'No registration',
          );
        }
        return {
          'event': testEvent(),
          'registration': {
            'depositCoins': 50,
            'attendeeSnapshot': {
              'fullName': 'Server user',
              'studentId': 'SE123456',
            },
          },
          'ticket': {'status': 'active', 'ticketNumber': 'EVIA-SERVER-17'},
        };
      case 'getTicketQr':
        return {
          'qrPayload': 'evia:ticket:test-only-token',
          'manualCode': 'ABCD-EFGH',
          'expiresAt': '2030-12-01T04:00:00Z',
        };
      default:
        throw StateError('Unexpected call: $operation');
    }
  }
}
