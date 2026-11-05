import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:asteroids/game/asteroids_game.dart';
import 'package:asteroids/game/components/drop.dart';
import 'package:asteroids/game/components/xp_orb.dart';

/// Interactive Point of Interest (POI): Abandoned Research Relay Station.
/// When the player navigates within the transmission perimeter (~240px)
/// and maintains the uplink for 15 seconds, it broadcasts archives, grants +1500 score,
/// and unleashes a massive Stardust and Shield drop reward.
class SpaceStationComponent extends PositionComponent with HasGameReference<AsteroidsGame> {
  static const double transmissionRadius = 240.0;
  static const double targetUploadTime = 15.0;

  double uploadProgress = 0.0; // 0.0 to 15.0s
  bool isSecured = false;
  bool isPlayerInZone = false;

  double _rotationAngle = 0.0;
  double _antennaAngle = 0.0;
  double _beaconTimer = 0.0;

  final Paint _ringPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;

  final Paint _arcPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeWidth = 3.5;

  final Paint _hullPaint = Paint()
    ..color = const Color(0xFF1E2838)
    ..style = PaintingStyle.fill;

  final Paint _hullOutlinePaint = Paint()
    ..color = const Color(0xFF00E5FF)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.8;

  final Paint _solarPaint = Paint()
    ..color = const Color(0xFF0D47A1)
    ..style = PaintingStyle.fill;

  final Paint _solarGridPaint = Paint()
    ..color = const Color(0xFF40C4FF).withOpacity(0.6)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0;

  final Paint _beaconPaint = Paint()..style = PaintingStyle.fill;

  SpaceStationComponent({required Vector2 position}) : super(position: position, size: Vector2.all(80.0));

  @override
  void update(double dt) {
    super.update(dt);
    _rotationAngle += dt * 0.15;
    _antennaAngle += dt * 1.8;
    _beaconTimer += dt * 3.5;

    if (game.state != GameState.playing) return;

    try {
      final distToPlayer = position.distanceTo(game.player.position);
      isPlayerInZone = distToPlayer <= transmissionRadius;

      if (!isSecured) {
        if (isPlayerInZone) {
          uploadProgress = math.min(targetUploadTime, uploadProgress + dt);
          if (uploadProgress >= targetUploadTime) {
            _secureStation();
          }
        } else if (uploadProgress > 0) {
          // Slow signal decay when drifting outside zone
          uploadProgress = math.max(0.0, uploadProgress - dt * 0.35);
        }
      }
    } catch (_) {}
  }

  void _secureStation() {
    isSecured = true;
    if (isMounted) {
      try {
        game.addScore(1500);
        game.playSfx('powerup.wav');
        game.triggerScreenShake(duration: 0.45, intensity: 8.0);

        game.spawnFloatingText(
          position + Vector2(0, -50),
          '⚡ RESEARCH RELAY ARCHIVES SECURED! +1500 PTS',
          color: const Color(0xFFFFD700),
          fontSize: 18.0,
          velocity: Vector2(0, -35),
        );

        // Eject massive Stardust XP Orbs
        final random = math.Random();
        for (int i = 0; i < 5; i++) {
          final angle = (i * (2 * math.pi / 5)) + random.nextDouble() * 0.3;
          final offset = Vector2(math.cos(angle), math.sin(angle))..scale(55.0);
          game.world.add(XpOrbComponent(position: position + offset, type: XpOrbType.large));
        }

        // Eject guaranteed Shield Drop
        game.world.add(
          DropComponent(
            position: position + Vector2(0, 50),
            type: DropType.shield,
          ),
        );
      } catch (_) {}
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final statusColor = isSecured
        ? const Color(0xFF00FF66)
        : (isPlayerInZone ? const Color(0xFFFFD700) : const Color(0xFF00E5FF));

    // 1. Transmission Range Boundary Circle
    _ringPaint.color = statusColor.withOpacity(0.18 + 0.08 * math.sin(_beaconTimer));
    canvas.drawCircle(Offset.zero, transmissionRadius, _ringPaint);

    // 2. Uplink Progress Arc around the transmission boundary
    if (!isSecured && uploadProgress > 0) {
      final progressPercent = (uploadProgress / targetUploadTime).clamp(0.0, 1.0);
      _arcPaint.color = const Color(0xFFFFD700);
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: transmissionRadius),
        -math.pi / 2,
        progressPercent * 2 * math.pi,
        false,
        _arcPaint,
      );
    }

    // 3. Station Structure (Rotated Core Module)
    canvas.save();
    canvas.rotate(_rotationAngle);

    // Solar Wings (Left & Right)
    final leftWing = Rect.fromLTWH(-75, -14, 45, 28);
    final rightWing = Rect.fromLTWH(30, -14, 45, 28);
    canvas.drawRect(leftWing, _solarPaint);
    canvas.drawRect(rightWing, _solarPaint);
    canvas.drawRect(leftWing, _solarGridPaint);
    canvas.drawRect(rightWing, _solarGridPaint);

    // Solar Wing struts
    canvas.drawLine(const Offset(-30, 0), const Offset(-15, 0), _hullOutlinePaint);
    canvas.drawLine(const Offset(15, 0), const Offset(30, 0), _hullOutlinePaint);

    // Central Octagonal Habitat Hull
    final hullPath = Path();
    const coreR = 24.0;
    for (int i = 0; i < 8; i++) {
      final a = (i * math.pi / 4);
      final p = Offset(coreR * math.cos(a), coreR * math.sin(a));
      if (i == 0) {
        hullPath.moveTo(p.dx, p.dy);
      } else {
        hullPath.lineTo(p.dx, p.dy);
      }
    }
    hullPath.close();

    canvas.drawPath(hullPath, _hullPaint);
    _hullOutlinePaint.color = statusColor;
    canvas.drawPath(hullPath, _hullOutlinePaint);

    // Inner Module Ring
    canvas.drawCircle(Offset.zero, 12.0, _hullPaint);
    canvas.drawCircle(Offset.zero, 12.0, _hullOutlinePaint);

    canvas.restore();

    // 4. Rotating Communication Antenna & Central Beacon
    canvas.save();
    canvas.rotate(_antennaAngle);
    canvas.drawLine(Offset.zero, const Offset(0, -22), _hullOutlinePaint);
    canvas.drawCircle(const Offset(0, -22), 4.5, _solarGridPaint);
    canvas.restore();

    // Beacon Pulse Center
    _beaconPaint.color = statusColor.withOpacity(0.7 + 0.3 * math.sin(_beaconTimer));
    canvas.drawCircle(Offset.zero, 6.0, _beaconPaint);
  }
}
