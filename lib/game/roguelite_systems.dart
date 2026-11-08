import 'package:flutter/material.dart';

/// Definição de um Diagrama Tecnológico (Blueprint) da Forja da Oficina (Sprint 16)
class BlueprintDef {
  final String weaponId;
  final String title;
  final String subtitle;
  final String elementLabel;
  final int forgeCost;
  final IconData icon;
  final Color color;

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
    ),
    BlueprintDef(
      weaponId: 'tesla_arc',
      title: 'TESLA ARC CANNON',
      subtitle: 'Raio em cadeia que salta entre múltiplos inimigos próximos.',
      elementLabel: '⚡ ION SHOCK',
      forgeCost: 180,
      icon: Icons.electric_bolt_rounded,
      color: Color(0xFF80D8FF),
    ),
    BlueprintDef(
      weaponId: 'quantum_chakram',
      title: 'QUANTUM CHAKRAM',
      subtitle: 'Disco bumerangue perfurante com 165% de dano no retorno.',
      elementLabel: '❄️ CRYO FREEZE',
      forgeCost: 200,
      icon: Icons.all_out_rounded,
      color: Color(0xFF00E676),
    ),
    BlueprintDef(
      weaponId: 'repulsor_aura',
      title: 'REPULSOR GRAVITY AURA',
      subtitle: 'Pulso 360° ao redor da nave que repele enxames e aplica Ruptura.',
      elementLabel: '🟣 VOID RUPTURE',
      forgeCost: 220,
      icon: Icons.radar_rounded,
      color: Color(0xFFE040FB),
    ),
    BlueprintDef(
      weaponId: 'solar_lance',
      title: 'SOLAR THERMAL LANCE',
      subtitle: 'Feixe laser contínuo de alta fusão que derrete armaduras.',
      elementLabel: '🔥 SOLAR BURN',
      forgeCost: 260,
      icon: Icons.wb_sunny_rounded,
      color: Color(0xFFFF5722),
    ),
    BlueprintDef(
      weaponId: 'inferno_cone',
      title: 'INFERNO PLASMA CONE',
      subtitle: 'Lança-chamas espacial de curta distância que incinera esquadrões.',
      elementLabel: '🔥 SOLAR BURN',
      forgeCost: 160,
      icon: Icons.local_fire_department_rounded,
      color: Color(0xFFFF9100),
    ),
    BlueprintDef(
      weaponId: 'valkyrie_wingmen',
      title: 'VALKYRIE WINGMEN',
      subtitle: 'Drones caçadores aliados que escoltam a nave e atiram autonomamente.',
      elementLabel: '⚡ TACTICAL DRONES',
      forgeCost: 300,
      icon: Icons.flight_class_rounded,
      color: Color(0xFF00B0FF),
    ),
    BlueprintDef(
      weaponId: 'void_mines',
      title: 'VOID CLUSTER MINES',
      subtitle: 'Minas magnéticas traseiras ideais para recuar atirando (Kiting).',
      elementLabel: '🟣 VOID RUPTURE',
      forgeCost: 190,
      icon: Icons.brightness_low_rounded,
      color: Color(0xFFAA00FF),
    ),
  ];

  static BlueprintDef? findByWeaponId(String id) {
    for (final b in allBlueprints) {
      if (b.weaponId == id) return b;
    }
    return null;
  }
}

/// Definição de uma Mutação de Piloto escolhida entre Setores (Sprint 16 — Estilo Dead Cells)
class PilotMutation {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const PilotMutation({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });

  static const List<PilotMutation> allMutations = [
    PilotMutation(
      id: 'mut_vampiric_close',
      title: 'ADRENALINA VAMPÍRICA',
      description: 'Abater inimigos ou asteroides restaura +4 HP de integridade do casco.',
      icon: Icons.favorite_rounded,
      color: Color(0xFFFF1744),
    ),
    PilotMutation(
      id: 'mut_mirror_dash',
      title: 'CONTRAMEDIDA ESPELHADA',
      description: 'Usar o Dash vaporiza projéteis inimigos próximos e causa +30% de velocidade de recarga.',
      icon: Icons.shield_moon_rounded,
      color: Color(0xFF00E5FF),
    ),
    PilotMutation(
      id: 'mut_lone_wolf',
      title: 'SOBRECARGA DE ARSENAL',
      description: 'Concede +35% de Dano Global e +15% de Chance Crítica para todas as armas.',
      icon: Icons.bolt_rounded,
      color: Color(0xFFFFD700),
    ),
    PilotMutation(
      id: 'mut_cryo_shatter',
      title: 'CATALISADOR ELEMENTAL',
      description: 'Aumenta em +50% o dano de todas as Reações Elementais (Burn, Freeze, Shock, Rupture).',
      icon: Icons.ac_unit_rounded,
      color: Color(0xFF80D8FF),
    ),
    PilotMutation(
      id: 'mut_scrap_alchemist',
      title: 'ALQUIMIA DE SUCATA',
      description: 'Aumenta em +40% toda a Sucata Cósmica e Stardust XP coletados no setor.',
      icon: Icons.precision_manufacturing_rounded,
      color: Color(0xFFFFB300),
    ),
    PilotMutation(
      id: 'mut_titan_slayer',
      title: 'CAÇADORA DE TITÃS',
      description: 'Causa +40% de dano contra Sub-Chefes e Chefes Soberanos.',
      icon: Icons.crisis_alert_rounded,
      color: Color(0xFFE040FB),
    ),
  ];

  static PilotMutation? findById(String id) {
    for (final m in allMutations) {
      if (m.id == id) return m;
    }
    return null;
  }
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
