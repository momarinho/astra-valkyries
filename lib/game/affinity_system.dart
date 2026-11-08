import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Modelo de Memória Secreta / Ilustração CG da Galeria
class SecretMemory {
  final String id;
  final String valkyrieId;
  final String title;
  final String subtitle;
  final String description;
  final String imageAsset;
  final int requiredBondLevel;
  final Color themeColor;

  const SecretMemory({
    required this.id,
    required this.valkyrieId,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.imageAsset,
    required this.requiredBondLevel,
    required this.themeColor,
  });

  bool isUnlocked(int currentBondLevel) => currentBondLevel >= requiredBondLevel;
}

/// Diálogo expressivo das Valquírias no Hangar e em Batalha
class PilotDialogue {
  final String text;
  final int minBondLevel;

  const PilotDialogue({
    required this.text,
    this.minBondLevel = 1,
  });
}

/// Estado de Afinidade e Elo de cada Valquíria
class ValkyrieAffinity {
  final String valkyrieId;
  int bondLevel; // 1 a 5
  int currentXp;

  ValkyrieAffinity({
    required this.valkyrieId,
    this.bondLevel = 1,
    this.currentXp = 0,
  });

  /// XP necessária para alcançar o próximo nível
  static int xpRequiredForNextLevel(int level) {
    switch (level) {
      case 1:
        return 100;
      case 2:
        return 250;
      case 3:
        return 500;
      case 4:
        return 1000;
      default:
        return 999999; // Nível Máximo (5)
    }
  }

  int get xpForNext => xpRequiredForNextLevel(bondLevel);

  double get progressPercent {
    if (bondLevel >= 5) return 1.0;
    return (currentXp / math.max(1, xpForNext)).clamp(0.0, 1.0);
  }

  /// Bônus passivo de combate concedido pelo Elo de Afinidade
  double get bondCritBonus => (bondLevel - 1) * 0.02; // +2% por nível (até +8%)
  double get bondSpeedBonus => (bondLevel - 1) * 0.02; // +2% de vel por nível (até +8%)

  String get bondTitle {
    switch (bondLevel) {
      case 1:
        return 'Recruta da Frota';
      case 2:
        return 'Companheira de Esquadrão';
      case 3:
        return 'Confidente Tática';
      case 4:
        return 'Elo de Almas';
      case 5:
        return 'Votos Eternos';
      default:
        return 'Piloto';
    }
  }

  /// Adiciona XP de Afinidade e retorna true caso tenha subido de nível
  bool addXp(int amount) {
    if (bondLevel >= 5) return false;
    currentXp += amount;
    bool leveledUp = false;

    while (bondLevel < 5 && currentXp >= xpRequiredForNextLevel(bondLevel)) {
      currentXp -= xpRequiredForNextLevel(bondLevel);
      bondLevel++;
      leveledUp = true;
    }

    if (bondLevel >= 5) {
      currentXp = 0;
    }

    return leveledUp;
  }

  Map<String, dynamic> toJson() => {
        'valkyrieId': valkyrieId,
        'bondLevel': bondLevel,
        'currentXp': currentXp,
      };

  factory ValkyrieAffinity.fromJson(Map<String, dynamic> json) => ValkyrieAffinity(
        valkyrieId: json['valkyrieId'] as String,
        bondLevel: (json['bondLevel'] as num?)?.toInt() ?? 1,
        currentXp: (json['currentXp'] as num?)?.toInt() ?? 0,
      );
}

/// Gerenciador Central de Afinidade e Galeria de Memórias
class AffinityManager {
  final Map<String, ValkyrieAffinity> _affinities = {
    'lyra': ValkyrieAffinity(valkyrieId: 'lyra'),
    'selene': ValkyrieAffinity(valkyrieId: 'selene'),
    'vesper': ValkyrieAffinity(valkyrieId: 'vesper'),
  };

  ValkyrieAffinity getAffinity(String valkyrieId) {
    return _affinities.putIfAbsent(
      valkyrieId,
      () => ValkyrieAffinity(valkyrieId: valkyrieId),
    );
  }

  /// Catálogo Completo de Memórias Secretas (CGs / Pinups)
  static final List<SecretMemory> allMemories = [
    // --- LYRA (Solar Vanguard) ---
    const SecretMemory(
      id: 'lyra_cg_1',
      valkyrieId: 'lyra',
      title: 'Voo Solo no Hangar',
      subtitle: 'Memória de Recruta // Inspeção no Hangar',
      description: 'Lyra ajusta seu headset mecha e checa as juntas do exoesqueleto no hangar principal antes de acelerar com tudo rumo ao desconhecido.',
      imageAsset: 'assets/art/valkyries/lyra/hangar_fullbody.png',
      requiredBondLevel: 1,
      themeColor: Color(0xFFFF5722),
    ),
    const SecretMemory(
      id: 'lyra_cg_2',
      valkyrieId: 'lyra',
      title: 'Descompressão Íntima',
      subtitle: 'Pinup Confidencial // Calor Pós-Combate',
      description: 'Após escapar por pouco de uma chuva de meteoros de magma, Lyra descansa em seu traje cibernético para aliviar o calor escaldante da cabine.',
      imageAsset: 'assets/art/valkyries/lyra/pinup_memory_1.jpg',
      requiredBondLevel: 3,
      themeColor: Color(0xFFFF9800),
    ),
    const SecretMemory(
      id: 'lyra_cg_3',
      valkyrieId: 'lyra',
      title: 'Supernova da Paixão',
      subtitle: 'Votos Eternos // Pôr do Sol em Alfa Centauro',
      description: 'Sob a luz dourada de um sistema estelar binário, Lyra confessa que seu coração queima com mais intensidade ao seu lado do que qualquer motor a plasma.',
      imageAsset: 'assets/art/valkyries/lyra/pinup_memory_2.jpg',
      requiredBondLevel: 5,
      themeColor: Color(0xFFFF1744),
    ),

    // --- SELENE (Void Tactician) ---
    const SecretMemory(
      id: 'selene_cg_1',
      valkyrieId: 'selene',
      title: 'Cálculo Quântico',
      subtitle: 'Memória de Recruta // Hologramas Táticos',
      description: 'Selene analisa as trajetórias hiperbólicas das frotas inimigas na penumbra azulada da ponte de comando.',
      imageAsset: 'assets/art/valkyries/selene/hangar_fullbody.png',
      requiredBondLevel: 1,
      themeColor: Color(0xFF00E5FF),
    ),
    const SecretMemory(
      id: 'selene_cg_2',
      valkyrieId: 'selene',
      title: 'Barreira Desarmada',
      subtitle: 'Pinup Confidencial // Banho de Cristal',
      description: 'Pela primeira vez em anos, a estoica estrategista desliga seus escudos e descansa em seu traje de nano-fibra translúcida, convidando você para seu aposento particular.',
      imageAsset: 'assets/art/valkyries/selene/pinup_memory_1.jpg',
      requiredBondLevel: 3,
      themeColor: Color(0xFF00B0FF),
    ),
    const SecretMemory(
      id: 'selene_cg_3',
      valkyrieId: 'selene',
      title: 'Prisma Eterno',
      subtitle: 'Votos Eternos // Ressonância Perfeita',
      description: 'Selene sintoniza a frequência de seu núcleo de escudo com o seu batimento cardíaco, jurando proteção absoluta contra a vastidão do vácuo.',
      imageAsset: 'assets/art/valkyries/selene/pinup_memory_2.jpg',
      requiredBondLevel: 5,
      themeColor: Color(0xFF651FFF),
    ),

    // --- VESPER (Dread Renegade) ---
    const SecretMemory(
      id: 'vesper_cg_1',
      valkyrieId: 'vesper',
      title: 'Faíscas na Oficina',
      subtitle: 'Memória de Recruta // Calibração de Ogivas',
      description: 'Vesper desmonta um canhão de antimatéria com um sorriso travesso e uma chave inglesa presa nos dentes.',
      imageAsset: 'assets/art/valkyries/vesper/hangar_fullbody.png',
      requiredBondLevel: 1,
      themeColor: Color(0xFFD500F9),
    ),
    const SecretMemory(
      id: 'vesper_cg_2',
      valkyrieId: 'vesper',
      title: 'Adrenalina Pura',
      subtitle: 'Pinup Confidencial // Couro e Graxa',
      description: 'Tirando a jaqueta pesada após aniquilar um esquadrão de elite, Vesper te desafia para uma aposta ousada na cabine de torpedos.',
      imageAsset: 'assets/art/valkyries/vesper/pinup_memory_1.jpg',
      requiredBondLevel: 3,
      themeColor: Color(0xFFFF4081),
    ),
    const SecretMemory(
      id: 'vesper_cg_3',
      valkyrieId: 'vesper',
      title: 'Colapso Gravitacional',
      subtitle: 'Votos Eternos // Pacto Selvagem',
      description: 'A renegada mais temida dos setores externos admite que seu único ponto vulnerável é o seu abraço.',
      imageAsset: 'assets/art/valkyries/vesper/pinup_memory_2.jpg',
      requiredBondLevel: 5,
      themeColor: Color(0xFFAA00FF),
    ),
  ];

  /// Diálogos Dinâmicos Reativos por Nível de Elo
  static final Map<String, List<PilotDialogue>> dialogues = {
    'lyra': [
      const PilotDialogue(
        minBondLevel: 1,
        text: '"Full throttle, Comandante! Os propulsores da Sol Blaze estão prontos para voar!"',
      ),
      const PilotDialogue(
        minBondLevel: 1,
        text: '"Não se preocupe com os asteroides, meus reflexos cuidam da esquiva!"',
      ),
      const PilotDialogue(
        minBondLevel: 2,
        text: '"Você tem uma mão firme no leme tático. Confio na sua mira de olhos fechados."',
      ),
      const PilotDialogue(
        minBondLevel: 3,
        text: '"Ufa... Esse macacão de voo fica tão justo e quente após o combate... Se importa se eu abrir um pouco o zíper, Comandante?"',
      ),
      const PilotDialogue(
        minBondLevel: 4,
        text: '"Quando aquela rajada atingiu nosso escudo, meu único medo não foi morrer... foi pensar em te deixar sozinho na escuridão."',
      ),
      const PilotDialogue(
        minBondLevel: 5,
        text: '"Meu coração queima mais forte com o seu toque do que com a minha Supernova. Eu sou sua piloto para sempre, Comandante."',
      ),
    ],
    'selene': [
      const PilotDialogue(
        minBondLevel: 1,
        text: '"Sistemas de telemetria operacionais. Mantenha os parâmetros táticos alinhados, Comandante."',
      ),
      const PilotDialogue(
        minBondLevel: 2,
        text: '"Suas manobras reduzem o estresse computacional da nave. Uma parceria... estatisticamente louvável."',
      ),
      const PilotDialogue(
        minBondLevel: 3,
        text: '"Passei a vida erguendo escudos contra tudo e todos... mas ao seu lado, sinto vontade de abaixar todas as defesas."',
      ),
      const PilotDialogue(
        minBondLevel: 4,
        text: '"Calculei uma certeza de 99.8%: não há galáxia no cosmos onde eu preferiria estar sem a sua presença."',
      ),
      const PilotDialogue(
        minBondLevel: 5,
        text: '"Você decodificou cada prisma da minha alma. Para onde quer que aponte o seu comando, eu serei a sua luz guia."',
      ),
    ],
    'vesper': [
      const PilotDialogue(
        minBondLevel: 1,
        text: '"E aí chefe! Trouxe munição pesada de verdade ou vamos ter que improvisar com dinamite estelar?"',
      ),
      const PilotDialogue(
        minBondLevel: 2,
        text: '"Haha! Gostei de ver como você atraiu aqueles drones pra linha de tiro! Temos química no tiroteio!"',
      ),
      const PilotDialogue(
        minBondLevel: 3,
        text: '"Minhas mãos estão cheias de graxa dos torpedos... Ei, não fica me olhando assim! Quer me ajudar a limpar ou tá amarelando?"',
      ),
      const PilotDialogue(
        minBondLevel: 4,
        text: '"Eu nunca confiei em ninguém no vácuo... Mas por você, eu entro de cabeça em qualquer tempestade de antimatéria."',
      ),
      const PilotDialogue(
        minBondLevel: 5,
        text: '"Você domou a piloto mais selvagem de toda a frota, Comandante. Agora aguenta, porque eu não te solto mais!"',
      ),
    ],
  };

  /// Retorna um diálogo aleatório condizente com o nível de elo da piloto
  String getRandomDialogue(String valkyrieId) {
    final affinity = getAffinity(valkyrieId);
    final pool = (dialogues[valkyrieId] ?? dialogues['lyra']!)
        .where((d) => d.minBondLevel <= affinity.bondLevel)
        .toList();

    if (pool.isEmpty) return '"Pronta para o combate, Comandante!"';
    final randIndex = math.Random().nextInt(pool.length);
    return pool[randIndex].text;
  }

  /// Diálogos Reativos Pós-Run estilo Hades (Sprint 18):
  /// Reage ao último Chefe enfrentado e ao resultado da incursão anterior.
  String getReactivePostRunDialogue(String valkyrieId, {String? lastBoss, bool wasVictory = false}) {
    if (lastBoss != null && lastBoss.isNotEmpty) {
      if (wasVictory) {
        switch (valkyrieId) {
          case 'selene':
            return '"O padrão de ataque de $lastBoss foi completamente decodificado. Uma vitória cirúrgica, Comandante."';
          case 'vesper':
            return '"HAHA! Você viu os pedaços de $lastBoss voando pelo setor?! Ninguém segura a nossa artilharia!"';
          case 'astraea':
            return '"A anomalia $lastBoss retornou ao pó estelar primordial. O cosmos curva-se à nossa luz."';
          default:
            return '"Derrubamos $lastBoss em velocidade máxima! Ninguém no vácuo consegue nos alcançar, Comandante!"';
        }
      } else {
        switch (valkyrieId) {
          case 'selene':
            return '"Recalibrando escudos após o confronto com $lastBoss. Ajustei a matriz de fase para não sermos surpreendidos novamente."';
          case 'vesper':
            return '"Aquele maldito $lastBoss amassou minha fuselagem! Abasteça os torpedos, chefe, quero revanche AGORA!"';
          case 'astraea':
            return '"Mesmo as estrelas oscilam diante de $lastBoss. Mas nossa chama ancestral jamais se apagará."';
          default:
            return '"Aquele $lastBoss tinha um poder de fogo absurdo... Mas já sei exatamente como desviar na próxima incursão!"';
        }
      }
    }
    return getRandomDialogue(valkyrieId);
  }

  /// Retorna a lista de memórias de uma Valquíria específica
  List<SecretMemory> getMemoriesForValkyrie(String valkyrieId) {
    return allMemories.where((m) => m.valkyrieId == valkyrieId).toList();
  }

  /// Persistência Local via SharedPreferences
  Future<void> loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final key in _affinities.keys) {
        final bondLvl = prefs.getInt('valkyrie_bond_level_$key');
        final bondXp = prefs.getInt('valkyrie_bond_xp_$key');
        if (bondLvl != null) _affinities[key]!.bondLevel = bondLvl;
        if (bondXp != null) _affinities[key]!.currentXp = bondXp;
      }
    } catch (_) {
      // Graceful fallback for test or uninitialized environment
    }
  }

  Future<void> saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final entry in _affinities.entries) {
        await prefs.setInt('valkyrie_bond_level_${entry.key}', entry.value.bondLevel);
        await prefs.setInt('valkyrie_bond_xp_${entry.key}', entry.value.currentXp);
      }
    } catch (_) {}
  }
}
