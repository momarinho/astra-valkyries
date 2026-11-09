import 'dart:io';
import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:asteroids/game/asteroids_game.dart';
import 'package:asteroids/game/sector.dart';
import 'package:asteroids/game/weapons.dart';
import 'package:asteroids/game/rogue_perks.dart';
import 'package:asteroids/game/roguelite_systems.dart';
import 'package:asteroids/game/valkyrie.dart';
import 'package:asteroids/game/affinity_system.dart';
import 'package:asteroids/game/map/sector_map_generator.dart';
import 'package:asteroids/game/components/player.dart';
import 'package:asteroids/game/components/enemy_ship.dart';
import 'package:asteroids/game/components/advanced_weapons.dart';
import 'package:asteroids/game/components/dead_cells_biome.dart';
import 'package:asteroids/game/components/sector_boss.dart';
import 'package:asteroids/game/components/dreadnought_leviathan.dart';
import 'package:asteroids/ui/star_chart_overlay.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Phase 2 Expansion (Sprints 13 to 18) Full Verification', () {
    test('Sprint 13: Dead Cells Biome Architecture spawns Walls, Laser Gates, Vaults, Merchant & Shrine', () {
      final game = AsteroidsGame();
      game.player = PlayerComponent(position: Vector2(2400, 2400))..customGame = game;
      game.currentSector = Sector.findById(SectorId.vesta);
      game.state = GameState.playing;

      final mapData = SectorMapGenerator.generateAndSpawn(game);

      expect(mapData.nodes.length, greaterThanOrEqualTo(10));
      expect(game.world.children.whereType<MegastructureWallComponent>(), isNotEmpty);
      expect(game.world.children.whereType<LaserContainmentGateComponent>(), isNotEmpty);
      expect(game.world.children.whereType<TimedVaultComponent>(), isNotEmpty);
      expect(game.world.children.whereType<FlawlessVaultComponent>(), isNotEmpty);
      expect(game.world.children.whereType<VoidMerchantComponent>(), isNotEmpty);
      expect(game.world.children.whereType<CursedShrineComponent>(), isNotEmpty);
    });

    test('Sprint 13: Branching Star Chart routes offer alternate biomes (2A/2B and 3A/3B)', () {
      final vesta = Sector.findById(SectorId.vesta);
      final vestaBranches = Sector.getNextBranchChoices(vesta);
      expect(vestaBranches.map((s) => s.id), containsAll([SectorId.orion, SectorId.cryoAbyss]));

      final cryo = Sector.findById(SectorId.cryoAbyss);
      final cryoBranches = Sector.getNextBranchChoices(cryo);
      expect(cryoBranches.map((s) => s.id), containsAll([SectorId.graveyard, SectorId.xenoHive]));
    });

    testWidgets('Sprint 13 & 16: StarChartOverlay displays branching sectors and Pilot Mutations', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 720));
      final game = AsteroidsGame();
      game.player = PlayerComponent(position: Vector2(2400, 2400))..customGame = game;
      game.currentSector = Sector.findById(SectorId.vesta);
      game.state = GameState.starChart;

      await tester.pumpWidget(
        MaterialApp(
          home: StarChartOverlay(game: game),
        ),
      );
      await tester.pump();

      expect(find.textContaining('MAPA ESTELAR DE HIPERESPAÇO'), findsOneWidget);
      expect(find.byKey(const Key('confirm_star_chart_jump_button')), findsOneWidget);

      await tester.tap(find.byKey(const Key('confirm_star_chart_jump_button')));
      await tester.pump();

      expect(game.currentSector.id, anyOf(equals(SectorId.orion), equals(SectorId.cryoAbyss)));
      expect(game.activeMutations, isNotEmpty);
    });

    test('Sprint 14: All 12 playable weapons fire, upgrade, and have Super-Evolution synergies', () {
      final game = AsteroidsGame();
      final player = PlayerComponent(position: Vector2(2400, 2400))..customGame = game;
      game.player = player;
      game.state = GameState.playing;

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

      expect(WeaponSynergy.allSynergies.length, equals(12));

      for (final w in allWeapons) {
        expect(w.fire(player), isTrue, reason: 'Weapon ${w.id} should fire at MK 1');
        w.upgrade();
        w.upgrade();
        expect(w.level, equals(w.maxLevel));
        w.evolve();
        expect(w.isEvolved, isTrue, reason: 'Weapon ${w.id} should evolve at MK MAX');
        expect(w.fire(player), isTrue, reason: 'Weapon ${w.id} should fire when evolved');
      }
    });

    test('Sprint 14: 4 Elemental Statuses & Cross-Elemental Synergy reactions on Enemies and Bosses', () {
      final game = AsteroidsGame();
      final player = PlayerComponent(position: Vector2(2400, 2400))..customGame = game;
      game.player = player;
      game.state = GameState.playing;

      final enemy = EnemyShipComponent(
        position: Vector2(2400, 2200),
        type: EnemyType.eliteCommander,
      );
      final initialHp = enemy.hp;

      enemy.applyElementalStatus(ElementalStatus.solarBurn, duration: 4.0);
      expect(enemy.hasStatus(ElementalStatus.solarBurn), isTrue);

      // Apply a second elemental status to trigger Cross-Elemental Synergy reaction damage
      enemy.applyElementalStatus(ElementalStatus.cryoFreeze, duration: 3.0);
      expect(enemy.hasStatus(ElementalStatus.cryoFreeze), isTrue);
      expect(enemy.hp, lessThan(initialHp));

      // Boss elemental status check
      final SectorBoss boss = DreadnoughtLeviathanComponent(position: Vector2(2400, 1800));
      boss.applyElementalStatus(ElementalStatus.ionShock);
      expect(boss.hasStatus(ElementalStatus.ionShock), isTrue);
    });

    test('Sprint 15: Faction Bestiary & Aegis Bulwark directional frontal shield mechanics', () {
      final game = AsteroidsGame();
      final player = PlayerComponent(position: Vector2(2400, 2400))..customGame = game;
      game.player = player;
      game.state = GameState.playing;

      final bulwark = EnemyShipComponent(
        position: Vector2(2400, 2200),
        type: EnemyType.aegisBulwark,
      );
      bulwark.angle = math.pi; // Facing downward toward player at (2400, 2400)

      final hpBeforeFront = bulwark.hp;
      // Hit from the front (2400, 2300) -> blocked by frontal shield (only 20% damage = 4.0)
      bulwark.takeDamage(20.0, Vector2(2400, 2300));
      final frontDamageTaken = hpBeforeFront - bulwark.hp;
      expect(frontDamageTaken, closeTo(4.0, 0.1));

      final hpBeforeRear = bulwark.hp;
      // Flank hit from behind (2400, 2100) -> full 100% damage = 20.0
      bulwark.takeDamage(20.0, Vector2(2400, 2100));
      final rearDamageTaken = hpBeforeRear - bulwark.hp;
      expect(rearDamageTaken, closeTo(20.0, 0.1));
    });

    test('Sprint 16: Blueprints drop, Forge unlocks weapons permanently & Void Cells scale rewards', () {
      final game = AsteroidsGame();
      game.player = PlayerComponent(position: Vector2(2400, 2400))..customGame = game;
      game.state = GameState.playing;
      game.totalCredits = 5000;

      // Guaranteed blueprint drop
      final initialFound = game.foundBlueprints.length;
      game.tryDropBlueprint(Vector2(2400, 2400), guaranteed: true);
      expect(game.foundBlueprints.length, equals(initialFound + 1));

      final newlyFoundId = game.foundBlueprints.difference(game.forgedBlueprints).first;
      expect(game.isWeaponUnlockedInPool(newlyFoundId), isFalse);

      final forged = game.forgeBlueprint(newlyFoundId);
      expect(forged, isTrue);
      expect(game.isWeaponUnlockedInPool(newlyFoundId), isTrue);
      expect(game.unlockedMilestones, contains('ach_blueprint_forge'));

      // Void Cells multiplier check
      game.voidCellsLevel = 4; // +100% scrap
      final creditsBefore = game.runCredits;
      game.addRunCredits(100);
      expect(game.runCredits - creditsBefore, equals(200));
    });

    test('Sprint 17 & 18: Clean Ship Nose, Synthesized WAVs, 2D Anime Art Assets & Hades Dialogues', () {
      final game = AsteroidsGame();
      final player = PlayerComponent(position: Vector2(2400, 2400))..customGame = game;
      game.player = player;

      expect(player.hasTacticalLaserSight, isFalse);

      // Verify synthesized WAV audio files exist
      for (final wav in ['level_up.wav', 'chest_open.wav', 'beacon_charge.wav', 'boss_spawn.wav']) {
        expect(File('assets/sounds/$wav').existsSync(), isTrue, reason: 'Missing $wav');
      }

      // Verify all Valkyries (Lyra, Selene, Vesper, Astraea) have real artwork on disk
      for (final v in Valkyrie.allValkyries) {
        expect(File(v.hangarFullBodyAsset).existsSync(), isTrue, reason: 'Missing ${v.hangarFullBodyAsset}');
        expect(File(v.hudNeutralAsset).existsSync(), isTrue, reason: 'Missing ${v.hudNeutralAsset}');
        expect(File(v.hudDamagedAsset).existsSync(), isTrue, reason: 'Missing ${v.hudDamagedAsset}');
        expect(File(v.hudUltimateAsset).existsSync(), isTrue, reason: 'Missing ${v.hudUltimateAsset}');
      }

      // Verify all Gallery Memories have real artwork on disk
      for (final mem in AffinityManager.allMemories) {
        expect(File(mem.imageAsset).existsSync(), isTrue, reason: 'Missing gallery CG ${mem.imageAsset}');
      }

      // Verify Hades-style reactive post-run dialogue
      final victoryLine = game.affinityManager.getReactivePostRunDialogue(
        'vesper',
        lastBoss: 'IGNIS WYRM',
        wasVictory: true,
      );
      expect(victoryLine, contains('IGNIS WYRM'));

      final defeatLine = game.affinityManager.getReactivePostRunDialogue(
        'lyra',
        lastBoss: 'SCRAP GOLIATH',
        wasVictory: false,
      );
      expect(defeatLine, contains('SCRAP GOLIATH'));
    });

    test('Cursed Shrine and Void Merchant grant temporary 10s blood overdrive instead of permanent weapon evolutions', () {
      final game = AsteroidsGame();
      final player = PlayerComponent(position: Vector2(300, 300))..customGame = game;
      game.player = player;
      game.world.add(player);
      game.state = GameState.playing;

      final initialWeapon = player.activeWeapons.first;
      expect(initialWeapon.level, equals(1));
      expect(initialWeapon.isEvolved, isFalse);

      final shrine = CursedShrineComponent(position: Vector2(300, 300));
      game.world.add(shrine);
      shrine.customGame = game;

      // Activate shrine
      player.hp = 100.0;
      shrine.activateShrine();

      expect(shrine.isActivated, isTrue);
      expect(player.bloodOverdriveTimer, equals(10.0));
      expect(player.invulnerableTimer, equals(2.5));
      // Weapon should remain level 1 and NOT be permanently evolved
      expect(initialWeapon.level, equals(1));
      expect(initialWeapon.isEvolved, isFalse);
      expect(player.hp, closeTo(85.0, 0.1)); // 15% non-lethal sacrifice
    });
  });
}
