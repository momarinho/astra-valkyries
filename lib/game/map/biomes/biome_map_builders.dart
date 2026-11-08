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
import 'package:asteroids/game/components/living_biomes.dart';
import 'package:asteroids/game/components/enemy_ship.dart';
import '../sector_map_data.dart';

/// Interface base dos Arquitetos Modulares de Bioma (Sprint 25).
abstract class BiomeMapArchitect {
  SectorId get sectorId;

  SectorMapData build(AsteroidsGame game, Sector sector, int seed) {
    final random = math.Random(seed);
    const mapW = GameConstants.sectorWidth;
    const mapH = GameConstants.sectorHeight;
    final center = Vector2(mapW / 2, mapH / 2);

    // 1. Adiciona Camada 0 e Camada 1: Backdrop Abissal & Sub-piso Fiel às Imagens Modelo
    game.world.add(BiomeBackdropComponent(sectorId: sector.id));

    final List<MapNode> nodes = [];

    // 2. Nó de Spawn da Jogadora
    nodes.add(
      MapNode(
        id: 'spawn_point',
        type: MapNodeType.playerSpawn,
        position: center.clone(),
        label: 'PONTO DE INSERÇÃO // ${sector.name.toUpperCase()}',
        description: 'Coordenadas seguras de inserção tática da Valquíria.',
        icon: Icons.navigation_rounded,
        primaryColor: sector.primaryColor,
        isDiscovered: true,
      ),
    );

    // 3. Slots Modulares de Canto/Extremidade (Sockets) sorteados por Seed
    final cornerSockets = getCornerSockets()..shuffle(random);
    final bossPos = _jitter(cornerSockets[0], random, 120.0);
    final relicPos = _jitter(cornerSockets[1], random, 90.0);
    final coffinPos = _jitter(cornerSockets[2], random, 90.0);
    final stationPos = _jitter(cornerSockets[3], random, 110.0);

    // 3A. Altar do Chefe + Cofre Intocável
    final bossLair = BossLairComponent(
      position: bossPos,
      requiresBeaconCharge: true,
    );
    game.world.add(bossLair);

    final bossNode = MapNode(
      id: 'boss_lair',
      type: MapNodeType.bossLair,
      position: bossPos,
      label: 'ALTAR DO TITÃ // ${sector.name.toUpperCase()}',
      description: 'Carregue 2 Sinalizadores para invocar o Titã Soberano deste bioma.',
      icon: Icons.warning_amber_rounded,
      primaryColor: const Color(0xFFFF1744),
      radius: 450.0,
      isDiscovered: false,
    );
    nodes.add(bossNode);

    final flawlessPos = (bossPos + Vector2(0, -290))
      ..x = (bossPos.x).clamp(450.0, mapW - 450.0)
      ..y = (bossPos.y - 290).clamp(450.0, mapH - 450.0);
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

    // 3B. Relíquia Permanente do Bioma (Sprint 26)
    final relicId = sector.relicId ?? 'yellow_sign';
    game.world.add(RelicPedestalComponent(position: relicPos, relicId: relicId));
    // Guardião de Elite protegendo a Relíquia
    game.world.add(
      EnemyShipComponent(
        position: relicPos + Vector2(85, 0),
        type: EnemyType.aegisBulwark,
      ),
    );
    nodes.add(
      MapNode(
        id: 'relic_pedestal',
        type: MapNodeType.relicPedestal,
        position: relicPos,
        label: 'RELÍQUIA OCULTA // ${sector.relicName.toUpperCase()}',
        description: 'Artefato permanente guardado nas coordenadas extremas do bioma.',
        icon: Icons.explore_rounded,
        primaryColor: const Color(0xFFFFD700),
        isDiscovered: false,
      ),
    );

    // 3C. Cápsula de Estase / Segredo do Bioma (Sprint 26 — Coffin)
    game.world.add(
      StasisCoffinComponent(
        position: coffinPos,
        sectorId: sector.id,
        secretTitle: sector.secretTitle,
      ),
    );
    game.world.add(
      EnemyShipComponent(
        position: coffinPos + Vector2(-85, 0),
        type: EnemyType.aegisBulwark,
      ),
    );
    nodes.add(
      MapNode(
        id: 'stasis_coffin',
        type: MapNodeType.stasisCoffin,
        position: coffinPos,
        label: 'SEGREDO DO BIOMA // ${sector.secretTitle.toUpperCase()}',
        description: 'Rompa a contenção ou aproxime-se para resgatar o segredo ancestral.',
        icon: Icons.lock_open_rounded,
        primaryColor: const Color(0xFF00E5FF),
        isDiscovered: false,
      ),
    );

    // 3D. Estação Orbital de Pesquisa
    game.world.add(SpaceStationComponent(position: stationPos));
    nodes.add(
      MapNode(
        id: 'research_station',
        type: MapNodeType.station,
        position: stationPos,
        label: 'ESTAÇÃO ORBITAL DE PESQUISA',
        description: 'Permaneça na zona para baixar telemetria científica e carregar 1 Sinalizador.',
        icon: Icons.sensors_rounded,
        primaryColor: const Color(0xFF00E5FF),
        radius: 240.0,
        isDiscovered: false,
      ),
    );

    // 4. Cargueiros Abandonados (Caixas Pretas)
    final wreckPositions = [
      Vector2(1750 + random.nextDouble() * 200, 3250 + random.nextDouble() * 200),
      Vector2(3050 - random.nextDouble() * 200, 1550 + random.nextDouble() * 200),
    ];
    for (var i = 0; i < wreckPositions.length; i++) {
      final pos = wreckPositions[i];
      game.world.add(CargoWreckComponent(position: pos));
      nodes.add(
        MapNode(
          id: 'cargo_wreck_$i',
          type: MapNodeType.cargoWreck,
          position: pos,
          label: 'DESTROÇOS DE CARGUEIRO // CAIXA PRETA',
          description: 'Carcaça à deriva. Destrua para extrair Sucata e Gravações de Voo.',
          icon: Icons.inventory_2_outlined,
          primaryColor: const Color(0xFFFFB300),
          isDiscovered: false,
        ),
      );
    }

    // 5. Nebulosas Cósmicas Dinâmicas (Sprint 20)
    final n1 = Vector2(3350, 3250);
    final n2 = Vector2(1450, 3150);
    game.world.add(CosmicNebulaComponent(position: n1, type: NebulaType.ionCloud, radius: 420.0));
    game.world.add(CosmicNebulaComponent(position: n2, type: NebulaType.darkMatter, radius: 420.0));
    nodes.add(
      MapNode(
        id: 'nebula_ion',
        type: MapNodeType.hazardNebula,
        position: n1,
        label: 'NEBULOSA IÔNICA (CADÊNCIA +30% // RISCO TÉRMICO)',
        description: 'Aumenta cadência, mas sobrecarrega o casco após 6s contínuos.',
        icon: Icons.bolt,
        primaryColor: const Color(0xFF00E5FF),
        isDiscovered: false,
      ),
    );

    // 6. Cofre Cronometrado (< 02:00), Mercador Errante e Santuário Amaldiçoado
    final gatePos = Vector2(2400, 1520);
    game.world.add(
      LaserContainmentGateComponent(
        position: gatePos,
        length: 260.0,
        isHorizontal: true,
      ),
    );

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

    final merchantPos = getMerchantPosition();
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

    // 7. Geometria Exclusiva do Bioma (Paredes, Câmaras e Perigos da Imagem Modelo)
    buildBiomeSpecificGeometry(game, sector, random, nodes);

    return SectorMapData(
      sector: sector,
      seed: seed,
      mapWidth: mapW,
      mapHeight: mapH,
      nodes: nodes,
      bossLairNode: bossNode,
    )..updateExploration(center, GameConstants.radarRange);
  }

  List<Vector2> getCornerSockets() => [
        Vector2(950, 950),   // Extremo Noroeste
        Vector2(3850, 950),  // Extremo Nordeste
        Vector2(950, 3850),  // Extremo Sudoeste
        Vector2(3850, 3850), // Extremo Sudeste
      ];

  Vector2 getMerchantPosition() => Vector2(1580, 2400);

  void buildBiomeSpecificGeometry(
    AsteroidsGame game,
    Sector sector,
    math.Random random,
    List<MapNode> nodes,
  );

  Vector2 _jitter(Vector2 base, math.Random rng, double range) {
    return Vector2(
      (base.x + (rng.nextDouble() - 0.5) * range).clamp(520.0, GameConstants.sectorWidth - 520.0),
      (base.y + (rng.nextDouble() - 0.5) * range).clamp(520.0, GameConstants.sectorHeight - 520.0),
    );
  }
}

/// 1. BIOMA 1: Cinturão de Mineração de Vesta (2 Anéis Concêntricos + Docas Laterais)
class VestaBeltMapBuilder extends BiomeMapArchitect {
  @override
  SectorId get sectorId => SectorId.vesta;

  @override
  void buildBiomeSpecificGeometry(
    AsteroidsGame game,
    Sector sector,
    math.Random random,
    List<MapNode> nodes,
  ) {
    // Vigas do Anel Interno de Mineração (mantendo o centro 2400,2400 livre)
    final ringWalls = <(Vector2 pos, Vector2 size)>[
      (Vector2(1850, 1750), Vector2(300, 28)),
      (Vector2(2950, 1750), Vector2(300, 28)),
      (Vector2(1750, 2950), Vector2(28, 300)),
      (Vector2(3050, 2950), Vector2(28, 300)),
      // Docas Industriais Oeste e Leste (como na Imagem Modelo 1)
      (Vector2(720, 2150), Vector2(340, 30)),
      (Vector2(720, 2650), Vector2(340, 30)),
      (Vector2(4080, 2150), Vector2(340, 30)),
      (Vector2(4080, 2650), Vector2(340, 30)),
    ];
    for (final w in ringWalls) {
      game.world.add(
        MegastructureWallComponent(
          position: w.$1,
          wallSize: w.$2,
          wallColor: const Color(0xFF00E5FF),
        ),
      );
    }
  }
}

/// 2. BIOMA 2A: Forja Solar de Hélio (Duas Asas Industriais + 5 Pontes Solares + Jatos de Fogo)
class HeliosForgeMapBuilder extends BiomeMapArchitect {
  @override
  SectorId get sectorId => SectorId.orion;

  @override
  void buildBiomeSpecificGeometry(
    AsteroidsGame game,
    Sector sector,
    math.Random random,
    List<MapNode> nodes,
  ) {
    // Muralhas da Refinaria Horizontal (Asa Oeste da Fornalha & Asa Leste de Fundição)
    final forgeWalls = <(Vector2 pos, Vector2 size)>[
      (Vector2(1550, 1380), Vector2(680, 34)),
      (Vector2(1550, 3420), Vector2(680, 34)),
      (Vector2(3250, 1380), Vector2(680, 34)),
      (Vector2(3250, 3420), Vector2(680, 34)),
      (Vector2(1180, 2000), Vector2(34, 420)),
      (Vector2(3620, 2800), Vector2(34, 420)),
    ];
    for (final w in forgeWalls) {
      game.world.add(
        MegastructureWallComponent(
          position: w.$1,
          wallSize: w.$2,
          wallColor: const Color(0xFFFF9100),
        ),
      );
    }

    // Jatos de Propulsão Solar (SolarFlameJetComponent) da Imagem Modelo 2A
    final jets = <(Vector2 pos, double angle)>[
      (Vector2(3520, 2150), math.pi),
      (Vector2(3520, 2650), math.pi),
      (Vector2(1450, 3360), math.pi / 2),
    ];
    for (final j in jets) {
      game.world.add(
        SolarFlameJetComponent(
          position: j.$1,
          jetAngle: j.$2,
          jetLength: 260.0,
        ),
      );
    }

    // Fissuras de Magma Solar
    final m1 = Vector2(1420, 2400);
    final m2 = Vector2(3380, 1750);
    game.world.add(MagmaHazardComponent(position: m1, radius: 220.0));
    game.world.add(MagmaHazardComponent(position: m2, radius: 200.0));
    nodes.add(
      MapNode(
        id: 'magma_hazard_1',
        type: MapNodeType.magmaHazard,
        position: m1,
        label: 'FORNALHA OCTOGONAL DE PLASMA',
        description: 'Núcleo térmico da refinaria solar de Hélio.',
        icon: Icons.whatshot,
        primaryColor: const Color(0xFFFF5722),
        isDiscovered: false,
      ),
    );
  }
}

/// 3. BIOMA 2B: Abismo Criogênico de Caelum (Domo Térmico Central + Labirinto de Gelo)
class CryoAbyssMapBuilder extends BiomeMapArchitect {
  @override
  SectorId get sectorId => SectorId.cryoAbyss;

  @override
  Vector2 getMerchantPosition() => Vector2(2260, 2400); // Abrigado dentro do Domo Térmico Central!

  @override
  void buildBiomeSpecificGeometry(
    AsteroidsGame game,
    Sector sector,
    math.Random random,
    List<MapNode> nodes,
  ) {
    // 1. Domo Térmico Dourado no Centro Exato (2400, 2400) — igual à Imagem Modelo 2B!
    game.world.add(
      ThermalDomeComponent(
        position: Vector2(2400, 2400),
        radius: 320.0,
      ),
    );

    // 2. Paredes de Gelo Cristalino formando o Labirinto Glacial ao redor do Domo
    final iceWalls = <(Vector2 pos, Vector2 size)>[
      (Vector2(1720, 1950), Vector2(340, 30)),
      (Vector2(3080, 1950), Vector2(340, 30)),
      (Vector2(1720, 2850), Vector2(340, 30)),
      (Vector2(3080, 2850), Vector2(340, 30)),
      (Vector2(1420, 2400), Vector2(30, 480)),
      (Vector2(3380, 2400), Vector2(30, 480)),
    ];
    for (final w in iceWalls) {
      game.world.add(
        MegastructureWallComponent(
          position: w.$1,
          wallSize: w.$2,
          wallColor: const Color(0xFF80D8FF),
        ),
      );
    }

    // 3. Zonas de Neblina Criogênica e Minas Estelares de Gelo nas alas laterais
    game.world.add(CryoMistZoneComponent(position: Vector2(1180, 2400), radius: 380.0));
    game.world.add(CryoMistZoneComponent(position: Vector2(3620, 2400), radius: 380.0));

    final cryoMineCoords = [
      Vector2(1880, 2320),
      Vector2(1880, 2480),
      Vector2(2920, 2320),
      Vector2(2920, 2480),
      Vector2(2320, 1880),
      Vector2(2480, 2920),
    ];
    for (final pos in cryoMineCoords) {
      game.world.add(CryoMineComponent(position: pos));
    }
  }
}

/// 4. BIOMA 3A: Cemitério da Frota Aegis (Cascos de Encouraçados + Vazamento Esmeralda)
class AegisGraveyardMapBuilder extends BiomeMapArchitect {
  @override
  SectorId get sectorId => SectorId.graveyard;

  @override
  void buildBiomeSpecificGeometry(
    AsteroidsGame game,
    Sector sector,
    math.Random random,
    List<MapNode> nodes,
  ) {
    // Paredes dos Cascos Rasgados de Encouraçados (Casco Oeste e Casco Leste)
    final hullWalls = <(Vector2 pos, Vector2 size)>[
      (Vector2(1450, 1550), Vector2(560, 32)),
      (Vector2(1450, 3250), Vector2(560, 32)),
      (Vector2(1150, 2400), Vector2(32, 900)),
      (Vector2(3350, 1550), Vector2(560, 32)),
      (Vector2(3350, 3250), Vector2(560, 32)),
      (Vector2(3650, 2400), Vector2(32, 900)),
    ];
    for (final w in hullWalls) {
      game.world.add(
        MegastructureWallComponent(
          position: w.$1,
          wallSize: w.$2,
          wallColor: const Color(0xFF00E676),
        ),
      );
    }

    // Rio de Radiação Esmeralda no Casco Oeste (ReactorLeakHazardComponent)
    game.world.add(ReactorLeakHazardComponent(position: Vector2(1450, 2050), radius: 190.0));
    game.world.add(ReactorLeakHazardComponent(position: Vector2(1450, 2750), radius: 190.0));

    // Minas Magnéticas no Pátio Central e Torretas Derelict no Casco Leste
    for (final m in [
      Vector2(2150, 2150),
      Vector2(2650, 2150),
      Vector2(2150, 2650),
      Vector2(2650, 2650),
    ]) {
      game.world.add(ProximityMineComponent(position: m));
    }

    for (final t in [Vector2(3350, 1950), Vector2(3350, 2850)]) {
      game.world.add(DerelictTurretComponent(position: t));
    }
  }
}

/// 5. BIOMA 3B: Colmeia Xeno-Biológica de Nêmesis (Zero Metal — 100% Paredes Orgânicas & Alcobas)
class XenoHiveMapBuilder extends BiomeMapArchitect {
  @override
  SectorId get sectorId => SectorId.xenoHive;

  @override
  List<Vector2> getCornerSockets() => [
        Vector2(1150, 1250), // Alcova Noroeste
        Vector2(3650, 1250), // Alcova Nordeste
        Vector2(1150, 3550), // Alcova Sudoeste
        Vector2(3650, 3550), // Alcova Sudeste
      ];

  @override
  void buildBiomeSpecificGeometry(
    AsteroidsGame game,
    Sector sector,
    math.Random random,
    List<MapNode> nodes,
  ) {
    // Câmaras Celulares feitas 100% de Paredes de Biomassa Viva Regenerativa
    final bioWalls = <(Vector2 pos, Vector2 size)>[
      (Vector2(1950, 1850), Vector2(320, 34)),
      (Vector2(2850, 1850), Vector2(320, 34)),
      (Vector2(1950, 2950), Vector2(320, 34)),
      (Vector2(2850, 2950), Vector2(320, 34)),
      (Vector2(1650, 2400), Vector2(34, 380)),
      (Vector2(3150, 2400), Vector2(34, 380)),
    ];
    for (final bw in bioWalls) {
      game.world.add(
        OrganicBiomassWallComponent(
          position: bw.$1,
          wallSize: bw.$2,
        ),
      );
    }

    // Ninhos de Casulos Xeno e Poças de Ácido Bio-Corrosivo nas Alcobas
    for (final c in [
      Vector2(1350, 1550),
      Vector2(3450, 1550),
      Vector2(1350, 3250),
      Vector2(3450, 3250),
      Vector2(2050, 2250),
      Vector2(2750, 2550),
    ]) {
      game.world.add(XenoCocoonComponent(position: c));
    }

    game.world.add(AcidPoolHazardComponent(position: Vector2(1450, 2400), radius: 165.0));
    game.world.add(AcidPoolHazardComponent(position: Vector2(3350, 2400), radius: 165.0));
  }
}

/// 6. BIOMA 4 & 5: Horizonte de Eventos & O Trono do Vazio (Catedral Astrolábio Circular)
class VoidThroneMapBuilder extends BiomeMapArchitect {
  @override
  final SectorId sectorId;

  VoidThroneMapBuilder({this.sectorId = SectorId.voidThrone});

  @override
  void buildBiomeSpecificGeometry(
    AsteroidsGame game,
    Sector sector,
    math.Random random,
    List<MapNode> nodes,
  ) {
    // Colunatas Monolíticas de Obsidiana e Ouro Branco ao redor do Astrolábio
    final monoliths = <(Vector2 pos, Vector2 size)>[
      (Vector2(1750, 1750), Vector2(280, 30)),
      (Vector2(3050, 1750), Vector2(280, 30)),
      (Vector2(1750, 3050), Vector2(280, 30)),
      (Vector2(3050, 3050), Vector2(280, 30)),
    ];
    for (final m in monoliths) {
      game.world.add(
        MegastructureWallComponent(
          position: m.$1,
          wallSize: m.$2,
          wallColor: const Color(0xFFFFD700),
        ),
      );
    }

    // 4 Fendas/Piras Gravitacionais dos Arquitetos nos pontos diagonais do Astrolábio
    for (final riftPos in [
      Vector2(1950, 1950),
      Vector2(2850, 1950),
      Vector2(1950, 2850),
      Vector2(2850, 2850),
    ]) {
      game.world.add(
        SingularityRiftComponent(
          position: riftPos,
          pullRadius: 160.0,
          duration: 0.8,
        ),
      );
    }
  }
}
