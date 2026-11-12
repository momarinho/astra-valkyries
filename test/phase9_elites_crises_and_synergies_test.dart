import 'package:flutter_test/flutter_test.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:asteroids/game/asteroids_game.dart';
import 'package:asteroids/game/components/player.dart';
import 'package:asteroids/game/components/enemy_ship.dart';
import 'package:asteroids/game/components/enemy_bullet.dart';
import 'package:asteroids/game/components/asteroid.dart';
import 'package:asteroids/game/components/asteroid_field.dart';
import 'package:asteroids/game/components/xp_orb.dart';
import 'package:asteroids/services/localization_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await I18n.init();
  });

  group('Phase 9: Sprints 45 to 48 - Elites, Crises, Relic Synergies & Hit-Stop', () {
    test('Sprint 45: Elite vortex affix pulls player towards hazardous epicenter', () {
      final game = AsteroidsGame();
      game.state = GameState.playing;
      game.player = PlayerComponent(position: Vector2(100, 100))..customGame = game;

      final enemy = EnemyShipComponent(
        position: Vector2(180, 100),
        type: EnemyType.scout,
      );
      enemy.promoteToEliteWithAura(EliteAuraType.vortex);
      expect(enemy.isPromotedElite, isTrue);
      expect(enemy.eliteAura, EliteAuraType.vortex);

      game.world.add(enemy);

      final initialPlayerX = game.player.position.x;
      // Enemy update with dt = 0.5s should pull player towards x = 180
      enemy.update(0.5);

      expect(game.player.position.x > initialPlayerX, isTrue);
    });

    test('Sprint 45: Elite volatile affix detonates 6 fragmentation bullets on death', () {
      final game = AsteroidsGame();
      game.state = GameState.playing;
      game.player = PlayerComponent(position: Vector2(0, 0))..customGame = game;

      final enemy = EnemyShipComponent(
        position: Vector2(200, 200),
        type: EnemyType.scout,
      );
      enemy.promoteToEliteWithAura(EliteAuraType.volatile);
      game.world.add(enemy);
      game.update(0.01);

      expect(enemy.eliteAura, EliteAuraType.volatile);
      enemy.die();

      final bullets = game.world.children.whereType<EnemyBulletComponent>().toList();
      expect(bullets.length, 6);
      for (final b in bullets) {
        expect(b.bulletColor, const Color(0xFFFF5252));
      }
    });

    test('Sprint 46: AsteroidField executes Magma Meteorite Surge and Smuggler Convoy crises', () {
      final game = AsteroidsGame();
      game.state = GameState.playing;
      game.player = PlayerComponent(position: Vector2(500, 500))..customGame = game;

      final field = AsteroidField();
      game.world.add(field);

      // Simulate timeline reaching 36s (Magma Meteorite Surge)
      field.difficultyTimer = 34.0;
      field.update(2.0);
      expect(field.magmaSurgeSpawned, isTrue);

      final magmaAsteroids = game.world.children.whereType<AsteroidComponent>()
          .where((a) => a.variant == AsteroidVariant.magma)
          .toList();
      expect(magmaAsteroids.isNotEmpty, isTrue);

      // Simulate timeline reaching 111s (Smuggler Convoy)
      field.difficultyTimer = 109.0;
      field.update(2.0);
      expect(field.smugglerSpawned, isTrue);

      final smuggler = game.world.children.whereType<EnemyShipComponent>()
          .where((e) => e.isPromotedElite && e.eliteAura == EliteAuraType.volatile)
          .toList();
      expect(smuggler.isNotEmpty, isTrue);
    });

    test('Sprint 47: chrono_crystal relic synergy slows nearby enemy bullets on dash', () {
      final game = AsteroidsGame();
      game.state = GameState.playing;
      game.player = PlayerComponent(position: Vector2(200, 200))..customGame = game;
      game.unlockedRelics.add('chrono_crystal');

      final fastBullet = EnemyBulletComponent(
        position: Vector2(220, 200),
        radius: 4.0,
        velocity: Vector2(200, 0),
      );
      game.world.add(fastBullet);

      expect(fastBullet.velocity.x, 200.0);

      // Execute dash
      game.player.dash();

      // Nearby bullet should be decelerated to half speed (100.0)
      expect(fastBullet.velocity.x, 100.0);
    });

    test('Sprint 47: void_lens relic synergy pulls nearby XP orbs on critical damage', () {
      final game = AsteroidsGame();
      game.state = GameState.playing;
      game.player = PlayerComponent(position: Vector2(100, 100))..customGame = game;
      game.unlockedRelics.add('void_lens');

      final orb = XpOrbComponent(
        position: Vector2(250, 100),
        type: XpOrbType.small,
      );
      game.world.add(orb);

      // Trigger critical combat damage at (240, 100)
      game.spawnCombatDamageText(
        position: Vector2(240, 100),
        damage: 120.0,
        isCritical: true,
      );

      // Orb should have been pulled closer to player at (100, 100)
      expect(orb.position.x < 250.0, isTrue);
    });

    test('Sprint 48: Hit-stop temporarily halts game update for visceral arcade impact', () {
      final game = AsteroidsGame();
      game.state = GameState.playing;
      expect(game.hitStopTimer, 0.0);

      game.triggerHitStop(0.08);
      expect(game.hitStopTimer, 0.08);

      // Update with dt = 0.03s should consume hitStopTimer without running gameplay logic
      game.update(0.03);
      expect(game.hitStopTimer, closeTo(0.05, 0.001));

      // Update remaining dt
      game.update(0.06);
      expect(game.hitStopTimer, 0.0);
    });
  });
}
