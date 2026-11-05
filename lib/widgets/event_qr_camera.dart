import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'status_widgets.dart';

/// Camera presentation only; attendance is authorized by the injected ViewModel action.
class EventQrCamera extends StatefulWidget {
  const EventQrCamera({
    required this.onScan,
    required this.enabled,
    required this.torch,
    super.key,
  });
  final ValueChanged<String> onScan;
  final bool enabled, torch;
  @override
  State<EventQrCamera> createState() => _EventQrCameraState();
}

class _EventQrCameraState extends State<EventQrCamera> {
  final controller = MobileScannerController(formats: [BarcodeFormat.qrCode]);
  String? last;
  DateTime? lastAt;
  @override
  void didUpdateWidget(covariant EventQrCamera oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.torch != oldWidget.torch && controller.value.isInitialized) {
      unawaited(controller.toggleTorch());
    }
  }

  @override
  void dispose() {
    unawaited(controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MobileScanner(
    controller: controller,
    onDetect: (capture) {
      if (!widget.enabled) return;
      final value = capture.barcodes.firstOrNull?.rawValue;
      if (value == null ||
          value == last &&
              DateTime.now().difference(lastAt!) < const Duration(seconds: 5)) {
        return;
      }
      last = value;
      lastAt = DateTime.now();
      widget.onScan(value);
    },
    errorBuilder: (_, error) => AppErrorWidget(
      message: error.errorCode == MobileScannerErrorCode.permissionDenied
          ? 'Camera permission is required. Enable it in Android Settings or enter the event code.'
          : 'Camera is unavailable. Enter the event code or retry.',
      onRetry: () async {
        try {
          await controller.start();
        } catch (_) {}
      },
    ),
  );
}
