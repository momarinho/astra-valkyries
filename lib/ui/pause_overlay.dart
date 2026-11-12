import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:asteroids/game/asteroids_game.dart';
import 'package:asteroids/services/localization_service.dart';
import 'package:asteroids/services/achievement_service.dart';
import 'package:asteroids/services/secret_grimoire_service.dart';
import 'package:asteroids/game/rogue_perks.dart';

class PauseOverlay extends StatefulWidget {
  final AsteroidsGame game;

  const PauseOverlay({super.key, required this.game});

  @override
  State<PauseOverlay> createState() => _PauseOverlayState();
}

class _PauseOverlayState extends State<PauseOverlay> {
  final FocusNode _focusNode = FocusNode();
  int _selectedButtonIndex = 0; // 0 = Resume Sortie, 1 = Return to Hangar, 2 = Main Menu
  int _activeTab = 0; // 0 = Mission Status, 1 = Cosmic Grimoire

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.escape ||
          event.logicalKey == LogicalKeyboardKey.keyP) {
        widget.game.resumeGame();
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowDown ||
          event.logicalKey == LogicalKeyboardKey.keyS) {
        setState(() {
          _selectedButtonIndex = (_selectedButtonIndex + 1) % 3;
        });
        widget.game.playSfx('menu_select.wav');
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowUp ||
          event.logicalKey == LogicalKeyboardKey.keyW) {
        setState(() {
          _selectedButtonIndex = (_selectedButtonIndex - 1 + 3) % 3;
        });
        widget.game.playSfx('menu_select.wav');
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.enter ||
          event.logicalKey == LogicalKeyboardKey.numpadEnter ||
          event.logicalKey == LogicalKeyboardKey.space) {
        if (_selectedButtonIndex == 0) {
          widget.game.resumeGame();
        } else if (_selectedButtonIndex == 1) {
          widget.game.resumeGame();
          widget.game.changeState(GameState.valkyrieSelection);
        } else {
          widget.game.resumeGame();
          widget.game.changeState(GameState.menu);
        }
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final valkyrie = game.selectedValkyrie;
    final score = game.score;

    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: SingleChildScrollView(
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
                child: Container(
                  width: 470,
                  padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 26.0),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.90),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: valkyrie.primaryColor.withOpacity(0.6),
                      width: 1.8,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: valkyrie.primaryColor.withOpacity(0.2),
                        blurRadius: 24.0,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.pause_circle_filled, color: valkyrie.primaryColor, size: 28),
                          const SizedBox(width: 8),
                          Text(
                            I18n.t('pause.title'),
                            style: const TextStyle(
                              fontFamily: 'Orbitron',
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2.5,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        I18n.t('pause.keyhints'),
                        style: const TextStyle(
                          fontFamily: 'Rajdhani',
                          fontSize: 11,
                          color: Colors.white54,
                          letterSpacing: 0.8,
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Tab Toggle: Mission Status vs Cosmic Grimoire vs Achievements
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() => _activeTab = 0);
                                game.playSfx('menu_select.wav');
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: _activeTab == 0
                                      ? valkyrie.primaryColor.withValues(alpha: 0.22)
                                      : Colors.white.withValues(alpha: 0.04),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: _activeTab == 0 ? valkyrie.primaryColor : Colors.white12,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    I18n.t('pause.tab_status'),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontFamily: 'Orbitron',
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() => _activeTab = 1);
                                game.playSfx('menu_select.wav');
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: _activeTab == 1
                                      ? const Color(0xFFFFD700).withValues(alpha: 0.22)
                                      : Colors.white.withValues(alpha: 0.04),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: _activeTab == 1 ? const Color(0xFFFFD700) : Colors.white12,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    I18n.t('pause.tab_grimoire'),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontFamily: 'Orbitron',
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFFFD700),
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() => _activeTab = 2);
                                game.playSfx('menu_select.wav');
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: _activeTab == 2
                                      ? const Color(0xFF64FFDA).withValues(alpha: 0.22)
                                      : Colors.white.withValues(alpha: 0.04),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: _activeTab == 2 ? const Color(0xFF64FFDA) : Colors.white12,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    I18n.t('pause.tab_achievements'),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontFamily: 'Orbitron',
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF64FFDA),
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      if (_activeTab == 1)
                        _buildCosmicGrimoire(game)
                      else if (_activeTab == 2)
                        _buildAchievementsTab()
                      else
                        // Round Summary Box
                        Container(
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Column(
                            children: [
                              // Pilot info
                              Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: valkyrie.accentColor, width: 1.5),
                                    ),
                                    child: ClipOval(
                                      child: Image.asset(
                                        valkyrie.hudNeutralAsset,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, _, _) => Icon(
                                          Icons.rocket_launch,
                                          color: valkyrie.primaryColor,
                                          size: 28,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${valkyrie.name.toUpperCase()} // ${valkyrie.callsign.toUpperCase()}',
                                          style: TextStyle(
                                            fontFamily: 'Orbitron',
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: valkyrie.primaryColor,
                                            letterSpacing: 1.2,
                                          ),
                                        ),
                                        Text(
                                          valkyrie.shipName,
                                          style: const TextStyle(
                                            fontFamily: 'Rajdhani',
                                            fontSize: 12,
                                            color: Colors.white70,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              const Divider(height: 20, color: Colors.white12),

                              // Quick Stats Row
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  Column(
                                    children: [
                                      Text(
                                        I18n.t('hud.score'),
                                        style: const TextStyle(
                                          fontFamily: 'Rajdhani',
                                          fontSize: 11,
                                          color: Colors.white54,
                                          letterSpacing: 1.1,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        '$score',
                                        style: const TextStyle(
                                          fontFamily: 'Orbitron',
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(width: 1, height: 32, color: Colors.white12),
                                  Column(
                                    children: [
                                      Text(
                                        I18n.select(pt: 'NÍVEL', en: 'RUN LEVEL'),
                                        style: const TextStyle(
                                          fontFamily: 'Rajdhani',
                                          fontSize: 11,
                                          color: Colors.white54,
                                          letterSpacing: 1.1,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        'LV ${game.runLevel}',
                                        style: TextStyle(
                                          fontFamily: 'Orbitron',
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: valkyrie.accentColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(width: 1, height: 32, color: Colors.white12),
                                  Column(
                                    children: [
                                      Text(
                                        I18n.select(pt: 'POEIRA', en: 'STARDUST'),
                                        style: const TextStyle(
                                          fontFamily: 'Rajdhani',
                                          fontSize: 11,
                                          color: Colors.white54,
                                          letterSpacing: 1.1,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        '${game.runXp}',
                                        style: const TextStyle(
                                          fontFamily: 'Orbitron',
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF00E5FF),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),

                              const Divider(height: 20, color: Colors.white12),

                              // Equipped Arsenal Badges
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                alignment: WrapAlignment.center,
                                children: game.player.activeWeapons.map((w) {
                                  final isMax = w.level >= w.maxLevel;
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.white10,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: isMax ? const Color(0xFFFFD700) : valkyrie.primaryColor.withOpacity(0.5),
                                      ),
                                    ),
                                    child: Text(
                                      '${w.name} ${w.isEvolved ? "★" : "MK ${w.level}"}',
                                      style: TextStyle(
                                        fontFamily: 'Rajdhani',
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: isMax ? const Color(0xFFFFD700) : Colors.white,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 16),

                      // Action Button 1: Resume Sortie
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _selectedButtonIndex == 0 ? Colors.white : Colors.transparent,
                            width: 2.0,
                          ),
                          boxShadow: _selectedButtonIndex == 0
                              ? [
                                  BoxShadow(
                                    color: valkyrie.primaryColor.withOpacity(0.6),
                                    blurRadius: 12,
                                  ),
                                ]
                              : null,
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            game.resumeGame();
                          },
                          icon: const Icon(Icons.play_arrow, size: 22),
                          label: Text(
                            _selectedButtonIndex == 0 ? '► ${I18n.t('pause.resume')}' : I18n.t('pause.resume'),
                            style: const TextStyle(
                              fontFamily: 'Orbitron',
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: valkyrie.primaryColor,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 8,
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Action Button 2: Abort Sortie (Return to Hangar / Workshop)
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _selectedButtonIndex == 1 ? Colors.white : Colors.transparent,
                            width: 2.0,
                          ),
                          boxShadow: _selectedButtonIndex == 1
                              ? [
                                  BoxShadow(
                                    color: Colors.white.withOpacity(0.3),
                                    blurRadius: 10,
                                  ),
                                ]
                              : null,
                        ),
                        child: OutlinedButton.icon(
                          onPressed: () {
                            game.resumeGame();
                            game.changeState(GameState.valkyrieSelection);
                          },
                          icon: const Icon(Icons.rocket_launch_rounded, size: 18),
                          label: Text(
                            _selectedButtonIndex == 1 ? '► ${I18n.t('pause.hangar')}' : I18n.t('pause.hangar'),
                            style: TextStyle(
                              fontFamily: 'Orbitron',
                              fontSize: 12.0,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1,
                              color: _selectedButtonIndex == 1 ? Colors.white : Colors.white70,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white70,
                            backgroundColor: _selectedButtonIndex == 1 ? Colors.white12 : Colors.transparent,
                            side: BorderSide(
                              color: _selectedButtonIndex == 1 ? Colors.white70 : Colors.white24,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Action Button 3: Return to Main Title Menu
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _selectedButtonIndex == 2 ? const Color(0xFF00E5FF) : Colors.transparent,
                            width: 2.0,
                          ),
                        ),
                        child: OutlinedButton.icon(
                          onPressed: () {
                            game.resumeGame();
                            game.changeState(GameState.menu);
                          },
                          icon: const Icon(Icons.home_rounded, size: 18),
                          label: Text(
                            _selectedButtonIndex == 2 ? '► ${I18n.t('pause.menu')}' : I18n.t('pause.menu'),
                            style: TextStyle(
                              fontFamily: 'Orbitron',
                              fontSize: 12.0,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1,
                              color: _selectedButtonIndex == 2 ? const Color(0xFF00E5FF) : Colors.white60,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white60,
                            backgroundColor: _selectedButtonIndex == 2 ? Colors.white10 : Colors.transparent,
                            side: BorderSide(
                              color: _selectedButtonIndex == 2 ? const Color(0xFF00E5FF) : Colors.white12,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Quick Language Switcher Bar at Pause Footer
                      InkWell(
                        onTap: () async {
                          await I18n.toggleLocale();
                          setState(() {});
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.language_rounded, size: 14, color: Color(0xFF64FFDA)),
                              const SizedBox(width: 6),
                              Text(
                                '${I18n.t('pause.language')}: ${I18n.currentLocale.flag} ${I18n.currentLocale.label}',
                                style: const TextStyle(
                                  fontFamily: 'Rajdhani',
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF64FFDA),
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCosmicGrimoire(AsteroidsGame game) {
    final discovered = SecretGrimoireService.discoveredCount;
    final total = SecretGrimoireService.totalCount;
    final pct = (SecretGrimoireService.progressFraction * 100).toInt();

    // 1. Super-Unions
    final superUnions = [
      (
        key: 'union_void_singularity',
        name: 'Void Singularity Nova',
        req1: 'Pulse Blaster (MK 3)',
        req2: 'Void Cluster Mines (MK 3)',
        hasReq1: game.player.unlockedWeapons['blaster']?.level == 3,
        hasReq2: game.player.unlockedWeapons['void_mines']?.level == 3,
        isEquipped: game.player.unlockedWeapons.containsKey('union_void_singularity'),
        desc: I18n.select(
          pt: 'Fusão de Blaster e Minas do Vazio. Libera 1 slot de arma e dispara feixes quânticos.',
          en: 'Fuses Blaster and Void Mines. Frees 1 arsenal slot and fires quantum singularity beams.',
        ),
      ),
      (
        key: 'union_thunderstorm',
        name: 'Thunderstorm Core Melter',
        req1: 'Solar Thermal Lance (MK 3)',
        req2: 'Tesla Arc Cannon (MK 3)',
        hasReq1: game.player.unlockedWeapons['solar_lance']?.level == 3,
        hasReq2: game.player.unlockedWeapons['tesla_arc']?.level == 3,
        isEquipped: game.player.unlockedWeapons.containsKey('union_thunderstorm'),
        desc: I18n.select(
          pt: 'Fusão de Lance Solar e Canhão Tesla. Libera 1 slot e emite raios solares bifurcados.',
          en: 'Fuses Solar Lance and Tesla Arc. Frees 1 slot and emits branched solar lightning.',
        ),
      ),
    ];

    return Container(
      constraints: const BoxConstraints(maxHeight: 285),
      child: Column(
        children: [
          // Header Progress Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.35)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        I18n.select(
                          pt: 'GRIMÓRIO // SEGREDOS REVELADOS',
                          en: 'GRIMOIRE // SECRETS DISCOVERED',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Orbitron',
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFFD700),
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$discovered / $total ($pct%)',
                      style: const TextStyle(
                        fontFamily: 'Orbitron',
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: SecretGrimoireService.progressFraction,
                    backgroundColor: Colors.white12,
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
                    minHeight: 5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              children: [
                // Super-Unions Section
                ...superUnions.map((u) {
                  final isDiscovered = SecretGrimoireService.isDiscovered(u.key);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: u.isEquipped
                          ? const Color(0xFFE040FB).withOpacity(0.20)
                          : (isDiscovered ? Colors.black.withOpacity(0.45) : Colors.white.withOpacity(0.02)),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: u.isEquipped
                            ? const Color(0xFFE040FB)
                            : (isDiscovered ? const Color(0xFFFFD700).withOpacity(0.5) : Colors.white12),
                        width: isDiscovered ? 1.2 : 0.8,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                isDiscovered ? '★ SUPER-UNIÃO: ${u.name.toUpperCase()}' : '★ ??? [SUPER-UNIÃO SECRETA]',
                                style: TextStyle(
                                  fontFamily: 'Orbitron',
                                  fontSize: 10.0,
                                  fontWeight: FontWeight.bold,
                                  color: isDiscovered ? const Color(0xFFE040FB) : Colors.white38,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: (u.isEquipped ? const Color(0xFFE040FB) : Colors.white10),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                u.isEquipped ? 'EQUIPADA!' : (isDiscovered ? 'LIBERA 1 SLOT' : 'SEGREDO'),
                                style: const TextStyle(
                                  fontFamily: 'Orbitron',
                                  fontSize: 8.0,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          isDiscovered
                              ? '${u.hasReq1 ? "✅" : "⬜"} ${u.req1}  +  ${u.hasReq2 ? "✅" : "⬜"} ${u.req2}'
                              : '⬜ ??? + ⬜ ??? (Funda 2 armas nível máximo em combate)',
                          style: TextStyle(
                            fontFamily: 'Rajdhani',
                            fontSize: 11.0,
                            fontWeight: FontWeight.w600,
                            color: isDiscovered ? const Color(0xFF64FFDA) : Colors.white30,
                          ),
                        ),
                        if (isDiscovered)
                          Text(
                            u.desc,
                            style: const TextStyle(
                              fontFamily: 'Rajdhani',
                              fontSize: 10.5,
                              color: Colors.white60,
                            ),
                          ),
                      ],
                    ),
                  );
                }),
                // Standard 13 Weapon Evolutions
                ...WeaponSynergy.allSynergies.map((s) {
                  final isDiscovered = SecretGrimoireService.isDiscovered(s.weaponId);
                  final weaponMatch = game.player.activeWeapons.where((w) => w.id == s.weaponId).toList();
                  final hasWeapon = weaponMatch.isNotEmpty;
                  final isMaxWeapon = hasWeapon && weaponMatch.first.level >= weaponMatch.first.maxLevel;
                  final isEvolved = hasWeapon && weaponMatch.first.isEvolved;
                  final hasPassive = game.activePassives.contains(s.passiveId);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isEvolved
                          ? const Color(0xFFFFD700).withOpacity(0.14)
                          : (isDiscovered ? Colors.black.withOpacity(0.45) : Colors.white.withOpacity(0.02)),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isEvolved
                            ? const Color(0xFFFFD700)
                            : (isMaxWeapon && hasPassive
                                ? const Color(0xFF00E676)
                                : (isDiscovered ? Colors.white24 : Colors.white10)),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                isDiscovered
                                    ? '★ ${s.evolvedName.toUpperCase()}'
                                    : (hasWeapon ? '★ ${s.weaponId.toUpperCase()} + ??? [SEGREDO]' : '★ ??? [SEGREDO DO VAZIO]'),
                                style: TextStyle(
                                  fontFamily: 'Orbitron',
                                  fontSize: 10.0,
                                  fontWeight: FontWeight.bold,
                                  color: isEvolved
                                      ? const Color(0xFFFFD700)
                                      : (isDiscovered ? Colors.white : Colors.white38),
                                ),
                              ),
                            ),
                            Text(
                              isEvolved
                                  ? I18n.select(pt: 'EVOLUÍDA!', en: 'EVOLVED!')
                                  : (isMaxWeapon && hasPassive
                                      ? I18n.select(pt: 'PRONTA!', en: 'READY!')
                                      : (isDiscovered
                                          ? I18n.select(pt: 'DESCOBERTA', en: 'KNOWN')
                                          : I18n.select(pt: 'OCULTO', en: 'HIDDEN'))),
                              style: TextStyle(
                                fontFamily: 'Orbitron',
                                fontSize: 8.5,
                                fontWeight: FontWeight.bold,
                                color: isEvolved
                                    ? const Color(0xFFFFD700)
                                    : (isMaxWeapon && hasPassive
                                        ? const Color(0xFF00E676)
                                        : (isDiscovered ? Colors.cyanAccent : Colors.white24)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          isDiscovered
                              ? '${hasWeapon ? "✅" : "⬜"} ${s.weaponId.toUpperCase()} (MK 3)  +  ${hasPassive ? "✅" : "⬜"} ${s.passiveTitle}'
                              : (hasWeapon
                                  ? '✅ ${s.weaponId.toUpperCase()} (MK 3)  +  ⬜ ??? [Módulo Desconhecido]'
                                  : '⬜ ??? + ⬜ ??? [Descubra fundindo em combate]'),
                          style: TextStyle(
                            fontFamily: 'Rajdhani',
                            fontSize: 11.0,
                            fontWeight: FontWeight.w600,
                            color: isDiscovered ? Colors.cyanAccent : Colors.white38,
                          ),
                        ),
                        if (isDiscovered)
                          Text(
                            s.evolutionDescription,
                            style: const TextStyle(
                              fontFamily: 'Rajdhani',
                              fontSize: 10.5,
                              color: Colors.white60,
                            ),
                          ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsTab() {
    final unlocked = AchievementService.unlockedCount;
    final total = AchievementService.totalCount;
    final pct = (AchievementService.progressFraction * 100).toInt();

    return Container(
      constraints: const BoxConstraints(maxHeight: 280),
      child: Column(
        children: [
          // Header Progress Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'PROGRESSO DE CONQUISTAS',
                      style: TextStyle(
                        fontFamily: 'Orbitron',
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFFD700),
                        letterSpacing: 1.0,
                      ),
                    ),
                    Text(
                      '$unlocked / $total ($pct%)',
                      style: const TextStyle(
                        fontFamily: 'Orbitron',
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: total == 0 ? 0.0 : unlocked / total,
                    minHeight: 5,
                    backgroundColor: Colors.white12,
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Scrollable list of achievements
          Expanded(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: AchievementService.all.length,
              separatorBuilder: (_, _) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final ach = AchievementService.all[index];
                final isUnlocked = AchievementService.isUnlocked(ach.id);

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: isUnlocked
                        ? ach.color.withOpacity(0.12)
                        : Colors.white.withOpacity(0.02),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isUnlocked ? ach.color.withOpacity(0.5) : Colors.white10,
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isUnlocked ? ach.color.withOpacity(0.2) : Colors.white10,
                          border: Border.all(
                            color: isUnlocked ? ach.color : Colors.white24,
                            width: 1.0,
                          ),
                        ),
                        child: Icon(
                          isUnlocked ? ach.icon : Icons.lock_outline_rounded,
                          size: 16,
                          color: isUnlocked ? ach.color : Colors.white38,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ach.title,
                              style: TextStyle(
                                fontFamily: 'Orbitron',
                                fontSize: 10.0,
                                fontWeight: FontWeight.bold,
                                color: isUnlocked ? Colors.white : Colors.white38,
                              ),
                            ),
                            Text(
                              ach.description,
                              style: TextStyle(
                                fontFamily: 'Rajdhani',
                                fontSize: 10.0,
                                color: isUnlocked ? Colors.white70 : Colors.white30,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isUnlocked)
                        const Icon(Icons.check_circle_rounded, color: Color(0xFF64FFDA), size: 16),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
