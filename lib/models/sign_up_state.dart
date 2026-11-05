enum SignUpSubmission { idle, account, google, waitingForSession }

class SignUpState {
  const SignUpState({
    this.errors = const {},
    this.acceptedTerms = false,
    this.showPassword = false,
    this.showConfirmation = false,
    this.submission = SignUpSubmission.idle,
    this.message,
    this.verificationRequired = false,
  });
  final Map<String, String> errors;
  final bool acceptedTerms,
      showPassword,
      showConfirmation,
      verificationRequired;
  final SignUpSubmission submission;
  final String? message;
  bool get isBusy => submission != SignUpSubmission.idle;
  SignUpState copy({
    Map<String, String>? errors,
    bool? acceptedTerms,
    bool? showPassword,
    bool? showConfirmation,
    bool? verificationRequired,
    SignUpSubmission? submission,
    String? message,
  }) => SignUpState(
    errors: Map.unmodifiable(errors ?? this.errors),
    acceptedTerms: acceptedTerms ?? this.acceptedTerms,
    showPassword: showPassword ?? this.showPassword,
    showConfirmation: showConfirmation ?? this.showConfirmation,
    verificationRequired: verificationRequired ?? this.verificationRequired,
    submission: submission ?? this.submission,
    message: message,
  );
}
