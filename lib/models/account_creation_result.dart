/// The adapter must complete real account creation before returning an outcome.
/// For signedIn, watchSession must publish the resulting usable session. For
/// verificationRequired, it must not publish a usable session prematurely.
enum AccountCreationResult { signedIn, verificationRequired }
