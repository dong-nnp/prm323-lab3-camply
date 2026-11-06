import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import '../theme/evia_theme.dart';
import 'evia_widgets.dart';

enum SkeletonLayout { discover, list, detail, rewards }

/// Static placeholders respect reduced motion and never impersonate real data.
class EviaSkeleton extends StatelessWidget {
  const EviaSkeleton({this.layout = SkeletonLayout.list, super.key});
  final SkeletonLayout layout;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Loading content',
    liveRegion: true,
    child: ExcludeSemantics(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (layout != SkeletonLayout.list) ...[
            if (layout == SkeletonLayout.discover) ...[
              const _Block(height: AppSizes.minimumTouchTarget),
              const SizedBox(height: AppSpacing.lg),
            ],
            const _Block(height: EviaTheme.heroHeight),
            const SizedBox(height: AppSpacing.xl),
            const _Block(width: EviaTheme.phoneWidth / 2),
            const SizedBox(height: AppSpacing.md),
            const _Block(),
            const SizedBox(height: AppSpacing.xl),
          ],
          if (layout == SkeletonLayout.discover ||
              layout == SkeletonLayout.rewards)
            const Row(
              children: [
                Expanded(child: _Card()),
                SizedBox(width: AppSpacing.md),
                Expanded(child: _Card()),
              ],
            )
          else
            for (var i = 0; i < 3; i++) ...[
              const _Card(horizontal: true),
              const SizedBox(height: AppSpacing.lg),
            ],
        ],
      ),
    ),
  );
}

class EviaLoadingPage extends StatelessWidget {
  const EviaLoadingPage({
    this.layout = SkeletonLayout.list,
    this.title = 'Loading…',
    this.footer,
    super.key,
  });
  final SkeletonLayout layout;
  final String title;
  final Widget? footer;

  @override
  Widget build(BuildContext context) => EviaPage(
    header: Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          if (Navigator.of(context).canPop()) const BackButton(),
          Expanded(child: Text(title, style: EviaTheme.section)),
        ],
      ),
    ),
    footer: footer,
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: EviaSkeleton(layout: layout),
    ),
  );
}

class _Card extends StatelessWidget {
  const _Card({this.horizontal = false});
  final bool horizontal;

  @override
  Widget build(BuildContext context) => EviaCard(
    child: horizontal
        ? const Row(
            children: [
              _Block(width: EviaTheme.thumbnail, height: EviaTheme.thumbnail),
              SizedBox(width: AppSpacing.md),
              Expanded(child: _Lines()),
            ],
          )
        : const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(aspectRatio: 1.5, child: _Block()),
              SizedBox(height: AppSpacing.lg),
              _Lines(),
            ],
          ),
  );
}

class _Lines extends StatelessWidget {
  const _Lines();

  @override
  Widget build(BuildContext context) => const Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _Block(),
      SizedBox(height: AppSpacing.md),
      _Block(),
      SizedBox(height: AppSpacing.sm),
      FractionallySizedBox(widthFactor: 0.6, child: _Block()),
    ],
  );
}

class _Block extends StatelessWidget {
  const _Block({this.width, this.height = AppSpacing.lg});
  final double? width;
  final double height;

  @override
  Widget build(BuildContext context) => Container(
    width: width ?? double.infinity,
    height: height,
    decoration: BoxDecoration(
      color: AppColors.border,
      borderRadius: BorderRadius.circular(AppRadius.medium),
    ),
  );
}
