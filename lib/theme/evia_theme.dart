import 'package:flutter/material.dart';

import 'app_tokens.dart';

/// Additional measurements/colors from the nine Evia Figma frames.
abstract final class EviaTheme {
  static const featuredGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFCACCCD), Color(0xFFB9BBBE), Color(0xFF202020)],
  );
  static const navy = Color(0xFF0B1F44);
  static const muted = Color(0xFF647797);
  static const blue = Color(0xFF1666FF);
  static const selectedIcon = Color(0xFFD5E3FF);
  static const bookmarkOverlay = Color(0xFF8D8F91);
  static const selectionSize = 20.0;
  static const lavender = Color(0xFFEEECFA);
  static const lavenderSoft = Color(0xFFF3F0FF);
  static const gold = Color(0xFF925B00);
  static const cardShadow = [
    BoxShadow(color: Color(0x090B1F44), blurRadius: 4, offset: Offset(0, 2)),
  ];
  static const loginShadow = [
    BoxShadow(color: Color(0x140B1F44), blurRadius: 28, offset: Offset(0, 12)),
  ];
  static const label = TextStyle(
    fontSize: 14,
    height: 1.3,
    fontWeight: FontWeight.w600,
  );
  static const caption = TextStyle(fontSize: 14, height: 1.4, color: muted);
  static const heading = TextStyle(
    fontSize: 28,
    height: 1.2,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.6,
  );
  static const loginHeading = TextStyle(
    fontSize: 32,
    height: 1.1,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.6,
    color: navy,
  );
  static const section = TextStyle(
    fontSize: 18,
    height: 1.4,
    fontWeight: FontWeight.w600,
  );
  static const badge = TextStyle(
    fontSize: 10,
    height: 1.2,
    fontWeight: FontWeight.w700,
  );
  static const cardTitle = TextStyle(
    fontSize: 16,
    height: 1.3,
    fontWeight: FontWeight.w600,
  );
  static const compactTitle = TextStyle(
    fontSize: 14,
    height: 1.3,
    fontWeight: FontWeight.w600,
    color: navy,
  );
  static const phoneWidth = 390.0;
  static const thumbnail = 96.0;
  static const coinIconSize = 12.5;
  static const compactThumbnail = 64.0;
  static const heroHeight = 200.0;
  static const logoWidth = 72.0;
  static const loginLogoWidth = 180.0;
  static const loginLogoHeight = 74.17;
  static const authContentOffset = Offset(0, -AppSpacing.xs / 2);
  static const compactLoginLogoWidth = 112.0;
  static const collageHeight = 204.0;
  static const signUpCollageHeight = 120.0;
  static const cardRadius = 28.0;
  static const cardGap = AppSpacing.md;
}
