import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/mock/evia_mock_data.dart';
import '../../models/evia_models.dart';
import '../../theme/app_tokens.dart';
import '../../theme/evia_theme.dart';
import '../../viewmodels/evia_view_model.dart';
import '../../widgets/app_button.dart';
import '../../widgets/evia_widgets.dart';

class EviaFiltersScreen extends ConsumerWidget {
  const EviaFiltersScreen({super.key});
  String _value(EventFilters filters, String key) => switch (key) {
    'Category' => filters.category,
    'Date' => filters.date,
    'Time' => filters.time,
    'Duration' => filters.duration,
    'Audience' => filters.audience,
    'Registration Policy' => filters.policy,
    _ => filters.availability,
  };
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(eviaViewModelProvider.select((s) => s.draft));
    final vm = ref.read(eviaViewModelProvider.notifier);
    return EviaPage(
      header: Container(
        color: AppColors.surface,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        child: Row(
          children: [
            IconButton(
              tooltip: 'Close filters',
              onPressed: () =>
                  context.canPop() ? context.pop() : context.go('/explore'),
              icon: const FigmaIcon('2083:1438', 'imgContainer'),
            ),
            const Expanded(
              child: Text(
                'Filter Events',
                textAlign: TextAlign.center,
                style: EviaTheme.label,
              ),
            ),
            TextButton(onPressed: vm.resetDraft, child: const Text('Reset')),
          ],
        ),
      ),
      footer: Container(
        color: AppColors.surface,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: SizedBox(
          width: double.infinity,
          child: AppButton(
            label: 'Apply Filters',
            onPressed: () {
              vm.applyFilters();
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/explore');
              }
            },
          ),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final entry in EviaMockData.filterGroups.entries) ...[
              if (entry.key != 'Category')
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                  child: Divider(),
                ),
              Text(entry.key, style: EviaTheme.label),
              if (entry.key == 'Time' || entry.key == 'Audience') ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  entry.key == 'Time'
                      ? 'Event start time'
                      : 'Who is allowed to attend?',
                  style: EviaTheme.caption,
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final value in entry.value)
                    EviaPill(
                      value,
                      selected: _value(filters, entry.key) == value,
                      onTap: () async {
                        if (entry.key == 'Date' && value == 'Custom range') {
                          final range = await showDateRangePicker(
                            context: context,
                            firstDate: DateTime(2026),
                            lastDate: DateTime(2030),
                            currentDate: EviaMockData.referenceDate,
                            initialDateRange:
                                filters.rangeStart != null &&
                                    filters.rangeEnd != null
                                ? DateTimeRange(
                                    start: filters.rangeStart!,
                                    end: filters.rangeEnd!,
                                  )
                                : null,
                          );
                          if (range != null) {
                            vm.selectDateRange(range.start, range.end);
                          }
                        } else {
                          vm.selectFilter(entry.key, value);
                        }
                      },
                    ),
                ],
              ),
              if (entry.key == 'Date' &&
                  filters.rangeStart != null &&
                  filters.rangeEnd != null)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Text(
                    '${MaterialLocalizations.of(context).formatCompactDate(filters.rangeStart!)} – ${MaterialLocalizations.of(context).formatCompactDate(filters.rangeEnd!)}',
                    style: EviaTheme.caption,
                  ),
                ),
              if (entry.key == 'Audience') ...[
                const SizedBox(height: AppSpacing.lg),
                EviaCard(
                  child: Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Only events I'm eligible for",
                              style: EviaTheme.label,
                            ),
                            SizedBox(height: AppSpacing.xs),
                            Text(
                              'Based on your verified student and club information.',
                              style: EviaTheme.caption,
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: filters.eligibleOnly,
                        onChanged: vm.setEligible,
                      ),
                    ],
                  ),
                ),
              ],
            ],
            const SizedBox(height: AppSpacing.section),
          ],
        ),
      ),
    );
  }
}
