import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab03/app/app.dart';
import 'package:prm393_lab03/app/router.dart';
import 'package:prm393_lab03/core/providers/service_providers.dart';
import 'package:prm393_lab03/models/auth_session.dart';
import 'package:prm393_lab03/models/sign_up_state.dart';
import 'package:prm393_lab03/screens/evia/login_screen.dart';
import 'package:prm393_lab03/screens/evia/sign_up_screen.dart';
import 'package:prm393_lab03/viewmodels/sign_up_view_model.dart';
import 'package:prm393_lab03/widgets/evia_brand.dart';

import '../helpers/sign_up_test_service.dart';

Future<ProviderContainer> openSignUp(
  WidgetTester tester, {
  SignUpTestService? service,
}) async {
  final c = ProviderContainer(
    overrides: [
      initialLocationProvider.overrideWithValue('/signup'),
      if (service != null)
        authenticationServiceProvider.overrideWithValue(service),
    ],
  );
  addTearDown(() async {
    c.dispose();
    await service?.close();
  });
  await tester.pumpWidget(
    RepaintBoundary(
      key: const ValueKey('signup-capture'),
      child: UncontrolledProviderScope(container: c, child: const LabApp()),
    ),
  );
  await tester.pumpAndSettle();
  await tester.runAsync(() async {
    final context = tester.element(find.byType(EviaSignUpScreen));
    for (final image in tester.widgetList<Image>(find.byType(Image))) {
      await precacheImage(image.image, context);
    }
  });
  await tester.pumpAndSettle();
  return c;
}

Future<void> fill(WidgetTester tester) async {
  for (final entry in [
    'Alex Example',
    'alex@example.com',
    'test-password',
    'test-password',
  ].indexed) {
    await tester.enterText(find.byType(TextField).at(entry.$1), entry.$2);
  }
  await tester.ensureVisible(find.byType(Checkbox));
  await tester.tap(find.byType(Checkbox));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    final root = Platform.environment['FLUTTER_ROOT'];
    if (root == null) return;
    final font = FontLoader('Roboto');
    for (final weight in ['regular', 'medium', 'bold']) {
      font.addFont(
        File('$root/bin/cache/artifacts/material_fonts/roboto-$weight.ttf')
            .readAsBytes()
            .then(ByteData.sublistView),
      );
    }
    await font.load();
    await (FontLoader('MaterialIcons')..addFont(
          File(
            '$root/bin/cache/artifacts/material_fonts/materialicons-regular.otf',
          ).readAsBytes().then(ByteData.sublistView),
        ))
        .load();
  });
  for (final viewport in [
    (360.0, 640.0, 1.0),
    (390.0, 844.0, 1.0),
    (412.0, 844.0, 2.0),
  ]) {
    testWidgets(
      'Sign Up fits ${viewport.$1}x${viewport.$2} text ${viewport.$3}',
      (tester) async {
        tester.view.physicalSize = Size(viewport.$1, viewport.$2);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = viewport.$3;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        addTearDown(tester.view.resetViewInsets);
        await openSignUp(tester);
        expect(find.byType(TextField), findsNWidgets(4));
        expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);
        expect(find.text('9:41'), findsNothing);
        expect(find.text('Student ID'), findsNothing);
        expect(find.byType(LoginCollage), findsNothing);
        expect(find.text('Find Events.\nMake Memories.'), findsOneWidget);
        expect(
          find.text("Join Evia and discover events you'll love."),
          findsOneWidget,
        );
        expect(
          tester.getTopLeft(find.text('Continue with Google')).dy,
          greaterThan(tester.getBottomLeft(find.text('Create Account')).dy),
        );
        expect(
          tester.getTopLeft(find.byType(Checkbox)).dy,
          greaterThan(tester.getBottomLeft(find.byType(TextField).last).dy),
        );
        if (viewport.$1 == 390) {
          expect(
            tester.getRect(find.text('Log In')).bottom,
            lessThanOrEqualTo(viewport.$2),
          );
        }
        final dir = Platform.environment['EVIA_SIGN_UP_CAPTURE_DIR'];
        if (dir != null && viewport.$1 == 390) {
          await tester.runAsync(() async {
            final boundary = tester.renderObject<RenderRepaintBoundary>(
              find.byKey(const ValueKey('signup-capture')),
            );
            final image = await boundary.toImage();
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            await Directory(dir).create(recursive: true);
            await File('$dir/signup-390.png')
                .writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
        final confirmation = find.byType(TextField).last;
        await tester.enterText(confirmation, 'kept-password');
        tester.view.viewInsets = const FakeViewPadding(bottom: 300);
        await tester.pumpAndSettle();
        expect(tester.getRect(confirmation).top, greaterThanOrEqualTo(0));
        expect(
          tester.getRect(confirmation).bottom,
          lessThanOrEqualTo(viewport.$2 - 300),
        );
        expect(
          tester.widget<TextField>(confirmation).controller!.text,
          'kept-password',
        );
        tester.view.resetViewInsets();
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Create Account'));
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'inline errors, password toggles and unavailable adapter do not navigate',
    (tester) async {
      final c = await openSignUp(tester);
      await tester.ensureVisible(find.text('Create Account'));
      await tester.tap(find.text('Create Account'));
      await tester.pumpAndSettle();
      expect(c.read(signUpViewModelProvider).errors.length, 5);
      await fill(tester);
      await tester.ensureVisible(find.byTooltip('Show password'));
      await tester.tap(find.byTooltip('Show password'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField).at(2)).obscureText,
        isFalse,
      );
      expect(
        tester.widget<TextField>(find.byType(TextField).at(3)).obscureText,
        isTrue,
      );
      await tester.ensureVisible(find.text('Create Account'));
      await tester.tap(find.text('Create Account'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Account creation is not available yet'),
        findsOneWidget,
      );
      expect(find.byType(EviaSignUpScreen), findsOneWidget);
      await tester.ensureVisible(find.text('Continue with Google'));
      await tester.tap(find.text('Continue with Google'));
      await tester.pumpAndSettle();
      expect(find.text('Google sign-in is not available yet.'), findsOneWidget);
    },
  );
  testWidgets('Log In opens the existing Login screen', (tester) async {
    await openSignUp(tester);
    await tester.ensureVisible(find.text('Log In'));
    await tester.tap(find.text('Log In'));
    await tester.pumpAndSettle();
    expect(find.byType(EviaLoginScreen), findsOneWidget);
  });
  for (final handled in [false, true]) {
    testWidgets(
      'creation waits for observed auth, then personalization $handled',
      (tester) async {
        tester.view.physicalSize = const Size(412, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final service = SignUpTestService();
        final c = await openSignUp(tester, service: service);
        await fill(tester);
        await tester.ensureVisible(find.text('Create Account'));
        await tester.tap(find.text('Create Account'));
        // A live waiting indicator deliberately never settles before auth emits.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        expect(service.createCalls, 1);
        expect(
          c.read(signUpViewModelProvider).submission,
          SignUpSubmission.waitingForSession,
        );
        expect(find.byType(EviaSignUpScreen), findsOneWidget);
        service.publish(
          AuthSession.signedIn(
            'actual-test-session',
            personalizationHandled: handled,
          ),
        );
        await tester.pumpAndSettle();
        expect(
          c.read(routerProvider).routeInformationProvider.value.uri.path,
          handled ? '/discover' : '/interests',
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
