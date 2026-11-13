import 'package:flutter_test/flutter_test.dart';
import 'package:flame/components.dart';
import 'package:asteroids/game/components/asteroid.dart';
import 'package:asteroids/game/components/player.dart';
import 'package:asteroids/game/weapons.dart';
import 'package:asteroids/game/asteroids_game.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Asteroid Inverted Scoring Tests', () {
    test(
      'Small asteroids score 300 pts, medium score 150 pts, large score 50 pts',
      () {
        final smallAsteroid = AsteroidComponent(
          radius: 20.0,
          position: Vector2.zero(),
          velocity: Vector2.zero(),
        );
        final mediumAsteroid = AsteroidComponent(
          radius: 35.0,
          position: Vector2.zero(),
          velocity: Vector2.zero(),
        );
        final largeAsteroid = AsteroidComponent(
          radius: 60.0,
          position: Vector2.zero(),
          velocity: Vector2.zero(),
        );

        expect(
          smallAsteroid.scoreValue,
          equals(300),
          reason: 'Small asteroids must reward highest points (+300)',
        );
        expect(
          mediumAsteroid.scoreValue,
          equals(150),
          reason: 'Medium asteroids reward intermediate points (+150)',
        );
        expect(
          largeAsteroid.scoreValue,
          equals(50),
          reason: 'Large asteroids reward opening points (+50)',
        );
      },
    );
  });

  group('Weapon Balance and Evolution Tests', () {
    test('All 4 weapons start at level 1 and upgrade properly to level 5', () {
      final blaster = Blaster();
      final spread = SpreadShot();
      final rapid = RapidFire();
      final bomb = BombLauncher();

      // Check initial level 1 stats
      expect(blaster.level, equals(1));
      expect(blaster.maxLevel, equals(5));
      expect(blaster.damage, equals(26.0));
      expect(blaster.cooldown, equals(0.70));

      expect(spread.level, equals(1));
      expect(spread.damage, equals(14.0));
      expect(spread.cooldown, equals(0.95));
      expect(spread.recoil, equals(14.0));

      expect(rapid.level, equals(1));
      expect(rapid.cooldown, equals(0.32));
      expect(rapid.damage, equals(10.0));

      expect(bomb.level, equals(1));
      expect(bomb.damage, equals(80.0));
      expect(bomb.cooldown, equals(1.80));
      expect(bomb.recoil, equals(22.0));

      // Test Upgrade to Level 2
      expect(blaster.upgrade(), isTrue);
      expect(spread.upgrade(), isTrue);
      expect(rapid.upgrade(), isTrue);
      expect(bomb.upgrade(), isTrue);

      expect(blaster.level, equals(2));
      expect(blaster.damage, equals(34.0));
      expect(spread.level, equals(2));
      expect(spread.damage, equals(18.0));
      expect(rapid.level, equals(2));
      expect(rapid.damage, equals(13.0));
      expect(bomb.level, equals(2));
      expect(bomb.damage, equals(105.0));

      // Upgrade through Level 3, 4 to Level 5 (Max)
      for (var i = 0; i < 3; i++) {
        expect(blaster.upgrade(), isTrue);
        expect(spread.upgrade(), isTrue);
        expect(rapid.upgrade(), isTrue);
        expect(bomb.upgrade(), isTrue);
      }

      expect(blaster.level, equals(5));
      expect(spread.level, equals(5));
      expect(rapid.level, equals(5));
      expect(bomb.level, equals(5));

      // Cannot upgrade beyond max
      expect(blaster.upgrade(), isFalse);
    });

    test(
      'Weapons DO NOT upgrade automatically by time or score; progression is purely roguelike',
      () {
        final game = AsteroidsGame();
        game.player = PlayerComponent(position: Vector2.zero());
        game.state = GameState.playing;
        final startingWeapon = game.player.weapon;
        expect(startingWeapon.level, equals(1));

        // Destroy asteroids pushing score beyond 1200 and 3000
        game.onAsteroidDestroyed(Vector2.zero(), 1500);
        expect(game.score, equals(1500));
        expect(
          game.player.weapon.level,
          equals(1),
          reason: 'Weapon must NOT auto-upgrade at 1200 points',
        );

        game.onAsteroidDestroyed(Vector2.zero(), 2000);
        expect(game.score, equals(3500));
        expect(
          game.player.weapon.level,
          equals(1),
          reason: 'Weapon must NOT auto-upgrade at 3000 points',
        );
      },
    );
  });
}
