import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flame/components.dart';
import 'package:void_protocol/game/asteroids_game.dart';
import 'package:void_protocol/game/components/player.dart';
import 'package:void_protocol/game/valkyrie.dart';
import 'package:void_protocol/game/weapons.dart';
import 'package:void_protocol/ui/hud_overlay.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final resolutions = [
    const Size(1920, 1080),
    const Size(1280, 720),
    const Size(1024, 768),
    const Size(800, 600),
    const Size(844, 390), // Mobile landscape
    const Size(667, 375), // Small mobile landscape
    const Size(390, 844), // Mobile portrait
    const Size(360, 640), // Small mobile portrait
  ];

  for (final res in resolutions) {
    testWidgets(
      'HudOverlay renders without error on ${res.width}x${res.height}',
      (tester) async {
        await tester.binding.setSurfaceSize(res);
        final game = AsteroidsGame();
        game.selectedValkyrie = Valkyrie.findById('selene');
        game.player = PlayerComponent(position: Vector2(100, 100))
          ..customGame = game;
        game.player.valkyrie = game.selectedValkyrie;
        game.score = 610;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: HudOverlay(game: game)),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        final err = tester.takeException();
        if (err is FlutterError) {
          // ignore: avoid_print
          print('DIAGNOSTICS for ${res.width}x${res.height}:');
          for (final d in err.diagnostics) {
            // ignore: avoid_print
            print('  ${d.name}: ${d.value}');
          }
        }
        expect(err, isNull);
      },
    );
  }

  testWidgets(
    'HudOverlay displays ★EVO badge on weapons ready for super-evolution',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 720));
      final game = AsteroidsGame();
      game.selectedValkyrie = Valkyrie.findById('kaede');
      game.player = PlayerComponent(position: Vector2(100, 100))
        ..customGame = game;
      game.player.valkyrie = game.selectedValkyrie;

      final katana = TachyonKatana();
      katana.level = katana.maxLevel; // Ready for evolution
      game.player.setWeapon(katana);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: HudOverlay(game: game)),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('★EVO'), findsOneWidget);
    },
  );
}
