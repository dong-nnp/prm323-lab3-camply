import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab03/core/errors/app_exception.dart';
import 'package:prm393_lab03/core/providers/service_providers.dart';
import 'package:prm393_lab03/models/account_creation_result.dart';
import 'package:prm393_lab03/models/sign_up_state.dart';
import 'package:prm393_lab03/services/pending_firebase_services.dart';
import 'package:prm393_lab03/viewmodels/sign_up_view_model.dart';

import '../helpers/sign_up_test_service.dart';

void main() {
  late ProviderContainer c;
  late SignUpTestService service;
  late SignUpViewModel vm;
  setUp(() {
    service = SignUpTestService();
    c = ProviderContainer(
      overrides: [authenticationServiceProvider.overrideWithValue(service)],
    );
    c.listen(signUpViewModelProvider, (_, _) {});
    vm = c.read(signUpViewModelProvider.notifier);
  });
  tearDown(() async {
    c.dispose();
    await service.close();
  });
  Future<void> submit({
    String password = 'correct-password',
    String? confirmation,
  }) => vm.createAccount(
    fullName: ' Alex Example ',
    email: ' alex@fpt.edu.vn ',
    password: password,
    confirmation: confirmation ?? password,
  );

  test(
    'required fields, email, confirmation and terms block submission',
    () async {
      expect(c.read(signUpViewModelProvider).acceptedTerms, isFalse);
      await vm.createAccount(
        fullName: ' ',
        email: 'invalid',
        password: '',
        confirmation: '',
      );
      expect(
        c.read(signUpViewModelProvider).errors.keys,
        containsAll(['name', 'email', 'password', 'confirmation', 'terms']),
      );
      expect(service.createCalls, 0);
      vm.acceptTerms(true);
      await submit(confirmation: 'different');
      expect(
        c.read(signUpViewModelProvider).errors['confirmation'],
        'Passwords do not match.',
      );
      expect(service.createCalls, 0);
    },
  );
  test(
    'password length comes from the adapter, not an invented default',
    () async {
      vm.acceptTerms(true);
      expect(vm.minimumPasswordLength, isNull);
      service.minimumPasswordLength = 10;
      await submit(password: 'short');
      expect(
        c.read(signUpViewModelProvider).errors['password'],
        'Use at least 10 characters.',
      );
      expect(service.createCalls, 0);
    },
  );
  test(
    'one request, trimmed identity, and wait for the real session',
    () async {
      final pending = Completer<AccountCreationResult>();
      service.create = () => pending.future;
      vm.acceptTerms(true);
      final first = submit();
      await submit();
      expect(service.createCalls, 1);
      expect(c.read(signUpViewModelProvider).isBusy, isTrue);
      expect(service.submittedName, 'Alex Example');
      expect(service.submittedEmail, 'alex@fpt.edu.vn');
      expect(service.submittedTerms, isTrue);
      pending.complete(AccountCreationResult.signedIn);
      await first;
      expect(
        c.read(signUpViewModelProvider).submission,
        SignUpSubmission.waitingForSession,
      );
    },
  );
  test('email conflicts are inline and edits clear that error', () async {
    service.create = () async => throw const AppException(
      code: 'email_already_in_use',
      message: 'Safe error',
    );
    vm.acceptTerms(true);
    await submit();
    expect(
      c.read(signUpViewModelProvider).errors['email'],
      contains('already uses'),
    );
    expect(c.read(signUpViewModelProvider).isBusy, isFalse);
    vm.edit('email');
    expect(c.read(signUpViewModelProvider).errors, isEmpty);
  });
  test(
    'verification stays on the form rather than claiming signed in',
    () async {
      service.create = () async => AccountCreationResult.verificationRequired;
      vm.acceptTerms(true);
      await submit();
      expect(c.read(signUpViewModelProvider).verificationRequired, isTrue);
      expect(c.read(signUpViewModelProvider).submission, SignUpSubmission.idle);
      expect(
        c.read(signUpViewModelProvider).message,
        contains('verify your account'),
      );
    },
  );
  test(
    'Google requires terms but does not require manual password fields',
    () async {
      await vm.continueWithGoogle();
      expect(service.googleCalls, 0);
      vm.acceptTerms(true);
      await vm.continueWithGoogle();
      expect(service.googleCalls, 1);
      expect(service.createCalls, 0);
      expect(
        c.read(signUpViewModelProvider).submission,
        SignUpSubmission.waitingForSession,
      );
    },
  );
  test('dispose during submission does not write disposed state', () async {
    final pending = Completer<AccountCreationResult>();
    service.create = () => pending.future;
    vm.acceptTerms(true);
    final future = submit();
    c.dispose();
    pending.complete(AccountCreationResult.signedIn);
    await expectLater(future, completes);
  });
  test(
    'pending runtime adapter never returns a fake account or password rule',
    () async {
      const pending = PendingFirebaseServices();
      expect(pending.minimumPasswordLength, isNull);
      await expectLater(
        pending.createAccount(
          fullName: 'Alex',
          email: 'alex@fpt.edu.vn',
          password: 'example',
          acceptedTerms: true,
        ),
        throwsA(isA<AppException>()),
      );
    },
  );
}
