import 'package:cloud_functions/cloud_functions.dart';

import '../core/errors/app_exception.dart';
import 'backend_service.dart';

class FirebaseBackendService implements BackendService {
  FirebaseBackendService(this.ready);
  final Future<void> Function() ready;

  @override
  Future<Map<String, dynamic>> call(
    String operation, [
    Map<String, dynamic> input = const {},
  ]) async {
    await ready();
    try {
      final result =
          await FirebaseFunctions.instanceFor(region: 'asia-southeast1')
              .httpsCallable(
                operation,
                options: HttpsCallableOptions(
                  timeout: const Duration(seconds: 25),
                ),
              )
              .call<dynamic>(input);
      return Map<String, dynamic>.from(result.data as Map);
    } on FirebaseFunctionsException catch (error) {
      final details = error.details;
      final code = details is Map && details['code'] is String
          ? details['code'] as String
          : error.code;
      const messages = {
        'EVENT_FULL': 'This event is full. No coins were charged.',
        'EVENT_NOT_OPEN': 'Registration has closed for this event.',
        'QUOTE_CHANGED': 'The deposit has changed. Review the updated event before confirming again.',
        'TERMS_CHANGED': 'The terms have changed. Review the updated event before confirming again.',
        'INSUFFICIENT_COINS': 'Not enough available coins for this deposit.',
        'ALREADY_REGISTERED':
            'You are already registered. Open your ticket in My Events.',
        'ONBOARDING_REQUIRED': 'Save at least 3 interests before continuing.',
        'EMAIL_REQUIRED': 'Enter a valid email address.',
        'ACCOUNT_DISABLED': 'This account is unavailable.',
        'EVENT_NOT_FOUND': 'This event is no longer available.',
        'NO_ACTIVE_TICKET': 'There is no active ticket for this event.',
        'NOT_REGISTERED': 'You do not have a ticket for this event.',
        'ALREADY_CHECKED_IN':
            'Attendance has already been confirmed for this event.',
        'ALREADY_ATTENDED': 'An attended registration cannot be cancelled.',
        'ALREADY_CANCELLED': 'This registration has already been cancelled.',
        'CANNOT_CANCEL': 'This registration can no longer be cancelled.',
        'QR_INVALID':
            'This QR is invalid or expired. Ask the organizer for a new QR.',
        'QR_EVENT_MISMATCH': 'This QR or code belongs to another event.',
        'CODE_INVALID': 'This event code is invalid.',
        'CODE_EXPIRED':
            'This event code has expired. Ask the organizer for a new code.',
        'CODE_RATE_LIMITED':
            'Too many attempts. Wait a minute before trying again.',
        'OUTSIDE_CHECKIN_WINDOW': 'Check-in is not open for this event.',
        'DEMO_NOT_ALLOWED':
            'Demo check-in is not enabled for this account or event.',
        'VALIDATION_FAILED': 'Check the information you entered and try again.',
        'unauthenticated': 'Please log in again.',
        'UNAUTHENTICATED': 'Please log in again.',
        'unavailable':
            'Cannot reach the service. Check your connection and retry.',
        'deadline-exceeded': 'The request timed out. Retry the same action to recover its result.',
      };
      throw AppException(
        code: code,
        message:
            messages[code] ??
            'The server could not complete this request. Please retry.',
      );
    } on AppException {
      rethrow;
    } catch (_) {
      throw const AppException(
        code: 'invalid_response',
        message: 'Could not read the server response. Please retry.',
      );
    }
  }
}
