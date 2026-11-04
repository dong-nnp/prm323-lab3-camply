import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mock/registration_mock_data.dart';
import '../models/registration_models.dart';
import '../models/activity_models.dart';
import 'activity_view_model.dart';

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
  @override
  RegistrationState build() {
    ref.onDispose(() => _generation++);
    return const RegistrationState();
  }

  EventPresentation event(String id) => [
    RegistrationMockData.music,
    RegistrationMockData.club,
    RegistrationMockData.innovation,
    RegistrationMockData.arts,
    RegistrationMockData.leadership,
  ].firstWhere((e) => e.id == id, orElse: () => RegistrationMockData.music);
  void preset(String view, String eventId) {
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
    } else if (!RegExp(r'^STU-\d{6}$').hasMatch(state.studentId.trim())) {
      errors['studentId'] = 'Please enter a valid student ID.';
    }
    if (!RegExp(
      r'^[^\s@]+@[^\s@]+\.(edu|edu\.vn)$',
      caseSensitive: false,
    ).hasMatch(state.email.trim())) {
      errors['email'] = legacy
          ? 'Please enter a valid university email address.'
          : 'Please enter a valid university email.';
    }
    if (state.phone.trim().isNotEmpty &&
        state.phone.replaceAll(RegExp(r'\D'), '').length < 8) {
      errors['phone'] = 'Please enter a valid phone number.';
    }
    if (!state.agreed) {
      errors['terms'] = 'Please accept the registration and deposit terms.';
    }
    state = state.copy(errors: errors);
    return errors.isEmpty;
  }

  Future<RegistrationStatus> submit({
    RegistrationOutcome outcome = RegistrationOutcome.success,
  }) async {
    if (state.status == RegistrationStatus.loading) return state.status;
    if (!validate()) return RegistrationStatus.idle;
    final selected = event(state.eventId);
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
        title: selected.title,
        category: selected.category,
        dateLabel: '${selected.date} · ${selected.time}',
        venue: selected.venue,
        start: selected.start,
        coins: selected.coins,
      ),
      deposit: selected.deposit,
    );
    if (!added) {
      state = state.copy(
        status: RegistrationStatus.failed,
        message: ActivityViewModel.coinServiceMessage,
      );
      return state.status;
    }
    state = state.copy(status: RegistrationStatus.success);
    return state.status;
  }

  void backToForm() => state = state.copy(status: RegistrationStatus.idle);
  void markGoing() {
    final selected = RegistrationMockData.club;
    ref
        .read(activityViewModelProvider.notifier)
        .addRegistration(
          RegisteredEvent(
            id: selected.id,
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
  }

  void joinWaitlist() {
    final selected = event(state.eventId);
    ref
        .read(activityViewModelProvider.notifier)
        .addRegistration(
          RegisteredEvent(
            id: '${selected.id}-waitlist',
            title: selected.title,
            category: selected.category,
            dateLabel: '${selected.date} · ${selected.time}',
            venue: selected.venue,
            start: selected.start,
            waitlisted: true,
          ),
        );
  }
}
