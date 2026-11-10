import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Idiomas suportados em Astra Valkyries: Void Protocol
enum AppLocale {
  ptBr('pt_BR', 'Português (Brasil)', '🇧🇷'),
  enUs('en_US', 'English (US)', '🇺🇸');

  final String code;
  final String label;
  final String flag;
  const AppLocale(this.code, this.label, this.flag);

  static AppLocale fromCode(String? code) {
    if (code == null) return AppLocale.ptBr;
    if (code.startsWith('en')) return AppLocale.enUs;
    return AppLocale.ptBr;
  }
}

/// Serviço Centralizado de Localização & I18n
/// Permite alternância reativa em tempo real (ValueNotifier) e persistência via SharedPreferences.
class I18n {
  static const String _prefKey = 'app_language';
  static AppLocale _currentLocale = AppLocale.ptBr;
  static final ValueNotifier<AppLocale> localeNotifier = ValueNotifier<AppLocale>(_currentLocale);

  static AppLocale get currentLocale => _currentLocale;
  static bool get isPt => _currentLocale == AppLocale.ptBr;
  static bool get isEn => _currentLocale == AppLocale.enUs;

  /// Inicializa o idioma a partir do SharedPreferences ou do idioma do sistema
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance().timeout(const Duration(milliseconds: 150));
      final savedCode = prefs.getString(_prefKey);
      if (savedCode != null) {
        _currentLocale = AppLocale.fromCode(savedCode);
      } else {
        // Tenta detectar o idioma do sistema operacional
        final systemLocale = ui.PlatformDispatcher.instance.locale.languageCode.toLowerCase();
        _currentLocale = systemLocale.startsWith('pt') ? AppLocale.ptBr : AppLocale.enUs;
      }
    } catch (_) {
      _currentLocale = AppLocale.ptBr;
    }
    localeNotifier.value = _currentLocale;
  }

  /// Altera o idioma ativo e persiste a escolha
  static Future<void> setLocale(AppLocale newLocale) async {
    _currentLocale = newLocale;
    localeNotifier.value = newLocale;
    try {
      final prefs = await SharedPreferences.getInstance().timeout(const Duration(milliseconds: 150));
      await prefs.setString(_prefKey, newLocale.code);
    } catch (_) {}
  }

  /// Define o idioma sincronamente (útil para testes unitários de widgets)
  static void setLocaleSync(AppLocale newLocale) {
    _currentLocale = newLocale;
    localeNotifier.value = newLocale;
  }

  /// Reseta o estado para testes
  static void resetForTest([AppLocale locale = AppLocale.ptBr]) {
    _currentLocale = locale;
    localeNotifier.value = locale;
  }

  /// Alterna entre PT-BR e EN-US rapidamente
  static Future<void> toggleLocale() async {
    final next = _currentLocale == AppLocale.ptBr ? AppLocale.enUs : AppLocale.ptBr;
    await setLocale(next);
  }

  /// Seleciona dinamicamente a string correspondente ao idioma ativo
  static String select({required String pt, required String en}) {
    return isPt ? pt : en;
  }

  /// Traduz uma chave com substituição opcional de parâmetros: {param}
  static String t(String key, [Map<String, String>? params]) {
    final dict = _currentLocale == AppLocale.ptBr ? _ptBr : _enUs;
    final fallbackDict = _currentLocale == AppLocale.ptBr ? _enUs : _ptBr;

    String? translation = dict[key] ?? fallbackDict[key];
    if (translation == null) {
      // Retorna a chave se não for encontrada para facilitar debug
      return key;
    }

    if (params != null && params.isNotEmpty) {
      params.forEach((paramKey, paramVal) {
        translation = translation!.replaceAll('{$paramKey}', paramVal);
      });
    }

    return translation!;
  }

  /// Atalho conveniente para tradução
  static String tr(String key, [Map<String, String>? params]) => t(key, params);

  // =========================================================================
  // DICIONÁRIOS DE TRADUÇÃO
  // =========================================================================

  static const Map<String, String> _ptBr = {
    // HUD & In-Game Telemetry
    'hud.hull': 'CASCO',
    'hud.shield': 'ESCUDO',
    'hud.score': 'PONTOS',
    'hud.optimal': 'ESTÁVEL',
    'hud.critical': 'ALERTA CRÍTICO',
    'hud.overdrive_ready': 'SOBRECARGA PRONTA',
    'hud.level': 'NÍVEL {level}',
    'hud.stardust': '{cur} / {max} POEIRA ESTELAR',
    'hud.pause': 'PAUSA',
    'hud.surge': 'SURTO: {time}s',
    'hud.tactical_map_btn': '[M] MAPA TÁTICO',
    'hud.recharge': 'RECARGA',
    'hud.lock_fire': 'MIRA / TIRO',
    'hud.dash': 'DASH',
    'hud.special': 'ESPECIAL',
    'hud.move': 'MOVER',
    'hud.hazard_warning': 'AVISO: LIMITE DO SETOR // PERÍMETRO CRÍTICO',
    'hud.keyboard': 'TECLADO',
    'hud.touch': 'TOQUE',
    'hud.station_uplink': 'ENLACE COM A ESTAÇÃO // TRANSMISSÃO DE DADOS',
    'hud.station_secured': 'ESTAÇÃO PACIFICADA // DADOS TRANSFERIDOS',
    'hud.lockdown_alert': 'ALERTA: PROTOCOLO DE CONTENÇÃO ATIVADO',
    'hud.fps': '{fps} FPS',
    'hud.boss_hull': '{percent}% CASCO',

    // Keyhints Desktop
    'keyhint.wasd': 'WASD',
    'keyhint.move': 'MOVER',
    'keyhint.space': 'ESPAÇO',
    'keyhint.dash': 'DASH',
    'keyhint.q': 'Q',
    'keyhint.special': 'ESPECIAL',
    'keyhint.left_click': 'BOTÃO ESQ',
    'keyhint.aim_fire': 'MIRA / TIRO',
    'keyhint.m': 'M',
    'keyhint.map': 'MAPA TÁTICO',

    // Pause Menu
    'pause.title': 'OPERAÇÃO PAUSADA',
    'pause.keyhints': 'ESC / P: Continuar  •  ▲/▼: Selecionar  •  ENTER: Confirmar',
    'pause.tab_status': 'STATUS DA MISSÃO',
    'pause.tab_grimoire': '✨ GRIMÓRIO CÓSMICO',
    'pause.resume': 'CONTINUAR OPERAÇÃO',
    'pause.hangar': 'RETORNAR AO HANGAR',
    'pause.menu': 'MENU PRINCIPAL',
    'pause.stats_title': 'TELEMETRIA DA INCURSÃO',
    'pause.time': 'Tempo de Combate',
    'pause.enemies_down': 'Inimigos Abatidos',
    'pause.asteroids_destroyed': 'Asteroides Fragmentados',
    'pause.stardust_collected': 'Poeira Estelar Coletada',
    'pause.tactical_map': 'ABRIR MAPA TÁTICO',
    'pause.language': 'IDIOMA',

    // Game Over & Victory
    'game_over.victory': '🏆 MISSÃO CUMPRIDA // SETOR PACIFICADO!',
    'game_over.campaign_victory': '🏆 VITÓRIA // SINGULARIDADE DO VAZIO CONQUISTADA!',
    'game_over.defeat': 'CASCO COMPROMETIDO // OPERAÇÃO ENCERRADA',
    'game_over.debrief': 'RELATÓRIO PÓS-COMBATE // {pilot}',
    'game_over.retry': 'REPETIR OPERAÇÃO',
    'game_over.shop_hangar': 'OFICINA & HANGAR',
    'game_over.menu': 'MENU PRINCIPAL',
    'game_over.stats_summary': 'RESUMO DA INCURSÃO',
    'game_over.final_score': 'PONTUAÇÃO FINAL',
    'game_over.level_reached': 'NÍVEL ALCANÇADO',
    'game_over.stardust_harvested': 'POEIRA ESTELAR COLETADA',
    'game_over.credits_earned': 'CRÉDITOS OBTIDOS',
    'game_over.new_record': '★ NOVO RECORDE PESSOAL! ★',

    // Title Screen / Main Menu
    'title.game_title': 'ASTRA VALKYRIES',
    'title.game_subtitle': 'VOID PROTOCOL // PROTOCOLO DO VAZIO',
    'title.play': 'INICIAR OPERAÇÃO // HANGAR',
    'title.play_sub': 'Selecionar Valquíria, Setor e Modo de Combate',
    'title.workshop': 'LOJA & OFICINA // UPGRADES',
    'title.workshop_sub': 'Comprar melhorias permanentes de frota ({credits}c disponíveis)',
    'title.gallery': 'GALERIA & AFINIDADE // MEMÓRIAS',
    'title.gallery_sub': 'Arquivos de Elo, ilustrações e memórias desbloqueadas',
    'title.settings': 'CONTROLES & CONFIGURAÇÕES',
    'title.settings_sub': 'Modo Direcional 360° vs Rotação Clássica e física de voo',
    'title.language': 'IDIOMA',
    'title.credits': 'CRÉDITOS',
    'title.press_start': 'PRESSIONE QUALQUER TECLA OU CLIQUE PARA ENTRAR',

    // Settings Overlay
    'settings.title': 'CONFIGURAÇÕES DE SISTEMA',
    'settings.language_header': 'IDIOMA DO JOGO // LANGUAGE',
    'settings.control_scheme_header': 'MODO DE PILOTAGEM // ESQUEMA DE CONTROLE',
    'settings.control_vector': 'PROPULSÃO VETORIAL & RÉ TÁTICA (PADRÃO)',
    'settings.control_vector_desc': 'W acelera, S dá ré atirando nos inimigos (Kiting) e A/D giram o nariz da nave.',
    'settings.control_directional': 'DIRECIONAL 360° (TWIN-STICK / ROGUELIKE)',
    'settings.control_directional_desc': 'WASD movem a nave diretamente na direção pressionada estilo Vampire Survivors.',
    'settings.audio_header': 'ÁUDIO & TRILHA SONORA',
    'settings.bgm': 'Música de Fundo (BGM)',
    'settings.sfx': 'Efeitos Sonoros (SFX)',
    'settings.close': 'VOLTAR',

    // Level Up Overlay
    'level_up.badge': 'NÍVEL SUPERADO! • NÍVEL {level}',
    'level_up.subtitle': 'SELECIONE 1 MÓDULO DE EXPANSÃO TÁTICA',
    'level_up.keyhint': '1 / 2 / 3 ou Clique para selecionar',

    // Perk Types & Rarities
    'perk_type.new_weapon': 'NOVA ARMA',
    'perk_type.upgrade_weapon': 'MELHORIA DE ARMA',
    'perk_type.passive': 'MÓDULO PASSIVO',
    'perk_type.evolution': '★ HIPER-EVOLUÇÃO ★',

    'rarity.common': 'COMUM',
    'rarity.rare': 'RARO',
    'rarity.epic': 'ÉPICO',
    'rarity.legendary': 'LENDÁRIO',

    // Hangar & Valkyrie Selection
    'hangar.title': 'CENTRO DE COMANDO & HANGAR',
    'hangar.tab_sortie': 'SORTIE // DECOLAR',
    'hangar.tab_workshop': 'OFICINA // UPGRADES',
    'hangar.tab_gallery': 'GALERIA // MEMÓRIAS',
    'hangar.tab_codex': 'CODEX // ARSENAL',
    'hangar.launch_btn': '► INICIAR INCURSÃO',
    'hangar.launch_sub': 'Confirmar decolagem no vácuo estelar',
    'hangar.refund_btn': 'REEMBOLSAR TUDO (100%)',
    'hangar.vessel': 'NAVE DE COMBATE',
    'hangar.special_ability': 'HABILIDADE ESPECIAL',
    'hangar.starting_weapon': 'ARMA INICIAL',
    'hangar.stats_header': 'ESPECIFICAÇÕES DA VALQUÍRIA',
    'hangar.stat_speed': 'VELOCIDADE',
    'hangar.stat_defense': 'DEFESA / CASCO',
    'hangar.stat_firepower': 'PODER DE FOGO',
    'hangar.stat_crit': 'CHANCE CRÍTICA',
    'hangar.stat_magnet': 'RAIO MAGNÉTICO',
    'hangar.back_menu': 'MENU PRINCIPAL',
    'hangar.wallpaper_mode': 'MODO PAPEL DE PAREDE',

    // Tactical Map Overlay
    'map.title': 'MAPA TÁTICO DO SETOR',
    'map.subtitle': 'Telemetria orbital em tempo real',
    'map.legend_player': 'Sua Nave',
    'map.legend_boss': 'Ameaça Leviatã',
    'map.legend_station': 'Estação de Enlace',
    'map.legend_hazard': 'Perímetro Crítico',
    'map.legend_lockdown': 'Câmara de Quarentena',
    'map.legend_props': 'Recursos / Carga',
    'map.close': 'FECHAR MAPA [ESC / M]',

    // Chest & Drops
    'chest.jackpot': 'SUPER RECOMPENSA! (5 ITENS)',
    'chest.gold': 'BAÚ DE SUPRIMENTOS DE OURO (3 ITENS)',
    'chest.standard': 'SUPRIMENTO TÁTICO (1 ITEM)',
    'chest.secured': 'CARGA ORBITAL RECUPERADA • PROTOCOLO DE RECOMPENSA ATIVO',
    'chest.claim': 'RESGATAR RECOMPENSAS [ESPAÇO / ENTER]',

    // Stage Clear Overlay
    'stage_clear.title': 'SETOR PACIFICADO!',
    'stage_clear.subtitle': 'Todos os alvos hostis do setor foram neutralizados',
    'stage_clear.next': 'AVANÇAR PARA O PRÓXIMO SETOR',

    // Workshop & Shop
    'shop.title': 'OFICINA DE TECNOLOGIA DE FROTA',
    'shop.subtitle': 'Melhorias permanentes de nanotecnologia e propulsão',
    'shop.credits': 'Créditos Disponíveis: {credits}c',
    'shop.buy': 'COMPRAR ({cost}c)',
    'shop.maxed': 'NÍVEL MÁXIMO',
    'shop.refund': 'REEMBOLSAR UPGRADES',
  };

  static const Map<String, String> _enUs = {
    // HUD & In-Game Telemetry
    'hud.hull': 'HULL',
    'hud.shield': 'SHIELD',
    'hud.score': 'SCORE',
    'hud.optimal': 'OPTIMAL',
    'hud.critical': 'CRITICAL ALERT',
    'hud.overdrive_ready': 'OVERDRIVE READY',
    'hud.level': 'LEVEL {level}',
    'hud.stardust': '{cur} / {max} STARDUST',
    'hud.pause': 'PAUSE',
    'hud.surge': 'SURGE: {time}s',
    'hud.tactical_map_btn': '[M] TACTICAL MAP',
    'hud.recharge': 'RECHARGE',
    'hud.lock_fire': 'LOCK / FIRE',
    'hud.dash': 'DASH',
    'hud.special': 'SPECIAL',
    'hud.move': 'MOVE',
    'hud.hazard_warning': 'WARNING: SECTOR BOUNDARY // HAZARD PERIMETER',
    'hud.keyboard': 'KEYBOARD',
    'hud.touch': 'TOUCH',
    'hud.station_uplink': 'STATION UPLINK // TRANSMISSION IN PROGRESS',
    'hud.station_secured': 'STATION SECURED // DATA TRANSMITTED',
    'hud.lockdown_alert': 'ALERT: CONTAINMENT PROTOCOL ENGAGED',
    'hud.fps': '{fps} FPS',
    'hud.boss_hull': '{percent}% HULL',

    // Keyhints Desktop
    'keyhint.wasd': 'WASD',
    'keyhint.move': 'MOVE',
    'keyhint.space': 'SPACE',
    'keyhint.dash': 'DASH',
    'keyhint.q': 'Q',
    'keyhint.special': 'SPECIAL',
    'keyhint.left_click': 'LEFT CLICK',
    'keyhint.aim_fire': 'AIM / FIRE',
    'keyhint.m': 'M',
    'keyhint.map': 'TACTICAL MAP',

    // Pause Menu
    'pause.title': 'SORTIE PAUSED',
    'pause.keyhints': 'ESC / P: Resume  •  ▲/▼: Select  •  ENTER: Confirm',
    'pause.tab_status': 'MISSION STATUS',
    'pause.tab_grimoire': '✨ COSMIC GRIMOIRE',
    'pause.resume': 'RESUME SORTIE',
    'pause.hangar': 'RETURN TO HANGAR',
    'pause.menu': 'MAIN MENU',
    'pause.stats_title': 'SORTIE TELEMETRY',
    'pause.time': 'Combat Time',
    'pause.enemies_down': 'Enemies Neutralized',
    'pause.asteroids_destroyed': 'Asteroids Shattered',
    'pause.stardust_collected': 'Stardust Harvested',
    'pause.tactical_map': 'OPEN TACTICAL MAP',
    'pause.language': 'LANGUAGE',

    // Game Over & Victory
    'game_over.victory': '🏆 MISSION ACCOMPLISHED // SECTOR SECURED!',
    'game_over.campaign_victory': '🏆 VICTORY // VOID SINGULARITY CONQUERED!',
    'game_over.defeat': 'HULL COMPROMISED // SORTIE TERMINATED',
    'game_over.debrief': 'AFTER-ACTION DEBRIEF // {pilot}',
    'game_over.retry': 'RETRY SORTIE',
    'game_over.shop_hangar': 'HANGAR & WORKSHOP',
    'game_over.menu': 'MAIN MENU',
    'game_over.stats_summary': 'SORTIE SUMMARY',
    'game_over.final_score': 'FINAL SCORE',
    'game_over.level_reached': 'LEVEL REACHED',
    'game_over.stardust_harvested': 'STARDUST HARVESTED',
    'game_over.credits_earned': 'CREDITS EARNED',
    'game_over.new_record': '★ NEW PERSONAL RECORD! ★',

    // Title Screen / Main Menu
    'title.game_title': 'ASTRA VALKYRIES',
    'title.game_subtitle': 'VOID PROTOCOL // DEEP SPACE ROGUELITE',
    'title.play': 'START SORTIE // HANGAR',
    'title.play_sub': 'Select Valkyrie, Sector and Combat Mode',
    'title.workshop': 'WORKSHOP & UPGRADES',
    'title.workshop_sub': 'Purchase permanent fleet upgrades ({credits}c available)',
    'title.gallery': 'GALLERY & BOND // MEMORIES',
    'title.gallery_sub': 'Bond logs, illustrations and unlocked memories',
    'title.settings': 'CONTROLS & SETTINGS',
    'title.settings_sub': '360° Directional vs Classic Vectorial flight physics',
    'title.language': 'LANGUAGE',
    'title.credits': 'CREDITS',
    'title.press_start': 'PRESS ANY KEY OR CLICK TO ENTER',

    // Settings Overlay
    'settings.title': 'SYSTEM SETTINGS',
    'settings.language_header': 'GAME LANGUAGE // IDIOMA',
    'settings.control_scheme_header': 'FLIGHT CONTROLS // CONTROL SCHEME',
    'settings.control_vector': 'VECTOR THRUST & TACTICAL REVERSE (DEFAULT)',
    'settings.control_vector_desc': 'W accelerates, S reverses while firing (Kiting), and A/D rotate ship heading.',
    'settings.control_directional': '360° DIRECTIONAL (TWIN-STICK / ROGUELIKE)',
    'settings.control_directional_desc': 'WASD moves ship directly in pressed direction, Vampire Survivors style.',
    'settings.audio_header': 'AUDIO & SOUNDTRACK',
    'settings.bgm': 'Background Music (BGM)',
    'settings.sfx': 'Sound Effects (SFX)',
    'settings.close': 'BACK',

    // Level Up Overlay
    'level_up.badge': 'LEVEL UP! • LEVEL {level}',
    'level_up.subtitle': 'CHOOSE 1 TACTICAL EXPANSION MODULE',
    'level_up.keyhint': '1 / 2 / 3 or Click to select',

    // Perk Types & Rarities
    'perk_type.new_weapon': 'NEW WEAPON',
    'perk_type.upgrade_weapon': 'WEAPON UPGRADE',
    'perk_type.passive': 'PASSIVE MODULE',
    'perk_type.evolution': '★ WEAPON EVOLUTION ★',

    'rarity.common': 'COMMON',
    'rarity.rare': 'RARE',
    'rarity.epic': 'EPIC',
    'rarity.legendary': 'LEGENDARY',

    // Hangar & Valkyrie Selection
    'hangar.title': 'COMMAND DECK & HANGAR',
    'hangar.tab_sortie': 'SORTIE // LAUNCH',
    'hangar.tab_workshop': 'WORKSHOP // UPGRADES',
    'hangar.tab_gallery': 'GALLERY // MEMORIES',
    'hangar.tab_codex': 'CODEX // ARMORY',
    'hangar.launch_btn': '► LAUNCH SORTIE',
    'hangar.launch_sub': 'Confirm combat departure into the void',
    'hangar.refund_btn': 'REFUND ALL (100%)',
    'hangar.vessel': 'COMBAT VESSEL',
    'hangar.special_ability': 'SPECIAL ABILITY',
    'hangar.starting_weapon': 'STARTING WEAPON',
    'hangar.stats_header': 'VALKYRIE SPECIFICATIONS',
    'hangar.stat_speed': 'SPEED',
    'hangar.stat_defense': 'DEFENSE / HULL',
    'hangar.stat_firepower': 'FIREPOWER',
    'hangar.stat_crit': 'CRIT CHANCE',
    'hangar.stat_magnet': 'MAGNET RADIUS',
    'hangar.back_menu': 'MAIN MENU',
    'hangar.wallpaper_mode': 'WALLPAPER MODE',

    // Tactical Map Overlay
    'map.title': 'SECTOR TACTICAL MAP',
    'map.subtitle': 'Real-time orbital telemetry',
    'map.legend_player': 'Player Ship',
    'map.legend_boss': 'Leviathan Threat',
    'map.legend_station': 'Relay Station',
    'map.legend_hazard': 'Hazard Boundary',
    'map.legend_lockdown': 'Lockdown Chamber',
    'map.legend_props': 'Supplies / Cargo',
    'map.close': 'CLOSE MAP [ESC / M]',

    // Chest & Drops
    'chest.jackpot': 'SUPER JACKPOT! (5 REWARDS)',
    'chest.gold': 'GOLD SUPPLY CACHE (3 REWARDS)',
    'chest.standard': 'TACTICAL SUPPLY CACHE (1 REWARD)',
    'chest.secured': 'ORBITAL DROP SECURED • REWARD PROTOCOL ENGAGED',
    'chest.claim': 'CLAIM REWARDS [SPACE / ENTER]',

    // Stage Clear Overlay
    'stage_clear.title': 'SECTOR SECURED!',
    'stage_clear.subtitle': 'All sector hostile threats neutralized',
    'stage_clear.next': 'PROCEED TO NEXT SECTOR',

    // Workshop & Shop
    'shop.title': 'FLEET TECH WORKSHOP',
    'shop.subtitle': 'Permanent nanotechnology and thruster upgrades',
    'shop.credits': 'Available Credits: {credits}c',
    'shop.buy': 'PURCHASE ({cost}c)',
    'shop.maxed': 'MAX LEVEL',
    'shop.refund': 'REFUND UPGRADES',
  };
}
