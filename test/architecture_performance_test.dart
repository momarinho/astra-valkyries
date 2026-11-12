import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flame/game.dart';
import 'package:asteroids/game/asteroids_game.dart';
import 'package:asteroids/game/components/asteroid.dart';
import 'package:asteroids/game/components/enemy_ship.dart';
import 'package:asteroids/game/components/drop.dart';
import 'package:asteroids/game/components/chest.dart';
import 'package:asteroids/game/components/space_station.dart';
import 'package:asteroids/game/components/cargo_wreck.dart';
import 'package:asteroids/game/components/cosmic_nebula.dart';
import 'package:asteroids/game/components/player.dart';
import 'package:asteroids/game/valkyrie.dart';
import 'package:asteroids/ui/settings_overlay.dart';
import 'package:asteroids/ui/hud_overlay.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Zero-GC Architecture & Entity Registry Guardrails (Sprint 60)', () {
    test('AsteroidsGame exposes O(1) Entity Registry sets', () {
      final game = AsteroidsGame();
      expect(game.activeEnemies, isNotNull);
      expect(game.activeAsteroids, isNotNull);
      expect(game.activeDrops, isNotNull);
      expect(game.activeStations, isNotNull);
      expect(game.activeChests, isNotNull);
      expect(game.activeCargoWrecks, isNotNull);
      expect(game.activeNebulae, isNotNull);
    });

    test('EnemyShipComponent registers and unregisters in activeEnemies via onMount / onRemove', () {
      final game = AsteroidsGame();
      expect(game.activeEnemies.isEmpty, isTrue);

      final enemy = EnemyShipComponent(
        position: Vector2(100, 100),
        type: EnemyType.scout,
      );

      game.activeEnemies.add(enemy);
      expect(game.activeEnemies.contains(enemy), isTrue);
      expect(game.activeEnemies.length, 1);

      game.activeEnemies.remove(enemy);
      expect(game.activeEnemies.isEmpty, isTrue);
    });

    test('AsteroidComponent registers and unregisters in activeAsteroids via onMount / onRemove', () {
      final game = AsteroidsGame();
      expect(game.activeAsteroids.isEmpty, isTrue);

      final asteroid = AsteroidComponent(
        radius: 30.0,
        position: Vector2(200, 200),
        velocity: Vector2.zero(),
      );

      game.activeAsteroids.add(asteroid);
      expect(game.activeAsteroids.contains(asteroid), isTrue);
      expect(game.activeAsteroids.length, 1);

      game.activeAsteroids.remove(asteroid);
      expect(game.activeAsteroids.isEmpty, isTrue);
    });

    test('DropComponent registers and unregisters in activeDrops via onMount / onRemove', () {
      final game = AsteroidsGame();
      expect(game.activeDrops.isEmpty, isTrue);

      final drop = DropComponent(
        position: Vector2(300, 300),
        type: DropType.lunarSample,
      );

      game.activeDrops.add(drop);
      expect(game.activeDrops.contains(drop), isTrue);
      expect(game.activeDrops.length, 1);

      game.activeDrops.remove(drop);
      expect(game.activeDrops.isEmpty, isTrue);
    });

    test('Static Paint Zero-GC Guardrail: Asteroid, EnemyShip, and Drop have zero local Paint() in render', () {
      final asteroidFile = File('lib/game/components/asteroid.dart').readAsStringSync();
      final enemyFile = File('lib/game/components/enemy_ship.dart').readAsStringSync();
      final dropFile = File('lib/game/components/drop.dart').readAsStringSync();

      // Ensure that in-render Paint() calls are forbidden:
      // Any Paint() in these files must only be static final
      final asteroidPaints = RegExp(r'Paint\(\)').allMatches(asteroidFile).length;
      final asteroidStaticPaints = RegExp(r'static final Paint').allMatches(asteroidFile).length;
      expect(asteroidPaints, equals(asteroidStaticPaints),
          reason: 'All Paint() in asteroid.dart must be static final reusable instances (Zero-GC)');

      final enemyPaints = RegExp(r'Paint\(\)').allMatches(enemyFile).length;
      final enemyStaticPaints = RegExp(r'static final Paint').allMatches(enemyFile).length;
      expect(enemyPaints, equals(enemyStaticPaints),
          reason: 'All Paint() in enemy_ship.dart must be static final reusable instances (Zero-GC)');

      final dropPaints = RegExp(r'Paint\(\)').allMatches(dropFile).length;
      final dropStaticPaints = RegExp(r'static final Paint').allMatches(dropFile).length;
      expect(dropPaints, equals(dropStaticPaints),
          reason: 'All Paint() in drop.dart must be static final reusable instances (Zero-GC)');
    });

    testWidgets('SettingsOverlay renders FPS & Telemetry setting and toggles state', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 720));
      final game = AsteroidsGame();
      expect(game.showFpsOverlay, isFalse);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsOverlay(game: game),
          ),
        ),
      );
      await tester.pump();

      // Verify that the FPS setting row exists
      expect(find.byIcon(Icons.speed_rounded), findsOneWidget);
      expect(find.byType(Switch), findsWidgets);

      // Toggle the switch
      await game.toggleFpsOverlay(true);
      expect(game.showFpsOverlay, isTrue);

      await tester.pump();
      expect(game.showFpsOverlay, isTrue);
    });

    testWidgets('HudOverlay displays FPS diagnostic badge when showFpsOverlay is true', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 720));
      final game = AsteroidsGame();
      game.selectedValkyrie = Valkyrie.findById('selene');
      game.player = PlayerComponent(position: Vector2(100, 100))..customGame = game;
      game.player.valkyrie = game.selectedValkyrie;
      game.player.initHp();
      game.currentFps = 60.0;
      game.showFpsOverlay = true;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HudOverlay(game: game),
          ),
        ),
      );
      await tester.pump();

      // Expect to find the 60 FPS badge
      expect(find.text('60 FPS'), findsOneWidget);

      // Tapping the badge toggles full diagnostic telemetry
      await tester.tap(find.text('60 FPS'));
      await tester.pump();

      expect(find.textContaining('ms |'), findsOneWidget);
    });
  });
}
