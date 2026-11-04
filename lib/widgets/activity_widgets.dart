import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/activity_assets.dart';
import '../theme/app_tokens.dart';
import '../theme/evia_theme.dart';
import '../theme/activity_theme.dart';

class ActivityIcon extends StatelessWidget {
  const ActivityIcon(this.screen, this.name, {super.key});
  final String screen, name;
  @override
  Widget build(BuildContext context) => SvgPicture.asset(
    ActivityAssets.path(
      screen,
      name == 'imgContainer0' ? 'imgContainer' : name,
    ),
  );
}

class ActivityHeader extends StatelessWidget {
  const ActivityHeader(
    this.title, {
    this.screen,
    this.backAsset,
    this.trailing,
    super.key,
  });
  final String title;
  final String? screen, backAsset;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Container(
    color: AppColors.surface,
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.lg,
      vertical: AppSpacing.xs,
    ),
    child: Row(
      children: [
        IconButton(
          tooltip: 'Back',
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/discover'),
          icon: screen != null && backAsset != null
              ? ActivityIcon(screen!, backAsset!)
              : const Icon(Icons.arrow_back),
        ),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: EviaTheme.section,
          ),
        ),
        trailing ?? const SizedBox(width: AppSizes.minimumTouchTarget),
      ],
    ),
  );
}

class ActivityBottomBar extends StatelessWidget {
  const ActivityBottomBar({
    required this.screen,
    required this.start,
    required this.selected,
    this.legacy = false,
    super.key,
  });
  final String screen;
  final int start, selected;
  final bool legacy;
  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      color: AppColors.surface,
      border: Border(top: BorderSide(color: AppColors.border)),
    ),
    child: Row(
      children: [
        for (var index = 0; index < 4; index++)
          Expanded(
            child: InkWell(
              onTap: () => context.go(
                (legacy
                    ? ['/discover', '/explore', '/my-events', '/profile']
                    : [
                        '/discover',
                        '/my-events',
                        '/rewards',
                        '/profile',
                      ])[index],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ActivityIcon(screen, 'imgContainer${start + index}'),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      (legacy
                          ? ['Discover', 'Explore', 'My Events', 'Profile']
                          : [
                              'Discover',
                              'Events',
                              'Rewards',
                              'Profile',
                            ])[index],
                      textAlign: TextAlign.center,
                      style: EviaTheme.caption.copyWith(
                        color: index == selected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                    ),
                    if (index == selected)
                      const Icon(
                        Icons.circle,
                        size: AppSpacing.xs,
                        color: AppColors.primary,
                      ),
                  ],
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

class ActivityTabs extends StatelessWidget {
  const ActivityTabs({
    required this.labels,
    required this.selected,
    required this.onSelected,
    this.icons,
    this.activeColor = AppColors.surface,
    this.activeForeground = AppColors.primary,
    super.key,
  });
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelected;
  final List<Widget>? icons;
  final Color activeColor, activeForeground;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.xs),
    decoration: BoxDecoration(
      color: EviaTheme.lavender,
      borderRadius: BorderRadius.circular(AppRadius.medium),
    ),
    child: Row(
      children: [
        for (var i = 0; i < labels.length; i++)
          Expanded(
            child: Semantics(
              selected: i == selected,
              child: Material(
                color: i == selected ? activeColor : Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadius.small),
                child: InkWell(
                  onTap: () => onSelected(i),
                  borderRadius: BorderRadius.circular(AppRadius.small),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (icons != null) ...[
                          icons![i],
                          const SizedBox(width: AppSpacing.xs),
                        ],
                        Flexible(
                          child: Text(
                            labels[i],
                            textAlign: TextAlign.center,
                            style: EviaTheme.label.copyWith(
                              color: i == selected
                                  ? activeForeground
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

class ActivityInfo extends StatelessWidget {
  const ActivityInfo(
    this.text, {
    required this.icon,
    this.color = AppColors.primarySoft,
    super.key,
  });
  final String text;
  final Widget icon;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.lg),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(AppRadius.medium),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        icon,
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: EviaTheme.caption.copyWith(
              color: color == AppColors.primarySoft
                  ? ActivityTheme.actionDark
                  : AppColors.textSecondary,
            ),
          ),
        ),
      ],
    ),
  );
}

class DetailRow extends StatelessWidget {
  const DetailRow(this.label, this.value, {this.icon, this.color, super.key});
  final String label, value;
  final Widget? icon;
  final Color? color;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[icon!, const SizedBox(width: AppSpacing.sm)],
        Expanded(flex: 2, child: Text(label, style: EviaTheme.caption)),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          flex: 3,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: EviaTheme.label.copyWith(color: color),
          ),
        ),
      ],
    ),
  );
}

class ActivityOverlay extends StatelessWidget {
  const ActivityOverlay({
    required this.background,
    required this.child,
    this.bottom = false,
    super.key,
  });
  final Widget background, child;
  final bool bottom;
  @override
  Widget build(BuildContext context) => Stack(
    children: [
      ExcludeSemantics(child: IgnorePointer(child: background)),
      Positioned.fill(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
          child: const ColoredBox(color: ActivityTheme.scrim),
        ),
      ),
      Align(
        alignment: bottom ? Alignment.bottomCenter : Alignment.center,
        child: Padding(
          padding: bottom
              ? EdgeInsets.zero
              : const EdgeInsets.all(AppSpacing.xl),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight:
                  MediaQuery.sizeOf(context).height * (bottom ? .8 : .86),
            ),
            child: Material(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.extraLarge),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: child,
              ),
            ),
          ),
        ),
      ),
    ],
  );
}

Future<void> copyActivityCode(BuildContext context, String code) async {
  await Clipboard.setData(ClipboardData(text: code));
  if (context.mounted) {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Code copied.')));
  }
}

void showActivityHelp(BuildContext context, String title, String message) =>
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: EviaTheme.section),
              const SizedBox(height: AppSpacing.md),
              Text(message),
            ],
          ),
        ),
      ),
    );

String monthName(int month) => const [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
][month - 1];
