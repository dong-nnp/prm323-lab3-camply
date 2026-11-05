/// Presentation content from the approved Figma screens; no SDK types.
class CampusEvent {
  const CampusEvent({
    required this.id,
    required this.title,
    required this.category,
    required this.date,
    required this.location,
    this.audience = 'University Students',
    this.policy = 'Registration required',
    this.coins = 0,
    this.image,
    this.organizer,
    this.organizerId,
    this.note,
    this.keywords = '',
    String? detailKey,
  }) : detailKey = detailKey ?? id;
  final String id, title, category, date, location, audience, policy;
  final int coins;
  final String? image, organizer, organizerId, note;
  final String keywords;
  final String detailKey;
}

class CampusOrganizer {
  const CampusOrganizer(
    this.id,
    this.name,
    this.description,
    this.followers, {
    this.badge,
    this.icon = 0,
    this.upcomingCount = 0,
  });
  final String id, name, description, followers;
  final String? badge;
  final int icon;
  final int upcomingCount;
}

class InterestTopic {
  const InterestTopic(this.name, this.description, this.asset);
  final String name, description, asset;
}

class EventFilters {
  const EventFilters({
    this.category = 'All',
    this.date = 'Any date',
    this.time = 'Any time',
    this.duration = 'Any duration',
    this.audience = 'Any audience',
    this.policy = 'Any',
    this.availability = 'Any',
    this.eligibleOnly = false,
    this.rangeStart,
    this.rangeEnd,
  });
  final String category, date, time, duration, audience, policy, availability;
  final bool eligibleOnly;
  final DateTime? rangeStart, rangeEnd;
  bool get isActive =>
      category != 'All' ||
      date != 'Any date' ||
      time != 'Any time' ||
      duration != 'Any duration' ||
      audience != 'Any audience' ||
      policy != 'Any' ||
      availability != 'Any' ||
      eligibleOnly;
  EventFilters withValue(String key, String value) => EventFilters(
    category: key == 'Category' ? value : category,
    date: key == 'Date' ? value : date,
    time: key == 'Time' ? value : time,
    duration: key == 'Duration' ? value : duration,
    audience: key == 'Audience' ? value : audience,
    policy: key == 'Registration Policy' ? value : policy,
    availability: key == 'Availability' ? value : availability,
    eligibleOnly: eligibleOnly,
    rangeStart: key == 'Date' ? null : rangeStart,
    rangeEnd: key == 'Date' ? null : rangeEnd,
  );
  EventFilters withEligibility(bool value) => EventFilters(
    category: category,
    date: date,
    time: time,
    duration: duration,
    audience: audience,
    policy: policy,
    availability: availability,
    eligibleOnly: value,
    rangeStart: rangeStart,
    rangeEnd: rangeEnd,
  );
  EventFilters withRange(DateTime start, DateTime end) => EventFilters(
    category: category,
    date: 'Custom range',
    time: time,
    duration: duration,
    audience: audience,
    policy: policy,
    availability: availability,
    eligibleOnly: eligibleOnly,
    rangeStart: start,
    rangeEnd: end,
  );
}
