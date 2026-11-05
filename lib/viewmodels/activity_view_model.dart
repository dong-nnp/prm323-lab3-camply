import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mock/activity_mock_data.dart';
import '../models/activity_models.dart';
import 'authentication_view_model.dart';

class ActivityState {
  ActivityState({
    this.past = false,
    this.selectedDate,
    DateTime? week,
    DateTime? calendarMonth,
    this.draftDate,
    this.cancelled = const {},
    this.available = ActivityMockData.balance,
    this.deposits = ActivityMockData.deposits,
    this.redeemed = const {},
    this.verified = ActivityMockData.initialVerified,
    this.rewardCategory = 'All',
    this.rewardQuery = '',
    this.historyFilter = 'All',
    this.usedRewards = false,
    this.flashlight = false,
    this.message,
    RedemptionReceipt? receipt,
    List<CoinEntry>? transactions,
    List<RedemptionReceipt>? receipts,
    this.registrations = const [],
  }) : week = week ?? DateTime(2026, 10, 26),
       calendarMonth = calendarMonth ?? DateTime(2026, 11),
       transactions = transactions ?? ActivityMockData.history,
       receipt = receipt ?? ActivityMockData.referenceReceipt,
       receipts = receipts ?? [ActivityMockData.referenceReceipt];
  final bool past, usedRewards, flashlight;
  final DateTime? selectedDate, draftDate;
  final DateTime week, calendarMonth;
  final Set<String> cancelled, redeemed, verified;
  final int available, deposits;
  final String rewardCategory, rewardQuery, historyFilter;
  final String? message;
  final RedemptionReceipt? receipt;
  final List<RedemptionReceipt> receipts;
  final List<CoinEntry> transactions;
  final List<RegisteredEvent> registrations;
  ActivityState copy({
    bool? past,
    DateTime? selectedDate,
    bool clearDate = false,
    DateTime? week,
    DateTime? calendarMonth,
    DateTime? draftDate,
    Set<String>? cancelled,
    int? available,
    int? deposits,
    Set<String>? redeemed,
    Set<String>? verified,
    String? rewardCategory,
    String? rewardQuery,
    String? historyFilter,
    bool? usedRewards,
    bool? flashlight,
    String? message,
    RedemptionReceipt? receipt,
    List<RedemptionReceipt>? receipts,
    List<CoinEntry>? transactions,
    List<RegisteredEvent>? registrations,
  }) => ActivityState(
    past: past ?? this.past,
    selectedDate: clearDate ? null : selectedDate ?? this.selectedDate,
    week: week ?? this.week,
    calendarMonth: calendarMonth ?? this.calendarMonth,
    draftDate: draftDate ?? this.draftDate,
    cancelled: cancelled ?? this.cancelled,
    available: available ?? this.available,
    deposits: deposits ?? this.deposits,
    redeemed: redeemed ?? this.redeemed,
    verified: verified ?? this.verified,
    rewardCategory: rewardCategory ?? this.rewardCategory,
    rewardQuery: rewardQuery ?? this.rewardQuery,
    historyFilter: historyFilter ?? this.historyFilter,
    usedRewards: usedRewards ?? this.usedRewards,
    flashlight: flashlight ?? this.flashlight,
    message: message,
    receipt: receipt ?? this.receipt,
    receipts: receipts ?? this.receipts,
    transactions: transactions ?? this.transactions,
    registrations: registrations ?? this.registrations,
  );
}

final activityViewModelProvider =
    NotifierProvider<ActivityViewModel, ActivityState>(ActivityViewModel.new);

class ActivityViewModel extends Notifier<ActivityState> {
  @override
  ActivityState build() => ActivityState();
  List<RegisteredEvent> get allEvents => [
    ...ActivityMockData.events,
    ...state.registrations,
  ];
  bool addRegistration(RegisteredEvent event, {int deposit = 0}) {
    if (!ref.read(hasAuthenticatedSessionProvider)) {
      state = state.copy(message: 'Log in to register for events.');
      return false;
    }
    if (allEvents.any((existing) => existing.id == event.id)) {
      state = state.copy(cancelled: {...state.cancelled}..remove(event.id));
      return true;
    }
    if (deposit > 0) {
      state = state.copy(message: coinServiceMessage);
      return false;
    }
    state = state.copy(registrations: [...state.registrations, event]);
    return true;
  }

  bool sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
  void setReference(String view) {
    switch (view) {
      case 'past-empty':
        state = state.copy(
          past: true,
          selectedDate: DateTime(2026, 10, 27),
          week: DateTime(2026, 10, 26),
        );
      case 'past-date':
        state = state.copy(
          past: true,
          selectedDate: DateTime(2026, 10, 26),
          week: DateTime(2026, 10, 26),
        );
      case 'past-all':
        state = state.copy(
          past: true,
          clearDate: true,
          week: DateTime(2026, 10, 26),
        );
      case 'selected':
        state = state.copy(
          past: false,
          selectedDate: DateTime(2026, 11, 2),
          week: DateTime(2026, 11, 2),
        );
      case 'calendar':
        if (state.selectedDate == null) selectDate(DateTime(2026, 11, 2));
        beginCalendar();
      case 'upcoming':
        state = state.copy(
          past: false,
          clearDate: true,
          week: DateTime(2026, 10, 26),
        );
    }
  }

  List<RegisteredEvent> get visibleEvents => allEvents
      .where(
        (event) =>
            !state.cancelled.contains(event.id) &&
            event.attended == state.past &&
            (state.selectedDate == null ||
                sameDay(event.start, state.selectedDate!)),
      )
      .toList();
  int countFor(bool past) => allEvents
      .where(
        (event) =>
            event.attended == past && !state.cancelled.contains(event.id),
      )
      .length;
  bool hasEvent(DateTime day) => allEvents.any(
    (event) => sameDay(event.start, day) && !state.cancelled.contains(event.id),
  );
  RegisteredEvent event(String id) => allEvents.firstWhere(
    (e) => e.id == id,
    orElse: () => ActivityMockData.events.first,
  );
  CampusReward reward(String id) => ActivityMockData.rewards.firstWhere(
    (r) => r.id == id,
    orElse: () => ActivityMockData.rewards.first,
  );
  void selectTab(bool past) => state = state.copy(past: past, clearDate: true);
  void showAll() => state = state.copy(clearDate: true);
  void selectDate(DateTime value) => state = state.copy(
    selectedDate: value,
    week: value.subtract(Duration(days: value.weekday - 1)),
  );
  void shiftWeek(int direction) => state = state.copy(
    week: state.week.add(Duration(days: 7 * direction)),
    clearDate: true,
  );
  void cancelRegistration(String id) => state = state.copy(
    cancelled: {...state.cancelled, id},
    message: 'Registration cancelled.',
  );
  void beginCalendar() => state = state.copy(
    draftDate: state.selectedDate ?? DateTime(2026, 11, 2),
    calendarMonth: DateTime(2026, 11),
  );
  void shiftMonth(int direction) => state = state.copy(
    calendarMonth: DateTime(
      state.calendarMonth.year,
      state.calendarMonth.month + direction,
    ),
  );
  void draftDate(DateTime value) => state = state.copy(draftDate: value);
  void applyDate() {
    if (state.draftDate != null) selectDate(state.draftDate!);
  }

  void toggleFlashlight() => state = state.copy(flashlight: !state.flashlight);
  static const coinServiceMessage =
      'Coin service is not connected yet. Preview data only.';
  bool get coinServiceAvailable => false;
  bool checkIn(String code) {
    state = state.copy(message: coinServiceMessage);
    return false;
  }

  void selectRewardCategory(String value) =>
      state = state.copy(rewardCategory: value);
  void searchRewards(String value) => state = state.copy(rewardQuery: value);
  void historyFilter(String value) => state = state.copy(historyFilter: value);
  void selectLockerTab(bool used) => state = state.copy(usedRewards: used);
  List<CampusReward> get visibleRewards => ActivityMockData.rewards
      .where(
        (reward) =>
            (state.rewardCategory == 'All' ||
                reward.category == state.rewardCategory) &&
            reward.title.toLowerCase().contains(
              state.rewardQuery.toLowerCase().trim(),
            ),
      )
      .toList();
  List<CoinEntry> get history => state.transactions
      .where(
        (entry) => switch (state.historyFilter) {
          'Earned' => entry.kind == CoinKind.earned,
          'Spent' => entry.kind == CoinKind.spent,
          'Deposits' => entry.kind == CoinKind.deposit,
          _ => true,
        },
      )
      .toList();
  bool canRedeem(String id) => false;
  String rewardStatus(String id) => 'Preview';

  RedemptionReceipt? voucher(String? code) {
    if (state.receipts.isEmpty) return null;
    if (code == null) return state.receipts.first;
    for (final item in state.receipts) {
      if (item.code == code) return item;
    }
    return null;
  }

  String dateLabel(DateTime date) =>
      '${_months[date.month - 1]} ${date.day}, ${date.year}';
  static const _months = [
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
  String validityLabel(CampusReward reward) => reward.validDays == null
      ? 'Validity not configured'
      : 'Valid for ${reward.validDays} days after redemption';
  String expiryLabel(RedemptionReceipt receipt) => receipt.expiresOn == null
      ? 'Validity not configured'
      : 'Valid until ${dateLabel(receipt.expiresOn!)}';
  List<MilestoneProgress> get milestones {
    final count = state.verified.length;
    final next = ActivityMockData.milestones
        .where((m) => m.events > count)
        .firstOrNull;
    return [
      for (final m in ActivityMockData.milestones)
        MilestoneProgress(
          m,
          reached: count >= m.events,
          next: m == next,
          remaining: (m.events - count).clamp(0, m.events),
        ),
    ];
  }

  int get unlockedMilestones => milestones.where((m) => m.reached).length;
  MilestoneProgress? get nextMilestone =>
      milestones.where((m) => m.next).firstOrNull;
  String get currentAchievement =>
      milestones.where((m) => m.reached).lastOrNull?.milestone.title ??
      'Getting started';
  int get milestoneTarget =>
      nextMilestone?.milestone.events ??
      ActivityMockData.milestones.last.events;
  double get milestoneFraction =>
      (state.verified.length / milestoneTarget).clamp(0, 1);
  int get milestonePercent => (milestoneFraction * 100).round();
  List<CoinHistoryGroup> get historyGroups {
    final entries = [...history]
      ..sort(
        (a, b) => (b.date ?? ActivityMockData.referenceDate).compareTo(
          a.date ?? ActivityMockData.referenceDate,
        ),
      );
    final groups = <String, List<CoinEntry>>{};
    for (final entry in entries) {
      final date = entry.date;
      final label = date == null
          ? 'Date unavailable'
          : '${_months[date.month - 1]} ${date.year}';
      groups.putIfAbsent(label, () => []).add(entry);
    }
    return [
      for (final group in groups.entries)
        CoinHistoryGroup(group.key, List.unmodifiable(group.value)),
    ];
  }

  bool redeem(String id) {
    state = state.copy(message: coinServiceMessage);
    return false;
  }
}
