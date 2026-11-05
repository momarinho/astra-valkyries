import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:asteroids/game/asteroids_game.dart';
import 'package:asteroids/services/api_service.dart';

class GameOverOverlay extends StatefulWidget {
  final AsteroidsGame game;

  const GameOverOverlay({super.key, required this.game});

  @override
  State<GameOverOverlay> createState() => _GameOverOverlayState();
}

class _GameOverOverlayState extends State<GameOverOverlay> {
  final TextEditingController _nameController = TextEditingController();
  final FocusNode _nameFocusNode = FocusNode();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameFocusNode.onKeyEvent = (node, event) {
      if (event is KeyDownEvent) {
        if (event.logicalKey == LogicalKeyboardKey.escape) {
          widget.game.changeState(GameState.valkyrieSelection);
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.enter ||
            event.logicalKey == LogicalKeyboardKey.numpadEnter) {
          if (_nameController.text.trim().isNotEmpty) {
            _submitAndShowLeaderboard();
          } else {
            widget.game.startGame();
          }
          return KeyEventResult.handled;
        }
      }
      return KeyEventResult.ignored;
    };
    // Mobile: Do not automatically focus textfield to prevent intrusive virtual keyboard popup
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submitAndShowLeaderboard() async {
    if (_isSaving) return;
    final name = _nameController.text.trim().isEmpty ? 'Commander' : _nameController.text.trim();
    setState(() {
      _isSaving = true;
    });

    widget.game.participantName = name;
    try {
      await ApiService.saveFairScore(
        playerName: name,
        scientistName: widget.game.selectedValkyrie.name,
        score: widget.game.score,
      );
    } catch (_) {}

    if (mounted) {
      widget.game.changeState(GameState.leaderboard);
    }
  }

  String _getCombatRating(int score, int level) {
    if (score >= 25000 || level >= 10) {
      return 'S-RANK // VOID APEX PILOT 👑';
    } else if (score >= 12000 || level >= 6) {
      return 'A-RANK // ELITE VANGUARD ACE 🌟';
    } else if (score >= 5000 || level >= 3) {
      return 'B-RANK // COMBAT SPECIALIST 🚀';
    } else {
      return 'C-RANK // CADET SORTIE 🛸';
    }
  }

  String _getAfterActionQuote(String pilotId) {
    switch (pilotId) {
      case 'lyra':
        return '"We\'ll come back with hotter thrusters next time, Commander! Don\'t count us out yet!"';
      case 'selene':
        return '"Tactical anomalies detected in void density. Recalibrating barrier matrix for next deployment."';
      case 'vesper':
        return '"Tch, they got lucky with that hit. Give me another hull and watch me blow this whole sector to dust!"';
      default:
        return '"Void Protocol aborted. Repair systems standing by in the Hangar."';
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final valkyrie = game.selectedValkyrie;
    final score = game.score;

    return Focus(
      focusNode: _nameFocusNode,
      autofocus: true,
      child: GestureDetector(
        onTap: () => _nameFocusNode.requestFocus(),
        child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
                child: Container(
                  width: 580,
                  padding: const EdgeInsets.symmetric(vertical: 26.0, horizontal: 26.0),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.90),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: valkyrie.primaryColor.withOpacity(0.6),
                      width: 1.8,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: valkyrie.primaryColor.withOpacity(0.2),
                        blurRadius: 26.0,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Status Header
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'HULL COMPROMISED // SORTIE TERMINATED',
                          style: TextStyle(
                            fontFamily: 'Orbitron',
                            fontVariations: const [FontVariation('wght', 800)],
                            fontSize: 22,
                            letterSpacing: 2,
                            color: valkyrie.primaryColor,
                            shadows: [
                              Shadow(
                                color: valkyrie.primaryColor.withOpacity(0.8),
                                blurRadius: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Vessel hull integrity collapsed under heavy asteroid bombardment.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Rajdhani',
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Score & Stats Display
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                children: [
                                  const Text(
                                    'FINAL SCORE',
                                    style: TextStyle(
                                      fontFamily: 'Rajdhani',
                                      fontSize: 11,
                                      color: Colors.white54,
                                      letterSpacing: 1.1,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '$score pts',
                                    style: const TextStyle(
                                      fontFamily: 'Orbitron',
                                      fontVariations: [FontVariation('wght', 800)],
                                      fontSize: 22,
                                      color: Colors.white,
                                      shadows: [Shadow(color: Color(0x8800E5FF), blurRadius: 10)],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 24),
                              Container(width: 1, height: 36, color: Colors.white24),
                              const SizedBox(width: 24),
                              Column(
                                children: [
                                  const Text(
                                    'LEVEL REACHED',
                                    style: TextStyle(
                                      fontFamily: 'Rajdhani',
                                      fontSize: 11,
                                      color: Colors.white54,
                                      letterSpacing: 1.1,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'LV ${game.runLevel}',
                                    style: TextStyle(
                                      fontFamily: 'Orbitron',
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: valkyrie.accentColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 24),
                              Container(width: 1, height: 36, color: Colors.white24),
                              const SizedBox(width: 24),
                              Column(
                                children: [
                                  const Text(
                                    'PILOT',
                                    style: TextStyle(
                                      fontFamily: 'Rajdhani',
                                      fontSize: 11,
                                      color: Colors.white54,
                                      letterSpacing: 1.1,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    valkyrie.name.toUpperCase(),
                                    style: TextStyle(
                                      fontFamily: 'Orbitron',
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: valkyrie.primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Rank Evaluation Badge
                      Container(
                        margin: const EdgeInsets.only(top: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.65),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: valkyrie.accentColor.withOpacity(0.5), width: 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: valkyrie.accentColor.withOpacity(0.15),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.military_tech, color: valkyrie.accentColor, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'COMBAT RATING: ${_getCombatRating(score, game.runLevel)}',
                                style: TextStyle(
                                  fontFamily: 'Orbitron',
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: valkyrie.accentColor,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Pilot Debrief / After-Action Dialogue Card
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              valkyrie.primaryColor.withOpacity(0.18),
                              valkyrie.accentColor.withOpacity(0.08),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: valkyrie.primaryColor.withOpacity(0.6),
                            width: 1.8,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: valkyrie.primaryColor.withOpacity(0.2),
                              blurRadius: 18.0,
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Pilot Portrait Frame
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: valkyrie.primaryColor,
                                  width: 2.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: valkyrie.primaryColor.withOpacity(0.4),
                                    blurRadius: 12.0,
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.asset(
                                  valkyrie.hudDamagedAsset,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    color: Colors.black54,
                                    child: Icon(Icons.person, color: valkyrie.primaryColor, size: 36),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Debrief Text
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.record_voice_over, color: valkyrie.accentColor, size: 18),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          'AFTER-ACTION DEBRIEF // ${valkyrie.name.toUpperCase()}',
                                          style: TextStyle(
                                            fontFamily: 'Orbitron',
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.bold,
                                            color: valkyrie.accentColor,
                                            letterSpacing: 1.1,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _getAfterActionQuote(valkyrie.id),
                                    style: const TextStyle(
                                      fontFamily: 'Rajdhani',
                                      fontSize: 14.0,
                                      fontWeight: FontWeight.w600,
                                      height: 1.35,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Action Buttons
                      Row(
                        children: [
                          // Retry Button
                          Expanded(
                            flex: 1,
                            child: ElevatedButton.icon(
                              focusNode: FocusNode(canRequestFocus: false),
                              onPressed: () {
                                game.startGame();
                              },
                              icon: const Icon(Icons.refresh, size: 20),
                              label: const Text(
                                'RETRY SORTIE',
                                style: TextStyle(
                                  fontFamily: 'Orbitron',
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: valkyrie.primaryColor,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 6,
                              ),
                            ),
                          ),

                          const SizedBox(width: 12),

                          // Return to Hangar Button
                          Expanded(
                            flex: 1,
                            child: OutlinedButton.icon(
                              focusNode: FocusNode(canRequestFocus: false),
                              onPressed: () {
                                game.changeState(GameState.valkyrieSelection);
                              },
                              icon: const Icon(Icons.home, size: 18),
                              label: const Text(
                                'RETURN TO HANGAR',
                                style: TextStyle(
                                  fontFamily: 'Orbitron',
                                  fontSize: 13,
                                  letterSpacing: 1,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white70,
                                side: const BorderSide(color: Colors.white24),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
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
