import 'package:flutter/material.dart';

enum SectorId {
  vesta,
  orion,
  graveyard,
  eventHorizon,
}

class Sector {
  final SectorId id;
  final String name;
  final String subtitle;
  final String description;
  final String difficultyLabel;
  final Color primaryColor;
  final Color secondaryColor;
  final double speedMultiplier;
  final double asteroidDensity;
  final List<({double t, Color a, Color b})> paletteStops;
  final String hazardWarning;
  final IconData icon;

  const Sector({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.description,
    required this.difficultyLabel,
    required this.primaryColor,
    required this.secondaryColor,
    required this.speedMultiplier,
    required this.asteroidDensity,
    required this.paletteStops,
    required this.hazardWarning,
    required this.icon,
  });

  static const List<Sector> allSectors = [
    Sector(
      id: SectorId.vesta,
      name: 'Cinturão de Vesta',
      subtitle: 'Setor 1 // Campo de Detritos Primário',
      description: 'Denso cinturão de asteroides ricos em ferro e silicato. Ideal para reconhecimento e testes balísticos.',
      difficultyLabel: 'NORMAL',
      primaryColor: Color(0xFF00E5FF),
      secondaryColor: Color(0xFF1E3C9E),
      speedMultiplier: 1.0,
      asteroidDensity: 1.0,
      hazardWarning: 'Alerta de Navegação: Ondas padrão de micrometeoritos.',
      icon: Icons.public,
      paletteStops: [
        (t: 0.0, a: Color(0xFF1E3C9E), b: Color(0xFF0E8A9E)),
        (t: 50.0, a: Color(0xFF1E3C9E), b: Color(0xFF0E8A9E)),
        (t: 105.0, a: Color(0xFF5B2A9E), b: Color(0xFF1E3C9E)),
        (t: 150.0, a: Color(0xFFB35A12), b: Color(0xFF7A2A9E)),
        (t: 180.0, a: Color(0xFFC4122A), b: Color(0xFF8A3A0E)),
      ],
    ),
    Sector(
      id: SectorId.orion,
      name: 'Forja Solar de Órion',
      subtitle: 'Setor 2 // Nebulosa de Plasma Quente',
      description: 'Região vulcânica estelar sob radiação solar extrema. Asteroides fundidos deixam rastros de magma ionizado.',
      difficultyLabel: 'DIFÍCIL',
      primaryColor: Color(0xFFFF5722),
      secondaryColor: Color(0xFFFF9100),
      speedMultiplier: 1.15,
      asteroidDensity: 1.15,
      hazardWarning: 'Radiação Térmica: Erupções solares e poças de magma estelar.',
      icon: Icons.whatshot,
      paletteStops: [
        (t: 0.0, a: Color(0xFFD84315), b: Color(0xFFFF8F00)),
        (t: 50.0, a: Color(0xFFE64A19), b: Color(0xFFFF6F00)),
        (t: 105.0, a: Color(0xFFBF360C), b: Color(0xFFD84315)),
        (t: 150.0, a: Color(0xFFFF3D00), b: Color(0xFFDD2C00)),
        (t: 180.0, a: Color(0xFFFF1744), b: Color(0xFFFF5252)),
      ],
    ),
    Sector(
      id: SectorId.graveyard,
      name: 'Cemitério de Dreadnoughts',
      subtitle: 'Setor 3 // Necrópole de Carcaças Militares',
      description: 'Carcaças de antigas naves de guerra e contêineres abandonados. Tempestades eletromagnéticas desestabilizam escudos.',
      difficultyLabel: 'EXPERT',
      primaryColor: Color(0xFF00E676),
      secondaryColor: Color(0xFF004D40),
      speedMultiplier: 1.25,
      asteroidDensity: 1.25,
      hazardWarning: 'Tempestade EMP: Interferências eletromagnéticas e piratas espaciais.',
      icon: Icons.token,
      paletteStops: [
        (t: 0.0, a: Color(0xFF004D40), b: Color(0xFF00BFA5)),
        (t: 50.0, a: Color(0xFF1B5E20), b: Color(0xFF00E676)),
        (t: 105.0, a: Color(0xFF33691E), b: Color(0xFF76FF03)),
        (t: 150.0, a: Color(0xFF4A148C), b: Color(0xFF00E5FF)),
        (t: 180.0, a: Color(0xFF311B92), b: Color(0xFF651FFF)),
      ],
    ),
    Sector(
      id: SectorId.eventHorizon,
      name: 'Abismo Event Horizon',
      subtitle: 'Setor 4 // Limiar do Buraco Negro',
      description: 'O tecido do hiperespaço dobra-se diante de uma singularidade cósmica. Forças gravitacionais arrastam tudo ao vórtice.',
      difficultyLabel: 'PESADELO',
      primaryColor: Color(0xFFE040FB),
      secondaryColor: Color(0xFF7C4DFF),
      speedMultiplier: 1.4,
      asteroidDensity: 1.35,
      hazardWarning: 'Gravidade Singular: Buracos negros ativos sugam matéria próxima.',
      icon: Icons.cyclone,
      paletteStops: [
        (t: 0.0, a: Color(0xFF311B92), b: Color(0xFF880E4F)),
        (t: 50.0, a: Color(0xFF4A148C), b: Color(0xFFAD1457)),
        (t: 105.0, a: Color(0xFF6A1B9A), b: Color(0xFFD81B60)),
        (t: 150.0, a: Color(0xFF7B1FA2), b: Color(0xFFE91E63)),
        (t: 180.0, a: Color(0xFF4A148C), b: Color(0xFF1A0033)),
      ],
    ),
  ];

  static Sector get defaultSector => allSectors.first;

  static Sector findById(SectorId id) {
    return allSectors.firstWhere((s) => s.id == id, orElse: () => defaultSector);
  }
}
