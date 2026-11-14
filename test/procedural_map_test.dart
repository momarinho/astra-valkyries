import 'package:flutter_test/flutter_test.dart';
import 'package:flame/components.dart';
import 'package:void_protocol/constants.dart';
import 'package:void_protocol/game/asteroids_game.dart';
import 'package:void_protocol/game/sector.dart';
import 'package:void_protocol/game/components/player.dart';
import 'package:void_protocol/game/components/boss_lair.dart';
import 'package:void_protocol/game/map/sector_map_data.dart';
import 'package:void_protocol/game/map/sector_map_generator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Sprint 8: Dead Cells-Style Procedural Map & Boss Lair Tests', () {
    test('SectorMapGenerator creates procedural layout with POIs and distant Boss Lair', () {
      final game = AsteroidsGame();
      game.currentSector = Sector.findById(SectorId.vesta);
      final mapData = SectorMapGenerator.generateAndSpawn(game, customSeed: 42);

      expect(mapData, isNotNull);
      expect(mapData.nodes.isNotEmpty, isTrue);
      expect(mapData.bossLairNode, isNotNull);

      // Boss Lair deve estar a uma distância considerável do spawn central (2400, 2400)
      final center = Vector2(GameConstants.sectorWidth / 2, GameConstants.sectorHeight / 2);
      final distToLair = (mapData.bossLairNode.position - center).length;
      expect(distToLair, greaterThan(1200.0));

      // Deve haver estações de pesquisa e destroços de carga gerados
      final stations = mapData.nodes.where((n) => n.type == MapNodeType.station);
      expect(stations.isNotEmpty, isTrue);

      final wrecks = mapData.nodes.where((n) => n.type == MapNodeType.cargoWreck);
      expect(wrecks.length, greaterThanOrEqualTo(2));
    });

    test('Exploration tracking updates Fog of War and discovers nearby POIs', () {
      final game = AsteroidsGame();
      final mapData = SectorMapGenerator.generateAndSpawn(game, customSeed: 100);

      final initialExplored = mapData.exploredCells.length;
      expect(initialExplored, greaterThan(0));

      // Move a nave para próximo de um nó ainda não descoberto
      final undiscovered = mapData.nodes.firstWhere((n) => !n.isDiscovered);
      expect(undiscovered.isDiscovered, isFalse);

      // Simula voo da nave até as coordenadas do nó
      mapData.updateExploration(undiscovered.position, GameConstants.radarRange);

      expect(undiscovered.isDiscovered, isTrue);
      expect(mapData.exploredCells.length, greaterThan(initialExplored));
    });

    test('BossLairComponent awakens boss when player navigates into territorial arena', () {
      final game = AsteroidsGame();
      game.currentSector = Sector.findById(SectorId.vesta);
      final player = PlayerComponent(position: Vector2(2400, 2400));
      game.player = player;
      game.state = GameState.playing;

      final lairPos = Vector2(3600, 3600);
      final lair = BossLairComponent(position: lairPos);
      game.world.add(lair);

      expect(lair.isAwakened, isFalse);
      expect(game.activeBoss, isNull);

      // Jogadora ainda longe: chefe permanece adormecido
      lair.update(0.1);
      expect(lair.isAwakened, isFalse);

      // Jogadora entra no perímetro territorial do covil (raio <= 750px)
      player.position = Vector2(3500, 3500); // Distância ~ 141px
      lair.update(0.1);

      expect(lair.isAwakened, isTrue);
      expect(game.activeBoss, isNotNull);
      expect(game.activeBoss!.bossName, contains('DREADNOUGHT'));
    });

    test('Tactical Map open and close functions update isTacticalMapOpen state', () {
      final game = AsteroidsGame();
      game.state = GameState.playing;
      expect(game.isTacticalMapOpen, isFalse);

      game.openTacticalMap();
      expect(game.isTacticalMapOpen, isTrue);

      game.closeTacticalMap();
      expect(game.isTacticalMapOpen, isFalse);
    });
  });
}
