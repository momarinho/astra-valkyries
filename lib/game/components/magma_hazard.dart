import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:void_protocol/game/asteroids_game.dart';
import 'package:void_protocol/game/glow.dart';
import 'enemy_ship.dart';

class MagmaHazardComponent extends PositionComponent with HasGameReference<AsteroidsGame> {
  final double radius;
  double duration;
  final double maxDuration;
  double pulseTimer = 0.0;
  double damageTickTimer = 0.0;

  MagmaHazardComponent({
    required Vector2 position,
    this.radius = 75.0,
    this.duration = 3.5,
  }) : maxDuration = duration {
    this.position = position;
    anchor = Anchor.center;
    size = Vector2.all(radius * 2);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (game.state != GameState.playing) {
      removeFromParent();
      return;
    }

    pulseTimer += dt;
    duration -= dt;
    if (duration <= 0) {
      removeFromParent();
      return;
    }

    // Damage tick every 0.35s to enemies inside the lava pool
    damageTickTimer += dt;
    if (damageTickTimer >= 0.35) {
      damageTickTimer = 0.0;
      _applyAreaDamage();
    }
  }

  void _applyAreaDamage() {
    try {
      final enemies = game.world.children.whereType<EnemyShipComponent>();
      for (final enemy in enemies) {
        if (enemy.position.distanceTo(position) <= radius + enemy.radius) {
          enemy.takeDamage(18.0, enemy.position);
          game.spawnExplosionParticles(
            position: enemy.position,
            colorChoices: [Colors.deepOrangeAccent, Colors.orange, Colors.yellow],
            count: 3,
            minSize: 1.5,
            maxSize: 3.0,
            minSpeed: 20.0,
            maxSpeed: 60.0,
          );
        }
      }
    } catch (_) {}

    // Minor thermal burn hazard for player if caught inside
    try {
      final player = game.player;
      if (player.position.distanceTo(position) <= radius && !player.isInvulnerable()) {
        // Player gets light pushback and screen flash
        final pushDir = (player.position - position).normalized();
        player.velocity += pushDir * 180.0;
      }
    } catch (_) {}
  }

  @override
  void render(Canvas canvas) {
    canvas.translate(radius, radius);

    final lifeFraction = (duration / maxDuration).clamp(0.0, 1.0);
    final pulse = 0.90 + 0.10 * math.sin(pulseTimer * 7.0);
    final curR = radius * pulse * lifeFraction;

    // Glowing outer ring
    final outerPaint = Paint()
      ..color = Colors.deepOrangeAccent.withValues(alpha: 0.22 * lifeFraction)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset.zero, curR, outerPaint);

    // Inner burning plasma core
    final corePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFD54F).withValues(alpha: 0.85 * lifeFraction),
          const Color(0xFFFF5722).withValues(alpha: 0.55 * lifeFraction),
          Colors.transparent,
        ],
        stops: const [0.0, 0.65, 1.0],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: curR));
    canvas.drawCircle(Offset.zero, curR * 0.85, corePaint);

    // Crackling perimeter border
    Glow.drawGlowCircle(
      canvas,
      Offset.zero,
      curR,
      const Color(0xFFFF6D00).withValues(alpha: lifeFraction),
      strokeWidth: 2.0,
      intensity: 1.4,
    );
  }
}
