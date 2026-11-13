import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:asteroids/game/asteroids_game.dart';
import 'package:asteroids/game/components/player.dart';
import 'package:asteroids/game/weapons.dart';
import 'package:asteroids/services/localization_service.dart';
import 'package:asteroids/services/secret_grimoire_service.dart';

enum PerkType { newWeapon, upgradeWeapon, passive, evolution }

enum PerkRarity { common, rare, epic, legendary }

class WeaponSynergy {
  final String weaponId;
  final String passiveId;
  final String passiveTitle;
  final String evolvedName;
  final String evolutionDescriptionPt;
  final String? evolutionDescriptionEn;
  final IconData evolutionIcon;

  String get evolutionDescription => I18n.isPt
      ? evolutionDescriptionPt
      : (evolutionDescriptionEn ?? evolutionDescriptionPt);

  const WeaponSynergy({
    required this.weaponId,
    required this.passiveId,
    required this.passiveTitle,
    required this.evolvedName,
    String? evolutionDescription,
    String? evolutionDescriptionPt,
    this.evolutionDescriptionEn,
    required this.evolutionIcon,
  }) : evolutionDescriptionPt =
           evolutionDescriptionPt ?? evolutionDescription ?? '';

  static const List<WeaponSynergy> allSynergies = [
    WeaponSynergy(
      weaponId: 'blaster',
      passiveId: 'passive_overdrive',
      passiveTitle: 'Void Catalyst',
      evolvedName: 'Supernova Annihilator',
      evolutionDescriptionPt:
          'Feixes gêmeos contínuos de plasma dourado imperial com perfuração infinita e dano catastrófico.',
      evolutionDescriptionEn:
          'Dual continuous imperial gold plasma beams with infinite pierce and catastrophic damage.',
      evolutionIcon: Icons.auto_awesome,
    ),
    WeaponSynergy(
      weaponId: 'spread_shot',
      passiveId: 'passive_shield_recharge',
      passiveTitle: 'Aegis Capacitor',
      evolvedName: 'Hyperion Flak Storm',
      evolutionDescriptionPt:
          'Anel perimétrico de 10 tiros em 360 graus que aniquila todos os enxames ao redor.',
      evolutionDescriptionEn:
          '10-way 360-degree perimeter flak ring annihilating all surrounding hostile swarms.',
      evolutionIcon: Icons.grain,
    ),
    WeaponSynergy(
      weaponId: 'rapid_fire',
      passiveId: 'passive_fire_rate',
      passiveTitle: 'Overclocked Emitters',
      evolvedName: 'Absolute Zero Tachyon Beam',
      evolutionDescriptionPt:
          'Fluxo criogênico perfurante com cadência extrema e penetração linear infinita.',
      evolutionDescriptionEn:
          'Piercing cryogenic stream with blistering fire rate and infinite line penetration.',
      evolutionIcon: Icons.ac_unit,
    ),
    WeaponSynergy(
      weaponId: 'bomb_launcher',
      passiveId: 'passive_magnet',
      passiveTitle: 'Magnetic Harvester',
      evolvedName: 'Singularity Rift Torpedo',
      evolutionDescriptionPt:
          'Torpedos de antimatéria detonando vórtices gravitacionais de buraco negro que atraem e esmagam inimigos.',
      evolutionDescriptionEn:
          'Antimatter torpedoes detonating in gravitational black hole vortexes that pull and crush foes.',
      evolutionIcon: Icons.cyclone,
    ),
    WeaponSynergy(
      weaponId: 'aegis_sawblades',
      passiveId: 'passive_armor_plating',
      passiveTitle: 'Armor Plating',
      evolvedName: 'Celestial Buzzsaw Ring',
      evolutionDescriptionPt:
          '6 serras precursoras douradas orbitando em velocidade supersônica, triturando tiros e inimigos.',
      evolutionDescriptionEn:
          '6 golden precursor sawblades orbiting at supersonic speed, shredding projectiles and enemies.',
      evolutionIcon: Icons.rotate_right_rounded,
    ),
    WeaponSynergy(
      weaponId: 'tesla_arc',
      passiveId: 'passive_luck_salvage',
      passiveTitle: 'Quantum Luck Array',
      evolvedName: 'Mjolnir Storm Conduit',
      evolutionDescriptionPt:
          'Raios elétricos de alta voltagem saltando entre até 8 alvos e aplicando Choque Iônico.',
      evolutionDescriptionEn:
          'High-voltage chain lightning jumping across 8 targets and inflicting Ion Shock.',
      evolutionIcon: Icons.electric_bolt_rounded,
    ),
    WeaponSynergy(
      weaponId: 'quantum_chakram',
      passiveId: 'passive_capacitor_surge',
      passiveTitle: 'Relativistic Damper',
      evolvedName: 'Chronos Eclipse Glaive',
      evolutionDescriptionPt:
          'Lâminas bumerangue triplas que congelam inimigos e causam 165% de dano no retorno.',
      evolutionDescriptionEn:
          'Triple boomerang glaives that freeze enemies and deal 165% return damage.',
      evolutionIcon: Icons.all_out_rounded,
    ),
    WeaponSynergy(
      weaponId: 'repulsor_aura',
      passiveId: 'passive_aoe_amplifier',
      passiveTitle: 'Thermobaric Warheads',
      evolvedName: 'Event Horizon Nova Pulse',
      evolutionDescriptionPt:
          'Onda de choque gravitacional maciça de 360° aplicando Ruptura do Vazio e Congelamento.',
      evolutionDescriptionEn:
          'Massive 360-degree gravitational shockwave inflicting Void Rupture and Cryo Freeze.',
      evolutionIcon: Icons.radar_rounded,
    ),
    WeaponSynergy(
      weaponId: 'solar_lance',
      passiveId: 'passive_piercing_sabots',
      passiveTitle: 'Tungsten Sabot Cores',
      evolvedName: 'Helios Core Melter',
      evolutionDescriptionPt:
          'Feixe estelar contínuo colossal que derrete blindagens e inflige Queimadura Solar.',
      evolutionDescriptionEn:
          'Colossal continuous starfire beam that melts armor and inflicts Solar Burn.',
      evolutionIcon: Icons.wb_sunny_rounded,
    ),
    WeaponSynergy(
      weaponId: 'inferno_cone',
      passiveId: 'passive_unstable_payloads',
      passiveTitle: 'Unstable Payloads',
      evolvedName: 'Phoenix Dragon Breath',
      evolutionDescriptionPt:
          'Cone de plasma de fogo de dragão com 5 feixes incinerando esquadrões hostis inteiros.',
      evolutionDescriptionEn:
          '5-stream dragonfire plasma cone incinerating entire enemy squadrons.',
      evolutionIcon: Icons.local_fire_department_rounded,
    ),
    WeaponSynergy(
      weaponId: 'valkyrie_wingmen',
      passiveId: 'passive_lifesteal_matrix',
      passiveTitle: 'Lifesteal Matrix',
      evolvedName: 'Seraphim Drone Squadron',
      evolutionDescriptionPt:
          '4 drones de combate Seraphim autônomos disparando salvas ionizadas de alta cadência.',
      evolutionDescriptionEn:
          '4 autonomous Seraphim combat drones firing high-velocity ionized volleys.',
      evolutionIcon: Icons.flight_class_rounded,
    ),
    WeaponSynergy(
      weaponId: 'void_mines',
      passiveId: 'passive_thrust',
      passiveTitle: 'Quantum Thrusters',
      evolvedName: 'Abyssal Minefield Matrix',
      evolutionDescriptionPt:
          'Lança 3 minas traseiras de matéria escura que congelam e rompem hordas perseguidoras.',
      evolutionDescriptionEn:
          'Deploys 3 rear dark-matter cluster mines that freeze and rupture pursuing hordes.',
      evolutionIcon: Icons.brightness_low_rounded,
    ),
    WeaponSynergy(
      weaponId: 'tachyon_katana',
      passiveId: 'passive_crit_optics',
      passiveTitle: 'Precision Crit Optics',
      evolvedName: 'Void Muramasa',
      evolutionDescriptionPt:
          'Cortes triplos dimensionais de plasma que rasgam a realidade com perfuração linear irrestrita.',
      evolutionDescriptionEn:
          'Triple dimensional plasma slashes cutting through reality with infinite line penetration.',
      evolutionIcon: Icons.flash_on_rounded,
    ),
  ];

  static WeaponSynergy? findByWeaponId(String weaponId) {
    for (final s in allSynergies) {
      if (s.weaponId == weaponId) return s;
    }
    return null;
  }
}

/// Receita compartilhada de Super-União entre duas armas em nível máximo (MK 5),
/// liberando 1 slot do arsenal ao fundir ambas em uma superarma lendária.
class WeaponUnionRecipe {
  final String unionId;
  final String title;
  final String weaponAId;
  final String weaponATitle;
  final String weaponBId;
  final String weaponBTitle;
  final String descriptionPt;
  final String descriptionEn;
  final IconData icon;
  final Color accentColor;

  const WeaponUnionRecipe({
    required this.unionId,
    required this.title,
    required this.weaponAId,
    required this.weaponATitle,
    required this.weaponBId,
    required this.weaponBTitle,
    required this.descriptionPt,
    required this.descriptionEn,
    required this.icon,
    required this.accentColor,
  });

  String get description => I18n.isPt ? descriptionPt : descriptionEn;

  bool hasWeaponAMaxed(PlayerComponent player) {
    final w = player.unlockedWeapons[weaponAId];
    return w != null && w.level >= w.maxLevel;
  }

  bool hasWeaponBMaxed(PlayerComponent player) {
    final w = player.unlockedWeapons[weaponBId];
    return w != null && w.level >= w.maxLevel;
  }

  bool isEligible(PlayerComponent player) =>
      hasWeaponAMaxed(player) &&
      hasWeaponBMaxed(player) &&
      !player.unlockedWeapons.containsKey(unionId);

  void applyFusion(AsteroidsGame game) {
    game.player.removeWeapon(weaponAId);
    game.player.removeWeapon(weaponBId);
    game.player.addWeapon(Weapon.createById(unionId));
    SecretGrimoireService.discover(unionId);
    game.unlockMilestone('ach_superweapon');
    game.playSfx('boss_spawn.wav');
    game.triggerScreenShake(duration: 0.8, intensity: 16.0);
  }

  static const List<WeaponUnionRecipe> allUnions = [
    WeaponUnionRecipe(
      unionId: 'union_void_singularity',
      title: 'Void Singularity Nova',
      weaponAId: 'blaster',
      weaponATitle: 'Pulse Blaster',
      weaponBId: 'void_mines',
      weaponBTitle: 'Void Cluster Mines',
      descriptionPt:
          'Funde Pulse Blaster e Void Mines em uma super-arma estelar que dispara feixes e minas de singularidade, LIBERANDO 1 SLOT DE ARMA!',
      descriptionEn:
          'Fuses Pulse Blaster and Void Mines into a stellar super-weapon, FREEING 1 ARSENAL SLOT!',
      icon: Icons.all_inclusive_rounded,
      accentColor: Color(0xFFE040FB),
    ),
    WeaponUnionRecipe(
      unionId: 'union_thunderstorm',
      title: 'Thunderstorm Core Melter',
      weaponAId: 'solar_lance',
      weaponATitle: 'Solar Thermal Lance',
      weaponBId: 'tesla_arc',
      weaponBTitle: 'Tesla Arc Cannon',
      descriptionPt:
          'Funde Solar Lance e Tesla Arc Cannon em um feixe colossal de plasma solar bifurcado em relâmpagos, LIBERANDO 1 SLOT DE ARMA!',
      descriptionEn:
          'Fuses Solar Lance and Tesla Arc into a colossal sunbeam branched in lightning, FREEING 1 ARSENAL SLOT!',
      icon: Icons.electric_bolt_rounded,
      accentColor: Color(0xFFFFD700),
    ),
    WeaponUnionRecipe(
      unionId: 'union_eclipse_tempest',
      title: 'Eclipse Orbital Tempest',
      weaponAId: 'aegis_sawblades',
      weaponATitle: 'Aegis Sawblades',
      weaponBId: 'quantum_chakram',
      weaponBTitle: 'Quantum Chakram',
      descriptionPt:
          'Funde Aegis Sawblades e Quantum Chakram em um furacão orbital de 6 lâminas e 3 discos criogênicos, LIBERANDO 1 SLOT DE ARMA!',
      descriptionEn:
          'Fuses Aegis Sawblades and Quantum Chakram into a 6-blade orbital storm + 3 cryo glaives, FREEING 1 ARSENAL SLOT!',
      icon: Icons.cyclone_rounded,
      accentColor: Color(0xFF00E5FF),
    ),
    WeaponUnionRecipe(
      unionId: 'union_cataclysm_inferno',
      title: 'Cataclysmic Void Inferno',
      weaponAId: 'inferno_cone',
      weaponATitle: 'Inferno Plasma Cone',
      weaponBId: 'bomb_launcher',
      weaponBTitle: 'Antimatter Torpedo',
      descriptionPt:
          'Funde Inferno Cone e Antimatter Torpedo em torrentes dracônicas e ogivas de buraco negro, LIBERANDO 1 SLOT DE ARMA!',
      descriptionEn:
          'Fuses Inferno Cone and Antimatter Torpedo into dragonfire streams & singularity warheads, FREEING 1 ARSENAL SLOT!',
      icon: Icons.local_fire_department_rounded,
      accentColor: Color(0xFFFF6D00),
    ),
    WeaponUnionRecipe(
      unionId: 'union_seraphim_requiem',
      title: 'Seraphim Void Requiem',
      weaponAId: 'tachyon_katana',
      weaponATitle: 'Tachyon Katana',
      weaponBId: 'valkyrie_wingmen',
      weaponBTitle: 'Valkyrie Wingmen',
      descriptionPt:
          'Funde Tachyon Katana e Valkyrie Wingmen em cortes dourados transcendentais e 4 drones Seraphim, LIBERANDO 1 SLOT DE ARMA!',
      descriptionEn:
          'Fuses Tachyon Katana and Valkyrie Wingmen into golden slashes & 4 Seraphim interceptors, FREEING 1 ARSENAL SLOT!',
      icon: Icons.auto_awesome,
      accentColor: Color(0xFFFFD54F),
    ),
  ];
}

class RoguePerk {
  final String id;
  final String title;
  final String descriptionPt;
  final String? descriptionEn;
  final PerkType type;
  final PerkRarity rarity;
  final IconData icon;
  final Color accentColor;
  final bool isTradeOff;
  final void Function(AsteroidsGame game) onSelect;

  String get description =>
      I18n.isPt ? descriptionPt : (descriptionEn ?? descriptionPt);

  const RoguePerk({
    required this.id,
    required this.title,
    String? description,
    String? descriptionPt,
    this.descriptionEn,
    required this.type,
    required this.rarity,
    required this.icon,
    required this.accentColor,
    this.isTradeOff = false,
    required this.onSelect,
  }) : descriptionPt = descriptionPt ?? description ?? '';

  String get typeLabel {
    switch (type) {
      case PerkType.newWeapon:
        return I18n.t('perk_type.new_weapon');
      case PerkType.upgradeWeapon:
        return I18n.t('perk_type.upgrade_weapon');
      case PerkType.passive:
        return I18n.t('perk_type.passive');
      case PerkType.evolution:
        return I18n.t('perk_type.evolution');
    }
  }

  String get rarityLabel {
    switch (rarity) {
      case PerkRarity.common:
        return I18n.t('rarity.common');
      case PerkRarity.rare:
        return I18n.t('rarity.rare');
      case PerkRarity.epic:
        return I18n.t('rarity.epic');
      case PerkRarity.legendary:
        return I18n.t('rarity.legendary');
    }
  }

  Color get rarityColor {
    switch (rarity) {
      case PerkRarity.common:
        return const Color(0xFF00E5FF); // Cyan
      case PerkRarity.rare:
        return const Color(0xFFE040FB); // Magenta
      case PerkRarity.epic:
        return const Color(0xFFFF9100); // Amber
      case PerkRarity.legendary:
        return const Color(0xFFFFD700); // Gold
    }
  }
}

class RoguePerkGenerator {
  static String _synergyHint(String weaponId, {required bool isPt}) {
    final synergy = WeaponSynergy.findByWeaponId(weaponId);
    if (synergy == null) return '';
    if (SecretGrimoireService.isDiscovered(weaponId)) {
      return isPt
          ? ' [Sinergia: ${synergy.passiveTitle}]'
          : ' [Synergy: ${synergy.passiveTitle}]';
    }
    return isPt
        ? ' [Sinergia: ??? (Combinação Secreta)]'
        : ' [Synergy: ??? (Secret Recipe)]';
  }

  static String _passiveSynergyHint(
    String weaponId,
    String weaponTitle, {
    required bool isPt,
  }) {
    if (SecretGrimoireService.isDiscovered(weaponId)) {
      return isPt ? ' [Sinergia: $weaponTitle]' : ' [Synergy: $weaponTitle]';
    }
    return '';
  }

  static List<RoguePerk> generateChoices(AsteroidsGame game, {int count = 3}) {
    final player = game.player;
    final List<RoguePerk> priorityPool = [];
    final List<RoguePerk> standardPool = [];

    // 0. Super-Evolutions (Vampire Survivors Synergy Matrix)
    for (final entry in player.unlockedWeapons.entries) {
      final key = entry.key;
      final weapon = entry.value;
      if (weapon.canEvolve) {
        final synergy = WeaponSynergy.findByWeaponId(key);
        if (synergy != null &&
            game.activePassives.contains(synergy.passiveId)) {
          priorityPool.add(
            RoguePerk(
              id: 'evolve_$key',
              title: synergy.evolvedName.toUpperCase(),
              descriptionPt: synergy.evolutionDescriptionPt,
              descriptionEn: synergy.evolutionDescriptionEn,
              type: PerkType.evolution,
              rarity: PerkRarity.legendary,
              icon: synergy.evolutionIcon,
              accentColor: const Color(0xFFFFD700),
              onSelect: (g) {
                weapon.evolve();
                g.unlockMilestone('ach_superweapon');
                g.playSfx('boss_spawn.wav');
                g.triggerScreenShake(duration: 0.6, intensity: 12.0);
              },
            ),
          );
        }
      }
    }

    // 0B. Super-Uniões de Armas Duplas (Vampire Survivors Style Unions)
    for (final union in WeaponUnionRecipe.allUnions) {
      if (union.isEligible(player)) {
        priorityPool.add(
          RoguePerk(
            id: union.unionId,
            title: '★ SUPER-UNIÃO: ${union.title.toUpperCase()}',
            descriptionPt: union.descriptionPt,
            descriptionEn: union.descriptionEn,
            type: PerkType.evolution,
            rarity: PerkRarity.legendary,
            icon: union.icon,
            accentColor: union.accentColor,
            onSelect: union.applyFusion,
          ),
        );
      }
    }

    // 1. New Arsenal Weapons (if not yet unlocked and inventory has free slots - Vampire Survivors 5 slots max)
    if (player.activeWeapons.length < PlayerComponent.maxArsenalSlots) {
      if (!player.unlockedWeapons.containsKey('blaster') &&
          game.isWeaponUnlockedInPool('blaster')) {
        standardPool.add(
          RoguePerk(
            id: 'new_blaster',
            title: 'Pulse Blaster',
            descriptionPt:
                'Canhão duplo de plasma de precisão com alta velocidade de projétil e poder equilibrado.${_synergyHint('blaster', isPt: true)}',
            descriptionEn:
                'Precision twin-bolt plasma cannon with high projectile speed and balanced power.${_synergyHint('blaster', isPt: false)}',
            type: PerkType.newWeapon,
            rarity: PerkRarity.common,
            icon: Icons.flash_on,
            accentColor: const Color(0xFFFF5722),
            onSelect: (g) {
              g.player.addWeapon(Blaster());
            },
          ),
        );
      }

      if (!player.unlockedWeapons.containsKey('spread_shot') &&
          game.isWeaponUnlockedInPool('spread_shot')) {
        standardPool.add(
          RoguePerk(
            id: 'new_spread_shot',
            title: 'Spread Cannon',
            descriptionPt:
                'Dispara salva em leque cobrindo amplo arco frontal com dispersão de plasma.${_synergyHint('spread_shot', isPt: true)}',
            descriptionEn:
                'Fires a 3-way fan of plasma projectiles covering a wide frontal arc.${_synergyHint('spread_shot', isPt: false)}',
            type: PerkType.newWeapon,
            rarity: PerkRarity.rare,
            icon: Icons.grain,
            accentColor: const Color(0xFF00E676),
            onSelect: (g) {
              g.player.addWeapon(SpreadShot());
            },
          ),
        );
      }

      if (!player.unlockedWeapons.containsKey('rapid_fire') &&
          game.isWeaponUnlockedInPool('rapid_fire')) {
        standardPool.add(
          RoguePerk(
            id: 'new_rapid_fire',
            title: 'Phase Laser',
            descriptionPt:
                'Feixe fotônico de alta frequência com cadência avassaladora e perfuração linear.${_synergyHint('rapid_fire', isPt: true)}',
            descriptionEn:
                'High-frequency photon beam with blazing fire rate and line piercing.${_synergyHint('rapid_fire', isPt: false)}',
            type: PerkType.newWeapon,
            rarity: PerkRarity.rare,
            icon: Icons.fast_forward,
            accentColor: const Color(0xFF2979FF),
            onSelect: (g) {
              g.player.addWeapon(RapidFire());
            },
          ),
        );
      }

      if (!player.unlockedWeapons.containsKey('bomb_launcher') &&
          game.isWeaponUnlockedInPool('bomb_launcher')) {
        standardPool.add(
          RoguePerk(
            id: 'new_bomb_launcher',
            title: 'Antimatter Torpedo',
            descriptionPt:
                'Ogivas explosivas pesadas que detonam em uma onda de choque destrutiva em área.${_synergyHint('bomb_launcher', isPt: true)}',
            descriptionEn:
                'Heavy explosive warheads detonating in a massive destructive shockwave.${_synergyHint('bomb_launcher', isPt: false)}',
            type: PerkType.newWeapon,
            rarity: PerkRarity.epic,
            icon: Icons.gps_fixed,
            accentColor: const Color(0xFFFF6D00),
            onSelect: (g) {
              g.player.addWeapon(BombLauncher());
            },
          ),
        );
      }

      // 1B. Phase 2 Expanded Arsenal (8 New Elemental & Orbital Weapons + Tachyon Katana)
      final expandedWeapons =
          <
            (
              String id,
              String title,
              String descPt,
              String descEn,
              PerkRarity rarity,
              IconData icon,
              Color color,
            )
          >[
            (
              'aegis_sawblades',
              'Aegis Sawblades',
              'Lâminas orbitais que giram ao redor da nave bloqueando tiros e serrando enxames.${_synergyHint('aegis_sawblades', isPt: true)}',
              'Orbital sawblades that spin around the ship blocking projectiles and shredding swarms.${_synergyHint('aegis_sawblades', isPt: false)}',
              PerkRarity.rare,
              Icons.rotate_right_rounded,
              const Color(0xFF00E5FF),
            ),
            (
              'tesla_arc',
              'Tesla Arc Cannon',
              'Corrente elétrica que salta entre múltiplos inimigos aplicando Choque Iônico.${_synergyHint('tesla_arc', isPt: true)}',
              'Electric arc leaping between multiple hostiles inflicting Ion Shock.${_synergyHint('tesla_arc', isPt: false)}',
              PerkRarity.rare,
              Icons.electric_bolt_rounded,
              const Color(0xFF80D8FF),
            ),
            (
              'quantum_chakram',
              'Quantum Chakram',
              'Disco bumerangue que atravessa inimigos na ida e volta com 165% de dano.${_synergyHint('quantum_chakram', isPt: true)}',
              'Boomerang disc cutting through hostiles outbound and returning with 165% damage.${_synergyHint('quantum_chakram', isPt: false)}',
              PerkRarity.rare,
              Icons.all_out_rounded,
              const Color(0xFF00E676),
            ),
            (
              'repulsor_aura',
              'Repulsor Gravity Aura',
              'Pulso gravitacional 360° que aplica Ruptura do Vazio e repele enxames.${_synergyHint('repulsor_aura', isPt: true)}',
              '360° gravitational pulse inflicting Void Rupture and repelling hostile swarms.${_synergyHint('repulsor_aura', isPt: false)}',
              PerkRarity.rare,
              Icons.radar_rounded,
              const Color(0xFFE040FB),
            ),
            (
              'solar_lance',
              'Solar Thermal Lance',
              'Feixe laser contínuo de fusão que perfura alvos aplicando Queimadura Solar.${_synergyHint('solar_lance', isPt: true)}',
              'Continuous fusion laser beam piercing hostiles and inflicting Solar Burn.${_synergyHint('solar_lance', isPt: false)}',
              PerkRarity.epic,
              Icons.wb_sunny_rounded,
              const Color(0xFFFF5722),
            ),
            (
              'inferno_cone',
              'Inferno Plasma Cone',
              'Lança-chamas espacial em cone que incinera hordas com Queimadura Solar.${_synergyHint('inferno_cone', isPt: true)}',
              'Cone plasma flamethrower incinerating swarms with Solar Burn.${_synergyHint('inferno_cone', isPt: false)}',
              PerkRarity.common,
              Icons.local_fire_department_rounded,
              const Color(0xFFFF9100),
            ),
            (
              'valkyrie_wingmen',
              'Valkyrie Wingmen',
              'Drones aliados autônomos que escoltam a nave e caçam inimigos próximos.${_synergyHint('valkyrie_wingmen', isPt: true)}',
              'Autonomous ally escort drones protecting the ship and hunting nearby enemies.${_synergyHint('valkyrie_wingmen', isPt: false)}',
              PerkRarity.epic,
              Icons.flight_class_rounded,
              const Color(0xFF00B0FF),
            ),
            (
              'void_mines',
              'Void Cluster Mines',
              'Minas traseiras de matéria escura ideais para Kiting na ré (Ruptura do Vazio).${_synergyHint('void_mines', isPt: true)}',
              'Rear dark-matter cluster mines ideal for reverse kiting (Void Rupture).${_synergyHint('void_mines', isPt: false)}',
              PerkRarity.rare,
              Icons.brightness_low_rounded,
              const Color(0xFFAA00FF),
            ),
            (
              'tachyon_katana',
              'Tachyon Katana',
              'Lâmina de plasma taquiônica que apara projéteis hostis e fatia enxames em arco.${_synergyHint('tachyon_katana', isPt: true)}',
              'Tachyon plasma blade that parries incoming fire and slashes swarms in an arc.${_synergyHint('tachyon_katana', isPt: false)}',
              PerkRarity.epic,
              Icons.flash_on_rounded,
              const Color(0xFF00E5FF),
            ),
          ];

      for (final wInfo in expandedWeapons) {
        if (!player.unlockedWeapons.containsKey(wInfo.$1) &&
            game.isWeaponUnlockedInPool(wInfo.$1)) {
          standardPool.add(
            RoguePerk(
              id: 'new_${wInfo.$1}',
              title: wInfo.$2,
              descriptionPt: wInfo.$3,
              descriptionEn: wInfo.$4,
              type: PerkType.newWeapon,
              rarity: wInfo.$5,
              icon: wInfo.$6,
              accentColor: wInfo.$7,
              onSelect: (g) {
                g.player.addWeapon(Weapon.createById(wInfo.$1));
              },
            ),
          );
        }
      }
    }

    // 2. Weapon Upgrades (for currently equipped/unlocked weapons)
    for (final entry in player.unlockedWeapons.entries) {
      final key = entry.key;
      final weapon = entry.value;
      if (weapon.level < weapon.maxLevel) {
        final nextLvl = weapon.level + 1;
        final isMaxNext = nextLvl == weapon.maxLevel;
        final synergyHintPt = _synergyHint(key, isPt: true);
        final synergyHintEn = _synergyHint(key, isPt: false);

        standardPool.add(
          RoguePerk(
            id: 'upgrade_${key}_$nextLvl',
            title: '${weapon.name.toUpperCase()} MK $nextLvl',
            descriptionPt: isMaxNext
                ? 'Potência Máxima! Amplifica dano e cadência.$synergyHintPt'
                : 'Aprimora velocidade de disparo e dano.$synergyHintPt',
            descriptionEn: isMaxNext
                ? 'Maximum Power! Amplifies damage and fire rate.$synergyHintEn'
                : 'Improves firing speed and damage.$synergyHintEn',
            type: PerkType.upgradeWeapon,
            rarity: isMaxNext ? PerkRarity.epic : PerkRarity.rare,
            icon: Icons.keyboard_double_arrow_up,
            accentColor: isMaxNext
                ? const Color(0xFFFFD700)
                : const Color(0xFF00E5FF),
            onSelect: (g) {
              weapon.upgrade();
              g.playSfx('powerup.wav');
            },
          ),
        );
      }
    }

    // 3. Passive Ship & Combat Modules (Sprint 59: 16 Passivas incluindo Trade-offs Brotato)
    standardPool.addAll(buildPassiveCatalog());

    // Combine priority choices (evolutions) first, then shuffle the rest
    // Sprint 54: Respeita o protocolo de purga do vazio (Banish)
    final filteredStandard = standardPool
        .where((p) => !game.runBanishedPerkIds.contains(p.id))
        .toList();
    filteredStandard.shuffle();
    final result = <RoguePerk>[
      ...priorityPool.where((p) => !game.runBanishedPerkIds.contains(p.id)),
    ];
    for (final perk in filteredStandard) {
      if (result.length >= count) break;
      result.add(perk);
    }
    return result;
  }

  /// Sprint 59: Catálogo completo com 16 passivas (13 módulos de combate + 3 trade-offs radicais estilo Brotato).
  static List<RoguePerk> buildPassiveCatalog() {
    return [
      RoguePerk(
        id: 'passive_magnet',
        title: 'Magnetic Harvester',
        descriptionPt:
            'Expande o raio de atração de Poeira Estelar em +40%.${_passiveSynergyHint('bomb_launcher', 'Torpedo Antimatter', isPt: true)}',
        descriptionEn:
            'Expands Stardust attraction radius by +40%.${_passiveSynergyHint('bomb_launcher', 'Antimatter Torpedo', isPt: false)}',
        type: PerkType.passive,
        rarity: PerkRarity.common,
        icon: Icons.all_inclusive,
        accentColor: const Color(0xFF00E5FF),
        onSelect: (g) {
          g.activePassives.add('passive_magnet');
          g.rogueMagnetRadius += 60.0;
          g.player.magnetRadius = g.rogueMagnetRadius;
        },
      ),
      RoguePerk(
        id: 'passive_thrust',
        title: 'Quantum Thrusters',
        descriptionPt:
            'Aumenta aceleração da nave em +20% e velocidade máxima.',
        descriptionEn: 'Increases ship acceleration by +20% and maximum speed.',
        type: PerkType.passive,
        rarity: PerkRarity.common,
        icon: Icons.flight_takeoff,
        accentColor: const Color(0xFF76FF03),
        onSelect: (g) {
          g.activePassives.add('passive_thrust');
          g.player.movementAcceleration += 120.0;
          g.player.movementMaxSpeed += 50.0;
        },
      ),
      RoguePerk(
        id: 'passive_shield_recharge',
        title: 'Aegis Capacitor',
        descriptionPt:
            'Restaura +1 Vida e concede invulnerabilidade temporária.${_passiveSynergyHint('spread_shot', 'Spread Cannon', isPt: true)}',
        descriptionEn:
            'Restores +1 Life and grants temporary invulnerability.${_passiveSynergyHint('spread_shot', 'Spread Cannon', isPt: false)}',
        type: PerkType.passive,
        rarity: PerkRarity.rare,
        icon: Icons.shield,
        accentColor: const Color(0xFF00B0FF),
        onSelect: (g) {
          g.activePassives.add('passive_shield_recharge');
          g.lives = math.min(g.lives + 1, 6);
          g.player.invulnerableTimer = 3.0;
        },
      ),
      RoguePerk(
        id: 'passive_fire_rate',
        title: 'Overclocked Emitters',
        descriptionPt:
            'Reduz recarga de todas as armas em 15%.${_passiveSynergyHint('rapid_fire', 'Phase Laser', isPt: true)}',
        descriptionEn:
            'Reduces weapon cooldown by 15%.${_passiveSynergyHint('rapid_fire', 'Phase Laser', isPt: false)}',
        type: PerkType.passive,
        rarity: PerkRarity.rare,
        icon: Icons.bolt,
        accentColor: const Color(0xFFFFD600),
        onSelect: (g) {
          g.activePassives.add('passive_fire_rate');
          g.rogueFireRateMultiplier *= 0.85;
        },
      ),
      RoguePerk(
        id: 'passive_overdrive',
        title: 'Void Catalyst',
        descriptionPt:
            'Gera Poeira Estelar passiva e concede +25% de dano a todas as armas.${_passiveSynergyHint('blaster', 'Pulse Blaster', isPt: true)}',
        descriptionEn:
            'Generates passive Stardust and grants +25% damage to all weapons.${_passiveSynergyHint('blaster', 'Pulse Blaster', isPt: false)}',
        type: PerkType.passive,
        rarity: PerkRarity.epic,
        icon: Icons.auto_awesome,
        accentColor: const Color(0xFFFF1744),
        onSelect: (g) {
          g.activePassives.add('passive_overdrive');
          g.rogueDamageMultiplier += 0.25;
          g.addStardust(50);
        },
      ),
      // Sprint 59: Novos Módulos Especializados
      RoguePerk(
        id: 'passive_armor_plating',
        title: 'Armor Plating',
        descriptionPt:
            'Reduz todo dano recebido no casco em +12% e adiciona +15 HP Máximo.',
        descriptionEn:
            'Reduces all incoming hull damage by +12% and grants +15 Max HP.',
        type: PerkType.passive,
        rarity: PerkRarity.common,
        icon: Icons.security,
        accentColor: const Color(0xFF90CAF9),
        onSelect: (g) {
          g.activePassives.add('passive_armor_plating');
          g.player.armorReduction = (g.player.armorReduction + 0.12).clamp(
            0.0,
            0.65,
          );
          g.player.maxHp += 15.0;
          g.player.hp = math.min(g.player.maxHp, g.player.hp + 15.0);
        },
      ),
      RoguePerk(
        id: 'passive_crit_optics',
        title: 'Precision Crit Optics',
        descriptionPt:
            '+8% Chance Crítica e +0.25x Multiplicador Crítico em todos os disparos.',
        descriptionEn:
            '+8% Critical Chance and +0.25x Critical Multiplier on all weapons.',
        type: PerkType.passive,
        rarity: PerkRarity.rare,
        icon: Icons.gps_fixed,
        accentColor: const Color(0xFFFF5252),
        onSelect: (g) {
          g.activePassives.add('passive_crit_optics');
          g.rogueCritChance = (g.rogueCritChance + 0.08).clamp(0.0, 1.0);
          g.rogueCritMultiplier += 0.25;
        },
      ),
      RoguePerk(
        id: 'passive_lifesteal_matrix',
        title: 'Lifesteal Matrix',
        descriptionPt:
            '+5% Sifão Vital: cada nave inimiga abatida regenera integridade do casco.',
        descriptionEn:
            '+5% Lifesteal: enemy ship kills siphon hull integrity back to your craft.',
        type: PerkType.passive,
        rarity: PerkRarity.epic,
        icon: Icons.favorite,
        accentColor: const Color(0xFFFF4081),
        onSelect: (g) {
          g.activePassives.add('passive_lifesteal_matrix');
          g.rogueLifesteal = (g.rogueLifesteal + 0.05).clamp(0.0, 0.45);
        },
      ),
      RoguePerk(
        id: 'passive_aoe_amplifier',
        title: 'Thermobaric Warheads',
        descriptionPt:
            '+20% Raio de Explosão e Área de Efeito (AoE) em bombas, minas e pulsos.',
        descriptionEn:
            '+20% Explosion & AoE Radius for bombs, mines, and gravity pulses.',
        type: PerkType.passive,
        rarity: PerkRarity.rare,
        icon: Icons.flare,
        accentColor: const Color(0xFFFF9100),
        onSelect: (g) {
          g.activePassives.add('passive_aoe_amplifier');
          g.rogueAreaMultiplier += 0.20;
        },
      ),
      RoguePerk(
        id: 'passive_piercing_sabots',
        title: 'Tungsten Sabot Cores',
        descriptionPt:
            '+1 Perfuração de Projétil (Pierce) em todos os disparos balísticos.',
        descriptionEn: '+1 Projectile Piercing across all ballistic weapons.',
        type: PerkType.passive,
        rarity: PerkRarity.rare,
        icon: Icons.double_arrow,
        accentColor: const Color(0xFF80D8FF),
        onSelect: (g) {
          g.activePassives.add('passive_piercing_sabots');
          g.player.pierceCount += 1;
        },
      ),
      RoguePerk(
        id: 'passive_luck_salvage',
        title: 'Quantum Luck Array',
        descriptionPt:
            '+15% Sorte (Luck), aumentando chance de Jackpots em baús e diagramas.',
        descriptionEn:
            '+15% Luck Drop Rate, boosting chest Jackpots and blueprint drop chances.',
        type: PerkType.passive,
        rarity: PerkRarity.common,
        icon: Icons.casino,
        accentColor: const Color(0xFFFFD740),
        onSelect: (g) {
          g.activePassives.add('passive_luck_salvage');
          g.rogueLuckBonus += 0.15;
        },
      ),
      RoguePerk(
        id: 'passive_capacitor_surge',
        title: 'Relativistic Damper',
        descriptionPt:
            'Acelera recarga do Dash em +15% e aumenta velocidade máxima em +10%.',
        descriptionEn:
            'Speeds up Dash recharge by +15% and increases max speed by +10%.',
        type: PerkType.passive,
        rarity: PerkRarity.common,
        icon: Icons.speed,
        accentColor: const Color(0xFF1DE9B6),
        onSelect: (g) {
          g.activePassives.add('passive_capacitor_surge');
          g.player.dashCooldownMultiplier =
              (g.player.dashCooldownMultiplier * 0.85).clamp(0.40, 2.0);
          g.player.movementMaxSpeed *= 1.10;
        },
      ),
      RoguePerk(
        id: 'passive_hull_nanobots',
        title: 'Nanobot Hull Repair',
        descriptionPt:
            'Repara +35 HP imediatamente e reforça o casco com +20 HP Máximo.',
        descriptionEn:
            'Immediately repairs +35 HP and reinforces hull with +20 Max HP.',
        type: PerkType.passive,
        rarity: PerkRarity.common,
        icon: Icons.medical_services,
        accentColor: const Color(0xFF00E676),
        onSelect: (g) {
          g.activePassives.add('passive_hull_nanobots');
          g.player.maxHp += 20.0;
          g.player.heal(35.0);
        },
      ),
      // Sprint 59: Passivas com Trade-Offs Radicais (Brotato Model)
      RoguePerk(
        id: 'passive_glass_cannon',
        title: 'Glass Cannon Reactor',
        descriptionPt:
            'TRADE-OFF: +45% Dano Global em todas as armas, mas reduz HP Máximo em -25%.',
        descriptionEn:
            'TRADE-OFF: +45% Global Damage across all weapons, but reduces Max HP by -25%.',
        type: PerkType.passive,
        rarity: PerkRarity.legendary,
        icon: Icons.whatshot,
        accentColor: const Color(0xFFFF1744),
        isTradeOff: true,
        onSelect: (g) {
          g.activePassives.add('passive_glass_cannon');
          g.rogueDamageMultiplier += 0.45;
          g.player.maxHp = math.max(20.0, g.player.maxHp * 0.75);
          g.player.hp = math.min(g.player.hp, g.player.maxHp);
        },
      ),
      RoguePerk(
        id: 'passive_juggernaut',
        title: 'Juggernaut Plating',
        descriptionPt:
            'TRADE-OFF: +60 HP Máx e +18% Blindagem contra impacto, mas -15% Velocidade Máxima.',
        descriptionEn:
            'TRADE-OFF: +60 Max HP & +18% Armor mitigation, but -15% Max Speed.',
        type: PerkType.passive,
        rarity: PerkRarity.epic,
        icon: Icons.shield_moon,
        accentColor: const Color(0xFF40C4FF),
        isTradeOff: true,
        onSelect: (g) {
          g.activePassives.add('passive_juggernaut');
          g.player.maxHp += 60.0;
          g.player.hp = math.min(g.player.maxHp, g.player.hp + 60.0);
          g.player.armorReduction = (g.player.armorReduction + 0.18).clamp(
            0.0,
            0.65,
          );
          g.player.movementMaxSpeed *= 0.85;
        },
      ),
      RoguePerk(
        id: 'passive_unstable_payloads',
        title: 'Unstable Payloads',
        descriptionPt:
            'TRADE-OFF: +40% Área de Explosão (AoE), mas reduz Cadência de Disparo em -20%.',
        descriptionEn:
            'TRADE-OFF: +40% Explosion & AoE Radius, but slows Fire Rate by -20%.',
        type: PerkType.passive,
        rarity: PerkRarity.epic,
        icon: Icons.crisis_alert,
        accentColor: const Color(0xFFFFAB00),
        isTradeOff: true,
        onSelect: (g) {
          g.activePassives.add('passive_unstable_payloads');
          g.rogueAreaMultiplier += 0.40;
          g.rogueFireRateMultiplier *= 1.20;
        },
      ),
    ];
  }
}
