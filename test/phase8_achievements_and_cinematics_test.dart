import 'package:flutter_test/flutter_test.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:asteroids/game/asteroids_game.dart';
import 'package:asteroids/game/components/player.dart';
import 'package:asteroids/game/components/asteroid.dart';
import 'package:asteroids/game/weapons.dart';
import 'package:asteroids/game/valkyrie.dart';
import 'package:asteroids/services/achievement_service.dart';
import 'package:asteroids/services/localization_service.dart';
import 'package:asteroids/ui/hud_overlay.dart';
import 'package:asteroids/ui/pause_overlay.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AchievementService.resetForTest();
    await I18n.init();
  });

  group('Phase 8: Sprints 41 to 44 - Achievements, Cinematic Boss Intros & Radar Titanium Blips', () {
    test('Sprint 41: AchievementService tracks unlock states, notifications and progress fraction', () async {
      expect(AchievementService.unlockedCount, 0);
      expect(AchievementService.totalCount, 10);
      expect(AchievementService.progressFraction, 0.0);

      final unlockedFirst = await AchievementService.unlock('first_blood');
      expect(unlockedFirst, isTrue);
      expect(AchievementService.isUnlocked('first_blood'), isTrue);
      expect(AchievementService.unlockedCount, 1);
      expect(AchievementService.progressFraction, 0.1);
      expect(AchievementService.latestUnlocked.value?.id, 'first_blood');

      // Idempotency: Unlocking again should return false and not increment count
      final duplicateUnlock = await AchievementService.unlock('first_blood');
      expect(duplicateUnlock, isFalse);
      expect(AchievementService.unlockedCount, 1);

      // Unlock another achievement
      await AchievementService.unlock('titanium_tycoon');
      expect(AchievementService.isUnlocked('titanium_tycoon'), isTrue);
      expect(AchievementService.unlockedCount, 2);
      expect(AchievementService.progressFraction, 0.2);
    });

    test('Sprint 41: Weapon evolution triggers transcendence achievement', () {
      final weapon = Blaster();
      weapon.level = 5;
      expect(weapon.canEvolve, isTrue);

      expect(AchievementService.isUnlocked('transcendence'), isFalse);
      final evolved = weapon.evolve();
      expect(evolved, isTrue);
      expect(weapon.isEvolved, isTrue);
      expect(AchievementService.isUnlocked('transcendence'), isTrue);
    });

    test('Sprint 42: triggerBossCinematicIntro populates bossCinematicNotifier', () {
      final game = AsteroidsGame();
      expect(game.bossCinematicNotifier.value, isNull);

      game.triggerBossCinematicIntro(
        title: 'TITAN LEVIATHAN',
        subtitle: 'FLAGSHIP COLOSSUS',
        color: const Color(0xFFFF1744),
      );

      expect(game.bossCinematicNotifier.value, isNotNull);
      expect(game.bossCinematicNotifier.value!.title, 'TITAN LEVIATHAN');
      expect(game.bossCinematicNotifier.value!.subtitle, 'FLAGSHIP COLOSSUS');
      expect(game.bossCinematicNotifier.value!.color, const Color(0xFFFF1744));
    });

    test('Sprint 43: Asteroid variant titanium properly distinguished', () {
      final normalAst = AsteroidComponent(
        radius: 25.0,
        position: Vector2.zero(),
        velocity: Vector2.zero(),
        variant: AsteroidVariant.standard,
      );
      final titaniumAst = AsteroidComponent(
        radius: 25.0,
        position: Vector2.zero(),
        velocity: Vector2.zero(),
        variant: AsteroidVariant.titanium,
      );

      expect(normalAst.variant, AsteroidVariant.standard);
      expect(titaniumAst.variant, AsteroidVariant.titanium);
      expect(titaniumAst.maxHp > normalAst.maxHp, isTrue);
    });

    testWidgets('Sprint 41 & 42: HudOverlay renders Achievement Toast and Boss Cinematic Banner without overflow', (tester) async {
      final game = AsteroidsGame();
      game.selectedValkyrie = Valkyrie.findById('selene');
      game.player = PlayerComponent(position: Vector2(100, 100))..customGame = game;
      game.player.valkyrie = game.selectedValkyrie;
      game.state = GameState.playing;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 1280,
              height: 720,
              child: HudOverlay(game: game),
            ),
          ),
        ),
      );

      // Trigger achievement toast
      await AchievementService.unlock('blade_master');
      await tester.pump();

      expect(find.text('🏆 CONQUISTA DESBLOQUEADA'), findsOneWidget);
      expect(find.text('MESTRE DAS LÂMINAS // BLADE MASTER'), findsOneWidget);

      // Trigger boss cinematic banner
      game.triggerBossCinematicIntro(
        title: 'ENCOURAÇADO LEVIATÃ',
        subtitle: 'SOBERANO DOS ESCOMBROS DE TITÃ',
      );
      await tester.pump();

      expect(find.text('ENCOURAÇADO LEVIATÃ'), findsOneWidget);
      expect(find.text('SOBERANO DOS ESCOMBROS DE TITÃ'), findsOneWidget);
      expect(find.text('⚠️ CLASSIFIED HOSTILE DETECTED ⚠️'), findsOneWidget);

      // Advance clock to finish auto-dismiss timers
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('Sprint 44: PauseOverlay displays Achievements tab and progress', (tester) async {
      final game = AsteroidsGame();
      game.selectedValkyrie = Valkyrie.findById('selene');
      game.player = PlayerComponent(position: Vector2(100, 100))..customGame = game;
      game.player.valkyrie = game.selectedValkyrie;
      game.state = GameState.playing;

      await AchievementService.unlock('first_blood');
      await AchievementService.unlock('transcendence');

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

      // Switch to tab 2: CONQUISTAS
      final achievementsTabBtn = find.text(I18n.t('pause.tab_achievements'));
      expect(achievementsTabBtn, findsOneWidget);
      await tester.tap(achievementsTabBtn);
      await tester.pump();

      expect(find.text('PROGRESSO DE CONQUISTAS'), findsOneWidget);
      expect(find.text('2 / 10 (20%)'), findsOneWidget);
      expect(find.text('PRIMEIRO ABATE // FIRST BLOOD'), findsOneWidget);
      expect(find.text('TRANSCENDÊNCIA // TRANSCENDENCE'), findsOneWidget);

      // Advance clock to finish timers
      await tester.pump(const Duration(seconds: 5));
    });
  });
}
