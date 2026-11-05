import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab03/models/activity_models.dart';
import 'package:prm393_lab03/models/registration_models.dart';
import 'package:prm393_lab03/viewmodels/activity_view_model.dart';
import 'package:prm393_lab03/viewmodels/evia_view_model.dart';
import 'package:prm393_lab03/viewmodels/profile_view_model.dart';
import 'package:prm393_lab03/viewmodels/registration_view_model.dart';

void main() {
  test('guest actions cannot mutate account collections or money', () async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    final evia = c.read(eviaViewModelProvider.notifier);
    final before = c.read(eviaViewModelProvider);
    evia.toggleSaved('guest-event');
    evia.toggleFollowed('guest-organizer');
    expect(c.read(eviaViewModelProvider).saved, before.saved);
    expect(c.read(eviaViewModelProvider).followed, before.followed);
    final profile = c.read(profileViewModelProvider.notifier);
    final saved = c.read(profileViewModelProvider).saved;
    profile.toggleSaved('guest-event');
    expect(c.read(profileViewModelProvider).saved, saved);
    final registration = c.read(registrationViewModelProvider.notifier);
    registration.markGoing();
    expect(await registration.submit(), RegistrationStatus.failed);
    final activity = c.read(activityViewModelProvider.notifier);
    expect(
      activity.addRegistration(
        RegisteredEvent(
          id: 'guest',
          title: 'Guest',
          category: 'Music',
          dateLabel: 'Nov 5',
          venue: 'Public venue',
          start: DateTime(2026, 11, 5),
          coins: 50,
        ),
      ),
      isFalse,
    );
    expect(c.read(activityViewModelProvider).registrations, isEmpty);
    expect(activity.checkIn('EVIA-CLUB-2026'), isFalse);
    expect(activity.redeem('cafe'), isFalse);
    expect(c.read(activityViewModelProvider).available, 420);
  });
}
