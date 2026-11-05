import '../../core/constants/activity_assets.dart';
import '../../models/activity_models.dart';

/// Authorized Figma presentation fixtures, isolated from production services.
abstract final class ActivityMockData {
  static const balance = 420;
  static const deposits = 100;
  static const dailyCheckInRules =
      'Days 1–2: +5 coins per day\nDays 3–4: +10 coins per day\nDays 5–6: +15 coins per day\nDay 7 onwards: +20 coins per day\n\nThe backend will confirm your streak and reward. Missing a day resets the streak; coins already earned are kept.';
  static const dailyCheckInPreview = (
    day: 8,
    coins: 20,
    checkedInToday: false,
    saving: false,
    message: 'Max daily reward unlocked! Earn +20 coins each day you keep your streak.',
    days: [
      (day: 2, coins: 5, today: false, claimed: true),
      (day: 3, coins: 10, today: false, claimed: true),
      (day: 4, coins: 10, today: false, claimed: true),
      (day: 5, coins: 15, today: false, claimed: true),
      (day: 6, coins: 15, today: false, claimed: true),
      (day: 7, coins: 20, today: false, claimed: true),
      (day: 8, coins: 20, today: true, claimed: false),
    ],
  );
  static const voucherCode = 'VOUCHER-CC-82914';
  static const validUntil = 'Nov 27, 2026';
  static const redeemedOn = 'Oct 28, 2026';
  static const attendee = 'Nguyen Van A';
  static const studentId = 'SE123456';
  static const ticketNumber = 'CMN-2026-0841';
  static const demoCheckInCode = 'EVIA-CLUB-2026';
  static final archivedRewards = [
    (reward: rewards[0], status: 'Used'),
    (reward: rewards[2], status: 'Expired'),
  ];
  static const initialVerified = {'music', 'orientation', 'hackathon'};
  static final referenceDate = DateTime(2026, 10, 28);
  static final events = <RegisteredEvent>[
    RegisteredEvent(
      id: 'music',
      title: 'Campus Music Night',
      category: 'Music',
      dateLabel: 'Mon, Oct 26, 2026 · 18:00 – 22:00',
      venue: 'Main Stadium',
      start: DateTime(2026, 10, 26, 18),
      attended: true,
      coins: 50,
    ),
    RegisteredEvent(
      id: 'ai',
      title: 'AI & Future Careers Workshop',
      category: 'Technology',
      dateLabel: 'Mon, Nov 2, 2026 · 14:00 – 16:30',
      venue: 'Innovation Hub, Room 302',
      start: DateTime(2026, 11, 2, 14),
    ),
    RegisteredEvent(
      id: 'mobile',
      title: 'Mobile App Development Workshop',
      category: 'Technology',
      dateLabel: 'Fri, Nov 6, 2026 · 13:30 – 15:30',
      venue: 'Computer Lab B',
      start: DateTime(2026, 11, 6, 13, 30),
      waitlisted: true,
      image: ActivityAssets.image('2083:273', 0),
    ),
  ];
  static final rewards = <CampusReward>[
    CampusReward(
      id: 'cafe',
      title: 'Campus Café \$10 Voucher',
      category: 'Food & Drinks',
      redeemCost: 250,
      image: ActivityAssets.image('2083:3327', 2),
      description: 'Enjoy a drink or pastry at participating campus cafés.',
      location: 'Participating campus cafés',
      instructions: 'Present your voucher code at a participating café.',
      terms: 'One-time use at participating campus cafés. Present your voucher code to the cashier.',
      validDays: 30,
    ),
    CampusReward(
      id: 'tote',
      title: 'Evia Eco Tote Bag',
      category: 'Merchandise',
      redeemCost: 400,
      image: ActivityAssets.image('2083:3327', 3),
      description: 'Redeem your coins for an Evia Eco Tote Bag.',
      location: 'Pickup location not configured',
      instructions:
          'Keep your reward code. Collection details have not been configured.',
      terms: 'Collection terms have not been configured for this demo reward.',
    ),
    CampusReward(
      id: 'cinema',
      title: 'Cinema Movie Pass',
      category: 'Experiences',
      redeemCost: 500,
      image: ActivityAssets.image('2083:3327', 4),
      description: 'Redeem your coins for a Cinema Movie Pass.',
      location: 'Participating venue not configured',
      instructions: 'Keep your reward code. Venue and usage details have not been configured.',
      terms: 'Usage terms have not been configured for this demo reward.',
    ),
    CampusReward(
      id: 'hoodie',
      title: 'Evia Campus Hoodie',
      category: 'Merchandise',
      redeemCost: 800,
      image: ActivityAssets.image('2083:3327', 5),
      description: 'Redeem your coins for an Evia Campus Hoodie.',
      location: 'Pickup location not configured',
      instructions:
          'Keep your reward code. Collection details have not been configured.',
      terms: 'Collection terms have not been configured for this demo reward.',
    ),
  ];
  static final referenceReceipt = RedemptionReceipt(
    rewards.first,
    250,
    170,
    voucherCode,
    redeemedOn: referenceDate,
    expiresOn: referenceDate.add(const Duration(days: 30)),
  );
  static final history = <CoinEntry>[
    CoinEntry(
      'Campus Music Night',
      'Event check-in · Oct 26',
      50,
      CoinKind.earned,
      2,
      date: DateTime(2026, 10, 26),
    ),
    CoinEntry(
      'Daily Check-in',
      'Daily reward · Oct 26',
      10,
      CoinKind.earned,
      3,
      date: DateTime(2026, 10, 26),
    ),
    CoinEntry(
      'AI & Careers Workshop',
      'Deposit held · Oct 21',
      100,
      CoinKind.deposit,
      4,
      date: DateTime(2026, 10, 21),
    ),
    CoinEntry(
      'Explorer Milestone',
      'Milestone reward · Oct 20',
      100,
      CoinKind.earned,
      5,
      date: DateTime(2026, 10, 20),
    ),
    CoinEntry(
      'Campus Café Cold Brew',
      'Reward redemption · Oct 19',
      -200,
      CoinKind.spent,
      6,
      date: DateTime(2026, 10, 19),
    ),
  ];
  static const milestones = <EventMilestone>[
    EventMilestone('First Event', 1, 50, 'Attended your first campus event.'),
    EventMilestone('Explorer', 3, 100, 'Attended 3 verified campus events.'),
    EventMilestone(
      'Active Student',
      5,
      150,
      'Attend 2 more events to unlock this milestone.',
    ),
    EventMilestone(
      'Campus Leader',
      10,
      300,
      'Attend 10 verified campus events.',
    ),
    EventMilestone(
      'Evia Champion',
      20,
      500,
      'Become a dedicated campus event participant.',
    ),
  ];
}
