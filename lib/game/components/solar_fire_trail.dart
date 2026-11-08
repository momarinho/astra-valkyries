import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:asteroids/game/asteroids_game.dart';
import 'package:asteroids/game/glow.dart';
import 'enemy_ship.dart';
import 'asteroid.dart';
import 'sector_boss.dart';

class SolarFireTrailComponent extends PositionComponent with HasGameReference<AsteroidsGame> {
  final double initialRadius;
  late double currentRadius;
  double lifespan = 2.2;
  final double maxLifespan = 2.2;
  final double damagePerSecond = 55.0;

  SolarFireTrailComponent({
    required Vector2 position,
    this.initialRadius = 24.0,
  }) {
    this.position = position;
    currentRadius = initialRadius;
    anchor = Anchor.center;
    size = Vector2.all(initialRadius * 2);
  }

  @override
  void update(double dt) {
    super.update(dt);
    lifespan -= dt;
    if (lifespan <= 0) {
      removeFromParent();
      return;
    }

    final progress = lifespan / maxLifespan;
    currentRadius = initialRadius * (0.6 + 0.4 * progress);

    // Damage enemies and push them away
    for (final enemy in game.world.children.whereType<EnemyShipComponent>().toList()) {
      if (enemy.isRemoved) continue;
      final dist = (enemy.position - position).length;
      if (dist < currentRadius + enemy.radius) {
        final pushDir = (enemy.position - position).normalized();
        enemy.velocity += pushDir * (80.0 * dt);
        enemy.takeDamage(damagePerSecond * dt, enemy.position);
      }
    }

    // Damage SectorBoss if present
    for (final boss in game.world.children.whereType<SectorBoss>().toList()) {
      if (boss.isRemoved) continue;
      final dist = (boss.position - position).length;
      if (dist < currentRadius + boss.radius) {
        boss.takeDamage(damagePerSecond * 0.7 * dt, boss.position);
      }
    }

    // Damage and scorch asteroids
    for (final ast in game.world.children.whereType<AsteroidComponent>().toList()) {
      if (ast.isRemoved) continue;
      final dist = (ast.position - position).length;
      if (dist < currentRadius + ast.radius) {
        final pushDir = (ast.position - position).normalized();
        ast.velocity.add(pushDir * (60.0 * dt));
        ast.takeDamage(damagePerSecond * 0.6 * dt, ast.position);
      }
    }
  }

  @override
  void render(Canvas canvas) {
    final progress = (lifespan / maxLifespan).clamp(0.0, 1.0);
    final alpha = (progress * 220).toInt();
    if (alpha <= 0) return;

    final pulse = (math.sin(DateTime.now().millisecondsSinceEpoch / 60.0) + 1) / 2;
    final r = currentRadius * (0.9 + 0.15 * pulse);

    final center = Offset(initialRadius, initialRadius);

    // Outer plasma flare
    final outerPaint = Paint()
      ..color = const Color(0xFFFF5722).withAlpha((alpha * 0.4).toInt())
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, r, outerPaint);

    // Middle fire ring
    Glow.drawGlowCircle(
      canvas,
      center,
      r * 0.75,
      Color.fromARGB(alpha, 255, 152, 0),
      strokeWidth: 2.0,
      intensity: 1.2,
    );

    // Inner white-hot core
    final corePaint = Paint()
      ..color = Color.fromARGB(alpha, 255, 235, 59)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, r * 0.35, corePaint);
  }
}
