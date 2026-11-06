import 'package:flutter_test/flutter_test.dart';
import 'package:flame/components.dart';
import 'package:asteroids/game/asteroids_game.dart';
import 'package:asteroids/game/components/player.dart';
import 'package:asteroids/game/components/asteroid.dart';
import 'package:asteroids/game/components/xp_orb.dart';
import 'package:asteroids/game/components/magma_hazard.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Asteroid Variants (Crystalline & Magma) Tests', () {
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
  });
}
