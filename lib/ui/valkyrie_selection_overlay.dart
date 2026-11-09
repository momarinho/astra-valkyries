import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:asteroids/game/asteroids_game.dart';
import 'package:asteroids/game/valkyrie.dart';
import 'package:asteroids/game/meta_progression.dart';
import 'package:asteroids/game/affinity_system.dart';
import 'package:asteroids/game/sector.dart';
import 'package:asteroids/game/roguelite_systems.dart';
import 'package:asteroids/game/weapon_codex.dart';

class ValkyrieSelectionOverlay extends StatefulWidget {
  final AsteroidsGame game;

  const ValkyrieSelectionOverlay({super.key, required this.game});

  @override
  State<ValkyrieSelectionOverlay> createState() => _ValkyrieSelectionOverlayState();
}

class _ValkyrieSelectionOverlayState extends State<ValkyrieSelectionOverlay> {
  int _selectedTab = 0; // 0 = Sortie / Hangar, 1 = Oficina / Workshop, 2 = Galeria / Memórias
  int _workshopSubTab = 0; // 0 = Upgrades, 1 = Forja de Diagramas (Sprint 16), 2 = Conquistas (Sprint 17)
  int _selectedIndex = 0;
  int _selectedSectorIndex = 0;
  bool _unlockedSecretValkyrie = false;
  final List<LogicalKeyboardKey> _keySequence = [];
  late final FocusNode _focusNode;

  List<Valkyrie> get _valkyries => _unlockedSecretValkyrie ? Valkyrie.allValkyries : Valkyrie.roster;

  static const List<LogicalKeyboardKey> _konamiSequence = [
    LogicalKeyboardKey.arrowUp,
    LogicalKeyboardKey.arrowUp,
    LogicalKeyboardKey.arrowDown,
    LogicalKeyboardKey.arrowDown,
    LogicalKeyboardKey.arrowLeft,
    LogicalKeyboardKey.arrowRight,
    LogicalKeyboardKey.arrowLeft,
    LogicalKeyboardKey.arrowRight,
    LogicalKeyboardKey.keyB,
    LogicalKeyboardKey.keyA,
  ];
  String? _currentDialogueText;
  String _selectedGalleryFilter = 'all'; // 'all', 'kaede', 'lyra', 'selene', 'vesper'
  int _gallerySubTab = 0; // 0 = Memórias das Pilotas, 1 = Códice do Arsenal
  String _selectedWeaponCodexCategory = 'all'; // 'all', 'blade', 'plasma', 'kinetic', 'gravity'
  WeaponCodexEntry? _openedWeaponCodex;
  SecretMemory? _openedMemory;
  bool _cleanMode = false;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.game.initialHangarTab.clamp(0, 2);
    _focusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    // Easter Egg: Konami Code sequence detection
    _keySequence.add(event.logicalKey);
    if (_keySequence.length > _konamiSequence.length) {
      _keySequence.removeAt(0);
    }
    if (_keySequence.length == _konamiSequence.length) {
      bool match = true;
      for (var i = 0; i < _konamiSequence.length; i++) {
        if (_keySequence[i] != _konamiSequence[i]) {
          match = false;
          break;
        }
      }
      if (match) {
        setState(() {
          _unlockedSecretValkyrie = true;
          _selectedIndex = _valkyries.indexWhere((v) => v.id == 'astraea');
          if (_selectedIndex < 0) _selectedIndex = 0;
          _currentDialogueText = '★ PROTOCOLO ANCESTRAL DESBLOQUEADO: ASTRAEA ATIVADA! (+9.999 SUCATA) ★';
        });
        widget.game.addScrap(9999);
        widget.game.playSfx('powerup.wav');
        _keySequence.clear();
        return;
      }
    }

    if (_openedMemory != null) {
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        setState(() => _openedMemory = null);
        return;
      }
    }

    // Q / E steps tabs sequentially: (0 -> 1 -> 2 -> 0)
    if (event.logicalKey == LogicalKeyboardKey.keyQ) {
      setState(() {
        _selectedTab = (_selectedTab - 1 + 3) % 3;
        _currentDialogueText = null;
      });
      widget.game.playSfx('menu_select.wav');
      return;
    }
    if (event.logicalKey == LogicalKeyboardKey.keyE) {
      setState(() {
        _selectedTab = (_selectedTab + 1) % 3;
        _currentDialogueText = null;
      });
      widget.game.playSfx('menu_select.wav');
      return;
    }

    // Tab toggles between Sortie and Workshop tabs
    if (event.logicalKey == LogicalKeyboardKey.tab) {
      setState(() {
        _selectedTab = (_selectedTab == 0 ? 1 : 0);
        _currentDialogueText = null;
      });
      widget.game.playSfx('menu_select.wav');
      return;
    }

    if (_selectedTab == 0) {
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
          event.logicalKey == LogicalKeyboardKey.keyA) {
        setState(() {
          _selectedIndex = (_selectedIndex - 1 + _valkyries.length) % _valkyries.length;
          _currentDialogueText = null;
        });
        widget.game.playSfx('menu_select.wav');
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight ||
          event.logicalKey == LogicalKeyboardKey.keyD) {
        setState(() {
          _selectedIndex = (_selectedIndex + 1) % _valkyries.length;
          _currentDialogueText = null;
        });
        widget.game.playSfx('menu_select.wav');
      } else if (event.logicalKey == LogicalKeyboardKey.bracketLeft) {
        setState(() {
          _selectedSectorIndex = (_selectedSectorIndex - 1 + Sector.allSectorsWithBranches.length) % Sector.allSectorsWithBranches.length;
        });
        widget.game.playSfx('menu_select.wav');
      } else if (event.logicalKey == LogicalKeyboardKey.bracketRight) {
        setState(() {
          _selectedSectorIndex = (_selectedSectorIndex + 1) % Sector.allSectorsWithBranches.length;
        });
        widget.game.playSfx('menu_select.wav');
      } else if (event.logicalKey == LogicalKeyboardKey.enter ||
          event.logicalKey == LogicalKeyboardKey.space) {
        _deployValkyrie(_valkyries[_selectedIndex]);
      }
    }

    if (event.logicalKey == LogicalKeyboardKey.escape) {
      widget.game.changeState(GameState.menu);
    }
  }

  void _deployValkyrie(Valkyrie valkyrie) {
    final sector = Sector.allSectorsWithBranches[_selectedSectorIndex.clamp(0, Sector.allSectorsWithBranches.length - 1)];
    if (!widget.game.isSectorUnlocked(sector.id)) {
      widget.game.playSfx('game_over.wav');
      return;
    }
    widget.game.selectedValkyrie = valkyrie;
    widget.game.currentSector = sector;
    widget.game.playSfx('powerup.wav');
    widget.game.startGame();
  }

  @override
  Widget build(BuildContext context) {
    final current = _valkyries[_selectedIndex];

    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // Ambient Backdrop Blur & Subtle Vignette
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 7.0, sigmaY: 7.0),
                child: Container(
                  color: Colors.black.withOpacity(0.78),
                ),
              ),
            ),

            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top Bar Header
                    _buildTopHeader(current),

                    const SizedBox(height: 10),

                    // Tab Selector Bar
                    _buildTabBar(current),

                    const SizedBox(height: 12),

                    // Main Content Area (Sortie vs Oficina vs Galeria)
                    Expanded(
                      child: _selectedTab == 0
                          ? _buildSortieView(current)
                          : (_selectedTab == 1
                              ? _buildWorkshopView()
                              : _buildGalleryView(current)),
                    ),
                  ],
                ),
              ),
            ),

            // Full-Screen Memory Lightbox Modal
            if (_openedMemory != null)
              Positioned.fill(
                child: _buildMemoryLightbox(_openedMemory!),
              ),

            // Full-Screen Weapon Dossier Lightbox Modal
            if (_openedWeaponCodex != null)
              Positioned.fill(
                child: _buildWeaponDossierLightbox(_openedWeaponCodex!),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopHeader(Valkyrie current) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Title & Logo
        Expanded(
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (_selectedTab == 0
                          ? current.primaryColor
                          : (_selectedTab == 1 ? const Color(0xFFFFB300) : const Color(0xFFFF4081)))
                      .withOpacity(0.18),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _selectedTab == 0
                        ? current.primaryColor
                        : (_selectedTab == 1 ? const Color(0xFFFFB300) : const Color(0xFFFF4081)),
                  ),
                ),
                child: Icon(
                  _selectedTab == 0
                      ? Icons.rocket_launch
                      : (_selectedTab == 1
                          ? Icons.precision_manufacturing_rounded
                          : Icons.auto_awesome_motion_rounded),
                  color: _selectedTab == 0
                      ? current.primaryColor
                      : (_selectedTab == 1 ? const Color(0xFFFFB300) : const Color(0xFFFF4081)),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'ASTRA VALKYRIES // HANGAR BAY',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Orbitron',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.5,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      _selectedTab == 0
                          ? 'SELECT PILOT & VESSEL FOR VOID DEPLOYMENT'
                          : (_selectedTab == 1
                              ? 'PERMANENT FLEET UPGRADES & WORKSHOP'
                              : 'SECRET MEMORIES, PINUPS & VALKYRIE BOND ARCHIVES'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Rajdhani',
                        fontSize: 12,
                        letterSpacing: 1.5,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Scrap Balance & Quick Actions
        Row(
          children: [
            // Cosmic Scrap Bank Indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFFFB300).withOpacity(0.16),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFFFB300).withOpacity(0.8),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFB300).withOpacity(0.2),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.build_circle_rounded, color: Color(0xFFFFB300), size: 16),
                  const SizedBox(width: 6),
                  Text(
                    '${widget.game.totalCredits} c',
                    style: const TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      color: Color(0xFFFFB300),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Settings
            IconButton(
              onPressed: () {
                widget.game.playSfx('menu_select.wav');
                widget.game.changeState(GameState.settings);
              },
              icon: const Icon(Icons.settings, color: Colors.cyanAccent),
              tooltip: 'Controles & Configurações',
            ),
            const SizedBox(width: 6),

            // Return to Main Menu
            OutlinedButton.icon(
              onPressed: () {
                widget.game.playSfx('menu_select.wav');
                widget.game.changeState(GameState.menu);
              },
              icon: const Icon(Icons.arrow_back_rounded, size: 15, color: Colors.white),
              label: const Text(
                'MENU PRINCIPAL',
                style: TextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: Colors.white,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white30),
                backgroundColor: Colors.white.withValues(alpha: 0.06),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTabBar(Valkyrie current) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 850;
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: const Color(0xFF101622).withOpacity(0.95),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTabPill(
                    index: 0,
                    label: isCompact ? 'SORTIE' : 'SORTIE // DECOLAR',
                    icon: Icons.rocket_launch_rounded,
                    activeColor: current.primaryColor,
                  ),
                  const SizedBox(width: 4),
                  _buildTabPill(
                    index: 1,
                    label: isCompact ? 'OFICINA' : 'OFICINA // UPGRADES',
                    icon: Icons.precision_manufacturing_rounded,
                    activeColor: const Color(0xFFFFB300),
                  ),
                  const SizedBox(width: 4),
                  _buildTabPill(
                    index: 2,
                    label: isCompact ? 'GALERIA' : 'GALERIA // MEMÓRIAS',
                    icon: Icons.auto_awesome_motion_rounded,
                    activeColor: const Color(0xFFFF4081),
                  ),
                ],
              ),
            ),
            if (!isCompact) ...[
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _selectedTab == 0
                      ? 'Pressione TAB ou Q/E para alternar abas'
                      : (_selectedTab == 1
                          ? 'Melhorias permanentes de Sucata Cósmica'
                          : 'Memórias Secretas e Ilustrações de Elo'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    fontFamily: 'Rajdhani',
                    fontSize: 12,
                    letterSpacing: 1.5,
                    color: Colors.white.withOpacity(0.4),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildTabPill({
    required int index,
    required String label,
    required IconData icon,
    required Color activeColor,
  }) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        if (_selectedTab != index) {
          setState(() => _selectedTab = index);
          widget.game.playSfx('menu_select.wav');
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withOpacity(0.22) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? activeColor : Colors.transparent,
            width: 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withOpacity(0.35),
                    blurRadius: 10,
                  )
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: isSelected ? activeColor : Colors.white60),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.4,
                color: isSelected ? Colors.white : Colors.white60,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------
  // VIEW 0: SORTIE // PILOT SELECTION & DEPLOYMENT
  // ---------------------------------------------------------
  Widget _buildSortieView(Valkyrie current) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Pilot Selection Tabs (Horizontal Roster)
        Row(
          children: List.generate(_valkyries.length, (i) {
            final v = _valkyries[i];
            final isSelected = i == _selectedIndex;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6.0),
                child: GestureDetector(
                  onTap: () {
                    setState(() => _selectedIndex = i);
                    widget.game.playSfx('menu_select.wav');
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? v.primaryColor.withOpacity(0.2)
                          : const Color(0xFF131A26).withOpacity(0.8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? v.primaryColor : Colors.white12,
                        width: isSelected ? 2.0 : 1.0,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: v.primaryColor.withOpacity(0.35),
                                blurRadius: 16,
                              )
                            ]
                          : [],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? v.primaryColor : Colors.white24,
                              width: 1.5,
                            ),
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              v.hudNeutralAsset,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: isSelected ? v.primaryColor : Colors.grey[800],
                                child: Icon(
                                  Icons.person,
                                  size: 16,
                                  color: isSelected ? Colors.black : Colors.white54,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                v.name.toUpperCase(),
                                style: TextStyle(
                                  fontFamily: 'Orbitron',
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                  color: isSelected ? Colors.white : Colors.white70,
                                ),
                              ),
                              Text(
                                v.callsign.toUpperCase(),
                                style: TextStyle(
                                  fontFamily: 'Rajdhani',
                                  fontSize: 11,
                                  color: isSelected ? v.accentColor : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),

        const SizedBox(height: 14),

        // Main Dossier Area (Pilot Hologram & Combat Specs)
        Expanded(
          child: GestureDetector(
            onHorizontalDragEnd: (details) {
              if (details.primaryVelocity != null) {
                if (details.primaryVelocity! < -150) {
                  // Swipe Left -> Next
                  setState(() {
                    _selectedIndex = (_selectedIndex + 1) % _valkyries.length;
                  });
                  widget.game.playSfx('menu_select.wav');
                } else if (details.primaryVelocity! > 150) {
                  // Swipe Right -> Previous
                  setState(() {
                    _selectedIndex = (_selectedIndex - 1 + _valkyries.length) % _valkyries.length;
                  });
                  widget.game.playSfx('menu_select.wav');
                }
              }
            },
            child: Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: const Color(0xFF0C1017).withOpacity(0.92),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: current.primaryColor.withOpacity(0.4), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: current.primaryColor.withOpacity(0.12),
                    blurRadius: 28,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Left Column: Pilot Visual Preview Slot
                  Expanded(
                    flex: 4,
                    child: _buildPilotVisualCard(current),
                  ),

                  const SizedBox(width: 24),

                  // Right Column: Tactical Specs, Weaponry & Lore
                  Expanded(
                    flex: 6,
                    child: _buildTacticalSpecs(current),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 14),

        // Launch Action Bar
        Row(
          children: [
            Expanded(
              child: _buildSectorSelector(current),
            ),
            const SizedBox(width: 8),
            // Void Cells Difficulty Selector (Sprint 16: 0 to 5 Cells)
            GestureDetector(
              key: const Key('void_cells_selector_button'),
              onTap: () {
                setState(() {
                  final maxVc = widget.game.maxUnlockedVoidCells.clamp(1, 5);
                  widget.game.voidCellsLevel = (widget.game.voidCellsLevel + 1) % (maxVc + 1);
                });
                widget.game.savePersistentCredits();
                widget.game.playSfx('menu_select.wav');
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                decoration: BoxDecoration(
                  color: widget.game.voidCellsLevel > 0
                      ? const Color(0xFFE040FB).withValues(alpha: 0.22)
                      : const Color(0xFF0C1017).withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: widget.game.voidCellsLevel > 0
                        ? const Color(0xFFE040FB)
                        : Colors.white24,
                    width: widget.game.voidCellsLevel > 0 ? 1.6 : 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.science_rounded,
                      size: 15,
                      color: widget.game.voidCellsLevel > 0 ? const Color(0xFFE040FB) : Colors.white54,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'VOID CELLS: ${widget.game.voidCellsLevel}',
                      style: TextStyle(
                        fontFamily: 'Orbitron',
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: widget.game.voidCellsLevel > 0 ? const Color(0xFFE040FB) : Colors.white54,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Hyper Mode Toggle Chip (+25% Speed, +50% XP/Scrap)
            GestureDetector(
              onTap: () {
                setState(() {
                  widget.game.isHyperMode = !widget.game.isHyperMode;
                });
                widget.game.playSfx('menu_select.wav');
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                decoration: BoxDecoration(
                  color: widget.game.isHyperMode
                      ? const Color(0xFFFFD700).withValues(alpha: 0.22)
                      : const Color(0xFF0C1017).withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: widget.game.isHyperMode
                        ? const Color(0xFFFFD700)
                        : Colors.white24,
                    width: widget.game.isHyperMode ? 1.6 : 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.bolt_rounded,
                      size: 15,
                      color: widget.game.isHyperMode ? const Color(0xFFFFD700) : Colors.white54,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'HYPER',
                      style: TextStyle(
                        fontFamily: 'Orbitron',
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: widget.game.isHyperMode ? const Color(0xFFFFD700) : Colors.white54,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Boss Rush Toggle Chip (Sequential 4-Titan Gauntlet)
            GestureDetector(
              onTap: () {
                setState(() {
                  widget.game.isBossRushMode = !widget.game.isBossRushMode;
                });
                widget.game.playSfx('menu_select.wav');
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                decoration: BoxDecoration(
                  color: widget.game.isBossRushMode
                      ? const Color(0xFFFF1744).withValues(alpha: 0.22)
                      : const Color(0xFF0C1017).withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: widget.game.isBossRushMode
                        ? const Color(0xFFFF1744)
                        : Colors.white24,
                    width: widget.game.isBossRushMode ? 1.6 : 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.whatshot_rounded,
                      size: 15,
                      color: widget.game.isBossRushMode ? const Color(0xFFFF1744) : Colors.white54,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'BOSS RUSH',
                      style: TextStyle(
                        fontFamily: 'Orbitron',
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: widget.game.isBossRushMode ? const Color(0xFFFF1744) : Colors.white54,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Builder(
              builder: (context) {
                final selectedSector = Sector.allSectorsWithBranches[
                    _selectedSectorIndex.clamp(0, Sector.allSectorsWithBranches.length - 1)];
                final isSectorUnlocked = widget.game.isSectorUnlocked(selectedSector.id);
                return ElevatedButton(
                  onPressed: isSectorUnlocked ? () => _deployValkyrie(current) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSectorUnlocked ? current.primaryColor : const Color(0xFF2A2E3D),
                    foregroundColor: isSectorUnlocked ? Colors.black : Colors.white38,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: isSectorUnlocked ? 12 : 0,
                    shadowColor: current.primaryColor.withOpacity(0.6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSectorUnlocked ? Icons.rocket_launch_rounded : Icons.lock_outline_rounded,
                        size: 18,
                        color: isSectorUnlocked ? Colors.black : Colors.white38,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isSectorUnlocked ? 'DEPLOY // DECOLAR' : 'BLOQUEADO',
                        style: TextStyle(
                          fontFamily: 'Orbitron',
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          color: isSectorUnlocked ? Colors.black : Colors.white38,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectorSelector(Valkyrie current) {
    final sector = Sector.allSectorsWithBranches[
        _selectedSectorIndex.clamp(0, Sector.allSectorsWithBranches.length - 1)];
    final isUnlocked = widget.game.isSectorUnlocked(sector.id);
    final isRelicClaimed = widget.game.unlockedRelics.contains(sector.relicId);
    final isSecretRescued = widget.game.rescuedSectorSecrets.contains(sector.id);
    final isCompletedWithCurrent = widget.game.isSectorCompletedWith(sector.id, current.id);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0C1017).withOpacity(0.94),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUnlocked
              ? sector.primaryColor.withOpacity(0.6)
              : Colors.redAccent.withOpacity(0.5),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          IconButton(
            iconSize: 16,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: 'Setor Anterior [Tecla [ ]',
            icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white70),
            onPressed: () {
              setState(() {
                _selectedSectorIndex = (_selectedSectorIndex - 1 + Sector.allSectorsWithBranches.length) %
                    Sector.allSectorsWithBranches.length;
              });
              widget.game.playSfx('menu_select.wav');
            },
          ),
          const SizedBox(width: 8),

          // Miniatura do Bioma (Sprint 25)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 48,
              height: 48,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    sector.biomeImageAsset,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: sector.primaryColor.withOpacity(0.2),
                      child: Icon(sector.icon, color: sector.primaryColor, size: 24),
                    ),
                  ),
                  if (!isUnlocked)
                    Container(
                      color: Colors.black.withOpacity(0.7),
                      child: const Center(
                        child: Icon(Icons.lock_rounded, color: Colors.amberAccent, size: 22),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Informações do Setor e Checklist
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        sector.name.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Orbitron',
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isUnlocked ? sector.primaryColor : Colors.white60,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: sector.primaryColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: sector.primaryColor.withOpacity(0.6)),
                      ),
                      child: Text(
                        sector.difficultyLabel,
                        style: TextStyle(
                          fontFamily: 'Rajdhani',
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: sector.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                if (!isUnlocked)
                  Text(
                    '🔒 DESBLOQUEIO: ${sector.unlockConditionText}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Rajdhani',
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: Colors.amberAccent,
                    ),
                  )
                else
                  // Checklist de Descobertas (Sprint 28)
                  Row(
                    children: [
                      _buildChecklistBadge(
                        'Relíquia',
                        isRelicClaimed,
                        const Color(0xFFFFD700),
                        sector.relicName,
                      ),
                      const SizedBox(width: 6),
                      _buildChecklistBadge(
                        'Segredo',
                        isSecretRescued,
                        const Color(0xFF00E5FF),
                        sector.secretTitle,
                      ),
                      const SizedBox(width: 6),
                      _buildChecklistBadge(
                        current.name,
                        isCompletedWithCurrent,
                        current.primaryColor,
                        'Completado com ${current.name}',
                      ),
                    ],
                  ),
              ],
            ),
          ),

          const SizedBox(width: 8),
          IconButton(
            iconSize: 16,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: 'Próximo Setor [Tecla ] ]',
            icon: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70),
            onPressed: () {
              setState(() {
                _selectedSectorIndex =
                    (_selectedSectorIndex + 1) % Sector.allSectorsWithBranches.length;
              });
              widget.game.playSfx('menu_select.wav');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistBadge(String label, bool completed, Color color, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            completed ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            size: 11,
            color: completed ? color : Colors.white30,
          ),
          const SizedBox(width: 2),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Rajdhani',
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: completed ? color : Colors.white54,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------
  // VIEW 1: OFICINA // ENGINEERING BAY & META-UPGRADES
  // ---------------------------------------------------------
  Widget _buildWorkshopView() {
    final meta = widget.game.metaProgression;
    final upgrades = MetaProgression.allUpgrades;

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: const Color(0xFF0C1017).withOpacity(0.92),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFB300).withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFB300).withOpacity(0.10),
            blurRadius: 28,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Workshop Header & Refund Action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'OFICINA DE ENGENHARIA // META-UPGRADES',
                      style: TextStyle(
                        fontFamily: 'Orbitron',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.5,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'MELHORIAS PERMANENTES PARA TODA A ESQUADRA • SUCATA CÓSMICA REEMBOLSÁVEL',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Rajdhani',
                        fontSize: 12,
                        letterSpacing: 1.5,
                        color: const Color(0xFFFFB300).withOpacity(0.85),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // Full Refund Button
              OutlinedButton.icon(
                onPressed: () {
                  widget.game.refundMetaUpgrades();
                  setState(() {});
                },
                icon: const Icon(Icons.restart_alt_rounded, size: 16, color: Color(0xFFFFB300)),
                label: const Text(
                  'REEMBOLSAR TUDO (100%)',
                  style: TextStyle(
                    fontFamily: 'Rajdhani',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: Color(0xFFFFB300),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFFFB300), width: 1.2),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  backgroundColor: const Color(0xFFFFB300).withOpacity(0.08),
                ),
              ),
            ],
          ),

          const Divider(color: Colors.white12, height: 20),

          // Sub-navigation inside Workshop: Fleet Upgrades | Blueprint Forge | Milestones Codex | Faction Codex | Flight Recorders | Permanent Relics
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _buildWorkshopSubTabButton(0, 'MELHORIAS DE FROTA', Icons.tune_rounded, const Color(0xFFFFB300)),
              _buildWorkshopSubTabButton(1, 'FORJA DE DIAGRAMAS', Icons.architecture_rounded, const Color(0xFF00E5FF)),
              _buildWorkshopSubTabButton(2, 'CONQUISTAS', Icons.emoji_events_rounded, const Color(0xFFFFD700)),
              _buildWorkshopSubTabButton(3, 'CÓDICE DE FACÇÕES', Icons.auto_stories_rounded, const Color(0xFFFF4081)),
              _buildWorkshopSubTabButton(4, 'CAIXAS PRETAS & LORE', Icons.settings_input_antenna_rounded, const Color(0xFFE040FB)),
              _buildWorkshopSubTabButton(5, 'RELÍQUIAS PERMANENTES', Icons.diamond_outlined, const Color(0xFFFFD700)),
            ],
          ),
          const SizedBox(height: 12),

          // Responsive Content (Upgrades / Blueprints / Milestones / Factions / Flight Recorders / Relics)
          Expanded(
            child: _workshopSubTab == 0
                ? LayoutBuilder(
                    builder: (context, constraints) {
                      final useTwoColumns = constraints.maxWidth > 800;

                      if (useTwoColumns) {
                        return GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 2.3,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                          ),
                          itemCount: upgrades.length,
                          itemBuilder: (context, index) {
                            return _buildMetaUpgradeCard(upgrades[index], meta);
                          },
                        );
                      } else {
                        return ListView.separated(
                          itemCount: upgrades.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            return _buildMetaUpgradeCard(upgrades[index], meta);
                          },
                        );
                      }
                    },
                  )
                : (_workshopSubTab == 1
                    ? _buildBlueprintForgeList()
                    : (_workshopSubTab == 2
                        ? _buildMilestonesList()
                        : (_workshopSubTab == 3
                            ? _buildFactionCodexList()
                            : (_workshopSubTab == 4
                                ? _buildFlightRecordersList()
                                : _buildPermanentRelicsList())))),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkshopSubTabButton(int subIndex, String label, IconData icon, Color color) {
    final isSelected = _workshopSubTab == subIndex;
    return GestureDetector(
      onTap: () {
        setState(() => _workshopSubTab = subIndex);
        widget.game.playSfx('menu_select.wav');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? color : Colors.white12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isSelected ? color : Colors.white54),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.white60,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlueprintForgeList() {
    final blueprints = BlueprintDef.allBlueprints;
    return ListView.separated(
      itemCount: blueprints.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final bp = blueprints[index];
        final isFound = widget.game.foundBlueprints.contains(bp.weaponId);
        final isForged = widget.game.forgedBlueprints.contains(bp.weaponId);
        final canForge = isFound && !isForged && widget.game.totalCredits >= bp.forgeCost;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF111724),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isForged ? const Color(0xFF00E676) : (isFound ? bp.color : Colors.white12),
            ),
          ),
          child: Row(
            children: [
              Icon(bp.icon, color: isFound ? bp.color : Colors.white24, size: 26),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isFound ? bp.name.toUpperCase() : 'DIAGRAMA CRIPTOGRAFADO // ???',
                      style: TextStyle(
                        fontFamily: 'Orbitron',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isFound ? Colors.white : Colors.white38,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isFound ? bp.description : 'Origem: ${bp.dropSource}',
                      style: const TextStyle(
                        fontFamily: 'Rajdhani',
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                    if (isFound) ...[
                      const SizedBox(height: 3),
                      Text(
                        '📜 ${bp.loreLog}',
                        style: const TextStyle(
                          fontFamily: 'Rajdhani',
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (isForged)
                const Text(
                  'FORJADO ✓',
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00E676),
                  ),
                )
              else
                ElevatedButton(
                  onPressed: canForge
                      ? () {
                          widget.game.forgeBlueprint(bp.weaponId);
                          setState(() {});
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00E5FF),
                    foregroundColor: Colors.black,
                  ),
                  child: Text(
                    isFound ? 'FORJAR (${bp.forgeCost} c)' : 'BLOQUEADO',
                    style: const TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMilestonesList() {
    final milestones = MilestoneAchievement.allMilestones;
    return ListView.separated(
      itemCount: milestones.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final m = milestones[index];
        final isUnlocked = widget.game.unlockedMilestones.contains(m.id);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF111724),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isUnlocked ? const Color(0xFFFFD700) : Colors.white12,
            ),
          ),
          child: Row(
            children: [
              Icon(m.icon, color: isUnlocked ? m.color : Colors.white24, size: 24),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m.title.toUpperCase(),
                      style: TextStyle(
                        fontFamily: 'Orbitron',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isUnlocked ? const Color(0xFFFFD700) : Colors.white70,
                      ),
                    ),
                    Text(
                      m.description,
                      style: const TextStyle(
                        fontFamily: 'Rajdhani',
                        fontSize: 12,
                        color: Colors.white60,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                isUnlocked ? 'CONCLUÍDA (+${m.scrapReward}c)' : 'RECOMPENSA: +${m.scrapReward}c',
                style: TextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  color: isUnlocked ? const Color(0xFF00E676) : const Color(0xFFFFB300),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFactionCodexList() {
    final factions = FactionCodexEntry.allFactions;
    return ListView.separated(
      itemCount: factions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final f = factions[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF111724),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: f.color.withValues(alpha: 0.7), width: 1.4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(f.icon, color: f.color, size: 26),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          f.title,
                          style: const TextStyle(
                            fontFamily: 'Orbitron',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          f.subtitle,
                          style: TextStyle(
                            fontFamily: 'Rajdhani',
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: f.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    f.threatClassification,
                    style: TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                      color: f.color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                f.loreHistory,
                style: const TextStyle(
                  fontFamily: 'Rajdhani',
                  fontSize: 12.5,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '🎯 DIRETRIZ TÁTICA: ${f.tacticalWeakness}',
                style: const TextStyle(
                  fontFamily: 'Rajdhani',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00E676),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFlightRecordersList() {
    final logs = FlightRecorderLog.allFlightRecorders;
    return ListView.separated(
      itemCount: logs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final log = logs[index];
        final isUnlocked = widget.game.unlockedFlightRecorders.contains(log.id);
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF111724),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isUnlocked ? const Color(0xFFE040FB) : Colors.white12,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.graphic_eq_rounded,
                    color: isUnlocked ? const Color(0xFFE040FB) : Colors.white24,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isUnlocked
                          ? '📼 ${log.vesselName.toUpperCase()} // ${log.pilotCallsign}'
                          : '📼 CAIXA PRETA CRIPTOGRAFADA // DESTRUA CARGUEIROS NO SETOR',
                      style: TextStyle(
                        fontFamily: 'Orbitron',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isUnlocked ? Colors.white : Colors.white38,
                      ),
                    ),
                  ),
                  Text(
                    log.sectorOrigin,
                    style: const TextStyle(
                      fontFamily: 'Rajdhani',
                      fontSize: 11.5,
                      color: Color(0xFF00E5FF),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                isUnlocked
                    ? log.transmissionText
                    : 'Sinal de caixa preta oculto em destroços de cargueiros (Cargo Wrecks).',
                style: TextStyle(
                  fontFamily: 'Rajdhani',
                  fontSize: 12.5,
                  fontStyle: isUnlocked ? FontStyle.italic : FontStyle.normal,
                  color: isUnlocked ? Colors.white70 : Colors.white38,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPermanentRelicsList() {
    final relics = PermanentRelic.allRelics;
    return ListView.separated(
      itemCount: relics.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final relic = relics[index];
        final isUnlocked = widget.game.unlockedRelics.contains(relic.id);
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isUnlocked
                ? relic.color.withOpacity(0.12)
                : const Color(0xFF10141E).withOpacity(0.7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isUnlocked ? relic.color : Colors.white24,
              width: isUnlocked ? 1.6 : 1.0,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: relic.color.withOpacity(isUnlocked ? 0.25 : 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: relic.color.withOpacity(isUnlocked ? 0.8 : 0.3)),
                ),
                child: Icon(relic.icon, color: isUnlocked ? relic.color : Colors.white38, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            relic.title.toUpperCase(),
                            style: TextStyle(
                              fontFamily: 'Orbitron',
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: isUnlocked ? Colors.white : Colors.white60,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: (isUnlocked ? relic.color : Colors.white24).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: isUnlocked ? relic.color : Colors.white38),
                          ),
                          child: Text(
                            isUnlocked ? '✓ ATIVA PERMANENTEMENTE' : '🔒 NÃO DESCOBERTA',
                            style: TextStyle(
                              fontFamily: 'Orbitron',
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isUnlocked ? relic.color : Colors.white54,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Origem: ${relic.sectorLabel}',
                      style: TextStyle(
                        fontFamily: 'Rajdhani',
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: relic.color,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      relic.effectDescription,
                      style: const TextStyle(
                        fontFamily: 'Rajdhani',
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '📜 "${relic.loreLog}"',
                      style: const TextStyle(
                        fontFamily: 'Rajdhani',
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetaUpgradeCard(MetaUpgradeDef def, MetaProgression meta) {
    final curLevel = meta.getLevel(def.id);
    final isMaxed = curLevel >= def.maxLevel;
    final cost = def.getCostForLevel(curLevel);
    final canAfford = !isMaxed && widget.game.totalCredits >= cost;

    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: const Color(0xFF111724).withOpacity(0.95),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isMaxed
              ? const Color(0xFFFFD700).withOpacity(0.6)
              : def.color.withOpacity(0.4),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: def.color.withOpacity(0.08),
            blurRadius: 14,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Header: Icon + Title + Level Badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: def.color.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: def.color, width: 1.2),
                ),
                child: Icon(def.icon, color: def.color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      def.title,
                      style: const TextStyle(
                        fontFamily: 'Orbitron',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      def.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Rajdhani',
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.65),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Level Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (isMaxed ? const Color(0xFFFFD700) : def.color).withOpacity(0.18),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isMaxed ? const Color(0xFFFFD700) : def.color,
                    width: 1.0,
                  ),
                ),
                child: Text(
                  isMaxed ? 'MAX' : 'LVL $curLevel/${def.maxLevel}',
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isMaxed ? const Color(0xFFFFD700) : def.color,
                  ),
                ),
              ),
            ],
          ),

          // Level Pips Bar
          Row(
            children: List.generate(def.maxLevel, (i) {
              final filled = i < curLevel;
              return Expanded(
                child: Container(
                  height: 5,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: filled ? def.color : Colors.white12,
                    boxShadow: filled
                        ? [
                            BoxShadow(
                              color: def.color.withOpacity(0.6),
                              blurRadius: 4,
                            )
                          ]
                        : [],
                  ),
                ),
              );
            }),
          ),

          // Current Effect vs Next Level
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF0A0E17).withOpacity(0.8),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    def.effectDescription(curLevel),
                    style: TextStyle(
                      fontFamily: 'Rajdhani',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: curLevel > 0 ? def.color : Colors.white70,
                    ),
                  ),
                ),
                if (!isMaxed) ...[
                  const Icon(Icons.arrow_forward, size: 12, color: Colors.white38),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      def.effectDescription(curLevel + 1),
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        fontFamily: 'Rajdhani',
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Colors.white.withOpacity(0.55),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Action Button (Purchase vs Maxed)
          if (isMaxed)
            Container(
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700).withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.6)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_rounded, color: Color(0xFFFFD700), size: 14),
                  SizedBox(width: 6),
                  Text(
                    'NÍVEL MÁXIMO ATINGIDO',
                    style: TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: Color(0xFFFFD700),
                    ),
                  ),
                ],
              ),
            )
          else
            ElevatedButton(
              onPressed: canAfford
                  ? () {
                      widget.game.purchaseMetaUpgrade(def.id);
                      setState(() {});
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: canAfford ? def.color : Colors.white10,
                foregroundColor: Colors.black,
                disabledBackgroundColor: Colors.white10,
                disabledForegroundColor: Colors.white30,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: canAfford ? 6 : 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.build_circle_rounded,
                    size: 14,
                    color: canAfford ? Colors.black : Colors.white30,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'APRIMORAR • $cost c',
                    style: TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: canAfford ? Colors.black : Colors.white30,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPilotVisualCard(Valkyrie v) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFF131A26),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: v.primaryColor.withOpacity(0.35)),
      ),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Background Cyber Pattern
          Positioned.fill(
            child: Opacity(
              opacity: 0.08,
              child: CustomPaint(
                painter: _GridPatternPainter(v.primaryColor),
              ),
            ),
          ),

          // Pilot Illustration / Artwork (Fullbody)
          Positioned.fill(
            child: Image.asset(
              v.hangarFullBodyAsset,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              errorBuilder: (context, error, stackTrace) {
                // Fallback icon when illustration is not present
                return Center(
                  child: Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: v.primaryColor.withOpacity(0.12),
                      border: Border.all(color: v.primaryColor, width: 2.5),
                    ),
                    child: Icon(
                      Icons.person_pin,
                      size: 70,
                      color: v.primaryColor,
                    ),
                  ),
                );
              },
            ),
          ),

          // Gradient shadow overlay for text legibility at bottom
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.40, 0.75, 1.0],
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.10),
                    Colors.black.withOpacity(0.85),
                    Colors.black.withOpacity(0.96),
                  ],
                ),
              ),
            ),
          ),

          // Top Left Pilot Affinity Badge
          Positioned(
            top: 14,
            left: 14,
            child: _buildPilotAffinityBadge(v),
          ),

          // Pilot Details (Name, Title, Interactive Dialogue Speech Box)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  v.name,
                  style: const TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                    color: Colors.white,
                  ),
                ),
                Text(
                  v.title.toUpperCase(),
                  style: TextStyle(
                    fontFamily: 'Rajdhani',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: v.primaryColor,
                  ),
                ),
                const SizedBox(height: 6),
                _buildDialogueBubble(v),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTacticalSpecs(Valkyrie v) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Bio Paragraph
        Text(
          'PILOT DOSSIER',
          style: TextStyle(
            fontFamily: 'Rajdhani',
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
            color: v.primaryColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          v.bio,
          style: TextStyle(
            fontFamily: 'Rajdhani',
            fontSize: 14,
            height: 1.35,
            color: Colors.white.withOpacity(0.85),
          ),
        ),

        const Divider(color: Colors.white12, height: 24),

        // Vessel & Weapon Spec Cards
        Row(
          children: [
            Expanded(
              child: _buildInfoCard(
                icon: Icons.flight,
                label: 'VESSEL',
                title: v.shipName,
                desc: 'Base Hull: ${v.baseHull.toInt()} HP • Shield: ${v.baseShield.toInt()} SP',
                color: v.primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildInfoCard(
                icon: Icons.shield,
                label: 'SPECIAL ABILITY',
                title: v.specialAbilityName,
                desc: v.specialAbilityDesc,
                color: v.accentColor,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        _buildInfoCard(
          icon: Icons.flash_on,
          label: 'STARTING WEAPON',
          title: v.startingWeaponName,
          desc: v.startingWeaponDesc,
          color: Colors.amberAccent,
        ),

        const Spacer(),

        // Stat Rating Gauges (Speed, Defense, Firepower)
        Row(
          children: [
            Expanded(child: _buildRatingGauge('SPEED', v.speedRating, v.primaryColor)),
            const SizedBox(width: 16),
            Expanded(child: _buildRatingGauge('DEFENSE', v.defenseRating, v.primaryColor)),
            const SizedBox(width: 16),
            Expanded(child: _buildRatingGauge('FIREPOWER', v.firepowerRating, v.primaryColor)),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String title,
    required String desc,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF131A26).withOpacity(0.7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Rajdhani',
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Orbitron',
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            desc,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Rajdhani',
              fontSize: 12,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingGauge(String label, int rating, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Rajdhani',
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
            Text(
              '$rating / 5',
              style: TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Row(
          children: List.generate(5, (index) {
            final active = index < rating;
            return Expanded(
              child: Container(
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  color: active ? color : Colors.white12,
                  boxShadow: active
                      ? [
                          BoxShadow(
                            color: color.withOpacity(0.5),
                            blurRadius: 6,
                          )
                        ]
                      : [],
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildPilotAffinityBadge(Valkyrie v) {
    final affinity = widget.game.affinityManager.getAffinity(v.id);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF101622).withOpacity(0.88),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFF4081).withOpacity(0.6), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF4081).withOpacity(0.2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.favorite, size: 13, color: Color(0xFFFF4081)),
              const SizedBox(width: 5),
              Text(
                'ELO LV. ${affinity.bondLevel}',
                style: const TextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '• ${affinity.bondTitle.toUpperCase()}',
                style: const TextStyle(
                  fontFamily: 'Rajdhani',
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF4081),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Progress Bar
          SizedBox(
            width: 130,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: affinity.progressPercent,
                minHeight: 4,
                backgroundColor: Colors.white12,
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF4081)),
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            affinity.bondLevel >= 5 ? 'ELO MÁXIMO' : '${affinity.currentXp} / ${affinity.xpForNext} XP',
            style: const TextStyle(
              fontFamily: 'Rajdhani',
              fontSize: 9.5,
              color: Colors.white54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogueBubble(Valkyrie v) {
    final text = _currentDialogueText ??
        widget.game.affinityManager.getReactivePostRunDialogue(
          v.id,
          lastBoss: widget.game.lastBossEncountered,
          wasVictory: widget.game.lastRunWasVictory,
        );

    return GestureDetector(
      onTap: () {
        widget.game.playSfx('menu_select.wav');
        setState(() {
          _currentDialogueText = widget.game.affinityManager.getRandomDialogue(v.id);
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF101622).withOpacity(0.85),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: v.primaryColor.withOpacity(0.4), width: 1.0),
        ),
        child: Column(
          children: [
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Rajdhani',
                fontSize: 13,
                fontStyle: FontStyle.italic,
                height: 1.25,
                color: Colors.white.withOpacity(0.95),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.touch_app_rounded, size: 10, color: v.primaryColor.withOpacity(0.7)),
                const SizedBox(width: 3),
                Flexible(
                  child: Text(
                    'Conversar',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Rajdhani',
                      fontSize: 10.0,
                      letterSpacing: 0.8,
                      color: v.primaryColor.withOpacity(0.7),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGalleryView(Valkyrie current) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Mode Selector: Memórias das Pilotas vs Códice do Arsenal
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFF101622).withOpacity(0.9),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white12),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildGalleryModeButton(
                  0,
                  '💖 MEMÓRIAS DAS PILOTOS',
                  Icons.photo_library_rounded,
                  const Color(0xFFFF4081),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildGalleryModeButton(
                  1,
                  '⚔️ CÓDICE DO ARSENAL & LORE',
                  Icons.military_tech_rounded,
                  const Color(0xFF00E5FF),
                ),
              ),
            ],
          ),
        ),

        // Sub-Tab Content: Pilot Memories or Weapon Armory Codex
        Expanded(
          child: _gallerySubTab == 0
              ? _buildPilotMemoriesView()
              : _buildWeaponCodexView(),
        ),
      ],
    );
  }

  Widget _buildGalleryModeButton(int index, String label, IconData icon, Color activeColor) {
    final isSelected = _gallerySubTab == index;
    return GestureDetector(
      onTap: () {
        widget.game.playSfx('menu_select.wav');
        setState(() => _gallerySubTab = index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? activeColor : Colors.transparent,
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: isSelected ? activeColor : Colors.white60),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
                color: isSelected ? Colors.white : Colors.white60,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPilotMemoriesView() {
    final allMemories = AffinityManager.allMemories;
    final filteredMemories = _selectedGalleryFilter == 'all'
        ? allMemories
        : allMemories.where((m) => m.valkyrieId == _selectedGalleryFilter).toList();

    int totalUnlocked = 0;
    for (final m in allMemories) {
      final aff = widget.game.affinityManager.getAffinity(m.valkyrieId);
      if (m.isUnlocked(aff.bondLevel)) totalUnlocked++;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Gallery Filter Bar & Stats
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF131A26).withOpacity(0.9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Filter Buttons
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildGalleryFilterChip('all', 'TODAS'),
                      const SizedBox(width: 8),
                      _buildGalleryFilterChip('kbr_01', 'KBR-01'),
                      const SizedBox(width: 8),
                      _buildGalleryFilterChip('lyra', 'LYRA'),
                      const SizedBox(width: 8),
                      _buildGalleryFilterChip('selene', 'SELENE'),
                      const SizedBox(width: 8),
                      _buildGalleryFilterChip('vesper', 'VESPER'),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Unlocked Counter Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF4081).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFF4081).withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.favorite, size: 14, color: Color(0xFFFF4081)),
                    const SizedBox(width: 6),
                    Text(
                      'DESBLOQUEADAS: $totalUnlocked / ${allMemories.length}',
                      style: const TextStyle(
                        fontFamily: 'Orbitron',
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Memories Grid
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 900 ? 3 : (constraints.maxWidth > 550 ? 2 : 1);
              return GridView.builder(
                padding: const EdgeInsets.only(bottom: 16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1.35,
                ),
                itemCount: filteredMemories.length,
                itemBuilder: (context, index) {
                  return _buildMemoryCard(filteredMemories[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGalleryFilterChip(String filterId, String label) {
    final isSelected = _selectedGalleryFilter == filterId;
    return GestureDetector(
      onTap: () {
        widget.game.playSfx('menu_select.wav');
        setState(() => _selectedGalleryFilter = filterId);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF4081).withOpacity(0.25) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? const Color(0xFFFF4081) : Colors.white12,
            width: 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Orbitron',
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: isSelected ? Colors.white : Colors.white60,
          ),
        ),
      ),
    );
  }

  Widget _buildMemoryCard(SecretMemory memory) {
    final pilot = Valkyrie.findById(memory.valkyrieId);
    final affinity = widget.game.affinityManager.getAffinity(memory.valkyrieId);
    final isUnlocked = memory.isUnlocked(affinity.bondLevel);

    return GestureDetector(
      onTap: () {
        if (isUnlocked) {
          widget.game.playSfx('menu_select.wav');
          setState(() {
            _openedMemory = memory;
            _cleanMode = false;
          });
        } else {
          widget.game.playSfx('low_health.wav');
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: const Color(0xFF131A26),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isUnlocked ? memory.themeColor.withOpacity(0.7) : Colors.white12,
            width: isUnlocked ? 1.8 : 1.0,
          ),
          boxShadow: isUnlocked
              ? [
                  BoxShadow(
                    color: memory.themeColor.withOpacity(0.25),
                    blurRadius: 10,
                  )
                ]
              : [],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Artwork Preview / Fallback
            Image.asset(
              memory.imageAsset,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              errorBuilder: (_, __, ___) => Container(
                color: const Color(0xFF1A2232),
                child: Center(
                  child: Icon(
                    isUnlocked ? Icons.image_rounded : Icons.lock_outline_rounded,
                    size: 44,
                    color: isUnlocked ? memory.themeColor : Colors.white24,
                  ),
                ),
              ),
            ),

            // Locked Dark Filter Overlay
            if (!isUnlocked)
              Container(
                color: Colors.black.withOpacity(0.85),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.08),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: const Icon(Icons.lock_rounded, size: 26, color: Colors.white54),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'MEMÓRIA CONFIDENCIAL',
                        style: TextStyle(
                          fontFamily: 'Orbitron',
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          color: Colors.white60,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Requer Elo Lv. ${memory.requiredBondLevel} com ${pilot.name}',
                        style: TextStyle(
                          fontFamily: 'Rajdhani',
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: memory.themeColor.withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Elo Atual: Nível ${affinity.bondLevel} / ${memory.requiredBondLevel}',
                        style: const TextStyle(
                          fontFamily: 'Rajdhani',
                          fontSize: 11,
                          color: Colors.white38,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Gradient at bottom for text legibility (when unlocked)
            if (isUnlocked)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.35, 1.0],
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.92),
                      ],
                    ),
                  ),
                ),
              ),

            // Card Bottom Info (when unlocked)
            if (isUnlocked)
              Positioned(
                left: 12,
                right: 12,
                bottom: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          pilot.name.toUpperCase(),
                          style: TextStyle(
                            fontFamily: 'Orbitron',
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: memory.themeColor,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: memory.themeColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: memory.themeColor.withOpacity(0.6), width: 0.8),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.zoom_in, size: 12, color: Colors.white),
                              SizedBox(width: 2),
                              Text(
                                'AMPLIAR',
                                style: TextStyle(
                                  fontFamily: 'Orbitron',
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      memory.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Orbitron',
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      memory.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Rajdhani',
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemoryLightbox(SecretMemory memory) {
    final pilot = Valkyrie.findById(memory.valkyrieId);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (_cleanMode) {
            setState(() => _cleanMode = false);
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Black Blur Backdrop
            Container(
              color: Colors.black.withOpacity(0.96),
            ),

          // High Resolution Image with Interactive Viewer (Zoom & Pan)
          Center(
            child: InteractiveViewer(
              minScale: 0.8,
              maxScale: 3.5,
              child: Image.asset(
                memory.imageAsset,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.image_rounded, size: 80, color: memory.themeColor),
                      const SizedBox(height: 12),
                      Text(
                        memory.title,
                        style: const TextStyle(
                          fontFamily: 'Orbitron',
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Header Controls (when not in clean mode)
          if (!_cleanMode)
            Positioned(
              top: 24,
              left: 24,
              right: 24,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Pilot & Memory Title
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: memory.themeColor.withOpacity(0.2),
                            border: Border.all(color: memory.themeColor),
                          ),
                          child: const Icon(Icons.auto_awesome, size: 16, color: Colors.white),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${pilot.name.toUpperCase()} // ${memory.title.toUpperCase()}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Orbitron',
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2.0,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Actions: Clean mode toggle & Close
                  Row(
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.12),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        ),
                        icon: const Icon(Icons.visibility_off, size: 16),
                        label: const Text(
                          'MODO PAPEL DE PAREDE',
                          style: TextStyle(fontFamily: 'Orbitron', fontSize: 10),
                        ),
                        onPressed: () => setState(() => _cleanMode = true),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        key: const Key('lightbox_close_button'),
                        tooltip: 'Fechar Memória',
                        icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                        onPressed: () => setState(() => _openedMemory = null),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          // Bottom Lore Card (when not in clean mode)
          if (!_cleanMode)
            Positioned(
              left: 24,
              right: 24,
              bottom: 24,
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 820),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF101622).withOpacity(0.92),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: memory.themeColor.withOpacity(0.5), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.7),
                        blurRadius: 20,
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            memory.title,
                            style: TextStyle(
                              fontFamily: 'Orbitron',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                              color: memory.themeColor,
                            ),
                          ),
                          Text(
                            'ELO NÍVEL ${memory.requiredBondLevel} DESBLOQUEADO',
                            style: TextStyle(
                              fontFamily: 'Rajdhani',
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                              color: Colors.white.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        memory.description,
                        style: TextStyle(
                          fontFamily: 'Rajdhani',
                          fontSize: 13.5,
                          height: 1.35,
                          color: Colors.white.withOpacity(0.88),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Hint in clean mode
          if (_cleanMode)
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Text(
                    'Toque na tela para restaurar a interface',
                    style: TextStyle(
                      fontFamily: 'Rajdhani',
                      fontSize: 12,
                      letterSpacing: 1.2,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
  }

  Widget _buildWeaponCodexView() {
    final allEntries = WeaponCodexEntry.allEntries;
    final filteredEntries = allEntries.where(_filterWeaponCodexByCat).toList();

    int totalUnlocked = 0;
    for (final e in allEntries) {
      if (widget.game.isWeaponUnlockedInPool(e.id)) totalUnlocked++;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Weapon Codex Filter Bar & Counter
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF131A26).withOpacity(0.9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Filter Buttons
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildWeaponCodexFilterChip('all', 'TODAS (${allEntries.length})'),
                      const SizedBox(width: 8),
                      _buildWeaponCodexFilterChip('blade', 'LÂMINAS / CORTE'),
                      const SizedBox(width: 8),
                      _buildWeaponCodexFilterChip('plasma', 'PLASMA / ENERGIA'),
                      const SizedBox(width: 8),
                      _buildWeaponCodexFilterChip('kinetic', 'CINÉTICA / EXPLOSIVOS'),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Unlocked Counter Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E5FF).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.shield_outlined, size: 14, color: Color(0xFF00E5FF)),
                    const SizedBox(width: 6),
                    Text(
                      'ARSENAL: $totalUnlocked / ${allEntries.length}',
                      style: const TextStyle(
                        fontFamily: 'Orbitron',
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Weapons Grid
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 950 ? 3 : (constraints.maxWidth > 600 ? 2 : 1);
              return GridView.builder(
                padding: const EdgeInsets.only(bottom: 16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: constraints.maxWidth > 950 ? 1.45 : 1.35,
                ),
                itemCount: filteredEntries.length,
                itemBuilder: (context, index) {
                  return _buildWeaponCodexCard(filteredEntries[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  bool _filterWeaponCodexByCat(WeaponCodexEntry entry) {
    switch (_selectedWeaponCodexCategory) {
      case 'blade':
        return ['tachyon_katana', 'quantum_chakram', 'aegis_sawblades'].contains(entry.id);
      case 'plasma':
        return ['blaster', 'rapid_fire', 'solar_lance', 'inferno_cone', 'tesla_arc'].contains(entry.id);
      case 'kinetic':
        return ['spread_shot', 'bomb_launcher', 'valkyrie_wingmen', 'void_mines', 'repulsor_aura'].contains(entry.id);
      default:
        return true;
    }
  }

  Widget _buildWeaponCodexFilterChip(String catId, String label) {
    final isSelected = _selectedWeaponCodexCategory == catId;
    return GestureDetector(
      onTap: () {
        widget.game.playSfx('menu_select.wav');
        setState(() => _selectedWeaponCodexCategory = catId);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00E5FF).withOpacity(0.25) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? const Color(0xFF00E5FF) : Colors.white12,
            width: 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Orbitron',
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: isSelected ? Colors.white : Colors.white60,
          ),
        ),
      ),
    );
  }

  Widget _buildWeaponCodexCard(WeaponCodexEntry entry) {
    final isUnlocked = widget.game.isWeaponUnlockedInPool(entry.id);

    return GestureDetector(
      onTap: () {
        widget.game.playSfx('menu_select.wav');
        setState(() => _openedWeaponCodex = entry);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF111824).withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isUnlocked ? entry.themeColor.withOpacity(0.65) : Colors.white12,
            width: isUnlocked ? 1.5 : 1.0,
          ),
          boxShadow: isUnlocked
              ? [
                  BoxShadow(
                    color: entry.themeColor.withOpacity(0.18),
                    blurRadius: 10,
                  )
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Icon, Name, Classification
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: entry.themeColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: entry.themeColor.withOpacity(0.6)),
                  ),
                  child: Center(
                    child: Icon(entry.icon, color: entry.themeColor, size: 24),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Orbitron',
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        entry.classification.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Rajdhani',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: entry.themeColor,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isUnlocked)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.orange.withOpacity(0.6)),
                    ),
                    child: const Text(
                      'BLOQUEADA',
                      style: TextStyle(
                        fontFamily: 'Orbitron',
                        fontSize: 8.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 8),

            // Manufacturer
            Text(
              'FABRICANTE: ${entry.manufacturer}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Rajdhani',
                fontSize: 11,
                color: Colors.white.withOpacity(0.55),
              ),
            ),

            const SizedBox(height: 4),

            // Short summary of lore
            Expanded(
              child: Text(
                entry.loreDescription,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Rajdhani',
                  fontSize: 11.5,
                  height: 1.25,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ),

            const Divider(color: Colors.white10, height: 10),

            // Evolution preview & Action
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.auto_awesome, size: 12, color: Color(0xFFFFD700)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          entry.evolvedName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Orbitron',
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFFD700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: entry.themeColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: entry.themeColor.withOpacity(0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.menu_book_rounded, size: 11, color: entry.themeColor),
                      const SizedBox(width: 4),
                      Text(
                        'DOSSIÊ',
                        style: TextStyle(
                          fontFamily: 'Orbitron',
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: entry.themeColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeaponDossierLightbox(WeaponCodexEntry entry) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          setState(() => _openedWeaponCodex = null);
        },
        child: Container(
          color: Colors.black.withOpacity(0.94),
          alignment: Alignment.center,
          padding: const EdgeInsets.all(24),
          child: GestureDetector(
            onTap: () {}, // Prevent closing when clicking inside modal
            child: Container(
              constraints: const BoxConstraints(maxWidth: 960, maxHeight: 620),
              decoration: BoxDecoration(
                color: const Color(0xFF0C121C),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: entry.themeColor.withOpacity(0.85), width: 2.0),
                boxShadow: [
                  BoxShadow(
                    color: entry.themeColor.withOpacity(0.35),
                    blurRadius: 24,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Modal Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF141D2B),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                      border: Border(bottom: BorderSide(color: entry.themeColor.withOpacity(0.4))),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: entry.themeColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(entry.icon, color: entry.themeColor, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    entry.name.toUpperCase(),
                                    style: const TextStyle(
                                      fontFamily: 'Orbitron',
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.5,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: entry.themeColor.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: entry.themeColor.withOpacity(0.5)),
                                    ),
                                    child: Text(
                                      entry.classification.toUpperCase(),
                                      style: TextStyle(
                                        fontFamily: 'Orbitron',
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: entry.themeColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                'FABRICANTE: ${entry.manufacturer.toUpperCase()}',
                                style: TextStyle(
                                  fontFamily: 'Rajdhani',
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.65),
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Close Button
                        IconButton(
                          onPressed: () {
                            widget.game.playSfx('menu_select.wav');
                            setState(() => _openedWeaponCodex = null);
                          },
                          icon: const Icon(Icons.close, color: Colors.white70),
                          tooltip: 'Fechar Dossiê',
                        ),
                      ],
                    ),
                  ),

                  // Modal Body
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left Column: Schematics & Ratings (~320px)
                          SizedBox(
                            width: 320,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Hologram Emblem
                                Container(
                                  height: 160,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF080D14),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: entry.themeColor.withOpacity(0.4)),
                                    gradient: RadialGradient(
                                      colors: [
                                        entry.themeColor.withOpacity(0.25),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      CustomPaint(
                                        size: const Size(320, 160),
                                        painter: _GridPatternPainter(entry.themeColor.withOpacity(0.1)),
                                      ),
                                      Icon(
                                        entry.icon,
                                        size: 64,
                                        color: entry.themeColor,
                                      ),
                                      Positioned(
                                        bottom: 8,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(0.75),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: entry.themeColor.withOpacity(0.5)),
                                          ),
                                          child: Text(
                                            entry.damageType.toUpperCase(),
                                            style: TextStyle(
                                              fontFamily: 'Rajdhani',
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1.0,
                                              color: entry.themeColor,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 14),

                                // Ratings Bars
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF131A26),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.white12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'AVALIAÇÃO TÁTICA DE COMBATE',
                                        style: TextStyle(
                                          fontFamily: 'Orbitron',
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.0,
                                          color: Colors.white70,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      _buildRatingRow('DANO BRUTO', entry.damageRating, entry.themeColor),
                                      _buildRatingRow('CADÊNCIA', entry.fireRateRating, entry.themeColor),
                                      _buildRatingRow('ALCANCE', entry.rangeRating, entry.themeColor),
                                      _buildRatingRow('COMPLEXIDADE', entry.difficultyRating, Colors.amber),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 14),

                                // Technical Specifications
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF131A26),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.white12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'ESPECIFICAÇÕES DE ENGENHARIA',
                                        style: TextStyle(
                                          fontFamily: 'Orbitron',
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.0,
                                          color: Colors.white70,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        entry.technicalSpecs,
                                        style: TextStyle(
                                          fontFamily: 'Rajdhani',
                                          fontSize: 12.5,
                                          height: 1.3,
                                          color: Colors.white.withOpacity(0.85),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 18),

                          // Right Column: Lore & Evolution
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Lore Section
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF131A26),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.white12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: const [
                                          Icon(Icons.history_edu_rounded, size: 16, color: Color(0xFF00E5FF)),
                                          SizedBox(width: 8),
                                          Text(
                                            'HISTÓRICO MILITAR & LORE DIEGÉTICA',
                                            style: TextStyle(
                                              fontFamily: 'Orbitron',
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1.0,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        entry.loreDescription,
                                        style: TextStyle(
                                          fontFamily: 'Rajdhani',
                                          fontSize: 13.5,
                                          height: 1.45,
                                          color: Colors.white.withOpacity(0.92),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 14),

                                // Pilot Quote Box
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: entry.themeColor.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: entry.themeColor.withOpacity(0.35)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        entry.pilotQuote,
                                        style: TextStyle(
                                          fontFamily: 'Rajdhani',
                                          fontSize: 13.5,
                                          fontStyle: FontStyle.italic,
                                          height: 1.3,
                                          color: Colors.white.withOpacity(0.95),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: Text(
                                          '— ${entry.pilotQuoteAuthor}',
                                          style: TextStyle(
                                            fontFamily: 'Orbitron',
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: entry.themeColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 14),

                                // Legendary Super-Evolution Card
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        const Color(0xFFFFD700).withOpacity(0.18),
                                        const Color(0xFF131A26),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.6), width: 1.5),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: const [
                                              Icon(Icons.auto_awesome, color: Color(0xFFFFD700), size: 18),
                                              SizedBox(width: 8),
                                              Text(
                                                'SUPER-EVOLUÇÃO LENDÁRIA',
                                                style: TextStyle(
                                                  fontFamily: 'Orbitron',
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 1.2,
                                                  color: Color(0xFFFFD700),
                                                ),
                                              ),
                                            ],
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFFD700).withOpacity(0.25),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: const Color(0xFFFFD700)),
                                            ),
                                            child: const Text(
                                              'MK MAX + SINERGIA',
                                              style: TextStyle(
                                                fontFamily: 'Orbitron',
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFFFFD700),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        entry.evolvedName,
                                        style: const TextStyle(
                                          fontFamily: 'Orbitron',
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.2,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.link, size: 14, color: Color(0xFFFF80AB)),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              'PASSIVA NECESSÁRIA: ${entry.synergyPassiveTitle}',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontFamily: 'Rajdhani',
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFFFF80AB),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        entry.evolutionDescription,
                                        style: TextStyle(
                                          fontFamily: 'Rajdhani',
                                          fontSize: 13,
                                          height: 1.35,
                                          color: Colors.white.withOpacity(0.9),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
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
    );
  }

  Widget _buildRatingRow(String label, int rating, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Rajdhani',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          Row(
            children: List.generate(5, (index) {
              return Icon(
                index < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                size: 13,
                color: index < rating ? color : Colors.white24,
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _GridPatternPainter extends CustomPainter {
  final Color color;
  _GridPatternPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0;
    const step = 20.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
