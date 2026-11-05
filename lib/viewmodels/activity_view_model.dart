import 'dart:math';

import 'package:flutter/foundation.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mock/activity_mock_data.dart';
import '../data/mock/registration_mock_data.dart';
import '../core/providers/service_providers.dart';
import '../core/providers/repository_providers.dart';
import '../core/utils/exception_mapper.dart';
import '../models/activity_models.dart';
import 'authentication_view_model.dart';
import '../models/flow1_models.dart';
import '../core/errors/app_exception.dart';
import 'flow1_view_model.dart';
import 'flow3_view_model.dart';
import '../models/flow3_models.dart';

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
    this.dailyClaimed = false,
    this.heldDeposits = const {},
    this.claimedMilestones = const {},
    this.claimingMilestoneId,
    this.cancellingEventId,
    this.checkingInEventId,
  }) : week = week ?? DateTime(2026, 10, 26),
       calendarMonth = calendarMonth ?? DateTime(2026, 11),
       transactions = transactions ?? ActivityMockData.history,
       receipt = receipt ?? ActivityMockData.referenceReceipt,
       receipts = receipts ?? [ActivityMockData.referenceReceipt];
  final bool past, usedRewards, flashlight;
  final bool dailyClaimed;
  final Map<String, int> heldDeposits;
  final Set<String> claimedMilestones;
  final String? claimingMilestoneId;
  final String? cancellingEventId;
  final String? checkingInEventId;
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
    bool? dailyClaimed,
    Map<String, int>? heldDeposits,
    Set<String>? claimedMilestones,
    String? claimingMilestoneId,
    bool clearMilestoneClaim = false,
    String? cancellingEventId,
    bool clearCancellation = false,
    String? checkingInEventId,
    bool clearCheckIn = false,
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
    dailyClaimed: dailyClaimed ?? this.dailyClaimed,
    heldDeposits: heldDeposits ?? this.heldDeposits,
    claimedMilestones: claimedMilestones ?? this.claimedMilestones,
    claimingMilestoneId: clearMilestoneClaim
        ? null
        : claimingMilestoneId ?? this.claimingMilestoneId,
    cancellingEventId: clearCancellation
        ? null
        : cancellingEventId ?? this.cancellingEventId,
    checkingInEventId: clearCheckIn
        ? null
        : checkingInEventId ?? this.checkingInEventId,
  );
}

final activityViewModelProvider =
    NotifierProvider<ActivityViewModel, ActivityState>(ActivityViewModel.new);

class ActivityViewModel extends Notifier<ActivityState> {
  bool get rewardsLive => ref.read(realBackendEnabledProvider);
  Flow3Snapshot? get rewardsData =>
      rewardsLive ? ref.read(flow3ViewModelProvider).asData?.value : null;
  bool get rewardsBusy => rewardsData?.busy != null;
  int get rewardAvailable =>
      rewardsLive ? rewardsData?.availableCoins ?? 0 : state.available;
  int get rewardHeld =>
      rewardsLive ? rewardsData?.heldCoins ?? 0 : state.deposits;
  bool get dailySaving => rewardsData?.busy == 'daily';
  bool get dailyClaimed => rewardsLive
      ? rewardsData?.daily['alreadyClaimed'] == true
      : state.dailyClaimed;
  DailyPresentation get dailyProgress => rewardsLive
      ? rewardsData!.dailyPresentation
      : ActivityMockData.dailyCheckInPreview;
  int get verifiedCount =>
      rewardsLive ? rewardsData?.verifiedCount ?? 0 : state.verified.length;
  List<RedemptionReceipt> get rewardReceipts =>
      rewardsLive ? rewardsData?.receipts ?? [] : state.receipts;
  List<RedemptionReceipt> get availableReceipts =>
      rewardReceipts.where((r) => r.available(DateTime.now().toUtc())).toList();
  List<({CampusReward reward, String status})> get archivedReceipts =>
      rewardsLive
      ? rewardReceipts
            .where((r) => !r.available(DateTime.now().toUtc()))
            .map(
              (r) => (
                reward: r.reward,
                status: r.expired(DateTime.now().toUtc()) && r.status != 'used'
                    ? 'Expired'
                    : r.status == 'used'
                    ? 'Used'
                    : 'Unavailable',
              ),
            )
            .toList()
      : ActivityMockData.archivedRewards;
  RedemptionReceipt? get lastReceipt => rewardsLive
      ? rewardReceipts
            .where((r) => r.id == rewardsData?.lastRedemptionId)
            .firstOrNull
      : state.receipt;
  String receiptStatus(RedemptionReceipt r) => r.status == 'used'
      ? 'Used'
      : r.expired(DateTime.now().toUtc())
      ? 'Expired'
      : r.status == 'revoked'
      ? 'Unavailable'
      : r.reward.fulfillmentType == 'physical'
      ? 'Ready for collection'
      : 'Available';
  Future<bool> claimDailyRemote() =>
      ref.read(flow3ViewModelProvider.notifier).claimDaily();
  Future<bool> redeemRemote(String id) =>
      ref.read(flow3ViewModelProvider.notifier).redeem(reward(id));

  final _cancelRequests = <String, String>{};
  final _attendanceRequests = <String, String>{};
  String? get _uid =>
      ref.read(authenticationViewModelProvider).asData?.value.userId;
  @override
  ActivityState build() {
    if (!ref.read(realBackendEnabledProvider)) {
      ref.watch(
        authenticationViewModelProvider.select(
          (auth) => auth.asData?.value.userId,
        ),
      );
    }
    if (ref.watch(realBackendEnabledProvider)) {
      ref.listen(flow3ViewModelProvider, (_, _) {
        state = state.copy();
      }, weak: true);
      ref.listen(authenticationViewModelProvider, (previous, next) {
        if (previous?.asData?.value.userId != next.asData?.value.userId) {
          _cancelRequests.clear();
          _attendanceRequests.clear();
          state = state.copy(clearCancellation: true, clearCheckIn: true);
        }
      });
      ref.listen(flow1ViewModelProvider, (_, next) {
        state = _serverState(next.asData?.value, state);
      });
      final now = vietnamTime(DateTime.now());
      return _serverState(
        ref.read(flow1ViewModelProvider).asData?.value,
        ActivityState(
          available: 0,
          deposits: 0,
          verified: {},
          transactions: [],
          receipts: [],
          week: now.subtract(Duration(days: now.weekday - 1)),
          calendarMonth: DateTime(now.year, now.month),
        ),
      );
    }
    return ref.watch(demoAuthEnabledProvider)
        ? ActivityState(available: 2000, heldDeposits: const {'ai': 100})
        : ActivityState();
  }

  ActivityState _serverState(Flow1Snapshot? data, ActivityState previous) {
    final mine = data?.myEvents ?? [];
    return previous.copy(
      available: data?.available ?? 0,
      deposits: data?.held ?? 0,
      verified: mine
          .where((m) => m['attendance'] != null)
          .map((m) => jsonMap(m['event'])['id'] as String)
          .toSet(),
      cancelled: mine
          .where(
            (m) =>
                m['registration'] != null &&
                jsonMap(m['registration'])['state'] == 'cancelled',
          )
          .map((m) => jsonMap(m['event'])['id'] as String)
          .toSet(),
      registrations: mine.map((m) {
        final e = Flow1Event(jsonMap(m['event']));
        final reg = m['registration'] == null
            ? null
            : jsonMap(m['registration']);
        final attendance = m['attendance'] == null
            ? null
            : jsonMap(m['attendance']);
        return RegisteredEvent(
          id: e.id,
          title: e.title,
          category: e.category,
          dateLabel: eventDate(e.start),
          venue: e.venue['name'] as String,
          start: vietnamTime(e.start),
          image:
              e.imageUrl ??
              ActivityMockData.events
                  .where(
                    (item) =>
                        item.category.toLowerCase() == e.category.toLowerCase(),
                  )
                  .firstOrNull
                  ?.image ??
              ActivityMockData.events.first.image,
          coins:
              (attendance?['rewardCoinsGranted'] as num?)?.toInt() ??
              (reg?['attendanceRewardCoinsSnapshot'] as num?)?.toInt() ??
              e.reward,
          walkIn: e.walkIn,
          attended: m['attendance'] != null,
          past: m['past'] == true,
          status: attendance != null
              ? 'Attended'
              : reg?['state'] == 'no_show'
              ? 'No-show'
              : e.walkIn
              ? 'Going'
              : 'Registered',
          verifiedAt: attendance?['verifiedAt'] == null
              ? null
              : DateTime.parse(attendance!['verifiedAt'] as String),
          canCancel:
              attendance == null &&
              (e.walkIn ? m['going'] == true : reg?['state'] == 'registered'),
        );
      }).toList(),
    );
  }

  void resetDemo() {
    if (ref.read(demoAuthEnabledProvider)) {
      state = ActivityState(available: 2000, heldDeposits: const {'ai': 100});
    }
  }

  bool get demoAvailable =>
      ref.read(demoAuthEnabledProvider) &&
      ref.read(hasAuthenticatedSessionProvider);

  List<CoinEntry> _history(String title, int amount, CoinKind kind) => [
    CoinEntry(
      title,
      'Demo session only',
      amount,
      kind,
      3,
      date: ActivityMockData.referenceDate,
    ),
    ...state.transactions,
  ];
  List<RegisteredEvent> get allEvents => [
    if (!ref.read(realBackendEnabledProvider))
      ...ActivityMockData.events.where(
        (event) => !state.registrations.any((entry) => entry.id == event.id),
      ),
    ...state.registrations,
  ];
  bool addRegistration(RegisteredEvent event, {int deposit = 0}) {
    if (!ref.read(hasAuthenticatedSessionProvider)) {
      state = state.copy(message: 'Log in to register for events.');
      return false;
    }
    final existing = state.registrations.any((item) => item.id == event.id);
    if (existing && !state.cancelled.contains(event.id)) return true;
    if (deposit < 0 || (deposit > 0 && !demoAvailable)) {
      state = state.copy(message: coinServiceMessage);
      return false;
    }
    if (deposit > state.available) {
      state = state.copy(message: 'Not enough demo coins for this deposit.');
      return false;
    }
    state = state.copy(
      registrations: existing
          ? state.registrations
          : [...state.registrations, event],
      cancelled: {...state.cancelled}..remove(event.id),
      available: state.available - deposit,
      deposits: state.deposits + deposit,
      heldDeposits: {...state.heldDeposits, if (deposit > 0) event.id: deposit},
      transactions: deposit > 0
          ? _history('Deposit · ${event.title}', deposit, CoinKind.deposit)
          : state.transactions,
    );
    return true;
  }

  bool sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
  void setReference(String view) {
    if (ref.read(realBackendEnabledProvider)) return;
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
            (ref.read(realBackendEnabledProvider)
                    ? event.past
                    : event.attended || state.verified.contains(event.id)) ==
                state.past &&
            (state.selectedDate == null ||
                sameDay(event.start, state.selectedDate!)),
      )
      .toList();
  int countFor(bool past) => allEvents
      .where(
        (event) =>
            (ref.read(realBackendEnabledProvider)
                    ? event.past
                    : event.attended || state.verified.contains(event.id)) ==
                past &&
            !state.cancelled.contains(event.id),
      )
      .length;
  bool hasEvent(DateTime day) => allEvents.any(
    (event) => sameDay(event.start, day) && !state.cancelled.contains(event.id),
  );
  RegisteredEvent? findEvent(String id) =>
      allEvents.where((e) => e.id == id).firstOrNull;
  RegisteredEvent event(String id) => allEvents.firstWhere(
    (e) => e.id == id,
    orElse: () {
      if (ref.read(realBackendEnabledProvider)) {
        throw const AppException(
          code: 'NOT_REGISTERED',
          message: 'No registration for this event.',
        );
      }
      return ActivityMockData.events.first;
    },
  );
  CampusReward reward(String id) =>
      (rewardsLive ? rewardsData?.rewards ?? [] : ActivityMockData.rewards)
          .firstWhere(
            (r) => r.id == id,
            orElse: () {
              if (rewardsLive) {
                throw const AppException(
                  code: 'REWARD_NOT_FOUND',
                  message: 'Reward unavailable.',
                );
              }
              return ActivityMockData.rewards.first;
            },
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
  Future<bool> cancelEvent(String id) async {
    if (!ref.read(realBackendEnabledProvider)) return cancelRegistration(id);
    if (_uid == null || state.cancellingEventId != null) return false;
    final item = allEvents.where((e) => e.id == id).firstOrNull;
    if (item == null || item.attended) return false;
    final uid = _uid;
    final repo = ref.read(flow1RepositoryProvider);
    final recovering = _cancelRequests.containsKey(id);
    final requestId = _cancelRequests.putIfAbsent(
      id,
      () => List.generate(
        16,
        (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0'),
      ).join(),
    );
    state = state.copy(cancellingEventId: id);
    try {
      Map<String, dynamic>? result;
      if (item.walkIn) {
        await repo.stopGoing(id);
      } else {
        if (recovering) {
          try {
            result = await repo.recover('cancel', requestId);
          } on AppException catch (e) {
            if (e.code != 'NOT_FOUND') rethrow;
          }
        }
        result ??= await repo.cancel(id, requestId);
      }
      if (!ref.mounted || _uid != uid) return false;
      _cancelRequests.remove(id);
      state = state.copy(
        cancelled: {...state.cancelled, id},
        available: result?['wallet'] == null
            ? state.available
            : (jsonMap(result!['wallet'])['availableCoins'] as num).toInt(),
        deposits: result?['wallet'] == null
            ? state.deposits
            : (jsonMap(result!['wallet'])['heldCoins'] as num).toInt(),
        clearCancellation: true,
        message: item.walkIn
            ? 'Removed from Going.'
            : 'Registration cancelled. ${result?['depositRefunded'] ?? 0} coins refunded.',
      );
      final message = state.message;
      await ref.read(flow1ViewModelProvider.notifier).refresh();
      if (!ref.mounted || _uid != uid) return false;
      state = state.copy(message: message);
      ref.invalidate(flow1TicketProvider(id));
      return true;
    } catch (error) {
      if (ref.mounted && _uid == uid) {
        state = state.copy(
          clearCancellation: true,
          message: ExceptionMapper.map(error).message,
        );
      }
      return false;
    }
  }

  bool cancelRegistration(String id) {
    if (ref.read(realBackendEnabledProvider)) {
      state = state.copy(message: 'Cancellation is not connected yet.');
      return false;
    }
    if (state.cancelled.contains(id)) return false;
    final deposit = demoAvailable ? state.heldDeposits[id] ?? 0 : 0;
    final refunded = deposit * 3 ~/ 10;
    state = state.copy(
      cancelled: {...state.cancelled, id},
      available: state.available + refunded,
      deposits: state.deposits - deposit,
      heldDeposits: {...state.heldDeposits}..remove(id),
      transactions: deposit > 0
          ? _history('Cancellation refund · 30%', refunded, CoinKind.refund)
          : state.transactions,
      message: 'Registration cancelled.',
    );
    return true;
  }

  void beginCalendar() => state = state.copy(
    draftDate:
        state.selectedDate ??
        (ref.read(realBackendEnabledProvider)
            ? vietnamTime(DateTime.now())
            : DateTime(2026, 11, 2)),
    calendarMonth: ref.read(realBackendEnabledProvider)
        ? DateTime(
            (state.selectedDate ?? vietnamTime(DateTime.now())).year,
            (state.selectedDate ?? vietnamTime(DateTime.now())).month,
          )
        : DateTime(2026, 11),
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
  DateTime get today => ref.read(realBackendEnabledProvider)
      ? vietnamTime(DateTime.now())
      : ActivityMockData.referenceDate;
  bool demoCheckInAvailable(String id) =>
      kDebugMode &&
      ref.read(realBackendEnabledProvider) &&
      ref
              .read(flow1ViewModelProvider)
              .asData
              ?.value
              .profile['demoAttendanceEnabled'] ==
          true &&
      ref
              .read(flow1ViewModelProvider)
              .asData
              ?.value
              .events
              .any((e) => e.id == id && e.data['isDemo'] == true) ==
          true;
  Future<bool> demoAttend(String id) => _attend(id, demo: true);
  Future<bool> verifyWalkIn(String id, String value, {bool manual = false}) =>
      _attend(id, value: value, manual: manual);
  Future<bool> _attend(
    String id, {
    String value = '',
    bool manual = false,
    bool demo = false,
  }) async {
    if (_uid == null || state.checkingInEventId != null) return false;
    if (demo && !demoCheckInAvailable(id)) return false;
    final input = manual
        ? value.replaceAll(RegExp(r'[\s-]'), '').toUpperCase()
        : value.trim();
    if (!demo &&
        !(manual
            ? RegExp(r'^[A-Z2-9]{8}$').hasMatch(input)
            : RegExp(r'^evia:walkin:[A-Za-z0-9_-]{32}:[A-Za-z0-9_-]{43}$')
                  .hasMatch(input))) {
      state = state.copy(
        message: 'Enter a valid event code or scan a walk-in QR.',
      );
      return false;
    }
    final uid = _uid, key = '$id:$demo:$manual:$input';
    final requestId = _attendanceRequests.putIfAbsent(
      key,
      () => List.generate(
        16,
        (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0'),
      ).join(),
    );
    state = state.copy(checkingInEventId: id);
    try {
      final repo = ref.read(flow1RepositoryProvider);
      final result = demo
          ? await repo.demoAttend(id, requestId)
          : await repo.verifyWalkIn({
              'requestId': requestId,
              'expectedEventId': id,
              if (manual) 'code': input else 'qrPayload': input,
            }, manual: manual);
      if (!ref.mounted || _uid != uid) return false;
      if (result['eventId'] != id) {
        throw StateError('Unexpected attendance event');
      }
      state = state.copy(
        verified: {...state.verified, id},
        clearCheckIn: true,
        message:
            '${demo ? 'Demo attendance' : 'Attendance'} confirmed · +${result['coinsGranted']} coins.',
      );
      final message = state.message;
      await ref.read(flow1ViewModelProvider.notifier).refresh();
      if (!ref.mounted || _uid != uid) return false;
      state = state.copy(message: message);
      ref.invalidate(flow1TicketProvider(id));
      return true;
    } catch (error) {
      if (ref.mounted && _uid == uid) {
        state = state.copy(
          clearCheckIn: true,
          message: ExceptionMapper.map(error).message,
        );
      }
      return false;
    }
  }

  static const coinServiceMessage =
      'Coin service is not connected yet. Preview data only.';
  bool get coinServiceAvailable => demoAvailable;
  bool checkIn(String code) {
    if (!demoAvailable) {
      state = state.copy(message: coinServiceMessage);
      return false;
    }
    if (code.trim().toUpperCase() != ActivityMockData.demoCheckInCode) {
      state = state.copy(message: 'Invalid demo event code.');
      return false;
    }
    if (state.verified.contains('club-live')) {
      state = state.copy(message: 'Attendance already confirmed.');
      return true;
    }
    final club = RegistrationMockData.club;
    addRegistration(
      RegisteredEvent(
        id: club.id,
        title: club.title,
        category: club.category,
        dateLabel: '${club.date} · ${club.time}',
        venue: club.venue,
        start: club.start,
        walkIn: true,
        coins: club.coins,
      ),
    );
    state = state.copy(
      verified: {...state.verified, 'club-live'},
      available: state.available + 80,
      transactions: _history('Campus Club Fair check-in', 80, CoinKind.earned),
      message: 'Demo attendance confirmed · +80 coins.',
    );
    return true;
  }

  bool claimDaily() {
    if (!demoAvailable || state.dailyClaimed) return false;
    state = state.copy(
      dailyClaimed: true,
      available: state.available + ActivityMockData.dailyCheckInPreview.coins,
      transactions: _history(
        'Daily Check-in',
        ActivityMockData.dailyCheckInPreview.coins,
        CoinKind.earned,
      ),
      message: 'Demo daily reward collected.',
    );
    return true;
  }

  void selectRewardCategory(String value) =>
      state = state.copy(rewardCategory: value);
  void searchRewards(String value) => state = state.copy(rewardQuery: value);
  void historyFilter(String value) => state = state.copy(historyFilter: value);
  void selectLockerTab(bool used) => state = state.copy(usedRewards: used);
  List<CampusReward> get visibleRewards =>
      (rewardsLive ? rewardsData?.rewards ?? [] : ActivityMockData.rewards)
          .where(
            (reward) =>
                (state.rewardCategory == 'All' ||
                    reward.category == state.rewardCategory) &&
                reward.title.toLowerCase().contains(
                  state.rewardQuery.toLowerCase().trim(),
                ),
          )
          .toList();
  List<CoinEntry> get history =>
      (rewardsLive ? rewardsData?.history ?? [] : state.transactions)
          .where(
            (entry) => switch (state.historyFilter) {
              'Earned' => entry.kind == CoinKind.earned,
              'Spent' => entry.kind == CoinKind.spent,
              'Deposits' =>
                entry.kind == CoinKind.deposit || entry.kind == CoinKind.refund,
              _ => true,
            },
          )
          .toList();
  bool canRedeem(String id) => rewardsLive
      ? !rewardsBusy &&
            rewardsData?.rewards.any(
                  (r) =>
                      r.id == id &&
                      r.active &&
                      r.stock > 0 &&
                      r.redeemCost <= rewardAvailable,
                ) ==
                true
      : demoAvailable &&
            !state.redeemed.contains(id) &&
            state.available >= reward(id).redeemCost;
  String rewardStatus(String id) => rewardsLive
      ? rewardsBusy
            ? 'Processing…'
            : !reward(id).active
            ? 'Unavailable'
            : reward(id).stock < 1
            ? 'Out of stock'
            : rewardAvailable < reward(id).redeemCost
            ? 'Not enough coins'
            : 'Available'
      : !demoAvailable
      ? 'Preview'
      : state.redeemed.contains(id)
      ? 'Redeemed'
      : state.available < reward(id).redeemCost
      ? 'Not enough coins'
      : 'Available';

  RedemptionReceipt? voucher(String? code) {
    if (rewardReceipts.isEmpty) return null;
    if (code == null) return rewardsLive ? null : rewardReceipts.first;
    for (final item in rewardReceipts) {
      if (item.code == code) return item;
    }
    return null;
  }

  String dateLabel(DateTime date) {
    final local = rewardsLive ? vietnamTime(date) : date;
    return '${_months[local.month - 1]} ${local.day}, ${local.year}';
  }

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
    if (rewardsLive) {
      return (rewardsData?.milestones ?? [])
          .map(
            (m) => MilestoneProgress(
              m.milestone,
              reached: m.reached,
              next: m.next,
              remaining: m.remaining,
              claimed: m.claimed,
              claiming: rewardsData?.busy == 'milestone:${m.milestone.id}',
            ),
          )
          .toList();
    }
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
          claimed: state.claimedMilestones.contains(m.id),
          claiming: state.claimingMilestoneId == m.id,
        ),
    ];
  }

  Future<bool> claimMilestone(String id) async {
    if (rewardsLive) {
      final milestone = milestones
          .where((m) => m.milestone.id == id)
          .firstOrNull;
      if (milestone == null || !milestone.canClaim || rewardsBusy) return false;
      return ref
          .read(flow3ViewModelProvider.notifier)
          .claimMilestone(id, milestone.milestone.version);
    }
    if (!ref.read(hasAuthenticatedSessionProvider) ||
        state.claimingMilestoneId != null) {
      return false;
    }
    final progress = milestones
        .where((item) => item.milestone.id == id)
        .firstOrNull;
    if (progress == null || !progress.canClaim) return false;
    state = state.copy(claimingMilestoneId: id);
    try {
      final result = await ref
          .read(campusRepositoryProvider)
          .claimEventMilestone(id, progress.milestone.version);
      if (!ref.mounted) return false;
      if (result.milestoneId != id ||
          result.availableCoins < 0 ||
          result.heldCoins < 0) {
        throw StateError('Invalid claim response');
      }
      state = state.copy(
        available: result.availableCoins,
        deposits: result.heldCoins,
        claimedMilestones: {...state.claimedMilestones, id},
        clearMilestoneClaim: true,
        message: 'Milestone reward received.',
      );
      return true;
    } catch (error) {
      if (ref.mounted) {
        state = state.copy(
          clearMilestoneClaim: true,
          message: ExceptionMapper.map(error).message,
        );
      }
      return false;
    }
  }

  int get unlockedMilestones => milestones.where((m) => m.reached).length;
  MilestoneProgress? get nextMilestone =>
      milestones.where((m) => m.next).firstOrNull;
  String get currentAchievement =>
      milestones.where((m) => m.reached).lastOrNull?.milestone.title ??
      'Getting started';
  int get milestoneTarget =>
      nextMilestone?.milestone.events ??
      (milestones.isEmpty ? 1 : milestones.last.milestone.events);
  double get milestoneFraction => (verifiedCount / milestoneTarget).clamp(0, 1);
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
    if (!canRedeem(id)) {
      state = state.copy(
        message: demoAvailable ? rewardStatus(id) : coinServiceMessage,
      );
      return false;
    }
    final item = reward(id);
    final balance = state.available - item.redeemCost;
    final date = ActivityMockData.referenceDate;
    final receipt = RedemptionReceipt(
      item,
      item.redeemCost,
      balance,
      'DEMO-${item.id.toUpperCase()}-${state.receipts.length + 1}',
      redeemedOn: date,
      expiresOn: item.validDays == null
          ? null
          : date.add(Duration(days: item.validDays!)),
    );
    state = state.copy(
      available: balance,
      redeemed: {...state.redeemed, id},
      receipt: receipt,
      receipts: [receipt, ...state.receipts],
      transactions: _history(item.title, item.redeemCost, CoinKind.spent),
      message: 'Demo reward redeemed.',
    );
    return true;
  }
}
