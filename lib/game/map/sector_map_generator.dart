import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:asteroids/constants.dart';
import 'package:asteroids/game/asteroids_game.dart';
import 'package:asteroids/game/sector.dart';
import 'package:asteroids/game/components/space_station.dart';
import 'package:asteroids/game/components/cargo_wreck.dart';
import 'package:asteroids/game/components/cosmic_nebula.dart';
import 'package:asteroids/game/components/magma_hazard.dart';
import 'package:asteroids/game/components/singularity_rift.dart';
import 'package:asteroids/game/components/proximity_mine.dart';
import 'package:asteroids/game/components/derelict_turret.dart';
import 'package:asteroids/game/components/boss_lair.dart';
import 'package:asteroids/game/components/dead_cells_biome.dart';
import 'sector_map_data.dart';

/// Gerador Procedural de Setores Cósmicos (Inspirado no estilo Dead Cells).
/// A cada partida ou salto de hiperespaço, gera organicamente a distribuição
/// dos quadrantes, estações científicas, cargueiros naufragados, névoas e o
/// Covil do Chefe soberano do setor.
class SectorMapGenerator {
  static SectorMapData generateAndSpawn(AsteroidsGame game, {int? customSeed}) {
    final seed = customSeed ?? DateTime.now().millisecondsSinceEpoch;
    final random = math.Random(seed);

    final sector = game.currentSector;
    const mapW = GameConstants.sectorWidth;
    const mapH = GameConstants.sectorHeight;
    final center = Vector2(mapW / 2, mapH / 2);

    // 1. Limpa POIs anteriores do mundo
    final oldPois = game.world.children.where((child) =>
        child is SpaceStationComponent ||
        child is CargoWreckComponent ||
        child is CosmicNebulaComponent ||
        child is MagmaHazardComponent ||
        child is SingularityRiftComponent ||
        child is ProximityMineComponent ||
        child is DerelictTurretComponent ||
        child is BossLairComponent ||
        child is MegastructureWallComponent ||
        child is LaserContainmentGateComponent ||
        child is TimedVaultComponent ||
        child is FlawlessVaultComponent ||
        child is VoidMerchantComponent ||
        child is CursedShrineComponent);
    for (final p in List.from(oldPois)) {
      p.removeFromParent();
    }

    final List<MapNode> nodes = [];

    // 2. Nó de Spawn da Jogadora (Centro)
    nodes.add(
      MapNode(
        id: 'spawn_point',
        type: MapNodeType.playerSpawn,
        position: center.clone(),
        label: 'PONTO DE INSERÇÃO // CENTRO DO SETOR',
        description: 'Coordenadas seguras de inserção tática da Valquíria.',
        icon: Icons.navigation_rounded,
        primaryColor: sector.primaryColor,
        isDiscovered: true,
      ),
    );

    // 3. Quadrantes disponíveis para distribuição procedural (NW, NE, SW, SE)
    final quadrants = [
      Vector2(1250, 1250), // NW
      Vector2(3550, 1250), // NE
      Vector2(1250, 3550), // SW
      Vector2(3550, 3550), // SE
    ]..shuffle(random);

    // Quadrante 0: Covil do Chefe (Boss Lair)
    final bossQuadrant = quadrants[0];
    final bossOffset = Vector2(
      (random.nextDouble() - 0.5) * 350.0,
      (random.nextDouble() - 0.5) * 350.0,
    );
    final bossPos = (bossQuadrant + bossOffset)
      ..x = (bossQuadrant.x + bossOffset.x).clamp(500.0, mapW - 500.0)
      ..y = (bossQuadrant.y + bossOffset.y).clamp(500.0, mapH - 500.0);

    final bossLairComponent = BossLairComponent(
      position: bossPos,
      requiresBeaconCharge: true,
    );
    game.world.add(bossLairComponent);

    final bossNode = MapNode(
      id: 'boss_lair',
      type: MapNodeType.bossLair,
      position: bossPos,
      label: 'ALTAR DO TITÃ // SINALIZADOR DE ANOMALIA',
      description: 'Carregue 2 Sinalizadores (Sub-Chefes ou POIs) para destrancar e invocar o Titã do Setor.',
      icon: Icons.warning_amber_rounded,
      primaryColor: const Color(0xFFFF1744),
      radius: 450.0,
      isDiscovered: false,
    );
    nodes.add(bossNode);

    // Quadrante 1: Estação Orbital de Pesquisa (Research Station)
    final stationQuadrant = quadrants[1];
    final stationPos = stationQuadrant +
        Vector2((random.nextDouble() - 0.5) * 300.0, (random.nextDouble() - 0.5) * 300.0);
    game.world.add(SpaceStationComponent(position: stationPos));

    nodes.add(
      MapNode(
        id: 'research_station',
        type: MapNodeType.station,
        position: stationPos,
        label: 'ESTAÇÃO ORBITAL DE PESQUISA',
        description: 'Permaneça na zona para baixar dados e telemetria científica.',
        icon: Icons.sensors_rounded,
        primaryColor: const Color(0xFF00E5FF),
        radius: 240.0,
        isDiscovered: false,
      ),
    );

    // Quadrantes 2 e 3: Cargueiros Abandonados (Derelict Cargo Wrecks)
    final wreckPositions = <Vector2>[
      quadrants[2] + Vector2((random.nextDouble() - 0.5) * 260.0, (random.nextDouble() - 0.5) * 260.0),
      quadrants[3] + Vector2((random.nextDouble() - 0.5) * 260.0, (random.nextDouble() - 0.5) * 260.0),
    ];

    for (var i = 0; i < wreckPositions.length; i++) {
      final pos = wreckPositions[i];
      game.world.add(CargoWreckComponent(position: pos));
      nodes.add(
        MapNode(
          id: 'cargo_wreck_$i',
          type: MapNodeType.cargoWreck,
          position: pos,
          label: 'DESTROÇOS DE CARGUEIRO // CAIXA DE SUCATA',
          description: 'Carcaça à deriva. Destrua para coletar baús e componentes.',
          icon: Icons.inventory_2_outlined,
          primaryColor: const Color(0xFFFFB300),
          isDiscovered: false,
        ),
      );
    }

    // 4. Perigos Ambientais Específicos do Setor
    switch (sector.id) {
      case SectorId.orion:
        final m1 = Vector2(2400 + (random.nextDouble() - 0.5) * 400.0, 2400 + (random.nextDouble() - 0.5) * 400.0);
        final m2 = Vector2(3800, 1800);
        game.world.add(MagmaHazardComponent(position: m1, radius: 240.0));
        game.world.add(MagmaHazardComponent(position: m2, radius: 200.0));
        nodes.add(MapNode(
          id: 'magma_hazard_1',
          type: MapNodeType.magmaHazard,
          position: m1,
          label: 'FISSURA DE MAGMA SOLAR',
          description: 'Radiação térmica extrema e erupções de plasma.',
          icon: Icons.whatshot,
          primaryColor: const Color(0xFFFF5722),
          isDiscovered: false,
        ));
        break;

      case SectorId.graveyard:
        final extraWreck = Vector2(1800, 3600);
        game.world.add(CargoWreckComponent(position: extraWreck));
        nodes.add(MapNode(
          id: 'cargo_wreck_extra',
          type: MapNodeType.cargoWreck,
          position: extraWreck,
          label: 'CARCAÇA DE ENCOURAÇADO ABANDONADA',
          description: 'Restos de guerra militar ricos em sucata pesada.',
          icon: Icons.token,
          primaryColor: const Color(0xFF00E676),
          isDiscovered: false,
        ));

        // Minas de Proximidade e Torretas Derelict do Cemitério de Dreadnoughts
        final mineCoords = [
          Vector2(1950, 2100),
          Vector2(2850, 2100),
          Vector2(2050, 2850),
          Vector2(2900, 2800),
        ];
        for (var i = 0; i < mineCoords.length; i++) {
          game.world.add(ProximityMineComponent(position: mineCoords[i]));
        }
        final turretCoords = [
          Vector2(1700, 3450),
          Vector2(3200, 1750),
        ];
        for (var i = 0; i < turretCoords.length; i++) {
          game.world.add(DerelictTurretComponent(position: turretCoords[i]));
          nodes.add(MapNode(
            id: 'derelict_turret_$i',
            type: MapNodeType.magmaHazard,
            position: turretCoords[i],
            label: 'TORRETA AUTOMÁTICA DERELICT',
            description: 'Defesa remanescente ativa. Destrua para obter sucata rara.',
            icon: Icons.gps_fixed_rounded,
            primaryColor: const Color(0xFF00E676),
            isDiscovered: false,
          ));
        }
        break;

      case SectorId.eventHorizon:
        final riftPos = Vector2(2400, 2000);
        final riftPos2 = Vector2(2800, 3000);
        game.world.add(SingularityRiftComponent(position: riftPos, pullRadius: 260.0));
        game.world.add(SingularityRiftComponent(position: riftPos2, pullRadius: 240.0));
        nodes.add(MapNode(
          id: 'singularity_rift',
          type: MapNodeType.singularityRift,
          position: riftPos,
          label: 'SINGULARIDADE GRAVITACIONAL PRIMÁRIA',
          description: 'Distorção no tecido espaço-tempo. Atrai tudo ao vórtice.',
          icon: Icons.cyclone,
          primaryColor: const Color(0xFFE040FB),
          isDiscovered: false,
        ));
        nodes.add(MapNode(
          id: 'singularity_rift_2',
          type: MapNodeType.singularityRift,
          position: riftPos2,
          label: 'ANOMALIA GRAVITACIONAL SECUNDÁRIA',
          description: 'Fenda quântica secundária de alta gravidade.',
          icon: Icons.cyclone,
          primaryColor: const Color(0xFFAA00FF),
          isDiscovered: false,
        ));
        break;

      case SectorId.vesta:
      default:
        break;
    }

    // 5. Nebulosas Cósmicas (Modificadores de Combate)
    final n1 = Vector2(3400, 3300);
    final n2 = Vector2(1400, 3200);
    game.world.add(CosmicNebulaComponent(position: n1, type: NebulaType.ionCloud, radius: 460.0));
    game.world.add(CosmicNebulaComponent(position: n2, type: NebulaType.darkMatter, radius: 460.0));

    nodes.add(MapNode(
      id: 'nebula_ion',
      type: MapNodeType.hazardNebula,
      position: n1,
      label: 'NEBULOSA IÔNICA (VELOCIDADE DE DISPARO +30%)',
      description: 'Nuvem ionizada que sobrecarrega capacitores de disparo.',
      icon: Icons.bolt,
      primaryColor: const Color(0xFF00E5FF),
      isDiscovered: false,
    ));

    // 6. Sprint 13: Arquitetura de Biomas estilo Dead Cells (Corredores de Megaestrutura, Portão Laser, Cofres & Mercador)
    // Corredores de Megaestrutura dividindo o setor em câmaras táticas (mantendo o centro de spawn 2400,2400 livre!)
    final walls = <(Vector2 pos, Vector2 size)>[
      (Vector2(1850, 1650), Vector2(320, 28)),
      (Vector2(2950, 1650), Vector2(320, 28)),
      (Vector2(1650, 2950), Vector2(28, 320)),
      (Vector2(3150, 2950), Vector2(28, 320)),
    ];
    for (final w in walls) {
      game.world.add(
        MegastructureWallComponent(
          position: w.$1,
          wallSize: w.$2,
          wallColor: sector.primaryColor,
        ),
      );
    }

    // Portão de Contenção Laser protegendo a Câmara do Cofre Cronometrado ao Norte
    final gatePos = Vector2(2400, 1520);
    game.world.add(
      LaserContainmentGateComponent(
        position: gatePos,
        length: 260.0,
        isHorizontal: true,
      ),
    );

    // Cofre Cronometrado (< 2m00s) estilo Dead Cells
    final timedVaultPos = Vector2(2400, 1180);
    game.world.add(TimedVaultComponent(position: timedVaultPos));
    nodes.add(
      MapNode(
        id: 'timed_vault',
        type: MapNodeType.timedVault,
        position: timedVaultPos,
        label: 'COFRE CRONOMETRADO (< 02:00)',
        description: 'Alcance antes de 2m00s para desbloquear Diagrama, Baú Dourado e +250c.',
        icon: Icons.timer_rounded,
        primaryColor: const Color(0xFFFFD700),
        isDiscovered: false,
      ),
    );

    // Cofre Intocável (Flawless Boss Vault)
    final flawlessPos = bossPos + Vector2(0, -290);
    game.world.add(FlawlessVaultComponent(position: flawlessPos));
    nodes.add(
      MapNode(
        id: 'flawless_vault',
        type: MapNodeType.flawlessVault,
        position: flawlessPos,
        label: 'CÂMARA INTOCÁVEL DO TITÃ',
        description: 'Derrote o Chefe Soberano sem sofrer dano para abrir este cofre lendário.',
        icon: Icons.workspace_premium_rounded,
        primaryColor: const Color(0xFF00E5FF),
        isDiscovered: false,
      ),
    );

    // Mercador Errante do Vazio (Void Merchant)
    final merchantPos = Vector2(1580, 2400);
    game.world.add(VoidMerchantComponent(position: merchantPos));
    nodes.add(
      MapNode(
        id: 'void_merchant',
        type: MapNodeType.voidMerchant,
        position: merchantPos,
        label: 'MERCADOR ERRANTE DO VAZIO',
        description: 'Troque Sucata por reparo imediato (+45 HP) e armamento tático.',
        icon: Icons.storefront_rounded,
        primaryColor: const Color(0xFFFFB300),
        isDiscovered: false,
      ),
    );

    // Santuário Amaldiçoado (Cursed Shrine)
    final shrinePos = Vector2(3220, 2400);
    game.world.add(CursedShrineComponent(position: shrinePos));
    nodes.add(
      MapNode(
        id: 'cursed_shrine',
        type: MapNodeType.cursedShrine,
        position: shrinePos,
        label: 'SANTUÁRIO AMALDIÇOADO DO VAZIO',
        description: 'Sacrifique 20% de HP atual para maximizar uma arma, ganhar +150c e carregar 1 Sinalizador.',
        icon: Icons.whatshot_rounded,
        primaryColor: const Color(0xFFE040FB),
        isDiscovered: false,
      ),
    );

    final mapData = SectorMapData(
      sector: sector,
      seed: seed,
      mapWidth: mapW,
      mapHeight: mapH,
      nodes: nodes,
      bossLairNode: bossNode,
    );

    // Revela imediatamente a célula de spawn inicial
    mapData.updateExploration(center, GameConstants.radarRange);

    game.sectorMap = mapData;
    return mapData;
  }
}
