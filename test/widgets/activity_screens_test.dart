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
import 'package:prm393_lab03/widgets/activity_widgets.dart';

import 'dart:convert';

const activityFrames = <String, double>{
  '/my-events/past-empty': 884,
  '/my-events/past-date': 900,
  '/my-events/ticket': 884,
  '/my-events/cancel': 884,
  '/my-events/past-all': 897,
  '/my-events/selected': 885,
  '/my-events': 885,
  '/my-events/calendar': 885,
  '/my-events/check-in': 884,
  '/rewards/locker': 884,
  '/rewards/catalog': 1074,
  '/rewards': 1254,
  '/rewards/success': 884,
  '/rewards/confirm': 884,
  '/rewards/detail': 1144,
  '/rewards/voucher': 1012,
  '/rewards/milestones': 1151,
  '/rewards/history': 885,
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
  for (final route in activityFrames.keys) {
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
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$route at $viewport');
      }
    });
  }
  testWidgets(
    'cancel confirmation changes registrations only after confirmation',
    (tester) async {
      tester.view.physicalSize = const Size(390, 884);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            signedInTestSession,
            initialLocationProvider.overrideWithValue('/my-events/selected'),
          ],
          child: const LabApp(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(OutlinedButton, 'Cancel'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Keep Registration'));
      await tester.pumpAndSettle();
      expect(find.text('AI & Future Careers Workshop'), findsOneWidget);
      await tester.tap(find.widgetWithText(OutlinedButton, 'Cancel'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Yes, Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('No events on this date'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('redemption stays disabled while coin API is not connected', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          signedInTestSession,
          initialLocationProvider.overrideWithValue('/rewards/detail'),
        ],
        child: const LabApp(),
      ),
    );
    await tester.pumpAndSettle();
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Coin API not connected'),
    );
    expect(button.onPressed, isNull);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(LabApp)),
    );
    expect(container.read(activityViewModelProvider).available, 420);
    expect(tester.takeException(), isNull);
  });
  testWidgets('catalog search remains editable beside its icon', (
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
          initialLocationProvider.overrideWithValue('/rewards/catalog'),
        ],
        child: const LabApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(EditableText)).width, greaterThan(100));
    await tester.enterText(find.byType(TextFormField), 'tote');
    await tester.pumpAndSettle();
    expect(find.text('Evia Eco Tote Bag'), findsOneWidget);
    expect(find.text('Campus Café \$10 Voucher'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  if (Platform.environment['EVIA_ACTIVITY_CAPTURE_DIR']
      case final String captureDir) {
    for (final entry in activityFrames.entries) {
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
            '$captureDir/${activityFrames.keys.toList().indexOf(entry.key)}.png',
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
            '$captureDir/${activityFrames.keys.toList().indexOf(entry.key)}.json',
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
