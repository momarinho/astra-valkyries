import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:asteroids/constants.dart';
import 'package:asteroids/game/asteroids_game.dart';
import 'asteroid.dart';
import 'enemy_ship.dart';
import 'dreadnought_leviathan.dart';

class AsteroidField extends Component with HasGameReference<AsteroidsGame> {
  final String mode;
  double spawnTimer = 0.0;
  double enemySpawnTimer = 0.0;
  double difficultyTimer = 0.0;
  double spawnRateMultiplier = 1.0;
  double speedMultiplier = 1.0;

  bool elite1Spawned = false;
  bool elite2Spawned = false;
  bool leviathanSpawned = false;

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

    // Timeline Script do Vampire Survivors:
    // 1. Spawns cronometrados de Elites (Void Commander)
    if (difficultyTimer >= 90.0 && !elite1Spawned) {
      elite1Spawned = true;
      _spawnEliteCommander(1);
    } else if (difficultyTimer >= 140.0 && !elite2Spawned) {
      elite2Spawned = true;
      _spawnEliteCommander(2);
    }

    // 2. Climax Boss: Titanic Dreadnought Leviathan (Minuto 2:40 / 160s ou 600s)
    if (difficultyTimer >= 160.0 && !leviathanSpawned) {
      leviathanSpawned = true;
      _spawnLeviathanBoss();
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

    // 3. Intervalo de Frota Inimiga (Scouts, Raiders, Snipers)
    double enemyInterval;
    if (difficultyTimer < 40.0) {
      enemyInterval = 4.5; // Onboarding inicial: patrulhas espaçadas
    } else if (difficultyTimer < 90.0) {
      enemyInterval = 3.0; // Enxames leves
    } else if (difficultyTimer < 150.0) {
      enemyInterval = 2.2; // Pressão constante
    } else {
      enemyInterval = 1.4; // Tempestade cósmica
    }

    if (enemySpawnTimer > enemyInterval) {
      enemySpawnTimer = 0.0;
      final activeEnemies = game.world.children.whereType<EnemyShipComponent>().length;
      if (activeEnemies < 16) {
        _spawnEnemyWave();
      }
    }
  }

  void _spawnLeviathanBoss() {
    Vector2 playerPos;
    try {
      playerPos = game.player.position;
    } catch (_) {
      playerPos = Vector2(GameConstants.sectorWidth / 2, GameConstants.sectorHeight / 2);
    }

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

    final random = math.Random();
    final angle = random.nextDouble() * 2 * math.pi;
    final spawnDist = 850.0;
    final spawnPos = playerPos + Vector2(math.cos(angle), math.sin(angle)) * spawnDist;

    spawnPos.x = spawnPos.x.clamp(120.0, GameConstants.sectorWidth - 120.0);
    spawnPos.y = spawnPos.y.clamp(120.0, GameConstants.sectorHeight - 120.0);

    final boss = DreadnoughtLeviathanComponent(position: spawnPos);
    game.world.add(boss);
  }

  void _spawnEliteCommander(int count) {
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
        '⚠️ HOSTILE FLAGSHIP DETECTED! (ELITE TARGET)',
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

    // Determine enemy type based on clock timeline
    EnemyType chosenType;
    int count = 1;

    if (difficultyTimer < 50.0) {
      // Phase 1: Scout Drones
      chosenType = EnemyType.scout;
      count = random.nextInt(2) + 1; // 1-2 scouts
    } else if (difficultyTimer < 110.0) {
      // Phase 2: Scout swarms + occasional Phantom Raider
      if (random.nextDouble() < 0.25) {
        chosenType = EnemyType.raider;
        count = 1;
      } else {
        chosenType = EnemyType.scout;
        count = random.nextInt(3) + 2; // 2-4 scouts
      }
    } else if (difficultyTimer < 180.0) {
      // Phase 3: Scouts, Raiders and Corvette Snipers
      final roll = random.nextDouble();
      if (roll < 0.40) {
        chosenType = EnemyType.scout;
        count = 3;
      } else if (roll < 0.75) {
        chosenType = EnemyType.raider;
        count = 1;
      } else {
        chosenType = EnemyType.sniper;
        count = 1;
      }
    } else {
      // Phase 4: High intensity mixed assault
      final roll = random.nextDouble();
      if (roll < 0.35) {
        chosenType = EnemyType.scout;
        count = 4;
      } else if (roll < 0.70) {
        chosenType = EnemyType.raider;
        count = 2;
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

      game.world.add(
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

    // Variant selection based on timeline
    AsteroidVariant variant = AsteroidVariant.standard;
    if (difficultyTimer >= 60.0) {
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
