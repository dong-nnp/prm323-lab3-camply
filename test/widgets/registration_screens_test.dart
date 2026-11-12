import '../helpers/startup_test_auth.dart';

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab03/app/app.dart';
import 'package:prm393_lab03/app/router.dart';
import 'package:prm393_lab03/viewmodels/activity_view_model.dart';
import 'package:prm393_lab03/viewmodels/profile_view_model.dart';
import 'package:prm393_lab03/viewmodels/registration_view_model.dart';

import 'package:prm393_lab03/widgets/activity_widgets.dart';

import 'dart:convert';

const flowFrames = <String, double>{
  '/registration/legacy-error': 1037,
  '/event/schedule': 1557,
  '/registration/success': 886,
  '/registration/legacy': 1036,
  '/event/location': 1679,
  '/registration/error': 1265,
  '/event/about': 1629,
  '/registration': 1169,
  '/registration/going': 884,
  '/registration/full': 885,
  '/registration/loading': 884,
  '/registration/failed': 884,
  '/organizer': 884,
  '/profile': 1036,
  '/profile/interests': 909,
  '/profile/saved': 886,
  '/profile/notifications': 944,
};
void main() {
  setUpAll(() async {
    final root = Platform.environment['FLUTTER_ROOT'];
    if (root != null) {
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
      final codeFont = File(
        '${Platform.environment['WINDIR'] ?? 'C:/Windows'}/Fonts/consola.ttf',
      );
      if (await codeFont.exists()) {
        await (FontLoader(
          'monospace',
        )..addFont(codeFont.readAsBytes().then(ByteData.sublistView))).load();
      }
    }
  });
  for (final route in flowFrames.keys) {
    testWidgets('$route fits phone widths and scaled text', (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      for (final viewport in [
        (360.0, 1.0),
        (412.0, 1.0),
        (360.0, 2.0),
        (412.0, 2.0),
      ]) {
        tester.view.physicalSize = Size(viewport.$1, 884);
        tester.platformDispatcher.textScaleFactorTestValue = viewport.$2;
        await tester.pumpWidget(
          ProviderScope(
            key: ValueKey(viewport),
            overrides: [
              signedInTestSession,
              initialLocationProvider.overrideWithValue(route),
            ],
            child: const LabApp(),
          ),
        );
        if (route == '/registration/loading') {
          // The indeterminate spinner intentionally keeps scheduling frames.
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
          expect(find.byType(CircularProgressIndicator), findsOneWidget);
          expect(find.text('Confirming your\nregistration...'), findsOneWidget);
        } else {
          await tester.pumpAndSettle();
        }
        expect(tester.takeException(), isNull, reason: '$route at $viewport');
      }
    });
  }
  testWidgets(
    'registration does not hold preview coins while API is unavailable',
    (tester) async {
      tester.view.physicalSize = const Size(390, 884);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            signedInTestSession,
            initialLocationProvider.overrideWithValue('/registration'),
          ],
          child: const LabApp(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm Registration'));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(LabApp)),
      );
      expect(
        container.read(registrationViewModelProvider).status.name,
        'failed',
      );
      expect(container.read(activityViewModelProvider).available, 420);
      expect(container.read(activityViewModelProvider).deposits, 100);
      expect(container.read(activityViewModelProvider).registrations, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('saving a form correction removes its validation error', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 884);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          signedInTestSession,
          initialLocationProvider.overrideWithValue('/registration/error'),
        ],
        child: const LabApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Please enter your full name.'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'Alex Morgan');
    await tester.pump();
    expect(find.text('Please enter your full name.'), findsNothing);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(LabApp)),
    );
    expect(container.read(registrationViewModelProvider).name, 'Alex Morgan');
    expect(container.read(activityViewModelProvider).registrations, isEmpty);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'mark all read updates notification badges without deleting notices',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            signedInTestSession,
            initialLocationProvider.overrideWithValue('/profile/notifications'),
          ],
          child: const LabApp(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('NEW'), findsNWidgets(2));
      await tester.tap(find.text('Mark all read'));
      await tester.pumpAndSettle();
      expect(find.text('NEW'), findsNothing);
      expect(find.text('Registration Confirmed'), findsOneWidget);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(LabApp)),
      );
      expect(container.read(profileViewModelProvider.notifier).unreadCount, 0);
      expect(tester.takeException(), isNull);
    },
  );
  if (Platform.environment['EVIA_FLOW_CAPTURE_DIR']
      case final String captureDir) {
    for (final entry in flowFrames.entries) {
      testWidgets('capture ${entry.key}', (tester) async {
        tester.view.physicalSize = Size(390, entry.value);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final boundaryKey = GlobalKey();
        await tester.pumpWidget(
          RepaintBoundary(
            key: boundaryKey,
            child: ProviderScope(
              overrides: [
                signedInTestSession,
                initialLocationProvider.overrideWithValue(entry.key),
              ],
              child: const LabApp(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.runAsync(() async {
          final imageContext = tester.element(find.byType(LabApp));
          await Future.wait(
            tester
                .widgetList<Image>(find.byType(Image))
                .map((widget) => precacheImage(widget.image, imageContext)),
          );
        });
        await tester.pumpAndSettle();
        await tester.runAsync(() async {
          final image =
              await (boundaryKey.currentContext!.findRenderObject()!
                      as RenderRepaintBoundary)
                  .toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await Directory(captureDir).create(recursive: true);
          await File(
            '$captureDir/${flowFrames.keys.toList().indexOf(entry.key)}.png',
          ).writeAsBytes(bytes!.buffer.asUint8List());
          final iconSlots = tester.elementList(find.byType(ActivityIcon)).map((
            element,
          ) {
            final widget = element.widget as ActivityIcon;
            final box = element.findRenderObject()! as RenderBox;
            final position = box.localToGlobal(Offset.zero);
            return {
              'asset':
                  '${widget.screen}/${widget.name == 'imgContainer0' ? 'imgContainer' : widget.name}',
              'x': position.dx,
              'y': position.dy,
              'width': box.size.width,
              'height': box.size.height,
            };
          }).toList();
          final images = tester.widgetList<Image>(find.byType(Image)).map((
            widget,
          ) {
            final provider = widget.image;
            return provider is AssetImage
                ? provider.assetName
                : provider.toString();
          }).toList();
          await File(
            '$captureDir/${flowFrames.keys.toList().indexOf(entry.key)}.json',
          ).writeAsString(
            jsonEncode({
              'route': entry.key,
              'icons': iconSlots,
              'images': images,
            }),
          );
          image.dispose();
        });
      });
    }
  }
}
