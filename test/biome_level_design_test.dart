import 'package:flutter_test/flutter_test.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:void_protocol/game/asteroids_game.dart';
import 'package:void_protocol/game/sector.dart';
import 'package:void_protocol/game/components/indoor_environment.dart';
import 'package:void_protocol/game/components/dead_cells_biome.dart';
import 'package:void_protocol/game/components/living_biomes.dart';
import 'package:void_protocol/game/components/breakable_prop.dart';
import 'package:void_protocol/game/map/sector_map_generator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Sprint 31: Biome Thematic Level Design (Inlaid Library, Gallo Tower, Aegis Hangar) Tests', () {
    test('Helios Forge (Setor 2A) constructs horizontal corridor architecture (Inlaid Library style)', () {
      final game = AsteroidsGame();
      game.currentSector = Sector.findById(SectorId.orion);
      final mapData = SectorMapGenerator.generateAndSpawn(game, customSeed: 101);

      expect(mapData.sector.id, equals(SectorId.orion));

      // Verifica presença do piso industrial contínuo da refinaria solar
      final floors = game.world.children.whereType<ModularFloorComponent>().toList();
      expect(floors.isNotEmpty, isTrue);

      // Deve ter pelo menos um piso de largura horizontal expressiva (>= 3000px)
      final corridorFloor = floors.firstWhere((f) => f.size.x >= 3000.0);
      expect(corridorFloor.floorAccent, equals(const Color(0xFFFF9100)));

      // Verifica presença de jatos solares e paredes de megastrutura
      final walls = game.world.children.whereType<MegastructureWallComponent>();
      expect(walls.isNotEmpty, isTrue);

      final jets = game.world.children.whereType<SolarFlameJetComponent>();
      expect(jets.isNotEmpty, isTrue);
    });

    test('Cryo Abyss (Setor 2B) constructs vertical canyon architecture (Gallo Tower style) with central Thermal Dome', () {
      final game = AsteroidsGame();
      game.currentSector = Sector.findById(SectorId.cryoAbyss);
      final mapData = SectorMapGenerator.generateAndSpawn(game, customSeed: 202);

      expect(mapData.sector.id, equals(SectorId.cryoAbyss));

      // Verifica presença do piso glacial vertical
      final floors = game.world.children.whereType<ModularFloorComponent>().toList();
      expect(floors.isNotEmpty, isTrue);

      final verticalFloor = floors.firstWhere((f) => f.size.y >= 3000.0);
      expect(verticalFloor.size.x, closeTo(1740.0, 50.0));

      // Verifica presença do Domo Térmico central
      final domes = game.world.children.whereType<ThermalDomeComponent>();
      expect(domes.isNotEmpty, isTrue);
      expect(domes.first.position, equals(Vector2(2400, 2400)));

      // Verifica presença de zonas de Cryo Mist e minas criogênicas
      final mists = game.world.children.whereType<CryoMistZoneComponent>();
      expect(mists.isNotEmpty, isTrue);
    });

    test('Aegis Graveyard (Setor 3A) builds derelict dreadnought decks and containment hazards', () {
      final game = AsteroidsGame();
      game.currentSector = Sector.findById(SectorId.graveyard);
      final mapData = SectorMapGenerator.generateAndSpawn(game, customSeed: 303);

      expect(mapData.sector.id, equals(SectorId.graveyard));

      // Verifica presença de pisos industriais internos dos encouraçados
      final floors = game.world.children.whereType<ModularFloorComponent>();
      expect(floors.isNotEmpty, isTrue);

      // Verifica vazamentos radioativos do reator
      final leaks = game.world.children.whereType<ReactorLeakHazardComponent>();
      expect(leksOrNotNull(leaks), isTrue);

      // Verifica paredes de casco de encouraçado
      final walls = game.world.children.whereType<MegastructureWallComponent>();
      expect(walls.length, greaterThanOrEqualTo(5));
    });

    test('Vesta Belt (Setor 1) generates mining ridges and breakable props', () {
      final game = AsteroidsGame();
      game.currentSector = Sector.findById(SectorId.vesta);
      final mapData = SectorMapGenerator.generateAndSpawn(game, customSeed: 404);

      expect(mapData.sector.id, equals(SectorId.vesta));

      // Verifica se há props quebráveis (veios de minério, barris e cargas)
      final props = game.world.children.whereType<BreakablePropComponent>().toList();
      expect(props.length, greaterThan(15));

      final oreProps = props.where((p) => p.type == BreakablePropType.oreCrystal);
      expect(oreProps.isNotEmpty, isTrue);

      final barrelProps = props.where((p) => p.type == BreakablePropType.explosiveBarrel);
      expect(barrelProps.isNotEmpty, isTrue);
    });
  });
}

bool leksOrNotNull(Iterable<ReactorLeakHazardComponent> leaks) => leaks.isNotEmpty;
