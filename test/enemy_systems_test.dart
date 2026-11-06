import 'package:flutter_test/flutter_test.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:asteroids/game/asteroids_game.dart';
import 'package:asteroids/game/components/player.dart';
import 'package:asteroids/game/components/enemy_ship.dart';
import 'package:asteroids/game/components/enemy_bullet.dart';
import 'package:asteroids/game/components/chest.dart';
import 'package:asteroids/game/components/xp_orb.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Vampire Survivors Enemy Fleet & AI Archetype Tests', () {
    test('Scout Drone initializes with correct speed, HP and pursues player', () {
      final game = AsteroidsGame();
      game.player = PlayerComponent(position: Vector2(500, 500));
      game.state = GameState.playing;

      final scout = EnemyShipComponent(
        position: Vector2(200, 200),
        type: EnemyType.scout,
      );
      game.world.add(scout);

      expect(scout.hp, 22.0);
      expect(scout.baseSpeed, 145.0);
      expect(scout.scoreValue, 80);

      // Update AI
      scout.update(0.1);

      // Scout velocity should point towards player (positive x and y)
      expect(scout.velocity.x > 0, isTrue);
      expect(scout.velocity.y > 0, isTrue);
    });

    test('Scout Drone dies, awards score, and drops Stardust XP', () {
      final game = AsteroidsGame();
      game.player = PlayerComponent(position: Vector2(500, 500));
      game.state = GameState.playing;

      final scout = EnemyShipComponent(
        position: Vector2(200, 200),
        type: EnemyType.scout,
      );
      game.world.add(scout);

      final initialScore = game.score;
      scout.takeDamage(50.0, scout.position);

      expect(scout.hp <= 0, isTrue);
      expect(game.score, initialScore + 80);

      final orbs = game.world.children.whereType<XpOrbComponent>();
      expect(orbs.isNotEmpty, isTrue);
      expect(orbs.first.type, XpOrbType.small);
    });

    test('Phantom Raider transitions from stalking to telegraphing and charging', () {
      final game = AsteroidsGame();
      game.player = PlayerComponent(position: Vector2(500, 500));
      game.state = GameState.playing;

      final raider = EnemyShipComponent(
        position: Vector2(500, 200),
        type: EnemyType.raider,
      );
      game.world.add(raider);

      expect(raider.raiderState, RaiderState.stalking);

      // Advance past raiderTimer (1.6s) to trigger telegraphing
      raider.update(1.7);
      expect(raider.raiderState, RaiderState.telegraphing);
      expect(raider.lockedChargeDirection.length > 0, isTrue);

      // Advance past telegraph timer (0.8s) to trigger charging
      raider.update(0.9);
      expect(raider.raiderState, RaiderState.charging);
      expect(raider.velocity.length, closeTo(390.0, 1.0));
    });

    test('Corvette Sniper fires EnemyBulletComponent towards player', () {
      final game = AsteroidsGame();
      game.player = PlayerComponent(position: Vector2(500, 500));
      game.state = GameState.playing;

      final sniper = EnemyShipComponent(
        position: Vector2(500, 150),
        type: EnemyType.sniper,
      );
      game.world.add(sniper);

      sniper.shootCooldown = 0.05;
      sniper.update(0.1);

      final bullets = game.world.children.whereType<EnemyBulletComponent>();
      expect(bullets.isNotEmpty, isTrue);
      expect(bullets.first.velocity.y > 0, isTrue); // Directed down towards player
    });

    test('Void Commander (Elite Miniboss) drops guaranteed Cosmic Chest on death', () {
      final game = AsteroidsGame();
      game.player = PlayerComponent(position: Vector2(500, 500));
      game.state = GameState.playing;

      final elite = EnemyShipComponent(
        position: Vector2(500, 200),
        type: EnemyType.eliteCommander,
      );
      game.world.add(elite);

      expect(elite.hp, 650.0);
      expect(elite.scoreValue, 1500);

      // Deal lethal damage
      elite.takeDamage(700.0, elite.position);

      expect(elite.hp <= 0, isTrue);
      final chests = game.world.children.whereType<ChestComponent>();
      expect(chests.isNotEmpty, isTrue);
      expect(chests.first.tier, ChestTier.gold);

      final largeOrbs = game.world.children.whereType<XpOrbComponent>().where((o) => o.type == XpOrbType.large);
      expect(largeOrbs.length >= 2, isTrue);
    });
  });
}
