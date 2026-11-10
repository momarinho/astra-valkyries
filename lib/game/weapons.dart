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
import 'components/katana_slash.dart';
import '../services/achievement_service.dart';

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
  double totalDamageDealt = 0.0;
  int totalKills = 0;

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
    AchievementService.unlock('transcendence');
    return true;
  }

  void applyUpgradeStats();
  void applyEvolution();

  /// Ficha de História / Origem Diegética (Sprint 22 — Lore Log estilo Dark Souls / Hades)
  String get loreLog => getWeaponLore(id);

  static String getWeaponLore(String id) {
    switch (id) {
      case 'blaster':
        return 'O armamento padrão da Esquadrilha Valquíria durante o Cerco de Vesta. '
            'Forjado com bobinas de deutério pressurizado, foi a única arma que continuou disparando '
            'quando a Primeira Frota perdeu contato com a Terra.';
      case 'spread_shot':
        return 'Desenvolvido nos estaleiros orbitais de Hélio para varrer nuvens de estilhaços. '
            'Seus canos divergentes dispersam energia cinética capaz de conter enxames inteiros no escuro.';
      case 'rapid_fire':
        return 'Um emissor experimental de táquions que resfria o próprio cano usando o zero absoluto do vácuo. '
            'Dizem que os pilotos que abusam de sua cadência ouvem ecos do próprio futuro no rádio.';
      case 'bomb_launcher':
        return 'Protótipo banido pelo Tratado de Titã de 2184. Cada ogiva comprime matéria escura até '
            'rasgar uma micro-fenda no espaço-tempo, devorando blindagens e a luz ao redor.';
      case 'aegis_sawblades':
        return 'Originalmente escudos rotativos de mineração criados para triturar asteroides de tungstênio em Calisto. '
            'Quando a Frota Corrompida atacou, as mineradoras descobriram que cascos inimigos rasgavam igual rocha.';
      case 'tesla_arc':
        return 'Bobina recuperada dos destroços do Encouraçado Soberano "Aegis-IV". '
            'Dispara arcos voltaicos inteligentes que buscam o núcleo energético mais próximo em cadeia.';
      case 'quantum_chakram':
        return 'Arma cerimonial da Ordem de Caelum. O disco dobra a geometria gravitacional local para '
            'retornar sempre à nave que o lançou, cortando duas vezes na mesma batida de coração.';
      case 'repulsor_aura':
        return 'Gerador de pulso harmônico instalado ao redor do reator central da Valquíria. '
            'Converte o desespero do cerco em ondas de choque gravitacionais de 360 graus.';
      case 'solar_lance':
        return 'Canalizador direto de plasma coronal extraído da Forja de Órion. '
            'Seu feixe contínuo atinge temperaturas estelares que fundem escudos frontais em segundos.';
      case 'inferno_cone':
        return 'Propulsor secundário modificado por Lyra Vance após ficar sem munição no Cinturão Exterior. '
            'Transforma combustível estelar bruto em uma tempestade incandescente de curta distância.';
      case 'valkyrie_wingmen':
        return 'Drones autônomos contendo fragmentos das matrizes de IA de pilotos caídas em missões passadas. '
            'Mesmo após a morte de suas naves originais, elas se recusam a deixar uma irmã voar sozinha.';
      case 'void_mines':
        return 'Minas magnéticas de contenção usadas por caçadoras furtivas. '
            'Flutuam silenciosamente no rastro da nave, aguardando perseguidores gananciosos demais.';
      case 'tachyon_katana':
        return 'Forjada nos estaleiros orbitais de Kyoto-7. Esta lâmina condensa táquions em uma fita de plasma '
            'de espessura atômica. Dizem que seu corte rasga a geometria do vácuo antes mesmo do dedo tocar o gatilho.';
      default:
        return 'Relíquia bélica registrada nos arquivos confidenciais do Protocolo Void.';
    }
  }

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
    'tachyon_katana',
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
      case 'tachyon_katana':
        return TachyonKatana();
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
          damage: 26.0,
        );

  @override
  bool fire(PlayerComponent player) {
    final surgeMult = player.bloodOverdriveTimer > 0 ? 2.0 : 1.0;
    final effectiveDamage = damage * player.damageMultiplier * surgeMult;

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
          weaponSource: this,
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
          damage: effectiveDamage * 0.60,
          piercesLeft: player.pierceCount,
          weaponSource: this,
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
      weaponSource: this,
    );
    player.game.world.add(bullet);
    return true;
  }

  @override
  void applyUpgradeStats() {
    if (level == 2) {
      cooldown = 0.52;
      recoil = 8.0;
      damage = 42.0;
      muzzleFlashSize = 10.0;
    } else if (level >= 3) {
      cooldown = 0.42;
      recoil = 5.0;
      damage = 60.0;
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
          damage: 14.0,
        );

  @override
  bool fire(PlayerComponent player) {
    final surgeMult = player.bloodOverdriveTimer > 0 ? 2.0 : 1.0;
    final effectiveDamage = damage * player.damageMultiplier * surgeMult;

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
          damage: effectiveDamage * 0.55,
          color: const Color(0xFFFF5252), // Flak Red
          piercesLeft: 2,
          weaponSource: this,
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
    final pelletDamage = level >= 3 ? effectiveDamage * 0.60 : effectiveDamage;

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
        damage: pelletDamage,
        piercesLeft: player.pierceCount,
        weaponSource: this,
      );
      player.game.world.add(bullet);
    }
    return true;
  }

  @override
  void applyUpgradeStats() {
    if (level == 2) {
      cooldown = 0.75;
      recoil = 10.0;
      damage = 22.0;
      muzzleFlashSize = 13.0;
    } else if (level >= 3) {
      cooldown = 0.62;
      recoil = 6.0;
      damage = 32.0;
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
          damage: 10.0,
        );

  @override
  bool fire(PlayerComponent player) {
    final surgeMult = player.bloodOverdriveTimer > 0 ? 2.0 : 1.0;
    final effectiveDamage = damage * player.damageMultiplier * surgeMult;

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
        weaponSource: this,
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
      weaponSource: this,
    );
    player.game.world.add(bullet);
    return true;
  }

  @override
  void applyUpgradeStats() {
    if (level == 2) {
      cooldown = 0.22;
      recoil = 2.5;
      damage = 16.0;
      muzzleFlashSize = 8.0;
    } else if (level >= 3) {
      cooldown = 0.18;
      recoil = 1.8;
      damage = 22.0;
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
          damage: 80.0,
        );

  @override
  bool fire(PlayerComponent player) {
    final surgeMult = player.bloodOverdriveTimer > 0 ? 2.0 : 1.0;
    final effectiveDamage = damage * player.damageMultiplier * surgeMult;
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
    final explosionRadius = (isEvolved ? 140.0 : 95.0) + (level - 1) * 15.0;

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
      cooldown = 1.45;
      recoil = 16.0;
      damage = 130.0;
      muzzleFlashSize = 22.0;
    } else if (level >= 3) {
      cooldown = 1.20;
      recoil = 12.0;
      damage = 190.0;
      muzzleFlashSize = 25.0;
    }
  }

  @override
  void applyEvolution() {
    cooldown = 0.95;
    recoil = 8.0;
    damage = 340.0;
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
          damage: 16.0,
        );

  @override
  bool fire(PlayerComponent player) {
    final surgeMult = player.bloodOverdriveTimer > 0 ? 2.0 : 1.0;
    final effectiveDamage = damage * player.damageMultiplier * surgeMult;
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
      damage = 24.0;
    } else if (level >= 3) {
      cooldown = 2.8;
      damage = 35.0;
    }
  }

  @override
  void applyEvolution() {
    cooldown = 2.2;
    damage = 55.0;
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
          damage: 20.0,
        );

  @override
  bool fire(PlayerComponent player) {
    final surgeMult = player.bloodOverdriveTimer > 0 ? 2.0 : 1.0;
    final effectiveDamage = damage * player.damageMultiplier * surgeMult;
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
      cooldown = 0.75;
      damage = 30.0;
    } else if (level >= 3) {
      cooldown = 0.62;
      damage = 42.0;
    }
  }

  @override
  void applyEvolution() {
    cooldown = 0.48;
    damage = 65.0;
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
          damage: 24.0,
        );

  @override
  bool fire(PlayerComponent player) {
    final surgeMult = player.bloodOverdriveTimer > 0 ? 2.0 : 1.0;
    final effectiveDamage = damage * player.damageMultiplier * surgeMult;
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
      cooldown = 1.05;
      damage = 34.0;
    } else if (level >= 3) {
      cooldown = 0.95;
      damage = 28.0;
    }
  }

  @override
  void applyEvolution() {
    cooldown = 0.85;
    damage = 40.0;
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
          damage: 18.0,
        );

  @override
  bool fire(PlayerComponent player) {
    final surgeMult = player.bloodOverdriveTimer > 0 ? 2.0 : 1.0;
    final effectiveDamage = damage * player.damageMultiplier * surgeMult;
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
      cooldown = 1.20;
      damage = 26.0;
    } else if (level >= 3) {
      cooldown = 1.05;
      damage = 36.0;
    }
  }

  @override
  void applyEvolution() {
    cooldown = 0.90;
    damage = 55.0;
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
          damage: 28.0,
        );

  @override
  bool fire(PlayerComponent player) {
    final surgeMult = player.bloodOverdriveTimer > 0 ? 2.0 : 1.0;
    final effectiveDamage = damage * player.damageMultiplier * surgeMult;
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
      cooldown = 0.58;
      damage = 44.0;
    } else if (level >= 3) {
      cooldown = 0.46;
      damage = 62.0;
    }
  }

  @override
  void applyEvolution() {
    cooldown = 0.35;
    damage = 95.0;
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
          damage: 9.0,
        );

  @override
  bool fire(PlayerComponent player) {
    final surgeMult = player.bloodOverdriveTimer > 0 ? 2.0 : 1.0;
    final effectiveDamage = damage * player.damageMultiplier * surgeMult;
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
      cooldown = 0.24;
      damage = 13.0;
    } else if (level >= 3) {
      cooldown = 0.20;
      damage = 17.0;
    }
  }

  @override
  void applyEvolution() {
    cooldown = 0.16;
    damage = 25.0;
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
          damage: 12.0,
        );

  @override
  bool fire(PlayerComponent player) {
    final surgeMult = player.bloodOverdriveTimer > 0 ? 2.0 : 1.0;
    final effectiveDamage = damage * player.damageMultiplier * surgeMult;
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
      damage = 18.0;
    } else if (level >= 3) {
      cooldown = 3.6;
      damage = 25.0;
    }
  }

  @override
  void applyEvolution() {
    cooldown = 3.0;
    damage = 40.0;
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
          damage: 45.0,
        );

  @override
  bool fire(PlayerComponent player) {
    final surgeMult = player.bloodOverdriveTimer > 0 ? 2.0 : 1.0;
    final effectiveDamage = damage * player.damageMultiplier * surgeMult;
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
      cooldown = 1.20;
      damage = 70.0;
    } else if (level >= 3) {
      cooldown = 1.05;
      damage = 65.0;
    }
  }

  @override
  void applyEvolution() {
    cooldown = 0.85;
    damage = 95.0;
  }
}

/// 13. Tachyon Katana -> Void Muramasa (Lâminas de Corte Dimensional de Alta Velocidade)
class TachyonKatana extends Weapon {
  TachyonKatana()
      : super(
          id: 'tachyon_katana',
          name: 'Tachyon Katana',
          evolvedName: 'Void Muramasa',
          cooldown: 0.60,
          recoil: 2.0,
          muzzleFlashSize: 6.0,
          damage: 14.0, // Calibrado: dano inicial moderado e justo
        );

  @override
  bool fire(PlayerComponent player) {
    player.customGame?.playSfx('katana_slash.wav');
    AchievementService.unlock('blade_master');
    final surgeMult = player.bloodOverdriveTimer > 0 ? 2.0 : 1.0;
    final effectiveDamage = damage * player.damageMultiplier * surgeMult;

    // Super-Evolution: Void Muramasa (Três cortes transcendentais com alcance e área calibrados)
    if (isEvolved) {
      final angles = [-12.0, 0.0, 12.0];
      for (final angleDeg in angles) {
        final angleRad = angleDeg * math.pi / 180.0;
        final shootAngle = player.angle + angleRad;
        final dir = Vector2(math.cos(shootAngle - math.pi / 2), math.sin(shootAngle - math.pi / 2));
        final slash = KatanaSlashComponent(
          position: player.position + dir * (player.radius + 10.0),
          angle: shootAngle,
          velocity: dir * 450.0,
          lifeTimer: 0.44, // Alcance calibrado ~195px
          damage: effectiveDamage * 1.25,
          slashWidth: 52.0,
          slashHeight: 16.0,
          slashColor: const Color(0xFFE040FB), // Void Muramasa Violet
          coreColor: const Color(0xFF00E5FF),  // Tachyon Core Cyan
          piercesLeft: 6,
          isVoidMuramasa: true,
          weaponSource: this,
        );
        player.game.world.add(slash);
      }
      return true;
    }

    if (level >= 3) {
      // 3 sweeping crescent blades em cone compacto
      final angles = [-11.0, 0.0, 11.0];
      for (final angleDeg in angles) {
        final angleRad = angleDeg * math.pi / 180.0;
        final shootAngle = player.angle + angleRad;
        final dir = Vector2(math.cos(shootAngle - math.pi / 2), math.sin(shootAngle - math.pi / 2));
        final slash = KatanaSlashComponent(
          position: player.position + dir * (player.radius + 8.0),
          angle: shootAngle,
          velocity: dir * 400.0,
          lifeTimer: 0.38, // Alcance ~150px
          damage: effectiveDamage,
          slashWidth: 38.0,
          slashHeight: 14.0,
          slashColor: const Color(0xFF00E5FF),
          piercesLeft: 3,
          weaponSource: this,
        );
        player.game.world.add(slash);
      }
      return true;
    }

    if (level == 2) {
      // Dual crossing crescent slashes (Corte duplo compacto)
      final offsets = [-6.0, 6.0];
      final angles = [-5.0, 5.0];
      final right = Vector2(-player.forward.y, player.forward.x);
      for (int i = 0; i < 2; i++) {
        final angleRad = angles[i] * math.pi / 180.0;
        final shootAngle = player.angle + angleRad;
        final dir = Vector2(math.cos(shootAngle - math.pi / 2), math.sin(shootAngle - math.pi / 2));
        final slash = KatanaSlashComponent(
          position: player.position + player.forward * (player.radius + 8.0) + right * offsets[i],
          angle: shootAngle,
          velocity: dir * 370.0,
          lifeTimer: 0.36, // Alcance ~130px
          damage: effectiveDamage,
          slashWidth: 32.0,
          slashHeight: 12.0,
          slashColor: const Color(0xFF00E5FF),
          piercesLeft: 2,
          weaponSource: this,
        );
        player.game.world.add(slash);
      }
      return true;
    }

    // Level 1: Lâmina crescente frontal taquiônica cirúrgica de alcance médio
    final slash = KatanaSlashComponent(
      position: player.position + player.forward * (player.radius + 8.0),
      angle: player.angle,
      velocity: player.forward * 340.0,
      lifeTimer: 0.35, // Alcance cirúrgico de ~120px
      damage: effectiveDamage,
      slashWidth: 26.0,
      slashHeight: 10.0,
      slashColor: const Color(0xFF00E5FF),
      piercesLeft: 1, // Consumido na primeira apara ou impacto
      weaponSource: this,
    );
    player.game.world.add(slash);
    return true;
  }

  @override
  void applyUpgradeStats() {
    if (level == 2) {
      cooldown = 0.50;
      recoil = 1.8;
      damage = 20.0;
      muzzleFlashSize = 7.0;
    } else if (level >= 3) {
      cooldown = 0.42;
      recoil = 1.2;
      damage = 28.0;
      muzzleFlashSize = 9.0;
    }
  }

  @override
  void applyEvolution() {
    cooldown = 0.32;
    recoil = 1.0;
    damage = 42.0;
    muzzleFlashSize = 12.0;
  }
}
