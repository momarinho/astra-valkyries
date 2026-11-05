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
import 'joystick.dart';

class PlayerComponent extends PositionComponent with HasGameReference<AsteroidsGame>, CollisionCallbacks {
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

  void resetRoguelikeStats() {
    magnetRadius = 140.0;
    pierceCount = 0;
    damageMultiplier = 1.0;
    cooldownMultiplier = 1.0;
    hasChainLightning = false;
    hasFieryDash = false;
    hasClusterBombs = false;
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
      if (!isInvulnerable()) {
        game.playSfx('player_hit.wav');
        game.triggerScreenShake(duration: 0.4, intensity: 12.0);

        final pColor = scientist?.primaryColor ?? Colors.cyan;
        final aColor = scientist?.accentColor ?? Colors.white;

        game.spawnExplosionParticles(
          position: position,
          colorChoices: [pColor, aColor, Colors.white, Colors.grey],
          count: 30,
          minSize: 2.5,
          maxSize: 5.0,
          minSpeed: 80.0,
          maxSpeed: 250.0,
        );

        game.lives -= 1;
        if (game.lives <= 0) {
          game.completeMission(survived: false);
        } else {
          respawn(game.size.x / 2, game.size.y / 2);
        }
      }
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

  void clampSpeed() {
    if (velocity.length > movementMaxSpeed) {
      velocity.normalize();
      velocity.scale(movementMaxSpeed);
    }
  }

  void applyFriction(double dt) {
    velocity.scale(math.exp(-movementFriction * dt));
  }

  void dash() {
    if (dashCooldownTimer > 0) return;

    dashActiveTimer = GameConstants.playerDashDurationSeconds;
    dashCooldownTimer = GameConstants.playerDashCooldownSeconds;
    dashDirection = forward.normalized();
    invulnerableTimer = math.max(invulnerableTimer, GameConstants.playerDashDurationSeconds);
  }

  void respawn(double x, double y) {
    position.setValues(x, y);
    angle = 0.0;
    velocity.setZero();
    invulnerableTimer = GameConstants.playerInvulnerableSeconds;
  }

  bool isInvulnerable() => invulnerableTimer > 0;

  @override
  void update(double dt) {
    super.update(dt);
    if (game.state != GameState.playing) return;

    invulnerableTimer = math.max(0.0, invulnerableTimer - dt);
    dashCooldownTimer = math.max(0.0, dashCooldownTimer - dt);
    muzzleFlashTimer = math.max(0.0, muzzleFlashTimer - dt);
    _soundCooldownTimer = math.max(0.0, _soundCooldownTimer - dt);

    // Auto-fire routine for all active weapons (Vampire Survivors style)
    for (final w in activeWeapons) {
      w.currentCooldown = math.max(0.0, w.currentCooldown - dt);
      if (w.currentCooldown <= 0) {
        if (w.fire(this)) {
          final effectiveCooldown = w.cooldown * game.rogueFireRateMultiplier;
          w.currentCooldown = effectiveCooldown;

          // Micro-recoil (subtle physical kickback without impeding steering)
          velocity -= forward * (w.recoil * 0.15);

          muzzleFlashTimer = 0.07;
          muzzleFlashSize = math.max(muzzleFlashSize, w.muzzleFlashSize);

          if (_soundCooldownTimer <= 0) {
            game.playSfx('shoot.wav');
            _soundCooldownTimer = 0.055;
          }
        }
      }
    }

    final keys = game.keysPressed;

    // Handle active dash
    if (dashActiveTimer > 0) {
      dashActiveTimer = math.max(0.0, dashActiveTimer - dt);
      velocity = dashDirection * GameConstants.playerDashSpeed;
      position += velocity * dt;
      wrapAround();

      // Spawn dash ghost trail
      game.world.add(
        DashGhost(
          position: position,
          initialAngle: angle,
          radius: radius,
        ),
      );
      return;
    }

    // Input Handling
    GameJoystick? joy;
    try {
      joy = game.joystick;
    } catch (_) {}
    final stick = joy?.stickInput ?? Vector2.zero();
    if (stick.length > 0.15 && (joy?.isDragging ?? false)) {
      // Joystick drag steering & thrust
      final targetAngle = math.atan2(stick.y, stick.x) + math.pi / 2;
      double diff = targetAngle - angle;
      while (diff < -math.pi) diff += 2 * math.pi;
      while (diff > math.pi) diff -= 2 * math.pi;

      final turnAmount = (GameConstants.playerTurnSpeed * math.pi / 180.0) * dt;
      if (diff.abs() < turnAmount) {
        angle = targetAngle;
      } else {
        angle += turnAmount * diff.sign;
      }

      accelerate(dt, stick.length);
      isThrusting = true;
    } else {
      // Standard Keyboard Input Handling (with HardwareKeyboard fallback to eliminate matrix ghosting)
      double rotateDirection = 0.0;
      final isLeft = keys.contains(LogicalKeyboardKey.arrowLeft) ||
          keys.contains(LogicalKeyboardKey.keyA) ||
          HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.arrowLeft) ||
          HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.keyA);

      final isRight = keys.contains(LogicalKeyboardKey.arrowRight) ||
          keys.contains(LogicalKeyboardKey.keyD) ||
          HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.arrowRight) ||
          HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.keyD);

      if (isLeft) {
        rotateDirection -= 1.0;
      }
      if (isRight) {
        rotateDirection += 1.0;
      }
      if (rotateDirection != 0.0) {
        rotate(dt, rotateDirection);
      }

      final isUp = keys.contains(LogicalKeyboardKey.arrowUp) ||
          keys.contains(LogicalKeyboardKey.keyW) ||
          HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.arrowUp) ||
          HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.keyW);

      if (isUp) {
        accelerate(dt, 1.0);
        isThrusting = true;
      } else {
        isThrusting = false;
      }

      final isDown = keys.contains(LogicalKeyboardKey.arrowDown) ||
          keys.contains(LogicalKeyboardKey.keyS) ||
          HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.arrowDown) ||
          HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.keyS);

      if (isDown) {
        accelerate(dt, -1.0);
      }
    }

    final isDash = keys.contains(LogicalKeyboardKey.shiftLeft) ||
        keys.contains(LogicalKeyboardKey.shiftRight) ||
        HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.shiftLeft) ||
        HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.shiftRight) ||
        game.mobileDashPressed;

    if (isDash) {
      dash();
      game.mobileDashPressed = false;
    }

    clampSpeed();
    applyFriction(dt);
    position += velocity * dt;
    wrapAround();

    // Disparo multi-tecla: Espaço, Z, X, C, Ctrl, Numpad 0 ou Enter
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
        HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.space) ||
        HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.keyZ) ||
        HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.keyX) ||
        HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.keyC) ||
        HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.controlLeft) ||
        HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.controlRight) ||
        HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.numpad0) ||
        HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.enter) ||
        HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.numpadEnter) ||
        game.mobileShootPressed;

    if (isShoot) {
      shoot();
    }

    final isSpecial = keys.contains(LogicalKeyboardKey.keyE) ||
        HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.keyE);

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

  void wrapAround() {
    final sizeX = GameConstants.screenWidth;
    final sizeY = GameConstants.screenHeight;

    if (position.x < -radius) {
      position.x = sizeX + radius;
    } else if (position.x > sizeX + radius) {
      position.x = -radius;
    }

    if (position.y < -radius) {
      position.y = sizeY + radius;
    } else if (position.y > sizeY + radius) {
      position.y = -radius;
    }
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

    // Muzzle flash rendering
    if (muzzleFlashTimer > 0) {
      Glow.orb(canvas, Offset(0, -radius), muzzleFlashSize * 0.7, Colors.yellowAccent, intensity: 1.2);
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
  final double maxLifespan = 0.15;
  double lifespan = 0.15;
  final double radius;

  DashGhost({
    required Vector2 position,
    required double initialAngle,
    required this.radius,
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
    final alpha = (lifespan / maxLifespan * 80).clamp(0.0, 255.0).toInt();
    if (alpha <= 0) return;

    canvas.translate(radius, radius);

    final paint = Paint()
      ..color = Color.fromARGB(alpha, 255, 255, 255)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final path = Path()
      ..moveTo(0, -radius)
      ..lineTo(-radius / 1.5, radius)
      ..lineTo(radius / 1.5, radius)
      ..close();

    canvas.drawPath(path, paint);
  }
}
