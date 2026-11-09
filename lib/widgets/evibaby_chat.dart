import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/flow1_models.dart';
import '../theme/app_tokens.dart';
import '../theme/evia_theme.dart';
import '../viewmodels/evibaby_view_model.dart';
import 'app_text_field.dart';
import 'evia_widgets.dart';

class EvibabyLauncher extends StatelessWidget {
  const EvibabyLauncher({super.key});

  @override
  Widget build(BuildContext context) => FloatingActionButton(
    heroTag: 'evibaby',
    tooltip: 'Trò chuyện với Evibaby',
    backgroundColor: AppColors.primary,
    foregroundColor: AppColors.surface,
    elevation: AppElevation.none,
    onPressed: () {
      final router = GoRouter.of(context);
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        backgroundColor: AppColors.background,
        constraints: const BoxConstraints(maxWidth: AppSizes.contentMaxWidth),
        builder: (sheetContext) {
          final keyboard = MediaQuery.viewInsetsOf(sheetContext).bottom;
          return Padding(
            padding: EdgeInsets.only(bottom: keyboard),
            child: SizedBox(
              height: (MediaQuery.sizeOf(sheetContext).height - keyboard) * 0.9,
              child: EvibabyChat(
                onOpenEvent: (eventId) {
                  Navigator.of(sheetContext).pop();
                  router.push(
                    Uri(
                      path: '/event/about',
                      queryParameters: {'event': eventId},
                    ).toString(),
                  );
                },
              ),
            ),
          );
        },
      );
    },
    child: const Icon(Icons.support_agent_rounded),
  );
}

class EvibabyChat extends ConsumerStatefulWidget {
  const EvibabyChat({required this.onOpenEvent, super.key});
  final ValueChanged<String> onOpenEvent;
  @override
  ConsumerState<EvibabyChat> createState() => _EvibabyChatState();
}

class _EvibabyChatState extends ConsumerState<EvibabyChat> {
  late final TextEditingController _input;
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _input = TextEditingController(
      text: ref.read(evibabyViewModelProvider).draft,
    );
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    await ref.read(evibabyViewModelProvider.notifier).send(_input.text);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(evibabyViewModelProvider);
    ref.listen(evibabyViewModelProvider, (previous, next) {
      if (_input.text != next.draft) _input.text = next.draft;
      if (previous?.messages.length != next.messages.length ||
          previous?.busy != next.busy ||
          previous?.error != next.error) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _scroll.hasClients) {
            _scroll.jumpTo(0);
          }
        });
      }
    });
    return SafeArea(
      top: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                const Icon(
                  Icons.support_agent_rounded,
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Evibaby',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: 'Đóng trò chuyện',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView(
              controller: _scroll,
              reverse: true,
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: <Widget>[
                for (final message in state.messages)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: message.fromUser
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        EviaCard(
                          color: message.fromUser
                              ? AppColors.primarySoft
                              : AppColors.surface,
                          child: SelectableText(message.text),
                        ),
                        for (final event in message.events)
                          Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.sm),
                            child: _EventCard(
                              event: event,
                              onTap: () => widget.onOpenEvent(event.id),
                            ),
                          ),
                      ],
                    ),
                  ),
                if (state.busy)
                  Semantics(
                    liveRegion: true,
                    child: const Text('Evibaby đang xem thông tin cho bạn nè…'),
                  ),
                if (state.error != null)
                  Semantics(
                    liveRegion: true,
                    child: EviaCard(
                      color: AppColors.errorSurface,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: AppColors.error,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(state.error!),
                          TextButton(
                            onPressed: _send,
                            child: const Text('Thử gửi lại'),
                          ),
                        ],
                      ),
                    ),
                  ),
              ].reversed.toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'Nhắn cho Evibaby',
                    hintText: 'Bạn muốn tìm sự kiện gì?',
                    controller: _input,
                    enabled: !state.busy,
                    onChanged: ref
                        .read(evibabyViewModelProvider.notifier)
                        .updateDraft,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                IconButton.filled(
                  tooltip: 'Gửi tin nhắn',
                  onPressed: state.busy ? null : _send,
                  constraints: const BoxConstraints(
                    minWidth: AppSizes.minimumTouchTarget,
                    minHeight: AppSizes.minimumTouchTarget,
                  ),
                  icon: const Icon(Icons.send_rounded),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event, required this.onTap});
  final Flow1Event event;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Xem sự kiện ${event.title}',
    child: EviaCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.small),
                child: event.imageUrl == null
                    ? const SizedBox(
                        width: EviaTheme.compactThumbnail,
                        height: EviaTheme.compactThumbnail,
                        child: ColoredBox(
                          color: AppColors.primarySoft,
                          child: Icon(Icons.event, color: AppColors.primary),
                        ),
                      )
                    : catalogImage(
                        event.imageUrl,
                        event.imageUrl!,
                        width: EviaTheme.compactThumbnail,
                        height: EviaTheme.compactThumbnail,
                        fit: BoxFit.cover,
                      ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(eventDate(event.start)),
                    Text(event.venue['name'] as String),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            event.walkIn
                ? 'Walk-in · Tham gia và quét QR tại sự kiện'
                : 'Cọc ${event.deposit} xu · Thưởng ${event.reward} xu khi tham dự hợp lệ',
          ),
          if (!event.walkIn)
            Text(
              event.registrationOpen(DateTime.now())
                  ? event.spots == null
                        ? 'Không giới hạn chỗ'
                        : 'Còn ${event.spots} chỗ'
                  : 'Hiện không thể đăng ký',
            ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Xem chi tiết →',
            style: TextStyle(color: AppColors.primary),
          ),
        ],
      ),
    ),
  );
}
