import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab03/core/errors/app_exception.dart';
import 'package:prm393_lab03/models/auth_session.dart';
import 'package:prm393_lab03/models/firebase_status.dart';
import 'package:prm393_lab03/services/firebase_initialization_service.dart';
import 'package:prm393_lab03/services/pending_firebase_services.dart';

void main() {
  test(
    'disabled initialization works without any native Firebase plugin',
    () async {
      const service = FirebaseInitializationService(enabled: false);
      expect(await service.initialize(), FirebaseStatus.notConfigured);
    },
  );

  test('pending authentication is explicitly unavailable', () async {
    const service = PendingFirebaseServices();
    expect((await service.watchSession().first).status, AuthStatus.unavailable);
    await expectLater(service.signInWithGoogle(), throwsA(isA<AppException>()));
  });
}
