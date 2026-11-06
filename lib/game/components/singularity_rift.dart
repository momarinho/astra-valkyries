import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:asteroids/game/asteroids_game.dart';
import 'package:asteroids/game/glow.dart';
import 'asteroid.dart';
import 'enemy_ship.dart';
import 'dreadnought_leviathan.dart';

class SingularityRiftComponent extends PositionComponent with HasGameReference<AsteroidsGame> {
  final double pullRadius;
  final double damage;
  final double duration;
  double timer = 0.0;
  double damageTickTimer = 0.0;
  double rotation = 0.0;

  SingularityRiftComponent({
    required Vector2 position,
    this.pullRadius = 240.0,
    this.damage = 380.0,
    this.duration = 1.8,
  }) {
    this.position = position;
    anchor = Anchor.center;
    size = Vector2.all(pullRadius * 2);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (game.state != GameState.playing) {
      removeFromParent();
      return;
    }

    timer += dt;
    rotation += dt * 4.5; // Fast swirling accretion disk

    // Gravitational Pull Effect
    final pullFactor = (1.0 - (timer / duration)).clamp(0.2, 1.0);
    _applyGravitationalVortex(dt, pullFactor);

    // Crushing Damage Tick every 0.25s
    damageTickTimer += dt;
    if (damageTickTimer >= 0.25) {
      damageTickTimer = 0.0;
      _applyVortexDamage();
    }

    // Collapse into supernova shockwave at end
    if (timer >= duration) {
      _detonateCollapse();
      removeFromParent();
    }
  }

  void _applyGravitationalVortex(double dt, double pullFactor) {
    // Pull nearby asteroids
    try {
      final asteroids = game.world.children.whereType<AsteroidComponent>();
      for (final a in asteroids) {
        final dist = position.distanceTo(a.position);
        if (dist <= pullRadius && dist > 15.0) {
          final dir = (position - a.position).normalized();
          final strength = (1.0 - (dist / pullRadius)) * 420.0 * pullFactor;
          a.position += dir * strength * dt;
        }
      }
    } catch (_) {}

    // Pull nearby enemy ships
    try {
      final enemies = game.world.children.whereType<EnemyShipComponent>();
      for (final e in enemies) {
        final dist = position.distanceTo(e.position);
        if (dist <= pullRadius && dist > 15.0) {
          final dir = (position - e.position).normalized();
          final strength = (1.0 - (dist / pullRadius)) * 520.0 * pullFactor;
          e.position += dir * strength * dt;
        }
      }
    } catch (_) {}
  }

  void _applyVortexDamage() {
    final tickDmg = damage * 0.18;

    try {
      final asteroids = game.world.children.whereType<AsteroidComponent>();
      for (final a in List<AsteroidComponent>.from(asteroids)) {
        if (position.distanceTo(a.position) <= pullRadius * 0.75) {
          final dead = a.takeDamage(tickDmg, a.position);
          if (dead) game.onAsteroidDestroyed(a.position, a.scoreValue);
        }
      }
    } catch (_) {}

    try {
      final enemies = game.world.children.whereType<EnemyShipComponent>();
      for (final e in List<EnemyShipComponent>.from(enemies)) {
        if (position.distanceTo(e.position) <= pullRadius * 0.75) {
          e.takeDamage(tickDmg, e.position);
        }
      }
    } catch (_) {}

    try {
      final bosses = game.world.children.whereType<DreadnoughtLeviathanComponent>();
      for (final b in List<DreadnoughtLeviathanComponent>.from(bosses)) {
        if (position.distanceTo(b.position) <= pullRadius * 0.75) {
          b.takeDamage(tickDmg, b.position);
        }
      }
    } catch (_) {}
  }

  void _detonateCollapse() {
    game.playSfx('bomb_explode.wav');
    game.triggerScreenShake(duration: 0.45, intensity: 18.0);

    // Final supernova burst particles
    game.spawnExplosionParticles(
      position: position,
      colorChoices: [const Color(0xFFD500F9), const Color(0xFF00E5FF), Colors.white, const Color(0xFFFFD700)],
      count: 45,
      minSize: 2.5,
      maxSize: 6.0,
      minSpeed: 80.0,
      maxSpeed: 320.0,
    );

    // Lethal collapse damage at epicenter
    try {
      final enemies = game.world.children.whereType<EnemyShipComponent>();
      for (final e in List<EnemyShipComponent>.from(enemies)) {
        if (position.distanceTo(e.position) <= pullRadius) {
          e.takeDamage(damage * 0.75, e.position);
        }
      }
    } catch (_) {}

    try {
      final bosses = game.world.children.whereType<DreadnoughtLeviathanComponent>();
      for (final b in List<DreadnoughtLeviathanComponent>.from(bosses)) {
        if (position.distanceTo(b.position) <= pullRadius) {
          b.takeDamage(damage * 0.75, b.position);
        }
      }
    } catch (_) {}

    try {
      final asteroids = game.world.children.whereType<AsteroidComponent>();
      for (final a in List<AsteroidComponent>.from(asteroids)) {
        if (position.distanceTo(a.position) <= pullRadius) {
          final dead = a.takeDamage(damage * 0.75, a.position);
          if (dead) game.onAsteroidDestroyed(a.position, a.scoreValue);
        }
      }
    } catch (_) {}
  }

  @override
  void render(Canvas canvas) {
    canvas.translate(pullRadius, pullRadius);

    final progress = (timer / duration).clamp(0.0, 1.0);
    final coreRadius = 24.0 + 8.0 * math.sin(timer * 12.0);

    // 1. Outer Gravitational Lensing Distort Ring
    final ringPaint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.25 * (1.0 - progress))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(Offset.zero, pullRadius * 0.85, ringPaint);

    // 2. Swirling Accretion Disk Arms
    canvas.save();
    canvas.rotate(rotation);

    for (var i = 0; i < 4; i++) {
      final armAngle = (i * math.pi / 2);
      final armPath = Path();
      armPath.moveTo(0, 0);
      for (double r = 10; r <= pullRadius * 0.7; r += 10) {
        final a = armAngle + (r / 35.0);
        armPath.lineTo(r * math.cos(a), r * math.sin(a));
      }

      final armPaint = Paint()
        ..color = (i.isEven ? const Color(0xFFD500F9) : const Color(0xFF00E5FF)).withValues(alpha: 0.6)
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke;
      canvas.drawPath(armPath, armPaint);
    }
    canvas.restore();

    // 3. Black Hole Event Horizon (Pure Black Void Center)
    final blackHolePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset.zero, coreRadius, blackHolePaint);

    // 4. Glowing Photosphere Border
    Glow.strokeCircle(
      canvas,
      Offset.zero,
      coreRadius,
      const Color(0xFFD500F9),
      width: 3.0,
      intensity: 1.8,
    );
  }
}
