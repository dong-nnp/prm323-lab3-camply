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
  });
  final String id, title, category, dateLabel, venue;
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
    required this.catalogCost,
    required this.redeemCost,
    required this.image,
  });
  final String id, title, category, image;
  final int catalogCost, redeemCost;
}

enum CoinKind { earned, spent, deposit }

class CoinEntry {
  const CoinEntry(this.title, this.subtitle, this.amount, this.kind, this.icon);
  final String title, subtitle;
  final int amount, icon;
  final CoinKind kind;
}

class RedemptionReceipt {
  const RedemptionReceipt(this.reward, this.cost, this.balance, this.code);
  final CampusReward reward;
  final int cost, balance;
  final String code;
}

class EventMilestone {
  const EventMilestone(this.title, this.events, this.coins, this.description);
  final String title, description;
  final int events, coins;
}
