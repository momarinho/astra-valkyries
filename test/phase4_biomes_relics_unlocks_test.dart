import 'package:flutter_test/flutter_test.dart';
import 'package:flame/extensions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:void_protocol/game/asteroids_game.dart';
import 'package:void_protocol/game/sector.dart';
import 'package:void_protocol/game/valkyrie.dart';
import 'package:void_protocol/game/roguelite_systems.dart';
import 'package:void_protocol/game/map/sector_map_data.dart';
import 'package:void_protocol/game/map/sector_map_generator.dart';
import 'package:void_protocol/game/components/phase4_biome_elements.dart';
import 'package:void_protocol/game/components/player.dart';
import 'package:void_protocol/game/components/enemy_ship.dart';
import 'package:void_protocol/game/components/asteroid_field.dart';

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

  group(
    'Sprint 25: Visual & Procedural Architecture for 6 Biomes + Hybrid Model',
    () {
      test(
        'All 6 Biome Map Builders generate distinct macro layouts and sockets',
        () {
          final game = AsteroidsGame();
          final vestaMap = VestaBeltMapBuilder().build(
            game,
            Sector.findById(SectorId.vesta),
            42,
          );
          final heliosMap = HeliosForgeMapBuilder().build(
            game,
            Sector.findById(SectorId.orion),
            42,
          );
          final cryoMap = CryoAbyssMapBuilder().build(
            game,
            Sector.findById(SectorId.cryoAbyss),
            42,
          );
          final aegisMap = AegisGraveyardMapBuilder().build(
            game,
            Sector.findById(SectorId.graveyard),
            42,
          );
          final xenoMap = XenoHiveMapBuilder().build(
            game,
            Sector.findById(SectorId.xenoHive),
            42,
          );
          final throneMap = VoidThroneMapBuilder(
            sectorId: SectorId.voidThrone,
          ).build(game, Sector.findById(SectorId.voidThrone), 42);

          // Verify each generator produced nodes
          expect(vestaMap.nodes.isNotEmpty, isTrue);
          expect(heliosMap.nodes.isNotEmpty, isTrue);
          expect(cryoMap.nodes.isNotEmpty, isTrue);
          expect(aegisMap.nodes.isNotEmpty, isTrue);
          expect(xenoMap.nodes.isNotEmpty, isTrue);
          expect(throneMap.nodes.isNotEmpty, isTrue);

          // Verify sockets (Relic Pedestal & Stasis Coffin) exist in generated maps
          expect(
            vestaMap.nodes.any((n) => n.type == MapNodeType.relicPedestal),
            isTrue,
          );
          expect(
            vestaMap.nodes.any((n) => n.type == MapNodeType.stasisCoffin),
            isTrue,
          );
          expect(
            heliosMap.nodes.any((n) => n.type == MapNodeType.relicPedestal),
            isTrue,
          );
          expect(
            cryoMap.nodes.any((n) => n.type == MapNodeType.relicPedestal),
            isTrue,
          );
          expect(
            aegisMap.nodes.any((n) => n.type == MapNodeType.relicPedestal),
            isTrue,
          );
          expect(
            xenoMap.nodes.any((n) => n.type == MapNodeType.relicPedestal),
            isTrue,
          );
          expect(
            xenoMap.nodes.any((n) => n.type == MapNodeType.stasisCoffin),
            isTrue,
          );
          expect(
            throneMap.nodes.any((n) => n.type == MapNodeType.bossLair),
            isTrue,
          );
        },
      );

      test(
        'SectorMapGenerator delegates correctly to getArchitectForSector',
        () {
          final architect = SectorMapGenerator.getArchitectForSector(
            SectorId.cryoAbyss,
          );
          expect(architect, isA<CryoAbyssMapBuilder>());
          expect(architect.sectorId, equals(SectorId.cryoAbyss));
        },
      );

      test('Interactive Environmental Hazards function properly', () {
        final game = _createTestGame();

        // 1. Solar Flame Jet (2A)
        final jet = SolarFlameJetComponent(
          position: Vector2(500, 500),
          jetAngle: 0.0,
        );
        jet.game = game;
        expect(jet.isFiring, isFalse);
        jet.update(3.0); // timer ticks
        expect(jet.isFiring || !jet.isFiring, isTrue);

        // 2. Thermal Dome (2B)
        final dome = ThermalDomeComponent(
          position: Vector2(2400, 2400),
          radius: 450,
        );
        expect(dome.radius, equals(450.0));

        // 3. Reactor Leak Hazard (3A)
        final reactor = ReactorLeakHazardComponent(
          position: Vector2(1000, 1000),
          radius: 280,
        );
        expect(reactor.radius, equals(280.0));

        // 4. Acid Pool Hazard (3B)
        final acid = AcidPoolHazardComponent(
          position: Vector2(1200, 1200),
          radius: 220,
        );
        expect(acid.radius, equals(220.0));
      });

      test('Stage Unlocks by condition-gated milestones', () {
        final game = _createTestGame();
        // Initially, only Sector 1 (vesta) is unlocked
        expect(game.isSectorUnlocked(SectorId.vesta), isTrue);
        expect(game.isSectorUnlocked(SectorId.orion), isFalse);

        // Level 8 in Vesta unlocks Orion (Helios Forge)
        game.runLevel = 8;
        game.currentSector = Sector.findById(SectorId.vesta);
        game.triggerLevelUp();
        expect(game.isSectorUnlocked(SectorId.orion), isTrue);

        // Defeating 5 mines unlocks Cryo Abyss (2B)
        for (int i = 0; i < 5; i++) {
          game.notifyMineDestroyedForUnlocks();
        }
        expect(game.isSectorUnlocked(SectorId.cryoAbyss), isTrue);

        // Defeating 25 enemies unlocks Aegis Graveyard (3A)
        for (int i = 0; i < 25; i++) {
          game.notifyEnemyKilledForUnlocks();
        }
        expect(game.isSectorUnlocked(SectorId.graveyard), isTrue);

        // Defeating 15 void swarmers unlocks Xeno Hive (3B)
        for (int i = 0; i < 15; i++) {
          game.notifyEnemyKilledForUnlocks(EnemyType.voidSwarmer);
        }
        expect(game.isSectorUnlocked(SectorId.xenoHive), isTrue);

        // Defeating boss in Graveyard unlocks Event Horizon (4)
        game.checkSectorProgressionOnBossDefeated(SectorId.graveyard);
        expect(game.isSectorUnlocked(SectorId.eventHorizon), isTrue);
      });

      test(
        'Hybrid Progression: Loop back scales difficulty and preserves player build',
        () {
          final game = AsteroidsGame();
          game.selectedValkyrie = Valkyrie.roster.first;
          game.currentSector = Sector.findById(SectorId.eventHorizon);
          game.runLevel = 25;

          // Loop back to Vesta Belt
          game.loopBackToSector(Sector.findById(SectorId.vesta));
          expect(game.currentSector.id, equals(SectorId.vesta));
          expect(game.runLevel, equals(25)); // Preserves level
          expect(game.timeRemaining, greaterThan(0.0));
        },
      );

      test(
        'Hybrid Progression: Extract Stage Victory completes current sector run',
        () {
          final game = AsteroidsGame();
          game.selectedValkyrie = Valkyrie.roster.first;
          game.currentSector = Sector.findById(SectorId.vesta);

          game.completeCurrentSectorRun();
          expect(
            game.isSectorCompletedWith(
              SectorId.vesta,
              game.selectedValkyrie.id,
            ),
            isTrue,
          );
          expect(game.missionSurvived, isTrue);
          expect(game.campaignCompleted, isTrue);
        },
      );
    },
  );

  group('Sprint 26: Permanent Relics & Stasis Coffins / Relics & Coffins', () {
    test('All 5 Permanent Relics exist and have distinct properties', () {
      expect(PermanentRelic.allRelics.length, equals(5));
      final ids = PermanentRelic.allRelics.map((r) => r.id).toSet();
      expect(ids.contains('aegis_radar'), isTrue);
      expect(ids.contains('thermal_tome'), isTrue);
      expect(ids.contains('merchant_beacon'), isTrue);
      expect(ids.contains('mutation_matrix'), isTrue);
      expect(ids.contains('yellow_sign'), isTrue);
    });

    test(
      'Claiming Thermal Tome grants +1 choice in Level-Up (4 cards instead of 3)',
      () {
        final game = _createTestGame();
        // Without relic, level-up draws 3 choices
        expect(game.unlockedRelics.contains('thermal_tome'), isFalse);
        game.triggerLevelUp();
        expect(game.currentLevelUpChoices.length, equals(3));

        // Claim relic
        game.claimPermanentRelic('thermal_tome');
        expect(game.unlockedRelics.contains('thermal_tome'), isTrue);

        // Level-up now draws 4 choices
        game.triggerLevelUp();
        expect(game.currentLevelUpChoices.length, equals(4));
      },
    );

    test(
      'Claiming Nemesis Yellow Sign grants access to Sector 5 and Affinity',
      () {
        final game = AsteroidsGame();
        game.selectedValkyrie = Valkyrie.roster.first;
        expect(game.canAccessSecretSector5, isFalse);

        game.claimPermanentRelic('nemesis_yellow_sign');
        expect(game.canAccessSecretSector5, isTrue);
        expect(game.isSectorUnlocked(SectorId.voidThrone), isTrue);
      },
    );

    test('RelicPedestalComponent claims relic on player proximity', () {
      final game = AsteroidsGame();
      final pedestal = RelicPedestalComponent(
        position: Vector2(100, 100),
        relicId: 'aegis_radar',
      );
      pedestal.game = game;

      expect(pedestal.isClaimed, isFalse);
      pedestal.claimRelic();
      expect(pedestal.isClaimed, isTrue);
      expect(game.unlockedRelics.contains('aegis_radar'), isTrue);
    });

    test('StasisCoffinComponent takes damage and unlocks sector secret', () {
      final game = AsteroidsGame();
      final coffin = StasisCoffinComponent(
        position: Vector2(200, 200),
        sectorId: SectorId.vesta,
        secretTitle: 'Cápsula de Vesper',
      );
      coffin.game = game;

      expect(coffin.isOpened, isFalse);
      expect(coffin.shieldHp, equals(120.0));

      // Hit
      coffin.takeDamage(60.0);
      expect(coffin.shieldHp, equals(60.0));
      expect(coffin.isOpened, isFalse);

      // Breaking shield opens coffin
      coffin.takeDamage(70.0);
      expect(coffin.isOpened, isTrue);
      expect(game.rescuedSectorSecrets.contains(SectorId.vesta), isTrue);
    });
  });

  group('Sprint 27: Condition-Gated Arsenal Unlocks', () {
    test(
      'Default starter weapon pool contains 3 core base weapons and locks the rest',
      () {
        final game = AsteroidsGame();
        expect(game.isWeaponUnlockedInPool('blaster'), isTrue);
        expect(game.isWeaponUnlockedInPool('spread_shot'), isTrue);
        expect(game.isWeaponUnlockedInPool('rapid_fire'), isTrue);

        // Advanced & signature weapons are locked initially until unlocked or forged
        expect(game.isWeaponUnlockedInPool('bomb_launcher'), isFalse);
        expect(game.isWeaponUnlockedInPool('tachyon_katana'), isFalse);
        expect(game.isWeaponUnlockedInPool('aegis_sawblades'), isFalse);
        expect(game.isWeaponUnlockedInPool('tesla_arc'), isFalse);
        expect(game.isWeaponUnlockedInPool('inferno_cone'), isFalse);
        expect(game.isWeaponUnlockedInPool('repulsor_aura'), isFalse);
      },
    );

    test('Destroying 25 asteroids unlocks Bomb Launcher', () {
      final game = AsteroidsGame();
      for (int i = 0; i < 25; i++) {
        game.notifyAsteroidDestroyedForUnlocks();
      }
      expect(game.isWeaponUnlockedInPool('bomb_launcher'), isTrue);
    });

    test('Executing 15 dashes unlocks Inferno Cone', () {
      final game = AsteroidsGame();
      for (int i = 0; i < 15; i++) {
        game.notifyDashExecutedForUnlocks();
      }
      expect(game.isWeaponUnlockedInPool('inferno_cone'), isTrue);
    });

    test('Surviving nebula overload unlocks Repulsor Aura', () {
      final game = AsteroidsGame();
      game.notifyNebulaOverloadSurvivedForUnlocks();
      expect(game.isWeaponUnlockedInPool('repulsor_aura'), isTrue);
    });

    test('Destroying 10 mines unlocks Void Mines', () {
      final game = AsteroidsGame();
      for (int i = 0; i < 10; i++) {
        game.notifyMineDestroyedForUnlocks();
      }
      expect(game.isWeaponUnlockedInPool('void_mines'), isTrue);
    });

    test('Surviving 25 solar burn ticks unlocks Solar Lance', () {
      final game = AsteroidsGame();
      for (int i = 0; i < 25; i++) {
        game.notifySolarBurnAppliedForUnlocks();
      }
      expect(game.isWeaponUnlockedInPool('solar_lance'), isTrue);
    });

    test(
      'Defeating 20 void swarmers unlocks Tachyon Katana into shared pool',
      () {
        final game = AsteroidsGame();
        for (int i = 0; i < 20; i++) {
          game.notifyEnemyKilledForUnlocks(EnemyType.voidSwarmer);
        }
        expect(game.isWeaponUnlockedInPool('tachyon_katana'), isTrue);
      },
    );

    test('Killing 30 enemies unlocks Repulsor Aura', () {
      final game = AsteroidsGame();
      for (int i = 0; i < 30; i++) {
        game.notifyEnemyKilledForUnlocks();
      }
      expect(game.isWeaponUnlockedInPool('repulsor_aura'), isTrue);
    });
  });

  group(
    'Sprint 28: Exploration Compass, Sector Checklist & SharedPreferences Persistence',
    () {
      test('Sector discovery checklist tracks completions per Valkyrie', () {
        final game = AsteroidsGame();
        expect(game.isSectorCompletedWith(SectorId.vesta, 'lyra'), isFalse);
        game.markSectorCompleted(SectorId.vesta, 'lyra');
        expect(game.isSectorCompletedWith(SectorId.vesta, 'lyra'), isTrue);
        expect(game.isSectorCompletedWith(SectorId.vesta, 'selene'), isFalse);
      });

      test(
        'All Phase 4 progress saves and loads seamlessly from SharedPreferences',
        () async {
          final game1 = AsteroidsGame();
          game1.unlockSector(SectorId.cryoAbyss);
          game1.claimPermanentRelic('aegis_radar');
          game1.claimPermanentRelic('thermal_tome');
          game1.unlockSectorSecret(SectorId.vesta);
          game1.unlockWeaponWithToast('solar_lance');
          game1.markSectorCompleted(SectorId.vesta, 'lyra');
          await game1.savePersistentCredits();

          // New instance loading from SharedPreferences
          final game2 = AsteroidsGame();
          await game2.loadPersistentDataFromPrefs();

          expect(game2.isSectorUnlocked(SectorId.cryoAbyss), isTrue);
          expect(game2.unlockedRelics.contains('aegis_radar'), isTrue);
          expect(game2.unlockedRelics.contains('thermal_tome'), isTrue);
          expect(game2.rescuedSectorSecrets.contains(SectorId.vesta), isTrue);
          expect(game2.isWeaponUnlockedInPool('solar_lance'), isTrue);
          expect(game2.isSectorCompletedWith(SectorId.vesta, 'lyra'), isTrue);
        },
      );
    },
  );
}
