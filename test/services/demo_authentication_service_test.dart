import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prm393_lab03/core/errors/app_exception.dart';
import 'package:prm393_lab03/core/providers/service_providers.dart';
import 'package:prm393_lab03/models/auth_session.dart';
import 'package:prm393_lab03/services/demo_authentication_service.dart';
import 'package:prm393_lab03/services/pending_firebase_services.dart';
import 'package:prm393_lab03/viewmodels/authentication_view_model.dart';
import 'package:prm393_lab03/viewmodels/evia_view_model.dart';

void main() {
  test('default adapter remains unavailable without demo flag', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(
      container.read(authenticationServiceProvider),
      isA<PendingFirebaseServices>(),
    );
  });

  test(
    'rejects wrong credentials, signs in and signs out through ViewModels',
    () async {
      final container = ProviderContainer(
        overrides: [demoAuthEnabledProvider.overrideWithValue(true)],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(
        authenticationViewModelProvider,
        (_, _) {},
      );
      addTearDown(subscription.close);
      await container.read(authenticationViewModelProvider.future);
      final vm = container.read(eviaViewModelProvider.notifier);
      await vm.login(DemoAuthenticationService.email, 'wrong');
      expect(
        container.read(eviaViewModelProvider).message,
        'Incorrect demo email or password.',
      );
      expect(container.read(hasAuthenticatedSessionProvider), isFalse);
      await vm.login(
        '  ALEX.M@FPT.EDU.VN ',
        DemoAuthenticationService.password,
      );
      await Future<void>.delayed(Duration.zero);
      expect(container.read(hasAuthenticatedSessionProvider), isTrue);
      expect(container.read(eviaViewModelProvider).isLoggingIn, isFalse);
      await container.read(authenticationViewModelProvider.notifier).signOut();
      await Future<void>.delayed(Duration.zero);
      expect(container.read(hasAuthenticatedSessionProvider), isFalse);
    },
  );

  test(
    'new listeners see current session; unsupported auth stays unavailable',
    () async {
      final service = DemoAuthenticationService();
      addTearDown(service.dispose);
      await service.signInWithEmailPassword(
        DemoAuthenticationService.email,
        DemoAuthenticationService.password,
      );
      expect((await service.watchSession().first).status, AuthStatus.signedIn);
      await expectLater(
        service.signInWithGoogle(),
        throwsA(isA<AppException>()),
      );
      await expectLater(
        service.createAccount(
          fullName: 'Other',
          email: 'other@example.com',
          password: 'password',
          acceptedTerms: true,
        ),
        throwsA(isA<AppException>()),
      );
    },
  );
}
