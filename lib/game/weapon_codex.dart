import 'package:flutter/material.dart';

/// Representação no Códice do Arsenal de cada arma de Astra Valkyries
class WeaponCodexEntry {
  final String id;
  final String name;
  final String evolvedName;
  final String manufacturer;
  final String damageType;
  final String classification;
  final String loreDescription;
  final String technicalSpecs;
  final String pilotQuote;
  final String pilotQuoteAuthor;
  final String evolutionTitle;
  final String evolutionDescription;
  final String synergyPassiveTitle;
  final IconData icon;
  final Color themeColor;
  final int difficultyRating; // 1 to 5
  final int rangeRating;      // 1 to 5
  final int damageRating;     // 1 to 5
  final int fireRateRating;   // 1 to 5

  const WeaponCodexEntry({
    required this.id,
    required this.name,
    required this.evolvedName,
    required this.manufacturer,
    required this.damageType,
    required this.classification,
    required this.loreDescription,
    required this.technicalSpecs,
    required this.pilotQuote,
    required this.pilotQuoteAuthor,
    required this.evolutionTitle,
    required this.evolutionDescription,
    required this.synergyPassiveTitle,
    required this.icon,
    required this.themeColor,
    required this.difficultyRating,
    required this.rangeRating,
    required this.damageRating,
    required this.fireRateRating,
  });

  static const List<WeaponCodexEntry> allEntries = [
    // 1. Tachyon Katana (Arma da Protagonista KBR-01 // Codename Kimberly)
    WeaponCodexEntry(
      id: 'tachyon_katana',
      name: 'Tachyon Katana',
      evolvedName: 'Void Muramasa',
      manufacturer: 'Laboratórios de Engenharia Espacial de Kyoto-7 // Projeto KBR',
      damageType: 'Corte Quântico Taquiônico',
      classification: 'Lâmina de Corte Dimensional & Apara Ativa',
      loreDescription:
          'Forjada na fornalha orbital de Kyoto-7 sob gravidade zero como arma exclusiva da unidade KBR-01. Condensa um feixe de táquions em uma lâmina crescente de plasma com espessura monomolecular. Seus arcos cortantes desintegram disparos inimigos em pleno ar (Tachyon Parry) e rasgam formações hostis com precisão cirúrgica.',
      technicalSpecs:
          'Lâmina monomolecular de táquions pressurizados com velocidade de ejeção de 520 px/s, anulação frontal de projéteis e penetração contínua em arco.',
      pilotQuote:
          '"Uma espada no espaço não é anacronismo quando seu corte apara a morte e abre caminho para a vitória."',
      pilotQuoteAuthor: 'Pilota KBR-01 (Shadow Lotus)',
      evolutionTitle: 'Juízo Dimensional do Vazio',
      evolutionDescription:
          'Atinge a ressonância do Trono do Vazio, disparando lâminas dimensionais triplas contínuas que atravessam a tela de ponta a ponta com penetração infinita.',
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
      damageType: 'Plasma Cinético de Deutério',
      classification: 'Rifle de Pulso Estelar',
      loreDescription:
          'O armamento padrão das esquadrilhas de interceptação durante o Cerco de Vesta. Forjado com bobinas de deutério pressurizado, foi a única arma que continuou disparando ininterruptamente quando a Primeira Frota perdeu contato com a Terra.',
      technicalSpecs:
          'Canhão eletromagnético com câmara de fusão magnética de deutério. Taxa de disparo estável de 0.70s calibrada para equilíbrio entre alcance e estabilidade de recuo.',
      pilotQuote:
          '"Simples, confiável e nunca emperra no vácuo. Se você sabe mirar, o Blaster faz o resto."',
      pilotQuoteAuthor: 'Lyra Vance (Solar Vanguard)',
      evolutionTitle: 'Supernova Annihilator',
      evolutionDescription:
          'A fita de deuterômeros entra em colapso nuclear contínuo, disparando feixes dourados paralelos de plasma imperial com perfuração irrestrita de tela.',
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
      damageType: 'Estilhaços Cinéticos Superaquecidos',
      classification: 'Canhão de Dispersão Angular / Flak',
      loreDescription:
          'Originalmente concebido nos estaleiros orbitais de Hélio para fragmentar campos de detritos de asteroides na órbita de Júpiter. Quando as naves da Frota Corrompida atacaram em formações fechadas, os engenheiros removeram as travas de dispersão angular, transformando-o na ferramenta definitiva contra enxames no escuro.',
      technicalSpecs:
          'Dispersão em leque de 3 a 5 vias de balotes cinéticos fragmentários de tungstênio. Letalidade multiplicada contra alvos a curta distância.',
      pilotQuote:
          '"Quem precisa calcular trajetórias perfeitas quando você pode inundar o quadrante inteiro com metal incandescente?"',
      pilotQuoteAuthor: 'Vesper Thorne (Dread Renegade)',
      evolutionTitle: 'Hyperion Flak Storm',
      evolutionDescription:
          'Projeta um anel perimetral de 10 vias em 360 graus de fragmentos de alta velocidade, desintegrando qualquer tentativa de cerco hostil.',
      synergyPassiveTitle: 'Aegis Capacitor (Capacitor de Escudo)',
      icon: Icons.grain_rounded,
      themeColor: Color(0xFFFF5252),
      difficultyRating: 2,
      rangeRating: 2,
      damageRating: 4,
      fireRateRating: 3,
    ),

    // 4. Phase Laser
    WeaponCodexEntry(
      id: 'rapid_fire',
      name: 'Phase Laser',
      evolvedName: 'Absolute Zero Tachyon Beam',
      manufacturer: 'Consórcio Criogênico de Tritão',
      damageType: 'Feixe Fotônico Coerente Sub-Zero',
      classification: 'Emissor Laser de Alta Frequência',
      loreDescription:
          'Um emissor experimental de táquions desenvolvido para perfurar blindagens refractárias. Seu sistema exclusivo canaliza o zero absoluto do vácuo cósmico diretamente para o cano, permitindo cadência extrema sem risco de fusão térmica da carcaça.',
      technicalSpecs:
          'Laser coerente pulsante de frequência contínua (0.32s inicial a 0.18s). Precisão linear cirúrgica com ricochete em escudos de plasma.',
      pilotQuote:
          '"O corte é tão rápido e frio que os sensores inimigos demoram dois segundos para registrar a perda da fuselagem."',
      pilotQuoteAuthor: 'Dra. Selene Vance (Void Tactician)',
      evolutionTitle: 'Absolute Zero Tachyon Beam',
      evolutionDescription:
          'Emite uma torrente ininterrupta de táquions azuis congelantes com 99 perfurações de alvos que rasgam linhas inteiras de inimigos.',
      synergyPassiveTitle: 'Overclocked Emitters (Cadência de Tiro)',
      icon: Icons.ac_unit_rounded,
      themeColor: Color(0xFF80D8FF),
      difficultyRating: 2,
      rangeRating: 5,
      damageRating: 2,
      fireRateRating: 5,
    ),

    // 5. Antimatter Torpedo
    WeaponCodexEntry(
      id: 'bomb_launcher',
      name: 'Antimatter Torpedo',
      evolvedName: 'Singularity Rift Torpedo',
      manufacturer: 'Arsenal Proibido de Titã (Divisão Ômega)',
      damageType: 'Implosão de Matéria Escura',
      classification: 'Lançador de Ogivas Gravitacionais',
      loreDescription:
          'Protótipo banido pelo Tratado de Titã de 2184 devido ao risco de colapso espacial. Cada ogiva comprime matéria escura em uma câmara selada por confinamento quântico. Ao atingir o alvo, rasga uma micro-fenda no espaço-tempo que devora blindagens pesadas e a própria luz ao redor.',
      technicalSpecs:
          'Ogiva teleguiada de alta massa com raio de explosão expansivo de 95px a 140px. Dano concentrado devastador contra naves capitânias e chefes de setor.',
      pilotQuote:
          '"Disseram que era perigoso demais colocar isso num caça leve. Eu respondi para colocarem duas."',
      pilotQuoteAuthor: 'Vesper Thorne (Dread Renegade)',
      evolutionTitle: 'Singularity Rift Torpedo',
      evolutionDescription:
          'Detona um autêntico micro buraco negro que atrai magneticamente todos os asteroides e inimigos da área antes da implosão cataclísmica.',
      synergyPassiveTitle: 'Magnetic Harvester (Imã de Coleta)',
      icon: Icons.cyclone_rounded,
      themeColor: Color(0xFFE040FB),
      difficultyRating: 3,
      rangeRating: 3,
      damageRating: 5,
      fireRateRating: 1,
    ),

    // 6. Aegis Sawblades
    WeaponCodexEntry(
      id: 'aegis_sawblades',
      name: 'Aegis Sawblades',
      evolvedName: 'Celestial Buzzsaw Ring',
      manufacturer: 'Consórcio de Mineração Pesada de Calisto',
      damageType: 'Lâminas Cinéticas Orbitais',
      classification: 'Escudo de Defesa Ativa Rotacional',
      loreDescription:
          'Originalmente escudos rotativos de mineração criados para triturar asteroides de tungstênio em Calisto. Quando a Frota Corrompida atacou, as mineradoras descobriram que cascos de caças inimigos rasgavam igual rocha fria ao entrar em contato com os anéis giratórios.',
      technicalSpecs:
          'Matriz orbital de 2 a 4 serras de liga hiperdensa sustentadas por braços gravitacionais. Tritura projéteis e corpos sólidos em contato perimetral.',
      pilotQuote:
          '"A melhor defesa não é um escudo estático; é um anel de lâminas girando a Mach 20 ao redor do seu cockpit."',
      pilotQuoteAuthor: 'Dra. Selene Vance (Void Tactician)',
      evolutionTitle: 'Celestial Buzzsaw Ring',
      evolutionDescription:
          'Expande o anel para 6 serras douradas com órbita estendida (115px) e velocidade de rotação triplicada, criando uma zona de morte impenetrável.',
      synergyPassiveTitle: 'Aegis Capacitor (Capacitor de Escudo)',
      icon: Icons.rotate_right_rounded,
      themeColor: Color(0xFFFFD700),
      difficultyRating: 1,
      rangeRating: 1,
      damageRating: 4,
      fireRateRating: 4,
    ),

    // 7. Tesla Arc Cannon
    WeaponCodexEntry(
      id: 'tesla_arc',
      name: 'Tesla Arc Cannon',
      evolvedName: 'Mjolnir Storm Conduit',
      manufacturer: 'Estaleiros Navais do Encouraçado Aegis-IV',
      damageType: 'Descarga Eletrostática Iônica',
      classification: 'Bobina Voltaica em Cadeia',
      loreDescription:
          'Bobina de alta indução recuperada dos destroços do lendário encouraçado Sovereign Aegis-IV. Dispara arcos voltaicos inteligentes que buscam o núcleo energético condutor mais próximo, saltando automaticamente entre alvos hostis em sequência.',
      technicalSpecs:
          'Descarga atmosférica em arco com até 5 saltos sucessivos e alcance de busca de 260px. Aplica o status elemental Choque Iônico com desativação temporária de propulsores.',
      pilotQuote:
          '"O raio sempre escolhe o caminho de menor resistência. No combate espacial, esse caminho passa pelo motor inimigo."',
      pilotQuoteAuthor: 'Dra. Selene Vance (Void Tactician)',
      evolutionTitle: 'Mjolnir Storm Conduit',
      evolutionDescription:
          'Amplia a cadeia para até 8 alvos simultâneos com arcos dourados de alta voltagem, eletrocutando formações inteiras instantaneamente.',
      synergyPassiveTitle: 'Overclocked Emitters (Cadência de Tiro)',
      icon: Icons.electric_bolt_rounded,
      themeColor: Color(0xFF00E5FF),
      difficultyRating: 2,
      rangeRating: 4,
      damageRating: 3,
      fireRateRating: 4,
    ),

    // 8. Quantum Chakram
    WeaponCodexEntry(
      id: 'quantum_chakram',
      name: 'Quantum Chakram',
      evolvedName: 'Chronos Eclipse Glaive',
      manufacturer: 'Ordem de Caelum (Artífices de Relíquias)',
      damageType: 'Cinético Temporal Retornável',
      classification: 'Glaive Bumerangue Espacial',
      loreDescription:
          'Arma cerimonial da Ordem de Caelum. O disco dobra a geometria gravitacional local para viajar em trajetória elíptica e retornar sempre à nave que o lançou, cortando duas vezes na mesma batida de coração ao atravessar formações na ida e na volta.',
      technicalSpecs:
          'Projétil giratório balanceado por massa quântica. Causa dano contínuo ao transpassar inimigos e amplificação de velocidade no retorno cinético.',
      pilotQuote:
          '"Ele sempre volta para casa. E sempre traz poeira cósmica daqueles que ousaram tentar interceptá-lo."',
      pilotQuoteAuthor: 'Astraea Solaris (Origin Matriarch)',
      evolutionTitle: 'Chronos Eclipse Glaive',
      evolutionDescription:
          'Dispara 3 chakrams gigantescos entrelaçados que desaceleram o tempo local e causam +165% de dano crítico ao retornarem para a nave.',
      synergyPassiveTitle: 'Quantum Thrusters (Propulsão Quântica)',
      icon: Icons.all_out_rounded,
      themeColor: Color(0xFF69F0AE),
      difficultyRating: 3,
      rangeRating: 4,
      damageRating: 4,
      fireRateRating: 2,
    ),

    // 9. Repulsor Gravity Aura
    WeaponCodexEntry(
      id: 'repulsor_aura',
      name: 'Repulsor Gravity Aura',
      evolvedName: 'Event Horizon Nova Pulse',
      manufacturer: 'Laboratórios de Propulsão Gravitacional de Encélado',
      damageType: 'Onda de Choque Gravimétrica',
      classification: 'Emissor de Pulso Perimetral 360°',
      loreDescription:
          'Gerador de pulso harmônico instalado ao redor do reator central da Valquíria. Converte o desespero de um cerco cerrado em ondas de choque gravitacionais de 360 graus que empurram asteroides errantes e repelem projéteis cinéticos leves.',
      technicalSpecs:
          'Pulso expansivo contínuo de 145px a 235px originado no centro da nave. Dano distribuído uniformemente a todos os corpos presentes na área de impacto.',
      pilotQuote:
          '"Espaço pessoal é sagrado no vácuo. Esse pulso garante que ninguém chegue a menos de duzentos metros de mim."',
      pilotQuoteAuthor: 'Vesper Thorne (Dread Renegade)',
      evolutionTitle: 'Event Horizon Nova Pulse',
      evolutionDescription:
          'Libera uma colossal onda de choque do Horizonte de Eventos que aplica Ruptura do Vazio e Congelamento Criogênico em toda a tela.',
      synergyPassiveTitle: 'Magnetic Harvester (Imã de Coleta)',
      icon: Icons.radar_rounded,
      themeColor: Color(0xFFB388FF),
      difficultyRating: 1,
      rangeRating: 2,
      damageRating: 3,
      fireRateRating: 3,
    ),

    // 10. Solar Thermal Lance
    WeaponCodexEntry(
      id: 'solar_lance',
      name: 'Solar Thermal Lance',
      evolvedName: 'Helios Core Melter',
      manufacturer: 'Forja Coronal de Órion',
      damageType: 'Plasma Térmico Coronal',
      classification: 'Lança de Fusão Contínua',
      loreDescription:
          'Canalizador direto de plasma coronal extraído da Forja de Órion. Seu feixe contínuo atinge temperaturas de milhões de graus Celsius ao longo de centenas de metros, fundindo escudos frontais e placas de titanite em segundos.',
      technicalSpecs:
          'Feixe térmico contínuo com extensão de 460px a 680px e largura focal de 18px. Aplica o status Queimadura Solar contínua que drena HP percentual.',
      pilotQuote:
          '"Não há liga metálica no cosmos que resista à temperatura de uma forja estelar em foco concentrado."',
      pilotQuoteAuthor: 'Lyra Vance (Solar Vanguard)',
      evolutionTitle: 'Helios Core Melter',
      evolutionDescription:
          'Amplia a largura da lança térmica para 28px, incinerando blindagens de titãs e gerando uma tempestade incandescente de longa duração.',
      synergyPassiveTitle: 'Void Catalyst (Acelerador de Sobrecarga)',
      icon: Icons.wb_sunny_rounded,
      themeColor: Color(0xFFFF9100),
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
      damageType: 'Chama Estelar Expansiva',
      classification: 'Lança-Chamas de Curta Distância',
      loreDescription:
          'Propulsor secundário modificado por Lyra Vance após ficar sem munição no Cinturão Exterior. Transforma combustível estelar bruto em uma tempestade incandescente de curta distância que derrete agressores que tentem encurralar a Valquíria.',
      technicalSpecs:
          'Jato cônico de partículas ionizadas de curta duração (0.40s) com dispersão angular ampla e alta frequência de acertos (0.28s cooldown).',
      pilotQuote:
          '"Se eles querem chegar perto o suficiente para ver os rebites da minha nave, vão ter que aguentar o calor da turbina na cara."',
      pilotQuoteAuthor: 'Lyra Vance (Solar Vanguard)',
      evolutionTitle: 'Phoenix Dragon Breath',
      evolutionDescription:
          'Dispara 5 jatos entrelaçados de fogo da fênix cósmica que incineram esquadrões inteiros e deixam um rastro persistente de brasas estelares.',
      synergyPassiveTitle: 'Void Catalyst (Acelerador de Sobrecarga)',
      icon: Icons.local_fire_department_rounded,
      themeColor: Color(0xFFFF3D00),
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
      damageType: 'Cinético Guiado por IA',
      classification: 'Esquadrão de Drones Caçadores',
      loreDescription:
          'Drones autônomos contendo fragmentos das matrizes de IA de pilotos caídas em missões passadas. Mesmo após a destruição de suas naves originais, suas almas cibernéticas se recusam a deixar uma irmã voar desacompanhada no vácuo.',
      technicalSpecs:
          'Enxame de 2 a 3 drones escoltas em voo sincronizado. Rastreamento térmico automático de alvos com rajadas de interceptação preventiva.',
      pilotQuote:
          '"Eu nunca voo sozinha. As vozes delas nos meus fones me avisam de qualquer ameaça antes mesmo dos meus sensores."',
      pilotQuoteAuthor: 'Pilota KBR-01 (Shadow Lotus)',
      evolutionTitle: 'Seraphim Drone Squadron',
      evolutionDescription:
          'Mobiliza 4 caças Seraphim dourados de interceptação de alta manobrabilidade com canhões gêmeos ionizados.',
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
      damageType: 'Minas Magnéticas de Ruptura',
      classification: 'Armamento Tático de Kiting',
      loreDescription:
          'Minas magnéticas de contenção usadas por caçadoras furtivas que operam em inferioridade numérica. Flutuam silenciosamente no rastro da nave, aguardando perseguidores gananciosos demais para surpreendê-los com detonações em cadeia.',
      technicalSpecs:
          'Carga traseira de ejeção magnética com raio de detonação de 110px a 155px. Dano maciço concentrado para neutralizar perseguidores.',
      pilotQuote:
          '"A primeira regra para sobreviver no Cinturão Sombrio: nunca persiga uma Valquíria em linha reta."',
      pilotQuoteAuthor: 'Vesper Thorne (Dread Renegade)',
      evolutionTitle: 'Abyssal Minefield Matrix',
      evolutionDescription:
          'Dispersa tríades de minas abissais que aplicam Ruptura do Vazio e Congelamento Criogênico em toda a retaguarda do campo de batalha.',
      synergyPassiveTitle: 'Quantum Thrusters (Propulsão Quântica)',
      icon: Icons.brightness_low_rounded,
      themeColor: Color(0xFF7C4DFF),
      difficultyRating: 3,
      rangeRating: 2,
      damageRating: 5,
      fireRateRating: 2,
    ),
  ];

  static WeaponCodexEntry? findById(String id) {
    for (final e in allEntries) {
      if (e.id == id) return e;
    }
    return null;
  }
}
