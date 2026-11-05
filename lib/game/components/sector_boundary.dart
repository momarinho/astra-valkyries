import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:asteroids/constants.dart';
import 'package:asteroids/game/asteroids_game.dart';

/// Renders the spatial navigation grid and hazardous outer perimeter
/// of the expanded 4800x4800 space sector.
class SectorBoundaryComponent extends Component with HasGameReference<AsteroidsGame> {
  double _pulseTimer = 0.0;

  final Paint _gridPaint = Paint()
    ..color = const Color(0xFF00E5FF).withOpacity(0.035)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0;

  final Paint _subGridPaint = Paint()
    ..color = const Color(0xFF00E5FF).withOpacity(0.015)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.5;

  final Paint _barrierPaint = Paint()
    ..color = const Color(0xFFFF2255).withOpacity(0.8)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3.0;

  final Paint _barrierGlowPaint = Paint()
    ..color = const Color(0xFFFF2255).withOpacity(0.25)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 10.0;

  final Paint _beaconPaint = Paint()
    ..color = const Color(0xFFFFD700)
    ..style = PaintingStyle.fill;

  @override
  void update(double dt) {
    super.update(dt);
    _pulseTimer += dt * 3.0;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    const width = GameConstants.sectorWidth;
    const height = GameConstants.sectorHeight;

    // Viewport bounds for culling
    final camPos = game.camera.viewfinder.position;
    final viewHalfW = GameConstants.screenWidth * 0.75;
    final viewHalfH = GameConstants.screenHeight * 0.75;
    final viewLeft = camPos.x - viewHalfW;
    final viewRight = camPos.x + viewHalfW;
    final viewTop = camPos.y - viewHalfH;
    final viewBottom = camPos.y + viewHalfH;

    // 1. Sector Spatial Grid Lines (drawn in camera view frustum)
    const gridSize = 400.0;
    final startX = (math.max(0.0, viewLeft) / gridSize).floor() * gridSize;
    final endX = (math.min(width, viewRight) / gridSize).ceil() * gridSize;
    final startY = (math.max(0.0, viewTop) / gridSize).floor() * gridSize;
    final endY = (math.min(height, viewBottom) / gridSize).ceil() * gridSize;

    for (var x = startX; x <= endX; x += gridSize) {
      if (x % 1200 == 0) {
        canvas.drawLine(Offset(x, math.max(0.0, viewTop)), Offset(x, math.min(height, viewBottom)), _gridPaint);
      } else {
        canvas.drawLine(Offset(x, math.max(0.0, viewTop)), Offset(x, math.min(height, viewBottom)), _subGridPaint);
      }
    }

    for (var y = startY; y <= endY; y += gridSize) {
      if (y % 1200 == 0) {
        canvas.drawLine(Offset(math.max(0.0, viewLeft), y), Offset(math.min(width, viewRight), y), _gridPaint);
      } else {
        canvas.drawLine(Offset(math.max(0.0, viewLeft), y), Offset(math.min(width, viewRight), y), _subGridPaint);
      }
    }

    // 2. Animated Outer Perimeter Barrier (Red Hazard Forcefield)
    final pulseAlpha = 0.55 + 0.35 * math.sin(_pulseTimer);
    _barrierPaint.color = const Color(0xFFFF2A55).withOpacity(pulseAlpha);
    _barrierGlowPaint.color = const Color(0xFFFF2A55).withOpacity(pulseAlpha * 0.35);

    final sectorRect = const Rect.fromLTWH(0, 0, width, height);

    // Draw glowing barrier borders if near viewport
    if (viewLeft < 200 || viewRight > width - 200 || viewTop < 200 || viewBottom > height - 200) {
      canvas.drawRect(sectorRect, _barrierGlowPaint);
      canvas.drawRect(sectorRect, _barrierPaint);

      // Corner Beacons
      const beaconRadius = 14.0;
      final corners = [
        const Offset(0, 0),
        const Offset(width, 0),
        const Offset(0, height),
        const Offset(width, height),
      ];

      for (final corner in corners) {
        if ((corner.dx - camPos.x).abs() < 1200 && (corner.dy - camPos.y).abs() < 1000) {
          canvas.drawCircle(corner, beaconRadius + 6.0 * math.sin(_pulseTimer).abs(), _barrierGlowPaint);
          canvas.drawCircle(corner, beaconRadius, _beaconPaint);
        }
      }
    }
  }
}
