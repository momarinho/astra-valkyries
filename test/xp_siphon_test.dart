import 'package:flutter_test/flutter_test.dart';
import 'package:flame/components.dart';
import 'package:asteroids/game/asteroids_game.dart';
import 'package:asteroids/game/components/player.dart';
import 'package:asteroids/game/components/xp_orb.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Vampire Survivors Red Gem Siphon (Gem Consolidation) Tests', () {
    test('spawnXpOrb caps active orbs at 60 and absorbs excess XP into furthest gem as hyperRed', () {
      final game = AsteroidsGame();
      game.player = PlayerComponent(position: Vector2(1000, 1000));
      game.state = GameState.playing;

      // Spawn exactly 60 orbs around player
      for (int i = 0; i < 60; i++) {
        game.spawnXpOrb(Vector2(1000 + i * 2.0, 1000), XpOrbType.small);
      }

      final orbs = game.world.children.whereType<XpOrbComponent>().toList();
      expect(orbs.length, 60);

      // The furthest orb is at index 59 (x = 1118)
      final furthestInitialX = orbs.last.position.x;
      expect(furthestInitialX, 1118.0);
      final initialValue = orbs.last.value;

      // Spawn 61st orb -> should NOT increase active count, should consolidate into furthest orb
      game.spawnXpOrb(Vector2(1050, 1050), XpOrbType.large, 14);

      final updatedOrbs = game.world.children.whereType<XpOrbComponent>().toList();
      expect(updatedOrbs.length, 60); // Still capped at 60!

      // Find the furthest orb again
      final furthest = updatedOrbs.firstWhere((o) => o.position.x == furthestInitialX);
      expect(furthest.type, XpOrbType.hyperRed);
      expect(furthest.value, initialValue + 14);
    });
  });
}
