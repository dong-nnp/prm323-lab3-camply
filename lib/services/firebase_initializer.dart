import '../models/firebase_status.dart';

abstract interface class FirebaseInitializer {
  Future<FirebaseStatus> initialize();
}
