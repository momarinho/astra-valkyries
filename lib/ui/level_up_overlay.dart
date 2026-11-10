import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:asteroids/game/asteroids_game.dart';
import 'package:asteroids/game/rogue_perks.dart';
import 'package:asteroids/services/localization_service.dart';

class LevelUpOverlay extends StatefulWidget {
  final AsteroidsGame game;

  const LevelUpOverlay({super.key, required this.game});

  @override
  State<LevelUpOverlay> createState() => _LevelUpOverlayState();
}

class _LevelUpOverlayState extends State<LevelUpOverlay> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late final FocusNode _focusNode;
  late final AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    )..forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    final choices = widget.game.currentLevelUpChoices;
    if (choices.isEmpty) return;

    if (event.logicalKey == LogicalKeyboardKey.digit1 && choices.isNotEmpty) {
      _selectPerk(0);
    } else if (event.logicalKey == LogicalKeyboardKey.digit2 && choices.length > 1) {
      _selectPerk(1);
    } else if (event.logicalKey == LogicalKeyboardKey.digit3 && choices.length > 2) {
      _selectPerk(2);
    } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
        event.logicalKey == LogicalKeyboardKey.keyA) {
      setState(() {
        _selectedIndex = (_selectedIndex - 1 + choices.length) % choices.length;
      });
      widget.game.playSfx('menu_select.wav');
    } else if (event.logicalKey == LogicalKeyboardKey.arrowRight ||
        event.logicalKey == LogicalKeyboardKey.keyD ||
        event.logicalKey == LogicalKeyboardKey.tab) {
      setState(() {
        _selectedIndex = (_selectedIndex + 1) % choices.length;
      });
      widget.game.playSfx('menu_select.wav');
    } else if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.space ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      _selectPerk(_selectedIndex);
    } else if (event.logicalKey == LogicalKeyboardKey.keyR) {
      if (widget.game.rerollLevelUpChoices()) {
        setState(() {
          _selectedIndex = 0;
        });
      }
    } else if (event.logicalKey == LogicalKeyboardKey.keyB) {
      if (choices.isNotEmpty) {
        final perkToBanish = choices[_selectedIndex.clamp(0, choices.length - 1)];
        if (widget.game.banishLevelUpPerk(perkToBanish)) {
          setState(() {
            _selectedIndex = 0;
          });
        }
      }
    } else if (event.logicalKey == LogicalKeyboardKey.keyS) {
      widget.game.skipLevelUp();
    }
  }

  void _selectPerk(int index) {
    final choices = widget.game.currentLevelUpChoices;
    if (index >= 0 && index < choices.length) {
      widget.game.selectLevelUpPerk(choices[index]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final choices = widget.game.currentLevelUpChoices;
    final level = widget.game.runLevel;

    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // Backdrop com desfoque e escurecimento cinematográfico
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 7.0, sigmaY: 7.0),
                child: Container(
                  color: Colors.black.withOpacity(0.65),
                ),
              ),
            ),

            Center(
              child: FadeTransition(
                opacity: _animController,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.92, end: 1.0).animate(
                    CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
                  ),
                  child: Container(
                    width: MediaQuery.of(context).size.width > 980
                        ? 960
                        : MediaQuery.of(context).size.width * 0.94,
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.90,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D1117).withOpacity(0.92),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: const Color(0xFFFFD700).withOpacity(0.45),
                        width: 1.8,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFD700).withOpacity(0.18),
                          blurRadius: 30.0,
                          spreadRadius: 2.0,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header com Badge de Nível
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFFFB300), Color(0xFFFF6D00)],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFFB300).withOpacity(0.4),
                                    blurRadius: 12,
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.bolt, color: Colors.black, size: 20),
                                  const SizedBox(width: 6),
                                  Text(
                                    I18n.t('level_up.badge', {'level': '$level'}),
                                    style: const TextStyle(
                                      fontFamily: 'Orbitron',
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 2.0,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        Text(
                          I18n.t('level_up.subtitle'),
                          style: TextStyle(
                            fontFamily: 'Rajdhani',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Grid / Row com as 3 Cartas
                        Flexible(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final isRow = constraints.maxWidth > 650;
                              return isRow
                                  ? Row(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: List.generate(choices.length, (i) {
                                        return Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                            child: _buildCard(choices[i], i),
                                          ),
                                        );
                                      }),
                                    )
                                  : ListView.separated(
                                      shrinkWrap: true,
                                      itemCount: choices.length,
                                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                                      itemBuilder: (_, i) => SizedBox(
                                        height: 120,
                                        child: _buildCard(choices[i], i),
                                      ),
                                    );
                            },
                          ),
                        ),

                        const SizedBox(height: 18),

                        // Sprint 54: Barra de Ações Táticas de Agência (Reroll, Banish, Skip)
                        _buildTacticalActionBar(),

                        const SizedBox(height: 14),

                        // Mobile / Touch Interaction Prompt
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.touch_app_rounded, color: Colors.cyanAccent, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                'TOQUE EM UMA CARTA PARA INSTALAR NO SEU CAÇA',
                                style: TextStyle(
                                  fontFamily: 'Rajdhani',
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white.withOpacity(0.8),
                                  letterSpacing: 1.2,
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(RoguePerk perk, int index) {
    final isSelected = index == _selectedIndex;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: GestureDetector(
        onTap: () => _selectPerk(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: isSelected
                ? perk.accentColor.withOpacity(0.18)
                : const Color(0xFF161B22).withOpacity(0.85),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? perk.accentColor
                  : perk.rarityColor.withOpacity(0.35),
              width: isSelected ? 2.2 : 1.2,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: perk.accentColor.withOpacity(0.35),
                      blurRadius: 18,
                      spreadRadius: 1.5,
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Topo do Card: Número do atalho + Rarity Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected ? perk.accentColor : Colors.white10,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontFamily: 'Rajdhani',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.black : Colors.white70,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: perk.rarityColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: perk.rarityColor.withOpacity(0.5)),
                    ),
                    child: Text(
                      perk.rarityLabel,
                      style: TextStyle(
                        fontFamily: 'Rajdhani',
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                        color: perk.rarityColor,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Ícone da Carta
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: perk.accentColor.withOpacity(0.12),
                  border: Border.all(color: perk.accentColor.withOpacity(0.6), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: perk.accentColor.withOpacity(0.2),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Icon(perk.icon, color: perk.accentColor, size: 32),
              ),

              const SizedBox(height: 8),

              // Tipo & Título
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    perk.typeLabel,
                    style: TextStyle(
                      fontFamily: 'Rajdhani',
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: perk.accentColor,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    perk.title,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              // Descrição
              Expanded(
                child: Center(
                  child: Text(
                    perk.description,
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Rajdhani',
                      fontSize: 12.5,
                      color: Colors.white.withOpacity(0.85),
                      height: 1.25,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Botão Selecionar
              AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? perk.accentColor : Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  isSelected ? 'CHOOSE [${index + 1}]' : 'SELECT',
                  style: TextStyle(
                    fontFamily: 'Rajdhani',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: isSelected ? Colors.black : Colors.white60,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTacticalActionBar() {
    final game = widget.game;
    final choices = game.currentLevelUpChoices;
    final canReroll = game.runRerollsRemaining > 0;
    final canBanish = game.runBanishesRemaining > 0 && choices.isNotEmpty;

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Reroll Button
          OutlinedButton.icon(
            key: const Key('level_up_reroll_button'),
            onPressed: canReroll
                ? () {
                    if (game.rerollLevelUpChoices()) {
                      setState(() {
                        _selectedIndex = 0;
                      });
                    }
                  }
                : null,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: Text(
              '[R] ${I18n.t('level_up.reroll', {'count': '${game.runRerollsRemaining}'})}',
              style: const TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF00E5FF),
              disabledForegroundColor: Colors.white24,
              side: BorderSide(color: canReroll ? const Color(0xFF00E5FF) : Colors.white12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(width: 12),
          // Banish Button
          OutlinedButton.icon(
            key: const Key('level_up_banish_button'),
            onPressed: canBanish
                ? () {
                    final perkToBanish = choices[_selectedIndex.clamp(0, choices.length - 1)];
                    if (game.banishLevelUpPerk(perkToBanish)) {
                      setState(() {
                        _selectedIndex = 0;
                      });
                    }
                  }
                : null,
            icon: const Icon(Icons.delete_sweep_rounded, size: 16),
            label: Text(
              '[B] ${I18n.t('level_up.banish', {'count': '${game.runBanishesRemaining}'})}',
              style: const TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFFF5252),
              disabledForegroundColor: Colors.white24,
              side: BorderSide(color: canBanish ? const Color(0xFFFF5252) : Colors.white12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(width: 12),
          // Skip Button
          OutlinedButton.icon(
            key: const Key('level_up_skip_button'),
            onPressed: () {
              game.skipLevelUp();
            },
            icon: const Icon(Icons.fast_forward_rounded, size: 16),
            label: Text(
              '[S] ${I18n.t('level_up.skip')}',
              style: const TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFFFB300),
              side: const BorderSide(color: Color(0xFFFFB300)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }
}
