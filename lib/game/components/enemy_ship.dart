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
import 'drop.dart';
import 'advanced_weapons.dart';

enum EnemyType {
  scout,          // Swarmer / Fodder: direct fast pursuit
  raider,         // Charger / Kamikaze: telegraphed laser dash
  sniper,         // Artillery: stays back and shoots plasma orbs
  eliteCommander, // Miniboss: large flagship with HP bar & guaranteed chest drop
  voidSwarmer,    // Sprint 15: Ultra-fast swarm drone that spawns in packs of 15-30
  aegisBulwark,   // Sprint 15: Heavy cruiser with impenetrable frontal shield (requires flanking/dash)
  carrierHive,    // Sprint 15: Mothership that spawns Void Swarmers from afar
  gravityWeaver,  // Sprint 15: Warps local gravity, pulling the player ship inward
  cryoBomber,     // Sprint 15: Fires glacial cryo-shells that slow movement
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

  // Sprint 14: 4 Elemental Status Effects & Cross-Elemental Synergy
  final Map<ElementalStatus, double> activeStatuses = {};
  double _burnTickTimer = 0.0;

  bool hasStatus(ElementalStatus status) => (activeStatuses[status] ?? 0.0) > 0.0;

  void applyElementalStatus(ElementalStatus status, {double duration = 4.0}) {
    if (status == ElementalStatus.none || hp <= 0) return;

    // Check for Cross-Elemental Synergy Reaction (e.g. Freeze + Burn, Shock + Freeze, Rupture + Element)
    final hadOtherElement = activeStatuses.entries.any((e) => e.key != status && e.value > 0);
    activeStatuses[status] = math.max(activeStatuses[status] ?? 0.0, duration);

    if (hadOtherElement) {
      try {
        game.spawnFloatingText(
          position + Vector2(0, -radius - 10),
          '⚡ ELEMENTAL SYNERGY!',
          color: const Color(0xFFFFD700),
          fontSize: 11.0,
        );
      } catch (_) {}
      hp -= 28.0;
      if (hp <= 0) {
        die();
        return;
      }
    }

    // Ion Shock arcs electricity to a nearby enemy within 170px
    if (status == ElementalStatus.ionShock) {
      try {
        for (final other in game.world.children.whereType<EnemyShipComponent>()) {
          if (other != this && other.hp > 0 && other.position.distanceTo(position) <= 170.0) {
            other.hp -= 14.0;
            if (other.hp <= 0) {
              other.die();
            }
            break;
          }
        }
      } catch (_) {}
    }
  }

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
      case EnemyType.voidSwarmer:
        radius = 9.5;
        maxHp = 14.0;
        baseSpeed = 195.0;
        scoreValue = 55;
        break;
      case EnemyType.aegisBulwark:
        radius = 22.0;
        maxHp = 190.0;
        baseSpeed = 72.0;
        scoreValue = 420;
        break;
      case EnemyType.carrierHive:
        radius = 28.0;
        maxHp = 340.0;
        baseSpeed = 48.0;
        scoreValue = 750;
        shootCooldown = 3.2;
        break;
      case EnemyType.gravityWeaver:
        radius = 18.0;
        maxHp = 115.0;
        baseSpeed = 85.0;
        scoreValue = 340;
        shootCooldown = 2.0;
        break;
      case EnemyType.cryoBomber:
        radius = 17.0;
        maxHp = 95.0;
        baseSpeed = 90.0;
        scoreValue = 310;
        shootCooldown = 2.2;
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

    // Tick Elemental Statuses (Solar Burn DoT & Cryo Freeze Slow)
    if (activeStatuses.isNotEmpty) {
      final expired = <ElementalStatus>[];
      activeStatuses.forEach((st, remaining) {
        final next = remaining - dt;
        if (next <= 0) {
          expired.add(st);
        } else {
          activeStatuses[st] = next;
        }
      });
      for (final st in expired) {
        activeStatuses.remove(st);
      }

      if (hasStatus(ElementalStatus.solarBurn)) {
        _burnTickTimer += dt;
        if (_burnTickTimer >= 0.5) {
          _burnTickTimer = 0.0;
          takeDamage(14.0, position);
          if (hp <= 0) return;
        }
      }
    }

    final cryoSlowFactor = hasStatus(ElementalStatus.cryoFreeze) ? 0.50 : 1.0;
    final effectiveDt = dt * cryoSlowFactor;

    final player = game.player;
    final toPlayer = player.position - position;
    final distToPlayer = toPlayer.length;

    // Despawn non-elite enemies if drifted far outside the camera radius
    if (type != EnemyType.eliteCommander &&
        type != EnemyType.carrierHive &&
        distToPlayer > GameConstants.proximityDespawnRadius * 1.35) {
      removeFromParent();
      return;
    }

    switch (type) {
      case EnemyType.scout:
        _updateScout(effectiveDt, toPlayer, distToPlayer);
        break;
      case EnemyType.raider:
        _updateRaider(effectiveDt, player, toPlayer, distToPlayer);
        break;
      case EnemyType.sniper:
        _updateSniper(effectiveDt, toPlayer, distToPlayer);
        break;
      case EnemyType.eliteCommander:
        _updateElite(effectiveDt, toPlayer, distToPlayer);
        break;
      case EnemyType.voidSwarmer:
        _updateVoidSwarmer(effectiveDt, toPlayer, distToPlayer);
        break;
      case EnemyType.aegisBulwark:
        _updateAegisBulwark(effectiveDt, toPlayer, distToPlayer);
        break;
      case EnemyType.carrierHive:
        _updateCarrierHive(effectiveDt, toPlayer, distToPlayer);
        break;
      case EnemyType.gravityWeaver:
        _updateGravityWeaver(effectiveDt, player, toPlayer, distToPlayer);
        break;
      case EnemyType.cryoBomber:
        _updateCryoBomber(effectiveDt, toPlayer, distToPlayer);
        break;
    }

    position += velocity * cryoSlowFactor * dt;
    _enforceSectorBounds();
  }

  void _updateVoidSwarmer(double dt, Vector2 toPlayer, double dist) {
    if (dist > 1.0) {
      final dir = toPlayer.normalized();
      final tangent = Vector2(-dir.y, dir.x) * math.sin( spiralAngle += dt * 7.0 ) * 0.35;
      final combined = (dir + tangent).normalized();
      velocity = combined * baseSpeed;
      angle = math.atan2(combined.y, combined.x) + math.pi / 2;
    }
  }

  void _updateAegisBulwark(double dt, Vector2 toPlayer, double dist) {
    if (dist > 1.0) {
      final targetDir = toPlayer.normalized();
      final desiredAngle = math.atan2(targetDir.y, targetDir.x) + math.pi / 2;
      double diff = (desiredAngle - angle) % (math.pi * 2);
      if (diff > math.pi) diff -= math.pi * 2;
      if (diff < -math.pi) diff += math.pi * 2;
      // Turns deliberately so the player can Dash behind its frontal shield!
      angle += diff.clamp(-1.8 * dt, 1.8 * dt);
      final forwardDir = Vector2(math.cos(angle - math.pi / 2), math.sin(angle - math.pi / 2));
      velocity = forwardDir * baseSpeed;
    }
  }

  void _updateCarrierHive(double dt, Vector2 toPlayer, double dist) {
    final targetDir = dist > 1.0 ? toPlayer.normalized() : Vector2(0, -1);
    angle = math.atan2(targetDir.y, targetDir.x) + math.pi / 2;
    if (dist > 520) {
      velocity = targetDir * baseSpeed;
    } else if (dist < 360) {
      velocity = -targetDir * (baseSpeed * 0.8);
    } else {
      velocity = Vector2(-targetDir.y, targetDir.x) * (baseSpeed * 0.5);
    }

    shootCooldown -= dt;
    if (shootCooldown <= 0) {
      shootCooldown = 3.8;
      // Spawns a mini-squad of 3 Void Swarmers if under enemy cap
      final currentEnemies = game.world.children.whereType<EnemyShipComponent>().length;
      if (currentEnemies < 32) {
        for (var i = -1; i <= 1; i++) {
          final offset = Vector2(i * 24.0, 24.0);
          game.world.add(
            EnemyShipComponent(
              position: position + offset,
              type: EnemyType.voidSwarmer,
            ),
          );
        }
      }
    }
  }

  void _updateGravityWeaver(double dt, PlayerComponent player, Vector2 toPlayer, double dist) {
    if (dist > 1.0) {
      final dir = toPlayer.normalized();
      angle += 2.5 * dt;
      velocity = dir * baseSpeed;
      // Pulls the player ship gently toward the Gravity Weaver within 340px
      if (dist <= 340.0) {
        final pullToWeaver = (position - player.position).normalized();
        player.velocity += pullToWeaver * (110.0 * dt);
      }
    }
  }

  void _updateCryoBomber(double dt, Vector2 toPlayer, double dist) {
    final targetDir = dist > 1.0 ? toPlayer.normalized() : Vector2(0, -1);
    angle = math.atan2(targetDir.y, targetDir.x) + math.pi / 2;
    velocity = targetDir * baseSpeed;

    shootCooldown -= dt;
    if (shootCooldown <= 0 && dist <= 520) {
      shootCooldown = 2.4;
      game.world.add(
        EnemyBulletComponent(
          position: position + targetDir * (radius + 5.0),
          radius: 6.0,
          velocity: targetDir * 195.0,
          damage: 1.0,
          bulletColor: const Color(0xFF80D8FF),
        ),
      );
    }
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
        final desiredAngle = math.atan2(targetDir.y, targetDir.x) + math.pi / 2;
        double diff = (desiredAngle - angle) % (math.pi * 2);
        if (diff > math.pi) diff -= math.pi * 2;
        if (diff < -math.pi) diff += math.pi * 2;
        angle += diff.clamp(-7.0 * dt, 7.0 * dt);

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
          angle = math.atan2(targetDir.y, targetDir.x) + math.pi / 2;
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
    double effectiveDamage = damage;

    // Void Rupture amplification (+35% damage from all sources)
    if (hasStatus(ElementalStatus.voidRupture)) {
      effectiveDamage *= 1.35;
    }

    // Aegis Bulwark directional frontal shield: blocks 80% of damage hitting the front arc!
    if (type == EnemyType.aegisBulwark) {
      final forwardDir = Vector2(math.cos(angle - math.pi / 2), math.sin(angle - math.pi / 2));
      Vector2 toAttacker = hitPos - position;
      if (toAttacker.length <= 0.1) {
        try {
          toAttacker = game.player.position - position;
        } catch (_) {}
      }
      if (toAttacker.length > 0.1 && toAttacker.normalized().dot(forwardDir) > 0.30) {
        effectiveDamage *= 0.20;
        try {
          game.spawnFloatingText(
            hitPos,
            '🛡️ SHIELDED!',
            color: const Color(0xFF00E5FF),
            fontSize: 10.0,
          );
        } catch (_) {}
      }
    }

    hp -= effectiveDamage;
    hitFlashTimer = 0.12;

    try {
      game.spawnExplosionParticles(
        position: hitPos,
        colorChoices: [Colors.white, const Color(0xFFFF1744), Colors.amber],
        count: 3,
        minSize: 1.5,
        maxSize: 3.0,
        minSpeed: 30.0,
        maxSpeed: 80.0,
      );
    } catch (_) {}

    if (hp <= 0) {
      die();
      return true;
    } else {
      try {
        game.spawnFloatingText(
          hitPos,
          '-${damage.toInt()}',
          color: const Color(0xFFFF8A80),
          fontSize: 11.5,
        );
      } catch (_) {}
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
      case EnemyType.voidSwarmer:
        scrapReward = 4;
        break;
      case EnemyType.aegisBulwark:
        scrapReward = 45;
        break;
      case EnemyType.carrierHive:
        scrapReward = 80;
        break;
      case EnemyType.gravityWeaver:
        scrapReward = 35;
        break;
      case EnemyType.cryoBomber:
        scrapReward = 30;
        break;
    }
    game.addRunCredits(scrapReward);
    game.spawnFloatingText(position, '+$scoreValue', color: Colors.white, fontSize: 13.0);

    // Solar Burn Death Detonation Synergy: enemies dying while burning explode!
    if (hasStatus(ElementalStatus.solarBurn)) {
      for (final other in List<EnemyShipComponent>.from(game.world.children.whereType<EnemyShipComponent>())) {
        if (other != this && other.hp > 0 && other.position.distanceTo(position) <= 105.0) {
          other.takeDamage(35.0, other.position);
        }
      }
    }

    // Blueprint Drop (Sprint 16): Elites and Carrier Hives can drop technological Blueprints!
    if (type == EnemyType.eliteCommander || type == EnemyType.carrierHive) {
      game.tryDropBlueprint(position);
    }

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
      game.chargeBossBeacon('SUB-CHEFE ABATIDO');
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

    // Health capsule drop: 100% on Elite, 8% on standard enemies (16% if player HP < 50%)
    final hpRatio = game.player.hpPercent;
    final healthChance = isElite ? 1.0 : (hpRatio < 0.5 ? 0.16 : 0.08);
    if (math.Random().nextDouble() < healthChance) {
      game.world.add(
        DropComponent(
          position: position.clone(),
          type: DropType.health,
          initialVelocity: Vector2(
            (math.Random().nextDouble() - 0.5) * 30.0,
            (math.Random().nextDouble() - 0.5) * 30.0,
          ),
        ),
      );
    }

    // Memory Core drop: 35% on Elite Commander to foster pilot bond progression
    if (isElite && math.Random().nextDouble() < 0.35) {
      game.world.add(
        DropComponent(
          position: position.clone() + Vector2(15, 0),
          type: DropType.memoryCore,
          initialVelocity: Vector2(
            (math.Random().nextDouble() - 0.5) * 40.0,
            (math.Random().nextDouble() - 0.5) * 40.0,
          ),
        ),
      );
    }
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is PlayerComponent) {
      final double dmg;
      switch (type) {
        case EnemyType.scout:
          dmg = 16.0;
          break;
        case EnemyType.raider:
          dmg = 32.0;
          break;
        case EnemyType.sniper:
          dmg = 22.0;
          break;
        case EnemyType.eliteCommander:
          dmg = 45.0;
          break;
        case EnemyType.voidSwarmer:
          dmg = 10.0;
          break;
        case EnemyType.aegisBulwark:
          dmg = 34.0;
          break;
        case EnemyType.carrierHive:
          dmg = 38.0;
          break;
        case EnemyType.gravityWeaver:
          dmg = 24.0;
          break;
        case EnemyType.cryoBomber:
          dmg = 22.0;
          break;
      }
      other.takeHit(dmg);
      // Small bounce/recoil away from player
      final push = (position - other.position).normalized();
      velocity = push * (baseSpeed * 1.5);
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.save();
    canvas.translate(radius, radius);

    // 1. Draw Telegraphed Red Aiming Laser for Raider (straight out of ship's nose)
    if (type == EnemyType.raider && raiderState == RaiderState.telegraphing) {
      final pulse = (math.sin(DateTime.now().millisecondsSinceEpoch / 50.0) + 1) / 2;
      final laserPaint = Paint()
        ..color = const Color(0xFFFF1744).withValues(alpha: 0.45 + pulse * 0.45)
        ..strokeWidth = 1.8 + pulse * 1.2
        ..style = PaintingStyle.stroke;

      // In local coordinates, ship's nose is (0, -radius), facing forward (0, -1)
      canvas.drawLine(Offset(0, -radius), const Offset(0, -650.0), laserPaint);
    }

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
      case EnemyType.voidSwarmer:
        _renderScout(canvas, isFlashing, const Color(0xFFE040FB));
        break;
      case EnemyType.aegisBulwark:
        _renderBulwark(canvas, isFlashing, flashColor);
        break;
      case EnemyType.carrierHive:
        _renderElite(canvas, isFlashing, const Color(0xFF00E676));
        break;
      case EnemyType.gravityWeaver:
        _renderSniper(canvas, isFlashing, const Color(0xFFAA00FF));
        break;
      case EnemyType.cryoBomber:
        _renderSniper(canvas, isFlashing, const Color(0xFF80D8FF));
        break;
    }

    canvas.restore();

    // 2. Floating Health Bar for Elite Commander & Carrier Hive (counter-rotated so it stays horizontal)
    if (type == EnemyType.eliteCommander || type == EnemyType.carrierHive) {
      canvas.save();
      canvas.translate(radius, radius);
      canvas.rotate(-angle);
      _renderHealthBar(canvas);
      canvas.restore();
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

  void _renderBulwark(Canvas canvas, bool isFlashing, Color flashColor) {
    final path = Path()
      ..moveTo(-radius * 0.9, -radius * 0.7)
      ..lineTo(radius * 0.9, -radius * 0.7)
      ..lineTo(radius * 0.7, radius * 0.9)
      ..lineTo(-radius * 0.7, radius * 0.9)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF0A1E2E).withValues(alpha: 0.95)
        ..style = PaintingStyle.fill,
    );
    final strokeColor = isFlashing ? flashColor : const Color(0xFF00E5FF);
    Glow.strokePath(canvas, path, strokeColor, width: 2.2, intensity: 1.3);

    // Glowing Frontal Directional Energy Shield Arc
    final shieldRect = Rect.fromCircle(center: Offset.zero, radius: radius * 1.18);
    canvas.drawArc(
      shieldRect,
      -math.pi * 0.85,
      math.pi * 0.70,
      false,
      Paint()
        ..color = const Color(0xFF00E5FF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5,
    );
  }

  void _renderHealthBar(Canvas canvas) {
    const barWidth = 60.0;
    const barHeight = 6.0;
    final barY = -radius - 14.0;
    const barX = -barWidth / 2;

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
