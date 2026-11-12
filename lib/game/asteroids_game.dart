import 'dart:math' as math;
import 'package:flame/game.dart';
import 'package:flame/camera.dart';
import 'package:flame/events.dart';
import 'package:flame/components.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:asteroids/constants.dart';
import 'components/player.dart';
import 'components/asteroid_field.dart';
import 'components/particle.dart';
import 'components/particle_system.dart';
import 'components/asteroid.dart';
import 'components/comet.dart';
import 'components/bullet.dart';
import 'components/bomb.dart';
import 'components/starfield.dart';
import 'components/sector_boundary.dart';
import 'components/joystick.dart';
import 'components/drop.dart';
import 'components/floating_text.dart';
import 'components/xp_orb.dart';
import 'components/enemy_ship.dart';
import 'components/enemy_bullet.dart';
import 'components/chest.dart';
import 'components/magma_hazard.dart';
import 'components/singularity_rift.dart';
import 'components/dreadnought_leviathan.dart';
import 'components/sector_boss.dart';
import 'components/hyperspace_gate.dart';
import 'components/void_reaper.dart';
import 'components/ignis_wyrm.dart';
import 'components/proximity_mine.dart';
import 'components/derelict_turret.dart';
import 'components/scrap_goliath.dart';
import 'components/void_singularity_core.dart';
import 'components/advanced_weapons.dart';
import 'components/dead_cells_biome.dart';
import 'components/living_biomes.dart';
import 'components/speech_bubble.dart';
import 'components/katana_slash.dart';
import 'components/space_station.dart';
import 'components/cargo_wreck.dart';
import 'components/cosmic_nebula.dart';
import 'components/kinetic_space_dust.dart';
import 'components/distant_megastructure.dart';
import 'components/procedural_cosmic_nebula.dart';
import 'components/space_time_warp_grid.dart';
import 'map/sector_map_data.dart';
import 'map/sector_map_generator.dart';
import 'weapons.dart';
import 'level_manager.dart';
import 'scientist.dart';
import 'valkyrie.dart';
import 'rogue_perks.dart';
import 'roguelite_systems.dart';
import '../services/achievement_service.dart';
import '../services/sound_engine.dart';
import '../services/secret_grimoire_service.dart';
import 'meta_progression.dart';
import 'affinity_system.dart';
import 'sector.dart';
import 'ending_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:asteroids/services/api_service.dart';
import 'package:asteroids/services/localization_service.dart';
import 'dart:io' as io;
import 'package:flutter/foundation.dart' show kIsWeb;

class BossCinematicData {
  final String title;
  final String subtitle;
  final Color color;

  BossCinematicData({
    required this.title,
    required this.subtitle,
    this.color = const Color(0xFFFF1744),
  });
}

enum GameState {
  menu,
  valkyrieSelection,
  settings,
  scienceIntro,
  scientistSelection,
  playing,
  gameOver,
  stageClear,
  shop,
  leaderboard,
  levelUp,
  starChart,
}

class ChestReward {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback apply;

  ChestReward({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.apply,
  });
}

class AsteroidsGame extends FlameGame
    with HasCollisionDetection, KeyboardEvents, TapCallbacks {
  late final PlayerComponent player;
  AsteroidField? asteroidField;
  LevelManager? levelManager;
  SectorBoss? activeBoss;
  late final GameJoystick joystick;
  final FastParticlePoolComponent particlePool = FastParticlePoolComponent();

  // Entity Registry (O(1) Spatial & Query System - Zero-GC)
  final Set<EnemyShipComponent> activeEnemies = <EnemyShipComponent>{};
  final Set<AsteroidComponent> activeAsteroids = <AsteroidComponent>{};
  final Set<DropComponent> activeDrops = <DropComponent>{};
  final Set<SectorBoss> activeBosses = <SectorBoss>{};
  final Set<SpaceStationComponent> activeStations = <SpaceStationComponent>{};
  final Set<ChestComponent> activeChests = <ChestComponent>{};
  final Set<CargoWreckComponent> activeCargoWrecks = <CargoWreckComponent>{};
  final Set<CosmicNebulaComponent> activeNebulae = <CosmicNebulaComponent>{};

  // Real-time Engine FPS & Diagnostics
  double currentFps = 60.0;
  double currentFrameTimeMs = 16.6;
  bool showDiagnostics = false;
  bool showFpsOverlay = false;

  // Vampire Survivors Climax: The Void Reaper
  bool voidReaperSpawned = false;

  // Procedural Sector Map Data (Dead Cells style exploration)
  SectorMapData? sectorMap;
  bool isTacticalMapOpen = false;

  FocusNode? gameFocusNode;

  final Set<LogicalKeyboardKey> keysPressed = {};

  bool get isMobile => !kIsWeb && (io.Platform.isAndroid || io.Platform.isIOS);
  bool mobileShootPressed = false;
  bool mobileDashPressed = false;
  bool showTouchControls = false;
  bool isAimLocked =
      false; // Trava de Mira (Strafe Lock) no Mobile/Joystick para recuar atirando
  bool useDirectionalControls =
      false; // False = Propulsão Vetorial + Ré Tática (Padrão PC), True = Direcional 360°
  int initialHangarTab = 0; // 0 = Hangar/Sortie, 1 = Loja/Oficina, 2 = Galeria
  GameState previousMenuState = GameState.menu;

  // Masterpiece Modes (Sprint 8 - 12) & Phase 2 Roguelite Systems (Sprint 13 - 18)
  bool isHyperMode = false;
  bool hyperModeUnlocked = true;
  bool isBossRushMode = false;
  int bossRushStage = 0;
  bool campaignCompleted = false;

  // Sprint 13, 16, 17, 18: Void Cells, Blueprints, Mutations & Milestones
  int voidCellsLevel = 0; // 0 a 5 (Dead Cells Boss Cells style)
  int maxUnlockedVoidCells = 1;
  final Set<String> foundBlueprints = {
    'aegis_sawblades',
    'tesla_arc',
    'inferno_cone',
  };
  final Set<String> forgedBlueprints = {
    'aegis_sawblades',
    'tesla_arc',
    'inferno_cone',
  };
  final List<String> activeMutations = [];
  final Set<String> unlockedMilestones = {};
  bool flawlessBossKill = true;
  String? lastBossEncountered;
  bool lastRunWasVictory = false;

  // Fase 3 (Sprints 22, 23, 24): Lore, Caixas Pretas, Balões de Fala & Finais Múltiplos
  SpeechBubbleComponent? activeSpeechBubble;
  final Set<String> unlockedFlightRecorders = {'log_erebus_01'};
  bool astraeaMatrixDecoded = false;
  bool primordialSovereignDefeated = false;
  EndingType lastTriggeredEnding = EndingType.none;
  final Set<EndingType> unlockedEndings = {};

  // Fase 4 (Sprints 25 a 28): Desbloqueio Condicional de Cenários, Relíquias, Armas & Bússola
  final Set<SectorId> unlockedSectors = {SectorId.vesta};
  final Set<String> unlockedRelics = {};
  final Set<SectorId> rescuedSectorSecrets = {};
  final Set<String> unlockedWeaponPool = {
    'tachyon_katana',
    'blaster',
    'spread_shot',
    'rapid_fire',
    'bomb_launcher',
  };
  final Map<String, Set<String>> completedSectorsPerValkyrie = {};

  // Rastreamento de feitos da run para desbloqueio condicional de armas (Sprint 27)
  int runAsteroidsDestroyed = 0;
  int runDashesExecuted = 0;
  int runEnemiesKilled = 0;
  int runVoidSwarmerKills = 0;
  int runMinesDestroyed = 0;
  int runSolarBurnTicks = 0;

  bool get canAccessSecretSector5 =>
      unlockedRelics.contains('yellow_sign') ||
      unlockedRelics.contains('nemesis_yellow_sign') ||
      EndingManager.canAccessSecretSector5(
        voidCellsLevel: voidCellsLevel,
        astraeaMatrixDecoded: astraeaMatrixDecoded,
        selectedValkyrieId: selectedValkyrie.id,
      );

  FlightRecorderLog recoverFlightRecorder(Vector2 pos) {
    final unfound = FlightRecorderLog.allFlightRecorders
        .where((log) => !unlockedFlightRecorders.contains(log.id))
        .toList();
    final chosen = unfound.isNotEmpty
        ? unfound.first
        : FlightRecorderLog.allFlightRecorders[pos.x.toInt().abs() %
              FlightRecorderLog.allFlightRecorders.length];
    unlockedFlightRecorders.add(chosen.id);
    if (unlockedFlightRecorders.length >= 4) {
      astraeaMatrixDecoded = true;
    }
    try {
      spawnFloatingText(
        pos + Vector2(0, -48),
        '📼 CAIXA PRETA: ${chosen.vesselName.toUpperCase()}!',
        color: const Color(0xFFFFD700),
        fontSize: 13.5,
      );
      triggerSpeechBubble(SpeechTrigger.flightRecorderFound);
    } catch (_) {}
    savePersistentCredits();
    return chosen;
  }

  SpeechBubbleComponent triggerSpeechBubble(
    SpeechTrigger trigger, {
    String? customText,
  }) {
    if (activeSpeechBubble != null && activeSpeechBubble!.isMounted) {
      activeSpeechBubble!.removeFromParent();
    }
    final text =
        customText ??
        SpeechBubbleComponent.getContextualLine(selectedValkyrie.id, trigger);
    final bubble = SpeechBubbleComponent(
      valkyrieId: selectedValkyrie.id,
      valkyrieName: selectedValkyrie.name,
      fullText: text,
      trigger: trigger,
      accentColor: selectedValkyrie.accentColor,
    );
    try {
      bubble.position = player.position + Vector2(0, -34);
    } catch (_) {}
    activeSpeechBubble = bubble;
    world.add(bubble);
    playSfx('menu_select.wav');
    return bubble;
  }

  void onBossDefeatedSpeechCheck() {
    // Sprint 52: Camera Punch Zoom ao derrubar chefe colossal
    setCameraZoom(1.18);
    Future.delayed(const Duration(milliseconds: 1500), () {
      setCameraZoom(1.0);
    });
    AchievementService.unlock('first_blood');
    if (flawlessBossKill) {
      unlockMilestone('ach_flawless_titan');
      triggerSpeechBubble(SpeechTrigger.flawlessVictory);
      unlockWeaponWithToast('void_mines');
    }
    if (selectedValkyrie.id == 'lyra') {
      unlockWeaponWithToast('inferno_cone');
    }
    markSectorCompleted(currentSector.id, selectedValkyrie.id);
    checkSectorProgressionOnBossDefeated(currentSector.id);
  }

  void checkSectorProgressionOnBossDefeated(SectorId completedSector) {
    switch (completedSector) {
      case SectorId.vesta:
        unlockSector(SectorId.cryoAbyss);
        unlockSector(SectorId.orion);
        break;
      case SectorId.orion:
        unlockSector(SectorId.graveyard);
        break;
      case SectorId.cryoAbyss:
        unlockSector(SectorId.xenoHive);
        break;
      case SectorId.graveyard:
      case SectorId.xenoHive:
        unlockSector(SectorId.eventHorizon);
        break;
      case SectorId.eventHorizon:
        if (voidCellsLevel >= 3 ||
            unlockedRelics.contains('yellow_sign') ||
            astraeaMatrixDecoded) {
          unlockSector(SectorId.voidThrone);
        }
        break;
      case SectorId.voidThrone:
        break;
    }
  }

  bool isWeaponUnlockedInPool(String weaponId) {
    return unlockedWeaponPool.contains(weaponId) ||
        forgedBlueprints.contains(weaponId);
  }

  void unlockWeaponWithToast(String weaponId) {
    if (unlockedWeaponPool.contains(weaponId)) return;
    unlockedWeaponPool.add(weaponId);
    final bp = BlueprintDef.findByWeaponId(weaponId);
    final name = bp?.name ?? weaponId.toUpperCase();
    try {
      spawnFloatingText(
        player.position + Vector2(0, -60),
        '🔓 ARMA DESBLOQUEADA NO POOL: $name!',
        color: const Color(0xFFFFD700),
        fontSize: 16.0,
      );
      playSfx('powerup.wav');
    } catch (_) {}
    savePersistentCredits();
  }

  void claimPermanentRelic(String relicId, [Vector2? pos]) {
    if (unlockedRelics.contains(relicId)) return;
    unlockedRelics.add(relicId);
    final relic = PermanentRelic.findById(relicId);
    final name = relic?.title ?? relicId.toUpperCase();

    // Aplica benefício imediato da relíquia
    if (relicId == 'yellow_sign' || relicId == 'nemesis_yellow_sign') {
      astraeaMatrixDecoded = true;
      affinityManager.addAffinity(selectedValkyrie.id, 500);
      unlockSector(SectorId.voidThrone);
    }

    if (pos != null) {
      try {
        spawnFloatingText(
          pos + Vector2(0, -50),
          '🗺️ RELÍQUIA PERMANENTE OBTIDA: $name!',
          color: const Color(0xFFFFD700),
          fontSize: 15.5,
        );
        playSfx('powerup.wav');
        triggerScreenShake(duration: 0.6, intensity: 10.0);
      } catch (_) {}
    }
    savePersistentCredits();
  }

  void unlockSectorSecret(SectorId sId, [Vector2? pos]) {
    if (rescuedSectorSecrets.contains(sId)) return;
    rescuedSectorSecrets.add(sId);

    // Resgate de Cápsulas (Coffins) estilo Vampire Survivors
    if (sId == SectorId.vesta) {
      // Libera Vesper gratuitamente
      unlockWeaponWithToast('aegis_sawblades');
    } else if (sId == SectorId.xenoHive) {
      // Libera Astraea e drones aliados
      astraeaMatrixDecoded = true;
      unlockWeaponWithToast('valkyrie_wingmen');
    } else if (sId == SectorId.cryoAbyss) {
      unlockWeaponWithToast('quantum_chakram');
    } else if (sId == SectorId.orion) {
      unlockWeaponWithToast('solar_lance');
    } else if (sId == SectorId.graveyard) {
      unlockWeaponWithToast('tesla_arc');
    }

    addRunCredits(350);
    if (pos != null) {
      try {
        spawnFloatingText(
          pos + Vector2(0, -50),
          '⚰️ SEGREDO DO BIOMA RESGATADO! (+350c)',
          color: const Color(0xFF00E5FF),
          fontSize: 15.0,
        );
        playSfx('powerup.wav');
        triggerScreenShake(duration: 0.5, intensity: 8.0);
      } catch (_) {}
    }
    savePersistentCredits();
  }

  bool isSectorUnlocked(SectorId id) => unlockedSectors.contains(id);

  void unlockSector(SectorId id) {
    if (unlockedSectors.contains(id)) return;
    unlockedSectors.add(id);
    final sector = Sector.findById(id);
    try {
      spawnFloatingText(
        player.position + Vector2(0, -65),
        '🌌 NOVO SETOR DESBLOQUEADO: ${sector.name.toUpperCase()}!',
        color: sector.primaryColor,
        fontSize: 16.0,
      );
      playSfx('powerup.wav');
    } catch (_) {}
    savePersistentCredits();
  }

  bool isSectorCompletedWith(SectorId sId, String valkyrieId) {
    return completedSectorsPerValkyrie[sId.name]?.contains(valkyrieId) ?? false;
  }

  void markSectorCompleted(SectorId sId, String valkyrieId) {
    completedSectorsPerValkyrie.putIfAbsent(sId.name, () => {}).add(valkyrieId);
    savePersistentCredits();
  }

  void notifyAsteroidDestroyedForUnlocks() {
    runAsteroidsDestroyed++;
    if (runAsteroidsDestroyed >= 20) {
      unlockWeaponWithToast('graviton_lance');
    }
    if (runAsteroidsDestroyed >= 80) {
      unlockWeaponWithToast('aegis_sawblades');
    }
  }

  void notifyDashExecutedForUnlocks() {
    runDashesExecuted++;
    if (runDashesExecuted >= 15) {
      unlockWeaponWithToast('quantum_teleport');
    }
    if (runDashesExecuted >= 20) {
      unlockWeaponWithToast('quantum_chakram');
    }
  }

  void notifyEnemyKilledForUnlocks([EnemyType type = EnemyType.scout]) {
    runEnemiesKilled++;
    if (type == EnemyType.voidSwarmer) {
      runVoidSwarmerKills++;
      if (runVoidSwarmerKills >= 15) {
        unlockSector(SectorId.xenoHive);
      }
      if (runVoidSwarmerKills >= 20) {
        unlockWeaponWithToast('singularity_cannon');
      }
    }
    if (runEnemiesKilled >= 25) {
      unlockSector(SectorId.graveyard);
    }
    if (runEnemiesKilled >= 30) {
      unlockWeaponWithToast('resonance_shield');
    }
    if (runEnemiesKilled >= 80 &&
        player.unlockedWeapons.containsKey('rapid_fire')) {
      final rf = player.unlockedWeapons['rapid_fire'];
      if (rf != null && rf.level >= 3) {
        unlockWeaponWithToast('tesla_arc');
      }
    }
  }

  void notifyMineDestroyedForUnlocks() {
    runMinesDestroyed++;
    if (runMinesDestroyed >= 5) {
      unlockSector(SectorId.cryoAbyss);
    }
    if (runMinesDestroyed >= 10) {
      unlockWeaponWithToast('void_mines');
    }
  }

  void notifySolarBurnAppliedForUnlocks() {
    runSolarBurnTicks++;
    if (runSolarBurnTicks >= 25) {
      unlockWeaponWithToast('solar_lance');
    }
  }

  void notifyNebulaOverloadSurvivedForUnlocks() {
    unlockWeaponWithToast('repulsor_aura');
  }

  void completeCurrentSectorRun() {
    markSectorCompleted(currentSector.id, selectedValkyrie.id);
    missionSurvived = true;
    campaignCompleted = true;
    addScore(15000);
    addRunCredits(500);
    checkSectorProgressionOnBossDefeated(currentSector.id);
    completeMission(survived: true);
  }

  void loopBackToSector(Sector targetSector) {
    if (state == GameState.starChart) {
      overlays.remove('starChart');
      state = GameState.playing;
      _safeAddOverlay('hud');
      resumeEngine();
      gameFocusNode?.requestFocus();
    }
    currentSector = targetSector;
    timeRemaining = fairRoundDuration;
    voidReaperSpawned = false;
    activeBoss = null;
    beaconsCharged = 0;
    if (asteroidField != null) {
      asteroidField!.difficultyTimer +=
          360.0; // Inimigos e hordas escalonadas para o loop!
    }
    _removeAllAsteroidsAndProjectiles();
    _initSectorPois();
    try {
      spawnFloatingText(
        player.position + Vector2(0, -60),
        '🔄 DOBRA REVERSA: REVISITANDO ${targetSector.name.toUpperCase()} EM LOOP!',
        color: const Color(0xFFFFD700),
        fontSize: 16.0,
      );
      playSfx('powerup.wav');
    } catch (_) {}
  }

  void tryDropBlueprint(Vector2 pos, {bool guaranteed = false}) {
    final unfound = BlueprintDef.allBlueprints
        .where((bp) => !foundBlueprints.contains(bp.weaponId))
        .toList();
    if (unfound.isEmpty) return;
    if (!guaranteed && math.Random().nextDouble() > 0.35) return;

    final bp = unfound.first;
    foundBlueprints.add(bp.weaponId);
    playSfx('powerup.wav');
    spawnFloatingText(
      pos + Vector2(0, -35),
      '📐 DIAGRAMA DESBLOQUEADO: ${bp.name.toUpperCase()}!',
      color: const Color(0xFF00E5FF),
      fontSize: 15.0,
    );
    savePersistentCredits();
  }

  bool forgeBlueprint(String weaponId) {
    final bp = BlueprintDef.findByWeaponId(weaponId);
    if (bp == null) return false;
    if (!foundBlueprints.contains(weaponId) ||
        forgedBlueprints.contains(weaponId)) {
      return false;
    }
    if (totalCredits < bp.forgeCost) return false;

    totalCredits -= bp.forgeCost;
    forgedBlueprints.add(weaponId);
    playSfx('purchase.wav');
    unlockMilestone('ach_blueprint_forge');
    savePersistentCredits();
    return true;
  }

  void unlockMilestone(String id) {
    if (unlockedMilestones.contains(id)) return;
    unlockedMilestones.add(id);
    for (final m in MilestoneAchievement.allMilestones) {
      if (m.id == id) {
        totalCredits += m.scrapReward;
        try {
          spawnFloatingText(
            player.position + Vector2(0, -85),
            '🏆 CONQUISTA: ${m.title} (+${m.scrapReward} SUCATA)',
            color: const Color(0xFFFFD700),
            fontSize: 15.5,
          );
        } catch (_) {}
        break;
      }
    }
    savePersistentCredits();
  }

  void applyPilotMutation(String mutationId) {
    if (activeMutations.contains(mutationId) || activeMutations.length >= 3) {
      return;
    }
    activeMutations.add(mutationId);
    switch (mutationId) {
      case 'mut_lone_wolf':
        rogueDamageMultiplier += 0.45;
        break;
      case 'mut_scrap_alchemist':
        rogueCritChance = (rogueCritChance + 0.08).clamp(0.0, 1.0);
        break;
      case 'mut_elemental_overload':
        rogueDamageMultiplier += 0.25;
        break;
    }
  }

  void spawnWingmanBullet({
    required Vector2 position,
    required Vector2 velocity,
    required double damage,
    required bool isEvolved,
  }) {
    world.add(
      BulletComponent(
        position: position,
        radius: isEvolved ? 3.5 : 2.5,
        velocity: velocity,
        lifeTimer: 0.75,
        damage: damage * rogueDamageMultiplier,
        color: isEvolved ? const Color(0xFFFFD700) : const Color(0xFF00E5FF),
        elementalStatus: isEvolved
            ? ElementalStatus.ionShock
            : ElementalStatus.none,
      ),
    );
  }

  // Sistema Híbrido (Vampire Survivors + Risk of Rain): Sinalizadores de Anomalia
  int beaconsCharged = 0;
  static const int requiredBeacons = 2;
  bool get isBossAltarUnlocked => beaconsCharged >= requiredBeacons;

  void chargeBossBeacon(String sourceLabel) {
    if (state != GameState.playing) return;
    beaconsCharged++;
    if (beaconsCharged == requiredBeacons) {
      sectorMap?.bossLairNode.isDiscovered = true;
      playSfx('powerup.wav');
      triggerScreenShake(duration: 0.8, intensity: 16.0);
      spawnFloatingText(
        player.position + Vector2(0, -65),
        '🔓 SINALIZADORES COMPLETOS ($beaconsCharged/$requiredBeacons)! ALTAR DO TITÃ DESTRANCADO!',
        color: const Color(0xFF00E676),
        fontSize: 16.5,
      );
    } else if (beaconsCharged < requiredBeacons) {
      spawnFloatingText(
        player.position + Vector2(0, -55),
        '📡 SINALIZADOR DE ANOMALIA CARREGADO ($beaconsCharged/$requiredBeacons) [$sourceLabel]',
        color: const Color(0xFF00E5FF),
        fontSize: 14.5,
      );
    }
  }

  GameState state = GameState.scienceIntro;
  String activeMode = 'arcade'; // 'arcade', 'classic' or 'campaign'

  // Astra Valkyrie Pilot
  Valkyrie selectedValkyrie = Valkyrie.defaultValkyrie;
  Sector currentSector = Sector.defaultSector;
  final Set<String> activePassives = {};
  double rogueCritChance = 0.05;
  double rogueFireRateMultiplier = 1.0;
  double rogueDamageMultiplier = 1.0;
  double rogueMagnetRadius = 150.0;

  void addStardust(int amount) => addXp(amount);
  void addScrap(int amount) {
    final voidCellMult = 1.0 + (voidCellsLevel * 0.25);
    final effective = ((isHyperMode ? amount * 1.5 : amount) * voidCellMult)
        .round();
    runCredits += effective;
    totalCredits += effective;
    if (activeMutations.contains('mut_scrap_alchemist')) {
      try {
        player.heal(0.5);
      } catch (_) {}
    }
    savePersistentCredits();
  }

  // Science Fair mode properties (legacy compatibility)
  Scientist selectedScientist = Scientist.defaultScientist;
  static const double fairRoundDuration = 180.0; // 3 minutes
  double timeRemaining = fairRoundDuration;
  bool missionSurvived = false;
  String? participantName;

  // Feature 1: Special Ability & HoloCure Ultimate Charge System
  bool specialAvailable = true;
  double ultimateCharge = 1.0;
  static const double ultimateChargeMax = 1.0;
  double ultimateChargeRate = 1.0 / 40.0; // 40s recarga passiva

  // Sprint 42: Apresentação Cinematográfica de Chefes
  final ValueNotifier<BossCinematicData?> bossCinematicNotifier = ValueNotifier(
    null,
  );

  void triggerBossCinematicIntro({
    required String title,
    required String subtitle,
    Color color = const Color(0xFFFF1744),
  }) {
    playSfx('boss_spawn.wav');
    triggerScreenShake(duration: 0.85, intensity: 20.0);
    setCameraZoom(1.12);
    bossCinematicNotifier.value = BossCinematicData(
      title: title,
      subtitle: subtitle,
      color: color,
    );
    Future.delayed(const Duration(milliseconds: 2800), () {
      if (bossCinematicNotifier.value?.title == title) {
        bossCinematicNotifier.value = null;
        setCameraZoom(1.0);
      }
    });
  }

  void gainUltimateCharge(double amount) {
    if (state != GameState.playing || specialAvailable) return;
    ultimateCharge = (ultimateCharge + amount).clamp(0.0, 1.0);
    if (ultimateCharge >= 1.0) {
      specialAvailable = true;
      playSfx('ultimate_ready.wav');
      try {
        spawnFloatingText(
          player.position + Vector2(0, -42),
          '⚡ ULTIMATE PRONTA! [SPACE]',
          color: const Color(0xFFFFD700),
          fontSize: 15.0,
        );
      } catch (_) {}
    }
  }

  // Feature 2: Scientific Samples Collected
  int samplesCollected = 0;

  // Feature 3: Target Leader Record
  String? topLeaderName;
  int topLeaderScore = 0;
  bool topRecordBeaten = false;

  // Feature 4: Surprise Celestial Event (Comet Halley Flyby)
  bool cometWarningTriggered = false;
  bool cometSpawned = false;
  double cometAlertTimer = 0.0;
  String? cometAlertMessage;

  // Roguelike In-Run Progression (XP & Escolha de Cartas)
  int runLevel = 1;
  int runXp = 0;
  int runXpNextLevel = 30;
  List<RoguePerk> currentLevelUpChoices = [];

  static int calculateNextLevelXp(int level) {
    return 24 + (level - 1) * 28 + (level * level * 6);
  }

  void addXp(int amount) {
    if (state != GameState.playing) return;
    gainUltimateCharge(amount * 0.003);
    final effective = isHyperMode ? (amount * 1.5).round() : amount;
    runXp += effective;
    if (runXp >= runXpNextLevel) {
      runXp -= runXpNextLevel;
      runLevel++;
      runXpNextLevel = calculateNextLevelXp(runLevel);
      triggerLevelUp();
    }
  }

  // Vampire Survivors Red Gem Siphon (Max 60 XP orbs on screen)
  void spawnXpOrb(Vector2 position, XpOrbType type, [int? customValue]) {
    final existingOrbs = world.children.whereType<XpOrbComponent>().toList();
    if (existingOrbs.length >= 60) {
      XpOrbComponent furthest = existingOrbs.first;
      double maxDistSq = -1.0;
      for (final o in existingOrbs) {
        final dSq = o.position.distanceToSquared(player.position);
        if (dSq > maxDistSq) {
          maxDistSq = dSq;
          furthest = o;
        }
      }
      final incomingValue =
          customValue ??
          (type == XpOrbType.large ? 14 : (type == XpOrbType.medium ? 6 : 2));
      furthest.absorbXp(incomingValue);
      return;
    }

    world.add(
      XpOrbComponent(position: position, type: type, customValue: customValue),
    );
  }

  void triggerLevelUp() {
    // Sprint 26: Tomo de Fusão Térmica concede permanentemente +1 escolha no Level-Up (4 em vez de 3)
    final choiceCount = unlockedRelics.contains('thermal_tome') ? 4 : 3;
    currentLevelUpChoices = RoguePerkGenerator.generateChoices(
      this,
      count: choiceCount,
    );

    // Sprint 25 & 27: Condições de nível estilo Vampire Survivors
    if (runLevel >= 8 && currentSector.id == SectorId.vesta) {
      unlockSector(SectorId.orion);
    }
    if (runLevel >= 8 && currentSector.id == SectorId.orion) {
      unlockWeaponWithToast('solar_lance');
    }
    if (runLevel >= 10 && selectedValkyrie.id == 'selene') {
      unlockSector(SectorId.cryoAbyss);
    }

    playSfx('powerup.wav');
    triggerScreenShake(duration: 0.35, intensity: 7.0);
    pauseEngine();
    state = GameState.levelUp;
    _safeAddOverlay('levelUp');
  }

  void selectLevelUpPerk(RoguePerk perk) {
    perk.onSelect(this);
    playSfx('purchase.wav');
    overlays.remove('levelUp');
    state = GameState.playing;
    _safeAddOverlay('hud');
    resumeEngine();
    gameFocusNode?.requestFocus();
  }

  // Sprint 54: Agência de Level-Up estilo Vampire Survivors (Reroll, Banish, Skip)
  int runRerollsRemaining = 0;
  int runBanishesRemaining = 0;
  final Set<String> runBanishedPerkIds = {};

  bool rerollLevelUpChoices() {
    if (runRerollsRemaining <= 0) return false;
    runRerollsRemaining--;
    playSfx('purchase.wav');
    currentLevelUpChoices = RoguePerkGenerator.generateChoices(this, count: 3);
    return true;
  }

  bool banishLevelUpPerk(RoguePerk perk) {
    if (runBanishesRemaining <= 0) return false;
    runBanishesRemaining--;
    runBanishedPerkIds.add(perk.id);
    playSfx('bomb_explode.wav');
    currentLevelUpChoices = RoguePerkGenerator.generateChoices(this, count: 3);
    return true;
  }

  void skipLevelUp() {
    playSfx('powerup.wav');
    if (player.hp < player.maxHp) {
      player.heal(35.0);
      try {
        spawnFloatingText(
          player.position + Vector2(0, -20),
          '+35 HP',
          color: const Color(0xFF00E676),
          fontSize: 13.0,
        );
      } catch (_) {}
    }
    state = GameState.playing;
    addRunCredits(50);
    try {
      overlays.remove('levelUp');
      _safeAddOverlay('hud');
      resumeEngine();
      gameFocusNode?.requestFocus();
    } catch (_) {}
  }

  // Vampire Survivors Dopamine Chest & Jackpot Rewards
  List<ChestReward> currentChestRewards = [];

  void onChestCollected(ChestTier tier) {
    currentChestRewards.clear();

    // Roll count of items using Vampire Survivors math & luck
    int itemCount;
    switch (tier) {
      case ChestTier.cosmic:
        itemCount = 5;
        break;
      case ChestTier.gold:
        final luckBonus =
            (rogueCritChance * 0.5) + metaProgression.jackpotChanceBonus;
        final roll = math.Random().nextDouble();
        if (roll < 0.12 + luckBonus) {
          itemCount = 5;
        } else {
          itemCount = 3;
        }
        break;
      case ChestTier.silver:
        final roll = math.Random().nextDouble();
        final luckBonus = metaProgression.jackpotChanceBonus;
        if (roll < 0.20 + luckBonus) {
          itemCount = 3;
        } else {
          itemCount = 1;
        }
        break;
    }

    currentChestRewards = _generateChestRewards(itemCount);
    if (itemCount >= 3) {
      AchievementService.unlock('lucky_jackpot');
    }

    pauseEngine();
    _safeAddOverlay('chest');
  }

  List<ChestReward> _generateChestRewards(int count) {
    final List<ChestReward> list = [];
    final random = math.Random();

    // 1. TOP PRIORITY: SUPER-EVOLUTION of MK MAX Weapons (Vampire Survivors Super-Weapon Loop)
    for (final w in player.activeWeapons) {
      if (w.canEvolve) {
        for (final syn in WeaponSynergy.allSynergies) {
          if (syn.weaponId == w.id) {
            w.evolvedName ??= syn.evolvedName;
          }
        }
      }
    }
    final evolvableWeapons = player.activeWeapons
        .where((w) => w.canEvolve)
        .toList();
    for (final w in evolvableWeapons) {
      if (list.length >= count) break;
      final targetW = w;
      final evoName = targetW.evolvedName ?? '${targetW.name} OVERDRIVE';
      list.add(
        ChestReward(
          title: 'SUPER-EVOLUTION // $evoName',
          subtitle: 'Ultimate Tier Reached: Cataclysmic Firepower Engaged!',
          icon: Icons.auto_awesome,
          color: const Color(0xFFFFD700),
          apply: () {
            targetW.evolve();
            unlockMilestone('ach_superweapon');
            triggerSpeechBubble(SpeechTrigger.superWeapon);
          },
        ),
      );
    }

    // 2. Regular Weapon Upgrades (MK 1 -> MK 2 -> MK 3)
    final upgradableWeapons = player.activeWeapons
        .where((w) => w.level < w.maxLevel)
        .toList();
    for (final w in upgradableWeapons) {
      if (list.length >= count) break;
      final targetW = w;
      list.add(
        ChestReward(
          title: '${targetW.name} MK ${targetW.level + 1}',
          subtitle:
              'Arsenal Upgrade: Weapon enhanced to MK ${targetW.level + 1}',
          icon: Icons.military_tech,
          color: const Color(0xFFFFB300),
          apply: () {
            targetW.upgrade();
          },
        ),
      );
    }

    // 2. Extra Stat Overchargers and XP Bounties
    while (list.length < count) {
      final roll = random.nextDouble();
      if (roll < 0.35) {
        list.add(
          ChestReward(
            title: 'Stardust Bounty',
            subtitle: '+60 Instant Stardust XP',
            icon: Icons.bolt,
            color: const Color(0xFF00E5FF),
            apply: () {
              addXp(60);
            },
          ),
        );
      } else if (roll < 0.65) {
        list.add(
          ChestReward(
            title: 'Hull Overcharge',
            subtitle: '+1 Pilot Life restored',
            icon: Icons.favorite,
            color: const Color(0xFFFF1744),
            apply: () {
              lives = math.min(GameConstants.playerLives + 1, lives + 1);
            },
          ),
        );
      } else {
        list.add(
          ChestReward(
            title: 'Photonic Core Amp',
            subtitle: '+15% Global Fire Rate & +10% Crit',
            icon: Icons.speed,
            color: const Color(0xFFE040FB),
            apply: () {
              rogueFireRateMultiplier *= 0.88;
              rogueCritChance = (rogueCritChance + 0.10).clamp(0.0, 1.0);
            },
          ),
        );
      }
    }

    return list;
  }

  void claimChestRewards() {
    for (final reward in currentChestRewards) {
      reward.apply();
    }
    currentChestRewards.clear();
    overlays.remove('chest');
    resumeEngine();
    playSfx('menu_select.wav');
    gameFocusNode?.requestFocus();
  }

  // Feature 6: Launch Transmission Dialogue Box
  bool showLaunchTransmission = false;
  double launchTransmissionTimer = 0.0;

  void dismissLaunchTransmission() {
    showLaunchTransmission = false;
  }

  // Settings selections
  int selectedMovementPresetIndex = 1; // 1 = Balanced
  int selectedWeaponIndex = 0; // 0 = Blaster

  int score = 0;
  int _lives = GameConstants.playerLives;
  int get lives {
    try {
      if (player.hp <= 0) return 0;
      final maxLives =
          GameConstants.playerLives + metaProgression.hullBonusLives;
      return (player.hp / math.max(1.0, player.maxHp) * maxLives).ceil().clamp(
        1,
        maxLives,
      );
    } catch (_) {
      return _lives;
    }
  }

  set lives(int val) => _lives = val;
  int currentLevel = 1;

  // Roguelite Meta-Progression & Scrap Economy
  final MetaProgression metaProgression = MetaProgression();
  final AffinityManager affinityManager = AffinityManager();
  int totalCredits = 0; // Bank balance across runs
  int runCredits = 0; // Scrap collected during current sortie

  int get credits => totalCredits;
  set credits(int val) => totalCredits = val;

  double shakeTimer = 0.0;
  double shakeDuration = 0.0;
  double shakeIntensity = 0.0;
  double hitStopTimer = 0.0;

  // SPRINT 57: Universal Special / Ultimate Input Buffering (120ms)
  double specialBufferTimer = 0.0;
  static const double inputBufferWindow = 0.12;

  void requestSpecial() {
    if (specialAvailable && state == GameState.playing) {
      specialBufferTimer = 0.0;
      triggerSpecial();
    } else {
      specialBufferTimer = inputBufferWindow;
    }
  }

  /// SPRINT 57: Hit-Stop Escalonado por Severidade de Dano (Hades Standard)
  /// - Tiro comum: 0ms (fluidez contínua)
  /// - Dano moderado (>= 45): 35ms
  /// - Acerto crítico / lâmina: 70ms com tremor direcional
  /// - Abate de Elite / Golpe Finalizador: 140ms
  void triggerScaledHitStop({
    required double damage,
    bool isCrit = false,
    bool isEliteKill = false,
    Vector2? impactDir,
  }) {
    double duration = 0.0;
    if (isEliteKill) {
      duration = 0.14;
      triggerScreenShake(duration: 0.35, intensity: 14.0);
    } else if (isCrit) {
      duration = 0.07;
      triggerScreenShake(duration: 0.20, intensity: 8.0);
    } else if (damage >= 45.0) {
      duration = 0.035;
    }

    if (duration > 0) {
      hitStopTimer = math.max(hitStopTimer, duration);
    }
  }

  // Sprint 50: Painel de Mixagem de Áudio
  double masterVolume = 1.0;
  double sfxVolume = 1.0;
  double bgmVolume = 0.8;

  // Sprint 52: Zoom Dinâmico de Câmera de Combate
  double targetCameraZoom = 1.0;

  void setCameraZoom(double zoom) {
    targetCameraZoom = zoom.clamp(0.8, 1.5);
  }

  double get effectiveBgmVolume => (bgmVolume * masterVolume).clamp(0.0, 1.0);

  void updateAudioMix({double? master, double? sfx, double? bgm}) {
    if (master != null) masterVolume = master.clamp(0.0, 1.0);
    if (sfx != null) sfxVolume = sfx.clamp(0.0, 1.0);
    if (bgm != null) bgmVolume = bgm.clamp(0.0, 1.0);

    try {
      if (FlameAudio.bgm.isPlaying) {
        FlameAudio.bgm.audioPlayer
            .setVolume(effectiveBgmVolume)
            .catchError((_) {});
      }
    } catch (_) {}
    saveAudioSettings();
  }

  Future<void> saveAudioSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('audio_master_volume', masterVolume);
      await prefs.setDouble('audio_sfx_volume', sfxVolume);
      await prefs.setDouble('audio_bgm_volume', bgmVolume);
    } catch (_) {}
  }

  Future<void> loadAudioSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      masterVolume = prefs.getDouble('audio_master_volume') ?? 1.0;
      sfxVolume = prefs.getDouble('audio_sfx_volume') ?? 1.0;
      bgmVolume = prefs.getDouble('audio_bgm_volume') ?? 0.8;
    } catch (_) {}
  }

  double lowHealthWarnTimer = 0.0;

  String? playerId;
  String? playerUsername;

  // Preset definitions
  final List<MovementPreset> movementPresets = [
    MovementPreset("Arcade Tight", 700.0, 220.0, 5.0),
    MovementPreset("Balanced", 650.0, 250.0, 4.0),
    MovementPreset("Floaty Classic", 450.0, 320.0, 2.0),
  ];

  final List<String> weaponOptions = [
    "Laser Fotônico",
    "Tiro Dispersor",
    "Laser Veloz",
    "Lança-Bombas",
  ];

  @override
  Color backgroundColor() => Colors.black;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Lock camera resolution to 1280x720 (matching Pygame coordinates)
    camera.viewport = FixedResolutionViewport(resolution: Vector2(1280, 720));
    camera.viewfinder.position = Vector2(
      GameConstants.sectorWidth / 2,
      GameConstants.sectorHeight / 2,
    );
    camera.viewfinder.anchor = Anchor.center;

    // Setup FlameAudio asset folder configuration and silence native warning spam on Linux
    try {
      AudioLogger.logLevel = AudioLogLevel.none;
      FlameAudio.updatePrefix('assets/sounds/');
      await FlameAudio.bgm.initialize();
    } catch (_) {}

    try {
      initSfxPlayers();
      await loadAudioSettings();
    } catch (_) {}

    // Add StarfieldComponent, SectorBoundaryComponent, and Sector POIs first
    world.add(StarfieldComponent());
    world.add(DistantMegastructureBackdropComponent());
    world.add(ProceduralCosmicNebulaComponent());
    world.add(KineticSpaceDustComponent());
    world.add(SpaceTimeWarpGridComponent());
    world.add(SectorBoundaryComponent());
    world.add(particlePool);
    _initSectorPois();

    // Add PlayerComponent (starts in center of the large sector)
    player = PlayerComponent(
      position: Vector2(
        GameConstants.sectorWidth / 2,
        GameConstants.sectorHeight / 2,
      ),
    )..customGame = this;
    world.add(player);

    // Add Joystick for mobile/touch/mouse controls
    joystick = GameJoystick();
    add(joystick);

    // Load local player profile
    try {
      final profile = await ApiService.getLocalProfile();
      if (profile != null) {
        playerId = profile['id'];
        playerUsername = profile['username'];
      }
    } catch (_) {}

    // Load persistent meta-progression upgrades and account scrap bank
    try {
      await metaProgression.loadFromPrefs();
      await affinityManager.loadFromPrefs();
      await loadPersistentDataFromPrefs();
    } catch (_) {}

    // Register global hardware keyboard handler for instant pause detection
    HardwareKeyboard.instance.addHandler(_handleGlobalKeyEvent);

    // Initial state set for Astra Valkyries (Bootloader + Main Title Menu)
    changeState(GameState.menu);
  }

  Future<void> loadPersistentDataFromPrefs() async {
    try {
      await I18n.init();
      await SecretGrimoireService.init();
      final prefs = await SharedPreferences.getInstance();
      totalCredits = prefs.getInt('persistent_credits') ?? 0;
      hyperModeUnlocked = prefs.getBool('hyper_mode_unlocked') ?? true;
      voidCellsLevel = prefs.getInt('void_cells_level') ?? 0;
      maxUnlockedVoidCells = prefs.getInt('max_unlocked_void_cells') ?? 1;
      selectedMovementPresetIndex = prefs.getInt('movement_preset_index') ?? 1;
      useDirectionalControls =
          prefs.getBool('use_directional_controls') ?? false;
      showFpsOverlay = prefs.getBool('show_fps_overlay') ?? false;
      final savedFoundBp = prefs.getStringList('found_blueprints');
      if (savedFoundBp != null) foundBlueprints.addAll(savedFoundBp);
      final savedForgedBp = prefs.getStringList('forged_blueprints');
      if (savedForgedBp != null) forgedBlueprints.addAll(savedForgedBp);
      final savedMilestones = prefs.getStringList('unlocked_milestones');
      if (savedMilestones != null) unlockedMilestones.addAll(savedMilestones);

      final savedSectors = prefs.getStringList('unlocked_sectors');
      if (savedSectors != null && savedSectors.isNotEmpty) {
        for (final sName in savedSectors) {
          try {
            unlockedSectors.add(SectorId.values.byName(sName));
          } catch (_) {}
        }
      }
      final savedRelics = prefs.getStringList('unlocked_relics');
      if (savedRelics != null) unlockedRelics.addAll(savedRelics);
      final savedSecrets = prefs.getStringList('rescued_sector_secrets');
      if (savedSecrets != null) {
        for (final sName in savedSecrets) {
          try {
            rescuedSectorSecrets.add(SectorId.values.byName(sName));
          } catch (_) {}
        }
      }
      final savedWeaponPool = prefs.getStringList('unlocked_weapon_pool');
      if (savedWeaponPool != null && savedWeaponPool.isNotEmpty) {
        unlockedWeaponPool.addAll(savedWeaponPool);
      }
      for (final sId in SectorId.values) {
        final list = prefs.getStringList('completed_sector_${sId.name}');
        if (list != null && list.isNotEmpty) {
          completedSectorsPerValkyrie[sId.name] = list.toSet();
        }
      }
    } catch (_) {}
  }

  Future<void> saveHyperModeState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('hyper_mode_unlocked', hyperModeUnlocked);
    } catch (_) {}
  }

  Future<void> toggleFpsOverlay(bool value) async {
    showFpsOverlay = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('show_fps_overlay', value);
    } catch (_) {}
  }

  void addRunCredits(int amount) {
    if (state != GameState.playing) return;
    final voidCellMult = 1.0 + (voidCellsLevel * 0.25);
    final effective = ((isHyperMode ? amount * 1.5 : amount) * voidCellMult)
        .round();
    runCredits += effective;
    if (activeMutations.contains('mut_scrap_alchemist')) {
      try {
        player.heal(0.5);
      } catch (_) {}
    }
  }

  bool purchaseMetaUpgrade(String id) {
    final success = metaProgression.purchase(id, (cost) {
      totalCredits -= cost;
      savePersistentCredits();
    });
    if (success) {
      playSfx('purchase.wav');
    }
    return success;
  }

  void refundMetaUpgrades() {
    metaProgression.refundAll((refund) {
      totalCredits += refund;
      savePersistentCredits();
    });
    playSfx('menu_select.wav');
  }

  Future<void> savePersistentCredits() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('persistent_credits', totalCredits);
      await prefs.setInt('void_cells_level', voidCellsLevel);
      await prefs.setInt('max_unlocked_void_cells', maxUnlockedVoidCells);
      await prefs.setInt('movement_preset_index', selectedMovementPresetIndex);
      await prefs.setBool('use_directional_controls', useDirectionalControls);
      await prefs.setStringList('found_blueprints', foundBlueprints.toList());
      await prefs.setStringList('forged_blueprints', forgedBlueprints.toList());
      await prefs.setStringList(
        'unlocked_milestones',
        unlockedMilestones.toList(),
      );

      // Fase 4: Persistência de Setores, Relíquias, Segredos e Armas Desbloqueadas
      await prefs.setStringList(
        'unlocked_sectors',
        unlockedSectors.map((s) => s.name).toList(),
      );
      await prefs.setStringList('unlocked_relics', unlockedRelics.toList());
      await prefs.setStringList(
        'rescued_sector_secrets',
        rescuedSectorSecrets.map((s) => s.name).toList(),
      );
      await prefs.setStringList(
        'unlocked_weapon_pool',
        unlockedWeaponPool.toList(),
      );
      for (final entry in completedSectorsPerValkyrie.entries) {
        await prefs.setStringList(
          'completed_sector_${entry.key}',
          entry.value.toList(),
        );
      }
    } catch (_) {}
  }

  DateTime? _lastPauseToggleTime;

  bool _handleGlobalKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return false;

    if (state == GameState.playing && showLaunchTransmission) {
      showLaunchTransmission = false;
    }

    final key = event.logicalKey;
    final isPauseKey =
        key == LogicalKeyboardKey.escape ||
        key == LogicalKeyboardKey.keyP ||
        key == LogicalKeyboardKey.gameButtonStart;

    if (state == GameState.playing && isPauseKey) {
      togglePause();
      return true;
    }
    if (state == GameState.playing &&
        key == LogicalKeyboardKey.gameButtonSelect) {
      toggleTacticalMap();
      return true;
    }
    return false;
  }

  void changeState(GameState newState) {
    if (state == GameState.menu || state == GameState.valkyrieSelection) {
      previousMenuState = state;
    }
    state = newState;
    keysPressed.clear();

    if (newState == GameState.playing) {
      gameFocusNode?.requestFocus();
    } else {
      gameFocusNode?.unfocus();
    }

    // Clear active overlays first
    try {
      overlays.clear();
    } catch (_) {}

    switch (newState) {
      case GameState.valkyrieSelection:
        _safeAddOverlay('valkyrieSelection');
        try {
          camera.stop();
          camera.viewfinder.position = Vector2(
            GameConstants.sectorWidth / 2,
            GameConstants.sectorHeight / 2,
          );
        } catch (_) {}
        try {
          if (!FlameAudio.bgm.isPlaying) {
            FlameAudio.bgm.play('music.wav', volume: 0.65).catchError((_) {});
          }
        } catch (_) {}
        _removeAllAsteroidsAndProjectiles();
        break;
      case GameState.scienceIntro:
        _safeAddOverlay('scienceIntro');
        try {
          if (!FlameAudio.bgm.isPlaying) {
            FlameAudio.bgm.play('music.wav', volume: 0.65).catchError((_) {});
          }
        } catch (_) {}
        _removeAllAsteroidsAndProjectiles();
        break;
      case GameState.scientistSelection:
        _safeAddOverlay('scientistSelection');
        try {
          if (!FlameAudio.bgm.isPlaying) {
            FlameAudio.bgm.play('music.wav', volume: 0.65).catchError((_) {});
          }
        } catch (_) {}
        _removeAllAsteroidsAndProjectiles();
        break;
      case GameState.menu:
        _safeAddOverlay('menu');
        try {
          camera.stop();
          camera.viewfinder.position = Vector2(
            GameConstants.sectorWidth / 2,
            GameConstants.sectorHeight / 2,
          );
        } catch (_) {}
        try {
          if (!FlameAudio.bgm.isPlaying) {
            FlameAudio.bgm.play('music.wav', volume: 0.65).catchError((_) {});
          }
        } catch (_) {}
        _removeAllAsteroidsAndProjectiles();
        break;
      case GameState.settings:
        _safeAddOverlay('settings');
        _removeAllAsteroidsAndProjectiles();
        break;
      case GameState.playing:
        _safeAddOverlay('hud');
        // Play loop background music
        try {
          FlameAudio.bgm.play('music.wav', volume: 0.85).catchError((_) {});
        } catch (_) {}
        gameFocusNode?.requestFocus();
        break;
      case GameState.shop:
        _safeAddOverlay('shop');
        break;
      case GameState.stageClear:
        _safeAddOverlay('stageClear');
        _removeAllAsteroidsAndProjectiles();
        break;
      case GameState.gameOver:
        _safeAddOverlay('gameOver');
        try {
          FlameAudio.bgm.stop();
        } catch (_) {}
        playSfx('game_over.wav');
        _removeAllAsteroidsAndProjectiles();
        break;
      case GameState.leaderboard:
        _safeAddOverlay('leaderboard');
        try {
          if (!FlameAudio.bgm.isPlaying) {
            FlameAudio.bgm.play('music.wav', volume: 0.6).catchError((_) {});
          }
        } catch (_) {}
        _removeAllAsteroidsAndProjectiles();
        break;
      case GameState.levelUp:
        _safeAddOverlay('levelUp');
        break;
      case GameState.starChart:
        _safeAddOverlay('starChart');
        break;
    }
  }

  void _safeAddOverlay(String name) {
    try {
      overlays.add(name);
    } catch (_) {}
  }

  bool isGamePaused = false;

  void togglePause() {
    if (state != GameState.playing) return;
    final now = DateTime.now();
    if (_lastPauseToggleTime != null &&
        now.difference(_lastPauseToggleTime!).inMilliseconds < 300) {
      return;
    }
    _lastPauseToggleTime = now;

    if (isGamePaused) {
      resumeGame();
    } else {
      pauseGame();
    }
  }

  void pauseGame() {
    if (state != GameState.playing || isGamePaused) return;
    _lastPauseToggleTime = DateTime.now();
    isGamePaused = true;
    keysPressed.clear();
    pauseEngine();
    _safeAddOverlay('pause');
  }

  void resumeGame() {
    if (!isGamePaused) return;
    _lastPauseToggleTime = DateTime.now();
    isGamePaused = false;
    keysPressed.clear();
    overlays.remove('pause');
    resumeEngine();
    gameFocusNode?.requestFocus();
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    if (state != GameState.playing) {
      this.keysPressed.clear();
      return KeyEventResult.ignored;
    }

    if (showLaunchTransmission && keysPressed.isNotEmpty) {
      showLaunchTransmission = false;
    }

    // Mapa Tático Holográfico em Tela Cheia [Tecla M]
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.keyM) {
      toggleTacticalMap();
      return KeyEventResult.handled;
    }

    this.keysPressed.clear();
    this.keysPressed.addAll(keysPressed);
    return KeyEventResult.handled;
  }

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    if (state == GameState.playing) {
      if (showLaunchTransmission) {
        showLaunchTransmission = false;
      }
      player.shoot();
    }
  }

  void startGame() {
    score = 0;
    runCredits = 0;
    currentLevel = 1;
    specialAvailable = true;
    samplesCollected = 0;
    runLevel = 1;
    runXp = 0;
    runXpNextLevel = calculateNextLevelXp(1);
    currentLevelUpChoices = [];
    missionSurvived = false;
    campaignCompleted = false;
    bossRushStage = 0;
    beaconsCharged = 0;
    timeRemaining = fairRoundDuration;
    try {
      player.resetRoguelikeStats();
    } catch (_) {}
    topRecordBeaten = false;
    cometWarningTriggered = false;
    cometSpawned = false;
    cometAlertTimer = 0.0;
    cometAlertMessage = null;
    showLaunchTransmission = true;
    launchTransmissionTimer = 5.0;
    fetchTopLeaderRecord();

    // Roguelike run stats from selected Valkyrie + Meta Upgrades
    activePassives.clear();
    activeMutations.clear();
    flawlessBossKill = true;
    runRerollsRemaining = metaProgression.rerollsCount;
    runBanishesRemaining = metaProgression.banishCount;
    runBanishedPerkIds.clear();

    // Sprint 27: Reseta contadores de feitos da run
    runAsteroidsDestroyed = 0;
    runDashesExecuted = 0;
    runEnemiesKilled = 0;
    runVoidSwarmerKills = 0;
    runMinesDestroyed = 0;
    runSolarBurnTicks = 0;

    // Sprint 26: Relíquia Matriz de Mutação Inicial concede 1 Mutação gratuita na decolagem!
    if (unlockedRelics.contains('mutation_matrix') &&
        PilotMutation.allMutations.isNotEmpty) {
      final muts = PilotMutation.allMutations.toList()..shuffle();
      applyPilotMutation(muts.first.id);
    }
    rogueCritChance =
        (selectedValkyrie.critChance + metaProgression.critChanceBonus).clamp(
          0.0,
          1.0,
        );
    rogueDamageMultiplier = 1.0 + metaProgression.damageBonusMultiplier;
    rogueFireRateMultiplier = 1.0;
    rogueMagnetRadius =
        (150.0 * selectedValkyrie.magnetRadiusMultiplier) *
        metaProgression.magnetMultiplier;

    // Remove any running level manager or asteroid field
    if (levelManager != null) {
      levelManager = null;
    }
    if (asteroidField != null) {
      asteroidField!.removeFromParent();
      asteroidField = null;
    }
    _removeAllAsteroidsAndProjectiles();

    // Reset player states, stats, and initialize chosen Valkyrie's starting weapon at Sector Center
    player.customGame ??= this;
    player.valkyrie = selectedValkyrie;
    player.respawn(
      GameConstants.sectorWidth / 2,
      GameConstants.sectorHeight / 2,
    );
    player.initHp();
    try {
      camera.viewfinder.position = player.position;
      camera.follow(player);
    } catch (_) {}

    // Set starting weapon based on chosen Valkyrie
    final startingWeapon = selectedValkyrie.createStartingWeapon();
    player.setWeapon(startingWeapon);

    // Apply movement stats based on pilot speed multiplier + meta-progression thrusters + bond bonus
    final preset = movementPresets[selectedMovementPresetIndex];
    final affinity = affinityManager.getAffinity(selectedValkyrie.id);
    final hyperSpeedMult = isHyperMode ? 1.25 : 1.0;
    player.movementAcceleration =
        preset.acceleration *
        selectedValkyrie.speedMultiplier *
        metaProgression.speedMultiplier *
        (1.0 + affinity.bondSpeedBonus) *
        hyperSpeedMult;
    player.movementMaxSpeed =
        preset.maxSpeed *
        selectedValkyrie.speedMultiplier *
        metaProgression.speedMultiplier *
        (1.0 + affinity.bondSpeedBonus) *
        hyperSpeedMult;
    player.movementFriction = preset.friction;
    player.magnetRadius = rogueMagnetRadius;
    rogueCritChance =
        (selectedValkyrie.critChance +
                metaProgression.critChanceBonus +
                affinity.bondCritBonus)
            .clamp(0.0, 1.0);

    // Setup Spawning Mode (Continuous void field for roguelike protocol)
    asteroidField = AsteroidField();
    world.add(asteroidField!);

    _initSectorPois();

    changeState(GameState.playing);
    primordialSovereignDefeated = false;
    lastTriggeredEnding = EndingType.none;
    triggerSpeechBubble(SpeechTrigger.hyperspaceJump);

    if (isBossRushMode) {
      _spawnBossRushStage(0);
    }
  }

  void _removeAllAsteroidsAndProjectiles() {
    // 1. Remove qualquer gerador de meteoros (AsteroidField / LevelManager)
    final fieldsToRemove = world.children.whereType<AsteroidField>();
    for (final f in List<AsteroidField>.from(fieldsToRemove)) {
      f.removeFromParent();
    }
    asteroidField = null;

    if (levelManager != null) {
      levelManager = null;
    }

    // 2. Remove todas as entidades dinâmicas de jogo
    final childrenToRemove = world.children.where(
      (child) =>
          child is AsteroidComponent ||
          child is BulletComponent ||
          child is BombComponent ||
          child is BombExplosionComponent ||
          child is ParticleComponent ||
          child is FloatingTextComponent ||
          child is DropComponent ||
          child is XpOrbComponent ||
          child is EnemyShipComponent ||
          child is EnemyBulletComponent ||
          child is ChestComponent ||
          child is MagmaHazardComponent ||
          child is SingularityRiftComponent ||
          child is ProximityMineComponent ||
          child is DerelictTurretComponent ||
          child is OrbitalSawbladeComponent ||
          child is TeslaLightningComponent ||
          child is ChakramProjectileComponent ||
          child is GravityAuraPulseComponent ||
          child is ThermalLanceBeamComponent ||
          child is WingmanDroneComponent ||
          child is PlayerClusterMineComponent ||
          child is MegastructureWallComponent ||
          child is LaserContainmentGateComponent ||
          child is TimedVaultComponent ||
          child is FlawlessVaultComponent ||
          child is VoidMerchantComponent ||
          child is CursedShrineComponent ||
          child is CryoMistZoneComponent ||
          child is CryoMineComponent ||
          child is OrganicBiomassWallComponent ||
          child is XenoCocoonComponent ||
          child is SpeechBubbleComponent ||
          child is SectorBoss ||
          child is HyperspaceGateComponent ||
          child is VoidReaperComponent,
    );
    for (final child in List.from(childrenToRemove)) {
      child.removeFromParent();
    }
    activeBoss = null;
    voidReaperSpawned = false;
    particlePool.clear();
    activeEnemies.clear();
    activeAsteroids.clear();
    activeDrops.clear();
    activeBosses.clear();
    activeStations.clear();
    activeChests.clear();
    activeCargoWrecks.clear();
    activeNebulae.clear();
  }

  void _initSectorPois() {
    SectorMapGenerator.generateAndSpawn(this);
  }

  void openTacticalMap() {
    if (state != GameState.playing || isTacticalMapOpen) return;
    isTacticalMapOpen = true;
    pauseEngine();
    _safeAddOverlay('tacticalMap');
  }

  void closeTacticalMap() {
    if (!isTacticalMapOpen) return;
    isTacticalMapOpen = false;
    overlays.remove('tacticalMap');
    resumeEngine();
    gameFocusNode?.requestFocus();
  }

  void toggleTacticalMap() {
    if (isTacticalMapOpen) {
      closeTacticalMap();
    } else {
      openTacticalMap();
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    // Sprint 57: Scaled Hit-Stop visceral impact freeze (Hades Standard)
    if (hitStopTimer > 0) {
      hitStopTimer = math.max(0.0, hitStopTimer - dt);
      if (shakeTimer > 0) {
        shakeTimer = math.max(0.0, shakeTimer - dt);
      }
      particlePool.update(dt);
      if (specialBufferTimer > 0) {
        specialBufferTimer = math.max(0.0, specialBufferTimer - dt);
      }
      return;
    }

    // Processa fila de input buffer para Ultimate/Especial
    if (specialBufferTimer > 0) {
      specialBufferTimer = math.max(0.0, specialBufferTimer - dt);
      if (specialAvailable && state == GameState.playing) {
        specialBufferTimer = 0.0;
        triggerSpecial();
      }
    }
    if (dt > 0) {
      final instantFps = (1.0 / dt).clamp(1.0, 240.0);
      currentFps = currentFps * 0.92 + instantFps * 0.08;
      currentFrameTimeMs = dt * 1000.0;
    }

    if (state == GameState.playing && sectorMap != null) {
      sectorMap!.updateExploration(player.position, GameConstants.radarRange);
    }

    if (shakeTimer > 0) {
      shakeTimer = math.max(0.0, shakeTimer - dt);
    }

    // Sprint 52: Interpolação suave do Zoom Dinâmico de Câmera
    if ((camera.viewfinder.zoom - targetCameraZoom).abs() > 0.001) {
      camera.viewfinder.zoom +=
          (targetCameraZoom - camera.viewfinder.zoom) *
          (dt * 3.5).clamp(0.0, 1.0);
    }

    // Science Fair 180-second (3-minute) countdown timer & Celestial Events
    if (state == GameState.playing) {
      if (!specialAvailable && ultimateCharge < 1.0) {
        ultimateCharge = (ultimateCharge + dt * ultimateChargeRate).clamp(
          0.0,
          1.0,
        );
        if (ultimateCharge >= 1.0) {
          specialAvailable = true;
          playSfx('powerup.wav');
          try {
            spawnFloatingText(
              player.position + Vector2(0, -42),
              '⚡ ULTIMATE PRONTA! [SPACE]',
              color: const Color(0xFFFFD700),
              fontSize: 15.0,
            );
          } catch (_) {}
        }
      }
      timeRemaining -= dt;
      if (showLaunchTransmission) {
        launchTransmissionTimer -= dt;
        if (launchTransmissionTimer <= 0) {
          showLaunchTransmission = false;
        }
      }
      if (cometAlertTimer > 0) {
        cometAlertTimer = math.max(0.0, cometAlertTimer - dt);
      }

      // Mid-game surprise event: Comet Halley warning at 105s remaining (75s played)
      if (!cometWarningTriggered &&
          timeRemaining <= 105.0 &&
          timeRemaining > 101.0) {
        cometWarningTriggered = true;
        cometAlertTimer = 4.0;
        cometAlertMessage = I18n.select(
          pt: '☄️ ALERTA CIENTÍFICO: Cometa Halley se aproximando!',
          en: '☄️ SCIENTIFIC ALERT: Halley Comet approaching!',
        );
        playSfx('low_health.wav');
      }

      // Spawn Comet at 101s remaining (79s played)
      if (cometWarningTriggered && !cometSpawned && timeRemaining <= 101.0) {
        cometSpawned = true;
        spawnComet();
      }

      if (timeRemaining <= 0) {
        final hasActiveBoss = activeBoss != null && !activeBoss!.isDefeated;
        final hasGate = world.children.any((c) => c is HyperspaceGateComponent);
        if (hasActiveBoss || hasGate) {
          timeRemaining =
              0; // Overtime durante o Clímax do Chefe ou preparação do Hipersalto
        } else {
          timeRemaining = 0;
          if (!voidReaperSpawned) {
            voidReaperSpawned = true;
            spawnVoidReaper();
          }
        }
      }
    }

    // If campaign is active, run the level manager update
    if (state == GameState.playing &&
        activeMode == 'campaign' &&
        levelManager != null) {
      levelManager!.update(dt);
    }

    // Low health sound warning loop (every 3.5 seconds when on 1 life)
    if (state == GameState.playing && lives == 1) {
      lowHealthWarnTimer -= dt;
      if (lowHealthWarnTimer <= 0) {
        lowHealthWarnTimer = 3.5;
        playSfx('low_health.wav');
      }
    }
  }

  @override
  void render(Canvas canvas) {
    if (shakeTimer > 0) {
      final random = math.Random();
      final progress = (shakeTimer / math.max(0.001, shakeDuration)).clamp(
        0.0,
        1.0,
      );
      final decay =
          progress *
          progress; // Decaimento quadrático de trauma (Nova Drift benchmark)
      final currentIntensity = shakeIntensity * decay;
      final dx = (-1.0 + random.nextDouble() * 2.0) * currentIntensity;
      final dy = (-1.0 + random.nextDouble() * 2.0) * currentIntensity;
      final angle =
          (-1.0 + random.nextDouble() * 2.0) * (currentIntensity * 0.0012);

      canvas.save();
      final cx = size.x * 0.5;
      final cy = size.y * 0.5;
      canvas.translate(cx + dx, cy + dy);
      canvas.rotate(angle);
      canvas.translate(-cx, -cy);
      super.render(canvas);
      canvas.restore();
    } else {
      super.render(canvas);
    }
  }

  void triggerBossEncounter() {
    if (state != GameState.playing) return;
    if (activeBoss != null && !activeBoss!.isDefeated) {
      spawnFloatingText(
        player.position + Vector2(0, -50),
        '⚠️ CHEFE JÁ PRESENTE NO SETOR!',
        color: const Color(0xFFFF5252),
        fontSize: 14.0,
      );
      return;
    }

    final random = math.Random();
    final angle = random.nextDouble() * 2 * math.pi;
    const spawnDist = 650.0;
    final spawnPos =
        player.position + Vector2(math.cos(angle), math.sin(angle)) * spawnDist;
    spawnPos.x = spawnPos.x.clamp(120.0, GameConstants.sectorWidth - 120.0);
    spawnPos.y = spawnPos.y.clamp(120.0, GameConstants.sectorHeight - 120.0);

    switch (currentSector.id) {
      case SectorId.orion:
        final boss = IgnisWyrmComponent(position: spawnPos);
        activeBoss = boss;
        flawlessBossKill = true;
        lastBossEncountered = boss.bossName;
        world.add(boss);
        spawnFloatingText(
          player.position + Vector2(0, -60),
          '🔥 IGNIS WYRM INVOCADO! (SOLAR LEVIATHAN)',
          color: const Color(0xFFFF5722),
          fontSize: 18.0,
        );
        break;
      case SectorId.cryoAbyss:
        final boss = GlacialColossusComponent(position: spawnPos);
        activeBoss = boss;
        flawlessBossKill = true;
        lastBossEncountered = boss.bossName;
        world.add(boss);
        spawnFloatingText(
          player.position + Vector2(0, -60),
          '❄️ GLACIAL COLOSSUS INVOCADO! (TITÃ CRIOGÊNICO)',
          color: const Color(0xFF80D8FF),
          fontSize: 18.0,
        );
        break;
      case SectorId.graveyard:
        final boss = ScrapGoliathComponent(position: spawnPos);
        activeBoss = boss;
        flawlessBossKill = true;
        lastBossEncountered = boss.bossName;
        world.add(boss);
        spawnFloatingText(
          player.position + Vector2(0, -60),
          '⚙️ SCRAP GOLIATH INVOCADO! (COLOSSO MAGNÉTICO)',
          color: const Color(0xFF00E676),
          fontSize: 18.0,
        );
        break;
      case SectorId.xenoHive:
        final boss = CarrierHiveAlphaComponent(position: spawnPos);
        activeBoss = boss;
        flawlessBossKill = true;
        lastBossEncountered = boss.bossName;
        world.add(boss);
        spawnFloatingText(
          player.position + Vector2(0, -60),
          '🪲 CARRIER HIVE ALPHA INVOCADA! (RAINHA XENO)',
          color: const Color(0xFFFF4081),
          fontSize: 18.0,
        );
        break;
      case SectorId.eventHorizon:
        final boss = VoidSingularityCoreComponent(position: spawnPos);
        activeBoss = boss;
        flawlessBossKill = true;
        lastBossEncountered = boss.bossName;
        world.add(boss);
        spawnFloatingText(
          player.position + Vector2(0, -60),
          '🌌 VOID SINGULARITY CORE INVOCADO! (SOBERANO DO VÁCUO)',
          color: const Color(0xFFE040FB),
          fontSize: 18.0,
        );
        break;
      case SectorId.voidThrone:
        final boss = PrimordialVoidSovereignComponent(position: spawnPos);
        activeBoss = boss;
        flawlessBossKill = true;
        lastBossEncountered = boss.bossName;
        world.add(boss);
        spawnFloatingText(
          player.position + Vector2(0, -60),
          '✨ PRIMORDIAL VOID SOVEREIGN INVOCADO! (O ARQUITETO)',
          color: const Color(0xFFFFD700),
          fontSize: 18.0,
        );
        break;
      case SectorId.vesta:
        final boss = DreadnoughtLeviathanComponent(position: spawnPos);
        activeBoss = boss;
        flawlessBossKill = true;
        lastBossEncountered = boss.bossName;
        world.add(boss);
        spawnFloatingText(
          player.position + Vector2(0, -60),
          '🚨 DREADNOUGHT LEVIATHAN INVOCADO!',
          color: const Color(0xFFFF1744),
          fontSize: 18.0,
        );
        break;
    }

    triggerSpeechBubble(SpeechTrigger.bossArrival);
    playSfx('powerup.wav');
    triggerScreenShake(duration: 0.9, intensity: 22.0);
  }

  void _spawnBossRushStage(int stage) {
    bossRushStage = stage;
    final spawnPos = player.position + Vector2(0, -520);
    spawnPos.x = spawnPos.x.clamp(160.0, GameConstants.sectorWidth - 160.0);
    spawnPos.y = spawnPos.y.clamp(160.0, GameConstants.sectorHeight - 160.0);

    final SectorBoss boss;
    String banner;
    Color bannerColor;
    switch (stage) {
      case 0:
        boss = DreadnoughtLeviathanComponent(position: spawnPos);
        banner = '💀 BOSS RUSH [1/4] // DREADNOUGHT LEVIATHAN!';
        bannerColor = const Color(0xFFFF1744);
        break;
      case 1:
        boss = IgnisWyrmComponent(position: spawnPos);
        banner = '💀 BOSS RUSH [2/4] // IGNIS WYRM!';
        bannerColor = const Color(0xFFFF5722);
        break;
      case 2:
        boss = ScrapGoliathComponent(position: spawnPos);
        banner = '💀 BOSS RUSH [3/4] // SCRAP GOLIATH!';
        bannerColor = const Color(0xFF00E676);
        break;
      default:
        boss = VoidSingularityCoreComponent(position: spawnPos);
        banner = '💀 BOSS RUSH FINAL [4/4] // VOID SINGULARITY CORE!';
        bannerColor = const Color(0xFFE040FB);
        break;
    }

    activeBoss = boss;
    world.add(boss);
    spawnFloatingText(
      player.position + Vector2(0, -70),
      banner,
      color: bannerColor,
      fontSize: 18.0,
    );
  }

  void onBossRushBossDefeated(Vector2 lastBossPos) {
    final nextStage = bossRushStage + 1;
    if (nextStage >= 4) {
      campaignCompleted = true;
      hyperModeUnlocked = true;
      saveHyperModeState();
      addScore(25000);
      addScrap(2000);
      completeMission(survived: true);
      return;
    }
    // Restaura parte do casco da Valquíria entre titãs do Boss Rush
    player.heal(player.maxHp * 0.35);
    _spawnBossRushStage(nextStage);
  }

  void spawnVoidReaper() {
    final random = math.Random();
    final angle = random.nextDouble() * 2 * math.pi;
    final spawnDist = 650.0;
    final spawnPos =
        player.position + Vector2(math.cos(angle), math.sin(angle)) * spawnDist;

    spawnPos.x = spawnPos.x.clamp(100.0, GameConstants.sectorWidth - 100.0);
    spawnPos.y = spawnPos.y.clamp(100.0, GameConstants.sectorHeight - 100.0);

    final reaper = VoidReaperComponent(position: spawnPos);
    world.add(reaper);
    playSfx('low_health.wav');
    triggerScreenShake(duration: 1.8, intensity: 25.0);
    spawnFloatingText(
      player.position + Vector2(0, -60),
      '⚠️ COLAPSO TEMPORAL! O CEIFADOR DO VÁCUO CHEGOU! ⚠️',
      color: const Color(0xFFFF1744),
      fontSize: 18.0,
    );
  }

  void openStarChart() {
    if (state != GameState.playing) return;
    if (currentSector.id == SectorId.voidThrone && campaignCompleted) {
      jumpToNextSector();
      return;
    }
    if (currentSector.id == SectorId.eventHorizon &&
        campaignCompleted &&
        !canAccessSecretSector5) {
      jumpToNextSector();
      return;
    }
    pauseEngine();
    state = GameState.starChart;
    _safeAddOverlay('starChart');
  }

  void jumpToNextSector({Sector? targetSector, String? chosenMutationId}) {
    if (chosenMutationId != null) {
      applyPilotMutation(chosenMutationId);
    }
    if (state == GameState.starChart) {
      overlays.remove('starChart');
      state = GameState.playing;
      _safeAddOverlay('hud');
      resumeEngine();
      gameFocusNode?.requestFocus();
    }

    if (currentSector.id == SectorId.voidThrone && campaignCompleted) {
      addScore(50000);
      addScrap(5000);
      completeMission(survived: true);
      return;
    }

    if (currentSector.id == SectorId.eventHorizon &&
        campaignCompleted &&
        targetSector?.id != SectorId.voidThrone) {
      addScore(30000);
      addScrap(2500);
      completeMission(survived: true);
      return;
    }

    if (targetSector != null) {
      currentSector = targetSector;
    } else {
      SectorId nextId;
      switch (currentSector.id) {
        case SectorId.vesta:
          nextId = SectorId.orion;
          break;
        case SectorId.orion:
        case SectorId.cryoAbyss:
          nextId = SectorId.graveyard;
          break;
        case SectorId.graveyard:
        case SectorId.xenoHive:
          nextId = SectorId.eventHorizon;
          break;
        case SectorId.eventHorizon:
          nextId = canAccessSecretSector5
              ? SectorId.voidThrone
              : SectorId.vesta;
          break;
        case SectorId.voidThrone:
          nextId = SectorId.vesta;
          break;
      }
      currentSector = Sector.findById(nextId);
    }

    timeRemaining = fairRoundDuration;
    voidReaperSpawned = false;
    activeBoss = null;
    beaconsCharged = 0;

    // Reseta cronômetros de ondas de Sub-Chefes do AsteroidField
    if (asteroidField != null) {
      asteroidField!.subBoss45Spawned = false;
    }

    // Remove entidades antigas de combate do setor anterior
    final toRemove = world.children.where(
      (child) =>
          child is AsteroidComponent ||
          child is EnemyShipComponent ||
          child is EnemyBulletComponent ||
          child is BulletComponent ||
          child is ProximityMineComponent ||
          child is DerelictTurretComponent ||
          child is TeslaLightningComponent ||
          child is ChakramProjectileComponent ||
          child is GravityAuraPulseComponent ||
          child is ThermalLanceBeamComponent ||
          child is PlayerClusterMineComponent ||
          child is MegastructureWallComponent ||
          child is LaserContainmentGateComponent ||
          child is TimedVaultComponent ||
          child is FlawlessVaultComponent ||
          child is VoidMerchantComponent ||
          child is CursedShrineComponent ||
          child is CryoMistZoneComponent ||
          child is CryoMineComponent ||
          child is OrganicBiomassWallComponent ||
          child is XenoCocoonComponent ||
          child is SpeechBubbleComponent ||
          child is SectorBoss ||
          child is HyperspaceGateComponent ||
          child is VoidReaperComponent,
    );
    for (final child in List.from(toRemove)) {
      child.removeFromParent();
    }

    // Re-inicializa os POIs e perigos para o novo setor
    _initSectorPois();

    // Reseta cronômetros de ondas do AsteroidField
    if (asteroidField != null) {
      asteroidField!.difficultyTimer = 0.0;
      asteroidField!.subBoss45Spawned = false;
      asteroidField!.elite1Spawned = false;
      asteroidField!.elite2Spawned = false;
      asteroidField!.leviathanSpawned = false;
      asteroidField!.cryoPodSpawned = false;
      asteroidField!.swarm20Spawned = false;
      asteroidField!.swarm60Spawned = false;
      asteroidField!.sectorClimaxSpawned = false;
    }

    // Repara o casco da Valquíria após a travessia hiperespacial bem-sucedida
    player.heal(player.maxHp);

    // Recompensas do Salto de Hiperespaço
    addScore(10000);
    addScrap(1000);
    addXp(350);
    affinityManager.getAffinity(selectedValkyrie.id).addXp(200);

    // Efeitos visuais e sonoros de dobra espacial
    playSfx('powerup.wav');
    triggerScreenShake(duration: 1.5, intensity: 22.0);
    triggerSpeechBubble(SpeechTrigger.hyperspaceJump);

    spawnFloatingText(
      player.position + Vector2(0, -75),
      '🚀 HIPERESPAÇO: BEM-VINDO A ${currentSector.name.toUpperCase()}!',
      color: currentSector.primaryColor,
      fontSize: 18.0,
    );
  }

  final SoundEngine soundEngine = SoundEngine();
  List<AudioPlayer> get sfxPlayers => soundEngine.allPlayers;

  void initSfxPlayers() {
    soundEngine.initialize();
  }

  void playSfx(String name, {double? volumeMultiplier, double? pitch}) {
    soundEngine.playSfx(
      name: name,
      masterVolume: masterVolume,
      sfxVolume: sfxVolume,
      volumeMultiplier: volumeMultiplier,
      overridePitch: pitch,
    );
  }

  @override
  void onRemove() {
    HardwareKeyboard.instance.removeHandler(_handleGlobalKeyEvent);
    soundEngine.dispose();
    try {
      FlameAudio.bgm.dispose();
    } catch (_) {}
    super.onRemove();
  }

  void triggerScreenShake({
    required double duration,
    required double intensity,
  }) {
    shakeIntensity = math.max(shakeIntensity, intensity).clamp(1.0, 36.0);
    shakeDuration = math.max(shakeDuration, duration).clamp(0.05, 3.0);
    shakeTimer = math.max(shakeTimer, duration);
  }

  void triggerHitStop(double durationSeconds) {
    hitStopTimer = math.max(hitStopTimer, durationSeconds.clamp(0.02, 0.25));
  }

  void spawnExplosionParticles({
    required Vector2 position,
    required List<Color> colorChoices,
    required int count,
    required double minSize,
    required double maxSize,
    required double minSpeed,
    required double maxSpeed,
  }) {
    particlePool.spawnExplosion(
      position: position,
      colorChoices: colorChoices,
      count: count,
      minSize: minSize,
      maxSize: maxSize,
      minSpeed: minSpeed,
      maxSpeed: maxSpeed,
    );
  }

  void spawnSparks({
    required Vector2 position,
    required Color color,
    int count = 8,
    double speed = 140.0,
  }) {
    particlePool.spawnSparks(
      position: position,
      color: color,
      count: count,
      speed: speed,
    );
  }

  void buyItem(String itemId) {
    final isWeapon = const [
      'blaster',
      'spread_shot',
      'rapid_fire',
      'bomb_launcher',
    ].contains(itemId);

    if (isWeapon) {
      if (player.unlockedWeapons.containsKey(itemId)) {
        final weapon = player.unlockedWeapons[itemId]!;
        if (weapon.level >= weapon.maxLevel) return;

        final upgradeCost = 200 * weapon.level;
        if (credits < upgradeCost) return;

        credits -= upgradeCost;
        weapon.upgrade();
        playSfx('purchase.wav');
      } else {
        int cost = 0;
        Weapon newWeapon;
        if (itemId == 'spread_shot') {
          cost = 500;
          newWeapon = SpreadShot();
        } else if (itemId == 'rapid_fire') {
          cost = 600;
          newWeapon = RapidFire();
        } else if (itemId == 'bomb_launcher') {
          cost = 800;
          newWeapon = BombLauncher();
        } else {
          return;
        }

        if (credits < cost) return;
        credits -= cost;
        player.unlockedWeapons[itemId] = newWeapon;
        player.setWeapon(newWeapon);
        playSfx('purchase.wav');
      }
    } else if (itemId == 'speed_boost') {
      if (credits < 300) return;
      credits -= 300;
      player.movementAcceleration += 150.0;
      player.movementMaxSpeed += 50.0;
      playSfx('powerup.wav');
    } else if (itemId == 'extra_life') {
      if (lives >= 5) return;
      if (credits < 400) return;
      credits -= 400;
      lives += 1;
      playSfx('powerup.wav');
    }
  }

  void gameOver() {
    completeMission(survived: false);
  }

  static const int maxActiveFloatingTexts = 26;

  void spawnFloatingText(
    Vector2 position,
    String text, {
    Color color = Colors.white,
    double fontSize = 14.0,
    Vector2? velocity,
  }) {
    final existingTexts = world.children
        .whereType<FloatingTextComponent>()
        .toList();
    if (existingTexts.length >= maxActiveFloatingTexts) {
      existingTexts.first.removeFromParent();
    }
    world.add(
      FloatingTextComponent(
        position: position.clone(),
        text: text,
        color: color,
        fontSize: fontSize,
        velocity: velocity,
      ),
    );
  }

  void _triggerRelicCritSynergy(Vector2 pos) {
    if (!unlockedRelics.contains('void_lens')) return;
    try {
      final orbs = world.children.whereType<XpOrbComponent>().toList();
      for (final orb in orbs) {
        if (orb.position.distanceTo(pos) <= 240.0) {
          final toPlayer = (player.position - orb.position).normalized();
          orb.position += toPlayer * 160.0;
        }
      }
    } catch (_) {}
  }

  /// Sprint 38: Floating Combat Text com codificação elemental (Diablo / Borderlands)
  void spawnCombatDamageText({
    required Vector2 position,
    required double damage,
    bool isCritical = false,
    ElementalStatus? element,
  }) {
    if (state != GameState.playing) return;
    if (isCritical) {
      _triggerRelicCritSynergy(position);
    }
    final Color textColor;
    if (isCritical) {
      textColor = const Color(0xFFFFD700); // Gold
    } else if (element == ElementalStatus.cryoFreeze) {
      textColor = const Color(0xFF00E5FF); // Cyber Cyan
    } else if (element == ElementalStatus.solarBurn) {
      textColor = const Color(0xFFFF6D00); // Solar Orange
    } else if (element == ElementalStatus.voidRupture) {
      textColor = const Color(0xFFE040FB); // Void Purple
    } else if (element == ElementalStatus.ionShock) {
      textColor = const Color(0xFF76FF03); // Neon Lime
    } else {
      textColor = const Color(0xFFFF8A80); // Soft Coral
    }

    final rng = math.Random();
    final text = isCritical ? '★ ${damage.toInt()}!' : '${damage.toInt()}';
    final fontSize = isCritical ? 14.5 : 11.5;
    final vel = Vector2(
      (rng.nextDouble() - 0.5) * 44.0,
      -60.0 - rng.nextDouble() * 25.0,
    );

    spawnFloatingText(
      position +
          Vector2(
            (rng.nextDouble() - 0.5) * 16.0,
            (rng.nextDouble() - 0.5) * 12.0,
          ),
      text,
      color: textColor,
      fontSize: fontSize,
      velocity: vel,
    );
  }

  void addScore(int points) {
    if (state != GameState.playing) return;
    score += points;
    if (!topRecordBeaten && topLeaderScore > 0 && score > topLeaderScore) {
      topRecordBeaten = true;
      playSfx('powerup.wav');
      triggerScreenShake(duration: 0.5, intensity: 10.0);
      spawnFloatingText(
        player.position + Vector2(0, -40),
        '👑 NOVO RECORDE DA FEIRA!',
        color: Colors.amberAccent,
        fontSize: 20.0,
        velocity: Vector2(0, -40),
      );
    }
  }

  void onAsteroidDestroyed(Vector2 pos, int basePoints) {
    if (state != GameState.playing) return;

    notifyAsteroidDestroyedForUnlocks();
    addScore(basePoints);
    final scrapReward = math.max(2, (basePoints / 16).round());
    addRunCredits(scrapReward);
    spawnFloatingText(pos, '+$basePoints', color: Colors.white, fontSize: 13.5);
  }

  void spawnComet() {
    if (state != GameState.playing) return;
    final random = math.Random();

    // Pick an edge to spawn from: 0 = Left, 1 = Right, 2 = Top, 3 = Bottom
    final edge = random.nextInt(4);
    Vector2 spawnPos;
    switch (edge) {
      case 0: // Left
        spawnPos = Vector2(
          -35.0,
          100.0 + random.nextDouble() * (GameConstants.screenHeight - 200.0),
        );
        break;
      case 1: // Right
        spawnPos = Vector2(
          GameConstants.screenWidth + 35.0,
          100.0 + random.nextDouble() * (GameConstants.screenHeight - 200.0),
        );
        break;
      case 2: // Top
        spawnPos = Vector2(
          100.0 + random.nextDouble() * (GameConstants.screenWidth - 200.0),
          -35.0,
        );
        break;
      default: // Bottom
        spawnPos = Vector2(
          100.0 + random.nextDouble() * (GameConstants.screenWidth - 200.0),
          GameConstants.screenHeight + 35.0,
        );
        break;
    }

    // Direct trajectory across the central play area (near player zone)
    final targetX =
        (GameConstants.screenWidth / 2) + (random.nextDouble() - 0.5) * 400.0;
    final targetY =
        (GameConstants.screenHeight / 2) + (random.nextDouble() - 0.5) * 260.0;
    final targetPoint = Vector2(targetX, targetY);

    final dir = (targetPoint - spawnPos).normalized();
    final velocity =
        dir * 105.0; // Calibrated speed (105 px/s): approachable and pursuable

    final comet = CometComponent(position: spawnPos, velocity: velocity);

    world.add(comet);
    playSfx('powerup.wav');
    triggerScreenShake(duration: 0.3, intensity: 6.0);
  }

  Future<void> fetchTopLeaderRecord() async {
    try {
      final list = await ApiService.getFairLeaderboard(period: 'all', limit: 1);
      if (list.isNotEmpty) {
        final top = list.first;
        topLeaderName = (top['username'] ?? 'Líder').toString().toUpperCase();
        topLeaderScore = (top['score'] ?? 0) as int;
      } else {
        topLeaderName = 'PIONEIRO';
        topLeaderScore = 10000;
      }
    } catch (_) {}
  }

  void triggerSpecial() {
    if (!specialAvailable || state != GameState.playing) return;
    specialAvailable = false;
    ultimateCharge = 0.0;
    playSfx('special.wav');
    triggerScreenShake(duration: 0.8, intensity: 20.0);

    final primaryColor = selectedValkyrie.primaryColor;
    final accentColor = selectedValkyrie.accentColor;
    final abilityName = selectedValkyrie.specialAbilityName;

    // Sprint 41: Conquistas de Habilidades Únicas
    if (selectedValkyrie.id == 'lyra') {
      AchievementService.unlock('corona_supernova');
    } else if (selectedValkyrie.id == 'selene') {
      AchievementService.unlock('absolute_zero');
    } else if (selectedValkyrie.id == 'vesper') {
      AchievementService.unlock('void_singularity');
    }

    // Visual shockwave particles
    spawnExplosionParticles(
      position: player.position,
      colorChoices: [
        primaryColor,
        accentColor,
        Colors.white,
        Colors.amberAccent,
      ],
      count: 50,
      minSize: 3.0,
      maxSize: 6.5,
      minSpeed: 120.0,
      maxSpeed: 380.0,
    );

    // Floating text indicator
    spawnFloatingText(
      player.position + Vector2(0, -35),
      '★ ${abilityName.toUpperCase()}! ★',
      color: primaryColor,
      fontSize: 18,
    );
    triggerSpeechBubble(SpeechTrigger.superWeapon);

    switch (selectedValkyrie.id) {
      case 'kaede':
      case 'kbr':
      case 'kbr_01':
      case 'kimberly':
        // Kaede / KBR-01: Tempest of Thousand Petals / Blade Storm
        // 4.0s invulnerabilidade, blink frontal de 180px e vórtice radial de 24 lâminas taquiônicas
        player.invulnerableTimer = 4.0;
        player.position += player.forward * 180.0;
        player.velocity = player.forward * 480.0;
        triggerScreenShake(duration: 0.75, intensity: 18.0);
        const bladesCount = 24;
        const stepBlades = (2 * math.pi) / bladesCount;
        for (int i = 0; i < bladesCount; i++) {
          final ang = i * stepBlades;
          final dir = Vector2(math.cos(ang), math.sin(ang));
          final slash = KatanaSlashComponent(
            position: player.position + dir * (player.radius + 6.0),
            angle: ang + math.pi / 2,
            velocity: dir * 680.0,
            lifeTimer: 1.1,
            damage: 85.0,
            slashWidth: 84.0,
            slashHeight: 26.0,
            slashColor: const Color(0xFF00E5FF),
            piercesLeft: 99,
          );
          world.add(slash);
        }
        break;

      case 'lyra':
        // Lyra: Corona Supernova / Solar Flare
        // 3.5s invulnerabilidade, anula tiros inimigos em 500px e dispara 36 labaredas solares perfurantes
        player.invulnerableTimer = 3.5;
        player.velocity += player.forward * 450.0;
        triggerScreenShake(duration: 0.85, intensity: 20.0);
        final enemyBullets = world.children
            .whereType<EnemyBulletComponent>()
            .toList();
        for (final b in enemyBullets) {
          if (b.position.distanceToSquared(player.position) <= 500.0 * 500.0) {
            b.removeFromParent();
            spawnSparks(
              position: b.position,
              color: const Color(0xFFFF9800),
              count: 5,
            );
          }
        }
        final waves = [
          (speed: 640.0, angleOffset: 0.0, color: const Color(0xFFFF5722)),
          (
            speed: 540.0,
            angleOffset: math.pi / 12,
            color: const Color(0xFFFF9800),
          ),
          (
            speed: 460.0,
            angleOffset: -math.pi / 12,
            color: const Color(0xFFFFEB3B),
          ),
        ];
        const bulletsPerWave = 12;
        const step = (2 * math.pi) / bulletsPerWave;
        for (final wave in waves) {
          for (int i = 0; i < bulletsPerWave; i++) {
            final ang = (i * step) + wave.angleOffset;
            final dir = Vector2(math.cos(ang), math.sin(ang));
            final bullet = BulletComponent(
              position: player.position + dir * (player.radius + 2.0),
              radius: 4.0,
              velocity: dir * wave.speed,
              lifeTimer: 0.85,
              damage: 35.0,
              color: wave.color,
            );
            world.add(bullet);
          }
        }
        break;

      case 'selene':
        // Selene: Absolute Zero Cryo Stasis & Singularity Barrier
        // 6.0s barreira impenetrável + congela todos inimigos visíveis por 4.5s + 28 feixes fotônicos
        player.invulnerableTimer = 6.0;
        triggerScreenShake(duration: 0.65, intensity: 16.0);
        for (final e in world.children.whereType<EnemyShipComponent>()) {
          e.cryoFreezeTimer = 4.5;
          spawnSparks(
            position: e.position,
            color: const Color(0xFF80D8FF),
            count: 6,
          );
        }
        const beamCount = 28;
        final stepSelene = (2 * math.pi) / beamCount;
        for (int i = 0; i < beamCount; i++) {
          final ang = i * stepSelene;
          final dir = Vector2(math.cos(ang), math.sin(ang));
          final bullet = BulletComponent(
            position: player.position + dir * player.radius,
            radius: 4.0,
            velocity: dir * 550.0,
            lifeTimer: 1.0,
            damage: 36.0,
            color: const Color(0xFF00E5FF),
          );
          world.add(bullet);
        }
        break;

      case 'vesper':
        // Vesper: Void Horizon Singularity & Gravitational XP Siphon
        // 3.5s escudo + implosão de antimatéria de 420px (600 dmg) + vácuo gravitacional de orbes de XP
        player.invulnerableTimer = 3.5;
        triggerScreenShake(duration: 1.1, intensity: 26.0);
        world.add(
          BombExplosionComponent(
            position: player.position.clone(),
            maxRadius: 420.0,
            damage: 600.0,
          ),
        );
        for (final orb in world.children.whereType<XpOrbComponent>()) {
          orb.velocity = (player.position - orb.position).normalized() * 550.0;
        }
        break;

      case 'astraea':
      default:
        // Astraea: Genesis Nova / Sovereign Orbital Matrix
        // 5.0s invulnerabilidade, anula projéteis em 600px + 36 lasers estelares imperiais
        player.invulnerableTimer = 5.0;
        triggerScreenShake(duration: 1.2, intensity: 28.0);
        final enemyBulletsAstraea = world.children
            .whereType<EnemyBulletComponent>()
            .toList();
        for (final b in enemyBulletsAstraea) {
          if (b.position.distanceToSquared(player.position) <= 600.0 * 600.0) {
            b.removeFromParent();
            spawnSparks(
              position: b.position,
              color: const Color(0xFFFFD700),
              count: 6,
            );
          }
        }
        const astraeaLaserCount = 36;
        final stepAstraea = (2 * math.pi) / astraeaLaserCount;
        for (int i = 0; i < astraeaLaserCount; i++) {
          final ang = i * stepAstraea;
          final dir = Vector2(math.cos(ang), math.sin(ang));
          final bullet = BulletComponent(
            position: player.position + dir * player.radius,
            radius: 4.5,
            velocity: dir * 600.0,
            lifeTimer: 1.1,
            damage: 48.0,
            color: const Color(0xFFFFD700),
          );
          world.add(bullet);
        }
        break;
    }
  }

  void startFairGame(Scientist scientist) {
    selectedScientist = scientist;
    score = 0;
    lives = GameConstants.playerLives;
    currentLevel = 1;
    timeRemaining = fairRoundDuration;
    missionSurvived = false;
    specialAvailable = true;
    samplesCollected = 0;
    runLevel = 1;
    runXp = 0;
    runXpNextLevel = calculateNextLevelXp(1);
    currentLevelUpChoices = [];
    try {
      player.resetRoguelikeStats();
    } catch (_) {}
    topRecordBeaten = false;
    cometWarningTriggered = false;
    cometSpawned = false;
    cometAlertTimer = 0.0;
    cometAlertMessage = null;
    showLaunchTransmission = true;
    launchTransmissionTimer = 5.0;
    fetchTopLeaderRecord();

    if (levelManager != null) {
      levelManager = null;
    }
    if (asteroidField != null) {
      asteroidField!.removeFromParent();
      asteroidField = null;
    }

    _removeAllAsteroidsAndProjectiles();

    player.customGame ??= this;
    player.respawn(
      GameConstants.screenWidth / 2,
      GameConstants.screenHeight / 2,
    );
    player.configureScientist(scientist);

    final preset = movementPresets[selectedMovementPresetIndex];
    player.movementAcceleration = preset.acceleration;
    player.movementMaxSpeed = preset.maxSpeed;
    player.movementFriction = preset.friction;

    asteroidField = AsteroidField();
    world.add(asteroidField!);

    changeState(GameState.playing);
  }

  void completeMission({required bool survived}) {
    if (state != GameState.playing) return;

    if (score >= 25000) {
      AchievementService.unlock('void_apex_pilot');
    }

    missionSurvived = survived;
    lastRunWasVictory = survived;
    final bondLevel = affinityManager
        .getAffinity(selectedValkyrie.id)
        .bondLevel;
    lastTriggeredEnding = EndingManager.evaluateEnding(
      survived: survived,
      sectorId: currentSector.id,
      voidReaperSpawned: voidReaperSpawned,
      campaignCompleted: campaignCompleted,
      primordialSovereignDefeated: primordialSovereignDefeated,
      activeValkyrieBondLevel: bondLevel,
    );
    if (lastTriggeredEnding != EndingType.none) {
      unlockedEndings.add(lastTriggeredEnding);
    }
    if (survived) {
      score += 1000; // Bônus de sobrevivência de 3 minutos completos
      runCredits += 350; // Survival mission scrap bounty
      if (voidCellsLevel >= maxUnlockedVoidCells && maxUnlockedVoidCells < 5) {
        maxUnlockedVoidCells = (voidCellsLevel + 1).clamp(1, 5);
        unlockMilestone('ach_void_cell_1');
      }
      if (!topRecordBeaten && topLeaderScore > 0 && score > topLeaderScore) {
        topRecordBeaten = true;
      }
      playSfx('powerup.wav');
    } else {
      playSfx('player_hit.wav');
    }

    // Bank all collected scrap into persistent credits
    totalCredits += runCredits;
    savePersistentCredits();

    // Bank bond affinity XP for active pilot
    final timeSurvivedMinutes = ((fairRoundDuration - timeRemaining) / 60.0)
        .clamp(0.0, 5.0);
    final bondXp = (survived ? 80 : 25) + (timeSurvivedMinutes * 15).toInt();
    affinityManager.getAffinity(selectedValkyrie.id).addXp(bondXp);
    affinityManager.saveToPrefs();

    if (asteroidField != null) {
      asteroidField!.removeFromParent();
      asteroidField = null;
    }
    _removeAllAsteroidsAndProjectiles();

    player.invulnerableTimer = 999999.0;
    player.velocity.setZero();

    changeState(GameState.gameOver);
  }
}

class MovementPreset {
  final String label;
  final double acceleration;
  final double maxSpeed;
  final double friction;

  MovementPreset(this.label, this.acceleration, this.maxSpeed, this.friction);
}
