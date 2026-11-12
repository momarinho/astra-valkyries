import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:asteroids/game/asteroids_game.dart';
import 'package:asteroids/game/components/player.dart';
import 'package:asteroids/game/components/dreadnought_leviathan.dart';
import 'package:asteroids/game/components/floating_text.dart';
import 'package:asteroids/game/components/advanced_weapons.dart';
import 'package:asteroids/game/weapons.dart';
import 'package:asteroids/game/valkyrie.dart';
import 'package:asteroids/ui/game_over_overlay.dart';
import 'package:asteroids/services/localization_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 7: Sprints 37 to 40 - Audio, Combat Feedback & Boss Telegraphs', () {
    test('Sprint 37: Audio soundscape assets exist and are accessible on disk', () {
      const soundDir = 'assets/sounds';
      final requiredSounds = [
        'dash.wav',
        'bomb_explode.wav',
        'game_over.wav',
        'special.wav',
        'katana_slash.wav',
        'titanium_mine.wav',
        'ultimate_ready.wav',
        'shoot.wav',
        'powerup.wav',
        'asteroid_split.wav',
      ];

      for (final s in requiredSounds) {
        final f = File('$soundDir/$s');
        expect(f.existsSync(), isTrue, reason: 'Expected $s to exist in $soundDir');
        expect(f.lengthSync() > 1000, isTrue, reason: '$s should have valid audio content');
      }
    });

    test('Sprint 38: spawnCombatDamageText spawns elemental floating text with correct colors', () {
      final game = AsteroidsGame();
      game.state = GameState.playing;

      // 1. Critical Hit (Gold)
      game.spawnCombatDamageText(
        position: Vector2(100, 100),
        damage: 150.0,
        isCritical: true,
      );
      final critText = game.world.children.whereType<FloatingTextComponent>().last;
      expect(critText.text, '★ 150!');
      expect(critText.color, const Color(0xFFFFD700));

      // 2. Cryo Freeze (Cyan)
      game.spawnCombatDamageText(
        position: Vector2(200, 200),
        damage: 45.0,
        element: ElementalStatus.cryoFreeze,
      );
      final cryoText = game.world.children.whereType<FloatingTextComponent>().last;
      expect(cryoText.text, '45');
      expect(cryoText.color, const Color(0xFF00E5FF));

      // 3. Solar Burn (Orange)
      game.spawnCombatDamageText(
        position: Vector2(300, 300),
        damage: 60.0,
        element: ElementalStatus.solarBurn,
      );
      final solarText = game.world.children.whereType<FloatingTextComponent>().last;
      expect(solarText.color, const Color(0xFFFF6D00));

      // 4. Void Rupture (Purple)
      game.spawnCombatDamageText(
        position: Vector2(400, 400),
        damage: 80.0,
        element: ElementalStatus.voidRupture,
      );
      final voidText = game.world.children.whereType<FloatingTextComponent>().last;
      expect(voidText.color, const Color(0xFFE040FB));
    });

    test('Sprint 39: Dreadnought Leviathan enters Enraged Mode below 35% HP', () {
      final game = AsteroidsGame();
      game.player = PlayerComponent(position: Vector2(500, 500));
      game.state = GameState.playing;

      final boss = DreadnoughtLeviathanComponent(position: Vector2(400, 400));
      game.world.add(boss);

      expect(boss.isEnraged, isFalse);

      // Deal damage down to 50% HP (not enraged yet)
      boss.takeDamage(boss.maxHp * 0.50, boss.position);
      expect(boss.isEnraged, isFalse);

      // Deal damage down to 30% HP (below 35% threshold -> triggers Enraged Protocol)
      boss.takeDamage(boss.maxHp * 0.25, boss.position);
      expect(boss.isEnraged, isTrue);
    });

    test('Sprint 40: Weapons track totalDamageDealt and PlayerComponent computes MVP weapon', () {
      final game = AsteroidsGame();
      final player = PlayerComponent(position: Vector2(500, 500))..customGame = game;
      game.player = player;
      game.state = GameState.playing;

      final blaster = Blaster();
      final katana = TachyonKatana();
      player.setWeapon(blaster);
      player.addWeapon(katana);

      blaster.totalDamageDealt = 1250.0;
      katana.totalDamageDealt = 3800.0;

      expect(player.totalDamageDealt, 5050.0);
      expect(player.mvpWeapon, katana);
    });

    testWidgets('Sprint 40: GameOverOverlay renders Tactical Arsenal Performance Report', (tester) async {
      I18n.setLocaleSync(AppLocale.ptBr);
      await tester.binding.setSurfaceSize(const Size(1280, 800));

      final game = AsteroidsGame();
      game.selectedValkyrie = Valkyrie.findById('kaede');
      final player = PlayerComponent(position: Vector2(100, 100))..customGame = game;
      player.valkyrie = game.selectedValkyrie;
      game.player = player;

      final blaster = Blaster()..totalDamageDealt = 900.0;
      final katana = TachyonKatana()
        ..totalDamageDealt = 2700.0
        ..level = 3
        ..isEvolved = true;
      player.setWeapon(blaster);
      player.addWeapon(katana);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GameOverOverlay(game: game),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify Arsenal Report Title
      expect(find.textContaining('DESEMPENHO DO ARSENAL BÉLICO'), findsOneWidget);

      // Verify MVP badge
      expect(find.textContaining('MVP: TACHYON KATANA'), findsOneWidget);

      // Verify ★EVO tag
      expect(find.text('★EVO'), findsOneWidget);
    });
  });
}
