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
import 'package:asteroids/game/components/breakable_prop.dart';
import 'package:asteroids/game/components/indoor_environment.dart';
import 'sector_map_data.dart';
import 'biomes/biome_map_builders.dart';
export 'biomes/biome_map_builders.dart';

/// Gerador Procedural de Setores Cósmicos (Refatorado na Sprint 25).
/// Delega a geração para o Arquiteto Modular específico de cada um dos 6 Biomas
/// (`VestaBeltMapBuilder`, `HeliosForgeMapBuilder`, `CryoAbyssMapBuilder`,
/// `AegisGraveyardMapBuilder`, `XenoHiveMapBuilder`, `VoidThroneMapBuilder`).
class SectorMapGenerator {
  static BiomeMapArchitect getArchitectForSector(SectorId id) {
    switch (id) {
      case SectorId.vesta:
        return VestaBeltMapBuilder();
      case SectorId.orion:
        return HeliosForgeMapBuilder();
      case SectorId.cryoAbyss:
        return CryoAbyssMapBuilder();
      case SectorId.graveyard:
        return AegisGraveyardMapBuilder();
      case SectorId.xenoHive:
        return XenoHiveMapBuilder();
      case SectorId.eventHorizon:
        return VoidThroneMapBuilder(sectorId: SectorId.eventHorizon);
      case SectorId.voidThrone:
        return VoidThroneMapBuilder(sectorId: SectorId.voidThrone);
    }
  }

  static SectorMapData generateAndSpawn(AsteroidsGame game, {int? customSeed}) {
    final seed = customSeed ?? DateTime.now().millisecondsSinceEpoch;
    final sector = game.currentSector;

    // 1. Limpa POIs e camadas de biomas anteriores do mundo
    final oldPois = game.world.children.where((child) =>
        child is BiomeBackdropComponent ||
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
        child is CursedShrineComponent ||
        child is CryoMistZoneComponent ||
        child is CryoMineComponent ||
        child is OrganicBiomassWallComponent ||
        child is XenoCocoonComponent ||
        child is SolarFlameJetComponent ||
        child is ThermalDomeComponent ||
        child is ReactorLeakHazardComponent ||
        child is AcidPoolHazardComponent ||
        child is RelicPedestalComponent ||
        child is StasisCoffinComponent ||
        child is BreakablePropComponent ||
        child is ModularFloorComponent ||
        child is BlastDoorComponent ||
        child is LockdownChamberComponent);
    for (final p in List.from(oldPois)) {
      p.removeFromParent();
    }

    // 2. Constrói o Bioma usando seu Arquiteto dedicado
    final architect = getArchitectForSector(sector.id);
    final mapData = architect.build(game, sector, seed);

    game.sectorMap = mapData;
    return mapData;
  }
}
