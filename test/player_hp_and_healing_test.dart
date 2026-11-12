import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import 'package:asteroids/game/asteroids_game.dart';
import 'package:asteroids/game/components/player.dart';
import 'package:asteroids/game/components/drop.dart';
import 'package:asteroids/game/valkyrie.dart';
import 'package:asteroids/services/localization_service.dart';
import 'package:asteroids/ui/hud_overlay.dart';

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

  group('Hull HP & Damage System Tests', () {
    test('Player initializes with archetype baseHull and meta-progression bonus', () {
      final game = AsteroidsGame();
      game.metaProgression.levels['hull'] = 2; // +50 HP bonus
      game.selectedValkyrie = Valkyrie.findById('selene'); // 120 base HP

      game.player = PlayerComponent(position: Vector2.zero())..customGame = game;
      game.player.valkyrie = game.selectedValkyrie;
      game.player.initHp();

      // Expected = 120 base + 50 meta = 170 HP
      expect(game.player.maxHp, equals(170.0));
      expect(game.player.hp, equals(170.0));
      expect(game.player.hpPercent, equals(1.0));
    });

    test('Player takes non-fatal damage and does not teleport to center map', () {
      final game = AsteroidsGame();
      game.state = GameState.playing;
      game.selectedValkyrie = Valkyrie.findById('lyra'); // 100 base HP

      final spawnPos = Vector2(800, 800);
      game.player = PlayerComponent(position: spawnPos)..customGame = game;
      game.player.valkyrie = game.selectedValkyrie;
      game.player.initHp();
      game.player.invulnerableTimer = 0; // Clear spawn protection

      // Take a 30 damage hit
      game.player.takeHit(30.0);

      expect(game.player.hp, equals(70.0));
      expect(game.player.position, equals(spawnPos), reason: 'Player must remain in combat flow instead of resetting position');
      expect(game.player.isInvulnerable(), isTrue, reason: 'Must trigger brief i-frames protection');
      expect(game.state, equals(GameState.playing));
    });

    test('Lethal damage triggers mission failure when HP reaches 0', () {
      final game = AsteroidsGame();
      game.state = GameState.playing;
      game.selectedValkyrie = Valkyrie.findById('vesper'); // 90 base HP

      game.player = PlayerComponent(position: Vector2(200, 200))..customGame = game;
      game.player.valkyrie = game.selectedValkyrie;
      game.player.initHp();
      game.player.invulnerableTimer = 0; // Clear spawn protection

      // Take lethal 150 damage
      game.player.takeHit(150.0);

      expect(game.player.hp, equals(0.0));
      expect(game.missionSurvived, isFalse);
    });

    test('Player healing restores HP capped at maxHp', () {
      final game = AsteroidsGame();
      game.selectedValkyrie = Valkyrie.findById('lyra'); // 100 HP

      game.player = PlayerComponent(position: Vector2.zero())..customGame = game;
      game.player.valkyrie = game.selectedValkyrie;
      game.player.initHp();

      // Damage player down to 40 HP
      game.player.hp = 40.0;
      expect(game.player.hp, equals(40.0));

      // Heal +35 HP
      game.player.heal(35.0);
      expect(game.player.hp, equals(75.0));

      // Overheal should be clamped at maxHp (100.0)
      game.player.heal(50.0);
      expect(game.player.hp, equals(100.0));
    });
  });

  group('Random Health Drop & Pity Repair Mechanic Tests', () {
    test('DropType.health restores player HP and displays repair notification', () {
      final game = AsteroidsGame();
      game.state = GameState.playing;
      game.selectedValkyrie = Valkyrie.findById('selene'); // 120 HP

      game.player = PlayerComponent(position: Vector2.zero())..customGame = game;
      game.player.valkyrie = game.selectedValkyrie;
      game.player.initHp();
      game.player.hp = 50.0; // Damaged

      final healthDrop = DropComponent(
        position: Vector2(10, 10),
        type: DropType.health,
      )..customGame = game;

      // Collect drop
      healthDrop.onCollisionStart({Vector2.zero()}, game.player);

      expect(game.player.hp, greaterThan(50.0));
    });

    test('Enemy ships and Asteroids roll health drops with increased pity chance when player HP is low', () {
      final game = AsteroidsGame();
      game.state = GameState.playing;
      game.player = PlayerComponent(position: Vector2.zero())..customGame = game;
      game.player.valkyrie = Valkyrie.findById('lyra');
      game.player.initHp();

      // Full HP -> hpPercent is 1.0
      expect(game.player.hpPercent, equals(1.0));

      // Damaged HP -> hpPercent < 0.5 triggers pity heal roll
      game.player.hp = 30.0;
      expect(game.player.hpPercent, lessThan(0.5));
    });
  });

  group('HUD Hull Integrity Bar Widget Tests', () {
    setUp(() {
      I18n.setLocaleSync(AppLocale.enUs);
    });

    tearDown(() {
      I18n.resetForTest(AppLocale.ptBr);
    });

    testWidgets('HudOverlay displays Hull HP Bar with current and max values', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 720));
      final game = AsteroidsGame();
      game.selectedValkyrie = Valkyrie.findById('selene');

      game.player = PlayerComponent(position: Vector2(100, 100))..customGame = game;
      game.player.valkyrie = game.selectedValkyrie;
      game.player.initHp(); // 120 HP
      game.score = 610;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HudOverlay(game: game),
          ),
        ),
      );
      await tester.pump();

      // Should display HULL label and 120/120 HP
      expect(find.text('HULL'), findsOneWidget);
      expect(find.text('120/120 HP'), findsOneWidget);

      // Damage player to 75 HP
      game.player.hp = 75.0;
      await tester.pump();

      expect(find.text('75/120 HP'), findsOneWidget);
    });
  });
}
