import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'package:asteroids/constants.dart';
import 'package:asteroids/game/asteroids_game.dart';
import 'package:asteroids/game/glow.dart';
import 'player.dart';
import 'dead_cells_biome.dart';

class EnemyBulletComponent extends PositionComponent
    with HasGameReference<AsteroidsGame>, CollisionCallbacks {
  final double radius;
  final Vector2 velocity;
  double lifeTimer;
  final double damage;
  final Color bulletColor;

  EnemyBulletComponent({
    required Vector2 position,
    required this.radius,
    required this.velocity,
    this.lifeTimer = 4.0,
    this.damage = 18.0,
    this.bulletColor = const Color(0xFFFF1744), // Vivid Crimson Neon
  }) {
    this.position = position;
    anchor = Anchor.center;
    size = Vector2.all(radius * 2);
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(CircleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (game.state != GameState.playing) {
      removeFromParent();
      return;
    }

    position += velocity * dt;
    lifeTimer -= dt;
    if (lifeTimer <= 0) {
      removeFromParent();
      return;
    }

    // Wrap / Bounds check
    if (position.x < -radius ||
        position.x > GameConstants.sectorWidth + radius ||
        position.y < -radius ||
        position.y > GameConstants.sectorHeight + radius) {
      removeFromParent();
    }
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is PlayerComponent) {
      other.takeHit(damage);
      removeFromParent();
    } else if (other is MegastructureWallComponent) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.translate(radius, radius);

    final pulse = 0.85 + 0.15 * math.sin(DateTime.now().millisecondsSinceEpoch / 90.0);
    final curR = radius * pulse;

    final fillPaint = Paint()
      ..color = bulletColor.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset.zero, curR * 0.7, fillPaint);

    final centerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset.zero, curR * 0.35, centerPaint);

    Glow.drawGlowCircle(
      canvas,
      Offset.zero,
      curR,
      bulletColor,
      strokeWidth: 1.5,
      intensity: 1.2,
    );
  }
}
