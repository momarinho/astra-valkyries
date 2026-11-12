import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'package:asteroids/constants.dart';
import 'package:asteroids/game/asteroids_game.dart';
import 'package:asteroids/game/glow.dart';
import 'player.dart';

enum ChestTier {
  silver, // 1 item roll
  gold,   // 3 items roll
  cosmic, // 5 items jackpot roll
}

class ChestComponent extends PositionComponent
    with HasGameReference<AsteroidsGame>, CollisionCallbacks {
  final ChestTier tier;
  final double radius;
  double pulseTimer = 0.0;
  double pingTimer = 0.0;
  Vector2 velocity = Vector2.zero();

  ChestComponent({
    required Vector2 position,
    this.tier = ChestTier.gold,
    this.radius = 16.0,
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
  void onMount() {
    super.onMount();
    game.activeChests.add(this);
  }

  @override
  void onRemove() {
    game.activeChests.remove(this);
    super.onRemove();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (game.state != GameState.playing) {
      removeFromParent();
      return;
    }

    pulseTimer += dt;
    pingTimer = (pingTimer + dt * 1.5) % 1.0;

    final player = game.player;
    final dist = position.distanceTo(player.position);
    final magnetDist = player.magnetRadius * 0.9;

    // Magnetized attraction toward player
    if (dist <= magnetDist) {
      final dir = (player.position - position).normalized();
      final speed = math.max(220.0, 550.0 * (1.0 - (dist / magnetDist)));
      velocity += dir * speed * dt;
      if (velocity.length > 480.0) {
        velocity = velocity.normalized() * 480.0;
      }
    } else {
      velocity.scale(math.exp(-1.8 * dt));
    }

    position += velocity * dt;
    position.x = position.x.clamp(radius, GameConstants.sectorWidth - radius);
    position.y = position.y.clamp(radius, GameConstants.sectorHeight - radius);

    // Collect when close
    if (dist <= player.radius + radius + 4.0) {
      collect();
    }
  }

  void collect() {
    removeFromParent();
    game.playSfx('powerup.wav');

    // Golden sparkles celebration
    game.spawnExplosionParticles(
      position: position,
      colorChoices: [const Color(0xFFFFD700), Colors.amberAccent, Colors.white, Colors.cyanAccent],
      count: 24,
      minSize: 2.0,
      maxSize: 4.5,
      minSpeed: 60.0,
      maxSpeed: 200.0,
    );

    game.triggerScreenShake(duration: 0.25, intensity: 8.0);
    game.onChestCollected(tier);
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is PlayerComponent) {
      collect();
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.translate(radius, radius);

    final pulse = 0.90 + 0.10 * math.sin(pulseTimer * 6.0);
    final curR = radius * pulse;

    final Color primaryColor = tier == ChestTier.cosmic
        ? const Color(0xFFFFD700) // Deep Gold
        : (tier == ChestTier.gold ? const Color(0xFFFFB300) : const Color(0xFF80DEEA));

    // Radar Ping ring expanding outward
    final pingRadius = curR + (pingTimer * 26.0);
    final pingOpacity = (1.0 - pingTimer).clamp(0.0, 1.0);
    final pingPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.45 * pingOpacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(Offset.zero, pingRadius, pingPaint);

    // Box container shadow / dark glass body
    final boxRect = Rect.fromCenter(center: Offset.zero, width: curR * 1.6, height: curR * 1.3);
    final boxPaint = Paint()
      ..color = const Color(0xFF0D1B2A).withValues(alpha: 0.92)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(RRect.fromRectAndRadius(boxRect, const Radius.circular(5)), boxPaint);

    // Glowing border outline
    final borderPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRRect(RRect.fromRectAndRadius(boxRect, const Radius.circular(5)), borderPaint);

    // Glowing latch / power core
    final corePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset.zero, curR * 0.25, corePaint);

    Glow.drawGlowCircle(
      canvas,
      Offset.zero,
      curR * 0.45,
      primaryColor,
      strokeWidth: 1.5,
      intensity: 1.5,
    );
  }
}
