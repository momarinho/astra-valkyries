import 'package:flutter_test/flutter_test.dart';
import 'package:void_protocol/game/asteroids_game.dart';
import 'package:void_protocol/game/sector.dart';
import 'package:void_protocol/game/components/indoor_environment.dart';
import 'package:void_protocol/game/components/dead_cells_biome.dart';
import 'package:void_protocol/game/components/breakable_prop.dart';
import 'package:void_protocol/game/map/sector_map_generator.dart';
import 'package:void_protocol/game/map/sector_map_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Procedural Level Design & Seed Variety Tests', () {
    test('Different seeds generate genuinely distinct POI layouts (Seed 100 vs Seed 200)', () {
      final game1 = AsteroidsGame();
      game1.currentSector = Sector.findById(SectorId.vesta);
      final mapData1 = SectorMapGenerator.generateAndSpawn(game1, customSeed: 100);

      final merchant1 = mapData1.nodes.firstWhere((n) => n.type == MapNodeType.voidMerchant);
      final vault1 = mapData1.nodes.firstWhere((n) => n.type == MapNodeType.timedVault);
      final shrine1 = mapData1.nodes.firstWhere((n) => n.type == MapNodeType.cursedShrine);
      final chamber1 = mapData1.nodes.firstWhere((n) => n.type == MapNodeType.lockdownChamber);

      final game2 = AsteroidsGame();
      game2.currentSector = Sector.findById(SectorId.vesta);
      final mapData2 = SectorMapGenerator.generateAndSpawn(game2, customSeed: 200);

      final merchant2 = mapData2.nodes.firstWhere((n) => n.type == MapNodeType.voidMerchant);
      final vault2 = mapData2.nodes.firstWhere((n) => n.type == MapNodeType.timedVault);
      final shrine2 = mapData2.nodes.firstWhere((n) => n.type == MapNodeType.cursedShrine);
      final chamber2 = mapData2.nodes.firstWhere((n) => n.type == MapNodeType.lockdownChamber);

      // As posições dos POIs essenciais devem ser dinâmicas e diferentes entre seeds distintas
      final samePositions = (merchant1.position == merchant2.position) &&
          (vault1.position == vault2.position) &&
          (shrine1.position == shrine2.position) &&
          (chamber1.position == chamber2.position);
      expect(samePositions, isFalse, reason: 'Seeds distintas devem gerar coordenadas distintas para os POIs cardinais.');
    });

    test('Vesta Belt instantiates real StationStructureComponents and Asteroid Canyons', () {
      final game = AsteroidsGame();
      game.currentSector = Sector.findById(SectorId.vesta);
      SectorMapGenerator.generateAndSpawn(game, customSeed: 777);

      // Ponto de inserção central (2400, 2400) possui estrutura de antena e balizas
      final stationStructures = game.world.children.whereType<StationStructureComponent>().toList();
      expect(stationStructures.length, greaterThanOrEqualTo(5),
          reason: 'O mapa deve conter estruturas modulares CC0 físicas como antenas, balizas e módulos.');

      // Paredes sólidas dividindo o setor em desfiladeiros cósmicos
      final walls = game.world.children.whereType<MegastructureWallComponent>().toList();
      expect(walls.length, greaterThanOrEqualTo(8),
          reason: 'O mapa deve conter cânions e desfiladeiros de asteroides físicos.');

      // Chokepoints com props destrutíveis
      final props = game.world.children.whereType<BreakablePropComponent>().toList();
      expect(props.length, greaterThanOrEqualTo(15));
    });

    test('SectorMapGenerator cleans up StationStructureComponents upon switching seeds', () {
      final game = AsteroidsGame();
      game.currentSector = Sector.findById(SectorId.vesta);
      SectorMapGenerator.generateAndSpawn(game, customSeed: 111);

      final firstCount = game.world.children.whereType<StationStructureComponent>().length;
      expect(firstCount, greaterThan(0));

      // Regenera com outro seed
      SectorMapGenerator.generateAndSpawn(game, customSeed: 222);

      // Deve ter substituído as antigas sem acumular componentes duplicados
      final secondCount = game.world.children.whereType<StationStructureComponent>().length;
      expect(secondCount, greaterThan(0));
      expect(secondCount, lessThan(firstCount * 2));
    });
  });
}
