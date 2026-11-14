import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:void_protocol/game/asteroids_game.dart';
import 'package:void_protocol/game/sector.dart';
import 'package:void_protocol/game/roguelite_systems.dart';

/// Overlay do Mapa Estelar de Rotas Ramificadas (Branching Star Chart) e Seleção de Mutação (Sprints 13 & 16)
class StarChartOverlay extends StatefulWidget {
  final AsteroidsGame game;

  const StarChartOverlay({super.key, required this.game});

  @override
  State<StarChartOverlay> createState() => _StarChartOverlayState();
}

class _StarChartOverlayState extends State<StarChartOverlay> {
  final FocusNode _focusNode = FocusNode();
  late List<Sector> _branchChoices;
  late List<PilotMutation> _mutationChoices;
  int _selectedSectorIdx = 0;
  int _selectedMutationIdx = 0;
  bool _showingLoopSelector = false;

  @override
  void initState() {
    super.initState();
    _branchChoices = Sector.getNextBranchChoices(
      widget.game.currentSector,
      canUnlockSecret: widget.game.canAccessSecretSector5,
    );
    if (_branchChoices.isEmpty) {
      _branchChoices = [Sector.defaultSector];
    }

    final availableMutations = PilotMutation.allMutations
        .where((m) => !widget.game.activeMutations.contains(m.id))
        .toList();
    _mutationChoices = availableMutations.take(3).toList();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _confirmWarpJump() {
    final targetSector = _branchChoices[_selectedSectorIdx.clamp(0, _branchChoices.length - 1)];
    final chosenMutation = (_mutationChoices.isNotEmpty && widget.game.activeMutations.length < 3)
        ? _mutationChoices[_selectedMutationIdx.clamp(0, _mutationChoices.length - 1)].id
        : null;
    widget.game.jumpToNextSector(
      targetSector: targetSector,
      chosenMutationId: chosenMutation,
    );
  }

  void _extractVictory() {
    widget.game.completeCurrentSectorRun();
  }

  void _loopBack(Sector sec) {
    widget.game.loopBackToSector(sec);
  }

  void _resumeExploration() {
    widget.game.overlays.remove('starChart');
    widget.game.changeState(GameState.playing);
    widget.game.resumeEngine();
    widget.game.gameFocusNode?.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final valkyrie = widget.game.selectedValkyrie;

    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
            event.logicalKey == LogicalKeyboardKey.keyA) {
          setState(() {
            _selectedSectorIdx = (_selectedSectorIdx - 1 + _branchChoices.length) % _branchChoices.length;
          });
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.arrowRight ||
            event.logicalKey == LogicalKeyboardKey.keyD) {
          setState(() {
            _selectedSectorIdx = (_selectedSectorIdx + 1) % _branchChoices.length;
          });
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.enter ||
            event.logicalKey == LogicalKeyboardKey.space) {
          _confirmWarpJump();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(MediaQuery.of(context).size.width < 600 ? 10 : 20),
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 760),
                    padding: EdgeInsets.all(MediaQuery.of(context).size.width < 600 ? 14 : 24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF070C18).withValues(alpha: 0.94),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.7),
                      width: 1.8,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00E5FF).withValues(alpha: 0.22),
                        blurRadius: 28,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.hub_rounded, color: Color(0xFF00E5FF), size: 26),
                          SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              'MAPA ESTELAR DE HIPERESPAÇO // ESCOLHA DE ROTA',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Orbitron',
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.8,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Selecione o próximo Bioma/Setor e adapte 1 Mutação Tática para a sua Nave',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Rajdhani',
                          fontSize: 13.5,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 18),

                      // 1. Branching Sector Choices
                      const Text(
                        '1. SELECIONE A ROTA DE SALTO QUÂNTICO',
                        style: TextStyle(
                          fontFamily: 'Orbitron',
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF00E5FF),
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final stackBranches = constraints.maxWidth < 520;
                          final cards = List.generate(_branchChoices.length, (i) {
                            final sec = _branchChoices[i];
                            final isSelected = _selectedSectorIdx == i;
                            final card = GestureDetector(
                              onTap: () => setState(() => _selectedSectorIdx = i),
                              child: Container(
                                margin: EdgeInsets.only(
                                  right: !stackBranches && i < _branchChoices.length - 1 ? 12 : 0,
                                  bottom: stackBranches && i < _branchChoices.length - 1 ? 10 : 0,
                                ),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? sec.primaryColor.withValues(alpha: 0.18)
                                      : Colors.white.withValues(alpha: 0.04),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isSelected ? sec.primaryColor : Colors.white24,
                                    width: isSelected ? 2.0 : 1.0,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(sec.icon, color: sec.primaryColor, size: 22),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            sec.name.toUpperCase(),
                                            style: TextStyle(
                                              fontFamily: 'Orbitron',
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: isSelected ? Colors.white : Colors.white70,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      sec.subtitle,
                                      style: TextStyle(
                                        fontFamily: 'Rajdhani',
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: sec.primaryColor,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      sec.description,
                                      style: const TextStyle(
                                        fontFamily: 'Rajdhani',
                                        fontSize: 12,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                            return stackBranches ? card : Expanded(child: card);
                          });
                          return stackBranches
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: cards,
                                )
                              : Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: cards,
                                );
                        },
                      ),

                      // 2. Pilot Mutation Selection (up to 3 per run)
                      if (_mutationChoices.isNotEmpty && widget.game.activeMutations.length < 3) ...[
                        const SizedBox(height: 12),
                        Text(
                          '2. ESCOLHA 1 MUTAÇÃO DE PILOTO (${widget.game.activeMutations.length}/3 ATIVAS)',
                          style: const TextStyle(
                            fontFamily: 'Orbitron',
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFFD700),
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...List.generate(_mutationChoices.length, (i) {
                          final mut = _mutationChoices[i];
                          final isSelected = _selectedMutationIdx == i;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedMutationIdx = i),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? mut.color.withValues(alpha: 0.18)
                                      : Colors.white.withValues(alpha: 0.04),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected ? mut.color : Colors.white12,
                                    width: isSelected ? 1.8 : 1.0,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(mut.icon, color: mut.color, size: 22),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            mut.title,
                                            style: TextStyle(
                                              fontFamily: 'Orbitron',
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: isSelected ? Colors.white : Colors.white70,
                                            ),
                                          ),
                                          Text(
                                            mut.description,
                                            style: const TextStyle(
                                              fontFamily: 'Rajdhani',
                                              fontSize: 12,
                                              color: Colors.white70,
                                            ),
                                          ),
                                          Text(
                                            '📜 ${mut.loreLog}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontFamily: 'Rajdhani',
                                              fontSize: 10.5,
                                              fontStyle: FontStyle.italic,
                                              color: Colors.white54,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isSelected)
                                      Icon(Icons.check_circle, color: mut.color, size: 20),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ],

                      if (_showingLoopSelector) ...[
                        const SizedBox(height: 12),
                        const Text(
                          '🔄 SELECIONE O SETOR DE DESTINO DA DOBRA REVERSA (+HORDAS):',
                          style: TextStyle(
                            fontFamily: 'Orbitron',
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFFD700),
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: Sector.allSectorsWithBranches
                              .where((s) => widget.game.isSectorUnlocked(s.id))
                              .map((sec) {
                            return ElevatedButton.icon(
                              onPressed: () => _loopBack(sec),
                              icon: Icon(sec.icon, size: 16, color: Colors.black),
                              label: Text(
                                '${sec.name.toUpperCase()} (LOOP)',
                                style: const TextStyle(
                                  fontFamily: 'Orbitron',
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFFD700),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                            );
                          }).toList(),
                        ),
                      ],

                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        key: const Key('confirm_star_chart_jump_button'),
                        onPressed: _confirmWarpJump,
                        icon: const Icon(Icons.rocket_launch_rounded, size: 20),
                        label: const Text(
                          'CONFIRMAR SALTO DE HIPERESPAÇO',
                          style: TextStyle(
                            fontFamily: 'Orbitron',
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: valkyrie.primaryColor,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Opções Táticas do Modelo Híbrido (Sprint 25)
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              key: const Key('extract_victory_button'),
                              onPressed: _extractVictory,
                              icon: const Icon(Icons.military_tech_rounded, size: 16, color: Color(0xFF00E676)),
                              label: const Text(
                                'EXTRAIR VITÓRIA',
                                style: TextStyle(
                                  fontFamily: 'Orbitron',
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF00E676),
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFF00E676), width: 1.2),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              key: const Key('loop_mode_toggle_button'),
                              onPressed: () {
                                setState(() => _showingLoopSelector = !_showingLoopSelector);
                                widget.game.playSfx('menu_select.wav');
                              },
                              icon: const Icon(Icons.sync_rounded, size: 16, color: Color(0xFFFFD700)),
                              label: Text(
                                _showingLoopSelector ? 'FECHAR LOOP' : 'DOBRA REVERSA',
                                style: const TextStyle(
                                  fontFamily: 'Orbitron',
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFFFD700),
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFFFFD700), width: 1.2),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              key: const Key('resume_exploration_button'),
                              onPressed: _resumeExploration,
                              icon: const Icon(Icons.explore_rounded, size: 16, color: Color(0xFF00E5FF)),
                              label: const Text(
                                'CONTINUAR MAPA',
                                style: TextStyle(
                                  fontFamily: 'Orbitron',
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF00E5FF),
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFF00E5FF), width: 1.2),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
