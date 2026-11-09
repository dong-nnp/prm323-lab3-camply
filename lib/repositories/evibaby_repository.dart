import '../core/errors/app_exception.dart';
import '../models/evibaby_models.dart';
import '../models/flow1_models.dart';
import '../services/backend_service.dart';

class EvibabyRepository {
  const EvibabyRepository(this.backend);
  final BackendService backend;

  Future<EvibabyMessage> send(
    String message,
    List<EvibabyMessage> history,
  ) async {
    final result = await backend.call('chatWithEvibaby', {
      'message': message,
      'history': history.map((m) => m.context).toList(growable: false),
    });
    try {
      final text = result['reply'] as String;
      final events = jsonRows(result['events']).map(Flow1Event.new).toList();
      if (text.trim().isEmpty || text.length > 3500 || events.length > 3) {
        throw const FormatException();
      }
      for (final event in events) {
        if (!RegExp(r'^[A-Za-z0-9_-]{1,128}$').hasMatch(event.id) ||
            event.data['status'] != 'published' ||
            event.data['visibility'] != 'public' ||
            event.venue['name'] is! String) {
          throw const FormatException();
        }
      }
      return EvibabyMessage(text: text, events: List.unmodifiable(events));
    } catch (_) {
      throw const AppException(
        code: 'EVIBABY_INVALID_RESPONSE',
        message: 'Evibaby chưa đọc được câu trả lời. Bạn thử lại nha.',
      );
    }
  }
}
