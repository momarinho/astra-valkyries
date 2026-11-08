import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:asteroids/game/asteroids_game.dart';
import 'package:asteroids/game/ending_manager.dart';
import 'package:asteroids/services/api_service.dart';

class GameOverOverlay extends StatefulWidget {
  final AsteroidsGame game;

  const GameOverOverlay({super.key, required this.game});

  @override
  State<GameOverOverlay> createState() => _GameOverOverlayState();
}

class _GameOverOverlayState extends State<GameOverOverlay> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.onKeyEvent = (node, event) {
      if (event is KeyDownEvent) {
        if (event.logicalKey == LogicalKeyboardKey.escape) {
          widget.game.changeState(GameState.menu);
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.enter ||
            event.logicalKey == LogicalKeyboardKey.numpadEnter) {
          widget.game.startGame();
          return KeyEventResult.handled;
        }
      }
      return KeyEventResult.ignored;
    };
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
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

  String _getAfterActionQuote(String pilotId, bool isVictory) {
    if (isVictory) {
      switch (pilotId) {
        case 'lyra':
          return '"Target neutralized and sector cleared! Nobody outflies the Sol-Blaze, Commander!"';
        case 'selene':
          return '"All Void anomalies purged with 100% tactical precision. The stars are secure once again."';
        case 'vesper':
          return '"Hah! Even their biggest Titans turned into cosmic dust! Ready for another round, Commander?"';
        default:
          return '"Void Protocol conquered! Returning to the Hangar in triumph."';
      }
    }
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
      focusNode: _focusNode,
      autofocus: true,
      child: GestureDetector(
        onTap: () => _focusNode.requestFocus(),
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
                          (game.missionSurvived || game.campaignCompleted)
                              ? (game.campaignCompleted
                                  ? '🏆 VICTORY // VOID SINGULARITY CONQUERED!'
                                  : '🏆 MISSION ACCOMPLISHED // SECTOR SECURED!')
                              : 'HULL COMPROMISED // SORTIE TERMINATED',
                          style: TextStyle(
                            fontFamily: 'Orbitron',
                            fontVariations: const [FontVariation('wght', 800)],
                            fontSize: 22,
                            letterSpacing: 2,
                            color: (game.missionSurvived || game.campaignCompleted)
                                ? const Color(0xFFFFD700)
                                : valkyrie.primaryColor,
                            shadows: [
                              Shadow(
                                color: ((game.missionSurvived || game.campaignCompleted)
                                        ? const Color(0xFFFFD700)
                                        : valkyrie.primaryColor)
                                    .withOpacity(0.8),
                                blurRadius: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        (game.missionSurvived || game.campaignCompleted)
                            ? 'All primary tactical objectives achieved. Returning to the Hangar in triumph!'
                            : 'Vessel hull integrity collapsed under heavy asteroid bombardment.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Rajdhani',
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),

                      if (game.lastTriggeredEnding != EndingType.none) ...[
                        const SizedBox(height: 12),
                        Builder(
                          builder: (context) {
                            final ending = EndingManager.getDetails(game.lastTriggeredEnding);
                            if (ending == null) return const SizedBox.shrink();
                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: ending.primaryColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: ending.primaryColor.withOpacity(0.65),
                                  width: 1.5,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${ending.code} // ${ending.title}',
                                    style: TextStyle(
                                      fontFamily: 'Orbitron',
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: ending.primaryColor,
                                      letterSpacing: 1.1,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    ending.biometricStatus,
                                    style: const TextStyle(
                                      fontFamily: 'Rajdhani',
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    ending.narrativeBody,
                                    style: const TextStyle(
                                      fontFamily: 'Rajdhani',
                                      fontSize: 12.5,
                                      height: 1.25,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],

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
                              const SizedBox(width: 24),
                              Container(width: 1, height: 36, color: Colors.white24),
                              const SizedBox(width: 24),
                              Column(
                                children: [
                                  const Text(
                                    'COSMIC SCRAP',
                                    style: TextStyle(
                                      fontFamily: 'Rajdhani',
                                      fontSize: 11,
                                      color: Colors.white54,
                                      letterSpacing: 1.1,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '+${game.runCredits}c',
                                    style: const TextStyle(
                                      fontFamily: 'Orbitron',
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFFFB300),
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
                                  (game.missionSurvived || game.campaignCompleted)
                                      ? valkyrie.hudNeutralAsset
                                      : valkyrie.hudDamagedAsset,
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
                                    _getAfterActionQuote(valkyrie.id, game.missionSurvived || game.campaignCompleted),
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
                              icon: const Icon(Icons.refresh, size: 18),
                              label: const Text(
                                'RETRY SORTIE',
                                style: TextStyle(
                                  fontFamily: 'Orbitron',
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: valkyrie.primaryColor,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 6,
                              ),
                            ),
                          ),

                          const SizedBox(width: 10),

                          // Shop & Hangar Button
                          Expanded(
                            flex: 1,
                            child: OutlinedButton.icon(
                              focusNode: FocusNode(canRequestFocus: false),
                              onPressed: () {
                                game.initialHangarTab = 1;
                                game.changeState(GameState.valkyrieSelection);
                              },
                              icon: const Icon(Icons.precision_manufacturing_rounded, size: 17, color: Color(0xFFFFB300)),
                              label: const Text(
                                'LOJA & HANGAR',
                                style: TextStyle(
                                  fontFamily: 'Orbitron',
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFFFB300),
                                  letterSpacing: 0.8,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFFFB300),
                                side: const BorderSide(color: Color(0xFFFFB300)),
                                padding: const EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 10),

                          // Return to Main Menu Button
                          Expanded(
                            flex: 1,
                            child: OutlinedButton.icon(
                              focusNode: FocusNode(canRequestFocus: false),
                              onPressed: () {
                                game.changeState(GameState.menu);
                              },
                              icon: const Icon(Icons.home_rounded, size: 18),
                              label: const Text(
                                'MENU PRINCIPAL',
                                style: TextStyle(
                                  fontFamily: 'Orbitron',
                                  fontSize: 11.5,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white70,
                                side: const BorderSide(color: Colors.white24),
                                padding: const EdgeInsets.symmetric(vertical: 15),
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
