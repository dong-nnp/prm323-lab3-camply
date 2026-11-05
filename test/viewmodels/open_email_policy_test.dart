import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab03/core/utils/fpt_identity.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prm393_lab03/core/providers/service_providers.dart';
import 'package:prm393_lab03/viewmodels/sign_up_view_model.dart';
import 'package:prm393_lab03/viewmodels/evia_view_model.dart';

import '../helpers/sign_up_test_service.dart';

class MailTestService extends SignUpTestService {
  String? loginEmail, resetEmail;
  @override
  Future<void> signInWithEmailPassword(String email, String password) async {
    loginEmail = email;
  }

  @override
  Future<void> resetPassword(String email) async {
    resetEmail = email;
  }
}

void main() {
  test('email accepts any valid domain and normalizes identity', () {
    for (final value in [
      ' person@gmail.com ',
      'Person@Outlook.COM',
      'name+event@yahoo.co.uk',
      'student@custom-domain.org',
      'student@fpt.edu.vn',
      'student@fe.edu.vn',
      'student@fpt.edu.vn.attacker.test',
    ]) {
      expect(FptIdentity.validEmail(value), isTrue, reason: value);
    }
    expect(FptIdentity.email(' Person@Gmail.COM '), 'person@gmail.com');
  });
  test(
    'bad email syntax is rejected while student ID format stays unchanged',
    () {
      for (final value in [
        '',
        'no-at-sign',
        'a@@example.com',
        'person@example',
        'person@.com',
        'person@-example.com',
        '.person@example.com',
        'a..b@example.com',
        'a b@example.com',
        'a@example..com',
        '${'a' * 245}@example.com',
      ]) {
        expect(FptIdentity.validEmail(value), isFalse, reason: value);
      }
      expect(FptIdentity.validStudentId(' se123456 '), isTrue);
      expect(FptIdentity.validStudentId('STU-123456'), isFalse);
    },
  );
  test('sign-up, login and reset accept public email providers through existing ViewModels', () async {
    final service = MailTestService();
    final c = ProviderContainer(
      overrides: [authenticationServiceProvider.overrideWithValue(service)],
    );
    final subscription = c.listen(signUpViewModelProvider, (_, _) {});
    final signup = c.read(signUpViewModelProvider.notifier);
    signup.acceptTerms(true);
    await signup.createAccount(
      fullName: 'Test Person',
      email: ' person@gmail.com ',
      password: 'valid-password',
      confirmation: 'valid-password',
    );
    expect(service.createCalls, 1);
    expect(service.submittedEmail, 'person@gmail.com');
    final login = c.read(eviaViewModelProvider.notifier);
    await login.login('person@outlook.com', 'valid-password');
    expect(service.loginEmail, 'person@outlook.com');
    await login.resetPassword('person@yahoo.com');
    expect(service.resetEmail, 'person@yahoo.com');
    await login.login('not-an-email', 'valid-password');
    expect(service.loginEmail, 'person@outlook.com');
    expect(
      c.read(eviaViewModelProvider).message,
      'Enter a valid email address.',
    );
    subscription.close();
    c.dispose();
    await service.close();
  });
}
