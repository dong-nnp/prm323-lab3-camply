import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mock/registration_mock_data.dart';
import '../core/utils/fpt_identity.dart';
import '../models/registration_models.dart';
import 'evia_view_model.dart';
import 'authentication_view_model.dart';
import '../core/providers/service_providers.dart';
import '../core/providers/repository_providers.dart';
import '../core/utils/exception_mapper.dart';
import '../firebase/firebase_configuration.dart';
import '../models/flow1_models.dart';
import 'flow1_view_model.dart';

final notificationsViewModelProvider =
    AsyncNotifierProvider.autoDispose<
      NotificationsViewModel,
      List<Map<String, dynamic>>
    >(NotificationsViewModel.new);

class NotificationsViewModel extends AsyncNotifier<List<Map<String, dynamic>>> {
  bool busy = false;
  @override
  Future<List<Map<String, dynamic>>> build() async {
    final session = ref.watch(authenticationViewModelProvider).asData?.value;
    if (session?.userId == null) return [];
    // shortcut: refresh inbox while open; replace polling with FCM invalidation when push is connected.
    final timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!busy) ref.invalidateSelf();
    });
    ref.onDispose(timer.cancel);
    return ref.watch(flow1RepositoryProvider).notifications();
  }

  Future<bool> markRead(List<String> ids) async {
    if (ids.isEmpty) return true;
    if (busy) return false;
    busy = true;
    final uid = ref.read(authenticationViewModelProvider).asData?.value.userId;
    try {
      await ref.read(flow1RepositoryProvider).readNotifications(ids);
      if (!ref.mounted ||
          ref.read(authenticationViewModelProvider).asData?.value.userId !=
              uid) {
        return false;
      }
      ref.invalidateSelf();
      return true;
    } finally {
      busy = false;
    }
  }
}

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
  bool _crashTestInProgress = false;

  Future<String?> triggerTestCrash() async {
    if (!FirebaseConfiguration.crashTestEnabled || _crashTestInProgress) {
      return null;
    }
    _crashTestInProgress = true;
    try {
      await ref.read(bootstrapRepositoryProvider).triggerTestCrash();
      return null;
    } catch (error) {
      return ExceptionMapper.map(error).message;
    } finally {
      _crashTestInProgress = false;
    }
  }

  @override
  ProfileState build() {
    if (!ref.watch(realBackendEnabledProvider)) {
      return ProfileState(
        draftInterests: ref.read(eviaViewModelProvider).interests,
      );
    }
    ref.listen(flow1ViewModelProvider, (_, next) {
      final data = next.asData?.value;
      state = state.copy(
        name: data?.profile['displayName'] as String? ?? '',
        studentId: data?.profile['studentId'] as String? ?? '',
        email: data?.profile['universityEmail'] as String? ?? '',
        saved: data?.saved ?? {},
      );
    });
    final data = ref.read(flow1ViewModelProvider).asData?.value;
    return ProfileState(
      name: data?.profile['displayName'] as String? ?? '',
      studentId: data?.profile['studentId'] as String? ?? '',
      email: data?.profile['universityEmail'] as String? ?? '',
      saved: data?.saved ?? {},
      draftInterests: ref.read(eviaViewModelProvider).interests,
    );
  }

  Future<bool> toggleSaved(String id) async {
    if (!ref.read(hasAuthenticatedSessionProvider)) {
      state = state.copy(message: 'Log in to save events.');
      return false;
    }
    if (ref.read(realBackendEnabledProvider)) {
      return ref.read(eviaViewModelProvider.notifier).toggleSaved(id);
    }
    state = state.copy(
      saved: state.saved.contains(id)
          ? ({...state.saved}..remove(id))
          : {...state.saved, id},
    );
    return true;
  }

  void filterSaved(String filter) => state = state.copy(savedFilter: filter);
  List<SavedEventPresentation> get _savedCatalog {
    if (!ref.read(realBackendEnabledProvider)) {
      return RegistrationMockData.saved;
    }
    final data = ref.read(flow1ViewModelProvider).asData?.value;
    return data?.events
            .map(
              (e) => SavedEventPresentation(
                e.presentation(data.organizerName(e.organizerId)),
                eventDate(e.start),
                data.organizerName(e.organizerId),
                RegistrationMockData.saved.first.image,
              ),
            )
            .toList() ??
        [];
  }

  int savedCount(String filter) => _savedCatalog
      .where(
        (entry) =>
            state.saved.contains(entry.event.id) &&
            (filter == 'All' || (filter == 'Past') == entry.event.past),
      )
      .length;
  List<SavedEventPresentation> get visibleSaved => _savedCatalog
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
  Future<bool> persistInterests() async {
    final vm = ref.read(eviaViewModelProvider.notifier);
    if (!ref.read(realBackendEnabledProvider)) {
      vm.setInterests(state.draftInterests);
      state = state.copy(message: 'Preferences saved.');
      return true;
    }
    final result = await vm.finishPersonalization(
      interests: state.draftInterests,
    );
    if (!ref.mounted) return false;
    state = state.copy(
      message: result == null
          ? ref.read(eviaViewModelProvider).message
          : 'Preferences saved.',
    );
    return result != null;
  }

  bool isUnread(ProfileNotice notice) =>
      notice.unread && !state.read.contains(notice.id);
  List<ProfileNotice> get notices {
    if (!ref.read(realBackendEnabledProvider)) {
      return RegistrationMockData.notices;
    }
    final today = vietnamTime(DateTime.now());
    final mine = ref.read(flow1ViewModelProvider).asData?.value.myEvents ?? [];
    return (ref.read(notificationsViewModelProvider).asData?.value ?? []).map((
      n,
    ) {
      final created = vietnamTime(DateTime.parse(n['createdAt'] as String));
      String? destination;
      if (n['entityType'] == 'event') {
        destination = Uri(
          path: '/event/about',
          queryParameters: {'event': n['entityId'] as String},
        ).toString();
      } else if (n['entityType'] == 'ticket') {
        final row = mine
            .where(
              (m) =>
                  m['registration'] != null &&
                  jsonMap(m['registration'])['ticketId'] == n['entityId'],
            )
            .firstOrNull;
        destination = row == null
            ? '/my-events'
            : Uri(
                path: '/my-events/ticket',
                queryParameters: {
                  'event': jsonMap(row['event'])['id'] as String,
                },
              ).toString();
      }
      return ProfileNotice(
        n['id'] as String,
        n['title'] as String,
        n['body'] as String,
        eventDate(DateTime.parse(n['createdAt'] as String)),
        n['type'] == 'registration_confirmed'
            ? 0
            : n['type'] == 'new_event'
            ? 1
            : 2,
        unread: n['readAt'] == null,
        today:
            created.year == today.year &&
            created.month == today.month &&
            created.day == today.day,
        destination: destination,
      );
    }).toList();
  }

  int get unreadCount => notices.where(isUnread).length;
  Future<bool> readNotice(String id) async => _readNotices([id]);
  Future<bool> markAllRead() async =>
      _readNotices(notices.where(isUnread).map((n) => n.id).toList());
  Future<bool> _readNotices(List<String> ids) async {
    if (!ref.read(realBackendEnabledProvider)) {
      state = state.copy(read: {...state.read, ...ids});
      return true;
    }
    try {
      return await ref
          .read(notificationsViewModelProvider.notifier)
          .markRead(ids);
    } catch (error) {
      if (ref.mounted) {
        state = state.copy(message: ExceptionMapper.map(error).message);
      }
      return false;
    }
  }

  void organizerTab(bool past) => state = state.copy(organizerPast: past);
  void toggleOrganizerDescription() =>
      state = state.copy(expandedOrganizer: !state.expandedOrganizer);
  Future<bool> updateProfile(String name, String id, String email) async {
    if (name.trim().isEmpty ||
        !FptIdentity.validStudentId(id) ||
        !FptIdentity.validEmail(email)) {
      state = state.copy(
        message: 'Enter your name, student ID and a valid email.',
      );
      return false;
    }
    if (ref.read(realBackendEnabledProvider)) {
      try {
        await ref.read(flow1RepositoryProvider).updateProfile({
          'displayName': name.trim(),
          'studentId': FptIdentity.studentId(id),
          'universityEmail': FptIdentity.email(email),
        });
        await ref.read(flow1ViewModelProvider.notifier).refresh();
        return ref.mounted && !ref.read(flow1ViewModelProvider).hasError;
      } catch (error) {
        if (ref.mounted) {
          state = state.copy(message: ExceptionMapper.map(error).message);
        }
        return false;
      }
    }
    state = state.copy(
      name: name.trim(),
      studentId: FptIdentity.studentId(id),
      email: FptIdentity.email(email),
    );
    return true;
  }
}
