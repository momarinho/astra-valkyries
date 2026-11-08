import 'package:flutter_test/flutter_test.dart';
import 'package:flame/extensions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:asteroids/game/asteroids_game.dart';
import 'package:asteroids/game/sector.dart';
import 'package:asteroids/game/components/player.dart';
import 'package:asteroids/game/components/asteroid_field.dart';
import 'package:asteroids/game/components/hyperspace_gate.dart';
import 'package:asteroids/game/components/phase4_biome_elements.dart';
import 'package:asteroids/game/components/starfield.dart';

AsteroidsGame _createTestGame() {
  final game = AsteroidsGame();
  game.player = PlayerComponent(position: Vector2(1000, 1000))..customGame = game;
  game.asteroidField = AsteroidField();
  game.world.add(game.player);
  game.world.add(game.asteroidField!);
  game.state = GameState.playing;
  return game;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Roguelite Pacing, Hordes, Biome Backdrop & Seamless Sector Flow Tests', () {
    test('AsteroidField triggers early swarm rush at 20s, elite at 45s, and boss climax at 150s', () {
      final game = _createTestGame();
      final field = game.asteroidField!;

      // At t=0, none of the scripted events have fired
      expect(field.swarm20Spawned, isFalse);
      expect(field.subBoss45Spawned, isFalse);
      expect(field.sectorClimaxSpawned, isFalse);

      // Advance to 22s -> Swarm Rush should trigger
      field.update(22.0);
      expect(field.swarm20Spawned, isTrue);
      expect(field.subBoss45Spawned, isFalse);

      // Advance past 45s -> Sub-boss should trigger
      field.update(25.0); // total 47s
      expect(field.subBoss45Spawned, isTrue);
      expect(field.sectorClimaxSpawned, isFalse);

      // Advance past 150s -> Sector Boss Climax should trigger
      field.update(105.0); // total 152s
      expect(field.sectorClimaxSpawned, isTrue);
      expect(game.activeBoss, isNotNull);
    });

    test('HyperspaceGateComponent has magnetic pull and auto-opens StarChart after 3.5s', () {
      final game = _createTestGame();
      final gate = HyperspaceGateComponent(position: Vector2(1300, 1000));
      game.world.add(gate);
      gate.onMount();

      expect(gate.position.x, equals(1300.0));

      // Update gate by 1.0s -> it should drift toward player at (1000, 1000)
      gate.update(1.0);
      expect(gate.position.x < 1300.0, isTrue);

      // Update gate past 3.5s -> automatically triggers StarChart transition
      gate.update(2.6);
      expect(game.state, equals(GameState.starChart));
    });

    test('BiomeBackdropComponent and StarfieldComponent have non-conflicting render priorities', () {
      final backdrop = BiomeBackdropComponent(sectorId: SectorId.vesta);
      final starfield = StarfieldComponent();

      // BiomeBackdrop (-45) renders under Starfield (-40)
      expect(backdrop.priority, equals(-45));
      expect(starfield.priority, equals(-40));
    });

    test('jumpToNextSector resets difficulty timers, heals player and updates sector', () {
      final game = _createTestGame();
      game.currentSector = Sector.findById(SectorId.vesta);
      game.player.hp = 20.0;
      game.asteroidField!.difficultyTimer = 140.0;
      game.asteroidField!.swarm20Spawned = true;
      game.asteroidField!.subBoss45Spawned = true;

      // Jump to Helios Forge (Orion)
      game.jumpToNextSector(targetSector: Sector.findById(SectorId.orion));

      expect(game.currentSector.id, equals(SectorId.orion));
      expect(game.asteroidField!.difficultyTimer, equals(0.0));
      expect(game.asteroidField!.swarm20Spawned, isFalse);
      expect(game.asteroidField!.subBoss45Spawned, isFalse);
      expect(game.player.hp, equals(game.player.maxHp));
    });
  });
}
