import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:asteroids/game/sector.dart';

enum MapNodeType {
  playerSpawn,
  station,
  cargoWreck,
  hazardNebula,
  magmaHazard,
  singularityRift,
  bossLair,
  cryoPod,
  warpGate,
  timedVault,
  flawlessVault,
  voidMerchant,
  cursedShrine,
  relicPedestal,
  stasisCoffin,
}

class MapNode {
  final String id;
  final MapNodeType type;
  final Vector2 position;
  final String label;
  final String description;
  final IconData icon;
  final Color primaryColor;
  final double radius;
  bool isDiscovered;
  bool isCompleted;

  MapNode({
    required this.id,
    required this.type,
    required this.position,
    required this.label,
    required this.description,
    required this.icon,
    required this.primaryColor,
    this.radius = 120.0,
    this.isDiscovered = false,
    this.isCompleted = false,
  });
}

/// Dados do mapa do setor gerado proceduralmente (estilo Dead Cells).
/// Mantém as coordenadas dos quadrantes, névoa de guerra (*fog of war*),
/// POIs gerados, e a localização do Covil do Chefe.
class SectorMapData {
  final Sector sector;
  final int seed;
  final double mapWidth;
  final double mapHeight;
  final List<MapNode> nodes;
  final MapNode bossLairNode;

  // Grade de 16x16 para rastrear a névoa de guerra explorada
  static const int gridResolution = 16;
  final Set<int> exploredCells = {};

  bool isBossAwakened = false;
  bool isBossDefeated = false;

  SectorMapData({
    required this.sector,
    required this.seed,
    required this.mapWidth,
    required this.mapHeight,
    required this.nodes,
    required this.bossLairNode,
  });

  /// Atualiza a exploração do mapa com base na posição da Valquíria e alcance do radar
  void updateExploration(Vector2 playerPos, double radarRange) {
    // 1. Atualiza células da grade de névoa de guerra
    final cellWidth = mapWidth / gridResolution;
    final cellHeight = mapHeight / gridResolution;

    final cellX = (playerPos.x / cellWidth).floor().clamp(0, gridResolution - 1);
    final cellY = (playerPos.y / cellHeight).floor().clamp(0, gridResolution - 1);

    // Revela a célula atual e vizinhas imediatas dentro do alcance do radar
    for (var dx = -1; dx <= 1; dx++) {
      for (var dy = -1; dy <= 1; dy++) {
        final cx = cellX + dx;
        final cy = cellY + dy;
        if (cx >= 0 && cx < gridResolution && cy >= 0 && cy < gridResolution) {
          exploredCells.add(cy * gridResolution + cx);
        }
      }
    }

    // 2. Revela POIs próximos no radar (alcance de detecção de 850px)
    for (final node in nodes) {
      if (!node.isDiscovered) {
        final dist = positionDistance(playerPos, node.position);
        if (dist <= 850.0) {
          node.isDiscovered = true;
        }
      }
    }
  }

  static double positionDistance(Vector2 a, Vector2 b) {
    return (a - b).length;
  }

  bool isCellExplored(int x, int y) {
    return exploredCells.contains(y * gridResolution + x);
  }

  int get totalDiscoverableNodes => nodes.where((n) => n.type != MapNodeType.playerSpawn).length;
  int get discoveredNodesCount => nodes.where((n) => n.isDiscovered && n.type != MapNodeType.playerSpawn).length;
}
