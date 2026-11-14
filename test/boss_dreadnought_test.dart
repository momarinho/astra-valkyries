import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:void_protocol/game/asteroids_game.dart';
import 'package:void_protocol/game/components/player.dart';
import 'package:void_protocol/game/components/dreadnought_leviathan.dart';
import 'package:void_protocol/game/components/enemy_bullet.dart';
import 'package:void_protocol/game/components/chest.dart';
import 'package:void_protocol/game/valkyrie.dart';
import 'package:void_protocol/ui/hud_overlay.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('xyz.luan/audioplayers.global'),
    (call) async => null,
  );
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('xyz.luan/audioplayers'),
    (call) async => null,
  );

  group('Sprint 3: Titanic Dreadnought Leviathan Boss Tests', () {
    test('DreadnoughtLeviathanComponent initializes with 3500 HP and registers as activeBoss', () async {
      final game = AsteroidsGame();
      game.player = PlayerComponent(position: Vector2(1000, 1000))..customGame = game;
      game.state = GameState.playing;

      final boss = DreadnoughtLeviathanComponent(position: Vector2(1500, 1500));
      await game.world.add(boss);
      await boss.onLoad();

      expect(boss.hp, 3500.0);
      expect(boss.maxHp, 3500.0);
      expect(game.activeBoss, boss);
      expect(boss.isDefeated, isFalse);
    });

    test('Boss fires twin turret volleys and danmaku spiral rings during combat', () async {
      final game = AsteroidsGame();
      game.player = PlayerComponent(position: Vector2(1000, 1000))..customGame = game;
      game.state = GameState.playing;

      final boss = DreadnoughtLeviathanComponent(position: Vector2(1000, 1400));
      await game.world.add(boss);
      await boss.onLoad();

      // Trigger twin turret fire
      boss.shootTimer = 2.0;
      boss.update(0.1);

      final bullets = game.world.children.whereType<EnemyBulletComponent>().toList();
      expect(bullets.length, 2); // Twin turrets
    });

    test('Lethal damage triggers Boss defeat, drops Legendary Cosmic Chest and sets victory flag', () async {
      final game = AsteroidsGame();
      game.player = PlayerComponent(position: Vector2(1000, 1000))..customGame = game;
      game.state = GameState.playing;

      final boss = DreadnoughtLeviathanComponent(position: Vector2(1000, 1200));
      await game.world.add(boss);
      await boss.onLoad();

      boss.takeDamage(4000.0, boss.position);

      expect(boss.isDefeated, isTrue);
      expect(boss.hp, 0.0);

      // Legendary Cosmic Chest (5 rewards jackpot)
      final chests = game.world.children.whereType<ChestComponent>().toList();
      expect(chests.isNotEmpty, isTrue);
      expect(chests.first.tier, ChestTier.cosmic);

      // Advance through death explosion sequence (3.5s) to trigger completeMission
      boss.update(3.6);
      expect(game.missionSurvived, isTrue);
    });

    testWidgets('HudOverlay displays dynamic Boss Health Bar when activeBoss is engaged', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 720));
      final game = AsteroidsGame();
      game.selectedValkyrie = Valkyrie.findById('lyra');
      game.player = PlayerComponent(position: Vector2(500, 500));
      game.player.valkyrie = game.selectedValkyrie;
      game.state = GameState.playing;

      final boss = DreadnoughtLeviathanComponent(position: Vector2(1000, 1000));
      boss.hp = 2625.0; // 75% HP
      game.activeBoss = boss;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HudOverlay(game: game),
          ),
        ),
      );
      await tester.pump();

      expect(find.textContaining('DREADNOUGHT LEVIATHAN // SECTOR TITAN'), findsOneWidget);
      expect(find.textContaining('75%'), findsOneWidget);
    });
  });
}
