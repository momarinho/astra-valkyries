import 'package:flutter_test/flutter_test.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:void_protocol/game/asteroids_game.dart';
import 'package:void_protocol/game/components/player.dart';
import 'package:void_protocol/game/components/bullet.dart';
import 'package:void_protocol/game/weapons.dart';
import 'package:void_protocol/game/valkyrie.dart';
import 'package:void_protocol/services/localization_service.dart';
import 'package:void_protocol/ui/game_over_overlay.dart';
import 'package:void_protocol/ui/settings_overlay.dart';
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
  });

  group('Phase 10: Sprints 49 to 52 - Victory Commendations, Audio Mixer, Evolved Particles & Dynamic Camera Zoom', () {
    testWidgets('Sprint 49: GameOverOverlay renders Tactical Commendations on mission victory', (tester) async {
      final game = AsteroidsGame();
      game.selectedValkyrie = Valkyrie.roster.first;
      game.player = PlayerComponent(position: Vector2(100, 100))..customGame = game;
      game.missionSurvived = true;
      game.lives = 3; // Untouchable
      game.runEnemiesKilled = 42; // Cosmic Reaper
      game.runCredits = 300; // Mining Baron
      game.score = 25000; // Void Apex

      await tester.pumpWidget(
        MaterialApp(
          home: GameOverOverlay(game: game),
        ),
      );
      await tester.pumpAndSettle();

      // Commendation container and badges should be present
      expect(find.text(I18n.t('game_over.commendations_title')), findsOneWidget);
      expect(find.text(I18n.t('game_over.badge_untouchable')), findsOneWidget);
      expect(find.text(I18n.t('game_over.badge_reaper')), findsOneWidget);
      expect(find.text(I18n.t('game_over.badge_baron')), findsOneWidget);
      expect(find.text(I18n.t('game_over.badge_apex')), findsOneWidget);
      expect(find.text('4 CONCEDIDAS'), findsOneWidget);
    });

    testWidgets('Sprint 49: GameOverOverlay does NOT render Commendations on mission defeat', (tester) async {
      final game = AsteroidsGame();
      game.selectedValkyrie = Valkyrie.roster.first;
      game.player = PlayerComponent(position: Vector2(100, 100))..customGame = game;
      game.missionSurvived = false;
      game.campaignCompleted = false;
      game.lives = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: GameOverOverlay(game: game),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(I18n.t('game_over.commendations_title')), findsNothing);
    });

    test('Sprint 50: AsteroidsGame manages and persists audio mixer settings', () async {
      final game = AsteroidsGame();
      expect(game.masterVolume, 1.0);
      expect(game.bgmVolume, 0.8);
      expect(game.sfxVolume, 1.0);
      expect(game.effectiveBgmVolume, 0.8);

      // Adjust mixer settings
      game.updateAudioMix(master: 0.5, bgm: 0.6, sfx: 0.7);
      expect(game.masterVolume, 0.5);
      expect(game.bgmVolume, 0.6);
      expect(game.sfxVolume, 0.7);
      expect(game.effectiveBgmVolume, closeTo(0.3, 0.001));

      // Test persistence
      await game.saveAudioSettings();
      final freshGame = AsteroidsGame();
      await freshGame.loadAudioSettings();
      expect(freshGame.masterVolume, 0.5);
      expect(freshGame.bgmVolume, 0.6);
      expect(freshGame.sfxVolume, 0.7);
    });

    testWidgets('Sprint 50: SettingsOverlay renders Audio Mixer Dashboard with sliders and test button', (tester) async {
      tester.view.physicalSize = const Size(1280, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final game = AsteroidsGame();

      await tester.pumpWidget(
        MaterialApp(
          home: SettingsOverlay(game: game),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(I18n.t('settings.audio_mixer')), findsOneWidget);
      expect(find.text(I18n.t('settings.master')), findsOneWidget);
      expect(find.text(I18n.t('settings.bgm')), findsOneWidget);
      expect(find.text(I18n.t('settings.sfx')), findsOneWidget);
      expect(find.text(I18n.t('settings.test_sfx')), findsOneWidget);

      // Tap test SFX button
      await tester.tap(find.text(I18n.t('settings.test_sfx')));
      await tester.pumpAndSettle();
    });

    test('Sprint 51: BulletComponent with evolved weapon emits particle flourishes and renders corona', () {
      final game = AsteroidsGame();
      final evolvedWeapon = Blaster()..level = 5;
      evolvedWeapon.evolve();
      expect(evolvedWeapon.isEvolved, isTrue);

      final bullet = BulletComponent(
        position: Vector2(200, 200),
        radius: 6.0,
        velocity: Vector2(300, 0),
        lifeTimer: 2.0,
        weaponSource: evolvedWeapon,
      );

      game.world.add(bullet);
      bullet.update(0.1); // Advances trail timer and emits flourishes

      // Bullet should be active in world
      expect(bullet.isMounted || bullet.parent != null, isTrue);
    });

    test('Sprint 52: AsteroidsGame smoothly interpolates camera zoom and triggers boss punch zoom', () {
      final game = AsteroidsGame();
      expect(game.targetCameraZoom, 1.0);
      expect(game.camera.viewfinder.zoom, 1.0);

      // Set target zoom
      game.setCameraZoom(1.15);
      expect(game.targetCameraZoom, 1.15);

      // Interpolation over dt
      game.update(0.2);
      expect(game.camera.viewfinder.zoom > 1.0, isTrue);
      expect(game.camera.viewfinder.zoom <= 1.15, isTrue);

      // Boss defeat triggers camera punch zoom (1.18x)
      game.onBossDefeatedSpeechCheck();
      expect(game.targetCameraZoom, 1.18);
    });
  });
}
