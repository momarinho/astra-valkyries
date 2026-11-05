import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flame/components.dart';
import 'package:asteroids/game/asteroids_game.dart';
import 'package:asteroids/game/valkyrie.dart';
import 'package:asteroids/game/components/player.dart';
import 'package:asteroids/ui/valkyrie_selection_overlay.dart';
import 'package:asteroids/ui/hud_overlay.dart';
import 'package:asteroids/ui/pause_overlay.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Astra Valkyries Pilot & Vessel Roster Tests', () {
    test('Roster contains the 3 primary archetypes: Lyra, Selene, Vesper', () {
      expect(Valkyrie.roster.length, equals(3));

      final ids = Valkyrie.roster.map((v) => v.id).toList();
      expect(ids, containsAll(['lyra', 'selene', 'vesper']));
    });

    test('Each Valkyrie defines unique ship designs, weapons and distinct stat multipliers', () {
      final lyra = Valkyrie.findById('lyra');
      final selene = Valkyrie.findById('selene');
      final vesper = Valkyrie.findById('vesper');

      expect(lyra.shipDesign, equals(ValkyrieShipDesign.solBlaze));
      expect(selene.shipDesign, equals(ValkyrieShipDesign.aegisPrism));
      expect(vesper.shipDesign, equals(ValkyrieShipDesign.eclipseFang));

      // Speed multipliers reflect archetypes (Lyra vanguard is fastest)
      expect(lyra.speedMultiplier, greaterThan(selene.speedMultiplier));

      // Selene tactician has largest magnet radius for Stardust collection
      expect(selene.magnetRadiusMultiplier, greaterThan(vesper.magnetRadiusMultiplier));

      // Vesper demolitionist has highest critical hit chance
      expect(vesper.critChance, greaterThan(lyra.critChance));
      expect(vesper.critChance, greaterThan(selene.critChance));

      // Starting weapons can be instantiated
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
      expect(find.text('ASTRA VALKYRIES // HANGAR BAY'), findsOneWidget);
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
}
