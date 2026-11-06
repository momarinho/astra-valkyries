import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'package:asteroids/constants.dart';
import 'package:asteroids/game/asteroids_game.dart';
import 'package:asteroids/game/glow.dart';
import 'player.dart';
import 'enemy_bullet.dart';
import 'xp_orb.dart';
import 'chest.dart';

enum EnemyType {
  scout,          // Swarmer / Fodder: direct fast pursuit
  raider,         // Charger / Kamikaze: telegraphed laser dash
  sniper,         // Artillery: stays back and shoots plasma orbs
  eliteCommander, // Miniboss: large flagship with HP bar & guaranteed chest drop
}

enum RaiderState {
  stalking,
  telegraphing,
  charging,
  recovering,
}

class EnemyShipComponent extends PositionComponent
    with HasGameReference<AsteroidsGame>, CollisionCallbacks {
  final EnemyType type;
  late final double radius;
  late double maxHp;
  late double hp;
  late double baseSpeed;
  late int scoreValue;

  Vector2 velocity = Vector2.zero();
  double hitFlashTimer = 0.0;
  double shootCooldown = 0.0;
  double spiralAngle = 0.0;

  // Phantom Raider specific states
  RaiderState raiderState = RaiderState.stalking;
  double raiderTimer = 0.0;
  Vector2 lockedChargeDirection = Vector2.zero();

  EnemyShipComponent({
    required Vector2 position,
    required this.type,
  }) {
    this.position = position;
    anchor = Anchor.center;

    switch (type) {
      case EnemyType.scout:
        radius = 12.0;
        maxHp = 22.0;
        baseSpeed = 145.0;
        scoreValue = 80;
        break;
      case EnemyType.raider:
        radius = 15.0;
        maxHp = 55.0;
        baseSpeed = 110.0;
        scoreValue = 200;
        raiderTimer = 1.6;
        break;
      case EnemyType.sniper:
        radius = 16.0;
        maxHp = 70.0;
        baseSpeed = 80.0;
        scoreValue = 260;
        shootCooldown = 1.8;
        break;
      case EnemyType.eliteCommander:
        radius = 32.0;
        maxHp = 650.0;
        baseSpeed = 55.0;
        scoreValue = 1500;
        shootCooldown = 2.4;
        break;
    }

    hp = maxHp;
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

    if (hitFlashTimer > 0) {
      hitFlashTimer = math.max(0.0, hitFlashTimer - dt);
    }

    final player = game.player;
    final toPlayer = player.position - position;
    final distToPlayer = toPlayer.length;

    // Despawn non-elite enemies if drifted far outside the camera radius
    if (type != EnemyType.eliteCommander && distToPlayer > GameConstants.proximityDespawnRadius * 1.35) {
      removeFromParent();
      return;
    }

    switch (type) {
      case EnemyType.scout:
        _updateScout(dt, toPlayer, distToPlayer);
        break;
      case EnemyType.raider:
        _updateRaider(dt, player, toPlayer, distToPlayer);
        break;
      case EnemyType.sniper:
        _updateSniper(dt, toPlayer, distToPlayer);
        break;
      case EnemyType.eliteCommander:
        _updateElite(dt, toPlayer, distToPlayer);
        break;
    }

    position += velocity * dt;
    _enforceSectorBounds();
  }

  void _updateScout(double dt, Vector2 toPlayer, double dist) {
    if (dist > 1.0) {
      final targetDir = toPlayer.normalized();
      velocity = targetDir * baseSpeed;
      angle = math.atan2(targetDir.y, targetDir.x) + math.pi / 2;
    }
  }

  void _updateRaider(double dt, PlayerComponent player, Vector2 toPlayer, double dist) {
    raiderTimer -= dt;

    switch (raiderState) {
      case RaiderState.stalking:
        // Orbit and drift near the player at ~350px
        final targetDir = toPlayer.normalized();
        angle = math.atan2(targetDir.y, targetDir.x) + math.pi / 2;
        if (dist > 380) {
          velocity = targetDir * baseSpeed;
        } else if (dist < 260) {
          velocity = -targetDir * (baseSpeed * 0.7);
        } else {
          // Tangential circling
          final tangent = Vector2(-targetDir.y, targetDir.x);
          velocity = tangent * baseSpeed;
        }

        if (raiderTimer <= 0) {
          raiderState = RaiderState.telegraphing;
          raiderTimer = 0.8; // 0.8s telegraphed laser warning
          lockedChargeDirection = targetDir;
          velocity = Vector2.zero();
        }
        break;

      case RaiderState.telegraphing:
        // Keep aim locked on target vector
        angle = math.atan2(lockedChargeDirection.y, lockedChargeDirection.x) + math.pi / 2;
        velocity = Vector2.zero();

        if (raiderTimer <= 0) {
          raiderState = RaiderState.charging;
          raiderTimer = 1.1; // 1.1s high speed charge
          velocity = lockedChargeDirection * 390.0;
          game.playSfx('dash.wav');
        }
        break;

      case RaiderState.charging:
        // Dash along locked trajectory with flame particles
        angle = math.atan2(lockedChargeDirection.y, lockedChargeDirection.x) + math.pi / 2;
        if (math.Random().nextDouble() < 0.45) {
          game.spawnExplosionParticles(
            position: position,
            colorChoices: [const Color(0xFFFF1744), Colors.amberAccent, Colors.orange],
            count: 2,
            minSize: 1.5,
            maxSize: 3.0,
            minSpeed: 20.0,
            maxSpeed: 60.0,
          );
        }

        if (raiderTimer <= 0) {
          raiderState = RaiderState.recovering;
          raiderTimer = 0.6;
          velocity = lockedChargeDirection * (baseSpeed * 0.5);
        }
        break;

      case RaiderState.recovering:
        velocity.scale(math.exp(-2.5 * dt));
        if (raiderTimer <= 0) {
          raiderState = RaiderState.stalking;
          raiderTimer = 2.0;
        }
        break;
    }
  }

  void _updateSniper(double dt, Vector2 toPlayer, double dist) {
    final targetDir = toPlayer.normalized();
    angle = math.atan2(targetDir.y, targetDir.x) + math.pi / 2;

    // Maintain artillery distance between 320px and 450px
    if (dist > 450) {
      velocity = targetDir * baseSpeed;
    } else if (dist < 320) {
      velocity = -targetDir * (baseSpeed * 0.9);
    } else {
      final tangent = Vector2(-targetDir.y, targetDir.x);
      velocity = tangent * (baseSpeed * 0.6);
    }

    shootCooldown -= dt;
    if (shootCooldown <= 0 && dist <= 550) {
      shootCooldown = 2.5;
      final bulletVel = targetDir * 230.0;
      game.world.add(
        EnemyBulletComponent(
          position: position + targetDir * (radius + 4.0),
          radius: 4.5,
          velocity: bulletVel,
          damage: 1.0,
          bulletColor: const Color(0xFFE040FB), // Magenta
        ),
      );
      game.playSfx('shoot.wav');
    }
  }

  void _updateElite(double dt, Vector2 toPlayer, double dist) {
    final targetDir = toPlayer.normalized();
    angle = math.atan2(targetDir.y, targetDir.x) + math.pi / 2;

    // Slow relentless advance toward player
    velocity = targetDir * baseSpeed;

    shootCooldown -= dt;
    if (shootCooldown <= 0 && dist <= 700) {
      shootCooldown = 3.2;
      spiralAngle += 0.35;

      // 5-way spiral salvo
      const int count = 5;
      const double spread = 0.38; // radians
      final baseAngle = math.atan2(targetDir.y, targetDir.x) + spiralAngle;

      for (var i = 0; i < count; i++) {
        final currentSalvoAngle = baseAngle + (i - (count - 1) / 2) * spread;
        final dir = Vector2(math.cos(currentSalvoAngle), math.sin(currentSalvoAngle));
        game.world.add(
          EnemyBulletComponent(
            position: position + dir * (radius + 6.0),
            radius: 5.5,
            velocity: dir * 210.0,
            damage: 1.0,
            bulletColor: const Color(0xFFFFD700), // Imperial Gold
          ),
        );
      }
      game.playSfx('shoot.wav');
    }
  }

  void _enforceSectorBounds() {
    position.x = position.x.clamp(radius, GameConstants.sectorWidth - radius);
    position.y = position.y.clamp(radius, GameConstants.sectorHeight - radius);
  }

  bool takeDamage(double damage, Vector2 hitPos) {
    hp -= damage;
    hitFlashTimer = 0.12;

    game.spawnExplosionParticles(
      position: hitPos,
      colorChoices: [Colors.white, const Color(0xFFFF1744), Colors.amber],
      count: 3,
      minSize: 1.5,
      maxSize: 3.0,
      minSpeed: 30.0,
      maxSpeed: 80.0,
    );

    if (hp <= 0) {
      die();
      return true;
    } else {
      game.spawnFloatingText(
        hitPos,
        '-${damage.toInt()}',
        color: const Color(0xFFFF8A80),
        fontSize: 11.5,
      );
      return false;
    }
  }

  void die() {
    removeFromParent();
    game.playSfx('asteroid_split.wav');
    game.addScore(scoreValue);

    // Award scrap credits based on enemy tier
    final int scrapReward;
    switch (type) {
      case EnemyType.scout:
        scrapReward = 6;
        break;
      case EnemyType.raider:
        scrapReward = 20;
        break;
      case EnemyType.sniper:
        scrapReward = 35;
        break;
      case EnemyType.eliteCommander:
        scrapReward = 120;
        break;
    }
    game.addRunCredits(scrapReward);
    game.spawnFloatingText(position, '+$scoreValue', color: Colors.white, fontSize: 13.0);

    final isElite = type == EnemyType.eliteCommander;
    final shake = isElite ? 16.0 : (type == EnemyType.raider ? 6.0 : 4.0);
    game.triggerScreenShake(duration: isElite ? 0.45 : 0.2, intensity: shake);

    // Explosion particles
    final List<Color> colors = isElite
        ? [const Color(0xFFFFD700), const Color(0xFFD500F9), Colors.white, Colors.orange]
        : [const Color(0xFFFF1744), const Color(0xFFFF5252), Colors.white];

    game.spawnExplosionParticles(
      position: position,
      colorChoices: colors,
      count: isElite ? 45 : 16,
      minSize: 2.0,
      maxSize: isElite ? 5.5 : 3.5,
      minSpeed: 50.0,
      maxSpeed: isElite ? 280.0 : 160.0,
    );

    // Vampire Survivors formula: Drop Stardust XP / Chest
    if (isElite) {
      // ⚠️ GUARANTEED COSMIC CHEST FROM ELITE COMMANDER!
      game.world.add(
        ChestComponent(
          position: position.clone(),
          tier: ChestTier.gold,
        ),
      );
      // Extra large XP burst
      game.world.add(XpOrbComponent(position: position + Vector2(-15, 0), type: XpOrbType.large));
      game.world.add(XpOrbComponent(position: position + Vector2(15, 0), type: XpOrbType.large));

      game.spawnFloatingText(
        position + Vector2(0, -35),
        '⚠️ VOID COMMANDER DESTROYED!',
        color: const Color(0xFFFFD700),
        fontSize: 16.0,
      );
    } else if (type == EnemyType.raider || type == EnemyType.sniper) {
      game.world.add(XpOrbComponent(position: position.clone(), type: XpOrbType.medium));
    } else {
      game.world.add(XpOrbComponent(position: position.clone(), type: XpOrbType.small));
    }
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is PlayerComponent) {
      other.takeHit(1.0);
      // Small bounce/recoil away from player
      final push = (position - other.position).normalized();
      velocity = push * (baseSpeed * 1.5);
    }
  }

  @override
  void render(Canvas canvas) {
    // 1. Draw Telegraphed Red Aiming Laser for Raider
    if (type == EnemyType.raider && raiderState == RaiderState.telegraphing) {
      final pulse = (math.sin(DateTime.now().millisecondsSinceEpoch / 50.0) + 1) / 2;
      final laserPaint = Paint()
        ..color = const Color(0xFFFF1744).withValues(alpha: 0.45 + pulse * 0.45)
        ..strokeWidth = 1.8 + pulse * 1.2
        ..style = PaintingStyle.stroke;

      // Laser points along lockedChargeDirection from ship center
      final endOffset = Offset(lockedChargeDirection.x * 650.0, lockedChargeDirection.y * 650.0);
      canvas.drawLine(Offset(radius, radius), Offset(radius + endOffset.dx, radius + endOffset.dy), laserPaint);
    }

    canvas.save();
    canvas.translate(radius, radius);
    canvas.rotate(angle);

    final isFlashing = hitFlashTimer > 0;
    final flashColor = Colors.white;

    switch (type) {
      case EnemyType.scout:
        _renderScout(canvas, isFlashing, flashColor);
        break;
      case EnemyType.raider:
        _renderRaider(canvas, isFlashing, flashColor);
        break;
      case EnemyType.sniper:
        _renderSniper(canvas, isFlashing, flashColor);
        break;
      case EnemyType.eliteCommander:
        _renderElite(canvas, isFlashing, flashColor);
        break;
    }

    canvas.restore();

    // 2. Floating Health Bar for Elite Commander (drawn unrotated above the ship)
    if (type == EnemyType.eliteCommander) {
      _renderHealthBar(canvas);
    }
  }

  void _renderScout(Canvas canvas, bool isFlashing, Color flashColor) {
    final path = Path()
      ..moveTo(0, -radius)
      ..lineTo(radius * 0.8, radius)
      ..lineTo(0, radius * 0.4)
      ..lineTo(-radius * 0.8, radius)
      ..close();

    final bodyPaint = Paint()
      ..color = const Color(0xFF1E0A24).withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, bodyPaint);

    final strokeColor = isFlashing ? flashColor : const Color(0xFFFF4081);
    Glow.strokePath(canvas, path, strokeColor, width: 1.8, intensity: 1.2);
  }

  void _renderRaider(Canvas canvas, bool isFlashing, Color flashColor) {
    final path = Path()
      ..moveTo(0, -radius * 1.2)
      ..lineTo(radius * 0.7, radius * 0.8)
      ..lineTo(radius * 0.3, radius * 0.4)
      ..lineTo(0, radius * 0.6)
      ..lineTo(-radius * 0.3, radius * 0.4)
      ..lineTo(-radius * 0.7, radius * 0.8)
      ..close();

    final bodyPaint = Paint()
      ..color = const Color(0xFF2B0B0E).withValues(alpha: 0.95)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, bodyPaint);

    final strokeColor = isFlashing ? flashColor : const Color(0xFFFF1744);
    Glow.strokePath(canvas, path, strokeColor, width: 2.0, intensity: 1.4);

    // Glowing crimson core
    final corePaint = Paint()
      ..color = isFlashing ? flashColor : const Color(0xFFFF5252)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(0, -radius * 0.2), 2.5, corePaint);
  }

  void _renderSniper(Canvas canvas, bool isFlashing, Color flashColor) {
    // Hexagonal hull with front gun prongs
    final path = Path()
      ..moveTo(0, -radius)
      ..lineTo(radius * 0.8, -radius * 0.3)
      ..lineTo(radius * 0.8, radius * 0.6)
      ..lineTo(0, radius)
      ..lineTo(-radius * 0.8, radius * 0.6)
      ..lineTo(-radius * 0.8, -radius * 0.3)
      ..close();

    final bodyPaint = Paint()
      ..color = const Color(0xFF100E2B).withValues(alpha: 0.95)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, bodyPaint);

    final strokeColor = isFlashing ? flashColor : const Color(0xFF7C4DFF);
    Glow.strokePath(canvas, path, strokeColor, width: 2.0, intensity: 1.3);

    // Twin sniper railgun barrels
    final gunPaint = Paint()
      ..color = isFlashing ? flashColor : const Color(0xFFE040FB)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(-radius * 0.45, -radius * 0.3), Offset(-radius * 0.45, -radius * 1.3), gunPaint);
    canvas.drawLine(Offset(radius * 0.45, -radius * 0.3), Offset(radius * 0.45, -radius * 1.3), gunPaint);
  }

  void _renderElite(Canvas canvas, bool isFlashing, Color flashColor) {
    // Majestic armored command cruiser hull
    final path = Path()
      ..moveTo(0, -radius * 1.25)
      ..lineTo(radius * 0.65, -radius * 0.4)
      ..lineTo(radius, radius * 0.7)
      ..lineTo(radius * 0.35, radius * 0.95)
      ..lineTo(0, radius * 0.6)
      ..lineTo(-radius * 0.35, radius * 0.95)
      ..lineTo(-radius, radius * 0.7)
      ..lineTo(-radius * 0.65, -radius * 0.4)
      ..close();

    final bodyPaint = Paint()
      ..color = const Color(0xFF180A28).withValues(alpha: 0.95)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, bodyPaint);

    final strokeColor = isFlashing ? flashColor : const Color(0xFFFFD700);
    Glow.strokePath(canvas, path, strokeColor, width: 2.5, intensity: 1.6);

    // Inner imperial insignia & purple energy core
    final corePaint = Paint()
      ..color = isFlashing ? flashColor : const Color(0xFFD500F9)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(0, -radius * 0.1), 6.5, corePaint);

    Glow.drawGlowCircle(
      canvas,
      Offset(0, -radius * 0.1),
      9.0,
      const Color(0xFFD500F9),
      strokeWidth: 2.0,
      intensity: 1.5,
    );
  }

  void _renderHealthBar(Canvas canvas) {
    const barWidth = 60.0;
    const barHeight = 6.0;
    const barY = -12.0;
    final barX = radius - barWidth / 2;

    // Background
    final bgPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(barX, barY, barWidth, barHeight), const Radius.circular(3)),
      bgPaint,
    );

    // Health Fill (Gold gradient)
    final healthRatio = (hp / maxHp).clamp(0.0, 1.0);
    final fillPaint = Paint()
      ..color = const Color(0xFFFFD700)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(barX, barY, barWidth * healthRatio, barHeight), const Radius.circular(3)),
      fillPaint,
    );

    // Border
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(barX, barY, barWidth, barHeight), const Radius.circular(3)),
      borderPaint,
    );
  }
}
