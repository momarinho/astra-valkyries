import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'game/asteroids_game.dart';
import 'ui/valkyrie_selection_overlay.dart';
import 'ui/title_screen_overlay.dart';
import 'ui/settings_overlay.dart';
import 'ui/hud_overlay.dart';
import 'ui/shop_overlay.dart';
import 'ui/stage_clear_overlay.dart';
import 'ui/game_over_overlay.dart';
import 'ui/leaderboard_overlay.dart';
import 'ui/weapon_selection_overlay.dart';
import 'ui/pause_overlay.dart';
import 'ui/level_up_overlay.dart';
import 'ui/chest_overlay.dart';
import 'ui/tactical_map_overlay.dart';
import 'ui/star_chart_overlay.dart';
import 'services/localization_service.dart';
import 'services/achievement_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await I18n.init();
  await AchievementService.load();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Astra Valkyries: Void Protocol',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.deepPurple,
      ),
      home: const GameScreen(),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final AsteroidsGame _game;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _game = AsteroidsGame();
    _focusNode = FocusNode();
    _game.gameFocusNode = _focusNode;
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLocale>(
      valueListenable: I18n.localeNotifier,
      builder: (context, locale, child) {
        return Scaffold(
          body: GameWidget<AsteroidsGame>(
            game: _game,
            focusNode: _focusNode,
            autofocus: true,
            overlayBuilderMap: {
              'valkyrieSelection': (context, game) => ValkyrieSelectionOverlay(game: game),
              'menu': (context, game) => TitleScreenOverlay(game: game),
              'settings': (context, game) => SettingsOverlay(game: game),
              'hud': (context, game) => HudOverlay(game: game),
              'shop': (context, game) => ShopOverlay(game: game),
              'stageClear': (context, game) => StageClearOverlay(game: game),
              'gameOver': (context, game) => GameOverOverlay(game: game),
              'leaderboard': (context, game) => LeaderboardOverlay(game: game),
              'weaponSelection': (context, game) => WeaponSelectionOverlay(game: game),
              'pause': (context, game) => PauseOverlay(game: game),
              'levelUp': (context, game) => LevelUpOverlay(game: game),
              'chest': (context, game) => ChestOverlay(game: game),
              'tacticalMap': (context, game) => TacticalMapOverlay(game: game),
              'starChart': (context, game) => StarChartOverlay(game: game),
            },
            initialActiveOverlays: const ['menu'],
          ),
        );
      },
    );
  }
}
