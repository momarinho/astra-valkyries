import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:asteroids/constants.dart';
import 'package:asteroids/game/asteroids_game.dart';
import 'package:asteroids/game/components/player.dart';
import 'package:asteroids/game/components/bullet.dart';
import 'package:asteroids/game/components/enemy_bullet.dart';
import 'package:asteroids/game/components/asteroid.dart';
import 'package:asteroids/game/components/enemy_ship.dart';
import 'package:asteroids/game/components/chest.dart';
import 'package:asteroids/game/components/xp_orb.dart';
import 'package:asteroids/game/components/dead_cells_biome.dart';
import 'package:asteroids/services/localization_service.dart';

/// 1. Piso Industrial Modular (Sprint 30 & 55 — Sub-piso metálico aeroespacial puramente vetorial)
class ModularFloorComponent extends PositionComponent
    with HasGameReference<AsteroidsGame> {
  final Color floorAccent;
  double _animTimer = 0.0;

  ModularFloorComponent({
    required Vector2 position,
    required Vector2 size,
    this.floorAccent = const Color(0xFF00E5FF),
  }) : super(
          position: position.clone(),
          size: size.clone(),
          anchor: Anchor.center,
          priority: -38, // Acima do starfield (-40) e do backdrop (-45)
        );

  @override
  void update(double dt) {
    super.update(dt);
    _animTimer += dt;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);

    // 1. Base fosca da chapa de liga de aço espacial
    final basePaint = Paint()..color = const Color(0xFF060913);
    canvas.drawRect(rect, basePaint);

    // 2. Grade geométrica de placas modulares com micro-costuras a laser
    const plateSize = 48.0;
    final seamPaint = Paint()
      ..color = const Color(0xFF131B2A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (double x = plateSize; x < size.x; x += plateSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.y), seamPaint);
    }
    for (double y = plateSize; y < size.y; y += plateSize) {
      canvas.drawLine(Offset(0, y), Offset(size.x, y), seamPaint);
    }

    // 3. Faixas de orientação de pouso e atracação (Runway Deck Guidelines)
    final runwayPaint = Paint()
      ..color = floorAccent.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    // Linhas internas de corredor de atracação
    if (size.x > 120.0 && size.y > 120.0) {
      final innerMargin = 28.0;
      final innerRect = Rect.fromLTWH(
        innerMargin,
        innerMargin,
        size.x - innerMargin * 2,
        size.y - innerMargin * 2,
      );
      canvas.drawRect(innerRect, runwayPaint);

      // Chevrons de direção no eixo central
      final chevronPaint = Paint()
        ..color = floorAccent.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      final midY = size.y / 2;
      for (double cx = innerMargin + 30.0; cx < size.x - innerMargin - 30.0; cx += 60.0) {
        final path = Path()
          ..moveTo(cx - 8, midY - 10)
          ..lineTo(cx + 4, midY)
          ..lineTo(cx - 8, midY + 10);
        canvas.drawPath(path, chevronPaint);
      }
    }

    // 4. Cantoneiras angulares em L nos 4 vértices
    final bracketPaint = Paint()
      ..color = floorAccent.withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4;
    const bLen = 18.0;
    // Top-Left
    canvas.drawLine(const Offset(4, 4), const Offset(4 + bLen, 4), bracketPaint);
    canvas.drawLine(const Offset(4, 4), const Offset(4, 4 + bLen), bracketPaint);
    // Top-Right
    canvas.drawLine(Offset(size.x - 4, 4), Offset(size.x - 4 - bLen, 4), bracketPaint);
    canvas.drawLine(Offset(size.x - 4, 4), Offset(size.x - 4, 4 + bLen), bracketPaint);
    // Bottom-Left
    canvas.drawLine(Offset(4, size.y - 4), Offset(4 + bLen, size.y - 4), bracketPaint);
    canvas.drawLine(Offset(4, size.y - 4), Offset(4, size.y - 4 - bLen), bracketPaint);
    // Bottom-Right
    canvas.drawLine(Offset(size.x - 4, size.y - 4), Offset(size.x - 4 - bLen, size.y - 4), bracketPaint);
    canvas.drawLine(Offset(size.x - 4, size.y - 4), Offset(size.x - 4, size.y - 4 - bLen), bracketPaint);

    // 5. Sinalizadores LED pulsantes nos cantos
    final pulse = 0.5 + 0.5 * math.sin(_animTimer * 3.5);
    final ledPaint = Paint()
      ..color = floorAccent.withValues(alpha: 0.4 + 0.6 * pulse)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(8, 8), 2.5, ledPaint);
    canvas.drawCircle(Offset(size.x - 8, 8), 2.5, ledPaint);
    canvas.drawCircle(Offset(8, size.y - 8), 2.5, ledPaint);
    canvas.drawCircle(Offset(size.x - 8, size.y - 8), 2.5, ledPaint);
  }
}

/// 2. Porta de Anteparo Blindada Automática (Sprint 30 — Blast Door com trava hidráulica)
class BlastDoorComponent extends PositionComponent
    with HasGameReference<AsteroidsGame>, CollisionCallbacks {
  final double length;
  final bool isHorizontal;
  bool isOpen;
  double transitionProgress; // 0.0 = Fechada, 1.0 = Totalmente Aberta
  RectangleHitbox? _hitbox;

  BlastDoorComponent({
    required Vector2 position,
    this.length = 160.0,
    this.isHorizontal = true,
    this.isOpen = false,
  })  : transitionProgress = isOpen ? 1.0 : 0.0,
        super(
          position: position.clone(),
          size: isHorizontal ? Vector2(length, 26.0) : Vector2(26.0, length),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _hitbox = RectangleHitbox(size: size);
    if (!isOpen) {
      add(_hitbox!);
    }
  }

  void openDoor() {
    if (isOpen) return;
    isOpen = true;
    if (_hitbox != null && _hitbox!.isMounted) {
      _hitbox!.removeFromParent();
    }
    try {
      game.playSfx('purchase.wav');
      game.spawnExplosionParticles(
        position: position,
        colorChoices: [const Color(0xFF00E676), Colors.white],
        count: 8,
        minSize: 1.5,
        maxSize: 3.0,
        minSpeed: 20.0,
        maxSpeed: 60.0,
      );
    } catch (_) {}
  }

  void closeDoor() {
    if (!isOpen) return;
    isOpen = false;
    if (_hitbox != null && !_hitbox!.isMounted) {
      add(_hitbox!);
    }
    try {
      game.playSfx('asteroid_split.wav');
      game.spawnExplosionParticles(
        position: position,
        colorChoices: [const Color(0xFFFF1744), const Color(0xFFFF9100), Colors.white],
        count: 10,
        minSize: 2.0,
        maxSize: 4.0,
        minSpeed: 30.0,
        maxSpeed: 80.0,
      );
    } catch (_) {}
  }

  @override
  void update(double dt) {
    super.update(dt);
    final target = isOpen ? 1.0 : 0.0;
    if (transitionProgress != target) {
      final step = 2.8 * dt;
      if (transitionProgress < target) {
        transitionProgress = math.min(target, transitionProgress + step);
      } else {
        transitionProgress = math.max(target, transitionProgress - step);
      }
    }

    // Se estiver fechada ou fechando, bloqueia fisicamente jogador e entidades
    if (transitionProgress < 0.85 && game.state == GameState.playing) {
      _resolvePhysicalCollisions();
    }
  }

  void _resolvePhysicalCollisions() {
    // 1. Bloqueia jogadora
    try {
      final p = game.player;
      final halfW = size.x / 2 + p.radius;
      final halfH = size.y / 2 + p.radius;
      final dx = p.position.x - position.x;
      final dy = p.position.y - position.y;

      if (dx.abs() < halfW && dy.abs() < halfH) {
        final overlapX = halfW - dx.abs();
        final overlapY = halfH - dy.abs();
        if (overlapX < overlapY) {
          p.position.x += (dx == 0 ? 1.0 : dx.sign) * overlapX;
          p.velocity.x = -p.velocity.x * 0.40;
        } else {
          p.position.y += (dy == 0 ? 1.0 : dy.sign) * overlapY;
          p.velocity.y = -p.velocity.y * 0.40;
        }
      }
    } catch (_) {}
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (transitionProgress >= 0.85) return; // Aberta: tiros passam livremente

    if (other is BulletComponent) {
      other.removeFromParent();
    } else if (other is EnemyBulletComponent) {
      other.removeFromParent();
    } else if (other is AsteroidComponent) {
      final impactDmg = math.max(25.0, other.velocity.length * 0.5);
      other.takeDamage(impactDmg, position);
      other.velocity.setFrom(-other.velocity * 0.75);
    } else if (other is EnemyShipComponent) {
      other.velocity.setFrom(-other.velocity * 0.50);
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final statusColor = isOpen ? const Color(0xFF00E676) : const Color(0xFFFF1744);
    final w = size.x;
    final h = size.y;

    // 1. Postes hidráulicos fixos nos batentes da porta
    final framePaint = Paint()..color = const Color(0xFF1E293B);
    final borderPaint = Paint()
      ..color = const Color(0xFF64748B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    if (isHorizontal) {
      // Batentes laterais
      final leftPost = Rect.fromLTWH(0, 0, 18, h);
      final rightPost = Rect.fromLTWH(w - 18, 0, 18, h);
      canvas.drawRect(leftPost, framePaint);
      canvas.drawRect(leftPost, borderPaint);
      canvas.drawRect(rightPost, framePaint);
      canvas.drawRect(rightPost, borderPaint);

      // Folhas deslizantes da porta blindada (retraem para os lados ao abrir)
      final leafWidth = (w / 2 - 18) * (1.0 - transitionProgress);
      if (leafWidth > 1.0) {
        final leftLeaf = Rect.fromLTWH(18, 2, leafWidth, h - 4);
        final rightLeaf = Rect.fromLTWH(w - 18 - leafWidth, 2, leafWidth, h - 4);

        final leafPaint = Paint()..color = const Color(0xFF334155);
        canvas.drawRect(leftLeaf, leafPaint);
        canvas.drawRect(rightLeaf, leafPaint);

        // Faixas de aviso de perigo amarelas/pretas nas portas
        final hazardPaint = Paint()
          ..color = const Color(0xFFFFD600)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5;
        canvas.drawLine(Offset(18, 5), Offset(18 + leafWidth, h - 5), hazardPaint);
        canvas.drawLine(Offset(w - 18 - leafWidth, 5), Offset(w - 18, h - 5), hazardPaint);
      }

      // Luz de status central
      final ledPaint = Paint()..color = statusColor;
      canvas.drawCircle(Offset(w / 2, h / 2), 3.5, ledPaint);
    } else {
      // Batentes verticais (topo e base)
      final topPost = Rect.fromLTWH(0, 0, w, 18);
      final botPost = Rect.fromLTWH(0, h - 18, w, 18);
      canvas.drawRect(topPost, framePaint);
      canvas.drawRect(topPost, borderPaint);
      canvas.drawRect(botPost, framePaint);
      canvas.drawRect(botPost, borderPaint);

      // Folhas verticais
      final leafHeight = (h / 2 - 18) * (1.0 - transitionProgress);
      if (leafHeight > 1.0) {
        final topLeaf = Rect.fromLTWH(2, 18, w - 4, leafHeight);
        final botLeaf = Rect.fromLTWH(2, h - 18 - leafHeight, w - 4, leafHeight);

        final leafPaint = Paint()..color = const Color(0xFF334155);
        canvas.drawRect(topLeaf, leafPaint);
        canvas.drawRect(botLeaf, leafPaint);

        final hazardPaint = Paint()
          ..color = const Color(0xFFFFD600)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5;
        canvas.drawLine(Offset(5, 18), Offset(w - 5, 18 + leafHeight), hazardPaint);
        canvas.drawLine(Offset(5, h - 18 - leafHeight), Offset(w - 5, h - 18), hazardPaint);
      }

      // Luz de status central
      final ledPaint = Paint()..color = statusColor;
      canvas.drawCircle(Offset(w / 2, h / 2), 3.5, ledPaint);
    }
  }
}

/// Estados da Câmara de Quarentena
enum ChamberState {
  /// Aguardando a Valquíria entrar na sala (Portas Abertas)
  dormant,

  /// Portas trancadas, alarme vermelho piscando e onda de inimigos confinada
  lockdown,

  /// Inimigos derrotados, portas liberadas e Cofre de Ouro recompensado
  completed,
}

/// 3. Câmara de Quarentena (Sprint 30 — Lockdown Chamber)
/// Uma sala fechada com paredes industriais, portas blindadas e combate confinado.
class LockdownChamberComponent extends PositionComponent
    with HasGameReference<AsteroidsGame> {
  final Vector2 chamberSize;
  final String chamberName;
  final int enemyWaveCount;

  ChamberState state = ChamberState.dormant;
  double _alarmFlashTimer = 0.0;
  final List<BlastDoorComponent> doors = [];
  final List<EnemyShipComponent> _chamberEnemies = [];
  ModularFloorComponent? floorComponent;

  LockdownChamberComponent({
    required Vector2 position,
    Vector2? chamberSize,
    this.chamberName = 'HANGAR DE BLINDAGEM // PROTOCOLO DE QUARENTENA',
    this.enemyWaveCount = 6,
  })  : chamberSize = chamberSize ?? Vector2(750.0, 700.0),
        super(
          position: position.clone(),
          size: (chamberSize ?? Vector2(750.0, 700.0)).clone(),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final halfW = chamberSize.x / 2;
    final halfH = chamberSize.y / 2;
    const wallThick = 26.0;
    const doorLength = 170.0;

    // 1. Piso Metálico Interior
    floorComponent = ModularFloorComponent(
      position: position,
      size: chamberSize,
      floorAccent: const Color(0xFF00E5FF),
    );
    game.world.add(floorComponent!);

    // 2. Paredes Perimétricas Modulares (Norte, Sul, Leste, Oeste)
    // Paredes Norte (divididas ao redor da porta de entrada norte)
    final topWallLength = (chamberSize.x - doorLength) / 2;
    final topWallLeftPos = position + Vector2(-halfW + topWallLength / 2, -halfH);
    final topWallRightPos = position + Vector2(halfW - topWallLength / 2, -halfH);
    game.world.add(
      MegastructureWallComponent(
        position: topWallLeftPos,
        wallSize: Vector2(topWallLength, wallThick),
        wallColor: const Color(0xFF00E5FF),
      ),
    );
    game.world.add(
      MegastructureWallComponent(
        position: topWallRightPos,
        wallSize: Vector2(topWallLength, wallThick),
        wallColor: const Color(0xFF00E5FF),
      ),
    );

    // Paredes Sul (divididas ao redor da porta de saída sul)
    final botWallLeftPos = position + Vector2(-halfW + topWallLength / 2, halfH);
    final botWallRightPos = position + Vector2(halfW - topWallLength / 2, halfH);
    game.world.add(
      MegastructureWallComponent(
        position: botWallLeftPos,
        wallSize: Vector2(topWallLength, wallThick),
        wallColor: const Color(0xFF00E5FF),
      ),
    );
    game.world.add(
      MegastructureWallComponent(
        position: botWallRightPos,
        wallSize: Vector2(topWallLength, wallThick),
        wallColor: const Color(0xFF00E5FF),
      ),
    );

    // Paredes Laterais Contínuas (Oeste e Leste)
    final leftWallPos = position + Vector2(-halfW, 0);
    final rightWallPos = position + Vector2(halfW, 0);
    game.world.add(
      MegastructureWallComponent(
        position: leftWallPos,
        wallSize: Vector2(wallThick, chamberSize.y),
        wallColor: const Color(0xFF00E5FF),
      ),
    );
    game.world.add(
      MegastructureWallComponent(
        position: rightWallPos,
        wallSize: Vector2(wallThick, chamberSize.y),
        wallColor: const Color(0xFF00E5FF),
      ),
    );

    // 3. Portas Blindadas (Norte e Sul — Começam abertas para convidar o jogador)
    final northDoor = BlastDoorComponent(
      position: position + Vector2(0, -halfH),
      length: doorLength,
      isHorizontal: true,
      isOpen: true,
    );
    final southDoor = BlastDoorComponent(
      position: position + Vector2(0, halfH),
      length: doorLength,
      isHorizontal: true,
      isOpen: true,
    );

    doors.addAll([northDoor, southDoor]);
    game.world.addAll(doors);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (game.state != GameState.playing) return;

    switch (state) {
      case ChamberState.dormant:
        _checkPlayerEntry();
        break;
      case ChamberState.lockdown:
        _updateLockdown(dt);
        break;
      case ChamberState.completed:
        break;
    }
  }

  void _checkPlayerEntry() {
    try {
      final p = game.player;
      final halfW = chamberSize.x / 2 - 50.0;
      final halfH = chamberSize.y / 2 - 50.0;
      final dx = (p.position.x - position.x).abs();
      final dy = (p.position.y - position.y).abs();

      if (dx < halfW && dy < halfH) {
        startLockdown();
      }
    } catch (_) {}
  }

  void startLockdown() {
    if (state != ChamberState.dormant) return;
    state = ChamberState.lockdown;

    // 1. Tranca as portas blindadas
    for (final door in doors) {
      door.closeDoor();
    }

    // 2. Feedback de alarme
    try {
      game.spawnFloatingText(
        position + Vector2(0, -50),
        I18n.select(
          pt: 'ALERTA // PROTOCOLO DE QUARENTENA ATIVADO',
          en: 'ALERT // QUARANTINE PROTOCOL ENGAGED',
        ),
        color: const Color(0xFFFF1744),
        fontSize: 16.0,
      );
      game.playSfx('boss_spawn.wav');
    } catch (_) {}

    // 3. Spawna onda tática confinada dentro da câmara
    _spawnChamberWave();
  }

  void _spawnChamberWave() {
    _chamberEnemies.clear();
    final halfW = chamberSize.x / 2 - 120.0;
    final halfH = chamberSize.y / 2 - 120.0;
    final rng = math.Random();

    for (var i = 0; i < enemyWaveCount; i++) {
      final offset = Vector2(
        (rng.nextDouble() * 2 - 1) * halfW,
        (rng.nextDouble() * 2 - 1) * halfH,
      );
      // Evita spawnar exatamente em cima do jogador
      if (offset.length < 90.0) {
        offset.x += (offset.x >= 0 ? 120.0 : -120.0);
      }

      final enemyType = (i % 3 == 0)
          ? EnemyType.raider
          : (i % 3 == 1 ? EnemyType.voidSwarmer : EnemyType.cryoBomber);

      final enemy = EnemyShipComponent(
        position: position + offset,
        type: enemyType,
      );
      _chamberEnemies.add(enemy);
      game.world.add(enemy);
    }
  }

  void _updateLockdown(double dt) {
    _alarmFlashTimer += dt * 4.0;

    // Filtra inimigos que já foram eliminados
    _chamberEnemies.removeWhere((e) => e.isRemoving || !e.isMounted || e.hp <= 0);

    if (_chamberEnemies.isEmpty) {
      completeLockdown();
    }
  }

  void completeLockdown() {
    if (state != ChamberState.lockdown) return;
    state = ChamberState.completed;

    // 1. Abre as portas blindadas
    for (final door in doors) {
      door.openDoor();
    }

    // 2. Spawna Baú Dourado Lendário no centro do hangar
    try {
      game.world.add(
        ChestComponent(
          position: position.clone(),
          tier: ChestTier.gold,
        ),
      );
      // Recompensa de 4 orbes de Stardust e Créditos
      final rng = math.Random();
      for (var i = 0; i < 4; i++) {
        final off = Vector2((rng.nextDouble() - 0.5) * 40, (rng.nextDouble() - 0.5) * 40);
        game.world.add(
          XpOrbComponent(
            position: position + off,
            type: XpOrbType.large,
          ),
        );
      }
      game.score += 350;
      game.spawnFloatingText(
        position + Vector2(0, -35),
        'QUARENTENA SUPERADA // COFRE DOURADO LIBERADO',
        color: const Color(0xFF00E676),
        fontSize: 16.0,
      );
      game.playSfx('chest_open.wav');
    } catch (_) {}
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Se estiver em lockdown, pulsa luz de emergência vermelha no chão da câmara
    if (state == ChamberState.lockdown) {
      final pulse = 0.5 + 0.5 * math.sin(_alarmFlashTimer);
      final alarmPaint = Paint()
        ..color = const Color(0xFFFF1744).withValues(alpha: 0.12 * pulse)
        ..style = PaintingStyle.fill;
      canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), alarmPaint);
    }
  }
}

/// 4. Estrutura Modular de Estação Espacial (Kenney CC0 — Hangar, Antenas, Módulos e Conectores)
class StationStructureComponent extends PositionComponent
    with HasGameReference<AsteroidsGame>, CollisionCallbacks {
  final String spriteAsset;
  final bool isSolid;
  final Color beaconColor;
  double _beaconTimer = 0.0;

  StationStructureComponent({
    required Vector2 position,
    required Vector2 size,
    required this.spriteAsset,
    this.isSolid = true,
    this.beaconColor = const Color(0xFF00E5FF),
    double angle = 0.0,
  }) : super(
          position: position.clone(),
          size: size.clone(),
          anchor: Anchor.center,
          angle: angle,
          priority: -35,
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    if (isSolid) {
      add(RectangleHitbox(size: size));
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _beaconTimer += dt;
    if (isSolid && isMounted && game.state == GameState.playing) {
      _resolvePhysicalCollisions();
    }
  }

  void _resolvePhysicalCollisions() {
    try {
      final p = game.player;
      final halfW = size.x / 2 + 18.0;
      final halfH = size.y / 2 + 18.0;
      final dx = p.position.x - position.x;
      final dy = p.position.y - position.y;
      if (dx.abs() < halfW && dy.abs() < halfH) {
        final overlapX = halfW - dx.abs();
        final overlapY = halfH - dy.abs();
        final signX = dx == 0 ? 1.0 : dx.sign;
        final signY = dy == 0 ? 1.0 : dy.sign;
        if (overlapX < overlapY) {
          p.position.x += signX * (overlapX + 1.0);
          p.velocity.x = 0;
        } else {
          p.position.y += signY * (overlapY + 1.0);
          p.velocity.y = 0;
        }
      }
    } catch (_) {}

    for (final child in game.world.children) {
      if (child is AsteroidComponent && !child.isRemoving) {
        final halfW = size.x / 2 + child.radius;
        final halfH = size.y / 2 + child.radius;
        final dx = child.position.x - position.x;
        final dy = child.position.y - position.y;
        if (dx.abs() < halfW && dy.abs() < halfH) {
          final overlapX = halfW - dx.abs();
          final overlapY = halfH - dy.abs();
          final signX = dx == 0 ? 1.0 : dx.sign;
          final signY = dy == 0 ? 1.0 : dy.sign;
          if (overlapX < overlapY) {
            child.position.x += signX * (overlapX + 1.0);
            child.velocity.x = signX * child.velocity.x.abs() * 0.8;
          } else {
            child.position.y += signY * (overlapY + 1.0);
            child.velocity.y = signY * child.velocity.y.abs() * 0.8;
          }
        }
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);

    if (spriteAsset.contains('satellite') || spriteAsset.contains('Dish')) {
      // 📡 Antena / Relé de Comunicações Espacial Hi-Tech
      final center = Offset(size.x / 2, size.y / 2);
      final r = math.min(size.x, size.y) * 0.42;

      // Base do suporte em treliça
      final pylonPaint = Paint()
        ..color = const Color(0xFF263238)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4;
      canvas.drawLine(Offset(center.dx, center.dy + r), Offset(center.dx, size.y), pylonPaint);
      canvas.drawLine(Offset(center.dx - r * 0.5, size.y), Offset(center.dx + r * 0.5, size.y), pylonPaint);

      // Prato parabólico
      final dishPaint = Paint()
        ..color = const Color(0xFF1E293B)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, r, dishPaint);

      final rimPaint = Paint()
        ..color = beaconColor.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawCircle(center, r, rimPaint);

      // Anéis concêntricos do receptor
      canvas.drawCircle(center, r * 0.55, rimPaint..strokeWidth = 1.2);
      canvas.drawCircle(center, 3.5, Paint()..color = Colors.white);

      // Pulso de transmissão de ondas de rádio
      final wavePulse = (_beaconTimer * 2.0) % 1.0;
      canvas.drawCircle(
        center,
        r * (0.6 + 0.6 * wavePulse),
        Paint()
          ..color = beaconColor.withValues(alpha: (1.0 - wavePulse) * 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    } else if (spriteAsset.contains('pipe')) {
      // 🧪 Dutos Industriais / Conduíte de Fluido Refrigerante
      final isVertical = size.y > size.x;
      final pipeRRect = RRect.fromRectAndRadius(rect, const Radius.circular(4.0));
      canvas.drawRRect(pipeRRect, Paint()..color = const Color(0xFF1A2230));

      // Borda e anéis de fixação
      final clampPaint = Paint()
        ..color = const Color(0xFF475569)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawRRect(pipeRRect, clampPaint);

      // Duto central brilhante de plasma/gás
      final coreVein = Paint()
        ..color = beaconColor.withValues(alpha: 0.65)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      if (isVertical) {
        canvas.drawLine(Offset(size.x / 2, 4), Offset(size.x / 2, size.y - 4), coreVein);
      } else {
        canvas.drawLine(Offset(4, size.y / 2), Offset(size.x - 4, size.y / 2), coreVein);
      }
    } else if (spriteAsset.contains('crater')) {
      // 🕳️ Cratera de Impacto Geológico com Camadas de Profundidade
      final center = Offset(size.x / 2, size.y / 2);
      final r = math.min(size.x, size.y) * 0.46;

      canvas.drawCircle(center, r, Paint()..color = const Color(0xFF0F141C));
      canvas.drawCircle(center, r * 0.72, Paint()..color = const Color(0xFF070A0F));
      canvas.drawCircle(
        center,
        r,
        Paint()
          ..color = const Color(0xFF334155)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0,
      );
      // Fragmentos de vidro estelar fundido
      canvas.drawCircle(center, 2.5, Paint()..color = beaconColor.withValues(alpha: 0.7));
    } else {
      // 🛰️ Módulo / Casco de Estação Espacial Modular de Blindagem
      final moduleRRect = RRect.fromRectAndRadius(rect, const Radius.circular(5.0));
      canvas.drawRRect(moduleRRect, Paint()..color = const Color(0xFF0F172A));

      // Moldura chanfrada de reforço
      canvas.drawRRect(
        moduleRRect,
        Paint()
          ..color = const Color(0xFF334155)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6,
      );

      // Células solares / painéis tecnológicos embutidos
      if (size.x >= 28.0 && size.y >= 28.0) {
        final panelMargin = 5.0;
        final panelRect = Rect.fromLTWH(
          panelMargin,
          panelMargin,
          size.x - panelMargin * 2,
          size.y - panelMargin * 2,
        );
        canvas.drawRect(
          panelRect,
          Paint()..color = const Color(0xFF070D18),
        );
        canvas.drawRect(
          panelRect,
          Paint()
            ..color = const Color(0xFF1E3A8A).withValues(alpha: 0.45)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.0,
        );
      }
    }

    // Sinalizadores estroboscópicos de segurança LED nas extremidades
    final pulse = 0.5 + 0.5 * math.sin(_beaconTimer * 3.5);
    final beaconPaint = Paint()
      ..color = beaconColor.withValues(alpha: 0.35 + 0.65 * pulse)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(6, 6), 2.8, beaconPaint);
    canvas.drawCircle(Offset(size.x - 6, size.y - 6), 2.8, beaconPaint);
  }
}

/// 5. Barreira de Recife de Asteroides (Cânions e Desfiladeiros Cósmicos intransponíveis)
class AsteroidReefComponent extends PositionComponent
    with HasGameReference<AsteroidsGame>, CollisionCallbacks {
  final List<({Offset offset, double radius, double craterScale})> clusters;
  final Color oreGlowColor;

  AsteroidReefComponent({
    required Vector2 position,
    required Vector2 size,
    required this.clusters,
    this.oreGlowColor = const Color(0xFF00E5FF),
  }) : super(
          position: position.clone(),
          size: size.clone(),
          anchor: Anchor.center,
          priority: -36,
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox(size: size));
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isMounted && game.state == GameState.playing) {
      _resolvePhysicalCollisions();
    }
  }

  void _resolvePhysicalCollisions() {
    try {
      final p = game.player;
      final halfW = size.x / 2 + 16.0;
      final halfH = size.y / 2 + 16.0;
      final dx = p.position.x - position.x;
      final dy = p.position.y - position.y;
      if (dx.abs() < halfW && dy.abs() < halfH) {
        final overlapX = halfW - dx.abs();
        final overlapY = halfH - dy.abs();
        final signX = dx == 0 ? 1.0 : dx.sign;
        final signY = dy == 0 ? 1.0 : dy.sign;
        if (overlapX < overlapY) {
          p.position.x += signX * (overlapX + 1.0);
          p.velocity.x = 0;
        } else {
          p.position.y += signY * (overlapY + 1.0);
          p.velocity.y = 0;
        }
      }
    } catch (_) {}

    for (final child in game.world.children) {
      if (child is AsteroidComponent && !child.isRemoving) {
        final halfW = size.x / 2 + child.radius;
        final halfH = size.y / 2 + child.radius;
        final dx = child.position.x - position.x;
        final dy = child.position.y - position.y;
        if (dx.abs() < halfW && dy.abs() < halfH) {
          final overlapX = halfW - dx.abs();
          final overlapY = halfH - dy.abs();
          final signX = dx == 0 ? 1.0 : dx.sign;
          final signY = dy == 0 ? 1.0 : dy.sign;
          if (overlapX < overlapY) {
            child.position.x += signX * (overlapX + 1.0);
            child.velocity.x = signX * child.velocity.x.abs() * 0.8;
          } else {
            child.position.y += signY * (overlapY + 1.0);
            child.velocity.y = signY * child.velocity.y.abs() * 0.8;
          }
        }
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // 1. Sombra volumétrica de profundidade do recife
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.70)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), shadowPaint);

    // 2. Rocha maciça densa de asteroide
    final rockPaint = Paint()
      ..color = const Color(0xFF1E262B)
      ..style = PaintingStyle.fill;
    final edgePaint = Paint()
      ..color = const Color(0xFF37474F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (final cluster in clusters) {
      final cPos = cluster.offset;
      canvas.drawCircle(cPos, cluster.radius, rockPaint);
      canvas.drawCircle(cPos, cluster.radius, edgePaint);

      // Crateras vetoriais profundas em relevo
      final crR = cluster.radius * cluster.craterScale * 0.45;
      if (crR >= 3.0) {
        canvas.drawCircle(cPos, crR, Paint()..color = const Color(0xFF0F1418));
        canvas.drawCircle(
          cPos,
          crR,
          Paint()
            ..color = const Color(0xFF546E7A).withValues(alpha: 0.6)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2,
        );
      }
    }

    // 3. Veios de minério luminescentes interligados
    final orePaint = Paint()
      ..color = oreGlowColor.withValues(alpha: 0.50)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    for (int i = 0; i < clusters.length - 1; i++) {
      canvas.drawLine(clusters[i].offset, clusters[i + 1].offset, orePaint);
    }
  }
}
