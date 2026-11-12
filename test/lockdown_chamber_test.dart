import 'package:flutter_test/flutter_test.dart';
import 'package:flame/components.dart';
import 'package:asteroids/game/asteroids_game.dart';
import 'package:asteroids/game/sector.dart';
import 'package:asteroids/game/components/player.dart';
import 'package:asteroids/game/components/bullet.dart';
import 'package:asteroids/game/components/enemy_ship.dart';
import 'package:asteroids/game/components/chest.dart';
import 'package:asteroids/game/components/indoor_environment.dart';
import 'package:asteroids/game/components/dead_cells_biome.dart';
import 'package:asteroids/game/map/sector_map_generator.dart';
import 'package:asteroids/game/map/sector_map_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Sprint 30: Indoor Level Design, Blast Doors & Lockdown Chambers Tests', () {
    test('ModularFloorComponent sets priority -38 and covers specified room area', () {
      final floor = ModularFloorComponent(
        position: Vector2(500, 500),
        size: Vector2(700, 600),
      );
      expect(floor.priority, equals(-38));
      expect(floor.size, equals(Vector2(700, 600)));
      expect(floor.position, equals(Vector2(500, 500)));
    });

    test('BlastDoorComponent toggles open and closed states, blocking projectiles when closed', () {
      final door = BlastDoorComponent(
        position: Vector2(200, 200),
        length: 160.0,
        isHorizontal: true,
        isOpen: false,
      );
      expect(door.isOpen, isFalse);
      expect(door.transitionProgress, equals(0.0));

      // Dispara projétil contra porta fechada
      final bullet = BulletComponent(
        position: Vector2(200, 200),
        radius: 4.0,
        velocity: Vector2(0, 100),
        lifeTimer: 2.0,
        damage: 20.0,
      );

      door.onCollisionStart({}, bullet);
      // O projétil deve ser destruído/removido pela porta fechada
      expect(bullet.isRemoving || !bullet.isMounted, isTrue);

      // Abre a porta
      door.openDoor();
      expect(door.isOpen, isTrue);

      // Atualiza o tempo para completar a animação
      door.update(1.0);
      expect(door.transitionProgress, equals(1.0));

      // Dispara outro projétil com a porta aberta
      final bullet2 = BulletComponent(
        position: Vector2(200, 200),
        radius: 4.0,
        velocity: Vector2(0, 100),
        lifeTimer: 2.0,
        damage: 20.0,
      );
      door.onCollisionStart({}, bullet2);
      // Com a porta aberta, o tiro passa direto sem ser bloqueado
      expect(bullet2.isRemoving, isFalse);
    });

    test('LockdownChamberComponent spawns floor, perimeter walls and blast doors in onLoad', () async {
      final game = AsteroidsGame();
      final chamber = LockdownChamberComponent(
        position: Vector2(1000, 1000),
        chamberSize: Vector2(750, 700),
      );
      await game.world.add(chamber);
      await chamber.onLoad();

      expect(chamber.state, equals(ChamberState.dormant));
      expect(chamber.doors.length, equals(2));
      expect(chamber.floorComponent, isNotNull);

      // Verifica se as paredes e o piso foram adicionados ao mundo
      final walls = game.world.children.whereType<MegastructureWallComponent>();
      expect(walls.length, greaterThanOrEqualTo(6));

      final doors = game.world.children.whereType<BlastDoorComponent>();
      expect(doors.length, equals(2));
    });

    test('LockdownChamberComponent triggers lockdown, locks doors and spawns enemies when player enters', () async {
      final game = AsteroidsGame();
      game.state = GameState.playing;
      game.player = PlayerComponent(position: Vector2.zero())..customGame = game;

      final chamber = LockdownChamberComponent(
        position: Vector2(2000, 2000),
        chamberSize: Vector2(750, 700),
        enemyWaveCount: 4,
      );
      await game.world.add(chamber);
      await chamber.onLoad();

      // Jogador ainda está longe (em 0, 0): câmara permanece dormente
      chamber.update(0.1);
      expect(chamber.state, equals(ChamberState.dormant));
      expect(chamber.doors.every((d) => d.isOpen), isTrue);

      // Move jogador para dentro do centro da câmara
      game.player.position = Vector2(2000, 2000);
      chamber.update(0.1);

      // Deve ter entrado em lockdown!
      expect(chamber.state, equals(ChamberState.lockdown));
      // Portas devem ter sido trancadas/fechadas
      expect(chamber.doors.every((d) => !d.isOpen), isTrue);

      // Inimigos da onda de quarentena devem ter sido spawnados
      final chamberEnemies = game.world.children.whereType<EnemyShipComponent>().toList();
      expect(chamberEnemies.length, equals(4));
    });

    test('LockdownChamberComponent unlocks doors and awards Gold Chest when chamber wave is cleared', () async {
      final game = AsteroidsGame();
      game.state = GameState.playing;
      game.player = PlayerComponent(position: Vector2(3000, 3000))..customGame = game;

      final chamber = LockdownChamberComponent(
        position: Vector2(3000, 3000),
        chamberSize: Vector2(750, 700),
        enemyWaveCount: 2,
      );
      await game.world.add(chamber);
      await chamber.onLoad();

      // Entra em lockdown
      chamber.startLockdown();
      expect(chamber.state, equals(ChamberState.lockdown));

      // Simula a eliminação de todos os inimigos da câmara
      final enemies = game.world.children.whereType<EnemyShipComponent>().toList();
      for (final e in enemies) {
        e.removeFromParent();
      }

      // Atualiza a câmara para processar a vitória
      chamber.update(0.1);

      expect(chamber.state, equals(ChamberState.completed));
      // Portas devem reabrir
      expect(chamber.doors.every((d) => d.isOpen), isTrue);

      // Deve ter liberado o Baú Dourado
      final chests = game.world.children.whereType<ChestComponent>().toList();
      expect(chests.isNotEmpty, isTrue);
      expect(chests.first.tier, equals(ChestTier.gold));
    });

    test('SectorMapGenerator spawns LockdownChamberComponent and cleans it up on new sector', () {
      final game = AsteroidsGame();
      game.currentSector = Sector.findById(SectorId.vesta);
      final mapData = SectorMapGenerator.generateAndSpawn(game, customSeed: 1234);

      // Verifica se um nó de câmara de quarentena foi registrado no mapa tático
      final chamberNodes = mapData.nodes.where((n) => n.type == MapNodeType.lockdownChamber);
      expect(chamberNodes.isNotEmpty, isTrue);

      final chambers = game.world.children.whereType<LockdownChamberComponent>().toList();
      expect(chambers.isNotEmpty, isTrue);

      // Regenera com outro seed: deve limpar as anteriores
      SectorMapGenerator.generateAndSpawn(game, customSeed: 5678);
      for (final oldChamber in chambers) {
        expect(oldChamber.isRemoving || !oldChamber.isMounted, isTrue);
      }
    });
  });
}
