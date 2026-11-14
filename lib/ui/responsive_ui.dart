import 'dart:math' as math;
import 'package:flutter/widgets.dart';

/// Métricas centralizadas de responsividade para adaptar HUD e Overlays
/// entre celulares (Retrato e Paisagem), tablets e desktops sem duplicar lógica.
class ResponsiveLayout {
  final double width;
  final double height;

  const ResponsiveLayout._(this.width, this.height);

  factory ResponsiveLayout.of(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return ResponsiveLayout._(size.width, size.height);
  }

  double get shortestSide => math.min(width, height);
  bool get isPhone => shortestSide < 600;
  bool get isPortrait => height > width;
  bool get isNarrow => width < 680;
  bool get isCompactLandscape => isPhone && !isPortrait && height < 500;
  bool get isCompact => isPhone || width < 720 || height < 520;

  double get scale {
    if (shortestSide < 370) return 0.78;
    if (shortestSide < 440) return 0.84;
    if (shortestSide < 600) return 0.90;
    return 1.0;
  }

  double get hudPadding => isPhone ? 6.0 : 18.0;

  double clampWidth(double desktopMax, {double mobileFraction = 0.94}) {
    return math.min(desktopMax, width * mobileFraction);
  }

  double clampHeight(double desktopMax, {double mobileFraction = 0.92}) {
    return math.min(desktopMax, height * mobileFraction);
  }
}
