import 'package:flutter/material.dart';
import 'package:asteroids/services/localization_service.dart';

/// Representação no Códice do Arsenal de cada arma de Astra Valkyries
class WeaponCodexEntry {
  final String id;
  final String name;
  final String evolvedName;
  final String manufacturer;
  final String damageType;
  final String classification;
  final String loreDescriptionPt;
  final String? loreDescriptionEn;
  final String technicalSpecsPt;
  final String? technicalSpecsEn;
  final String pilotQuotePt;
  final String? pilotQuoteEn;
  final String pilotQuoteAuthor;
  final String evolutionTitle;
  final String evolutionDescriptionPt;
  final String? evolutionDescriptionEn;
  final String synergyPassiveTitle;
  final IconData icon;
  final Color themeColor;
  final int difficultyRating; // 1 to 5
  final int rangeRating;      // 1 to 5
  final int damageRating;     // 1 to 5
  final int fireRateRating;   // 1 to 5

  String get loreDescription =>
      I18n.isPt ? loreDescriptionPt : (loreDescriptionEn ?? loreDescriptionPt);
  String get technicalSpecs =>
      I18n.isPt ? technicalSpecsPt : (technicalSpecsEn ?? technicalSpecsPt);
  String get pilotQuote =>
      I18n.isPt ? pilotQuotePt : (pilotQuoteEn ?? pilotQuotePt);
  String get evolutionDescription =>
      I18n.isPt ? evolutionDescriptionPt : (evolutionDescriptionEn ?? evolutionDescriptionPt);

  const WeaponCodexEntry({
    required this.id,
    required this.name,
    required this.evolvedName,
    required this.manufacturer,
    required this.damageType,
    required this.classification,
    String? loreDescription,
    String? loreDescriptionPt,
    this.loreDescriptionEn,
    String? technicalSpecs,
    String? technicalSpecsPt,
    this.technicalSpecsEn,
    String? pilotQuote,
    String? pilotQuotePt,
    this.pilotQuoteEn,
    required this.pilotQuoteAuthor,
    required this.evolutionTitle,
    String? evolutionDescription,
    String? evolutionDescriptionPt,
    this.evolutionDescriptionEn,
    required this.synergyPassiveTitle,
    required this.icon,
    required this.themeColor,
    required this.difficultyRating,
    required this.rangeRating,
    required this.damageRating,
    required this.fireRateRating,
  })  : loreDescriptionPt = loreDescriptionPt ?? loreDescription ?? '',
        technicalSpecsPt = technicalSpecsPt ?? technicalSpecs ?? '',
        pilotQuotePt = pilotQuotePt ?? pilotQuote ?? '',
        evolutionDescriptionPt = evolutionDescriptionPt ?? evolutionDescription ?? '';

  static const List<WeaponCodexEntry> allEntries = [
    // 1. Tachyon Katana (Arma da Protagonista KBR-01 // Codename Kimberly)
    WeaponCodexEntry(
      id: 'tachyon_katana',
      name: 'Tachyon Katana',
      evolvedName: 'Void Muramasa',
      manufacturer: 'Kyoto-7 Orbital Skunkworks // Protocol Kimberly',
      damageType: 'Corte Quântico Taquiônico // Quantum Tachyon Slash',
      classification: 'Lâmina de Corte Dimensional & Apara Ativa',
      loreDescriptionPt:
          'Forjada na fornalha orbital de Kyoto-7 sob gravidade zero como arma exclusiva da unidade KBR-01. Condensa um feixe de táquions em uma lâmina crescente de plasma com espessura monomolecular. Seus arcos cortantes desintegram disparos inimigos em pleno ar (Tachyon Parry) e rasgam formações hostis com precisão cirúrgica.',
      loreDescriptionEn:
          'Forged in Kyoto-7 orbital foundry under zero-gravity as exclusive armament for unit KBR-01. Compresses a tachyon beam into a monomolecular plasma crescent blade. Its slashes disintegrate incoming enemy fire mid-air (Tachyon Parry) and slice hostile formations with surgical precision.',
      technicalSpecsPt:
          'Lâmina monomolecular de táquions pressurizados com velocidade de ejeção de 520 px/s, anulação frontal de projéteis e penetração contínua em arco.',
      technicalSpecsEn:
          'Monomolecular pressurized tachyon blade with 520 px/s velocity, frontal projectile parry, and continuous arc piercing.',
      pilotQuotePt:
          '"Uma espada no espaço não é anacronismo quando seu corte apara a morte e abre caminho para a vitória."',
      pilotQuoteEn:
          '"A sword in space is no anachronism when its edge parries death itself and carves the path to victory."',
      pilotQuoteAuthor: 'KBR-01 (Shadow Lotus)',
      evolutionTitle: 'Juízo Dimensional do Vazio // Void Muramasa',
      evolutionDescriptionPt:
          'Atinge a ressonância do Trono do Vazio, disparando lâminas dimensionais triplas contínuas que atravessam a tela de ponta a ponta com penetração infinita.',
      evolutionDescriptionEn:
          'Attains Void Throne resonance, releasing continuous triple dimensional blades across the screen with infinite penetration.',
      synergyPassiveTitle: 'Void Catalyst (Acelerador de Sobrecarga)',
      icon: Icons.flash_on_rounded,
      themeColor: Color(0xFF00F0FF),
      difficultyRating: 4,
      rangeRating: 5,
      damageRating: 4,
      fireRateRating: 4,
    ),

    // 2. Pulse Blaster
    WeaponCodexEntry(
      id: 'blaster',
      name: 'Pulse Blaster',
      evolvedName: 'Supernova Annihilator',
      manufacturer: 'Vanguard Tactical Skunkworks (Estaleiros de Vesta)',
      damageType: 'Plasma Cinético de Deutério // Deuterium Kinetic Plasma',
      classification: 'Rifle de Pulso Estelar',
      loreDescriptionPt:
          'O armamento padrão das esquadrilhas de interceptação durante o Cerco de Vesta. Forjado com bobinas de deutério pressurizado, foi a única arma que continuou disparando ininterruptamente quando a Primeira Frota perdeu contato com a Terra.',
      loreDescriptionEn:
          'Standard issue armament for interceptor wings during the Siege of Vesta. Built with pressurized deuterium coils, it remained operational when the First Fleet lost contact with Earth.',
      technicalSpecsPt:
          'Canhão eletromagnético com câmara de fusão magnética de deutério. Taxa de disparo estável de 0.70s calibrada para equilíbrio entre alcance e estabilidade de recuo.',
      technicalSpecsEn:
          'Electromagnetic cannon with magnetic confinement deuterium fusion chamber. Stable 0.70s fire rate calibrated for optimal recoil control.',
      pilotQuotePt:
          '"Simples, confiável e nunca emperra no vácuo. Se você sabe mirar, o Blaster faz o resto."',
      pilotQuoteEn:
          '"Simple, reliable, and never jams in the vacuum. If you can aim, the Blaster does the rest."',
      pilotQuoteAuthor: 'Lyra Vance (Solar Vanguard)',
      evolutionTitle: 'Supernova Annihilator',
      evolutionDescriptionPt:
          'A fita de deuterômeros entra em colapso nuclear contínuo, disparando feixes dourados paralelos de plasma imperial com perfuração irrestrita de tela.',
      evolutionDescriptionEn:
          'Deuterium core enters sustained nuclear cascade, firing dual golden beams of imperial plasma with infinite line pierce.',
      synergyPassiveTitle: 'Void Catalyst (Acelerador de Sobrecarga)',
      icon: Icons.bolt_rounded,
      themeColor: Color(0xFFFFB300),
      difficultyRating: 1,
      rangeRating: 4,
      damageRating: 3,
      fireRateRating: 3,
    ),

    // 3. Spread Cannon
    WeaponCodexEntry(
      id: 'spread_shot',
      name: 'Spread Cannon',
      evolvedName: 'Hyperion Flak Storm',
      manufacturer: 'Estaleiros Orbitais de Hélio (Divisão de Mineração)',
      damageType: 'Estilhaços de Íon Superaquecido // Superheated Ion Shrapnel',
      classification: 'Bateria de Dispersão Angular',
      loreDescriptionPt:
          'Projetado originalmente como um canhão de dispersão de resíduos em campos de mineração densos de asteroides. Modificado por contrabandistas de Hélio para disparar salvas triangulares incandescentes capazes de fragmentar enxames inteiros de caças leves em segundos.',
      loreDescriptionEn:
          'Originally designed as a debris-clearing scatter gun for dense asteroid belts. Modified by Helios scavengers into a tri-directional battery capable of shredding swarms of light fighters in seconds.',
      technicalSpecsPt:
          'Matriz tripla de bicos vetoriais divergentes em 30 graus. Dispara 3 projéteis de 15 de dano por salva com dispersão cônica uniforme.',
      technicalSpecsEn:
          'Triple vector nozzles diverging at 30 degrees. Fires 3 kinetic bolts of 15 damage per burst with uniform conical spread.',
      pilotQuotePt:
          '"Quando você está cercada por cinquenta drones de uma vez, mira cirúrgica é luxo. O Spread Cannon resolve o problema com um puxão de gatilho."',
      pilotQuoteEn:
          '"When surrounded by fifty drones at once, precision aiming is a luxury. The Spread Cannon clears the room with one pull."',
      pilotQuoteAuthor: 'Lyra Vance (Solar Vanguard)',
      evolutionTitle: 'Hyperion Flak Storm',
      evolutionDescriptionPt:
          'Sobrecarga no núcleo dispersor ejeta um anel concêntrico de 10 projéteis ionizados em 360 graus a cada ciclo de disparo.',
      evolutionDescriptionEn:
          'Core overload ejects a concentric 10-projectile 360-degree perimeter ring every firing cycle.',
      synergyPassiveTitle: 'Aegis Capacitor (Blindagem Regenerativa)',
      icon: Icons.grain_rounded,
      themeColor: Color(0xFF00E676),
      difficultyRating: 2,
      rangeRating: 3,
      damageRating: 4,
      fireRateRating: 3,
    ),

    // 4. Phase Laser Beam
    WeaponCodexEntry(
      id: 'rapid_fire',
      name: 'Phase Laser',
      evolvedName: 'Absolute Zero Tachyon Beam',
      manufacturer: 'Consórcio Criogênico de Tritão',
      damageType: 'Radiação Eletromagnética Coerente // Coherent Laser Beam',
      classification: 'Laser de Fase Linear Contínua',
      loreDescriptionPt:
          'Desenvolvido pela Dra. Selene Aris durante os testes com matrizes de cristais de prisma em gravidade zero. O Phase Laser condensa fótons em frequências taquiônicas capazes de atravessar a blindagem de múltiplos alvos sem dissipar sua energia térmica.',
      loreDescriptionEn:
          'Engineered by Dr. Selene Aris during zero-G prism crystal trials. Condenses photons into tachyon frequencies that pierce through multiple hull plates without energy dissipation.',
      technicalSpecsPt:
          'Emissor de feixe contínuo colimado. Alcance de tela cheia, perfuração irrestrita de alvos e alta frequência de pulsos.',
      technicalSpecsEn:
          'Collimated continuous beam emitter. Full-screen range, unhindered target penetration, and rapid pulse repetition.',
      pilotQuotePt:
          '"A luz não negocia com obstáculos. Cada feixe segue a linha mais pura até a aniquilação do alvo."',
      pilotQuoteEn:
          '"Light does not negotiate with obstacles. Each beam follows the purest line to target destruction."',
      pilotQuoteAuthor: 'Selene Aris (Void Tactician)',
      evolutionTitle: 'Absolute Zero Tachyon Beam',
      evolutionDescriptionPt:
          'Alcança ressonância termodinâmica subatômica, disparando um feixe crio-taquiônico que perfura infinitamente congelando alvos em zero absoluto.',
      evolutionDescriptionEn:
          'Attains subatomic thermodynamic resonance, unleashing a cryo-tachyon beam freezing targets at absolute zero.',
      synergyPassiveTitle: 'Overclocked Emitters (Cadência de Tiro)',
      icon: Icons.fast_forward_rounded,
      themeColor: Color(0xFF2979FF),
      difficultyRating: 3,
      rangeRating: 5,
      damageRating: 4,
      fireRateRating: 5,
    ),

    // 5. Antimatter Torpedo
    WeaponCodexEntry(
      id: 'bomb_launcher',
      name: 'Antimatter Torpedo',
      evolvedName: 'Singularity Rift Torpedo',
      manufacturer: 'Arsenal Proibido de Titã (Divisão Ômega)',
      damageType: 'Colapso de Antimatéria // Antimatter Annihilation',
      classification: 'Artilharia Pesada de Ogivas de Vácuo',
      loreDescriptionPt:
          'Classificado como armamento de categoria proibida pelos tratados de não-proliferação de Titã. Cada ogiva contém 2 miligramas de pósitrons magneticamente confinados que liberam uma detonação cataclísmica capaz de vaporizar cruzadores leves inteiros.',
      loreDescriptionEn:
          'Classified as forbidden ordnance under Titan non-proliferation treaties. Contains magnetically trapped positrons that unleash a cataclysmic blast obliterating light cruisers.',
      technicalSpecsPt:
          'Ogiva balística autoguiada com rastro de fusão. Raio de detonação em área de 140px, 45 de dano base e onda de impacto expansiva.',
      technicalSpecsEn:
          'Self-guided fusion warhead with 140px blast radius, 45 base damage, and expanding concussive shockwave.',
      pilotQuotePt:
          '"Se você precisa de sutileza, use uma agulha. Se precisa que uma frota inteira pare de existir, me dê um Torpedo de Antimatéria."',
      pilotQuoteEn:
          '"If you want subtlety, use a needle. If you want an entire hostile fleet to cease existing, hand me an Antimatter Torpedo."',
      pilotQuoteAuthor: 'Vesper Cruz (Dread Renegade)',
      evolutionTitle: 'Singularity Rift Torpedo',
      evolutionDescriptionPt:
          'Detona um micro-buraco negro gravitacional na zona de impacto, atraindo asteroides e inimigos antes do colapso final.',
      evolutionDescriptionEn:
          'Detonates a localized micro black hole at impact point, pulling debris and foes into gravity collapse.',
      synergyPassiveTitle: 'Magnetic Harvester (Raio Magnético)',
      icon: Icons.gps_fixed_rounded,
      themeColor: Color(0xFFFF6D00),
      difficultyRating: 4,
      rangeRating: 4,
      damageRating: 5,
      fireRateRating: 1,
    ),

    // 6. Aegis Sawblades
    WeaponCodexEntry(
      id: 'aegis_sawblades',
      name: 'Aegis Sawblades',
      evolvedName: 'Celestial Buzzsaw Ring',
      manufacturer: 'Consórcio de Mineração Pesada de Calisto',
      damageType: 'Corte Cinético Monomolecular // Monomolecular Kinetic',
      classification: 'Lâminas Orbitais de Defesa Proativa',
      loreDescriptionPt:
          'Adaptadas de serras de corte mineral de asteroides ultradensos em Calisto. Foram reprojetadas com estabilizadores de gravidade de curto alcance para orbitar o casco da nave, transformando o perímetro defensivo em um triturador letal.',
      loreDescriptionEn:
          'Adapted from ultradense mineral cutters on Callisto. Re-engineered with localized gravity stabilizers to orbit the ship hull, turning defensive perimeter into a lethal buzzsaw.',
      technicalSpecsPt:
          '3 serras monomoleculares com rotação angular constante de 2.2 rad/s. Colisão persistente de 18 de dano por contato.',
      technicalSpecsEn:
          '3 monomolecular blades with constant 2.2 rad/s angular speed. Deals 18 persistent contact damage per tick.',
      pilotQuotePt:
          '"Inimigos que tentam abalroar minha nave aprendem da pior forma: quem encosta no meu escudo vira pó metálico."',
      pilotQuoteEn:
          '"Enemies attempting to ram my ship learn the hard way: anything touching my perimeter turns into metal shavings."',
      pilotQuoteAuthor: 'Selene Aris (Void Tactician)',
      evolutionTitle: 'Celestial Buzzsaw Ring',
      evolutionDescriptionPt:
          'Dobra o número de lâminas para 6 serras precursoras douradas em rotação supersônica que anulam projéteis inimigos.',
      evolutionDescriptionEn:
          'Doubles blades to 6 golden precursor buzzsaws orbiting at supersonic speed, shredding enemy fire.',
      synergyPassiveTitle: 'Aegis Capacitor (Blindagem Regenerativa)',
      icon: Icons.rotate_right_rounded,
      themeColor: Color(0xFF00E5FF),
      difficultyRating: 2,
      rangeRating: 2,
      damageRating: 4,
      fireRateRating: 4,
    ),

    // 7. Tesla Arc Cannon
    WeaponCodexEntry(
      id: 'tesla_arc',
      name: 'Tesla Arc Cannon',
      evolvedName: 'Mjolnir Storm Conduit',
      manufacturer: 'Estaleiros Navais do Encouraçado Aegis-IV',
      damageType: 'Arco Elétrico de Alta Voltagem // High-Voltage Tesla Arc',
      classification: 'Canhão Eletrostático de Cadeia',
      loreDescriptionPt:
          'Canhão desenvolvido para desativar a eletrônica de drones hostis através de sobrecargas de relâmpagos em arco no vácuo ionizado.',
      loreDescriptionEn:
          'Engineered to fry hostile drone avionics using high-voltage lightning arcs propagated through ionized space.',
      technicalSpecsPt:
          'Descarga dielétrica de 28 de dano base. Salta instantaneamente entre até 4 alvos adjacentes aplicando efeito Ion Shock.',
      technicalSpecsEn:
          'Dielectric discharge of 28 base damage. Chains instantly across up to 4 targets inflicting Ion Shock.',
      pilotQuotePt:
          '"Um tiro, dez alvos fritos. A eletricidade sempre escolhe o caminho mais rápido para a destruição."',
      pilotQuoteEn:
          '"One bolt, ten targets fried. Electricity always finds the quickest path to destruction."',
      pilotQuoteAuthor: 'Vesper Cruz (Dread Renegade)',
      evolutionTitle: 'Mjolnir Storm Conduit',
      evolutionDescriptionPt:
          'Aumenta os saltos de cadeia para 8 alvos com relâmpagos azuis estocásticos de dano duplicado.',
      evolutionDescriptionEn:
          'Increases chain jumps to 8 targets with stochastic blue lightning bolts dealing double damage.',
      synergyPassiveTitle: 'Overclocked Emitters (Cadência de Tiro)',
      icon: Icons.electric_bolt_rounded,
      themeColor: Color(0xFF80D8FF),
      difficultyRating: 2,
      rangeRating: 4,
      damageRating: 3,
      fireRateRating: 3,
    ),

    // 8. Quantum Chakram
    WeaponCodexEntry(
      id: 'quantum_chakram',
      name: 'Quantum Chakram',
      evolvedName: 'Chronos Eclipse Glaive',
      manufacturer: 'Ordem de Caelum (Artífices de Relíquias)',
      damageType: 'Ressonância Gravitacional Crio-Temporal // Cryo-Temporal Glaive',
      classification: 'Lâmina Bumerangue Quântica',
      loreDescriptionPt:
          'Arma cerimonial milenar dos guardiões de Caelum. Forjada a partir de meteoritos hiperdensos dopados com cronotrons.',
      loreDescriptionEn:
          'Ancient ceremonial armament of Caelum guardians. Forged from hyperdense meteorites laced with chronotrons.',
      technicalSpecsPt:
          'Projétil curvo com aceleração de retorno de 1.8x. Causa 22 de dano na ida e 165% de dano extra no trajeto de volta.',
      technicalSpecsEn:
          'Curved boomerang projectile with 1.8x return acceleration. 22 base damage outbound, 165% return damage bonus.',
      pilotQuotePt:
          '"O que vai volta — e quando volta pelo casco de um cruzador inimigo, a sensação é maravilhosa."',
      pilotQuoteEn:
          '"What goes around comes around — and when it cuts through an enemy cruiser on the return, it feels glorious."',
      pilotQuoteAuthor: 'Lyra Vance (Solar Vanguard)',
      evolutionTitle: 'Chronos Eclipse Glaive',
      evolutionDescriptionPt:
          'Dispara 3 glaives simultâneos que congelam os inimigos atingidos e orbitam no ponto de retorno.',
      evolutionDescriptionEn:
          'Fires 3 simultaneous chronos glaives freezing hit enemies and orbiting at the apex.',
      synergyPassiveTitle: 'Quantum Thrusters (Propulsão Quântica)',
      icon: Icons.all_out_rounded,
      themeColor: Color(0xFF00E676),
      difficultyRating: 3,
      rangeRating: 4,
      damageRating: 4,
      fireRateRating: 3,
    ),

    // 9. Repulsor Gravity Aura
    WeaponCodexEntry(
      id: 'repulsor_aura',
      name: 'Repulsor Gravity Aura',
      evolvedName: 'Event Horizon Nova Pulse',
      manufacturer: 'Laboratórios de Propulsão Gravitacional de Encélado',
      damageType: 'Onda Gravitacional de Pulso Escalar // Gravitational Shockwave',
      classification: 'Emissor de Campo de Repulsão Perimétrica',
      loreDescriptionPt:
          'Projetado como sistema de contenção de asteroides desgovernados em minas orbitais profundas.',
      loreDescriptionEn:
          'Engineered as a runaway asteroid containment system for deep space mining platforms.',
      technicalSpecsPt:
          'Pulso radial com raio de expansão de 200px a cada 1.8s. Causa 20 de dano e repele fisicamente inimigos.',
      technicalSpecsEn:
          'Radial pulse expanding 200px every 1.8s. Deals 20 damage and applies physical knockback.',
      pilotQuotePt:
          '"Mantenha distância. Meu espaço pessoal é de duzentos pixels e é garantido por gravidade pura."',
      pilotQuoteEn:
          '"Keep your distance. My personal space is two hundred pixels wide and enforced by gravity."',
      pilotQuoteAuthor: 'Selene Aris (Void Tactician)',
      evolutionTitle: 'Event Horizon Nova Pulse',
      evolutionDescriptionPt:
          'Converte o pulso em onda de choque de horizonte de eventos, aplicando Ruptura do Vazio que desintegra inimigos repelidos.',
      evolutionDescriptionEn:
          'Converts pulse into event horizon shockwave, inflicting Void Rupture that disintegrates knocked-back foes.',
      synergyPassiveTitle: 'Magnetic Harvester (Raio Magnético)',
      icon: Icons.radar_rounded,
      themeColor: Color(0xFFE040FB),
      difficultyRating: 2,
      rangeRating: 3,
      damageRating: 3,
      fireRateRating: 3,
    ),

    // 10. Solar Thermal Lance
    WeaponCodexEntry(
      id: 'solar_lance',
      name: 'Solar Thermal Lance',
      evolvedName: 'Helios Core Melter',
      manufacturer: 'Forja Coronal de Órion',
      damageType: 'Fogo Coronal Termonuclear // Coronal Starfire',
      classification: 'Lança Térmica Solar de Fusão',
      loreDescriptionPt:
          'Canaliza plasma diretamente de cápsulas solares comprimidas da forja de Hélio.',
      loreDescriptionEn:
          'Channels plasma drawn directly from compressed solar cells harvested in the Helios forge.',
      technicalSpecsPt:
          'Feixe frontal espesso de 45 de dano/s contínuo com acúmulo de Queimadura Solar em 3 estágios.',
      technicalSpecsEn:
          'Dense frontal beam dealing 45 dps continuously with 3-stage Solar Burn stacking.',
      pilotQuotePt:
          '"O calor do sol na ponta dos dedos. Nada no vácuo resiste a três milhões de graus Kelvin."',
      pilotQuoteEn:
          '"The heat of a star at my fingertips. Nothing in the void can withstand three million Kelvin."',
      pilotQuoteAuthor: 'Lyra Vance (Solar Vanguard)',
      evolutionTitle: 'Helios Core Melter',
      evolutionDescriptionPt:
          'Amplia a largura da lança solar em 250%, derretendo asteroides e blindagens pesadas instantaneamente.',
      evolutionDescriptionEn:
          'Expands solar lance width by 250%, melting heavy armor and asteroids on contact.',
      synergyPassiveTitle: 'Void Catalyst (Acelerador de Sobrecarga)',
      icon: Icons.wb_sunny_rounded,
      themeColor: Color(0xFFFF5722),
      difficultyRating: 3,
      rangeRating: 5,
      damageRating: 5,
      fireRateRating: 4,
    ),

    // 11. Inferno Plasma Cone
    WeaponCodexEntry(
      id: 'inferno_cone',
      name: 'Inferno Plasma Cone',
      evolvedName: 'Phoenix Dragon Breath',
      manufacturer: 'Modificação Clandestina de Hangar (Oficina de Lyra Vance)',
      damageType: 'Incandescência Plasma de Curto Alcance // Cone Flamethrower',
      classification: 'Lança-Chamas de Vácuo em Cone',
      loreDescriptionPt:
          'Uma modificação ilegal dos exaustores de propulsão dos caças Vanguard.',
      loreDescriptionEn:
          'An illicit retrofit of Vanguard thruster exhaust manifolds.',
      technicalSpecsPt:
          'Cone frontal de 70 graus com alcance de 220px. Dispara 12 labaredas por segundo.',
      technicalSpecsEn:
          '70-degree frontal cone with 220px reach. Sprays 12 plasma bursts per second.',
      pilotQuotePt:
          '"Os manuais da frota dizem para não desviar combustível para os canos dianteiros. Eu digo que funciona que é uma beleza."',
      pilotQuoteEn:
          '"Fleet manuals say not to pipe rocket fuel into the forward guns. I say it works wonders."',
      pilotQuoteAuthor: 'Lyra Vance (Solar Vanguard)',
      evolutionTitle: 'Phoenix Dragon Breath',
      evolutionDescriptionPt:
          'Expande o cone para 5 labaredas massivas de fogo de dragão com penetração e queima acelerada.',
      evolutionDescriptionEn:
          'Expands cone into 5 dragonfire flame plumes with deep penetration and accelerated burn.',
      synergyPassiveTitle: 'Void Catalyst (Acelerador de Sobrecarga)',
      icon: Icons.local_fire_department_rounded,
      themeColor: Color(0xFFFF9100),
      difficultyRating: 2,
      rangeRating: 2,
      damageRating: 4,
      fireRateRating: 5,
    ),

    // 12. Valkyrie Wingmen
    WeaponCodexEntry(
      id: 'valkyrie_wingmen',
      name: 'Valkyrie Wingmen',
      evolvedName: 'Seraphim Drone Squadron',
      manufacturer: 'Complexo Memorial de Valhalla Orbital',
      damageType: 'Tiro Cinético Duplo de Apoio // Kinetic Escort Fire',
      classification: 'Esquadrilha de Drones Autônomos',
      loreDescriptionPt:
          'Drones de suporte tático programados com algoritmos de escolta desenvolvidos na Primeira Guerra da Singularidade.',
      loreDescriptionEn:
          'Tactical escort drones programmed with swarm algorithms developed during the First Singularity War.',
      technicalSpecsPt:
          '2 caças drones autônomos que orbitam a nave mãe e engajam alvos prioritários a 350px de distância.',
      technicalSpecsEn:
          '2 autonomous escort drones orbiting the mothership and engaging hostiles within 350px radius.',
      pilotQuotePt:
          '"Eu nunca voo sozinha. As vozes delas nos meus fones me avisam de qualquer ameaça antes mesmo dos meus sensores."',
      pilotQuoteEn:
          '"I never fly alone. Their telemetry in my headset warns me of threats before my sensors do."',
      pilotQuoteAuthor: 'KBR-01 (Shadow Lotus)',
      evolutionTitle: 'Seraphim Drone Squadron',
      evolutionDescriptionPt:
          'Mobiliza 4 caças Seraphim dourados de interceptação de alta manobrabilidade com canhões gêmeos ionizados.',
      evolutionDescriptionEn:
          'Deploys 4 golden Seraphim interceptors with high agility and twin ionized pulse guns.',
      synergyPassiveTitle: 'Overclocked Emitters (Cadência de Tiro)',
      icon: Icons.flight_class_rounded,
      themeColor: Color(0xFFFFD54F),
      difficultyRating: 1,
      rangeRating: 4,
      damageRating: 3,
      fireRateRating: 4,
    ),

    // 13. Void Cluster Mines
    WeaponCodexEntry(
      id: 'void_mines',
      name: 'Void Cluster Mines',
      evolvedName: 'Abyssal Minefield Matrix',
      manufacturer: 'Oficinas de Guerrilha do Cinturão Sombrio',
      damageType: 'Ruptura de Matéria Escura // Dark Matter Rupture',
      classification: 'Minas Espaciais Proximidade em Ré',
      loreDescriptionPt:
          'Armamento defensivo assimétrico desenvolvido por rebeldes mineradores para emboscar patrulhas leviatãs.',
      loreDescriptionEn:
          'Asymmetric defensive ordnance engineered by asteroid miners to ambush pursue patrols.',
      technicalSpecsPt:
          'Lança 2 minas magnéticas a cada 1.6s na ré. Detonam ao toque causando 35 de dano em área com efeito Ruptura do Vazio.',
      technicalSpecsEn:
          'Deploys 2 magnetic proximity mines every 1.6s in reverse. 35 blast damage with Void Rupture effect.',
      pilotQuotePt:
          '"Quer me perseguir? Fique à vontade. O caminho atrás de mim é um campo minado de matéria escura."',
      pilotQuoteEn:
          '"Want to chase me? Be my guest. The trail behind my thrusters is a dark matter minefield."',
      pilotQuoteAuthor: 'Vesper Cruz (Dread Renegade)',
      evolutionTitle: 'Abyssal Minefield Matrix',
      evolutionDescriptionPt:
          'Ejeta 3 minas em leque posterior com raio de detonação duplicado e fragmentação de submunições.',
      evolutionDescriptionEn:
          'Ejects 3 cluster mines in a rear fan with doubled blast radius and submunition fragmentation.',
      synergyPassiveTitle: 'Quantum Thrusters (Propulsão Quântica)',
      icon: Icons.brightness_low_rounded,
      themeColor: Color(0xFFAA00FF),
      difficultyRating: 3,
      rangeRating: 3,
      damageRating: 4,
      fireRateRating: 2,
    ),
  ];

  static WeaponCodexEntry? findById(String id) {
    for (final entry in allEntries) {
      if (entry.id == id) return entry;
    }
    return null;
  }
}
