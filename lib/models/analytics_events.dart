/// Only content IDs and enumerated values may cross the telemetry boundary.
abstract final class AnalyticsEvents {
  static const _schema = <String, Map<String, Type>>{
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
    'action_error': {'action': String, 'error_code': String},
  };
  static const actions = {
    'login',
    'sign_up',
    'logout',
    'view_event',
    'register_event',
    'cancel_registration',
    'check_in_event',
    'view_reward',
    'redeem_reward',
    'generate_report',
    'claim_daily',
    'claim_milestone',
  };
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
    allowed('report_type', {'coin_history_csv'});
    allowed('action', actions);
    allowed('error_code', errorCodes);
  }
}
