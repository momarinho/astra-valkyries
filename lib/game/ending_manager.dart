import 'package:flutter/material.dart';
import 'sector.dart';

enum EndingType {
  none,
  badEnding,  // 💀 Colapso do Vazio (Sinal biométrico perdido & reinício de loop)
  goodEnding, // 🌟 Protocolo Estabilizado (Fenda selada & frota humana salva)
  trueEnding, // ✨ Quebra do Protocolo & Ascensão (Ciclo cósmico rompido no Setor 5 com Elo 5)
}

class EndingDetails {
  final EndingType type;
  final String code;
  final String title;
  final String subtitle;
  final String narrativeBody;
  final String biometricStatus;
  final Color primaryColor;
  final IconData icon;

  const EndingDetails({
    required this.type,
    required this.code,
    required this.title,
    required this.subtitle,
    required this.narrativeBody,
    required this.biometricStatus,
    required this.primaryColor,
    required this.icon,
  });
}

/// Gerenciador de Finais Múltiplos e Desbloqueio do Setor 5 Secreto (Sprint 24).
class EndingManager {
  static const Map<EndingType, EndingDetails> endingsCatalog = {
    EndingType.badEnding: EndingDetails(
      type: EndingType.badEnding,
      code: 'ENDING A // BAD ENDING',
      title: 'COLAPSO DO VAZIO',
      subtitle: 'SINAL BIOMÉTRICO PERDIDO // REINICIANDO LOOP TEMPORAL',
      narrativeBody:
          'O casco da nave se rompe diante da singularidade. Enquanto os sensores apagam no vácuo absoluto, '
          'a transmissão automática do Comando Central ecoa: "Sinal biométrico da Valquíria perdido. '
          'Restaurando backup neural no Hangar... Reiniciando Protocolo Void." '
          'Você desperta novamente na baia de lançamento, presa no ciclo eterno de sacrifício.',
      biometricStatus: '⚠️ ALERTA CRÍTICO: SINAL BIOMÉTRICO PERDIDO — LOOP REINICIADO NO HANGAR',
      primaryColor: Color(0xFFFF1744),
      icon: Icons.sentiment_very_dissatisfied_rounded,
    ),
    EndingType.goodEnding: EndingDetails(
      type: EndingType.goodEnding,
      code: 'ENDING B // GOOD ENDING',
      title: 'PROTOCOLO ESTABILIZADO',
      subtitle: 'SINGULARIDADE CONTIDA // FROTA HUMANA EVACUADA COM SUCESSO',
      narrativeBody:
          'Com a destruição do Void Singularity Core no Horizonte de Eventos, as ondas gravitacionais '
          'cessam por tempo suficiente para que os comboios civis cruzem o portal de evacuação. '
          'A Valquíria retorna ao Hangar sob aplausos da frota sobrevivente. Contudo, os sensores de longo '
          'alcance indicam que uma presença primordial ainda dorme além da fenda...',
      biometricStatus: '✅ SINAL ESTÁVEL: COMBOIO HUMANO SALVO // CRÉDITOS GALÁCTICOS DE HONRA',
      primaryColor: Color(0xFF00E5FF),
      icon: Icons.verified_rounded,
    ),
    EndingType.trueEnding: EndingDetails(
      type: EndingType.trueEnding,
      code: 'ENDING C // TRUE ENDING',
      title: 'QUEBRA DO PROTOCOLO & ASCENSÃO',
      subtitle: 'O TRONO DO VAZIO DESTRONADO // LIBERTAÇÃO DO CICLO CÓSMICO',
      narrativeBody:
          'No coração do Setor 5 Secreto, o Primordial Void Sovereign cai diante do Elo Nível 5 entre '
          'piloto e Comandante. A verdade oculta vem à tona: o Protocolo Void era uma jaula temporal '
          'criada pelos Arquitetos Ancestrais. Ao fundir sua matriz com a chama da Astraea, a Valquíria '
          'estilhaça o loop para sempre e retira o capacete sob o renascimento de milhares de estrelas.',
      biometricStatus: '✨ ASCENSÃO COMPLETA: PROTOCOLO VOID ROMPIDO // LIBERDADE ETERNA ALCANÇADA',
      primaryColor: Color(0xFFFFD700),
      icon: Icons.auto_awesome_rounded,
    ),
  };

  /// Verifica se o Setor 5 Secreto (O Trono do Vazio) está desbloqueado para a run atual
  static bool canAccessSecretSector5({
    required int voidCellsLevel,
    required bool astraeaMatrixDecoded,
    required String selectedValkyrieId,
  }) {
    return voidCellsLevel >= 3 || astraeaMatrixDecoded || selectedValkyrieId == 'astraea';
  }

  /// Determina qual final foi alcançado ao término da missão
  static EndingType evaluateEnding({
    required bool survived,
    required SectorId sectorId,
    required bool voidReaperSpawned,
    required bool campaignCompleted,
    required bool primordialSovereignDefeated,
    required int activeValkyrieBondLevel,
  }) {
    if (!survived) {
      if (sectorId == SectorId.eventHorizon ||
          sectorId == SectorId.voidThrone ||
          voidReaperSpawned) {
        return EndingType.badEnding;
      }
      return EndingType.none;
    }

    // Vitória no Setor 5 Secreto (O Trono do Vazio)
    if (sectorId == SectorId.voidThrone || primordialSovereignDefeated) {
      if (activeValkyrieBondLevel >= 5) {
        return EndingType.trueEnding;
      }
      return EndingType.goodEnding;
    }

    // Vitória no Setor 4 (Horizonte de Eventos)
    if (sectorId == SectorId.eventHorizon && campaignCompleted) {
      return EndingType.goodEnding;
    }

    return EndingType.none;
  }

  static EndingDetails? getDetails(EndingType type) => endingsCatalog[type];
}
