import 'package:flutter_test/flutter_test.dart';
import 'package:flame/components.dart';
import 'package:asteroids/game/asteroids_game.dart';
import 'package:asteroids/game/sector.dart';
import 'package:asteroids/game/valkyrie.dart';
import 'package:asteroids/game/components/player.dart';
import 'package:asteroids/game/components/enemy_ship.dart';
import 'package:asteroids/game/components/solar_fire_trail.dart';
import 'package:asteroids/game/components/singularity_vortex.dart';
import 'package:asteroids/game/components/phantom_shuriken.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Sprint 6: Balanced Valkyrie Dashes & Mob Orientation Tests', () {
    test('Lyra dash triggers Afterburner Surge with clean DashGhost and no damaging floor hazards', () {
      final game = AsteroidsGame();
      game.selectedValkyrie = Valkyrie.findById('lyra');
      final player = PlayerComponent(position: Vector2(500, 500));
      player.valkyrie = game.selectedValkyrie;
      game.player = player;
      game.state = GameState.playing;
      game.world.add(player);

      // Trigger Lyra dash
      player.dash();

      expect(player.dashActiveTimer, greaterThan(0.0));
      expect(player.dashCooldownTimer, equals(1.8));

      // Deve criar DashGhost visual, mas ZERO componentes de dano automático
      final ghosts = game.world.children.whereType<DashGhost>();
      expect(ghosts.isNotEmpty, isTrue);

      final fireTrails = game.world.children.whereType<SolarFireTrailComponent>();
      expect(fireTrails.isEmpty, isTrue);
    });

    test('Selene dash triggers Quantum Phase Blink with 210px warp and no damaging vortex', () {
      final game = AsteroidsGame();
      game.selectedValkyrie = Valkyrie.findById('selene');
      final player = PlayerComponent(position: Vector2(500, 500));
      player.valkyrie = game.selectedValkyrie;
      game.player = player;
      game.state = GameState.playing;
      game.world.add(player);

      final origin = player.position.clone();
      player.dash();

      // Selene teletransporta 210px limpos
      final dist = (player.position - origin).length;
      expect(dist, closeTo(210.0, 5.0));
      expect(player.dashCooldownTimer, equals(2.5));

      // Sem vortex de dano no chão
      final vortices = game.world.children.whereType<SingularityVortexComponent>();
      expect(vortices.isEmpty, isTrue);

      // Ghost deixado no ponto de origem
      final ghosts = game.world.children.whereType<DashGhost>();
      expect(ghosts.isNotEmpty, isTrue);
    });

    test('Vesper dash triggers Phantom Quick-Slip with 2 charges and no auto-shurikens', () {
      final game = AsteroidsGame();
      game.selectedValkyrie = Valkyrie.findById('vesper');
      final player = PlayerComponent(position: Vector2(500, 500));
      player.valkyrie = game.selectedValkyrie;
      player.initHp();
      game.player = player;
      game.state = GameState.playing;
      game.world.add(player);

      expect(player.maxDashCharges, equals(2));
      expect(player.dashCharges, equals(2));

      // Primeiro dash consome 1 carga
      player.dash();
      expect(player.dashCharges, equals(1));

      // Segundo dash consome a 2ª carga imediatamente
      player.dash();
      expect(player.dashCharges, equals(0));

      // Sem shurikens automáticos
      final shurikens = game.world.children.whereType<PhantomShurikenComponent>();
      expect(shurikens.isEmpty, isTrue);
    });

    test('Mob orientation fix: EnemyShipComponent points towards player and does not invert rotation', () {
      final game = AsteroidsGame();
      game.player = PlayerComponent(position: Vector2(500, 500));
      game.state = GameState.playing;

      final scout = EnemyShipComponent(position: Vector2(200, 500), type: EnemyType.scout);
      game.world.add(scout);

      scout.update(0.1);

      // Player está à direita (+X) do scout:
      expect(scout.velocity.x > 0, isTrue);
      expect(scout.angle, closeTo(1.5707, 0.05));
    });

    test('Instant Boss Encounter shortcut spawns the current sector boss immediately', () {
      final game = AsteroidsGame();
      game.selectedValkyrie = Valkyrie.roster.first;
      game.player = PlayerComponent(position: Vector2(2500, 2500));
      game.state = GameState.playing;
      game.currentSector = Sector.findById(SectorId.orion);

      expect(game.activeBoss, isNull);

      // Dispara invocação instantânea de boss
      game.triggerBossEncounter();

      expect(game.activeBoss, isNotNull);
      expect(game.activeBoss!.bossName, contains('IGNIS WYRM'));
      expect(game.activeBoss!.isDefeated, isFalse);
    });
  });
}
