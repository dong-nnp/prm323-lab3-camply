import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers/repository_providers.dart';
import '../core/utils/exception_mapper.dart';
import '../models/account_creation_result.dart';
import '../models/sign_up_state.dart';
import '../core/utils/fpt_identity.dart';
import 'authentication_view_model.dart';

final signUpViewModelProvider =
    NotifierProvider.autoDispose<SignUpViewModel, SignUpState>(
      SignUpViewModel.new,
    );

class SignUpViewModel extends Notifier<SignUpState> {
  @override
  SignUpState build() => const SignUpState();

  int? get minimumPasswordLength =>
      ref.read(authenticationRepositoryProvider).minimumPasswordLength;

  void edit(String field) {
    if (state.isBusy) return;
    state = state.copy(
      errors: {...state.errors}..remove(field),
      verificationRequired: false,
    );
  }

  void acceptTerms(bool accepted) {
    if (state.isBusy) return;
    state = state.copy(
      acceptedTerms: accepted,
      errors: {...state.errors}..remove('terms'),
    );
  }

  void togglePassword() => state = state.copy(
    showPassword: !state.showPassword,
    message: state.message,
  );
  void toggleConfirmation() => state = state.copy(
    showConfirmation: !state.showConfirmation,
    message: state.message,
  );

  Future<void> createAccount({
    required String fullName,
    required String email,
    required String password,
    required String confirmation,
  }) async {
    if (state.isBusy) return;
    final minimum = minimumPasswordLength;
    final errors = <String, String>{
      if (fullName.trim().isEmpty) 'name': 'Enter your full name.',
      if (!FptIdentity.validEmail(email))
        'email': 'Enter a valid email address.',
      if (password.isEmpty)
        'password': 'Create a password.'
      else if (minimum != null && password.length < minimum)
        'password': 'Use at least $minimum characters.',
      if (confirmation.isEmpty)
        'confirmation': 'Re-enter your password.'
      else if (confirmation != password)
        'confirmation': 'Passwords do not match.',
      if (!state.acceptedTerms)
        'terms': 'Please agree to the terms and privacy policy.',
    };
    state = state.copy(errors: errors, verificationRequired: false);
    if (errors.isNotEmpty) return;
    state = state.copy(submission: SignUpSubmission.account);
    final authentication = ref.read(authenticationViewModelProvider.notifier);
    final analytics = ref.read(analyticsRepositoryProvider);
    try {
      final result = await ref
          .read(authenticationRepositoryProvider)
          .createAccount(
            fullName: fullName.trim(),
            email: email.trim(),
            password: password,
            acceptedTerms: state.acceptedTerms,
          );
      if (result == AccountCreationResult.signedIn) {
        authentication.recordSignUp();
      } else {
        unawaited(
          analytics.track('sign_up', parameters: {'method': 'password'}),
        );
      }
      if (!ref.mounted) return;
      state = state.copy(
        submission: result == AccountCreationResult.signedIn
            ? SignUpSubmission.waitingForSession
            : SignUpSubmission.idle,
        verificationRequired:
            result == AccountCreationResult.verificationRequired,
        message: result == AccountCreationResult.verificationRequired
            ? 'Check your email to verify your account, then log in.'
            : 'Account created. Waiting for your sign-in session…',
      );
      // Router reacts to the observed real session, never to a local fake login.
    } catch (error) {
      if (ref.mounted) _showError(error, google: false);
    }
  }

  Future<void> continueWithGoogle() async {
    if (state.isBusy) return;
    if (!state.acceptedTerms) {
      state = state.copy(
        errors: {'terms': 'Please agree to the terms and privacy policy.'},
      );
      return;
    }
    state = state.copy(
      submission: SignUpSubmission.google,
      errors: {},
      verificationRequired: false,
    );
    final authentication = ref.read(authenticationViewModelProvider.notifier);
    try {
      await ref.read(authenticationRepositoryProvider).signInWithGoogle();
      authentication.recordLogin('google');
      if (!ref.mounted) return;
      state = state.copy(
        submission: SignUpSubmission.waitingForSession,
        message: 'Waiting for your sign-in session…',
      );
    } catch (error) {
      if (ref.mounted) _showError(error, google: true);
    }
  }

  void _showError(Object error, {required bool google}) {
    unawaited(
      ref
          .read(analyticsRepositoryProvider)
          .error(google ? 'login' : 'sign_up', error),
    );
    final failure = ExceptionMapper.map(error);
    final errors = <String, String>{};
    String? message;
    switch (failure.code) {
      case 'email_already_in_use':
        errors['email'] = 'An account already uses this email. Try logging in.';
      case 'invalid_email':
        errors['email'] = 'Enter a valid email address.';
      case 'weak_password':
        errors['password'] = 'Choose a stronger password.';
      case 'account_exists_with_different_credential':
        message = 'An account already uses this email. Log in using your original sign-in method.';
      case 'firebase_service_pending':
        message = google
            ? 'Google sign-in is not available yet.'
            : 'Account creation is not available yet. Please try again later.';
      default:
        message = failure.message;
    }
    state = state.copy(
      submission: SignUpSubmission.idle,
      errors: errors,
      message: message,
    );
  }
}
