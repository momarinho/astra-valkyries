import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'package:asteroids/constants.dart';
import 'package:asteroids/game/asteroids_game.dart';
import 'package:asteroids/game/glow.dart';
import 'package:asteroids/game/weapons.dart';
import 'package:asteroids/game/scientist.dart';
import 'package:asteroids/game/valkyrie.dart';
import 'asteroid.dart';
import 'enemy_ship.dart';
import 'enemy_bullet.dart';
import 'sector_boss.dart';
import 'joystick.dart';
import 'cosmic_nebula.dart';

class PlayerComponent extends PositionComponent with HasGameReference<AsteroidsGame>, CollisionCallbacks {
  AsteroidsGame? customGame;

  set game(AsteroidsGame? g) {
    customGame = g;
    try {
      super.game = g;
    } catch (_) {}
  }

  @override
  AsteroidsGame get game {
    if (customGame != null) return customGame!;
    try {
      return super.game;
    } catch (_) {
      return AsteroidsGame();
    }
  }

  Vector2 velocity = Vector2.zero();
  
  double movementAcceleration = GameConstants.playerAcceleration;
  double movementMaxSpeed = GameConstants.playerMaxSpeed;
  double movementFriction = GameConstants.playerFriction;
  
  double radius = GameConstants.playerRadius;
  double invulnerableTimer = GameConstants.playerInvulnerableSeconds;
  double dashCooldownTimer = 0.0;
  double dashActiveTimer = 0.0;
  Vector2 dashDirection = Vector2.zero();
  double muzzleFlashTimer = 0.0;
  double muzzleFlashSize = 0.0;
  double _soundCooldownTimer = 0.0;

  // Balanced Dash System: charges and recharge (Vesper has 2 charges)
  int dashCharges = 1;
  int get maxDashCharges => (valkyrie?.id == 'vesper') ? 2 : 1;
  double dashRechargeTimer = 0.0;
  static const double vesperRechargeCooldown = 1.8;

  // Hull Points (HP) & Damage System
  double maxHp = 100.0;
  double hp = 100.0;
  double get hpPercent => (hp / math.max(1.0, maxHp)).clamp(0.0, 1.0);

  void initHp() {
    final baseHull = valkyrie?.baseHull ?? 100.0;
    double bonusHp = 0.0;
    try {
      bonusHp = game.metaProgression.hullBonusHp;
    } catch (_) {
      bonusHp = 0.0;
    }
    maxHp = baseHull + bonusHp;
    hp = maxHp;
    dashCharges = maxDashCharges;
    dashRechargeTimer = 0.0;
  }

  void heal(double amount) {
    if (hp <= 0) return;
    hp = (hp + amount).clamp(0.0, maxHp);
  }

  final List<Weapon> activeWeapons = [];
  final Map<String, Weapon> unlockedWeapons = {};

  Weapon get weapon => activeWeapons.isNotEmpty ? activeWeapons.first : Blaster();
  set weapon(Weapon w) {
    setWeapon(w);
  }

  double get shootTimer => activeWeapons.isNotEmpty ? activeWeapons.first.currentCooldown : 0.0;
  set shootTimer(double val) {
    if (activeWeapons.isNotEmpty) {
      activeWeapons.first.currentCooldown = val;
    }
  }

  Scientist? scientist;
  Valkyrie? valkyrie;
  bool isThrusting = false;

  // Atributos Roguelike & Sinergias de Partida
  double magnetRadius = 140.0;
  int pierceCount = 0;
  double damageMultiplier = 1.0;
  double cooldownMultiplier = 1.0;
  bool hasChainLightning = false;
  bool hasFieryDash = false;
  bool hasClusterBombs = false;

  // Sector Navigation & Boundary Status
  bool isNearBoundary = false;
  double boundaryDistance = double.infinity;

  // Interactive Environmental Zones & Modifiers
  String? activeNebulaName;
  String? activeNebulaModifier;
  double speedModifier = 1.0;
  double bonusCritChance = 0.0;
  bool isShieldSuppressed = false;

  void resetRoguelikeStats() {
    magnetRadius = 140.0;
    pierceCount = 0;
    damageMultiplier = 1.0;
    cooldownMultiplier = 1.0;
    hasChainLightning = false;
    hasFieryDash = false;
    hasClusterBombs = false;

    activeNebulaName = null;
    activeNebulaModifier = null;
    speedModifier = 1.0;
    bonusCritChance = 0.0;
    isShieldSuppressed = false;
  }

  PlayerComponent({required Vector2 position}) {
    this.position = position;
    angle = 0.0;
    anchor = Anchor.center;
    size = Vector2.all(radius * 2);
    setWeapon(Blaster());
  }

  void configureScientist(Scientist newScientist) {
    scientist = newScientist;
    setWeapon(newScientist.createWeapon());
  }

  void setWeapon(Weapon startingWeapon) {
    activeWeapons.clear();
    unlockedWeapons.clear();
    activeWeapons.add(startingWeapon);
    unlockedWeapons[startingWeapon.id] = startingWeapon;
    startingWeapon.currentCooldown = 0.0;
  }

  void addWeapon(Weapon newWeapon) {
    if (!unlockedWeapons.containsKey(newWeapon.id)) {
      unlockedWeapons[newWeapon.id] = newWeapon;
      activeWeapons.add(newWeapon);
      newWeapon.currentCooldown = 0.0;
    } else {
      unlockedWeapons[newWeapon.id]!.upgrade();
    }
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(CircleHitbox());
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (game.state != GameState.playing) return;
    if (other is AsteroidComponent) {
      final double dmg;
      if (other.radius >= 40.0) {
        dmg = 35.0; // Large asteroid collision
      } else if (other.radius >= 25.0) {
        dmg = 24.0; // Medium asteroid collision
      } else {
        dmg = 14.0; // Small asteroid collision
      }
      takeHit(dmg);
    } else if (other is EnemyShipComponent) {
      final double dmg;
      switch (other.type) {
        case EnemyType.scout:
          dmg = 16.0;
          break;
        case EnemyType.raider:
          dmg = 32.0;
          break;
        case EnemyType.sniper:
          dmg = 22.0;
          break;
        case EnemyType.eliteCommander:
          dmg = 45.0;
          break;
      }
      takeHit(dmg);
    } else if (other is SectorBoss) {
      takeHit(45.0);
    }
  }

  void takeHit([double damage = 20.0]) {
    if (isInvulnerable() || game.state != GameState.playing) return;
    game.playSfx('player_hit.wav');

    final actualDamage = damage.clamp(5.0, 999.0);
    hp = math.max(0.0, hp - actualDamage);

    game.triggerScreenShake(duration: 0.35, intensity: math.min(18.0, 8.0 + actualDamage * 0.25));
    game.spawnFloatingText(
      position + Vector2(0, -28),
      '-${actualDamage.toInt()} HP',
      color: const Color(0xFFFF1744),
      fontSize: 16.0,
      velocity: Vector2(0, -35),
    );

    final pColor = scientist?.primaryColor ?? valkyrie?.primaryColor ?? Colors.cyan;
    final aColor = scientist?.accentColor ?? valkyrie?.accentColor ?? Colors.white;

    game.spawnExplosionParticles(
      position: position,
      colorChoices: [pColor, aColor, Colors.white, Colors.redAccent],
      count: 24,
      minSize: 2.5,
      maxSize: 5.0,
      minSpeed: 80.0,
      maxSpeed: 220.0,
    );

    // Brief invulnerability window (i-frames)
    invulnerableTimer = 0.85;

    if (hp <= 0) {
      hp = 0.0;
      game.completeMission(survived: false);
    }
  }

  Vector2 get forward => Vector2(
        math.cos(angle - math.pi / 2),
        math.sin(angle - math.pi / 2),
      );

  void rotate(double dt, double direction) {
    angle += (GameConstants.playerTurnSpeed * math.pi / 180.0) * direction * dt;
  }

  void accelerate(double dt, double directionMultiplier) {
    velocity += forward * movementAcceleration * directionMultiplier * dt;
  }

  void accelerateInDirection(double dt, Vector2 direction, double power) {
    if (direction.length <= 0.001) return;
    velocity += direction.normalized() * movementAcceleration * power * dt;
  }

  void clampSpeed() {
    final effectiveMaxSpeed = movementMaxSpeed * speedModifier;
    if (velocity.length > effectiveMaxSpeed) {
      velocity.normalize();
      velocity.scale(effectiveMaxSpeed);
    }
  }

  void applyFriction(double dt) {
    velocity.scale(math.exp(-movementFriction * dt));
  }

  void dash() {
    final vId = valkyrie?.id ?? 'lyra';

    if (vId == 'vesper') {
      // 🗡️ VESPER: PHANTOM QUICK-SLIP (Dual-charge agile micro-evade)
      if (dashCharges <= 0) return;
      dashCharges--;
      if (dashRechargeTimer <= 0) {
        dashRechargeTimer = vesperRechargeCooldown;
      }
      dashActiveTimer = 0.18;
      dashDirection = forward.normalized();
      invulnerableTimer = 0.25;
      game.playSfx('dash.wav');
      game.world.add(
        DashGhost(
          position: position,
          initialAngle: angle,
          radius: radius,
          ghostColor: const Color(0xFFE040FB),
        ),
      );
      return;
    }

    if (dashCooldownTimer > 0) return;

    if (vId == 'selene') {
      // 🔮 SELENE: QUANTUM PHASE BLINK
      // Instant spatial blink of 210px forward; phases clean through obstacles
      dashCooldownTimer = 2.5;
      invulnerableTimer = 0.35;
      dashDirection = forward.normalized();

      game.world.add(
        DashGhost(
          position: position,
          initialAngle: angle,
          radius: radius,
          ghostColor: const Color(0xFF00E5FF),
        ),
      );

      position += dashDirection * 210.0;
      enforceSectorBounds(0.01);

      game.spawnExplosionParticles(
        position: position,
        colorChoices: [const Color(0xFF00E5FF), Colors.white],
        count: 8,
        minSize: 1.5,
        maxSize: 3.0,
        minSpeed: 30.0,
        maxSpeed: 80.0,
      );
      game.playSfx('dash.wav');
      return;
    }

    if (vId == 'astraea') {
      // 🌟 ASTRAEA: GENESIS PHASE GLIDE
      dashCooldownTimer = 2.2;
      invulnerableTimer = 0.40;
      dashDirection = forward.normalized();

      game.world.add(
        DashGhost(
          position: position,
          initialAngle: angle,
          radius: radius,
          ghostColor: const Color(0xFFFFD700),
        ),
      );

      position += dashDirection * 220.0;
      enforceSectorBounds(0.01);
      game.playSfx('dash.wav');
      return;
    }

    // 🔥 LYRA (Default): AFTERBURNER SURGE
    // Linear high-velocity burst (0.28s), no floor hazards
    dashActiveTimer = 0.28;
    dashCooldownTimer = 1.8;
    dashDirection = forward.normalized();
    invulnerableTimer = 0.32;
    game.playSfx('dash.wav');

    game.world.add(
      DashGhost(
        position: position,
        initialAngle: angle,
        radius: radius,
        ghostColor: const Color(0xFFFF9100),
      ),
    );
  }

  void respawn(double x, double y) {
    position.setValues(x, y);
    angle = 0.0;
    velocity.setZero();
    invulnerableTimer = GameConstants.playerInvulnerableSeconds;
    initHp();
  }

  bool isInvulnerable() => !isShieldSuppressed && invulnerableTimer > 0;

  @override
  void update(double dt) {
    super.update(dt);
    if (game.state != GameState.playing) return;

    _updateNebulaModifiers();

    invulnerableTimer = math.max(0.0, invulnerableTimer - dt);
    if (valkyrie?.id == 'vesper') {
      if (dashCharges < maxDashCharges) {
        dashRechargeTimer = math.max(0.0, dashRechargeTimer - dt);
        if (dashRechargeTimer <= 0) {
          dashCharges++;
          if (dashCharges < maxDashCharges) {
            dashRechargeTimer = vesperRechargeCooldown;
          }
        }
      }
      dashCooldownTimer = (dashCharges > 0) ? 0.0 : dashRechargeTimer;
    } else {
      dashCooldownTimer = math.max(0.0, dashCooldownTimer - dt);
    }
    muzzleFlashTimer = math.max(0.0, muzzleFlashTimer - dt);
    _soundCooldownTimer = math.max(0.0, _soundCooldownTimer - dt);

    // Auto-fire routine for all active weapons (Vampire Survivors style)
    for (final w in activeWeapons) {
      w.currentCooldown = math.max(0.0, w.currentCooldown - dt);
      if (w.currentCooldown <= 0) {
        if (w.fire(this)) {
          final cooldownMultiplier = (activeNebulaName == 'ION NEBULA') ? 0.70 : 1.0;
          final effectiveCooldown = w.cooldown * game.rogueFireRateMultiplier * cooldownMultiplier;
          w.currentCooldown = effectiveCooldown;

          // Micro-recoil (subtle physical kickback without impeding steering)
          velocity -= forward * (w.recoil * 0.15);

          muzzleFlashTimer = 0.05;
          muzzleFlashSize = math.max(muzzleFlashSize, w.muzzleFlashSize);

          if (_soundCooldownTimer <= 0) {
            game.playSfx('shoot.wav');
            _soundCooldownTimer = 0.11;
          }
        }
      }
    }

    final keys = game.keysPressed;

    // Handle active dash
    if (dashActiveTimer > 0) {
      dashActiveTimer = math.max(0.0, dashActiveTimer - dt);
      final speed = (valkyrie?.id == 'lyra')
          ? 520.0
          : (valkyrie?.id == 'vesper' ? 440.0 : GameConstants.playerDashSpeed);
      velocity = dashDirection * speed;
      position += velocity * dt;
      enforceSectorBounds(dt);

      final ghostColor = (valkyrie?.id == 'vesper') ? const Color(0xFFE040FB) : const Color(0xFFFF9100);
      game.world.add(
        DashGhost(
          position: position,
          initialAngle: angle,
          radius: radius,
          ghostColor: ghostColor,
        ),
      );
      return;
    }

    // Input Handling (Virtual Joystick + 360° Directional WASD/Arrows or Classic Tank Rotation)
    GameJoystick? joy;
    try {
      joy = game.joystick;
    } catch (_) {}
    final stick = joy?.stickInput ?? Vector2.zero();

    final isLeft = keys.contains(LogicalKeyboardKey.arrowLeft) ||
        keys.contains(LogicalKeyboardKey.keyA) ||
        HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.arrowLeft) ||
        HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.keyA);

    final isRight = keys.contains(LogicalKeyboardKey.arrowRight) ||
        keys.contains(LogicalKeyboardKey.keyD) ||
        HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.arrowRight) ||
        HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.keyD);

    final isUp = keys.contains(LogicalKeyboardKey.arrowUp) ||
        keys.contains(LogicalKeyboardKey.keyW) ||
        HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.arrowUp) ||
        HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.keyW);

    final isDown = keys.contains(LogicalKeyboardKey.arrowDown) ||
        keys.contains(LogicalKeyboardKey.keyS) ||
        HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.arrowDown) ||
        HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.keyS);

    final kbDir = Vector2.zero();
    if (isLeft) kbDir.x -= 1.0;
    if (isRight) kbDir.x += 1.0;
    if (isUp) kbDir.y -= 1.0;
    if (isDown) kbDir.y += 1.0;
    if (kbDir.length > 1.0) kbDir.normalize();

    final isStrafeLock = game.isAimLocked || game.mobileShootPressed;

    if (stick.length > 0.12 && (joy?.isDragging ?? false)) {
      // Mobile / Virtual Joystick Hybrid:
      // 1) Always move/thrust in 360° direction of the joystick thumb
      accelerateInDirection(dt, stick, stick.length.clamp(0.0, 1.0));
      isThrusting = true;

      // 2) If AIM LOCK (FIRE/LOCK button) is NOT active, smoothly align nose with flight direction.
      //    If AIM LOCK IS active, keep nose locked on target so the player can fly backward/strafe while shooting!
      if (!isStrafeLock) {
        final targetAngle = math.atan2(stick.y, stick.x) + math.pi / 2;
        double diff = targetAngle - angle;
        while (diff < -math.pi) diff += 2 * math.pi;
        while (diff > math.pi) diff -= 2 * math.pi;

        final turnAmount = (GameConstants.playerTurnSpeed * 2.1 * math.pi / 180.0) * dt;
        if (diff.abs() < turnAmount) {
          angle = targetAngle;
        } else {
          angle += turnAmount * diff.sign;
        }
      }
    } else if (game.useDirectionalControls) {
      // Optional 360° Directional Mode on Keyboard (with Strafe Lock support)
      if (kbDir.length > 0.05) {
        accelerateInDirection(dt, kbDir, 1.0);
        isThrusting = true;

        if (!isStrafeLock) {
          final targetAngle = math.atan2(kbDir.y, kbDir.x) + math.pi / 2;
          double diff = targetAngle - angle;
          while (diff < -math.pi) diff += 2 * math.pi;
          while (diff > math.pi) diff -= 2 * math.pi;

          final turnAmount = (GameConstants.playerTurnSpeed * 2.1 * math.pi / 180.0) * dt;
          if (diff.abs() < turnAmount) {
            angle = targetAngle;
          } else {
            angle += turnAmount * diff.sign;
          }
        }
      } else {
        isThrusting = false;
      }
    } else {
      // Formula 1 on Keyboard (Default — Nova Drift / Tactical Reverse Kiting):
      // A/D = Rotate nose smoothly, W = Thrust forward, S = Tactical Reverse (Kiting while shooting forward!)
      double rotateDirection = 0.0;
      if (isLeft) rotateDirection -= 1.0;
      if (isRight) rotateDirection += 1.0;
      if (rotateDirection != 0.0) {
        rotate(dt, rotateDirection * 1.15);
      }

      if (isUp) {
        accelerate(dt, 1.0);
        isThrusting = true;
      } else {
        isThrusting = false;
      }

      if (isDown) {
        accelerate(dt, -0.92);
      }
    }

    final isDash = keys.contains(LogicalKeyboardKey.shiftLeft) ||
        keys.contains(LogicalKeyboardKey.shiftRight) ||
        keys.contains(LogicalKeyboardKey.gameButtonB) ||
        keys.contains(LogicalKeyboardKey.gameButtonLeft1) ||
        HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.shiftLeft) ||
        HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.shiftRight) ||
        HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.gameButtonB) ||
        HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.gameButtonLeft1) ||
        game.mobileDashPressed;

    if (isDash) {
      dash();
      game.mobileDashPressed = false;
    }

    clampSpeed();
    applyFriction(dt);
    position += velocity * dt;
    enforceSectorBounds(dt);

    // Disparo multi-tecla: Espaço, Z, X, C, Ctrl, Numpad 0, Enter ou Gamepad A/R1
    // Isso resolve completamente qualquer conflito de ghosting em teclados escolares
    final isShoot = keys.contains(LogicalKeyboardKey.space) ||
        keys.contains(LogicalKeyboardKey.keyZ) ||
        keys.contains(LogicalKeyboardKey.keyX) ||
        keys.contains(LogicalKeyboardKey.keyC) ||
        keys.contains(LogicalKeyboardKey.controlLeft) ||
        keys.contains(LogicalKeyboardKey.controlRight) ||
        keys.contains(LogicalKeyboardKey.numpad0) ||
        keys.contains(LogicalKeyboardKey.enter) ||
        keys.contains(LogicalKeyboardKey.numpadEnter) ||
        keys.contains(LogicalKeyboardKey.gameButtonA) ||
        keys.contains(LogicalKeyboardKey.gameButtonRight1) ||
        HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.space) ||
        HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.keyZ) ||
        HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.keyX) ||
        HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.keyC) ||
        HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.controlLeft) ||
        HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.controlRight) ||
        HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.numpad0) ||
        HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.enter) ||
        HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.numpadEnter) ||
        HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.gameButtonA) ||
        HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.gameButtonRight1) ||
        game.mobileShootPressed;

    if (isShoot) {
      shoot();
    }

    final isSpecial = keys.contains(LogicalKeyboardKey.keyE) ||
        keys.contains(LogicalKeyboardKey.gameButtonX) ||
        keys.contains(LogicalKeyboardKey.gameButtonY) ||
        HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.keyE) ||
        HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.gameButtonX) ||
        HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.gameButtonY);

    if (isSpecial) {
      game.triggerSpecial();
    }

  }

  void shoot() {
    // Manual shoot input (Spacebar / Click) triggers any ready or nearly ready weapons
    for (final w in activeWeapons) {
      if (w.currentCooldown <= 0.06) {
        w.currentCooldown = 0.0;
      }
    }
  }

  void enforceSectorBounds(double dt) {
    const maxX = GameConstants.sectorWidth;
    const maxY = GameConstants.sectorHeight;
    const warnDist = GameConstants.sectorWarningDistance;

    // Minimum distance to the 4 outer boundary edges
    final distLeft = position.x;
    final distRight = maxX - position.x;
    final distTop = position.y;
    final distBottom = maxY - position.y;

    boundaryDistance = math.min(math.min(distLeft, distRight), math.min(distTop, distBottom));
    isNearBoundary = boundaryDistance < warnDist;

    // Repulsive acceleration towards center when venturing into hazard perimeter
    if (isNearBoundary) {
      final centerX = maxX / 2;
      final centerY = maxY / 2;
      final toCenter = Vector2(centerX - position.x, centerY - position.y).normalized();
      final pushFactor = (1.0 - (boundaryDistance / warnDist).clamp(0.0, 1.0));
      velocity += toCenter * (pushFactor * 320.0 * dt);
    }

    // Hard boundary collision with elastic deflection
    if (position.x < radius) {
      position.x = radius;
      if (velocity.x < 0) velocity.x = -velocity.x * 0.45;
    } else if (position.x > maxX - radius) {
      position.x = maxX - radius;
      if (velocity.x > 0) velocity.x = -velocity.x * 0.45;
    }

    if (position.y < radius) {
      position.y = radius;
      if (velocity.y < 0) velocity.y = -velocity.y * 0.45;
    } else if (position.y > maxY - radius) {
      position.y = maxY - radius;
      if (velocity.y > 0) velocity.y = -velocity.y * 0.45;
    }
  }

  void wrapAround() => enforceSectorBounds(0.016);

  void _updateNebulaModifiers() {
    activeNebulaName = null;
    activeNebulaModifier = null;
    speedModifier = 1.0;
    bonusCritChance = 0.0;
    isShieldSuppressed = false;

    try {
      for (final nebula in game.world.children.whereType<CosmicNebulaComponent>()) {
        if (nebula.containsPoint(position)) {
          activeNebulaName = nebula.name;
          activeNebulaModifier = nebula.modifierText;
          if (nebula.type == NebulaType.ionCloud) {
            isShieldSuppressed = true;
          } else if (nebula.type == NebulaType.darkMatter) {
            speedModifier = 0.70;
            bonusCritChance = 0.50;
          }
          break;
        }
      }
    } catch (_) {}
  }

  @override
  void render(Canvas canvas) {
    // Blinking effect when invulnerable
    if (isInvulnerable()) {
      final milliseconds = DateTime.now().millisecondsSinceEpoch;
      if (milliseconds % 200 < 100) {
        return; // Skip rendering
      }
    }

    canvas.translate(radius, radius);

    _renderShip(canvas);

    // Muzzle flash rendering: crisp, forward-directed spark that never covers the ship
    if (muzzleFlashTimer > 0) {
      final flashRatio = (muzzleFlashTimer / 0.05).clamp(0.0, 1.0);
      final flashLen = math.min(9.0, muzzleFlashSize * 0.35);
      final flashWidth = math.min(4.5, muzzleFlashSize * 0.18);

      final tip = Offset(0, -radius * 1.18);

      // Sharp directional diamond spark
      final diamond = Path()
        ..moveTo(tip.dx, tip.dy - flashLen)
        ..lineTo(tip.dx - flashWidth, tip.dy)
        ..lineTo(tip.dx, tip.dy + flashLen * 0.4)
        ..lineTo(tip.dx + flashWidth, tip.dy)
        ..close();

      final flashPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.95 * flashRatio)
        ..blendMode = BlendMode.plus
        ..style = PaintingStyle.fill;
      canvas.drawPath(diamond, flashPaint);

      final coronaPaint = Paint()
        ..color = const Color(0xFFFFEB3B).withValues(alpha: 0.40 * flashRatio)
        ..blendMode = BlendMode.plus
        ..style = PaintingStyle.fill;
      canvas.drawCircle(tip, flashLen * 0.6, coronaPaint);
    }
  }

  void _renderShip(Canvas canvas) {
    final primary = valkyrie?.primaryColor ?? scientist?.primaryColor ?? Colors.white;
    final accent = valkyrie?.accentColor ?? scientist?.accentColor ?? Colors.cyanAccent;

    final accentPaint = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final fillPaint = Paint()
      ..color = primary.withOpacity(0.12)
      ..style = PaintingStyle.fill;

    // Thruster flames if accelerating forward
    if (isThrusting) {
      final flameFlicker = (DateTime.now().millisecondsSinceEpoch % 150) / 150.0;
      final flameLength = radius * (0.6 + flameFlicker * 0.5);

      final flamePath = Path()
        ..moveTo(-radius * 0.25, radius * 0.7)
        ..lineTo(0, radius * 0.7 + flameLength)
        ..lineTo(radius * 0.25, radius * 0.7);
      Glow.strokePath(canvas, flamePath, accent, width: 2.0, intensity: 1.4);

      // Núcleo quente da chama, quase branco
      final corePath = Path()
        ..moveTo(-radius * 0.12, radius * 0.72)
        ..lineTo(0, radius * 0.72 + flameLength * 0.55)
        ..lineTo(radius * 0.12, radius * 0.72);
      Glow.strokePath(canvas, corePath, Glow.mix(accent, Colors.white, 0.8), width: 1.5, intensity: 0.8);
    }

    if (valkyrie != null) {
      switch (valkyrie!.shipDesign) {
        case ValkyrieShipDesign.solBlaze:
          // Lyra: High-speed swept interceptor with aggressive forward canards
          final path = Path()
            ..moveTo(0, -radius * 1.15) // Needle tip
            ..lineTo(-radius * 0.85, radius * 0.75) // Wingtip L
            ..lineTo(-radius * 0.45, radius * 0.4) // Notch L
            ..lineTo(-radius * 0.25, radius * 0.85) // Engine L
            ..lineTo(0, radius * 0.5) // Aft center
            ..lineTo(radius * 0.25, radius * 0.85) // Engine R
            ..lineTo(radius * 0.45, radius * 0.4) // Notch R
            ..lineTo(radius * 0.85, radius * 0.75) // Wingtip R
            ..close();
          canvas.drawPath(path, fillPaint);
          Glow.heroStrokePath(canvas, path, primary, width: GameConstants.lineWidth);

          // Cockpit canopy
          final canopy = Path()
            ..moveTo(0, -radius * 0.6)
            ..lineTo(-radius * 0.18, -radius * 0.05)
            ..lineTo(0, radius * 0.2)
            ..lineTo(radius * 0.18, -radius * 0.05)
            ..close();
          canvas.drawPath(canopy, accentPaint);
          return;

        case ValkyrieShipDesign.aegisPrism:
          // Selene: Angular crystalline prism with geometric shield stabilizers
          final path = Path()
            ..moveTo(0, -radius * 1.05)
            ..lineTo(-radius * 0.7, radius * 0.2)
            ..lineTo(-radius * 0.9, radius * 0.85)
            ..lineTo(-radius * 0.35, radius * 0.65)
            ..lineTo(0, radius * 0.8)
            ..lineTo(radius * 0.35, radius * 0.65)
            ..lineTo(radius * 0.9, radius * 0.85)
            ..lineTo(radius * 0.7, radius * 0.2)
            ..close();
          canvas.drawPath(path, fillPaint);
          Glow.heroStrokePath(canvas, path, primary, width: GameConstants.lineWidth);

          // Crystalline core
          final core = Path()
            ..moveTo(0, -radius * 0.45)
            ..lineTo(-radius * 0.25, 0)
            ..lineTo(0, radius * 0.35)
            ..lineTo(radius * 0.25, 0)
            ..close();
          canvas.drawPath(core, accentPaint);
          return;

        case ValkyrieShipDesign.eclipseFang:
          // Vesper: Forward-swept wing heavy stealth fighter with aggressive fangs
          final path = Path()
            ..moveTo(0, -radius * 0.65)
            ..lineTo(-radius * 0.45, -radius * 0.95) // Forward Fang L
            ..lineTo(-radius * 0.85, radius * 0.35) // Outer wing
            ..lineTo(-radius * 0.55, radius * 0.85) // Aft fin
            ..lineTo(0, radius * 0.45) // Central engine bay
            ..lineTo(radius * 0.55, radius * 0.85)
            ..lineTo(radius * 0.85, radius * 0.35)
            ..lineTo(radius * 0.45, -radius * 0.95) // Forward Fang R
            ..close();
          canvas.drawPath(path, fillPaint);
          Glow.heroStrokePath(canvas, path, primary, width: GameConstants.lineWidth);

          // Dark matter reactor ring
          canvas.drawCircle(Offset(0, radius * 0.05), radius * 0.22, accentPaint);
          return;

        case ValkyrieShipDesign.originPrime:
          // Astraea: Mythical precursor starframe with sweeping golden wings
          final path = Path()
            ..moveTo(0, -radius * 1.25) // Apex
            ..lineTo(-radius * 0.5, -radius * 0.2)
            ..lineTo(-radius * 1.1, radius * 0.6) // Swept wing L
            ..lineTo(-radius * 0.4, radius * 0.5)
            ..lineTo(-radius * 0.2, radius * 0.95) // Engine L
            ..lineTo(0, radius * 0.65)
            ..lineTo(radius * 0.2, radius * 0.95) // Engine R
            ..lineTo(radius * 0.4, radius * 0.5)
            ..lineTo(radius * 1.1, radius * 0.6) // Swept wing R
            ..lineTo(radius * 0.5, -radius * 0.2)
            ..close();
          canvas.drawPath(path, fillPaint);
          Glow.heroStrokePath(canvas, path, const Color(0xFFFFD700), width: GameConstants.lineWidth + 0.5);

          // Celestial Diamond Core
          final core = Path()
            ..moveTo(0, -radius * 0.5)
            ..lineTo(-radius * 0.22, 0)
            ..lineTo(0, radius * 0.3)
            ..lineTo(radius * 0.22, 0)
            ..close();
          canvas.drawPath(core, Paint()..color = Colors.white..style = PaintingStyle.fill);
          return;
      }
    }

    final design = scientist?.shipDesign ?? ShipDesign.deltaJet;
    switch (design) {
      case ShipDesign.deltaJet:
        // Mae Jemison: Endeavour Bio-Jet (Aerodynamic delta wings)
        final path = Path()
          ..moveTo(0, -radius) // Nose tip
          ..lineTo(-radius * 0.85, radius * 0.85) // Left wing tip
          ..lineTo(-radius * 0.35, radius * 0.5) // Left wing inner notch
          ..lineTo(-radius * 0.2, radius * 0.75) // Left engine
          ..lineTo(0, radius * 0.55) // Center aft
          ..lineTo(radius * 0.2, radius * 0.75) // Right engine
          ..lineTo(radius * 0.35, radius * 0.5) // Right wing inner notch
          ..lineTo(radius * 0.85, radius * 0.85) // Right wing tip
          ..close();

        canvas.drawPath(path, fillPaint);
        Glow.heroStrokePath(canvas, path, primary, width: GameConstants.lineWidth);

        // Cockpit canopy
        final cockpit = Path()
          ..moveTo(0, -radius * 0.55)
          ..lineTo(-radius * 0.18, 0)
          ..lineTo(0, radius * 0.2)
          ..lineTo(radius * 0.18, 0)
          ..close();
        canvas.drawPath(cockpit, accentPaint);
        break;

      case ShipDesign.codeApollo:
        // Margaret Hamilton: Apollo Code-1 (Precision angular wedge with antenna probe)
        final path = Path()
          ..moveTo(0, -radius * 1.1) // Nose probe
          ..lineTo(-radius * 0.65, radius * 0.85) // Left aft
          ..lineTo(-radius * 0.25, radius * 0.6) // Inset
          ..lineTo(0, radius * 0.75) // Center
          ..lineTo(radius * 0.25, radius * 0.6) // Inset
          ..lineTo(radius * 0.65, radius * 0.85) // Right aft
          ..close();

        canvas.drawPath(path, fillPaint);
        Glow.heroStrokePath(canvas, path, primary, width: GameConstants.lineWidth);

        // Outer data wings / stabilizer struts
        final wingLines = Path()
          ..moveTo(-radius * 0.35, -radius * 0.1)
          ..lineTo(-radius * 0.85, radius * 0.35)
          ..lineTo(-radius * 0.7, radius * 0.7)
          ..moveTo(radius * 0.35, -radius * 0.1)
          ..lineTo(radius * 0.85, radius * 0.35)
          ..lineTo(radius * 0.7, radius * 0.7);
        canvas.drawPath(wingLines, accentPaint);

        // Core data module
        canvas.drawRect(
          Rect.fromCenter(center: Offset(0, -radius * 0.05), width: radius * 0.35, height: radius * 0.35),
          accentPaint,
        );
        break;

      case ShipDesign.hubbleScout:
        // Nancy Grace Roman: Hubble Scout (Telescope barrel + solar panel wings)
        final barrel = RRect.fromRectAndRadius(
          Rect.fromCenter(center: const Offset(0, 0), width: radius * 0.7, height: radius * 1.8),
          const Radius.circular(3),
        );
        canvas.drawRRect(barrel, fillPaint);
        Glow.heroStrokePath(canvas, Path()..addRRect(barrel), primary, width: GameConstants.lineWidth);

        // Optical aperture at top
        canvas.drawCircle(Offset(0, -radius * 0.8), radius * 0.26, accentPaint);

        // Left solar panel
        final leftPanel = Rect.fromLTRB(-radius * 1.25, -radius * 0.35, -radius * 0.35, radius * 0.35);
        canvas.drawRect(leftPanel, accentPaint);
        canvas.drawLine(Offset(-radius * 0.8, -radius * 0.35), Offset(-radius * 0.8, radius * 0.35), accentPaint);
        canvas.drawLine(Offset(-radius * 1.25, 0), Offset(-radius * 0.35, 0), accentPaint);

        // Right solar panel
        final rightPanel = Rect.fromLTRB(radius * 0.35, -radius * 0.35, radius * 1.25, radius * 0.35);
        canvas.drawRect(rightPanel, accentPaint);
        canvas.drawLine(Offset(radius * 0.8, -radius * 0.35), Offset(radius * 0.8, radius * 0.35), accentPaint);
        canvas.drawLine(Offset(radius * 0.35, 0), Offset(radius * 1.25, 0), accentPaint);
        break;

      case ShipDesign.orbitalTitan:
        // Peggy Whitson: Orbital Station-X (Modular station hull with heavy thrusters)
        final path = Path()
          ..moveTo(0, -radius) // Heavy front ram
          ..lineTo(-radius * 0.45, -radius * 0.5)
          ..lineTo(-radius * 0.85, radius * 0.15) // Heavy shoulder
          ..lineTo(-radius * 0.65, radius * 0.85) // Left booster pod
          ..lineTo(-radius * 0.2, radius * 0.6)
          ..lineTo(radius * 0.2, radius * 0.6)
          ..lineTo(radius * 0.65, radius * 0.85) // Right booster pod
          ..lineTo(radius * 0.85, radius * 0.15) // Heavy shoulder
          ..lineTo(radius * 0.45, -radius * 0.5)
          ..close();

        canvas.drawPath(path, fillPaint);
        Glow.heroStrokePath(canvas, path, primary, width: GameConstants.lineWidth);

        // Central science module
        canvas.drawCircle(Offset(0, radius * 0.05), radius * 0.28, accentPaint);
        break;
    }
  }
}

class DashGhost extends PositionComponent {
  final double maxLifespan = 0.20;
  double lifespan = 0.20;
  final double radius;
  final Color ghostColor;

  DashGhost({
    required Vector2 position,
    required double initialAngle,
    required this.radius,
    this.ghostColor = Colors.white,
  }) {
    this.position = position.clone();
    angle = initialAngle;
    anchor = Anchor.center;
    size = Vector2.all(radius * 2);
  }

  @override
  void update(double dt) {
    super.update(dt);
    lifespan -= dt;
    if (lifespan <= 0) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final alpha = (lifespan / maxLifespan * 110).clamp(0.0, 255.0).toInt();
    if (alpha <= 0) return;

    canvas.translate(radius, radius);

    final paint = Paint()
      ..color = ghostColor.withAlpha(alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    final path = Path()
      ..moveTo(0, -radius)
      ..lineTo(-radius / 1.5, radius)
      ..lineTo(radius / 1.5, radius)
      ..close();

    canvas.drawPath(path, paint);
  }
}
