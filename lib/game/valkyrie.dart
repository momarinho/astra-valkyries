import 'package:flutter/material.dart';
import 'package:asteroids/services/localization_service.dart';
import 'weapons.dart';

enum ValkyrieShipDesign {
  zephyrBlade,  // Kaede: Ultra-sleek needle interceptor with swept katana-wings (Cyber Cyan/Midnight)
  solBlaze,     // Lyra: Aerodynamic twin-engine vanguard interceptor (Orange/Crimson)
  aegisPrism,   // Selene: High-tech crystalline prism with shield pylons (Cyan/Silver)
  eclipseFang,  // Vesper: Forward-swept wing stealth heavy fighter (Black/Magenta)
  originPrime,  // Astraea: Mythical precursor starframe (Gold/White)
}

class Valkyrie {
  final String id;
  final String name;
  final String callsign;
  final String titlePt;
  final String? titleEn;
  final String bioPt;
  final String? bioEn;
  final String quotePt;
  final String? quoteEn;
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
  final String startingWeaponDescPt;
  final String? startingWeaponDescEn;
  final String specialAbilityName;
  final String specialAbilityDescPt;
  final String? specialAbilityDescEn;
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

  String get title => I18n.isPt ? titlePt : (titleEn ?? titlePt);
  String get bio => I18n.isPt ? bioPt : (bioEn ?? bioPt);
  String get quote => I18n.isPt ? quotePt : (quoteEn ?? quotePt);
  String get startingWeaponDesc => I18n.isPt ? startingWeaponDescPt : (startingWeaponDescEn ?? startingWeaponDescPt);
  String get specialAbilityDesc => I18n.isPt ? specialAbilityDescPt : (specialAbilityDescEn ?? specialAbilityDescPt);

  const Valkyrie({
    required this.id,
    required this.name,
    required this.callsign,
    String? title,
    String? titlePt,
    this.titleEn,
    String? bio,
    String? bioPt,
    this.bioEn,
    String? quote,
    String? quotePt,
    this.quoteEn,
    required this.shipName,
    required this.shipDesign,
    required this.baseHull,
    required this.baseShield,
    required this.speedMultiplier,
    required this.magnetRadiusMultiplier,
    required this.critChance,
    required this.startingWeaponName,
    String? startingWeaponDesc,
    String? startingWeaponDescPt,
    this.startingWeaponDescEn,
    required this.specialAbilityName,
    String? specialAbilityDesc,
    String? specialAbilityDescPt,
    this.specialAbilityDescEn,
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
  })  : titlePt = titlePt ?? title ?? '',
        bioPt = bioPt ?? bio ?? '',
        quotePt = quotePt ?? quote ?? '',
        startingWeaponDescPt = startingWeaponDescPt ?? startingWeaponDesc ?? '',
        specialAbilityDescPt = specialAbilityDescPt ?? specialAbilityDesc ?? '';

  static final List<Valkyrie> roster = [
    // 0. KBR-01 - The Voidblade Ace (Protagonista Principal - Codename: Kimberly)
    Valkyrie(
      id: 'kbr_01',
      name: 'KBR-01',
      callsign: 'Shadow Lotus',
      titlePt: 'Pilota Ás da Lâmina do Vazio // Protocolo Kimberly',
      titleEn: 'Voidblade Ace Pilot // Protocol Kimberly',
      bioPt: 'Designação tática de elite KBR-01 ("Kimberly"). Silenciosa, esguia e com foco cirúrgico no cockpit, empunha lâminas taquiônicas capazes de aparar disparos inimigos em pleno voo e dobra o espaço com o passo dimensional Shunpo.',
      bioEn: 'Elite tactical designation KBR-01 ("Kimberly"). Silent, poised, and with surgical precision in the cockpit, she wields tachyon blades capable of parrying enemy fire mid-flight and folds spacetime with dimensional Shunpo strides.',
      quotePt: '"Protocolo KBR sincronizado. Cada fração de segundo no vácuo é um corte decisivo."',
      quoteEn: '"KBR Protocol synchronized. Every fraction of a second in the void is a decisive cut."',
      shipName: 'AV-00 Muramasa',
      shipDesign: ValkyrieShipDesign.zephyrBlade,
      baseHull: 85.0,
      baseShield: 65.0,
      speedMultiplier: 1.35,
      magnetRadiusMultiplier: 1.25,
      critChance: 0.20,
      startingWeaponName: 'Tachyon Katana',
      startingWeaponDescPt: 'Lâminas de corte crescente taquiônico que aparam e anulam projéteis inimigos.',
      startingWeaponDescEn: 'Tachyon crescent wave blades that parry and nullify incoming enemy projectiles.',
      specialAbilityName: 'Phantom Slash',
      specialAbilityDescPt: 'Teletransporte para frente com 3.5s de invulnerabilidade e surto radial de 16 lâminas de vácuo.',
      specialAbilityDescEn: 'Dimensional flash forward with 3.5s invulnerability and radial burst of 16 void blades.',
      createStartingWeapon: () => TachyonKatana(),
      speedRating: 5,
      defenseRating: 2,
      firepowerRating: 5,
      primaryColor: const Color(0xFF00E5FF), // Cyber Cyan
      accentColor: const Color(0xFF0D1B2A),  // Midnight Carbon
      hudNeutralAsset: 'assets/art/valkyries/kbr_01/hud_neutral.png',
      hudDamagedAsset: 'assets/art/valkyries/kbr_01/hud_damaged.png',
      hudUltimateAsset: 'assets/art/valkyries/kbr_01/hud_ultimate.png',
      hangarFullBodyAsset: 'assets/art/valkyries/kbr_01/hangar_fullbody.png',
      shipAsset: 'assets/art/valkyries/kbr_01/ship_topdown.png',
    ),

    // 1. LYRA - The Solar Vanguard
    Valkyrie(
      id: 'lyra',
      name: 'Lyra',
      callsign: 'Solar Vanguard',
      titlePt: 'Pilota de Ataque de Alta Velocidade',
      titleEn: 'High-Velocity Strike Pilot',
      bioPt: 'Pilota ás destemida da Frota Vanguard. Trajando um exo-traje cibernético com headset acústico mecha, abre caminho nas linhas inimigas com disparos incandescentes de plasma vulcan.',
      bioEn: 'Fearless ace pilot of the Vanguard Fleet. Wielding a cybernetic interceptor suit and acoustic mecha headset, she shatters enemy lines with blazing vulcan fire.',
      quotePt: '"Aceleração total no vácuo! Tente acompanhar, Comandante!"',
      quoteEn: '"Full throttle into the void! Try to keep up, Commander!"',
      shipName: 'AV-01 Sol Blaze',
      shipDesign: ValkyrieShipDesign.solBlaze,
      baseHull: 100.0,
      baseShield: 50.0,
      speedMultiplier: 1.25,
      magnetRadiusMultiplier: 1.1,
      critChance: 0.10,
      startingWeaponName: 'Twin Vulcan Plasma',
      startingWeaponDescPt: 'Projéteis duplos de plasma cinético de alta cadência e velocidade extrema.',
      startingWeaponDescEn: 'High-speed dual kinetic plasma bolts with blazing fire rate.',
      specialAbilityName: 'Hyper-Overdrive Dash',
      specialAbilityDescPt: 'Impulso instantâneo de 300% de propulsão com 1.5s de invulnerabilidade total e rastro incandescente.',
      specialAbilityDescEn: 'Instant 300% thrust boost with 1.5s complete invulnerability, leaving a burning trail.',
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
      titlePt: 'Comandante Estratégica de Escudos',
      titleEn: 'Strategic Shield Commander',
      bioPt: 'Ex-pesquisadora de física quântica tornada estrategista de frota. Domina o campo de batalha com barreiras de energia amplificadas, colheita de espectro amplo de Poeira Estelar e raios de fase perfurantes.',
      bioEn: 'Former quantum physics researcher turned fleet strategist. Commands the battlefield through amplified energy barriers, wide-spectrum Stardust extraction, and piercing phase beams.',
      quotePt: '"Trajetória travada. Todos os alvos sob cálculo tático serão neutralizados."',
      quoteEn: '"Trajectory locked. All hostiles within tactical calculation will be neutralized."',
      shipName: 'AV-02 Aegis Prism',
      shipDesign: ValkyrieShipDesign.aegisPrism,
      baseHull: 120.0,
      baseShield: 100.0,
      speedMultiplier: 0.95,
      magnetRadiusMultiplier: 1.45,
      critChance: 0.05,
      startingWeaponName: 'Phase Laser Beam',
      startingWeaponDescPt: 'Feixe fotônico coerente perfurante que atravessa múltiplos alvos em linha reta.',
      startingWeaponDescEn: 'Piercing coherent photon beam that cuts through multiple targets in a line.',
      specialAbilityName: 'Singularity Barrier',
      specialAbilityDescPt: 'Projeta um campo de força esférico impenetrável por 5 segundos que reflete disparos inimigos.',
      specialAbilityDescEn: 'Deploys an impenetrable spherical forcefield for 5 seconds that reflects incoming projectiles.',
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
      titlePt: 'Especialista em Demolição de Antimatéria',
      titleEn: 'Antimatter Heavy Demolitionist',
      bioPt: 'Mercenária rebelde e audaciosa com apetite insaciável por artilharia pesada. Especialista em bombas de antimatéria em cacho, dano de impacto crítico extremo e manobras arriscadas no limite.',
      bioEn: 'Unorthodox tomboy mercenary with an insatiable appetite for heavy ordnance. Specializes in cluster antimatter bombs, extreme critical impact damage, and high-risk maneuvers.',
      quotePt: '"Alguém pediu uma explosão catastrófica? Afastem-se e aproveitem os fogos de artifício!"',
      quoteEn: '"Did someone call for a catastrophic explosion? Stand back and watch the fireworks!"',
      shipName: 'AV-03 Eclipse Fang',
      shipDesign: ValkyrieShipDesign.eclipseFang,
      baseHull: 90.0,
      baseShield: 40.0,
      speedMultiplier: 1.10,
      magnetRadiusMultiplier: 1.0,
      critChance: 0.25,
      startingWeaponName: 'Antimatter Cluster Flak',
      startingWeaponDescPt: 'Munições voláteis de dispersão ampla devastadoras que detonam ao impacto.',
      startingWeaponDescEn: 'Devastating high-spread volatile shells that detonate on contact.',
      specialAbilityName: 'Void Nova Detonation',
      specialAbilityDescPt: 'Detona uma onda omnidirecional de antimatéria que aniquila todos os projéteis e sondas na tela.',
      specialAbilityDescEn: 'Detonates an omnidirectional antimatter wave that obliterates all standard asteroids and enemy probes on screen.',
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
    titlePt: 'Valquíria Ancestral Precursora',
    titleEn: 'Ancient Precursor Valkyrie',
    bioPt: 'A lendária matriarca Valquíria despertada de um estase milenar. Irradia energia celestial soberana, canalizando tecnologia hiperavançada de eras esquecidas.',
    bioEn: 'The legendary progenitor Valkyrie awakened from millennial stasis. Radiates sovereign celestial energy, channeling ancient hyper-advanced alien tech.',
    quotePt: '"As estrelas chamaram meu nome mais uma vez. Contemplem a origem do poder cósmico."',
    quoteEn: '"The stars have called my name once more. Behold the origin of cosmic power."',
    shipName: 'AV-00 Origin Prime',
    shipDesign: ValkyrieShipDesign.originPrime,
    baseHull: 150.0,
    baseShield: 120.0,
    speedMultiplier: 1.30,
    magnetRadiusMultiplier: 1.8,
    critChance: 0.35,
    startingWeaponName: 'Supernova Annihilator',
    startingWeaponDescPt: 'Feixes dourados gêmeos de fogo estelar concentrado com perfuração infinita.',
    startingWeaponDescEn: 'Twin golden beams of concentrated starfire with infinite line penetration.',
    specialAbilityName: 'Genesis Nova',
    specialAbilityDescPt: 'Libera a luz primordial da criação cósmica, vaporizando todas as ameaças hostis.',
    specialAbilityDescEn: 'Releases the primordial light of creation, vaporizing all hostiles.',
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
    if (id == 'kaede' || id == 'kbr' || id == 'kimberly') {
      return allValkyries.firstWhere(
        (v) => v.id == 'kbr_01',
        orElse: () => defaultValkyrie,
      );
    }
    return allValkyries.firstWhere(
      (v) => v.id == id,
      orElse: () => defaultValkyrie,
    );
  }
}
