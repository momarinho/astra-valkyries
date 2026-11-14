import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flame/game.dart';
import 'package:void_protocol/game/asteroids_game.dart';
import 'package:void_protocol/game/valkyrie.dart';
import 'package:void_protocol/game/components/player.dart';
import 'package:void_protocol/game/components/enemy_ship.dart';
import 'package:void_protocol/game/components/enemy_bullet.dart';
import 'package:void_protocol/game/components/xp_orb.dart';
import 'package:void_protocol/game/components/particle_system.dart';
import 'package:void_protocol/game/components/katana_slash.dart';
import 'package:void_protocol/game/components/bomb.dart';
import 'package:void_protocol/game/components/bullet.dart';
import 'package:void_protocol/game/weapons.dart';

AsteroidsGame _createTestGame([Valkyrie? valkyrie]) {
  final game = AsteroidsGame();
  final p = PlayerComponent(position: Vector2(500, 500))..customGame = game;
  if (valkyrie != null) {
    p.valkyrie = valkyrie;
    game.selectedValkyrie = valkyrie;
  }
  p.initHp();
  game.player = p;
  game.world.add(p);
  return game;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Sprint 33 - Combat Game Feel & 60 FPS Engine Refinement', () {
    test('Screen Shake accumulates trauma and decays smoothly', () {
      final game = _createTestGame();
      expect(game.shakeTimer, equals(0.0));

      game.triggerScreenShake(duration: 0.4, intensity: 10.0);
      expect(game.shakeTimer, equals(0.4));
      expect(game.shakeIntensity, equals(10.0));

      // Stronger impact accumulates trauma
      game.triggerScreenShake(duration: 0.6, intensity: 22.0);
      expect(game.shakeTimer, equals(0.6));
      expect(game.shakeIntensity, equals(22.0));

      // Decays over time
      game.update(0.2);
      expect(game.shakeTimer, closeTo(0.4, 0.001));

      game.update(0.5);
      expect(game.shakeTimer, equals(0.0));
    });

    test('FastParticlePoolComponent provides zero-allocation particle bursts', () {
      final pool = FastParticlePoolComponent();
      expect(pool.activeCount, equals(0));

      pool.spawnExplosion(
        position: Vector2(100, 100),
        colorChoices: [Colors.cyan, Colors.white],
        count: 25,
        minSize: 2.0,
        maxSize: 4.0,
        minSpeed: 50.0,
        maxSpeed: 150.0,
      );
      expect(pool.activeCount, equals(25));

      pool.spawnSparks(
        position: Vector2(100, 100),
        color: Colors.white,
        count: 8,
      );
      expect(pool.activeCount, equals(33));

      // Updating advances particle lifetime
      pool.update(0.1);
      expect(pool.activeCount, greaterThan(0));

      // Fast-forward beyond max lifetime clears active particles
      pool.update(1.0);
      expect(pool.activeCount, equals(0));

      // Test explicit clear
      pool.spawnSparks(position: Vector2(50, 50), color: Colors.amber, count: 12);
      expect(pool.activeCount, equals(12));
      pool.clear();
      expect(pool.activeCount, equals(0));
    });

    test('PlayerComponent receives pure-white hit flash on damage taken', () {
      final game = _createTestGame();
      game.state = GameState.playing;
      final player = game.player;
      player.invulnerableTimer = 0.0;
      player.initHp();

      expect(player.hitFlashTimer, equals(0.0));
      player.takeHit(15.0);
      expect(player.hitFlashTimer, closeTo(0.12, 0.01));

      player.update(0.06);
      expect(player.hitFlashTimer, closeTo(0.06, 0.01));

      player.update(0.10);
      expect(player.hitFlashTimer, equals(0.0));
    });

    test('EnemyShipComponent pure-white hit flash and spark emission', () {
      final game = _createTestGame();
      final enemy = EnemyShipComponent(
        type: EnemyType.scout,
        position: Vector2(200, 200),
      )..game = game;

      expect(enemy.hitFlashTimer, equals(0.0));
      enemy.takeDamage(10.0, Vector2(205, 205));
      expect(enemy.hitFlashTimer, closeTo(0.12, 0.01));
      expect(game.particlePool.activeCount, greaterThanOrEqualTo(5)); // Sparks emitted
    });

    test('Newtonian Recoil kicks player ship back upon firing heavy ordnance', () {
      final game = _createTestGame();
      final player = game.player;
      game.state = GameState.playing;
      player.initHp();
      player.velocity = Vector2.zero();

      // Equipping bomb launcher (recoil 22.0)
      final bomb = BombLauncher();
      player.setWeapon(bomb);
      bomb.currentCooldown = 0.0;

      player.update(0.016);
      // Ship facing upwards (0, -1), forward is (0, -1), recoil kickback should push downwards (positive Y)
      expect(player.velocity.y, greaterThan(20.0));
    });
  });

  group('Sprint 34 - HoloCure Valkyrie Ultimates & Kit Identity', () {
    test('Ultimate Charge Gauge charges passives, kills, and XP, and resets on trigger', () {
      final game = _createTestGame();
      game.state = GameState.playing;
      game.player.shootTimer = 99.0;
      game.specialAvailable = false;
      game.ultimateCharge = 0.0;

      // Passive recharge: 10s of 40s rate = 0.25
      for (int i = 0; i < 100; i++) {
        game.update(0.1);
      }
      expect(game.ultimateCharge, closeTo(0.25, 0.02));

      // XP orb collection charge (under level threshold to avoid triggering levelUp state pause)
      game.addXp(10);
      expect(game.ultimateCharge, greaterThan(0.25));

      // Direct charge gain reaching 100%
      game.gainUltimateCharge(1.0);
      expect(game.ultimateCharge, equals(1.0));
      expect(game.specialAvailable, isTrue);

      // Triggering special resets gauge
      game.triggerSpecial();
      expect(game.specialAvailable, isFalse);
      expect(game.ultimateCharge, equals(0.0));
    });

    test('Kaede/KBR-01 Ultimate: Tempest of Thousand Petals fires 24 Tachyon Katana slashes', () {
      final game = _createTestGame(Valkyrie.findById('kbr_01'));
      game.state = GameState.playing;
      game.specialAvailable = true;

      game.triggerSpecial();
      expect(game.player.invulnerableTimer, equals(4.0));
      final slashes = game.world.children.whereType<KatanaSlashComponent>().toList();
      expect(slashes.length, equals(24));
      expect(slashes.first.damage, equals(85.0));
    });

    test('Lyra Ultimate: Corona Supernova cleanses bullets and fires 36 solar flares', () {
      final game = _createTestGame(Valkyrie.findById('lyra'));
      game.state = GameState.playing;
      game.specialAvailable = true;

      // Add enemy bullets nearby and far away
      final nearbyBullet = EnemyBulletComponent(
        position: game.player.position + Vector2(100, 100),
        radius: 4.0,
        velocity: Vector2.zero(),
      );
      final farBullet = EnemyBulletComponent(
        position: game.player.position + Vector2(1200, 1200),
        radius: 4.0,
        velocity: Vector2.zero(),
      );
      game.world.add(nearbyBullet);
      game.world.add(farBullet);

      game.triggerSpecial();
      expect(game.player.invulnerableTimer, equals(3.5));
      expect(nearbyBullet.isRemoving || !nearbyBullet.isMounted, isTrue); // Cleared in 500px radius
      expect(farBullet.isRemoving, isFalse);    // Survived

      final solarBullets = game.world.children.whereType<BulletComponent>().toList();
      expect(solarBullets.length, equals(36));
    });

    test('Selene Ultimate: Absolute Zero Cryo Stasis freezes all onscreen enemies', () {
      final game = _createTestGame(Valkyrie.findById('selene'));
      game.state = GameState.playing;
      game.specialAvailable = true;

      final enemy1 = EnemyShipComponent(type: EnemyType.scout, position: Vector2(300, 300))..game = game;
      final enemy2 = EnemyShipComponent(type: EnemyType.raider, position: Vector2(400, 400))..game = game;
      game.world.add(enemy1);
      game.world.add(enemy2);

      game.triggerSpecial();
      expect(game.player.invulnerableTimer, equals(6.0));
      expect(enemy1.cryoFreezeTimer, closeTo(4.5, 0.01));
      expect(enemy2.cryoFreezeTimer, closeTo(4.5, 0.01));

      final photonBeams = game.world.children.whereType<BulletComponent>().toList();
      expect(photonBeams.length, equals(28));
    });

    test('Vesper Ultimate: Void Horizon Singularity detonates 420px void bomb and vacuums XP', () {
      final game = _createTestGame(Valkyrie.findById('vesper'));
      game.state = GameState.playing;
      game.specialAvailable = true;

      final orb = XpOrbComponent(
        position: game.player.position + Vector2(300, 0),
        type: XpOrbType.small,
      );
      game.world.add(orb);

      game.triggerSpecial();
      expect(game.player.invulnerableTimer, equals(3.5));
      final bomb = game.world.children.whereType<BombExplosionComponent>().first;
      expect(bomb.maxRadius, equals(420.0));
      expect(bomb.damage, equals(600.0));

      // XP orb velocity should be directed towards player
      expect(orb.velocity.x, lessThan(0.0)); // Pulled left toward player
    });

    test('Astraea Ultimate: Genesis Nova fires 36 imperial lasers and clears bullets', () {
      final game = _createTestGame(Valkyrie.secretValkyrie);
      game.state = GameState.playing;
      game.specialAvailable = true;

      game.triggerSpecial();
      expect(game.player.invulnerableTimer, equals(5.0));
      final imperialLasers = game.world.children.whereType<BulletComponent>().toList();
      expect(imperialLasers.length, equals(36));
      expect(imperialLasers.first.damage, equals(48.0));
    });

    test('Valkyrie Passives: Selene Shield Regenerator and Lyra Afterburner', () {
      final game = _createTestGame();
      game.state = GameState.playing;

      // 1. Selene Shield Regen
      final selenePlayer = PlayerComponent(position: Vector2(500, 500))..customGame = game;
      selenePlayer.valkyrie = Valkyrie.findById('selene');
      selenePlayer.initHp();
      selenePlayer.hp = 50.0;
      selenePlayer.invulnerableTimer = 0.0;

      // 3.0s elapsed: no regen yet (< 4.0s threshold)
      selenePlayer.update(3.0);
      expect(selenePlayer.hp, equals(50.0));

      // 2.0s more elapsed (total 5.0s > 4.0s): regens at 5 HP/s
      selenePlayer.update(2.0);
      expect(selenePlayer.hp, greaterThan(50.0));

      // 2. Lyra Afterburner Surge
      final lyraPlayer = PlayerComponent(position: Vector2(500, 500))..customGame = game;
      lyraPlayer.valkyrie = Valkyrie.findById('lyra');
      lyraPlayer.initHp();
      lyraPlayer.isThrusting = true;
      lyraPlayer.velocity = Vector2.zero();

      lyraPlayer.update(1.5);
      expect(lyraPlayer.lyraThrustTime, closeTo(1.5, 0.01));
    });
  });
}
