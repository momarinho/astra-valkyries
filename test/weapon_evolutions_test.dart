import 'package:flutter_test/flutter_test.dart';
import 'package:flame/components.dart';
import 'package:asteroids/game/asteroids_game.dart';
import 'package:asteroids/game/components/player.dart';
import 'package:asteroids/game/components/bullet.dart';
import 'package:asteroids/game/components/bomb.dart';
import 'package:asteroids/game/components/singularity_rift.dart';
import 'package:asteroids/game/components/chest.dart';
import 'package:asteroids/game/weapons.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Sprint 3: Weapon Super-Evolutions & Vampire Survivors Mechanics Tests', () {
    test(
      'Blaster evolves into Supernova Annihilator with dual piercing gold plasma bolts',
      () {
        final game = AsteroidsGame();
        game.player = PlayerComponent(position: Vector2(500, 500))
          ..customGame = game;
        game.world.add(game.player);
        game.state = GameState.playing;

        final blaster = Blaster();
        game.player.setWeapon(blaster);

        // Upgrade to MK 2 .. MK 5 (MAX)
        expect(blaster.level, 1);
        expect(blaster.canEvolve, isFalse);

        while (blaster.level < blaster.maxLevel) {
          expect(blaster.canEvolve, isFalse);
          expect(blaster.upgrade(), isTrue);
        }

        expect(blaster.level, 5);
        expect(blaster.canEvolve, isTrue);
        expect(blaster.isEvolved, isFalse);

        // Super-Evolution
        final success = blaster.evolve();
        expect(success, isTrue);
        expect(blaster.isEvolved, isTrue);
        expect(blaster.evolvedName, 'Supernova Annihilator');
        expect(blaster.cooldown, 0.16);
        expect(blaster.damage, 150.0);

        // Fire evolved weapon
        blaster.fire(game.player);
        final bullets = game.world.children
            .whereType<BulletComponent>()
            .toList();
        expect(bullets.length, 2); // Dual parallel bolts
        expect(bullets.first.piercesLeft, 99); // Infinite piercing
      },
    );

    test(
      'SpreadShot evolves into Hyperion Flak Storm firing 10-way 360-degree perimeter ring',
      () {
        final game = AsteroidsGame();
        game.player = PlayerComponent(position: Vector2(500, 500))
          ..customGame = game;
        game.world.add(game.player);
        game.state = GameState.playing;

        final spread = SpreadShot();
        spread.level = spread.maxLevel;
        expect(spread.canEvolve, isTrue);

        spread.evolve();
        expect(spread.isEvolved, isTrue);
        expect(spread.evolvedName, 'Hyperion Flak Storm');
        expect(spread.cooldown, 0.38);

        spread.fire(game.player);
        final bullets = game.world.children
            .whereType<BulletComponent>()
            .toList();
        expect(bullets.length, 10); // 10-way omnidirectional flak
      },
    );

    test(
      'RapidFire evolves into Absolute Zero Tachyon Beam with ultra-fast glacial stream',
      () {
        final game = AsteroidsGame();
        game.player = PlayerComponent(position: Vector2(500, 500))
          ..customGame = game;
        game.world.add(game.player);
        game.state = GameState.playing;

        final laser = RapidFire();
        laser.level = laser.maxLevel;
        expect(laser.canEvolve, isTrue);

        laser.evolve();
        expect(laser.isEvolved, isTrue);
        expect(laser.evolvedName, 'Absolute Zero Tachyon Beam');
        expect(laser.cooldown, 0.075);

        laser.fire(game.player);
        final bullets = game.world.children
            .whereType<BulletComponent>()
            .toList();
        expect(bullets.isNotEmpty, isTrue);
        expect(bullets.first.piercesLeft, 99);
      },
    );

    test(
      'BombLauncher evolves into Singularity Rift Torpedo spawning gravitational vortex',
      () {
        final game = AsteroidsGame();
        game.player = PlayerComponent(position: Vector2(500, 500))
          ..customGame = game;
        game.world.add(game.player);
        game.state = GameState.playing;

        final torpedo = BombLauncher();
        torpedo.level = torpedo.maxLevel;
        torpedo.evolve();

        expect(torpedo.isEvolved, isTrue);
        expect(torpedo.evolvedName, 'Singularity Rift Torpedo');

        torpedo.fire(game.player);
        final bombs = game.world.children.whereType<BombComponent>().toList();
        expect(bombs.isNotEmpty, isTrue);
        expect(bombs.first.isSingularity, isTrue);

        // Trigger torpedo detonation
        bombs.first.explode();
        final rifts = game.world.children
            .whereType<SingularityRiftComponent>()
            .toList();
        expect(rifts.isNotEmpty, isTrue);
        expect(rifts.first.pullRadius, 160.0);
        expect(rifts.first.duration, 0.8);
      },
    );

    test(
      'ChestComponent generates Super-Evolution reward card ONLY when synergy passive is owned',
      () {
        final game = AsteroidsGame();
        game.player = PlayerComponent(position: Vector2(500, 500))
          ..customGame = game;
        game.world.add(game.player);
        final blaster = Blaster();
        blaster.level = blaster.maxLevel; // MK MAX (5)
        game.player.setWeapon(blaster);
        game.state = GameState.playing;

        // Without required passive ('passive_overdrive'), chest does NOT award free evolution
        game.onChestCollected(ChestTier.silver);
        expect(
          game.currentChestRewards.any(
            (r) => r.title.contains('SUPER-EVOLUTION'),
          ),
          isFalse,
        );
        game.currentChestRewards.clear();
        game.overlays.remove('chest');

        // Acquire required synergy passive
        game.activePassives.add('passive_overdrive');
        game.onChestCollected(ChestTier.silver);

        expect(game.currentChestRewards.isNotEmpty, isTrue);
        final firstReward = game.currentChestRewards.first;
        expect(firstReward.title.contains('SUPER-EVOLUTION'), isTrue);
        expect(firstReward.title.contains('Supernova Annihilator'), isTrue);

        // Claim reward -> evolves weapon
        game.claimChestRewards();
        expect(blaster.isEvolved, isTrue);
      },
    );
  });
}
