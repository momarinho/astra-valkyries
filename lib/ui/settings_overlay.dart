import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:asteroids/game/asteroids_game.dart';
import 'package:asteroids/services/localization_service.dart';

class SettingsOverlay extends StatelessWidget {
  final AsteroidsGame game;

  const SettingsOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
          game.changeState(game.previousMenuState);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 6.0, sigmaY: 6.0),
              child: Container(
                width: MediaQuery.of(context).size.width > 580 ? 580 : MediaQuery.of(context).size.width * 0.92,
                padding: const EdgeInsets.all(22.0),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.cyan.withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.cyan.withValues(alpha: 0.12),
                      blurRadius: 20.0,
                      spreadRadius: 2.0,
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header & Title
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.tune_rounded, color: Colors.cyanAccent, size: 26),
                              const SizedBox(width: 10),
                              Text(
                                I18n.t('settings.title'),
                                style: const TextStyle(
                                  fontFamily: 'Orbitron',
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            onPressed: () => game.changeState(game.previousMenuState),
                            icon: const Icon(Icons.close_rounded, color: Colors.white70),
                            tooltip: I18n.t('settings.close'),
                          ),
                        ],
                      ),
                      const Divider(color: Colors.white24, height: 24),

                      // Section 0: Idioma // Language Selector
                      Text(
                        I18n.t('settings.language_header'),
                        style: const TextStyle(
                          fontFamily: 'Orbitron',
                          fontSize: 12.0,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          color: Color(0xFF64FFDA),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          // PT-BR Option
                          Expanded(
                            child: _buildLanguageOption(
                              context: context,
                              locale: AppLocale.ptBr,
                              isSelected: I18n.isPt,
                              onTap: () async {
                                await I18n.setLocale(AppLocale.ptBr);
                                (context as Element).markNeedsBuild();
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          // EN-US Option
                          Expanded(
                            child: _buildLanguageOption(
                              context: context,
                              locale: AppLocale.enUs,
                              isSelected: I18n.isEn,
                              onTap: () async {
                                await I18n.setLocale(AppLocale.enUs);
                                (context as Element).markNeedsBuild();
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Section 1: Modo de Pilotagem (Vector Reverse vs 360° Directional)
                      Text(
                        I18n.t('settings.control_scheme_header'),
                        style: const TextStyle(
                          fontFamily: 'Orbitron',
                          fontSize: 12.0,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          color: Color(0xFFFFD700),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildControlSchemeOption(
                        context: context,
                        isSelected: !game.useDirectionalControls,
                        title: I18n.t('settings.control_vector'),
                        subtitle: I18n.t('settings.control_vector_desc'),
                        onTap: () {
                          game.useDirectionalControls = false;
                          (context as Element).markNeedsBuild();
                        },
                      ),
                      const SizedBox(height: 8),
                      _buildControlSchemeOption(
                        context: context,
                        isSelected: game.useDirectionalControls,
                        title: I18n.t('settings.control_directional'),
                        subtitle: I18n.t('settings.control_directional_desc'),
                        onTap: () {
                          game.useDirectionalControls = true;
                          (context as Element).markNeedsBuild();
                        },
                      ),

                      const SizedBox(height: 20),

                      // Section 2: Movement Presets
                      Text(
                        I18n.select(
                          pt: 'CALIBRAGEM DE PROPULSÃO // FÍSICA DE VOO',
                          en: 'THRUSTER CALIBRATION // FLIGHT PHYSICS',
                        ),
                        style: const TextStyle(
                          fontFamily: 'Orbitron',
                          fontSize: 12.0,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          color: Colors.cyanAccent,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...List.generate(game.movementPresets.length, (index) {
                        final preset = game.movementPresets[index];
                        final isSelected = game.selectedMovementPresetIndex == index;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: InkWell(
                            onTap: () {
                              game.selectedMovementPresetIndex = index;
                              (context as Element).markNeedsBuild();
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 11.0, horizontal: 14.0),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.white.withValues(alpha: 0.06) : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected ? Colors.cyan : Colors.white12,
                                  width: isSelected ? 1.5 : 1.0,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          preset.label.toUpperCase(),
                                          style: TextStyle(
                                            fontFamily: 'Orbitron',
                                            fontSize: 13.0,
                                            fontWeight: FontWeight.bold,
                                            color: isSelected ? Colors.cyanAccent : Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          'Acc: ${preset.acceleration.toInt()}  |  Max Speed: ${preset.maxSpeed.toInt()}  |  Friction: ${preset.friction.toStringAsFixed(1)}',
                                          style: const TextStyle(fontSize: 11.5, color: Colors.white60),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    const Icon(Icons.check_circle, color: Colors.cyan, size: 20),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),

                      const SizedBox(height: 22),

                      // Save & Return Button
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                game.changeState(GameState.menu);
                              },
                              icon: const Icon(Icons.home_rounded, size: 18),
                              label: Text(
                                I18n.t('game_over.menu'),
                                style: const TextStyle(
                                  fontFamily: 'Orbitron',
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white70,
                                side: const BorderSide(color: Colors.white24),
                                padding: const EdgeInsets.symmetric(vertical: 15.0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                game.changeState(game.previousMenuState);
                              },
                              icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                              label: Text(
                                I18n.select(pt: 'CONFIRMAR & VOLTAR', en: 'CONFIRM & RETURN'),
                                style: const TextStyle(
                                  fontFamily: 'Orbitron',
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.cyan,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(vertical: 15.0),
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
    );
  }

  Widget _buildLanguageOption({
    required BuildContext context,
    required AppLocale locale,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF64FFDA).withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFF64FFDA) : Colors.white12,
            width: isSelected ? 1.8 : 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(locale.flag, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(
              locale.label,
              style: TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: isSelected ? const Color(0xFF64FFDA) : Colors.white70,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              const Icon(Icons.check_circle_rounded, color: Color(0xFF64FFDA), size: 16),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildControlSchemeOption({
    required BuildContext context,
    required bool isSelected,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11.0, horizontal: 14.0),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFFFD700).withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFFFFD700) : Colors.white12,
            width: isSelected ? 1.6 : 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 12.0,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? const Color(0xFFFFD700) : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11.5, color: Colors.white70),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Color(0xFFFFD700), size: 20),
          ],
        ),
      ),
    );
  }
}
