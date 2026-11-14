import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flame/components.dart';
import 'package:void_protocol/game/asteroids_game.dart';
import 'package:void_protocol/game/components/enemy_ship.dart';
import 'package:void_protocol/game/components/player.dart';
import 'package:void_protocol/game/rogue_perks.dart';
import 'package:void_protocol/game/weapons.dart';
import 'package:void_protocol/ui/level_up_overlay.dart';
import 'package:void_protocol/ui/pause_overlay.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group(
    'Sprint 59: Roguelite Expansion, Radical Trade-Offs & Ordered Level-Up Queue',
    () {
      test(
        'Passive catalog expands to 15+ distinct passives including 3 Brotato radical trade-offs',
        () {
          final catalog = RoguePerkGenerator.buildPassiveCatalog();
          expect(catalog.length, greaterThanOrEqualTo(15));

          final uniqueIds = catalog.map((p) => p.id).toSet();
          expect(uniqueIds.length, catalog.length);

          final tradeOffs = catalog.where((p) => p.isTradeOff).toList();
          expect(tradeOffs.length, 3);
          expect(
            tradeOffs.map((p) => p.id),
            containsAll([
              'passive_glass_cannon',
              'passive_juggernaut',
              'passive_unstable_payloads',
            ]),
          );
        },
      );

      test(
        'Radical Trade-Offs (Glass Cannon, Juggernaut, Unstable Payloads) apply exact stat bonuses and penalties',
        () {
          final game = AsteroidsGame();
          final player = PlayerComponent(position: Vector2(200, 200))
            ..customGame = game
            ..maxHp = 100.0
            ..hp = 100.0
            ..movementMaxSpeed = 400.0;
          game.player = player;

          final catalog = {
            for (final p in RoguePerkGenerator.buildPassiveCatalog()) p.id: p,
          };

          // 1. Glass Cannon Reactor: +45% Damage, -25% Max HP
          final baseDmg = game.rogueDamageMultiplier;
          catalog['passive_glass_cannon']!.onSelect(game);
          expect(game.rogueDamageMultiplier, closeTo(baseDmg + 0.45, 0.001));
          expect(player.maxHp, closeTo(75.0, 0.01));
          expect(player.hp, lessThanOrEqualTo(75.0));

          // 2. Juggernaut Plating: +60 Max HP, +18% Armor, -15% Max Speed
          catalog['passive_juggernaut']!.onSelect(game);
          expect(player.maxHp, closeTo(135.0, 0.01));
          expect(player.armorReduction, closeTo(0.18, 0.001));
          expect(player.movementMaxSpeed, closeTo(340.0, 0.01));

          // 3. Unstable Payloads: +40% AoE Radius, -20% Fire Rate (1.20x cooldown)
          final baseCd = game.rogueFireRateMultiplier;
          catalog['passive_unstable_payloads']!.onSelect(game);
          expect(game.rogueAreaMultiplier, closeTo(1.40, 0.001));
          expect(game.rogueFireRateMultiplier, closeTo(baseCd * 1.20, 0.001));
        },
      );

      test(
        'Specialized modules connect to real combat mechanics (Armor, Lifesteal, Crit Mult, Pierce, Luck)',
        () {
          final game = AsteroidsGame()..state = GameState.playing;
          final player = PlayerComponent(position: Vector2(300, 300))
            ..customGame = game
            ..maxHp = 120.0
            ..hp = 80.0
            ..invulnerableTimer = 0.0;
          game.player = player;

          final catalog = {
            for (final p in RoguePerkGenerator.buildPassiveCatalog()) p.id: p,
          };

          catalog['passive_armor_plating']!.onSelect(
            game,
          ); // +12% armor, +15 maxHp
          catalog['passive_crit_optics']!.onSelect(
            game,
          ); // +8% crit, +0.25x critMult
          catalog['passive_lifesteal_matrix']!.onSelect(game); // +5% lifesteal
          catalog['passive_piercing_sabots']!.onSelect(game); // +1 pierce
          catalog['passive_luck_salvage']!.onSelect(game); // +15% luck

          expect(player.armorReduction, closeTo(0.12, 0.001));
          expect(game.rogueCritMultiplier, closeTo(2.25, 0.001));
          expect(game.rogueLifesteal, closeTo(0.05, 0.001));
          expect(player.pierceCount, 1);
          expect(game.rogueLuckBonus, closeTo(0.15, 0.001));

          // Verify Armor reduces damage taken in combat
          final hpBeforeHit = player.hp;
          player.takeHit(50.0);
          final hpLost = hpBeforeHit - player.hp;
          expect(hpLost, closeTo(50.0 * 0.88, 0.1));

          // Verify Lifesteal Matrix siphons HP on enemy kill
          final hpBeforeKill = player.hp;
          final enemy = EnemyShipComponent(
            position: Vector2(350, 300),
            type: EnemyType.raider,
          );
          game.world.add(enemy);
          enemy.die();
          expect(player.hp, greaterThan(hpBeforeKill));
        },
      );

      test(
        'Ordered Level-Up Queue (pendingLevelUps) preserves every level on massive XP spike',
        () {
          final game = AsteroidsGame();
          final player = PlayerComponent(position: Vector2(400, 400))
            ..customGame = game;
          game.player = player;
          player.setWeapon(Blaster());
          game.state = GameState.playing;

          expect(game.runLevel, 1);
          expect(game.pendingLevelUps, 0);

          // Massive +300 XP spike at Level 1 (threshold 30 -> lvl 2, 76 -> lvl 3, 134 -> lvl 4)
          game.addXp(300);

          // Must advance multiple levels and open the first level-up while keeping the rest queued
          expect(game.runLevel, greaterThanOrEqualTo(4));
          expect(game.state, GameState.levelUp);
          expect(game.pendingLevelUps, game.runLevel - 2);

          // Drain the remaining queue one perk selection at a time
          final totalRemaining = game.pendingLevelUps;
          for (var i = 0; i < totalRemaining; i++) {
            expect(game.currentLevelUpChoices, isNotEmpty);
            game.selectLevelUpPerk(game.currentLevelUpChoices.first);
            expect(game.state, GameState.levelUp);
          }

          // Selecting the final card completes the queue and resumes GameState.playing
          expect(game.pendingLevelUps, 0);
          game.selectLevelUpPerk(game.currentLevelUpChoices.first);
          expect(game.state, GameState.playing);
        },
      );

      test(
        'BuildStatsSnapshot calculates consolidated mathematical DPS, modifiers and active trade-offs',
        () {
          final game = AsteroidsGame();
          final player = PlayerComponent(position: Vector2(200, 200))
            ..customGame = game;
          game.player = player;
          player.setWeapon(Blaster()); // damage 15.0, cooldown 0.70

          final baseline = game.getBuildStatsSnapshot();
          expect(baseline.estimatedDps, greaterThan(20.0));
          expect(baseline.activeTradeOffIds, isEmpty);

          final catalog = {
            for (final p in RoguePerkGenerator.buildPassiveCatalog()) p.id: p,
          };
          catalog['passive_glass_cannon']!.onSelect(game);
          catalog['passive_crit_optics']!.onSelect(game);

          final boosted = game.getBuildStatsSnapshot();
          expect(
            boosted.estimatedDps,
            greaterThan(baseline.estimatedDps * 1.35),
          );
          expect(boosted.damageMultiplier, closeTo(1.45, 0.01));
          expect(boosted.critMultiplier, closeTo(2.25, 0.01));
          expect(boosted.activeTradeOffIds, contains('passive_glass_cannon'));
        },
      );

      testWidgets(
        'LevelUpOverlay renders queued level-up badge and Trade-Off warning tag',
        (tester) async {
          tester.view.physicalSize = const Size(1280, 800);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });

          final game = AsteroidsGame();
          game.player = PlayerComponent(position: Vector2.zero())
            ..customGame = game;
          game.pendingLevelUps = 2;
          game.runLevel = 4;
          final glassCannon = RoguePerkGenerator.buildPassiveCatalog()
              .firstWhere((p) => p.id == 'passive_glass_cannon');
          game.currentLevelUpChoices = [glassCannon];

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(body: LevelUpOverlay(game: game)),
            ),
          );
          await tester.pump(const Duration(milliseconds: 400));

          expect(find.textContaining('2'), findsWidgets);
          expect(find.textContaining('TRADE-OFF'), findsWidgets);
        },
      );

      testWidgets(
        'PauseOverlay displays Transparent Build Stats tab with real combat metrics',
        (tester) async {
          tester.view.physicalSize = const Size(1280, 800);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });

          final game = AsteroidsGame();
          game.player = PlayerComponent(position: Vector2.zero())
            ..customGame = game
            ..setWeapon(Blaster());
          game.rogueDamageMultiplier = 1.45;
          game.activePassives.add('passive_glass_cannon');

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(body: PauseOverlay(game: game)),
            ),
          );
          await tester.pump();

          final statsTabFinder = find.textContaining('STATS');
          expect(statsTabFinder, findsOneWidget);

          await tester.tap(statsTabFinder);
          await tester.pump();

          expect(find.text('145%'), findsWidgets);
          expect(find.textContaining('TRADE-OFF'), findsWidgets);
        },
      );
    },
  );
}
