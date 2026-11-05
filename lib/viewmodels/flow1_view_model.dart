import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers/repository_providers.dart';
import '../core/errors/app_exception.dart';
import '../core/utils/exception_mapper.dart';
import '../core/utils/fpt_identity.dart';
import '../models/flow1_models.dart';
import '../models/activity_models.dart';
import '../models/auth_session.dart';
import '../models/evia_models.dart';
import 'authentication_view_model.dart';

final flow1ViewModelProvider =
    AsyncNotifierProvider<Flow1ViewModel, Flow1Snapshot>(Flow1ViewModel.new);

class Flow1ViewModel extends AsyncNotifier<Flow1Snapshot> {
  bool _busy = false;
  int _generation = 0;
  String? get _uid =>
      ref.read(authenticationViewModelProvider).asData?.value.userId;
  @override
  Future<Flow1Snapshot> build() async {
    _generation++;
    final session = ref.watch(authenticationViewModelProvider).asData?.value;
    return ref
        .watch(flow1RepositoryProvider)
        .load(session?.status == AuthStatus.signedIn);
  }

  Future<void> refresh() async {
    final generation = ++_generation, uid = _uid;
    if (!state.hasValue) state = const AsyncLoading();
    try {
      final data = await ref.read(flow1RepositoryProvider).load(uid != null);
      if (ref.mounted && generation == _generation && uid == _uid) {
        state = AsyncData(data);
      }
    } catch (e, s) {
      if (ref.mounted && generation == _generation && uid == _uid) {
        state = AsyncError(e, s);
      }
    }
  }

  ({
    int day,
    int coins,
    int lastDayCoins,
    bool checkedInToday,
    bool saving,
    List<({int day, int coins, bool today, bool claimed})> days,
  })?
  get dailyProgress {
    final data = state.asData?.value;
    final rawDaily = data?.account?['daily'];
    if (rawDaily is! Map) return null;
    final daily = jsonMap(rawDaily);
    final rewards = daily['rewards'];
    final day = daily['streakDay'];
    final coins = daily['coins'];
    if (rewards is! List ||
        rewards.length != 7 ||
        rewards.any((value) => value is! num) ||
        day is! num ||
        day < 1 ||
        coins is! num) {
      return null;
    }
    final currentDay = min(day.toInt(), 7);
    final claimed = daily['alreadyClaimed'] == true;
    return (
      day: day.toInt(),
      coins: coins.toInt(),
      lastDayCoins: (rewards.last as num).toInt(),
      checkedInToday: claimed,
      saving: data?.busy ?? false,
      days: [
        for (var index = 1; index <= 7; index++)
          (
            day: index,
            coins: index == currentDay
                ? coins.toInt()
                : (rewards[index - 1] as num).toInt(),
            today: index == currentDay,
            claimed: index < currentDay || (index == currentDay && claimed),
          ),
      ],
    );
  }

  Future<bool> claimDaily() =>
      _action(() => ref.read(flow1RepositoryProvider).claimDaily());

  void selectInterest(String id) {
    if (_busy || !state.hasValue) return;
    final data = state.requireValue;
    if (!data.interests.any((i) => i['id'] == id)) return;
    final selected = {...data.selectedInterests};
    selected.contains(id) ? selected.remove(id) : selected.add(id);
    state = AsyncData(data.withInterests(selected));
  }

  Future<bool> _action(Future<void> Function() work) async {
    if (_busy || _uid == null || !state.hasValue) return false;
    _busy = true;
    final uid = _uid, generation = _generation;
    final data = state.requireValue;
    state = AsyncData(data.withAction(busy: true));
    try {
      await work();
      if (!ref.mounted || uid != _uid || generation != _generation) {
        return false;
      }
      await refresh();
      return state.hasValue;
    } catch (e) {
      if (ref.mounted && uid == _uid && generation == _generation) {
        state = AsyncData(
          data.withAction(error: ExceptionMapper.map(e).message),
        );
      }
      return false;
    } finally {
      _busy = false;
    }
  }

  Future<bool> saveInterests() async {
    final selected = state.asData?.value.selectedInterests;
    if (selected == null || selected.length < 3) return false;
    return _action(
      () => ref.read(flow1RepositoryProvider).saveInterests(selected),
    );
  }

  Future<bool> follow(String id) {
    final next = !(state.asData?.value.followed.contains(id) ?? false);
    return _action(() => ref.read(flow1RepositoryProvider).follow(id, next));
  }

  Future<bool> bookmark(String id) {
    final next = !(state.asData?.value.saved.contains(id) ?? false);
    return _action(() => ref.read(flow1RepositoryProvider).bookmark(id, next));
  }

  Future<bool> going(String id) =>
      _action(() => ref.read(flow1RepositoryProvider).going(id));
}

final flow1EventProvider = FutureProvider.autoDispose
    .family<Flow1Event, String>(
      (ref, id) => ref.watch(flow1RepositoryProvider).event(id),
    );
typedef Flow1Search = ({String query, String category, EventFilters filters});
final flow1SearchProvider = FutureProvider.autoDispose
    .family<List<Flow1Event>, Flow1Search>(
      (ref, input) => ref
          .watch(flow1RepositoryProvider)
          .search(input.query, input.category, input.filters),
    );
final flow1TicketProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, id) async {
      ref.watch(authenticationViewModelProvider);
      final repo = ref.watch(flow1RepositoryProvider);
      final ticket = await repo.ticket(id);
      if (ticket['event'] is! Map) {
        throw const AppException(
          code: 'EVENT_NOT_FOUND',
          message: 'This event is no longer available.',
        );
      }
      final event = Flow1Event(jsonMap(ticket['event']));
      if (event.id != id) {
        throw const AppException(
          code: 'invalid_response',
          message: 'The ticket does not match this event. Please reload.',
        );
      }
      ticket['eventPresentation'] = RegisteredEvent(
        id: event.id,
        title: event.title,
        category: event.category,
        dateLabel: eventDate(event.start),
        venue: event.venue['name'] as String,
        start: vietnamTime(event.start),
        walkIn: event.walkIn,
      );
      final registration = jsonMap(ticket['registration']);
      final row = ref
          .read(flow1ViewModelProvider)
          .asData
          ?.value
          .myEvents
          .where((m) => jsonMap(m['event'])['id'] == id)
          .firstOrNull;
      if (row != null &&
          row['registration'] != null &&
          jsonMap(row['registration'])['state'] != registration['state']) {
        unawaited(ref.read(flow1ViewModelProvider.notifier).refresh());
      }
      if (jsonMap(ticket['ticket'])['status'] == 'active') {
        ticket['qr'] = await repo.ticketQr(id);
      }
      if (ref.mounted) {
        final timer = Timer(
          const Duration(seconds: 60),
          () => ref.invalidateSelf(),
        );
        ref.onDispose(timer.cancel);
      }
      return ticket;
    });

class Flow1RegistrationState {
  const Flow1RegistrationState({
    this.busy = false,
    this.uncertain = false,
    this.success = false,
    this.message,
    this.errors = const {},
    this.result,
  });
  final bool busy, uncertain, success;
  final String? message;
  final Map<String, String> errors;
  final Map<String, dynamic>? result;
}

final flow1RegistrationProvider = NotifierProvider.autoDispose
    .family<Flow1RegistrationViewModel, Flow1RegistrationState, String>(
      Flow1RegistrationViewModel.new,
    );

class Flow1RegistrationViewModel extends Notifier<Flow1RegistrationState> {
  Flow1RegistrationViewModel(this.eventId);
  final String eventId;
  Map<String, dynamic>? _request;
  @override
  Flow1RegistrationState build() {
    ref.watch(authenticationViewModelProvider);
    _request = null;
    return const Flow1RegistrationState();
  }

  Future<bool> submit(
    Flow1Event event,
    Map<String, String> fields,
    bool agreed,
  ) async {
    if (state.busy || state.success) return state.success;
    if (event.id != eventId) return false;
    final uid = ref.read(authenticationViewModelProvider).asData?.value.userId;
    if (uid == null) {
      state = const Flow1RegistrationState(message: 'Log in to register.');
      return false;
    }
    if (_request == null && (event.walkIn || event.terms == null)) {
      state = const Flow1RegistrationState(
        message: 'This event does not accept ticket registration.',
      );
      return false;
    }
    final errors = <String, String>{
      if (fields['fullName']!.trim().isEmpty)
        'fullName': 'Enter your full name.',
      if (!FptIdentity.validStudentId(fields['studentId']!))
        'studentId': 'Use two letters and six digits, e.g. SE123456.',
      if (!FptIdentity.validEmail(fields['universityEmail']!))
        'universityEmail': 'Enter a valid email address.',
      if (fields['phoneNumber']!.isNotEmpty &&
          !RegExp(r'^\+?[0-9 ()-]{7,24}$').hasMatch(fields['phoneNumber']!))
        'phoneNumber': 'Enter a valid phone number.',
      if (!agreed) 'terms': 'Accept the event terms.',
    };
    if (_request == null && errors.isNotEmpty) {
      state = Flow1RegistrationState(errors: errors);
      return false;
    }
    final recovering = _request != null;
    _request ??= {
      'eventId': event.id,
      'requestId': List.generate(
        16,
        (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0'),
      ).join(),
      'expectedDepositCoins': event.deposit,
      'acceptedTermsVersion': event.terms!['version'],
      'attendeeInput': {
        'fullName': fields['fullName']!.trim(),
        'studentId': FptIdentity.studentId(fields['studentId']!),
        'universityEmail': FptIdentity.email(fields['universityEmail']!),
        if (fields['phoneNumber']!.trim().isNotEmpty)
          'phoneNumber': fields['phoneNumber']!.trim(),
      },
    };
    state = Flow1RegistrationState(busy: true, uncertain: recovering);
    final repo = ref.read(flow1RepositoryProvider);
    try {
      Map<String, dynamic>? receipt;
      if (recovering) {
        try {
          receipt = await repo.recoverRegistration(
            _request!['requestId'] as String,
          );
        } on AppException catch (e) {
          if (e.code != 'NOT_FOUND') rethrow;
        }
      }
      receipt ??= await repo.register(_request!);
      if (!ref.mounted ||
          ref.read(authenticationViewModelProvider).asData?.value.userId !=
              uid) {
        return false;
      }
      state = Flow1RegistrationState(success: true, result: receipt);
      unawaited(ref.read(flow1ViewModelProvider.notifier).refresh());
      return true;
    } catch (error) {
      if (!ref.mounted ||
          ref.read(authenticationViewModelProvider).asData?.value.userId !=
              uid) {
        return false;
      }
      final e = ExceptionMapper.map(error);
      final uncertain = [
        'deadline-exceeded',
        'unavailable',
        'timeout',
        'internal',
        'invalid_response',
        'unexpected',
      ].contains(e.code);
      if (!uncertain) _request = null;
      state = Flow1RegistrationState(
        message: e.message,
        errors: {'server': e.code},
        uncertain: uncertain,
      );
      if (['QUOTE_CHANGED', 'TERMS_CHANGED'].contains(e.code)) {
        ref.invalidate(flow1EventProvider(event.id));
      }
      return false;
    }
  }
}
