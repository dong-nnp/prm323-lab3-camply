import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/constants/figma_assets.dart';
import '../theme/evia_theme.dart';
import '../theme/flow_theme.dart';

class CoinIcon extends StatelessWidget {
  const CoinIcon({this.size = EviaTheme.coinIconSize, this.color, super.key});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
    FigmaAssets.path('2083:456', 'imgContainer18'),
    width: size,
    height: size,
    excludeFromSemantics: true,
    colorFilter: ColorFilter.mode(color ?? FlowTheme.gold, BlendMode.srcIn),
  );
}
