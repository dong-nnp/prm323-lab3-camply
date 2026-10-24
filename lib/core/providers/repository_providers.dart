import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../repositories/authentication_repository.dart';
import '../../repositories/bootstrap_repository.dart';
import 'service_providers.dart';

final bootstrapRepositoryProvider = Provider(
  (ref) => BootstrapRepository(ref.watch(firebaseInitializerProvider)),
);

final authenticationRepositoryProvider = Provider(
  (ref) => AuthenticationRepository(ref.watch(authenticationServiceProvider)),
);
