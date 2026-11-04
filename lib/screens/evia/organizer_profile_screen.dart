import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/flow_assets.dart';
import '../../data/mock/registration_mock_data.dart';
import '../../theme/app_tokens.dart';
import '../../theme/evia_theme.dart';
import '../../viewmodels/evia_view_model.dart';
import '../../viewmodels/authentication_view_model.dart';
import '../../viewmodels/profile_view_model.dart';
import '../../widgets/activity_widgets.dart';
import '../../widgets/evia_widgets.dart';
import '../../widgets/authenticated_action.dart';
import '../../widgets/coin_icon.dart';

class OrganizerProfileScreen extends ConsumerWidget {
  const OrganizerProfileScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const screen = '2083:6080';
    final state = ref.watch(profileViewModelProvider),
        vm = ref.read(profileViewModelProvider.notifier);
    final following =
        ref.watch(hasAuthenticatedSessionProvider) &&
        ref.watch(
          eviaViewModelProvider.select((s) => s.followed.contains('union')),
        );
    final events = state.organizerPast
        ? [RegistrationMockData.arts]
        : [RegistrationMockData.club, RegistrationMockData.leadership];
    return EviaPage(
      header: ActivityHeader(
        'Organizer Profile',
        screen: screen,
        backAsset: 'imgContainer7',
        trailing: IconButton(
          tooltip: 'Copy organizer information',
          onPressed: () => copyActivityCode(
            context,
            'Student Union — Official campus student organization. 2 upcoming events: Campus Club Fair and Student Leadership Workshop.',
          ),
          icon: const ActivityIcon(screen, 'imgContainer8'),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Image.asset(
              FlowAssets.image(screen, 0),
              height: 128,
              fit: BoxFit.cover,
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const CircleAvatar(
                        radius: 26,
                        backgroundColor: AppColors.surface,
                        child: ActivityIcon(screen, 'imgContainer'),
                      ),
                      OutlinedButton(
                        onPressed: () {
                          if (!ensureAuthenticated(context, ref)) return;
                          ref
                              .read(eviaViewModelProvider.notifier)
                              .toggleFollowed('union');
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (following)
                              const ActivityIcon(screen, 'imgContainer1'),
                            const SizedBox(width: AppSpacing.xs),
                            Text(following ? 'Following' : '+ Follow'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: AppSpacing.sm,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text('Student Union', style: EviaTheme.section),
                      const EventBadge('STUDENT ORGANIZATION'),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    RegistrationMockData.organizerDescription,
                    maxLines: state.expandedOrganizer ? null : 2,
                    overflow: state.expandedOrganizer
                        ? null
                        : TextOverflow.ellipsis,
                    style: EviaTheme.caption,
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: vm.toggleOrganizerDescription,
                      child: Text(
                        state.expandedOrganizer ? 'Read less' : 'Read more',
                      ),
                    ),
                  ),
                  const Text('Events', style: EviaTheme.section),
                  const SizedBox(height: AppSpacing.sm),
                  ActivityTabs(
                    labels: const ['Upcoming  2', 'Past  1'],
                    selected: state.organizerPast ? 1 : 0,
                    onSelected: (index) => vm.organizerTab(index == 1),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  for (var index = 0; index < events.length; index++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: EviaCard(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        child: InkWell(
                          onTap: () => context.push(
                            '/event/about?event=${events[index].id}',
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 90,
                                height: 90,
                                child: Stack(
                                  children: [
                                    Positioned.fill(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                          AppRadius.medium,
                                        ),
                                        child: Image.asset(
                                          state.organizerPast
                                              ? RegistrationMockData
                                                    .saved
                                                    .last
                                                    .image
                                              : FlowAssets.image(
                                                  screen,
                                                  index + 1,
                                                ),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      left: 0,
                                      top: 0,
                                      child: EventBadge(
                                        events[index].category.toUpperCase(),
                                        category: true,
                                        color: AppColors.accent,
                                        foreground: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      events[index].title,
                                      style: EviaTheme.label,
                                    ),
                                    const SizedBox(height: AppSpacing.xs),
                                    Row(
                                      children: [
                                        const ActivityIcon(
                                          screen,
                                          'imgContainer2',
                                        ),
                                        const SizedBox(width: AppSpacing.xs),
                                        Expanded(
                                          child: Text(
                                            state.organizerPast
                                                ? '${events[index].date} · ${events[index].time}'
                                                : '${index == 0 ? 'Tue, Nov 10' : 'Wed, Nov 18'}, 2026 · ${events[index].time}',
                                            style: EviaTheme.caption,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        const ActivityIcon(
                                          screen,
                                          'imgContainer3',
                                        ),
                                        const SizedBox(width: AppSpacing.xs),
                                        Expanded(
                                          child: Text(
                                            events[index].venue,
                                            style: EviaTheme.caption,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: AppSpacing.xs),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (!events[index].walkIn)
                                          const ActivityIcon(
                                            screen,
                                            'imgContainer6',
                                          ),
                                        Flexible(
                                          child: EventBadge(
                                            events[index].walkIn
                                                ? 'Walk-in allowed'
                                                : 'Registration required',
                                            color: events[index].walkIn
                                                ? AppColors.successSurface
                                                : AppColors.primarySoft,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const CoinIcon(),
                                        Text(
                                          '+${events[index].coins} coins',
                                          style: EviaTheme.caption.copyWith(
                                            color: AppColors.warning,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: 'Save ${events[index].title}',
                                onPressed: () {
                                  if (!ensureAuthenticated(context, ref)) {
                                    return;
                                  }
                                  vm.toggleSaved(events[index].id);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        ref
                                                .read(profileViewModelProvider)
                                                .saved
                                                .contains(events[index].id)
                                            ? 'Event saved.'
                                            : 'Event removed from saved.',
                                      ),
                                    ),
                                  );
                                },
                                icon: const ActivityIcon(
                                  screen,
                                  'imgContainer5',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
