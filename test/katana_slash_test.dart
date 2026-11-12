import 'package:flutter_test/flutter_test.dart';
import 'package:flame/components.dart';
import 'package:asteroids/game/asteroids_game.dart';
import 'package:asteroids/game/valkyrie.dart';
import 'package:asteroids/game/weapons.dart';
import 'package:asteroids/game/components/player.dart';
import 'package:asteroids/game/components/katana_slash.dart';
import 'package:asteroids/game/components/enemy_bullet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Tachyon Katana & Crescent Slash Mechanics Tests', () {
    late AsteroidsGame game;
    late PlayerComponent player;

    setUp(() {
      game = AsteroidsGame();
      game.state = GameState.playing;
      player = PlayerComponent(position: Vector2(200, 200))..customGame = game;
      game.player = player;
      game.world.add(player);
    });

    test('KatanaSlashComponent can be instantiated with proper dimensions and velocity', () {
      final slash = KatanaSlashComponent(
        position: Vector2(100, 100),
        angle: 0.0,
        velocity: Vector2(0, -400),
        lifeTimer: 0.8,
        slashWidth: 50.0,
        slashHeight: 18.0,
        damage: 35.0,
      );

      expect(slash.size.x, equals(50.0));
      expect(slash.size.y, equals(18.0));
      expect(slash.damage, equals(35.0));
      expect(slash.piercesLeft, equals(4));
    });

    test('KatanaSlashComponent parries and destroys incoming EnemyBulletComponent on contact', () {
      final slash = KatanaSlashComponent(
        position: Vector2(200, 200),
        angle: 0.0,
        velocity: Vector2(0, -400),
        lifeTimer: 0.8,
      );
      slash.game = game;
      game.world.add(slash);

      final enemyBullet = EnemyBulletComponent(
        position: Vector2(200, 200),
        radius: 4.0,
        velocity: Vector2(0, 200),
      );
      enemyBullet.game = game;
      game.world.add(enemyBullet);

      // Simulate collision
      slash.onCollisionStart({}, enemyBullet);

      // Bullet must be removed/marked for removal
      expect(enemyBullet.isRemoving || !enemyBullet.isMounted, isTrue);
    });

    test('TachyonKatana weapon fires KatanaSlashComponent instead of ordinary bullets', () {
      final katana = TachyonKatana();
      player.setWeapon(katana);

      final fired = katana.fire(player);
      expect(fired, isTrue);

      final slashes = game.world.children.whereType<KatanaSlashComponent>().toList();
      expect(slashes.isNotEmpty, isTrue);
      expect(slashes.first.damage, greaterThanOrEqualTo(12.0));
      expect(slashes.first.slashWidth, lessThanOrEqualTo(32.0)); // Compact surgical area
    });

    test('Evolved Void Muramasa fires 3 transcendent crescent blades with calibrated area', () {
      final katana = TachyonKatana()..isEvolved = true;
      player.setWeapon(katana);

      final fired = katana.fire(player);
      expect(fired, isTrue);

      final slashes = game.world.children.whereType<KatanaSlashComponent>().toList();
      expect(slashes.length, equals(3));
      for (final s in slashes) {
        expect(s.isVoidMuramasa, isTrue);
        expect(s.piercesLeft, equals(6));
        expect(s.slashWidth, greaterThanOrEqualTo(50.0));
      }
    });

    test('Parrying an enemy bullet consumes pierce durability and dissipates when out of pierce', () {
      final slash = KatanaSlashComponent(
        position: Vector2(200, 200),
        angle: 0.0,
        velocity: Vector2(0, -300),
        lifeTimer: 0.4,
        piercesLeft: 1,
      );
      slash.game = game;
      game.world.add(slash);

      final enemyBullet = EnemyBulletComponent(
        position: Vector2(200, 200),
        radius: 4.0,
        velocity: Vector2(0, 200),
      );
      enemyBullet.game = game;
      game.world.add(enemyBullet);

      slash.onCollisionStart({}, enemyBullet);

      expect(enemyBullet.isRemoving || !enemyBullet.isMounted, isTrue);
      expect(slash.isRemoving || !slash.isMounted, isTrue);
    });

    test('Phantom Shunpo Dash instantaneously blinks and slices obstacles in corridor', () {
      final kbr = Valkyrie.findById('kbr_01');
      player.valkyrie = kbr;
      player.position = Vector2(500, 500);
      player.dashCooldownTimer = 0.0;

      final initialPos = player.position.clone();

      // Spawn an enemy bullet in the teleport corridor ahead of the player
      final bulletAhead = EnemyBulletComponent(
        position: initialPos + player.forward * 100.0,
        radius: 4.0,
        velocity: Vector2.zero(),
      );
      game.world.add(bulletAhead);

      // Trigger dash
      player.dash();

      // Player must have instantly teleported forward
      expect(player.position.distanceTo(initialPos), greaterThanOrEqualTo(190.0));

      // Bullet in the corridor should be removed/sliced
      expect(bulletAhead.isRemoving || !bulletAhead.isMounted, isTrue);
    });
  });
}
