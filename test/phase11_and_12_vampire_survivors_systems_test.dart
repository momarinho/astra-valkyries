import 'package:flutter_test/flutter_test.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:asteroids/game/asteroids_game.dart';
import 'package:asteroids/game/components/player.dart';
import 'package:asteroids/game/meta_progression.dart';
import 'package:asteroids/game/rogue_perks.dart';
import 'package:asteroids/game/weapons.dart';
import 'package:asteroids/game/valkyrie.dart';
import 'package:asteroids/services/localization_service.dart';
import 'package:asteroids/services/secret_grimoire_service.dart';
import 'package:asteroids/ui/level_up_overlay.dart';
import 'package:asteroids/ui/pause_overlay.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
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
    await I18n.init();
    await I18n.setLocale(AppLocale.ptBr);
    await SecretGrimoireService.init();
  });

  group('Phases 11 & 12: Vampire Survivors Weapon Systems & Level-Up Agency', () {
    test('MetaProgression handles Rerolls and Banish upgrades with persistence', () async {
      final meta = MetaProgression();
      expect(meta.rerollsCount, 0);
      expect(meta.banishCount, 0);

      // Verify upgrade definitions
      final rerollUp = MetaProgression.allUpgrades.firstWhere((u) => u.id == 'rerolls');
      final banishUp = MetaProgression.allUpgrades.firstWhere((u) => u.id == 'banish');
      expect(rerollUp.maxLevel, 3);
      expect(banishUp.maxLevel, 2);

      // Purchase reroll
      expect(meta.canPurchase('rerolls', 10000), isTrue);
      expect(meta.purchase('rerolls', (_) {}), isTrue);
      expect(meta.rerollsCount, 1);
      expect(meta.getLevel('rerolls'), 1);

      // Purchase banish
      expect(meta.canPurchase('banish', 10000), isTrue);
      expect(meta.purchase('banish', (_) {}), isTrue);
      expect(meta.banishCount, 1);
      expect(meta.getLevel('banish'), 1);

      // Verify saving and loading
      await meta.saveToPrefs();
      final metaLoaded = MetaProgression();
      await metaLoaded.loadFromPrefs();
      expect(metaLoaded.rerollsCount, 1);
      expect(metaLoaded.banishCount, 1);
    });

    test('AsteroidsGame handles Level-Up Agency: Reroll, Banish and Skip', () {
      final game = AsteroidsGame();
      game.metaProgression.levels['rerolls'] = 2;
      game.metaProgression.levels['banish'] = 1;
      game.selectedValkyrie = Valkyrie.roster.first;
      game.player = PlayerComponent(position: Vector2(100, 100))..customGame = game;

      game.startGame();
      expect(game.runRerollsRemaining, 2);
      expect(game.runBanishesRemaining, 1);
      expect(game.runBanishedPerkIds, isEmpty);

      // Reroll action
      game.currentLevelUpChoices = RoguePerkGenerator.generateChoices(game, count: 3);
      expect(game.currentLevelUpChoices.length, 3);
      final didReroll = game.rerollLevelUpChoices();
      expect(didReroll, isTrue);
      expect(game.runRerollsRemaining, 1);

      // Banish action
      final targetPerk = game.currentLevelUpChoices.first;
      final didBanish = game.banishLevelUpPerk(targetPerk);
      expect(didBanish, isTrue);
      expect(game.runBanishesRemaining, 0);
      expect(game.runBanishedPerkIds.contains(targetPerk.id), isTrue);

      // Cannot banish again when charges depleted
      expect(game.banishLevelUpPerk(targetPerk), isFalse);

      // Skip action restores HP and gives credits
      game.player.hp = 50.0;
      game.player.maxHp = 100.0;
      final oldCredits = game.runCredits;
      game.skipLevelUp();
      expect(game.player.hp, 85.0);
      expect(game.runCredits, oldCredits + 50);
    });

    test('SecretGrimoireService tracks 15 recipes and records discoveries', () async {
      expect(SecretGrimoireService.totalCount, 15);
      expect(SecretGrimoireService.isDiscovered('union_void_singularity'), isFalse);
      expect(SecretGrimoireService.isDiscovered('union_thunderstorm'), isFalse);

      await SecretGrimoireService.discover('union_void_singularity');
      expect(SecretGrimoireService.isDiscovered('union_void_singularity'), isTrue);
      expect(SecretGrimoireService.discoveredCount >= 1, isTrue);
      expect(SecretGrimoireService.progressFraction > 0.0, isTrue);

      // Duplicate discovery does not increment total
      final countBefore = SecretGrimoireService.discoveredCount;
      await SecretGrimoireService.discover('union_void_singularity');
      expect(SecretGrimoireService.discoveredCount, countBefore);
    });

    test('Dual-weapon Super-Unions fuse weapons and free up arsenal slots', () {
      final game = AsteroidsGame();
      game.selectedValkyrie = Valkyrie.roster.first;
      game.player = PlayerComponent(position: Vector2(100, 100))..customGame = game;

      // Ensure blaster is MK 3 and void_mines is MK 3
      game.player.unlockedWeapons['blaster']!.level = 3;
      final voidMines = VoidClusterMines();
      voidMines.level = 3;
      game.player.addWeapon(voidMines);

      expect(game.player.unlockedWeapons['blaster']?.level, 3);
      expect(game.player.unlockedWeapons['void_mines']?.level, 3);
      expect(game.player.activeWeapons.length, 2);

      // Super union priority pool generation
      final choices = RoguePerkGenerator.generateChoices(game, count: 5);
      final unionPerk = choices.firstWhere((p) => p.id == 'union_void_singularity');
      expect(unionPerk, isNotNull);

      // Select Union: removes 2 weapons and adds 1 Super-Union weapon
      unionPerk.onSelect(game);
      expect(game.player.unlockedWeapons.containsKey('blaster'), isFalse);
      expect(game.player.unlockedWeapons.containsKey('void_mines'), isFalse);
      expect(game.player.unlockedWeapons.containsKey('union_void_singularity'), isTrue);
      expect(game.player.activeWeapons.length, 1);
      expect(game.player.activeWeapons.first is VoidSingularityNova, isTrue);
      expect(SecretGrimoireService.isDiscovered('union_void_singularity'), isTrue);

      // Verify weapon firing behaves correctly
      final didFire = game.player.activeWeapons.first.fire(game.player);
      expect(didFire, isTrue);
    });

    testWidgets('LevelUpOverlay renders Tactical Action Bar and triggers Reroll and Skip', (tester) async {
      final game = AsteroidsGame();
      game.state = GameState.playing;
      game.runRerollsRemaining = 2;
      game.runBanishesRemaining = 1;
      game.selectedValkyrie = Valkyrie.roster.first;
      game.player = PlayerComponent(position: Vector2(100, 100))..customGame = game;
      game.currentLevelUpChoices = RoguePerkGenerator.generateChoices(game, count: 3);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 1280,
              height: 720,
              child: LevelUpOverlay(game: game),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Tactical Action Bar buttons exist
      expect(find.byKey(const Key('level_up_reroll_button')), findsOneWidget);
      expect(find.byKey(const Key('level_up_banish_button')), findsOneWidget);
      expect(find.byKey(const Key('level_up_skip_button')), findsOneWidget);

      // Tap Reroll
      await tester.tap(find.byKey(const Key('level_up_reroll_button')));
      await tester.pumpAndSettle();
      expect(game.runRerollsRemaining, 1);

      // Tap Skip
      final oldCredits = game.runCredits;
      await tester.tap(find.byKey(const Key('level_up_skip_button')));
      await tester.pumpAndSettle();
      expect(game.runCredits, oldCredits + 50);
    });

    testWidgets('PauseOverlay renders Cosmic Grimoire with secrets and progress', (tester) async {
      final game = AsteroidsGame();
      game.selectedValkyrie = Valkyrie.roster.first;
      game.player = PlayerComponent(position: Vector2(100, 100))..customGame = game;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 1280,
              height: 720,
              child: PauseOverlay(game: game),
            ),
          ),
        ),
      );
      await tester.pump();

      // Switch to Grimoire tab (Index 1)
      final grimoireTab = find.text(I18n.t('pause.tab_grimoire'));
      expect(grimoireTab, findsOneWidget);
      await tester.tap(grimoireTab);
      await tester.pump();

      // Grimoire header and recipe masks should be present
      expect(find.textContaining('GRIMÓRIO // SEGREDOS REVELADOS'), findsOneWidget);
      expect(find.textContaining('15'), findsOneWidget);
    });
  });
}
