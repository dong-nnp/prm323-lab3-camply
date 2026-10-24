import '../models/firebase_status.dart';
import '../services/firebase_initializer.dart';

final class BootstrapRepository {
  const BootstrapRepository(this._initializer);

  final FirebaseInitializer _initializer;

  Future<FirebaseStatus> initialize() => _initializer.initialize();
}
