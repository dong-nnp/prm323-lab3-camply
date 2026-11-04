import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mock/evia_mock_data.dart';
import '../models/evia_models.dart';

class EviaState {
  const EviaState({
    this.interests = EviaMockData.initialInterests,
    this.saved = EviaMockData.initialSaved,
    this.followed = EviaMockData.initialFollowed,
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
  });
  final Set<String> interests, saved, followed;
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
  );
}

final eviaViewModelProvider = NotifierProvider<EviaViewModel, EviaState>(
  EviaViewModel.new,
);

class EviaViewModel extends Notifier<EviaState> {
  @override
  EviaState build() => const EviaState();
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

  void toggleSaved(String id) =>
      state = state.copyWith(saved: _toggle(state.saved, id));
  void toggleFollowed(String id) =>
      state = state.copyWith(followed: _toggle(state.followed, id));
  void removeHistory(String value) => state = state.copyWith(
    history: state.history.where((e) => e != value).toList(),
  );
  void clearHistory() => state = state.copyWith(history: []);
  void updateQuery(String value) =>
      state = state.copyWith(query: value, results: value.trim().isNotEmpty);
  void submitSearch(String value) {
    final query = value.trim();
    state = state.copyWith(
      query: query,
      results: query.isNotEmpty,
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
  void applyFilters() =>
      state = state.copyWith(filters: state.draft, results: true);
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
  List<CampusEvent> get followedEventFeed => EviaMockData.followingEvents
      .where(
        (event) => state.followed.contains(
          event.organizer == 'Student Union' ? 'union' : 'photography',
        ),
      )
      .toList();
  List<CampusEvent> get followingEvents {
    final events = EviaMockData.followingEvents
        .where(
          (event) =>
              (state.organizer == 'All' ||
                  event.organizer == state.organizer) &&
              state.followed.contains(
                event.organizer == 'Student Union' ? 'union' : 'photography',
              ),
        )
        .toList();
    return state.descending ? events.reversed.toList() : events;
  }

  List<CampusOrganizer> get followedOrganizers {
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
    final catalog = <String, CampusEvent>{
      for (final event in [
        EviaMockData.music,
        ...EviaMockData.upcoming,
        ...EviaMockData.followingEvents,
        ...EviaMockData.searchEvents,
      ])
        event.id: event,
    };
    final events = catalog.values.where((event) {
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
    events.sort((a, b) => _start(a).compareTo(_start(b)));
    if (state.descending) return events.reversed.toList();
    return events;
  }

  DateTime _start(CampusEvent event) {
    final date = RegExp(r'^(Oct|Nov) (\d+)').firstMatch(event.date)!;
    final time = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(event.date)!;
    return DateTime(
      2026,
      date[1] == 'Oct' ? 10 : 11,
      int.parse(date[2]!),
      int.parse(time[1]!),
      int.parse(time[2]!),
    );
  }

  bool _matchesDetails(CampusEvent event) {
    final filters = state.filters;
    final start = _start(event);
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
