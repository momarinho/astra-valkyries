import 'package:flutter_test/flutter_test.dart';
import 'package:flame/components.dart';
import 'package:asteroids/game/asteroids_game.dart';
import 'package:asteroids/game/components/player.dart';
import 'package:asteroids/game/components/asteroid.dart';
import 'package:asteroids/game/components/xp_orb.dart';
import 'package:asteroids/game/components/magma_hazard.dart';
import 'package:asteroids/game/components/enemy_ship.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Asteroid Variants (Crystalline, Magma & Titanium) Tests', () {
    test('Crystalline variant does NOT divide into sub-asteroids and bursts into Stardust XP rain', () {
      final game = AsteroidsGame();
      game.player = PlayerComponent(position: Vector2(500, 500));
      game.state = GameState.playing;

      final crystal = AsteroidComponent(
        radius: 40.0,
        position: Vector2(300, 300),
        velocity: Vector2(10, 10),
        variant: AsteroidVariant.crystalline,
      );
      game.world.add(crystal);

      crystal.takeDamage(100.0, crystal.position);

      // Should not spawn child asteroids
      final remainingAsteroids = game.world.children.whereType<AsteroidComponent>();
      expect(remainingAsteroids.isEmpty, isTrue);

      // Should spawn multiple XP orbs (Stardust rain)
      final orbs = game.world.children.whereType<XpOrbComponent>();
      expect(orbs.length >= 7, isTrue);
    });

    test('Magma variant erupts into persistent MagmaHazardComponent on death', () {
      final game = AsteroidsGame();
      game.player = PlayerComponent(position: Vector2(500, 500));
      game.state = GameState.playing;

      final magma = AsteroidComponent(
        radius: 35.0,
        position: Vector2(400, 400),
        velocity: Vector2(5, 5),
        variant: AsteroidVariant.magma,
      );
      game.world.add(magma);

      magma.takeDamage(120.0, magma.position);

      final hazards = game.world.children.whereType<MagmaHazardComponent>();
      expect(hazards.isNotEmpty, isTrue);
      expect(hazards.first.position, Vector2(400, 400));
      expect(hazards.first.duration, 3.5);
    });

    test('Titanium vein variant has 1.6x HP, grants +35 scrap, drops 2 medium XP orbs and slows nearby enemies', () {
      final game = AsteroidsGame();
      game.player = PlayerComponent(position: Vector2(500, 500));
      game.state = GameState.playing;
      final initialScrap = game.runCredits;

      final titanium = AsteroidComponent(
        radius: 40.0,
        position: Vector2(400, 400),
        velocity: Vector2(2, 2),
        variant: AsteroidVariant.titanium,
      );
      game.world.add(titanium);

      // Verify 1.6x HP scaling (medium asteroid base 50.0 * 1.6 = 80.0)
      expect(titanium.maxHp, closeTo(50.0 * 1.6, 0.1));

      // Spawn an enemy within shockwave radius (140px)
      final enemy = EnemyShipComponent(
        position: Vector2(450, 400),
        type: EnemyType.scout,
      );
      game.world.add(enemy);

      titanium.takeDamage(100.0, titanium.position);

      // Verify scrap credits increased by +35
      expect(game.runCredits, initialScrap + 35);

      // Verify medium XP orbs spawned
      final mediumOrbs = game.world.children.whereType<XpOrbComponent>().where((o) => o.type == XpOrbType.medium);
      expect(mediumOrbs.length, 2);

      // Verify enemy received cryo freeze slow shockwave
      expect(enemy.cryoFreezeTimer, closeTo(3.0, 0.1));
    });
  });
}
