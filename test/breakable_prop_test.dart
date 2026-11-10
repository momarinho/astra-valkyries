import 'package:flutter_test/flutter_test.dart';
import 'package:flame/components.dart';
import 'package:asteroids/game/asteroids_game.dart';
import 'package:asteroids/game/sector.dart';
import 'package:asteroids/game/components/breakable_prop.dart';
import 'package:asteroids/game/components/player.dart';
import 'package:asteroids/game/components/enemy_ship.dart';
import 'package:asteroids/game/components/enemy_bullet.dart';
import 'package:asteroids/game/components/asteroid.dart';
import 'package:asteroids/game/components/xp_orb.dart';
import 'package:asteroids/game/components/drop.dart';
import 'package:asteroids/game/map/sector_map_generator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Sprint 29: Breakable Props (Vampire Survivors Style) Tests', () {
    test('Default HP and Sizes match each BreakablePropType specifications', () {
      final barrel = BreakablePropComponent(
        position: Vector2(100, 100),
        type: BreakablePropType.explosiveBarrel,
      );
      expect(barrel.hp, equals(24.0));
      expect(barrel.size, equals(Vector2(38.0, 44.0)));

      final ore = BreakablePropComponent(
        position: Vector2(200, 200),
        type: BreakablePropType.oreCrystal,
      );
      expect(ore.hp, equals(38.0));
      expect(ore.size, equals(Vector2(46.0, 42.0)));

      final crate = BreakablePropComponent(
        position: Vector2(300, 300),
        type: BreakablePropType.cargoCrate,
      );
      expect(crate.hp, equals(50.0));
      expect(crate.size, equals(Vector2(48.0, 44.0)));

      final cell = BreakablePropComponent(
        position: Vector2(400, 400),
        type: BreakablePropType.fusionCell,
      );
      expect(cell.hp, equals(30.0));
      expect(cell.size, equals(Vector2(44.0, 36.0)));
    });

    test('Ore Crystal destruction grants credits and releases Stardust XP orbs', () {
      final game = AsteroidsGame();
      final initialScore = game.score;
      final ore = BreakablePropComponent(
        position: Vector2(500, 500),
        type: BreakablePropType.oreCrystal,
      );
      game.world.add(ore);

      final destroyed = ore.takeDamage(45.0);
      expect(destroyed, isTrue);
      expect(ore.isDestroyed, isTrue);
      expect(game.score, greaterThan(initialScore));

      // Verifica se orbes de XP foram adicionados ao mundo
      final xpOrbs = game.world.children.whereType<XpOrbComponent>();
      expect(xpOrbs.isNotEmpty, isTrue);
    });

    test('Explosive Barrel detonates dealing area damage to nearby enemies and asteroids', () {
      final game = AsteroidsGame();
      game.player = PlayerComponent(position: Vector2.zero())..customGame = game;
      final barrel = BreakablePropComponent(
        position: Vector2(1000, 1000),
        type: BreakablePropType.explosiveBarrel,
      );
      final enemy = EnemyShipComponent(
        position: Vector2(1060, 1000), // a 60px de distância (dentro do raio de 190px)
        type: EnemyType.scout,
      );
      final initialEnemyHp = enemy.hp;

      game.world.addAll([barrel, enemy]);

      final destroyed = barrel.takeDamage(30.0);
      expect(destroyed, isTrue);
      expect(barrel.isDestroyed, isTrue);

      // O inimigo deve ter sofrido dano da explosão em área
      expect(enemy.hp, lessThan(initialEnemyHp));
    });

    test('Fusion Cell EMP Nova clears nearby enemy bullets', () {
      final game = AsteroidsGame();
      final cell = BreakablePropComponent(
        position: Vector2(1500, 1500),
        type: BreakablePropType.fusionCell,
      );
      final bullet = EnemyBulletComponent(
        position: Vector2(1550, 1500), // a 50px da célula
        radius: 4.0,
        velocity: Vector2(100, 0),
      );

      game.world.addAll([cell, bullet]);

      cell.takeDamage(35.0);
      expect(cell.isDestroyed, isTrue);

      // O projétil inimigo dentro do raio de 280px deve ser removido
      expect(bullet.isRemoving || !bullet.isMounted, isTrue);
    });

    test('Cargo Crate destruction drops tactical items (health, shield or rare helium)', () {
      final game = AsteroidsGame();
      final crate = BreakablePropComponent(
        position: Vector2(2000, 2000),
        type: BreakablePropType.cargoCrate,
      );
      game.world.add(crate);

      crate.takeDamage(60.0);
      expect(crate.isDestroyed, isTrue);

      final drops = game.world.children.whereType<DropComponent>();
      expect(drops.isNotEmpty, isTrue);
    });

    test('SectorMapGenerator spawns BreakablePropComponents and cleans them up on new generation', () {
      final game = AsteroidsGame();
      game.currentSector = Sector.findById(SectorId.vesta);
      SectorMapGenerator.generateAndSpawn(game, customSeed: 42);

      final initialProps = game.world.children.whereType<BreakablePropComponent>().toList();
      expect(initialProps.length, greaterThan(15));

      // Gera novamente: deve limpar os anteriores e criar novos
      SectorMapGenerator.generateAndSpawn(game, customSeed: 99);

      final newProps = game.world.children.whereType<BreakablePropComponent>().toList();
      expect(newProps.length, greaterThan(15));
      for (final oldProp in initialProps) {
        expect(oldProp.isRemoving || !oldProp.isMounted, isTrue);
      }
    });
  });
}
