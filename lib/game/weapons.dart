import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:asteroids/constants.dart';
import 'components/player.dart';
import 'components/bullet.dart';
import 'components/bomb.dart';
import 'components/asteroid.dart';
import 'components/enemy_ship.dart';

abstract class Weapon {
  final String id;
  final String name;
  double cooldown;
  double recoil;
  double muzzleFlashSize;
  double damage;
  int level = 1;
  final int maxLevel = 3;
  double currentCooldown = 0.0;

  Weapon({
    required this.id,
    required this.name,
    required this.cooldown,
    required this.recoil,
    required this.muzzleFlashSize,
    required this.damage,
  });

  bool fire(PlayerComponent player);

  bool upgrade() {
    if (level >= maxLevel) {
      return false;
    }
    level++;
    applyUpgradeStats();
    return true;
  }

  void applyUpgradeStats();
}

class Blaster extends Weapon {
  Blaster()
      : super(
          id: 'blaster',
          name: "Pulse Blaster",
          cooldown: 0.70,
          recoil: 12.0,
          muzzleFlashSize: 8.0,
          damage: 60.0,
        );

  @override
  bool fire(PlayerComponent player) {
    final effectiveDamage = damage * player.damageMultiplier;
    if (level >= 3) {
      // Level 3: Dual parallel high-density plasma bolts
      final right = Vector2(-player.forward.y, player.forward.x);
      for (final offset in [-6.0, 6.0]) {
        final spawnPos = player.position + player.forward * player.radius + right * offset;
        final bullet = BulletComponent(
          position: spawnPos,
          radius: GameConstants.shotRadius,
          velocity: player.forward * (GameConstants.playerShootSpeed + 40.0),
          lifeTimer: GameConstants.shotLifetimeSeconds,
          damage: effectiveDamage,
          piercesLeft: player.pierceCount,
        );
        player.game.world.add(bullet);
      }
      return true;
    }

    final velocity = player.forward * (GameConstants.playerShootSpeed + (level == 2 ? 30.0 : 0.0));
    final bullet = BulletComponent(
      position: player.position + player.forward * player.radius,
      radius: GameConstants.shotRadius + (level == 2 ? 1.0 : 0.0),
      velocity: velocity,
      lifeTimer: GameConstants.shotLifetimeSeconds,
      damage: effectiveDamage,
      piercesLeft: player.pierceCount,
    );
    player.game.world.add(bullet);
    return true;
  }

  @override
  void applyUpgradeStats() {
    if (level == 2) {
      cooldown = 0.50;
      recoil = 8.0;
      damage = 75.0;
      muzzleFlashSize = 10.0;
    } else if (level >= 3) {
      cooldown = 0.35;
      recoil = 5.0;
      damage = 100.0;
      muzzleFlashSize = 12.0;
    }
  }
}

class SpreadShot extends Weapon {
  SpreadShot()
      : super(
          id: 'spread_shot',
          name: "Spread Cannon",
          cooldown: 0.95,
          recoil: 14.0,
          muzzleFlashSize: 11.0,
          damage: 32.0,
        );

  @override
  bool fire(PlayerComponent player) {
    final effectiveDamage = damage * player.damageMultiplier;
    // Level 3 fires a 5-way spread; Levels 1 and 2 fire 3-way
    final List<double> angles = level >= 3
        ? [-24.0, -12.0, 0.0, 12.0, 24.0]
        : [-14.0, 0.0, 14.0];

    final speedMultiplier = 1.0 + (level - 1) * 0.12;
    final baseSpeed = GameConstants.playerShootSpeed * 0.95 * speedMultiplier;
    final lifeTime = 0.75 + (level - 1) * 0.06;

    for (final angleDeg in angles) {
      final angleRad = angleDeg * math.pi / 180.0;
      final shootAngle = player.angle + angleRad;
      
      final direction = Vector2(
        math.cos(shootAngle - math.pi / 2),
        math.sin(shootAngle - math.pi / 2),
      );

      final bullet = BulletComponent(
        position: player.position + player.forward * player.radius,
        radius: 3.5 + (level >= 3 ? 0.8 : 0.0),
        velocity: direction * baseSpeed,
        lifeTimer: lifeTime,
        damage: effectiveDamage,
        piercesLeft: player.pierceCount,
      );
      player.game.world.add(bullet);
    }
    return true;
  }

  @override
  void applyUpgradeStats() {
    if (level == 2) {
      cooldown = 0.72;
      recoil = 10.0;
      damage = 42.0;
      muzzleFlashSize = 13.0;
    } else if (level >= 3) {
      cooldown = 0.52;
      recoil = 6.0;
      damage = 55.0;
      muzzleFlashSize = 15.0;
    }
  }
}

class RapidFire extends Weapon {
  RapidFire()
      : super(
          id: 'rapid_fire',
          name: "Phase Laser",
          cooldown: 0.32,
          recoil: 4.0,
          muzzleFlashSize: 6.0,
          damage: 20.0,
        );

  @override
  bool fire(PlayerComponent player) {
    final effectiveDamage = damage * player.damageMultiplier;
    final velocity = player.forward * (GameConstants.playerShootSpeed + 50.0);
    final bullet = BulletComponent(
      position: player.position + player.forward * player.radius,
      radius: 3.2 + (level >= 3 ? 0.8 : 0.0),
      velocity: velocity,
      lifeTimer: 0.88,
      damage: effectiveDamage,
      piercesLeft: player.pierceCount,
    );
    player.game.world.add(bullet);
    return true;
  }

  @override
  void applyUpgradeStats() {
    if (level == 2) {
      cooldown = 0.22;
      recoil = 2.5;
      damage = 26.0;
      muzzleFlashSize = 8.0;
    } else if (level >= 3) {
      cooldown = 0.14;
      recoil = 1.5;
      damage = 34.0;
      muzzleFlashSize = 9.0;
    }
  }
}

class BombLauncher extends Weapon {
  BombLauncher()
      : super(
          id: 'bomb_launcher',
          name: "Antimatter Torpedo",
          cooldown: 1.80,
          recoil: 22.0,
          muzzleFlashSize: 18.0,
          damage: 180.0,
        );

  @override
  bool fire(PlayerComponent player) {
    final effectiveDamage = damage * player.damageMultiplier;
    final speed = 280.0 + (level - 1) * 40.0;

    // Smart torpedo targeting: seeks the nearest enemy ship or asteroid within 550px, otherwise launches forward
    Vector2 fireDir = player.forward;
    PositionComponent? closestTarget;
    double closestDistSq = double.infinity;

    final enemies = player.game.world.children.whereType<EnemyShipComponent>();
    for (final e in enemies) {
      final dSq = player.position.distanceToSquared(e.position);
      if (dSq < closestDistSq) {
        closestDistSq = dSq;
        closestTarget = e;
      }
    }

    if (closestTarget == null || closestDistSq > 400.0 * 400.0) {
      final asteroids = player.game.world.children.whereType<AsteroidComponent>();
      for (final ast in asteroids) {
        final dSq = player.position.distanceToSquared(ast.position);
        if (dSq < closestDistSq) {
          closestDistSq = dSq;
          closestTarget = ast;
        }
      }
    }

    if (closestTarget != null && closestDistSq <= 550.0 * 550.0) {
      final toTarget = closestTarget.position - player.position;
      if (toTarget.length2 > 0.01) {
        fireDir = toTarget.normalized();
      }
    }

    final velocity = fireDir * speed;
    final explosionRadius = 95.0 + (level - 1) * 20.0;

    final bomb = BombComponent(
      position: player.position + fireDir * player.radius,
      velocity: velocity,
      damage: effectiveDamage,
      explosionRadius: explosionRadius,
    );
    player.game.world.add(bomb);
    return true;
  }

  @override
  void applyUpgradeStats() {
    if (level == 2) {
      cooldown = 1.40;
      recoil = 16.0;
      damage = 240.0;
      muzzleFlashSize = 22.0;
    } else if (level >= 3) {
      cooldown = 1.00;
      recoil = 10.0;
      damage = 320.0;
      muzzleFlashSize = 26.0;
    }
  }
}
