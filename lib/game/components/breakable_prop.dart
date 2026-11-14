import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'package:void_protocol/game/asteroids_game.dart';
import 'package:void_protocol/game/components/drop.dart';
import 'package:void_protocol/game/components/xp_orb.dart';
import 'package:void_protocol/game/components/enemy_ship.dart';
import 'package:void_protocol/game/components/enemy_bullet.dart';
import 'package:void_protocol/game/components/asteroid.dart';

/// Tipos de objetos quebráveis no cenário (Sprint 29 — Estilo Vampire Survivors)
enum BreakablePropType {
  /// Barril Explosivo: detona em área ao ser destruído, causando dano em cadeia
  explosiveBarrel,

  /// Veio de Minério Cristalino: libera cristais de Stardust (XP) e Sucata (moedas)
  oreCrystal,

  /// Contêiner de Carga Abandonado: libera drops táticos (Reparo de HP, Escudo, Vórtice)
  cargoCrate,

  /// Célula de Fusão: emite uma onda EMP que destrói tiros inimigos e causa choque
  fusionCell,
}

/// Componente de Cenário Destrutível com colisão física e drops táticos.
/// Utiliza sprites modulares CC0 do Kenney com fallback vetorial dinâmico.
class BreakablePropComponent extends PositionComponent
    with HasGameReference<AsteroidsGame>, CollisionCallbacks {
  final BreakablePropType type;
  double hp;
  final double maxHp;
  double hitFlashTimer = 0.0;
  bool isDestroyed = false;
  double _animTimer = 0.0;

  BreakablePropComponent({
    required Vector2 position,
    this.type = BreakablePropType.oreCrystal,
    double? customHp,
  })  : maxHp = customHp ?? _defaultHpForType(type),
        hp = customHp ?? _defaultHpForType(type),
        super(
          position: position.clone(),
          size: _defaultSizeForType(type),
          anchor: Anchor.center,
        );

  static double _defaultHpForType(BreakablePropType type) {
    switch (type) {
      case BreakablePropType.explosiveBarrel:
        return 24.0;
      case BreakablePropType.oreCrystal:
        return 38.0;
      case BreakablePropType.cargoCrate:
        return 50.0;
      case BreakablePropType.fusionCell:
        return 30.0;
    }
  }

  static Vector2 _defaultSizeForType(BreakablePropType type) {
    switch (type) {
      case BreakablePropType.explosiveBarrel:
        return Vector2(38.0, 44.0);
      case BreakablePropType.oreCrystal:
        return Vector2(46.0, 42.0);
      case BreakablePropType.cargoCrate:
        return Vector2(48.0, 44.0);
      case BreakablePropType.fusionCell:
        return Vector2(44.0, 36.0);
    }
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox(size: size));
  }

  @override
  void update(double dt) {
    super.update(dt);
    _animTimer += dt;
    if (hitFlashTimer > 0) {
      hitFlashTimer = math.max(0.0, hitFlashTimer - dt);
    }
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is AsteroidComponent) {
      final impactDmg = math.max(20.0, other.velocity.length * 0.4);
      takeDamage(impactDmg, other.position);
      other.takeDamage(impactDmg * 0.8, position);
    }
  }

  /// Aplica dano ao objeto do cenário. Retorna true se foi destruído.
  bool takeDamage(double damage, [Vector2? hitPos]) {
    if (isDestroyed) return false;
    hp -= damage;
    hitFlashTimer = 0.12;

    try {
      game.spawnExplosionParticles(
        position: hitPos ?? position,
        colorChoices: _hitParticleColors,
        count: 4,
        minSize: 1.5,
        maxSize: 3.0,
        minSpeed: 25.0,
        maxSpeed: 70.0,
      );
    } catch (_) {}

    if (hp <= 0) {
      onDestroyed(hitPos);
      return true;
    }
    return false;
  }

  List<Color> get _hitParticleColors {
    switch (type) {
      case BreakablePropType.explosiveBarrel:
        return [Colors.orange, Colors.redAccent, Colors.yellow];
      case BreakablePropType.oreCrystal:
        return [const Color(0xFF00E5FF), const Color(0xFFFFD700), Colors.white];
      case BreakablePropType.cargoCrate:
        return [const Color(0xFF90A4AE), const Color(0xFFFFB300), Colors.white];
      case BreakablePropType.fusionCell:
        return [const Color(0xFF00E5FF), const Color(0xFFE040FB), Colors.white];
    }
  }

  void onDestroyed([Vector2? hitPos]) {
    if (isDestroyed) return;
    isDestroyed = true;

    final triggerPos = hitPos ?? position;

    switch (type) {
      case BreakablePropType.explosiveBarrel:
        _triggerBarrelExplosion(triggerPos);
        break;
      case BreakablePropType.oreCrystal:
        _triggerOreShatter(triggerPos);
        break;
      case BreakablePropType.cargoCrate:
        _triggerCrateBreak(triggerPos);
        break;
      case BreakablePropType.fusionCell:
        _triggerFusionOverload(triggerPos);
        break;
    }

    removeFromParent();
  }

  void _triggerBarrelExplosion(Vector2 triggerPos) {
    const explosionRadius = 190.0;
    const barrelDamage = 65.0;

    try {
      game.playSfx('asteroid_split.wav');
      game.spawnFloatingText(
        position + Vector2(0, -18),
        'BOOM!',
        color: const Color(0xFFFF3D00),
        fontSize: 15.0,
      );
      game.spawnExplosionParticles(
        position: position,
        colorChoices: [
          const Color(0xFFFF3D00),
          const Color(0xFFFF9100),
          const Color(0xFFFFEA00),
          Colors.white,
        ],
        count: 22,
        minSize: 2.0,
        maxSize: 5.5,
        minSpeed: 60.0,
        maxSpeed: 210.0,
      );
    } catch (_) {}

    // Dano em área para inimigos, asteroides e outros barris (reação em cadeia)
    final children = List<Component>.from(game.world.children);
    for (final child in children) {
      if (child == this) continue;

      if (child is EnemyShipComponent && !child.isRemoving) {
        if (child.position.distanceTo(position) <= explosionRadius) {
          child.takeDamage(barrelDamage, child.position);
        }
      } else if (child is AsteroidComponent && !child.isRemoving) {
        if (child.position.distanceTo(position) <= explosionRadius) {
          final destroyed = child.takeDamage(barrelDamage, child.position);
          if (destroyed) {
            try {
              game.onAsteroidDestroyed(child.position, child.scoreValue);
            } catch (_) {}
          }
        }
      } else if (child is BreakablePropComponent && !child.isDestroyed && !child.isRemoving) {
        if (child.position.distanceTo(position) <= explosionRadius) {
          child.takeDamage(barrelDamage, child.position);
        }
      }
    }

    // Drop pequeno de Stardust no local da explosão
    try {
      game.world.add(
        XpOrbComponent(
          position: position,
          type: XpOrbType.small,
        ),
      );
    } catch (_) {}
  }

  void _triggerOreShatter(Vector2 triggerPos) {
    try {
      game.playSfx('asteroid_split.wav');
      game.spawnFloatingText(
        position + Vector2(0, -16),
        '+30 CRÉDITOS',
        color: const Color(0xFFFFD700),
        fontSize: 13.0,
      );
      game.spawnExplosionParticles(
        position: position,
        colorChoices: [
          const Color(0xFF00E5FF),
          const Color(0xFFFFD700),
          Colors.white,
        ],
        count: 14,
        minSize: 2.0,
        maxSize: 4.0,
        minSpeed: 40.0,
        maxSpeed: 120.0,
      );
      game.score += 150;
    } catch (_) {}

    // Libera 3 a 4 orbes de Stardust XP (estilo Vampire Survivors)
    final rng = math.Random();
    final count = 3 + rng.nextInt(2);
    for (var i = 0; i < count; i++) {
      final offset = Vector2(
        (rng.nextDouble() - 0.5) * 36.0,
        (rng.nextDouble() - 0.5) * 36.0,
      );
      try {
        game.world.add(
          XpOrbComponent(
            position: position + offset,
            type: i == 0 ? XpOrbType.medium : XpOrbType.small,
          ),
        );
      } catch (_) {}
    }
  }

  void _triggerCrateBreak(Vector2 triggerPos) {
    try {
      game.playSfx('chest_open.wav');
      game.spawnFloatingText(
        position + Vector2(0, -16),
        'CARGA EXTRAÍDA',
        color: const Color(0xFF00E5FF),
        fontSize: 13.0,
      );
      game.spawnExplosionParticles(
        position: position,
        colorChoices: [const Color(0xFFFFB300), const Color(0xFF00E5FF), Colors.white],
        count: 12,
        minSize: 2.0,
        maxSize: 4.5,
        minSpeed: 30.0,
        maxSpeed: 100.0,
      );
    } catch (_) {}

    // Drop tático ponderado
    final rng = math.Random();
    final roll = rng.nextDouble();
    try {
      if (roll < 0.45) {
        // Kit de Reparo de Casco (+1 Vida / HP)
        game.world.add(DropComponent(position: position, type: DropType.health));
      } else if (roll < 0.75) {
        // Escudo Fotônico
        game.world.add(DropComponent(position: position, type: DropType.shield));
      } else {
        // Sobrecarga de Vórtice / Matéria Rara
        game.world.add(DropComponent(position: position, type: DropType.rareHelium));
      }
    } catch (_) {}
  }

  void _triggerFusionOverload(Vector2 triggerPos) {
    const empRadius = 280.0;
    const empDamage = 40.0;

    try {
      game.playSfx('asteroid_split.wav');
      game.spawnFloatingText(
        position + Vector2(0, -18),
        'EMP NOVA!',
        color: const Color(0xFF00E5FF),
        fontSize: 14.0,
      );
      game.spawnExplosionParticles(
        position: position,
        colorChoices: [
          const Color(0xFF00E5FF),
          const Color(0xFFE040FB),
          Colors.white,
        ],
        count: 24,
        minSize: 2.0,
        maxSize: 5.0,
        minSpeed: 50.0,
        maxSpeed: 180.0,
      );
    } catch (_) {}

    // O pulso EMP vaporiza tiros inimigos e causa dano de choque nos inimigos no raio
    final children = List<Component>.from(game.world.children);
    for (final child in children) {
      if (child is EnemyBulletComponent && !child.isRemoving) {
        if (child.position.distanceTo(position) <= empRadius) {
          child.removeFromParent();
        }
      } else if (child is EnemyShipComponent && !child.isRemoving) {
        if (child.position.distanceTo(position) <= empRadius) {
          child.takeDamage(empDamage, child.position);
        }
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // 1. Renderização Vetorial Hi-Tech Procedural de Resolução Nativa
    _renderProceduralVector(canvas);

    // 2. Efeito de Flash Branco ao Sofrer Dano (Feedback tátil visceral)
    if (hitFlashTimer > 0) {
      final flashOpacity = (hitFlashTimer / 0.12).clamp(0.0, 1.0) * 0.75;
      final flashPaint = Paint()
        ..color = Colors.white.withValues(alpha: flashOpacity)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.x, size.y),
          const Radius.circular(5.0),
        ),
        flashPaint,
      );
    }
  }

  void _renderProceduralVector(Canvas canvas) {
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);

    switch (type) {
      case BreakablePropType.explosiveBarrel:
        // 🛢️ Barril de Fusão / Combustível Volátil Hi-Tech
        // Casco cilíndrico de blindagem reforçada
        final barrelRRect = RRect.fromRectAndRadius(rect, const Radius.circular(7.0));
        final bodyGradient = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: const [
            Color(0xFF8B0000), // Sombra carmesim profunda
            Color(0xFFE53935), // Destaque frontal vermelho
            Color(0xFFFF5252), // Reflexo especular
            Color(0xFF5A0000), // Oclusão traseira
          ],
          stops: const [0.0, 0.4, 0.65, 1.0],
        );
        canvas.drawRRect(
          barrelRRect,
          Paint()
            ..shader = bodyGradient.createShader(rect)
            ..style = PaintingStyle.fill,
        );

        // Anéis metálicos duplos de contenção de pressão
        final ringPaint = Paint()
          ..color = const Color(0xFF263238)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0;
        canvas.drawLine(Offset(2, size.y * 0.28), Offset(size.x - 2, size.y * 0.28), ringPaint);
        canvas.drawLine(Offset(2, size.y * 0.72), Offset(size.x - 2, size.y * 0.72), ringPaint);

        // Faixa central de aviso de radiação/volatilidade (amarelo e preto)
        final hazardStripRect = Rect.fromLTWH(4, size.y * 0.42, size.x - 8, size.y * 0.16);
        canvas.drawRect(hazardStripRect, Paint()..color = const Color(0xFFFFD600));
        final stripePaint = Paint()
          ..color = const Color(0xFF1A1A1A)
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke;
        for (double sx = 6; sx < size.x - 8; sx += 7.0) {
          canvas.drawLine(Offset(sx, hazardStripRect.bottom), Offset(sx + 4, hazardStripRect.top), stripePaint);
        }

        // Borda externa nítida e núcleo térmico pulsante
        final borderPaint = Paint()
          ..color = const Color(0xFFFF8A80)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4;
        canvas.drawRRect(barrelRRect, borderPaint);

        final pulse = 0.5 + 0.5 * math.sin(_animTimer * 5.0);
        final coreGlowPaint = Paint()
          ..color = const Color(0xFFFFD600).withValues(alpha: 0.4 + 0.4 * pulse)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(size.x / 2, size.y / 2), 3.2, coreGlowPaint);
        break;

      case BreakablePropType.oreCrystal:
        // 💎 Veio de Minério Cósmico Facetado (Polígonos cortados a laser com veios luminescentes)
        final crustPaint = Paint()
          ..color = const Color(0xFF131A22)
          ..style = PaintingStyle.fill;
        final rockPath = Path()
          ..moveTo(size.x * 0.25, 0)
          ..lineTo(size.x * 0.85, size.y * 0.08)
          ..lineTo(size.x, size.y * 0.55)
          ..lineTo(size.x * 0.75, size.y)
          ..lineTo(size.x * 0.18, size.y * 0.92)
          ..lineTo(0, size.y * 0.45)
          ..close();
        canvas.drawPath(rockPath, crustPaint);

        // Facetas internas sombreadas com reflexo ciano e ametista
        final facet1 = Path()
          ..moveTo(size.x * 0.25, 0)
          ..lineTo(size.x * 0.55, size.y * 0.40)
          ..lineTo(size.x * 0.85, size.y * 0.08)
          ..close();
        canvas.drawPath(facet1, Paint()..color = const Color(0xFF00E5FF).withValues(alpha: 0.18));

        final facet2 = Path()
          ..moveTo(size.x * 0.55, size.y * 0.40)
          ..lineTo(size.x * 0.75, size.y)
          ..lineTo(size.x * 0.18, size.y * 0.92)
          ..close();
        canvas.drawPath(facet2, Paint()..color = const Color(0xFF7C4DFF).withValues(alpha: 0.14));

        // Veios de cristal energizados com brilho pulsante
        final crystalPulse = 0.6 + 0.4 * math.sin(_animTimer * 3.5);
        final veinPaint = Paint()
          ..color = const Color(0xFF00E5FF).withValues(alpha: 0.75 * crystalPulse)
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(Offset(size.x * 0.25, 0), Offset(size.x * 0.55, size.y * 0.40), veinPaint);
        canvas.drawLine(Offset(size.x * 0.55, size.y * 0.40), Offset(size.x * 0.75, size.y), veinPaint);
        canvas.drawLine(Offset(size.x * 0.55, size.y * 0.40), Offset(size.x, size.y * 0.55), veinPaint);

        // Aresta perimétrica de corte
        canvas.drawPath(
          rockPath,
          Paint()
            ..color = const Color(0xFF455A64)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6,
        );

        // Pontos de gemas de ouro estelar
        canvas.drawCircle(Offset(size.x * 0.55, size.y * 0.40), 3.0, Paint()..color = const Color(0xFFFFD700));
        canvas.drawCircle(Offset(size.x * 0.70, size.y * 0.25), 2.0, Paint()..color = Colors.white);
        break;

      case BreakablePropType.cargoCrate:
        // 📦 Contêiner Tático Industrial com Blindagem Chanfrada e Trancas Magnéticas
        final crateRRect = RRect.fromRectAndRadius(rect, const Radius.circular(5.0));
        // Base de liga metálica aeroespacial
        canvas.drawRRect(
          crateRRect,
          Paint()
            ..color = const Color(0xFF1E2631)
            ..style = PaintingStyle.fill,
        );

        // Moldura perimétrica de proteção dourada/âmbar
        final frameRect = Rect.fromLTWH(3.5, 3.5, size.x - 7.0, size.y - 7.0);
        canvas.drawRRect(
          RRect.fromRectAndRadius(frameRect, const Radius.circular(3.0)),
          Paint()
            ..color = const Color(0xFFFFB300).withValues(alpha: 0.85)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.8,
        );

        // Reforço cruzado estrutural em X
        final crossPaint = Paint()
          ..color = const Color(0xFF37474F)
          ..strokeWidth = 2.2
          ..style = PaintingStyle.stroke;
        canvas.drawLine(Offset(6, 6), Offset(size.x - 6, size.y - 6), crossPaint);
        canvas.drawLine(Offset(size.x - 6, 6), Offset(6, size.y - 6), crossPaint);

        // Selo magnético central com LED de status operacional
        final lockRect = Rect.fromCenter(center: Offset(size.x / 2, size.y / 2), width: 14, height: 10);
        canvas.drawRRect(RRect.fromRectAndRadius(lockRect, const Radius.circular(2.0)), Paint()..color = const Color(0xFF0F172A));
        final ledColor = (math.sin(_animTimer * 4.0) > 0) ? const Color(0xFF00E676) : const Color(0xFF00B0FF);
        canvas.drawCircle(Offset(size.x / 2, size.y / 2), 2.2, Paint()..color = ledColor);
        break;

      case BreakablePropType.fusionCell:
        // ⚡ Célula de Contenção Eletromagnética EMP (Núcleo de plasma suspenso)
        final cellRRect = RRect.fromRectAndRadius(rect, const Radius.circular(8.0));
        canvas.drawRRect(cellRRect, Paint()..color = const Color(0xFF0B132B));

        // Placas laterais de isolamento cerâmico
        final insulatorPaint = Paint()
          ..color = const Color(0xFF1C2541)
          ..style = PaintingStyle.fill;
        canvas.drawRect(Rect.fromLTWH(0, 4, 6, size.y - 8), insulatorPaint);
        canvas.drawRect(Rect.fromLTWH(size.x - 6, 4, 6, size.y - 8), insulatorPaint);

        // Câmara de vácuo interna
        final chamberRect = Rect.fromLTWH(8, 5, size.x - 16, size.y - 10);
        canvas.drawRRect(RRect.fromRectAndRadius(chamberRect, const Radius.circular(4.0)), Paint()..color = const Color(0xFF020617));

        // Esfera de plasma em levitação com halo energético
        final centerOffset = Offset(size.x / 2, size.y / 2);
        final plasmaPulse = 0.7 + 0.3 * math.sin(_animTimer * 8.0);
        final plasmaColor = const Color(0xFF00E5FF);

        // Anel de contenção gravitacional
        canvas.drawCircle(
          centerOffset,
          (size.y * 0.28) * plasmaPulse,
          Paint()
            ..color = plasmaColor.withValues(alpha: 0.35)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );

        // Núcleo hiperdenso
        canvas.drawCircle(centerOffset, 4.5, Paint()..color = Colors.white);
        canvas.drawCircle(centerOffset, 3.0, Paint()..color = plasmaColor);

        // Borda externa tecnológica
        canvas.drawRRect(
          cellRRect,
          Paint()
            ..color = const Color(0xFF3A86FF).withValues(alpha: 0.7)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4,
        );
        break;
    }
  }
}
