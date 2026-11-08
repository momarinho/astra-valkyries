import 'package:flutter/material.dart';
import 'weapons.dart';

/// Definição de um Diagrama Tecnológico (Blueprint) da Forja da Oficina (Sprint 16 & Sprint 22 Lore)
class BlueprintDef {
  final String weaponId;
  final String title;
  final String subtitle;
  final String elementLabel;
  final int forgeCost;
  final IconData icon;
  final Color color;
  final String loreLog;

  String get name => title;
  String get description => subtitle;
  String get dropSource => elementLabel;

  const BlueprintDef({
    required this.weaponId,
    required this.title,
    required this.subtitle,
    required this.elementLabel,
    required this.forgeCost,
    required this.icon,
    required this.color,
    required this.loreLog,
  });

  static const List<BlueprintDef> allBlueprints = [
    BlueprintDef(
      weaponId: 'aegis_sawblades',
      title: 'AEGIS SAWBLADES',
      subtitle: 'Lâminas orbitais contínuas que destroem projéteis e aplicam Ruptura.',
      elementLabel: '🟣 VOID RUPTURE',
      forgeCost: 150,
      icon: Icons.rotate_right_rounded,
      color: Color(0xFF00E5FF),
      loreLog:
          'Criadas originalmente para cortar rochas de tungstênio em Calisto, foram convertidas em anéis '
          'orbitais de defesa quando a Primeira Frota ficou cercada sem escolta.',
    ),
    BlueprintDef(
      weaponId: 'tesla_arc',
      title: 'TESLA ARC CANNON',
      subtitle: 'Raio em cadeia que salta entre múltiplos inimigos próximos.',
      elementLabel: '⚡ ION SHOCK',
      forgeCost: 180,
      icon: Icons.electric_bolt_rounded,
      color: Color(0xFF80D8FF),
      loreLog:
          'Extraído do gerador principal do encouraçado Aegis-IV. Seus arcos elétricos saltam de casco em '
          'casco, fritando circuitos de mira e escudos defletores.',
    ),
    BlueprintDef(
      weaponId: 'quantum_chakram',
      title: 'QUANTUM CHAKRAM',
      subtitle: 'Disco bumerangue perfurante com 165% de dano no retorno.',
      elementLabel: '❄️ CRYO FREEZE',
      forgeCost: 200,
      icon: Icons.all_out_rounded,
      color: Color(0xFF00E676),
      loreLog:
          'Artefato balístico da guarda real de Caelum. Utiliza âncoras gravitacionais de fase para '
          'retornar infalivelmente às mãos de sua portadora.',
    ),
    BlueprintDef(
      weaponId: 'repulsor_aura',
      title: 'REPULSOR GRAVITY AURA',
      subtitle: 'Pulso 360° ao redor da nave que repele enxames e aplica Ruptura.',
      elementLabel: '🟣 VOID RUPTURE',
      forgeCost: 220,
      icon: Icons.radar_rounded,
      color: Color(0xFFE040FB),
      loreLog:
          'Dispositivo de contenção espacial projetado após o desastre da Colmeia Nêmesis. '
          'Emite ondas sísmicas de antimatéria que impedem que enxames devorem o cockpit.',
    ),
    BlueprintDef(
      weaponId: 'solar_lance',
      title: 'SOLAR THERMAL LANCE',
      subtitle: 'Feixe laser contínuo de alta fusão que derrete armaduras.',
      elementLabel: '🔥 SOLAR BURN',
      forgeCost: 260,
      icon: Icons.wb_sunny_rounded,
      color: Color(0xFFFF5722),
      loreLog:
          'Alimenta-se de plasma solar engarrafado nas estrelas binárias de Órion. '
          'Capaz de atravessar três encouraçados alinhados como se fossem papel.',
    ),
    BlueprintDef(
      weaponId: 'inferno_cone',
      title: 'INFERNO PLASMA CONE',
      subtitle: 'Lança-chamas espacial de curta distância que incinera esquadrões.',
      elementLabel: '🔥 SOLAR BURN',
      forgeCost: 160,
      icon: Icons.local_fire_department_rounded,
      color: Color(0xFFFF9100),
      loreLog:
          'Invenção improvisada nos corredores de Vesta: despeja plasma superaquecido direto das '
          'câmaras de pós-combustão sobre qualquer inimigo que ouse se aproximar.',
    ),
    BlueprintDef(
      weaponId: 'valkyrie_wingmen',
      title: 'VALKYRIE WINGMEN',
      subtitle: 'Drones caçadores aliados que escoltam a nave e atiram autonomamente.',
      elementLabel: '⚡ TACTICAL DRONES',
      forgeCost: 300,
      icon: Icons.flight_class_rounded,
      color: Color(0xFF00B0FF),
      loreLog:
          'Cada drone carrega o eco neural de uma piloto veterana caída no Vazio. '
          'Mesmo além da morte física, elas protegem as asas da nova geração.',
    ),
    BlueprintDef(
      weaponId: 'void_mines',
      title: 'VOID CLUSTER MINES',
      subtitle: 'Minas magnéticas traseiras ideais para recuar atirando (Kiting).',
      elementLabel: '🟣 VOID RUPTURE',
      forgeCost: 190,
      icon: Icons.brightness_low_rounded,
      color: Color(0xFFAA00FF),
      loreLog:
          'Armadilhas silenciosas de antimatéria usadas pela divisão furtiva Eclipse. '
          'Transformam qualquer perseguição inimiga em um corredor de aniquilação.',
    ),
  ];

  static BlueprintDef? findByWeaponId(String id) {
    for (final b in allBlueprints) {
      if (b.weaponId == id) return b;
    }
    return null;
  }
}

/// Definição de uma Mutação de Piloto escolhida entre Setores (Sprint 16 & Sprint 22 Lore)
class PilotMutation {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final String loreLog;

  const PilotMutation({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.loreLog,
  });

  static const List<PilotMutation> allMutations = [
    PilotMutation(
      id: 'mut_vampiric_close',
      title: 'ADRENALINA VAMPÍRICA',
      description: 'Abater inimigos ou asteroides restaura +4 HP de integridade do casco.',
      icon: Icons.favorite_rounded,
      color: Color(0xFFFF1744),
      loreLog:
          'Nanorrobôs canibais liberados no casco que absorvem o calor residual de reatores inimigos '
          'abatidos para soldar fissuras em tempo real.',
    ),
    PilotMutation(
      id: 'mut_mirror_dash',
      title: 'CONTRAMEDIDA ESPELHADA',
      description: 'Usar o Dash vaporiza projéteis inimigos próximos e causa +30% de velocidade de recarga.',
      icon: Icons.shield_moon_rounded,
      color: Color(0xFF00E5FF),
      loreLog:
          'Revestimento fotônico de inversão de fase. No instante do salto evasivo, o campo desintegra '
          'qualquer projétil hostil que tente interceptar a trajetória.',
    ),
    PilotMutation(
      id: 'mut_lone_wolf',
      title: 'SOBRECARGA DE ARSENAL',
      description: 'Concede +35% de Dano Global e +15% de Chance Crítica para todas as armas.',
      icon: Icons.bolt_rounded,
      color: Color(0xFFFFD700),
      loreLog:
          'Protocolo proibido que desativa os limitadores de segurança do núcleo da Valquíria, '
          'direcionando energia letal pura para os barramentos de tiro.',
    ),
    PilotMutation(
      id: 'mut_cryo_shatter',
      title: 'CATALISADOR ELEMENTAL',
      description: 'Aumenta em +50% o dano de todas as Reações Elementais (Burn, Freeze, Shock, Rupture).',
      icon: Icons.ac_unit_rounded,
      color: Color(0xFF80D8FF),
      loreLog:
          'Câmara de síntese quântica que amplifica o choque térmico entre gelo criogênico, '
          'fogo solar e fissuras do Vazio.',
    ),
    PilotMutation(
      id: 'mut_scrap_alchemist',
      title: 'ALQUIMIA DE SUCATA',
      description: 'Aumenta em +40% toda a Sucata Cósmica e Stardust XP coletados no setor.',
      icon: Icons.precision_manufacturing_rounded,
      color: Color(0xFFFFB300),
      loreLog:
          'Algoritmo de mineração herdado das guildas de Vesta que extrai isótopos raros até '
          'mesmo dos menores estilhaços de batalha.',
    ),
    PilotMutation(
      id: 'mut_titan_slayer',
      title: 'CAÇADORA DE TITÃS',
      description: 'Causa +40% de dano contra Sub-Chefes e Chefes Soberanos.',
      icon: Icons.crisis_alert_rounded,
      color: Color(0xFFE040FB),
      loreLog:
          'Módulo de escaneamento de ponto fraco desenvolvido após a queda de três esquadrões '
          'diante do primeiro Dreadnought Leviathan.',
    ),
  ];

  static PilotMutation? findById(String id) {
    for (final m in allMutations) {
      if (m.id == id) return m;
    }
    return null;
  }
}

/// Caixas Pretas (Flight Recorders) encontradas em Destroços Espaciais (Cargo Wrecks) — Sprint 22
class FlightRecorderLog {
  final String id;
  final String vesselName;
  final String pilotCallsign;
  final String sectorOrigin;
  final String transmissionText;

  const FlightRecorderLog({
    required this.id,
    required this.vesselName,
    required this.pilotCallsign,
    required this.sectorOrigin,
    required this.transmissionText,
  });

  static const List<FlightRecorderLog> allFlightRecorders = [
    FlightRecorderLog(
      id: 'log_erebus_01',
      vesselName: 'Cargueiro Aegis "Estrela Dalva"',
      pilotCallsign: 'Cap. Helena Vane',
      sectorOrigin: 'Setor 1 // Cinturão de Vesta',
      transmissionText:
          '“As paredes das antigas megaestruturas estão refletindo nossos tiros e triturando os asteroides... '
          'Usem as vigas metálicas como escudo contra os Snipers! Se alguém ouvir isso, não confiem na fenda!”',
    ),
    FlightRecorderLog(
      id: 'log_orion_02',
      vesselName: 'Corveta Científica "Helios-IX"',
      pilotCallsign: 'Dra. Maya Lin',
      sectorOrigin: 'Setor 2A // Forja de Órion',
      transmissionText:
          '“As nebulosas iônicas sobrecarrregam nossas armas, mas a radiação começa a derreter o suporte de vida '
          'após seis segundos lá dentro! Entrem, disparem tudo o que têm e saiam imediatamente!”',
    ),
    FlightRecorderLog(
      id: 'log_caelum_03',
      vesselName: 'Interceptor "Lâmina Boreal"',
      pilotCallsign: 'Ten. Sora Kael',
      sectorOrigin: 'Setor 2B // Abismo Criogênico',
      transmissionText:
          '“O Glacial Colossus regenera sua armadura de gelo sem parar... Apenas armas térmicas de Queimadura Solar '
          'conseguem impedir que a carapaça dele se feche novamente!”',
    ),
    FlightRecorderLog(
      id: 'log_graveyard_04',
      vesselName: 'Encouraçado "Vanguarda de Titã"',
      pilotCallsign: 'Com. Marcus Vance',
      sectorOrigin: 'Setor 3A // Cemitério Aegis',
      transmissionText:
          '“Esta é a 47ª vez que encontro os destroços da minha própria nave. Nós não estamos avançando '
          'pela galáxia... estamos presos em um protocolo de repetição criado antes da queda da Terra.”',
    ),
    FlightRecorderLog(
      id: 'log_nemesis_05',
      vesselName: 'Sonda Biológica "Deméter-IV"',
      pilotCallsign: 'Especialista K. Nox',
      sectorOrigin: 'Setor 3B // Colmeia Xeno',
      transmissionText:
          '“As paredes desta estação respiram! Quando paramos de atirar, a biomassa se regenera em segundos. '
          'Não cheguem perto dos casulos vermelhos a menos que estejam prontas para o enxame!”',
    ),
    FlightRecorderLog(
      id: 'log_throne_06',
      vesselName: 'Protótipo Ancestral "Origin-00"',
      pilotCallsign: 'Primeira Valquíria Astraea',
      sectorOrigin: 'Setor 5 // O Trono do Vazio',
      transmissionText:
          '“Para quebrar o Protocolo de uma vez por todas, tragam pelo menos 3 Células do Vazio e o Elo Eterno '
          'de quem jurou esperar por vocês no Hangar. Só o vínculo humano pode destruir o Arquiteto.”',
    ),
  ];
}

/// Códice de Facções Hostis (Sprint 22 — Documentação Militar no Menu/Oficina)
class FactionCodexEntry {
  final String id;
  final String title;
  final String subtitle;
  final String threatClassification;
  final String loreHistory;
  final String tacticalWeakness;
  final IconData icon;
  final Color color;

  const FactionCodexEntry({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.threatClassification,
    required this.loreHistory,
    required this.tacticalWeakness,
    required this.icon,
    required this.color,
  });

  static const List<FactionCodexEntry> allFactions = [
    FactionCodexEntry(
      id: 'faction_erebus',
      title: 'FROTA CORROMPIDA DE ÉREBO',
      subtitle: 'Armada Automatizada da Antiga Coalizão Humana',
      threatClassification: 'AMEAÇA NÍVEL ALFA // BLINDAGEM & ARTILHARia',
      loreHistory:
          'Outrora o orgulho defensivo das colônias humanas nos setores de Vesta e Cemitério Aegis. '
          'Quando o Protocolo Void foi ativado, suas inteligências artificiais de bordo foram infectadas '
          'pela frequência abissal, passando a caçar qualquer piloto viva que tente escapar do setor. '
          'Inclui Scouts, Phantom Raiders, Corvette Snipers, Aegis Bulwarks e o titânico Dreadnought Leviathan.',
      tacticalWeakness:
          'Use paredes de megaestruturas para bloquear tiros de Snipers e o Dash para flanquear o escudo frontal dos Aegis Bulwarks.',
      icon: Icons.shield_rounded,
      color: Color(0xFF00E5FF),
    ),
    FactionCodexEntry(
      id: 'faction_xeno',
      title: 'COLMEIA XENO-BIOLÓGICA DE NÊMESIS',
      subtitle: 'Organismo Superpredador Assimilador de Matéria',
      threatClassification: 'AMEAÇA NÍVEL ÔMEGA // ENXAME & REGENERAÇÃO',
      loreHistory:
          'Uma forma de vida cósmica parasitária que nidificou nas carcaças de estações espaciais do Setor 3B. '
          'Alimenta-se da radiação de reatores destruídos, tecendo paredes de biomassa viva que se regeneram '
          'e incubando milhares de Void Swarmers sob o comando da Carrier Hive Alpha.',
      tacticalWeakness:
          'Armas de área (Repulsor Aura, Inferno Plasma Cone e Aegis Sawblades) e Queimadura Solar cortam a regeneração biológica.',
      icon: Icons.hive_rounded,
      color: Color(0xFFFF4081),
    ),
    FactionCodexEntry(
      id: 'faction_architects',
      title: 'ARQUITETOS ANCESTRAIS DO PROTOCOLO',
      subtitle: 'Guardiões Primordiais do Horizonte de Eventos',
      threatClassification: 'AMEAÇA NÍVEL TRANSCENDENTE // GRAVIDADE & ENTROPIA',
      loreHistory:
          'Entidades multidimensionais que regem a singularidade do Setor 4 e o Trono Secreto do Setor 5. '
          'Foram eles que ergueram o loop temporal do Protocolo Void para conter a morte térmica do universo '
          'usando as memórias de combate das Valquírias como combustível eterno.',
      tacticalWeakness:
          'Sinergias Elementais Cruzadas e a Mutação Caçadora de Titãs são essenciais para romper seus núcleos gravitacionais.',
      icon: Icons.auto_awesome_rounded,
      color: Color(0xFFFFD700),
    ),
  ];
}

/// Definição de Conquistas / Milestones do Códice das Valquírias (Sprint 17)
class MilestoneAchievement {
  final String id;
  final String title;
  final String description;
  final int scrapReward;
  final IconData icon;
  final Color color;

  const MilestoneAchievement({
    required this.id,
    required this.title,
    required this.description,
    required this.scrapReward,
    required this.icon,
    required this.color,
  });

  static const List<MilestoneAchievement> allMilestones = [
    MilestoneAchievement(
      id: 'ach_first_blood',
      title: 'BATISMO DE FOGO',
      description: 'Destrua 20 alvos hostis em uma operação.',
      scrapReward: 150,
      icon: Icons.local_fire_department_rounded,
      color: Color(0xFFFF5722),
    ),
    MilestoneAchievement(
      id: 'ach_speed_vault',
      title: 'VELOCISTA DO VÁCUO',
      description: 'Alcance e abra o Cofre Cronometrado (< 02:00) antes que se tranque.',
      scrapReward: 250,
      icon: Icons.timer_rounded,
      color: Color(0xFFFFD700),
    ),
    MilestoneAchievement(
      id: 'ach_flawless_titan',
      title: 'INTOCÁVEL',
      description: 'Derrote um Chefe Soberano sem sofrer dano e abra sua Câmara Intocável.',
      scrapReward: 350,
      icon: Icons.workspace_premium_rounded,
      color: Color(0xFF00E5FF),
    ),
    MilestoneAchievement(
      id: 'ach_superweapon',
      title: 'FORJADORA DE ESTRELAS',
      description: 'Evolua qualquer arma MK 3 para sua forma de Superarma Lendária.',
      scrapReward: 300,
      icon: Icons.auto_awesome_rounded,
      color: Color(0xFFFFD700),
    ),
    MilestoneAchievement(
      id: 'ach_blueprint_forge',
      title: 'ENGENHEIRA DO VAZIO',
      description: 'Desbloqueie um Diagrama Tecnológico na Forja da Oficina.',
      scrapReward: 200,
      icon: Icons.precision_manufacturing_rounded,
      color: Color(0xFF00E676),
    ),
    MilestoneAchievement(
      id: 'ach_void_cell',
      title: 'PORTADORA DA CÉLULA',
      description: 'Vença um Setor ou Campanha com pelo menos 1 Void Cell ativa.',
      scrapReward: 400,
      icon: Icons.cyclone_rounded,
      color: Color(0xFFE040FB),
    ),
  ];
}
