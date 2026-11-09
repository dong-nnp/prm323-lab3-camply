import 'dart:convert';

import '../core/errors/app_exception.dart';
import '../models/evia_models.dart';
import '../services/ai_filter_service.dart';

final class AiFilterRepository {
  AiFilterRepository(this.service);
  final AiFilterService service;
  // Only recognized event vocabulary leaves the device, never the original text.
  static const vocabulary =
      'find event events workshop music sports arts seminar volunteer competition career social technology business other all this next week month morning afternoon evening under over hour hours duration any today tomorrow weekend 1 2 3 tìm sự kiện âm nhạc thể thao nghệ thuật hội thảo tình nguyện nghề nghiệp công nghệ kinh doanh tuần tháng này tới sau sáng chiều tối dưới trên giờ hôm nay mai cuối';
  static String keywords(String input) {
    if (input.trim().isEmpty || input.length > 300) {
      throw const AppException(
        code: 'invalid_input',
        message: 'Enter an event preference of 1–300 characters.',
      );
    }
    final allowed = vocabulary.split(' ').toSet();
    final words = RegExp(r'[a-zA-ZÀ-ỹ]+|(?<![a-z0-9])[1-3](?![a-z0-9])')
        .allMatches(input.toLowerCase())
        .map((match) => match.group(0)!)
        .where(allowed.contains)
        .toList();
    if (words.isEmpty) {
      throw const AppException(
        code: 'invalid_input',
        message: 'Describe a category, date, time or duration.',
      );
    }
    return words.join(' ');
  }

  Future<EventFilters> suggest(
    String input,
    Map<String, List<String>> choices,
  ) async => parse(await service.suggest(keywords(input), choices), choices);
  static EventFilters parse(
    String source,
    Map<String, List<String>> choices, {
    DateTime? now,
  }) {
    try {
      final json = jsonDecode(source);
      if (json is! Map<String, dynamic> || json.length != choices.length) {
        throw const FormatException();
      }
      var filters = const EventFilters();
      for (final entry in choices.entries) {
        final value = json[entry.key];
        if (value is! String || !entry.value.contains(value)) {
          throw const FormatException();
        }
        filters = filters.withValue(entry.key, value);
      }
      final clock = now ?? DateTime.now();
      final today = DateTime(clock.year, clock.month, clock.day);
      if (filters.date == 'Today') return filters.withRange(today, today);
      if (filters.date == 'Tomorrow') {
        final tomorrow = today.add(const Duration(days: 1));
        return filters.withRange(tomorrow, tomorrow);
      }
      if (filters.date == 'This weekend') {
        final start = today.add(
          Duration(days: today.weekday == 7 ? 0 : 6 - today.weekday),
        );
        final end = start.add(Duration(days: today.weekday == 7 ? 0 : 1));
        return filters.withRange(start, end);
      }
      return filters;
    } catch (_) {
      throw const AppException(
        code: 'invalid_result',
        message: 'AI returned unsupported filters. Try again or choose filters manually.',
      );
    }
  }
}
