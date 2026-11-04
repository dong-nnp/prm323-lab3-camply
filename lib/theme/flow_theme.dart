import 'package:flutter/material.dart';

import 'app_tokens.dart';

abstract final class FlowTheme {
  static const heroHeight = 270.0;
  static const heroOverlap = 32.0;
  static const bannerHeight = 128.0;
  static const formThumbnail = 64.0;
  static const mapHeight = 184.0;
  static const resultMascotHeight = 190.0;
  static const resultMascotWidth = 220.0;
  static const waitingMascotHeight = 160.0;
  static const profileAvatarSize = 64.0;
  static const mapWash = Color(0xFFE7EEF7);
  static const panelWash = Color(0xFFF5F6FF);
  static const muted = Color(0xFF64748B);
  static const error = Color(0xFFDC2626);
  static const errorWash = Color(0xFFFEF2F2);
  static const gold = Color(0xFFF59E0B);
  static const coin = Color(0xFFFFF3C7);
  static const heroGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x80000000), Color(0x00000000)],
  );
  static const fieldLabel = TextStyle(
    fontSize: 14,
    height: 1.4,
    fontWeight: FontWeight.w600,
  );
  static const helpText = TextStyle(fontSize: 14, height: 1.4, color: muted);
  static const footnote = TextStyle(fontSize: 11, height: 1.3, color: muted);
  static const required = TextStyle(color: error);
  static const formSectionGap = AppSpacing.xl;
}
