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
import 'package:asteroids/game/components/breakable_prop.dart';
import 'package:asteroids/game/components/indoor_environment.dart';
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

    // 8. Objetos Quebráveis do Cenário (Sprint 29 — Estilo Vampire Survivors: Barris, Cristais, Cargas)
    _spawnBreakableProps(game, sector, random, nodes);

    // 9. Câmaras de Quarentena Indoor (Sprint 30 — Hangar Fechado, Portas Blindadas & Combate Confinado)
    _spawnLockdownChamber(game, sector, random, nodes);

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

  /// Verifica se uma posição está a uma distância segura de todos os POIs e do Ponto de Spawn (2400, 2400).
  bool isClearOfPois(Vector2 pos, List<MapNode> nodes, [double minDistance = 280.0]) {
    // Spawn seguro: raio de 520px ao redor do centro 2400,2400
    if (pos.distanceTo(Vector2(2400, 2400)) < 520.0) return false;
    for (final node in nodes) {
      if (pos.distanceTo(node.position) < minDistance) return false;
    }
    return true;
  }

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

  void _spawnBreakableProps(
    AsteroidsGame game,
    Sector sector,
    math.Random random,
    List<MapNode> nodes,
  ) {
    const mapW = GameConstants.sectorWidth;
    const mapH = GameConstants.sectorHeight;

    // Distribuição de Props Destrutíveis estilo Vampire Survivors
    // Veios de Minério Cristalino (Stardust + Moedas)
    for (int i = 0; i < 12; i++) {
      final pos = Vector2(
        600.0 + random.nextDouble() * (mapW - 1200.0),
        600.0 + random.nextDouble() * (mapH - 1200.0),
      );
      if (isClearOfPois(pos, nodes, 180.0)) {
        game.world.add(
          BreakablePropComponent(
            position: pos,
            type: BreakablePropType.oreCrystal,
          ),
        );
      }
    }

    // Barris Explosivos (Dano em Área e Reação em Cadeia)
    for (int i = 0; i < 8; i++) {
      final pos = Vector2(
        650.0 + random.nextDouble() * (mapW - 1300.0),
        650.0 + random.nextDouble() * (mapH - 1300.0),
      );
      if (isClearOfPois(pos, nodes, 180.0)) {
        game.world.add(
          BreakablePropComponent(
            position: pos,
            type: BreakablePropType.explosiveBarrel,
          ),
        );
      }
    }

    // Contêineres de Carga Abandonados (Reparos de Casco e Escudos)
    for (int i = 0; i < 5; i++) {
      final pos = Vector2(
        700.0 + random.nextDouble() * (mapW - 1400.0),
        700.0 + random.nextDouble() * (mapH - 1400.0),
      );
      if (isClearOfPois(pos, nodes, 180.0)) {
        game.world.add(
          BreakablePropComponent(
            position: pos,
            type: BreakablePropType.cargoCrate,
          ),
        );
      }
    }

    // Células de Fusão (EMP Nova)
    for (int i = 0; i < 3; i++) {
      final pos = Vector2(
        750.0 + random.nextDouble() * (mapW - 1500.0),
        750.0 + random.nextDouble() * (mapH - 1500.0),
      );
      if (isClearOfPois(pos, nodes, 180.0)) {
        game.world.add(
          BreakablePropComponent(
            position: pos,
            type: BreakablePropType.fusionCell,
          ),
        );
      }
    }
  }

  void _spawnLockdownChamber(
    AsteroidsGame game,
    Sector sector,
    math.Random random,
    List<MapNode> nodes,
  ) {
    // Escolhe uma posição estratégica nos quadrantes industriais afastados do centro
    final chamberPositions = [
      Vector2(3250, 1650),
      Vector2(1550, 3150),
      Vector2(3250, 3150),
      Vector2(1550, 1650),
    ]..shuffle(random);

    for (final pos in chamberPositions) {
      if (isClearOfPois(pos, nodes, 450.0)) {
        final chamber = LockdownChamberComponent(
          position: pos,
          chamberSize: Vector2(760.0, 700.0),
          chamberName: 'COMPLEXO DE CONTENÇÃO // ${sector.name.toUpperCase()}',
        );
        game.world.add(chamber);
        nodes.add(
          MapNode(
            id: 'lockdown_chamber',
            type: MapNodeType.lockdownChamber,
            position: pos,
            label: 'CÂMARA DE QUARENTENA // ${sector.name.toUpperCase()}',
            description: 'Entre para ativar o protocolo de contenção, eliminar a horda e desbloquear o Baú Dourado.',
            icon: Icons.shield_outlined,
            primaryColor: const Color(0xFF00E676),
            isDiscovered: false,
          ),
        );
        break;
      }
    }
  }
}

/// 1. BIOMA 1: Cinturão de Mineração de Vesta (Cordilheiras de Asteroides e Docas Industriais Procedurais)
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
    // Cordilheiras de Asteroides Procedurais por Seed:
    // 4 braços de cordilheira radial que subdividem os quadrantes em desfiladeiros cósmicos
    final angles = [math.pi / 4, 3 * math.pi / 4, 5 * math.pi / 4, 7 * math.pi / 4];
    final center = Vector2(2400, 2400);

    for (var i = 0; i < angles.length; i++) {
      final baseAngle = angles[i] + (random.nextDouble() - 0.5) * 0.35;
      final distSteps = [850.0, 1380.0, 1880.0];

      for (var d = 0; d < distSteps.length; d++) {
        final dist = distSteps[d] + (random.nextDouble() - 0.5) * 120.0;
        final pos = center + Vector2(math.cos(baseAngle) * dist, math.sin(baseAngle) * dist);

        if (!isClearOfPois(pos, nodes, 320.0)) continue;

        final isHoriz = (i + d) % 2 == 0;
        final wallLength = 260.0 + random.nextDouble() * 160.0;
        final wallThick = 28.0 + random.nextDouble() * 8.0;
        final wallSize = isHoriz ? Vector2(wallLength, wallThick) : Vector2(wallThick, wallLength);

        game.world.add(
          MegastructureWallComponent(
            position: pos,
            wallSize: wallSize,
            wallColor: const Color(0xFF00E5FF),
          ),
        );
      }
    }

    // Docas Industriais Periféricas com Variação por Seed
    final dockOffsets = [
      Vector2(750 + (random.nextDouble() - 0.5) * 100, 2150 + (random.nextDouble() - 0.5) * 100),
      Vector2(750 + (random.nextDouble() - 0.5) * 100, 2650 + (random.nextDouble() - 0.5) * 100),
      Vector2(4050 + (random.nextDouble() - 0.5) * 100, 2150 + (random.nextDouble() - 0.5) * 100),
      Vector2(4050 + (random.nextDouble() - 0.5) * 100, 2650 + (random.nextDouble() - 0.5) * 100),
    ];
    for (final dp in dockOffsets) {
      if (isClearOfPois(dp, nodes, 260.0)) {
        game.world.add(
          MegastructureWallComponent(
            position: dp,
            wallSize: Vector2(320 + random.nextDouble() * 60, 30),
            wallColor: const Color(0xFF00E5FF),
          ),
        );
      }
    }
  }
}

/// 2. BIOMA 2A: Forja Solar de Hélio (Grande Corredor Horizontal Estilo Inlaid Library + Fornalhas)
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
    // 1. Piso Industrial Contínuo da Refinaria Solar (Corredor Horizontal estilo Inlaid Library)
    game.world.add(
      ModularFloorComponent(
        position: Vector2(2400, 2400),
        size: Vector2(3300, 1360),
        floorAccent: const Color(0xFFFF9100),
      ),
    );

    // 2. Muralhas de Contenção Superior (Teto a y=1720) e Inferior (Chão a y=3080)
    final corridorWalls = [
      // Paredes Superiores (Teto)
      (Vector2(1450, 1720), Vector2(750, 34)),
      (Vector2(2400, 1720), Vector2(650, 34)),
      (Vector2(3350, 1720), Vector2(750, 34)),
      // Paredes Inferiores (Chão)
      (Vector2(1450, 3080), Vector2(750, 34)),
      (Vector2(2400, 3080), Vector2(650, 34)),
      (Vector2(3350, 3080), Vector2(750, 34)),
    ];
    for (final w in corridorWalls) {
      if (isClearOfPois(w.$1, nodes, 280.0)) {
        game.world.add(
          MegastructureWallComponent(
            position: w.$1,
            wallSize: w.$2,
            wallColor: const Color(0xFFFF9100),
          ),
        );
      }
    }

    // 3. Muralhas da Refinaria e Condutores de Plasma Procedurais
    final conduitBases = [
      (Vector2(1550, 1380), Vector2(620, 34)),
      (Vector2(1550, 3420), Vector2(620, 34)),
      (Vector2(3250, 1380), Vector2(620, 34)),
      (Vector2(3250, 3420), Vector2(620, 34)),
      (Vector2(1180, 2000), Vector2(34, 420)),
      (Vector2(3620, 2800), Vector2(34, 420)),
    ];

    for (final c in conduitBases) {
      final pos = _jitter(c.$1, random, 80.0);
      if (isClearOfPois(pos, nodes, 280.0)) {
        game.world.add(
          MegastructureWallComponent(
            position: pos,
            wallSize: c.$2,
            wallColor: const Color(0xFFFF9100),
          ),
        );
      }
    }

    // 2. Jatos de Propulsão Solar Procedurais nos Ângulos da Usina
    final jetPlacements = [
      (Vector2(3520, 2150), math.pi),
      (Vector2(3520, 2650), math.pi),
      (Vector2(1450, 3360), math.pi / 2),
      (Vector2(1280, 1450), 0.0),
      (Vector2(2400, 1150), math.pi / 2),
    ];
    for (final j in jetPlacements) {
      final jPos = _jitter(j.$1, random, 90.0);
      if (isClearOfPois(jPos, nodes, 240.0)) {
        game.world.add(
          SolarFlameJetComponent(
            position: jPos,
            jetAngle: j.$2,
            jetLength: 260.0 + random.nextDouble() * 60.0,
          ),
        );
      }
    }

    // 3. Fornalhas e Fissuras de Magma Solar Procedurais
    final magmaSpawns = [
      Vector2(1420, 2400),
      Vector2(3380, 1750),
      Vector2(2400, 3250),
    ];
    var magmaId = 1;
    for (final m in magmaSpawns) {
      final mPos = _jitter(m, random, 90.0);
      if (isClearOfPois(mPos, nodes, 260.0)) {
        final radius = 180.0 + random.nextDouble() * 60.0;
        game.world.add(MagmaHazardComponent(position: mPos, radius: radius));
        nodes.add(
          MapNode(
            id: 'magma_hazard_$magmaId',
            type: MapNodeType.magmaHazard,
            position: mPos,
            label: 'FORNALHA DE PLASMA #$magmaId',
            description: 'Núcleo térmico da refinaria solar de Hélio.',
            icon: Icons.whatshot,
            primaryColor: const Color(0xFFFF5722),
            isDiscovered: false,
          ),
        );
        magmaId++;
      }
    }
  }
}

/// 3. BIOMA 2B: Abismo Criogênico de Caelum (Grande Abismo Vertical Estilo Gallo Tower + Domo Térmico)
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
    // 1. Piso Glacial do Grande Abismo Vertical (Corredor Vertical estilo Gallo Tower)
    game.world.add(
      ModularFloorComponent(
        position: Vector2(2400, 2400),
        size: Vector2(1740, 3300),
        floorAccent: const Color(0xFF00E5FF),
      ),
    );

    // 2. Domo Térmico Dourado no Centro Exato (2400, 2400) — refúgio seguro de calor
    game.world.add(
      ThermalDomeComponent(
        position: Vector2(2400, 2400),
        radius: 320.0,
      ),
    );

    // 3. Paredes Glaciais Verticais Contínuas nas Bordas (Oeste a x=1530 e Leste a x=3270)
    final chasmWalls = [
      (Vector2(1530, 1450), Vector2(34, 750)),
      (Vector2(1530, 2400), Vector2(34, 650)),
      (Vector2(1530, 3350), Vector2(34, 750)),
      (Vector2(3270, 1450), Vector2(34, 750)),
      (Vector2(3270, 2400), Vector2(34, 650)),
      (Vector2(3270, 3350), Vector2(34, 750)),
    ];
    for (final w in chasmWalls) {
      if (isClearOfPois(w.$1, nodes, 280.0)) {
        game.world.add(
          MegastructureWallComponent(
            position: w.$1,
            wallSize: w.$2,
            wallColor: const Color(0xFF80D8FF),
          ),
        );
      }
    }

    // 4. Paredes de Gelo Cristalino formando Labirinto Glacial Procedural por Seed
    final iceWallBases = [
      (Vector2(1720, 1950), Vector2(340, 30)),
      (Vector2(3080, 1950), Vector2(340, 30)),
      (Vector2(1720, 2850), Vector2(340, 30)),
      (Vector2(3080, 2850), Vector2(340, 30)),
      (Vector2(2400, 1650), Vector2(400, 30)),
      (Vector2(2400, 3150), Vector2(400, 30)),
    ];
    for (final w in iceWallBases) {
      final pos = _jitter(w.$1, random, 80.0);
      if (isClearOfPois(pos, nodes, 280.0)) {
        game.world.add(
          MegastructureWallComponent(
            position: pos,
            wallSize: w.$2,
            wallColor: const Color(0xFF80D8FF),
          ),
        );
      }
    }

    // 3. Zonas de Neblina Criogênica e Minas Estelares de Gelo nas alas laterais
    final mistSpawns = [
      Vector2(1180, 2400),
      Vector2(3620, 2400),
      Vector2(2400, 1220),
    ];
    for (final m in mistSpawns) {
      final mPos = _jitter(m, random, 80.0);
      if (isClearOfPois(mPos, nodes, 260.0)) {
        game.world.add(CryoMistZoneComponent(position: mPos, radius: 340.0 + random.nextDouble() * 60.0));
      }
    }

    final cryoMineCoords = [
      Vector2(1880, 2320),
      Vector2(1880, 2480),
      Vector2(2920, 2320),
      Vector2(2920, 2480),
      Vector2(2320, 1880),
      Vector2(2480, 2920),
    ];
    for (final pos in cryoMineCoords) {
      final mPos = _jitter(pos, random, 60.0);
      if (isClearOfPois(mPos, nodes, 180.0)) {
        game.world.add(CryoMineComponent(position: mPos));
      }
    }
  }
}

/// 4. BIOMA 3A: Cemitério da Frota Aegis (Cascos de Encouraçados + Corredores Procedurais)
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
    // Pisos Industriais Internos dos Encouraçados (Interior Indoor)
    game.world.add(
      ModularFloorComponent(
        position: Vector2(1380, 2400),
        size: Vector2(580, 1150),
        floorAccent: const Color(0xFF00E676),
      ),
    );
    game.world.add(
      ModularFloorComponent(
        position: Vector2(3420, 2400),
        size: Vector2(580, 1150),
        floorAccent: const Color(0xFF00E676),
      ),
    );

    // Cascos Rasgados de Encouraçados Gerados Proceduralmente por Seed
    final hullWalls = [
      (Vector2(1450, 1550), Vector2(560, 32)),
      (Vector2(1450, 3250), Vector2(560, 32)),
      (Vector2(1150, 2400), Vector2(32, 840)),
      (Vector2(3350, 1550), Vector2(560, 32)),
      (Vector2(3350, 3250), Vector2(560, 32)),
      (Vector2(3650, 2400), Vector2(32, 840)),
      (Vector2(2400, 1420), Vector2(440, 32)),
      (Vector2(2400, 3380), Vector2(440, 32)),
    ];
    for (final w in hullWalls) {
      final pos = _jitter(w.$1, random, 80.0);
      if (isClearOfPois(pos, nodes, 280.0)) {
        game.world.add(
          MegastructureWallComponent(
            position: pos,
            wallSize: w.$2,
            wallColor: const Color(0xFF00E676),
          ),
        );
      }
    }

    // Rio de Radiação Esmeralda (ReactorLeakHazardComponent)
    for (final leakBase in [Vector2(1450, 2050), Vector2(1450, 2750), Vector2(3350, 2400)]) {
      final lPos = _jitter(leakBase, random, 70.0);
      if (isClearOfPois(lPos, nodes, 240.0)) {
        game.world.add(ReactorLeakHazardComponent(position: lPos, radius: 190.0));
      }
    }

    // Minas Magnéticas e Torretas Derelict
    for (final m in [
      Vector2(2150, 2150),
      Vector2(2650, 2150),
      Vector2(2150, 2650),
      Vector2(2650, 2650),
    ]) {
      final mPos = _jitter(m, random, 40.0);
      game.world.add(ProximityMineComponent(position: mPos));
    }

    for (final t in [Vector2(3350, 1950), Vector2(3350, 2850)]) {
      final tPos = _jitter(t, random, 40.0);
      game.world.add(DerelictTurretComponent(position: tPos));
    }
  }
}

/// 5. BIOMA 3B: Colmeia Xeno-Biológica de Nêmesis (Paredes Orgânicas Regenerativas & Alcobas)
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
    // Câmaras Celulares de Biomassa Viva Regenerativa Procedurais
    final bioWalls = [
      (Vector2(1950, 1850), Vector2(320, 34)),
      (Vector2(2850, 1850), Vector2(320, 34)),
      (Vector2(1950, 2950), Vector2(320, 34)),
      (Vector2(2850, 2950), Vector2(320, 34)),
      (Vector2(1650, 2400), Vector2(34, 380)),
      (Vector2(3150, 2400), Vector2(34, 380)),
      (Vector2(2400, 1550), Vector2(360, 34)),
      (Vector2(2400, 3250), Vector2(360, 34)),
    ];
    for (final bw in bioWalls) {
      final pos = _jitter(bw.$1, random, 70.0);
      if (isClearOfPois(pos, nodes, 280.0)) {
        game.world.add(
          OrganicBiomassWallComponent(
            position: pos,
            wallSize: bw.$2,
          ),
        );
      }
    }

    // Casulos Xeno e Poças de Ácido Bio-Corrosivo
    final cocoonPositions = [
      Vector2(1350, 1550),
      Vector2(3450, 1550),
      Vector2(1350, 3250),
      Vector2(3450, 3250),
      Vector2(2050, 2250),
      Vector2(2750, 2550),
    ];
    for (final c in cocoonPositions) {
      final cPos = _jitter(c, random, 80.0);
      if (isClearOfPois(cPos, nodes, 180.0)) {
        game.world.add(XenoCocoonComponent(position: cPos));
      }
    }

    for (final poolBase in [Vector2(1450, 2400), Vector2(3350, 2400)]) {
      final pPos = _jitter(poolBase, random, 70.0);
      if (isClearOfPois(pPos, nodes, 240.0)) {
        game.world.add(AcidPoolHazardComponent(position: pPos, radius: 165.0));
      }
    }
  }
}

/// 6. BIOMA 4 & 5: Horizonte de Eventos & O Trono do Vazio (Catedral Astrolábio Circular Procedural)
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
    // Colunatas Monolíticas de Obsidiana e Ouro Branco em Padrão Harmônico
    final monolithBases = [
      (Vector2(1750, 1750), Vector2(280, 30)),
      (Vector2(3050, 1750), Vector2(280, 30)),
      (Vector2(1750, 3050), Vector2(280, 30)),
      (Vector2(3050, 3050), Vector2(280, 30)),
      (Vector2(2400, 1500), Vector2(340, 30)),
      (Vector2(2400, 3300), Vector2(340, 30)),
    ];
    for (final m in monolithBases) {
      final pos = _jitter(m.$1, random, 60.0);
      if (isClearOfPois(pos, nodes, 280.0)) {
        game.world.add(
          MegastructureWallComponent(
            position: pos,
            wallSize: m.$2,
            wallColor: const Color(0xFFFFD700),
          ),
        );
      }
    }

    // Fendas/Piras Gravitacionais dos Arquitetos
    for (final riftBase in [
      Vector2(1950, 1950),
      Vector2(2850, 1950),
      Vector2(1950, 2850),
      Vector2(2850, 2850),
    ]) {
      final rPos = _jitter(riftBase, random, 60.0);
      if (isClearOfPois(rPos, nodes, 200.0)) {
        game.world.add(
          SingularityRiftComponent(
            position: rPos,
            pullRadius: 160.0,
            duration: 0.8,
          ),
        );
      }
    }
  }
}
