import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:asteroids/constants.dart';
import 'package:asteroids/game/asteroids_game.dart';
import 'package:asteroids/game/sector.dart';
import 'asteroid.dart';
import 'enemy_ship.dart';
import 'cryo_pod.dart';
import 'package:asteroids/services/localization_service.dart';

/// Sprint 58: Formações coreografadas de esquadrilhas táticas (*Nova Drift / Galaga*).
enum TacticalFormationType {
  wedge, // Cunha Tática: 1 Líder Raider + 4 Scouts em V
  pincer, // Pinça Dupla Flanqueadora: 2 esquadrões em quadrantes opostos
  freightEscort, // Comboio de Suprimentos: 1 Flagship/Carrier + 2 AegisBulwarks frontais
}

class TacticalSpawnSpec {
  final Vector2 position;
  final EnemyType type;
  const TacticalSpawnSpec(this.position, this.type);
}

class AsteroidField extends Component with HasGameReference<AsteroidsGame> {
  static const int maxActiveEnemiesCap =
      40; // Teto estrito (35 a 45 naves) para manter 60 FPS cravados
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
  bool magmaSurgeSpawned = false;
  bool swarm60Spawned = false;
  bool smugglerSpawned = false;
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
      _spawnSwarmRush(
        count: 4,
        label: '⚠️ PATRULHA DE RECONHECIMENTO DETECTADA! ⚠️',
      );
    }
    // Sprint 46: Crise de Setor 1 - Tempestade de Meteoritos Magmáticos
    if (difficultyTimer >= 35.0 && !magmaSurgeSpawned) {
      magmaSurgeSpawned = true;
      _spawnMagmaMeteoriteSurge();
    }
    if (difficultyTimer >= 45.0 && !subBoss45Spawned) {
      subBoss45Spawned = true;
      _spawnEliteCommander(
        1,
        label: '⚠️ SUB-CHEFE [0:45]: VANGUARDA DO VÁCUO!',
      );
    }
    if (difficultyTimer >= 60.0 && !swarm60Spawned) {
      swarm60Spawned = true;
      _spawnSwarmRush(
        count: 10,
        label: '⚠️ CERCO DE DRONES EM ALTA VELOCIDADE! ⚠️',
      );
    }
    if (difficultyTimer >= 75.0 && !cryoPodSpawned) {
      cryoPodSpawned = true;
      _spawnCryoPod();
    }
    if (difficultyTimer >= 90.0 && !elite1Spawned) {
      elite1Spawned = true;
      _spawnEliteCommander(
        2,
        label: '⚠️ SUB-CHEFES [1:30]: EXECUTORES GÊMEOS!',
      );
    }
    // Sprint 46: Crise de Setor 2 - Cargueiro Contrabandista de Alta Prioridade
    if (difficultyTimer >= 110.0 && !smugglerSpawned) {
      smugglerSpawned = true;
      _spawnSmugglerConvoy();
    }
    if (difficultyTimer >= 135.0 && !elite2Spawned) {
      elite2Spawned = true;
      _spawnEliteCommander(
        2,
        label: '⚠️ SUB-CHEFES [2:15]: GUARDA DE ELITE DO SETOR!',
      );
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
      final activeCount = game.activeAsteroids.isNotEmpty
          ? game.activeAsteroids.length
          : game.world.children.whereType<AsteroidComponent>().length;
      if (activeCount < 24) {
        _spawnAsteroid();
      }
    }

    // 3. Intervalo de Frota Inimiga (Curva Roguelite Progressiva)
    double enemyInterval;
    if (difficultyTimer < 25.0) {
      enemyInterval =
          3.4; // Onboarding suave: 1 nave por vez para coletar XP inicial e escolher upgrade
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
      playerPos = Vector2(
        GameConstants.sectorWidth / 2,
        GameConstants.sectorHeight / 2,
      );
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
      final angle =
          (2 * math.pi * i / count) + (random.nextDouble() - 0.5) * 0.25;
      final dist = 520.0 + random.nextDouble() * 80.0;
      final spawnPos =
          playerPos + Vector2(math.cos(angle), math.sin(angle)) * dist;

      spawnPos.x = spawnPos.x.clamp(60.0, GameConstants.sectorWidth - 60.0);
      spawnPos.y = spawnPos.y.clamp(60.0, GameConstants.sectorHeight - 60.0);

      spawnOrPromoteEnemy(
        EnemyShipComponent(position: spawnPos, type: EnemyType.voidSwarmer),
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
        pPos = Vector2(
          GameConstants.sectorWidth / 2,
          GameConstants.sectorHeight / 2,
        );
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
    final enemies = game.activeEnemies.isNotEmpty
        ? game.activeEnemies
        : game.world.children.whereType<EnemyShipComponent>();
    if (enemies.length >= maxActiveEnemiesCap) {
      final nonPromoted = enemies
          .where((e) => !e.isPromotedElite && e.hp > 0)
          .toList();
      if (nonPromoted.isNotEmpty) {
        nonPromoted.first.promoteToEliteWithAura();
      } else if (enemies.isNotEmpty) {
        enemies.first.promoteToEliteWithAura();
      }
      return;
    }
    game.activeEnemies.add(candidate);
    game.world.add(candidate);
  }

  void _spawnEliteCommander(int count, {String? label}) {
    Vector2 playerPos;
    try {
      playerPos = game.player.position;
    } catch (_) {
      playerPos = Vector2(
        GameConstants.sectorWidth / 2,
        GameConstants.sectorHeight / 2,
      );
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
        EnemyShipComponent(position: spawnPos, type: EnemyType.eliteCommander),
      );
    }
  }

  void _spawnMagmaMeteoriteSurge() {
    Vector2 playerPos;
    try {
      playerPos = game.player.position;
    } catch (_) {
      playerPos = Vector2(
        GameConstants.sectorWidth / 2,
        GameConstants.sectorHeight / 2,
      );
    }

    try {
      game.playSfx('low_health.wav');
      game.triggerScreenShake(duration: 0.8, intensity: 16.0);
      game.spawnFloatingText(
        playerPos + Vector2(0, -65),
        I18n.select(
          pt: '🌋 ALERTA DE CATACLISMO: TEMPESTADE DE MAGMA! 🌋',
          en: '🌋 CATACLYSM WARNING: MAGMA METEORITE SURGE! 🌋',
        ),
        color: const Color(0xFFFF5722),
        fontSize: 17.0,
      );
    } catch (_) {}

    final random = math.Random();
    const count = 4;
    for (int i = 0; i < count; i++) {
      final angle = (math.pi / 4) + (random.nextDouble() - 0.5) * 0.4;
      final speed = 190.0 + random.nextDouble() * 50.0;
      final velocity = Vector2(math.cos(angle), math.sin(angle)) * speed;
      final offset = Vector2(-400.0 - (i * 90.0), -300.0 + (i * 120.0));
      final spawnPos = playerPos + offset;

      game.world.add(
        AsteroidComponent(
          radius: 35.0,
          position: spawnPos,
          velocity: velocity,
          variant: AsteroidVariant.magma,
        ),
      );
    }
  }

  void _spawnSmugglerConvoy() {
    Vector2 playerPos;
    try {
      playerPos = game.player.position;
    } catch (_) {
      playerPos = Vector2(
        GameConstants.sectorWidth / 2,
        GameConstants.sectorHeight / 2,
      );
    }

    try {
      game.playSfx('powerup.wav');
      game.triggerScreenShake(duration: 0.6, intensity: 14.0);
      game.spawnFloatingText(
        playerPos + Vector2(0, -65),
        I18n.select(
          pt: '🛸 CARGUEIRO CLASSIFICADO DETECTADO // INTERCEPTE A CARGA! 🛸',
          en: '🛸 CLASSIFIED SMUGGLER DETECTED // INTERCEPT CARGO! 🛸',
        ),
        color: const Color(0xFFFFD700),
        fontSize: 17.0,
      );
    } catch (_) {}

    final smuggler = EnemyShipComponent(
      position: playerPos + Vector2(450, -350),
      type: EnemyType.eliteCommander,
    )..promoteToEliteWithAura(EliteAuraType.volatile);

    game.world.add(smuggler);
  }

  void _spawnEnemyWave() {
    final random = math.Random();
    Vector2 playerPos;
    try {
      playerPos = game.player.position;
    } catch (_) {
      playerPos = Vector2(
        GameConstants.sectorWidth / 2,
        GameConstants.sectorHeight / 2,
      );
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
        chosenType = (sectorId == SectorId.cryoAbyss)
            ? EnemyType.cryoBomber
            : EnemyType.raider;
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
        chosenType = (sectorId == SectorId.cryoAbyss)
            ? EnemyType.cryoBomber
            : EnemyType.gravityWeaver;
        count = 1;
      } else {
        chosenType = EnemyType.sniper;
        count = 2;
      }
    }

    // Sprint 58: A partir dos 45s, esquadrilhas coreografadas substituem spawns caóticos periodicamente
    if (difficultyTimer >= 45.0 && roll < 0.38) {
      Vector2 playerVel = Vector2.zero();
      try {
        playerVel = game.player.velocity;
      } catch (_) {}

      final TacticalFormationType formation;
      if (difficultyTimer >= 95.0 && roll < 0.13) {
        formation = TacticalFormationType.freightEscort;
      } else if (roll < 0.26) {
        formation = TacticalFormationType.wedge;
      } else {
        formation = TacticalFormationType.pincer;
      }

      spawnTacticalFormation(
        formation,
        playerPos: playerPos,
        playerVel: playerVel,
        spawnAngle: random.nextDouble() * 2 * math.pi,
      );
      return;
    }

    // Spawn the batch around camera perimeter
    final baseAngle = random.nextDouble() * 2 * math.pi;
    for (var i = 0; i < count; i++) {
      final angle = baseAngle + (i * 0.25);
      final dist =
          GameConstants.proximitySpawnMinRadius + random.nextDouble() * 120.0;
      final spawnPos =
          playerPos + Vector2(math.cos(angle), math.sin(angle)) * dist;

      spawnPos.x = spawnPos.x.clamp(60.0, GameConstants.sectorWidth - 60.0);
      spawnPos.y = spawnPos.y.clamp(60.0, GameConstants.sectorHeight - 60.0);

      spawnOrPromoteEnemy(
        EnemyShipComponent(position: spawnPos, type: chosenType),
      );
    }
  }

  static Vector2 _clampFormationPoint(Vector2 p) {
    return Vector2(
      p.x.clamp(60.0, GameConstants.sectorWidth - 60.0),
      p.y.clamp(60.0, GameConstants.sectorHeight - 60.0),
    );
  }

  /// Cunha Tática (*Wedge Formation*): 1 Raider líder na ponta + 4 Scouts em V simétrico.
  static List<TacticalSpawnSpec> buildWedgeFormation({
    required Vector2 origin,
    required Vector2 approachDir,
    double spacing = 48.0,
  }) {
    final forward = approachDir.length2 > 0.0001
        ? approachDir.normalized()
        : Vector2(0, 1);
    final right = Vector2(-forward.y, forward.x);

    return [
      TacticalSpawnSpec(_clampFormationPoint(origin), EnemyType.raider),
      TacticalSpawnSpec(
        _clampFormationPoint(origin - forward * spacing - right * spacing),
        EnemyType.scout,
      ),
      TacticalSpawnSpec(
        _clampFormationPoint(origin - forward * spacing + right * spacing),
        EnemyType.scout,
      ),
      TacticalSpawnSpec(
        _clampFormationPoint(
          origin - forward * (spacing * 2.0) - right * (spacing * 2.0),
        ),
        EnemyType.scout,
      ),
      TacticalSpawnSpec(
        _clampFormationPoint(
          origin - forward * (spacing * 2.0) + right * (spacing * 2.0),
        ),
        EnemyType.scout,
      ),
    ];
  }

  /// Pinça Dupla Flanqueadora (*Pincer Maneuver*): 2 esquadrões em quadrantes opostos
  /// interceptando o vetor de fuga da jogadora.
  static List<TacticalSpawnSpec> buildPincerManeuver({
    required Vector2 playerPos,
    required Vector2 playerVel,
    double forwardLead = 260.0,
    double flankDistance = 380.0,
  }) {
    final forward = playerVel.length2 > 25.0
        ? playerVel.normalized()
        : Vector2(0, -1);
    final right = Vector2(-forward.y, forward.x);
    final interceptCenter = playerPos + forward * forwardLead;

    final leftCenter = _clampFormationPoint(
      interceptCenter - right * flankDistance,
    );
    final rightCenter = _clampFormationPoint(
      interceptCenter + right * flankDistance,
    );

    return [
      TacticalSpawnSpec(leftCenter, EnemyType.raider),
      TacticalSpawnSpec(
        _clampFormationPoint(leftCenter + forward * 42.0 - right * 28.0),
        EnemyType.scout,
      ),
      TacticalSpawnSpec(
        _clampFormationPoint(leftCenter - forward * 42.0 - right * 28.0),
        EnemyType.scout,
      ),
      TacticalSpawnSpec(rightCenter, EnemyType.raider),
      TacticalSpawnSpec(
        _clampFormationPoint(rightCenter + forward * 42.0 + right * 28.0),
        EnemyType.scout,
      ),
      TacticalSpawnSpec(
        _clampFormationPoint(rightCenter - forward * 42.0 + right * 28.0),
        EnemyType.scout,
      ),
    ];
  }

  /// Comboio de Suprimentos (*Freight Escort*): 1 nave capital/Carrier protegida
  /// na vanguarda por 2 cruzadores de escudo frontal AegisBulwark.
  static List<TacticalSpawnSpec> buildFreightEscort({
    required Vector2 origin,
    required Vector2 approachDir,
    bool useEliteFlagship = false,
  }) {
    final forward = approachDir.length2 > 0.0001
        ? approachDir.normalized()
        : Vector2(0, 1);
    final right = Vector2(-forward.y, forward.x);

    return [
      TacticalSpawnSpec(
        _clampFormationPoint(origin),
        useEliteFlagship ? EnemyType.eliteCommander : EnemyType.carrierHive,
      ),
      TacticalSpawnSpec(
        _clampFormationPoint(origin + forward * 68.0 - right * 54.0),
        EnemyType.aegisBulwark,
      ),
      TacticalSpawnSpec(
        _clampFormationPoint(origin + forward * 68.0 + right * 54.0),
        EnemyType.aegisBulwark,
      ),
    ];
  }

  void spawnTacticalFormation(
    TacticalFormationType formation, {
    required Vector2 playerPos,
    Vector2? playerVel,
    double spawnAngle = 0.0,
    bool useEliteFlagship = false,
  }) {
    final dist = GameConstants.proximitySpawnMinRadius + 80.0;
    final origin = _clampFormationPoint(
      playerPos + Vector2(math.cos(spawnAngle), math.sin(spawnAngle)) * dist,
    );
    final toPlayer = playerPos - origin;
    final approachDir = toPlayer.length2 > 1.0
        ? toPlayer.normalized()
        : Vector2(0, 1);

    final List<TacticalSpawnSpec> specs;
    switch (formation) {
      case TacticalFormationType.wedge:
        specs = buildWedgeFormation(origin: origin, approachDir: approachDir);
        break;
      case TacticalFormationType.pincer:
        specs = buildPincerManeuver(
          playerPos: playerPos,
          playerVel: playerVel ?? Vector2.zero(),
        );
        break;
      case TacticalFormationType.freightEscort:
        specs = buildFreightEscort(
          origin: origin,
          approachDir: approachDir,
          useEliteFlagship: useEliteFlagship,
        );
        break;
    }

    for (final spec in specs) {
      spawnOrPromoteEnemy(
        EnemyShipComponent(position: spec.position.clone(), type: spec.type),
      );
    }
  }

  void _spawnAsteroid() {
    if (game.state != GameState.playing) return;
    final activeCount = game.activeAsteroids.isNotEmpty
        ? game.activeAsteroids.length
        : game.world.children.whereType<AsteroidComponent>().length;
    if (activeCount >= 24) return;

    final random = math.Random();
    Vector2 playerPos;
    try {
      playerPos = game.player.position;
    } catch (_) {
      playerPos = Vector2(
        GameConstants.sectorWidth / 2,
        GameConstants.sectorHeight / 2,
      );
    }

    final spawnDist =
        GameConstants.proximitySpawnMinRadius +
        random.nextDouble() *
            (GameConstants.proximitySpawnMaxRadius -
                GameConstants.proximitySpawnMinRadius);
    final spawnAngle = random.nextDouble() * 2 * math.pi;
    final spawnOffset = Vector2(math.cos(spawnAngle), math.sin(spawnAngle))
      ..scale(spawnDist);
    final position = playerPos + spawnOffset;

    position.x = position.x.clamp(60.0, GameConstants.sectorWidth - 60.0);
    position.y = position.y.clamp(60.0, GameConstants.sectorHeight - 60.0);

    final speed = (35.0 + random.nextDouble() * 45.0) * speedMultiplier;
    final toPlayer = (playerPos - position).normalized();
    final deviationAngle =
        (-45.0 + random.nextDouble() * 90.0) * math.pi / 180.0;
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
    } else if (game.currentSector.id == SectorId.orion &&
        random.nextDouble() < 0.40) {
      variant = AsteroidVariant.magma;
    } else if (difficultyTimer >= 30.0) {
      final roll = random.nextDouble();
      if (roll < 0.14) {
        variant = AsteroidVariant.titanium;
      } else if (roll < 0.35) {
        variant = AsteroidVariant.crystalline;
      } else if (roll < 0.50 &&
          (game.currentSector.id == SectorId.orion ||
              difficultyTimer >= 120.0)) {
        variant = AsteroidVariant.magma;
      }
    }

    final asteroid = AsteroidComponent(
      radius: radius,
      position: position,
      velocity: velocity,
      variant: variant,
    );
    game.activeAsteroids.add(asteroid);
    game.world.add(asteroid);
  }

  void _spawnCryoPod() {
    Vector2 playerPos;
    try {
      playerPos = game.player.position;
    } catch (_) {
      playerPos = Vector2(
        GameConstants.sectorWidth / 2,
        GameConstants.sectorHeight / 2,
      );
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
