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

/// 1. Piso Industrial Modular (Sprint 30 — Sub-piso metálico indoor com texturas CC0)
class ModularFloorComponent extends PositionComponent
    with HasGameReference<AsteroidsGame> {
  ui.Image? _floorImage;
  final Color floorAccent;

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
  Future<void> onLoad() async {
    await super.onLoad();
    try {
      final byteData = await rootBundle.load('assets/art/environment/metalTile.png');
      final codec = await ui.instantiateImageCodec(byteData.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      _floorImage = frame.image;
    } catch (_) {
      _floorImage = null;
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);

    // 1. Base escura do piso da estação
    final basePaint = Paint()..color = const Color(0xFF070B14);
    canvas.drawRect(rect, basePaint);

    // 2. Tiling do sprite CC0 de metal se disponível
    if (_floorImage != null) {
      final imgW = _floorImage!.width.toDouble();
      final imgH = _floorImage!.height.toDouble();
      const tileSize = 64.0;
      final cols = (size.x / tileSize).ceil();
      final rows = (size.y / tileSize).ceil();

      final tilePaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.28)
        ..filterQuality = FilterQuality.medium;

      for (var c = 0; c < cols; c++) {
        for (var r = 0; r < rows; r++) {
          final x = c * tileSize;
          final y = r * tileSize;
          final w = math.min(tileSize, size.x - x);
          final h = math.min(tileSize, size.y - y);
          final dst = Rect.fromLTWH(x, y, w, h);
          final src = Rect.fromLTWH(0, 0, imgW * (w / tileSize), imgH * (h / tileSize));
          canvas.drawImageRect(_floorImage!, src, dst, tilePaint);
        }
      }
    } else {
      // Grade geométrica de placas de aço (Fallback vetorial)
      final gridPaint = Paint()
        ..color = const Color(0xFF1E293B).withValues(alpha: 0.60)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      for (double x = 48.0; x < size.x; x += 48.0) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.y), gridPaint);
      }
      for (double y = 48.0; y < size.y; y += 48.0) {
        canvas.drawLine(Offset(0, y), Offset(size.x, y), gridPaint);
      }
    }

    // 3. Moldura de perímetro do hangar
    final borderPaint = Paint()
      ..color = floorAccent.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRect(rect, borderPaint);

    // 4. Marcadores de iluminação LED nos 4 cantos
    final ledPaint = Paint()
      ..color = floorAccent.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(12, 12), 3.0, ledPaint);
    canvas.drawCircle(Offset(size.x - 12, 12), 3.0, ledPaint);
    canvas.drawCircle(Offset(12, size.y - 12), 3.0, ledPaint);
    canvas.drawCircle(Offset(size.x - 12, size.y - 12), 3.0, ledPaint);
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
  ui.Image? _spriteImage;
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
    try {
      final path = spriteAsset.startsWith('assets/')
          ? spriteAsset
          : 'assets/art/environment/$spriteAsset';
      final byteData = await rootBundle.load(path);
      final codec = await ui.instantiateImageCodec(byteData.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      _spriteImage = frame.image;
    } catch (_) {
      _spriteImage = null;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _beaconTimer += dt;
    if (isSolid && game.state == GameState.playing) {
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

    if (_spriteImage != null) {
      final src = Rect.fromLTWH(
        0,
        0,
        _spriteImage!.width.toDouble(),
        _spriteImage!.height.toDouble(),
      );
      final paint = Paint()..filterQuality = FilterQuality.medium;
      canvas.drawImageRect(_spriteImage!, src, rect, paint);
    } else {
      final bgPaint = Paint()..color = const Color(0xFF1E293B);
      canvas.drawRect(rect, bgPaint);
      final borderPaint = Paint()
        ..color = beaconColor.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawRect(rect, borderPaint);
    }

    // Sinalizadores luminosos LED
    final pulse = 0.5 + 0.5 * math.sin(_beaconTimer * 3.5);
    final beaconPaint = Paint()
      ..color = beaconColor.withValues(alpha: 0.3 + 0.7 * pulse)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(6, 6), 3.0, beaconPaint);
    canvas.drawCircle(Offset(size.x - 6, size.y - 6), 3.0, beaconPaint);
  }
}

/// 5. Barreira de Recife de Asteroides (Cânions e Desfiladeiros Cósmicos intransponíveis)
class AsteroidReefComponent extends PositionComponent
    with HasGameReference<AsteroidsGame>, CollisionCallbacks {
  final List<({Offset offset, double radius, double craterScale})> clusters;
  final Color oreGlowColor;
  ui.Image? _craterImage;

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
    try {
      final byteData = await rootBundle.load('assets/art/environment/crater.png');
      final codec = await ui.instantiateImageCodec(byteData.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      _craterImage = frame.image;
    } catch (_) {}
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (game.state == GameState.playing) {
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
      ..color = const Color(0xFF263238)
      ..style = PaintingStyle.fill;
    final edgePaint = Paint()
      ..color = const Color(0xFF455A64)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (final cluster in clusters) {
      final cPos = cluster.offset;
      canvas.drawCircle(cPos, cluster.radius, rockPaint);
      canvas.drawCircle(cPos, cluster.radius, edgePaint);

      if (_craterImage != null) {
        final crSize = cluster.radius * cluster.craterScale;
        final dst = Rect.fromCenter(center: cPos, width: crSize, height: crSize);
        final src = Rect.fromLTWH(
          0,
          0,
          _craterImage!.width.toDouble(),
          _craterImage!.height.toDouble(),
        );
        canvas.drawImageRect(
          _craterImage!,
          src,
          dst,
          Paint()..filterQuality = FilterQuality.medium,
        );
      }
    }

    // 3. Veios de minério luminescentes interligados
    final orePaint = Paint()
      ..color = oreGlowColor.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    for (int i = 0; i < clusters.length - 1; i++) {
      canvas.drawLine(clusters[i].offset, clusters[i + 1].offset, orePaint);
    }
  }
}
