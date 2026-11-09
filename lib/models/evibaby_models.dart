import 'flow1_models.dart';

class EvibabyMessage {
  const EvibabyMessage({
    required this.text,
    this.fromUser = false,
    this.events = const [],
  });
  final String text;
  final bool fromUser;
  final List<Flow1Event> events;

  Map<String, String> get context => {
    'role': fromUser ? 'user' : 'assistant',
    'content': events.isEmpty
        ? text
        : '$text\n[Sự kiện đã giới thiệu: ${events.map((e) => e.id).join(', ')}]',
  };
}

class EvibabyState {
  const EvibabyState({
    this.messages = const [
      EvibabyMessage(
        text:
            'Chào bạn, Evibaby là linh vật của Evia đây nè! 💚 '
            'Bạn thích sự kiện gì, muốn đi khi nào và ở đâu? '
            'Evibaby sẽ xem sự kiện thật để tư vấn cho bạn nha.\n\n'
            'Nội dung chat được gửi tới dịch vụ AI để trả lời. '
            'Lịch sử trong app chỉ được giữ trong phiên này.',
      ),
    ],
    this.busy = false,
    this.draft = '',
    this.error,
  });
  final List<EvibabyMessage> messages;
  final bool busy;
  final String draft;
  final String? error;
}
