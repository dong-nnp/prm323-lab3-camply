import 'dart:ui';

abstract final class SplashTokens {
  static const asset = 'assets/evia-logo-lime-transparent(4).png';
  static const ticketAsset = 'assets/splash/evia-ticket.png';
  static const wordmarkAsset = 'assets/splash/evia-wordmark-via.png';
  static const raysAsset = 'assets/splash/evia-lime-rays.png';
  static const layerAssets = [ticketAsset, wordmarkAsset, raysAsset];
  static const duration = Duration(milliseconds: 1200);
  static const transition = Duration(milliseconds: 180);
  static const logoWidth = 280.0;
  static const initialScale = 0.85;
  static const accentPulse = 0.06;
  static const ticketEnterEnd = 300.0;
  static const ticketMoveStart = 300.0;
  static const wordmarkStart = 350.0;
  static const assemblyEnd = 800.0;
  static const raysStart = 700.0;
  static const raysEnd = 950.0;

  // Alpha bounds of the original PNG, with (149,139) as shared origin.
  // All three layers are copied pixels: no resizing/repainting at extraction.
  static const canvas = Size(1690, 622);
  static const originalBounds = Rect.fromLTWH(-149, -139, 1952, 806);
  static const ticketBounds = Rect.fromLTWH(0, 92, 638, 530);
  static const wordmarkBounds = Rect.fromLTWH(618, 40, 1072, 539);
  static const raysBounds = Rect.fromLTWH(522, 0, 185, 181);
}
