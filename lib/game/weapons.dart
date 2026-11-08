import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:asteroids/constants.dart';
import 'components/player.dart';
import 'components/bullet.dart';
import 'components/bomb.dart';
import 'components/asteroid.dart';
import 'components/enemy_ship.dart';
import 'components/sector_boss.dart';
import 'components/advanced_weapons.dart';

abstract class Weapon {
  final String id;
  final String name;
  double cooldown;
  double recoil;
  double muzzleFlashSize;
  double damage;
  int level = 1;
  final int maxLevel = 3;
  double currentCooldown = 0.0;

  bool isEvolved = false;
  String? evolvedName;

  bool get canEvolve => level >= maxLevel && !isEvolved;

  Weapon({
    required this.id,
    required this.name,
    required this.cooldown,
    required this.recoil,
    required this.muzzleFlashSize,
    required this.damage,
    this.evolvedName,
  });

  bool fire(PlayerComponent player);

  bool upgrade() {
    if (level >= maxLevel) {
      return false;
    }
    level++;
    applyUpgradeStats();
    return true;
  }

  bool evolve() {
    if (!canEvolve) return false;
    isEvolved = true;
    applyEvolution();
    return true;
  }

  void applyUpgradeStats();
  void applyEvolution();

  static const List<String> allWeaponIds = [
    'blaster',
    'spread_shot',
    'rapid_fire',
    'bomb_launcher',
    'aegis_sawblades',
    'tesla_arc',
    'quantum_chakram',
    'repulsor_aura',
    'solar_lance',
    'inferno_cone',
    'valkyrie_wingmen',
    'void_mines',
  ];

  static Weapon createById(String id) {
    switch (id) {
      case 'blaster':
        return Blaster();
      case 'spread_shot':
        return SpreadShot();
      case 'rapid_fire':
        return RapidFire();
      case 'bomb_launcher':
        return BombLauncher();
      case 'aegis_sawblades':
        return AegisSawblades();
      case 'tesla_arc':
        return TeslaArcCannon();
      case 'quantum_chakram':
        return QuantumChakram();
      case 'repulsor_aura':
        return RepulsorGravityAura();
      case 'solar_lance':
        return SolarThermalLance();
      case 'inferno_cone':
        return InfernoPlasmaCone();
      case 'valkyrie_wingmen':
        return ValkyrieWingmen();
      case 'void_mines':
        return VoidClusterMines();
      default:
        return Blaster();
    }
  }
}

class Blaster extends Weapon {
  Blaster()
      : super(
          id: 'blaster',
          name: "Pulse Blaster",
          evolvedName: "Supernova Annihilator",
          cooldown: 0.70,
          recoil: 12.0,
          muzzleFlashSize: 8.0,
          damage: 60.0,
        );

  @override
  bool fire(PlayerComponent player) {
    final effectiveDamage = damage * player.damageMultiplier;

    // Super-Evolution: Supernova Annihilator (Dual continuous gold plasma beams with infinite pierce)
    if (isEvolved) {
      final right = Vector2(-player.forward.y, player.forward.x);
      for (final offset in [-8.0, 8.0]) {
        final spawnPos = player.position + player.forward * player.radius + right * offset;
        final bullet = BulletComponent(
          position: spawnPos,
          radius: 5.5,
          velocity: player.forward * (GameConstants.playerShootSpeed + 120.0),
          lifeTimer: GameConstants.shotLifetimeSeconds * 1.3,
          damage: effectiveDamage,
          color: const Color(0xFFFFD700), // Imperial Gold
          piercesLeft: 99,
        );
        player.game.world.add(bullet);
      }
      return true;
    }

    if (level >= 3) {
      // Level 3: Dual parallel high-density plasma bolts
      final right = Vector2(-player.forward.y, player.forward.x);
      for (final offset in [-6.0, 6.0]) {
        final spawnPos = player.position + player.forward * player.radius + right * offset;
        final bullet = BulletComponent(
          position: spawnPos,
          radius: GameConstants.shotRadius,
          velocity: player.forward * (GameConstants.playerShootSpeed + 40.0),
          lifeTimer: GameConstants.shotLifetimeSeconds,
          damage: effectiveDamage,
          piercesLeft: player.pierceCount,
        );
        player.game.world.add(bullet);
      }
      return true;
    }

    final velocity = player.forward * (GameConstants.playerShootSpeed + (level == 2 ? 30.0 : 0.0));
    final bullet = BulletComponent(
      position: player.position + player.forward * player.radius,
      radius: GameConstants.shotRadius + (level == 2 ? 1.0 : 0.0),
      velocity: velocity,
      lifeTimer: GameConstants.shotLifetimeSeconds,
      damage: effectiveDamage,
      piercesLeft: player.pierceCount,
    );
    player.game.world.add(bullet);
    return true;
  }

  @override
  void applyUpgradeStats() {
    if (level == 2) {
      cooldown = 0.50;
      recoil = 8.0;
      damage = 75.0;
      muzzleFlashSize = 10.0;
    } else if (level >= 3) {
      cooldown = 0.35;
      recoil = 5.0;
      damage = 100.0;
      muzzleFlashSize = 12.0;
    }
  }

  @override
  void applyEvolution() {
    cooldown = 0.16;
    recoil = 2.0;
    damage = 150.0;
    muzzleFlashSize = 16.0;
  }
}

class SpreadShot extends Weapon {
  SpreadShot()
      : super(
          id: 'spread_shot',
          name: "Spread Cannon",
          evolvedName: "Hyperion Flak Storm",
          cooldown: 0.95,
          recoil: 14.0,
          muzzleFlashSize: 11.0,
          damage: 32.0,
        );

  @override
  bool fire(PlayerComponent player) {
    final effectiveDamage = damage * player.damageMultiplier;

    // Super-Evolution: Hyperion Flak Storm (10-way 360-degree perimeter flak ring)
    if (isEvolved) {
      const int flakCount = 10;
      const double speed = GameConstants.playerShootSpeed * 1.15;
      for (var i = 0; i < flakCount; i++) {
        final angleRad = (i * 2 * math.pi / flakCount);
        final direction = Vector2(math.cos(angleRad), math.sin(angleRad));
        final spawnPos = player.position + direction * player.radius;

        final bullet = BulletComponent(
          position: spawnPos,
          radius: 4.8,
          velocity: direction * speed,
          lifeTimer: 0.85,
          damage: effectiveDamage,
          color: const Color(0xFFFF5252), // Flak Red
          piercesLeft: 2,
        );
        player.game.world.add(bullet);
      }
      return true;
    }

    // Level 3 fires a 5-way spread; Levels 1 and 2 fire 3-way
    final List<double> angles = level >= 3
        ? [-24.0, -12.0, 0.0, 12.0, 24.0]
        : [-14.0, 0.0, 14.0];

    final speedMultiplier = 1.0 + (level - 1) * 0.12;
    final baseSpeed = GameConstants.playerShootSpeed * 0.95 * speedMultiplier;
    final lifeTime = 0.75 + (level - 1) * 0.06;

    for (final angleDeg in angles) {
      final angleRad = angleDeg * math.pi / 180.0;
      final shootAngle = player.angle + angleRad;
      
      final direction = Vector2(
        math.cos(shootAngle - math.pi / 2),
        math.sin(shootAngle - math.pi / 2),
      );

      final bullet = BulletComponent(
        position: player.position + player.forward * player.radius,
        radius: 3.5 + (level >= 3 ? 0.8 : 0.0),
        velocity: direction * baseSpeed,
        lifeTimer: lifeTime,
        damage: effectiveDamage,
        piercesLeft: player.pierceCount,
      );
      player.game.world.add(bullet);
    }
    return true;
  }

  @override
  void applyUpgradeStats() {
    if (level == 2) {
      cooldown = 0.72;
      recoil = 10.0;
      damage = 42.0;
      muzzleFlashSize = 13.0;
    } else if (level >= 3) {
      cooldown = 0.52;
      recoil = 6.0;
      damage = 55.0;
      muzzleFlashSize = 15.0;
    }
  }

  @override
  void applyEvolution() {
    cooldown = 0.38;
    recoil = 3.0;
    damage = 75.0;
    muzzleFlashSize = 18.0;
  }
}

class RapidFire extends Weapon {
  RapidFire()
      : super(
          id: 'rapid_fire',
          name: "Phase Laser",
          evolvedName: "Absolute Zero Tachyon Beam",
          cooldown: 0.32,
          recoil: 4.0,
          muzzleFlashSize: 6.0,
          damage: 20.0,
        );

  @override
  bool fire(PlayerComponent player) {
    final effectiveDamage = damage * player.damageMultiplier;

    // Super-Evolution: Absolute Zero Tachyon Beam (Hyper-dense piercing glacial stream)
    if (isEvolved) {
      final velocity = player.forward * (GameConstants.playerShootSpeed + 140.0);
      final bullet = BulletComponent(
        position: player.position + player.forward * player.radius,
        radius: 4.5,
        velocity: velocity,
        lifeTimer: 1.1,
        damage: effectiveDamage,
        color: const Color(0xFF80D8FF), // Glacial Neon Ice Blue
        piercesLeft: 99,
      );
      player.game.world.add(bullet);
      return true;
    }

    final velocity = player.forward * (GameConstants.playerShootSpeed + 50.0);
    final bullet = BulletComponent(
      position: player.position + player.forward * player.radius,
      radius: 3.2 + (level >= 3 ? 0.8 : 0.0),
      velocity: velocity,
      lifeTimer: 0.88,
      damage: effectiveDamage,
      piercesLeft: player.pierceCount,
    );
    player.game.world.add(bullet);
    return true;
  }

  @override
  void applyUpgradeStats() {
    if (level == 2) {
      cooldown = 0.22;
      recoil = 2.5;
      damage = 26.0;
      muzzleFlashSize = 8.0;
    } else if (level >= 3) {
      cooldown = 0.14;
      recoil = 1.5;
      damage = 34.0;
      muzzleFlashSize = 9.0;
    }
  }

  @override
  void applyEvolution() {
    cooldown = 0.075;
    recoil = 0.8;
    damage = 50.0;
    muzzleFlashSize = 12.0;
  }
}

class BombLauncher extends Weapon {
  BombLauncher()
      : super(
          id: 'bomb_launcher',
          name: "Antimatter Torpedo",
          evolvedName: "Singularity Rift Torpedo",
          cooldown: 1.80,
          recoil: 22.0,
          muzzleFlashSize: 18.0,
          damage: 180.0,
        );

  @override
  bool fire(PlayerComponent player) {
    final effectiveDamage = damage * player.damageMultiplier;
    final speed = (isEvolved ? 340.0 : 280.0) + (level - 1) * 40.0;

    // Smart torpedo targeting: seeks the nearest enemy ship or asteroid within 550px
    Vector2 fireDir = player.forward;
    PositionComponent? closestTarget;
    double closestDistSq = double.infinity;

    final enemies = player.game.world.children.whereType<EnemyShipComponent>();
    for (final e in enemies) {
      final dSq = player.position.distanceToSquared(e.position);
      if (dSq < closestDistSq) {
        closestDistSq = dSq;
        closestTarget = e;
      }
    }

    if (closestTarget == null || closestDistSq > 400.0 * 400.0) {
      final asteroids = player.game.world.children.whereType<AsteroidComponent>();
      for (final ast in asteroids) {
        final dSq = player.position.distanceToSquared(ast.position);
        if (dSq < closestDistSq) {
          closestDistSq = dSq;
          closestTarget = ast;
        }
      }
    }

    if (closestTarget != null && closestDistSq <= 550.0 * 550.0) {
      final toTarget = closestTarget.position - player.position;
      if (toTarget.length2 > 0.01) {
        fireDir = toTarget.normalized();
      }
    }

    final velocity = fireDir * speed;
    final explosionRadius = (isEvolved ? 150.0 : 95.0) + (level - 1) * 20.0;

    final bomb = BombComponent(
      position: player.position + fireDir * player.radius,
      velocity: velocity,
      damage: effectiveDamage,
      explosionRadius: explosionRadius,
      isSingularity: isEvolved,
    );
    player.game.world.add(bomb);
    return true;
  }

  @override
  void applyUpgradeStats() {
    if (level == 2) {
      cooldown = 1.40;
      recoil = 16.0;
      damage = 240.0;
      muzzleFlashSize = 22.0;
    } else if (level >= 3) {
      cooldown = 1.00;
      recoil = 10.0;
      damage = 320.0;
      muzzleFlashSize = 26.0;
    }
  }

  @override
  void applyEvolution() {
    cooldown = 0.85;
    recoil = 8.0;
    damage = 420.0;
    muzzleFlashSize = 28.0;
  }
}

/// 5. Aegis Sawblades -> Celestial Buzzsaw Ring (Orbitais estilo King Bible)
class AegisSawblades extends Weapon {
  AegisSawblades()
      : super(
          id: 'aegis_sawblades',
          name: 'Aegis Sawblades',
          evolvedName: 'Celestial Buzzsaw Ring',
          cooldown: 3.8,
          recoil: 0.0,
          muzzleFlashSize: 4.0,
          damage: 45.0,
        );

  @override
  bool fire(PlayerComponent player) {
    final effectiveDamage = damage * player.damageMultiplier;
    final bladeCount = isEvolved ? 6 : (level + 1); // 2, 3, 4 -> 6 blades
    final orbitRadius = isEvolved ? 115.0 : 88.0;

    // Remove lâminas anteriores para renovar o anel orbital
    final existing = player.game.world.children.whereType<OrbitalSawbladeComponent>().toList();
    for (final b in existing) {
      b.removeFromParent();
    }

    for (var i = 0; i < bladeCount; i++) {
      player.game.world.add(
        OrbitalSawbladeComponent(
          bladeIndex: i,
          totalBlades: bladeCount,
          orbitRadius: orbitRadius,
          damagePerHit: effectiveDamage,
          isEvolved: isEvolved,
          lifeTimer: isEvolved ? 5.5 : 3.6,
        ),
      );
    }
    return true;
  }

  @override
  void applyUpgradeStats() {
    if (level == 2) {
      cooldown = 3.2;
      damage = 62.0;
    } else if (level >= 3) {
      cooldown = 2.6;
      damage = 85.0;
    }
  }

  @override
  void applyEvolution() {
    cooldown = 2.0;
    damage = 135.0;
  }
}

/// 6. Tesla Arc Cannon -> Mjolnir Storm Conduit (Corrente Elétrica em Cadeia)
class TeslaArcCannon extends Weapon {
  TeslaArcCannon()
      : super(
          id: 'tesla_arc',
          name: 'Tesla Arc Cannon',
          evolvedName: 'Mjolnir Storm Conduit',
          cooldown: 0.90,
          recoil: 3.0,
          muzzleFlashSize: 10.0,
          damage: 52.0,
        );

  @override
  bool fire(PlayerComponent player) {
    final effectiveDamage = damage * player.damageMultiplier;
    final maxJumps = isEvolved ? 8 : (2 + level); // 3, 4, 5 -> 8 jumps
    final jumpRange = isEvolved ? 380.0 : 260.0;

    final chainPoints = <Vector2>[player.position.clone()];
    final hitTargets = <PositionComponent>{};
    Vector2 currentOrigin = player.position.clone();

    for (var j = 0; j < maxJumps; j++) {
      PositionComponent? bestTarget;
      double bestDist = jumpRange;

      for (final e in player.game.world.children.whereType<EnemyShipComponent>()) {
        if (hitTargets.contains(e)) continue;
        final d = e.position.distanceTo(currentOrigin);
        if (d < bestDist) {
          bestDist = d;
          bestTarget = e;
        }
      }
      if (bestTarget == null) {
        final boss = player.game.activeBoss;
        if (boss != null && !boss.isDefeated && !hitTargets.contains(boss)) {
          if (boss.position.distanceTo(currentOrigin) <= jumpRange + boss.radius) {
            bestTarget = boss;
          }
        }
      }
      if (bestTarget == null) {
        for (final a in player.game.world.children.whereType<AsteroidComponent>()) {
          if (hitTargets.contains(a)) continue;
          final d = a.position.distanceTo(currentOrigin);
          if (d < bestDist) {
            bestDist = d;
            bestTarget = a;
          }
        }
      }

      if (bestTarget == null) break;
      hitTargets.add(bestTarget);
      chainPoints.add(bestTarget.position.clone());
      currentOrigin = bestTarget.position.clone();

      if (bestTarget is EnemyShipComponent) {
        bestTarget.applyElementalStatus(ElementalStatus.ionShock, duration: 4.0);
        bestTarget.takeDamage(effectiveDamage, bestTarget.position);
      } else if (bestTarget is SectorBoss) {
        bestTarget.applyElementalStatus(ElementalStatus.ionShock, duration: 4.0);
        bestTarget.takeDamage(effectiveDamage, bestTarget.position);
      } else if (bestTarget is AsteroidComponent) {
        if (bestTarget.takeDamage(effectiveDamage, bestTarget.position)) {
          player.game.onAsteroidDestroyed(bestTarget.position, bestTarget.scoreValue);
        }
      }
    }

    if (chainPoints.length == 1) {
      // Disparo visual frontal caso não haja alvo próximo
      chainPoints.add(player.position + player.forward * 210.0);
    }

    player.game.world.add(
      TeslaLightningComponent(
        chainPoints: chainPoints,
        arcColor: isEvolved ? const Color(0xFFFFD700) : const Color(0xFF80D8FF),
      ),
    );
    return true;
  }

  @override
  void applyUpgradeStats() {
    if (level == 2) {
      cooldown = 0.72;
      damage = 68.0;
    } else if (level >= 3) {
      cooldown = 0.56;
      damage = 90.0;
    }
  }

  @override
  void applyEvolution() {
    cooldown = 0.36;
    damage = 140.0;
  }
}

/// 7. Quantum Chakram -> Chronos Eclipse Glaive (Bumerangue Espacial)
class QuantumChakram extends Weapon {
  QuantumChakram()
      : super(
          id: 'quantum_chakram',
          name: 'Quantum Chakram',
          evolvedName: 'Chronos Eclipse Glaive',
          cooldown: 1.15,
          recoil: 4.0,
          muzzleFlashSize: 8.0,
          damage: 65.0,
        );

  @override
  bool fire(PlayerComponent player) {
    final effectiveDamage = damage * player.damageMultiplier;
    final count = isEvolved ? 3 : (level >= 3 ? 2 : 1);

    for (var i = 0; i < count; i++) {
      final spreadAngle = count == 1 ? 0.0 : (i - (count - 1) / 2.0) * 0.28;
      final a = player.angle + spreadAngle - math.pi / 2;
      final dir = Vector2(math.cos(a), math.sin(a));

      player.game.world.add(
        ChakramProjectileComponent(
          position: player.position + dir * player.radius,
          velocity: dir * (isEvolved ? 520.0 : 430.0),
          baseDamage: effectiveDamage,
          isEvolved: isEvolved,
        ),
      );
    }
    return true;
  }

  @override
  void applyUpgradeStats() {
    if (level == 2) {
      cooldown = 0.92;
      damage = 85.0;
    } else if (level >= 3) {
      cooldown = 0.75;
      damage = 110.0;
    }
  }

  @override
  void applyEvolution() {
    cooldown = 0.52;
    damage = 155.0;
  }
}

/// 8. Repulsor Gravity Aura -> Event Horizon Nova Pulse (Pulso 360° estilo Garlic)
class RepulsorGravityAura extends Weapon {
  RepulsorGravityAura()
      : super(
          id: 'repulsor_aura',
          name: 'Repulsor Gravity Aura',
          evolvedName: 'Event Horizon Nova Pulse',
          cooldown: 1.35,
          recoil: 0.0,
          muzzleFlashSize: 6.0,
          damage: 48.0,
        );

  @override
  bool fire(PlayerComponent player) {
    final effectiveDamage = damage * player.damageMultiplier;
    final radius = (isEvolved ? 235.0 : 145.0) + (level - 1) * 22.0;

    player.game.world.add(
      GravityAuraPulseComponent(
        position: player.position,
        maxRadius: radius,
        damage: effectiveDamage,
        isEvolved: isEvolved,
      ),
    );
    return true;
  }

  @override
  void applyUpgradeStats() {
    if (level == 2) {
      cooldown = 1.10;
      damage = 65.0;
    } else if (level >= 3) {
      cooldown = 0.88;
      damage = 88.0;
    }
  }

  @override
  void applyEvolution() {
    cooldown = 0.62;
    damage = 135.0;
  }
}

/// 9. Solar Thermal Lance -> Helios Core Melter (Feixe Contínuo de Fusão Solar)
class SolarThermalLance extends Weapon {
  SolarThermalLance()
      : super(
          id: 'solar_lance',
          name: 'Solar Thermal Lance',
          evolvedName: 'Helios Core Melter',
          cooldown: 0.65,
          recoil: 6.0,
          muzzleFlashSize: 14.0,
          damage: 78.0,
        );

  @override
  bool fire(PlayerComponent player) {
    final effectiveDamage = damage * player.damageMultiplier;
    final beamLen = isEvolved ? 680.0 : (460.0 + (level - 1) * 60.0);
    final start = player.position + player.forward * player.radius;
    final end = start + player.forward * beamLen;
    final beamWidth = isEvolved ? 28.0 : 18.0;

    player.game.world.add(
      ThermalLanceBeamComponent(
        startPos: start,
        endPos: end,
        isEvolved: isEvolved,
      ),
    );

    // Colisão linear ao longo do feixe térmico
    for (final e in List<EnemyShipComponent>.from(player.game.world.children.whereType<EnemyShipComponent>())) {
      if (_distancePointToSegment(e.position, start, end) <= e.radius + beamWidth) {
        e.applyElementalStatus(ElementalStatus.solarBurn, duration: 4.5);
        e.takeDamage(effectiveDamage, e.position);
      }
    }
    for (final a in List<AsteroidComponent>.from(player.game.world.children.whereType<AsteroidComponent>())) {
      if (_distancePointToSegment(a.position, start, end) <= a.radius + beamWidth) {
        if (a.takeDamage(effectiveDamage, a.position)) {
          player.game.onAsteroidDestroyed(a.position, a.scoreValue);
        }
      }
    }
    final boss = player.game.activeBoss;
    if (boss != null && !boss.isDefeated) {
      if (_distancePointToSegment(boss.position, start, end) <= boss.radius + beamWidth) {
        boss.applyElementalStatus(ElementalStatus.solarBurn, duration: 4.5);
        boss.takeDamage(effectiveDamage, boss.position);
      }
    }
    return true;
  }

  static double _distancePointToSegment(Vector2 p, Vector2 a, Vector2 b) {
    final ab = b - a;
    final lenSq = ab.length2;
    if (lenSq <= 0.0001) return p.distanceTo(a);
    final t = ((p - a).dot(ab) / lenSq).clamp(0.0, 1.0);
    final proj = a + ab * t;
    return p.distanceTo(proj);
  }

  @override
  void applyUpgradeStats() {
    if (level == 2) {
      cooldown = 0.50;
      damage = 105.0;
    } else if (level >= 3) {
      cooldown = 0.38;
      damage = 135.0;
    }
  }

  @override
  void applyEvolution() {
    cooldown = 0.24;
    damage = 195.0;
  }
}

/// 10. Inferno Plasma Cone -> Phoenix Dragon Breath (Lança-Chamas Espacial)
class InfernoPlasmaCone extends Weapon {
  InfernoPlasmaCone()
      : super(
          id: 'inferno_cone',
          name: 'Inferno Plasma Cone',
          evolvedName: 'Phoenix Dragon Breath',
          cooldown: 0.28,
          recoil: 2.0,
          muzzleFlashSize: 12.0,
          damage: 24.0,
        );

  @override
  bool fire(PlayerComponent player) {
    final effectiveDamage = damage * player.damageMultiplier;
    final count = isEvolved ? 5 : 3;
    for (var i = 0; i < count; i++) {
      final offsetAngle = (i - (count - 1) / 2.0) * 0.18;
      final a = player.angle + offsetAngle - math.pi / 2;
      final dir = Vector2(math.cos(a), math.sin(a));

      player.game.world.add(
        BulletComponent(
          position: player.position + dir * player.radius,
          radius: isEvolved ? 7.0 : 5.2,
          velocity: dir * (isEvolved ? 420.0 : 340.0),
          lifeTimer: isEvolved ? 0.55 : 0.40,
          damage: effectiveDamage,
          color: const Color(0xFFFF6D00),
          piercesLeft: isEvolved ? 4 : 2,
          elementalStatus: ElementalStatus.solarBurn,
        ),
      );
    }
    return true;
  }

  @override
  void applyUpgradeStats() {
    if (level == 2) {
      cooldown = 0.22;
      damage = 32.0;
    } else if (level >= 3) {
      cooldown = 0.16;
      damage = 44.0;
    }
  }

  @override
  void applyEvolution() {
    cooldown = 0.11;
    damage = 68.0;
  }
}

/// 11. Valkyrie Wingmen -> Seraphim Drone Squadron (Drones Aliados Caçadores)
class ValkyrieWingmen extends Weapon {
  ValkyrieWingmen()
      : super(
          id: 'valkyrie_wingmen',
          name: 'Valkyrie Wingmen',
          evolvedName: 'Seraphim Drone Squadron',
          cooldown: 4.5,
          recoil: 0.0,
          muzzleFlashSize: 4.0,
          damage: 34.0,
        );

  @override
  bool fire(PlayerComponent player) {
    final effectiveDamage = damage * player.damageMultiplier;
    final droneCount = isEvolved ? 4 : (level >= 3 ? 3 : 2);

    final existing = player.game.world.children.whereType<WingmanDroneComponent>().toList();
    for (final d in existing) {
      d.removeFromParent();
    }

    for (var i = 0; i < droneCount; i++) {
      player.game.world.add(
        WingmanDroneComponent(
          droneIndex: i,
          damage: effectiveDamage,
          isEvolved: isEvolved,
        ),
      );
    }
    return true;
  }

  @override
  void applyUpgradeStats() {
    if (level == 2) {
      cooldown = 4.0;
      damage = 46.0;
    } else if (level >= 3) {
      cooldown = 3.5;
      damage = 60.0;
    }
  }

  @override
  void applyEvolution() {
    cooldown = 3.0;
    damage = 88.0;
  }
}

/// 12. Void Cluster Mines -> Abyssal Minefield Matrix (Minas Traseiras de Kiting)
class VoidClusterMines extends Weapon {
  VoidClusterMines()
      : super(
          id: 'void_mines',
          name: 'Void Cluster Mines',
          evolvedName: 'Abyssal Minefield Matrix',
          cooldown: 1.40,
          recoil: 0.0,
          muzzleFlashSize: 5.0,
          damage: 115.0,
        );

  @override
  bool fire(PlayerComponent player) {
    final effectiveDamage = damage * player.damageMultiplier;
    final backward = -player.forward;
    final right = Vector2(-player.forward.y, player.forward.x);
    final count = isEvolved ? 3 : (level >= 3 ? 2 : 1);

    for (var i = 0; i < count; i++) {
      final sideOffset = count == 1 ? 0.0 : (i - (count - 1) / 2.0) * 28.0;
      final dropPos = player.position + backward * (player.radius + 18.0) + right * sideOffset;
      player.game.world.add(
        PlayerClusterMineComponent(
          position: dropPos,
          damage: effectiveDamage,
          blastRadius: isEvolved ? 155.0 : 110.0,
          isEvolved: isEvolved,
        ),
      );
    }
    return true;
  }

  @override
  void applyUpgradeStats() {
    if (level == 2) {
      cooldown = 1.15;
      damage = 150.0;
    } else if (level >= 3) {
      cooldown = 0.92;
      damage = 195.0;
    }
  }

  @override
  void applyEvolution() {
    cooldown = 0.68;
    damage = 275.0;
  }
}
