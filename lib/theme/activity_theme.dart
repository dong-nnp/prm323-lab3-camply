import 'package:flutter/material.dart';

import 'app_tokens.dart';

abstract final class ActivityTheme {
  static const action = Color(0xFF1666FF);
  static const actionDark = Color(0xFF003ECE);
  static const wallet = Color(0xFFEAF4FF);
  static const lavender = Color(0xFFF2F0FF);
  static const scrim = Color(0x990F172A);
  static const photoScrim = Color(0x66000000);
  static const disabled = Color(0xFF94A3B8);
  static const calendarCell = 48.0;
  static const walletHeight = 212.0;
  static const scannerHeight = 310.0;
  static const rewardImageHeight = 136.0;
  static const detailImageHeight = 220.0;
  static const mascotHeight = 200.0;
  static const successMascotHeight = 179.3;
  static const successMascotWidth = 215.0;
  static const catalogMascotSize = 112.0;
  static const earnMascotWidth = 152.0;
  static const earnMascotHeight = 101.23;
  static const historyMascotWidth = 144.14;
  static const historyMascotHeight = 96.0;
  static const scannerFrameSize = 212.0;
  static const scannerTint = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x80000000), Color(0x00000000), Color(0xB3000000)],
    stops: [0, .5, 1],
  );
  static const cameraMultiply = Color(0xFFBFBFBF);
  static const ticketStripe = 6.0;
  static const iconCircle = 48.0;
  static const title = TextStyle(
    fontSize: 22,
    height: 1.3,
    fontWeight: FontWeight.w700,
  );
  static const balance = TextStyle(
    fontSize: 34,
    height: 1.2,
    fontWeight: FontWeight.w700,
  );
  static const smallLabel = TextStyle(
    fontSize: 11,
    height: 1.3,
    fontWeight: FontWeight.w700,
    letterSpacing: .4,
  );
  static const code = TextStyle(
    fontFamily: 'monospace',
    fontSize: 14,
    height: 1.4,
    fontWeight: FontWeight.w700,
  );
  static const progressHeight = AppSpacing.sm;
}
