import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flame/components.dart';
import 'package:void_protocol/game/asteroids_game.dart';
import 'package:void_protocol/game/valkyrie.dart';
import 'package:void_protocol/game/weapons.dart';
import 'package:void_protocol/game/components/player.dart';
import 'package:void_protocol/services/localization_service.dart';
import 'package:void_protocol/ui/valkyrie_selection_overlay.dart';
import 'package:void_protocol/ui/hud_overlay.dart';
import 'package:void_protocol/ui/pause_overlay.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Astra Valkyries Pilot & Vessel Roster Tests', () {
    test('Roster contains the 4 primary archetypes: KBR-01 (Protagonist // Kimberly), Lyra, Selene, Vesper', () {
      expect(Valkyrie.roster.length, equals(4));

      final ids = Valkyrie.roster.map((v) => v.id).toList();
      expect(ids, containsAll(['kbr_01', 'lyra', 'selene', 'vesper']));
      expect(Valkyrie.defaultValkyrie.id, equals('kbr_01'));
    });

    test('Each Valkyrie defines unique ship designs, weapons and distinct stat multipliers', () {
      final kbr = Valkyrie.findById('kbr_01');
      final kaedeAlias = Valkyrie.findById('kaede'); // Backwards-compatible alias
      final lyra = Valkyrie.findById('lyra');
      final selene = Valkyrie.findById('selene');
      final vesper = Valkyrie.findById('vesper');

      expect(kbr.id, equals('kbr_01'));
      expect(kbr.name, equals('KBR-01'));
      expect(kaedeAlias.id, equals('kbr_01'));
      expect(kbr.shipDesign, equals(ValkyrieShipDesign.zephyrBlade));
      expect(lyra.shipDesign, equals(ValkyrieShipDesign.solBlaze));
      expect(selene.shipDesign, equals(ValkyrieShipDesign.aegisPrism));
      expect(vesper.shipDesign, equals(ValkyrieShipDesign.eclipseFang));

      // KBR-01 (flagship agile ace) is fastest
      expect(kbr.speedMultiplier, greaterThan(lyra.speedMultiplier));
      expect(lyra.speedMultiplier, greaterThan(selene.speedMultiplier));

      // Selene tactician has largest magnet radius for Stardust collection
      expect(selene.magnetRadiusMultiplier, greaterThan(vesper.magnetRadiusMultiplier));

      // Vesper demolitionist has highest critical hit chance
      expect(vesper.critChance, greaterThan(lyra.critChance));
      expect(vesper.critChance, greaterThan(selene.critChance));

      // Starting weapons can be instantiated
      expect(kbr.createStartingWeapon(), isA<TachyonKatana>());
      expect(lyra.createStartingWeapon(), isNotNull);
      expect(selene.createStartingWeapon(), isNotNull);
      expect(vesper.createStartingWeapon(), isNotNull);
    });

    test('findById gracefully falls back to defaultValkyrie on invalid id', () {
      final fallback = Valkyrie.findById('unknown_pilot');
      expect(fallback.id, equals(Valkyrie.defaultValkyrie.id));
    });
  });

  group('Valkyrie Selection & Hangar UI Tests', () {
    testWidgets('ValkyrieSelectionOverlay renders pilots and responds to A/D or Arrow keys', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 720));
      final game = AsteroidsGame();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ValkyrieSelectionOverlay(game: game),
          ),
        ),
      );
      await tester.pump();

      // Header should display Hangar Bay in English
      expect(find.text('VOID PROTOCOL // HANGAR BAY'), findsOneWidget);
      expect(find.text('SELECT PILOT & VESSEL FOR VOID DEPLOYMENT'), findsOneWidget);

      // Initially Lyra should be displayed
      expect(find.text('LYRA'), findsWidgets);
      expect(find.text('SOLAR VANGUARD'), findsWidgets);

      // Press ArrowRight to cycle to Selene
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();

      expect(find.text('SELENE'), findsWidgets);
      expect(find.text('VOID TACTICIAN'), findsWidgets);

      // Press ArrowRight again to cycle to Vesper
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();

      expect(find.text('VESPER'), findsWidgets);
      expect(find.text('DREAD RENEGADE'), findsWidgets);
    });
  });

  group('In-Run Reactive HUD and Pilot Integration Tests', () {
    setUp(() {
      I18n.setLocaleSync(AppLocale.enUs);
    });

    tearDown(() {
      I18n.resetForTest(AppLocale.ptBr);
    });

    testWidgets('HudOverlay displays Valkyrie pilot badge, callsign, and score', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 720));
      final game = AsteroidsGame();
      game.selectedValkyrie = Valkyrie.findById('selene');
      game.player = PlayerComponent(position: Vector2(100, 100));
      game.player.valkyrie = game.selectedValkyrie;
      game.score = 1250;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HudOverlay(game: game),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('SELENE'), findsOneWidget);
      expect(find.text('// VOID TACTICIAN'), findsOneWidget);
      expect(find.text('SCORE'), findsOneWidget);
      expect(find.text('PAUSE'), findsOneWidget);
    });

    testWidgets('PauseOverlay renders English labels and pilot specs', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 720));
      final game = AsteroidsGame();
      game.selectedValkyrie = Valkyrie.findById('vesper');
      game.player = PlayerComponent(position: Vector2.zero());
      game.score = 3400;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PauseOverlay(game: game),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('SORTIE PAUSED'), findsOneWidget);
      expect(find.text('VESPER // DREAD RENEGADE'), findsOneWidget);
      expect(find.text('► RESUME SORTIE'), findsOneWidget);
      expect(find.text('RETURN TO HANGAR'), findsOneWidget);
    });
  });

  group('Vampire Survivors Multi-Weapon Stacking & Auto-Fire Tests', () {
    test('PlayerComponent stacks new weapons without discarding previous weapons', () {
      final player = PlayerComponent(position: Vector2.zero());
      final blaster = Blaster();
      player.setWeapon(blaster);

      expect(player.activeWeapons.length, equals(1));
      expect(player.activeWeapons.first.id, equals('blaster'));

      // Add SpreadShot
      final spread = SpreadShot();
      player.addWeapon(spread);

      expect(player.activeWeapons.length, equals(2));
      expect(player.activeWeapons.map((w) => w.id), containsAll(['blaster', 'spread_shot']));

      // Add RapidFire
      final rapid = RapidFire();
      player.addWeapon(rapid);

      expect(player.activeWeapons.length, equals(3));
      expect(player.activeWeapons.map((w) => w.id), containsAll(['blaster', 'spread_shot', 'rapid_fire']));

      // Upgrading blaster does not alter other weapons
      expect(blaster.level, equals(1));
      expect(spread.level, equals(1));
      expect(rapid.level, equals(1));

      player.addWeapon(Blaster()); // adding already unlocked weapon upgrades it
      expect(blaster.level, equals(2));
      expect(spread.level, equals(1));
      expect(player.activeWeapons.length, equals(3));
    });

    test('Each equipped weapon fires automatically on its independent cooldown timer', () {
      final game = AsteroidsGame();
      game.state = GameState.playing;

      final player = PlayerComponent(position: Vector2(100, 100));
      player.game = game;
      game.player = player;

      final blaster = Blaster();
      final rapid = RapidFire();
      player.setWeapon(blaster);
      player.addWeapon(rapid);

      // Initially both weapons ready
      expect(blaster.currentCooldown, equals(0.0));
      expect(rapid.currentCooldown, equals(0.0));

      // Simulate a physics tick
      player.update(0.02);

      // Both weapons should have fired and set their individual cooldowns
      expect(blaster.currentCooldown, greaterThan(0.0));
      expect(rapid.currentCooldown, greaterThan(0.0));

      // RapidFire has a shorter cooldown than Blaster
      expect(rapid.cooldown, lessThan(blaster.cooldown));
    });
  });
}
