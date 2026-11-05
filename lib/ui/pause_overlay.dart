import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:asteroids/game/asteroids_game.dart';

class PauseOverlay extends StatefulWidget {
  final AsteroidsGame game;

  const PauseOverlay({super.key, required this.game});

  @override
  State<PauseOverlay> createState() => _PauseOverlayState();
}

class _PauseOverlayState extends State<PauseOverlay> {
  final FocusNode _focusNode = FocusNode();
  int _selectedButtonIndex = 0; // 0 = Resume Sortie, 1 = Return to Hangar

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
          _selectedButtonIndex = 1;
        });
        widget.game.playSfx('menu_select.wav');
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowUp ||
          event.logicalKey == LogicalKeyboardKey.keyW) {
        setState(() {
          _selectedButtonIndex = 0;
        });
        widget.game.playSfx('menu_select.wav');
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.enter ||
          event.logicalKey == LogicalKeyboardKey.numpadEnter ||
          event.logicalKey == LogicalKeyboardKey.space) {
        if (_selectedButtonIndex == 0) {
          widget.game.resumeGame();
        } else {
          widget.game.resumeGame();
          widget.game.changeState(GameState.valkyrieSelection);
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
                  width: 460,
                  padding: const EdgeInsets.symmetric(vertical: 28.0, horizontal: 28.0),
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
                          const Text(
                            'SORTIE PAUSED',
                            style: TextStyle(
                              fontFamily: 'Orbitron',
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2.5,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'ESC / P: Resume  •  ▲/▼: Select  •  ENTER: Confirm',
                        style: TextStyle(
                          fontFamily: 'Rajdhani',
                          fontSize: 11,
                          color: Colors.white54,
                          letterSpacing: 0.8,
                        ),
                      ),

                      const SizedBox(height: 20),

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
                                      errorBuilder: (_, __, ___) => Icon(
                                        Icons.rocket_launch,
                                        color: valkyrie.primaryColor,
                                        size: 28,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${valkyrie.name.toUpperCase()} // ${valkyrie.callsign.toUpperCase()}',
                                        style: TextStyle(
                                          fontFamily: 'Orbitron',
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: valkyrie.primaryColor,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'VESSEL: ${valkyrie.shipName}',
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

                            const Divider(height: 22, color: Colors.white12),

                            // Stats: Score, Sector Level & Stardust
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Column(
                                  children: [
                                    const Text(
                                      'SCORE',
                                      style: TextStyle(
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
                                    const Text(
                                      'RUN LEVEL',
                                      style: TextStyle(
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
                                    const Text(
                                      'STARDUST',
                                      style: TextStyle(
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
                                    '${w.name.toUpperCase()} (MK ${w.level})',
                                    style: TextStyle(
                                      fontFamily: 'Orbitron',
                                      fontSize: 9.0,
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

                      const SizedBox(height: 24),

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
                            _selectedButtonIndex == 0 ? '► RESUME SORTIE' : 'RESUME SORTIE',
                            style: const TextStyle(
                              fontFamily: 'Orbitron',
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: valkyrie.primaryColor,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 8,
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Action Button 2: Abort Sortie (Return to Hangar)
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
                          icon: const Icon(Icons.home, size: 18),
                          label: Text(
                            _selectedButtonIndex == 1 ? '► RETURN TO HANGAR' : 'RETURN TO HANGAR',
                            style: TextStyle(
                              fontFamily: 'Orbitron',
                              fontSize: 12.5,
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
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
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
}
