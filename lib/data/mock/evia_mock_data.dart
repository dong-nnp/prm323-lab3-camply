import '../../core/constants/figma_assets.dart';
import '../../models/evia_models.dart';

/// Explicit UI demo content transcribed from Figma, authorized by the user.
/// Replace this presentation source when a real event service is specified.
abstract final class EviaMockData {
  static const initialInterests = {
    'Technology',
    'Music & Gigs',
    'Arts & Culture',
  };
  static const initialSaved = {'football', 'mobile'};
  static const recentSearches = [
    'campus music night',
    'football tournament',
    'hackathon',
  ];
  static const discoverName = 'Hey Alex! 👋';
  static const points = '350 pts';
  // The reference timeline is anchored to the featured event's week.
  static final referenceDate = DateTime(2026, 10, 26);
  static final music = CampusEvent(
    id: 'music',
    title: 'Campus Music Night',
    category: 'Music',
    date: 'Oct 26 · 18:00',
    location: 'Main Stadium',
    organizer: 'Student Union',
    coins: 120,
    note: '120 spots left',
    image: FigmaAssets.path('2083:993', 'imgCampusMusicNight'),
  );
  static const recommendedAi = CampusEvent(
    id: 'ai',
    detailKey: 'ai-recommended',
    title: 'AI & Future Careers Workshop',
    category: 'Technology',
    date: 'Nov 2 · 14:00',
    location: 'Tech Center',
    audience: 'CS Students Only',
    coins: 50,
  );
  static const photoWalk = CampusEvent(
    id: 'photo-walk',
    title: 'Autumn Photography Walk',
    category: 'Arts',
    date: 'Nov 5 · 10:00',
    location: 'Memorial Courtyard',
    organizer: 'Photography Club',
    policy: 'Walk-in allowed',
    coins: 30,
  );
  static final suggestedAi = CampusEvent(
    id: 'ai',
    detailKey: 'ai-suggested',
    title: 'AI & Future Careers Workshop',
    category: 'Technology',
    date: 'Nov 2 · 14:00',
    location: 'Innovation Hub',
    audience: 'Open to Public',
    policy: 'Walk-in allowed',
    note: 'Free admission',
    image: FigmaAssets.path('2083:993', 'imgAiFutureCareersWorkshop'),
  );
  static final searchEvents = <CampusEvent>[
    CampusEvent(
      id: 'ai',
      title: 'AI & Future Careers Workshop',
      category: 'Technology',
      date: 'Nov 2 · 14:00',
      location: 'Innovation Hub',
      image: FigmaAssets.path('2083:826', 'imgAiFutureCareersWorkshop'),
    ),
    CampusEvent(
      id: 'design',
      title: 'Design Thinking Bootcamp',
      keywords: 'workshop',
      category: 'Arts',
      date: 'Nov 4 · 09:00',
      location: 'Room A203',
      image: FigmaAssets.path('2083:826', 'imgDesignThinkingBootcamp'),
    ),
    const CampusEvent(
      id: 'mobile',
      title: 'Mobile App Development Workshop',
      category: 'Technology',
      date: 'Nov 6 · 13:30',
      location: 'Computer Lab B',
      policy: 'Waitlist available',
    ),
  ];
  static const upcoming = <CampusEvent>[
    CampusEvent(
      id: 'football',
      title: 'Football Tournament Finals',
      category: 'Sports',
      date: 'Oct 28 · 16:00',
      location: 'Campus Sports Field',
      coins: 80,
    ),
    CampusEvent(
      id: 'robotics',
      title: 'University Robotics Exhibition',
      category: 'Technology',
      date: 'Oct 30 · 11:00',
      location: 'Engineering Hall B',
      audience: 'Open to Public',
      policy: 'Walk-in allowed',
      coins: 100,
    ),
    CampusEvent(
      id: 'open-mic',
      title: 'Acoustic Open Mic Night',
      category: 'Music',
      date: 'Nov 1 · 19:00',
      location: 'Student Union Lounge',
      coins: 40,
    ),
  ];
  static final followingEvents = <CampusEvent>[
    CampusEvent(
      id: 'club',
      title: 'Campus Club Fair',
      category: 'Club',
      date: 'Nov 10, 2026 · 10:00',
      location: 'Central Plaza',
      organizer: 'Student Union',
      policy: 'Walk-in allowed',
      coins: 80,
      image: FigmaAssets.path('2083:456', 'imgCampusClubFair'),
    ),
    CampusEvent(
      id: 'photo-meetup',
      title: 'Creative Photography Meetup',
      category: 'Arts',
      date: 'Nov 14, 2026 · 14:00',
      location: 'Arts Studio',
      organizer: 'Photography Club',
      coins: 50,
      image: FigmaAssets.path('2083:456', 'imgCreativePhotographyMeetup'),
    ),
  ];
  static final catalog = <CampusEvent>[
    music,
    photoWalk,
    ...upcoming,
    ...followingEvents,
    ...searchEvents,
  ];

  static DateTime startOf(CampusEvent event) {
    final date = RegExp(r'^(Oct|Nov) (\d+)').firstMatch(event.date)!;
    final time = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(event.date)!;
    return DateTime(
      2026,
      date[1] == 'Oct' ? 10 : 11,
      int.parse(date[2]!),
      int.parse(time[1]!),
      int.parse(time[2]!),
    );
  }

  static const topics = <InterestTopic>[
    InterestTopic('Technology', 'Hackathons, AI, coding', 'imgContainer1'),
    InterestTopic('Music & Gigs', 'Live shows, jam sessions', 'imgContainer3'),
    InterestTopic('Arts & Culture', 'Film, theatre, exhibits', 'imgContainer4'),
    InterestTopic(
      'Sports & Fitness',
      'Tournaments, intramural',
      'imgContainer5',
    ),
    InterestTopic('Photography', 'Walks, visual arts', 'imgContainer7'),
    InterestTopic('Career & Skills', 'Networking, portfolios', 'imgContainer8'),
    InterestTopic('Volunteering', 'Community, impact', 'imgContainer9'),
    InterestTopic('Startups & Pitch', 'Founders, demo days', 'imgContainer10'),
  ];
  static const organizers = <CampusOrganizer>[
    CampusOrganizer(
      'union',
      'Student Union',
      'Official Campus Student Life',
      '2.4k',
      badge: 'verified',
      upcomingCount: 1,
    ),
    CampusOrganizer(
      'photography',
      'Photography Club',
      'Arts & Creative Media',
      '840',
      badge: 'CLUB',
      upcomingCount: 1,
      icon: 1,
    ),
    CampusOrganizer(
      'gdsc',
      'GDSC Campus Chapter',
      'Tech & Hackathons • 3 upcoming events',
      '',
      icon: 2,
      upcomingCount: 3,
    ),
  ];
  static const recommendations = <CampusOrganizer>[
    CampusOrganizer('drama', 'Drama Club', 'Performing Arts', '', icon: 0),
    CampusOrganizer('gaming', 'Gaming Club', 'Gaming', '', icon: 1),
    CampusOrganizer(
      'environment',
      'Environmental Club',
      'Environment',
      '',
      icon: 2,
    ),
  ];
  static const filterGroups = <String, List<String>>{
    'Category': [
      'All',
      'Music',
      'Workshop',
      'Sports',
      'Arts',
      'Seminar',
      'Volunteer',
      'Competition',
      'Career',
      'Social',
      'Other',
    ],
    'Date': [
      'Any date',
      'This week',
      'This month',
      'Next month',
      'Custom range',
    ],
    'Time': ['Any time', 'Morning', 'Afternoon', 'Evening'],
    'Duration': ['Any duration', 'Under 1 hour', '1–3 hours', 'Over 3 hours'],
    'Audience': [
      'Any audience',
      'Open to Everyone',
      'Students from Any University',
      'Host University Only',
      'Faculty Restricted',
      'Club Members Only',
    ],
    'Registration Policy': ['Any', 'Registration Required', 'Walk-in Allowed'],
    'Availability': [
      'Any',
      'Spots Available',
      'Full',
      'Waitlist Available',
      'Unlimited Registration',
    ],
  };
}
