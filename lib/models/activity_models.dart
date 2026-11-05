class RegisteredEvent {
  const RegisteredEvent({
    required this.id,
    required this.title,
    required this.category,
    required this.dateLabel,
    required this.venue,
    required this.start,
    this.attended = false,
    this.waitlisted = false,
    this.walkIn = false,
    this.image,
    this.coins = 0,
    String? detailKey,
  }) : detailKey = detailKey ?? id;
  final String id, title, category, dateLabel, venue;
  final String detailKey;
  final DateTime start;
  final bool attended, waitlisted, walkIn;
  final String? image;
  final int coins;
}

class CampusReward {
  const CampusReward({
    required this.id,
    required this.title,
    required this.category,
    required this.redeemCost,
    required this.image,
    required this.description,
    required this.location,
    required this.instructions,
    required this.terms,
    this.validDays,
  });
  final String id, title, category, image;
  final int redeemCost;
  int get catalogCost => redeemCost;
  final String description, location, instructions, terms;
  final int? validDays;
}

enum CoinKind { earned, spent, deposit }

class CoinEntry {
  const CoinEntry(
    this.title,
    this.subtitle,
    this.amount,
    this.kind,
    this.icon, {
    this.date,
  });
  final String title, subtitle;
  final int amount, icon;
  final CoinKind kind;
  final DateTime? date;
}

class RedemptionReceipt {
  const RedemptionReceipt(
    this.reward,
    this.cost,
    this.balance,
    this.code, {
    required this.redeemedOn,
    this.expiresOn,
  });
  final CampusReward reward;
  final int cost, balance;
  final String code;
  final DateTime redeemedOn;
  final DateTime? expiresOn;
}

class CoinHistoryGroup {
  const CoinHistoryGroup(this.label, this.entries);
  final String label;
  final List<CoinEntry> entries;
}

class MilestoneProgress {
  const MilestoneProgress(
    this.milestone, {
    required this.reached,
    required this.next,
    required this.remaining,
  });
  final EventMilestone milestone;
  final bool reached, next;
  final int remaining;
  String get description => reached
      ? 'Attended ${milestone.events} verified campus ${milestone.events == 1 ? 'event' : 'events'}.'
      : 'Attend $remaining more ${remaining == 1 ? 'event' : 'events'} to unlock this milestone.';
}

class EventMilestone {
  const EventMilestone(this.title, this.events, this.coins, this.description);
  final String title, description;
  final int events, coins;
}
