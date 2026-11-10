import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import 'package:asteroids/game/asteroids_game.dart';
import 'package:asteroids/game/meta_progression.dart';
import 'package:asteroids/game/components/player.dart';
import 'package:asteroids/game/valkyrie.dart';
import 'package:asteroids/constants.dart';
import 'package:asteroids/ui/valkyrie_selection_overlay.dart';

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

  group('Sprint 4: MetaProgression Core Domain Tests', () {
    test('MetaProgression initializes with 7 core upgrade definitions at level 0', () {
      final meta = MetaProgression();
      expect(MetaProgression.allUpgrades.length, equals(7));

      final ids = MetaProgression.allUpgrades.map((u) => u.id).toList();
      expect(ids, containsAll(['hull', 'magnet', 'thrusters', 'targeting', 'luck', 'rerolls', 'banish']));

      for (final id in ids) {
        expect(meta.getLevel(id), equals(0));
      }

      expect(meta.hullBonusLives, equals(0));
      expect(meta.magnetMultiplier, equals(1.0));
      expect(meta.speedMultiplier, equals(1.0));
      expect(meta.critChanceBonus, equals(0.0));
      expect(meta.damageBonusMultiplier, equals(0.0));
      expect(meta.jackpotChanceBonus, equals(0.0));
    });

    test('Meta upgrade costs scale correctly with level and maxLevel constraints', () {
      final hullDef = MetaProgression.allUpgrades.firstWhere((u) => u.id == 'hull');
      expect(hullDef.maxLevel, equals(3));
      expect(hullDef.getCostForLevel(0), equals(150));
      expect(hullDef.getCostForLevel(1), equals(350));
      expect(hullDef.getCostForLevel(2), equals(750));
      expect(hullDef.getCostForLevel(3), equals(0)); // Maxed
    });

    test('canPurchase and purchase deduct credits and advance levels properly', () {
      final meta = MetaProgression();
      int bankCredits = 500;

      // Check canPurchase with insufficient vs sufficient credits
      expect(meta.canPurchase('hull', 100), isFalse);
      expect(meta.canPurchase('hull', 150), isTrue);

      // Purchase level 1
      final bought = meta.purchase('hull', (cost) => bankCredits -= cost);
      expect(bought, isTrue);
      expect(bankCredits, equals(350));
      expect(meta.getLevel('hull'), equals(1));
      expect(meta.hullBonusLives, equals(1));

      // Purchase level 2
      final boughtLvl2 = meta.purchase('hull', (cost) => bankCredits -= cost);
      expect(boughtLvl2, isTrue);
      expect(bankCredits, equals(0));
      expect(meta.getLevel('hull'), equals(2));
      expect(meta.hullBonusLives, equals(2));

      // Cannot purchase level 3 with 0 credits
      expect(meta.canPurchase('hull', bankCredits), isFalse);
    });

    test('refundAll restores 100% of spent credits and resets all upgrades to 0', () {
      final meta = MetaProgression();
      int bankCredits = 2000;

      // Purchase multiple upgrades
      meta.purchase('hull', (c) => bankCredits -= c); // 150 (hull lvl 1)
      meta.purchase('magnet', (c) => bankCredits -= c); // 100 (magnet lvl 1)
      meta.purchase('magnet', (c) => bankCredits -= c); // 200 (magnet lvl 2)
      meta.purchase('thrusters', (c) => bankCredits -= c); // 120 (thrusters lvl 1)

      // Total spent = 150 + 100 + 200 + 120 = 570
      expect(bankCredits, equals(2000 - 570));
      expect(meta.getLevel('hull'), equals(1));
      expect(meta.getLevel('magnet'), equals(2));
      expect(meta.getLevel('thrusters'), equals(1));

      // Execute 100% refund
      meta.refundAll((refund) => bankCredits += refund);

      expect(bankCredits, equals(2000));
      expect(meta.getLevel('hull'), equals(0));
      expect(meta.getLevel('magnet'), equals(0));
      expect(meta.getLevel('thrusters'), equals(0));
    });
  });

  group('Sprint 4: AsteroidsGame Meta-Progression & Scrap Economy Integration Tests', () {
    test('Game incorporates meta-progression upgrades into initial player run stats', () {
      final game = AsteroidsGame();
      game.player = PlayerComponent(position: Vector2.zero())..customGame = game;
      game.metaProgression.levels['hull'] = 2; // +2 lives
      game.metaProgression.levels['magnet'] = 3; // +60% magnet radius
      game.metaProgression.levels['thrusters'] = 2; // +16% speed
      game.metaProgression.levels['targeting'] = 2; // +8% crit, +12% damage
      game.metaProgression.levels['luck'] = 1; // +10% jackpot

      game.selectedValkyrie = Valkyrie.findById('lyra');
      game.startGame();

      // Check lives = base 3 + meta 2 = 5
      expect(game.lives, equals(GameConstants.playerLives + 2));

      // Check crit chance bonus applied
      expect(game.rogueCritChance, closeTo(game.selectedValkyrie.critChance + 0.08, 0.001));

      // Check damage multiplier
      expect(game.rogueDamageMultiplier, closeTo(1.12, 0.001));

      // Check magnet radius = base 150 * valkyrie * meta (1.6)
      final expectedMagnet = (150.0 * game.selectedValkyrie.magnetRadiusMultiplier) * 1.6;
      expect(game.rogueMagnetRadius, closeTo(expectedMagnet, 0.01));
    });

    test('addRunCredits and mission completion bank rewards into persistent totalCredits', () {
      final game = AsteroidsGame();
      game.player = PlayerComponent(position: Vector2.zero())..customGame = game;
      game.state = GameState.playing;
      game.totalCredits = 250;
      game.runCredits = 0;

      // Earn scrap in run
      game.addRunCredits(45);
      game.addRunCredits(80);
      expect(game.runCredits, equals(125));

      // Mission survival completion adds 350c bonus and banks into totalCredits
      game.completeMission(survived: true);

      // Expected total = initial 250 + run 125 + bonus 350 = 725
      expect(game.totalCredits, equals(725));
    });

    test('purchaseMetaUpgrade and refundMetaUpgrades properly modify game bank balance', () {
      final game = AsteroidsGame();
      game.totalCredits = 500;

      // Purchase hull lvl 1 (cost 150)
      final bought = game.purchaseMetaUpgrade('hull');
      expect(bought, isTrue);
      expect(game.totalCredits, equals(350));
      expect(game.metaProgression.getLevel('hull'), equals(1));

      // Refund all
      game.refundMetaUpgrades();
      expect(game.totalCredits, equals(500));
      expect(game.metaProgression.getLevel('hull'), equals(0));
    });
  });

  group('Sprint 4: Hangar Workshop & Tab Navigation Widget Tests', () {
    testWidgets('ValkyrieSelectionOverlay renders Sortie and Workshop tabs with scrap balance', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 720));
      final game = AsteroidsGame();
      game.totalCredits = 640;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ValkyrieSelectionOverlay(game: game),
          ),
        ),
      );
      await tester.pump();

      // Top bar header and tab pills present
      expect(find.text('ASTRA VALKYRIES // HANGAR BAY'), findsOneWidget);
      expect(find.text('SORTIE // DECOLAR'), findsOneWidget);
      expect(find.text('OFICINA // UPGRADES'), findsOneWidget);
      expect(find.text('640 c'), findsOneWidget);

      // Initially in Sortie mode
      expect(find.text('DEPLOY // DECOLAR'), findsOneWidget);

      // Tap on OFICINA // UPGRADES tab pill
      await tester.tap(find.text('OFICINA // UPGRADES'));
      await tester.pumpAndSettle();

      // Now in Workshop view
      expect(find.text('OFICINA DE ENGENHARIA // META-UPGRADES'), findsOneWidget);
      expect(find.text('REEMBOLSAR TUDO (100%)'), findsOneWidget);

      // All 5 meta-upgrades rendered
      expect(find.text('HULL REINFORCEMENT'), findsOneWidget);
      expect(find.text('ION MAGNET OVERDRIVE'), findsOneWidget);
      expect(find.text('HYPER-THRUSTERS'), findsOneWidget);
      expect(find.text('QUANTUM TARGETING'), findsOneWidget);
      expect(find.text('LUCKY STAR PROTOCOL', skipOffstage: false), findsOneWidget);

      // Purchase Hull upgrade (cost 150 c)
      expect(find.text('APRIMORAR • 150 c'), findsWidgets);
      await tester.tap(find.text('APRIMORAR • 150 c').first);
      await tester.pumpAndSettle();

      // Balance reduced: 640 - 150 = 490 c
      expect(game.totalCredits, equals(490));
      expect(find.text('490 c'), findsOneWidget);
      expect(game.metaProgression.getLevel('hull'), equals(1));

      // Test refund button
      await tester.tap(find.text('REEMBOLSAR TUDO (100%)'));
      await tester.pumpAndSettle();

      expect(game.totalCredits, equals(640));
      expect(find.text('640 c'), findsOneWidget);
      expect(game.metaProgression.getLevel('hull'), equals(0));

      // Press Tab key to toggle back to Sortie mode
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      expect(find.text('DEPLOY // DECOLAR'), findsOneWidget);
    });
  });
}
