import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab03/core/constants/app_strings.dart';
import 'package:prm393_lab03/core/errors/app_exception.dart';
import 'package:prm393_lab03/core/providers/service_providers.dart';
import 'package:prm393_lab03/models/app_state.dart';
import 'package:prm393_lab03/models/firebase_status.dart';
import 'package:prm393_lab03/viewmodels/bootstrap_view_model.dart';

import '../helpers/fake_firebase_initializer.dart';

void main() {
  ProviderContainer containerFor(FakeFirebaseInitializer service) {
    final container = ProviderContainer.test(
      overrides: [firebaseInitializerProvider.overrideWithValue(service)],
    );
    container.listen(bootstrapViewModelProvider, (_, next) {});
    return container;
  }

  test('loading becomes empty when Firebase is not configured', () async {
    final service = FakeFirebaseInitializer(
      () async => FirebaseStatus.notConfigured,
    );
    final container = containerFor(service);

    expect(container.read(bootstrapViewModelProvider), isA<AppLoading>());
    await pumpEventQueue();

    final state = container.read(bootstrapViewModelProvider);
    expect(state, isA<AppEmpty<FirebaseStatus>>());
    expect((state as AppEmpty).message, AppStrings.notConfigured);
    expect(service.calls, 1);
  });

  test('configured Firebase becomes data', () async {
    final container = containerFor(
      FakeFirebaseInitializer(() async => FirebaseStatus.ready),
    );
    await pumpEventQueue();

    final state = container.read(bootstrapViewModelProvider);
    expect(state, isA<AppData<FirebaseStatus>>());
    expect((state as AppData).value, FirebaseStatus.ready);
  });

  test('safe error is preserved and retry can recover', () async {
    const error = AppException(code: 'test', message: 'Cấu hình không hợp lệ.');
    final service = FakeFirebaseInitializer(() async => throw error);
    final container = containerFor(service);
    await pumpEventQueue();

    expect(
      (container.read(bootstrapViewModelProvider) as AppError).error,
      same(error),
    );
    service.result = () async => FirebaseStatus.ready;
    await container.read(bootstrapViewModelProvider.notifier).refresh();

    expect(container.read(bootstrapViewModelProvider), isA<AppData>());
    expect(service.calls, 2);
  });

  test(
    'concurrent refresh does not start a duplicate initialization',
    () async {
      final result = Completer<FirebaseStatus>();
      final service = FakeFirebaseInitializer(() => result.future);
      final container = containerFor(service);
      await pumpEventQueue();

      await container.read(bootstrapViewModelProvider.notifier).refresh();
      expect(service.calls, 1);
      expect(container.read(bootstrapViewModelProvider), isA<AppLoading>());

      result.complete(FirebaseStatus.notConfigured);
      await pumpEventQueue();
      expect(container.read(bootstrapViewModelProvider), isA<AppEmpty>());
    },
  );

  test('completion after disposal does not update disposed state', () async {
    final result = Completer<FirebaseStatus>();
    final container = containerFor(
      FakeFirebaseInitializer(() => result.future),
    );
    await pumpEventQueue();
    container.dispose();

    result.complete(FirebaseStatus.ready);
    await pumpEventQueue();
  });
}
