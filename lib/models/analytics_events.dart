/// Only content IDs and enumerated values may cross the telemetry boundary.
abstract final class AnalyticsEvents {
  static const _schema = <String, Map<String, Type>>{
    'ai_request': {},
    'ai_result_accepted': {},
    'ai_error': {},
    'login': {'method': String},
    'sign_up': {'method': String},
    'logout': {},
    'view_event': {'event_id': String, 'participation_mode': String},
    'register_event': {'event_id': String, 'deposit_coins': int},
    'cancel_registration': {'event_id': String},
    'check_in_event': {'event_id': String, 'mode': String},
    'view_reward': {'reward_id': String, 'price_coins': int},
    'redeem_reward': {
      'reward_id': String,
      'cost_coins': int,
      'fulfillment_type': String,
    },
    'generate_report': {'report_type': String, 'file_size_kb': int},
    'upload_report': {'report_type': String, 'file_size_kb': int},
    'search': {
      'search_term': String,
      'loaded_count': int,
      'has_more': int,
      'outcome': String,
    },
    'action_error': {'action': String, 'error_code': String},
  };
  static const actions = {
    'login',
    'sign_up',
    'logout',
    'search',
    'view_event',
    'register_event',
    'cancel_registration',
    'check_in_event',
    'view_reward',
    'redeem_reward',
    'generate_report',
    'upload_report',
    'claim_daily',
    'claim_milestone',
  };
  static const searchTerms = {
    'free_text_redacted',
    'all',
    'technology',
    'music',
    'arts',
    'sports',
    'photography',
    'career',
    'volunteer',
    'business',
    'gaming',
    'environment',
    'workshop',
    'academic',
    'community',
    'social',
  };
  static const searchOutcomes = {'data', 'empty', 'error'};

  /// Redacts user-entered queries and maps category selections to the allowlist.
  static String redactSearchTerm({
    required String query,
    String category = 'All',
    String filterCategory = 'All',
  }) {
    if (query.trim().isNotEmpty) return 'free_text_redacted';
    final selected = category != 'All' ? category : filterCategory;
    final slug = selected.trim().toLowerCase().replaceAll(' ', '_');
    if (slug.isEmpty || slug == 'all') return 'all';
    if (searchTerms.contains(slug)) return slug;
    return 'free_text_redacted';
  }

  static const errorCodes = {
    'invalid_credential',
    'network_request_failed',
    'too_many_requests',
    'cancelled',
    'unavailable',
    'deadline-exceeded',
    'permission-denied',
    'unauthenticated',
    'OUT_OF_STOCK',
    'INSUFFICIENT_COINS',
    'PRICE_CHANGED',
    'TERMS_CHANGED',
    'EVENT_FULL',
    'REWARD_INACTIVE',
    'NOT_FOUND',
    'report_failed',
    'unexpected',
  };

  static void validate(String name, Map<String, Object> parameters) {
    final schema = _schema[name];
    if (schema == null || parameters.length != schema.length) {
      throw ArgumentError('Unknown analytics event or parameters');
    }
    for (final field in schema.entries) {
      final value = parameters[field.key];
      if ((field.value == int && (value is! int || value < 0)) ||
          (field.value == String &&
              (value is! String ||
                  !RegExp(r'^[a-zA-Z0-9_-]{1,100}$').hasMatch(value)))) {
        throw ArgumentError('Invalid analytics parameter');
      }
    }
    void allowed(String key, Set<String> values) {
      if (parameters.containsKey(key) && !values.contains(parameters[key])) {
        throw ArgumentError('Invalid analytics value');
      }
    }

    allowed('method', {'google', 'password'});
    allowed('participation_mode', {'registration', 'walk_in'});
    allowed('mode', {'registered', 'walk_in'});
    allowed('fulfillment_type', {'voucher', 'physical'});
    allowed('report_type', {'coin_history_csv', 'coin_history_pdf'});
    allowed('search_term', searchTerms);
    allowed('outcome', searchOutcomes);
    if (name == 'search') {
      final hasMore = parameters['has_more'];
      if (hasMore != 0 && hasMore != 1) {
        throw ArgumentError('Invalid analytics value');
      }
    }
    allowed('action', actions);
    allowed('error_code', errorCodes);
  }
}
