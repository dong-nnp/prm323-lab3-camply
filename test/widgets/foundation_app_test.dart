import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab03/app/app.dart';
import 'package:prm393_lab03/app/router.dart';
import 'package:prm393_lab03/core/constants/app_strings.dart';
import 'package:prm393_lab03/core/errors/app_exception.dart';
import 'package:prm393_lab03/core/providers/service_providers.dart';
import 'package:prm393_lab03/models/firebase_status.dart';
import 'package:prm393_lab03/services/firebase_initialization_service.dart';
import 'package:prm393_lab03/theme/app_tokens.dart';

import '../helpers/fake_firebase_initializer.dart';

void main() {
  for (final width in [360.0, 412.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('unconfigured app fits ${width}dp at text scale $scale', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              initialLocationProvider.overrideWithValue('/foundation'),
              firebaseInitializerProvider.overrideWithValue(
                const FirebaseInitializationService(enabled: false),
              ),
            ],
            child: const LabApp(),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text(AppStrings.notConfigured), findsOneWidget);
        final action = find.widgetWithText(FilledButton, AppStrings.checkAgain);
        await tester.ensureVisible(action);
        final size = tester.getSize(action);
        expect(size.height, greaterThanOrEqualTo(AppSizes.minimumTouchTarget));
        expect(size.width, greaterThanOrEqualTo(AppSizes.minimumTouchTarget));
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('loading, failure and retry are driven by the ViewModel', (
    tester,
  ) async {
    final pending = Completer<FirebaseStatus>();
    final service = FakeFirebaseInitializer(() => pending.future);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          initialLocationProvider.overrideWithValue('/foundation'),
          firebaseInitializerProvider.overrideWithValue(service),
        ],
        child: const LabApp(),
      ),
    );
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    pending.completeError(
      const AppException(code: 'test', message: 'Không thể kết nối.'),
    );
    await tester.pumpAndSettle();
    expect(find.text('Không thể kết nối.'), findsOneWidget);

    service.result = () async => FirebaseStatus.notConfigured;
    await tester.tap(find.text(AppStrings.retry));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.notConfigured), findsOneWidget);
    expect(service.calls, 2);
    expect(tester.takeException(), isNull);
  });
}
