import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:asteroids/game/asteroids_game.dart';
import 'package:asteroids/game/sector.dart';
import 'package:asteroids/game/roguelite_systems.dart';

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

  @override
  void initState() {
    super.initState();
    _branchChoices = Sector.getNextBranchChoices(widget.game.currentSector);
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
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 760),
                  padding: const EdgeInsets.all(24),
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
                        'Selecione o próximo Bioma/Setor e adapte 1 Mutação Tática para a sua Valquíria',
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
                      Row(
                        children: List.generate(_branchChoices.length, (i) {
                          final sec = _branchChoices[i];
                          final isSelected = _selectedSectorIdx == i;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedSectorIdx = i),
                              child: Container(
                                margin: EdgeInsets.only(right: i < _branchChoices.length - 1 ? 12 : 0),
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
                            ),
                          );
                        }),
                      ),

                      // 2. Pilot Mutation Selection (up to 3 per run)
                      if (_mutationChoices.isNotEmpty && widget.game.activeMutations.length < 3) ...[
                        const SizedBox(height: 18),
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
                        const SizedBox(height: 10),
                        ...List.generate(_mutationChoices.length, (i) {
                          final mut = _mutationChoices[i];
                          final isSelected = _selectedMutationIdx == i;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedMutationIdx = i),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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

                      const SizedBox(height: 18),
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
