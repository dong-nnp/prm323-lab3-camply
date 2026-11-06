import '../core/errors/app_exception.dart';
import 'evia_models.dart';
import 'registration_models.dart';

Map<String, dynamic> jsonMap(dynamic value) =>
    Map<String, dynamic>.from(value as Map);
List<Map<String, dynamic>> jsonRows(dynamic value) =>
    (value as List).map(jsonMap).toList(growable: false);
DateTime vietnamTime(DateTime instant) =>
    instant.toUtc().add(const Duration(hours: 7));
String eventDate(DateTime instant) {
  final date = vietnamTime(instant);
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}, ${date.year} · ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}

class Flow1Event {
  Flow1Event(Map<String, dynamic> value) : data = Map.unmodifiable(value) {
    if (data['id'] is! String ||
        data['title'] is! String ||
        data['organizerId'] is! String ||
        !['registration', 'walk_in'].contains(data['participationMode']) ||
        data['depositCoins'] is! num ||
        data['attendanceRewardCoins'] is! num) {
      throw const AppException(
        code: 'invalid_event',
        message: 'The event data is incomplete. Please reload.',
      );
    }
    start;
    end;
    venue;
  }
  final Map<String, dynamic> data;
  String get id => data['id'] as String;
  String get title => data['title'] as String;
  String get organizerId => data['organizerId'] as String;
  String get category => data['category'] as String;
  String get description => data['description'] as String? ?? '';
  DateTime get start => DateTime.parse(data['startAt'] as String);
  DateTime get end => DateTime.parse(data['endAt'] as String);
  Map<String, dynamic> get venue => jsonMap(data['venue']);
  bool get walkIn => data['participationMode'] == 'walk_in';
  bool get featured => data['featured'] == true;
  bool registrationOpen(DateTime now) =>
      !walkIn &&
      data['status'] == 'published' &&
      now.isBefore(
        DateTime.parse(
          data['registrationClosesAt'] as String? ?? data['startAt'] as String,
        ),
      ) &&
      (spots == null || spots! > 0);
  int get deposit => (data['depositCoins'] as num).toInt();
  int get reward => (data['attendanceRewardCoins'] as num).toInt();
  int? get spots => (data['spotsRemaining'] as num?)?.toInt();
  String? get imageUrl => data['imageUrl'] as String?;
  Map<String, dynamic>? get terms => data['registrationTerms'] == null
      ? null
      : jsonMap(data['registrationTerms']);
  List<Map<String, dynamic>> get schedule => jsonRows(data['schedule'] ?? []);
  CampusEvent card(String organizer) => CampusEvent(
    id: id,
    title: title,
    category: category,
    date: eventDate(start),
    location: venue['name'] as String,
    audience: 'Open to Public',
    policy: walkIn ? 'Walk-in allowed' : 'Registration required',
    coins: reward,
    organizer: organizer,
    organizerId: organizerId,
    image: imageUrl,
    note: spots == null ? 'Unlimited registration' : '$spots spots left',
  );
  EventPresentation presentation(String organizer) => EventPresentation(
    id: id,
    title: title,
    category: category,
    date: eventDate(start).split(' · ').first,
    time: eventDate(start).split(' · ').last,
    venue: venue['name'] as String,
    organizer: organizer,
    start: start,
    coins: reward,
    deposit: deposit,
    walkIn: walkIn,
    past: end.isBefore(DateTime.now().toUtc()),
    spots: spots,
    audience: 'Open to Public',
    policy: walkIn ? 'Walk-in allowed' : 'Registration required',
    image: imageUrl,
  );
}

class Flow1Snapshot {
  const Flow1Snapshot({
    this.events = const [],
    this.organizers = const [],
    this.interests = const [],
    this.account,
    this.followed = const {},
    this.saved = const {},
    this.myEvents = const [],
    this.selectedInterests = const {},
    this.busy = false,
    this.actionError,
  });
  final List<Flow1Event> events;
  final List<Map<String, dynamic>> organizers, interests, myEvents;
  final Map<String, dynamic>? account;
  final Set<String> followed, saved;
  final Set<String> selectedInterests;
  final bool busy;
  final String? actionError;
  Flow1Snapshot withAction({
    bool busy = false,
    String? error,
    Set<String>? saved,
  }) => Flow1Snapshot(
    events: events,
    organizers: organizers,
    interests: interests,
    account: account,
    followed: followed,
    saved: saved ?? this.saved,
    myEvents: myEvents,
    selectedInterests: selectedInterests,
    busy: busy,
    actionError: error,
  );
  Flow1Snapshot withInterests(Set<String> ids) => Flow1Snapshot(
    events: events,
    organizers: organizers,
    interests: interests,
    account: account,
    followed: followed,
    saved: saved,
    myEvents: myEvents,
    selectedInterests: Set.unmodifiable(ids),
  );
  int get available => account == null
      ? 0
      : (jsonMap(account!['wallet'])['availableCoins'] as num).toInt();
  int get held => account == null
      ? 0
      : (jsonMap(account!['wallet'])['heldCoins'] as num).toInt();
  Map<String, dynamic> get profile =>
      account == null ? {} : jsonMap(account!['profile']);
  String organizerName(String id) =>
      organizers.where((o) => o['id'] == id).firstOrNull?['name'] as String? ??
      'Organizer';
  List<CampusOrganizer> get organizerCards => organizers
      .map(
        (o) => CampusOrganizer(
          o['id'] as String,
          o['name'] as String,
          o['description'] as String? ?? '',
          '${o['followerCount'] ?? 0} followers',
          upcomingCount: events
              .where(
                (e) =>
                    e.organizerId == o['id'] &&
                    e.end.isAfter(DateTime.now().toUtc()),
              )
              .length,
        ),
      )
      .toList();
}
