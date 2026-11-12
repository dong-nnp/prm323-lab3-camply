import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mock/evia_mock_data.dart';
import '../core/providers/repository_providers.dart';
import '../core/utils/exception_mapper.dart';
import '../data/mock/registration_mock_data.dart';
import '../models/analytics_events.dart';
import '../models/evia_models.dart';
import '../models/auth_session.dart';
import '../core/constants/app_routes.dart';
import '../core/utils/fpt_identity.dart';
import 'authentication_view_model.dart';
import '../core/providers/service_providers.dart';
import '../models/flow1_models.dart';
import 'flow1_view_model.dart';
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
    this.isLoggingIn = false,
    this.isSavingInterests = false,
    this.personalizedUsers = const {},
  });
  final Set<String> interests, saved, followed;
  final Set<String> personalizedUsers;
  final List<String> history;
  final String query, category, organizer;
  final EventFilters filters, draft;
  final bool results, descending, showPassword;
  final String? message;
  final bool isLoggingIn;
  final bool isSavingInterests;
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
    bool? isLoggingIn,
    bool? isSavingInterests,
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
    isLoggingIn: isLoggingIn ?? this.isLoggingIn,
    isSavingInterests: isSavingInterests ?? this.isSavingInterests,
    personalizedUsers: personalizedUsers ?? this.personalizedUsers,
  );
}

final eviaViewModelProvider = NotifierProvider<EviaViewModel, EviaState>(
  EviaViewModel.new,
);

class EviaViewModel extends Notifier<EviaState> {
  Future<void> refresh() async {
    if (live) await ref.read(flow1ViewModelProvider.notifier).refresh();
  }

  bool get live => ref.read(realBackendEnabledProvider);
  Flow1Snapshot? get catalog =>
      live ? ref.read(flow1ViewModelProvider).asData?.value : null;
  static const interestIds = {
    'Technology': 'technology',
    'Music': 'music',
    'Arts': 'arts',
    'Sports': 'sports',
    'Photography': 'photography',
    'Career': 'career',
    'Volunteering': 'volunteer',
    'Business': 'business',
    'Gaming': 'gaming',
    'Environment': 'environment',
  };
  Set<String> _interestNames(Flow1Snapshot? data) => interestIds.entries
      .where((e) => data?.selectedInterests.contains(e.value) ?? false)
      .map((e) => e.key)
      .toSet();
  ProviderSubscription<AsyncValue<List<Flow1Event>>>? _searchSub;
  int _searchNonce = 0;

  @override
  EviaState build() {
    ref.onDispose(() {
      _searchSub?.close();
      _searchSub = null;
      _searchNonce++;
    });
    if (!ref.read(realBackendEnabledProvider)) {
      ref.watch(
        authenticationViewModelProvider.select(
          (auth) => auth.asData?.value.userId,
        ),
      );
    }
    if (!ref.watch(realBackendEnabledProvider)) return const EviaState();
    ref.listen(flow1ViewModelProvider, (_, next) {
      final data = next.asData?.value;
      state = state.copyWith(
        saved: data?.saved ?? {},
        followed: data?.followed ?? {},
        interests: _interestNames(data),
        message: data?.actionError,
      );
    });
    return EviaState(
      saved: catalog?.saved ?? {},
      followed: catalog?.followed ?? {},
      interests: _interestNames(catalog),
      history: const [],
    );
  }

  Future<String?> finishPersonalization() async {
    if (!canContinue || state.isSavingInterests) return null;
    final session = ref.read(authenticationViewModelProvider).asData?.value;
    if (session?.status != AuthStatus.signedIn) {
      state = state.copyWith(message: 'Log in before saving your interests.');
      return null;
    }
    state = state.copyWith(isSavingInterests: true);
    try {
      if (live) {
        final ids = state.interests.map((name) => interestIds[name]!).toSet();
        // Preserve server interests unknown to this app when saving preferences.
        ids.addAll(
          (catalog?.selectedInterests ?? {}).where(
            (id) => !interestIds.containsValue(id),
          ),
        );
        await ref.read(flow1RepositoryProvider).saveInterests(ids);
        await ref.read(flow1ViewModelProvider.notifier).refresh();
        if (ref.read(flow1ViewModelProvider).hasError) {
          throw ref.read(flow1ViewModelProvider).error!;
        }
      } else {
        await ref
            .read(campusRepositoryProvider)
            .saveInterests(Set.unmodifiable(state.interests));
      }
      if (!ref.mounted ||
          ref.read(authenticationViewModelProvider).asData?.value.userId !=
              session!.userId) {
        return null;
      }
      state = state.copyWith(
        personalizedUsers: {...state.personalizedUsers, session.userId!},
        isSavingInterests: false,
      );
      return AppRoutes.discover;
    } catch (error) {
      if (ref.mounted) {
        state = state.copyWith(
          isSavingInterests: false,
          message: ExceptionMapper.map(error).message,
        );
      }
      return null;
    } finally {
      if (ref.mounted && state.isSavingInterests) {
        state = state.copyWith(
          isSavingInterests: false,
          message: state.message,
        );
      }
    }
  }

  Set<String> _toggle(Set<String> values, String value) =>
      values.contains(value)
      ? ({...values}..remove(value))
      : {...values, value};
  void toggleInterest(String name) {
    if (!state.isSavingInterests) {
      state = state.copyWith(interests: _toggle(state.interests, name));
    }
  }

  bool saveInterests(Set<String> values) {
    if (values.length < 3) return false;
    state = state.copyWith(interests: Set.unmodifiable(values));
    return true;
  }

  Future<bool> toggleSaved(String id) async {
    if (!ref.read(hasAuthenticatedSessionProvider)) {
      state = state.copyWith(message: 'Log in to save events.');
      return false;
    }
    if (live) return ref.read(flow1ViewModelProvider.notifier).bookmark(id);
    state = state.copyWith(saved: _toggle(state.saved, id));
    return true;
  }

  Future<bool> toggleFollowed(String id) async {
    if (!ref.read(hasAuthenticatedSessionProvider)) {
      state = state.copyWith(message: 'Log in to follow organizers.');
      return false;
    }
    if (live) return ref.read(flow1ViewModelProvider.notifier).follow(id);
    state = state.copyWith(followed: _toggle(state.followed, id));
    return true;
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
    _recordSearchSubmission();
  }

  void showSearch({bool referenceResults = false}) {
    state = state.copyWith(
      query: referenceResults ? 'workshop' : '',
      results: referenceResults,
      category: 'All',
      filters: referenceResults
          ? const EventFilters(
              date: 'Next week',
              audience: 'University Students',
            )
          : const EventFilters(),
    );
    if (referenceResults) {
      _recordSearchSubmission();
    }
  }

  void selectCategory(String category) {
    state = state.copyWith(
      category: category,
      results:
          category != 'All' || state.query.isNotEmpty || state.filters.isActive,
    );
    _recordSearchSubmission();
  }

  void selectOrganizer(String organizer) =>
      state = state.copyWith(organizer: organizer);
  void toggleSort() => state = state.copyWith(descending: !state.descending);
  void useAiFilters(EventFilters suggestion) {
    var draft = state.draft
        .withValue('Category', suggestion.category)
        .withValue('Date', suggestion.date)
        .withValue('Time', suggestion.time)
        .withValue('Duration', suggestion.duration);
    if (suggestion.rangeStart != null && suggestion.rangeEnd != null) {
      draft = draft.withRange(suggestion.rangeStart!, suggestion.rangeEnd!);
    }
    state = state.copyWith(draft: draft);
  }

  void beginFilters() => state = state.copyWith(draft: state.filters);
  void selectFilter(String group, String value) =>
      state = state.copyWith(draft: state.draft.withValue(group, value));
  void selectDateRange(DateTime start, DateTime end) =>
      state = state.copyWith(draft: state.draft.withRange(start, end));
  void setEligible(bool value) =>
      state = state.copyWith(draft: state.draft.withEligibility(value));
  void resetDraft() => state = state.copyWith(draft: const EventFilters());
  void applyFilters() {
    state = state.copyWith(
      filters: state.draft,
      category: 'All',
      results: true,
    );
    _recordSearchSubmission();
  }

  void clearFilters() {
    state = state.copyWith(
      filters: const EventFilters(),
      draft: const EventFilters(),
      category: 'All',
    );
    _recordSearchSubmission();
  }

  void removeFilter(String key) {
    state = state.copyWith(
      filters: state.filters.withValue(
        key,
        key == 'Date' ? 'Any date' : 'Any audience',
      ),
    );
    _recordSearchSubmission();
  }

  void retrySearch() {
    final input = (
      query: state.query,
      category: state.category,
      filters: state.filters,
    );
    if (live) {
      ref.invalidate(flow1SearchProvider(input));
    }
    _recordSearchSubmission();
  }

  void _recordSearchSubmission() {
    if (!live || !state.results) return;
    _searchSub?.close();
    _searchSub = null;
    final nonce = ++_searchNonce;
    final input = (
      query: state.query,
      category: state.category,
      filters: state.filters,
    );
    final searchTerm = AnalyticsEvents.redactSearchTerm(
      query: input.query,
      category: input.category,
      filterCategory: input.filters.category,
    );

    bool handle(AsyncValue<List<Flow1Event>> next) {
      if (!ref.mounted || nonce != _searchNonce || next.isLoading) {
        return false;
      }
      final items = next.asData?.value;
      if (items != null) {
        unawaited(
          ref
              .read(analyticsRepositoryProvider)
              .track(
                'search',
                parameters: {
                  'search_term': searchTerm,
                  'loaded_count': items.length,
                  'has_more': 0,
                  'outcome': items.isEmpty ? 'empty' : 'data',
                },
              ),
        );
        return true;
      }
      if (next.hasError) {
        final analytics = ref.read(analyticsRepositoryProvider);
        unawaited(
          analytics.track(
            'search',
            parameters: {
              'search_term': searchTerm,
              'loaded_count': 0,
              'has_more': 0,
              'outcome': 'error',
            },
          ),
        );
        unawaited(analytics.error('search', next.error!));
        return true;
      }
      return false;
    }

    var completed = false;
    final sub = ref.listen<AsyncValue<List<Flow1Event>>>(
      flow1SearchProvider(input),
      (_, next) {
        if (completed) return;
        if (handle(next)) {
          completed = true;
          _searchSub?.close();
          _searchSub = null;
        }
      },
    );
    final current = ref.read(flow1SearchProvider(input));
    if (handle(current)) {
      completed = true;
      sub.close();
    } else if (ref.mounted && nonce == _searchNonce) {
      _searchSub = sub;
    } else {
      sub.close();
    }
  }

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
                  !event.walkIn && !activity.cancelled.contains(event.id),
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
          organizer: live
              ? catalog?.organizerName(
                  catalog!.myEvents
                          .map((item) => Flow1Event(jsonMap(item['event'])))
                          .where((item) => item.id == event.id)
                          .firstOrNull
                          ?.organizerId ??
                      '',
                )
              : RegistrationMockData.findEvent(event.detailKey)?.organizer,
          policy: 'Registered',
          coins: event.coins,
          image: event.image,
        ),
    ];
    return state.descending ? events.reversed.toList() : events;
  }

  List<CampusEvent> get followedClubEvents {
    if (!ref.read(hasAuthenticatedSessionProvider)) return [];
    final List<CampusEvent> followedEvents;
    if (live) {
      final data = catalog;
      if (data == null) return [];
      final rows =
          data.events
              .where((event) => state.followed.contains(event.organizerId))
              .toList()
            ..sort((a, b) => a.start.compareTo(b.start));
      followedEvents = rows
          .map((event) => event.card(data.organizerName(event.organizerId)))
          .toList();
    } else {
      final names = followedOrganizers
          .map((organizer) => organizer.name)
          .toSet();
      followedEvents =
          EviaMockData.catalog
              .where((event) => names.contains(event.organizer))
              .toList()
            ..sort(
              (a, b) =>
                  EviaMockData.startOf(a).compareTo(EviaMockData.startOf(b)),
            );
    }
    return state.descending ? followedEvents.reversed.toList() : followedEvents;
  }

  List<CampusEvent> get followingEvents => followedClubEvents
      .where(
        (event) =>
            state.organizer == 'All' || event.organizer == state.organizer,
      )
      .toList();

  List<CampusOrganizer> get followedOrganizers {
    if (!ref.read(hasAuthenticatedSessionProvider)) return [];
    final organizers = [...allOrganizers]
        .where((o) => state.followed.contains(o.id))
        .toList();
    return state.descending ? organizers.reversed.toList() : organizers;
  }

  List<CampusOrganizer> get suggestedOrganizers =>
      (live ? allOrganizers : EviaMockData.organizers)
          .where((o) => !state.followed.contains(o.id))
          .toList();
  List<CampusOrganizer> get allOrganizers => live
      ? catalog?.organizerCards ?? []
      : [...EviaMockData.organizers, ...EviaMockData.recommendations];
  List<CampusEvent> get events => live
      ? catalog?.events
                .map((e) => e.card(catalog!.organizerName(e.organizerId)))
                .toList() ??
            []
      : [EviaMockData.music, ...EviaMockData.upcoming];
  List<CampusEvent> get featuredEvents => live
      ? catalog?.events
                .where((e) => e.featured)
                .take(5)
                .map((e) => e.card(catalog!.organizerName(e.organizerId)))
                .toList() ??
            []
      : [EviaMockData.music];
  CampusEvent? get featured => featuredEvents.firstOrNull;
  List<CampusEvent> get recommended => live
      ? catalog?.events
                .where(
                  (e) => [
                    e.category,
                    ...List<String>.from(e.data['tags'] as List? ?? []),
                  ].any(catalog!.selectedInterests.contains),
                )
                .map((e) => e.card(catalog!.organizerName(e.organizerId)))
                .take(5)
                .toList() ??
            []
      : [EviaMockData.recommendedAi, EviaMockData.photoWalk];
  List<String> get categories => live
      ? ['All', ...events.map((e) => e.category).toSet()]
      : ['All', 'Technology', 'Music', 'Sports', 'Arts'];
  String categoryLabel(String id) {
    if (id == 'All') return id;
    final labels = catalog?.interests.where((item) => item['id'] == id);
    if (labels != null && labels.isNotEmpty) {
      final label = labels.first['label'];
      if (label is String && label.trim().isNotEmpty) return label;
    }
    return id
        .split(RegExp(r'[_\s-]+'))
        .map((word) {
          if (word.isEmpty) return word;
          return '${word[0].toUpperCase()}${word.substring(1)}';
        })
        .join(' ');
  }

  String get discoverName => live
      ? 'Hey ${catalog?.profile['displayName'] ?? ''}! 👋'
      : EviaMockData.discoverName;
  String get recommendationSubtitle => live
      ? 'Based on your interests'
      : 'Based on your interests in Technology & Arts';
  Future<void> login(String email, String password) async {
    if (state.isLoggingIn) return;
    if (!FptIdentity.validEmail(email)) {
      state = state.copyWith(message: 'Enter a valid email address.');
      return;
    }
    if (password.isEmpty) {
      state = state.copyWith(message: 'Please enter your password.');
      return;
    }
    state = state.copyWith(isLoggingIn: true);
    try {
      await ref
          .read(authenticationRepositoryProvider)
          .signInWithEmailPassword(email, password);
      if (ref.mounted) {
        ref
            .read(authenticationViewModelProvider.notifier)
            .recordLogin('password');
      }
    } catch (error) {
      if (ref.mounted) {
        unawaited(ref.read(analyticsRepositoryProvider).error('login', error));
        state = state.copyWith(message: ExceptionMapper.map(error).message);
      }
    } finally {
      if (ref.mounted) {
        state = state.copyWith(isLoggingIn: false, message: state.message);
      }
    }
  }

  Future<void> continueWithGoogle() async {
    if (state.isLoggingIn) return;
    state = state.copyWith(isLoggingIn: true);
    try {
      await ref.read(authenticationRepositoryProvider).signInWithGoogle();
      if (ref.mounted) {
        ref
            .read(authenticationViewModelProvider.notifier)
            .recordLogin('google');
      }
    } catch (error) {
      if (ref.mounted) {
        unawaited(ref.read(analyticsRepositoryProvider).error('login', error));
        state = state.copyWith(
          message: ExceptionMapper.map(error).message,
          isLoggingIn: true,
        );
      }
    } finally {
      if (ref.mounted) {
        state = state.copyWith(isLoggingIn: false, message: state.message);
      }
    }
  }

  Future<void> resetPassword(String email) async {
    if (state.isLoggingIn) return;
    if (!FptIdentity.validEmail(email)) {
      state = state.copyWith(message: 'Enter a valid email address.');
      return;
    }
    state = state.copyWith(isLoggingIn: true);
    try {
      await ref.read(authenticationRepositoryProvider).resetPassword(email);
      if (ref.mounted) {
        state = state.copyWith(
          isLoggingIn: true,
          message:
              'If this account exists, a password reset email has been sent.',
        );
      }
    } catch (error) {
      if (ref.mounted) {
        state = state.copyWith(
          isLoggingIn: true,
          message: ExceptionMapper.map(error).message,
        );
      }
    } finally {
      if (ref.mounted) {
        state = state.copyWith(isLoggingIn: false, message: state.message);
      }
    }
  }

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
