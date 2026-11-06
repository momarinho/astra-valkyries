import 'package:flutter_test/flutter_test.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:asteroids/game/asteroids_game.dart';
import 'package:asteroids/game/components/player.dart';
import 'package:asteroids/game/components/chest.dart';
import 'package:asteroids/game/weapons.dart';
import 'package:asteroids/game/valkyrie.dart';
import 'package:asteroids/ui/chest_overlay.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Vampire Survivors Chest & Jackpot System Tests', () {
    test('ChestComponent is magnetized by player and calls onChestCollected', () {
      final game = AsteroidsGame();
      game.player = PlayerComponent(position: Vector2(500, 500));
      game.player.magnetRadius = 200.0;
      game.state = GameState.playing;

      final chest = ChestComponent(
        position: Vector2(550, 500),
        tier: ChestTier.gold,
      );
      game.world.add(chest);

      // Within magnet radius, chest should accelerate towards player
      chest.update(0.1);
      expect(chest.velocity.x < 0, isTrue); // Moving left towards player at x=500
    });

    test('onChestCollected rolls rewards, pauses engine and generates upgrades', () {
      final game = AsteroidsGame();
      game.player = PlayerComponent(position: Vector2(500, 500));
      game.player.setWeapon(Blaster());
      game.state = GameState.playing;

      game.onChestCollected(ChestTier.gold);

      expect(game.currentChestRewards.isNotEmpty, isTrue);
      expect(game.currentChestRewards.length >= 3, isTrue);
      expect(game.paused, isTrue);
    });

    test('claimChestRewards applies upgrades, clears rewards and unpauses engine', () {
      final game = AsteroidsGame();
      game.player = PlayerComponent(position: Vector2(500, 500));
      final blaster = Blaster();
      game.player.setWeapon(blaster);
      game.state = GameState.playing;

      game.onChestCollected(ChestTier.silver);
      expect(game.currentChestRewards.isNotEmpty, isTrue);

      final initialBlasterLevel = blaster.level;
      game.claimChestRewards();

      expect(game.currentChestRewards.isEmpty, isTrue);
      expect(game.paused, isFalse);
      expect(blaster.level, initialBlasterLevel + 1);
    });

    testWidgets('ChestOverlay renders jackpot cards and claim button', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 720));
      final game = AsteroidsGame();
      game.selectedValkyrie = Valkyrie.findById('lyra');
      game.player = PlayerComponent(position: Vector2(100, 100));
      game.player.valkyrie = game.selectedValkyrie;

      game.currentChestRewards = [
        ChestReward(
          title: 'Pulse Blaster MK 2',
          subtitle: 'Evolution upgrade',
          icon: Icons.military_tech,
          color: const Color(0xFFFFD700),
          apply: () {},
        ),
        ChestReward(
          title: 'Stardust Bounty',
          subtitle: '+60 Instant XP',
          icon: Icons.bolt,
          color: const Color(0xFF00E5FF),
          apply: () {},
        ),
        ChestReward(
          title: 'Hull Overcharge',
          subtitle: '+1 Life',
          icon: Icons.favorite,
          color: const Color(0xFFFF1744),
          apply: () {},
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChestOverlay(game: game),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('3 REWARDS'), findsOneWidget);
      expect(find.textContaining('PULSE BLASTER MK 2'), findsOneWidget);
      expect(find.textContaining('CLAIM & RESUME SORTIE'), findsOneWidget);

      await tester.tap(find.textContaining('CLAIM & RESUME SORTIE'));
      await tester.pump();
    });
  });
}
