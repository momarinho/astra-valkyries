import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flame/components.dart';
import 'package:asteroids/game/asteroids_game.dart';
import 'package:asteroids/game/valkyrie.dart';
import 'package:asteroids/game/weapons.dart';
import 'package:asteroids/game/sector.dart';
import 'package:asteroids/game/rogue_perks.dart';
import 'package:asteroids/game/components/player.dart';
import 'package:asteroids/game/components/bullet.dart';
import 'package:asteroids/game/components/asteroid.dart';
import 'package:asteroids/game/components/cryo_pod.dart';
import 'package:asteroids/game/components/chest.dart';
import 'package:asteroids/game/components/starfield.dart';
import 'package:asteroids/ui/valkyrie_selection_overlay.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Sprint 7: Vampire Survivors Evolution Matrix Tests', () {
    test('Weapon synergies are correctly paired with their signature passives', () {
      final blasterSyn = WeaponSynergy.findByWeaponId('blaster');
      expect(blasterSyn, isNotNull);
      expect(blasterSyn!.passiveId, equals('passive_overdrive'));
      expect(blasterSyn.evolvedName, equals('Supernova Annihilator'));

      final spreadSyn = WeaponSynergy.findByWeaponId('spread_shot');
      expect(spreadSyn, isNotNull);
      expect(spreadSyn!.passiveId, equals('passive_shield_recharge'));
      expect(spreadSyn.evolvedName, equals('Hyperion Flak Storm'));

      final laserSyn = WeaponSynergy.findByWeaponId('rapid_fire');
      expect(laserSyn, isNotNull);
      expect(laserSyn!.passiveId, equals('passive_fire_rate'));
      expect(laserSyn.evolvedName, equals('Absolute Zero Tachyon Beam'));

      final bombSyn = WeaponSynergy.findByWeaponId('bomb_launcher');
      expect(bombSyn, isNotNull);
      expect(bombSyn!.passiveId, equals('passive_magnet'));
      expect(bombSyn.evolvedName, equals('Singularity Rift Torpedo'));
    });

    test('RoguePerkGenerator generates Legendary Evolution Card when MK 3 weapon has synergy passive', () {
      final game = AsteroidsGame();
      game.player = PlayerComponent(position: Vector2.zero());
      game.player.customGame = game;

      // Set Blaster directly at level 3
      final blaster = Blaster();
      blaster.level = 3;
      game.player.setWeapon(blaster);

      // Without passive: no evolution card generated
      var choices = RoguePerkGenerator.generateChoices(game);
      expect(choices.any((p) => p.type == PerkType.evolution), isFalse);

      // Acquire synergy passive module
      game.activePassives.add('passive_overdrive');

      // Now evolution card MUST appear with top priority
      choices = RoguePerkGenerator.generateChoices(game);
      final evoPerk = choices.firstWhere((p) => p.type == PerkType.evolution);
      expect(evoPerk.title, contains('SUPERNOVA ANNIHILATOR'));
      expect(evoPerk.rarity, equals(PerkRarity.legendary));

      // Selecting evolution evolves weapon
      evoPerk.onSelect(game);
      expect(blaster.isEvolved, isTrue);
    });

    test('Chest reward prioritizes super-evolution if weapon is MK 3 and synergy is acquired', () {
      final game = AsteroidsGame();
      game.player = PlayerComponent(position: Vector2.zero());
      game.player.customGame = game;

      final laser = RapidFire();
      laser.level = 3;
      game.player.setWeapon(laser);
      game.activePassives.add('passive_fire_rate');

      game.onChestCollected(ChestTier.cosmic);
      expect(game.currentChestRewards.isNotEmpty, isTrue);
      final firstReward = game.currentChestRewards.first;
      expect(firstReward.title, contains('SUPER-EVOLUTION'));
      firstReward.apply();
      expect(laser.isEvolved, isTrue);
    });
  });

  group('Sprint 7: 4 Sectors (Biomes) System Tests', () {
    test('All 4 sectors are configured with unique color palettes and hazard specs', () {
      expect(Sector.allSectors.length, equals(4));

      final vesta = Sector.findById(SectorId.vesta);
      final orion = Sector.findById(SectorId.orion);
      final graveyard = Sector.findById(SectorId.graveyard);
      final eventHorizon = Sector.findById(SectorId.eventHorizon);

      expect(vesta.difficultyLabel, equals('NORMAL'));
      expect(orion.difficultyLabel, equals('DIFÍCIL'));
      expect(graveyard.difficultyLabel, equals('EXPERT'));
      expect(eventHorizon.difficultyLabel, equals('PESADELO'));

      expect(vesta.speedMultiplier, equals(1.0));
      expect(eventHorizon.speedMultiplier, greaterThan(orion.speedMultiplier));
    });

    test('StarfieldComponent adapts dynamic nebula palette stops to current sector', () {
      final game = AsteroidsGame();
      final starfield = StarfieldComponent();
      starfield.game = game;

      // Sector 1: Vesta
      game.currentSector = Sector.findById(SectorId.vesta);
      expect(game.currentSector.paletteStops.isNotEmpty, isTrue);

      // Sector 2: Orion
      game.currentSector = Sector.findById(SectorId.orion);
      expect(game.currentSector.primaryColor, equals(const Color(0xFFFF5722)));
    });
  });

  group('Sprint 7: Easter Eggs & Secrets Tests', () {
    test('Golden Asteroid awards 5x score and +100 scrap when shattered', () {
      final game = AsteroidsGame();
      final initialCredits = game.totalCredits;

      final golden = AsteroidComponent(
        radius: 40.0,
        position: Vector2(100, 100),
        velocity: Vector2.zero(),
        variant: AsteroidVariant.golden,
      );
      golden.game = game;

      expect(golden.scoreValue, equals(150 * 5));

      golden.split();
      expect(game.totalCredits, equals(initialCredits + 100));
    });

    test('CryoPodComponent salvaging awards +500 XP and +250 Scrap', () {
      final game = AsteroidsGame();
      game.state = GameState.playing;
      game.player = PlayerComponent(position: Vector2.zero());
      game.player.customGame = game;

      final pod = CryoPodComponent(position: Vector2(10, 10));
      pod.game = game;

      final prevCredits = game.totalCredits;

      pod.salvage();
      expect(game.runLevel, greaterThan(1));
      expect(game.totalCredits, equals(prevCredits + 250));
      expect(pod.isSalvaged, isTrue);
    });

    test('Valkyrie.secretValkyrie defines Astraea with Genesis Nova and Origin Prime vessel', () {
      final astraea = Valkyrie.secretValkyrie;
      expect(astraea.id, equals('astraea'));
      expect(astraea.shipDesign, equals(ValkyrieShipDesign.originPrime));
      expect(astraea.isSecret, isTrue);

      final startingWeapon = astraea.createStartingWeapon();
      expect(startingWeapon.isEvolved, isTrue);
    });

    testWidgets('Konami Code in Hangar unlocks secret Valkyrie Astraea and +9999 Scrap', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final game = AsteroidsGame();
      final initialCredits = game.totalCredits;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ValkyrieSelectionOverlay(game: game),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter Konami Code: Up, Up, Down, Down, Left, Right, Left, Right, B, A
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyB);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
      await tester.pumpAndSettle();

      expect(game.totalCredits, equals(initialCredits + 9999));
      expect(find.text('ASTRAEA'), findsWidgets);
    });
  });

  group('Vampire Survivors Arsenal & Health Economy Calibration Tests', () {
    test('Player arsenal caps at 5 slots and perk generator stops offering new weapons', () {
      final game = AsteroidsGame();
      final player = PlayerComponent(position: Vector2.zero())..customGame = game;
      game.player = player;

      expect(PlayerComponent.maxArsenalSlots, equals(5));
      // Player starts with Blaster (slot 1)
      expect(player.activeWeapons.length, equals(1));
      expect(player.activeWeapons.first.level, equals(1));

      // Fill remaining 4 slots
      player.addWeapon(SpreadShot());
      player.addWeapon(RapidFire());
      player.addWeapon(BombLauncher());
      player.addWeapon(AegisSawblades());

      expect(player.activeWeapons.length, equals(5));

      // Attempting to add a 6th weapon is blocked
      player.addWeapon(TeslaArcCannon());
      expect(player.activeWeapons.length, equals(5));
      expect(player.unlockedWeapons.containsKey('tesla_arc'), isFalse);

      // Upgrading an existing weapon still succeeds
      player.addWeapon(Blaster());
      expect(player.activeWeapons.first.level, equals(2));

      // Perk generator should ONLY offer upgrades or passives, never newWeapon
      final perks = RoguePerkGenerator.generateChoices(game);
      expect(perks.any((p) => p.type == PerkType.newWeapon), isFalse,
          reason: 'When player has 5 weapons, no newWeapon perks should appear');
    });

    test('Calibrated weapon power curves maintain smooth progression without exponential early spikes', () {
      final blaster = Blaster();
      expect(blaster.damage, equals(26.0));
      blaster.upgrade(); // Lv 2
      expect(blaster.damage, equals(42.0));
      expect(blaster.cooldown, equals(0.52));
      blaster.upgrade(); // Lv 3
      expect(blaster.damage, equals(60.0));
      expect(blaster.cooldown, equals(0.42));
      blaster.evolve();
      expect(blaster.damage, equals(150.0));
      expect(blaster.cooldown, equals(0.16));
    });

    test('Blood Overdrive surge grants temporary x2 damage and high firing cadence without permanent mutation', () {
      final game = AsteroidsGame();
      final player = PlayerComponent(position: Vector2(200, 200))..customGame = game;
      game.player = player;
      game.world.add(player);
      game.state = GameState.playing;

      expect(player.bloodOverdriveTimer, equals(0.0));
      player.activateBloodOverdrive(10.0);
      expect(player.bloodOverdriveTimer, equals(10.0));

      final blaster = Blaster();
      blaster.fire(player);

      final bullets = game.world.children.whereType<BulletComponent>().toList();
      expect(bullets.isNotEmpty, isTrue);
      // Base damage is 26.0, with overdrive surge multiplier (x2) it is 52.0
      expect(bullets.first.damage, equals(52.0));

      // Update dt = 3.0
      player.update(3.0);
      expect(player.bloodOverdriveTimer, closeTo(7.0, 0.01));

      // Update dt = 8.0 -> expires
      player.update(8.0);
      expect(player.bloodOverdriveTimer, equals(0.0));
    });
  });
}
