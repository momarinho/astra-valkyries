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
    'kbr_01': ValkyrieAffinity(valkyrieId: 'kbr_01'),
    'kaede': ValkyrieAffinity(valkyrieId: 'kbr_01'),
    'lyra': ValkyrieAffinity(valkyrieId: 'lyra'),
    'selene': ValkyrieAffinity(valkyrieId: 'selene'),
    'vesper': ValkyrieAffinity(valkyrieId: 'vesper'),
  };

  ValkyrieAffinity getAffinity(String valkyrieId) {
    final normalized = (valkyrieId == 'kaede' || valkyrieId == 'kbr' || valkyrieId == 'kimberly') ? 'kbr_01' : valkyrieId;
    return _affinities.putIfAbsent(
      normalized,
      () => ValkyrieAffinity(valkyrieId: normalized),
    );
  }

  /// Adiciona pontos/XP de afinidade à Valquíria informada
  bool addAffinity(String valkyrieId, int amount) {
    return getAffinity(valkyrieId).addXp(amount);
  }

  /// Catálogo Completo de Arquivos Táticos & Dossiês de Piloto
  static final List<SecretMemory> allMemories = [
    // --- LYRA (Solar Vanguard) ---
    const SecretMemory(
      id: 'lyra_cg_1',
      valkyrieId: 'lyra',
      title: 'Voo Solo no Hangar',
      subtitle: 'Dossiê de Recruta // Inspeção no Hangar',
      description: 'Lyra ajusta seu headset mecha e checa as juntas do exoesqueleto no hangar principal antes de acelerar com tudo rumo ao desconhecido.',
      imageAsset: 'assets/art/valkyries/lyra/hangar_fullbody.png',
      requiredBondLevel: 1,
      themeColor: Color(0xFFFF5722),
    ),
    const SecretMemory(
      id: 'lyra_cg_2',
      valkyrieId: 'lyra',
      title: 'Manobra em Vesta Belt',
      subtitle: 'Dossiê Tático // Telemetria Pós-Combate',
      description: 'Após escapar por pouco de uma tempestade densa de magma, Lyra calibra os dissipadores térmicos da Sol Blaze e valida a telemetria com o comando.',
      imageAsset: 'assets/art/valkyries/lyra/tactical_log_1.jpg',
      requiredBondLevel: 3,
      themeColor: Color(0xFFFF9800),
    ),
    const SecretMemory(
      id: 'lyra_cg_3',
      valkyrieId: 'lyra',
      title: 'Supernova Convergente',
      subtitle: 'Registro Supremo // Pôr do Sol em Alfa Centauro',
      description: 'Sob a luz dourada de um sistema estelar binário, Lyra confirma que a sincronia da Sol Blaze sob o comando da frota queima mais forte que qualquer motor a plasma.',
      imageAsset: 'assets/art/valkyries/lyra/tactical_log_2.jpg',
      requiredBondLevel: 5,
      themeColor: Color(0xFFFF1744),
    ),

    // --- SELENE (Void Tactician) ---
    const SecretMemory(
      id: 'selene_cg_1',
      valkyrieId: 'selene',
      title: 'Cálculo Quântico',
      subtitle: 'Dossiê de Recruta // Hologramas Táticos',
      description: 'Selene analisa as trajetórias hiperbólicas das frotas inimigas na penumbra azulada da ponte de comando.',
      imageAsset: 'assets/art/valkyries/selene/hangar_fullbody.png',
      requiredBondLevel: 1,
      themeColor: Color(0xFF00E5FF),
    ),
    const SecretMemory(
      id: 'selene_cg_2',
      valkyrieId: 'selene',
      title: 'Harmônica Quântica',
      subtitle: 'Dossiê Tático // Matriz de Escudos em Cryo Abyss',
      description: 'Selene recalibra os prismas de escudo contra estilhaços criogênicos a zero-kelvin, integrando as rotas de evasão diretamente aos consoles da frota.',
      imageAsset: 'assets/art/valkyries/selene/tactical_log_1.jpg',
      requiredBondLevel: 3,
      themeColor: Color(0xFF00B0FF),
    ),
    const SecretMemory(
      id: 'selene_cg_3',
      valkyrieId: 'selene',
      title: 'Prisma Eterno',
      subtitle: 'Registro Supremo // Ressonância Quântica Total',
      description: 'Selene sintoniza a frequência de seu núcleo de escudo com os parâmetros da frota, estabelecendo barreira defensiva impenetrável sob o seu comando.',
      imageAsset: 'assets/art/valkyries/selene/tactical_log_2.jpg',
      requiredBondLevel: 5,
      themeColor: Color(0xFF651FFF),
    ),

    // --- VESPER (Dread Renegade) ---
    const SecretMemory(
      id: 'vesper_cg_1',
      valkyrieId: 'vesper',
      title: 'Faíscas na Oficina',
      subtitle: 'Dossiê de Recruta // Calibração de Ogivas',
      description: 'Vesper desmonta um canhão de antimatéria com um sorriso travesso e uma chave inglesa presa nos dentes.',
      imageAsset: 'assets/art/valkyries/vesper/hangar_fullbody.png',
      requiredBondLevel: 1,
      themeColor: Color(0xFFD500F9),
    ),
    const SecretMemory(
      id: 'vesper_cg_2',
      valkyrieId: 'vesper',
      title: 'Potência Máxima',
      subtitle: 'Dossiê Tático // Balística Pesada em Aegis',
      description: 'Após aniquilar uma esquadrilha pesada em Aegis Graveyard, Vesper customiza os torpedos de antimatéria para atingir cadência e dispersão recordes.',
      imageAsset: 'assets/art/valkyries/vesper/tactical_log_1.jpg',
      requiredBondLevel: 3,
      themeColor: Color(0xFFFF4081),
    ),
    const SecretMemory(
      id: 'vesper_cg_3',
      valkyrieId: 'vesper',
      title: 'Colapso Gravitacional',
      subtitle: 'Registro Supremo // Protocolo Singularity',
      description: 'A temida piloto renegada sela aliança definitiva de combate com a Frota Valkyrie: onde houver um bloqueio estelar, ela abrirá o caminho com fogo pesado.',
      imageAsset: 'assets/art/valkyries/vesper/tactical_log_2.jpg',
      requiredBondLevel: 5,
      themeColor: Color(0xFFAA00FF),
    ),

    // --- KBR-01 (Protagonista // Protocol Kimberly) ---
    const SecretMemory(
      id: 'kbr_cg_1',
      valkyrieId: 'kbr_01',
      title: 'Lótus no Hangar',
      subtitle: 'Dossiê de Recruta // Meditação de Espadachim',
      description: 'KBR-01 em silêncio absoluto no hangar da AV-00 Muramasa, concentrando energia taquiônica antes de desembaínhar sua lâmina no vácuo.',
      imageAsset: 'assets/art/valkyries/kbr_01/hangar_fullbody.png',
      requiredBondLevel: 1,
      themeColor: Color(0xFF00E5FF),
    ),
    const SecretMemory(
      id: 'kbr_cg_2',
      valkyrieId: 'kbr_01',
      title: 'Ressonância de Iaido',
      subtitle: 'Dossiê Tático // Frequência Taquiônica KBR',
      description: 'KBR-01 desacopla os sensores de combate da AV-00 Muramasa para afinar a lâmina taquiônica a 10^14 Hz, atingindo precisão cirúrgica de corte dimensional.',
      imageAsset: 'assets/art/valkyries/kbr_01/tactical_log_1.jpg',
      requiredBondLevel: 3,
      themeColor: Color(0xFF00B0FF),
    ),
    const SecretMemory(
      id: 'kbr_cg_3',
      valkyrieId: 'kbr_01',
      title: 'Corte do Infinito',
      subtitle: 'Registro Supremo // Vínculo Neural Inabalável',
      description: 'A mestre de combate KBR jura lealdade absoluta ao comando da frota: onde quer que a missão exija, sua lâmina romperá o espaço-tempo para abrir passagem.',
      imageAsset: 'assets/art/valkyries/kbr_01/tactical_log_2.jpg',
      requiredBondLevel: 5,
      themeColor: Color(0xFF00E5FF),
    ),
  ];

  static const List<PilotDialogue> _kbrDialogues = [
    PilotDialogue(
      minBondLevel: 1,
      text: '"Protocolo KBR ativo. A lâmina e a nave são uma só. Pronta quando você ordenar, Comandante."',
    ),
    PilotDialogue(
      minBondLevel: 1,
      text: '"O vácuo é silencioso... Esse silêncio me acalma antes de cada corte."',
    ),
    PilotDialogue(
      minBondLevel: 2,
      text: '"Você tem uma calma rara sob fogo cruzado. Pilotar ao seu lado é quase meditativo."',
    ),
    PilotDialogue(
      minBondLevel: 3,
      text: '"Sabe... eu sempre voei sob códigos táticos estritos. Mas com você no comando, sinto que posso alcançar qualquer estrela."',
    ),
    PilotDialogue(
      minBondLevel: 4,
      text: '"No hangar, longe dos monitores de combate... você é a única pessoa com quem não preciso ser apenas a arma KBR."',
    ),
    PilotDialogue(
      minBondLevel: 5,
      text: '"Minha espada e meu coração pertencem a você, Comandante. Onde você for, eu cortarei o seu caminho."',
    ),
  ];

  /// Diálogos Dinâmicos Reativos por Nível de Elo
  static final Map<String, List<PilotDialogue>> dialogues = {
    'kbr_01': _kbrDialogues,
    'kaede': _kbrDialogues,
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
        text: '"Ufa... Esse combate foi intenso! A refrigeração da Sol Blaze segurou a onda por um triz. Ótimo trabalho sincronizando os disparos, Comandante!"',
      ),
      const PilotDialogue(
        minBondLevel: 4,
        text: '"Quando aquela rajada atingiu nosso escudo, meu único pensamento foi proteger a frota e garantir que voltássemos inteiros para a base."',
      ),
      const PilotDialogue(
        minBondLevel: 5,
        text: '"Com você liderando a esquadrilha, meu coração queima com mais intensidade do que qualquer motor a plasma. Vamos voar juntos até o fim do cosmos!"',
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
        text: '"Passei anos confiando apenas em frios algoritmos defensivos... mas a sua precisão tática sob fogo cruzado supera qualquer cálculo preditivo."',
      ),
      const PilotDialogue(
        minBondLevel: 4,
        text: '"Calculei uma probabilidade de 99.8%: com as nossas táticas combinadas, nenhuma frota do Vácuo é capaz de romper o nosso setor."',
      ),
      const PilotDialogue(
        minBondLevel: 5,
        text: '"Você sintonizou perfeitamente os prismas da frota. Para onde quer que aponte o seu comando, a minha barreira será o seu escudo inabalável."',
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
        text: '"Olha só o resultado dos torpedos! Haha! Sabia que recalibrar os canhões de antimatéria ia pulverizar os cruzadores de elite!"',
      ),
      const PilotDialogue(
        minBondLevel: 4,
        text: '"Eu nunca confiei em comando nenhum nessa galáxia... Mas por essa esquadrilha, eu encaro qualquer tempestade estelar de frente."',
      ),
      const PilotDialogue(
        minBondLevel: 5,
        text: '"Você conquistou o respeito da piloto mais renegada da frota, Comandante. Agora segura firme, porque a nossa próxima saída vai abalar o cosmos!"',
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
          case 'kbr_01':
          case 'kaede':
            return '"$lastBoss caiu com um corte limpo. Protocolo KBR concluído sem atrasos, Comandante."';
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
          case 'kbr_01':
          case 'kaede':
            return '"A lâmina taquiônica errou por um milímetro contra $lastBoss... Meditarei sobre essa falha e recalibrarei o Protocolo KBR."';
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
