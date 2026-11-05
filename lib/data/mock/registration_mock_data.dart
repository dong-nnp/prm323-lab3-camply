import '../../core/constants/flow_assets.dart';
import '../../models/registration_models.dart';
import 'evia_mock_data.dart';

/// Figma fixtures only. No real registration or verified-account assertion.
abstract final class RegistrationMockData {
  static EventPresentation? findEvent(String key) {
    final id = key == 'club' ? club.id : key;
    for (final event in [music, club, innovation, arts, leadership]) {
      if (event.id == id) return event;
    }
    for (final event in [
      ...EviaMockData.catalog,
      EviaMockData.recommendedAi,
      EviaMockData.suggestedAi,
    ]) {
      if (event.detailKey != key) continue;
      return EventPresentation(
        id: event.id == 'music' ? music.id : event.detailKey,
        title: event.title,
        category: event.category,
        date: event.date.split(' · ').first,
        time: event.date.split(' · ').last,
        venue: event.location,
        organizer: event.organizer ?? '',
        start: EviaMockData.startOf(event),
        coins: event.coins,
        deposit: event.id == 'music' ? music.deposit : 0,
        walkIn: event.policy == 'Walk-in allowed',
        audience: event.audience,
        policy: event.policy,
        image: event.image,
        spots: event.id == 'music' ? music.spots : null,
      );
    }
    return null;
  }

  static const name = 'Alex Morgan';
  static const studentId = 'STU-849201';
  static const profileStudentId = 'STU-842901';
  static const email = 'alex.m@university.edu';
  static const phone = '+1 (555) 019-2834';
  static const venue = 'Main Stadium, University Campus';
  static final music = EventPresentation(
    id: 'music-live',
    title: 'Campus Music Night',
    category: 'Music',
    date: 'Saturday, Nov 7, 2026',
    time: '18:00 – 22:00',
    venue: venue,
    organizer: 'Student Union',
    start: DateTime(2026, 11, 7, 18),
    coins: 120,
    deposit: 100,
    spots: 120,
  );
  static final club = EventPresentation(
    id: 'club-live',
    title: 'Campus Club Fair',
    category: 'Club',
    date: 'Tuesday, Nov 10, 2026',
    time: '10:00',
    venue: 'Central Plaza',
    organizer: 'Student Union',
    start: DateTime(2026, 11, 10, 10),
    coins: 80,
    walkIn: true,
    policy: 'Walk-in allowed',
    image: FlowAssets.image('2083:5861', 1),
  );
  static final innovation = EventPresentation(
    id: 'innovation',
    title: 'AI & Innovation Workshop',
    category: 'Technology',
    date: 'Monday, Nov 9, 2026',
    time: '14:00',
    venue: 'Innovation Lab',
    organizer: 'Tech Club',
    start: DateTime(2026, 11, 9, 14),
    coins: 50,
  );
  static final arts = EventPresentation(
    id: 'arts',
    title: 'Creative Arts Showcase',
    category: 'Arts',
    date: 'Sunday, Oct 25, 2026',
    time: '15:00',
    venue: 'Arts Hall',
    organizer: 'Arts Society',
    start: DateTime(2026, 10, 25, 15),
    coins: 40,
    past: true,
  );
  static final leadership = EventPresentation(
    id: 'leadership',
    title: 'Student Leadership Workshop',
    category: 'Academic',
    date: 'Wednesday, Nov 18, 2026',
    time: '14:30',
    venue: 'Union Hall B, 2nd Floor',
    organizer: 'Student Union',
    start: DateTime(2026, 11, 18, 14, 30),
    coins: 60,
    image: FlowAssets.image('2083:6080', 2),
  );
  static final saved = <SavedEventPresentation>[
    SavedEventPresentation(
      music,
      'Sat, Nov 7, 2026 • 6:00 PM',
      'Student Union',
      FlowAssets.image('2091:440', 0),
    ),
    SavedEventPresentation(
      innovation,
      'Mon, Nov 9, 2026 • 2:00 PM',
      'Tech Club',
      FlowAssets.image('2091:440', 1),
    ),
    SavedEventPresentation(
      club,
      'Tue, Nov 10, 2026 • 10:00 AM',
      'Student Affairs',
      FlowAssets.image('2091:440', 2),
    ),
    SavedEventPresentation(
      arts,
      'Sun, Oct 25, 2026 • 3:00 PM',
      'Arts Society',
      FlowAssets.image('2091:440', 3),
    ),
  ];
  static const savedIds = {'music-live', 'innovation', 'club-live', 'arts'};
  static const organizerDescription =
      'The official governing student body advocating for campus life, hosting university-wide fairs, forums, and student-led activities.';
  static const agenda = [
    EventAgendaItem(
      '17:30',
      'Doors Open & Check-in',
      'West Lawn Gate 4 · ID verification & wristband pickup',
    ),
    EventAgendaItem(
      '18:00',
      'Opening Act: Campus Indie Band',
      'Main Festival Stage · Student opener',
    ),
    EventAgendaItem(
      '19:15',
      'Student Showcase & DJ Set',
      'Student Union Stage · Interactive live beats',
    ),
    EventAgendaItem(
      '20:30',
      'Headline Performance',
      'Main Festival Stage · Special guest alumni artist',
    ),
    EventAgendaItem(
      '21:45',
      'Closing Remarks & Encores',
      'Main Festival Stage · Wrap-up & group photo',
    ),
  ];
  static const notices = [
    ProfileNotice(
      'registration',
      'Registration Confirmed',
      'Your Campus Music Night ticket is ready.',
      '10m ago',
      0,
      unread: true,
      today: true,
    ),
    ProfileNotice(
      'new-event',
      'New Event Available',
      'AI & Future Careers Workshop is open for registration.',
      '2h ago',
      1,
      unread: true,
      today: true,
    ),
    ProfileNotice(
      'reminder',
      'Event Reminder',
      'Campus Music Night starts in 3 days.',
      'Yesterday',
      2,
    ),
    ProfileNotice(
      'schedule',
      'Schedule Update',
      'Photography Walk venue information has been updated.',
      'Oct 8',
      3,
    ),
  ];
}
