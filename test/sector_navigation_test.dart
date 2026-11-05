import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:flame/components.dart';
import 'package:asteroids/constants.dart';
import 'package:asteroids/game/asteroids_game.dart';
import 'package:asteroids/game/components/player.dart';
import 'package:asteroids/game/components/asteroid.dart';
import 'package:asteroids/game/components/asteroid_field.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Procedural Sector Navigation & World Dimension Tests', () {
    test('GameConstants defines large 4800x4800 sector arena', () {
      expect(GameConstants.sectorWidth, equals(4800.0));
      expect(GameConstants.sectorHeight, equals(4800.0));
      expect(GameConstants.sectorWarningDistance, equals(450.0));
      expect(GameConstants.proximitySpawnMinRadius, greaterThan(700.0));
      expect(GameConstants.proximityDespawnRadius, greaterThan(1500.0));
    });

    test('Player starts centered and is contained within sector boundaries', () {
      final player = PlayerComponent(
        position: Vector2(GameConstants.sectorWidth / 2, GameConstants.sectorHeight / 2),
      );

      expect(player.position.x, equals(2400.0));
      expect(player.position.y, equals(2400.0));
      expect(player.isNearBoundary, isFalse);

      // Move player close to the left boundary (x = 100)
      player.position.x = 100.0;
      player.enforceSectorBounds(0.1);
      expect(player.isNearBoundary, isTrue);
      expect(player.boundaryDistance, equals(100.0));

      // Attempt to breach outer boundary (x = -50)
      player.position.x = -50.0;
      player.velocity.x = -150.0;
      player.enforceSectorBounds(0.1);

      // Player must be contained inside radius with velocity deflected
      expect(player.position.x, greaterThanOrEqualTo(player.radius));
      expect(player.velocity.x, greaterThan(0.0));
    });

    test('Asteroids beyond proximity despawn distance are pruned to conserve 60 FPS mobile performance', () {
      final game = AsteroidsGame();
      final playerPos = Vector2(2400.0, 2400.0);
      game.player = PlayerComponent(position: playerPos);
      game.state = GameState.playing;

      // Asteroid nearby (distance = 500 px)
      final nearbyAsteroid = AsteroidComponent(
        radius: 30.0,
        position: Vector2(2400.0, 2900.0),
        velocity: Vector2.zero(),
      );
      expect(nearbyAsteroid.shouldPrune(playerPos), isFalse);

      // Asteroid drifted far away in deep space (distance = 2600 px > 1850 px)
      final farAsteroid = AsteroidComponent(
        radius: 30.0,
        position: Vector2(2400.0, 5000.0),
        velocity: Vector2.zero(),
      );
      expect(farAsteroid.shouldPrune(playerPos), isTrue);
      expect(farAsteroid.position.distanceTo(playerPos), greaterThan(GameConstants.proximityDespawnRadius));
    });

    test('AsteroidField spawns dynamic asteroids in proximity ring around player', () {
      final game = AsteroidsGame();
      game.player = PlayerComponent(position: Vector2(2400.0, 2400.0));
      game.state = GameState.playing;

      final field = AsteroidField();
      game.world.add(field);

      // Advance field to trigger proximity spawn
      field.spawnTimer = 5.0;
      field.update(0.1);

      final spawnedAsteroids = game.world.children.whereType<AsteroidComponent>().toList();
      expect(spawnedAsteroids.isNotEmpty, isTrue);

      final spawned = spawnedAsteroids.first;
      final distToPlayer = spawned.position.distanceTo(game.player.position);

      // Verify spawn is in proximity ring outside viewport
      expect(distToPlayer, greaterThanOrEqualTo(GameConstants.proximitySpawnMinRadius - 50.0));
      expect(distToPlayer, lessThanOrEqualTo(GameConstants.proximitySpawnMaxRadius + 50.0));

      // Verify asteroid is within sector bounds
      expect(spawned.position.x, greaterThanOrEqualTo(0.0));
      expect(spawned.position.x, lessThanOrEqualTo(GameConstants.sectorWidth));
      expect(spawned.position.y, greaterThanOrEqualTo(0.0));
      expect(spawned.position.y, lessThanOrEqualTo(GameConstants.sectorHeight));
    });
  });
}
