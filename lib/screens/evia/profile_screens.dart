import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/flow_assets.dart';
import '../../data/mock/evia_mock_data.dart';
import '../../data/mock/registration_mock_data.dart';
import '../../theme/app_tokens.dart';
import '../../theme/evia_theme.dart';
import '../../viewmodels/profile_view_model.dart';
import '../../viewmodels/evia_view_model.dart';
import '../../viewmodels/activity_view_model.dart';
import '../../viewmodels/registration_view_model.dart';
import '../../widgets/activity_widgets.dart';
import '../../widgets/app_button.dart';
import '../../widgets/evia_widgets.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const screen = '2089:154';
    final state = ref.watch(profileViewModelProvider);
    Widget menu(String title, String subtitle, int icon, VoidCallback action) =>
        InkWell(
          onTap: action,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primarySoft,
                  child: ActivityIcon(screen, 'imgContainer$icon'),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: EviaTheme.cardTitle),
                      Text(subtitle, style: EviaTheme.caption),
                    ],
                  ),
                ),
                const ActivityIcon(screen, 'imgContainer4'),
              ],
            ),
          ),
        );
    return EviaPage(
      header: const Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text('Profile', style: EviaTheme.heading),
        ),
      ),
      footer: const ActivityBottomBar(screen: screen, start: 11, selected: 3),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            EviaCard(
              color: AppColors.primarySoft.withValues(alpha: .25),
              child: Column(
                children: [
                  Row(
                    children: [
                      ClipOval(
                        child: Image.asset(
                          FlowAssets.image(screen, 0),
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(state.name, style: EviaTheme.section),
                            const SizedBox(height: AppSpacing.xs),
                            Row(
                              children: [
                                const ActivityIcon(screen, 'imgContainer'),
                                const SizedBox(width: AppSpacing.xs),
                                Expanded(
                                  child: Text(
                                    state.studentId,
                                    style: EviaTheme.caption,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                const ActivityIcon(screen, 'imgContainer1'),
                                const SizedBox(width: AppSpacing.xs),
                                Expanded(
                                  child: Text(
                                    state.email,
                                    style: EviaTheme.caption,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => _edit(context, ref),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ActivityIcon(screen, 'imgContainer2'),
                          SizedBox(width: AppSpacing.sm),
                          Text('Edit Profile'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            const Text('YOUR ACTIVITY', style: EviaTheme.caption),
            const SizedBox(height: AppSpacing.sm),
            EviaCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  menu(
                    'Saved Events',
                    "Events you've bookmarked",
                    3,
                    () => context.push('/profile/saved'),
                  ),
                  const Divider(height: 1),
                  menu(
                    'Following',
                    'Organizers and clubs you follow',
                    5,
                    () => context.push('/following/organizers'),
                  ),
                  const Divider(height: 1),
                  menu(
                    'Notifications',
                    'Event updates and reminders',
                    6,
                    () => context.push('/profile/notifications'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            const Text('PREFERENCES & SUPPORT', style: EviaTheme.caption),
            const SizedBox(height: AppSpacing.sm),
            EviaCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  menu(
                    'My Interests',
                    'Personalize your event recommendations',
                    7,
                    () {
                      ref
                          .read(profileViewModelProvider.notifier)
                          .beginInterests();
                      context.push('/profile/interests');
                    },
                  ),
                  const Divider(height: 1),
                  menu(
                    'App Settings',
                    'Preferences and permissions',
                    8,
                    () => showActivityHelp(
                      context,
                      'App Settings',
                      'Event preferences are managed in My Interests. Device permissions can be managed in your system settings.',
                    ),
                  ),
                  const Divider(height: 1),
                  menu(
                    'Help & Support',
                    'FAQs, guides and contact support',
                    9,
                    () => showActivityHelp(
                      context,
                      'Help & Support',
                      'Register from an event page, find tickets in My Events and scan the event QR at the venue. Rewards are available after verified check-in.',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            OutlinedButton(
              onPressed: () {
                ref.invalidate(profileViewModelProvider);
                ref.invalidate(eviaViewModelProvider);
                ref.invalidate(registrationViewModelProvider);
                ref.invalidate(activityViewModelProvider);
                context.go('/');
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ActivityIcon(screen, 'imgContainer10'),
                  SizedBox(width: AppSpacing.sm),
                  Text('Log Out'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _edit(BuildContext context, WidgetRef ref) async {
    final state = ref.read(profileViewModelProvider);
    final name = TextEditingController(text: state.name),
        id = TextEditingController(text: state.studentId),
        email = TextEditingController(text: state.email);
    await showDialog<void>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Edit Profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Full Name'),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: id,
                decoration: const InputDecoration(labelText: 'Student ID'),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'University Email',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (ref
                  .read(profileViewModelProvider.notifier)
                  .updateProfile(name.text, id.text, email.text)) {
                Navigator.pop(dialog);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Enter your name, student ID and a valid email.',
                    ),
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    name.dispose();
    id.dispose();
    email.dispose();
  }
}

class ProfileInterestsScreen extends ConsumerWidget {
  const ProfileInterestsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const screen = '2089:296';
    final selected = ref.watch(
      profileViewModelProvider.select((s) => s.draftInterests),
    );
    final vm = ref.read(profileViewModelProvider.notifier);
    return EviaPage(
      header: const ActivityHeader(
        'My Interests',
        screen: screen,
        backAsset: 'imgContainer',
      ),
      footer: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppButton(
              label: 'Save Preferences',
              onPressed: selected.length < 3
                  ? null
                  : () {
                      vm.saveInterests();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Preferences saved.')),
                      );
                    },
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Your Discover feed will update automatically.',
              textAlign: TextAlign.center,
              style: EviaTheme.caption,
            ),
          ],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Your Event Interests', style: EviaTheme.heading),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Update your favorite topics anytime to keep your personalized event recommendations and notifications tailored to you.',
              style: EviaTheme.caption,
            ),
            const SizedBox(height: AppSpacing.xl),
            for (var row = 0; row < 4; row++)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var col = 0; col < 2; col++) ...[
                        if (col == 1) const SizedBox(width: AppSpacing.lg),
                        Expanded(
                          child: Builder(
                            builder: (context) {
                              final topic = EviaMockData.topics[row * 2 + col],
                                  active = selected.contains(
                                    EviaMockData.topics[row * 2 + col].name,
                                  );
                              return Semantics(
                                selected: active,
                                button: true,
                                child: InkWell(
                                  onTap: () => vm.toggleInterest(topic.name),
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.large,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.all(
                                      AppSpacing.lg,
                                    ),
                                    decoration: BoxDecoration(
                                      color: active
                                          ? AppColors.primarySoft
                                          : AppColors.surface,
                                      borderRadius: BorderRadius.circular(
                                        AppRadius.large,
                                      ),
                                      border: Border.all(
                                        color: active
                                            ? AppColors.primary
                                            : AppColors.border,
                                        width: active ? 2 : 1,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Container(
                                              width: 32,
                                              height: 32,
                                              alignment: Alignment.center,
                                              decoration: BoxDecoration(
                                                color: active
                                                    ? AppColors.primarySoft
                                                    : AppColors.surfaceMuted,
                                                borderRadius:
                                                    BorderRadius.circular(
                                                      AppRadius.small,
                                                    ),
                                              ),
                                              child: ActivityIcon(
                                                screen,
                                                topic.asset,
                                              ),
                                            ),
                                            Container(
                                              width: 20,
                                              height: 20,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: active
                                                    ? AppColors.primary
                                                    : AppColors.surface,
                                                border: Border.all(
                                                  color: active
                                                      ? AppColors.primary
                                                      : AppColors.border,
                                                ),
                                              ),
                                              child: Center(
                                                child: Opacity(
                                                  opacity: active ? 1 : 0,
                                                  child: ActivityIcon(
                                                    screen,
                                                    active
                                                        ? 'imgContainer2'
                                                        : 'imgContainer6',
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: AppSpacing.md),
                                        Text(
                                          topic.name,
                                          style: EviaTheme.label,
                                        ),
                                        const SizedBox(height: AppSpacing.xs),
                                        Text(
                                          topic.description,
                                          style: EviaTheme.caption,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.lg,
              runSpacing: AppSpacing.sm,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.circle,
                      size: AppSpacing.sm,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      '${selected.length} interests selected',
                      style: EviaTheme.label,
                    ),
                  ],
                ),
                const Text(
                  'Changes will update feed',
                  style: TextStyle(color: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Select at least 3 interests for best recommendations',
              style: EviaTheme.caption,
            ),
          ],
        ),
      ),
    );
  }
}

class SavedEventsScreen extends ConsumerWidget {
  const SavedEventsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const screen = '2091:440';
    final state = ref.watch(profileViewModelProvider),
        vm = ref.read(profileViewModelProvider.notifier);
    return EviaPage(
      header: const ActivityHeader(
        'Saved Events',
        screen: screen,
        backAsset: 'imgContainer6',
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${vm.savedCount('All')} saved events',
              style: EviaTheme.section,
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              "Events you've bookmarked for later.",
              style: EviaTheme.caption,
            ),
            const SizedBox(height: AppSpacing.xl),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                for (final filter in ['All', 'Upcoming', 'Past'])
                  ChoiceChip(
                    label: Text('$filter (${vm.savedCount(filter)})'),
                    selected: state.savedFilter == filter,
                    onSelected: (_) => vm.filterSaved(filter),
                    showCheckmark: false,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            if (vm.visibleSaved.isEmpty)
              const Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: Text('No saved events in this category.'),
              ),
            for (final entry in vm.visibleSaved)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: EviaCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: InkWell(
                    onTap: () =>
                        context.push('/event/about?event=${entry.event.id}'),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.small),
                          child: Image.asset(
                            entry.image,
                            width: 88,
                            height: 88,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: AppSpacing.xs,
                                runSpacing: AppSpacing.xs,
                                children: [
                                  EventBadge(
                                    entry.event.past ? 'Past' : 'Upcoming',
                                  ),
                                  Text(
                                    entry.organizer,
                                    style: EviaTheme.caption,
                                  ),
                                ],
                              ),
                              Text(
                                entry.event.title,
                                style: EviaTheme.cardTitle,
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Row(
                                children: [
                                  ActivityIcon(
                                    screen,
                                    entry.event.past
                                        ? 'imgContainer4'
                                        : 'imgContainer',
                                  ),
                                  const SizedBox(width: AppSpacing.xs),
                                  Expanded(
                                    child: Text(
                                      entry.dateLabel,
                                      style: EviaTheme.caption,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Row(
                                children: [
                                  const ActivityIcon(screen, 'imgContainer1'),
                                  const SizedBox(width: AppSpacing.xs),
                                  Expanded(
                                    child: Text(
                                      entry.event.id == 'music-live'
                                          ? 'Main Auditorium'
                                          : entry.event.venue,
                                      style: EviaTheme.caption,
                                    ),
                                  ),
                                  ActivityIcon(
                                    screen,
                                    entry.event.past
                                        ? 'imgContainer5'
                                        : 'imgContainer2',
                                  ),
                                  Text(
                                    '+${entry.event.coins}',
                                    style: EviaTheme.caption,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Remove ${entry.event.title} from saved',
                          onPressed: () => vm.toggleSaved(entry.event.id),
                          icon: const ActivityIcon(screen, 'imgContainer3'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const screen = '2092:607';
    ref.watch(profileViewModelProvider);
    final vm = ref.read(profileViewModelProvider.notifier);
    return EviaPage(
      header: ActivityHeader(
        'Notifications',
        screen: screen,
        backAsset: 'imgContainer4',
        trailing: TextButton(
          onPressed: vm.markAllRead,
          child: const Text('Mark all read'),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final today in [true, false]) ...[
              Wrap(
                spacing: AppSpacing.sm,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(today ? 'Today' : 'This Week', style: EviaTheme.label),
                  if (today && vm.unreadCount > 0)
                    EventBadge('${vm.unreadCount} new'),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              EviaCard(
                color: today
                    ? AppColors.primarySoft.withValues(alpha: .2)
                    : AppColors.surface,
                child: Column(
                  children: [
                    for (final notice in RegistrationMockData.notices.where(
                      (n) => n.today == today,
                    )) ...[
                      if (notice !=
                          RegistrationMockData.notices.firstWhere(
                            (n) => n.today == today,
                          ))
                        const Divider(height: AppSpacing.xl),
                      InkWell(
                        onTap: () {
                          vm.readNotice(notice.id);
                          context.push(
                            notice.id == 'registration'
                                ? '/my-events/ticket?event=music-live'
                                : '/event/about?event=${notice.id == 'new-event' ? 'innovation' : 'music-live'}',
                          );
                        },
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                CircleAvatar(
                                  backgroundColor: today
                                      ? AppColors.primarySoft
                                      : AppColors.surfaceMuted,
                                  child: ActivityIcon(
                                    screen,
                                    notice.icon == 0
                                        ? 'imgContainer'
                                        : 'imgContainer${notice.icon}',
                                  ),
                                ),
                                if (vm.isUnread(notice))
                                  const Positioned(
                                    right: 0,
                                    top: 0,
                                    child: Icon(
                                      Icons.circle,
                                      color: AppColors.primary,
                                      size: AppSpacing.sm,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    spacing: AppSpacing.sm,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      Text(
                                        notice.title,
                                        style: EviaTheme.label,
                                      ),
                                      if (vm.isUnread(notice))
                                        const EventBadge('NEW'),
                                      Text(
                                        notice.when,
                                        style: EviaTheme.caption,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    notice.message,
                                    style: EviaTheme.caption,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ],
        ),
      ),
    );
  }
}
