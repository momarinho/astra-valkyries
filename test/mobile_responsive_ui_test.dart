import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flame/components.dart';
import 'package:void_protocol/game/asteroids_game.dart';
import 'package:void_protocol/game/components/player.dart';
import 'package:void_protocol/game/rogue_perks.dart';
import 'package:void_protocol/game/valkyrie.dart';
import 'package:void_protocol/ui/game_over_overlay.dart';
import 'package:void_protocol/ui/hud_overlay.dart';
import 'package:void_protocol/ui/level_up_overlay.dart';
import 'package:void_protocol/ui/pause_overlay.dart';
import 'package:void_protocol/ui/settings_overlay.dart';
import 'package:void_protocol/ui/shop_overlay.dart';
import 'package:void_protocol/ui/title_screen_overlay.dart';
import 'package:void_protocol/ui/valkyrie_selection_overlay.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Responsive Camera & Web Mobile UI', () {
    test('computeResponsiveCameraZoom scales cleanly for portrait and landscape mobile', () {
      expect(AsteroidsGame.computeResponsiveCameraZoom(1280, 720), closeTo(1.0, 0.001));

      final portraitZoom = AsteroidsGame.computeResponsiveCameraZoom(390, 844);
      expect(portraitZoom, closeTo(390 / 740.0, 0.001));
      expect(390 / portraitZoom, closeTo(740.0, 1.0));

      final smallPortraitZoom = AsteroidsGame.computeResponsiveCameraZoom(360, 640);
      expect(smallPortraitZoom, closeTo(360 / 740.0, 0.001));

      final landscapeZoom = AsteroidsGame.computeResponsiveCameraZoom(844, 390);
      expect(landscapeZoom, closeTo(390 / 720.0, 0.001));
      expect(844 / landscapeZoom, greaterThanOrEqualTo(960.0));
    });

    final mobileViewports = <Size>[
      const Size(360, 640), // Compact Portrait
      const Size(390, 844), // Standard Portrait
      const Size(667, 375), // Compact Landscape
      const Size(844, 390), // Standard Landscape
    ];

    AsteroidsGame createMockGame() {
      final game = AsteroidsGame();
      game.state = GameState.playing;
      game.selectedValkyrie = Valkyrie.roster.first;
      game.player = PlayerComponent(position: Vector2(100, 100))
        ..customGame = game;
      game.player.valkyrie = game.selectedValkyrie;
      game.currentLevelUpChoices = RoguePerkGenerator.generateChoices(game, count: 3);
      game.runRerollsRemaining = 2;
      game.runBanishesRemaining = 1;
      game.score = 4250;
      game.runCredits = 320;
      return game;
    }

    Future<void> pumpAndAssertClean(WidgetTester tester, Size size, Widget child) async {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: size),
            child: child,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
    }

    for (final size in mobileViewports) {
      testWidgets('TitleScreenOverlay renders cleanly on ${size.width}x${size.height}', (tester) async {
        final game = createMockGame();
        await pumpAndAssertClean(tester, size, TitleScreenOverlay(game: game));
        // Skip boot animation to test main title view without blocking on infinite idle loops
        await tester.tap(find.byType(TitleScreenOverlay));
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.textContaining('VOID PROTOCOL'), findsWidgets);
        expect(tester.takeException(), isNull);
      });

      testWidgets('ValkyrieSelectionOverlay renders cleanly on ${size.width}x${size.height}', (tester) async {
        final game = createMockGame();
        await pumpAndAssertClean(tester, size, ValkyrieSelectionOverlay(game: game));
      });

      testWidgets('LevelUpOverlay renders cleanly on ${size.width}x${size.height}', (tester) async {
        final game = createMockGame();
        await pumpAndAssertClean(tester, size, Scaffold(body: LevelUpOverlay(game: game)));
      });

      testWidgets('PauseOverlay renders cleanly on ${size.width}x${size.height}', (tester) async {
        final game = createMockGame();
        await pumpAndAssertClean(tester, size, PauseOverlay(game: game));
      });

      testWidgets('GameOverOverlay renders cleanly on ${size.width}x${size.height}', (tester) async {
        final game = createMockGame();
        await pumpAndAssertClean(tester, size, GameOverOverlay(game: game));
      });

      testWidgets('ShopOverlay renders cleanly on ${size.width}x${size.height}', (tester) async {
        final game = createMockGame();
        await pumpAndAssertClean(tester, size, ShopOverlay(game: game));
      });

      testWidgets('SettingsOverlay renders cleanly on ${size.width}x${size.height}', (tester) async {
        final game = createMockGame();
        await pumpAndAssertClean(tester, size, SettingsOverlay(game: game));
      });

      testWidgets('HudOverlay with Launch Transmission renders cleanly on ${size.width}x${size.height}', (tester) async {
        final game = createMockGame();
        game.showLaunchTransmission = true;
        await pumpAndAssertClean(tester, size, Scaffold(body: HudOverlay(game: game)));
      });
    }
  });
}
