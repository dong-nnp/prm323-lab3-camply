import 'package:prm393_lab03/models/firebase_status.dart';
import 'package:prm393_lab03/services/firebase_initializer.dart';

/// Test-only control of bootstrap outcomes; contains no business data.
class FakeFirebaseInitializer implements FirebaseInitializer {
  FakeFirebaseInitializer(this.result);

  Future<FirebaseStatus> Function() result;
  int calls = 0;

  @override
  Future<FirebaseStatus> initialize() {
    calls++;
    return result();
  }
}
