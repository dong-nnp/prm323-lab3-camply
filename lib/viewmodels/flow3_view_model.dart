import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/activity_assets.dart';
import '../data/mock/activity_mock_data.dart';
import '../core/errors/app_exception.dart';
import '../core/providers/repository_providers.dart';
import '../core/utils/exception_mapper.dart';
import '../models/activity_models.dart';
import '../models/flow1_models.dart';
import '../models/flow3_models.dart';
import 'authentication_view_model.dart';
import 'flow1_view_model.dart';

final flow3ViewModelProvider =
    AsyncNotifierProvider<Flow3ViewModel, Flow3Snapshot>(Flow3ViewModel.new);

class Flow3ViewModel extends AsyncNotifier<Flow3Snapshot> {
  int _generation = 0;
  // shortcut: pending request IDs last for this session; persist them before supporting restart recovery.
  final _requests = <String, Map<String, dynamic>>{};
  String? _lastRedemptionId;
  bool _busy = false;
  Timer? _dayTimer;
  String? get _uid =>
      ref.read(authenticationViewModelProvider).asData?.value.userId;
  @override
  Future<Flow3Snapshot> build() async {
    ref.watch(
      authenticationViewModelProvider.select(
        (auth) => auth.asData?.value.userId,
      ),
    );
    _generation++;
    _requests.clear();
    _lastRedemptionId = null;
    ref.onDispose(() => _dayTimer?.cancel());
    if (_uid == null) {
      throw const AppException(
        code: 'unauthenticated',
        message: 'Log in to view rewards.',
      );
    }
    final generation = _generation, uid = _uid;
    final result = await _load();
    if (ref.mounted && generation == _generation && uid == _uid) {
      _scheduleDayRefresh(result);
    }
    return result;
  }

  void _scheduleDayRefresh(Flow3Snapshot data) {
    final now = DateTime.parse(data.daily['serverTime'] as String).toUtc();
    final local = vietnamTime(now);
    final next = DateTime.utc(
      local.year,
      local.month,
      local.day + 1,
    ).subtract(const Duration(hours: 7));
    _dayTimer?.cancel();
    _dayTimer = Timer(next.difference(now) + const Duration(seconds: 1), () {
      if (ref.mounted) unawaited(refresh());
    });
  }

  Future<Flow3Snapshot> _load() async {
    final raw = await ref.read(flow1RepositoryProvider).loadRewards();
    final account = jsonMap(raw['account']),
        milestoneData = jsonMap(raw['milestones']);
    final daily = jsonMap(account['daily']);
    if (daily['dayKey'] is! String ||
        daily['serverTime'] is! String ||
        daily['streakDay'] is! num ||
        daily['coins'] is! num ||
        daily['alreadyClaimed'] is! bool) {
      throw const AppException(
        code: 'daily_unavailable',
        message: 'Daily status is unavailable. Please reload.',
      );
    }
    final balance = (jsonMap(account['wallet'])['availableCoins'] as num)
        .toInt();
    String fallback(String id) =>
        ActivityMockData.rewards
            .where((r) => r.id == id.replaceFirst(RegExp(r'^demo-'), ''))
            .firstOrNull
            ?.image ??
        ActivityAssets.image('2083:3327', 2);
    final vouchers = jsonRows(raw['vouchers']);
    final nextId = milestoneData['nextMilestone'] == null
        ? null
        : jsonMap(milestoneData['nextMilestone'])['id'];
    return Flow3Snapshot(
      daily: daily,
      availableCoins: balance,
      heldCoins: (jsonMap(account['wallet'])['heldCoins'] as num).toInt(),
      rewards: jsonRows(raw['rewards'])
          .map((r) => serverReward(r, fallback(r['id'] as String)))
          .toList(),
      receipts: jsonRows(raw['redemptions'])
          .map(
            (r) => serverReceipt(
              r,
              vouchers.where((v) => v['id'] == r['voucherId']).firstOrNull,
              fallback(r['rewardId'] as String),
              balance,
            ),
          )
          .toList(),
      history: jsonRows(raw['ledger']).map(serverLedger).toList(),
      verifiedCount: (milestoneData['verifiedEventCount'] as num).toInt(),
      milestones: jsonRows(milestoneData['items'])
          .map(
            (m) => MilestoneProgress(
              EventMilestone(
                m['title'] as String,
                (m['requiredEvents'] as num).toInt(),
                (m['rewardCoins'] as num).toInt(),
                m['description'] as String? ?? '',
                id: m['id'] as String,
                version: (m['version'] as num).toInt(),
              ),
              reached: m['unlocked'] == true,
              next: m['id'] == nextId,
              remaining: (m['remainingEvents'] as num).toInt(),
              claimed: m['claimed'] == true,
            ),
          )
          .toList(),
      lastRedemptionId: _lastRedemptionId,
    );
  }

  Future<void> refresh() async {
    if (_busy) return;
    final generation = ++_generation, uid = _uid;
    if (!state.hasValue) state = const AsyncLoading();
    try {
      final data = await _load();
      if (ref.mounted && generation == _generation && uid == _uid) {
        _scheduleDayRefresh(data);
      }
      if (ref.mounted && generation == _generation && uid == _uid) {
        state = AsyncData(data);
      }
    } catch (e, s) {
      if (ref.mounted && generation == _generation && uid == _uid) {
        state = AsyncError(e, s);
      }
    }
  }

  Future<bool> _action(String name, Future<void> Function() work) async {
    if (_busy || _uid == null || !state.hasValue) return false;
    final uid = _uid, generation = _generation;
    bool current() => ref.mounted && uid == _uid && generation == _generation;
    _busy = true;
    final before = state.requireValue;
    state = AsyncData(before.action(busy: name));
    try {
      await work();
      if (!current()) return false;
      final data = await _load();
      if (ref.mounted && generation == _generation && uid == _uid) {
        _scheduleDayRefresh(data);
      }
      if (!current()) return false;
      state = AsyncData(data);
      if (name.startsWith('redeem:')) _requests.remove(name.substring(7));
      await ref.read(flow1ViewModelProvider.notifier).refresh();
      return current();
    } catch (error) {
      if (current()) {
        unawaited(
          ref
              .read(analyticsRepositoryProvider)
              .error(
                name.startsWith('redeem:')
                    ? 'redeem_reward'
                    : name == 'daily'
                    ? 'claim_daily'
                    : 'claim_milestone',
                error,
              ),
        );
      }
      if (current() &&
          error is AppException &&
          [
            'PRICE_CHANGED',
            'TERMS_CHANGED',
            'OUT_OF_STOCK',
            'REWARD_INACTIVE',
            'INSUFFICIENT_COINS',
            'MILESTONE_CHANGED',
            'MILESTONE_NOT_UNLOCKED',
            'MILESTONE_INACTIVE',
          ].contains(error.code)) {
        try {
          final updated = await _load();
          if (current()) {
            state = AsyncData(
              updated.action(error: ExceptionMapper.map(error).message),
            );
          }
          return false;
        } catch (_) {
          /* Keep the action error when reloading also fails. */
        }
      }
      if (current()) {
        state = AsyncData(
          before.action(error: ExceptionMapper.map(error).message),
        );
      }
      return false;
    } finally {
      _busy = false;
    }
  }

  Future<bool> claimDaily() => _action('daily', () async {
    await ref.read(flow1RepositoryProvider).claimDaily();
  });
  Future<bool> claimMilestone(String id, int version) =>
      _action('milestone:$id', () async {
        await ref.read(flow1RepositoryProvider).claimMilestone(id, version);
      });
  Future<bool> redeem(CampusReward reward) => _action(
    'redeem:${reward.id}',
    () async {
      final repo = ref.read(flow1RepositoryProvider);
      final prior = _requests[reward.id];
      final input = _requests.putIfAbsent(
        reward.id,
        () => {
          'rewardId': reward.id,
          'requestId': List.generate(
            16,
            (_) =>
                Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0'),
          ).join(),
          'expectedPriceCoins': reward.redeemCost,
          'expectedTermsVersion': reward.termsVersion,
        },
      );
      final uid = _uid;
      Map<String, dynamic>? result;
      if (prior != null) {
        try {
          result = await repo.recover('redeem', input['requestId'] as String);
        } on AppException catch (e) {
          if (e.code != 'NOT_FOUND') rethrow;
        }
      }
      try {
        if (!ref.mounted || uid != _uid) return;
        result ??= await repo.redeem(input);
      } on AppException catch (e) {
        if ([
          'PRICE_CHANGED',
          'TERMS_CHANGED',
          'OUT_OF_STOCK',
          'REWARD_INACTIVE',
          'INSUFFICIENT_COINS',
        ].contains(e.code)) {
          _requests.remove(reward.id);
        }
        rethrow;
      }
      if (!ref.mounted || uid != _uid) return;
      _lastRedemptionId = result['redemptionId'] as String;
      unawaited(
        ref
            .read(analyticsRepositoryProvider)
            .track(
              'redeem_reward',
              once: input['requestId'] as String,
              parameters: {
                'reward_id': reward.id,
                'cost_coins': input['expectedPriceCoins'] as int,
                'fulfillment_type': reward.fulfillmentType,
              },
            ),
      );
      // Retain receipt key until a fresh load succeeds, so a failed refresh cannot debit twice.
    },
  );
}

final rewardDetailViewModelProvider = FutureProvider.autoDispose
    .family<void, String>((ref, id) async {
      final uid = ref
          .read(authenticationViewModelProvider)
          .asData
          ?.value
          .userId;
      final analytics = ref.read(analyticsRepositoryProvider);
      try {
        final data = await ref.read(flow3ViewModelProvider.future);
        if (!ref.mounted ||
            uid !=
                ref
                    .read(authenticationViewModelProvider)
                    .asData
                    ?.value
                    .userId) {
          return;
        }
        final reward = data.rewards.where((r) => r.id == id).firstOrNull;
        if (reward != null) {
          unawaited(
            analytics.track(
              'view_reward',
              parameters: {
                'reward_id': reward.id,
                'price_coins': reward.redeemCost,
              },
            ),
          );
        }
      } catch (error) {
        if (ref.mounted) unawaited(analytics.error('view_reward', error));
      }
    });

final voucherCodeProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, id) async {
      ref.watch(
        authenticationViewModelProvider.select(
          (auth) => auth.asData?.value.userId,
        ),
      );
      try {
        final code = await ref.watch(flow1RepositoryProvider).voucherCode(id);
        if (code['code'] is! String || code['qrPayload'] is! String) {
          throw const AppException(
            code: 'invalid_voucher',
            message: 'Voucher code is unavailable.',
          );
        }
        if (ref.mounted) {
          final remaining = code['expiresAt'] == null
              ? const Duration(seconds: 30)
              : DateTime.parse(code['expiresAt'] as String)
                    .difference(DateTime.now().toUtc());
          final timer = Timer(
            remaining < const Duration(seconds: 30)
                ? remaining
                : const Duration(seconds: 30),
            () {
              ref.invalidateSelf();
              unawaited(ref.read(flow3ViewModelProvider.notifier).refresh());
            },
          );
          ref.onDispose(timer.cancel);
        }
        return code;
      } on AppException catch (e) {
        if (ref.mounted &&
            ['USED', 'EXPIRED', 'VOUCHER_UNAVAILABLE'].contains(e.code)) {
          unawaited(ref.read(flow3ViewModelProvider.notifier).refresh());
        }
        rethrow;
      }
    });
