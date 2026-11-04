import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_tokens.dart';
import '../../theme/evia_theme.dart';
import '../../viewmodels/activity_view_model.dart';
import '../../widgets/app_button.dart';
import '../../widgets/activity_widgets.dart';

class MonthlyCalendar extends ConsumerWidget {
  const MonthlyCalendar({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(activityViewModelProvider);
    final vm = ref.read(activityViewModelProvider.notifier);
    final month = state.calendarMonth;
    final first = DateTime(month.year, month.month);
    final gridStart = first.subtract(Duration(days: first.weekday - 1));
    final days = DateTime(month.year, month.month + 1, 0).day;
    final cells = ((first.weekday - 1 + days) / 7).ceil() * 7;
    void close() => context.canPop() ? context.pop() : context.go('/my-events');
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: AppSpacing.xxxl,
            height: AppSpacing.xs,
            color: AppColors.border,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Select a date', style: EviaTheme.section),
                  Text(
                    'View and filter your events by day',
                    style: EviaTheme.caption,
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Close calendar',
              onPressed: close,
              icon: const ActivityIcon('2083:2481', 'imgContainer8'),
            ),
          ],
        ),
        const Divider(height: AppSpacing.xl),
        Row(
          children: [
            IconButton(
              tooltip: 'Previous month',
              onPressed: () => vm.shiftMonth(-1),
              icon: const ActivityIcon('2083:2481', 'imgContainer9'),
            ),
            Expanded(
              child: Text(
                '${monthName(month.month)} ${month.year}',
                textAlign: TextAlign.center,
                style: EviaTheme.section,
              ),
            ),
            IconButton(
              tooltip: 'Next month',
              onPressed: () => vm.shiftMonth(1),
              icon: const ActivityIcon('2083:2481', 'imgContainer10'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            for (final day in ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'])
              Expanded(
                child: Text(
                  day,
                  textAlign: TextAlign.center,
                  style: EviaTheme.caption,
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        for (var row = 0; row < cells ~/ 7; row++)
          Row(
            children: [
              for (var col = 0; col < 7; col++)
                Expanded(
                  child: Builder(
                    builder: (context) {
                      final date = gridStart.add(Duration(days: row * 7 + col));
                      if (date.isAfter(
                        DateTime(month.year, month.month + 1, 0),
                      )) {
                        return const SizedBox(
                          height: AppSizes.minimumTouchTarget,
                        );
                      }
                      final eventDay =
                          date.month == month.month && vm.hasEvent(date);
                      final selected =
                          state.draftDate != null &&
                          vm.sameDay(date, state.draftDate!);
                      return Semantics(
                        selected: selected,
                        label: '${monthName(date.month)} ${date.day}',
                        child: TextButton(
                          onPressed: () => vm.draftDate(date),
                          style: TextButton.styleFrom(
                            backgroundColor: selected
                                ? AppColors.primary
                                : eventDay
                                ? AppColors.primarySoft
                                : null,
                            foregroundColor: selected
                                ? AppColors.surface
                                : date.month == month.month
                                ? AppColors.textPrimary
                                : AppColors.textDisabled,
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.md,
                            ),
                            minimumSize: const Size(
                              AppSizes.minimumTouchTarget,
                              AppSizes.minimumTouchTarget,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppRadius.medium,
                              ),
                            ),
                          ),
                          child: Column(
                            children: [
                              if (date.year == 2026 &&
                                  date.month == 11 &&
                                  date.day == 15 &&
                                  !selected)
                                const ActivityIcon(
                                  '2083:2481',
                                  'imgContainer11',
                                )
                              else
                                Text('${date.day}'),
                              if (eventDay)
                                Icon(
                                  Icons.circle,
                                  size: AppSpacing.xs,
                                  color: selected
                                      ? AppColors.surface
                                      : AppColors.primary,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        const Divider(height: AppSpacing.xl),
        AppButton(
          label: 'Apply date',
          onPressed: () {
            vm.applyDate();
            close();
          },
        ),
      ],
    );
  }
}
