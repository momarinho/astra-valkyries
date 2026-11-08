import 'package:flutter/material.dart';
import 'weapons.dart';

enum ValkyrieShipDesign {
  solBlaze,     // Lyra: Aerodynamic twin-engine vanguard interceptor (Orange/Crimson)
  aegisPrism,   // Selene: High-tech crystalline prism with shield pylons (Cyan/Silver)
  eclipseFang,  // Vesper: Forward-swept wing stealth heavy fighter (Black/Magenta)
  originPrime,  // Astraea: Mythical precursor starframe (Gold/White)
}

class Valkyrie {
  final String id;
  final String name;
  final String callsign;
  final String title;
  final String bio;
  final String quote;
  final String shipName;
  final ValkyrieShipDesign shipDesign;
  final bool isSecret;
  
  // Base Pilot Combat Stats
  final double baseHull;
  final double baseShield;
  final double speedMultiplier;
  final double magnetRadiusMultiplier;
  final double critChance; // 0.0 to 1.0

  // Weapon & Special
  final String startingWeaponName;
  final String startingWeaponDesc;
  final String specialAbilityName;
  final String specialAbilityDesc;
  final Weapon Function() createStartingWeapon;

  // Stat Ratings (1 to 5 stars)
  final int speedRating;
  final int defenseRating;
  final int firepowerRating;

  // Visual Aesthetics
  final Color primaryColor;
  final Color accentColor;
  final String hudNeutralAsset;
  final String hudDamagedAsset;
  final String hudUltimateAsset;
  final String hangarFullBodyAsset;
  final String shipAsset;

  const Valkyrie({
    required this.id,
    required this.name,
    required this.callsign,
    required this.title,
    required this.bio,
    required this.quote,
    required this.shipName,
    required this.shipDesign,
    required this.baseHull,
    required this.baseShield,
    required this.speedMultiplier,
    required this.magnetRadiusMultiplier,
    required this.critChance,
    required this.startingWeaponName,
    required this.startingWeaponDesc,
    required this.specialAbilityName,
    required this.specialAbilityDesc,
    required this.createStartingWeapon,
    required this.speedRating,
    required this.defenseRating,
    required this.firepowerRating,
    required this.primaryColor,
    required this.accentColor,
    required this.hudNeutralAsset,
    required this.hudDamagedAsset,
    required this.hudUltimateAsset,
    required this.hangarFullBodyAsset,
    required this.shipAsset,
    this.isSecret = false,
  });

  static final List<Valkyrie> roster = [
    // 1. LYRA - The Solar Vanguard
    Valkyrie(
      id: 'lyra',
      name: 'Lyra',
      callsign: 'Solar Vanguard',
      title: 'High-Velocity Strike Pilot',
      bio: 'Fearless ace pilot of the Vanguard Fleet. Wielding a cybernetic interceptor suit and acoustic mecha headset, she shatters enemy lines with blazing vulcan fire.',
      quote: '"Full throttle into the void! Try to keep up, Commander!"',
      shipName: 'AV-01 Sol Blaze',
      shipDesign: ValkyrieShipDesign.solBlaze,
      baseHull: 100.0,
      baseShield: 50.0,
      speedMultiplier: 1.25,
      magnetRadiusMultiplier: 1.1,
      critChance: 0.10,
      startingWeaponName: 'Twin Vulcan Plasma',
      startingWeaponDesc: 'High-speed dual kinetic plasma bolts with blazing fire rate.',
      specialAbilityName: 'Hyper-Overdrive Dash',
      specialAbilityDesc: 'Instant 300% thrust boost with 1.5s complete invulnerability, leaving a burning trail.',
      createStartingWeapon: () => Blaster(),
      speedRating: 5,
      defenseRating: 3,
      firepowerRating: 4,
      primaryColor: const Color(0xFFFF5722), // Blazing Solar Orange
      accentColor: const Color(0xFFFFEB3B),  // Plasma Yellow
      hudNeutralAsset: 'assets/art/valkyries/lyra/hud_neutral.png',
      hudDamagedAsset: 'assets/art/valkyries/lyra/hud_damaged.png',
      hudUltimateAsset: 'assets/art/valkyries/lyra/hud_ultimate.png',
      hangarFullBodyAsset: 'assets/art/valkyries/lyra/hangar_fullbody.png',
      shipAsset: 'assets/art/valkyries/lyra/ship_topdown.png',
    ),

    // 2. SELENE - The Void Tactician
    Valkyrie(
      id: 'selene',
      name: 'Selene',
      callsign: 'Void Tactician',
      title: 'Strategic Shield Commander',
      bio: 'Former quantum physics researcher turned fleet strategist. Commands the battlefield through amplified energy barriers, wide-spectrum Stardust extraction, and piercing phase beams.',
      quote: '"Trajectory locked. All hostiles within tactical calculation will be neutralized."',
      shipName: 'AV-02 Aegis Prism',
      shipDesign: ValkyrieShipDesign.aegisPrism,
      baseHull: 120.0,
      baseShield: 100.0,
      speedMultiplier: 0.95,
      magnetRadiusMultiplier: 1.45,
      critChance: 0.05,
      startingWeaponName: 'Phase Laser Beam',
      startingWeaponDesc: 'Piercing coherent photon beam that cuts through multiple targets in a line.',
      specialAbilityName: 'Singularity Barrier',
      specialAbilityDesc: 'Deploys an impenetrable spherical forcefield for 5 seconds that reflects incoming projectiles.',
      createStartingWeapon: () => RapidFire(),
      speedRating: 3,
      defenseRating: 5,
      firepowerRating: 4,
      primaryColor: const Color(0xFF00E5FF), // Electric Cyan
      accentColor: const Color(0xFFE0F7FA),  // Prismatic Silver
      hudNeutralAsset: 'assets/art/valkyries/selene/hud_neutral.png',
      hudDamagedAsset: 'assets/art/valkyries/selene/hud_damaged.png',
      hudUltimateAsset: 'assets/art/valkyries/selene/hud_ultimate.png',
      hangarFullBodyAsset: 'assets/art/valkyries/selene/hangar_fullbody.png',
      shipAsset: 'assets/art/valkyries/selene/ship_topdown.png',
    ),

    // 3. VESPER - The Dread Renegade (Tomboy / Heavy Gunner)
    Valkyrie(
      id: 'vesper',
      name: 'Vesper',
      callsign: 'Dread Renegade',
      title: 'Antimatter Heavy Demolitionist',
      bio: 'Unorthodox tomboy mercenary with an insatiable appetite for heavy ordnance. Specializes in cluster antimatter bombs, extreme critical impact damage, and high-risk maneuvers.',
      quote: '"Did someone call for a catastrophic explosion? Stand back and watch the fireworks!"',
      shipName: 'AV-03 Eclipse Fang',
      shipDesign: ValkyrieShipDesign.eclipseFang,
      baseHull: 90.0,
      baseShield: 40.0,
      speedMultiplier: 1.10,
      magnetRadiusMultiplier: 1.0,
      critChance: 0.25,
      startingWeaponName: 'Antimatter Cluster Flak',
      startingWeaponDesc: 'Devastating high-spread volatile shells that detonate on contact.',
      specialAbilityName: 'Void Nova Detonation',
      specialAbilityDesc: 'Detonates an omnidirectional antimatter wave that obliterates all standard asteroids and enemy probes on screen.',
      createStartingWeapon: () => BombLauncher(),
      speedRating: 4,
      defenseRating: 2,
      firepowerRating: 5,
      primaryColor: const Color(0xFFD500F9), // Deep Void Magenta
      accentColor: const Color(0xFF212121),  // Stealth Carbon Black
      hudNeutralAsset: 'assets/art/valkyries/vesper/hud_neutral.png',
      hudDamagedAsset: 'assets/art/valkyries/vesper/hud_damaged.png',
      hudUltimateAsset: 'assets/art/valkyries/vesper/hud_ultimate.png',
      hangarFullBodyAsset: 'assets/art/valkyries/vesper/hangar_fullbody.png',
      shipAsset: 'assets/art/valkyries/vesper/ship_topdown.png',
    ),
  ];

  // Secret 4th Valkyrie (Unlocked via Konami Code / Ancient Cryo-Pod)
  static final Valkyrie secretValkyrie = Valkyrie(
    id: 'astraea',
    name: 'Astraea',
    callsign: 'Origin Matriarch',
    title: 'Ancient Precursor Valkyrie',
    bio: 'The legendary progenitor Valkyrie awakened from millennial stasis. Radiates sovereign celestial energy, channeling ancient hyper-advanced alien tech.',
    quote: '"The stars have called my name once more. Behold the origin of cosmic power."',
    shipName: 'AV-00 Origin Prime',
    shipDesign: ValkyrieShipDesign.originPrime,
    baseHull: 150.0,
    baseShield: 120.0,
    speedMultiplier: 1.30,
    magnetRadiusMultiplier: 1.8,
    critChance: 0.35,
    startingWeaponName: 'Supernova Annihilator',
    startingWeaponDesc: 'Twin golden beams of concentrated starfire with infinite line penetration.',
    specialAbilityName: 'Genesis Nova',
    specialAbilityDesc: 'Releases the primordial light of creation, vaporizing all hostiles.',
    createStartingWeapon: () {
      final b = Blaster();
      b.level = 3;
      b.evolve();
      return b;
    },
    speedRating: 5,
    defenseRating: 5,
    firepowerRating: 5,
    primaryColor: const Color(0xFFFFD700), // Imperial Gold
    accentColor: const Color(0xFFFFFFFF),  // Pure Stellar White
    hudNeutralAsset: 'assets/art/valkyries/astraea/hud_neutral.png',
    hudDamagedAsset: 'assets/art/valkyries/astraea/hud_damaged.png',
    hudUltimateAsset: 'assets/art/valkyries/astraea/hud_ultimate.png',
    hangarFullBodyAsset: 'assets/art/valkyries/astraea/hangar_fullbody.png',
    shipAsset: 'assets/art/valkyries/lyra/ship_topdown.png',
    isSecret: true,
  );

  static List<Valkyrie> get allValkyries => [...roster, secretValkyrie];

  static Valkyrie get defaultValkyrie => roster.first;

  static Valkyrie findById(String id) {
    return allValkyries.firstWhere(
      (v) => v.id == id,
      orElse: () => defaultValkyrie,
    );
  }
}
