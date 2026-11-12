import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:asteroids/game/asteroids_game.dart';
import 'package:asteroids/game/glow.dart';

/// Easter Egg: Ancient Precursor Cryo-Pod drifting in deep space.
/// Rescuing it triggers a 5s chronostasis field, grants scrap/XP,
/// and decrypts ancient precursor data.
class CryoPodComponent extends PositionComponent with HasGameReference<AsteroidsGame> {
  final double radius = 26.0;
  Vector2 driftVelocity;
  double rotation = 0.0;
  double beaconTimer = 0.0;
  bool isSalvaged = false;

  CryoPodComponent({
    required Vector2 position,
    Vector2? driftVelocity,
  }) : driftVelocity = driftVelocity ?? Vector2(25.0, -15.0),
       super(position: position, size: Vector2.all(52.0), anchor: Anchor.center);

  @override
  void update(double dt) {
    super.update(dt);
    if (game.state != GameState.playing) {
      removeFromParent();
      return;
    }

    position += driftVelocity * dt;
    rotation += dt * 0.8;
    beaconTimer += dt * 4.0;

    // Check interaction with Player
    final player = game.player;
    final distSq = position.distanceToSquared(player.position);
    final interactDist = radius + player.radius + 15.0;

    if (!isSalvaged && distSq <= interactDist * interactDist) {
      salvage();
    }
  }

  void salvage() {
    if (isSalvaged) return;
    isSalvaged = true;

    // 1. Rewards
    game.addXp(500);
    game.addScrap(250);
    game.playSfx('powerup.wav');

    // 2. Floating announcement
    game.spawnFloatingText(
      position + Vector2(0, -40),
      '🌟 ANCIENT CRYO-POD RECOVERED! +500 XP // +250 SCRAP',
      color: const Color(0xFF00E5FF),
      fontSize: 20.0,
    );

    // 4. Decrypt Precursor Message
    game.spawnExplosionParticles(
      position: position,
      colorChoices: [const Color(0xFF00E5FF), Colors.white, const Color(0xFFFFD700)],
      count: 32,
      minSize: 3.0,
      maxSize: 6.0,
      minSpeed: 40.0,
      maxSpeed: 240.0,
    );

    removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final pulse = 0.6 + 0.4 * math.sin(beaconTimer);
    final beaconColor = Color.lerp(const Color(0xFF00E5FF), Colors.white, pulse)!;

    canvas.save();
    canvas.rotate(rotation);

    // 1. Pod Hexagonal Hull
    final hullPath = Path();
    for (var i = 0; i < 6; i++) {
      final a = i * 2 * math.pi / 6;
      final px = math.cos(a) * radius;
      final py = math.sin(a) * radius;
      if (i == 0) {
        hullPath.moveTo(px, py);
      } else {
        hullPath.lineTo(px, py);
      }
    }
    hullPath.close();

    final fillPaint = Paint()
      ..color = const Color(0xFF0B192C)
      ..style = PaintingStyle.fill;
    canvas.drawPath(hullPath, fillPaint);

    final strokePaint = Paint()
      ..color = const Color(0xFF00E5FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawPath(hullPath, strokePaint);

    if (Glow.enabled) {
      Glow.heroStrokePath(canvas, hullPath, const Color(0xFF00E5FF), width: 2.5);
    }

    // 2. Cryo-Chamber Glass Window (Pulsing Cyan Core)
    final corePaint = Paint()
      ..color = beaconColor.withOpacity(0.85)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset.zero, radius * 0.45, corePaint);

    // 3. Stasis Ring Blades
    final ringPaint = Paint()
      ..color = const Color(0xFFFFD700).withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(Offset.zero, radius * 0.8, ringPaint);

    canvas.restore();
  }
}
