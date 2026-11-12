import 'dart:ui' show PictureRecorder;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flame/components.dart';
import 'package:asteroids/game/asteroids_game.dart';
import 'package:asteroids/game/components/player.dart';
import 'package:asteroids/game/components/asteroid.dart';
import 'package:asteroids/game/components/enemy_ship.dart';
import 'package:asteroids/game/valkyrie.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group(
    'Sprint 57: Visceral Game Feel, Input Buffering & Scaled Hit-Stop (Hades Standard)',
    () {
      test(
        'Universal Input Buffer: Dash requested 40ms before cooldown expires executes successfully',
        () {
          final game = AsteroidsGame();
          final player = PlayerComponent(position: Vector2(300, 300))
            ..customGame = game;
          game.world.add(player);
          game.player = player;
          game.state = GameState.playing;

          // Put dash on 40ms remaining cooldown
          player.dashCooldownTimer = 0.04;
          expect(player.canDash, isFalse);

          // Request dash while in cooldown - must buffer for 120ms
          player.requestDash();
          expect(
            player.dashBufferTimer,
            closeTo(PlayerComponent.inputBufferWindow, 0.001),
          );
          expect(player.isDashing, isFalse);

          // Advance time by 50ms (cooldown finishes, buffer triggers)
          player.update(0.05);

          // Buffered dash must have executed!
          expect(player.isDashing, isTrue);
          expect(player.dashBufferTimer, 0.0);
          expect(player.dashCooldownTimer, greaterThan(1.0));
        },
      );

      test(
        'Universal Input Buffer: Dash buffer expires naturally if cooldown exceeds buffer window',
        () {
          final game = AsteroidsGame();
          final player = PlayerComponent(position: Vector2(300, 300))
            ..customGame = game;
          game.world.add(player);
          game.player = player;
          game.state = GameState.playing;

          // Cooldown has 1.5s remaining
          player.dashCooldownTimer = 1.5;
          player.requestDash();
          expect(
            player.dashBufferTimer,
            closeTo(PlayerComponent.inputBufferWindow, 0.001),
          );

          // Advance time by 150ms (longer than 120ms buffer)
          player.update(0.15);

          // Buffer expired without triggering dash
          expect(player.dashBufferTimer, 0.0);
          expect(player.isDashing, isFalse);
          expect(player.dashCooldownTimer, closeTo(1.35, 0.02));
        },
      );

      test(
        'Universal Input Buffer: Special/Ultimate queued during recharge fires upon becoming available',
        () {
          final game = AsteroidsGame();
          game.player = PlayerComponent(position: Vector2(300, 300))
            ..customGame = game;
          game.state = GameState.playing;
          game.specialAvailable = false;

          // Request special while unavailable
          game.requestSpecial();
          expect(
            game.specialBufferTimer,
            closeTo(AsteroidsGame.inputBufferWindow, 0.001),
          );

          // Special becomes available right after
          game.specialAvailable = true;

          // Game update runs
          game.update(0.03);

          // Special executed and buffer consumed
          expect(game.specialBufferTimer, 0.0);
          expect(game.specialAvailable, isFalse); // consumed
        },
      );

      test(
        'Scaled Hit-Stop escalates duration by damage severity and impact weight',
        () {
          final game = AsteroidsGame();
          game.hitStopTimer = 0.0;

          // 1. Regular shot (<45 dmg): 0ms hit-stop
          game.triggerScaledHitStop(damage: 25.0);
          expect(
            game.hitStopTimer,
            0.0,
            reason: 'Regular hits maintain 120 FPS fluid stream',
          );

          // 2. Moderate hit (>=45 dmg): 35ms hit-stop
          game.triggerScaledHitStop(damage: 48.0);
          expect(game.hitStopTimer, closeTo(0.035, 0.001));

          // 3. Critical strike: 70ms hit-stop + screen shake
          game.hitStopTimer = 0.0;
          game.triggerScaledHitStop(damage: 60.0, isCrit: true);
          expect(game.hitStopTimer, closeTo(0.070, 0.001));
          expect(game.shakeTimer, greaterThan(0.0));

          // 4. Elite kill / finisher: 140ms hit-stop + visceral screen shake
          game.hitStopTimer = 0.0;
          game.triggerScaledHitStop(
            damage: 80.0,
            isCrit: true,
            isEliteKill: true,
          );
          expect(game.hitStopTimer, closeTo(0.140, 0.001));
          expect(game.shakeIntensity, greaterThanOrEqualTo(14.0));
        },
      );

      test(
        'Hit-stop micro-freeze halts entity movement while preserving particle and shake updates',
        () {
          final game = AsteroidsGame();
          game.state = GameState.playing;
          game.player = PlayerComponent(position: Vector2(200, 200))
            ..customGame = game;
          game.hitStopTimer = 0.08;
          game.shakeTimer = 0.5;

          // Advance game during hit-stop
          game.update(0.04);

          // Hit-stop decreased, shake updated, particles updated
          expect(game.hitStopTimer, closeTo(0.04, 0.005));
          expect(game.shakeTimer, closeTo(0.46, 0.005));
        },
      );

      test(
        'EnemyShip and Asteroid localFreezeTimer pauses physics and applies micro-jiggle',
        () {
          final game = AsteroidsGame();
          final enemy = EnemyShipComponent(
            type: EnemyType.eliteCommander,
            position: Vector2(100, 100),
          );
          enemy.testGame = game;
          game.world.add(enemy);

          // Heavy damage triggers localFreezeTimer
          enemy.takeDamage(55.0, Vector2(100, 100));
          expect(enemy.localFreezeTimer, greaterThan(0.0));

          // In update, position does not advance while frozen
          final posBefore = enemy.position.clone();
          enemy.update(0.016);
          expect(enemy.position.x, posBefore.x);
          expect(enemy.position.y, posBefore.y);

          // Asteroid localFreezeTimer
          final asteroid = AsteroidComponent(
            radius: 60.0,
            position: Vector2(200, 200),
            velocity: Vector2(50, 50),
          );
          asteroid.testGame = game;
          game.world.add(asteroid);

          asteroid.takeDamage(45.0, Vector2(200, 200));
          expect(asteroid.localFreezeTimer, greaterThan(0.0));

          final aPosBefore = asteroid.position.clone();
          asteroid.update(0.016);
          expect(asteroid.position.x, aPosBefore.x);
          expect(asteroid.position.y, aPosBefore.y);
        },
      );

      test(
        'Vector Inertia & Dynamic Thruster Plume scales with physical acceleration and craft mass',
        () {
          final game = AsteroidsGame();
          final player = PlayerComponent(position: Vector2(400, 400))
            ..customGame = game;
          game.world.add(player);
          game.player = player;
          game.state = GameState.playing;

          // Stationary player: zero acceleration
          player.update(0.016);
          expect(player.currentAcceleration, closeTo(0.0, 1.0));

          // Player accelerates hard (0 to 300 px/s in 16ms)
          player.velocity = Vector2(300.0, 0.0);
          player.update(0.016);
          expect(player.currentAcceleration, greaterThan(1000.0));

          // Verify rendering with dynamic plume without allocation or exception
          player.isThrusting = true;
          final recorder = PictureRecorder();
          final canvas = Canvas(recorder);
          player.render(canvas);

          // Test heavy craft (Astraea) mass scaling
          player.valkyrie = Valkyrie.findById('astraea');
          player.render(canvas);

          final picture = recorder.endRecording();
          expect(picture, isNotNull);
        },
      );
    },
  );
}
