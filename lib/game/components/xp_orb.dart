import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:asteroids/constants.dart';
import 'package:asteroids/game/asteroids_game.dart';
import 'package:asteroids/game/glow.dart';

enum XpOrbType {
  small,    // 2 XP (Cyan)
  medium,   // 6 XP (Magenta)
  large,    // 14 XP (Gold)
  hyperRed, // Consolidated Red Gem Siphon (Ruby)
}

class XpOrbComponent extends PositionComponent with HasGameReference<AsteroidsGame> {
  XpOrbType type;
  int value;
  Color primaryColor;
  double radius;

  Vector2 velocity = Vector2.zero();
  double lifeTimer = 50.0;
  double pulseTimer = 0.0;
  bool isMagnetized = false;

  XpOrbComponent({
    required Vector2 position,
    required this.type,
    int? customValue,
  })  : value = customValue ?? 0,
        primaryColor = Colors.cyanAccent,
        radius = 4.5 {
    this.position = position;
    anchor = Anchor.center;

    _setupProperties(customValue);

    size = Vector2.all(radius * 2);

    final random = math.Random();
    final angle = random.nextDouble() * 2 * math.pi;
    final speed = 15.0 + random.nextDouble() * 30.0;
    velocity = Vector2(math.cos(angle), math.sin(angle)) * speed;
  }

  void _setupProperties(int? customValue) {
    switch (type) {
      case XpOrbType.small:
        value = customValue ?? 2;
        primaryColor = const Color(0xFF00E5FF);
        radius = 4.5;
        break;
      case XpOrbType.medium:
        value = customValue ?? 6;
        primaryColor = const Color(0xFFE040FB);
        radius = 6.0;
        break;
      case XpOrbType.large:
        value = customValue ?? 14;
        primaryColor = const Color(0xFFFFD700);
        radius = 8.0;
        break;
      case XpOrbType.hyperRed:
        value = customValue ?? 40;
        primaryColor = const Color(0xFFFF1744); // Vivid Ruby / Red Gem
        radius = 10.0;
        break;
    }
  }

  void absorbXp(int amount) {
    value += amount;
    if (type != XpOrbType.hyperRed) {
      type = XpOrbType.hyperRed;
      _setupProperties(value);
      size = Vector2.all(radius * 2);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (game.state != GameState.playing) return;

    pulseTimer += dt;
    // Hyper-red gems never despawn so the player never loses XP
    if (type != XpOrbType.hyperRed) {
      lifeTimer -= dt;
      if (lifeTimer <= 0) {
        removeFromParent();
        return;
      }
    }

    final player = game.player;
    final distToPlayer = position.distanceTo(player.position);
    final magnetDist = player.magnetRadius;

    // Magnetic Attraction
    if (distToPlayer <= magnetDist) {
      isMagnetized = true;
      final dir = (player.position - position).normalized();
      final accel = math.max(250.0, 700.0 * (1.0 - (distToPlayer / magnetDist)));
      velocity += dir * accel * dt;
      if (velocity.length > 600.0) {
        velocity = velocity.normalized() * 600.0;
      }
    } else {
      isMagnetized = false;
      velocity.scale(math.exp(-1.5 * dt));
    }

    position += velocity * dt;
    wrapAround();

    // Collection by player
    if (distToPlayer <= player.radius + radius + 4.0) {
      _collect();
    }
  }

  void _collect() {
    game.addXp(value);

    game.spawnExplosionParticles(
      position: position,
      colorChoices: [primaryColor, Colors.white, Colors.amberAccent],
      count: type == XpOrbType.hyperRed ? 20 : (type == XpOrbType.large ? 10 : 6),
      minSize: 1.5,
      maxSize: type == XpOrbType.hyperRed ? 4.5 : 3.5,
      minSpeed: 40.0,
      maxSpeed: type == XpOrbType.hyperRed ? 180.0 : 110.0,
    );

    if (type != XpOrbType.small) {
      game.spawnFloatingText(
        position,
        '+$value XP',
        color: primaryColor,
        fontSize: type == XpOrbType.hyperRed ? 16.0 : (type == XpOrbType.large ? 14.0 : 12.0),
      );
    }

    removeFromParent();
  }

  void wrapAround() {
    position.x = position.x.clamp(radius, GameConstants.sectorWidth - radius).toDouble();
    position.y = position.y.clamp(radius, GameConstants.sectorHeight - radius).toDouble();
  }

  @override
  void render(Canvas canvas) {
    canvas.translate(radius, radius);

    final pulseSpeed = type == XpOrbType.hyperRed ? 12.0 : 8.0;
    final pulse = 0.85 + 0.15 * math.sin(pulseTimer * pulseSpeed);
    final currentR = radius * pulse;

    final fillPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;

    final innerCorePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Diamond / Rhombus shape for gems
    final path = Path()
      ..moveTo(0, -currentR)
      ..lineTo(currentR * 0.75, 0)
      ..lineTo(0, currentR)
      ..lineTo(-currentR * 0.75, 0)
      ..close();

    canvas.drawPath(path, fillPaint);

    final corePath = Path()
      ..moveTo(0, -currentR * 0.45)
      ..lineTo(currentR * 0.35, 0)
      ..lineTo(0, currentR * 0.45)
      ..lineTo(-currentR * 0.35, 0)
      ..close();
    canvas.drawPath(corePath, innerCorePaint);

    Glow.strokePath(
      canvas,
      path,
      primaryColor,
      width: type == XpOrbType.hyperRed ? 2.5 : 1.5,
      intensity: type == XpOrbType.hyperRed ? 1.8 : 1.2,
    );
  }
}
