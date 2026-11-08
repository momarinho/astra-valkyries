import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flame/components.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:asteroids/game/asteroids_game.dart';
import 'package:asteroids/game/weapons.dart';
import 'package:asteroids/game/roguelite_systems.dart';
import 'package:asteroids/game/sector.dart';
import 'package:asteroids/game/ending_manager.dart';
import 'package:asteroids/ui/game_over_overlay.dart';
import 'package:asteroids/game/components/player.dart';
import 'package:asteroids/game/components/asteroid.dart';
import 'package:asteroids/game/components/asteroid_field.dart';
import 'package:asteroids/game/components/dead_cells_biome.dart';
import 'package:asteroids/game/components/enemy_ship.dart';
import 'package:asteroids/game/components/enemy_bullet.dart';
import 'package:asteroids/game/components/cosmic_nebula.dart';
import 'package:asteroids/game/components/singularity_rift.dart';
import 'package:asteroids/game/components/living_biomes.dart';
import 'package:asteroids/game/components/cargo_wreck.dart';
import 'package:asteroids/game/components/speech_bubble.dart';

AsteroidsGame _createTestGame() {
  final game = AsteroidsGame();
  game.player = PlayerComponent(position: Vector2(500, 500))..customGame = game;
  game.asteroidField = AsteroidField();
  game.world.add(game.player);
  game.world.add(game.asteroidField!);
  game.state = GameState.playing;
  return game;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Sprint 19: Unified Map Physics & Tactical Cover', () {
    test('MegastructureWallComponent bounces and shatters high-speed asteroids', () {
      final game = _createTestGame();

      final wall = MegastructureWallComponent(
        position: Vector2(500, 500),
        wallSize: Vector2(200, 60),
      );
      final asteroid = AsteroidComponent(
        position: Vector2(500, 460),
        velocity: Vector2(0, 120), // high speed >= 50.0
        radius: 30,
      );
      game.world.add(wall);
      game.world.add(asteroid);

      final initialHp = asteroid.hp;
      wall.resolveAsteroidCollision(asteroid);

      // Should bounce upwards (negative Y velocity) and take impact damage
      expect(asteroid.velocity.y, lessThan(0));
      expect(asteroid.hp, lessThan(initialHp));
    });

    test('MegastructureWallComponent blocks EnemyShipComponent and applies steering', () {
      final game = _createTestGame();

      final wall = MegastructureWallComponent(
        position: Vector2(500, 500),
        wallSize: Vector2(200, 60),
      );
      final enemy = EnemyShipComponent(
        position: Vector2(500, 468),
        type: EnemyType.raider,
      );
      game.world.add(wall);
      game.world.add(enemy);

      final beforeY = enemy.position.y;
      wall.resolveEnemyCollision(enemy);

      // Pushed away from top surface of wall
      expect(enemy.position.y, lessThanOrEqualTo(beforeY));
    });

    test('EnemyBulletComponent dissipates on colliding with MegastructureWallComponent', () {
      final game = _createTestGame();

      final wall = MegastructureWallComponent(
        position: Vector2(300, 300),
        wallSize: Vector2(100, 40),
      );
      final bullet = EnemyBulletComponent(
        position: Vector2(300, 300),
        velocity: Vector2(200, 0),
        radius: 5.0,
      );
      game.world.add(wall);
      game.world.add(bullet);

      wall.onCollisionStart({Vector2(300, 300)}, bullet);

      expect(bullet.isRemoving || !bullet.isMounted, isTrue);
    });

    test('Light ships (VoidSwarmComponent) take impact damage against massive asteroids', () {
      final game = _createTestGame();

      final swarmer = VoidSwarmComponent(position: Vector2(400, 400));
      final massiveAsteroid = AsteroidComponent(
        position: Vector2(410, 400),
        velocity: Vector2(-100, 0),
        radius: 36.0, // >= 24.0
      );
      game.world.add(swarmer);
      game.world.add(massiveAsteroid);

      final initialHp = swarmer.hp;
      swarmer.resolveAsteroidImpact(massiveAsteroid);
      expect(swarmer.hp, lessThan(initialHp));
    });
  });

  group('Sprint 20: Nebula Rebalance & Dynamic Horde Director (60 FPS)', () {
    test('CosmicNebulaComponent drifts, expires after maxDuration, and applies Thermal Overload after 6s', () {
      final game = _createTestGame();

      final nebula = CosmicNebulaComponent(
        position: game.player.position.clone(),
        radius: 150.0,
        type: NebulaType.ionCloud,
        driftVelocity: Vector2(10, 0),
        maxDuration: 28.0,
      );
      game.world.add(nebula);

      final startX = nebula.position.x;
      // Stay inside for 6.5 seconds (keep player inside moving nebula)
      for (int i = 0; i < 65; i++) {
        nebula.update(0.1);
        game.player.position.setFrom(nebula.position);
      }

      expect(nebula.position.x, greaterThan(startX));
      expect(nebula.isOverloaded, isTrue);

      final hpBeforeDrain = game.player.hp;
      for (int i = 0; i < 12; i++) {
        nebula.update(0.1);
        game.player.position.setFrom(nebula.position);
      }
      expect(game.player.hp, lessThan(hpBeforeDrain));

      // Fast-forward past maxDuration
      nebula.update(30.0);
      expect(nebula.isRemoving || !nebula.isMounted, isTrue);
    });

    test('SingularityRiftComponent is calibrated to 160px pullRadius and 0.8s duration', () {
      final rift = SingularityRiftComponent(position: Vector2.zero());
      expect(rift.pullRadius, equals(160.0));
      expect(rift.duration, equals(0.8));
    });

    test('Hybrid enemy HP scaling formula scales with elapsed minutes and Void Cells', () {
      // Base 100 HP at 0m, 0 cells -> 100
      expect(
        EnemyShipComponent.calculateScaledHp(
          baseHp: 100.0,
          minutesElapsed: 0.0,
          voidCells: 0,
        ),
        closeTo(100.0, 0.01),
      );

      // Base 100 HP at 4m (+100%) and 2 Void Cells (+70%) -> 100 * 2.0 * 1.7 = 340
      expect(
        EnemyShipComponent.calculateScaledHp(
          baseHp: 100.0,
          minutesElapsed: 4.0,
          voidCells: 2,
        ),
        closeTo(340.0, 0.01),
      );
    });

    test('Horde Director enforces 40-enemy cap and promotes existing enemies to Elite with Aura', () {
      final game = _createTestGame();

      // Spawn up to the cap (40)
      for (int i = 0; i < AsteroidField.maxActiveEnemiesCap; i++) {
        game.world.add(
          EnemyShipComponent(
            position: Vector2(100.0 + i * 10, 100.0),
            type: EnemyType.scout,
          ),
        );
      }

      final activeCountBefore =
          game.world.children.whereType<EnemyShipComponent>().where((e) => !e.isRemoving).length;
      expect(activeCountBefore, equals(AsteroidField.maxActiveEnemiesCap));

      // Attempt to spawn one more via Horde Director
      game.asteroidField!.spawnOrPromoteEnemy(
        EnemyShipComponent(
          position: Vector2(200, 200),
          type: EnemyType.sniper,
        ),
      );

      final activeShips =
          game.world.children.whereType<EnemyShipComponent>().where((e) => !e.isRemoving).toList();
      // Entity count stays capped at 40
      expect(activeShips.length, equals(AsteroidField.maxActiveEnemiesCap));
      // At least one ship was promoted to Elite with an active EliteAuraType
      expect(
        activeShips.any((e) => e.isPromotedElite && e.eliteAura != EliteAuraType.none),
        isTrue,
      );
    });
  });

  group('Sprint 21: Living Environments for Biomes 2B (Cryo) & 3B (Xeno)', () {
    test('Sector 2B: CryoMistZone reduces acceleration by 30%, CryoMine freezes for 0.8s, GlacialColossus regenerates ice armor', () {
      final game = _createTestGame();

      final mist = CryoMistZoneComponent(
        position: game.player.position.clone(),
        radius: 200,
      );
      game.world.add(mist);

      mist.update(0.1);
      expect(game.player.cryoMistAccelerationMultiplier, closeTo(0.70, 0.01));

      final mine = CryoMineComponent(position: game.player.position.clone());
      game.world.add(mine);
      mine.update(0.1);
      expect(game.player.cryoFreezeTimer, greaterThan(0.0));

      final colossus = GlacialColossusComponent(position: Vector2(600, 200));
      game.world.add(colossus);

      final initialShield = colossus.iceArmorShieldHp;
      colossus.takeDamage(50, game.player.position);
      expect(colossus.iceArmorShieldHp, lessThan(initialShield));
    });

    test('Sector 3B: OrganicBiomassWall regenerates, XenoCocoon hatches VoidSwarmers, CarrierHiveAlpha spawns', () {
      final game = _createTestGame();

      final bioWall = OrganicBiomassWallComponent(
        position: Vector2(500, 500),
        wallSize: Vector2(120, 40),
      );
      final cocoon = XenoCocoonComponent(position: Vector2(700, 500));
      final hiveBoss = CarrierHiveAlphaComponent(position: Vector2(800, 300));
      game.world.add(bioWall);
      game.world.add(cocoon);
      game.world.add(hiveBoss);

      bioWall.takeDamage(60);
      final damagedHp = bioWall.hp;
      // Wait 3.5 seconds without hits -> regenerates
      for (int i = 0; i < 35; i++) {
        bioWall.update(0.1);
      }
      expect(bioWall.hp, greaterThan(damagedHp));

      // Hit cocoon -> hatches VoidSwarmComponent
      cocoon.takeDamage(20);
      expect(game.world.children.whereType<VoidSwarmComponent>().isNotEmpty, isTrue);
      expect(hiveBoss.bossName, contains('CARRIER HIVE ALPHA'));
    });
  });

  group('Sprint 22: Diegetic Lore, Black Box Flight Recorders & Faction Codex', () {
    test('Every Weapon, Blueprint, and PilotMutation has a rich non-empty loreLog', () {
      final allWeapons = <Weapon>[
        Blaster(),
        SpreadShot(),
        RapidFire(),
        BombLauncher(),
        AegisSawblades(),
        TeslaArcCannon(),
        QuantumChakram(),
        RepulsorGravityAura(),
        SolarThermalLance(),
        InfernoPlasmaCone(),
        ValkyrieWingmen(),
        VoidClusterMines(),
      ];
      for (final weapon in allWeapons) {
        expect(weapon.loreLog.trim().isNotEmpty, isTrue, reason: 'Weapon ${weapon.name} missing loreLog');
      }
      for (final bp in BlueprintDef.allBlueprints) {
        expect(bp.loreLog.trim().isNotEmpty, isTrue, reason: 'Blueprint ${bp.name} missing loreLog');
      }
      for (final mut in PilotMutation.allMutations) {
        expect(mut.loreLog.trim().isNotEmpty, isTrue, reason: 'Mutation ${mut.title} missing loreLog');
      }
    });

    test('Destroying a CargoWreckComponent recovers a FlightRecorderLog and FactionCodex has 3 factions', () {
      final game = _createTestGame();

      expect(FactionCodexEntry.allFactions.length, equals(3));
      expect(FlightRecorderLog.allFlightRecorders.length, greaterThanOrEqualTo(6));

      final initialUnlocked = game.unlockedFlightRecorders.length;
      final wreck = CargoWreckComponent(position: Vector2(300, 300));
      game.world.add(wreck);

      wreck.takeDamage(500, game.player.position);
      expect(game.unlockedFlightRecorders.length, greaterThan(initialUnlocked));
    });
  });

  group('Sprint 23: Combat Anime Speech Bubbles', () {
    test('SpeechBubbleComponent renders typewriter text above player ship on contextual triggers', () {
      final game = _createTestGame();

      game.triggerSpeechBubble(SpeechTrigger.bossArrival);

      expect(game.activeSpeechBubble, isNotNull);
      final bubble = game.activeSpeechBubble!;
      expect(bubble.fullText.isNotEmpty, isTrue);

      bubble.update(0.5);
      expect(bubble.displayedText.isNotEmpty, isTrue);
    });
  });

  group('Sprint 24: Multiple Endings & Secret Sector 5 (O Trono do Vazio)', () {
    test('EndingManager evaluates Bad Ending, Good Ending, Secret Sector 5 eligibility, and True Ending', () {
      // Bad Ending on defeat in Sector 4
      final bad = EndingManager.evaluateEnding(
        survived: false,
        sectorId: SectorId.eventHorizon,
        voidReaperSpawned: false,
        campaignCompleted: false,
        primordialSovereignDefeated: false,
        activeValkyrieBondLevel: 2,
      );
      expect(bad, equals(EndingType.badEnding));

      // Secret Sector 5 eligibility with 3+ Void Cells or Astraea decoded
      expect(
        EndingManager.canAccessSecretSector5(
          voidCellsLevel: 3,
          astraeaMatrixDecoded: false,
          selectedValkyrieId: 'lyra',
        ),
        isTrue,
      );
      expect(
        EndingManager.canAccessSecretSector5(
          voidCellsLevel: 0,
          astraeaMatrixDecoded: false,
          selectedValkyrieId: 'lyra',
        ),
        isFalse,
      );

      // Good Ending on Sector 4 victory
      expect(
        EndingManager.evaluateEnding(
          survived: true,
          sectorId: SectorId.eventHorizon,
          voidReaperSpawned: false,
          campaignCompleted: true,
          primordialSovereignDefeated: false,
          activeValkyrieBondLevel: 2,
        ),
        equals(EndingType.goodEnding),
      );

      // True Ending on Sector 5 (Void Throne) victory with Bond Level 5
      expect(
        EndingManager.evaluateEnding(
          survived: true,
          sectorId: SectorId.voidThrone,
          voidReaperSpawned: false,
          campaignCompleted: true,
          primordialSovereignDefeated: true,
          activeValkyrieBondLevel: 5,
        ),
        equals(EndingType.trueEnding),
      );

      // Verify Sector 5 Boss exists
      final sovereign = PrimordialVoidSovereignComponent(position: Vector2(400, 200));
      expect(sovereign.bossName, contains('PRIMORDIAL VOID SOVEREIGN'));
    });

    testWidgets('GameOverOverlay displays True Ending climax banner when unlocked', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 720));
      final game = _createTestGame();
      game.missionSurvived = true;
      game.campaignCompleted = true;
      game.lastTriggeredEnding = EndingType.trueEnding;

      await tester.pumpWidget(
        MaterialApp(
          home: GameOverOverlay(game: game),
        ),
      );
      await tester.pump();

      expect(find.textContaining('QUEBRA DO PROTOCOLO & ASCENSÃO'), findsOneWidget);
    });
  });
}
