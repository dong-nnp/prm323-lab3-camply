import 'package:flutter/widgets.dart';

abstract final class AppMotion {
  static const bannerInterval = Duration(seconds: 5);
  static const bannerTransition = Duration(milliseconds: 400);
  static const loginEnter = Duration(milliseconds: 280);
  static const loginExit = Duration(milliseconds: 220);
  static const loginOffset = Offset(0.06, 0);
  static const loginCurve = Curves.easeInOutCubic;
  static const keyboardLayout = Duration(milliseconds: 180);
  static const keyboardCurve = Curves.easeOutCubic;
}
