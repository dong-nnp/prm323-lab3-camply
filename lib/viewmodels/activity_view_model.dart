import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mock/activity_mock_data.dart';
import '../models/activity_models.dart';

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
    this.checkedInToday = false,
    this.redeemed = const {},
    this.verified = ActivityMockData.initialVerified,
    this.rewardCategory = 'All',
    this.rewardQuery = '',
    this.historyFilter = 'All',
    this.usedRewards = false,
    this.flashlight = false,
    this.message,
    this.receipt,
    this.transactions = ActivityMockData.history,
    this.registrations = const [],
  }) : week = week ?? DateTime(2026, 10, 26),
       calendarMonth = calendarMonth ?? DateTime(2026, 11);
  final bool past, checkedInToday, usedRewards, flashlight;
  final DateTime? selectedDate, draftDate;
  final DateTime week, calendarMonth;
  final Set<String> cancelled, redeemed, verified;
  final int available, deposits;
  final String rewardCategory, rewardQuery, historyFilter;
  final String? message;
  final RedemptionReceipt? receipt;
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
    bool? checkedInToday,
    Set<String>? redeemed,
    Set<String>? verified,
    String? rewardCategory,
    String? rewardQuery,
    String? historyFilter,
    bool? usedRewards,
    bool? flashlight,
    String? message,
    RedemptionReceipt? receipt,
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
    checkedInToday: checkedInToday ?? this.checkedInToday,
    redeemed: redeemed ?? this.redeemed,
    verified: verified ?? this.verified,
    rewardCategory: rewardCategory ?? this.rewardCategory,
    rewardQuery: rewardQuery ?? this.rewardQuery,
    historyFilter: historyFilter ?? this.historyFilter,
    usedRewards: usedRewards ?? this.usedRewards,
    flashlight: flashlight ?? this.flashlight,
    message: message,
    receipt: receipt ?? this.receipt,
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
    if (allEvents.any((existing) => existing.id == event.id)) {
      state = state.copy(cancelled: {...state.cancelled}..remove(event.id));
      return true;
    }
    if (state.available < deposit) return false;
    state = state.copy(
      registrations: [...state.registrations, event],
      available: state.available - deposit,
      deposits: state.deposits + deposit,
    );
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
  bool checkIn(String code) {
    if (code.trim().toUpperCase() != ActivityMockData.demoCheckInCode) {
      state = state.copy(
        message: 'Code not recognized. Check the code and try again.',
      );
      return false;
    }
    if (state.verified.contains('club')) {
      state = state.copy(message: 'Your attendance is already confirmed.');
      return true;
    }
    state = state.copy(
      verified: {...state.verified, 'club'},
      available: state.available + 80,
      message: 'Attendance confirmed. +80 coins',
      transactions: [
        const CoinEntry(
          'Campus Club Fair',
          'Event check-in · Nov 10',
          80,
          CoinKind.earned,
          2,
        ),
        ...state.transactions,
      ],
    );
    return true;
  }

  void dailyCheckIn() {
    if (state.checkedInToday) return;
    state = state.copy(
      checkedInToday: true,
      available: state.available + 10,
      transactions: [
        const CoinEntry(
          'Daily Check-in',
          'Daily reward · Today',
          10,
          CoinKind.earned,
          3,
        ),
        ...state.transactions,
      ],
    );
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
  bool canRedeem(String id) =>
      state.available >= reward(id).redeemCost && !state.redeemed.contains(id);
  bool redeem(String id) {
    if (!canRedeem(id)) {
      state = state.copy(
        message: state.redeemed.contains(id)
            ? 'This reward has already been redeemed.'
            : 'You need more available coins.',
      );
      return false;
    }
    final selected = reward(id);
    final balance = state.available - selected.redeemCost;
    state = state.copy(
      available: balance,
      redeemed: {...state.redeemed, id},
      receipt: RedemptionReceipt(
        selected,
        selected.redeemCost,
        balance,
        ActivityMockData.voucherCode,
      ),
      transactions: [
        CoinEntry(
          selected.title,
          'Reward redemption · Today',
          -selected.redeemCost,
          CoinKind.spent,
          6,
        ),
        ...state.transactions,
      ],
    );
    return true;
  }
}
