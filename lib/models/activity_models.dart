class RegisteredEvent {
  const RegisteredEvent({
    required this.id,
    required this.title,
    required this.category,
    required this.dateLabel,
    required this.venue,
    required this.start,
    this.attended = false,
    this.past = false,
    this.walkIn = false,
    this.image,
    this.coins = 0,
    this.status = 'Registered',
    this.verifiedAt,
    this.canCancel = true,
    String? detailKey,
  }) : detailKey = detailKey ?? id;
  final String id, title, category, dateLabel, venue;
  final String detailKey;
  final DateTime start;
  final bool attended, walkIn, past;
  final String? image;
  final int coins;
  final String status;
  final DateTime? verifiedAt;
  final bool canCancel;
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
    this.stock = 0,
    this.termsVersion = '',
    this.fulfillmentType = 'voucher',
    this.active = true,
  });
  final String id, title, category, image;
  final int redeemCost;
  int get catalogCost => redeemCost;
  final String description, location, instructions, terms;
  final int? validDays;
  final int stock;
  final String termsVersion, fulfillmentType;
  final bool active;
}

enum CoinKind { earned, spent, deposit, refund }

class CoinEntry {
  const CoinEntry(
    this.title,
    this.subtitle,
    this.amount,
    this.kind,
    this.icon, {
    this.date,
    this.amountLabel,
  });
  final String title, subtitle;
  final int amount, icon;
  final CoinKind kind;
  final DateTime? date;
  final String? amountLabel;
}

class RedemptionReceipt {
  const RedemptionReceipt(
    this.reward,
    this.cost,
    this.balance,
    this.code, {
    required this.redeemedOn,
    this.expiresOn,
    this.id = '',
    this.voucherId,
    this.status = 'unused',
  });
  final CampusReward reward;
  final int cost, balance;
  final String code;
  final DateTime redeemedOn;
  final DateTime? expiresOn;
  final String id, status;
  final String? voucherId;
  bool expired(DateTime now) => expiresOn != null && !expiresOn!.isAfter(now);
  bool available(DateTime now) =>
      status != 'used' && status != 'revoked' && !expired(now);
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
    this.claimed = false,
    this.claiming = false,
  });
  final EventMilestone milestone;
  final bool reached, next;
  final bool claimed, claiming;
  bool get canClaim => reached && !claimed && !claiming;
  final int remaining;
  String get description => reached
      ? 'Attended ${milestone.events} verified campus ${milestone.events == 1 ? 'event' : 'events'}.'
      : 'Attend $remaining more ${remaining == 1 ? 'event' : 'events'} to unlock this milestone.';
}

class EventMilestone {
  const EventMilestone(
    this.title,
    this.events,
    this.coins,
    this.description, {
    required this.id,
    this.version = 1,
  });
  final String id, title, description;
  final int events, coins, version;
}

class MilestoneClaimResult {
  const MilestoneClaimResult({
    required this.milestoneId,
    required this.availableCoins,
    required this.heldCoins,
  });
  final String milestoneId;
  final int availableCoins, heldCoins;
}
