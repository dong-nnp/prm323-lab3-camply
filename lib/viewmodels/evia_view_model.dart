import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mock/evia_mock_data.dart';
import '../data/mock/registration_mock_data.dart';
import '../models/evia_models.dart';
import '../models/auth_session.dart';
import '../core/constants/app_routes.dart';
import 'authentication_view_model.dart';
import 'activity_view_model.dart';

class EviaState {
  const EviaState({
    this.interests = EviaMockData.initialInterests,
    this.saved = EviaMockData.initialSaved,
    this.followed = const {},
    this.history = EviaMockData.recentSearches,
    this.query = '',
    this.category = 'All',
    this.filters = const EventFilters(),
    this.draft = const EventFilters(),
    this.results = false,
    this.descending = false,
    this.organizer = 'All',
    this.message,
    this.showPassword = false,
    this.personalizedUsers = const {},
  });
  final Set<String> interests, saved, followed;
  final Set<String> personalizedUsers;
  final List<String> history;
  final String query, category, organizer;
  final EventFilters filters, draft;
  final bool results, descending, showPassword;
  final String? message;
  EviaState copyWith({
    Set<String>? interests,
    Set<String>? saved,
    Set<String>? followed,
    List<String>? history,
    String? query,
    String? category,
    EventFilters? filters,
    EventFilters? draft,
    bool? results,
    bool? descending,
    String? organizer,
    String? message,
    bool? showPassword,
    Set<String>? personalizedUsers,
  }) => EviaState(
    interests: interests ?? this.interests,
    saved: saved ?? this.saved,
    followed: followed ?? this.followed,
    history: history ?? this.history,
    query: query ?? this.query,
    category: category ?? this.category,
    filters: filters ?? this.filters,
    draft: draft ?? this.draft,
    results: results ?? this.results,
    descending: descending ?? this.descending,
    organizer: organizer ?? this.organizer,
    message: message,
    showPassword: showPassword ?? this.showPassword,
    personalizedUsers: personalizedUsers ?? this.personalizedUsers,
  );
}

final eviaViewModelProvider = NotifierProvider<EviaViewModel, EviaState>(
  EviaViewModel.new,
);

class EviaViewModel extends Notifier<EviaState> {
  @override
  EviaState build() {
    ref.watch(
      authenticationViewModelProvider.select(
        (auth) => auth.asData?.value.userId,
      ),
    );
    return const EviaState();
  }

  /// Records an explicit completion/skip for the current real session only.
  /// This UI state does not claim to save a profile to a pending backend.
  String? finishPersonalization({bool skipped = false}) {
    if (!skipped && !canContinue) return null;
    final session = ref.read(authenticationViewModelProvider).asData?.value;
    if (session?.status == AuthStatus.signedIn) {
      state = state.copyWith(
        personalizedUsers: {...state.personalizedUsers, session!.userId!},
      );
      return AppRoutes.discover;
    }
    return AppRoutes.guestDiscover;
  }

  Set<String> _toggle(Set<String> values, String value) =>
      values.contains(value)
      ? ({...values}..remove(value))
      : {...values, value};
  void toggleInterest(String name) =>
      state = state.copyWith(interests: _toggle(state.interests, name));
  bool saveInterests(Set<String> values) {
    if (values.length < 3) return false;
    state = state.copyWith(interests: Set.unmodifiable(values));
    return true;
  }

  void toggleSaved(String id) {
    if (!ref.read(hasAuthenticatedSessionProvider)) {
      state = state.copyWith(message: 'Log in to save events.');
      return;
    }
    state = state.copyWith(saved: _toggle(state.saved, id));
  }

  void toggleFollowed(String id) {
    if (!ref.read(hasAuthenticatedSessionProvider)) {
      state = state.copyWith(message: 'Log in to follow organizers.');
      return;
    }
    state = state.copyWith(followed: _toggle(state.followed, id));
  }

  void removeHistory(String value) => state = state.copyWith(
    history: state.history.where((e) => e != value).toList(),
  );
  void clearHistory() => state = state.copyWith(history: []);
  void updateQuery(String value) => state = state.copyWith(
    query: value,
    results:
        value.trim().isNotEmpty ||
        state.filters.isActive ||
        state.category != 'All',
  );
  void submitSearch(String value) {
    final query = value.trim();
    state = state.copyWith(
      query: query,
      results:
          query.isNotEmpty || state.filters.isActive || state.category != 'All',
      history: query.isEmpty
          ? state.history
          : [query, ...state.history.where((e) => e != query)].take(5).toList(),
    );
  }

  void showSearch({bool referenceResults = false}) => state = state.copyWith(
    query: referenceResults ? 'workshop' : '',
    results: referenceResults,
    category: 'All',
    filters: referenceResults
        ? const EventFilters(date: 'Next week', audience: 'University Students')
        : const EventFilters(),
  );
  void selectCategory(String category) => state = state.copyWith(
    category: category,
    results:
        category != 'All' || state.query.isNotEmpty || state.filters.isActive,
  );
  void selectOrganizer(String organizer) =>
      state = state.copyWith(organizer: organizer);
  void toggleSort() => state = state.copyWith(descending: !state.descending);
  void beginFilters() => state = state.copyWith(draft: state.filters);
  void selectFilter(String group, String value) =>
      state = state.copyWith(draft: state.draft.withValue(group, value));
  void selectDateRange(DateTime start, DateTime end) =>
      state = state.copyWith(draft: state.draft.withRange(start, end));
  void setEligible(bool value) =>
      state = state.copyWith(draft: state.draft.withEligibility(value));
  void resetDraft() => state = state.copyWith(draft: const EventFilters());
  void applyFilters() => state = state.copyWith(
    filters: state.draft,
    category: 'All',
    results: true,
  );
  void clearFilters() => state = state.copyWith(
    filters: const EventFilters(),
    draft: const EventFilters(),
    category: 'All',
  );
  void removeFilter(String key) => state = state.copyWith(
    filters: state.filters.withValue(
      key,
      key == 'Date' ? 'Any date' : 'Any audience',
    ),
  );
  void togglePassword() =>
      state = state.copyWith(showPassword: !state.showPassword);
  bool get canContinue => state.interests.length >= 3;
  List<CampusEvent> get registeredEvents {
    if (!ref.read(hasAuthenticatedSessionProvider)) return [];
    final activity = ref.read(activityViewModelProvider);
    final registered =
        activity.registrations
            .where(
              (event) =>
                  !event.waitlisted &&
                  !event.walkIn &&
                  !activity.cancelled.contains(event.id),
            )
            .toList()
          ..sort((a, b) => a.start.compareTo(b.start));
    final events = [
      for (final event in registered)
        CampusEvent(
          id: event.id,
          detailKey: event.detailKey,
          title: event.title,
          category: event.category,
          date: event.dateLabel,
          location: event.venue,
          organizer: RegistrationMockData.findEvent(event.detailKey)?.organizer,
          policy: 'Registered',
          coins: event.coins,
          image: event.image,
        ),
    ];
    return state.descending ? events.reversed.toList() : events;
  }

  List<CampusEvent> get followingEvents => registeredEvents
      .where(
        (event) =>
            state.organizer == 'All' || event.organizer == state.organizer,
      )
      .toList();

  List<CampusOrganizer> get followedOrganizers {
    if (!ref.read(hasAuthenticatedSessionProvider)) return [];
    final organizers = [
      ...EviaMockData.organizers,
      ...EviaMockData.recommendations,
    ].where((o) => state.followed.contains(o.id)).toList();
    return state.descending ? organizers.reversed.toList() : organizers;
  }

  List<CampusOrganizer> get suggestedOrganizers => EviaMockData.organizers
      .where((o) => !state.followed.contains(o.id))
      .toList();
  void login(String email, String password) => state = state.copyWith(
    message: !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email.trim())
        ? 'Please enter a valid email address.'
        : password.isEmpty
        ? 'Please enter your password.'
        : 'Sign-in is currently unavailable. Use Skip to explore.',
  );

  List<CampusEvent> get searchResults {
    final events = EviaMockData.catalog.where((event) {
      final q = state.query.toLowerCase().trim();
      final matchesQuery =
          q.isEmpty ||
          '${event.title} ${event.category} ${event.location} ${event.keywords} ${event.organizer ?? ''}'
              .toLowerCase()
              .contains(q);
      final category = state.category != 'All'
          ? state.category
          : state.filters.category;
      return matchesQuery &&
          (category == 'All' ||
              event.category.toLowerCase() == category.toLowerCase() ||
              (category == 'Workshop' &&
                  '${event.title} ${event.keywords}'.toLowerCase().contains(
                    'workshop',
                  ))) &&
          (state.filters.policy == 'Any' ||
              event.policy.toLowerCase() ==
                  state.filters.policy.toLowerCase()) &&
          _matchesDetails(event);
    }).toList();
    events.sort(
      (a, b) => EviaMockData.startOf(a).compareTo(EviaMockData.startOf(b)),
    );
    if (state.descending) return events.reversed.toList();
    return events;
  }

  bool _matchesDetails(CampusEvent event) {
    final filters = state.filters;
    final start = EviaMockData.startOf(event);
    final anchor = EviaMockData.referenceDate;
    final weekEnd = anchor.add(const Duration(days: 7));
    final matchesDate = switch (filters.date) {
      'This week' => !start.isBefore(anchor) && start.isBefore(weekEnd),
      'Next week' =>
        !start.isBefore(weekEnd) &&
            start.isBefore(weekEnd.add(const Duration(days: 7))),
      'This month' => start.month == anchor.month,
      'Next month' => start.month == anchor.month + 1,
      'Custom range' =>
        filters.rangeStart != null &&
            filters.rangeEnd != null &&
            !start.isBefore(filters.rangeStart!) &&
            start.isBefore(filters.rangeEnd!.add(const Duration(days: 1))),
      _ => true,
    };
    final matchesTime = switch (filters.time) {
      'Morning' => start.hour < 12,
      'Afternoon' => start.hour >= 12 && start.hour < 18,
      'Evening' => start.hour >= 18,
      _ => true,
    };
    final matchesAudience = switch (filters.audience) {
      'Any audience' => true,
      'Students from Any University' ||
      'University Students' => event.audience == 'University Students',
      'Open to Everyone' => event.audience == 'Open to Public',
      _ => false,
    };
    final matchesAvailability = switch (filters.availability) {
      'Any' => true,
      'Waitlist Available' => event.policy == 'Waitlist available',
      'Spots Available' => event.note == '120 spots left',
      _ => false,
    };
    // No duration or verified-student data was supplied by these nine frames.
    // Unknown metadata must not falsely satisfy an active filter.
    return matchesDate &&
        matchesTime &&
        matchesAudience &&
        matchesAvailability &&
        filters.duration == 'Any duration' &&
        !filters.eligibleOnly;
  }
}
