import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flame/components.dart';
import 'package:asteroids/game/asteroids_game.dart';
import 'package:asteroids/game/rogue_perks.dart';
import 'package:asteroids/game/components/xp_orb.dart';
import 'package:asteroids/game/components/player.dart';
import 'package:asteroids/game/weapons.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Roguelike Level-Up & XP Engine Tests', () {
    test('XpOrbComponent initializes with correct XP value and radius based on type', () {
      final small = XpOrbComponent(position: Vector2.zero(), type: XpOrbType.small);
      final medium = XpOrbComponent(position: Vector2.zero(), type: XpOrbType.medium);
      final large = XpOrbComponent(position: Vector2.zero(), type: XpOrbType.large);

      expect(small.value, equals(2));
      expect(medium.value, equals(6));
      expect(large.value, equals(14));

      expect(small.radius, equals(4.5));
      expect(medium.radius, equals(6.0));
      expect(large.radius, equals(8.0));
    });

    test('XP progression curve scales dynamically with run level', () {
      final xpLevel1 = AsteroidsGame.calculateNextLevelXp(1);
      final xpLevel2 = AsteroidsGame.calculateNextLevelXp(2);
      final xpLevel3 = AsteroidsGame.calculateNextLevelXp(3);
      final xpLevel5 = AsteroidsGame.calculateNextLevelXp(5);

      expect(xpLevel1, equals(30));
      expect(xpLevel2, equals(76));
      expect(xpLevel3, equals(134));
      expect(xpLevel5, greaterThan(xpLevel3));
    });

    test('RoguePerkGenerator generates exactly 3 distinct cards', () {
      final game = AsteroidsGame();
      game.player = PlayerComponent(position: Vector2.zero());

      final choices = RoguePerkGenerator.generateChoices(game, count: 3);

      expect(choices.length, equals(3));
      final ids = choices.map((c) => c.id).toSet();
      expect(ids.length, equals(3), reason: 'Level up cards must be unique');
    });

    test('Selecting perks applies stat modifications to PlayerComponent', () {
      final game = AsteroidsGame();
      game.player = PlayerComponent(position: Vector2.zero());

      final initialPierce = game.player.pierceCount;
      final initialDamage = game.player.damageMultiplier;
      final initialMagnet = game.player.magnetRadius;

      // Apply pierce perk
      final piercePerk = RoguePerk(
        id: 'test_pierce',
        title: 'Pierce',
        description: 'Test',
        type: PerkType.passive,
        rarity: PerkRarity.rare,
        icon: Icons.double_arrow,
        accentColor: const Color(0xFFFFFFFF),
        onSelect: (g) => g.player.pierceCount += 1,
      );
      piercePerk.onSelect(game);
      expect(game.player.pierceCount, equals(initialPierce + 1));

      // Apply damage perk
      final damagePerk = RoguePerk(
        id: 'test_damage',
        title: 'Damage',
        description: 'Test',
        type: PerkType.passive,
        rarity: PerkRarity.rare,
        icon: Icons.local_fire_department,
        accentColor: const Color(0xFFFFFFFF),
        onSelect: (g) => g.player.damageMultiplier += 0.20,
      );
      damagePerk.onSelect(game);
      expect(game.player.damageMultiplier, closeTo(initialDamage + 0.20, 0.001));

      // Apply magnet perk
      final magnetPerk = RoguePerk(
        id: 'test_magnet',
        title: 'Magnet',
        description: 'Test',
        type: PerkType.passive,
        rarity: PerkRarity.common,
        icon: Icons.attractions,
        accentColor: const Color(0xFFFFFFFF),
        onSelect: (g) => g.player.magnetRadius *= 1.6,
      );
      magnetPerk.onSelect(game);
      expect(game.player.magnetRadius, closeTo(initialMagnet * 1.6, 0.01));
    });
  });
}
