enum RegistrationStatus { idle, loading, success, failed, full, going }

enum RegistrationOutcome { success, failed, full }

class EventPresentation {
  const EventPresentation({
    required this.id,
    required this.title,
    required this.category,
    required this.date,
    required this.time,
    required this.venue,
    required this.organizer,
    required this.start,
    required this.coins,
    this.deposit = 0,
    this.walkIn = false,
    this.past = false,
    this.image,
    this.spots = 120,
  });
  final String id, title, category, date, time, venue, organizer;
  final DateTime start;
  final int coins, deposit;
  final int? spots;
  final bool walkIn, past;
  final String? image;
}

class SavedEventPresentation {
  const SavedEventPresentation(
    this.event,
    this.dateLabel,
    this.organizer,
    this.image,
  );
  final EventPresentation event;
  final String dateLabel, organizer, image;
}

class EventAgendaItem {
  const EventAgendaItem(this.time, this.title, this.description);
  final String time, title, description;
}

class ProfileNotice {
  const ProfileNotice(
    this.id,
    this.title,
    this.message,
    this.when,
    this.icon, {
    this.unread = false,
    this.today = false,
    this.destination,
  });
  final String id, title, message, when;
  final int icon;
  final bool unread, today;
  final String? destination;
}
