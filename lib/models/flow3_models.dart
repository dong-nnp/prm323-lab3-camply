import 'activity_models.dart';
import 'flow1_models.dart';

typedef DailyPresentation = ({
  int day,
  int coins,
  bool checkedInToday,
  bool saving,
  String message,
  List<({int day, int coins, bool today, bool claimed})> days,
});

class Flow3Snapshot {
  const Flow3Snapshot({
    required this.daily,
    required this.rewards,
    required this.receipts,
    required this.history,
    required this.milestones,
    required this.verifiedCount,
    required this.availableCoins,
    required this.heldCoins,
    this.busy,
    this.error,
    this.lastRedemptionId,
  });
  final Map<String, dynamic> daily;
  final List<CampusReward> rewards;
  final List<RedemptionReceipt> receipts;
  final List<CoinEntry> history;
  final List<MilestoneProgress> milestones;
  final int verifiedCount;
  final int availableCoins, heldCoins;
  final String? busy, error, lastRedemptionId;
  Flow3Snapshot action({
    String? busy,
    String? error,
    String? lastRedemptionId,
  }) => Flow3Snapshot(
    daily: daily,
    rewards: rewards,
    receipts: receipts,
    history: history,
    milestones: milestones,
    verifiedCount: verifiedCount,
    availableCoins: availableCoins,
    heldCoins: heldCoins,
    busy: busy,
    error: error,
    lastRedemptionId: lastRedemptionId ?? this.lastRedemptionId,
  );
  DailyPresentation get dailyPresentation {
    final day = (daily['streakDay'] as num).toInt();
    final claimed = daily['alreadyClaimed'] == true;
    final first = day > 7 ? day - 6 : 1;
    const amounts = [5, 10, 15, 30, 50, 70, 100];
    return (
      day: day,
      coins: (daily['coins'] as num).toInt(),
      checkedInToday: claimed,
      saving: busy == 'daily',
      message: day >= 7
          ? 'Max reward unlocked · +100 coins daily'
          : 'Keep your streak to earn up to 100 coins daily',
      days: [
        for (var i = first; i < first + 7; i++)
          (
            day: i,
            coins: amounts[(i - 1).clamp(0, 6)],
            today: i == day,
            claimed: i < day || i == day && claimed,
          ),
      ],
    );
  }
}

CampusReward serverReward(Map<String, dynamic> r, String fallback) =>
    CampusReward(
      id: r['id'] as String,
      title: r['title'] as String,
      category: switch (r['category']) {
        'food_drinks' => 'Food & Drinks',
        'merchandise' => 'Merchandise',
        'experiences' => 'Experiences',
        final String value => value,
        _ => 'Other',
      },
      redeemCost: (r['priceCoins'] as num).toInt(),
      image: r['imageUrl'] as String? ?? fallback,
      description: r['description'] as String? ?? '',
      location: (r['usageLocations'] as List? ?? []).join('\n'),
      instructions:
          r['redemptionInstructions'] as String? ??
          (r['redemptionSteps'] as List? ?? []).join('\n'),
      terms: r['termsText'] as String? ?? '',
      validDays: (r['validDays'] as num?)?.toInt(),
      stock: (r['stockRemaining'] as num?)?.toInt() ?? 0,
      termsVersion: r['termsVersion'] as String? ?? '',
      fulfillmentType: r['fulfillmentType'] as String? ?? 'voucher',
      active: r['status'] == 'active',
    );

RedemptionReceipt serverReceipt(
  Map<String, dynamic> row,
  Map<String, dynamic>? voucher,
  String fallback,
  int balance,
) {
  final snapshot = jsonMap(row['rewardSnapshot']);
  final reward = serverReward({
    ...snapshot,
    'id': row['rewardId'],
    'title': row['rewardTitleSnapshot'],
    'priceCoins': row['priceCoinsSnapshot'],
    'status': 'active',
  }, fallback);
  return RedemptionReceipt(
    reward,
    (row['priceCoinsSnapshot'] as num).toInt(),
    balance,
    row['id'] as String,
    id: row['id'] as String,
    voucherId: row['voucherId'] as String?,
    status: voucher?['status'] as String? ?? row['status'] as String,
    redeemedOn: DateTime.parse(row['redeemedAt'] as String),
    expiresOn: row['expiresAt'] == null
        ? null
        : DateTime.parse(row['expiresAt'] as String),
  );
}

CoinEntry serverLedger(Map<String, dynamic> row) {
  final delta = (row['deltaAvailable'] as num).toInt(),
      held = (row['deltaHeld'] as num).toInt();
  final type = row['type'] as String;
  final kind = type == 'deposit_hold' || type == 'no_show_forfeit'
      ? CoinKind.deposit
      : type.contains('refund')
      ? CoinKind.refund
      : delta < 0
      ? CoinKind.spent
      : CoinKind.earned;
  final title = switch (type) {
    'signup_bonus' => 'Welcome bonus',
    'daily_checkin' => 'Daily Check-in',
    'monthly_gift' => 'Monthly Gift',
    'event_reward' => 'Event attendance',
    'milestone_reward' => 'Event milestone',
    'deposit_hold' => 'Event deposit',
    'deposit_refund' => 'Deposit returned',
    'deposit_partial_refund' => 'Cancellation refund · 30%',
    'no_show_forfeit' => 'No-show · deposit forfeited',
    'redeem_reward' => 'Reward redemption',
    _ => type,
  };
  return CoinEntry(
    title,
    type == 'no_show_forfeit'
        ? '${-held} held coins forfeited'
        : row['sourceId'] as String? ?? '',
    delta,
    kind,
    0,
    date: vietnamTime(DateTime.parse(row['createdAt'] as String)),
    amountLabel: type == 'deposit_hold'
        ? '$held held'
        : type == 'no_show_forfeit'
        ? '${-held} forfeited'
        : null,
  );
}
