import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:asteroids/game/asteroids_game.dart';
import 'package:asteroids/game/sector.dart';
import 'package:asteroids/game/components/player.dart';
import 'package:asteroids/game/components/joystick.dart';
import 'package:asteroids/game/components/scrap_goliath.dart';
import 'package:asteroids/game/components/void_singularity_core.dart';
import 'package:asteroids/game/components/proximity_mine.dart';
import 'package:asteroids/game/components/derelict_turret.dart';
import 'package:asteroids/game/components/hyperspace_gate.dart';
import 'package:asteroids/game/components/chest.dart';
import 'package:asteroids/game/components/boss_lair.dart';
import 'package:asteroids/game/map/sector_map_generator.dart';
import 'package:asteroids/ui/pause_overlay.dart';
import 'package:asteroids/ui/game_over_overlay.dart';
import 'package:asteroids/ui/title_screen_overlay.dart';

AsteroidsGame _createTestGame() {
  final game = AsteroidsGame();
  game.player = PlayerComponent(position: Vector2(2400, 2400))..customGame = game;
  game.joystick = GameJoystick();
  game.state = GameState.playing;
  return game;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('xyz.luan/audioplayers.global'),
    (call) async => null,
  );
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('xyz.luan/audioplayers'),
    (call) async => null,
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Masterpiece Expansion (Sprints 8 to 12)', () {
    test('Sprint 8: Sector 3 Graveyard generates Proximity Mines, Derelict Turrets & awakens Scrap Goliath', () async {
      final game = _createTestGame();
      game.currentSector = Sector.findById(SectorId.graveyard);
      SectorMapGenerator.generateAndSpawn(game, customSeed: 42);
      await Future<void>.delayed(Duration.zero);

      final mines = game.world.children.whereType<ProximityMineComponent>().toList();
      final turrets = game.world.children.whereType<DerelictTurretComponent>().toList();
      expect(mines.length, greaterThanOrEqualTo(4));
      expect(turrets.length, greaterThanOrEqualTo(2));

      // Trigger boss encounter in Sector 3 -> Scrap Goliath
      game.triggerBossEncounter();
      await Future<void>.delayed(Duration.zero);

      expect(game.activeBoss, isA<ScrapGoliathComponent>());
      final goliath = game.activeBoss as ScrapGoliathComponent;
      expect(goliath.maxHp, 4500.0);

      // Deal lethal damage to Scrap Goliath
      final killed = goliath.takeDamage(5000.0, goliath.position);
      expect(killed, isTrue);
      expect(goliath.isDefeated, isTrue);
      await Future<void>.delayed(Duration.zero);

      expect(game.world.children.whereType<ChestComponent>().isNotEmpty, isTrue);
      expect(game.world.children.whereType<HyperspaceGateComponent>().isNotEmpty, isTrue);
    });

    test('Sprint 8: Sector 4 Event Horizon awakens Void Singularity Core and unlocks Campaign Victory', () async {
      final game = _createTestGame();
      game.currentSector = Sector.findById(SectorId.eventHorizon);

      game.triggerBossEncounter();
      await Future<void>.delayed(Duration.zero);

      expect(game.activeBoss, isA<VoidSingularityCoreComponent>());
      final core = game.activeBoss as VoidSingularityCoreComponent;
      expect(core.maxHp, 6000.0);

      // Defeat Void Singularity Core
      final killed = core.takeDamage(6500.0, core.position);
      expect(killed, isTrue);
      expect(game.campaignCompleted, isTrue);
      expect(game.hyperModeUnlocked, isTrue);

      // Jumping into the final Hyperspace Gate completes the campaign with survival victory
      game.jumpToNextSector();
      expect(game.missionSurvived, isTrue);
      expect(game.state, GameState.gameOver);
    });

    test('Sprint 9: Maxed Weapon + Passive Synergy triggers Superweapon Evolution in Cosmic Chest', () {
      final game = _createTestGame();

      // Upgrade starting weapon (blaster) to MK 3 and equip passive_overdrive
      final blaster = game.player.activeWeapons.first;
      blaster.upgrade(); // MK 2
      blaster.upgrade(); // MK 3
      expect(blaster.level, blaster.maxLevel);
      game.activePassives.add('passive_overdrive');

      game.onChestCollected(ChestTier.cosmic);
      expect(game.currentChestRewards.first.title, contains('Supernova Annihilator'));

      game.claimChestRewards();
      expect(blaster.isEvolved, isTrue);
    });

    test('Sprint 10: Virtual Joystick applies 0.12 radial deadzone', () async {
      final game = _createTestGame();
      final joy = game.joystick;
      await game.add(joy);

      joy.isDragging = true;
      // Small micro-movement inside 12% deadzone (5px out of 60px radius = 0.083)
      joy.knobPosition = Vector2(5.0, 0.0);
      joy.update(0.016);
      expect(joy.stickInput.length, 0.0);

      // Deliberate drag outside deadzone (30px out of 60px radius = 0.5)
      joy.knobPosition = Vector2(30.0, 0.0);
      joy.update(0.016);
      expect(joy.stickInput.x, closeTo(0.5, 0.01));
    });

    test('Sprint 11: Hyper Mode grants +25% Speed and +50% XP & Scrap', () {
      final game = _createTestGame();

      game.isHyperMode = false;
      game.startGame();
      final normalMaxSpeed = game.player.movementMaxSpeed;

      game.isHyperMode = true;
      game.startGame();
      final hyperMaxSpeed = game.player.movementMaxSpeed;

      expect(hyperMaxSpeed, closeTo(normalMaxSpeed * 1.25, 0.1));

      final initialCredits = game.runCredits;
      game.addRunCredits(100);
      expect(game.runCredits - initialCredits, 150);

      final initialXp = game.runXp;
      game.addXp(10);
      expect(game.runXp - initialXp, 15);
    });

    test('Sprint 11: Boss Rush Mode sequences all 4 Sovereign Titans to Victory', () async {
      final game = _createTestGame();
      game.isBossRushMode = true;
      game.startGame();
      await Future<void>.delayed(Duration.zero);

      // Stage 0: Dreadnought Leviathan
      expect(game.bossRushStage, 0);
      expect(game.activeBoss?.bossName, contains('DREADNOUGHT'));

      // Advance through all 4 stages
      game.onBossRushBossDefeated(game.player.position);
      await Future<void>.delayed(Duration.zero);
      expect(game.bossRushStage, 1);
      expect(game.activeBoss?.bossName, contains('IGNIS WYRM'));

      game.onBossRushBossDefeated(game.player.position);
      await Future<void>.delayed(Duration.zero);
      expect(game.bossRushStage, 2);
      expect(game.activeBoss?.bossName, contains('SCRAP GOLIATH'));

      game.onBossRushBossDefeated(game.player.position);
      await Future<void>.delayed(Duration.zero);
      expect(game.bossRushStage, 3);
      expect(game.activeBoss?.bossName, contains('VOID SINGULARITY'));

      game.onBossRushBossDefeated(game.player.position);
      expect(game.campaignCompleted, isTrue);
      expect(game.missionSurvived, isTrue);
    });

    testWidgets('Sprint 9 & 12: PauseOverlay Cosmic Grimoire and GameOverOverlay Victory Banner render cleanly', (tester) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final game = _createTestGame();

      await tester.pumpWidget(
        MaterialApp(
          home: PauseOverlay(game: game),
        ),
      );
      await tester.pump();

      expect(find.text('✨ GRIMÓRIO CÓSMICO'), findsOneWidget);
      await tester.tap(find.text('✨ GRIMÓRIO CÓSMICO'));
      await tester.pump();

      expect(find.textContaining('SUPERNOVA ANNIHILATOR'), findsOneWidget);
      expect(find.textContaining('SINGULARITY RIFT TORPEDO'), findsOneWidget);

      // Verify Victory Screen in GameOverOverlay
      game.campaignCompleted = true;
      game.missionSurvived = true;
      await tester.pumpWidget(
        MaterialApp(
          home: GameOverOverlay(game: game),
        ),
      );
      await tester.pump();

      expect(find.textContaining('VICTORY // VOID SINGULARITY CONQUERED!'), findsOneWidget);
    });

    testWidgets('Sprint 12: TitleScreenOverlay runs Bootloader Loading Sequence and transitions to Main Menu', (tester) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final game = _createTestGame();
      game.state = GameState.menu;

      await tester.pumpWidget(
        MaterialApp(
          home: TitleScreenOverlay(game: game),
        ),
      );
      await tester.pump();

      // Initially in Bootloader Loading Screen
      expect(find.textContaining('VOID PROTOCOL BOOTLOADER'), findsOneWidget);

      // Advance boot sequence or tap to skip into Main Title Menu
      await tester.tap(find.byType(TitleScreenOverlay));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('ASTRA VALKYRIES'), findsOneWidget);
      expect(find.textContaining('INICIAR OPERAÇÃO // HANGAR'), findsOneWidget);
      expect(find.textContaining('LOJA & OFICINA // UPGRADES'), findsOneWidget);
      expect(find.textContaining('HALL DA FAMA // LEADERBOARD'), findsNothing);

      // Tap LOJA & OFICINA // UPGRADES -> opens Hangar directly on Workshop tab (1)
      await tester.tap(find.textContaining('LOJA & OFICINA // UPGRADES'));
      await tester.pump();
      expect(game.state, GameState.valkyrieSelection);
      expect(game.initialHangarTab, 1);
    });

    test('Hybrid Boss Altar (Vampire Survivors + Risk of Rain): Altar stays sealed until 2 Signal Beacons are charged', () async {
      final game = _createTestGame();
      SectorMapGenerator.generateAndSpawn(game, customSeed: 77);
      await Future<void>.delayed(Duration.zero);

      final lair = game.world.children.whereType<BossLairComponent>().first;
      expect(lair.requiresBeaconCharge, isTrue);
      expect(game.beaconsCharged, 0);
      expect(game.isBossAltarUnlocked, isFalse);

      // Fly inside Altar while beacons are 0/2 -> Altar remains sealed, boss does NOT awaken
      game.player.position = lair.position.clone();
      lair.update(1.0);
      expect(lair.isAwakened, isFalse);
      expect(game.activeBoss, isNull);

      // Charge 2 Beacons (e.g. from Sub-Bosses / POIs)
      game.chargeBossBeacon('SUB-CHEFE ABATIDO');
      expect(game.isBossAltarUnlocked, isFalse);
      game.chargeBossBeacon('ESTAÇÃO DE PESQUISA');
      expect(game.isBossAltarUnlocked, isTrue);

      // Stay inside unlocked Altar to synchronize Teleporter Ritual (2.0s)
      lair.update(2.0);
      expect(lair.isAwakened, isTrue);
      expect(game.activeBoss, isNotNull);
    });

    test('Mobile Hybrid Control: Virtual Joystick moves 360° and locks nose angle when Aim Lock is active', () {
      final game = _createTestGame();
      final joy = game.joystick;

      // Player starts aiming North (angle = 0.0)
      game.player.angle = 0.0;
      game.isAimLocked = true;

      // Drag joystick South (y = +1.0) while Aim Lock is active -> ship flies South (backward) while nose stays North (0.0)!
      joy.isDragging = true;
      joy.stickInput.setValues(0.0, 1.0);
      game.player.update(0.1);

      expect(game.player.angle, closeTo(0.0, 0.001));
      expect(game.player.velocity.y, greaterThan(0.0));
    });
  });
}
