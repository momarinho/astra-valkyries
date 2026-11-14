import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flame/components.dart' show Vector2;
import 'package:void_protocol/constants.dart';
import 'package:void_protocol/game/asteroids_game.dart';
import 'package:void_protocol/game/map/sector_map_data.dart';
import 'package:void_protocol/services/localization_service.dart';

/// Holograma do Mapa Tático em Tela Cheia (Estilo Dead Cells / Metroidvania).
/// Permite à piloto inspecionar o setor proceduralmente gerado,
/// visualizar a névoa de guerra (*fog of war*), estações, destroços e o
/// Covil do Chefe soberano do setor com telemetria em tempo real.
class TacticalMapOverlay extends StatefulWidget {
  final AsteroidsGame game;

  const TacticalMapOverlay({super.key, required this.game});

  @override
  State<TacticalMapOverlay> createState() => _TacticalMapOverlayState();
}

class _TacticalMapOverlayState extends State<TacticalMapOverlay> with SingleTickerProviderStateMixin {
  late final FocusNode _focusNode;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _closeMap() {
    widget.game.closeTacticalMap();
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final mapData = game.sectorMap;
    final player = game.player;
    final sector = game.currentSector;
    final valkyrie = game.selectedValkyrie;

    final playerPos = player.position;
    final bossNode = mapData?.bossLairNode;
    final distanceToBoss = bossNode != null
        ? (bossNode.position - playerPos).length
        : 0.0;

    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.keyM ||
                event.logicalKey == LogicalKeyboardKey.escape)) {
          _closeMap();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Scaffold(
        backgroundColor: Colors.black.withOpacity(0.88),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Header: Sector Name, Callsign & Close Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: sector.primaryColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: sector.primaryColor.withOpacity(0.6)),
                          ),
                          child: Icon(Icons.map_rounded, color: sector.primaryColor, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${I18n.t('map.title')} // ${sector.name.toUpperCase()}',
                              style: TextStyle(
                                fontFamily: 'Orbitron',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                                color: sector.primaryColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${sector.subtitle} • ${I18n.select(pt: 'PILOTO', en: 'PILOT')}: ${valkyrie.name.toUpperCase()} [${valkyrie.callsign}]',
                              style: TextStyle(
                                fontFamily: 'Rajdhani',
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.7),
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E293B),
                        foregroundColor: Colors.white,
                        side: BorderSide(color: sector.primaryColor.withOpacity(0.6)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _closeMap,
                      icon: const Icon(Icons.close, size: 16),
                      label: Text(
                        I18n.t('map.close'),
                        style: const TextStyle(
                          fontFamily: 'Orbitron',
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Center Map Viewport (Interactive Holographic Grid)
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF070B14),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: sector.primaryColor.withOpacity(0.35), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: sector.primaryColor.withOpacity(0.12),
                          blurRadius: 18,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // 1. Grid Canvas & Fog of War Drawing
                          AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, _) {
                              return CustomPaint(
                                painter: _TacticalMapPainter(
                                  game: game,
                                  mapData: mapData,
                                  pulse: _pulseController.value,
                                ),
                              );
                            },
                          ),

                          // 2. Compass Orientation & Coordinates Watermark
                          Positioned(
                            top: 12,
                            left: 14,
                            child: Row(
                              children: [
                                const Icon(Icons.explore_rounded, color: Colors.white38, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  'NAV: (${playerPos.x.toInt()}, ${playerPos.y.toInt()}) [SETOR 4.800x4.800 km]',
                                  style: TextStyle(
                                    fontFamily: 'Rajdhani',
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white.withOpacity(0.5),
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Bottom Tactical Telemetry Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A).withOpacity(0.95),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Boss Distance Vector
                      Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: const Color(0xFFFF1744),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            I18n.select(pt: 'COVIL DO TITÃ: ', en: 'LEVIATHAN LAIR: '),
                            style: const TextStyle(
                              fontFamily: 'Orbitron',
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFF1744),
                              letterSpacing: 0.8,
                            ),
                          ),
                          Text(
                            '${(distanceToBoss / 10).round()}m ${I18n.select(pt: 'de distância', en: 'distance')}',
                            style: TextStyle(
                              fontFamily: 'Rajdhani',
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),

                      // Exploration Progress
                      if (mapData != null)
                        Row(
                          children: [
                            Icon(Icons.radar_rounded, color: sector.primaryColor, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              '${I18n.select(pt: 'PONTOS DESCOBERTOS', en: 'DISCOVERED SITES')}: ${mapData.discoveredNodesCount}/${mapData.totalDiscoverableNodes}',
                              style: TextStyle(
                                fontFamily: 'Orbitron',
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: sector.primaryColor,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Text(
                              '${I18n.select(pt: 'COBERTURA', en: 'COVERAGE')}: ${((mapData.exploredCells.length / (SectorMapData.gridResolution * SectorMapData.gridResolution)) * 100).toInt()}%',
                              style: TextStyle(
                                fontFamily: 'Rajdhani',
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TacticalMapPainter extends CustomPainter {
  final AsteroidsGame game;
  final SectorMapData? mapData;
  final double pulse;

  _TacticalMapPainter({
    required this.game,
    required this.mapData,
    required this.pulse,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const worldW = GameConstants.sectorWidth;
    const worldH = GameConstants.sectorHeight;

    // Escala uniforme para caber no container mantendo aspecto quadrado
    final mapSide = math.min(size.width, size.height);
    final originX = (size.width - mapSide) / 2;
    final originY = (size.height - mapSide) / 2;
    final mapRect = Rect.fromLTWH(originX, originY, mapSide, mapSide);

    // 1. Fundo do Setor com grade de coordenadas
    final bgPaint = Paint()..color = const Color(0xFF030712);
    canvas.drawRect(mapRect, bgPaint);

    final gridPaint = Paint()
      ..color = Colors.cyanAccent.withOpacity(0.08)
      ..strokeWidth = 1.0;

    const divisions = SectorMapData.gridResolution;
    final step = mapSide / divisions;

    for (var i = 0; i <= divisions; i++) {
      final pos = i * step;
      canvas.drawLine(Offset(originX + pos, originY), Offset(originX + pos, originY + mapSide), gridPaint);
      canvas.drawLine(Offset(originX, originY + pos), Offset(originX + mapSide, originY + pos), gridPaint);
    }

    // 2. Desenha Névoa de Guerra (Fog of War)
    if (mapData != null) {
      final cellW = mapSide / divisions;
      final cellH = mapSide / divisions;

      for (var cy = 0; cy < divisions; cy++) {
        for (var cx = 0; cx < divisions; cx++) {
          final isExplored = mapData!.isCellExplored(cx, cy);
          final cellRect = Rect.fromLTWH(originX + cx * cellW, originY + cy * cellH, cellW, cellH);

          if (!isExplored) {
            // Região não explorada: sombra escura com padrão
            canvas.drawRect(
              cellRect,
              Paint()..color = Colors.black.withOpacity(0.75),
            );
          } else {
            // Região explorada: leve brilho holográfico
            canvas.drawRect(
              cellRect,
              Paint()..color = const Color(0xFF00E5FF).withOpacity(0.04),
            );
          }
        }
      }
    }

    // Converte coordenadas do mundo em coordenadas da tela do mapa
    Offset toScreen(Vector2 worldPos) {
      final nx = (worldPos.x / worldW).clamp(0.0, 1.0);
      final ny = (worldPos.y / worldH).clamp(0.0, 1.0);
      return Offset(originX + nx * mapSide, originY + ny * mapSide);
    }

    // 3. Desenha POIs (Pontos de Interesse) descobertos ou aproximados
    if (mapData != null) {
      for (final node in mapData!.nodes) {
        final nodePos = toScreen(node.position);

        switch (node.type) {
          case MapNodeType.bossLair:
            // Covil do Titã: Círculo de Perigo Vermelho Pulsante
            final lairR = (node.radius / worldW) * mapSide;
            final pPaint = Paint()
              ..color = const Color(0xFFFF1744).withOpacity(0.25 + 0.15 * pulse)
              ..style = PaintingStyle.fill;
            canvas.drawCircle(nodePos, lairR, pPaint);

            final strokePaint = Paint()
              ..color = const Color(0xFFFF1744).withOpacity(0.8)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5;
            canvas.drawCircle(nodePos, lairR, strokePaint);

            // Ícone de Caveira / Alerta
            canvas.drawCircle(nodePos, 8.0 + pulse * 2.0, Paint()..color = const Color(0xFFFF1744));
            break;

          case MapNodeType.station:
            canvas.drawCircle(nodePos, 6.0, Paint()..color = const Color(0xFF00E5FF));
            break;

          case MapNodeType.cargoWreck:
            canvas.drawRect(
              Rect.fromCenter(center: nodePos, width: 8, height: 8),
              Paint()..color = const Color(0xFFFFB300),
            );
            break;

          case MapNodeType.magmaHazard:
          case MapNodeType.singularityRift:
          case MapNodeType.hazardNebula:
            canvas.drawCircle(nodePos, 10.0, Paint()..color = node.primaryColor.withOpacity(0.35));
            break;

          case MapNodeType.timedVault:
          case MapNodeType.flawlessVault:
            canvas.drawCircle(nodePos, 6.5, Paint()..color = node.primaryColor);
            break;

          case MapNodeType.voidMerchant:
            canvas.drawRect(
              Rect.fromCenter(center: nodePos, width: 9, height: 9),
              Paint()..color = const Color(0xFFFFB300),
            );
            break;

          case MapNodeType.cursedShrine:
            canvas.drawCircle(nodePos, 6.0, Paint()..color = const Color(0xFFE040FB));
            break;

          case MapNodeType.playerSpawn:
            break;
          default:
            break;
        }
      }
    }

    // 4. Desenha a Valquíria (Posição do Jogador e Vetor de Projeção)
    final player = game.player;
    final pScreen = toScreen(player.position);

    canvas.save();
    canvas.translate(pScreen.dx, pScreen.dy);
    canvas.rotate(player.angle);

    // Triângulo da nave com neon
    final shipPath = Path()
      ..moveTo(0, -9)
      ..lineTo(-6, 7)
      ..lineTo(6, 7)
      ..close();

    canvas.drawPath(
      shipPath,
      Paint()..color = const Color(0xFF00E5FF),
    );
    canvas.drawPath(
      shipPath,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    canvas.restore();

    // Pulso do Radar em torno do jogador
    canvas.drawCircle(
      pScreen,
      12.0 + pulse * 6.0,
      Paint()
        ..color = const Color(0xFF00E5FF).withOpacity(0.4 - pulse * 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // 5. Moldura de Borda do Setor
    canvas.drawRect(
      mapRect,
      Paint()
        ..color = game.currentSector.primaryColor.withOpacity(0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );
  }

  @override
  bool shouldRepaint(covariant _TacticalMapPainter oldDelegate) => true;
}
