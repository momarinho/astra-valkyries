import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'package:asteroids/constants.dart';
import 'package:asteroids/game/asteroids_game.dart';
import 'package:asteroids/game/glow.dart';
import 'asteroid.dart';

class BulletComponent extends PositionComponent with HasGameReference<AsteroidsGame>, CollisionCallbacks {
  final double radius;
  final Vector2 velocity;
  double lifeTimer;
  final double damage;
  final Color? color;
  int piercesLeft;

  BulletComponent({
    required Vector2 position,
    required this.radius,
    required this.velocity,
    required this.lifeTimer,
    this.damage = 25.0,
    this.color,
    this.piercesLeft = 0,
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
    position += velocity * dt;
    wrapAround();
    
    lifeTimer -= dt;
    if (lifeTimer <= 0) {
      removeFromParent();
    }
  }

  void wrapAround() {
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
    if (other is AsteroidComponent) {
      final destroyed = other.takeDamage(damage, position);
      if (destroyed) {
        game.playSfx('asteroid_split.wav');
        game.onAsteroidDestroyed(other.position, other.scoreValue);
      } else {
        game.playSfx('asteroid_split.wav');
      }

      if (piercesLeft > 0) {
        piercesLeft--;
        // Efeito de faísca indicando perfuração contínua
        game.spawnExplosionParticles(
          position: position,
          colorChoices: [Colors.cyanAccent, Colors.white],
          count: 5,
          minSize: 1.5,
          maxSize: 3.0,
          minSpeed: 40.0,
          maxSpeed: 90.0,
        );
      } else {
        removeFromParent();
      }
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.translate(radius, radius);

    // Sem cor explícita, o tiro assume a cor-tema da valquíria piloto.
    final tint = color ?? game.selectedValkyrie.primaryColor;
    Glow.orb(canvas, Offset.zero, radius * 0.85, tint);
  }
}
