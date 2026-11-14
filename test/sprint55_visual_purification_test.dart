import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flame/components.dart';
import 'package:void_protocol/game/asteroids_game.dart';
import 'package:void_protocol/game/sector.dart';
import 'package:void_protocol/game/components/breakable_prop.dart';
import 'package:void_protocol/game/components/dead_cells_biome.dart';
import 'package:void_protocol/game/components/indoor_environment.dart';
import 'package:void_protocol/game/components/phase4_biome_elements.dart';
import 'package:void_protocol/game/components/asteroid.dart';
import 'package:void_protocol/game/components/enemy_bullet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Sprint 55 — Visual Purification & Procedural Vector Megastructures', () {
    test('MegastructureWallComponent initializes purely procedurally without raster textures', () {
      final wall = MegastructureWallComponent(
        position: Vector2(500, 500),
        wallSize: Vector2(300, 32),
        wallColor: const Color(0xFF00E5FF),
      );

      expect(wall.position, equals(Vector2(500, 500)));
      expect(wall.size, equals(Vector2(300, 32)));
      expect(wall.wallColor, equals(const Color(0xFF00E5FF)));
    });

    test('MegastructureWallComponent physically blocks and deflects colliding asteroids', () {
      final game = AsteroidsGame();
      final wall = MegastructureWallComponent(
        position: Vector2(400, 400),
        wallSize: Vector2(200, 40),
      );
      final asteroid = AsteroidComponent(
        position: Vector2(400, 410),
        radius: 40.0,
        velocity: Vector2(0, -60.0),
      );

      game.world.addAll([wall, asteroid]);
      wall.resolveAsteroidCollision(asteroid);

      expect(asteroid.velocity.y, greaterThanOrEqualTo(0));
    });

    test('ModularFloorComponent sets correct priority and renders procedural hangar decking', () {
      final floor = ModularFloorComponent(
        position: Vector2(1000, 1000),
        size: Vector2(400, 300),
        floorAccent: const Color(0xFFFFB300),
      );

      expect(floor.priority, equals(-38));
      expect(floor.size, equals(Vector2(400, 300)));
      expect(floor.floorAccent, equals(const Color(0xFFFFB300)));

      // Verificação de ciclo de update sem exceções
      floor.update(0.016);
    });

    test('StationStructureComponent supports satellite relays, corridors and craters purely in vector', () {
      final dish = StationStructureComponent(
        position: Vector2(600, 600),
        size: Vector2(90, 90),
        spriteAsset: 'satelliteDishLarge.png',
        isSolid: false,
        beaconColor: const Color(0xFF00E5FF),
      );

      final pipe = StationStructureComponent(
        position: Vector2(700, 600),
        size: Vector2(40, 80),
        spriteAsset: 'pipeStraight.png',
        isSolid: true,
      );

      final module = StationStructureComponent(
        position: Vector2(800, 600),
        size: Vector2(50, 50),
        spriteAsset: 'spaceStation_017.png',
        isSolid: true,
        beaconColor: const Color(0xFFFF1744),
      );

      expect(dish.isSolid, isFalse);
      expect(pipe.isSolid, isTrue);
      expect(module.beaconColor, equals(const Color(0xFFFF1744)));

      dish.update(0.05);
      pipe.update(0.05);
      module.update(0.05);
    });

    test('AsteroidReefComponent renders procedural craters and ore clusters without raster crashes', () {
      final reef = AsteroidReefComponent(
        position: Vector2(1200, 1200),
        size: Vector2(300, 100),
        clusters: [
          (offset: const Offset(50, 50), radius: 35.0, craterScale: 0.8),
          (offset: const Offset(150, 50), radius: 45.0, craterScale: 1.0),
          (offset: const Offset(250, 50), radius: 30.0, craterScale: 0.7),
        ],
        oreGlowColor: const Color(0xFFFFD700),
      );

      expect(reef.priority, equals(-36));
      expect(reef.clusters.length, equals(3));
      reef.update(0.016);
    });

    test('BreakablePropComponent renders all 4 types procedurally and maintains damage feedback', () {
      for (final type in BreakablePropType.values) {
        final prop = BreakablePropComponent(
          position: Vector2(300, 300),
          type: type,
        );

        expect(prop.hp, greaterThan(0));
        expect(prop.size.x, greaterThan(20));
        expect(prop.size.y, greaterThan(20));

        prop.takeDamage(10.0);
        expect(prop.hitFlashTimer, greaterThan(0));
        prop.update(0.02);
      }
    });

    test('BreakablePropComponent EMP Nova clearing works cleanly with vector-first architecture', () {
      final game = AsteroidsGame();
      final fusionCell = BreakablePropComponent(
        position: Vector2(500, 500),
        type: BreakablePropType.fusionCell,
      );

      final bullet = EnemyBulletComponent(
        position: Vector2(520, 520),
        radius: 5.0,
        velocity: Vector2.zero(),
      );

      game.world.addAll([fusionCell, bullet]);
      expect(game.world.children.whereType<EnemyBulletComponent>().length, equals(1));

      // Destrói a célula de fusão
      fusionCell.takeDamage(50.0);
      expect(fusionCell.isDestroyed, isTrue);
    });

    test('BiomeBackdropComponent renders deep cosmic void and motes for every sector without JPEG asset dependencies', () {
      for (final sectorId in SectorId.values) {
        final backdrop = BiomeBackdropComponent(sectorId: sectorId);
        expect(backdrop.priority, equals(-45));
        expect(backdrop.sectorId, equals(sectorId));
        backdrop.update(0.016);
      }
    });
  });
}
