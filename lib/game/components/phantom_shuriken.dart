import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:asteroids/game/asteroids_game.dart';
import 'package:asteroids/game/glow.dart';
import 'enemy_ship.dart';
import 'asteroid.dart';
import 'sector_boss.dart';

class PhantomShurikenComponent extends PositionComponent with HasGameReference<AsteroidsGame> {
  final double damage = 45.0;
  Vector2 velocity;
  double lifespan = 2.0;
  double spinAngle = 0.0;
  PositionComponent? target;

  PhantomShurikenComponent({
    required Vector2 position,
    required this.velocity,
  }) {
    this.position = position;
    anchor = Anchor.center;
    size = Vector2.all(18.0);
  }

  @override
  void update(double dt) {
    super.update(dt);
    lifespan -= dt;
    if (lifespan <= 0) {
      removeFromParent();
      return;
    }

    spinAngle += 18.0 * dt;

    // Find nearest target if none locked
    if (target == null || target!.isRemoved) {
      double closestDist = 450.0;
      for (final enemy in game.world.children.whereType<EnemyShipComponent>().toList()) {
        if (enemy.isRemoved) continue;
        final d = (enemy.position - position).length;
        if (d < closestDist) {
          closestDist = d;
          target = enemy;
        }
      }
      if (target == null) {
        for (final ast in game.world.children.whereType<AsteroidComponent>().toList()) {
          if (ast.isRemoved) continue;
          final d = (ast.position - position).length;
          if (d < closestDist) {
            closestDist = d;
            target = ast;
          }
        }
      }
    }

    // Home in towards target with aggressive steering
    if (target != null && !target!.isRemoved) {
      final desired = (target!.position - position).normalized() * 520.0;
      velocity += (desired - velocity) * (7.0 * dt);
    }

    position += velocity * dt;

    // Check hit against enemies
    for (final enemy in game.world.children.whereType<EnemyShipComponent>().toList()) {
      if (enemy.isRemoved) continue;
      if ((enemy.position - position).length < 16.0 + enemy.radius) {
        enemy.takeDamage(damage, position);
        _detonate();
        return;
      }
    }

    // Check hit against boss
    for (final boss in game.world.children.whereType<SectorBoss>().toList()) {
      if (boss.isRemoved) continue;
      if ((boss.position - position).length < 16.0 + boss.radius) {
        boss.takeDamage(damage, position);
        _detonate();
        return;
      }
    }

    // Check hit against asteroids
    for (final ast in game.world.children.whereType<AsteroidComponent>().toList()) {
      if (ast.isRemoved) continue;
      if ((ast.position - position).length < 16.0 + ast.radius) {
        ast.takeDamage(damage, position);
        _detonate();
        return;
      }
    }
  }

  void _detonate() {
    game.playSfx('asteroid_split.wav');
    game.spawnExplosionParticles(
      position: position,
      colorChoices: [const Color(0xFFD500F9), const Color(0xFFE040FB), Colors.white],
      count: 10,
      minSize: 1.5,
      maxSize: 3.5,
      minSpeed: 40.0,
      maxSpeed: 120.0,
    );
    removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    canvas.save();
    canvas.translate(9.0, 9.0);
    canvas.rotate(spinAngle);

    final path = Path();
    const blades = 4;
    const rOuter = 9.0;
    const rInner = 2.5;

    for (var i = 0; i < blades * 2; i++) {
      final r = i.isEven ? rOuter : rInner;
      final a = i * math.pi / blades;
      final x = r * math.cos(a);
      final y = r * math.sin(a);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    final fillPaint = Paint()
      ..color = const Color(0xFF1B0324)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    Glow.strokePath(
      canvas,
      path,
      const Color(0xFFD500F9),
      width: 1.8,
      intensity: 1.4,
    );

    canvas.restore();
  }
}
