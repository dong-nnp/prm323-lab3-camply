import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/errors/app_exception.dart';
import '../core/providers/repository_providers.dart';
import '../models/evibaby_models.dart';
import 'authentication_view_model.dart';

final evibabyViewModelProvider =
    NotifierProvider<EvibabyViewModel, EvibabyState>(EvibabyViewModel.new);

class EvibabyViewModel extends Notifier<EvibabyState> {
  int _session = 0;
  @override
  EvibabyState build() {
    ref.watch(
      authenticationViewModelProvider.select((s) => s.asData?.value.userId),
    );
    _session++;
    return const EvibabyState();
  }

  void updateDraft(String value) {
    state = EvibabyState(
      messages: state.messages,
      busy: state.busy,
      draft: value,
    );
  }

  Future<bool> send(String value) async {
    if (state.busy) return false;
    final message = value.trim();
    if (message.isEmpty || message.length > 1500) {
      state = EvibabyState(
        messages: state.messages,
        draft: value,
        error: message.isEmpty
            ? 'Bạn nhắn điều muốn hỏi cho Evibaby nha.'
            : 'Bạn viết gọn trong 1.500 ký tự giúp Evibaby nha.',
      );
      return false;
    }
    final previous = state.messages;
    final session = _session;
    final history = previous.skip(1).toList();
    state = EvibabyState(
      messages: List.unmodifiable([
        ...previous,
        EvibabyMessage(text: message, fromUser: true),
      ]),
      draft: value,
      busy: true,
    );
    try {
      final reply = await ref
          .read(evibabyRepositoryProvider)
          .send(
            message,
            history.length > 10
                ? history.sublist(history.length - 10)
                : history,
          );
      if (!ref.mounted || session != _session) return false;
      state = EvibabyState(
        messages: List.unmodifiable([...state.messages, reply]),
      );
      return true;
    } catch (error) {
      if (!ref.mounted || session != _session) return false;
      const messages = {
        'backend_unavailable': 'Evibaby chưa kết nối Firebase ở bản app này. Bạn vẫn có thể tìm sự kiện ở Discover nha.',
        'EVIBABY_NOT_CONFIGURED':
            'Evibaby đang chờ cấu hình DeepSeek. Bạn quay lại sau nha.',
        'not-found':
            'Evibaby chưa được triển khai trên server. Bạn quay lại sau nha.',
        'EVIBABY_RATE_LIMITED': 'Evibaby đã đạt giới hạn lượt tư vấn. Bạn thử lại sau một lúc nha; giới hạn ngày sẽ làm mới vào ngày mai.',
        'UNAUTHENTICATED': 'Bạn đăng nhập Evia để trò chuyện với Evibaby nha.',
        'unauthenticated': 'Bạn đăng nhập Evia để trò chuyện với Evibaby nha.',
        'ACCOUNT_DISABLED': 'Tài khoản hiện chưa thể dùng tư vấn. Bạn kiểm tra lại tài khoản nha.',
        'EVIBABY_EVENT_CHANGED': 'Thông tin sự kiện vừa thay đổi. Bạn gửi lại để Evibaby xem bản mới nha.',
      };
      state = EvibabyState(
        messages: previous,
        draft: value,
        error: error is AppException
            ? messages[error.code] ?? 'Evibaby chưa kết nối được dịch vụ tư vấn. Bạn thử gửi lại nha.'
            : 'Evibaby gặp trục trặc khi đọc câu trả lời. Bạn thử lại nha.',
      );
      return false;
    }
  }
}
