import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:asteroids/constants.dart';
import 'package:asteroids/game/asteroids_game.dart';
import 'package:asteroids/game/sector.dart';
import 'asteroid.dart';
import 'enemy_ship.dart';
import 'dreadnought_leviathan.dart';
import 'ignis_wyrm.dart';
import 'cryo_pod.dart';
import 'package:asteroids/services/localization_service.dart';

class AsteroidField extends Component with HasGameReference<AsteroidsGame> {
  static const int maxActiveEnemiesCap = 40; // Teto estrito (35 a 45 naves) para manter 60 FPS cravados
  final String mode;
  double spawnTimer = 0.0;
  double enemySpawnTimer = 0.0;
  double difficultyTimer = 0.0;
  double spawnRateMultiplier = 1.0;
  double speedMultiplier = 1.0;

  bool subBoss45Spawned = false;
  bool elite1Spawned = false;
  bool elite2Spawned = false;
  bool leviathanSpawned = false;
  bool cryoPodSpawned = false;
  bool goldenAsteroidSpawned = false;
  bool swarm20Spawned = false;
  bool swarm60Spawned = false;
  bool sectorClimaxSpawned = false;

  AsteroidField({this.mode = 'classic'});

  @override
  void update(double dt) {
    super.update(dt);
    
    // NUNCA spawnar entidades fora do estado de partida ativa
    if (game.state != GameState.playing || mode == 'campaign') {
      return;
    }

    spawnTimer += dt;
    enemySpawnTimer += dt;
    difficultyTimer += dt;

    // Timeline Script do Roguelite (Hordas e Incursões Escaladas):
    if (difficultyTimer >= 20.0 && !swarm20Spawned) {
      swarm20Spawned = true;
      _spawnSwarmRush(count: 4, label: '⚠️ PATRULHA DE RECONHECIMENTO DETECTADA! ⚠️');
    }
    if (difficultyTimer >= 45.0 && !subBoss45Spawned) {
      subBoss45Spawned = true;
      _spawnEliteCommander(1, label: '⚠️ SUB-CHEFE [0:45]: VANGUARDA DO VÁCUO!');
    }
    if (difficultyTimer >= 60.0 && !swarm60Spawned) {
      swarm60Spawned = true;
      _spawnSwarmRush(count: 10, label: '⚠️ CERCO DE DRONES EM ALTA VELOCIDADE! ⚠️');
    }
    if (difficultyTimer >= 75.0 && !cryoPodSpawned) {
      cryoPodSpawned = true;
      _spawnCryoPod();
    }
    if (difficultyTimer >= 90.0 && !elite1Spawned) {
      elite1Spawned = true;
      _spawnEliteCommander(2, label: '⚠️ SUB-CHEFES [1:30]: EXECUTORES GÊMEOS!');
    }
    if (difficultyTimer >= 135.0 && !elite2Spawned) {
      elite2Spawned = true;
      _spawnEliteCommander(2, label: '⚠️ SUB-CHEFES [2:15]: GUARDA DE ELITE DO SETOR!');
    }
    if (difficultyTimer >= 150.0 && !sectorClimaxSpawned) {
      sectorClimaxSpawned = true;
      _triggerSectorBossClimax();
    }

    // 2. Intervalo de Asteroides
    double asteroidInterval;
    if (difficultyTimer < 50.0) {
      final p = difficultyTimer / 50.0;
      asteroidInterval = 3.2 - (p * 1.0);
      speedMultiplier = 0.55 + (p * 0.30);
    } else if (difficultyTimer < 105.0) {
      final p = (difficultyTimer - 50.0) / 55.0;
      asteroidInterval = 2.2 - (p * 0.90);
      speedMultiplier = 0.85 + (p * 0.40);
    } else if (difficultyTimer < 150.0) {
      final p = (difficultyTimer - 105.0) / 45.0;
      asteroidInterval = 1.30 - (p * 0.60);
      speedMultiplier = 1.25 + (p * 0.50);
    } else {
      final p = ((difficultyTimer - 150.0) / 30.0).clamp(0.0, 1.0);
      asteroidInterval = 0.70 - (p * 0.44);
      speedMultiplier = 1.75 + (p * 0.90);
    }

    if (spawnTimer > asteroidInterval) {
      spawnTimer = 0.0;
      final activeAsteroids = game.world.children.whereType<AsteroidComponent>().length;
      if (activeAsteroids < 24) {
        _spawnAsteroid();
      }
    }

    // 3. Intervalo de Frota Inimiga (Curva Roguelite Progressiva)
    double enemyInterval;
    if (difficultyTimer < 25.0) {
      enemyInterval = 3.4; // Onboarding suave: 1 nave por vez para coletar XP inicial e escolher upgrade
    } else if (difficultyTimer < 50.0) {
      enemyInterval = 2.4; // Pequenas patrulhas para testar o primeiro upgrade
    } else if (difficultyTimer < 90.0) {
      enemyInterval = 1.6; // Incursões moderadas (Scouts, Raiders, Enxames)
    } else if (difficultyTimer < 140.0) {
      enemyInterval = 1.15; // Pressão constante
    } else {
      enemyInterval = 0.80; // Tempestade cósmica pré-chefe
    }

    if (enemySpawnTimer > enemyInterval) {
      enemySpawnTimer = 0.0;
      _spawnEnemyWave();
    }
  }

  void _spawnSwarmRush({required int count, String? label}) {
    Vector2 playerPos;
    try {
      playerPos = game.player.position;
    } catch (_) {
      playerPos = Vector2(GameConstants.sectorWidth / 2, GameConstants.sectorHeight / 2);
    }

    if (label != null) {
      try {
        game.playSfx('low_health.wav');
        game.triggerScreenShake(duration: 0.6, intensity: 12.0);
        game.spawnFloatingText(
          playerPos + Vector2(0, -60),
          label,
          color: const Color(0xFFFF5252),
          fontSize: 16.0,
        );
      } catch (_) {}
    }

    final random = math.Random();
    for (int i = 0; i < count; i++) {
      final angle = (2 * math.pi * i / count) + (random.nextDouble() - 0.5) * 0.25;
      final dist = 520.0 + random.nextDouble() * 80.0;
      final spawnPos = playerPos + Vector2(math.cos(angle), math.sin(angle)) * dist;

      spawnPos.x = spawnPos.x.clamp(60.0, GameConstants.sectorWidth - 60.0);
      spawnPos.y = spawnPos.y.clamp(60.0, GameConstants.sectorHeight - 60.0);

      spawnOrPromoteEnemy(
        EnemyShipComponent(
          position: spawnPos,
          type: EnemyType.voidSwarmer,
        ),
      );
    }
  }

  void _triggerSectorBossClimax() {
    if (game.activeBoss != null && !game.activeBoss!.isDefeated) return;

    try {
      game.triggerBossEncounter();
      game.playSfx('powerup.wav');
      game.triggerScreenShake(duration: 1.5, intensity: 24.0);
      Vector2 pPos;
      try {
        pPos = game.player.position;
      } catch (_) {
        pPos = Vector2(GameConstants.sectorWidth / 2, GameConstants.sectorHeight / 2);
      }
      game.spawnFloatingText(
        pPos + Vector2(0, -75),
        I18n.select(
          pt: '🚨 ALERTA GERAL: O TITÃ DO SETOR EMERGIU DO HIPERESPAÇO! 🚨',
          en: '🚨 SECTOR ALERT: SECTOR TITAN EMERGED FROM HYPERSPACE! 🚨',
        ),
        color: const Color(0xFFFF1744),
        fontSize: 19.0,
      );
    } catch (_) {}
  }

  /// Horde Director (Sprint 20): Respeita o teto de 35-45 naves ativas.
  /// Se o teto for atingido, promove uma nave existente para Elite com Aura em vez de inflar entidades.
  void spawnOrPromoteEnemy(EnemyShipComponent candidate) {
    final activeEnemies = game.world.children.whereType<EnemyShipComponent>().toList();
    if (activeEnemies.length >= maxActiveEnemiesCap) {
      final nonPromoted = activeEnemies.where((e) => !e.isPromotedElite && e.hp > 0).toList();
      if (nonPromoted.isNotEmpty) {
        nonPromoted.first.promoteToEliteWithAura();
      } else if (activeEnemies.isNotEmpty) {
        activeEnemies.first.promoteToEliteWithAura();
      }
      return;
    }
    game.world.add(candidate);
  }

  void _spawnLeviathanBoss() {
    Vector2 playerPos;
    try {
      playerPos = game.player.position;
    } catch (_) {
      playerPos = Vector2(GameConstants.sectorWidth / 2, GameConstants.sectorHeight / 2);
    }

    final random = math.Random();
    final angle = random.nextDouble() * 2 * math.pi;
    final spawnDist = 850.0;
    final spawnPos = playerPos + Vector2(math.cos(angle), math.sin(angle)) * spawnDist;

    spawnPos.x = spawnPos.x.clamp(120.0, GameConstants.sectorWidth - 120.0);
    spawnPos.y = spawnPos.y.clamp(120.0, GameConstants.sectorHeight - 120.0);

    if (game.currentSector.id == SectorId.orion) {
      final boss = IgnisWyrmComponent(position: spawnPos);
      game.world.add(boss);
      try {
        game.playSfx('powerup.wav');
        game.triggerScreenShake(duration: 0.9, intensity: 22.0);
        game.spawnFloatingText(
          playerPos + Vector2(0, -60),
          '🔥 IGNIS WYRM SOLAR LEVIATHAN DETECTED! (SECTOR CLIMAX)',
          color: const Color(0xFFFF5722),
          fontSize: 18.0,
        );
      } catch (_) {}
    } else {
      final boss = DreadnoughtLeviathanComponent(position: spawnPos);
      game.world.add(boss);
      try {
        game.playSfx('powerup.wav');
        game.triggerScreenShake(duration: 0.9, intensity: 22.0);
        game.spawnFloatingText(
          playerPos + Vector2(0, -60),
          '🚨 TITANIC DREADNOUGHT LEVIATHAN DETECTED! (SECTOR CLIMAX)',
          color: const Color(0xFFFF1744),
          fontSize: 18.0,
        );
      } catch (_) {}
    }
  }

  void _spawnEliteCommander(int count, {String? label}) {
    Vector2 playerPos;
    try {
      playerPos = game.player.position;
    } catch (_) {
      playerPos = Vector2(GameConstants.sectorWidth / 2, GameConstants.sectorHeight / 2);
    }

    try {
      game.playSfx('powerup.wav');
      game.triggerScreenShake(duration: 0.5, intensity: 14.0);
      game.spawnFloatingText(
        playerPos + Vector2(0, -50),
        label ?? '⚠️ HOSTILE FLAGSHIP DETECTED! (ELITE TARGET)',
        color: const Color(0xFFFFD700),
        fontSize: 16.0,
      );
    } catch (_) {}

    final random = math.Random();
    for (var i = 0; i < count; i++) {
      final angle = (2 * math.pi * i / count) + random.nextDouble() * 0.5;
      final spawnDist = 850.0;
      final offset = Vector2(math.cos(angle), math.sin(angle)) * spawnDist;
      final spawnPos = playerPos + offset;

      spawnPos.x = spawnPos.x.clamp(80.0, GameConstants.sectorWidth - 80.0);
      spawnPos.y = spawnPos.y.clamp(80.0, GameConstants.sectorHeight - 80.0);

      game.world.add(
        EnemyShipComponent(
          position: spawnPos,
          type: EnemyType.eliteCommander,
        ),
      );
    }
  }

  void _spawnEnemyWave() {
    final random = math.Random();
    Vector2 playerPos;
    try {
      playerPos = game.player.position;
    } catch (_) {
      playerPos = Vector2(GameConstants.sectorWidth / 2, GameConstants.sectorHeight / 2);
    }

    // Determine enemy type based on clock timeline & Sprint 15 Sector Faction Bestiary
    EnemyType chosenType;
    int count = 1;
    final sectorId = game.currentSector.id;
    final roll = random.nextDouble();

    if (difficultyTimer < 25.0) {
      // Início seguro: apenas Scouts lentos individuais (fácil de mirar e farmar XP inicial)
      chosenType = EnemyType.scout;
      count = 1;
    } else if (difficultyTimer < 50.0) {
      if (roll < 0.35) {
        chosenType = EnemyType.voidSwarmer;
        count = 3;
      } else {
        chosenType = EnemyType.scout;
        count = 2;
      }
    } else if (difficultyTimer < 110.0) {
      if (roll < 0.25) {
        chosenType = (sectorId == SectorId.cryoAbyss) ? EnemyType.cryoBomber : EnemyType.raider;
        count = 2;
      } else if (roll < 0.50) {
        if (sectorId == SectorId.graveyard) {
          chosenType = EnemyType.aegisBulwark;
          count = 1;
        } else if (sectorId == SectorId.xenoHive) {
          chosenType = EnemyType.voidSwarmer;
          count = 6 + random.nextInt(4);
        } else {
          chosenType = EnemyType.voidSwarmer;
          count = 4 + random.nextInt(3);
        }
      } else {
        chosenType = EnemyType.scout;
        count = 2 + random.nextInt(2);
      }
    } else {
      if (roll < 0.22) {
        chosenType = EnemyType.voidSwarmer;
        count = 10 + random.nextInt(6);
      } else if (roll < 0.42) {
        chosenType = EnemyType.aegisBulwark;
        count = 1 + (game.voidCellsLevel >= 2 ? 1 : 0);
      } else if (roll < 0.58) {
        chosenType = EnemyType.carrierHive;
        count = 1;
      } else if (roll < 0.76) {
        chosenType = (sectorId == SectorId.cryoAbyss) ? EnemyType.cryoBomber : EnemyType.gravityWeaver;
        count = 1;
      } else {
        chosenType = EnemyType.sniper;
        count = 2;
      }
    }

    // Spawn the batch around camera perimeter
    final baseAngle = random.nextDouble() * 2 * math.pi;
    for (var i = 0; i < count; i++) {
      final angle = baseAngle + (i * 0.25);
      final dist = GameConstants.proximitySpawnMinRadius + random.nextDouble() * 120.0;
      final spawnPos = playerPos + Vector2(math.cos(angle), math.sin(angle)) * dist;

      spawnPos.x = spawnPos.x.clamp(60.0, GameConstants.sectorWidth - 60.0);
      spawnPos.y = spawnPos.y.clamp(60.0, GameConstants.sectorHeight - 60.0);

      spawnOrPromoteEnemy(
        EnemyShipComponent(
          position: spawnPos,
          type: chosenType,
        ),
      );
    }
  }

  void _spawnAsteroid() {
    if (game.state != GameState.playing) return;
    if (game.world.children.whereType<AsteroidComponent>().length >= 24) return;

    final random = math.Random();
    Vector2 playerPos;
    try {
      playerPos = game.player.position;
    } catch (_) {
      playerPos = Vector2(GameConstants.sectorWidth / 2, GameConstants.sectorHeight / 2);
    }

    final spawnDist = GameConstants.proximitySpawnMinRadius +
        random.nextDouble() * (GameConstants.proximitySpawnMaxRadius - GameConstants.proximitySpawnMinRadius);
    final spawnAngle = random.nextDouble() * 2 * math.pi;
    final spawnOffset = Vector2(math.cos(spawnAngle), math.sin(spawnAngle))..scale(spawnDist);
    final position = playerPos + spawnOffset;

    position.x = position.x.clamp(60.0, GameConstants.sectorWidth - 60.0);
    position.y = position.y.clamp(60.0, GameConstants.sectorHeight - 60.0);

    final speed = (35.0 + random.nextDouble() * 45.0) * speedMultiplier;
    final toPlayer = (playerPos - position).normalized();
    final deviationAngle = (-45.0 + random.nextDouble() * 90.0) * math.pi / 180.0;
    final velocity = toPlayer.clone()..rotate(deviationAngle);
    velocity.scale(speed);

    // Kind/Size
    final int kind;
    if (difficultyTimer < 50.0) {
      kind = random.nextBool() ? 2 : 3;
    } else {
      kind = random.nextInt(GameConstants.asteroidKinds) + 1;
    }
    final radius = GameConstants.asteroidMinRadius * kind;

    // Variant selection based on timeline, current sector & golden easter egg
    AsteroidVariant variant = AsteroidVariant.standard;
    if (!goldenAsteroidSpawned && difficultyTimer >= 40.0) {
      goldenAsteroidSpawned = true;
      variant = AsteroidVariant.golden;
    } else if (random.nextDouble() < 0.015) {
      variant = AsteroidVariant.golden;
    } else if (game.currentSector.id == SectorId.orion && random.nextDouble() < 0.40) {
      variant = AsteroidVariant.magma;
    } else if (difficultyTimer >= 60.0) {
      final roll = random.nextDouble();
      if (difficultyTimer < 120.0) {
        if (roll < 0.30) variant = AsteroidVariant.crystalline;
      } else {
        if (roll < 0.25) {
          variant = AsteroidVariant.crystalline;
        } else if (roll < 0.50) {
          variant = AsteroidVariant.magma;
        }
      }
    }

    final asteroid = AsteroidComponent(
      radius: radius,
      position: position,
      velocity: velocity,
      variant: variant,
    );
    game.world.add(asteroid);
  }

  void _spawnCryoPod() {
    Vector2 playerPos;
    try {
      playerPos = game.player.position;
    } catch (_) {
      playerPos = Vector2(GameConstants.sectorWidth / 2, GameConstants.sectorHeight / 2);
    }
    final random = math.Random();
    final a = random.nextDouble() * 2 * math.pi;
    final spawnPos = playerPos + Vector2(math.cos(a), math.sin(a)) * 520.0;
    spawnPos.x = spawnPos.x.clamp(200.0, GameConstants.sectorWidth - 200.0);
    spawnPos.y = spawnPos.y.clamp(200.0, GameConstants.sectorHeight - 200.0);

    game.world.add(CryoPodComponent(position: spawnPos));
    game.spawnFloatingText(
      playerPos + Vector2(0, -60),
      '📡 SOS DISTRESS BEACON: ANCIENT CRYO-POD DETECTED!',
      color: const Color(0xFF00E5FF),
      fontSize: 16.0,
    );
  }

  String dangerLevel() {
    if (spawnRateMultiplier >= 2.0 || speedMultiplier >= 1.7) {
      return "High";
    }
    if (spawnRateMultiplier >= 1.5 || speedMultiplier >= 1.35) {
      return "Medium";
    }
    return "Low";
  }
}
