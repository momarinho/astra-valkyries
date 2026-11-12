import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'package:asteroids/constants.dart';
import 'package:asteroids/game/asteroids_game.dart';
import 'package:asteroids/game/glow.dart';
import 'asteroid.dart';
import 'cargo_wreck.dart';
import 'breakable_prop.dart';
import 'enemy_ship.dart';
import 'sector_boss.dart';
import 'advanced_weapons.dart';
import 'package:asteroids/game/weapons.dart';

class BulletComponent extends PositionComponent
    with HasGameReference<AsteroidsGame>, CollisionCallbacks {
  final double radius;
  final Vector2 velocity;
  double lifeTimer;
  final double damage;
  final Color? color;
  int piercesLeft;
  final ElementalStatus elementalStatus;
  final Weapon? weaponSource;
  double _evolvedTrailTimer = 0.0;

  BulletComponent({
    required Vector2 position,
    required this.radius,
    required this.velocity,
    required this.lifeTimer,
    this.damage = 25.0,
    this.color,
    this.piercesLeft = 0,
    this.elementalStatus = ElementalStatus.none,
    this.weaponSource,
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

    // Sprint 51: Partículas de rastro para projéteis de armas Super-Evoluídas
    if (weaponSource?.isEvolved == true) {
      _evolvedTrailTimer += dt;
      if (_evolvedTrailTimer >= 0.04) {
        _evolvedTrailTimer = 0.0;
        try {
          game.spawnExplosionParticles(
            position: position,
            colorChoices: [color ?? const Color(0xFFFFD700), Colors.white],
            count: 1,
            minSize: 1.2,
            maxSize: 2.4,
            minSpeed: 15.0,
            maxSpeed: 45.0,
          );
        } catch (_) {}
      }
    }

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

  (double damage, bool isCrit) _computeDealtDamage() {
    double dealtDamage = damage;
    bool isCrit = false;
    try {
      final totalCritChance =
          (game.rogueCritChance + game.player.bonusCritChance).clamp(0.0, 1.0);
      if (totalCritChance > 0 && math.Random().nextDouble() < totalCritChance) {
        dealtDamage *= game.rogueCritMultiplier;
        isCrit = true;
      }
    } catch (_) {}
    return (dealtDamage, isCrit);
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is AsteroidComponent) {
      final (dealtDamage, isCrit) = _computeDealtDamage();

      final destroyed = other.takeDamage(dealtDamage, position);
      weaponSource?.totalDamageDealt += dealtDamage;
      if (destroyed) {
        weaponSource?.totalKills++;
      }
      if (isCrit) {
        game.spawnFloatingText(
          position + Vector2(0, -18),
          'CRIT!',
          color: const Color(0xFFFF5252),
          fontSize: 13.0,
        );
      }
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
    } else if (other is CargoWreckComponent) {
      final (dealtDamage, _) = _computeDealtDamage();

      final destroyed = other.takeDamage(dealtDamage, position);
      weaponSource?.totalDamageDealt += dealtDamage;
      if (destroyed) {
        weaponSource?.totalKills++;
      }
      if (piercesLeft > 0) {
        piercesLeft--;
      } else {
        removeFromParent();
      }
    } else if (other is BreakablePropComponent) {
      final (dealtDamage, _) = _computeDealtDamage();

      final destroyed = other.takeDamage(dealtDamage, position);
      weaponSource?.totalDamageDealt += dealtDamage;
      if (destroyed) {
        weaponSource?.totalKills++;
      }
      if (piercesLeft > 0) {
        piercesLeft--;
      } else {
        removeFromParent();
      }
    } else if (other is EnemyShipComponent) {
      final (dealtDamage, isCrit) = _computeDealtDamage();

      if (elementalStatus != ElementalStatus.none) {
        other.applyElementalStatus(elementalStatus, duration: 4.0);
      }
      final destroyed = other.takeDamage(dealtDamage, position);
      weaponSource?.totalDamageDealt += dealtDamage;
      if (destroyed) {
        weaponSource?.totalKills++;
      }
      if (isCrit) {
        game.spawnFloatingText(
          position + Vector2(0, -18),
          'CRIT!',
          color: const Color(0xFFFF5252),
          fontSize: 13.0,
        );
      }

      if (piercesLeft > 0) {
        piercesLeft--;
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
    } else if (other is SectorBoss) {
      final (dealtDamage, isCrit) = _computeDealtDamage();

      if (elementalStatus != ElementalStatus.none) {
        other.applyElementalStatus(elementalStatus, duration: 4.0);
      }
      final destroyed = other.takeDamage(dealtDamage, position);
      weaponSource?.totalDamageDealt += dealtDamage;
      if (destroyed) {
        weaponSource?.totalKills++;
      }
      if (isCrit) {
        game.spawnFloatingText(
          position + Vector2(0, -18),
          'CRIT!',
          color: const Color(0xFFFF5252),
          fontSize: 13.0,
        );
      }

      if (piercesLeft > 0) {
        piercesLeft--;
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

    // Sprint 51: Corona de energia luminosa para disparos super-evoluídos
    if (weaponSource?.isEvolved == true) {
      final coronaPaint = Paint()
        ..color = tint.withValues(alpha: 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0);
      canvas.drawCircle(Offset.zero, radius * 1.5, coronaPaint);
    }

    Glow.orb(canvas, Offset.zero, radius * 0.85, tint);
  }
}
