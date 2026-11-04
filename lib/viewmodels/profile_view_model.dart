import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mock/registration_mock_data.dart';
import '../models/registration_models.dart';
import 'evia_view_model.dart';

class ProfileState {
  const ProfileState({
    this.name = RegistrationMockData.name,
    this.studentId = RegistrationMockData.profileStudentId,
    this.email = RegistrationMockData.email,
    this.saved = RegistrationMockData.savedIds,
    this.savedFilter = 'All',
    this.read = const {},
    this.draftInterests = const {},
    this.organizerPast = false,
    this.expandedOrganizer = false,
    this.message,
  });
  final String name, studentId, email, savedFilter;
  final Set<String> saved, read, draftInterests;
  final bool organizerPast, expandedOrganizer;
  final String? message;
  ProfileState copy({
    String? name,
    String? studentId,
    String? email,
    Set<String>? saved,
    String? savedFilter,
    Set<String>? read,
    Set<String>? draftInterests,
    bool? organizerPast,
    bool? expandedOrganizer,
    String? message,
  }) => ProfileState(
    name: name ?? this.name,
    studentId: studentId ?? this.studentId,
    email: email ?? this.email,
    saved: saved ?? this.saved,
    savedFilter: savedFilter ?? this.savedFilter,
    read: read ?? this.read,
    draftInterests: draftInterests ?? this.draftInterests,
    organizerPast: organizerPast ?? this.organizerPast,
    expandedOrganizer: expandedOrganizer ?? this.expandedOrganizer,
    message: message,
  );
}

final profileViewModelProvider =
    NotifierProvider<ProfileViewModel, ProfileState>(ProfileViewModel.new);

class ProfileViewModel extends Notifier<ProfileState> {
  @override
  ProfileState build() =>
      ProfileState(draftInterests: ref.read(eviaViewModelProvider).interests);
  void toggleSaved(String id) => state = state.copy(
    saved: state.saved.contains(id)
        ? ({...state.saved}..remove(id))
        : {...state.saved, id},
  );
  void filterSaved(String filter) => state = state.copy(savedFilter: filter);
  int savedCount(String filter) => RegistrationMockData.saved
      .where(
        (entry) =>
            state.saved.contains(entry.event.id) &&
            (filter == 'All' || (filter == 'Past') == entry.event.past),
      )
      .length;
  List<SavedEventPresentation> get visibleSaved => RegistrationMockData.saved
      .where(
        (entry) =>
            state.saved.contains(entry.event.id) &&
            (state.savedFilter == 'All' ||
                (state.savedFilter == 'Past') == entry.event.past),
      )
      .toList();
  void beginInterests() => state = state.copy(
    draftInterests: {...ref.read(eviaViewModelProvider).interests},
  );
  void toggleInterest(String interest) => state = state.copy(
    draftInterests: state.draftInterests.contains(interest)
        ? ({...state.draftInterests}..remove(interest))
        : {...state.draftInterests, interest},
  );
  bool saveInterests() {
    final success = ref
        .read(eviaViewModelProvider.notifier)
        .saveInterests(state.draftInterests);
    state = state.copy(
      message: success ? 'Preferences saved.' : 'Select at least 3 interests.',
    );
    return success;
  }

  bool isUnread(ProfileNotice notice) =>
      notice.unread && !state.read.contains(notice.id);
  int get unreadCount => RegistrationMockData.notices.where(isUnread).length;
  void readNotice(String id) => state = state.copy(read: {...state.read, id});
  void markAllRead() => state = state.copy(
    read: RegistrationMockData.notices.map((n) => n.id).toSet(),
  );
  void organizerTab(bool past) => state = state.copy(organizerPast: past);
  void toggleOrganizerDescription() =>
      state = state.copy(expandedOrganizer: !state.expandedOrganizer);
  bool updateProfile(String name, String id, String email) {
    if (name.trim().isEmpty ||
        id.trim().isEmpty ||
        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      state = state.copy(
        message: 'Enter your name, student ID and a valid email.',
      );
      return false;
    }
    state = state.copy(
      name: name.trim(),
      studentId: id.trim(),
      email: email.trim(),
    );
    return true;
  }
}
