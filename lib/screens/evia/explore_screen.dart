import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/mock/evia_mock_data.dart';
import '../../core/providers/service_providers.dart';
import '../../core/utils/exception_mapper.dart';
import '../../viewmodels/flow1_view_model.dart';
import '../../theme/app_tokens.dart';
import '../../theme/evia_theme.dart';
import '../../viewmodels/evia_view_model.dart';
import '../../widgets/evia_widgets.dart';
import '../../widgets/status_widgets.dart';
import '../../widgets/evia_skeleton.dart';

class EviaExploreScreen extends ConsumerStatefulWidget {
  const EviaExploreScreen({
    this.referenceResults = false,
    this.onClose,
    super.key,
  });
  final bool referenceResults;
  final VoidCallback? onClose;
  @override
  ConsumerState<EviaExploreScreen> createState() => _EviaExploreScreenState();
}

class _EviaExploreScreenState extends ConsumerState<EviaExploreScreen> {
  late final TextEditingController _query;
  @override
  void initState() {
    super.initState();
    _query = TextEditingController(text: ref.read(eviaViewModelProvider).query);
    if (widget.referenceResults) {
      Future.microtask(() {
        if (mounted) {
          ref
              .read(eviaViewModelProvider.notifier)
              .showSearch(referenceResults: true);
        }
      });
    }
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(eviaViewModelProvider);
    final vm = ref.read(eviaViewModelProvider.notifier);
    final results = state.results || widget.referenceResults;
    final screen = results ? '2083:826' : '2083:993';
    final queryValue = state.query;
    if (_query.text != queryValue) {
      _query.value = TextEditingValue(
        text: queryValue,
        selection: TextSelection.collapsed(offset: queryValue.length),
      );
    }
    final live = ref.watch(realBackendEnabledProvider);
    final input = (
      query: state.query,
      category: state.category,
      filters: state.filters,
    );
    final remote = live ? ref.watch(flow1SearchProvider(input)) : null;
    final events = live
        ? (remote?.asData?.value
                  .map(
                    (event) => event.card(
                      vm.catalog!.organizerName(event.organizerId),
                    ),
                  )
                  .toList() ??
              [])
        : vm.searchResults;
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              tooltip: widget.onClose == null
                  ? 'Back to Discover'
                  : 'Close search',
              onPressed:
                  widget.onClose ??
                  () => context.canPop()
                      ? context.pop()
                      : context.go('/discover'),
              icon: FigmaIcon(screen, 'imgContainer'),
            ),
            const SizedBox(width: AppSpacing.xs),
            const Expanded(
              child: Text('Search & Explore', style: EviaTheme.heading),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _query,
                onChanged: vm.updateQuery,
                onSubmitted: vm.submitSearch,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search events, organizers...',
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: FigmaIcon(
                      screen,
                      results ? 'imgContainer1' : 'imgIcon',
                    ),
                  ),
                  suffixIcon: state.query.isNotEmpty
                      ? IconButton(
                          tooltip: 'Clear search',
                          onPressed: () => vm.updateQuery(''),
                          icon: const FigmaIcon('2083:826', 'imgContainer2'),
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            EviaCard(
              padding: EdgeInsets.zero,
              child: IconButton(
                tooltip: 'Filter events',
                onPressed: () {
                  vm.beginFilters();
                  context.push('/filters');
                },
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    FigmaIcon(
                      screen,
                      results ? 'imgContainer3' : 'imgContainer1',
                    ),
                    if (state.filters.isActive)
                      const Positioned(
                        right: 0,
                        top: 0,
                        child: Icon(
                          Icons.circle,
                          size: AppSpacing.sm,
                          color: AppColors.primary,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final category
                  in (live
                      ? vm.categories
                      : results
                      ? ['All', 'Technology', 'Music', 'Sports', 'Arts']
                      : ['All', 'Music', 'Technology', 'Sports', 'Arts']))
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: EviaPill(
                    vm.categoryLabel(category),
                    selected: state.category == category,
                    onTap: () => vm.selectCategory(category),
                    leading: category == 'All' && !results
                        ? const FigmaIcon('2083:993', 'imgContainer4')
                        : null,
                  ),
                ),
            ],
          ),
        ),
        if (results) ...[
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (state.filters.date != 'Any date')
                InputChip(
                  label: Text(state.filters.date),
                  onDeleted: () => vm.removeFilter('Date'),
                  deleteIcon: const FigmaIcon('2083:826', 'imgContainer4'),
                ),
              if (state.filters.audience != 'Any audience')
                InputChip(
                  label: Text(state.filters.audience),
                  onDeleted: () => vm.removeFilter('Audience'),
                  deleteIcon: const FigmaIcon('2083:826', 'imgContainer4'),
                ),
              if (state.filters.isActive)
                TextButton(
                  onPressed: vm.clearFilters,
                  child: const Text('Clear all'),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: Text(
                  remote?.isLoading == true && remote?.hasValue != true
                      ? 'Searching…'
                      : remote?.hasError == true
                      ? 'Search results'
                      : '${events.length} events found',
                  style: EviaTheme.label,
                ),
              ),
              Flexible(
                child: TextButton(
                  onPressed: vm.toggleSort,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          state.descending ? 'Sort: Latest' : 'Sort: Soonest',
                          style: EviaTheme.caption,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      const FigmaIcon('2083:826', 'imgContainer5'),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (remote?.isLoading == true && remote?.hasValue != true)
            const EviaSkeleton(),
          if (remote?.hasError == true)
            AppErrorWidget(
              message: ExceptionMapper.map(remote!.error!).message,
              onRetry: () => ref.invalidate(flow1SearchProvider(input)),
            ),
          if (events.isEmpty &&
              remote?.isLoading != true &&
              remote?.hasError != true)
            const AppEmptyWidget(
              title: 'No events found',
              message: 'No events match your search. Try another topic or clear the filters.',
            ),
          for (final event in events)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: SearchEventCard(event: event),
            ),
        ] else ...[
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              const Expanded(
                child: Text('Recent Searches', style: EviaTheme.section),
              ),
              if (state.history.isNotEmpty)
                TextButton(
                  onPressed: vm.clearHistory,
                  child: const Text('Clear all'),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (state.history.isEmpty)
            const EviaCard(
              child: Row(
                children: [
                  Icon(Icons.history, color: AppColors.textSecondary),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'Your recent searches will appear here.',
                      style: EviaTheme.caption,
                    ),
                  ),
                ],
              ),
            )
          else
            EviaCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (var i = 0; i < state.history.length; i++) ...[
                    if (i != 0) const Divider(height: 1),
                    Material(
                      color: AppColors.surface,
                      child: ListTile(
                        leading: const FigmaIcon('2083:993', 'imgContainer2'),
                        title: Text(state.history[i]),
                        onTap: () => vm.submitSearch(state.history[i]),
                        trailing: IconButton(
                          tooltip: 'Remove ${state.history[i]} from history',
                          onPressed: () => vm.removeHistory(state.history[i]),
                          icon: const FigmaIcon('2083:993', 'imgContainer3'),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          const SectionHeading('Suggested Events'),
          for (final event
              in (live
                  ? vm.events.take(2)
                  : [EviaMockData.music, EviaMockData.suggestedAi]))
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: SearchEventCard(event: event, idle: true),
            ),
        ],
        const SizedBox(height: AppSpacing.xxl),
      ],
    );
    if (widget.onClose != null) return content;
    return EviaPage(
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: content,
      ),
    );
  }
}
