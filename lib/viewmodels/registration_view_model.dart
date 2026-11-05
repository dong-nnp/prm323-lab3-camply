import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mock/registration_mock_data.dart';
import '../core/utils/fpt_identity.dart';
import '../models/registration_models.dart';
import '../models/activity_models.dart';
import 'activity_view_model.dart';
import 'authentication_view_model.dart';
import '../core/providers/service_providers.dart';
import '../models/flow1_models.dart';
import 'flow1_view_model.dart';

class RegistrationState {
  const RegistrationState({
    this.name = RegistrationMockData.name,
    this.studentId = RegistrationMockData.studentId,
    this.email = RegistrationMockData.email,
    this.phone = RegistrationMockData.phone,
    this.agreed = true,
    this.errors = const {},
    this.status = RegistrationStatus.idle,
    this.eventId = 'music-live',
    this.message,
  });
  final String name, studentId, email, phone, eventId;
  final bool agreed;
  final Map<String, String> errors;
  final RegistrationStatus status;
  final String? message;
  RegistrationState copy({
    String? name,
    String? studentId,
    String? email,
    String? phone,
    bool? agreed,
    Map<String, String>? errors,
    RegistrationStatus? status,
    String? eventId,
    String? message,
  }) => RegistrationState(
    name: name ?? this.name,
    studentId: studentId ?? this.studentId,
    email: email ?? this.email,
    phone: phone ?? this.phone,
    agreed: agreed ?? this.agreed,
    errors: errors ?? this.errors,
    status: status ?? this.status,
    eventId: eventId ?? this.eventId,
    message: message,
  );
}

final registrationDelayProvider = Provider<Duration>(
  (ref) => const Duration(milliseconds: 700),
);
final registrationViewModelProvider =
    NotifierProvider<RegistrationViewModel, RegistrationState>(
      RegistrationViewModel.new,
    );

class RegistrationViewModel extends Notifier<RegistrationState> {
  int _generation = 0;
  ProviderSubscription<Flow1RegistrationState>? _requestSubscription;
  bool get live => ref.read(realBackendEnabledProvider);
  bool get pendingConfirmation =>
      live &&
      state.eventId.isNotEmpty &&
      ref.read(flow1RegistrationProvider(state.eventId)).uncertain;
  @override
  RegistrationState build() {
    if (!ref.read(realBackendEnabledProvider)) {
      ref.watch(
        authenticationViewModelProvider.select(
          (auth) => auth.asData?.value.userId,
        ),
      );
    }
    ref.onDispose(() {
      _generation++;
      _requestSubscription?.close();
    });
    if (ref.watch(realBackendEnabledProvider)) {
      ref.listen(authenticationViewModelProvider, (previous, next) {
        if (previous?.asData?.value.userId != next.asData?.value.userId) {
          _generation++;
          _requestSubscription?.close();
          state = const RegistrationState(
            name: '',
            studentId: '',
            email: '',
            phone: '',
            agreed: false,
            eventId: '',
          );
        }
      });
      return const RegistrationState(
        name: '',
        studentId: '',
        email: '',
        phone: '',
        agreed: false,
        eventId: '',
      );
    }
    return const RegistrationState();
  }

  Flow1Event remoteEvent(String id) {
    final data = ref.read(flow1ViewModelProvider).requireValue;
    return ref.read(flow1EventProvider(id)).asData?.value ??
        data.events.firstWhere((e) => e.id == id);
  }

  EventPresentation? findEvent(String id) {
    if (!live) return RegistrationMockData.findEvent(id);
    final data = ref.read(flow1ViewModelProvider).asData?.value;
    final event =
        ref.read(flow1EventProvider(id)).asData?.value ??
        data?.events.where((event) => event.id == id).firstOrNull;
    return event?.presentation(
      data?.organizerName(event.organizerId) ?? 'Organizer',
    );
  }

  EventPresentation event(String id) =>
      findEvent(id) ??
      (live
          ? (throw StateError('Event not found: $id'))
          : RegistrationMockData.music);

  void preset(String view, String eventId) {
    if (live) {
      final profile = ref.read(flow1ViewModelProvider).requireValue.profile;
      _requestSubscription?.close();
      _requestSubscription = ref.listen(
        flow1RegistrationProvider(eventId),
        (_, _) {},
      );
      state = RegistrationState(
        name: profile['displayName'] as String? ?? '',
        studentId: profile['studentId'] as String? ?? '',
        email: profile['universityEmail'] as String? ?? '',
        phone: profile['phoneNumber'] as String? ?? '',
        agreed: false,
        eventId: eventId,
      );
      return;
    }
    if (view == 'legacy-error') {
      state = RegistrationState(
        name: '',
        studentId: '',
        email: 'alex@gmail.com',
        phone: '',
        agreed: false,
        eventId: eventId,
      );
      validate(legacy: true);
    } else if (view == 'error') {
      state = RegistrationState(
        name: '',
        studentId: 'STU-INVALID',
        email: 'alex@gmail.com',
        agreed: false,
        eventId: eventId,
      );
      validate();
    } else {
      state = RegistrationState(
        eventId: eventId,
        phone: view == 'legacy' ? '' : RegistrationMockData.phone,
        agreed: view != 'legacy',
      );
    }
  }

  void edit(String field, String value) {
    final errors = {...state.errors}..remove(field);
    state = state.copy(
      name: field == 'name' ? value : null,
      studentId: field == 'studentId' ? value : null,
      email: field == 'email' ? value : null,
      phone: field == 'phone' ? value : null,
      errors: errors,
    );
  }

  void agree(bool value) => state = state.copy(
    agreed: value,
    errors: {...state.errors}..remove('terms'),
  );
  bool validate({bool legacy = false}) {
    final errors = <String, String>{};
    if (state.name.trim().isEmpty) {
      errors['name'] = 'Please enter your full name.';
    }
    if (state.studentId.trim().isEmpty) {
      errors['studentId'] = legacy
          ? 'Student ID is required.'
          : 'Please enter a valid student ID.';
    } else if (!FptIdentity.validStudentId(state.studentId)) {
      errors['studentId'] = 'Please enter a valid student ID.';
    }
    if (!FptIdentity.validEmail(state.email)) {
      errors['email'] = legacy
          ? 'Enter a valid email address.'
          : 'Enter a valid email address.';
    }
    if (state.phone.trim().isNotEmpty &&
        (live
            ? !RegExp(r'^\+?[0-9 ()-]{7,24}$').hasMatch(state.phone)
            : state.phone.replaceAll(RegExp(r'\D'), '').length < 8)) {
      errors['phone'] = 'Please enter a valid phone number.';
    }
    if (!state.agreed) {
      final deposit = findEvent(state.eventId)?.deposit ?? 0;
      errors['terms'] = deposit > 0
          ? 'Please accept the registration and deposit terms.'
          : 'Please accept the registration terms.';
    }
    state = state.copy(errors: errors);
    return errors.isEmpty;
  }

  Future<RegistrationStatus> submit({
    RegistrationOutcome outcome = RegistrationOutcome.success,
  }) async {
    if (!ref.read(hasAuthenticatedSessionProvider)) {
      state = state.copy(
        status: RegistrationStatus.failed,
        message: 'Log in to register for events.',
      );
      return state.status;
    }
    if (state.status == RegistrationStatus.loading) return state.status;
    if (!validate()) return RegistrationStatus.idle;
    if (live) {
      final generation = _generation;
      final uid = ref
          .read(authenticationViewModelProvider)
          .asData
          ?.value
          .userId;
      final id = state.eventId;
      final input = {
        'fullName': state.name,
        'studentId': state.studentId,
        'universityEmail': state.email,
        'phoneNumber': state.phone,
      };
      final agreed = state.agreed;
      state = state.copy(status: RegistrationStatus.loading);
      final done = await ref
          .read(flow1RegistrationProvider(id).notifier)
          .submit(remoteEvent(id), input, agreed);
      if (!ref.mounted ||
          generation != _generation ||
          ref.read(authenticationViewModelProvider).asData?.value.userId !=
              uid) {
        return RegistrationStatus.idle;
      }
      final result = ref.read(flow1RegistrationProvider(id));
      final status = done
          ? RegistrationStatus.success
          : result.errors['server'] == 'EVENT_FULL'
          ? RegistrationStatus.full
          : RegistrationStatus.failed;
      state = state.copy(
        status: status,
        message: result.message,
        agreed:
            ['QUOTE_CHANGED', 'TERMS_CHANGED'].contains(result.errors['server'])
            ? false
            : null,
      );
      return status;
    }
    final selected = findEvent(state.eventId);
    if (selected == null) {
      state = state.copy(
        status: RegistrationStatus.failed,
        message: 'Event not found.',
      );
      return state.status;
    }
    final generation = _generation;
    state = state.copy(status: RegistrationStatus.loading);
    await Future<void>.delayed(ref.read(registrationDelayProvider));
    if (!ref.mounted || generation != _generation) {
      return RegistrationStatus.idle;
    }
    if (outcome != RegistrationOutcome.success) {
      final status = outcome == RegistrationOutcome.failed
          ? RegistrationStatus.failed
          : RegistrationStatus.full;
      state = state.copy(status: status);
      return status;
    }
    final activity = ref.read(activityViewModelProvider.notifier);
    final added = activity.addRegistration(
      RegisteredEvent(
        id: selected.id,
        detailKey: state.eventId,
        title: selected.title,
        category: selected.category,
        dateLabel: '${selected.date} · ${selected.time}',
        venue: selected.venue,
        start: selected.start,
        coins: selected.coins,
        image: selected.image,
      ),
      deposit: selected.deposit,
    );
    if (!added) {
      state = state.copy(
        status: RegistrationStatus.failed,
        message:
            ref.read(activityViewModelProvider).message ??
            ActivityViewModel.coinServiceMessage,
      );
      return state.status;
    }
    state = state.copy(status: RegistrationStatus.success);
    return state.status;
  }

  void backToForm() => state = state.copy(status: RegistrationStatus.idle);
  Future<bool> markGoing([String? eventId]) async {
    if (!ref.read(hasAuthenticatedSessionProvider)) return false;
    if (live) {
      final id = eventId ?? state.eventId;
      final result = await ref.read(flow1ViewModelProvider.notifier).going(id);
      if (!ref.mounted) return false;
      if (result) {
        state = state.copy(status: RegistrationStatus.going, eventId: id);
      }
      return result;
    }
    final selected = findEvent(eventId ?? 'club-live');
    if (selected == null || !selected.walkIn) return false;
    ref
        .read(activityViewModelProvider.notifier)
        .addRegistration(
          RegisteredEvent(
            id: selected.id,
            detailKey: eventId,
            title: selected.title,
            category: selected.category,
            dateLabel: '${selected.date} · ${selected.time}',
            venue: selected.venue,
            start: selected.start,
            image: selected.image,
            coins: selected.coins,
            walkIn: true,
          ),
        );
    state = state.copy(status: RegistrationStatus.going, eventId: selected.id);
    return true;
  }
}
