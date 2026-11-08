import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:asteroids/game/asteroids_game.dart';
import 'package:asteroids/game/glow.dart';
import 'enemy_ship.dart';
import 'asteroid.dart';
import 'sector_boss.dart';

class SingularityVortexComponent extends PositionComponent with HasGameReference<AsteroidsGame> {
  final double pullRadius;
  double lifespan = 2.4;
  final double maxLifespan = 2.4;
  final double damagePerSecond = 35.0;
  double rotation = 0.0;

  SingularityVortexComponent({
    required Vector2 position,
    this.pullRadius = 240.0,
  }) {
    this.position = position;
    anchor = Anchor.center;
    size = Vector2.all(pullRadius * 2);
  }

  @override
  void update(double dt) {
    super.update(dt);
    lifespan -= dt;
    if (lifespan <= 0) {
      removeFromParent();
      return;
    }

    rotation += 3.5 * dt;

    // Pull and slow enemies
    for (final enemy in game.world.children.whereType<EnemyShipComponent>().toList()) {
      if (enemy.isRemoved) continue;
      final toVortex = position - enemy.position;
      final dist = toVortex.length;
      if (dist < pullRadius && dist > 8.0) {
        final pullDir = toVortex.normalized();
        final pullStrength = (1.0 - (dist / pullRadius)) * 260.0;
        enemy.velocity += pullDir * (pullStrength * dt);
        enemy.velocity.scale(math.exp(-1.8 * dt)); // Slow them down
        enemy.takeDamage(damagePerSecond * dt, enemy.position);
      }
    }

    // Pull and damage asteroids
    for (final ast in game.world.children.whereType<AsteroidComponent>().toList()) {
      if (ast.isRemoved) continue;
      final toVortex = position - ast.position;
      final dist = toVortex.length;
      if (dist < pullRadius && dist > 8.0) {
        final pullDir = toVortex.normalized();
        final pullStrength = (1.0 - (dist / pullRadius)) * 180.0;
        ast.velocity.add(pullDir * (pullStrength * dt));
        ast.takeDamage(damagePerSecond * 0.5 * dt, ast.position);
      }
    }

    // Pull boss lightly if present
    for (final boss in game.world.children.whereType<SectorBoss>().toList()) {
      if (boss.isRemoved) continue;
      final toVortex = position - boss.position;
      final dist = toVortex.length;
      if (dist < pullRadius) {
        boss.takeDamage(damagePerSecond * 0.8 * dt, boss.position);
      }
    }
  }

  @override
  void render(Canvas canvas) {
    final progress = (lifespan / maxLifespan).clamp(0.0, 1.0);
    final alpha = (progress * 230).toInt();
    if (alpha <= 0) return;

    final center = Offset(pullRadius, pullRadius);

    canvas.save();
    canvas.translate(pullRadius, pullRadius);
    canvas.rotate(rotation);

    // Gravitational lensing field (outer disc)
    final outerPaint = Paint()
      ..color = const Color(0xFF00E5FF).withAlpha((alpha * 0.12).toInt())
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset.zero, pullRadius * 0.85, outerPaint);

    // Spiral accretion arms
    const arms = 4;
    for (var i = 0; i < arms; i++) {
      final armAngle = (i * 2 * math.pi / arms);
      final armPath = Path()..moveTo(0, 0);
      for (double r = 10; r < pullRadius * 0.8; r += 15) {
        final a = armAngle + (r / 35.0);
        armPath.lineTo(r * math.cos(a), r * math.sin(a));
      }

      final armPaint = Paint()
        ..color = Color.fromARGB(alpha, 0, 229, 255)
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;
      canvas.drawPath(armPath, armPaint);
    }

    // Dense Event Horizon ring
    Glow.drawGlowCircle(
      canvas,
      Offset.zero,
      30.0,
      Color.fromARGB(alpha, 224, 247, 250),
      strokeWidth: 2.5,
      intensity: 1.6,
    );

    // Void Core (Black Hole)
    final blackHolePaint = Paint()
      ..color = const Color(0xFF02000A)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset.zero, 18.0, blackHolePaint);

    canvas.restore();
  }
}
